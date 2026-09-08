import Foundation
import UserNotifications
import UIKit

@MainActor
final class AppNotificationService: NSObject, ObservableObject {
    static let shared = AppNotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationsEnabled: Bool = false
    @Published var soundEnabled: Bool = true
    @Published var previewEnabled: Bool = true

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task {
            await refreshStatus()
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        self.notificationsEnabled = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshStatus()
            return granted
        } catch {
            print("[AppNotificationService] Permission request failed: \(error)")
            await refreshStatus()
            return false
        }
    }

    func scheduleLocalNotification(
        title: String,
        subtitle: String? = nil,
        body: String,
        delaySeconds: TimeInterval = 1.0,
        threadId: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let sub = subtitle, !sub.isEmpty {
            content.subtitle = sub
        }
        content.body = body
        if soundEnabled {
            content.sound = .default
        }
        if let threadId = threadId {
            content.threadIdentifier = threadId
            content.userInfo = ["threadId": threadId]
        }

        let triggerTime = max(0.5, delaySeconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
        let identifier = "aigram_notify_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[AppNotificationService] Failed to schedule notification: \(error)")
            }
        }
    }

    func sendTestNotificationNow() {
        scheduleLocalNotification(
            title: "Atlas Architect",
            subtitle: "AIGram Workspace",
            body: "🚀 High-performance reactive state engine and video note pipeline successfully verified!",
            delaySeconds: 1.0,
            threadId: "product-coach"
        )
    }
}

extension AppNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when the app is in the foreground
        completionHandler([.banner, .sound, .badge, .list])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
