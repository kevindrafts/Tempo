import SwiftUI
import EventKit

struct CalendarSidebarView: View {
    @EnvironmentObject var eventKitManager: EventKitManager
    @ObservedObject var viewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: 0) {
            miniMonthPicker
            Divider()
            calendarList
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Mini Month Picker

    private var miniMonthPicker: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    viewModel.currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: viewModel.currentMonth) ?? viewModel.currentMonth
                }) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(miniMonthTitle)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button(action: {
                    viewModel.currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: viewModel.currentMonth) ?? viewModel.currentMonth
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            miniCalendarGrid
        }
        .padding(12)
    }

    private var miniMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.currentMonth)
    }

    private var miniCalendarGrid: some View {
        let days = viewModel.daysInMonthGrid
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

        return VStack(spacing: 4) {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(String(symbol.prefix(2)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(days.prefix(42).enumerated()), id: \.offset) { _, date in
                    miniDayCell(date)
                }
            }
        }
    }

    private func miniDayCell(_ date: Date) -> some View {
        let isCurrentMonth = viewModel.isCurrentMonth(date)
        let isToday = viewModel.isToday(date)
        let isSelected = viewModel.isSelected(date)

        return Text("\(Calendar.current.component(.day, from: date))")
            .font(.caption2)
            .frame(width: 22, height: 22)
            .foregroundColor(isCurrentMonth ? (isToday ? .white : .primary) : .secondary.opacity(0.5))
            .background {
                if isToday {
                    Circle().fill(Color.accentColor)
                } else if isSelected {
                    Circle().stroke(Color.accentColor, lineWidth: 1)
                }
            }
            .onTapGesture {
                viewModel.selectedDate = date
            }
    }

    // MARK: - Calendar List

    private var calendarList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(calendarsBySource, id: \.key) { source, calendars in
                    Section {
                        ForEach(calendars, id: \.calendarIdentifier) { calendar in
                            calendarRow(calendar)
                        }
                    } header: {
                        Text(source)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private var calendarsBySource: [(key: String, value: [EKCalendar])] {
        let grouped = Dictionary(grouping: eventKitManager.calendars) { $0.source?.title ?? "Other" }
        return grouped.sorted { $0.key < $1.key }
    }

    private func calendarRow(_ calendar: EKCalendar) -> some View {
        let isVisible = eventKitManager.isCalendarVisible(calendar.calendarIdentifier)

        return HStack(spacing: 8) {
            Image(systemName: isVisible ? "checkmark.circle.fill" : "circle")
                .foregroundColor(Color(cgColor: calendar.cgColor))
                .font(.body)

            Text(calendar.title)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            eventKitManager.toggleCalendarVisibility(calendar.calendarIdentifier)
        }
    }
}
