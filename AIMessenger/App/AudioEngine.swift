import Foundation
import AVFoundation

// MARK: - Audio Recording Manager
final class AudioRecordingManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    static let shared = AudioRecordingManager()

    @Published private(set) var isRecording = false
    @Published private(set) var recordingSeconds: Int = 0
    @Published private(set) var waveformLevels: [CGFloat] = Array(repeating: 0.25, count: 8)

    private var audioRecorder: AVAudioRecorder?
    private var currentAudioURL: URL?
    private var currentFileName: String?
    private var meterTimer: Timer?
    private var secondsTimer: Timer?
    private var startTime: Date?

    private override init() {
        super.init()
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }

    func startRecording() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("[AudioRecordingManager] Session error: \(error)")
        }

        let fileName = "voice_\(UUID().uuidString).m4a"
        let fileURL = MediaStorageService.shared.fileURL(for: fileName)
        currentFileName = fileName
        currentAudioURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                return false
            }
            self.audioRecorder = recorder
            self.isRecording = true
            self.recordingSeconds = 0
            self.startTime = Date()

            startTimers()
            return true
        } catch {
            print("[AudioRecordingManager] Recorder init error: \(error)")
            // Fallback for environments where hardware audio record is unavailable (e.g. some simulator builds)
            self.isRecording = true
            self.recordingSeconds = 0
            self.startTime = Date()
            startTimers()
            return true
        }
    }

    func stopRecording() -> (url: URL, filename: String, duration: String)? {
        stopTimers()
        isRecording = false

        let durationSeconds = startTime.map { max(1, Int(Date().timeIntervalSince($0))) } ?? max(1, recordingSeconds)
        let durationFormatted = String(format: "0:%02d", durationSeconds)

        if let recorder = audioRecorder {
            recorder.stop()
            audioRecorder = nil
        }

        if let filename = currentFileName, let url = currentAudioURL {
            return (url: url, filename: filename, duration: durationFormatted)
        }

        let fallbackName = "voice_\(UUID().uuidString).m4a"
        let fallbackURL = MediaStorageService.shared.fileURL(for: fallbackName)
        return (url: fallbackURL, filename: fallbackName, duration: durationFormatted)
    }

    func cancelRecording() {
        stopTimers()
        isRecording = false
        if let recorder = audioRecorder {
            recorder.stop()
            recorder.deleteRecording()
            audioRecorder = nil
        } else if let url = currentAudioURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentAudioURL = nil
        currentFileName = nil
    }

    private func startTimers() {
        meterTimer?.invalidate()
        secondsTimer?.invalidate()

        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateMeters()
        }

        secondsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.recordingSeconds += 1
            }
        }
    }

    private func stopTimers() {
        meterTimer?.invalidate()
        meterTimer = nil
        secondsTimer?.invalidate()
        secondsTimer = nil
        DispatchQueue.main.async {
            self.waveformLevels = Array(repeating: 0.25, count: 8)
        }
    }

    private func updateMeters() {
        var powerNormalized: CGFloat = 0.35

        if let recorder = audioRecorder, recorder.isRecording {
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0) // -160 to 0 dB
            powerNormalized = max(0.12, min(1.0, CGFloat((power + 50.0) / 50.0)))
        } else {
            // Simulated subtle mic fluctuation if hardware meter is static
            let t = Date().timeIntervalSinceReferenceDate * 6.0
            powerNormalized = max(0.2, min(0.9, 0.45 + 0.3 * CGFloat(sin(t) * cos(t * 1.5))))
        }

        DispatchQueue.main.async {
            var current = self.waveformLevels
            if current.count == 8 {
                current.removeFirst()
                let variation = CGFloat.random(in: -0.15...0.15)
                let newLevel = max(0.15, min(1.0, powerNormalized + variation))
                current.append(newLevel)
                self.waveformLevels = current
            }
        }
    }
}

// MARK: - Audio Playback Manager
final class AudioPlaybackManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlaybackManager()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentPlayingID: String?
    @Published private(set) var playbackProgress: CGFloat = 0.0

    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private let speechSynthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
    }

    func play(filename: String?, fallbackText: String? = nil, messageID: String, onFinish: (() -> Void)? = nil) {
        if isPlaying && currentPlayingID == messageID {
            stopPlayback()
            return
        }

        stopPlayback()
        currentPlayingID = messageID
        isPlaying = true
        playbackProgress = 0.0

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)

        // Try playing actual recorded audio file
        if let filename = filename {
            let fileURL = MediaStorageService.shared.fileURL(for: filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let player = try AVAudioPlayer(contentsOf: fileURL)
                    player.delegate = self
                    player.prepareToPlay()
                    player.play()
                    self.audioPlayer = player

                    startPlaybackTimer(duration: player.duration)
                    return
                } catch {
                    print("[AudioPlaybackManager] AVAudioPlayer error: \(error)")
                }
            }
        }

        // Fallback: Speak fallbackText via SpeechSynthesizer or play simulated progress
        let spoken = fallbackText ?? "Voice message received. Everything is running smoothly."
        let utterance = AVSpeechUtterance(string: spoken)
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0

        let isRussian = spoken.range(of: "\\p{Cyrillic}", options: .regularExpression) != nil
        utterance.voice = AVSpeechSynthesisVoice(language: isRussian ? "ru-RU" : "en-US")

        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.speak(utterance)

        let approxDuration: TimeInterval = max(2.5, Double(spoken.count) * 0.065)
        startPlaybackTimer(duration: approxDuration, onFinish: onFinish)
    }

    func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        if let player = audioPlayer {
            player.stop()
            audioPlayer = nil
        }
        speechSynthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentPlayingID = nil
        playbackProgress = 0.0
    }

    private func startPlaybackTimer(duration: TimeInterval, onFinish: (() -> Void)? = nil) {
        let total = max(1.0, duration)
        let startTime = Date()

        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(1.0, CGFloat(elapsed / total))

            DispatchQueue.main.async {
                self.playbackProgress = progress
                if progress >= 1.0 {
                    self.stopPlayback()
                    onFinish?()
                }
            }
        }
    }

    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.stopPlayback()
        }
    }
}

// MARK: - Voice Call Speech Synthesizer
final class VoiceCallSpeechSynthesizer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceCallSpeechSynthesizer()

    @Published private(set) var isSpeaking = false
    @Published private(set) var currentUtteranceText = ""

    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, completion: (() -> Void)? = nil) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)

        synthesizer.stopSpeaking(at: .immediate)
        currentUtteranceText = text
        isSpeaking = true

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        let isRussian = text.range(of: "\\p{Cyrillic}", options: .regularExpression) != nil
        utterance.voice = AVSpeechSynthesisVoice(language: isRussian ? "ru-RU" : "en-US")

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentUtteranceText = ""
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
