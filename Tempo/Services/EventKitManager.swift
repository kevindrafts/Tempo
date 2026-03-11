import Foundation
import EventKit
import Combine

final class EventKitManager: ObservableObject {
    static let shared = EventKitManager()

    let eventStore = EKEventStore()

    // MARK: - Published State
    @Published var calendarAccessGranted = false
    @Published var remindersAccessGranted = false
    @Published var calendars: [EKCalendar] = []
    @Published var reminderLists: [EKCalendar] = []
    @Published var events: [EKEvent] = []
    @Published var reminders: [EKReminder] = []
    @Published var hiddenCalendarIDs: Set<String> = []

    // Current fetch parameters
    private var currentEventStartDate: Date?
    private var currentEventEndDate: Date?
    private var currentReminderListID: String?
    private var fetchAllReminders = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load hidden calendar IDs from UserDefaults
        if let saved = UserDefaults.standard.array(forKey: "hiddenCalendarIDs") as? [String] {
            hiddenCalendarIDs = Set(saved)
        }

        // Observe external changes to EventKit
        NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: eventStore)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAll()
            }
            .store(in: &cancellables)
    }

    // MARK: - Permissions

    func requestCalendarAccess() async {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            await MainActor.run {
                self.calendarAccessGranted = granted
                if granted {
                    self.fetchCalendars()
                }
            }
        } catch {
            await MainActor.run {
                self.calendarAccessGranted = false
            }
        }
    }

    func requestRemindersAccess() async {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToReminders()
            } else {
                granted = try await eventStore.requestAccess(to: .reminder)
            }
            await MainActor.run {
                self.remindersAccessGranted = granted
                if granted {
                    self.fetchReminderLists()
                }
            }
        } catch {
            await MainActor.run {
                self.remindersAccessGranted = false
            }
        }
    }

    func requestAllAccess() async {
        await requestCalendarAccess()
        await requestRemindersAccess()
    }

    // MARK: - Calendar Operations

    func fetchCalendars() {
        calendars = eventStore.calendars(for: .event)
    }

    func fetchEvents(from startDate: Date, to endDate: Date) {
        currentEventStartDate = startDate
        currentEventEndDate = endDate

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let fetchedEvents = eventStore.events(matching: predicate)
        events = fetchedEvents.sorted { $0.startDate < $1.startDate }
    }

    func saveEvent(_ event: EKEvent) throws {
        try eventStore.save(event, span: .thisEvent)
    }

    func resizeEvent(_ event: EKEvent, newEnd: Date) throws {
        event.endDate = newEnd
        try eventStore.save(event, span: .thisEvent)
    }

    func deleteEvent(_ event: EKEvent) throws {
        try eventStore.remove(event, span: .thisEvent)
    }

    func createNewEvent() -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.calendar = eventStore.defaultCalendarForNewEvents
        return event
    }

    // MARK: - Calendar Visibility

    func toggleCalendarVisibility(_ calendarID: String) {
        if hiddenCalendarIDs.contains(calendarID) {
            hiddenCalendarIDs.remove(calendarID)
        } else {
            hiddenCalendarIDs.insert(calendarID)
        }
        UserDefaults.standard.set(Array(hiddenCalendarIDs), forKey: "hiddenCalendarIDs")
    }

    func isCalendarVisible(_ calendarID: String) -> Bool {
        !hiddenCalendarIDs.contains(calendarID)
    }

    var visibleEvents: [EKEvent] {
        events.filter { isCalendarVisible($0.calendar.calendarIdentifier) }
    }

    // MARK: - Reminder Operations

    func fetchReminderLists() {
        reminderLists = eventStore.calendars(for: .reminder)
    }

    func fetchReminders(for list: EKCalendar?, includeCompleted: Bool = true) {
        currentReminderListID = list?.calendarIdentifier
        fetchAllReminders = (list == nil)

        let calendars = list != nil ? [list!] : nil
        let predicate = eventStore.predicateForReminders(in: calendars)

        eventStore.fetchReminders(matching: predicate) { [weak self] fetchedReminders in
            DispatchQueue.main.async {
                self?.reminders = fetchedReminders ?? []
            }
        }
    }

    func saveReminder(_ reminder: EKReminder) throws {
        try eventStore.save(reminder, commit: true)
    }

    func deleteReminder(_ reminder: EKReminder) throws {
        try eventStore.remove(reminder, commit: true)
    }

    func toggleReminderCompletion(_ reminder: EKReminder) throws {
        reminder.isCompleted = !reminder.isCompleted
        if reminder.isCompleted {
            reminder.completionDate = Date()
        } else {
            reminder.completionDate = nil
        }
        try eventStore.save(reminder, commit: true)
    }

    func createNewReminder(in list: EKCalendar? = nil) -> EKReminder {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = list ?? eventStore.defaultCalendarForNewReminders()
        return reminder
    }

    // MARK: - Refresh

    private func refreshAll() {
        if calendarAccessGranted {
            fetchCalendars()
            if let start = currentEventStartDate, let end = currentEventEndDate {
                fetchEvents(from: start, to: end)
            }
        }
        if remindersAccessGranted {
            fetchReminderLists()
            if fetchAllReminders {
                fetchReminders(for: nil)
            } else if let listID = currentReminderListID,
                      let list = reminderLists.first(where: { $0.calendarIdentifier == listID }) {
                fetchReminders(for: list)
            }
        }
    }
}
