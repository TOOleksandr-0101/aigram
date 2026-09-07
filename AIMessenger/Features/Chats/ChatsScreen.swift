import SwiftUI

struct ChatsScreen: View {
    let onOpenThread: (ChatThread) -> Void

    @EnvironmentObject private var aiWorkspace: AIWorkspace
    private let threads = ChatThread.sampleThreads
    @State private var showModalPreview = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            chatsList
        }
        .background(TelegramPalette.backgroundPrimary)
        .sheet(isPresented: $showModalPreview) {
            ChatModalPreviewScreen(threads: threads)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var filteredThreads: [ChatThreadSummary] {
        let summaries = aiWorkspace.orderedSummaries(for: threads)
        guard searchText.isEmpty == false else { return summaries }

        return summaries.filter { summary in
            summary.searchableText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Edit") { }
                    .font(.system(size: 17))
                    .foregroundStyle(.white)

                Spacer()

                Text("Chats")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    showModalPreview = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
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
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private var chatsList: some View {
        List {
            ForEach(Array(filteredThreads.enumerated()), id: \.element.id) { index, summary in
                Button {
                    onOpenThread(summary.thread)
                } label: {
                    ChatRow(summary: summary, showSeparator: index < filteredThreads.count - 1)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(summary.thread.groupedBackground ? TelegramPalette.backgroundElevated : TelegramPalette.backgroundPrimary)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button { } label: {
                        swipeLabel(title: "Pin", systemImage: "pin.fill")
                    }
                    .tint(TelegramPalette.successGreen)

                    Button { } label: {
                        swipeLabel(title: "Unread", systemImage: "bubble.left.fill")
                    }
                    .tint(TelegramPalette.unreadGray)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { } label: {
                        swipeLabel(title: "Delete", systemImage: "trash.fill")
                    }
                    .tint(TelegramPalette.destructiveRed)

                    Button { } label: {
                        swipeLabel(title: "Mute", systemImage: "bell.slash.fill")
                    }
                    .tint(TelegramPalette.warningOrange)

                    Button { } label: {
                        swipeLabel(title: "Archive", systemImage: "archivebox.fill")
                    }
                    .tint(TelegramPalette.unreadGray)
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

struct ChatsScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChatsScreen { _ in }
            .environmentObject(AIWorkspace())
    }
}
