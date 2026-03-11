import SwiftUI
import EventKit

struct RemindersTabView: View {
    @EnvironmentObject var eventKitManager: EventKitManager
    @StateObject private var viewModel = RemindersViewModel()
    @State private var showingReminderEditor = false
    @State private var editingReminder: EKReminder?

    var body: some View {
        Group {
            if !eventKitManager.remindersAccessGranted {
                PermissionDeniedView(type: "Reminders")
            } else {
                remindersContent
            }
        }
        .onAppear {
            refreshReminders()
        }
    }

    @ViewBuilder
    private var remindersContent: some View {
        VStack(spacing: 0) {
            remindersToolbar
            Divider()
            HSplitView {
                RemindersSidebarView(viewModel: viewModel) {
                    refreshReminders()
                }
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)

                remindersList
            }
        }
        .sheet(isPresented: $showingReminderEditor) {
            ReminderEditorSheet(
                reminder: editingReminder,
                selectedList: viewModel.selectedList,
                onSave: {
                    refreshReminders()
                    showingReminderEditor = false
                    editingReminder = nil
                },
                onCancel: {
                    showingReminderEditor = false
                    editingReminder = nil
                },
                onDelete: {
                    refreshReminders()
                    showingReminderEditor = false
                    editingReminder = nil
                }
            )
        }
    }

    private var remindersToolbar: some View {
        HStack {
            Text(viewModel.isShowingAllList ? "All Reminders" : (viewModel.selectedList?.title ?? "Reminders"))
                .font(.headline)

            Spacer()

            Button(action: {
                editingReminder = nil
                showingReminderEditor = true
            }) {
                Image(systemName: "plus")
            }
            .help("New Reminder")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var remindersList: some View {
        let incomplete = viewModel.incompleteReminders(from: filteredReminders)
        let completed = viewModel.completedReminders(from: filteredReminders)

        if incomplete.isEmpty && completed.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No reminders")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("Tap + to create a new reminder")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(incomplete, id: \.calendarItemIdentifier) { reminder in
                        ReminderRowView(
                            reminder: reminder,
                            viewModel: viewModel,
                            onToggle: { toggleCompletion(reminder) },
                            onTap: {
                                editingReminder = reminder
                                showingReminderEditor = true
                            }
                        )
                    }

                    if !completed.isEmpty {
                        DisclosureGroup(isExpanded: $viewModel.showCompleted) {
                            ForEach(completed, id: \.calendarItemIdentifier) { reminder in
                                ReminderRowView(
                                    reminder: reminder,
                                    viewModel: viewModel,
                                    onToggle: { toggleCompletion(reminder) },
                                    onTap: {
                                        editingReminder = reminder
                                        showingReminderEditor = true
                                    }
                                )
                            }
                        } label: {
                            Text("Completed (\(completed.count))")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var filteredReminders: [EKReminder] {
        if viewModel.isShowingAllList {
            return eventKitManager.reminders
        }
        guard let list = viewModel.selectedList else { return eventKitManager.reminders }
        return eventKitManager.reminders.filter { $0.calendar.calendarIdentifier == list.calendarIdentifier }
    }

    private func refreshReminders() {
        if viewModel.isShowingAllList {
            eventKitManager.fetchReminders(for: nil)
        } else {
            eventKitManager.fetchReminders(for: viewModel.selectedList)
        }
    }

    private func toggleCompletion(_ reminder: EKReminder) {
        do {
            try eventKitManager.toggleReminderCompletion(reminder)
            refreshReminders()
        } catch {
            // Error handled silently; data stays in sync via EventKit notification
        }
    }
}
