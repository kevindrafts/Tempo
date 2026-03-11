import Foundation
import EventKit
import SwiftUI

final class RemindersViewModel: ObservableObject {
    @Published var selectedList: EKCalendar?
    @Published var selectedReminder: EKReminder?
    @Published var showCompleted = false
    @Published var isShowingAllList = true

    // MARK: - List Selection

    func selectList(_ list: EKCalendar?) {
        isShowingAllList = (list == nil)
        selectedList = list
    }

    func selectAllList() {
        isShowingAllList = true
        selectedList = nil
    }

    // MARK: - Filtering & Sorting

    func incompleteReminders(from reminders: [EKReminder]) -> [EKReminder] {
        reminders
            .filter { !$0.isCompleted }
            .sorted { r1, r2 in
                // Sort by due date (soonest first), then by creation date
                let d1 = r1.dueDateComponents?.date
                let d2 = r2.dueDateComponents?.date
                if let d1 = d1, let d2 = d2 {
                    return d1 < d2
                }
                if d1 != nil { return true }
                if d2 != nil { return false }
                return (r1.creationDate ?? Date.distantPast) < (r2.creationDate ?? Date.distantPast)
            }
    }

    func completedReminders(from reminders: [EKReminder]) -> [EKReminder] {
        reminders
            .filter { $0.isCompleted }
            .sorted { r1, r2 in
                (r1.completionDate ?? Date.distantPast) > (r2.completionDate ?? Date.distantPast)
            }
    }

    func reminderCount(for list: EKCalendar, from reminders: [EKReminder]) -> Int {
        reminders.filter { $0.calendar.calendarIdentifier == list.calendarIdentifier && !$0.isCompleted }.count
    }

    func allIncompleteCount(from reminders: [EKReminder]) -> Int {
        reminders.filter { !$0.isCompleted }.count
    }

    // MARK: - Due Date Helpers

    func isOverdue(_ reminder: EKReminder) -> Bool {
        guard let dueDate = reminder.dueDateComponents?.date else { return false }
        return dueDate < Date() && !reminder.isCompleted
    }

    func formattedDueDate(_ reminder: EKReminder) -> String? {
        guard let components = reminder.dueDateComponents, let date = components.date else { return nil }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mm a"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow,' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: date)
    }

    func priorityLabel(_ priority: Int) -> String? {
        switch priority {
        case 1: return "High"
        case 5: return "Medium"
        case 9: return "Low"
        default: return nil
        }
    }

    func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 1: return .red
        case 5: return .orange
        case 9: return .blue
        default: return .secondary
        }
    }
}
