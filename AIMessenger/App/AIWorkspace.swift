import SwiftUI

struct OpenRouterConfiguration {
    let apiKey: String
    let modelSlug: String
    let useZeroRetention: Bool
    let denyProviderLogging: Bool
}

private struct StoredConversationState: Codable {
    var messages: [ConversationMessage]
    var updatedAt: Date
    var memoryNote: String
}

@MainActor
final class AIWorkspace: ObservableObject {
    private static let conversationSchemaVersion = 2

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

    @Published var useZeroRetention: Bool {
        didSet { defaults.set(useZeroRetention, forKey: Keys.useZeroRetention) }
    }

    @Published var denyProviderLogging: Bool {
        didSet { defaults.set(denyProviderLogging, forKey: Keys.denyProviderLogging) }
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
        self.useZeroRetention = defaults.object(forKey: Keys.useZeroRetention) as? Bool ?? true
        self.denyProviderLogging = defaults.object(forKey: Keys.denyProviderLogging) as? Bool ?? true
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

    func deleteMessage(messageId: String, in thread: ChatThread) {
        var msgs = messages(for: thread)
        msgs.removeAll { $0.id == messageId }
        replaceMessages(msgs, for: thread)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func sendVoiceMessage(duration: String, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .voice(duration: duration),
            time: formatter.string(from: Date())
        )
        appendMessage(msg, to: thread)
    }

    func sendAttachment(name: String, size: String, to thread: ChatThread) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let msg = ConversationMessage(
            id: UUID().uuidString,
            side: .outgoing,
            payload: .photo(name: name, size: size),
            time: formatter.string(from: Date())
        )
        appendMessage(msg, to: thread)
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
        trimmedAPIKey.isEmpty == false
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
        isConfigured ? "OpenRouter connected" : "Local fallback only"
    }

    var configurationSnapshot: OpenRouterConfiguration {
        OpenRouterConfiguration(
            apiKey: trimmedAPIKey,
            modelSlug: trimmedModelSlug,
            useZeroRetention: useZeroRetention,
            denyProviderLogging: denyProviderLogging
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
        case "memory-vault":
            return calendar.date(byAdding: .day, value: -2, to: now) ?? now
        case "design-scout":
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case "seminar-circle":
            return calendar.date(byAdding: .hour, value: -18, to: now) ?? now
        case "product-coach":
            return calendar.date(byAdding: .minute, value: -90, to: now) ?? now
        case "build-board":
            return calendar.date(byAdding: .minute, value: -35, to: now) ?? now
        case "research-desk":
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
    static let useZeroRetention = "aiworkspace.openrouter.useZeroRetention"
    static let denyProviderLogging = "aiworkspace.openrouter.denyProviderLogging"
    static let storedConversations = "aiworkspace.conversations.state"
    static let conversationSchemaVersion = "aiworkspace.conversations.schemaVersion"
}
