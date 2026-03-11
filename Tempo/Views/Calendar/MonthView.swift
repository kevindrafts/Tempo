import SwiftUI
import EventKit

struct MonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let events: [EKEvent]
    let onEventTapped: (EKEvent) -> Void

    @State private var overflowPopoverDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Calendar grid
            GeometryReader { geometry in
                let rowHeight = geometry.size.height / 6

                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(Array(viewModel.daysInMonthGrid.prefix(42).enumerated()), id: \.offset) { _, date in
                        dayCellView(date, height: rowHeight)
                    }
                }
                .background(Color(nsColor: .separatorColor).opacity(0.3))
            }

            Divider()

            // Selected day detail panel
            EventDetailPanel(
                date: viewModel.selectedDate,
                events: viewModel.events(for: viewModel.selectedDate, from: events),
                onEventTapped: onEventTapped
            )
            .frame(height: 150)
        }
    }

    @ViewBuilder
    private func dayCellView(_ date: Date, height: CGFloat) -> some View {
        let dayEvents = viewModel.events(for: date, from: events)
        let isCurrentMonth = viewModel.isCurrentMonth(date)
        let isToday = viewModel.isToday(date)
        let isSelected = viewModel.isSelected(date)

        VStack(alignment: .leading, spacing: 2) {
            // Day number
            HStack {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundColor(isCurrentMonth ? (isToday ? .white : .primary) : .secondary.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .background {
                        if isToday {
                            Circle().fill(Color.accentColor)
                        }
                    }
                Spacer()
            }
            .padding(.top, 4)
            .padding(.leading, 4)

            // Events (up to 3)
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(dayEvents.prefix(3).enumerated()), id: \.offset) { _, event in
                    eventPill(event)
                        .onTapGesture {
                            onEventTapped(event)
                        }
                }

                if dayEvents.count > 3 {
                    Text("+\(dayEvents.count - 3) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                        .onTapGesture {
                            viewModel.selectedDate = date
                        }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: height)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedDate = date
        }
    }

    private func eventPill(_ event: EKEvent) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 6, height: 6)

            Text(event.title ?? "Untitled")
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }
}
