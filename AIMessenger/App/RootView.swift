import SwiftUI

struct RootView: View {
    @StateObject private var aiWorkspace = AIWorkspace()
    @State private var selectedTab: AppTab = .chats
    @State private var contactsPath: [ContactsRoute] = []
    @State private var chatsPath: [ChatsRoute] = []
    @State private var settingsPath: [SettingsRoute] = []

    var body: some View {
        appShell
    }

    private var appShell: some View {
        ZStack(alignment: .bottom) {
            currentScreen

            if isTabBarVisible {
                AppTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(TelegramPalette.backgroundPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .environmentObject(aiWorkspace)
        .onAppear {
            handleLaunchArguments()
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .contacts:
            NavigationStack(path: $contactsPath) {
                ContactsScreen(
                    onOpenContact: { contact in
                        contactsPath.append(.info(contact))
                    },
                    onOpenChat: { thread in
                        contactsPath = []
                        selectedTab = .chats
                        chatsPath = [.conversation(thread)]
                    }
                )
                .navigationDestination(for: ContactsRoute.self) { route in
                    switch route {
                    case let .info(contact):
                        ContactInfoScreen(
                            contact: contact,
                            onEdit: {
                                contactsPath.append(.editInfo(contact))
                            },
                            onStartChat: { thread in
                                contactsPath = []
                                selectedTab = .chats
                                chatsPath = [.conversation(thread)]
                            }
                        )
                    case let .editInfo(contact):
                        EditableContactInfoScreen(contact: contact)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        case .calls:
            NavigationStack {
                CallsScreen()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        case .chats:
            NavigationStack(path: $chatsPath) {
                ChatsScreen { thread in
                    chatsPath.append(.conversation(thread))
                }
                .navigationDestination(for: ChatsRoute.self) { route in
                    switch route {
                    case let .conversation(thread):
                        ChatConversationScreen(thread: thread)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        case .settings:
            NavigationStack(path: $settingsPath) {
                SettingsHubScreen(
                    onOpenRoute: { route in
                        settingsPath.append(route)
                    },
                    onSwitchTab: { tab in
                        selectedTab = tab
                    }
                )
                .navigationDestination(for: SettingsRoute.self) { route in
                    switch route {
                    case .editProfile:
                        EditProfileScreen()
                    case .aiSetup:
                        AIGatewayScreen()
                    case .notifications:
                        NotificationsScreen()
                    case .privacySecurity:
                        PrivacySecurityScreen()
                    case .dataStorage:
                        DataStorageScreen()
                    case .appearance:
                        AppearanceScreen()
                    case .stickers:
                        StickersScreen()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        }
    }

    private var isTabBarVisible: Bool {
        switch selectedTab {
        case .contacts:
            return contactsPath.isEmpty
        case .calls:
            return true
        case .chats:
            return chatsPath.isEmpty
        case .settings:
            return settingsPath.isEmpty
        }
    }

    private func handleLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-openDesignScout") {
            if let thread = aiWorkspace.threads.first(where: { $0.id == "design-scout" }) ?? aiWorkspace.threads.first {
                selectedTab = .chats
                chatsPath = [.conversation(thread)]
            }
        } else if args.contains("-openCodePartner") {
            if let thread = aiWorkspace.threads.first(where: { $0.id == "code-partner" }) {
                selectedTab = .chats
                chatsPath = [.conversation(thread)]
            }
        } else if args.contains("-openSettings") {
            selectedTab = .settings
        } else if args.contains("-openAIGateway") {
            selectedTab = .settings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                settingsPath = [.aiSetup]
            }
        } else if args.contains("-openNotifications") {
            selectedTab = .settings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                settingsPath = [.notifications]
            }
        } else if args.contains("-openAppearance") {
            selectedTab = .settings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                settingsPath = [.appearance]
            }
        } else if args.contains("-openCalls") {
            selectedTab = .calls
        } else if args.contains("-openContacts") {
            selectedTab = .contacts
        } else if args.contains("-openContactInfo") {
            selectedTab = .contacts
            if let contact = aiWorkspace.contacts.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    contactsPath = [.info(contact)]
                }
            }
        } else if args.contains("-openDataStorage") {
            selectedTab = .settings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                settingsPath = [.dataStorage]
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
