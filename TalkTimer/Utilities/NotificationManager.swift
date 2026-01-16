import OSLog
import UserNotifications

protocol NotificationManaging {
    func requestAuthorization()
    func scheduleTimerNotifications(remainingSeconds: Int, yellowThreshold: Int, redThreshold: Int)
    func cancelAllNotifications()
}

final class NotificationManager {
    static let shared = NotificationManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TalkTimer", category: "NotificationManager")
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                self.logger.error("Notification authorization error: \(String(describing: error))")
            }
        }
    }

    func scheduleTimerNotifications(
        remainingSeconds: Int,
        yellowThreshold: Int,
        redThreshold: Int
    ) {
        // Cancel any existing notifications first
        cancelAllNotifications()

        // Schedule yellow threshold notification
        if remainingSeconds > yellowThreshold {
            let yellowDelay = TimeInterval(remainingSeconds - yellowThreshold)
            scheduleNotification(
                identifier: "yellow-threshold",
                title: "Warning",
                body: "Yellow zone - \(formatTime(yellowThreshold)) remaining",
                delay: yellowDelay
            )
        }

        // Schedule red threshold notification
        if remainingSeconds > redThreshold {
            let redDelay = TimeInterval(remainingSeconds - redThreshold)
            scheduleNotification(
                identifier: "red-threshold",
                title: "Hurry!",
                body: "Red zone - \(formatTime(redThreshold)) remaining",
                delay: redDelay
            )
        }

        // Schedule timer finished notification
        if remainingSeconds > 0 {
            scheduleNotification(
                identifier: "timer-finished",
                title: "Time's up!",
                body: "Your talk time has ended",
                delay: TimeInterval(remainingSeconds)
            )
        }
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    private func scheduleNotification(identifier: String, title: String, body: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error {
                self.logger.error("Failed to schedule notification: \(String(describing: error))")
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(mins) min"
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}

extension NotificationManager: NotificationManaging {}
