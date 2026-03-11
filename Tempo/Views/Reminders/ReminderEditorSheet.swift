import SwiftUI
import EventKit

struct ReminderEditorSheet: View {
    @EnvironmentObject var eventKitManager: EventKitManager

    let reminder: EKReminder?
    let selectedList: EKCalendar?
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasDueTime = false
    @State private var dueTime = Date()
    @State private var selectedListID: String = ""
    @State private var priority: Int = 0
    @State private var url = ""
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false

    private var isEditing: Bool { reminder != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(isEditing ? "Edit Reminder" : "New Reminder")
                    .font(.headline)
                Spacer()
                Button("Save") { saveReminder() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()

            Divider()

            // Form
            Form {
                TextField("Title", text: $title)
                    .font(.title3)

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                Toggle("Due Date", isOn: $hasDueDate)

                if hasDueDate {
                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)

                    Toggle("Due Time", isOn: $hasDueTime)

                    if hasDueTime {
                        DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                    }
                }

                Picker("List", selection: $selectedListID) {
                    ForEach(eventKitManager.reminderLists, id: \.calendarIdentifier) { list in
                        HStack {
                            Circle()
                                .fill(Color(cgColor: list.cgColor))
                                .frame(width: 8, height: 8)
                            Text(list.title)
                        }
                        .tag(list.calendarIdentifier)
                    }
                }

                Picker("Priority", selection: $priority) {
                    Text("None").tag(0)
                    Text("Low").tag(9)
                    Text("Medium").tag(5)
                    Text("High").tag(1)
                }

                TextField("URL", text: $url)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if isEditing {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Reminder")
                            .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 420, height: 520)
        .onAppear(perform: loadReminder)
        .alert("Delete Reminder", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteReminder() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this reminder? This action cannot be undone.")
        }
    }

    // MARK: - Load

    private func loadReminder() {
        if let reminder = reminder {
            title = reminder.title ?? ""
            notes = reminder.notes ?? ""
            selectedListID = reminder.calendar.calendarIdentifier
            priority = Int(reminder.priority)
            url = reminder.url?.absoluteString ?? ""

            if let dueComponents = reminder.dueDateComponents, let date = dueComponents.date {
                hasDueDate = true
                dueDate = date
                hasDueTime = dueComponents.hour != nil
                if hasDueTime {
                    dueTime = date
                }
            }
        } else {
            selectedListID = selectedList?.calendarIdentifier
                ?? eventKitManager.eventStore.defaultCalendarForNewReminders()?.calendarIdentifier
                ?? ""
        }
    }

    // MARK: - Save

    private func saveReminder() {
        let ekReminder = reminder ?? eventKitManager.createNewReminder()
        ekReminder.title = title.trimmingCharacters(in: .whitespaces)
        ekReminder.notes = notes.isEmpty ? nil : notes
        ekReminder.priority = priority
        if let urlObj = URL(string: url), !url.isEmpty {
            ekReminder.url = urlObj
        }

        if let list = eventKitManager.reminderLists.first(where: { $0.calendarIdentifier == selectedListID }) {
            ekReminder.calendar = list
        }

        if hasDueDate {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            if hasDueTime {
                let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: dueTime)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
            }
            ekReminder.dueDateComponents = components
        } else {
            ekReminder.dueDateComponents = nil
        }

        do {
            try eventKitManager.saveReminder(ekReminder)
            onSave()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete

    private func deleteReminder() {
        guard let reminder = reminder else { return }
        do {
            try eventKitManager.deleteReminder(reminder)
            onDelete()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
}
