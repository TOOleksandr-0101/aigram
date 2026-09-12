import SwiftUI

struct SettingsHubScreen: View {
    let onOpenRoute: (SettingsRoute) -> Void
    let onSwitchTab: (AppTab) -> Void

    @EnvironmentObject private var aiWorkspace: AIWorkspace
    @State private var showQRCodeSheet = false
    @State private var searchText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                topBar
                profileHeader
                premiumCard
                searchField
                workspaceGroup
                preferencesGroup
                aiEngineGroup
                helpGroup
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
        .background(TelegramPalette.backgroundPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showQRCodeSheet) {
            QRCodeShareSheet(
                displayName: aiWorkspace.displayName,
                username: aiWorkspace.username,
                initials: aiWorkspace.initials
            )
        }
    }

    private var topBar: some View {
        HStack {
            Button("Edit") {
                onOpenRoute(.editProfile)
            }
            .font(.system(size: 17))
            .foregroundStyle(TelegramPalette.accentBlue)

            Spacer()

            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                showQRCodeSheet = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Image(systemName: "qrcode")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(TelegramPalette.accentBlue)
            }
            .buttonStyle(.plain)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 8) {
            Button {
                onOpenRoute(.editProfile)
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xFF9966), Color(hex: 0xFF5E62)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(aiWorkspace.initials)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 82, height: 82)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(TelegramPalette.accentBlue, in: Circle())
                        .overlay(Circle().stroke(TelegramPalette.backgroundPrimary, lineWidth: 2))
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 3) {
                Text(aiWorkspace.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text(aiWorkspace.phoneNumber)
                    .font(.system(size: 14))
                    .foregroundStyle(TelegramPalette.mutedText)

                Text(aiWorkspace.username)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TelegramPalette.skyBlue)
            }

            Button {
                onOpenRoute(.editProfile)
            } label: {
                Text("Change Profile Photo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TelegramPalette.accentBlue)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }

    private var premiumCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xF59E0B).opacity(0.2))
                    .frame(width: 38, height: 38)

                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: 0xFBBF24))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("AIGram Premium")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(TelegramPalette.skyBlue)
                }

                Text("Fastest AI Models, Voice Notes & 4GB Memory")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Text("ACTIVE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x5856D6), Color(hex: 0x8A56E6)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .shadow(color: Color(hex: 0x5856D6).opacity(0.3), radius: 10, y: 4)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.45))

            TextField("", text: $searchText, prompt: Text("Search Settings").foregroundStyle(Color.white.opacity(0.45)))
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var workspaceGroup: some View {
        VStack(spacing: 0) {
            telegramRow(
                title: "Saved Messages",
                symbol: "bookmark.fill",
                color: Color(hex: 0x0A84FF),
                showSeparator: true
            ) {
                onSwitchTab(.chats)
            }

            telegramRow(
                title: "Recent Calls",
                symbol: "phone.fill",
                color: Color(hex: 0x30D158),
                showSeparator: true
            ) {
                onSwitchTab(.calls)
            }

            telegramRow(
                title: "Devices",
                symbol: "laptopcomputer",
                color: Color(hex: 0xFF9F0A),
                showSeparator: true
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

            telegramRow(
                title: "Chat Folders",
                symbol: "folder.fill",
                color: Color(hex: 0x64D2FF),
                showSeparator: false
            ) {
                onSwitchTab(.chats)
            }
        }
        .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var preferencesGroup: some View {
        VStack(spacing: 0) {
            telegramRow(
                title: "Notifications and Sounds",
                symbol: "bell.badge.fill",
                color: Color(hex: 0xFF453A),
                showSeparator: true
            ) {
                onOpenRoute(.notifications)
            }

            telegramRow(
                title: "Privacy and Security",
                symbol: "lock.fill",
                color: Color(hex: 0x8E8E93),
                showSeparator: true
            ) {
                onOpenRoute(.privacySecurity)
            }

            telegramRow(
                title: "Data and Storage",
                symbol: "arrow.up.arrow.down.circle.fill",
                color: Color(hex: 0x30D158),
                showSeparator: true
            ) {
                onOpenRoute(.dataStorage)
            }

            telegramRow(
                title: "Appearance",
                symbol: "paintbrush.fill",
                color: Color(hex: 0x0A84FF),
                showSeparator: true
            ) {
                onOpenRoute(.appearance)
            }

            telegramRow(
                title: "Stickers and Emoji",
                symbol: "face.smiling.fill",
                color: Color(hex: 0xFFD60A),
                showSeparator: false
            ) {
                onOpenRoute(.stickers)
            }
        }
        .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var aiEngineGroup: some View {
        VStack(spacing: 0) {
            telegramRow(
                title: "AI Gateway & OpenRouter",
                subtitle: aiWorkspace.isConfigured ? "Live" : "Fallback",
                symbol: "sparkles",
                color: Color(hex: 0xBF5AF2),
                showSeparator: true
            ) {
                onOpenRoute(.aiSetup)
            }

            telegramRow(
                title: "AI Agent Library",
                subtitle: "7 Contacts",
                symbol: "person.2.fill",
                color: Color(hex: 0x5E5CE6),
                showSeparator: true
            ) {
                onSwitchTab(.contacts)
            }

            telegramRow(
                title: "Language",
                subtitle: "English",
                symbol: "globe",
                color: Color(hex: 0x64D2FF),
                showSeparator: false
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var helpGroup: some View {
        VStack(spacing: 0) {
            telegramRow(
                title: "Ask a Question",
                symbol: "bubble.left.and.bubble.right.fill",
                color: Color(hex: 0xFF9F0A),
                showSeparator: true
            ) {
                onSwitchTab(.chats)
            }

            telegramRow(
                title: "AIGram FAQ",
                symbol: "questionmark.circle.fill",
                color: Color(hex: 0x0A84FF),
                showSeparator: false
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .background(TelegramPalette.backgroundElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func telegramRow(
        title: String,
        subtitle: String? = nil,
        symbol: String,
        color: Color,
        showSeparator: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color)
                    .frame(width: 29, height: 29)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                    }

                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(TelegramPalette.mutedText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TelegramPalette.mutedText.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 55)
            }
        }
    }
}

struct QRCodeShareSheet: View {
    let displayName: String
    let username: String
    let initials: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TelegramPalette.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)

                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .frame(width: 260, height: 260)

                        VStack(spacing: 6) {
                            Image(systemName: "qrcode")
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .foregroundStyle(Color.black)
                        }
                        .overlay {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFF9966), Color(hex: 0xFF5E62)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Text(initials)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        }
                    }
                    .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)

                    VStack(spacing: 4) {
                        Text(displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        Text("aigram.app/\(username.replacingOccurrences(of: "@", with: ""))")
                            .font(.system(size: 15))
                            .foregroundStyle(TelegramPalette.skyBlue)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        UIPasteboard.general.string = "https://aigram.app/\(username.replacingOccurrences(of: "@", with: ""))"
                        dismiss()
                    } label: {
                        Text("Share QR Code")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(TelegramPalette.accentBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        UIPasteboard.general.string = "https://aigram.app/\(username.replacingOccurrences(of: "@", with: ""))"
                        dismiss()
                    } label: {
                        Text("Copy Link")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.fraction(0.7)])
        .presentationDragIndicator(.visible)
    }
}
