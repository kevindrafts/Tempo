import Foundation
import EventKit
import SwiftUI

enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case week = "Week"
    case day = "Day"
}

final class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var viewMode: CalendarViewMode = .month
    @Published var selectedEvent: EKEvent?

    private let calendar = Calendar.current

    // MARK: - Navigation

    func goToToday() {
        selectedDate = Date()
        currentMonth = Date()
    }

    func goToPrevious() {
        switch viewMode {
        case .month:
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
            currentMonth = selectedDate
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            currentMonth = selectedDate
        }
    }

    func goToNext() {
        switch viewMode {
        case .month:
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
            currentMonth = selectedDate
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            currentMonth = selectedDate
        }
    }

    // MARK: - Date Range for Fetching

    var fetchStartDate: Date {
        switch viewMode {
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
            return calendar.date(byAdding: .day, value: -7, to: startOfMonth)!
        case .week:
            let weekday = calendar.component(.weekday, from: selectedDate)
            let firstWeekday = calendar.firstWeekday
            let daysToSubtract = (weekday - firstWeekday + 7) % 7
            return calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: selectedDate))!
        case .day:
            return calendar.startOfDay(for: selectedDate)
        }
    }

    var fetchEndDate: Date {
        switch viewMode {
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            return calendar.date(byAdding: .day, value: 8, to: endOfMonth)!
        case .week:
            return calendar.date(byAdding: .day, value: 7, to: fetchStartDate)!
        case .day:
            return calendar.date(byAdding: .day, value: 1, to: fetchStartDate)!
        }
    }

    // MARK: - Month Grid Helpers

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    var weekdaySymbols: [String] {
        let cal = calendar
        let symbols = cal.shortWeekdaySymbols
        let firstWeekday = cal.firstWeekday - 1
        return Array(symbols[firstWeekday...]) + Array(symbols[..<firstWeekday])
    }

    var daysInMonthGrid: [Date] {
        let cal = calendar
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = cal.component(.weekday, from: startOfMonth)
        let offset = (firstWeekday - cal.firstWeekday + 7) % 7

        let startDate = cal.date(byAdding: .day, value: -offset, to: startOfMonth)!

        var dates: [Date] = []
        for i in 0..<42 {
            if let date = cal.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }
        return dates
    }

    func isCurrentMonth(_ date: Date) -> Bool {
        calendar.component(.month, from: date) == calendar.component(.month, from: currentMonth) &&
        calendar.component(.year, from: date) == calendar.component(.year, from: currentMonth)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    // MARK: - Week View Helpers

    var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: fetchStartDate) }
    }

    var dayHours: [Int] {
        Array(6...22) // 6 AM to 10 PM
    }

    // MARK: - Event Filtering

    func events(for date: Date, from allEvents: [EKEvent]) -> [EKEvent] {
        allEvents.filter { event in
            if event.isAllDay {
                return calendar.isDate(event.startDate, inSameDayAs: date)
            }
            let eventStart = calendar.startOfDay(for: event.startDate)
            let eventEnd = calendar.startOfDay(for: event.endDate)
            let dayStart = calendar.startOfDay(for: date)
            return dayStart >= eventStart && dayStart <= eventEnd
        }
    }

    func allDayEvents(for date: Date, from allEvents: [EKEvent]) -> [EKEvent] {
        events(for: date, from: allEvents).filter { $0.isAllDay }
    }

    func timedEvents(for date: Date, from allEvents: [EKEvent]) -> [EKEvent] {
        events(for: date, from: allEvents).filter { !$0.isAllDay }
    }

    func eventsForHour(_ hour: Int, on date: Date, from allEvents: [EKEvent]) -> [EKEvent] {
        timedEvents(for: date, from: allEvents).filter { event in
            let eventHour = calendar.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }
}
