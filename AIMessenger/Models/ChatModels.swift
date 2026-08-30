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

enum ChatAvatarKind {
    case saved
    case visionCluster
    case tutor
    case uxCopilot
    case researchBot
    case artEngine
    case codeAgents
}

struct ChatThread: Identifiable, Hashable {
    let id: String
    let title: String
    let headline: String
    let detail: String?
    let time: String
    let badge: String?
    let badgeBright: Bool
    let isMuted: Bool
    let isPinned: Bool
    let online: Bool
    let revealSide: SwipeRevealSide
    let deliveryState: DeliveryState
    let groupedBackground: Bool
    let avatar: ChatAvatarKind
}

struct AIContactProfile: Hashable {
    let username: String
    let roleTitle: String
    let rolePrompt: String
    let greeting: String
    let status: String
    let bio: String
}

struct ConversationMessage: Identifiable, Hashable {
    enum Side: Hashable {
        case incoming
        case outgoing
    }

    enum Payload: Hashable {
        case text(String)
        case emoji(String)
        case photo(name: String, size: String)
    }

    let id: String
    let side: Side
    let payload: Payload
    let time: String
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
    let displayName: String
    let username: String
    let roleTitle: String
    let bio: String
    let presence: PresenceState
    let avatar: ChatAvatarKind
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
            avatar: .saved
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
            online: false,
            revealSide: .none,
            deliveryState: .read,
            groupedBackground: true,
            avatar: .visionCluster
        ),
        ChatThread(
            id: "study-room",
            title: "Study Room",
            headline: "I turned the topic into 5 flashcards.",
            detail: nil,
            time: "Sun",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: true,
            online: false,
            revealSide: .left,
            deliveryState: .none,
            groupedBackground: true,
            avatar: .tutor
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
            avatar: .uxCopilot
        ),
        ChatThread(
            id: "research-desk",
            title: "Research Desk",
            headline: "I compared the 4 APIs for you.",
            detail: nil,
            time: "13:25",
            badge: nil,
            badgeBright: false,
            isMuted: false,
            isPinned: false,
            online: true,
            revealSide: .right,
            deliveryState: .read,
            groupedBackground: false,
            avatar: .researchBot
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
            avatar: .artEngine
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
            avatar: .codeAgents
        )
    ]

    var aiProfile: AIContactProfile {
        switch id {
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
        let intro = thread.aiProfile.greeting

        return [
            ConversationMessage(
                id: "\(thread.id)-hello",
                side: .incoming,
                payload: .text(intro),
                time: "now"
            )
        ]
    }

    static let sampleConversation: [ConversationMessage] = [
        ConversationMessage(id: "msg-1", side: .incoming, payload: .text("Send me the brief and I'll summarize the moving parts first."), time: "11:40"),
        ConversationMessage(id: "msg-2", side: .outgoing, payload: .text("I need a simpler plan for the project."), time: "11:41"),
        ConversationMessage(id: "msg-3", side: .incoming, payload: .text("Sure. I can give you a short version, a step-by-step version, or a deadline-first version."), time: "11:42"),
        ConversationMessage(id: "msg-4", side: .outgoing, payload: .text("Let's do step by step."), time: "11:43"),
        ConversationMessage(id: "msg-5", side: .incoming, payload: .emoji("👍"), time: "11:43"),
        ConversationMessage(id: "msg-6", side: .incoming, payload: .text("Step 1: define the outcome. Step 2: list the screens. Step 3: connect the live model."), time: "11:44"),
        ConversationMessage(id: "msg-7", side: .outgoing, payload: .photo(name: "screen-draft.png", size: "2.6 MB"), time: "11:45")
    ]
}
