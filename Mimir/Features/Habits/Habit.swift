import Foundation
import SwiftData

@Model final class Habit {
    var name = ""
    var section = ""
    var perWeek = 7               // 7 = every day
    var reminder: Date?           // only the time of day is used; nil = no reminder
    var days: [Date] = []         // start of each day it was done
    var archived = false
    var created = Date.now

    init() {}
}

extension Habit {
    var isDaily: Bool { perWeek == 7 }

    var goal: String { isDaily ? "Every day" : "\(perWeek)× a week" }

    func isDone(on day: Date) -> Bool { days.contains(cal.startOfDay(for: day)) }

    /// Still needs doing that day: not done yet, and the week's goal isn't reached.
    func isOpen(on day: Date = .now) -> Bool { !isDone(on: day) && count(inWeekOf: day) < perWeek }

    func toggle(_ day: Date = .now) {
        let day = cal.startOfDay(for: day)
        if let i = days.firstIndex(of: day) { days.remove(at: i) } else { days.append(day) }
        HabitReminders.update(modelContext)
    }

    func count(inWeekOf day: Date) -> Int {
        let week = cal.dateInterval(of: .weekOfYear, for: day)!
        return days.filter { week.start <= $0 && $0 < week.end }.count
    }

    /// Days (every-day habits) or weeks (weekly habits) in a row the goal was met.
    /// Today / this week only counts once met, and never breaks the streak while still open.
    var streak: Int {
        var date = isMet(.now) ? Date.now : back(.now)
        var n = 0
        while isMet(date) { n += 1; date = back(date) }
        return n
    }

    var bestStreak: Int {
        guard let first = days.min() else { return 0 }
        var date = cal.dateInterval(of: unit, for: first)!.start
        var n = 0, best = 0
        while date <= .now {
            n = isMet(date) ? n + 1 : 0
            best = max(best, n)
            date = cal.date(byAdding: unit, value: 1, to: date)!
        }
        return best
    }

    /// What the list shows: this week's progress while a weekly goal is open, otherwise the streak.
    var status: String {
        let done = count(inWeekOf: .now)
        if !isDaily && done < perWeek { return "\(done)/\(perWeek) this week" }
        return streak > 0 ? "🔥 " + periods(streak) : ""
    }

    func periods(_ n: Int) -> String { "\(n) \(isDaily ? "day" : "week")\(n == 1 ? "" : "s")" }

    private var cal: Calendar { .current }
    private var unit: Calendar.Component { isDaily ? .day : .weekOfYear }
    private func isMet(_ date: Date) -> Bool { isDaily ? isDone(on: date) : count(inWeekOf: date) >= perWeek }
    private func back(_ date: Date) -> Date { cal.date(byAdding: unit, value: -1, to: date)! }
}
