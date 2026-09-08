import Foundation
import AVFoundation
import UIKit
import SwiftUI
import CoreMedia

@MainActor
final class VideoNoteRecordingManager: NSObject, ObservableObject {
    static let shared = VideoNoteRecordingManager()

    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var durationString: String = "0:00"
    @Published var cameraAvailable: Bool = false

    private var captureSession: AVCaptureSession?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var currentRecordingURL: URL?
    private var recordingTimer: Task<Void, Never>?
    private var completionContinuation: CheckedContinuation<(duration: String, filename: String)?, Never>?

    override private init() {
        super.init()
        checkCameraAvailability()
    }

    private func checkCameraAvailability() {
        #if targetEnvironment(simulator)
        cameraAvailable = false
        #else
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices
        cameraAvailable = !devices.isEmpty
        #endif
    }

    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func startRecording() async -> Bool {
        guard !isRecording else { return false }

        let mediaDir = MediaStorageService.shared.mediaDirectory
        let filename = "video_note_\(UUID().uuidString).mp4"
        let outputURL = mediaDir.appendingPathComponent(filename)
        self.currentRecordingURL = outputURL

        isRecording = true
        recordingDuration = 0
        durationString = "0:00"

        startTimer()

        if cameraAvailable {
            setupAndStartCaptureSession(outputURL: outputURL)
        }

        return true
    }

    private func startTimer() {
        recordingTimer?.cancel()
        recordingTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self, self.isRecording else { break }
                self.recordingDuration += 1
                let seconds = Int(self.recordingDuration)
                self.durationString = String(format: "0:%02d", seconds)

                if seconds >= 60 {
                    _ = await self.stopRecording()
                    break
                }
            }
        }
    }

    func stopRecording() async -> (duration: String, filename: String)? {
        guard isRecording, let outputURL = currentRecordingURL else { return nil }

        recordingTimer?.cancel()
        recordingTimer = nil
        isRecording = false

        let finalDuration = durationString == "0:00" ? "0:02" : durationString
        let filename = outputURL.lastPathComponent

        if cameraAvailable, let movieOutput = movieFileOutput, movieOutput.isRecording {
            return await withCheckedContinuation { continuation in
                self.completionContinuation = continuation
                movieOutput.stopRecording()
                self.captureSession?.stopRunning()
            }
        } else {
            let seconds = max(2, Int(recordingDuration))
            await generateFallbackVideoFile(at: outputURL, durationSeconds: Double(seconds))
            return (duration: finalDuration, filename: filename)
        }
    }

    func cancelRecording() {
        recordingTimer?.cancel()
        recordingTimer = nil
        isRecording = false

        if cameraAvailable, let movieOutput = movieFileOutput, movieOutput.isRecording {
            movieOutput.stopRecording()
            captureSession?.stopRunning()
        }

        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentRecordingURL = nil
    }

    private func setupAndStartCaptureSession(outputURL: URL) {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let frontCamera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first else {
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }

            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }

            let output = AVCaptureMovieFileOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.movieFileOutput = output
            }

            self.captureSession = session

            Task.detached(priority: .userInitiated) {
                session.startRunning()
                await MainActor.run {
                    output.startRecording(to: outputURL, recordingDelegate: self)
                }
            }
        } catch {
            print("[VideoNoteRecorder] Capture session error: \(error)")
        }
    }

    private func generateFallbackVideoFile(at fileURL: URL, durationSeconds: Double) async {
        let width = 480
        let height = 480
        let fps: Int32 = 30
        let totalFrames = Int(durationSeconds * Double(fps))

        try? FileManager.default.removeItem(at: fileURL)

        guard let writer = try? AVAssetWriter(outputURL: fileURL, fileType: .mp4) else { return }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1_200_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )

        guard writer.canAdd(writerInput) else { return }
        writer.add(writerInput)

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        for frame in 0..<totalFrames {
            while !writerInput.isReadyForMoreMediaData {
                try? await Task.sleep(nanoseconds: 2_000_000)
            }

            let presentationTime = CMTime(value: Int64(frame), timescale: fps)
            if let pixelBuffer = makeFramePixelBuffer(frame: frame, total: totalFrames, width: width, height: height) {
                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
            }
        }

        writerInput.markAsFinished()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writer.finishWriting {
                continuation.resume()
            }
        }
    }

    private func makeFramePixelBuffer(frame: Int, total: Int, width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        let progress = CGFloat(frame) / CGFloat(max(1, total))
        let phase = progress * .pi * 4

        // Background Gradient
        let color1 = UIColor(red: 0.08, green: 0.12, blue: 0.22, alpha: 1.0).cgColor
        let color2 = UIColor(red: 0.12, green: 0.18, blue: 0.32, alpha: 1.0).cgColor
        let colors = [color1, color2] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: CGFloat(width), y: CGFloat(height)),
                options: []
            )
        }

        // Circular dynamic pulse rings
        let center = CGPoint(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
        let ringCount = 4
        for i in 0..<ringCount {
            let rPhase = (CGFloat(i) * 0.25 + progress).truncatingRemainder(dividingBy: 1.0)
            let radius = 60.0 + rPhase * 140.0
            let alpha = (1.0 - rPhase) * 0.45

            context.setStrokeColor(UIColor(red: 0.2, green: 0.65, blue: 1.0, alpha: alpha).cgColor)
            context.setLineWidth(3.0)
            context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }

        // Animated Avatar Center Silhouette
        let headRadius: CGFloat = 45.0 + sin(phase) * 3.0
        context.setFillColor(UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.85).cgColor)
        context.fillEllipse(in: CGRect(x: center.x - headRadius, y: center.y - headRadius - 10, width: headRadius * 2, height: headRadius * 2))

        // Shoulders
        let shoulderRect = CGRect(x: center.x - 90, y: center.y + 40, width: 180, height: 110)
        let shoulderPath = UIBezierPath(roundedRect: shoulderRect, cornerRadius: 40)
        context.addPath(shoulderPath.cgPath)
        context.fillPath()

        return buffer
    }
}

extension VideoNoteRecordingManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            let finalDuration = self.durationString == "0:00" ? "0:02" : self.durationString
            let filename = outputFileURL.lastPathComponent
            self.completionContinuation?.resume(returning: (duration: finalDuration, filename: filename))
            self.completionContinuation = nil
        }
    }
}

// MARK: - Circular Video Player for VideoNoteBubble

struct CircularVideoPlayerView: View {
    let videoURL: URL
    @Binding var isPlaying: Bool
    @Binding var progress: CGFloat
    let onFinished: () -> Void

    @State private var player: AVPlayer?
    @State private var timeObserver: Any?

    var body: some View {
        VideoPlayerLayerRepresentable(player: player)
            .clipShape(Circle())
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                cleanupPlayer()
            }
            .onChange(of: isPlaying) { _, playing in
                if playing {
                    player?.play()
                } else {
                    player?.pause()
                }
            }
    }

    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        let avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer.isMuted = false
        self.player = avPlayer

        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak avPlayer] time in
            guard let avPlayer = avPlayer,
                  let duration = avPlayer.currentItem?.duration.seconds,
                  duration > 0 else { return }
            let current = time.seconds
            self.progress = CGFloat(current / duration)

            if current >= duration - 0.05 {
                self.isPlaying = false
                self.progress = 0
                avPlayer.seek(to: .zero)
                self.onFinished()
            }
        }
    }

    private func cleanupPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
    }
}

private struct VideoPlayerLayerRepresentable: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerUIView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
