import SwiftUI

struct TempoCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Event") {
                NotificationCenter.default.post(name: .newEvent, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Reminder") {
                NotificationCenter.default.post(name: .newReminder, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("Calendar") {
                NotificationCenter.default.post(name: .switchToCalendar, object: nil)
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Reminders") {
                NotificationCenter.default.post(name: .switchToReminders, object: nil)
            }
            .keyboardShortcut("2", modifiers: .command)

            Divider()

            Button("Month View") {
                NotificationCenter.default.post(name: .switchToMonthView, object: nil)
            }
            .keyboardShortcut("m", modifiers: [.command, .option])

            Button("Week View") {
                NotificationCenter.default.post(name: .switchToWeekView, object: nil)
            }
            .keyboardShortcut("w", modifiers: [.command, .option])

            Button("Day View") {
                NotificationCenter.default.post(name: .switchToDayView, object: nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newEvent = Notification.Name("newEvent")
    static let newReminder = Notification.Name("newReminder")
    static let switchToCalendar = Notification.Name("switchToCalendar")
    static let switchToReminders = Notification.Name("switchToReminders")
    static let switchToMonthView = Notification.Name("switchToMonthView")
    static let switchToWeekView = Notification.Name("switchToWeekView")
    static let switchToDayView = Notification.Name("switchToDayView")
}
