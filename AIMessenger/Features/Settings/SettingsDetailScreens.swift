import SwiftUI

struct NotificationsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notificationService = AppNotificationService.shared

    @State private var accountNotifications = true
    @State private var groupNotifications = true
    @State private var channelNotifications = true
    @State private var testBannerSent = false

    var body: some View {
        DetailScreenContainer(title: "Notifications", backTitle: "Back", dismissAction: { dismiss() }) {
            VStack(spacing: 22) {
                // System Permission & Test Card
                lightGroup {
                    sectionTitle("System Permission")

                    VStack(spacing: 12) {
                        HStack {
                            Text("iOS Push Status")
                                .font(.system(size: 16))
                                .foregroundStyle(TelegramPalette.settingsPrimaryText)

                            Spacer()

                            Text(notificationService.notificationsEnabled ? "Enabled" : "Not Permitted")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(notificationService.notificationsEnabled ? Color(hex: 0x17975F) : Color(hex: 0xC67A00))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                        divider

                        if !notificationService.notificationsEnabled {
                            Button {
                                Task {
                                    _ = await notificationService.requestAuthorization()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                    Text("Allow System Notifications")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(TelegramPalette.accentBlue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.horizontal, 16)
                            }
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            notificationService.sendTestNotificationNow()
                            withAnimation {
                                testBannerSent = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation {
                                    testBannerSent = false
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text(testBannerSent ? "Banner Dispatched!" : "Send Test Notification Now")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(testBannerSent ? Color(hex: 0x17975F) : Color.white.opacity(0.08))
                            .foregroundStyle(testBannerSent ? .white : TelegramPalette.settingsPrimaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }

                        if testBannerSent {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: 0x17975F))
                                Text("Check top of screen for native iOS notification banner!")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(TelegramPalette.settingsSecondaryText)
                            }
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                        }

                        Spacer().frame(height: 4)
                    }

                    footerNote("AIGram delivers real-time local push notifications when AI collaborators finish tasks, send voice notes, or update projects.")
                }

                lightGroup {
                    sectionTitle("Message notifications")
                    toggleRow("Sound", isOn: $notificationService.soundEnabled)
                    divider
                    toggleRow("Message Preview", isOn: $notificationService.previewEnabled)
                    divider
                    chevronRow("Exceptions", value: "None")
                    footerNote("Controls whether notification previews and alert tones are played when agents reply.")
                }

                lightGroup {
                    sectionTitle("Group & Workspace notifications")
                    toggleRow("Show Group Notifications", isOn: $groupNotifications)
                    divider
                    chevronRow("Sound", value: "Chord")
                    divider
                    chevronRow("Exceptions", value: "Build Board")
                    footerNote("Set notifications for collaborative group channels.")
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-sendTestNotification") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    notificationService.sendTestNotificationNow()
                    withAnimation {
                        testBannerSent = true
                    }
                }
            }
        }
    }
}

struct PrivacySecurityScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DetailScreenContainer(title: "Privacy and Security", backTitle: "Back", dismissAction: { dismiss() }) {
            VStack(spacing: 22) {
                lightGroup {
                    sectionTitle("Privacy")
                    chevronRow("Profile Visibility", value: "Contacts Only")
                    divider
                    chevronRow("Last Seen & Activity", value: "Nobody (+14)")
                    divider
                    chevronRow("Profile Photo", value: "Everybody")
                    divider
                    chevronRow("Voice Sessions", value: "Nobody (+7)")
                    divider
                    chevronRow("Forwarded Messages", value: "Everybody")
                    divider
                    chevronRow("Agent Invites", value: "Everybody")
                    footerNote("Choose who can discover your profile and start new AI conversations.")
                }

                lightGroup {
                    sectionTitle("Inactive workspace cleanup")
                    chevronRow("If Away For", value: "6 months")
                    footerNote("If this device stays inactive for long enough, local sessions and cached messages can be cleared automatically.")
                }

                lightGroup {
                    chevronRow("Blocked Agents", value: "2")
                    divider
                    chevronRow("Active Sessions", value: "1 device")
                    divider
                    chevronRow("Passcode & Face ID", value: "On")
                    divider
                    chevronRow("Local Encryption", value: "Enabled")
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }
}

struct DataStorageScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var cacheSizeString = MediaStorageService.shared.totalCacheSizeString()
    @State private var showClearedAlert = false
    @State private var showResetCanvasConfirmation = false
    @State private var saveIncomingPhotos = false
    @State private var saveEditedPhotos = true
    @State private var gifsAutoplay = true
    @State private var videosAutoplay = true

    var body: some View {
        DetailScreenContainer(title: "Data and Storage", backTitle: "Back", dismissAction: { dismiss() }) {
            VStack(spacing: 22) {
                lightGroup {
                    sectionTitle("Storage Usage")
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Media Cache")
                                .font(.system(size: 16))
                                .foregroundStyle(TelegramPalette.settingsPrimaryText)
                            Text("Photos, videos, audio notes, and files")
                                .font(.system(size: 13))
                                .foregroundStyle(TelegramPalette.settingsSecondaryText)
                        }
                        Spacer()
                        Text(cacheSizeString)
                            .font(.system(size: 15))
                            .foregroundStyle(TelegramPalette.settingsSecondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    divider

                    Button {
                        MediaStorageService.shared.clearMediaCache()
                        cacheSizeString = MediaStorageService.shared.totalCacheSizeString()
                        showClearedAlert = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        HStack {
                            Text("Clear Entire Cache")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(TelegramPalette.destructiveRed)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }

                lightGroup {
                    sectionTitle("Чистый холст")
                    Button {
                        showResetCanvasConfirmation = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Начать с чистого листа")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(TelegramPalette.destructiveRed)
                                Text("Удаляет чужую историю и сбрасывает все чаты к чистому холсту")
                                    .font(.system(size: 13))
                                    .foregroundStyle(TelegramPalette.settingsSecondaryText)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }

                lightGroup {
                    sectionTitle("Automatic media download")
                    chevronRow("Using Cellular", value: "Disabled")
                    divider
                    chevronRow("Using Wi‑Fi", value: "Disabled")
                    divider
                    chevronRow("Reset Auto-Download Settings", value: nil)
                }

                lightGroup {
                    sectionTitle("Other")
                    toggleRow("Save Incoming Photos", isOn: $saveIncomingPhotos)
                    divider
                    toggleRow("Save Edited Photos", isOn: $saveEditedPhotos)
                }

                lightGroup {
                    sectionTitle("Auto-play media")
                    toggleRow("GIFs", isOn: $gifsAutoplay)
                    divider
                    toggleRow("Videos", isOn: $videosAutoplay)
                }

                lightGroup {
                    sectionTitle("Voice calls")
                    chevronRow("Use Less Data", value: "Never")
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .alert("Cache Cleared", isPresented: $showClearedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Local cached media files have been cleared successfully.")
        }
        .confirmationDialog("Начать с чистого листа?", isPresented: $showResetCanvasConfirmation, titleVisibility: .visible) {
            Button("Очистить всё", role: .destructive) {
                aiWorkspace.resetToCleanCanvas()
                MediaStorageService.shared.clearMediaCache()
                cacheSizeString = MediaStorageService.shared.totalCacheSizeString()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Будут удалены все чаты, вызовы и персонажи, останутся только ваши Избранные сообщения.")
        }
    }
}

struct AppearanceScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var selectedTheme = "Night"
    @State private var textScale: Double = 0.58
    @State private var autoNightMode = false

    private let themes = ["Tinted Blue", "Classic", "Day", "Night"]
    private let icons = ["Default", "Default X", "Classic", "Classic X"]

    var body: some View {
        DarkDetailScreenContainer(title: "Appearance", dismissAction: { dismiss() }) {
            VStack(spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color theme")
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.mutedText)
                        .padding(.horizontal, 12)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(themes, id: \.self) { theme in
                            themeCard(title: theme, active: selectedTheme == theme)
                        }
                    }
                    .padding(.horizontal, 12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Chat Wallpaper")
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.mutedText)
                        .padding(.horizontal, 12)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ChatWallpaperKind.allCases) { wp in
                                wallpaperCard(wallpaper: wp, isSelected: aiWorkspace.selectedWallpaper == wp)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Text size")
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.mutedText)
                        .padding(.horizontal, 12)

                    VStack(spacing: 14) {
                        HStack {
                            Text("A")
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.7))

                            Slider(value: $textScale)
                                .tint(TelegramPalette.accentBlue)

                            Text("A")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        messagePreview
                    }
                    .padding(16)
                    .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("App icon")
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.mutedText)
                        .padding(.horizontal, 12)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            appIconCard(title: icon)
                        }
                    }
                    .padding(.horizontal, 12)
                }

                VStack(spacing: 0) {
                    darkRow("Chat Background", value: aiWorkspace.selectedWallpaper.rawValue)
                    darkDivider
                    toggleRowDark("Auto-Night Mode", isOn: $autoNightMode)
                    darkDivider
                    darkRow("Performance Mode", value: "High FPS")
                }
                .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 12)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    private func wallpaperCard(wallpaper: ChatWallpaperKind, isSelected: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            aiWorkspace.selectedWallpaper = wallpaper
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(wallpaperPreviewGradient(for: wallpaper))
                        .frame(width: 80, height: 110)

                    Image(systemName: wallpaper.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.85))

                    if isSelected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(TelegramPalette.accentBlue)
                                    .background(Circle().fill(.white))
                                    .padding(6)
                            }
                        }
                        .frame(width: 80, height: 110)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? TelegramPalette.accentBlue : Color.white.opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
                )

                Text(wallpaper.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .white : TelegramPalette.mutedText)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }

    private func wallpaperPreviewGradient(for wallpaper: ChatWallpaperKind) -> LinearGradient {
        switch wallpaper {
        case .doodles:
            return LinearGradient(colors: [Color(hex: 0x18181A), Color(hex: 0x0E0E10)], startPoint: .top, endPoint: .bottom)
        case .obsidian:
            return LinearGradient(colors: [Color.black, Color(hex: 0x111111)], startPoint: .top, endPoint: .bottom)
        case .neon:
            return LinearGradient(colors: [Color(hex: 0x05051F), Color(hex: 0x031B33)], startPoint: .top, endPoint: .bottom)
        case .sunset:
            return LinearGradient(colors: [Color(hex: 0x2A0826), Color(hex: 0x13041A)], startPoint: .top, endPoint: .bottom)
        case .emerald:
            return LinearGradient(colors: [Color(hex: 0x061D12), Color(hex: 0x020E08)], startPoint: .top, endPoint: .bottom)
        }
    }

    private func themeCard(title: String, active: Bool) -> some View {
        Button {
            selectedTheme = title
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient(for: title),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .overlay(alignment: .bottomLeading) {
                        if active {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .padding(10)
                        }
                    }

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private var messagePreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bob Harris")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text("00:20")
                    .font(.system(size: 13))
                    .foregroundStyle(TelegramPalette.mutedText)
            }

            Text("Good morning!")
                .font(.system(size: 15))
                .foregroundStyle(.white)

            Text("Do you know what time it is?  It's morning in Tokyo 😎")
                .font(.system(size: 15))
                .foregroundStyle(TelegramPalette.mutedText)
        }
    }

    private func appIconCard(title: String) -> some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2E88FF), Color(hex: 0x7E5BFF)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 86)
                .overlay {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private func gradient(for theme: String) -> [Color] {
        switch theme {
        case "Tinted Blue":
            return [Color(hex: 0x5BC0FF), Color(hex: 0x237CFF)]
        case "Classic":
            return [Color(hex: 0xB7CADF), Color(hex: 0x6D8DAD)]
        case "Day":
            return [Color(hex: 0xFFF1A8), Color(hex: 0xFDBD5F)]
        default:
            return [Color(hex: 0x282850), Color(hex: 0x0E1028)]
        }
    }
}

struct StickersScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var loopAnimated = true

    private let sets = ["Simba", "Diggy animated", "Screaming Checkin", "Ted", "Melie the Cavy", "Egg Yolk", "Tom & Jerry"]

    var body: some View {
        DetailScreenContainer(title: "Stickers", backTitle: "Back", trailingTitle: "Edit", dismissAction: { dismiss() }) {
            VStack(spacing: 22) {
                lightGroup {
                    chevronRow("Trending Stickers", value: "15")
                    divider
                    chevronRow("Suggest by Emoji", value: "All Sets")
                    divider
                    chevronRow("Archived Stickers", value: "46")
                    divider
                    chevronRow("Masks", value: nil)
                    divider
                    toggleRow("Loop Animated Stickers", isOn: $loopAnimated)
                    footerNote("Animated stickers will play in chat continuously.")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Sticker sets")
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.settingsSecondaryText)
                        .padding(.horizontal, 16)

                    lightGroup {
                        ForEach(Array(sets.enumerated()), id: \.offset) { index, name in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0xFFB347), Color(hex: 0xFF6B6B)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 42, height: 42)
                                    .overlay {
                                        Text("🙂")
                                            .font(.system(size: 18))
                                    }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.system(size: 17))
                                        .foregroundStyle(TelegramPalette.settingsPrimaryText)
                                    Text("25 stickers")
                                        .font(.system(size: 14))
                                        .foregroundStyle(TelegramPalette.settingsSecondaryText)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 58)

                            if index < sets.count - 1 {
                                divider
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }
}

struct DetailScreenContainer<Content: View>: View {
    let title: String
    var backTitle: String
    var trailingTitle: String?
    let dismissAction: () -> Void
    @ViewBuilder let content: Content

    init(
        title: String,
        backTitle: String,
        trailingTitle: String? = nil,
        dismissAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.backTitle = backTitle
        self.trailingTitle = trailingTitle
        self.dismissAction = dismissAction
        self.content = content()
    }

    var body: some View {
        ZStack {
            TelegramPalette.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: dismissAction) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(backTitle)
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundStyle(TelegramPalette.accentBlue)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(Color.white.opacity(0.12), in: Capsule(style: .continuous))
                    }

                    Spacer()

                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Group {
                        if let trailingTitle {
                            Button(action: dismissAction) {
                                Text(trailingTitle)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(TelegramPalette.accentBlue)
                                    .padding(.horizontal, 12)
                                    .frame(height: 38)
                                    .background(Color.white.opacity(0.12), in: Capsule(style: .continuous))
                            }
                        } else {
                            Color.clear
                                .frame(width: 56, height: 38)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    content
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

struct DarkDetailScreenContainer<Content: View>: View {
    let title: String
    let dismissAction: () -> Void
    @ViewBuilder let content: Content

    init(title: String, dismissAction: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.dismissAction = dismissAction
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: dismissAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundStyle(.white)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Color.clear.frame(width: 50)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(TelegramPalette.backgroundElevated)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
            }

            ScrollView(showsIndicators: false) {
                content
            }
            .background(TelegramPalette.backgroundPrimary)
        }
        .background(TelegramPalette.backgroundPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

@ViewBuilder
func lightGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(spacing: 0) {
        content()
    }
    .background(TelegramPalette.settingsCard)
    .overlay {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(TelegramPalette.settingsCardStroke, lineWidth: 1)
    }
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .shadow(color: TelegramPalette.settingsShadow, radius: 22, y: 12)
    .padding(.horizontal, 12)
}

@ViewBuilder
func sectionTitle(_ title: String) -> some View {
    HStack {
        Text(title)
            .font(.system(size: 14))
            .foregroundStyle(TelegramPalette.settingsSecondaryText)
        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 12)
    .padding(.bottom, 8)
}

@ViewBuilder
func footerNote(_ note: String) -> some View {
    HStack {
        Text(note)
            .font(.system(size: 14))
            .foregroundStyle(TelegramPalette.settingsSecondaryText)
            .fixedSize(horizontal: false, vertical: true)
        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 12)
}

var divider: some View {
    Rectangle()
        .fill(Color.white.opacity(0.7))
        .frame(height: 0.5)
        .padding(.leading, 16)
}

var darkDivider: some View {
    Rectangle()
        .fill(Color.white.opacity(0.08))
        .frame(height: 0.5)
        .padding(.leading, 16)
}

@ViewBuilder
func chevronRow(_ title: String, value: String?) -> some View {
    HStack {
        Text(title)
            .font(.system(size: 17))
            .foregroundStyle(TelegramPalette.settingsPrimaryText)

        Spacer()

        if let value {
            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.settingsSecondaryText)
        }

        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(TelegramPalette.settingsSecondaryText.opacity(0.55))
    }
    .padding(.horizontal, 16)
    .frame(height: 44)
}

@ViewBuilder
func darkRow(_ title: String, value: String?) -> some View {
    HStack {
        Text(title)
            .font(.system(size: 17))
            .foregroundStyle(.white)

        Spacer()

        if let value {
            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.mutedText)
        }
    }
    .padding(.horizontal, 16)
    .frame(height: 44)
}

@ViewBuilder
func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
    HStack {
        Text(title)
            .font(.system(size: 17))
            .foregroundStyle(TelegramPalette.settingsPrimaryText)

        Spacer()

        Toggle("", isOn: isOn)
            .labelsHidden()
    }
    .padding(.horizontal, 16)
    .frame(height: 44)
}

@ViewBuilder
func toggleRowDark(_ title: String, isOn: Binding<Bool>) -> some View {
    HStack {
        Text(title)
            .font(.system(size: 17))
            .foregroundStyle(.white)

        Spacer()

        Toggle("", isOn: isOn)
            .labelsHidden()
    }
    .padding(.horizontal, 16)
    .frame(height: 44)
}

struct SettingsDetailScreens_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsScreen()
    }
}

private var settingsDetailBackground: some View {
    LinearGradient(
        colors: [TelegramPalette.settingsCanvasTop, TelegramPalette.settingsCanvasBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    .overlay(alignment: .topLeading) {
        Circle()
            .fill(Color(hex: 0xD9DDFF, opacity: 0.42))
            .frame(width: 220, height: 220)
            .blur(radius: 58)
            .offset(x: -60, y: -50)
    }
    .overlay(alignment: .topTrailing) {
        Circle()
            .fill(Color(hex: 0xFFE1C4, opacity: 0.56))
            .frame(width: 200, height: 200)
            .blur(radius: 68)
            .offset(x: 70, y: -40)
    }
    .ignoresSafeArea()
}
