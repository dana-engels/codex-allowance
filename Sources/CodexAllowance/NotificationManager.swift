import Foundation
import UserNotifications
import AllowanceCore

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private var sending = false


    override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission(completion: @escaping (Bool, String?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { allowed, error in
            DispatchQueue.main.async { completion(allowed, error?.localizedDescription) }
        }
    }

    func check(_ snapshot: UsageSnapshot, enabled: Bool) {
        guard enabled, !sending, let accountID = snapshot.accountID,
              let window = snapshot.fiveHour, window.isCurrent(at: Date()) else { return }
        var histories = defaults.data(forKey: "alertHistories").flatMap {
            try? JSONDecoder().decode([String: AlertHistory].self, from: $0)
        } ?? [:]
        histories = histories.filter { $0.value.reset > Date() }
        var history = histories[accountID]
        if history?.matches(accountID: accountID, reset: window.resetsAt) != true {
            history = AlertHistory(accountID: accountID, reset: window.resetsAt, sent: [])
        }
        guard var history,
              let threshold = AlertPolicy.threshold(remaining: window.remainingPercent, alreadySent: history.sent) else { return }
        sending = true
        center.getNotificationSettings { settings in
            guard [.authorized, .provisional].contains(settings.authorizationStatus) else {
                DispatchQueue.main.async { self.sending = false }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Codex allowance is running low"
            let time = DateFormatter(); time.timeStyle = .short
            content.body = "\(window.remainingPercent)% of your five-hour allowance remains. Resets at \(time.string(from: window.resetsAt))."
            content.sound = .default
            let identifier = "allowance-\(Int(window.resetsAt.timeIntervalSince1970 / 60))-\(threshold)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            self.center.add(request) { error in
                DispatchQueue.main.async {
                    self.sending = false
                    // A failed notification is retried; do not mark it as delivered.
                    guard error == nil else { return }
                    history.sent.formUnion(AlertPolicy.thresholdsCovered(by: threshold))
                    histories[accountID] = history
                    if let data = try? JSONEncoder().encode(histories) {
                        self.defaults.set(data, forKey: "alertHistories")
                    }
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
