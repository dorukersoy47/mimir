import SwiftUI
import SwiftData

struct HabitForm: View {
    @Bindable var habit: Habit
    var isNew = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]

    private var sections: [String] {
        Set(habits.map(\.section)).filter { !$0.isEmpty }.sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $habit.name)
                HStack {
                    TextField("Section (optional)", text: $habit.section)
                    if !sections.isEmpty {
                        Menu {
                            ForEach(sections, id: \.self) { name in
                                Button(name) { habit.section = name }
                            }
                        } label: {
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                }
                Stepper(habit.goal, value: $habit.perWeek, in: 1...7)
                Toggle("Reminder", isOn: Binding(
                    get: { habit.reminder != nil },
                    set: { on in
                        habit.reminder = on ? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) : nil
                        if on { HabitReminders.requestPermission() }
                    }
                ))
                if habit.reminder != nil {
                    DatePicker("Time", selection: Binding(get: { habit.reminder ?? .now }, set: { habit.reminder = $0 }),
                               displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle(isNew ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isNew {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Add" : "Done") {
                        if isNew { context.insert(habit) }
                        dismiss()
                    }
                    .disabled(habit.name.isEmpty)
                }
            }
            .onDisappear { HabitReminders.update(context) }
        }
    }
}
