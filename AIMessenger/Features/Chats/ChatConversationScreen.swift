import SwiftUI
import PhotosUI

struct MediaItem: Identifiable {
    var id: String { name }
    let name: String
}

struct ChatConversationScreen: View {
    let thread: ChatThread

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var draft = ""
    @State private var messages: [ConversationMessage] = []
    @State private var isSending = false
    @State private var currentTypingBotName: String?
    @State private var isCallPresented = false
    @State private var showAttachmentSheet = false
    @State private var selectedMediaName: String?
    @State private var isStickerSheetPresented = false
    @State private var showWidgetPickerSheet = false
    @State private var inputMediaMode: InputMediaMode = .voice
    @State private var isRecordingVoice = false
    @State private var isRecordingVideoNote = false
    @State private var recordingSeconds = 0
    @State private var recordDotBlink = false
    @State private var recordingTimer: Task<Void, Never>?
    @State private var errorText: String?
    @ObservedObject private var audioRecorder = AudioRecordingManager.shared
    @ObservedObject private var videoRecorder = VideoNoteRecordingManager.shared
    private let openRouterService = OpenRouterService()

    enum InputMediaMode {
        case voice
        case video
    }

    init(thread: ChatThread) {
        self.thread = thread
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ChatDatePill(title: "Today")

                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            thread: thread,
                            isGroupThread: thread.isGroup,
                            onReact: { emoji in
                                aiWorkspace.addReaction(emoji: emoji, to: message.id, in: thread)
                                messages = aiWorkspace.messages(for: thread)
                            },
                            onDelete: {
                                withAnimation {
                                    aiWorkspace.deleteMessage(messageId: message.id, in: thread)
                                    messages = aiWorkspace.messages(for: thread)
                                }
                            },
                            onTranscribe: {
                                aiWorkspace.transcribeMessage(id: message.id, in: thread)
                                messages = aiWorkspace.messages(for: thread)
                            },
                            onOpenMedia: { mediaName in
                                selectedMediaName = mediaName
                            }
                        )
                        .id(message.id)
                    }

                    if isSending {
                        TypingBubble(authorName: currentTypingBotName)
                            .id("typingBubble")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
        }
        .scrollContentBackground(.hidden)
        .background(chatWallpaperView.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .task {
            loadConversationIfNeeded()
        }
        .onReceive(aiWorkspace.objectWillChange) { _ in
            DispatchQueue.main.async {
                messages = aiWorkspace.messages(for: thread)
            }
        }
        .overlay {
            if isRecordingVideoNote {
                VideoNoteRecordingOverlay(
                    duration: videoRecorder.durationString,
                    onCancel: { cancelRecordingVideo() },
                    onSend: { finishRecordingVideo() }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-showAttachment") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showAttachmentSheet = true
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-showWidgetPicker") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showWidgetPickerSheet = true
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testTranscribe") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if let msg = messages.first(where: { $0.isTranscribable }) {
                        aiWorkspace.transcribeMessage(id: msg.id, in: thread)
                        messages = aiWorkspace.messages(for: thread)
                    }
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testTranscribeVideo") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if let msg = messages.first(where: { $0.isVideoNote }) {
                        aiWorkspace.transcribeMessage(id: msg.id, in: thread)
                        messages = aiWorkspace.messages(for: thread)
                    }
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testRecording") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    startRecordingVoice()
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testRecordingAndSend") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startRecordingVoice()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        finishRecordingVoice()
                    }
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testSendPhoto") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    aiWorkspace.sendPhoto(name: "Wireframe_Screen.png", size: "2.4 MB", localFileName: "Wireframe_Screen.png", to: thread)
                    messages = aiWorkspace.messages(for: thread)
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testVideoRecording") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startRecordingVideo()
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testVideoRecordAndSend") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startRecordingVideo()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        finishRecordingVideo()
                    }
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-testSendWidget") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    aiWorkspace.sendInteractiveWidget(.sampleMetricsWidget(), to: thread)
                    messages = aiWorkspace.messages(for: thread)
                }
            }
        }
        .sheet(isPresented: $showAttachmentSheet) {
            AttachmentPickerSheet(
                onSendPhoto: { name, size in
                    aiWorkspace.sendPhoto(name: name, size: size, localFileName: name, to: thread)
                    messages = aiWorkspace.messages(for: thread)
                },
                onSendFile: { name, size in
                    aiWorkspace.sendAttachment(name: name, size: size, to: thread)
                    messages = aiWorkspace.messages(for: thread)
                },
                onOpenWidgetPicker: {
                    showWidgetPickerSheet = true
                }
            )
        }
        .sheet(isPresented: $showWidgetPickerSheet) {
            WidgetPickerSheet { widget in
                aiWorkspace.sendInteractiveWidget(widget, to: thread)
                messages = aiWorkspace.messages(for: thread)
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedMediaName.map { MediaItem(name: $0) } },
            set: { selectedMediaName = $0?.name }
        )) { item in
            MediaViewerModal(name: item.name)
        }
        .fullScreenCover(isPresented: $isCallPresented) {
            TelegramCallView(
                contactName: thread.title,
                avatar: thread.avatar,
                roleTitle: thread.aiProfile.roleTitle,
                greetingText: thread.aiProfile.greeting
            )
        }
        .sheet(isPresented: $isStickerSheetPresented) {
            StickerEmojiSheet { name, emoji in
                aiWorkspace.sendSticker(name: name, emoji: emoji, to: thread)
                messages = aiWorkspace.messages(for: thread)
            }
        }
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

                if isSending {
                    HStack(spacing: 2) {
                        Text(currentTypingBotName != nil ? "\(currentTypingBotName!) is typing" : "typing")
                            .font(.system(size: 13))
                            .foregroundStyle(TelegramPalette.skyBlue)
                        TypingHeaderDots()
                    }
                } else {
                    Text(thread.isGroup ? thread.memberNamesText : thread.aiProfile.status)
                        .font(.system(size: 13))
                        .foregroundStyle(thread.online ? TelegramPalette.skyBlue : TelegramPalette.mutedText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                isCallPresented = true
            } label: {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }

            Menu {
                Button {
                    aiWorkspace.togglePin(for: thread)
                } label: {
                    Label(thread.isPinned ? "Unpin Chat" : "Pin Chat", systemImage: thread.isPinned ? "pin.slash" : "pin")
                }

                Button {
                    aiWorkspace.toggleMute(for: thread)
                } label: {
                    Label(thread.isMuted ? "Unmute" : "Mute Notifications", systemImage: thread.isMuted ? "bell" : "bell.slash")
                }

                Divider()

                Button(role: .destructive) {
                    aiWorkspace.deleteThread(thread)
                    dismiss()
                } label: {
                    Label("Delete Chat", systemImage: "trash")
                }
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
        HStack(spacing: 8) {
            if isRecordingVoice {
                recordingInputBar
            } else {
                normalInputBar
            }
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

    private var recordingInputBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: 0xFF3B30))
                    .frame(width: 10, height: 10)
                    .opacity(recordDotBlink ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: recordDotBlink)

                Text(String(format: "0:%02d", recordingSeconds))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 3) {
                ForEach(0..<audioRecorder.waveformLevels.count, id: \.self) { idx in
                    let level = audioRecorder.waveformLevels[idx]
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(TelegramPalette.skyBlue)
                        .frame(width: 2.5, height: max(6, level * 26))
                        .animation(.easeInOut(duration: 0.08), value: level)
                }
            }
            .frame(height: 24)

            Spacer()

            Button {
                cancelRecordingVoice()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Cancel")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TelegramPalette.mutedText)
            }

            Button {
                finishRecordingVoice()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(TelegramPalette.skyBlue)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(Color.white.opacity(0.12), in: Capsule(style: .continuous))
    }

    private var normalInputBar: some View {
        Group {
            HStack(spacing: 8) {
                Button {
                    showAttachmentSheet = true
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 19))
                        .foregroundStyle(TelegramPalette.mutedText)
                }

                TextField("Message", text: $draft)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .disabled(isSending)

                Button {
                    isStickerSheetPresented = true
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundStyle(TelegramPalette.mutedText)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color.white.opacity(0.08), in: Capsule(style: .continuous))

            if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    if inputMediaMode == .voice {
                        startRecordingVoice()
                    } else {
                        handleMediaTap()
                    }
                } label: {
                    Image(systemName: inputMediaMode == .voice ? "mic.fill" : "camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            inputMediaMode == .voice ? TelegramPalette.skyBlue : Color(hex: 0x30B0C7),
                            in: Circle()
                        )
                }
                .contextMenu {
                    Button {
                        startRecordingVoice()
                    } label: {
                        Label("Record Voice Message", systemImage: "mic.fill")
                    }

                    Button {
                        startRecordingVideo()
                    } label: {
                        Label("Record Video Note (Кружочек)", systemImage: "camera.circle.fill")
                    }

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            inputMediaMode = (inputMediaMode == .voice ? .video : .voice)
                        }
                    } label: {
                        Label(inputMediaMode == .voice ? "Switch to Video" : "Switch to Voice", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            } else {
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
        }
    }

    private func startRecordingVoice() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        audioRecorder.requestMicrophonePermission { _ in }
        _ = audioRecorder.startRecording()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isRecordingVoice = true
            recordingSeconds = 0
            recordDotBlink = true
        }
        recordingTimer?.cancel()
        recordingTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                await MainActor.run {
                    recordingSeconds += 1
                }
            }
        }
    }

    private func cancelRecordingVoice() {
        recordingTimer?.cancel()
        recordingTimer = nil
        audioRecorder.cancelRecording()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isRecordingVoice = false
            recordingSeconds = 0
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func finishRecordingVoice() {
        recordingTimer?.cancel()
        recordingTimer = nil
        let result = audioRecorder.stopRecording()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isRecordingVoice = false
            recordingSeconds = 0
        }
        let durationText = result?.duration ?? String(format: "0:%02d", max(1, recordingSeconds))
        let filename = result?.filename
        aiWorkspace.sendVoiceMessage(duration: durationText, filename: filename, to: thread)
        messages = aiWorkspace.messages(for: thread)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func handleMediaTap() {
        if inputMediaMode == .voice {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                inputMediaMode = .video
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            startRecordingVideo()
        }
    }

    private func startRecordingVideo() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            _ = await videoRecorder.requestCameraPermission()
            _ = await videoRecorder.startRecording()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isRecordingVideoNote = true
            }
        }
    }

    private func cancelRecordingVideo() {
        videoRecorder.cancelRecording()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isRecordingVideoNote = false
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func finishRecordingVideo() {
        Task {
            let result = await videoRecorder.stopRecording()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isRecordingVideoNote = false
            }
            if let res = result {
                aiWorkspace.sendVideoNote(duration: res.duration, filename: res.filename, to: thread)
                messages = aiWorkspace.messages(for: thread)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    @ViewBuilder
    private var chatWallpaperView: some View {
        switch aiWorkspace.selectedWallpaper {
        case .doodles:
            TelegramDoodleWallpaper()
        case .obsidian:
            Color.black
        case .neon:
            ZStack {
                Color(hex: 0x050518)
                RadialGradient(
                    colors: [Color(hex: 0x0066FF).opacity(0.28), Color.clear],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 450
                )
            }
        case .sunset:
            LinearGradient(
                colors: [Color(hex: 0x240A22), Color(hex: 0x0E030E)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .emerald:
            ZStack {
                Color(hex: 0x04130A)
                RadialGradient(
                    colors: [Color(hex: 0x00E676).opacity(0.18), Color.clear],
                    center: .bottomLeading,
                    startRadius: 50,
                    endRadius: 460
                )
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
        persistMessages()

        do {
            let reply: String
            if aiWorkspace.isConfigured {
                reply = try await openRouterService.sendMessage(
                    draft: trimmedDraft,
                    thread: thread,
                    history: historyBeforeRequest,
                    memoryNote: aiWorkspace.memoryNote(for: thread),
                    configuration: aiWorkspace.configurationSnapshot
                )
            } else {
                reply = offlineFallbackReply(for: trimmedDraft)
                errorText = "OpenRouter is not connected yet. This reply uses the built-in offline fallback."
            }

            let incoming = incomingMessages(from: reply)
            if thread.isGroup && incoming.count > 1 {
                for (idx, msg) in incoming.enumerated() {
                    currentTypingBotName = msg.authorName ?? "Agent"
                    try? await Task.sleep(nanoseconds: idx == 0 ? 1_000_000_000 : 1_500_000_000)
                    messages.append(msg)
                    persistMessages()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                if let author = incoming.first?.authorName {
                    currentTypingBotName = author
                }
                try? await Task.sleep(nanoseconds: 750_000_000)
                messages.append(contentsOf: incoming)
                persistMessages()
            }
        } catch {
            errorText = error.localizedDescription
            messages.append(contentsOf: incomingMessages(from: offlineFallbackReply(for: trimmedDraft)))
            persistMessages()
        }

        currentTypingBotName = nil
        isSending = false
    }

    private func sendVoiceNote() {
        aiWorkspace.sendVoiceMessage(duration: "0:04", to: thread)
        messages = aiWorkspace.messages(for: thread)
    }

    @MainActor
    private func loadConversationIfNeeded() {
        aiWorkspace.ensureConversationExists(for: thread)
        if messages.isEmpty {
            messages = aiWorkspace.messages(for: thread)
        }
    }

    @MainActor
    private func persistMessages() {
        aiWorkspace.replaceMessages(messages, for: thread)
    }

    private func offlineFallbackReply(for draft: String) -> String {
        switch thread.id {
        case "seminar-circle":
            return """
            [Study Room] Могу быстро разложить это на понятный конспект и 5 карточек для повторения: \(draft)
            [Research Desk] Если хочешь, следом добавлю короткое сравнение источников и что лучше цитировать в работе.
            """
        case "build-board":
            return """
            [Code Partner] Для начала я бы сузил задачу: входные данные, ожидаемый результат и где именно ломается сценарий для \(draft).
            [Product Coach] После этого можно сразу решить, что упростить в пользовательском потоке, чтобы проблема не возвращалась.
            """
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
        case "memory-vault":
            return "📌 Сохранил заметку в Memory Vault: \"\(draft)\". Она зафиксирована в локальной памяти диалогов."
        default:
            return "Понял. Могу ответить коротко, подробно или в рабочем тоне этого контакта. Для живых ответов подключи OpenRouter в Settings -> AI Gateway."
        }
    }

    private var currentTimeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    private func incomingMessages(from reply: String) -> [ConversationMessage] {
        let trimmedReply = reply.trimmingCharacters(in: .whitespacesAndNewlines)

        if thread.isGroup {
            let parsed = parseGroupReply(trimmedReply)
            if parsed.isEmpty == false {
                return parsed
            }

            if let defaultMember = thread.members.first {
                return [
                    ConversationMessage(
                        id: UUID().uuidString,
                        side: .incoming,
                        payload: .text(trimmedReply),
                        time: currentTimeLabel,
                        authorName: defaultMember.name,
                        authorAvatar: defaultMember.avatar
                    )
                ]
            }
        }

        return [
            ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .text(trimmedReply),
                time: currentTimeLabel
            )
        ]
    }

    private func parseGroupReply(_ reply: String) -> [ConversationMessage] {
        let lines = reply
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        return lines.compactMap { line in
            guard line.hasPrefix("["),
                  let closingIndex = line.firstIndex(of: "]") else {
                return nil
            }

            let name = String(line[line.index(after: line.startIndex) ..< closingIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let contentStart = line.index(after: closingIndex)
            let content = String(line[contentStart...]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard content.isEmpty == false else { return nil }

            let member = thread.members.first { candidate in
                candidate.name.caseInsensitiveCompare(name) == .orderedSame
            } ?? thread.members.first

            return ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .text(content),
                time: currentTimeLabel,
                authorName: member?.name ?? name,
                authorAvatar: member?.avatar
            )
        }
    }
}

private struct MessageBubble: View {
    let message: ConversationMessage
    let thread: ChatThread
    let isGroupThread: Bool
    let onReact: (String) -> Void
    let onDelete: () -> Void
    let onTranscribe: () -> Void
    let onOpenMedia: (String) -> Void

    var body: some View {
        HStack {
            if message.side == .outgoing {
                Spacer(minLength: 40)
            }

            switch message.payload {
            case let .videoNote(duration):
                VideoNoteBubble(
                    duration: duration,
                    time: message.time,
                    isOutgoing: message.side == .outgoing,
                    localFileName: message.localFileName,
                    transcription: message.transcription,
                    isTranscribing: message.isTranscribing,
                    isTranscribed: message.isTranscribed,
                    onTranscribe: onTranscribe,
                    onReact: onReact,
                    onDelete: onDelete
                )
            case let .widget(widget):
                InteractiveWidgetBubble(
                    widget: widget,
                    time: message.time,
                    isOutgoing: message.side == .outgoing,
                    thread: thread
                )
            case let .sticker(name, emoji):
                StickerBubble(
                    name: name,
                    emoji: emoji,
                    time: message.time,
                    isOutgoing: message.side == .outgoing,
                    onReact: onReact,
                    onDelete: onDelete
                )
            case let .photo(name, size):
                PhotoMessageBubble(
                    name: name,
                    size: size,
                    time: message.time,
                    isOutgoing: message.side == .outgoing,
                    localFileName: message.localFileName,
                    onTap: { onOpenMedia(message.localFileName ?? name) }
                )
                .contextMenu {
                    Button {
                        onReact("❤️")
                    } label: {
                        Label("Heart ❤️", systemImage: "heart")
                    }
                    Button {
                        onReact("🔥")
                    } label: {
                        Label("Fire 🔥", systemImage: "flame")
                    }
                    Divider()
                    Button {
                        onOpenMedia(name)
                    } label: {
                        Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            default:
                content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .padding(.trailing, message.side == .outgoing ? 5 : 0)
                    .padding(.leading, message.side == .incoming ? 5 : 0)
                    .background(backgroundColor, in: TelegramBubbleShape(isOutgoing: message.side == .outgoing))
                    .contextMenu {
                        Button {
                            onReact("👍")
                        } label: {
                            Label("Like 👍", systemImage: "hand.thumbsup")
                        }
                        Button {
                            onReact("❤️")
                        } label: {
                            Label("Heart ❤️", systemImage: "heart")
                        }
                        Button {
                            onReact("🔥")
                        } label: {
                            Label("Fire 🔥", systemImage: "flame")
                        }
                        Button {
                            onReact("🎉")
                        } label: {
                            Label("Party 🎉", systemImage: "party.popper")
                        }
                        Divider()
                        Button {
                            if case let .text(txt) = message.payload {
                                UIPasteboard.general.string = txt
                            }
                        } label: {
                            Label("Copy Text", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Message", systemImage: "trash")
                        }
                    }
            }

            if message.side == .incoming {
                Spacer(minLength: 40)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: message.side == .outgoing ? .trailing : .leading, spacing: 6) {
            if isGroupThread, message.side == .incoming, let authorName = message.authorName {
                Text(authorName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(authorTint)
            }

            payloadContent

            if message.reactions.isEmpty == false {
                HStack(spacing: 4) {
                    ForEach(message.reactions, id: \.self) { reaction in
                        Text(reaction)
                            .font(.system(size: 13))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.18), in: Capsule())
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private var payloadContent: some View {
        switch message.payload {
        case let .text(text):
            VStack(alignment: message.side == .outgoing ? .trailing : .leading, spacing: 5) {
                Text(text)
                    .font(.system(size: 17))
                    .foregroundStyle(foregroundColor)

                HStack(spacing: 3) {
                    Text(message.time)
                        .font(.system(size: 11))

                    if message.side == .outgoing {
                        HStack(spacing: -3) {
                            Image(systemName: "checkmark")
                            Image(systemName: "checkmark")
                        }
                        .font(.system(size: 9, weight: .bold))
                    }
                }
                .foregroundStyle(foregroundColor.opacity(0.75))
            }
        case let .voice(duration):
            VoiceMessageBubble(
                messageId: message.id,
                duration: duration,
                time: message.time,
                isOutgoing: message.side == .outgoing,
                foregroundColor: foregroundColor,
                transcription: message.transcription,
                isTranscribing: message.isTranscribing,
                isTranscribed: message.isTranscribed,
                audioFileName: message.audioFileName,
                onTranscribe: onTranscribe
            )
        case let .emoji(value):
            VStack(alignment: message.side == .outgoing ? .trailing : .leading, spacing: 5) {
                Text(value)
                    .font(.system(size: 34))

                HStack(spacing: 3) {
                    Text(message.time)
                        .font(.system(size: 11))

                    if message.side == .outgoing {
                        HStack(spacing: -3) {
                            Image(systemName: "checkmark")
                            Image(systemName: "checkmark")
                        }
                        .font(.system(size: 9, weight: .bold))
                    }
                }
                .foregroundStyle(foregroundColor.opacity(0.75))
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
        case .videoNote, .sticker, .widget:
            EmptyView()
        }
    }

    private var foregroundColor: Color {
        message.side == .outgoing ? .white : Color.black
    }

    private var backgroundColor: Color {
        message.side == .outgoing ? Color(hex: 0x0A84FF) : Color.white
    }

    private var authorTint: Color {
        switch message.authorAvatar {
        case .saved:
            return Color(hex: 0x1F8CFF)
        case .visionCluster:
            return Color(hex: 0x7DD3FC)
        case .tutor:
            return Color(hex: 0xC969FF)
        case .uxCopilot:
            return Color(hex: 0xFF9D42)
        case .researchBot:
            return Color(hex: 0x8A5BFF)
        case .artEngine:
            return Color(hex: 0x466DFF)
        case .codeAgents:
            return Color(hex: 0x3C72FF)
        case .seminarCircle:
            return Color(hex: 0x2F8FFF)
        case .buildBoard:
            return Color(hex: 0xFF8A57)
        case .none:
            return Color(hex: 0x3578F6)
        }
    }
}

private struct TypingBubble: View {
    var authorName: String? = nil
    @State private var phase = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let authorName {
                    Text(authorName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TelegramPalette.accentBlue)
                }

                HStack(spacing: 6) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Circle()
                            .fill(Color.black.opacity(0.42))
                            .frame(width: 7, height: 7)
                            .scaleEffect(phase == index ? 1.1 : 0.82)
                            .animation(.easeInOut(duration: 0.35), value: phase)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .padding(.leading, 4)
            .background(Color.white, in: TelegramBubbleShape(isOutgoing: false))

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

private struct TypingHeaderDots: View {
    @State private var dotCount = 1

    var body: some View {
        Text(String(repeating: ".", count: dotCount))
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(TelegramPalette.skyBlue)
            .task {
                while true {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    dotCount = (dotCount % 3) + 1
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
            .environmentObject(AIWorkspace())
    }
}

struct ChatDatePill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.38), in: Capsule())
            .padding(.vertical, 4)
    }
}

struct TelegramDoodleWallpaper: View {
    private let doodleIcons: [[String]] = [
        ["paperplane.fill", "sparkles", "heart.fill", "cup.and.saucer.fill"],
        ["chevron.left.forwardslash.chevron.right", "star.fill", "music.note", "bolt.fill"],
        ["bubble.left.fill", "globe.europe.africa.fill", "gearshape.fill", "pawprint.fill"],
        ["gamecontroller.fill", "lock.fill", "camera.fill", "headphones"]
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x161618), Color(hex: 0x0E0E0F)],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryReader { geometry in
                let columns = 4
                let rows = Int(geometry.size.height / 75) + 2
                let cellWidth = geometry.size.width / CGFloat(columns)
                let cellHeight: CGFloat = 75

                VStack(spacing: 0) {
                    ForEach(0 ..< rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0 ..< columns, id: \.self) { col in
                                let iconName = doodleIcons[row % doodleIcons.count][col % doodleIcons[0].count]
                                Image(systemName: iconName)
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundStyle(Color.white.opacity(0.045))
                                    .rotationEffect(.degrees((col % 2 == 0) ? -12 : 12))
                                    .frame(width: cellWidth, height: cellHeight)
                            }
                        }
                    }
                }
            }
        }
        .drawingGroup()
    }
}

struct TelegramBubbleShape: Shape {
    let isOutgoing: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 17
        let tailSize: CGFloat = 6

        var p = Path()

        if isOutgoing {
            p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - r - tailSize, y: rect.minY))
            p.addArc(
                center: CGPoint(x: rect.maxX - r - tailSize, y: rect.minY + r),
                radius: r,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - 10))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.maxX - tailSize + 1, y: rect.maxY - 2)
            )
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX - tailSize - 5, y: rect.maxY),
                control: CGPoint(x: rect.maxX - 2, y: rect.maxY)
            )
            p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            p.addArc(
                center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            p.addArc(
                center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
            p.closeSubpath()
        } else {
            p.move(to: CGPoint(x: rect.minX + r + tailSize, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            p.addArc(
                center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                radius: r,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            p.addArc(
                center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                radius: r,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: rect.minX + tailSize + 5, y: rect.maxY))
            p.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY),
                control: CGPoint(x: rect.minX + 2, y: rect.maxY)
            )
            p.addQuadCurve(
                to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - 10),
                control: CGPoint(x: rect.minX + tailSize - 1, y: rect.maxY - 2)
            )
            p.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.minY + r))
            p.addArc(
                center: CGPoint(x: rect.minX + r + tailSize, y: rect.minY + r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
            p.closeSubpath()
        }

        return p
    }
}

private struct VoiceMessageBubble: View {
    let messageId: String
    let duration: String
    let time: String
    let isOutgoing: Bool
    let foregroundColor: Color
    let transcription: String?
    let isTranscribing: Bool
    let isTranscribed: Bool
    let audioFileName: String?
    let onTranscribe: () -> Void

    @ObservedObject private var playbackManager = AudioPlaybackManager.shared
    @State private var animatedHeights: [CGFloat] = [10, 20, 14, 26, 12, 18, 8, 22, 16, 10, 14, 20, 12, 8]

    private var isPlayingThisMessage: Bool {
        playbackManager.isPlaying && playbackManager.currentPlayingID == messageId
    }

    private var currentProgress: CGFloat {
        isPlayingThisMessage ? playbackManager.playbackProgress : 0.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlayingThisMessage ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(foregroundColor)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.18), in: Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(0 ..< animatedHeights.count, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(
                                    CGFloat(idx) / CGFloat(animatedHeights.count) <= currentProgress ?
                                        foregroundColor : foregroundColor.opacity(0.4)
                                )
                                .frame(width: 2.5, height: animatedHeights[idx])
                                .animation(.easeInOut(duration: 0.15), value: animatedHeights[idx])
                        }
                    }
                    .frame(height: 28)

                    HStack(spacing: 4) {
                        Text(isPlayingThisMessage ? String(format: "0:%02d", Int(currentProgress * 5)) : duration)
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text(time)
                            .font(.system(size: 11))
                        if isOutgoing {
                            HStack(spacing: -3) {
                                Image(systemName: "checkmark")
                                Image(systemName: "checkmark")
                            }
                            .font(.system(size: 9, weight: .bold))
                        }
                    }
                    .foregroundStyle(foregroundColor.opacity(0.75))
                }

                Button {
                    onTranscribe()
                } label: {
                    Text("→A")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(isTranscribed ? Color.black : Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            isTranscribed ? Color.white : TelegramPalette.accentBlue,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }

            if isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.65)
                    Text("Transcribing speech...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(foregroundColor.opacity(0.8))
                }
                .padding(.top, 2)
            } else if isTranscribed, let text = transcription {
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(foregroundColor.opacity(0.18))
                        .frame(height: 0.5)
                    Text(text)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(foregroundColor.opacity(0.95))
                        .padding(.top, 2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(minWidth: 195)
    }

    private func togglePlayback() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        playbackManager.play(
            filename: audioFileName,
            fallbackText: transcription,
            messageID: messageId
        )
    }
}

private struct VideoNoteBubble: View {
    let duration: String
    let time: String
    let isOutgoing: Bool
    var localFileName: String? = nil
    let transcription: String?
    let isTranscribing: Bool
    let isTranscribed: Bool
    let onTranscribe: () -> Void
    let onReact: (String) -> Void
    let onDelete: () -> Void

    @State private var isPlaying = false
    @State private var progress: CGFloat = 0.0
    @State private var animationTimer: Task<Void, Never>?

    private var hasRealVideoFile: Bool {
        guard let fn = localFileName else { return false }
        return MediaStorageService.shared.fileExists(filename: fn)
    }

    var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    if let fn = localFileName, hasRealVideoFile {
                        CircularVideoPlayerView(
                            videoURL: MediaStorageService.shared.fileURL(for: fn),
                            isPlaying: $isPlaying,
                            progress: $progress,
                            onFinished: {
                                isPlaying = false
                                progress = 0.0
                            }
                        )
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: 0x1A2332),
                                        Color(hex: 0x0F172A),
                                        Color(hex: 0x1E293B)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        ZStack {
                            Image(systemName: isOutgoing ? "person.crop.circle.fill" : "sparkles")
                                .font(.system(size: 76))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: 0x60A5FA), Color(hex: 0xA855F7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(isPlaying ? 1.08 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPlaying)

                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.18), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }

                    if !isPlaying {
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 54, height: 54)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white)
                                    .offset(x: 2)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }

                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 3.5)
                        .frame(width: 196, height: 196)

                    Circle()
                        .trim(from: 0, to: isPlaying ? progress : 1.0)
                        .stroke(
                            LinearGradient(
                                colors: [TelegramPalette.skyBlue, Color(hex: 0x60A5FA)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 196, height: 196)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: progress)
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
                .onTapGesture {
                    togglePlayback()
                }

                // Top right corner →A transcribe button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onTranscribe()
                        } label: {
                            Text("→A")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(isTranscribed ? Color.black : Color.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(isTranscribed ? Color.white : TelegramPalette.accentBlue, in: Capsule())
                                .shadow(radius: 4)
                        }
                        .padding(8)
                    }
                    Spacer()
                }
                .frame(width: 200, height: 200)

                HStack(spacing: 4) {
                    if isPlaying {
                        Circle()
                            .fill(Color(hex: 0x34D399))
                            .frame(width: 6, height: 6)
                    }

                    Text(isPlaying ? String(format: "0:0%d", Int(progress * 4)) : duration)
                        .font(.system(size: 11, weight: .semibold))

                    Text(time)
                        .font(.system(size: 10))

                    if isOutgoing {
                        HStack(spacing: -3) {
                            Image(systemName: "checkmark")
                            Image(systemName: "checkmark")
                        }
                        .font(.system(size: 9, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.65), in: Capsule())
                .padding(6)
            }
            .contextMenu {
                Button {
                    onReact("❤️")
                } label: {
                    Label("Heart ❤️", systemImage: "heart")
                }
                Button {
                    onReact("🔥")
                } label: {
                    Label("Fire 🔥", systemImage: "flame")
                }
                Button {
                    onReact("👏")
                } label: {
                    Label("Clap 👏", systemImage: "hands.clap")
                }
                Divider()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Video Note", systemImage: "trash")
                }
            }

            if isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.65)
                    Text("Transcribing speech...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.7), in: Capsule())
            } else if isTranscribed, let text = transcription {
                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: 220, alignment: isOutgoing ? .trailing : .leading)
            }
        }
    }

    private func togglePlayback() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isPlaying.toggle()
        if !hasRealVideoFile {
            if isPlaying {
                progress = 0.0
                animationTimer?.cancel()
                animationTimer = Task {
                    for i in 1...20 {
                        guard isPlaying else { break }
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        withAnimation {
                            progress = CGFloat(i) / 20.0
                        }
                    }
                    isPlaying = false
                    progress = 0.0
                }
            } else {
                animationTimer?.cancel()
                progress = 0.0
            }
        }
    }
}

private struct StickerBubble: View {
    let name: String
    let emoji: String
    let time: String
    let isOutgoing: Bool
    let onReact: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 100))
                    .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
            }
            .frame(width: 130, height: 130)

            HStack(spacing: 3) {
                Text(time)
                    .font(.system(size: 10, weight: .medium))

                if isOutgoing {
                    HStack(spacing: -3) {
                        Image(systemName: "checkmark")
                        Image(systemName: "checkmark")
                    }
                    .font(.system(size: 8, weight: .bold))
                }
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.black.opacity(0.45), in: Capsule())
            .padding(4)
        }
        .contextMenu {
            Button {
                onReact("❤️")
            } label: {
                Label("Heart ❤️", systemImage: "heart")
            }
            Button {
                onReact("🔥")
            } label: {
                Label("Fire 🔥", systemImage: "flame")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Sticker", systemImage: "trash")
            }
        }
    }
}

private struct StickerEmojiSheet: View {
    let onSendSticker: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: StickerTab = .stickers

    enum StickerTab: String, CaseIterable, Identifiable {
        case stickers = "Stickers"
        case emoji = "Emoji"
        case gifs = "GIFs"

        var id: String { rawValue }
    }

    struct StickerItem: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
    }

    private let stickerPacks: [String: [StickerItem]] = [
        "AI Agent Essentials": [
            StickerItem(name: "Robot Joy", emoji: "🤖"),
            StickerItem(name: "Quantum Brain", emoji: "🧠"),
            StickerItem(name: "Cosmic Spark", emoji: "✨"),
            StickerItem(name: "Rocket Launch", emoji: "🚀"),
            StickerItem(name: "Lightning Fast", emoji: "⚡️"),
            StickerItem(name: "Fire Code", emoji: "🔥"),
            StickerItem(name: "Alien Intelligence", emoji: "👾"),
            StickerItem(name: "Celebration", emoji: "🎉")
        ],
        "AIGram Classics": [
            StickerItem(name: "Duck Cool", emoji: "🦆"),
            StickerItem(name: "Sunglasses", emoji: "😎"),
            StickerItem(name: "Mind Blown", emoji: "🤯"),
            StickerItem(name: "Heart Eyes", emoji: "😍"),
            StickerItem(name: "Thinking Deeply", emoji: "🧐"),
            StickerItem(name: "Super Thumbs Up", emoji: "👍"),
            StickerItem(name: "Magic Crystal", emoji: "🔮"),
            StickerItem(name: "Gem", emoji: "💎")
        ]
    ]

    private let emojisList: [String] = [
        "😀", "😃", "😄", "😁", "😆", "🥹", "😅", "😂", "🤣", "🥲", "☺️", "😊",
        "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋",
        "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🥸", "🤩", "🥳", "😏",
        "🔥", "💯", "✨", "💫", "⭐️", "🌟", "⚡️", "💥", "❤️", "🧡", "💛", "💚",
        "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖"
    ]

    private let gifItems: [(title: String, icon: String, color: Color)] = [
        ("LGTM Ship It", "shippingbox.fill", Color(hex: 0x10B981)),
        ("Code Compiling", "gearshape.arrow.triangle.2.circlepath", Color(hex: 0x3B82F6)),
        ("Thinking AI", "brain.head.profile", Color(hex: 0x8B5CF6)),
        ("Mind Blown", "bolt.fill", Color(hex: 0xF59E0B)),
        ("Celebration 100", "party.popper.fill", Color(hex: 0xEC4899)),
        ("Coffee Break", "cup.and.saucer.fill", Color(hex: 0x6366F1))
    ]

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)

            HStack(spacing: 8) {
                ForEach(StickerTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundStyle(selectedTab == tab ? .white : TelegramPalette.mutedText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(
                                selectedTab == tab ? Color.white.opacity(0.16) : Color.clear,
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(.bottom, 10)

            Divider()
                .background(TelegramPalette.separator)

            ScrollView(showsIndicators: false) {
                switch selectedTab {
                case .stickers:
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(stickerPacks.keys.sorted()), id: \.self) { packName in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(packName.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(TelegramPalette.mutedText)
                                    .padding(.horizontal, 16)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 16) {
                                    if let items = stickerPacks[packName] {
                                        ForEach(items) { item in
                                            Button {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                onSendSticker(item.name, item.emoji)
                                                dismiss()
                                            } label: {
                                                VStack(spacing: 4) {
                                                    Text(item.emoji)
                                                        .font(.system(size: 46))
                                                    Text(item.name)
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundStyle(.white.opacity(0.7))
                                                        .lineLimit(1)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 14)

                case .emoji:
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 16) {
                        ForEach(emojisList, id: \.self) { em in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onSendSticker("Emoji", em)
                                dismiss()
                            } label: {
                                Text(em)
                                    .font(.system(size: 34))
                                    .frame(width: 48, height: 48)
                            }
                        }
                    }
                    .padding(16)

                case .gifs:
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(gifItems, id: \.title) { item in
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onSendSticker(item.title, "🎬")
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 32))
                                        .foregroundStyle(item.color)
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 90)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(TelegramPalette.backgroundElevated.ignoresSafeArea())
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Photo Message Bubble
private struct PhotoMessageBubble: View {
    let name: String
    let size: String
    let time: String
    let isOutgoing: Bool
    let localFileName: String?
    let onTap: () -> Void

    @State private var loadedImage: UIImage?

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                if let loadedImage = loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 230, height: 160)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(photoGradient(for: name))
                        .frame(width: 230, height: 160)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: photoIcon(for: name))
                                    .font(.system(size: 44, weight: .light))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text(name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .padding(.horizontal, 16)
                                Text(size)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                }

                // Time & Checkmark overlay pill
                HStack(spacing: 4) {
                    Text(time)
                        .font(.system(size: 11, weight: .medium))

                    if isOutgoing {
                        HStack(spacing: -3) {
                            Image(systemName: "checkmark")
                            Image(systemName: "checkmark")
                        }
                        .font(.system(size: 9, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.55), in: Capsule())
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let filename = localFileName ?? name
        if let img = MediaStorageService.shared.loadImage(named: filename) {
            loadedImage = img
        }
    }

    private func photoIcon(for name: String) -> String {
        if name.contains("Architecture") { return "server.rack" }
        if name.contains("Wireframe") { return "rectangle.split.3x3" }
        if name.contains("Design") { return "paintbrush.pointed.fill" }
        if name.contains("Dashboard") { return "chart.bar.xaxis" }
        return "photo.fill"
    }

    private func photoGradient(for name: String) -> LinearGradient {
        if name.contains("Architecture") {
            return LinearGradient(colors: [Color(hex: 0x1E3A8A), Color(hex: 0x3B82F6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if name.contains("Wireframe") {
            return LinearGradient(colors: [Color(hex: 0x4C1D95), Color(hex: 0x8B5CF6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if name.contains("Design") {
            return LinearGradient(colors: [Color(hex: 0x831843), Color(hex: 0xEC4899)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [Color(hex: 0x064E3B), Color(hex: 0x10B981)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Fullscreen Media Viewer Modal
private struct MediaViewerModal: View {
    let name: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var loadedImage: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("AIGram Media")
                            .font(.system(size: 12))
                            .foregroundStyle(TelegramPalette.mutedText)
                    }

                    Spacer()

                    if let img = loadedImage {
                        ShareLink(item: Image(uiImage: img), preview: SharePreview(name, image: Image(uiImage: img))) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.12), in: Circle())
                        }
                    } else {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.12), in: Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // High-res preview container
                ZStack {
                    if let loadedImage = loadedImage {
                        Image(uiImage: loadedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 500)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0x1E293B), Color(hex: 0x0F172A)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 380)

                        VStack(spacing: 16) {
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 80, weight: .ultraLight))
                                .foregroundStyle(TelegramPalette.skyBlue)

                            Text(name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)

                            Text("High-Definition Asset Preview")
                                .font(.system(size: 14))
                                .foregroundStyle(TelegramPalette.mutedText)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { val in scale = val }
                        .onEnded { _ in withAnimation(.spring()) { scale = 1.0 } }
                )

                Spacer()

                // Bottom actions
                HStack(spacing: 40) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let img = loadedImage {
                            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 20))
                            Text("Save")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 20))
                            Text("Edit")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white)
                    }

                    Button {
                        dismiss()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                            Text("Delete")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(Color(hex: 0xFF453A))
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            loadedImage = MediaStorageService.shared.loadImage(named: name)
        }
    }
}

// MARK: - Attachment Picker Sheet
private struct AttachmentPickerSheet: View {
    let onSendPhoto: (String, String) -> Void
    let onSendFile: (String, String) -> Void
    var onOpenWidgetPicker: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoPickerItem: PhotosPickerItem?

    private let sampleGalleryPhotos: [(title: String, icon: String, color: Color)] = [
        ("Architecture_V2.png", "server.rack", Color(hex: 0x3B82F6)),
        ("Wireframe_Screen.png", "rectangle.split.3x3", Color(hex: 0x8B5CF6)),
        ("Design_Tokens.png", "paintbrush.pointed.fill", Color(hex: 0xEC4899)),
        ("Dashboard_Metrics.png", "chart.bar.xaxis", Color(hex: 0x10B981)),
        ("AI_Cluster_Map.png", "cpu.fill", Color(hex: 0xF59E0B)),
        ("Mobile_Mockup.png", "iphone", Color(hex: 0x06B6D4))
    ]

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            HStack {
                Text("Share Content")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(TelegramPalette.mutedText)
                }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("RECENT MEDIA")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TelegramPalette.mutedText)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sampleGalleryPhotos, id: \.title) { item in
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onSendPhoto(item.title, "1.8 MB")
                                dismiss()
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    if let img = MediaStorageService.shared.loadImage(named: item.title) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipped()
                                    } else {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(item.color.opacity(0.3))
                                            .frame(width: 110, height: 110)
                                            .overlay {
                                                Image(systemName: item.icon)
                                                    .font(.system(size: 32))
                                                    .foregroundStyle(item.color)
                                            }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 10, weight: .semibold))
                                            .lineLimit(1)
                                            .foregroundStyle(.white)
                                    }
                                    .padding(8)
                                    .frame(width: 110, alignment: .leading)
                                    .background(Color.black.opacity(0.65))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        PhotosPicker(selection: $selectedPhotoPickerItem, matching: .images) {
                            attachmentActionItem(title: "Gallery", icon: "photo.on.rectangle.angled", color: Color(hex: 0x0A84FF))
                        }
                        .onChange(of: selectedPhotoPickerItem) { newItem in
                            guard let newItem = newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    let filename = "User_Photo_\(Int.random(in: 100...999)).jpg"
                                    MediaStorageService.shared.saveImage(data: data, filename: filename)
                                    let sizeStr = MediaStorageService.shared.fileSizeString(for: filename)
                                    await MainActor.run {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        onSendPhoto(filename, sizeStr)
                                        dismiss()
                                    }
                                }
                            }
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSendFile("Spec_Sheet_v2.pdf", "4.2 MB")
                            dismiss()
                        } label: {
                            attachmentActionItem(title: "File", icon: "doc.fill", color: Color(hex: 0x30B0C7))
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onOpenWidgetPicker?()
                            }
                        } label: {
                            attachmentActionItem(title: "AI Widget", icon: "sparkles", color: Color(hex: 0xAF52DE))
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSendFile("San_Francisco_HQ.loc", "GPS Data")
                            dismiss()
                        } label: {
                            attachmentActionItem(title: "Location", icon: "location.fill", color: Color(hex: 0x34C759))
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSendFile("Team_Consensus_Vote.poll", "Active Poll")
                            dismiss()
                        } label: {
                            attachmentActionItem(title: "Poll", icon: "chart.bar.fill", color: Color(hex: 0xFF9500))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(350)])
        .background(TelegramPalette.backgroundElevated.ignoresSafeArea())
    }

    private func attachmentActionItem(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                }
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Video Note Recording Overlay
private struct VideoNoteRecordingOverlay: View {
    let duration: String
    let onCancel: () -> Void
    let onSend: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            VStack(spacing: 24) {
                // Top header: REC 0:03
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: 0xEF4444))
                        .frame(width: 10, height: 10)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulseScale)

                    Text("REC \(duration)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6), in: Capsule())

                // Circular Video Viewfinder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x1E293B), Color(hex: 0x0F172A)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Animated Camera Sensor Simulation
                    VStack(spacing: 12) {
                        Image(systemName: "video.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [TelegramPalette.skyBlue, Color(hex: 0x8B5CF6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(pulseScale)

                        Text("Live Sensor Active")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TelegramPalette.mutedText)
                    }

                    // Dynamic Pulsing Recording Ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: 0xEF4444), Color(hex: 0xF59E0B)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .scaleEffect(1.02)
                }
                .frame(width: 240, height: 240)
                .clipShape(Circle())
                .shadow(color: Color(hex: 0xEF4444).opacity(0.3), radius: 20)

                // Controls
                HStack(spacing: 48) {
                    Button {
                        onCancel()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.white.opacity(0.6))
                            Text("Discard")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }

                    Button {
                        onSend()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(TelegramPalette.accentBlue)
                            Text("Send Note")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            pulseScale = 1.08
        }
    }
}

// MARK: - Interactive Widget Bubble
private struct InteractiveWidgetBubble: View {
    let widget: InteractiveWidget
    let time: String
    let isOutgoing: Bool
    let thread: ChatThread

    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var activeTab: String = "Latency"
    @State private var isRunningCode: Bool = false
    @State private var consoleOutput: String? = nil
    @State private var currentStatus: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: widgetIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(widgetAccentColor)

                Text(widget.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(widget.subtitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(TelegramPalette.mutedText)
            }

            Divider()
                .background(Color.white.opacity(0.12))

            switch widget.kind {
            case .metricsChart:
                metricsContentView
            case .codeRunner:
                codeRunnerContentView
            case .kanbanTask:
                kanbanContentView
            }

            // Footer with time & checkmarks
            HStack {
                Text(currentStatus.isEmpty ? widget.currentStatus : currentStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(TelegramPalette.mutedText)

                Spacer()

                Text(time)
                    .font(.system(size: 10))
                    .foregroundStyle(TelegramPalette.mutedText)

                if isOutgoing {
                    HStack(spacing: -3) {
                        Image(systemName: "checkmark")
                        Image(systemName: "checkmark")
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(TelegramPalette.skyBlue)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: 310)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1A2234), Color(hex: 0x111827)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(widgetAccentColor.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
        .onAppear {
            currentStatus = widget.currentStatus
            if let tab = widget.selectedMetricTab {
                activeTab = tab
            }
        }
    }

    private var metricsContentView: some View {
        VStack(spacing: 10) {
            // Tabs
            HStack(spacing: 6) {
                ForEach(["Latency", "TPS", "Cache"], id: \.self) { tab in
                    Button {
                        activeTab = tab
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(tab)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(activeTab == tab ? widgetAccentColor : Color.white.opacity(0.08))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }

            // Animated Bar Graph
            HStack(alignment: .bottom, spacing: 12) {
                metricBar(label: "Groq", value: activeTab == "Latency" ? 0.35 : (activeTab == "TPS" ? 0.95 : 0.90), text: activeTab == "Latency" ? "38ms" : (activeTab == "TPS" ? "480" : "94%"))
                metricBar(label: "Qwen", value: activeTab == "Latency" ? 0.45 : (activeTab == "TPS" ? 0.50 : 0.85), text: activeTab == "Latency" ? "52ms" : (activeTab == "TPS" ? "120" : "88%"))
                metricBar(label: "GPT-4o", value: activeTab == "Latency" ? 0.70 : (activeTab == "TPS" ? 0.65 : 0.82), text: activeTab == "Latency" ? "140ms" : (activeTab == "TPS" ? "110" : "84%"))
                metricBar(label: "Sonnet", value: activeTab == "Latency" ? 0.85 : (activeTab == "TPS" ? 0.55 : 0.78), text: activeTab == "Latency" ? "190ms" : (activeTab == "TPS" ? "88" : "79%"))
            }
            .frame(height: 80)
            .padding(.top, 4)
        }
    }

    private func metricBar(label: String, value: Double, text: String) -> some View {
        VStack(spacing: 4) {
            Text(text)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)

            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [widgetAccentColor, TelegramPalette.skyBlue],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44, height: max(14, CGFloat(value) * 55))
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: value)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(TelegramPalette.mutedText)
        }
    }

    private var codeRunnerContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(widget.codeSnippet ?? "print(\"Running AIGram Sandbox...\")")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color(hex: 0x93C5FD))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                runSandboxCode()
            } label: {
                HStack(spacing: 6) {
                    if isRunningCode {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                        Text("Compiling & Executing...")
                            .font(.system(size: 12, weight: .semibold))
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text(consoleOutput == nil ? "Run In Sandbox" : "Re-Run Sandbox")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(TelegramPalette.accentBlue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(isRunningCode)

            if let out = consoleOutput {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle().fill(Color(hex: 0x10B981)).frame(width: 6, height: 6)
                        Text("Terminal Output (Exit 0)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: 0x10B981))
                    }
                    Text(out)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func runSandboxCode() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isRunningCode = true
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                isRunningCode = false
                consoleOutput = "> [Dispatcher] Thread pool initialized (4 workers)\n> [Bench] 1000 tasks isolated in 18.2ms\n> ✅ Success (0 memory leaks)"
                currentStatus = "Ran successfully (18ms)"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private var kanbanContentView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(["To Do", "In Progress", "Done"], id: \.self) { status in
                    Button {
                        currentStatus = status
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        aiWorkspace.updateWidgetState(widgetId: widget.id, newStatus: status, in: thread)
                    } label: {
                        Text(status)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(currentStatus == status ? statusColor(for: status) : Color.white.opacity(0.08))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "Done": return Color(hex: 0x10B981)
        case "In Progress": return TelegramPalette.accentBlue
        default: return Color(hex: 0xF59E0B)
        }
    }

    private var widgetIcon: String {
        switch widget.kind {
        case .metricsChart: return "chart.bar.xaxis"
        case .codeRunner: return "chevron.left.forwardslash.chevron.right"
        case .kanbanTask: return "checklist"
        }
    }

    private var widgetAccentColor: Color {
        switch widget.kind {
        case .metricsChart: return Color(hex: 0x38BDF8)
        case .codeRunner: return Color(hex: 0x34D399)
        case .kanbanTask: return Color(hex: 0xA78BFA)
        }
    }
}

// MARK: - Widget Picker Sheet
private struct WidgetPickerSheet: View {
    let onSelect: (InteractiveWidget) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            HStack {
                Text("AI Canvas & Mini-Apps")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(TelegramPalette.mutedText)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                widgetOptionRow(
                    title: "Telemetry & Metrics Chart",
                    desc: "Interactive latency and token throughput charts",
                    icon: "chart.bar.xaxis",
                    color: Color(hex: 0x38BDF8)
                ) {
                    onSelect(.sampleMetricsWidget())
                    dismiss()
                }

                widgetOptionRow(
                    title: "Code Runner Sandbox",
                    desc: "Interactive Swift 6 code execution with console",
                    icon: "chevron.left.forwardslash.chevron.right",
                    color: Color(hex: 0x34D399)
                ) {
                    onSelect(.sampleCodeRunnerWidget())
                    dismiss()
                }

                widgetOptionRow(
                    title: "Sprint Kanban Task Card",
                    desc: "Interactive task card with real-time status switches",
                    icon: "checklist",
                    color: Color(hex: 0xA78BFA)
                ) {
                    onSelect(.sampleKanbanWidget())
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.height(340)])
        .background(TelegramPalette.backgroundElevated.ignoresSafeArea())
    }

    private func widgetOptionRow(title: String, desc: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(color)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(TelegramPalette.mutedText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TelegramPalette.mutedText)
            }
            .padding(12)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
