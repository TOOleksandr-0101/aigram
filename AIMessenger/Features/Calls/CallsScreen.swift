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
struct TelegramCallView: View {
    let contactName: String
    let avatar: ChatAvatarKind
    let roleTitle: String
    let greetingText: String?

    @Environment(\.dismiss) private var dismiss
    @State private var callDurationSeconds = 0
    @State private var isConnected = false
    @State private var isMuted = false
    @State private var isSpeakerOn = true
    @State private var isVideoOn = false
    @State private var pulsePhase: CGFloat = 1.0
    @State private var subtitleText: String = ""

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

                avatarAndPulseSection

                Spacer()

                if subtitleText.isEmpty == false {
                    spokenSubtitleBadge
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                bottomControls
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 20)
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            let spokenGreeting = greetingText ?? "Hey! Connected to \(contactName). How can I help today?"
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isConnected = true
                subtitleText = spokenGreeting
            }

            if !isMuted {
                VoiceCallSpeechSynthesizer.shared.speak(text: spokenGreeting)
            }

            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if isConnected {
                    callDurationSeconds += 1
                }
            }
        }
        .onDisappear {
            VoiceCallSpeechSynthesizer.shared.stop()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                VoiceCallSpeechSynthesizer.shared.stop()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.12), in: Circle())
            }

            Spacer()

            HStack(spacing: 5) {
                Text("🔐")
                Text("⚡️")
                Text("🤖")
                Text("🧠")
            }
            .font(.system(size: 15))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12), in: Capsule())

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var avatarAndPulseSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(isConnected ? 0.15 : 0.25), lineWidth: 1.5)
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulsePhase)
                    .opacity(2.0 - pulsePhase)
                    .animation(
                        .easeInOut(duration: 1.6).repeatForever(autoreverses: false),
                        value: pulsePhase
                    )

                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 170, height: 170)
                    .scaleEffect(pulsePhase * 0.95)
                    .opacity(1.8 - pulsePhase)
                    .animation(
                        .easeInOut(duration: 1.6).repeatForever(autoreverses: false).delay(0.3),
                        value: pulsePhase
                    )

                AvatarView(kind: avatar, showsOnlineDot: false)
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.4), radius: 18, x: 0, y: 10)
            }
            .onAppear {
                pulsePhase = 1.6
            }

            VStack(spacing: 6) {
                Text(contactName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(statusText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isConnected ? Color(hex: 0x55E296) : .white.opacity(0.65))
            }
        }
    }

    private var spokenSubtitleBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0x55E296))

            Text(subtitleText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.45), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var bottomControls: some View {
        VStack(spacing: 28) {
            HStack(spacing: 32) {
                callControlButton(
                    symbol: isMuted ? "mic.slash.fill" : "mic.fill",
                    label: "Mute",
                    isActive: isMuted
                ) {
                    isMuted.toggle()
                    if isMuted {
                        VoiceCallSpeechSynthesizer.shared.stop()
                    } else if isConnected && !subtitleText.isEmpty {
                        VoiceCallSpeechSynthesizer.shared.speak(text: subtitleText)
                    }
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
                VoiceCallSpeechSynthesizer.shared.stop()
                dismiss()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
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
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(isActive ? .black : .white)
                    .frame(width: 60, height: 60)
                    .background(
                        isActive ? Color.white : Color.white.opacity(0.18),
                        in: Circle()
                    )

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var statusText: String {
        if isConnected {
            let minutes = callDurationSeconds / 60
            let seconds = callDurationSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return "Calling..."
        }
    }

    private var callBackground: some View {
        ZStack {
            Color(hex: 0x0F141C)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x1C2F4D).opacity(0.7), Color.clear],
                center: .top,
                startRadius: 40,
                endRadius: 400
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0x241C3D).opacity(0.5), Color.clear],
                center: .bottom,
                startRadius: 20,
                endRadius: 350
            )
            .ignoresSafeArea()
        }
    }
}
