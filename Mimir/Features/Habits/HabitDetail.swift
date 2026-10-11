import SwiftUI

struct HabitDetail: View {
    let habit: Habit
    @State private var editing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Goal", value: habit.goal)
                if !habit.isDaily {
                    LabeledContent("This week", value: "\(habit.count(inWeekOf: .now))/\(habit.perWeek)")
                }
                LabeledContent("Streak", value: "🔥 " + habit.periods(habit.streak))
                LabeledContent("Best", value: habit.periods(habit.bestStreak))
            }
            Section {
                HabitHistory(habit: habit)
            } header: {
                Text("History")
            } footer: {
                Text("Tap a day to fix it.")
            }
        }
        .navigationTitle(habit.name)
        .toolbar { Button("Edit") { editing = true } }
        .sheet(isPresented: $editing) { HabitForm(habit: habit) }
    }
}

/// GitHub-style grid: one column per week, one square per day, newest week on the right.
private struct HabitHistory: View {
    let habit: Habit
    private let cal = Calendar.current
    private let size = 20.0

    var body: some View {
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: .now)!.start
        let first = cal.dateInterval(of: .weekOfYear, for: ([habit.created] + habit.days).min()!)!.start
        let weeks = max(16, cal.dateComponents([.weekOfYear], from: first, to: thisWeek).weekOfYear! + 1)

        HStack(alignment: .top) {
            VStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { d in
                    Text(cal.date(byAdding: .day, value: d, to: thisWeek)!, format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(height: size)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<weeks, id: \.self) { w in
                        let start = cal.date(byAdding: .weekOfYear, value: w - weeks + 1, to: thisWeek)!
                        VStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { d in
                                square(cal.date(byAdding: .day, value: d, to: start)!)
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
        }
    }

    private func square(_ day: Date) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(habit.isDone(on: day) ? Color.green : Color.secondary.opacity(0.2))
            .overlay {
                if cal.isDateInToday(day) { RoundedRectangle(cornerRadius: 4).stroke(.primary) }
            }
            .frame(width: size, height: size)
            .opacity(day > .now ? 0 : 1)
            .onTapGesture {
                if day <= .now { withAnimation { habit.toggle(day) } }
            }
    }
}
