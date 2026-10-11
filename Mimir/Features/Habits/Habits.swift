import SwiftUI
import SwiftData

extension Feature {
    static let habits = Feature(name: "Habits", icon: "checkmark.circle", models: [Habit.self], view: AnyView(HabitList()))
}

struct HabitList: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @Query(sort: \Habit.created) private var habits: [Habit]
    @State private var newHabit: Habit?

    private var active: [Habit] { habits.filter { !$0.archived } }

    /// Section names in the order they were first used.
    private var sections: [String] {
        active.map(\.section).reduce(into: []) { if !$0.contains($1) { $0.append($1) } }
    }

    var body: some View {
        List {
            ForEach(sections, id: \.self) { section in
                Section(section) {
                    ForEach(active.filter { $0.section == section }.sorted { $0.isOpen() && !$1.isOpen() }) { habit in
                        HabitRow(habit: habit)
                            .swipeActions {
                                Button("Archive", systemImage: "archivebox") {
                                    habit.archived = true
                                    HabitReminders.update(context)
                                }
                                .tint(.indigo)
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    context.delete(habit)
                                    HabitReminders.update(context)
                                }
                            }
                    }
                }
            }
            let archived = habits.count - active.count
            if archived > 0 {
                Section { NavigationLink("Archived (\(archived))") { ArchivedHabits() } }
            }
        }
        .overlay {
            if habits.isEmpty {
                ContentUnavailableView("No Habits", systemImage: "checkmark.circle",
                                       description: Text("Tap + to add your first habit."))
            }
        }
        .navigationTitle("Habits")
        .toolbar { Button("Add", systemImage: "plus") { newHabit = Habit() } }
        .sheet(item: $newHabit) { HabitForm(habit: $0, isNew: true) }
        .onChange(of: phase, initial: true) {
            if phase == .active { HabitReminders.update(context) }
        }
    }
}

private struct HabitRow: View {
    let habit: Habit

    var body: some View {
        HStack {
            Button {
                withAnimation { habit.toggle() }
            } label: {
                Image(systemName: habit.isDone(on: .now) ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)

            NavigationLink { HabitDetail(habit: habit) } label: {
                LabeledContent(habit.name, value: habit.status)
            }
        }
        .opacity(habit.isOpen() ? 1 : 0.5)
    }
}

private struct ArchivedHabits: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Habit> { $0.archived }, sort: \Habit.created) private var habits: [Habit]

    var body: some View {
        List(habits) { habit in
            NavigationLink(habit.name) { HabitDetail(habit: habit) }
                .swipeActions {
                    Button("Unarchive", systemImage: "arrow.uturn.backward") {
                        habit.archived = false
                        HabitReminders.update(context)
                    }
                    .tint(.indigo)
                    Button("Delete", systemImage: "trash", role: .destructive) { context.delete(habit) }
                }
        }
        .navigationTitle("Archived")
    }
}

#Preview {
    NavigationStack { HabitList() }
        .modelContainer(for: Habit.self, inMemory: true)
}
