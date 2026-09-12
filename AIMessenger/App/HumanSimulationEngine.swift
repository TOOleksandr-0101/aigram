import SwiftUI
import Combine

@MainActor
final class HumanSimulationEngine: ObservableObject {
    static let shared = HumanSimulationEngine()

    @Published var typingStatus: [String: String] = [:]
    @Published var pendingInitiations: Set<String> = []

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func statusLabel(for threadId: String) -> String? {
        typingStatus[threadId]
    }

    func scheduleInitiationIfNeeded(
        for human: FakeHuman,
        in thread: ChatThread,
        workspace: AIWorkspace
    ) {
        guard human.whoWritesFirst == .humanWritesFirst else { return }

        let currentMessages = workspace.messages(for: thread)
        let incomingCount = currentMessages.filter { $0.side == .incoming }.count
        guard incomingCount == 0 else { return }
        guard !pendingInitiations.contains(thread.id) else { return }

        pendingInitiations.insert(thread.id)

        Task {
            // Initial delay before the human picks up phone
            let initialDelay = UInt64(max(1.0, human.initialDelaySeconds) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: initialDelay)

            // Human starts typing
            self.typingStatus[thread.id] = "печатает..."

            // Simulate typing duration (2.2 to 3.5 seconds)
            try? await Task.sleep(nanoseconds: 2_500_000_000)

            self.typingStatus[thread.id] = nil
            self.pendingInitiations.remove(thread.id)

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            let msg = ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .text(human.initialMessage),
                time: formatter.string(from: Date()),
                authorName: human.name,
                authorAvatar: human.avatarKind
            )

            workspace.appendMessage(msg, to: thread)
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            AppNotificationService.shared.scheduleLocalNotification(
                title: human.name,
                subtitle: human.relationship.rawValue,
                body: human.initialMessage,
                delaySeconds: 1.0,
                threadId: thread.id
            )
        }
    }

    func handleUserMessage(
        _ text: String,
        in thread: ChatThread,
        human: FakeHuman,
        workspace: AIWorkspace,
        openRouterService: OpenRouterService
    ) async {
        var updatedHuman = human
        let lower = text.lowercased()

        // 1. Emotional Tone & Mood Detection
        let offendedWords = ["дура", "дурак", "придурок", "отвали", "заткнись", "надоел", "надоела", "хватит", "пох", "забей", "бесишь", "иди на", "ненавижу", "отстань", "ты никто", "заткни", "пошел ты", "пошла ты", "плевать"]
        let warmWords = ["прости", "извини", "скучаю", "люблю", "не обижайся", "ты лучшая", "ты лучший", "давай мириться", "как ты", "извини пожалуйста", "солнышко", "котик", "красивая", "красивый", "милая", "милый"]

        if updatedHuman.canGetOffended && offendedWords.contains(where: { lower.contains($0) }) {
            updatedHuman.currentMood = .offended
            workspace.updateFakeHuman(updatedHuman)
        } else if warmWords.contains(where: { lower.contains($0) }) {
            if updatedHuman.currentMood == .offended || updatedHuman.currentMood == .annoyed {
                updatedHuman.currentMood = .calm
                workspace.updateFakeHuman(updatedHuman)
            }
        }

        // 2. Check if user asked for voice or photo
        let wantsVoice = updatedHuman.canSendVoice && (lower.contains("голосов") || lower.contains("войс") || lower.contains("скажи") || lower.contains("кружоч"))
        let wantsPhoto = updatedHuman.canSendPhotos && (lower.contains("фото") || lower.contains("фотк") || lower.contains("селфи") || lower.contains("где ты") || lower.contains("покажи"))

        // 3. Human reading delay (1.2 to 2.2 seconds)
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // 4. Typing or Voice Recording status
        if wantsVoice {
            self.typingStatus[thread.id] = "записывает голосовое..."
        } else {
            self.typingStatus[thread.id] = "печатает..."
        }

        let typingDuration: UInt64 = wantsVoice ? 3_200_000_000 : 2_400_000_000
        try? await Task.sleep(nanoseconds: typingDuration)

        self.typingStatus[thread.id] = nil

        // 5. Generate message payload
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: Date())

        if wantsVoice {
            let spokenText = offlineVoiceTranscription(for: updatedHuman, inReplyTo: text)
            let voiceMsg = ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .voice(duration: "0:06"),
                time: currentTime,
                authorName: updatedHuman.name,
                authorAvatar: updatedHuman.avatarKind,
                transcription: spokenText,
                isTranscribed: true
            )
            workspace.appendMessage(voiceMsg, to: thread)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        if wantsPhoto {
            let photoNames = ["photo_coffee.jpg", "photo_sunset.jpg", "photo_workspace.jpg", "photo_walk.jpg"]
            let chosen = photoNames.randomElement() ?? "photo_coffee.jpg"
            let photoMsg = ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .photo(name: chosen, size: "2.3 MB"),
                time: currentTime,
                authorName: updatedHuman.name,
                authorAvatar: updatedHuman.avatarKind
            )
            workspace.appendMessage(photoMsg, to: thread)

            // Accompany with short natural caption message
            try? await Task.sleep(nanoseconds: 800_000_000)
            let captionText = photoCaption(for: updatedHuman)
            let captionMsg = ConversationMessage(
                id: UUID().uuidString,
                side: .incoming,
                payload: .text(captionText),
                time: currentTime,
                authorName: updatedHuman.name,
                authorAvatar: updatedHuman.avatarKind
            )
            workspace.appendMessage(captionMsg, to: thread)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        // Text Message generation
        var replyText: String = ""
        if workspace.isConfigured {
            do {
                replyText = try await openRouterService.sendMessage(
                    draft: text,
                    thread: thread,
                    history: workspace.messages(for: thread),
                    memoryNote: workspace.memoryNote(for: thread),
                    configuration: workspace.configurationSnapshot
                )
            } catch {
                print("[HumanSimulationEngine] OpenRouter failed: \(error)")
            }
        }

        if replyText.isEmpty {
            replyText = offlineHumanReply(for: text, human: updatedHuman)
        }

        let textMsg = ConversationMessage(
            id: UUID().uuidString,
            side: .incoming,
            payload: .text(replyText),
            time: currentTime,
            authorName: updatedHuman.name,
            authorAvatar: updatedHuman.avatarKind
        )

        workspace.appendMessage(textMsg, to: thread)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        AppNotificationService.shared.scheduleLocalNotification(
            title: updatedHuman.name,
            subtitle: updatedHuman.relationship.rawValue,
            body: replyText,
            delaySeconds: 1.0,
            threadId: thread.id
        )
    }

    func offlineHumanReply(for draft: String, human: FakeHuman) -> String {
        let lower = draft.lowercased()

        // 1. Offended state
        if human.currentMood == .offended {
            let replies = [
                "Ясно.",
                "Ладно.",
                "Ок, как скажешь.",
                "Мне сейчас некогда говорить об этом.",
                "Не пиши мне пока, пожалуйста.",
                "Ты всегда так делаешь, а потом удивляешься.",
                "Я тебя услышала. Больше вопросов нет."
            ]
            return replies.randomElement() ?? "Ясно."
        }

        // 2. Busy state
        if human.currentMood == .busy {
            let replies = [
                "Я сейчас на созвоне, напишу чуть позже ⏳",
                "Слушай, завал на работе, освобожусь — наберу!",
                "Я за рулем, напиши через час, ладно?",
                "Вижу, но сейчас не могу говорить. Позже!"
            ]
            return replies.randomElement() ?? "Сейчас занят(а), отвечу позже!"
        }

        // 3. Tired state
        if human.currentMood == .tired {
            let replies = [
                "У меня просто ноль сил сегодня... Вымоталась за весь день 🥱",
                "Голова раскалывается, давай завтра всё обсудим?",
                "Еле до кровати дошла... Ты как там?"
            ]
            return replies.randomElement() ?? "Очень устал(а) сегодня..."
        }

        // 4. Specific relationship nuances
        switch human.relationship {
        case .exPartner:
            if lower.contains("скуча") || lower.contains("вспомин") || lower.contains("встрет") {
                return "Не надо, пожалуйста... Нам обоим потом будет только больнее. Хотя я тоже скучаю, если честно."
            }
            if lower.contains("привет") || lower.contains("как ты") {
                return "Привет. Живу потихоньку, работаю. Сама не знаю, зачем ответила... Ты как?"
            }
            return "Мы же договорились оставить прошлое в прошлом. Зачем ты снова ворошишь всё это?"

        case .strictBoss:
            if lower.contains("готов") || lower.contains("отправил") || lower.contains("сделал") {
                return "Хорошо, сейчас ознакомлюсь. Если возникнут правки — верну на доработку."
            }
            if lower.contains("дедлайн") || lower.contains("срок") || lower.contains("не успева") {
                return "Срыв сроков недопустим. Подключайте коллег, но задача должна быть сдана в срок."
            }
            return "Принято к сведению. Держите меня в курсе ключевых этапов."

        case .bestFriend:
            if lower.contains("хаха") || lower.contains("мем") || lower.contains("смеш") {
                return "Ахаха, я просто ору с этого 😂 Скинь еще!"
            }
            if lower.contains("пиво") || lower.contains("бар") || lower.contains("гулять") || lower.contains("встрет") {
                return "Я только ЗА! Во сколько и где? Чур ты бронируешь столик 🍻"
            }
            return "Бро, жиза полная! Я тебе позже такое расскажу, вообще офигеешь."

        case .romanticPartner:
            if lower.contains("любл") || lower.contains("скуча") || lower.contains("целу") {
                return "И я тебя безумно люблю ❤️ Жду не дождусь вечера, чтобы обнять!"
            }
            if lower.contains("вечер") || lower.contains("ужин") || lower.contains("план") {
                return "Давай закажем пиццу и посмотрим что-нибудь уютное вместе? 🥰"
            }
            return "Солнышко, я так рада, когда ты пишешь! Как день проходит? ✨"

        case .secretCrush:
            return "Ты сегодня в ударе 😉 Приятно, что не забываешь обо мне. Чем занимаешься?"

        default:
            if human.currentMood == .flirty {
                return "А ты сегодня подозрительно внимательный... К чему бы это? 😏"
            }
            return "Интересная мысль! Слушай, а что ты сам думаешь по этому поводу?"
        }
    }

    private func offlineVoiceTranscription(for human: FakeHuman, inReplyTo: String) -> String {
        switch human.relationship {
        case .romanticPartner:
            return "Привет, любимый! Не было времени печатать, на бегу записываю. Очень соскучилась, скоро буду дома, целую!"
        case .exPartner:
            return "Слушай... текстом это сложно объяснить. Просто хотела услышать твой голос и сказать, что зла на тебя не держу."
        case .bestFriend:
            return "Короче, слушай голосовое, потому что писать пальцы отсохнут! Тема такая: мы обязаны это провернуть в эти выходные!"
        case .strictBoss:
            return "Коллега, кратко по проекту: правки принял, продолжайте выполнение в рамках согласованного плана."
        default:
            return "Привет! Решил(а) ответить голосом, так живее звучит. Надеюсь, у тебя всё отлично сегодня!"
        }
    }

    private func photoCaption(for human: FakeHuman) -> String {
        switch human.relationship {
        case .romanticPartner:
            return "Вот, держи селфи, пока никто не видит 😘"
        case .exPartner:
            return "Смотри, где я сейчас... Помнишь это место?"
        case .bestFriend:
            return "Чекай вид! Пушка просто 🔥"
        default:
            return "Вот так сейчас выглядит мой день 📸"
        }
    }
}
