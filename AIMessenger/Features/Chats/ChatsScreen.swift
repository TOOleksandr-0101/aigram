import SwiftUI

struct ChatsScreen: View {
    let onOpenThread: (ChatThread) -> Void

    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var showNewChatSheet = false
    @State private var searchText = ""
    @State private var selectedFolder: ChatFolder = .all
    @State private var activeStory: TelegramStory?
    @State private var isEditingChats = false
    @State private var selectedThreadIds: Set<String> = []

    enum ChatFolder: String, CaseIterable, Identifiable {
        case all = "All Chats"
        case agents = "AI Agents"
        case groups = "Groups"
        case unread = "Unread"

        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                storiesBar
                chatsList
            }
            .background(TelegramPalette.backgroundPrimary)

            if isEditingChats {
                editingBottomBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isEditingChats)
        .sheet(isPresented: $showNewChatSheet) {
            NewChatSheet { selectedThread in
                onOpenThread(selectedThread)
            }
        }
        .fullScreenCover(item: $activeStory) { story in
            TelegramStoryViewer(
                initialStory: story,
                allStories: TelegramStory.sampleStories,
                onOpenThread: onOpenThread
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var filteredThreads: [ChatThreadSummary] {
        var summaries = aiWorkspace.orderedSummaries()

        switch selectedFolder {
        case .all:
            break
        case .agents:
            summaries = summaries.filter { $0.thread.isGroup == false }
        case .groups:
            summaries = summaries.filter { $0.thread.isGroup == true }
        case .unread:
            summaries = summaries.filter { $0.thread.badge != nil }
        }

        guard searchText.isEmpty == false else { return summaries }

        return summaries.filter { summary in
            summary.searchableText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                if isEditingChats {
                    Button("Done") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditingChats = false
                            selectedThreadIds.removeAll()
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(TelegramPalette.accentBlue)
                } else {
                    Button("Edit") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditingChats = true
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    .font(.system(size: 17))
                    .foregroundStyle(TelegramPalette.accentBlue)
                }

                Spacer()

                Text("Chats")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                if isEditingChats {
                    Button(selectedThreadIds.count == filteredThreads.count && !filteredThreads.isEmpty ? "Deselect" : "Select All") {
                        if selectedThreadIds.count == filteredThreads.count {
                            selectedThreadIds.removeAll()
                        } else {
                            selectedThreadIds = Set(filteredThreads.map { $0.thread.id })
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(TelegramPalette.accentBlue)
                } else {
                    Button {
                        showNewChatSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.horizontal, 15)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))

                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("Search for messages or users").foregroundStyle(Color.white.opacity(0.5))
                )
                .font(.system(size: 17))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(TelegramPalette.searchFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 10)

            foldersBar
        }
        .padding(.top, 8)
        .padding(.bottom, 0)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private var foldersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(ChatFolder.allCases) { folder in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            selectedFolder = folder
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Text(folder.rawValue)
                                    .font(.system(size: 15, weight: selectedFolder == folder ? .semibold : .medium))
                                    .foregroundStyle(selectedFolder == folder ? .white : TelegramPalette.mutedText)

                                if let count = unreadCount(for: folder) {
                                    Text("\(count)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(selectedFolder == folder ? .white : Color.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            selectedFolder == folder ? TelegramPalette.accentBlue : TelegramPalette.mutedText.opacity(0.8),
                                            in: Capsule()
                                        )
                                }
                            }
                            .padding(.top, 4)

                            ZStack {
                                if selectedFolder == folder {
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(TelegramPalette.accentBlue)
                                        .frame(height: 2.5)
                                } else {
                                    Color.clear
                                        .frame(height: 2.5)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 38)
    }

    private func unreadCount(for folder: ChatFolder) -> Int? {
        let threads = aiWorkspace.threads
        switch folder {
        case .all:
            let count = threads.filter { $0.badge != nil }.count
            return count > 0 ? count : nil
        case .agents:
            let count = threads.filter { !$0.isGroup && $0.badge != nil }.count
            return count > 0 ? count : nil
        case .groups:
            let count = threads.filter { $0.isGroup && $0.badge != nil }.count
            return count > 0 ? count : nil
        case .unread:
            let count = threads.filter { $0.badge != nil }.count
            return count > 0 ? count : nil
        }
    }

    private var storiesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                Button {
                    activeStory = TelegramStory.sampleStories[0]
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottomTrailing) {
                            AvatarView(kind: .saved, showsOnlineDot: false, initials: aiWorkspace.initials)
                                .frame(width: 58, height: 58)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                }

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(TelegramPalette.skyBlue)
                                .background(Color.black, in: Circle())
                                .offset(x: 2, y: 2)
                        }

                        Text("My Story")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .frame(width: 66)
                }
                .buttonStyle(.plain)

                ForEach(TelegramStory.sampleStories.dropFirst()) { story in
                    Button {
                        activeStory = story
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: 0xE052A0), Color(hex: 0xF15C42), Color(hex: 0x0088CC)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.2
                                    )
                                    .frame(width: 64, height: 64)

                                AvatarView(kind: story.authorAvatar, showsOnlineDot: false)
                                    .frame(width: 56, height: 56)
                            }

                            Text(story.authorName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 66)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private var chatsList: some View {
        List {
            if filteredThreads.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 60)
                    Image(systemName: selectedFolder == .unread ? "tray.fill" : "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(TelegramPalette.mutedText.opacity(0.5))
                    Text(selectedFolder == .unread ? "No Unread Chats" : "No Chats in Folder")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("All messages are up to date.")
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.mutedText)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(Array(filteredThreads.enumerated()), id: \.element.id) { index, summary in
                Button {
                    if isEditingChats {
                        if selectedThreadIds.contains(summary.thread.id) {
                            selectedThreadIds.remove(summary.thread.id)
                        } else {
                            selectedThreadIds.insert(summary.thread.id)
                        }
                    } else {
                        aiWorkspace.markAsRead(threadId: summary.thread.id)
                        onOpenThread(summary.thread)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isEditingChats {
                            Image(systemName: selectedThreadIds.contains(summary.thread.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(selectedThreadIds.contains(summary.thread.id) ? TelegramPalette.accentBlue : TelegramPalette.mutedText)
                                .padding(.leading, 12)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        ChatRow(summary: summary, showSeparator: index < filteredThreads.count - 1)
                    }
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(summary.thread.groupedBackground ? TelegramPalette.backgroundElevated : TelegramPalette.backgroundPrimary)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        aiWorkspace.togglePin(threadId: summary.thread.id)
                    } label: {
                        swipeLabel(
                            title: summary.thread.isPinned ? "Unpin" : "Pin",
                            systemImage: summary.thread.isPinned ? "pin.slash.fill" : "pin.fill"
                        )
                    }
                    .tint(TelegramPalette.successGreen)

                    Button {
                        aiWorkspace.toggleUnread(threadId: summary.thread.id)
                    } label: {
                        swipeLabel(
                            title: summary.thread.badge != nil ? "Read" : "Unread",
                            systemImage: summary.thread.badge != nil ? "envelope.open.fill" : "bubble.left.fill"
                        )
                    }
                    .tint(TelegramPalette.unreadGray)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        withAnimation {
                            aiWorkspace.deleteThread(threadId: summary.thread.id)
                        }
                    } label: {
                        swipeLabel(title: "Delete", systemImage: "trash.fill")
                    }
                    .tint(TelegramPalette.destructiveRed)

                    Button {
                        aiWorkspace.toggleMute(threadId: summary.thread.id)
                    } label: {
                        swipeLabel(
                            title: summary.thread.isMuted ? "Unmute" : "Mute",
                            systemImage: summary.thread.isMuted ? "bell.fill" : "bell.slash.fill"
                        )
                    }
                    .tint(TelegramPalette.warningOrange)
                }
            }

            Color.clear
                .frame(height: 92)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(TelegramPalette.backgroundPrimary)
    }

    private var editingBottomBar: some View {
        HStack {
            Button {
                withAnimation {
                    for id in selectedThreadIds {
                        aiWorkspace.toggleMute(threadId: id)
                    }
                    selectedThreadIds.removeAll()
                }
            } label: {
                Text("Mute")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(selectedThreadIds.isEmpty ? TelegramPalette.mutedText : TelegramPalette.accentBlue)
            }
            .disabled(selectedThreadIds.isEmpty)

            Spacer()

            Button {
                withAnimation {
                    for id in selectedThreadIds {
                        aiWorkspace.togglePin(threadId: id)
                    }
                    selectedThreadIds.removeAll()
                }
            } label: {
                Text("Pin")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(selectedThreadIds.isEmpty ? TelegramPalette.mutedText : TelegramPalette.accentBlue)
            }
            .disabled(selectedThreadIds.isEmpty)

            Spacer()

            Button {
                withAnimation {
                    for id in selectedThreadIds {
                        aiWorkspace.deleteThread(threadId: id)
                    }
                    selectedThreadIds.removeAll()
                }
            } label: {
                Text("Delete")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selectedThreadIds.isEmpty ? TelegramPalette.mutedText : Color(hex: 0xFE3B30))
            }
            .disabled(selectedThreadIds.isEmpty)
        }
        .padding(.horizontal, 28)
        .frame(height: 52)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
        .padding(.bottom, 80)
    }

    private func swipeLabel(title: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
    }
}

private struct ChatRow: View {
    let summary: ChatThreadSummary
    let showSeparator: Bool

    private var thread: ChatThread { summary.thread }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(kind: thread.avatar, showsOnlineDot: thread.online)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 1) {
                Text(thread.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.top, 10)

                previewBlock
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 16) {
                topMeta
                    .padding(.top, 12)
                bottomMeta
            }
            .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.leading, 9)
        .padding(.trailing, 10)
        .frame(height: 76)
        .background(thread.groupedBackground ? TelegramPalette.backgroundElevated : TelegramPalette.backgroundPrimary)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 79)
            }
        }
    }

    @ViewBuilder
    private var previewBlock: some View {
        if let detail = summary.detailText {
            Text(summary.previewText)
                .font(.system(size: 15))
                .foregroundStyle(detail == "GIF" ? .white : TelegramPalette.mutedText)
                .lineLimit(1)

            Text(detail)
                .font(.system(size: 15))
                .foregroundStyle(TelegramPalette.mutedText)
                .lineLimit(1)
        } else {
            Text(summary.previewText)
                .font(.system(size: 15))
                .foregroundStyle(TelegramPalette.mutedText)
                .lineLimit(2)
        }
    }

    private var topMeta: some View {
        HStack(spacing: 1) {
            if thread.deliveryState == .read {
                doubleCheckmark
            } else if thread.deliveryState == .sent {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(summary.timeText)
                .font(.system(size: 14))
                .foregroundStyle(TelegramPalette.mutedText)
        }
    }

    @ViewBuilder
    private var bottomMeta: some View {
        if thread.isPinned {
            Image(systemName: "pin.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TelegramPalette.mutedText)
                .rotationEffect(.degrees(45))
        } else if let badge = thread.badge {
            Text(badge)
                .font(.system(size: 14))
                .foregroundStyle(.black)
                .padding(.horizontal, 7)
                .frame(minWidth: 26, minHeight: 20)
                .background(
                    Capsule(style: .continuous)
                        .fill(thread.badgeBright ? Color.white : Color(hex: 0x636366))
                )
        } else if thread.isMuted {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(TelegramPalette.mutedText)
        } else {
            Color.clear
                .frame(width: 20, height: 20)
        }
    }

    private var doubleCheckmark: some View {
        ZStack {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .offset(x: -3)
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .offset(x: 3)
        }
        .frame(width: 16, height: 12)
    }
}

struct AvatarView: View {
    let kind: ChatAvatarKind
    let showsOnlineDot: Bool
    var initials: String? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
                .frame(width: 60, height: 60)
                .clipShape(Circle())

            if showsOnlineDot {
                Circle()
                    .fill(Color(hex: 0x1ED760))
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .stroke(TelegramPalette.backgroundPrimary, lineWidth: 2)
                    }
                    .offset(x: -3, y: -3)
            }
        }
        .frame(width: 60, height: 60)
    }

    @ViewBuilder
    private var content: some View {
        if let initials = initials, !initials.isEmpty {
            LinearGradient(
                colors: [Color(hex: 0xFF9966), Color(hex: 0xFF5E62)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Text(initials)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
        } else {
            switch kind {
            case .saved:
                LinearGradient(colors: [Color(hex: 0x66C6FF), Color(hex: 0x1F8CFF)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            case .visionCluster:
            Circle()
                .fill(Color(hex: 0x151515))
                .overlay {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 6, height: 6)
                        }
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 6, height: 6)
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
        case .tutor:
            AngularGradient(colors: [Color(hex: 0x3AC7FF), Color(hex: 0xFF6A92), Color(hex: 0x885CFF), Color(hex: 0x3AC7FF)], center: .center)
                .overlay {
                    Text("TG")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(.white)
                }
        case .uxCopilot:
            LinearGradient(colors: [Color(hex: 0x2C2C2E), Color(hex: 0x111111)], startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .center) {
                    VStack(spacing: 0) {
                        Text("UX")
                        Text("LIVE")
                    }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                }
                .overlay(alignment: .topTrailing) {
                    Text("x")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(6)
                }
        case .researchBot:
            LinearGradient(colors: [Color(hex: 0xFFB03A), Color(hex: 0x7A4EFF)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Text("RB")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
        case .artEngine:
            LinearGradient(colors: [Color(hex: 0x5935FF), Color(hex: 0x2A73FF)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Text("AE")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
        case .codeAgents:
            LinearGradient(colors: [Color(hex: 0x2447A2), Color(hex: 0x062B7A)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                }
        case .seminarCircle:
            LinearGradient(colors: [Color(hex: 0x2B94FF), Color(hex: 0x6E5BFF)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: 18, height: 18)
                            .offset(x: -10, y: -4)
                        Circle()
                            .fill(Color.white.opacity(0.88))
                            .frame(width: 18, height: 18)
                            .offset(x: 10, y: -4)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .offset(y: 10)
                    }
                }
        case .buildBoard:
            LinearGradient(colors: [Color(hex: 0xFF8A57), Color(hex: 0xFF5252)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct ChatsScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChatsScreen { _ in }
            .environmentObject(AIWorkspace())
    }
}

// MARK: - New Chat Agent Selection Sheet
struct NewChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace
    let onSelectThread: (ChatThread) -> Void

    @State private var searchContactText = ""

    var filteredContacts: [ContactProfile] {
        if searchContactText.isEmpty {
            return aiWorkspace.contacts
        }
        return aiWorkspace.contacts.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchContactText) ||
            $0.roleTitle.localizedCaseInsensitiveContains(searchContactText) ||
            $0.username.localizedCaseInsensitiveContains(searchContactText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredContacts) { contact in
                        Button {
                            let thread = aiWorkspace.createOrGetThread(for: contact)
                            dismiss()
                            onSelectThread(thread)
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(kind: contact.avatar, showsOnlineDot: contact.presence.isOnline)
                                    .frame(width: 44, height: 44)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(contact.displayName)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Text(contact.roleTitle)
                                        .font(.system(size: 14))
                                        .foregroundStyle(TelegramPalette.mutedText)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(contact.username)
                                    .font(.system(size: 13))
                                    .foregroundStyle(TelegramPalette.accentBlue)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(TelegramPalette.backgroundElevated)
                    }
                } header: {
                    Text("AI Agents & Contacts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TelegramPalette.mutedText)
                }
            }
            .scrollContentBackground(.hidden)
            .background(TelegramPalette.backgroundPrimary.ignoresSafeArea())
            .searchable(text: $searchContactText, prompt: "Search agents or roles")
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TelegramPalette.accentBlue)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct TelegramStory: Identifiable, Equatable {
    let id: String
    let authorName: String
    let authorAvatar: ChatAvatarKind
    let timeAgo: String
    let title: String
    let text: String
    let tags: [String]
    let symbol: String
    let gradientColors: [Color]
    let threadId: String

    static let sampleStories: [TelegramStory] = [
        TelegramStory(
            id: "my-story",
            authorName: "My Story",
            authorAvatar: .saved,
            timeAgo: "Just now",
            title: "Weekend Coastal Trail",
            text: "Heading out for an early hike along the coast. Clear views, crisp ocean air, and quiet trails.",
            tags: ["#Weekend", "#Coast", "#Hiking"],
            symbol: "sun.max.fill",
            gradientColors: [Color(hex: 0x0F2027), Color(hex: 0x203A43), Color(hex: 0x2C5364)],
            threadId: "saved-messages"
        ),
        TelegramStory(
            id: "ai-assistant",
            authorName: "AI Assistant",
            authorAvatar: .saved,
            timeAgo: "2h ago",
            title: "Morning Focus & Summary",
            text: "Organized your tasks for today, summarized unread project threads, and prepped the calendar.",
            tags: ["#Focus", "#Productivity", "#Assistant"],
            symbol: "sparkles",
            gradientColors: [Color(hex: 0x1E3A8A), Color(hex: 0x3B82F6), Color(hex: 0x06B6D4)],
            threadId: "ai-assistant"
        ),
        TelegramStory(
            id: "design-studio",
            authorName: "Design Studio",
            authorAvatar: .uxCopilot,
            timeAgo: "3h ago",
            title: "Minimal Design Inspiration",
            text: "Studying subtle blur effects, clean typography hierarchy, and dynamic gesture interactions.",
            tags: ["#DesignSystem", "#Typography", "#MobileUI"],
            symbol: "paintbrush.pointed.fill",
            gradientColors: [Color(hex: 0x831843), Color(hex: 0xBE185D), Color(hex: 0xFB7185)],
            threadId: "design-scout"
        ),
        TelegramStory(
            id: "research-desk",
            authorName: "Research Desk",
            authorAvatar: .researchBot,
            timeAgo: "5h ago",
            title: "Weekend Reading Digest",
            text: "Compiled top articles on distributed systems, modern memory management, and neural embeddings.",
            tags: ["#Learning", "#Research", "#ReadingList"],
            symbol: "book.fill",
            gradientColors: [Color(hex: 0x064E3B), Color(hex: 0x059669), Color(hex: 0x10B981)],
            threadId: "research-desk"
        ),
        TelegramStory(
            id: "code-partner",
            authorName: "Code Partner",
            authorAvatar: .codeAgents,
            timeAgo: "7h ago",
            title: "Swift 6 Architecture Patterns",
            text: "Exploring clean actor boundaries, structured concurrency, and responsive UI rendering.",
            tags: ["#Swift", "#CleanCode", "#Engineering"],
            symbol: "chevron.left.forwardslash.chevron.right",
            gradientColors: [Color(hex: 0x1A102F), Color(hex: 0x2E1065), Color(hex: 0x4C1D95)],
            threadId: "code-partner"
        )
    ]
}

struct TelegramStoryViewer: View {
    let initialStory: TelegramStory
    let allStories: [TelegramStory]
    let onOpenThread: (ChatThread) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace

    @State private var currentIndex: Int = 0
    @State private var progress: CGFloat = 0.0
    @State private var isPaused: Bool = false
    @State private var replyText: String = ""
    @State private var floatingHearts: [HeartParticle] = []
    @State private var timerTask: Task<Void, Never>?

    struct HeartParticle: Identifiable {
        let id = UUID()
        var xOffset: CGFloat
        var yOffset: CGFloat
        var opacity: Double
        var scale: CGFloat
    }

    private var currentStory: TelegramStory {
        allStories[min(max(currentIndex, 0), allStories.count - 1)]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: currentStory.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 320, height: 320)
                    .blur(radius: 50)
                    .offset(x: -80, y: -120)
            }

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToPrevious()
                    }
                    .frame(width: 100)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToNext()
                    }
            }

            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    ForEach(0..<allStories.count, id: \.self) { idx in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))

                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: idx < currentIndex ? geo.size.width : (idx == currentIndex ? geo.size.width * progress : 0))
                            }
                        }
                        .frame(height: 2.5)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 54)

                HStack(spacing: 10) {
                    AvatarView(kind: currentStory.authorAvatar, showsOnlineDot: false)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentStory.authorName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)

                        Text(currentStory.timeAgo)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.4), in: Circle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: currentStory.symbol)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 6)

                    Text(currentStory.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    Text(currentStory.text)
                        .font(.system(size: 15, weight: .medium))
                        .lineSpacing(4)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        ForEach(currentStory.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.18), in: Capsule())
                        }
                    }
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.32))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        }
                )
                .padding(.horizontal, 18)

                Spacer()

                HStack(spacing: 12) {
                    HStack {
                        TextField("Send a message...", text: $replyText)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)

                        if replyText.isEmpty == false {
                            Button {
                                sendStoryReply()
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(TelegramPalette.skyBlue)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.2), in: Capsule())

                    Button {
                        spawnHeart()
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: 0xFF3B30))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2), in: Circle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 24)
            }

            ForEach(floatingHearts) { heart in
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: 0xFF2D55))
                    .scaleEffect(heart.scale)
                    .opacity(heart.opacity)
                    .offset(x: heart.xOffset, y: heart.yOffset)
            }
        }
        .onAppear {
            if let idx = allStories.firstIndex(of: initialStory) {
                currentIndex = idx
            }
            startTimer()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        progress = 0.0
        timerTask = Task {
            for i in 1...50 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: 100_000_000)
                if !isPaused {
                    await MainActor.run {
                        progress = CGFloat(i) / 50.0
                    }
                }
            }
            await MainActor.run {
                goToNext()
            }
        }
    }

    private func goToNext() {
        if currentIndex < allStories.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            dismiss()
        }
    }

    private func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        } else {
            startTimer()
        }
    }

    private func spawnHeart() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let heart = HeartParticle(
            xOffset: CGFloat.random(in: 80...140),
            yOffset: 240,
            opacity: 1.0,
            scale: 0.6
        )
        floatingHearts.append(heart)

        withAnimation(.easeOut(duration: 1.2)) {
            if let idx = floatingHearts.firstIndex(where: { $0.id == heart.id }) {
                floatingHearts[idx].yOffset -= CGFloat.random(in: 180...300)
                floatingHearts[idx].xOffset += CGFloat.random(in: -30...30)
                floatingHearts[idx].opacity = 0.0
                floatingHearts[idx].scale = 1.3
            }
        }
    }

    private func sendStoryReply() {
        guard replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let thread = aiWorkspace.threads.first(where: { $0.id == currentStory.threadId }) {
            aiWorkspace.sendTextMessage("Story reply: \"\(replyText)\"", to: thread)
            dismiss()
            onOpenThread(thread)
        } else {
            dismiss()
        }
    }
}
