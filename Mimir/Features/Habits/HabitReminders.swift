import Foundation
import SwiftData
import UserNotifications

/// Reminders are scheduled one by one for upcoming days, skipping days a habit is already finished.
/// Re-run after every change, so ticking a habit off cancels today's reminder.
enum HabitReminders {
    private static let slots = (0..<64).map { "habit.\($0)" }  // iOS keeps at most 64 pending

    static func requestPermission() {
        Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
    }

    static func update(_ context: ModelContext?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: slots)

        let cal = Calendar.current
        let habits = ((try? context?.fetch(FetchDescriptor<Habit>())) ?? []).filter { $0.reminder != nil && !$0.archived }
        var upcoming: [(habit: Habit, date: Date)] = []
        for habit in habits {
            let time = cal.dateComponents([.hour, .minute], from: habit.reminder!)
            for offset in 0..<7 {
                let day = cal.date(byAdding: .day, value: offset, to: .now)!
                let date = cal.date(bySettingHour: time.hour!, minute: time.minute!, second: 0, of: day)!
                if date > .now && habit.isOpen(on: day) { upcoming.append((habit, date)) }
            }
        }

        for (slot, item) in zip(slots, upcoming.sorted { $0.date < $1.date }) {
            let content = UNMutableNotificationContent()
            content.title = item.habit.name
            content.sound = .default
            let when = cal.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
            center.add(UNNotificationRequest(identifier: slot, content: content,
                                             trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)))
        }
    }
}
