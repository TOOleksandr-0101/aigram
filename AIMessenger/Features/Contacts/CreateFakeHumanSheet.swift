import SwiftUI
import PhotosUI

struct CreateFakeHumanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var phoneNumber: String = "+7 (999) 012-34-56"
    @State private var bio: String = ""
    @State private var selectedAvatar: ChatAvatarKind = .artEngine
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var customAvatarFilename: String? = nil
    @State private var customAvatarImage: UIImage? = nil

    @State private var relationship: HumanRelationshipKind = .exPartner
    @State private var relationshipDetail: String = ""
    @State private var temperament: HumanTemperament = .tsundere
    @State private var chatStyle: HumanChatStyle = .casualSlang
    @State private var currentMood: HumanMood = .flirty
    @State private var canGetOffended: Bool = true

    @State private var whoWritesFirst: WhoWritesFirstMode = .humanWritesFirst
    @State private var initialMessage: String = ""
    @State private var initialDelaySeconds: Double = 3.0

    @State private var canSendVoice: Bool = true
    @State private var canSendPhotos: Bool = true
    @State private var isProactive: Bool = true

    private let availableAvatars: [ChatAvatarKind] = [
        .artEngine,
        .visionCluster,
        .codeAgents,
        .uxCopilot,
        .tutor,
        .researchBot,
        .saved
    ]

    var body: some View {
        NavigationStack {
            Form {
                presetsSection

                identitySection

                relationshipSection

                characterSection

                initiationSection

                autonomySection
            }
            .scrollContentBackground(.hidden)
            .background(TelegramPalette.backgroundPrimary)
            .navigationTitle("Создать Fake Human")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(TelegramPalette.accentBlue)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveFakeHuman()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? TelegramPalette.mutedText : TelegramPalette.accentBlue)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    let filename = "avatar_\(UUID().uuidString).jpg"
                    if MediaStorageService.shared.saveImage(data: data, filename: filename) != nil {
                        customAvatarFilename = filename
                        customAvatarImage = image
                    }
                }
            }
            .onAppear {
                applyRelationshipDefaults(relationship)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var presetsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("БЫСТРЫЕ ШАБЛОНЫ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TelegramPalette.mutedText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FakeHuman.samplePresets) { preset in
                            Button {
                                loadPreset(preset)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: preset.relationship.badgeIcon)
                                        .font(.system(size: 13))
                                    Text(preset.name)
                                        .font(.system(size: 14, weight: .medium))
                                    Text("(\(preset.relationship.rawValue))")
                                        .font(.system(size: 12))
                                        .foregroundStyle(TelegramPalette.mutedText)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(TelegramPalette.separator, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
        }
    }

    private var identitySection: some View {
        Section("Личность и внешность") {
            HStack(spacing: 16) {
                if let customAvatarImage = customAvatarImage {
                    Image(uiImage: customAvatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                } else {
                    AvatarView(kind: selectedAvatar, showsOnlineDot: true)
                        .frame(width: 72, height: 72)
                        .scaleEffect(1.1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                            Text("Выбрать реальное фото")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(TelegramPalette.accentBlue)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableAvatars, id: \.self) { kind in
                                Button {
                                    selectedAvatar = kind
                                    customAvatarImage = nil
                                    customAvatarFilename = nil
                                } label: {
                                    AvatarView(kind: kind, showsOnlineDot: false)
                                        .frame(width: 32, height: 32)
                                        .scaleEffect(0.6)
                                        .overlay {
                                            if selectedAvatar == kind && customAvatarImage == nil {
                                                Circle()
                                                    .stroke(TelegramPalette.accentBlue, lineWidth: 2)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(TelegramPalette.backgroundElevated)

            TextField("Имя (напр. Алина, Макс)", text: $name)
                .listRowBackground(TelegramPalette.backgroundElevated)

            TextField("Юзернейм (напр. @alina_v)", text: $username)
                .listRowBackground(TelegramPalette.backgroundElevated)

            TextField("Номер телефона", text: $phoneNumber)
                .listRowBackground(TelegramPalette.backgroundElevated)

            TextField("Статус / Bio (напр. кофеман | не звонить)", text: $bio)
                .listRowBackground(TelegramPalette.backgroundElevated)
        }
    }

    private var relationshipSection: some View {
        Section("Кто вы друг другу (Предыстория)") {
            Picker("Отношения", selection: $relationship) {
                ForEach(HumanRelationshipKind.allCases) { rel in
                    Label(rel.rawValue, systemImage: rel.badgeIcon).tag(rel)
                }
            }
            .listRowBackground(TelegramPalette.backgroundElevated)
            .onChange(of: relationship) { _, newRel in
                applyRelationshipDefaults(newRel)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("История отношений, секреты и триггеры:")
                    .font(.system(size: 13))
                    .foregroundStyle(TelegramPalette.mutedText)

                TextEditor(text: $relationshipDetail)
                    .frame(minHeight: 70)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .listRowBackground(TelegramPalette.backgroundElevated)
        }
    }

    private var characterSection: some View {
        Section("Характер и стиль общения") {
            Picker("Темперамент", selection: $temperament) {
                ForEach(HumanTemperament.allCases) { temp in
                    Text(temp.rawValue).tag(temp)
                }
            }
            .listRowBackground(TelegramPalette.backgroundElevated)

            Picker("Манера письма", selection: $chatStyle) {
                ForEach(HumanChatStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .listRowBackground(TelegramPalette.backgroundElevated)

            Picker("Стартовое настроение", selection: $currentMood) {
                ForEach(HumanMood.allCases) { mood in
                    Text("\(mood.emoji) \(mood.rawValue)").tag(mood)
                }
            }
            .listRowBackground(TelegramPalette.backgroundElevated)

            Toggle("Может обижаться и игнорировать", isOn: $canGetOffended)
                .listRowBackground(TelegramPalette.backgroundElevated)
        }
    }

    private var initiationSection: some View {
        Section("Первый шаг (Кто пишет первым)") {
            Picker("Инициатива", selection: $whoWritesFirst) {
                ForEach(WhoWritesFirstMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(TelegramPalette.backgroundElevated)

            if whoWritesFirst == .humanWritesFirst {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Текст первого сообщения от персонажа:")
                        .font(.system(size: 13))
                        .foregroundStyle(TelegramPalette.mutedText)

                    TextEditor(text: $initialMessage)
                        .frame(minHeight: 50)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .listRowBackground(TelegramPalette.backgroundElevated)

                HStack {
                    Text("Пауза перед отправкой:")
                    Spacer()
                    Text("\(Int(initialDelaySeconds)) сек")
                        .foregroundStyle(TelegramPalette.mutedText)
                }
                .listRowBackground(TelegramPalette.backgroundElevated)

                Slider(value: $initialDelaySeconds, in: 1...10, step: 1)
                    .listRowBackground(TelegramPalette.backgroundElevated)
            }
        }
    }

    private var autonomySection: some View {
        Section("Автономия и медиа") {
            Toggle("Отправлять голосовые сообщения", isOn: $canSendVoice)
                .listRowBackground(TelegramPalette.backgroundElevated)

            Toggle("Присылать фото из жизни", isOn: $canSendPhotos)
                .listRowBackground(TelegramPalette.backgroundElevated)

            Toggle("Писать самому в течение дня", isOn: $isProactive)
                .listRowBackground(TelegramPalette.backgroundElevated)
        }
    }

    private func applyRelationshipDefaults(_ rel: HumanRelationshipKind) {
        if relationshipDetail.isEmpty || relationshipDetail == relationship.defaultBackstory {
            relationshipDetail = rel.defaultBackstory
        }
        if initialMessage.isEmpty || initialMessage == relationship.defaultOpeningMessage {
            initialMessage = rel.defaultOpeningMessage
        }
    }

    private func loadPreset(_ preset: FakeHuman) {
        name = preset.name
        username = preset.username
        phoneNumber = preset.phoneNumber
        bio = preset.bio
        selectedAvatar = preset.avatarKind
        customAvatarFilename = preset.customAvatarFilename
        relationship = preset.relationship
        relationshipDetail = preset.relationshipDetail
        temperament = preset.temperament
        chatStyle = preset.chatStyle
        currentMood = preset.currentMood
        canGetOffended = preset.canGetOffended
        whoWritesFirst = preset.whoWritesFirst
        initialMessage = preset.initialMessage
        initialDelaySeconds = preset.initialDelaySeconds
        canSendVoice = preset.canSendVoice
        canSendPhotos = preset.canSendPhotos
        isProactive = preset.isProactive
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func saveFakeHuman() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
            "@\(cleanName.lowercased().replacingOccurrences(of: " ", with: "_"))" : username

        let human = FakeHuman(
            name: cleanName,
            username: cleanUsername,
            phoneNumber: phoneNumber,
            bio: bio.isEmpty ? relationshipDetail : bio,
            avatarKind: selectedAvatar,
            customAvatarFilename: customAvatarFilename,
            relationship: relationship,
            relationshipDetail: relationshipDetail,
            temperament: temperament,
            chatStyle: chatStyle,
            currentMood: currentMood,
            canGetOffended: canGetOffended,
            whoWritesFirst: whoWritesFirst,
            initialMessage: initialMessage,
            initialDelaySeconds: initialDelaySeconds,
            canSendVoice: canSendVoice,
            canSendPhotos: canSendPhotos,
            isProactive: isProactive
        )

        aiWorkspace.addFakeHuman(human)
        dismiss()
    }
}
