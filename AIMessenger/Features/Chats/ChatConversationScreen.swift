import SwiftUI

struct ChatConversationScreen: View {
    let thread: ChatThread

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var draft = ""
    @State private var messages: [ConversationMessage]
    @State private var isSending = false
    @State private var errorText: String?
    private let openRouterService = OpenRouterService()

    init(thread: ChatThread) {
        self.thread = thread
        _messages = State(initialValue: ConversationMessage.bootstrapConversation(for: thread))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(messages) { message in
                    MessageBubble(message: message)
                }

                if isSending {
                    TypingBubble()
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
        }
        .scrollContentBackground(.hidden)
        .background(chatBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }

            AvatarView(kind: thread.avatar, showsOnlineDot: thread.online)
                .frame(width: 36, height: 36)
                .scaleEffect(0.6)

            VStack(alignment: .leading, spacing: 1) {
                Text(thread.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(thread.aiProfile.status)
                    .font(.system(size: 13))
                    .foregroundStyle(thread.online ? TelegramPalette.skyBlue : TelegramPalette.mutedText)
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "paperclip")
                    .font(.system(size: 18))
                    .foregroundStyle(TelegramPalette.mutedText)

                TextField("Message", text: $draft)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .disabled(isSending)

                Button {
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(TelegramPalette.mutedText)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color.white.opacity(0.08), in: Capsule(style: .continuous))

            Button {
                Task {
                    await sendMessage()
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(canSend ? .white : Color.white.opacity(0.35))
            }
            .disabled(canSend == false)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .top) {
            if let errorText {
                Text(errorText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0xFFB4AE))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0x521717), in: Capsule(style: .continuous))
                    .padding(.top, -18)
            }
        }
    }

    private var chatBackground: some View {
        LinearGradient(
            colors: [Color(hex: 0x18181A), Color(hex: 0x0C0C0D)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            VStack {
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 280, height: 280)
                    .offset(x: 120, y: 80)
            }
        }
    }

    private var canSend: Bool {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && isSending == false
    }

    @MainActor
    private func sendMessage() async {
        let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedDraft.isEmpty == false else { return }

        errorText = nil
        draft = ""
        isSending = true
        let historyBeforeRequest = messages

        let outgoingMessage = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .text(trimmedDraft),
            time: currentTimeLabel
        )
        messages.append(outgoingMessage)

        do {
            let reply: String
            if aiWorkspace.isConfigured {
                reply = try await openRouterService.sendMessage(
                    draft: trimmedDraft,
                    thread: thread,
                    history: historyBeforeRequest,
                    configuration: aiWorkspace.configurationSnapshot
                )
            } else {
                reply = offlineFallbackReply(for: trimmedDraft)
                errorText = "OpenRouter is not connected yet. This reply uses the built-in offline fallback."
            }

            messages.append(
                ConversationMessage(
                    id: UUID().uuidString,
                    side: .incoming,
                    payload: .text(reply),
                    time: currentTimeLabel
                )
            )
        } catch {
            errorText = error.localizedDescription
            messages.append(
                ConversationMessage(
                    id: UUID().uuidString,
                    side: .incoming,
                    payload: .text(offlineFallbackReply(for: trimmedDraft)),
                    time: currentTimeLabel
                )
            )
        }

        isSending = false
    }

    private func offlineFallbackReply(for draft: String) -> String {
        switch thread.id {
        case "research-desk":
            return "Быстро разложу это на 3 части: цель, варианты и критерии выбора. Если хочешь, следующим сообщением сделаю короткое сравнение именно по твоему запросу: \(draft)"
        case "product-coach":
            return "Если смотреть как на продуктовый диалог, я бы уточнил у пользователя цель и потом упростил бы сценарий. Могу сразу предложить новый UX-вариант для: \(draft)"
        case "code-partner":
            return "Похоже на задачу, где лучше сначала определить входные данные, желаемое поведение и крайние случаи. Если хочешь, я распишу решение по шагам для: \(draft)"
        case "study-room":
            return "Давай упростим это до понятного учебного объяснения. Могу разбить тему на шаги, мини-конспект или карточки по запросу: \(draft)"
        case "design-scout":
            return "Если это про интерфейс или визуал, я бы сначала посмотрел на иерархию, отступы и главный акцент. Могу сразу дать короткий дизайн-разбор для: \(draft)"
        default:
            return "Понял. Могу ответить коротко, подробно или в рабочем тоне этого контакта. Для живых ответов подключи OpenRouter в Settings -> AI Gateway."
        }
    }

    private var currentTimeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

private struct MessageBubble: View {
    let message: ConversationMessage

    var body: some View {
        HStack {
            if message.side == .outgoing {
                Spacer(minLength: 40)
            }

            content
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if message.side == .incoming {
                Spacer(minLength: 40)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.payload {
        case let .text(text):
            VStack(alignment: .trailing, spacing: 6) {
                Text(text)
                    .font(.system(size: 17))
                    .foregroundStyle(foregroundColor)

                Text(message.time)
                    .font(.system(size: 11))
                    .foregroundStyle(foregroundColor.opacity(0.7))
            }
        case let .emoji(value):
            VStack(alignment: .trailing, spacing: 6) {
                Text(value)
                    .font(.system(size: 34))

                Text(message.time)
                    .font(.system(size: 11))
                    .foregroundStyle(foregroundColor.opacity(0.7))
            }
        case let .photo(name, size):
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x8556FF), Color(hex: 0x2F7CFF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 96)
                    .overlay {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.system(size: 15, weight: .medium))
                        Text(size)
                            .font(.system(size: 13))
                            .opacity(0.7)
                    }

                    Spacer()

                    Text(message.time)
                        .font(.system(size: 11))
                        .opacity(0.7)
                }
                .foregroundStyle(foregroundColor)
            }
        }
    }

    private var foregroundColor: Color {
        message.side == .outgoing ? .white : Color.black
    }

    private var backgroundColor: Color {
        message.side == .outgoing ? Color(hex: 0x0A84FF) : Color.white
    }
}

private struct TypingBubble: View {
    @State private var phase = 0

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Circle()
                        .fill(Color.black.opacity(0.42))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == index ? 1.1 : 0.82)
                        .animation(.easeInOut(duration: 0.35), value: phase)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 40)
        }
        .task {
            while true {
                try? await Task.sleep(nanoseconds: 280_000_000)
                phase = (phase + 1) % 3
            }
        }
    }
}

struct ChatModalPreviewScreen: View {
    let threads: [ChatThread]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TelegramPalette.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)

                Text("Chat Modal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Базовая версия экрана с действиями над чатом из концепта.")
                    .font(.system(size: 15))
                    .foregroundStyle(TelegramPalette.mutedText)
                    .multilineTextAlignment(.center)

                if let featured = threads.first {
                    HStack(spacing: 10) {
                        AvatarView(kind: featured.avatar, showsOnlineDot: featured.online)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(featured.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(featured.headline)
                                .font(.system(size: 15))
                                .foregroundStyle(TelegramPalette.mutedText)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                VStack(spacing: 0) {
                    modalRow("Pin Chat", symbol: "pin.fill", tint: TelegramPalette.successGreen)
                    modalDivider
                    modalRow("Mute Notifications", symbol: "bell.slash.fill", tint: TelegramPalette.warningOrange)
                    modalDivider
                    modalRow("Delete Conversation", symbol: "trash.fill", tint: TelegramPalette.destructiveRed)
                    modalDivider
                    modalRow("Archive", symbol: "archivebox.fill", tint: .white)
                }
                .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button("Close") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .presentationDetents([.fraction(0.72)])
        .presentationDragIndicator(.hidden)
    }

    private func modalRow(_ title: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    private var modalDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }
}

struct ChatConversationScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChatConversationScreen(thread: ChatThread.sampleThreads[0])
    }
}
