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
    let firstName: String
    let lastName: String
    let username: String
    let mainPhone: String
    let homePhone: String
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
            id: "saved-prompts",
            title: "Saved Prompts",
            headline: "midjourney-v6.txt",
            detail: nil,
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
            id: "vision-cluster",
            title: "Vision Cluster",
            headline: "Pixel Tutor",
            detail: "GIF",
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
            id: "tutor-gpt",
            title: "Tutor GPT",
            headline: "Let's choose the first option",
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
            id: "ux-copilot",
            title: "UX Copilot",
            headline: "Robot Sketch. Analyst",
            detail: "Turn your ideas into incredible wor...",
            time: "11:30",
            badge: "153",
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
            id: "research-bot",
            title: "Research Bot",
            headline: "What about a super idea?",
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
            id: "art-engine",
            title: "Art Engine",
            headline: "Photo",
            detail: nil,
            time: "10:42",
            badge: "17",
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
            id: "code-agents",
            title: "Code Agents",
            headline: "Wave IOS 13 Design Kit.",
            detail: "Turn your ideas into incredible wor...",
            time: "Sat",
            badge: "32",
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
}

extension ContactProfile {
    static let sampleContacts: [ContactProfile] = [
        ContactProfile(
            id: "joshua",
            firstName: "Joshua",
            lastName: "Lawrence",
            username: "@joshua_law",
            mainPhone: "+998 97 444 67 17",
            homePhone: "+998 90 934 50 44",
            bio: "Design adds value faster, than it adds cost",
            presence: .online,
            avatar: .tutor
        ),
        ContactProfile(
            id: "andrew",
            firstName: "Andrew",
            lastName: "Parker",
            username: "@andrew_parker",
            mainPhone: "+1 202 555 0105",
            homePhone: "+1 202 555 0128",
            bio: "Researching product ideas and UX systems.",
            presence: .online,
            avatar: .visionCluster
        ),
        ContactProfile(
            id: "martin",
            firstName: "Martin",
            lastName: "Randolph",
            username: "@martin_r",
            mainPhone: "+1 202 555 0139",
            homePhone: "+1 202 555 0188",
            bio: "Focused on speech interfaces and tutoring flows.",
            presence: .online,
            avatar: .researchBot
        ),
        ContactProfile(
            id: "kieron",
            firstName: "Kieron",
            lastName: "Dotson",
            username: "@kieron",
            mainPhone: "+1 202 555 0174",
            homePhone: "+1 202 555 0141",
            bio: "Prototype reviewer for AI assistants.",
            presence: .lastSeen("last seen 10 minutes ago"),
            avatar: .artEngine
        ),
        ContactProfile(
            id: "zack",
            firstName: "Zack",
            lastName: "John",
            username: "@zack_life",
            mainPhone: "+998 97 444 67 17",
            homePhone: "+998 90 934 50 44",
            bio: "Design adds value faster, than it adds cost",
            presence: .lastSeen("last seen 25 minutes ago"),
            avatar: .uxCopilot
        ),
        ContactProfile(
            id: "karen",
            firstName: "Karen",
            lastName: "Castillo",
            username: "@karen_cast",
            mainPhone: "+1 202 555 0162",
            homePhone: "+1 202 555 0182",
            bio: "QA and feedback loops for AI products.",
            presence: .lastSeen("last seen 1 hour ago"),
            avatar: .saved
        ),
        ContactProfile(
            id: "jamie",
            firstName: "Jamie",
            lastName: "Franco",
            username: "@jamiefranco",
            mainPhone: "+1 202 555 0133",
            homePhone: "+1 202 555 0119",
            bio: "Visual prototyping and user testing notes.",
            presence: .lastSeen("last seen 2 hours ago"),
            avatar: .codeAgents
        )
    ]
}

extension CallRecord {
    static let sampleCalls: [CallRecord] = [
        CallRecord(id: "call-1", name: "Martin Randolph", detail: "Outgoing (2 min)", date: "10/13", avatar: .researchBot, direction: .outgoing),
        CallRecord(id: "call-2", name: "Zack John", detail: "Incoming", date: "9/24", avatar: .uxCopilot, direction: .incoming),
        CallRecord(id: "call-3", name: "Martha Craig", detail: "Incoming", date: "9/10", avatar: .visionCluster, direction: .incoming),
        CallRecord(id: "call-4", name: "Kieron Dotson", detail: "Outgoing", date: "10/8", avatar: .artEngine, direction: .outgoing),
        CallRecord(id: "call-5", name: "Maisy Humphrey", detail: "Outgoing", date: "9/6", avatar: .saved, direction: .outgoing),
        CallRecord(id: "call-6", name: "Karen Castillo", detail: "Outgoing, Incoming", date: "10/11", avatar: .saved, direction: .mixed),
        CallRecord(id: "call-7", name: "Jamie Franco", detail: "Missed", date: "8/22", avatar: .codeAgents, direction: .missed)
    ]
}

extension ConversationMessage {
    static let sampleConversation: [ConversationMessage] = [
        ConversationMessage(id: "msg-1", side: .incoming, payload: .text("Good morning!"), time: "11:40"),
        ConversationMessage(id: "msg-2", side: .incoming, payload: .text("Do you know what time is it?"), time: "11:40"),
        ConversationMessage(id: "msg-3", side: .outgoing, payload: .text("What is the most popular meal in Japan?"), time: "11:45"),
        ConversationMessage(id: "msg-4", side: .incoming, payload: .text("It's morning in Tokyo"), time: "11:43"),
        ConversationMessage(id: "msg-5", side: .incoming, payload: .emoji("😎"), time: "11:43"),
        ConversationMessage(id: "msg-6", side: .outgoing, payload: .text("Japan looks amazing!"), time: "10:10"),
        ConversationMessage(id: "msg-7", side: .incoming, payload: .text("I think top two are:"), time: "11:50"),
        ConversationMessage(id: "msg-8", side: .incoming, payload: .text("Good morning!"), time: "10:10"),
        ConversationMessage(id: "msg-9", side: .outgoing, payload: .text("Do you like it?"), time: "11:45"),
        ConversationMessage(id: "msg-10", side: .outgoing, payload: .photo(name: "IMG_0484.PNG", size: "2.6 MB"), time: "11:51"),
        ConversationMessage(id: "msg-11", side: .outgoing, payload: .photo(name: "IMG_0481.PNG", size: "2.8 MB"), time: "10:15"),
        ConversationMessage(id: "msg-12", side: .outgoing, payload: .photo(name: "IMG_0483.PNG", size: "2.8 MB"), time: "11:51"),
        ConversationMessage(id: "msg-13", side: .outgoing, payload: .photo(name: "IMG_0475.PNG", size: "2.4 MB"), time: "10:15")
    ]
}
