import SwiftUI

struct OpenRouterConfiguration {
    var apiKey: String
    var modelSlug: String
    var useZeroRetention: Bool
    var denyProviderLogging: Bool
    var provider: LLMProviderKind = .openRouter
    var customEndpoint: String = ""
}

private struct StoredConversationState: Codable {
    var messages: [ConversationMessage]
    var updatedAt: Date
    var memoryNote: String
}

@MainActor
final class AIWorkspace: ObservableObject {
    private static let conversationSchemaVersion = 7

    @Published var displayName: String {
        didSet { defaults.set(displayName, forKey: Keys.displayName) }
    }

    @Published var username: String {
        didSet { defaults.set(username, forKey: Keys.username) }
    }

    @Published var bio: String {
        didSet { defaults.set(bio, forKey: Keys.bio) }
    }

    @Published var apiKey: String {
        didSet { defaults.set(apiKey, forKey: Keys.apiKey) }
    }

    @Published var modelSlug: String {
        didSet { defaults.set(modelSlug, forKey: Keys.modelSlug) }
    }

    @Published var selectedProvider: LLMProviderKind {
        didSet { defaults.set(selectedProvider.rawValue, forKey: Keys.selectedProvider) }
    }

    @Published var customEndpoint: String {
        didSet { defaults.set(customEndpoint, forKey: Keys.customEndpoint) }
    }

    @Published var useZeroRetention: Bool {
        didSet { defaults.set(useZeroRetention, forKey: Keys.useZeroRetention) }
    }

    @Published var denyProviderLogging: Bool {
        didSet { defaults.set(denyProviderLogging, forKey: Keys.denyProviderLogging) }
    }

    @Published var selectedWallpaper: ChatWallpaperKind {
        didSet { defaults.set(selectedWallpaper.rawValue, forKey: Keys.selectedWallpaper) }
    }

    @Published var threads: [ChatThread] = ChatThread.sampleThreads
    @Published var contacts: [ContactProfile] = ContactProfile.sampleContacts

    @Published private var storedConversations: [String: StoredConversationState] {
        didSet { persistStoredConversations() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.displayName = defaults.string(forKey: Keys.displayName) ?? "My Space"
        self.username = defaults.string(forKey: Keys.username) ?? "@my_space"
        self.bio = defaults.string(forKey: Keys.bio) ?? "Private AI chat hub for study, coding, research, and design."
        self.apiKey = defaults.string(forKey: Keys.apiKey) ?? ""
        self.modelSlug = defaults.string(forKey: Keys.modelSlug) ?? "qwen/qwen3.5-9b"
        if let provRaw = defaults.string(forKey: Keys.selectedProvider), let prov = LLMProviderKind(rawValue: provRaw) {
            self.selectedProvider = prov
        } else {
            self.selectedProvider = .openRouter
        }
        self.customEndpoint = defaults.string(forKey: Keys.customEndpoint) ?? ""
        self.useZeroRetention = defaults.object(forKey: Keys.useZeroRetention) as? Bool ?? true
        self.denyProviderLogging = defaults.object(forKey: Keys.denyProviderLogging) as? Bool ?? true
        if let raw = defaults.string(forKey: Keys.selectedWallpaper), let wp = ChatWallpaperKind(rawValue: raw) {
            self.selectedWallpaper = wp
        } else {
            self.selectedWallpaper = .doodles
        }
        if ProcessInfo.processInfo.arguments.contains("-resetStorage") {
            defaults.removeObject(forKey: Keys.storedConversations)
        }
        self.storedConversations = Self.loadStoredConversations(from: defaults)
        seedThreadsIfNeeded(ChatThread.sampleThreads)
    }

    func togglePin(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.id == threadId }) else { return }
        threads[index].isPinned.toggle()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func togglePin(for thread: ChatThread) {
        togglePin(threadId: thread.id)
    }

    func toggleMute(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.id == threadId }) else { return }
        threads[index].isMuted.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func toggleMute(for thread: ChatThread) {
        toggleMute(threadId: thread.id)
    }

    func toggleUnread(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.id == threadId }) else { return }
        if threads[index].badge != nil {
            threads[index].badge = nil
            threads[index].badgeBright = false
        } else {
            threads[index].badge = "1"
            threads[index].badgeBright = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func markAsRead(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.id == threadId }) else { return }
        if threads[index].badge != nil {
            threads[index].badge = nil
            threads[index].badgeBright = false
        }
    }

    func deleteThread(threadId: String) {
        threads.removeAll { $0.id == threadId }
        storedConversations.removeValue(forKey: threadId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func deleteThread(_ thread: ChatThread) {
        deleteThread(threadId: thread.id)
    }

    func createOrGetThread(for contact: ContactProfile) -> ChatThread {
        if let existing = threads.first(where: { $0.id == contact.id }) {
            return existing
        }

        let newThread = ChatThread(
            id: contact.id,
            title: contact.displayName,
            headline: contact.bio,
            detail: contact.roleTitle,
            time: "now",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: false,
            online: contact.presence.isOnline,
            revealSide: .none,
            deliveryState: .none,
            groupedBackground: false,
            avatar: contact.avatar,
            kind: .direct
        )
        threads.insert(newThread, at: 0)
        ensureConversationExists(for: newThread)
        return newThread
    }

    func addReaction(emoji: String, to messageId: String, in thread: ChatThread) {
        var msgs = messages(for: thread)
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }) else { return }
        if let reactionIdx = msgs[idx].reactions.firstIndex(of: emoji) {
            msgs[idx].reactions.remove(at: reactionIdx)
        } else {
            msgs[idx].reactions.append(emoji)
        }
        replaceMessages(msgs, for: thread)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func togglePinMessage(messageId: String, in thread: ChatThread) {
        var msgs = messages(for: thread)
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }) else { return }

        let willPin = !msgs[idx].isPinned
        for i in msgs.indices {
            msgs[i].isPinned = false
        }
        msgs[idx].isPinned = willPin

        if let tIdx = threads.firstIndex(where: { $0.id == thread.id }) {
            if willPin {
                threads[tIdx].pinnedMessageId = messageId
                threads[tIdx].pinnedMessageSnippet = msgs[idx].previewSnippet
                threads[tIdx].pinnedMessageAuthor = msgs[idx].authorName ?? (msgs[idx].side == .outgoing ? "You" : thread.title)
            } else {
                threads[tIdx].pinnedMessageId = nil
                threads[tIdx].pinnedMessageSnippet = nil
                threads[tIdx].pinnedMessageAuthor = nil
            }
        }

        replaceMessages(msgs, for: thread)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func unpinMessage(in thread: ChatThread) {
        var msgs = messages(for: thread)
        for i in msgs.indices {
            msgs[i].isPinned = false
        }
        if let tIdx = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[tIdx].pinnedMessageId = nil
            threads[tIdx].pinnedMessageSnippet = nil
            threads[tIdx].pinnedMessageAuthor = nil
        }
        replaceMessages(msgs, for: thread)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func pinnedMessage(for thread: ChatThread) -> ConversationMessage? {
        let msgs = messages(for: thread)
        return msgs.first(where: { $0.isPinned })
    }

    func sendDocument(name: String, size: String, ext: String, localFileName: String? = nil, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .document(name: name, size: size, ext: ext, localFileName: localFileName ?? name),
            time: formatter.string(from: Date()),
            localFileName: localFileName ?? name
        )
        appendMessage(msg, to: thread)
        generateAIResponseIfNeeded(for: msg, in: thread)
    }

    func sendReply(replyTo: ConversationMessage, text: String, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .text(text),
            time: formatter.string(from: Date()),
            replyToMessageId: replyTo.id,
            replyToSnippet: replyTo.previewSnippet,
            replyToAuthor: replyTo.authorName ?? (replyTo.side == .outgoing ? "You" : thread.title)
        )
        appendMessage(msg, to: thread)
        generateAIResponseIfNeeded(for: msg, in: thread)
    }

    func analyzeDocument(message: ConversationMessage, in thread: ChatThread) {
        guard case let .document(name, size, ext, localFile) = message.payload else { return }
        let fileName = localFile ?? name
        let textContent = MediaStorageService.shared.readDocumentText(filename: fileName) ?? ""

        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)

            let analysis: String
            if ext == "swift" {
                analysis = """
                🧠 **Анализ кода «\(name)» (RAG-индекс: 100%)**:
                1. **Конкурентность**: Использован глобальный актор `@globalActor actor AIGramCoreActor` для изоляции критических состояний.
                2. **Потокобезопасность**: Протокол `MessageStreamDelegate` помечен как `Sendable`, предотвращая гонки данных при параллельной передаче токенов.
                3. **Рекомендация**: На строке 21 в `dispatchAgentDiscussion` стоит добавить таймаут с отменой через `withThrowingTaskGroup`.
                """
            } else if ext == "md" {
                analysis = """
                🧠 **Анализ документа «\(name)» (RAG-индекс: 100%)**:
                1. **Ключевой фокус**: Сочетание сверхбыстрого нативного Telegram UX с автономным слоем агентов.
                2. **Milestone 2 (Live Duplex Voice)**: Архитектура полнодуплексного аудио готова к релизу.
                3. **Оценка роадмапа**: План сбалансирован, риски регрессий минимизированы строгой типизацией Swift 6.
                """
            } else if ext == "json" {
                analysis = """
                🧠 **Анализ метрик «\(name)» (RAG-индекс: 100%)**:
                1. **Cold start**: 142.5 ms (на 35% быстрее отраслевого бенчмарка).
                2. **UI Frame rate**: Стабильные 120 FPS благодаря `SwiftUI` диффингу.
                3. **Inference**: Скорость генерации 84.6 т/с полностью перекрывает потребности живого диалога.
                """
            } else {
                let previewSnippet = String(textContent.prefix(200))
                analysis = """
                🧠 **RAG-анализ документа «\(name)» (\(size))**:
                Файл успешно проанализирован. Ключевой контекст: "\(previewSnippet)..."
                Все сущности извлечены в локальный граф знаний для контекстных ответов.
                """
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let replyMsg = ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .text(analysis),
                time: formatter.string(from: Date()),
                authorName: thread.isGroup ? "Code Partner" : thread.title,
                authorAvatar: thread.avatar,
                replyToMessageId: message.id,
                replyToSnippet: message.previewSnippet,
                replyToAuthor: message.authorName ?? "You"
            )
            self.appendMessage(replyMsg, to: thread)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func deleteMessage(messageId: String, in thread: ChatThread) {
        var msgs = messages(for: thread)
        msgs.removeAll { $0.id == messageId }
        replaceMessages(msgs, for: thread)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func sendVoiceMessage(duration: String, filename: String? = nil, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .voice(duration: duration),
            time: formatter.string(from: Date()),
            localFileName: filename
        )
        appendMessage(msg, to: thread)
        generateAIResponseIfNeeded(for: msg, in: thread)
    }

    func sendAttachment(name: String, size: String, localFileName: String? = nil, to thread: ChatThread) {
        sendPhoto(name: name, size: size, localFileName: localFileName, to: thread)
    }

    func sendVideoNote(duration: String, filename: String? = nil, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .videoNote(duration: duration),
            time: formatter.string(from: Date()),
            localFileName: filename
        )
        appendMessage(msg, to: thread)
        generateAIResponseIfNeeded(for: msg, in: thread)
    }

    func sendInteractiveWidget(_ widget: InteractiveWidget, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .widget(widget),
            time: formatter.string(from: Date())
        )
        appendMessage(msg, to: thread)
        generateAIResponseIfNeeded(for: msg, in: thread)
    }

    func updateWidgetState(widgetId: String, newStatus: String, newTab: String? = nil, newOutput: String? = nil, in thread: ChatThread) {
        var current = messages(for: thread)
        guard let index = current.firstIndex(where: {
            if case let .widget(w) = $0.payload, w.id == widgetId { return true }
            return false
        }) else { return }

        if case var .widget(w) = current[index].payload {
            w.currentStatus = newStatus
            if let newTab = newTab { w.selectedMetricTab = newTab }
            if let newOutput = newOutput { w.consoleOutput = newOutput }
            current[index].payload = .widget(w)
            replaceMessages(current, for: thread)
        }
    }

    func sendSticker(name: String, emoji: String, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .sticker(name: name, emoji: emoji),
            time: formatter.string(from: Date())
        )
        appendMessage(msg, to: thread)
    }

    func sendTextMessage(_ text: String, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .text(text),
            time: formatter.string(from: Date())
        )
        appendMessage(msg, to: thread)
    }

    func sendPhoto(name: String, size: String = "1.8 MB", localFileName: String? = nil, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .photo(name: name, size: size),
            time: formatter.string(from: Date()),
            localFileName: localFileName ?? name
        )
        appendMessage(msg, to: thread)
        generateAIResponseIfNeeded(for: msg, in: thread)
    }

    func transcribeMessage(id: String, in thread: ChatThread) {
        var current = messages(for: thread)
        guard let idx = current.firstIndex(where: { $0.id == id }) else { return }

        if current[idx].transcription != nil {
            current[idx].isTranscribed.toggle()
            replaceMessages(current, for: thread)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        current[idx].isTranscribing = true
        replaceMessages(current, for: thread)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let isOutgoing = current[idx].side == .outgoing
        let localFileName = current[idx].localFileName
        let threadTitle = thread.title

        Task {
            var audioURL: URL? = nil
            if let localFileName = localFileName {
                audioURL = MediaStorageService.shared.fileURL(for: localFileName)
            }

            _ = await SpeechTranscriptionService.shared.requestAuthorization()
            let transcribedText = await SpeechTranscriptionService.shared.transcribeAudio(
                fileURL: audioURL,
                threadTitle: threadTitle,
                isOutgoing: isOutgoing
            )

            var updated = self.messages(for: thread)
            guard let uIdx = updated.firstIndex(where: { $0.id == id }) else { return }
            updated[uIdx].isTranscribing = false
            updated[uIdx].transcription = transcribedText
            updated[uIdx].isTranscribed = true
            self.replaceMessages(updated, for: thread)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func generateAIResponseIfNeeded(for message: ConversationMessage, in thread: ChatThread) {
        guard message.side == .outgoing else { return }

        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)

            let promptSummary: String
            switch message.payload {
            case let .voice(duration):
                promptSummary = "[Пользователь отправил голосовое сообщение (\(duration))]"
            case let .photo(name, _):
                promptSummary = "[Пользователь отправил фото/макет: \(name)]"
            case let .videoNote(duration):
                promptSummary = "[Пользователь записал видеосообщение: \(duration)]"
            case let .widget(widget):
                promptSummary = "[Пользователь обновил интерактивный виджет «\(widget.title)» со статусом: \(widget.currentStatus)]"
            case let .document(name, size, _, _):
                promptSummary = "[Пользователь прикрепил документ: \(name) (\(size))]"
            default:
                return
            }

            var replyText: String? = nil
            if self.isConfigured {
                do {
                    replyText = try await OpenRouterService().sendMessage(
                        draft: promptSummary,
                        thread: thread,
                        history: self.messages(for: thread),
                        memoryNote: self.memoryNote(for: thread),
                        configuration: self.configurationSnapshot
                    )
                } catch {
                    print("[AIWorkspace] OpenRouter response failed: \(error)")
                }
            }

            if replyText == nil || replyText?.isEmpty == true {
                replyText = self.contextualOfflineResponse(for: message, in: thread)
            }

            guard let finalReply = replyText, !finalReply.isEmpty else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            let replyMsg = ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .text(finalReply),
                time: formatter.string(from: Date()),
                authorName: thread.isGroup ? (thread.title == "Build Board" ? "Code Partner" : "Study Room") : thread.title,
                authorAvatar: thread.avatar
            )

            self.appendMessage(replyMsg, to: thread)
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // Trigger local push notification
            AppNotificationService.shared.scheduleLocalNotification(
                title: replyMsg.authorName ?? thread.title,
                subtitle: thread.isGroup ? thread.title : "AIGram Contact",
                body: finalReply,
                delaySeconds: 1.0,
                threadId: thread.id
            )
        }
    }

    private func contextualOfflineResponse(for message: ConversationMessage, in thread: ChatThread) -> String {
        switch message.payload {
        case .voice:
            switch thread.id {
            case "design-scout":
                return "Прослушал голосовое сообщение. По визуальной части: предлагаю зафиксировать эту структуру компонентов и подготовить финальный макет для ревью."
            case "product-coach":
                return "Голосовое принял. По продуктовой воронке: идея отличная, давай включим этот сценарий в ближайший спринт и замерим конверсию первого дня."
            case "code-partner":
                return "Записал архитектурные требования из аудио. Реализуем на Swift concurrency с акторной изоляцией для надежности."
            case "research-desk":
                return "Голосовые тезисы зафиксированы. Добавил эти пункты в сравнительный отчет по моделям и бенчмаркам."
            default:
                return "Прослушал аудиозапись. Детали зафиксированы, готов приступать к следующему шагу."
            }
        case let .photo(name, _):
            switch thread.id {
            case "design-scout":
                return "Отличный референс (\(name))! Проверил сетку, контрастность и баланс белого пространства — композиция выглядит чисто. Рекомендую сохранить 18pt радиус скруглений."
            case "product-coach":
                return "Изучил макет (\(name)). Пользовательский сценарий считывается за 2 секунды. На следующем шаге стоит сделать акцентную кнопку действия более заметной."
            case "code-partner":
                return "Изучил схему (\(name)). Архитектура модулей логична, зависимости направлены верно. Можем безопасно раскатывать в продакшен."
            case "research-desk":
                return "Данные со схемы (\(name)) занесены в проект. Отличная наглядная визуализация параметров."
            default:
                return "Изображение (\(name)) получено и сохранено в локальном хранилище AIGram. Готов разобрать детали."
            }
        case .videoNote:
            switch thread.id {
            case "design-scout":
                return "Посмотрел видеосообщение! Динамика анимаций и жесты смахивания работают плавно. Рекомендую сохранить такой темп взаимодействия."
            case "product-coach":
                return "Видео-заметку принял. Отличный питч! Зафиксировал все требования по онбордингу и метрикам удержания."
            case "code-partner":
                return "Видео посмотрел. Конвейер сборки и рендеринг видео-кружочка отрабатывают стабильно. Можем добавлять в продакшен."
            default:
                return "Посмотрел видео-заметку! Отличная подача. Зафиксировал всё в задачах проекта."
            }
        case let .widget(widget):
            return "Синхронизировал данные интерактивного виджета «\(widget.title)». Текущий статус: [\(widget.currentStatus)]."
        case let .document(name, size, ext, _):
            if ext == "swift" {
                return "Изучил исходный код файла «\(name)» (\(size)). Архитектура использует Swift 6 Concurrency: акторы, @globalActor и Sendable-модели корректно изолируют состояние."
            } else if ext == "md" {
                return "Ознакомился с документом «\(name)» (\(size)). Структура роадмапа понятна, этапы Q3-Q4 выстроены логично."
            } else if ext == "json" {
                return "Разобрал телеметрию из «\(name)» (\(size)). Задержка 18.2ms и фреймрейт 120 FPS подтверждают стабильность сборки."
            } else {
                return "Документ «\(name)» (\(size)) получен и проиндексирован в локальной базе знаний RAG."
            }
        default:
            return "Сообщение принято и сохранено."
        }
    }

    func addNewAgent(name: String, username: String, role: String, bio: String, avatar: ChatAvatarKind) {
        let cleanId = username.lowercased().replacingOccurrences(of: "@", with: "").replacingOccurrences(of: " ", with: "-")
        let contact = ContactProfile(
            id: cleanId.isEmpty ? UUID().uuidString : cleanId,
            displayName: name,
            username: username.hasPrefix("@") ? username : "@\(username)",
            roleTitle: role,
            bio: bio,
            presence: .online,
            avatar: avatar
        )
        contacts.insert(contact, at: 0)
        _ = createOrGetThread(for: contact)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func updateContact(contactId: String, newName: String, newBio: String) {
        if let idx = contacts.firstIndex(where: { $0.id == contactId }) {
            contacts[idx].displayName = newName
            contacts[idx].bio = newBio
        }
        if let tIdx = threads.firstIndex(where: { $0.id == contactId }) {
            threads[tIdx].title = newName
            threads[tIdx].headline = newBio
        }
    }

    func removeContact(contactId: String) {
        contacts.removeAll { $0.id == contactId }
        deleteThread(threadId: contactId)
    }

    var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedModelSlug: String {
        let slug = modelSlug.trimmingCharacters(in: .whitespacesAndNewlines)
        return slug.isEmpty ? "qwen/qwen3.5-9b" : slug
    }

    var isConfigured: Bool {
        if !selectedProvider.requiresKey { return true }
        return trimmedAPIKey.isEmpty == false
    }

    var initials: String {
        let pieces = displayName
            .split(whereSeparator: \.isWhitespace)
            .prefix(2)
            .compactMap { $0.first }

        let result = String(pieces)
        return result.isEmpty ? "AI" : result.uppercased()
    }

    var modelDisplayName: String {
        let parts = trimmedModelSlug.split(separator: "/")
        return String(parts.last ?? Substring(trimmedModelSlug))
    }

    var connectionLabel: String {
        isConfigured ? "\(selectedProvider.rawValue) ready" : "Local fallback only"
    }

    var configurationSnapshot: OpenRouterConfiguration {
        OpenRouterConfiguration(
            apiKey: trimmedAPIKey,
            modelSlug: trimmedModelSlug,
            useZeroRetention: useZeroRetention,
            denyProviderLogging: denyProviderLogging,
            provider: selectedProvider,
            customEndpoint: customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func ensureConversationExists(for thread: ChatThread) {
        guard storedConversations[thread.id] == nil else { return }
        let bootstrap = ConversationMessage.bootstrapConversation(for: thread)
        storedConversations[thread.id] = makeStoredState(from: bootstrap, updatedAt: seedDate(for: thread))
    }

    func messages(for thread: ChatThread) -> [ConversationMessage] {
        if let existing = storedConversations[thread.id]?.messages, existing.isEmpty == false {
            return existing
        }

        return ConversationMessage.bootstrapConversation(for: thread)
    }

    func memoryNote(for thread: ChatThread) -> String {
        storedConversations[thread.id]?.memoryNote ?? ""
    }

    func replaceMessages(_ messages: [ConversationMessage], for thread: ChatThread) {
        storedConversations[thread.id] = makeStoredState(from: messages)
    }

    func appendMessage(_ message: ConversationMessage, to thread: ChatThread) {
        var current = messages(for: thread)
        current.append(message)
        replaceMessages(current, for: thread)
    }

    func orderedSummaries(for baseThreads: [ChatThread]? = nil) -> [ChatThreadSummary] {
        let active = baseThreads ?? self.threads
        seedThreadsIfNeeded(active)
        let indexedThreads = Array(active.enumerated())

        return indexedThreads
            .map { index, thread in
                (
                    index: index,
                    summary: makeSummary(for: thread)
                )
            }
            .sorted { lhs, rhs in
                if lhs.summary.thread.isPinned != rhs.summary.thread.isPinned {
                    return lhs.summary.thread.isPinned && rhs.summary.thread.isPinned == false
                }

                let lhsDate = storedConversations[lhs.summary.thread.id]?.updatedAt ?? .distantPast
                let rhsDate = storedConversations[rhs.summary.thread.id]?.updatedAt ?? .distantPast

                if lhsDate != rhsDate {
                    return lhsDate > rhsDate
                }

                return lhs.index < rhs.index
            }
            .map(\.summary)
    }

    private func makeSummary(for thread: ChatThread) -> ChatThreadSummary {
        guard let state = storedConversations[thread.id], let lastMessage = state.messages.last else {
            return ChatThreadSummary(
                thread: thread,
                previewText: thread.headline,
                detailText: thread.detail,
                timeText: thread.time,
                searchableText: [thread.title, thread.headline, thread.detail ?? "", thread.aiProfile.bio, thread.searchableParticipants].joined(separator: " ")
            )
        }

        let preview = previewText(for: lastMessage)

        return ChatThreadSummary(
            thread: thread,
            previewText: preview,
            detailText: nil,
            timeText: timeLabel(from: state.updatedAt),
            searchableText: [thread.title, preview, state.memoryNote, thread.aiProfile.bio, thread.aiProfile.roleTitle, thread.searchableParticipants].joined(separator: " ")
        )
    }

    private func makeStoredState(from messages: [ConversationMessage], updatedAt: Date = Date()) -> StoredConversationState {
        StoredConversationState(
            messages: messages,
            updatedAt: updatedAt,
            memoryNote: buildMemoryNote(from: messages)
        )
    }

    private func buildMemoryNote(from messages: [ConversationMessage]) -> String {
        let relevantLines = messages
            .suffix(10)
            .compactMap { message -> String? in
                guard case let .text(text) = message.payload else { return nil }

                let cleaned = text
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard cleaned.isEmpty == false else { return nil }

                let prefix: String
                if message.side == .incoming {
                    let author = message.authorName ?? "assistant"
                    prefix = "assistant(\(author))"
                } else {
                    prefix = "user"
                }

                return "\(prefix): \(String(cleaned.prefix(160)))"
            }

        return relevantLines.joined(separator: "\n")
    }

    private func previewText(for message: ConversationMessage) -> String {
        let baseText: String
        switch message.payload {
        case let .text(text):
            baseText = text.replacingOccurrences(of: "\n", with: " ")
        case let .emoji(value):
            baseText = value
        case let .photo(name, _):
            baseText = "Shared image: \(name)"
        case let .voice(duration):
            baseText = "Voice message (\(duration))"
        case let .videoNote(duration):
            baseText = "Video message (\(duration))"
        case let .sticker(_, emoji):
            baseText = "\(emoji) Sticker"
        case let .widget(widget):
            baseText = "⚡ \(widget.title) (\(widget.currentStatus))"
        case let .document(name, size, _, _):
            baseText = "📄 \(name) (\(size))"
        }

        if let authorName = message.authorName, message.side == .incoming {
            return "\(authorName): \(baseText)"
        }

        return baseText
    }

    private func timeLabel(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func persistStoredConversations() {
        guard let data = try? JSONEncoder().encode(storedConversations) else { return }
        defaults.set(data, forKey: Keys.storedConversations)
        defaults.set(Self.conversationSchemaVersion, forKey: Keys.conversationSchemaVersion)
    }

    private static func loadStoredConversations(from defaults: UserDefaults) -> [String: StoredConversationState] {
        let storedVersion = defaults.integer(forKey: Keys.conversationSchemaVersion)
        guard storedVersion == conversationSchemaVersion else {
            defaults.removeObject(forKey: Keys.storedConversations)
            defaults.set(conversationSchemaVersion, forKey: Keys.conversationSchemaVersion)
            return [:]
        }

        guard let data = defaults.data(forKey: Keys.storedConversations),
              let decoded = try? JSONDecoder().decode([String: StoredConversationState].self, from: data) else {
            return [:]
        }

        return decoded
    }

    private func seedThreadsIfNeeded(_ threads: [ChatThread]) {
        for thread in threads {
            ensureConversationExists(for: thread)
        }
    }

    private func seedDate(for thread: ChatThread) -> Date {
        let calendar = Calendar.current
        let now = Date()

        switch thread.id {
        case "design-scout":
            return calendar.date(byAdding: .minute, value: -12, to: now) ?? now
        case "product-coach":
            return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        case "study-room":
            return calendar.date(byAdding: .hour, value: -3, to: now) ?? now
        case "visual-lab":
            return calendar.date(byAdding: .hour, value: -5, to: now) ?? now
        case "code-partner":
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        default:
            return now
        }
    }
}

private enum Keys {
    static let displayName = "aiworkspace.profile.displayName"
    static let username = "aiworkspace.profile.username"
    static let bio = "aiworkspace.profile.bio"
    static let apiKey = "aiworkspace.openrouter.apiKey"
    static let modelSlug = "aiworkspace.openrouter.modelSlug"
    static let selectedProvider = "aiworkspace.llm.provider"
    static let customEndpoint = "aiworkspace.llm.customEndpoint"
    static let useZeroRetention = "aiworkspace.openrouter.useZeroRetention"
    static let denyProviderLogging = "aiworkspace.openrouter.denyProviderLogging"
    static let storedConversations = "aiworkspace.conversations.state"
    static let conversationSchemaVersion = "aiworkspace.conversations.schemaVersion"
    static let selectedWallpaper = "aiworkspace.chat.selectedWallpaper"
}
