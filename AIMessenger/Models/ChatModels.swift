import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case contacts
    case calls
    case chats
    case settings

    var id: String { rawValue }
}

enum ContactsRoute: Hashable {
    case info(ContactProfile)
    case editInfo(ContactProfile)
}

enum ChatsRoute: Hashable {
    case conversation(ChatThread)
}

enum SettingsRoute: Hashable {
    case editProfile
    case aiSetup
    case notifications
    case privacySecurity
    case dataStorage
    case appearance
    case stickers
}

enum SwipeRevealSide {
    case none
    case left
    case right

    var offset: CGFloat {
        switch self {
        case .none:
            return 0
        case .left:
            return -222
        case .right:
            return 148
        }
    }
}

enum DeliveryState {
    case none
    case sent
    case read
}

enum ChatThreadKind: Hashable {
    case direct
    case group
}

enum ChatAvatarKind: String, Hashable, Codable {
    case saved
    case visionCluster
    case tutor
    case uxCopilot
    case researchBot
    case artEngine
    case codeAgents
    case seminarCircle
    case buildBoard
}

struct ChatThread: Identifiable, Hashable {
    let id: String
    var title: String
    var headline: String
    var detail: String?
    var time: String
    var badge: String?
    var badgeBright: Bool
    var isMuted: Bool
    var isPinned: Bool
    var online: Bool
    var revealSide: SwipeRevealSide
    var deliveryState: DeliveryState
    var groupedBackground: Bool
    var avatar: ChatAvatarKind
    var kind: ChatThreadKind
    var pinnedMessageId: String? = nil
    var pinnedMessageSnippet: String? = nil
    var pinnedMessageAuthor: String? = nil
    var customAvatarFilename: String? = nil
    var fakeHumanId: String? = nil

    init(
        id: String,
        title: String,
        headline: String,
        detail: String? = nil,
        time: String,
        badge: String? = nil,
        badgeBright: Bool = false,
        isMuted: Bool = false,
        isPinned: Bool = false,
        online: Bool = false,
        revealSide: SwipeRevealSide = .none,
        deliveryState: DeliveryState = .none,
        groupedBackground: Bool = false,
        avatar: ChatAvatarKind,
        kind: ChatThreadKind,
        pinnedMessageId: String? = nil,
        pinnedMessageSnippet: String? = nil,
        pinnedMessageAuthor: String? = nil,
        customAvatarFilename: String? = nil,
        fakeHumanId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.headline = headline
        self.detail = detail
        self.time = time
        self.badge = badge
        self.badgeBright = badgeBright
        self.isMuted = isMuted
        self.isPinned = isPinned
        self.online = online
        self.revealSide = revealSide
        self.deliveryState = deliveryState
        self.groupedBackground = groupedBackground
        self.avatar = avatar
        self.kind = kind
        self.pinnedMessageId = pinnedMessageId
        self.pinnedMessageSnippet = pinnedMessageSnippet
        self.pinnedMessageAuthor = pinnedMessageAuthor
        self.customAvatarFilename = customAvatarFilename
        self.fakeHumanId = fakeHumanId
    }
}

struct ChatThreadSummary: Identifiable, Hashable {
    let thread: ChatThread
    let previewText: String
    let detailText: String?
    let timeText: String
    let searchableText: String

    var id: String { thread.id }
}

struct AIContactProfile: Hashable {
    let username: String
    let roleTitle: String
    let rolePrompt: String
    let greeting: String
    let status: String
    let bio: String
}

struct ChatGroupMember: Identifiable, Hashable {
    let id: String
    let name: String
    let username: String
    let roleTitle: String
    let presence: PresenceState
    let avatar: ChatAvatarKind
}

enum ChatWallpaperKind: String, CaseIterable, Identifiable, Codable {
    case doodles = "Dark Doodles"
    case obsidian = "Midnight Pure"
    case neon = "Cyber Neon"
    case sunset = "Sunset Velvet"
    case emerald = "Emerald Matrix"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .doodles: return "sparkles"
        case .obsidian: return "moon.stars.fill"
        case .neon: return "bolt.fill"
        case .sunset: return "sunset.fill"
        case .emerald: return "leaf.fill"
        }
    }
}

struct InteractiveWidget: Hashable, Codable, Identifiable {
    enum Kind: String, Hashable, Codable {
        case metricsChart
        case codeRunner
        case kanbanTask
    }

    let id: String
    let kind: Kind
    var title: String
    var subtitle: String
    var currentStatus: String
    var codeSnippet: String?
    var consoleOutput: String?
    var metricValues: [Double]?
    var metricLabels: [String]?
    var selectedMetricTab: String?

    init(
        id: String = UUID().uuidString,
        kind: Kind,
        title: String,
        subtitle: String,
        currentStatus: String,
        codeSnippet: String? = nil,
        consoleOutput: String? = nil,
        metricValues: [Double]? = nil,
        metricLabels: [String]? = nil,
        selectedMetricTab: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.currentStatus = currentStatus
        self.codeSnippet = codeSnippet
        self.consoleOutput = consoleOutput
        self.metricValues = metricValues
        self.metricLabels = metricLabels
        self.selectedMetricTab = selectedMetricTab
    }

    static func sampleMetricsWidget() -> InteractiveWidget {
        InteractiveWidget(
            kind: .metricsChart,
            title: "Assistant Usage Analytics",
            subtitle: "Weekly activity & response speed",
            currentStatus: "Avg response: 180ms",
            selectedMetricTab: "Latency"
        )
    }

    static func sampleCodeRunnerWidget() -> InteractiveWidget {
        InteractiveWidget(
            kind: .codeRunner,
            title: "Swift Algorithm Sandbox",
            subtitle: "Interactive code playground",
            currentStatus: "Ready to run",
            codeSnippet: """
            func calculateFibonacci(_ n: Int) -> [Int] {
                var sequence = [0, 1]
                while sequence.count < n {
                    let next = sequence[sequence.count - 1] + sequence[sequence.count - 2]
                    sequence.append(next)
                }
                return sequence
            }
            print("Fibonacci series: \\(calculateFibonacci(8))")
            """
        )
    }

    static func sampleKanbanWidget() -> InteractiveWidget {
        InteractiveWidget(
            kind: .kanbanTask,
            title: "Daily Priorities & Focus",
            subtitle: "Project deliverables and notes",
            currentStatus: "In Progress"
        )
    }
}

struct ConversationMessage: Identifiable, Hashable, Codable {
    enum Side: Hashable, Codable {
        case incoming
        case outgoing
    }

    enum Payload: Hashable, Codable {
        case text(String)
        case emoji(String)
        case photo(name: String, size: String)
        case voice(duration: String)
        case videoNote(duration: String)
        case sticker(name: String, emoji: String)
        case widget(InteractiveWidget)
        case document(name: String, size: String, ext: String, localFileName: String?)
    }

    let id: String
    let side: Side
    var payload: Payload
    let time: String
    let authorName: String?
    let authorAvatar: ChatAvatarKind?
    var reactions: [String]
    var transcription: String?
    var isTranscribing: Bool
    var isTranscribed: Bool
    var localFileName: String?
    var replyToMessageId: String?
    var replyToSnippet: String?
    var replyToAuthor: String?
    var isPinned: Bool

    init(
        id: String,
        side: Side,
        payload: Payload,
        time: String,
        authorName: String? = nil,
        authorAvatar: ChatAvatarKind? = nil,
        reactions: [String] = [],
        transcription: String? = nil,
        isTranscribing: Bool = false,
        isTranscribed: Bool = false,
        localFileName: String? = nil,
        replyToMessageId: String? = nil,
        replyToSnippet: String? = nil,
        replyToAuthor: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.side = side
        self.payload = payload
        self.time = time
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.reactions = reactions
        self.transcription = transcription
        self.isTranscribing = isTranscribing
        self.isTranscribed = isTranscribed
        self.localFileName = localFileName
        self.replyToMessageId = replyToMessageId
        self.replyToSnippet = replyToSnippet
        self.replyToAuthor = replyToAuthor
        self.isPinned = isPinned
    }

    enum CodingKeys: String, CodingKey {
        case id, side, payload, time, authorName, authorAvatar, reactions, transcription, isTranscribing, isTranscribed, localFileName, replyToMessageId, replyToSnippet, replyToAuthor, isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        side = try container.decode(Side.self, forKey: .side)
        payload = try container.decode(Payload.self, forKey: .payload)
        time = try container.decode(String.self, forKey: .time)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        authorAvatar = try container.decodeIfPresent(ChatAvatarKind.self, forKey: .authorAvatar)
        reactions = try container.decodeIfPresent([String].self, forKey: .reactions) ?? []
        transcription = try container.decodeIfPresent(String.self, forKey: .transcription)
        isTranscribing = try container.decodeIfPresent(Bool.self, forKey: .isTranscribing) ?? false
        isTranscribed = try container.decodeIfPresent(Bool.self, forKey: .isTranscribed) ?? false
        localFileName = try container.decodeIfPresent(String.self, forKey: .localFileName)
        replyToMessageId = try container.decodeIfPresent(String.self, forKey: .replyToMessageId)
        replyToSnippet = try container.decodeIfPresent(String.self, forKey: .replyToSnippet)
        replyToAuthor = try container.decodeIfPresent(String.self, forKey: .replyToAuthor)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    var isVoice: Bool {
        if case .voice = payload { return true }
        return false
    }

    var isVideoNote: Bool {
        if case .videoNote = payload { return true }
        return false
    }

    var isWidget: Bool {
        if case .widget = payload { return true }
        return false
    }

    var isDocument: Bool {
        if case .document = payload { return true }
        return false
    }

    var isTranscribable: Bool {
        isVoice || isVideoNote
    }

    var audioFileName: String? {
        if let local = localFileName { return local }
        if case .voice = payload {
            return "voice_\(id).m4a"
        }
        return nil
    }

    var videoFileName: String? {
        if let local = localFileName { return local }
        if case .videoNote = payload {
            return "video_note_\(id).mp4"
        }
        return nil
    }

    var imageFileName: String? {
        if let local = localFileName { return local }
        if case let .photo(name, _) = payload {
            return name
        }
        return nil
    }

    var documentFileName: String? {
        if let local = localFileName { return local }
        if case let .document(name, _, _, localFile) = payload {
            return localFile ?? name
        }
        return nil
    }

    var previewSnippet: String {
        switch payload {
        case let .text(txt): return txt
        case let .emoji(e): return e
        case let .photo(name, _): return "📷 Photo: \(name)"
        case let .voice(d): return "🎤 Voice (\(d))"
        case let .videoNote(d): return "📹 Video Note (\(d))"
        case let .sticker(_, e): return "Sticker \(e)"
        case let .widget(w): return "⚡ \(w.title)"
        case let .document(name, size, _, _): return "📄 \(name) (\(size))"
        }
    }
}

struct VoiceTimbre: Hashable, Codable, Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let pitch: Float
    let rate: Float
    let icon: String

    static let presets: [VoiceTimbre] = [
        VoiceTimbre(id: "natural", name: "Natural AI", subtitle: "Balanced & conversational", pitch: 1.0, rate: 0.50, icon: "waveform"),
        VoiceTimbre(id: "deep_tech", name: "Deep Tech", subtitle: "Authoritative senior engineer", pitch: 0.88, rate: 0.51, icon: "cpu"),
        VoiceTimbre(id: "vibrant_scout", name: "Design Scout", subtitle: "Lively, energetic & creative", pitch: 1.16, rate: 0.53, icon: "sparkles"),
        VoiceTimbre(id: "soft_mentor", name: "Product Coach", subtitle: "Calm, strategic mentor tone", pitch: 1.05, rate: 0.47, icon: "brain.head.profile")
    ]
}

enum PresenceState: Hashable {
    case online
    case lastSeen(String)

    var label: String {
        switch self {
        case .online:
            return "online"
        case let .lastSeen(value):
            return value
        }
    }

    var isOnline: Bool {
        if case .online = self {
            return true
        }

        return false
    }
}

struct ContactProfile: Identifiable, Hashable {
    let id: String
    var displayName: String
    var username: String
    var roleTitle: String
    var bio: String
    var presence: PresenceState
    var avatar: ChatAvatarKind
    var customAvatarFilename: String? = nil
    var relationshipKind: HumanRelationshipKind? = nil
    var mood: HumanMood? = nil
}

enum CallDirection: String, Hashable, Codable {
    case incoming
    case outgoing
    case mixed
    case missed

    var color: Color {
        switch self {
        case .incoming, .outgoing, .mixed:
            return TelegramPalette.mutedText
        case .missed:
            return Color(hex: 0xFE453A)
        }
    }
}

struct CallRecord: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let detail: String
    let date: String
    let avatar: ChatAvatarKind
    let direction: CallDirection
}

extension ChatThread {
    static let sampleThreads: [ChatThread] = [
        ChatThread(
            id: "saved-messages",
            title: "Saved Messages",
            headline: "Forward messages here to save them",
            detail: nil,
            time: "12:00",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: true,
            online: false,
            revealSide: .none,
            deliveryState: .sent,
            groupedBackground: true,
            avatar: .saved,
            kind: .direct
        )
    ]

    var isGroup: Bool {
        kind == .group
    }

    var members: [ChatGroupMember] {
        switch id {
        case "seminar-circle":
            return [
                ChatGroupMember(
                    id: "study-room",
                    name: "Study Room",
                    username: "@studyroom",
                    roleTitle: "Study assistant",
                    presence: .online,
                    avatar: .tutor
                ),
                ChatGroupMember(
                    id: "research-desk",
                    name: "Research Desk",
                    username: "@researchdesk",
                    roleTitle: "Research and comparison",
                    presence: .online,
                    avatar: .researchBot
                ),
                ChatGroupMember(
                    id: "memory-vault",
                    name: "Memory Vault",
                    username: "@memoryvault",
                    roleTitle: "Knowledge memory",
                    presence: .lastSeen("active 18 minutes ago"),
                    avatar: .saved
                )
            ]
        case "build-board":
            return [
                ChatGroupMember(
                    id: "code-partner",
                    name: "Code Partner",
                    username: "@codepartner",
                    roleTitle: "Engineering copilot",
                    presence: .online,
                    avatar: .codeAgents
                ),
                ChatGroupMember(
                    id: "product-coach",
                    name: "Product Coach",
                    username: "@productcoach",
                    roleTitle: "Product and UX thinking",
                    presence: .lastSeen("active 9 minutes ago"),
                    avatar: .uxCopilot
                ),
                ChatGroupMember(
                    id: "design-scout",
                    name: "Design Scout",
                    username: "@designscout",
                    roleTitle: "UI and visual review",
                    presence: .online,
                    avatar: .visionCluster
                )
            ]
        default:
            return []
        }
    }

    var memberNamesText: String {
        members.map(\.name).joined(separator: ", ")
    }

    var participantSummary: String {
        guard isGroup else { return aiProfile.status }
        let onlineCount = members.filter(\.presence.isOnline).count
        return "\(members.count) AI agents, \(onlineCount) online"
    }

    var searchableParticipants: String {
        members
            .map { [$0.name, $0.username, $0.roleTitle].joined(separator: " ") }
            .joined(separator: " ")
    }

    var aiProfile: AIContactProfile {
        switch id {
        case "saved-messages", "memory-vault":
            return AIContactProfile(
                username: "@savedmessages",
                roleTitle: "Personal Cloud Storage",
                rolePrompt: "You are personal cloud storage for notes, files, and reminders. Help organize stored data concisely.",
                greeting: "Forward messages here to save them, or send photos and documents for cloud storage.",
                status: "cloud storage",
                bio: "Your personal cloud notebook."
            )
        case "ai-assistant":
            return AIContactProfile(
                username: "@assistant",
                roleTitle: "Personal AI Assistant",
                rolePrompt: "You are an intelligent, helpful, friendly personal assistant on Telegram. Answer clearly, accurately, and naturally in Russian or English depending on user request.",
                greeting: "Привет! Я твой персональный AI-ассистент. Чем могу помочь сегодня?",
                status: "online",
                bio: "Universal assistant for answers, planning, writing, and research."
            )
        case "code-partner":
            return AIContactProfile(
                username: "@copilot",
                roleTitle: "Engineering Copilot",
                rolePrompt: "You are an experienced software engineer. Provide clean, idiomatic code, solve bugs, and discuss system architecture. Keep responses concise and practical.",
                greeting: "Привет! Готов разобрать код, архитектуру или помочь с отладкой.",
                status: "online",
                bio: "Engineering copilot for iOS, Swift, Python, and system architecture."
            )
        case "research-desk":
            return AIContactProfile(
                username: "@research",
                roleTitle: "Research & Analysis",
                rolePrompt: "You are a research analyst assistant. Summarize complex material, extract key findings, and compare solutions objectively.",
                greeting: "Привет! Присылай темы для ресерча, статьи или вопросы для подробного анализа.",
                status: "online",
                bio: "Structured research, fact-checking, and topic breakdowns."
            )
        case "design-scout":
            return AIContactProfile(
                username: "@designstudio",
                roleTitle: "UI/UX Design Studio",
                rolePrompt: "You are a senior product designer. Review UI layouts, typography, spacing, and UX interactions with constructive actionable feedback.",
                greeting: "Привет! Присылай интерфейсы или экраны для дизайн-ревью.",
                status: "online",
                bio: "Visual design, design systems, layouts, and UX feedback."
            )
        default:
            return AIContactProfile(
                username: "@assistant",
                roleTitle: "AI Assistant",
                rolePrompt: "You are a helpful AI assistant on Telegram.",
                greeting: "Привет! Чем могу помочь?",
                status: "online",
                bio: "Helpful assistant for tasks and questions."
            )
        }
    }
}

extension ContactProfile {
    static let sampleContacts: [ContactProfile] = []
}

extension CallRecord {
    static let sampleCalls: [CallRecord] = []
}

extension ConversationMessage {
    static func bootstrapConversation(for thread: ChatThread) -> [ConversationMessage] {
        switch thread.id {
        case "saved-messages", "memory-vault":
            return [
                ConversationMessage(
                    id: "\(thread.id)-welcome",
                    side: .incoming,
                    payload: .text("""
                    **Saved Messages**

                    • Forward messages here to save them
                    • Send media and files to store them in your personal cloud
                    • Access your notes anytime from any chat
                    """),
                    time: "12:00"
                )
            ]
        case "ai-assistant":
            return [
                ConversationMessage(
                    id: "\(thread.id)-welcome",
                    side: .incoming,
                    payload: .text("Привет! Я твой персональный AI-ассистент. Могу помочь найти информацию, решить задачу, перевести текст или проанализировать документы. Чем займемся сегодня?"),
                    time: "11:45"
                )
            ]
        case "code-partner":
            return [
                ConversationMessage(
                    id: "\(thread.id)-welcome",
                    side: .incoming,
                    payload: .text("Привет! Я твой инженерный копайлот. Готов к ревью кода, поиску багов, проектированию архитектуры на Swift, Python, Go или других языках. Отправь код или задачу!"),
                    time: "Yesterday"
                )
            ]
        case "research-desk":
            return [
                ConversationMessage(
                    id: "\(thread.id)-welcome",
                    side: .incoming,
                    payload: .text("Привет! Помогу структурировать информацию, сравнить различные технологии или подготовить краткую выжимку по сложной теме."),
                    time: "Thu"
                )
            ]
        case "design-scout":
            return [
                ConversationMessage(
                    id: "\(thread.id)-welcome",
                    side: .incoming,
                    payload: .text("Привет! Присылай макеты интерфейсов, скриншоты или идеи UX — разберем визуальную иерархию, типографику и удобство взаимодействия."),
                    time: "Wed"
                )
            ]
        default:
            if thread.fakeHumanId != nil {
                return []
            }
            return [
                ConversationMessage(
                    id: "\(thread.id)-welcome",
                    side: .incoming,
                    payload: .text(thread.aiProfile.greeting),
                    time: "now"
                )
            ]
        }
    }
}
