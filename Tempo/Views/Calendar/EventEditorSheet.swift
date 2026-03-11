import SwiftUI
import EventKit

struct EventEditorSheet: View {
    @EnvironmentObject var eventKitManager: EventKitManager

    let event: EKEvent?
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var selectedCalendarID: String = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var url = ""
    @State private var recurrenceRule: RecurrenceOption = .none
    @State private var alertOption: AlertOption = .none
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false

    private var isEditing: Bool { event != nil }

    enum RecurrenceOption: String, CaseIterable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }

    enum AlertOption: String, CaseIterable {
        case none = "None"
        case atTime = "At time of event"
        case fiveMin = "5 minutes before"
        case fifteenMin = "15 minutes before"
        case thirtyMin = "30 minutes before"
        case oneHour = "1 hour before"
        case oneDay = "1 day before"

        var offset: TimeInterval? {
            switch self {
            case .none: return nil
            case .atTime: return 0
            case .fiveMin: return -300
            case .fifteenMin: return -900
            case .thirtyMin: return -1800
            case .oneHour: return -3600
            case .oneDay: return -86400
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(isEditing ? "Edit Event" : "New Event")
                    .font(.headline)
                Spacer()
                Button("Save") { saveEvent() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()

            Divider()

            // Form
            Form {
                TextField("Title", text: $title)
                    .font(.title3)

                Toggle("All Day", isOn: $isAllDay)

                if isAllDay {
                    DatePicker("Date", selection: $startDate, displayedComponents: .date)
                } else {
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }

                Picker("Calendar", selection: $selectedCalendarID) {
                    ForEach(eventKitManager.calendars, id: \.calendarIdentifier) { cal in
                        HStack {
                            Circle()
                                .fill(Color(cgColor: cal.cgColor))
                                .frame(width: 8, height: 8)
                            Text(cal.title)
                        }
                        .tag(cal.calendarIdentifier)
                    }
                }

                TextField("Location", text: $location)

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                TextField("URL", text: $url)

                Picker("Repeat", selection: $recurrenceRule) {
                    ForEach(RecurrenceOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                Picker("Alert", selection: $alertOption) {
                    ForEach(AlertOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if isEditing {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Event")
                            .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 550)
        .onAppear(perform: loadEvent)
        .alert("Delete Event", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteEvent() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }

    // MARK: - Load

    private func loadEvent() {
        if let event = event {
            title = event.title ?? ""
            startDate = event.startDate
            endDate = event.endDate
            isAllDay = event.isAllDay
            selectedCalendarID = event.calendar.calendarIdentifier
            location = event.location ?? ""
            notes = event.notes ?? ""
            url = event.url?.absoluteString ?? ""

            if let rule = event.recurrenceRules?.first {
                switch rule.frequency {
                case .daily: recurrenceRule = .daily
                case .weekly: recurrenceRule = .weekly
                case .monthly: recurrenceRule = .monthly
                case .yearly: recurrenceRule = .yearly
                @unknown default: recurrenceRule = .none
                }
            }

            if let alarm = event.alarms?.first {
                let offset = alarm.relativeOffset
                switch offset {
                case 0: alertOption = .atTime
                case -300: alertOption = .fiveMin
                case -900: alertOption = .fifteenMin
                case -1800: alertOption = .thirtyMin
                case -3600: alertOption = .oneHour
                case -86400: alertOption = .oneDay
                default: alertOption = .none
                }
            }
        } else {
            selectedCalendarID = eventKitManager.eventStore.defaultCalendarForNewEvents?.calendarIdentifier ?? ""
        }
    }

    // MARK: - Save

    private func saveEvent() {
        let ekEvent = event ?? eventKitManager.createNewEvent()
        ekEvent.title = title.trimmingCharacters(in: .whitespaces)
        ekEvent.startDate = startDate
        ekEvent.endDate = isAllDay ? startDate : endDate
        ekEvent.isAllDay = isAllDay
        ekEvent.location = location.isEmpty ? nil : location
        ekEvent.notes = notes.isEmpty ? nil : notes

        if let urlObj = URL(string: url), !url.isEmpty {
            ekEvent.url = urlObj
        }

        if let cal = eventKitManager.calendars.first(where: { $0.calendarIdentifier == selectedCalendarID }) {
            ekEvent.calendar = cal
        }

        // Recurrence
        ekEvent.recurrenceRules?.forEach { ekEvent.removeRecurrenceRule($0) }
        if recurrenceRule != .none {
            let freq: EKRecurrenceFrequency
            switch recurrenceRule {
            case .daily: freq = .daily
            case .weekly: freq = .weekly
            case .monthly: freq = .monthly
            case .yearly: freq = .yearly
            case .none: freq = .daily
            }
            let rule = EKRecurrenceRule(recurrenceWith: freq, interval: 1, end: nil)
            ekEvent.addRecurrenceRule(rule)
        }

        // Alert
        ekEvent.alarms?.forEach { ekEvent.removeAlarm($0) }
        if let offset = alertOption.offset {
            ekEvent.addAlarm(EKAlarm(relativeOffset: offset))
        }

        do {
            try eventKitManager.saveEvent(ekEvent)
            onSave()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete

    private func deleteEvent() {
        guard let event = event else { return }
        do {
            try eventKitManager.deleteEvent(event)
            onDelete()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
}
