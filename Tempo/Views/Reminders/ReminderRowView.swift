import SwiftUI
import EventKit

struct ReminderRowView: View {
    let reminder: EKReminder
    @ObservedObject var viewModel: RemindersViewModel
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Completion circle
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(reminder.isCompleted ? .green : Color(cgColor: reminder.calendar.cgColor))
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(reminder.title ?? "Untitled")
                        .font(.subheadline)
                        .strikethrough(reminder.isCompleted)
                        .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                        .lineLimit(1)

                    // Priority indicator
                    if let priorityLabel = viewModel.priorityLabel(Int(reminder.priority)) {
                        Text(priorityLabel)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(viewModel.priorityColor(Int(reminder.priority)))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(viewModel.priorityColor(Int(reminder.priority)).opacity(0.1))
                            .cornerRadius(3)
                    }

                }

                HStack(spacing: 6) {
                    // Due date
                    if let dueDate = viewModel.formattedDueDate(reminder) {
                        Text(dueDate)
                            .font(.caption)
                            .foregroundColor(viewModel.isOverdue(reminder) ? .red : .secondary)
                    }

                    // Notes preview
                    if let notes = reminder.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
