import SwiftUI

struct ContactsScreen: View {
    let onOpenContact: (ContactProfile) -> Void
    let onOpenChat: (ChatThread) -> Void

    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var isCreateAgentPresented = false
    @State private var isLibraryPresented = false
    @State private var isSortedAlphabetically = false

    private var displayedContacts: [ContactProfile] {
        if isSortedAlphabetically {
            return aiWorkspace.contacts.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        } else {
            return aiWorkspace.contacts
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar

                Button {
                    isCreateAgentPresented = true
                } label: {
                    actionRow(title: "Создать Fake Human", symbol: "person.crop.circle.badge.plus", tint: TelegramPalette.accentBlue)
                }
                .buttonStyle(.plain)

                ForEach(Array(displayedContacts.enumerated()), id: \.element.id) { index, contact in
                    Button {
                        onOpenContact(contact)
                    } label: {
                        contactRow(contact: contact, showSeparator: index < displayedContacts.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 96)
        }
        .background(TelegramPalette.backgroundPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isCreateAgentPresented) {
            CreateFakeHumanSheet()
        }
        .sheet(isPresented: $isLibraryPresented) {
            ExploreLibrarySheet()
        }
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button(isSortedAlphabetically ? "Default" : "Sort A-Z") {
                    withAnimation {
                        isSortedAlphabetically.toggle()
                    }
                }
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.92))

                Spacer()

                Text("Contacts")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    isCreateAgentPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private func actionRow(title: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 26)

            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(TelegramPalette.backgroundPrimary)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
                .padding(.leading, 16)
        }
    }

    private func contactRow(contact: ContactProfile, showSeparator: Bool) -> some View {
        HStack(spacing: 10) {
            AvatarView(
                kind: contact.avatar,
                showsOnlineDot: contact.presence.isOnline,
                customImageFilename: contact.customAvatarFilename
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(contact.displayName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)

                    if let mood = contact.mood {
                        Text(mood.emoji)
                            .font(.system(size: 14))
                    }
                }

                if let rel = contact.relationshipKind {
                    Text(rel.rawValue)
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.accentBlue)
                        .lineLimit(1)
                } else {
                    Text(contact.roleTitle)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                }

                Text(contact.mood?.statusText ?? contact.presence.label)
                    .font(.system(size: 14))
                    .foregroundStyle(contact.mood == .offended ? Color(hex: 0xFE3B30) : (contact.presence.isOnline ? TelegramPalette.accentBlue : TelegramPalette.mutedText))
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 88)
        .background(TelegramPalette.backgroundPrimary)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 79)
            }
        }
    }
}

struct ContactInfoScreen: View {
    let contact: ContactProfile
    let onEdit: () -> Void
    let onStartChat: (ChatThread) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var isCallPresented = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            lightTopBar(title: "Info", trailingTitle: "Edit", trailingAction: onEdit)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    profileHeader
                    infoGroup
                    actionGroup
                    communicationGroup
                    removeAgentButton
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(TelegramPalette.backgroundPrimary)
        }
        .background(TelegramPalette.backgroundPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $isCallPresented) {
            TelegramCallView(
                contactName: contact.displayName,
                avatar: contact.avatar,
                roleTitle: contact.roleTitle,
                greetingText: contact.bio
            )
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            AvatarView(
                kind: contact.avatar,
                showsOnlineDot: contact.presence.isOnline,
                customImageFilename: contact.customAvatarFilename
            )
            .frame(width: 82, height: 82)
            .scaleEffect(1.32)

            Text(contact.displayName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)

            if let mood = contact.mood {
                HStack(spacing: 6) {
                    Text(mood.emoji)
                    Text(mood.statusText)
                }
                .font(.system(size: 15))
                .foregroundStyle(mood == .offended ? Color(hex: 0xFE3B30) : TelegramPalette.accentBlue)
            } else {
                Text(contact.presence.label)
                    .font(.system(size: 15))
                    .foregroundStyle(contact.presence.isOnline ? TelegramPalette.accentBlue : TelegramPalette.mutedText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var infoGroup: some View {
        LightGroupCard {
            InfoValueRow(title: "username", value: contact.username)
            DividerLine()
            if let rel = contact.relationshipKind {
                InfoValueRow(title: "отношения", value: rel.rawValue)
                DividerLine()
            }
            if let human = aiWorkspace.fakeHuman(for: contact.id) {
                InfoValueRow(title: "характер", value: human.temperament.rawValue)
                DividerLine()
                InfoValueRow(title: "стиль чата", value: human.chatStyle.rawValue)
                DividerLine()
                InfoValueRow(title: "кто пишет первым", value: human.whoWritesFirst.rawValue)
                DividerLine()
            } else {
                InfoValueRow(title: "роль", value: contact.roleTitle)
                DividerLine()
            }
            InfoValueRow(title: "о себе / контекст", value: contact.bio, multiline: true)
        }
    }

    private var actionGroup: some View {
        LightGroupCard {
            Button {
                let thread = aiWorkspace.createOrGetThread(for: contact)
                onStartChat(thread)
            } label: {
                PlainTextRow(title: "Start Chat", titleColor: TelegramPalette.accentBlue)
            }
            .buttonStyle(.plain)

            DividerLine()

            Button {
                isCallPresented = true
            } label: {
                PlainTextRow(title: "Start Audio Call", titleColor: TelegramPalette.accentBlue)
            }
            .buttonStyle(.plain)

            DividerLine()

            Button {
                let thread = aiWorkspace.createOrGetThread(for: contact)
                aiWorkspace.togglePin(for: thread)
            } label: {
                let thread = aiWorkspace.threads.first(where: { $0.id == contact.id })
                PlainTextRow(
                    title: (thread?.isPinned == true) ? "Unpin from Top" : "Pin to Top",
                    titleColor: TelegramPalette.accentBlue
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var communicationGroup: some View {
        LightGroupCard {
            ChevronValueRow(title: "Shared Media", value: "Enabled")
            DividerLine()
            ChevronValueRow(title: "Notifications", value: "Default")
            DividerLine()
            ChevronValueRow(title: "Context Memory", value: "On")
        }
    }

    private var removeAgentButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            destructiveButton(title: "Удалить Fake Human")
        }
        .buttonStyle(.plain)
        .confirmationDialog("Удалить Fake Human", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                if aiWorkspace.fakeHuman(for: contact.id) != nil {
                    aiWorkspace.deleteFakeHuman(id: contact.id)
                } else {
                    aiWorkspace.removeContact(contactId: contact.id)
                }
                dismiss()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы уверены, что хотите удалить \(contact.displayName)?")
        }
    }

    private func destructiveButton(title: String) -> some View {
        Text(title)
            .font(.system(size: 17))
            .foregroundStyle(Color(hex: 0xFE3B30))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(TelegramPalette.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 12)
    }

    private func lightTopBar(title: String, trailingTitle: String, trailingAction: @escaping () -> Void) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundStyle(TelegramPalette.accentBlue)
            }

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button(trailingTitle, action: trailingAction)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.accentBlue)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }
}

struct EditableContactInfoScreen: View {
    let contact: ContactProfile

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var displayName: String
    @State private var bio: String
    @State private var showDeleteConfirmation = false

    init(contact: ContactProfile) {
        self.contact = contact
        _displayName = State(initialValue: contact.displayName)
        _bio = State(initialValue: contact.bio)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.accentBlue)

                Spacer()

                Text("Edit Info")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button("Done") {
                    aiWorkspace.updateContact(contactId: contact.id, newName: displayName, newBio: bio)
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(TelegramPalette.accentBlue)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(TelegramPalette.backgroundElevated)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            AvatarView(kind: contact.avatar, showsOnlineDot: false)

                            VStack(spacing: 16) {
                                TextField("Name", text: $displayName)
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white)
                                DividerLine()
                                Text(contact.username)
                                    .font(.system(size: 17))
                                    .foregroundStyle(TelegramPalette.mutedText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 13)
                        .background(TelegramPalette.backgroundElevated)

                        Text("Update contact details and local notes.")
                            .font(.system(size: 14))
                            .foregroundStyle(TelegramPalette.mutedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    LightGroupCard {
                        InfoValueRow(title: "role", value: contact.roleTitle)
                        DividerLine()
                        HStack(alignment: .top) {
                            Text("note")
                                .font(.system(size: 15))
                                .foregroundStyle(TelegramPalette.mutedText)
                                .frame(width: 86, alignment: .leading)

                            TextField("Add a note", text: $bio, axis: .vertical)
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    LightGroupCard {
                        ChevronValueRow(title: "Notifications", value: "Enabled")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Contact")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(hex: 0xFE3B30))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(TelegramPalette.backgroundElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Delete Contact", isPresented: $showDeleteConfirmation) {
                        Button("Delete Contact", role: .destructive) {
                            aiWorkspace.removeContact(contactId: contact.id)
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to delete \(contact.displayName)?")
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(TelegramPalette.backgroundPrimary)
        }
        .background(TelegramPalette.backgroundPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

struct CreateAgentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace

    @State private var name = ""
    @State private var username = ""
    @State private var role = ""
    @State private var bio = ""
    @State private var selectedAvatar: ChatAvatarKind = .codeAgents

    private let availableAvatars: [ChatAvatarKind] = [
        .codeAgents,
        .visionCluster,
        .tutor,
        .uxCopilot,
        .researchBot,
        .artEngine,
        .seminarCircle,
        .buildBoard,
        .saved
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            AvatarView(kind: selectedAvatar, showsOnlineDot: true)
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.2)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(availableAvatars, id: \.self) { kind in
                                        Button {
                                            selectedAvatar = kind
                                        } label: {
                                            AvatarView(kind: kind, showsOnlineDot: false)
                                                .frame(width: 44, height: 44)
                                                .overlay {
                                                    if selectedAvatar == kind {
                                                        Circle()
                                                            .stroke(TelegramPalette.accentBlue, lineWidth: 3)
                                                    }
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Agent Identity") {
                    TextField("Display Name (e.g. Architect)", text: $name)
                    TextField("Username (e.g. @architect)", text: $username)
                    TextField("Role (e.g. Cloud & Systems Expert)", text: $role)
                }

                Section("System Instructions / Bio") {
                    TextField("Describe how this agent thinks and assists...", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New AI Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveAgent()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveAgent() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanName.isEmpty == false else { return }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
            "@\(cleanName.lowercased().replacingOccurrences(of: " ", with: "_"))" : username

        let cleanRole = role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
            "Autonomous AI Assistant" : role

        let cleanBio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
            "Specialized AI agent ready to assist with complex tasks." : bio

        aiWorkspace.addNewAgent(
            name: cleanName,
            username: cleanUsername,
            role: cleanRole,
            bio: cleanBio,
            avatar: selectedAvatar
        )
        dismiss()
    }
}

struct ExploreLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace

    struct TemplateAgent: Identifiable {
        let id = UUID()
        let name: String
        let username: String
        let role: String
        let bio: String
        let avatar: ChatAvatarKind
    }

    private let templates: [TemplateAgent] = [
        TemplateAgent(
            name: "Cloud Architect",
            username: "@cloud_architect",
            role: "Distributed Systems & AWS",
            bio: "Reviews architectures, designs fault-tolerant systems, and optimizes cloud costs.",
            avatar: .visionCluster
        ),
        TemplateAgent(
            name: "SwiftUI Master",
            username: "@swift_guru",
            role: "iOS Animations & CoreData",
            bio: "Specialist in declarative SwiftUI architecture, custom layouts, and fluid gestures.",
            avatar: .codeAgents
        ),
        TemplateAgent(
            name: "Security Auditor",
            username: "@sec_auditor",
            role: "Pen-testing & OWASP",
            bio: "Identifies vulnerabilities, leaks, and suggests military-grade encryption patterns.",
            avatar: .researchBot
        ),
        TemplateAgent(
            name: "Growth Hacker",
            username: "@growth_bot",
            role: "Viral Loops & Unit Economics",
            bio: "Analyzes retention funnels, conversion rates, and crafts high-converting copy.",
            avatar: .uxCopilot
        ),
        TemplateAgent(
            name: "Algorithm Mentor",
            username: "@algo_mentor",
            role: "DSA & LeetCode Hard",
            bio: "Explains tree traversals, dynamic programming, and prepares you for technical interviews.",
            avatar: .tutor
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose from curated AI agent personas to add to your workspace contacts.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                ForEach(templates) { template in
                    HStack(spacing: 12) {
                        AvatarView(kind: template.avatar, showsOnlineDot: true)
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(template.name)
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Text(template.username)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Text(template.role)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(TelegramPalette.accentBlue)
                            Text(template.bio)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Button {
                            aiWorkspace.addNewAgent(
                                name: template.name,
                                username: template.username,
                                role: template.role,
                                bio: template.bio,
                                avatar: template.avatar
                            )
                            dismiss()
                        } label: {
                            Text("Add")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(TelegramPalette.accentBlue, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Agent Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct LightGroupCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(TelegramPalette.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 12)
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(TelegramPalette.separator)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }
}

private struct InfoValueRow: View {
    let title: String
    let value: String
    var multiline = false

    var body: some View {
        HStack(alignment: multiline ? .top : .center) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(TelegramPalette.textSecondary)
                .frame(width: 86, alignment: .leading)

            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: multiline)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct PlainTextRow: View {
    let title: String
    let titleColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(titleColor)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}

private struct ChevronValueRow: View {
    let title: String
    let value: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.textPrimary)

            Spacer()

            if let value {
                Text(value)
                    .font(.system(size: 17))
                    .foregroundStyle(TelegramPalette.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TelegramPalette.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}

struct ContactsFlow_Previews: PreviewProvider {
    static var previews: some View {
        ContactsScreen(onOpenContact: { _ in }, onOpenChat: { _ in })
            .environmentObject(AIWorkspace())
    }
}
