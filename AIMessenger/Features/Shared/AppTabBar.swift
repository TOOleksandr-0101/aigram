import SwiftUI

struct AppTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                tabButton(for: .contacts, label: "Contacts", symbol: "person.crop.circle.fill")
                tabButton(for: .calls, label: "Calls", symbol: "phone.fill")
                chatsButton
                settingsButton
            }
            .frame(height: 49)

            Capsule(style: .continuous)
                .fill(Color.white)
                .frame(width: 134, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
        .background(TelegramPalette.tabBarBackground)
    }

    private func tabButton(for tab: AppTab, label: String, symbol: String) -> some View {
        let active = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(active ? Color.white : Color.white.opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var chatsButton: some View {
        let active = selectedTab == .chats

        return Button {
            selectedTab = .chats
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24, weight: .medium))

                    Text("2")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0x1C1C1D))
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.white))
                        .offset(x: 10, y: -6)
                }

                Text("Chats")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(active ? Color.white : Color.white.opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var settingsButton: some View {
        let active = selectedTab == .settings

        return Button {
            selectedTab = .settings
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFAA4B), Color(hex: 0xFF5E7A)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 25, height: 25)
                    .overlay {
                        Text("AI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }

                Text("Settings")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(active ? Color.white : Color.white.opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct AppTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            TelegramPalette.backgroundPrimary.ignoresSafeArea()
            AppTabBar(selectedTab: .constant(.chats))
        }
        .preferredColorScheme(.dark)
    }
}
