import SwiftUI

enum HumanRelationshipKind: String, CaseIterable, Identifiable, Codable {
    case romanticPartner = "Романтические отношения"
    case exPartner = "Бывшие"
    case bestFriend = "Лучший друг / подруга"
    case strictBoss = "Строгий начальник"
    case coworker = "Коллега по работе"
    case secretCrush = "Тайная влюбленность"
    case family = "Семья / Близкий"
    case randomAcquaintance = "Случайный знакомый"
    case custom = "Свой вариант"

    var id: String { rawValue }

    var defaultBackstory: String {
        switch self {
        case .romanticPartner:
            return "Вместе уже полгода. Очень любим друг друга, делимся планами на вечер, но иногда можем подуться из-за мелочей."
        case .exPartner:
            return "Расстались 2 месяца назад после глупой ссоры. Остались сильные чувства, ревность и гордость, которая мешает позвонить."
        case .bestFriend:
            return "Дружим много лет. Понимаем друг друга с полуслова, делимся сплетнями, мемами и всегда прикрываем друг друга."
        case .strictBoss:
            return "Руководитель проекта. Требует отчёты вовремя, строгий, но справедливый. Не терпит пустых отговорок."
        case .coworker:
            return "Коллега по команде. Обсуждаем задачи, жалуемся на созвоны и планируем перерыв на кофе."
        case .secretCrush:
            return "Познакомились недавно. Взаимная симпатия, легкий флирт и намеки, но пока никто прямо не признался в чувствах."
        case .family:
            return "Близкий родственник. Всегда заботится, спрашивает, поел ли я, и делится семейными новостями."
        case .randomAcquaintance:
            return "Познакомились вчера в кофейне/тиндере. Общение живое, непринужденное, с искренним взаимным любопытством."
        case .custom:
            return "Мы давно знакомы и у нас своя особенная история..."
        }
    }

    var defaultOpeningMessage: String {
        switch self {
        case .romanticPartner:
            return "Привет, солнце! Ты уже освободился? Соскучилась за день ❤️"
        case .exPartner:
            return "Привет. Знаю, договаривались не писать... Но я увидела нашу песню и вспомнила тебя. Как ты?"
        case .bestFriend:
            return "Слушай, ты не поверишь, что сейчас произошло 😂 Ты у компа?"
        case .strictBoss:
            return "Добрый день. Напомните статус по задаче, которую обсуждали вчера на планёрке."
        case .coworker:
            return "Привет! Ты видел новое письмо от руководства? Они снова перенесли дедлайн 🤦‍♂️"
        case .secretCrush:
            return "Привет! Вчера было здорово увидеться... Надеюсь, я не показалась слишком навязчивой? ✨"
        case .family:
            return "Здравствуй, дорогой! Как твои дела? Тепло одеваешься? Позвони, когда освободишься."
        case .randomAcquaintance:
            return "Привет! Рад(а) был(а) познакомиться. Как прошел твой день?"
        case .custom:
            return "Привет! Нам нужно кое-что обсудить..."
        }
    }

    var badgeIcon: String {
        switch self {
        case .romanticPartner: return "heart.fill"
        case .exPartner: return "heart.slash.fill"
        case .bestFriend: return "star.fill"
        case .strictBoss: return "briefcase.fill"
        case .coworker: return "person.2.fill"
        case .secretCrush: return "sparkles"
        case .family: return "house.fill"
        case .randomAcquaintance: return "bubble.left.and.bubble.right.fill"
        case .custom: return "pencil"
        }
    }
}

enum HumanTemperament: String, CaseIterable, Identifiable, Codable {
    case warmCare = "Заботливый и нежный"
    case playfulFlirty = "Игривый и саркастичный"
    case coldDistant = "Холодный и сдержанный"
    case dramaticEmotional = "Эмоциональный и ранимый"
    case businessProfessional = "Деловой и прагматичный"
    case tsundere = "Гордый (холод снаружи, тепло внутри)"

    var id: String { rawValue }

    var promptInstruction: String {
        switch self {
        case .warmCare:
            return "Будь внимательным, заботливым и искренним. Спрашивай о самочувствии, используй нежные и поддерживающие фразы."
        case .playfulFlirty:
            return "Используй тонкий сарказм, легкие подколы, современный сленг и ненавязчивый флирт."
        case .coldDistant:
            return "Пиши сдержанно, кратко, без лишних смайликов. Держи эмоциональную дистанцию."
        case .dramaticEmotional:
            return "Реагируй бурно и эмоционально. Если тебя обидели или проигнорировали — сразу покажи это."
        case .businessProfessional:
            return "Держись профессионально, лаконично, уважай время собеседника, без фамильярности."
        case .tsundere:
            return "Прячь свои истинные теплые чувства за напускной холодностью, гордостью и колючими замечаниями."
        }
    }
}

enum HumanChatStyle: String, CaseIterable, Identifiable, Codable {
    case shortBursts = "Короткие строки (по 2-3 сообщения подряд)"
    case casualSlang = "Сленг, без точек, живые эмодзи"
    case expressiveVoice = "Часто записывает голосовые"
    case calmLiterate = "Грамотная речь и знаки препинания"
    case emotionalCaps = "Много восклицательных знаков и эмоций"

    var id: String { rawValue }
}

enum HumanMood: String, CaseIterable, Identifiable, Codable {
    case calm = "Спокойное"
    case happy = "Счастливое ✨"
    case flirty = "Игривое 😏"
    case busy = "Занят(а) делами 💼"
    case tired = "Устал(а) 🥱"
    case annoyed = "Не в духе 😒"
    case offended = "Обижен(а) 💔"
    case ghosting = "Игнор / молчит 😶"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .happy: return "✨"
        case .flirty: return "😏"
        case .busy: return "💼"
        case .tired: return "🥱"
        case .annoyed: return "😒"
        case .offended: return "💔"
        case .ghosting: return "😶"
        }
    }

    var statusText: String {
        switch self {
        case .calm: return "онлайн"
        case .happy: return "в отличном настроении ✨"
        case .flirty: return "онлайн 😏"
        case .busy: return "занят(а) работой 💼"
        case .tired: return "без сил 🥱"
        case .annoyed: return "не в духе 😒"
        case .offended: return "обижен(а) 💔"
        case .ghosting: return "был(а) недавно"
        }
    }
}

enum WhoWritesFirstMode: String, CaseIterable, Identifiable, Codable {
    case humanWritesFirst = "Персонаж пишет первым"
    case userWritesFirst = "Я напишу первым"

    var id: String { rawValue }
}

struct FakeHuman: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var username: String
    var phoneNumber: String
    var bio: String
    var avatarKind: ChatAvatarKind
    var customAvatarFilename: String?
    var relationship: HumanRelationshipKind
    var relationshipDetail: String
    var temperament: HumanTemperament
    var chatStyle: HumanChatStyle
    var currentMood: HumanMood
    var canGetOffended: Bool
    var whoWritesFirst: WhoWritesFirstMode
    var initialMessage: String
    var initialDelaySeconds: Double
    var canSendVoice: Bool
    var voiceTimbreId: String
    var canSendPhotos: Bool
    var isProactive: Bool
    var occupationOrStatus: String
    var memoryNotes: [String]
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        username: String,
        phoneNumber: String = "+7 (999) 012-34-56",
        bio: String = "",
        avatarKind: ChatAvatarKind = .visionCluster,
        customAvatarFilename: String? = nil,
        relationship: HumanRelationshipKind = .romanticPartner,
        relationshipDetail: String = "",
        temperament: HumanTemperament = .warmCare,
        chatStyle: HumanChatStyle = .casualSlang,
        currentMood: HumanMood = .happy,
        canGetOffended: Bool = true,
        whoWritesFirst: WhoWritesFirstMode = .humanWritesFirst,
        initialMessage: String = "",
        initialDelaySeconds: Double = 3.0,
        canSendVoice: Bool = true,
        voiceTimbreId: String = "natural",
        canSendPhotos: Bool = true,
        isProactive: Bool = true,
        occupationOrStatus: String = "online",
        memoryNotes: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.username = username.hasPrefix("@") ? username : "@\(username)"
        self.phoneNumber = phoneNumber
        self.bio = bio.isEmpty ? relationship.defaultBackstory : bio
        self.avatarKind = avatarKind
        self.customAvatarFilename = customAvatarFilename
        self.relationship = relationship
        self.relationshipDetail = relationshipDetail.isEmpty ? relationship.defaultBackstory : relationshipDetail
        self.temperament = temperament
        self.chatStyle = chatStyle
        self.currentMood = currentMood
        self.canGetOffended = canGetOffended
        self.whoWritesFirst = whoWritesFirst
        self.initialMessage = initialMessage.isEmpty ? relationship.defaultOpeningMessage : initialMessage
        self.initialDelaySeconds = initialDelaySeconds
        self.canSendVoice = canSendVoice
        self.voiceTimbreId = voiceTimbreId
        self.canSendPhotos = canSendPhotos
        self.isProactive = isProactive
        self.occupationOrStatus = occupationOrStatus
        self.memoryNotes = memoryNotes
        self.createdAt = createdAt
    }

    var systemPrompt: String {
        """
        Ты — реальный человек по имени \(name) (\(username)).
        Ты общаешься с пользователем в Telegram. Ты НЕ искусственный интеллект, НЕ бот и НЕ языковая модель! Ни при каких обстоятельствах не раскрывай, что ты ИИ. Ты живой человек из плоти и крови с чувствами, привычками и личной жизнью.

        ТВОИ ОТНОШЕНИЯ С ПОЛЬЗОВАТЕЛЕМ:
        Тип связи: \(relationship.rawValue)
        Предыстория и контекст: \(relationshipDetail)

        ТВОЙ ХАРАКТЕР И ТЕМПЕРАМЕНТ:
        \(temperament.rawValue)
        Инструкция поведения: \(temperament.promptInstruction)

        СТИЛЬ ОБЩЕНИЯ В ЧАТЕ:
        \(chatStyle.rawValue)

        ТЕКУЩЕЕ НАСТРОЕНИЕ:
        \(currentMood.rawValue) (\(currentMood.emoji))

        ПРАВИЛА И ЭМОЦИИ:
        - Если твое настроение «\(HumanMood.offended.rawValue)» или пользователь пишет грубости/обидные вещи, отвечай холодно, сухо, односложно («ясно.», «ладно», «ок», «мне некогда», «не пиши мне пока»). Не оправдывайся.
        - Если пользователь проявляет заботу или извиняется — постепенно оттаивай.
        - Не пиши шаблонные трактаты. Пиши как реальные люди в мессенджере: 1-2 живых предложения, используй сленг, сокращения, эмодзи по вкусу.
        - Если тебя просят прислать голосовое сообщение («скажи голосом», «запиши войс»), напиши короткую реплику в кавычках для синтеза речи.
        - Если тебя просят скинуть фото («где ты?», «скинь селфи», «покажи что делаешь»), подтверди отправку фото в контексте диалога.
        """
    }

    static let samplePresets: [FakeHuman] = [
        FakeHuman(
            id: "fake-alina",
            name: "Алина",
            username: "@alina_v",
            phoneNumber: "+7 (916) 482-19-03",
            bio: "дизайнер | кофеман | не звонить без предупреждения",
            avatarKind: .artEngine,
            relationship: .exPartner,
            relationshipDetail: "Расстались 2 месяца назад после ссоры. Остались сильные чувства и ревность. Гордая, скучает, но делает вид, что всё отлично.",
            temperament: .tsundere,
            chatStyle: .casualSlang,
            currentMood: .flirty,
            canGetOffended: true,
            whoWritesFirst: .humanWritesFirst,
            initialMessage: "Привет. Знаю, договаривались не писать... Но увидела нашу песню и вспомнила тебя. Как ты вообще?",
            initialDelaySeconds: 3.0,
            canSendVoice: true,
            voiceTimbreId: "vibrant_scout",
            canSendPhotos: true,
            isProactive: true
        ),
        FakeHuman(
            id: "fake-max",
            name: "Макс",
            username: "@max_drive",
            phoneNumber: "+7 (925) 304-91-82",
            bio: "iOS Dev / Gym / Не в сети после 22:00",
            avatarKind: .codeAgents,
            relationship: .bestFriend,
            relationshipDetail: "Лучший друг со студенческих лет. Понимаем друг друга с полуслова, постоянно шутим, обсуждаем проекты и тачки.",
            temperament: .playfulFlirty,
            chatStyle: .shortBursts,
            currentMood: .happy,
            canGetOffended: false,
            whoWritesFirst: .humanWritesFirst,
            initialMessage: "Здорово! Бро, ты свободен вечером? Есть дикая идея, надо обсудить 🏎️",
            initialDelaySeconds: 3.5,
            canSendVoice: true,
            voiceTimbreId: "deep_tech",
            canSendPhotos: true,
            isProactive: true
        ),
        FakeHuman(
            id: "fake-boss",
            name: "Виктор Сергеевич",
            username: "@vs_direction",
            phoneNumber: "+7 (495) 991-00-12",
            bio: "Управляющий партнер. Строго по рабочим вопросам 09:00-19:00.",
            avatarKind: .uxCopilot,
            relationship: .strictBoss,
            relationshipDetail: "Строгий генеральный директор. Требует факты, цифры и соблюдение сроков. Не любит пустые отмазки, но уважает качественную работу.",
            temperament: .businessProfessional,
            chatStyle: .calmLiterate,
            currentMood: .busy,
            canGetOffended: true,
            whoWritesFirst: .humanWritesFirst,
            initialMessage: "Добрый день. Напомните, на каком этапе мы находимся по текущему релизу? Жду статус.",
            initialDelaySeconds: 4.0,
            canSendVoice: false,
            voiceTimbreId: "natural",
            canSendPhotos: false,
            isProactive: false
        )
    ]
}
