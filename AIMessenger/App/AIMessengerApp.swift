import SwiftUI

@main
struct AIMessengerApp: App {
    init() {
        _ = AppNotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
