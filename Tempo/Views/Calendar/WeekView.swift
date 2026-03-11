import SwiftUI
import EventKit

struct WeekView: View {
    @EnvironmentObject var eventKitManager: EventKitManager
    @ObservedObject var viewModel: CalendarViewModel
    let events: [EKEvent]
    let onEventTapped: (EKEvent) -> Void

    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            weekdayHeader
            Divider()
            allDaySection
            Divider()
            timeGrid
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: timeColumnWidth)

            ForEach(viewModel.weekDays, id: \.self) { date in
                VStack(spacing: 2) {
                    Text(dayOfWeekString(date))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.title3.weight(viewModel.isToday(date) ? .bold : .regular))
                        .foregroundColor(viewModel.isToday(date) ? .white : .primary)
                        .frame(width: 30, height: 30)
                        .background {
                            if viewModel.isToday(date) {
                                Circle().fill(Color.accentColor)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(viewModel.isSelected(date) ? Color.accentColor.opacity(0.05) : .clear)
                .onTapGesture {
                    viewModel.selectedDate = date
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - All Day Section

    @ViewBuilder
    private var allDaySection: some View {
        let hasAllDayEvents = viewModel.weekDays.contains { date in
            !viewModel.allDayEvents(for: date, from: events).isEmpty
        }

        if hasAllDayEvents {
            HStack(spacing: 0) {
                Text("all-day")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: timeColumnWidth)

                ForEach(viewModel.weekDays, id: \.self) { date in
                    VStack(spacing: 2) {
                        ForEach(viewModel.allDayEvents(for: date, from: events), id: \.eventIdentifier) { event in
                            Text(event.title ?? "Untitled")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(cgColor: event.calendar.cgColor).opacity(0.3))
                                .cornerRadius(3)
                                .onTapGesture { onEventTapped(event) }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 1)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Time Grid

    private var timeGrid: some View {
        ScrollView {
            ScrollViewReader { proxy in
                ZStack(alignment: .topLeading) {
                    // Grid lines (hour + half-hour)
                    gridLines

                    // Day column separators
                    dayColumnSeparators

                    // Events overlay
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: timeColumnWidth)

                        ForEach(viewModel.weekDays, id: \.self) { date in
                            ZStack(alignment: .topLeading) {
                                if viewModel.isToday(date) {
                                    currentTimeIndicator
                                }

                                ForEach(viewModel.timedEvents(for: date, from: events), id: \.eventIdentifier) { event in
                                    WeekEventBlock(
                                        event: event,
                                        hourHeight: hourHeight,
                                        firstHour: viewModel.dayHours.first!,
                                        onTap: { onEventTapped(event) },
                                        onResize: { newEnd in resizeEvent(event, to: newEnd) }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .onAppear {
                    let currentHour = Calendar.current.component(.hour, from: Date())
                    let targetHour = max(currentHour - 1, 6)
                    proxy.scrollTo(targetHour, anchor: .top)
                }
            }
        }
    }

    // MARK: - Grid Lines

    private var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.dayHours, id: \.self) { hour in
                VStack(spacing: 0) {
                    // Hour line
                    HStack(spacing: 0) {
                        Text(hourString(hour))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: timeColumnWidth, alignment: .trailing)
                            .padding(.trailing, 8)
                            .offset(y: -7)

                        Rectangle()
                            .fill(Color(nsColor: .separatorColor).opacity(0.4))
                            .frame(height: 0.5)
                    }

                    Spacer()

                    // Half-hour line
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: timeColumnWidth)

                        Rectangle()
                            .fill(Color(nsColor: .separatorColor).opacity(0.15))
                            .frame(height: 0.5)
                    }

                    Spacer()
                }
                .frame(height: hourHeight)
                .id(hour)
            }
        }
    }

    // MARK: - Day Column Separators

    private var dayColumnSeparators: some View {
        GeometryReader { geo in
            let totalGridHeight = CGFloat(viewModel.dayHours.count) * hourHeight
            let contentWidth = geo.size.width - timeColumnWidth
            let columnWidth = contentWidth / 7

            ForEach(0..<7, id: \.self) { index in
                Rectangle()
                    .fill(Color(nsColor: .separatorColor).opacity(0.15))
                    .frame(width: 0.5, height: totalGridHeight)
                    .offset(x: timeColumnWidth + columnWidth * CGFloat(index))
            }
        }
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        let offset = CGFloat(hour - viewModel.dayHours.first!) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        return HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(Color.red)
                .frame(height: 1.5)
        }
        .offset(y: offset - 4)
    }

    // MARK: - Resize

    private func resizeEvent(_ event: EKEvent, to newEnd: Date) {
        do {
            try eventKitManager.resizeEvent(event, newEnd: newEnd)
        } catch {
            // Silently fail; EventKit notification will refresh
        }
    }

    // MARK: - Helpers

    private func dayOfWeekString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func hourString(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Week Event Block (with resize handle)

struct WeekEventBlock: View {
    let event: EKEvent
    let hourHeight: CGFloat
    let firstHour: Int
    let onTap: () -> Void
    let onResize: (Date) -> Void

    @State private var dragHeight: CGFloat = 0
    @State private var isDragging = false

    private var startHour: Int { Calendar.current.component(.hour, from: event.startDate) }
    private var startMinute: Int { Calendar.current.component(.minute, from: event.startDate) }
    private var duration: Double { event.endDate.timeIntervalSince(event.startDate) / 3600 }
    private var topOffset: CGFloat {
        CGFloat(startHour - firstHour) * hourHeight + CGFloat(startMinute) / 60.0 * hourHeight
    }
    private var baseHeight: CGFloat { max(CGFloat(duration) * hourHeight, 20) }
    private var currentHeight: CGFloat { max(baseHeight + dragHeight, 15) }

    var body: some View {
        VStack(spacing: 0) {
            // Event content
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Untitled")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)

                if currentHeight > 30 {
                    Text(timeRangeString)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 3)

            Spacer(minLength: 0)

            // Resize handle
            Rectangle()
                .fill(Color.white.opacity(isDragging ? 0.5 : 0.001))
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            isDragging = true
                            // Snap to 15-minute increments
                            let rawDelta = value.translation.height
                            let fifteenMin = hourHeight / 4
                            dragHeight = (rawDelta / fifteenMin).rounded() * fifteenMin
                        }
                        .onEnded { _ in
                            isDragging = false
                            let newDurationHours = Double(currentHeight) / Double(hourHeight)
                            let newEnd = event.startDate.addingTimeInterval(newDurationHours * 3600)
                            dragHeight = 0
                            if newEnd > event.startDate.addingTimeInterval(900) {
                                onResize(newEnd)
                            }
                        }
                )
                .onHover { hovering in
                    if hovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: currentHeight)
        .background(Color(cgColor: event.calendar.cgColor).opacity(isDragging ? 0.95 : 0.85))
        .foregroundColor(.white)
        .cornerRadius(4)
        .padding(.horizontal, 2)
        .offset(y: topOffset)
        .onTapGesture(perform: onTap)
    }

    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }
}
