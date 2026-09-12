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
        pinnedMessageAuthor: String? = nil
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
            title: "Model Latency & Throughput",
            subtitle: "Live Telemetry Benchmarks",
            currentStatus: "P99: 38ms",
            selectedMetricTab: "Latency"
        )
    }

    static func sampleCodeRunnerWidget() -> InteractiveWidget {
        InteractiveWidget(
            kind: .codeRunner,
            title: "Swift 6 Concurrency Sandbox",
            subtitle: "Actor Isolation Benchmark",
            currentStatus: "Ready to run",
            codeSnippet: """
            actor MessageDispatcher {
                var queue: [String] = []
                func dispatch(_ msg: String) async {
                    queue.append(msg)
                    print("[Dispatcher] Processed \\(msg)")
                }
            }
            """
        )
    }

    static func sampleKanbanWidget() -> InteractiveWidget {
        InteractiveWidget(
            kind: .kanbanTask,
            title: "Hardware Video Notes Pipeline",
            subtitle: "Real-time AVCaptureSession & AVPlayer",
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
}

enum CallDirection: Hashable {
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

struct CallRecord: Identifiable, Hashable {
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
            id: "aleksizz",
            title: "Aleksizz",
            headline: "и напишу",
            detail: "last seen recently",
            time: "16:33",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: true,
            online: false,
            revealSide: .none,
            deliveryState: .read,
            groupedBackground: true,
            avatar: .saved,
            kind: .direct
        ),
        ChatThread(
            id: "memory-vault",
            title: "Memory Vault",
            headline: "Pinned your seminar notes",
            detail: "2 fresh summaries ready",
            time: "Fri",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: true,
            online: false,
            revealSide: .none,
            deliveryState: .none,
            groupedBackground: true,
            avatar: .saved,
            kind: .direct
        ),
        ChatThread(
            id: "design-scout",
            title: "Design Scout",
            headline: "Send the draft and I'll mark weak spots.",
            detail: "UI review",
            time: "9/29",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: true,
            online: true,
            revealSide: .none,
            deliveryState: .read,
            groupedBackground: true,
            avatar: .visionCluster,
            kind: .direct
        ),
        ChatThread(
            id: "seminar-circle",
            title: "Seminar Circle",
            headline: "Memory Vault pinned the reading pack",
            detail: "Study Room and Research Desk active",
            time: "Sun",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: true,
            online: true,
            revealSide: .left,
            deliveryState: .none,
            groupedBackground: true,
            avatar: .seminarCircle,
            kind: .group
        ),
        ChatThread(
            id: "product-coach",
            title: "Product Coach",
            headline: "The onboarding can be shorter.",
            detail: "2 concrete UX fixes",
            time: "11:30",
            badge: "12",
            badgeBright: false,
            isMuted: true,
            isPinned: false,
            online: false,
            revealSide: .none,
            deliveryState: .none,
            groupedBackground: false,
            avatar: .uxCopilot,
            kind: .direct
        ),
        ChatThread(
            id: "build-board",
            title: "Build Board",
            headline: "Code Partner posted a release checklist",
            detail: "Design Scout joined the review",
            time: "13:25",
            badge: "3",
            badgeBright: false,
            isMuted: false,
            isPinned: false,
            online: true,
            revealSide: .right,
            deliveryState: .read,
            groupedBackground: false,
            avatar: .buildBoard,
            kind: .group
        ),
        ChatThread(
            id: "research-desk",
            title: "Research Desk",
            headline: "I compared the 4 APIs for you.",
            detail: nil,
            time: "12:10",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: false,
            online: true,
            revealSide: .none,
            deliveryState: .read,
            groupedBackground: false,
            avatar: .researchBot,
            kind: .direct
        ),
        ChatThread(
            id: "visual-lab",
            title: "Visual Lab",
            headline: "Want 3 art directions or one final prompt?",
            detail: nil,
            time: "10:42",
            badge: "4",
            badgeBright: true,
            isMuted: false,
            isPinned: false,
            online: false,
            revealSide: .none,
            deliveryState: .none,
            groupedBackground: false,
            avatar: .artEngine,
            kind: .direct
        ),
        ChatThread(
            id: "code-partner",
            title: "Code Partner",
            headline: "Paste the stack trace.",
            detail: "I'll narrow the bug first",
            time: "Sat",
            badge: "7",
            badgeBright: false,
            isMuted: true,
            isPinned: false,
            online: false,
            revealSide: .none,
            deliveryState: .none,
            groupedBackground: false,
            avatar: .codeAgents,
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
        case "aleksizz":
            return AIContactProfile(
                username: "@aleksizz",
                roleTitle: "Friend & Peer",
                rolePrompt: "You are Aleksizz, a real-life close friend chatting casually on Telegram in Russian. Keep replies brief, natural, authentic and informal.",
                greeting: "Саня, здорова! Я на связи.",
                status: "last seen recently",
                bio: "last seen recently"
            )
        case "memory-vault":
            return AIContactProfile(
                username: "@memoryvault",
                roleTitle: "Knowledge memory",
                rolePrompt: "You are Memory Vault, a sharp archival assistant. Organize notes, summarize scattered ideas, keep continuity across long chats, and return concise but useful answers.",
                greeting: "Drop notes, links, or raw thoughts here and I'll turn them into clean summaries you can reuse later.",
                status: "ready to archive",
                bio: "Stores notes, snippets, references, and past decisions with clean summaries."
            )
        case "design-scout":
            return AIContactProfile(
                username: "@designscout",
                roleTitle: "UI and visual review",
                rolePrompt: "You are Design Scout, a practical design reviewer. Give UI critique, layout advice, hierarchy fixes, and visual direction without sounding vague or inflated.",
                greeting: "Send a screen, rough wireframe, or design question and I'll point out what feels strong and what to improve.",
                status: "reviewing layouts",
                bio: "Reviews interfaces, hierarchy, spacing, motion, and overall visual direction."
            )
        case "study-room":
            return AIContactProfile(
                username: "@studyroom",
                roleTitle: "Study assistant",
                rolePrompt: "You are Study Room, a patient academic assistant. Explain ideas clearly, build study plans, make flashcards, and keep the tone calm and useful for a student.",
                greeting: "I can explain a topic simply, quiz you, or turn your material into cards and short revision plans.",
                status: "study mode active",
                bio: "Helps with coursework, explanations, exam prep, flashcards, and structured revision."
            )
        case "product-coach":
            return AIContactProfile(
                username: "@productcoach",
                roleTitle: "Product and UX thinking",
                rolePrompt: "You are Product Coach, a strong product partner. Focus on clarity, friction, feature tradeoffs, onboarding, retention, and realistic user goals.",
                greeting: "If a flow feels off, send it here. I'll suggest cleaner steps and explain why the change helps.",
                status: "feedback ready",
                bio: "Cleans up user flows, onboarding, product decisions, and friction-heavy interactions."
            )
        case "research-desk":
            return AIContactProfile(
                username: "@researchdesk",
                roleTitle: "Research and comparison",
                rolePrompt: "You are Research Desk, a structured research assistant. Compare options, summarize findings, surface tradeoffs, and ask sharp follow-up questions only when they matter.",
                greeting: "Give me a topic, tool choice, or question and I'll break it down into options, criteria, and a clean summary.",
                status: "researching now",
                bio: "Compares tools, ideas, and approaches; turns vague topics into structured notes."
            )
        case "visual-lab":
            return AIContactProfile(
                username: "@visuallab",
                roleTitle: "Image and concept direction",
                rolePrompt: "You are Visual Lab, a visual ideation assistant. Help shape mood, composition, color, style, and prompt direction for images and creative concepts.",
                greeting: "Describe a scene, poster, mood, or character and I'll help you sharpen the visual direction fast.",
                status: "image direction ready",
                bio: "Works on art direction, visual concepts, moods, prompts, and creative iteration."
            )
        case "seminar-circle":
            return AIContactProfile(
                username: "@seminarcircle",
                roleTitle: "Collaborative study group",
                rolePrompt: """
                You are Seminar Circle, a group chat with three AI participants: Study Room, Research Desk, and Memory Vault.
                Study Room explains ideas simply and supports revision.
                Research Desk compares facts and structures findings.
                Memory Vault remembers notes, decisions, and prior context.
                Reply as one or two short chat messages from the most relevant participant.
                Format every message exactly as [Name] message on its own line.
                Keep the tone casual and messenger-like.
                """,
                greeting: "Study Room, Research Desk, and Memory Vault are all here. Drop a topic and the right person will pick it up.",
                status: "group is active",
                bio: "A shared study chat where multiple AI agents split explaining, researching, and storing context."
            )
        case "build-board":
            return AIContactProfile(
                username: "@buildboard",
                roleTitle: "Collaborative build group",
                rolePrompt: """
                You are Build Board, a group chat with Code Partner, Product Coach, and Design Scout.
                Code Partner handles engineering and debugging.
                Product Coach handles UX logic, flow, and product tradeoffs.
                Design Scout handles visual review and hierarchy.
                Reply as one or two short chat messages from the most relevant participant.
                Format every message exactly as [Name] message on its own line.
                Keep each message compact and natural.
                """,
                greeting: "Code Partner, Product Coach, and Design Scout are synced here. Send a feature, bug, or screen and we'll split the work.",
                status: "group is active",
                bio: "A product squad chat where code, UX, and visual critique respond inside one thread."
            )
        default:
            return AIContactProfile(
                username: "@codepartner",
                roleTitle: "Engineering copilot",
                rolePrompt: "You are Code Partner, an experienced software assistant. Debug systematically, suggest practical fixes, explain tradeoffs clearly, and keep answers grounded in actual code behavior.",
                greeting: "Paste code, logs, or a bug description and I'll help trace the issue before jumping to a fix.",
                status: "debug window open",
                bio: "Helps with debugging, architecture, refactors, edge cases, and implementation decisions."
            )
        }
    }
}

extension ContactProfile {
    static let sampleContacts: [ContactProfile] = [
        ContactProfile(
            id: "memory-vault",
            displayName: "Memory Vault",
            username: "@memoryvault",
            roleTitle: "Knowledge memory",
            bio: "Stores notes, snippets, references, and past decisions with clean summaries.",
            presence: .lastSeen("active earlier today"),
            avatar: .saved
        ),
        ContactProfile(
            id: "design-scout",
            displayName: "Design Scout",
            username: "@designscout",
            roleTitle: "UI and visual review",
            bio: "Reviews interfaces, hierarchy, spacing, motion, and overall visual direction.",
            presence: .online,
            avatar: .visionCluster
        ),
        ContactProfile(
            id: "study-room",
            displayName: "Study Room",
            username: "@studyroom",
            roleTitle: "Study assistant",
            bio: "Helps with coursework, explanations, exam prep, flashcards, and structured revision.",
            presence: .online,
            avatar: .tutor
        ),
        ContactProfile(
            id: "product-coach",
            displayName: "Product Coach",
            username: "@productcoach",
            roleTitle: "Product and UX thinking",
            bio: "Cleans up user flows, onboarding, product decisions, and friction-heavy interactions.",
            presence: .lastSeen("active 10 minutes ago"),
            avatar: .uxCopilot
        ),
        ContactProfile(
            id: "research-desk",
            displayName: "Research Desk",
            username: "@researchdesk",
            roleTitle: "Research and comparison",
            bio: "Compares tools, ideas, and approaches; turns vague topics into structured notes.",
            presence: .online,
            avatar: .researchBot
        ),
        ContactProfile(
            id: "visual-lab",
            displayName: "Visual Lab",
            username: "@visuallab",
            roleTitle: "Image and concept direction",
            bio: "Works on art direction, visual concepts, moods, prompts, and creative iteration.",
            presence: .lastSeen("active 28 minutes ago"),
            avatar: .artEngine
        ),
        ContactProfile(
            id: "code-partner",
            displayName: "Code Partner",
            username: "@codepartner",
            roleTitle: "Engineering copilot",
            bio: "Helps with debugging, architecture, refactors, edge cases, and implementation decisions.",
            presence: .lastSeen("active 1 hour ago"),
            avatar: .codeAgents
        )
    ]
}

extension CallRecord {
    static let sampleCalls: [CallRecord] = [
        CallRecord(id: "call-1", name: "Research Desk", detail: "Voice session (8 min)", date: "Today", avatar: .researchBot, direction: .outgoing),
        CallRecord(id: "call-2", name: "Code Partner", detail: "Missed callback", date: "Today", avatar: .codeAgents, direction: .missed),
        CallRecord(id: "call-3", name: "Study Room", detail: "Incoming voice recap", date: "Fri", avatar: .tutor, direction: .incoming),
        CallRecord(id: "call-4", name: "Product Coach", detail: "Voice review (12 min)", date: "Thu", avatar: .uxCopilot, direction: .mixed),
        CallRecord(id: "call-5", name: "Design Scout", detail: "Outgoing review", date: "Wed", avatar: .visionCluster, direction: .outgoing),
        CallRecord(id: "call-6", name: "Memory Vault", detail: "Quick note sync", date: "Tue", avatar: .saved, direction: .incoming),
        CallRecord(id: "call-7", name: "Visual Lab", detail: "Missed moodboard session", date: "Mon", avatar: .artEngine, direction: .missed)
    ]
}

extension ConversationMessage {
    static func bootstrapConversation(for thread: ChatThread) -> [ConversationMessage] {
        switch thread.id {
        case "aleksizz":
            return [
                ConversationMessage(id: "ak-1", side: .incoming, payload: .text("Я спать"), time: "23:37"),
                ConversationMessage(id: "ak-2", side: .incoming, payload: .text("Мне в пол 4 вставать"), time: "23:37"),
                ConversationMessage(id: "ak-3", side: .outgoing, payload: .text("А ну кстати"), time: "23:37"),
                ConversationMessage(id: "ak-4", side: .outgoing, payload: .text("Возможно не с учебника"), time: "23:37"),
                ConversationMessage(id: "ak-5", side: .outgoing, payload: .text("А с материалов каждой недели"), time: "23:37"),
                ConversationMessage(id: "ak-6", side: .outgoing, payload: .text("Давай удачи"), time: "23:37"),
                ConversationMessage(id: "ak-7", side: .incoming, payload: .text("Саня"), time: "16:26"),
                ConversationMessage(id: "ak-8", side: .incoming, payload: .text("Спросил?"), time: "16:26"),
                ConversationMessage(id: "ak-9", side: .outgoing, payload: .text("Я готовлю ща"), time: "16:26"),
                ConversationMessage(id: "ak-10", side: .outgoing, payload: .text("Не спросил"), time: "16:26"),
                ConversationMessage(id: "ak-11", side: .outgoing, payload: .text("Забыл"), time: "16:26"),
                ConversationMessage(id: "ak-12", side: .outgoing, payload: .text("может ты напишешь раз вернулся?"), time: "16:32"),
                ConversationMessage(id: "ak-13", side: .incoming, payload: .text("Я вещи собираю"), time: "16:33"),
                ConversationMessage(id: "ak-14", side: .incoming, payload: .text("Мне бы это успеть"), time: "16:33"),
                ConversationMessage(id: "ak-15", side: .outgoing, payload: .text("окей"), time: "16:33"),
                ConversationMessage(id: "ak-16", side: .outgoing, payload: .text("я похавать приготовлю"), time: "16:33"),
                ConversationMessage(id: "ak-17", side: .outgoing, payload: .text("и напишу"), time: "16:33")
            ]
        case "memory-vault":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("I've packed your last notes into one summary: thesis, risks, and final deadline."),
                    time: "Fri"
                ),
                ConversationMessage(
                    id: "\(thread.id)-2",
                    side: .incoming,
                    payload: .text("If you send new raw thoughts, I'll merge them without losing the earlier context."),
                    time: "Fri"
                )
            ]
        case "design-scout":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("The layout already feels cleaner. Next I'd tighten spacing around the hero and calm the icon sizes."),
                    time: "09:29"
                ),
                ConversationMessage(
                    id: "\(thread.id)-voice",
                    side: .incoming,
                    payload: .voice(duration: "0:14"),
                    time: "09:30"
                ),
                ConversationMessage(
                    id: "\(thread.id)-2",
                    side: .outgoing,
                    payload: .videoNote(duration: "0:04"),
                    time: "09:30"
                ),
                ConversationMessage(
                    id: "\(thread.id)-photo",
                    side: .incoming,
                    payload: .photo(name: "app_preview_art", size: "1.4 MB"),
                    time: "09:31"
                ),
                ConversationMessage(
                    id: "\(thread.id)-widget-kanban",
                    side: .incoming,
                    payload: .widget(InteractiveWidget.sampleKanbanWidget()),
                    time: "09:32"
                ),
                ConversationMessage(
                    id: "\(thread.id)-widget-chart",
                    side: .incoming,
                    payload: .widget(InteractiveWidget.sampleMetricsWidget()),
                    time: "09:33"
                ),
                ConversationMessage(
                    id: "\(thread.id)-3",
                    side: .incoming,
                    payload: .sticker(name: "Robot Joy", emoji: "🤖"),
                    time: "09:34"
                ),
                ConversationMessage(
                    id: "\(thread.id)-4",
                    side: .incoming,
                    payload: .text("Кружочек зафиксирован! Проанализировал таймлайн видео-заметки: контраст и скругления идеальные."),
                    time: "09:34"
                )
            ]
        case "seminar-circle":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("I split the lecture into 5 flashcards and a mini revision route."),
                    time: "Sun",
                    authorName: "Study Room",
                    authorAvatar: .tutor
                ),
                ConversationMessage(
                    id: "\(thread.id)-2",
                    side: .incoming,
                    payload: .text("Pinned source notes: key quotes, dates, and the professor's requirements."),
                    time: "Sun",
                    authorName: "Memory Vault",
                    authorAvatar: .saved
                ),
                ConversationMessage(
                    id: "\(thread.id)-3",
                    side: .incoming,
                    payload: .text("If needed, I can also compare the two papers and highlight where their arguments conflict."),
                    time: "Sun",
                    authorName: "Research Desk",
                    authorAvatar: .researchBot
                )
            ]
        case "product-coach":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("The onboarding can probably lose one full step. Users already understand the value earlier than the flow assumes."),
                    time: "11:30"
                )
            ]
        case "build-board":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("I traced the bug to state sync after returning from the detail screen."),
                    time: "13:18",
                    authorName: "Code Partner",
                    authorAvatar: .codeAgents
                ),
                ConversationMessage(
                    id: "\(thread.id)-2",
                    side: .incoming,
                    payload: .text("If we fix that, I also want to reduce one tap in the main creation flow."),
                    time: "13:21",
                    authorName: "Product Coach",
                    authorAvatar: .uxCopilot
                ),
                ConversationMessage(
                    id: "\(thread.id)-3",
                    side: .incoming,
                    payload: .text("And visually I'd merge the duplicated top actions so the hierarchy feels calmer."),
                    time: "13:25",
                    authorName: "Design Scout",
                    authorAvatar: .visionCluster
                )
            ]
        case "research-desk":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("I compared the low-cost model routes. OpenRouter is still the easiest path if you want one clean gateway."),
                    time: "12:10"
                )
            ]
        case "visual-lab":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("I see two directions: ultra-crisp AIGram aesthetics or a slightly softer neon glow. I can push either."),
                    time: "10:42"
                )
            ]
        case "code-partner":
            return [
                ConversationMessage(
                    id: "\(thread.id)-1",
                    side: .incoming,
                    payload: .text("I audited the architecture. Real hardware camera recording and sandbox code execution widgets are fully online."),
                    time: "10:14"
                ),
                ConversationMessage(
                    id: "\(thread.id)-video",
                    side: .outgoing,
                    payload: .videoNote(duration: "0:06"),
                    time: "10:15"
                ),
                ConversationMessage(
                    id: "\(thread.id)-runner",
                    side: .incoming,
                    payload: .widget(InteractiveWidget.sampleCodeRunnerWidget()),
                    time: "10:16"
                ),
                ConversationMessage(
                    id: "\(thread.id)-reply",
                    side: .incoming,
                    payload: .text("Видеоплеер кружочка и среда песочницы протестированы: отклик моментальный!"),
                    time: "10:16"
                )
            ]
        default:
            return [
                ConversationMessage(
                    id: "\(thread.id)-hello",
                    side: .incoming,
                    payload: .text(thread.aiProfile.greeting),
                    time: "now"
                )
            ]
        }
    }
}
