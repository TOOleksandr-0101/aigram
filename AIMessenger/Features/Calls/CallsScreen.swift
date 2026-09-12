import SwiftUI

struct CallsScreen: View {
    private let calls = CallRecord.sampleCalls
    @State private var activeCallRecord: CallRecord?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar

                ForEach(Array(calls.enumerated()), id: \.element.id) { index, call in
                    Button {
                        activeCallRecord = call
                    } label: {
                        callRow(call: call, showSeparator: index < calls.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 96)
        }
        .background(TelegramPalette.backgroundPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $activeCallRecord) { call in
            TelegramCallView(
                contactName: call.name,
                avatar: call.avatar,
                roleTitle: call.detail,
                greetingText: "Hey! Connected with \(call.name). Ready to discuss your questions."
            )
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-testCall") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activeCallRecord = calls.first
                }
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Edit") { }
                    .font(.system(size: 17))
                    .foregroundStyle(.white)

                Spacer()

                Text("Calls")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    activeCallRecord = calls.first
                } label: {
                    Image(systemName: "waveform.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private func callRow(call: CallRecord, showSeparator: Bool) -> some View {
        HStack(spacing: 10) {
            AvatarView(kind: call.avatar, showsOnlineDot: false)

            VStack(alignment: .leading, spacing: 3) {
                Text(call.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)

                Text(call.detail)
                    .font(.system(size: 15))
                    .foregroundStyle(call.direction.color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(call.date)
                    .font(.system(size: 14))
                    .foregroundStyle(TelegramPalette.mutedText)

                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(TelegramPalette.accentBlue)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 76)
        .background(TelegramPalette.backgroundPrimary)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 79)
            }
        }
    }
}

struct CallsScreen_Previews: PreviewProvider {
    static var previews: some View {
        CallsScreen()
    }
}

// MARK: - Telegram Audio Call View
// MARK: - Telegram Audio Call View with Live Duplex AI & Glowing Audio Orb
struct TelegramCallView: View {
    let contactName: String
    let avatar: ChatAvatarKind
    let roleTitle: String
    let greetingText: String?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var duplexManager = LiveDuplexVoiceManager.shared
    @State private var callDurationSeconds = 0
    @State private var isConnected = false
    @State private var isMuted = false
    @State private var isSpeakerOn = true
    @State private var isVideoOn = false
    @State private var orbRotation: Double = 0
    @State private var selectedTimbre: VoiceTimbre = VoiceTimbre.presets[0]

    private let samplePromptChips = [
        "Review Swift 6 Concurrency",
        "What is in Q3 Roadmap?",
        "Explain On-Device Inference",
        "Design System 16pt Grid"
    ]

    init(
        contactName: String,
        avatar: ChatAvatarKind,
        roleTitle: String = "AI Assistant",
        greetingText: String? = nil
    ) {
        self.contactName = contactName
        self.avatar = avatar
        self.roleTitle = roleTitle
        self.greetingText = greetingText
    }

    var body: some View {
        ZStack {
            callBackground

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 16)

                Spacer()

                glowingOrbSection

                Spacer()

                if !duplexManager.aiResponseText.isEmpty {
                    spokenSubtitleBadge
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                // Interactive Duplex Test Prompt Chips
                duplexPromptChips
                    .padding(.bottom, 16)

                bottomControls
                    .padding(.bottom, 36)
            }
            .padding(.horizontal, 16)
        }
        .task {
            // Assign persona-specific initial timbre
            let initialTimbre: VoiceTimbre
            switch contactName {
            case "Design Scout": initialTimbre = VoiceTimbre.presets[2]
            case "Product Coach": initialTimbre = VoiceTimbre.presets[3]
            case "Code Partner": initialTimbre = VoiceTimbre.presets[1]
            default: initialTimbre = VoiceTimbre.presets[0]
            }
            selectedTimbre = initialTimbre

            try? await Task.sleep(nanoseconds: 1_200_000_000)
            let spokenGreeting = greetingText ?? "Hey! Connected with \(contactName). I'm ready to collaborate live."
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isConnected = true
            }

            duplexManager.startDuplex(initialGreeting: spokenGreeting, timbre: selectedTimbre)

            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if isConnected {
                    callDurationSeconds += 1
                }
            }
        }
        .onDisappear {
            duplexManager.stopDuplex()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                duplexManager.stopDuplex()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.12), in: Circle())
            }

            Spacer()

            // Voice Timbre Selector Menu
            Menu {
                ForEach(VoiceTimbre.presets) { preset in
                    Button {
                        selectedTimbre = preset
                        duplexManager.selectedTimbre = preset
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        HStack {
                            Label(preset.name, systemImage: preset.icon)
                            if selectedTimbre.id == preset.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedTimbre.icon)
                        .font(.system(size: 13))
                    Text(selectedTimbre.name)
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.14), in: Capsule())
            }

            Spacer()

            HStack(spacing: 4) {
                Text("🔐")
                Text("⚡️")
            }
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.10), in: Capsule())
        }
    }

    private var glowingOrbSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer Chromatic Glow Rings
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Color(hex: 0x00E5FF), Color(hex: 0x9D4EDD), Color(hex: 0x00FF87), Color(hex: 0x00E5FF)],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(orbRotation))
                    .scaleEffect(1.0 + duplexManager.activeAudioLevel * 0.35)
                    .opacity(0.6 + duplexManager.activeAudioLevel * 0.4)
                    .blur(radius: 6)
                    .animation(.easeInOut(duration: 0.12), value: duplexManager.activeAudioLevel)

                // Secondary Pulsing Wave
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 195, height: 195)
                    .scaleEffect(1.0 + duplexManager.activeAudioLevel * 0.45)
                    .opacity(max(0.1, 0.8 - duplexManager.activeAudioLevel))
                    .animation(.easeOut(duration: 0.2), value: duplexManager.activeAudioLevel)

                // Living Glowing Orb Sphere
                ZStack {
                    RadialGradient(
                        colors: [
                            Color(hex: duplexManager.state == .speaking ? 0x00F0FF : (duplexManager.state == .listening ? 0x55E296 : 0x7928CA)),
                            Color(hex: 0x0E1424).opacity(0.9)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 75
                    )
                    .clipShape(Circle())
                    .frame(width: 140, height: 140)
                    .shadow(
                        color: Color(hex: duplexManager.state == .speaking ? 0x00E5FF : 0x55E296).opacity(0.7),
                        radius: 24,
                        x: 0,
                        y: 0
                    )

                    // Avatar in center of glowing orb
                    AvatarView(kind: avatar, showsOnlineDot: false)
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                    orbRotation = 360
                }
            }

            VStack(spacing: 6) {
                Text(contactName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                // Live Duplex State Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(duplexManager.state.statusColor)
                        .frame(width: 8, height: 8)

                    Text(duplexManager.state.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(duplexManager.state.statusColor)

                    if isConnected {
                        Text("• \(callDurationText)")
                            .font(.system(size: 14))
                            .foregroundStyle(TelegramPalette.mutedText)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08), in: Capsule())
            }
        }
    }

    private var spokenSubtitleBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: duplexManager.state == .speaking ? "waveform.path" : "bubble.left.and.bubble.right.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0x55E296))

            Text(duplexManager.aiResponseText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var duplexPromptChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(samplePromptChips, id: \.self) { chip in
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        duplexManager.sendUserPrompt(chip, personaName: contactName)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 11))
                            Text(chip)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 24) {
            HStack(spacing: 28) {
                callControlButton(
                    symbol: isMuted ? "mic.slash.fill" : "mic.fill",
                    label: isMuted ? "Unmute" : "Mute",
                    isActive: isMuted
                ) {
                    isMuted.toggle()
                    duplexManager.setMuted(isMuted)
                }

                callControlButton(
                    symbol: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    label: "Speaker",
                    isActive: isSpeakerOn
                ) {
                    isSpeakerOn.toggle()
                }

                callControlButton(
                    symbol: isVideoOn ? "video.fill" : "video.slash.fill",
                    label: "Video",
                    isActive: isVideoOn
                ) {
                    isVideoOn.toggle()
                }
            }

            Button {
                duplexManager.stopDuplex()
                dismiss()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(Color(hex: 0xFE3B30), in: Circle())
                    .shadow(color: Color(hex: 0xFE3B30).opacity(0.4), radius: 12, y: 6)
            }
        }
    }

    private func callControlButton(
        symbol: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(isActive ? .black : .white)
                    .frame(width: 54, height: 54)
                    .background(
                        isActive ? Color.white : Color.white.opacity(0.18),
                        in: Circle()
                    )

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var callDurationText: String {
        let minutes = callDurationSeconds / 60
        let seconds = callDurationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var callBackground: some View {
        ZStack {
            Color(hex: 0x0A0E17)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x1A2942).opacity(0.7), Color.clear],
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x2A1538).opacity(0.55), Color.clear],
                center: .bottom,
                startRadius: 20,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }
}
