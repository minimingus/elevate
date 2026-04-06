import UserNotifications
import Foundation

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Call after every session or on app launch. Reschedules both notifications.
    func scheduleDaily(currentStreak: Int, todaySteps: Int, dailyGoal: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder", "streak_protection"])

        let calendar = Calendar.current

        // Daily reminder at 7pm — only if goal not yet met
        if todaySteps < dailyGoal {
            let content = UNMutableNotificationContent()
            content.title = "Time to climb"
            content.body = todaySteps > 0
                ? "You've got \(todaySteps) steps today. Finish strong!"
                : "You haven't climbed yet today. Every step counts."
            content.sound = .default

            var date = DateComponents()
            date.hour = 19
            date.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            center.add(UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger))
        }

        // Streak protection at 9pm — only if streak > 0 and goal not met
        if currentStreak > 0 && todaySteps < dailyGoal {
            let content = UNMutableNotificationContent()
            content.title = "\(currentStreak)-day streak at risk 🔥"
            content.body = "Climb some stairs before midnight to keep your streak alive."
            content.sound = .default

            var date = DateComponents()
            date.hour = 21
            date.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            center.add(UNNotificationRequest(identifier: "streak_protection", content: content, trigger: trigger))
        }
    }
}
