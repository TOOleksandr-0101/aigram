import SwiftUI

struct SettingsHubScreen: View {
    let onOpenRoute: (SettingsRoute) -> Void
    let onSwitchTab: (AppTab) -> Void

    @EnvironmentObject private var aiWorkspace: AIWorkspace

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                topBar
                profileHero
                quickActions
                workspaceSection
                preferencesSection
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 112)
        }
        .background(backgroundLayer)
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [TelegramPalette.settingsCanvasTop, TelegramPalette.settingsCanvasBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color(hex: 0xCDD6FF, opacity: 0.45))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: -70, y: -80)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xFFE0C5, opacity: 0.65))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: 80, y: -50)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack(spacing: 14) {
            HStack {
                Button("Edit") {
                    onOpenRoute(.editProfile)
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(TelegramPalette.accentBlue)

                Spacer()

                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(TelegramPalette.settingsPrimaryText)

                Spacer()

                Button {
                    onOpenRoute(.editProfile)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(TelegramPalette.accentBlue)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(TelegramPalette.settingsSecondaryText)

                Text("Search")
                    .font(.system(size: 17))
                    .foregroundStyle(TelegramPalette.settingsSecondaryText)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(TelegramPalette.settingsSearchFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                    }
            )
            .shadow(color: TelegramPalette.settingsShadow, radius: 20, y: 10)
        }
    }

    private var profileHero: some View {
        Button {
            onOpenRoute(.editProfile)
        } label: {
            ZStack(alignment: .topTrailing) {
                roundedCard(cornerRadius: 28)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFFB765), Color(hex: 0xFF6F91)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Circle()
                                .stroke(Color.white.opacity(0.82), lineWidth: 2)
                                .padding(4)

                            Text(aiWorkspace.initials)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 78, height: 78)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(aiWorkspace.displayName)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(TelegramPalette.settingsPrimaryText)

                            Text(aiWorkspace.connectionLabel)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(TelegramPalette.accentBlue)

                            Text("\(aiWorkspace.username)  •  \(aiWorkspace.modelDisplayName)")
                                .font(.system(size: 15))
                                .foregroundStyle(TelegramPalette.settingsSecondaryText)
                        }
                    }

                    HStack(spacing: 10) {
                        statPill(title: "7", subtitle: "agents")
                        statPill(title: "24", subtitle: "chats")
                        statPill(title: aiWorkspace.isConfigured ? "Live" : "Local", subtitle: "mode")
                    }
                }
                .padding(22)

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x5F87FF), Color(hex: 0x8B67FF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .padding(18)
            }
        }
        .buttonStyle(.plain)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            actionCard(title: "Saved", subtitle: "Chats", symbol: "bookmark.fill", colors: [Color(hex: 0x66C4FF), Color(hex: 0x2D87FF)]) {
                onSwitchTab(.chats)
            }
            actionCard(title: "Voice", subtitle: "Calls", symbol: "phone.fill", colors: [Color(hex: 0x7CBAFF), Color(hex: 0x5A6CFF)]) {
                onSwitchTab(.calls)
            }
            actionCard(title: "Agents", subtitle: "Library", symbol: "sparkles", colors: [Color(hex: 0xFFBF78), Color(hex: 0xFF7B70)]) {
                onSwitchTab(.contacts)
            }
        }
    }

    private var workspaceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Workspace")

            SettingsGlassCard {
                modernRow(title: "Profile", subtitle: "Name, handle and bio", symbol: "person.crop.square.fill", colors: [Color(hex: 0x7187FF), Color(hex: 0x8F71FF)]) {
                    onOpenRoute(.editProfile)
                }
                cardDivider
                modernRow(title: "Agent Library", subtitle: "Browse your AI contacts", symbol: "square.grid.2x2.fill", colors: [Color(hex: 0x4DB7FF), Color(hex: 0x2B8CFF)]) {
                    onSwitchTab(.contacts)
                }
                cardDivider
                modernRow(title: "Saved Messages", subtitle: "Pinned notes and long-term context", symbol: "bookmark.fill", colors: [Color(hex: 0x52C2B9), Color(hex: 0x2A9D8F)]) {
                    onSwitchTab(.chats)
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Preferences")

            SettingsGlassCard {
                modernRow(title: "Notifications", subtitle: "Alerts, previews and sounds", symbol: "bell.badge.fill", colors: [Color(hex: 0xFF8F85), Color(hex: 0xFF6363)]) {
                    onOpenRoute(.notifications)
                }
                cardDivider
                modernRow(title: "AI Gateway", subtitle: "OpenRouter, model and privacy", symbol: "brain.head.profile", colors: [Color(hex: 0x5DB8FF), Color(hex: 0x6B66FF)]) {
                    onOpenRoute(.aiSetup)
                }
                cardDivider
                modernRow(title: "Privacy & Security", subtitle: "Visibility, passcode and sessions", symbol: "lock.shield.fill", colors: [Color(hex: 0x68D2B0), Color(hex: 0x1AA083)]) {
                    onOpenRoute(.privacySecurity)
                }
                cardDivider
                modernRow(title: "Data & Storage", subtitle: "Downloads, cache and network", symbol: "externaldrive.fill", colors: [Color(hex: 0x7BC2FF), Color(hex: 0x4B92FF)]) {
                    onOpenRoute(.dataStorage)
                }
                cardDivider
                modernRow(title: "Appearance", subtitle: "Theme, text size and icon", symbol: "paintpalette.fill", colors: [Color(hex: 0x9E8BFF), Color(hex: 0x6C63FF)]) {
                    onOpenRoute(.appearance)
                }
            }
        }
    }

    private func actionCard(
        title: String,
        subtitle: String,
        symbol: String,
        colors: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(TelegramPalette.settingsPrimaryText)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(TelegramPalette.settingsSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(TelegramPalette.settingsCard)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(TelegramPalette.settingsCardStroke, lineWidth: 1)
                    }
            )
            .shadow(color: TelegramPalette.settingsShadow, radius: 20, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func modernRow(
        title: String,
        subtitle: String,
        symbol: String,
        colors: [Color],
        trailingBadge: String? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(TelegramPalette.settingsPrimaryText)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(TelegramPalette.settingsSecondaryText)
                        .lineLimit(1)
                }

                Spacer()

                if let trailingBadge {
                    Text(trailingBadge)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TelegramPalette.settingsSecondaryText)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(Color.white.opacity(0.7), in: Capsule(style: .continuous))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0xB1B7CA))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func statPill(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(TelegramPalette.settingsPrimaryText)
            Text(subtitle.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(TelegramPalette.settingsSecondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.56), in: Capsule(style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(TelegramPalette.settingsSecondaryText)
            .padding(.horizontal, 6)
    }

    private func roundedCard(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(TelegramPalette.settingsCard)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(TelegramPalette.settingsCardStroke, lineWidth: 1)
            }
            .shadow(color: TelegramPalette.settingsShadow, radius: 26, y: 14)
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.72))
            .frame(height: 1)
            .padding(.leading, 74)
            .padding(.trailing, 18)
    }
}

private struct SettingsGlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(TelegramPalette.settingsCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(TelegramPalette.settingsCardStroke, lineWidth: 1)
                }
        )
        .shadow(color: TelegramPalette.settingsShadow, radius: 24, y: 14)
    }
}

struct SettingsHubScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsHubScreen(onOpenRoute: { _ in }, onSwitchTab: { _ in })
            .environmentObject(AIWorkspace())
    }
}
