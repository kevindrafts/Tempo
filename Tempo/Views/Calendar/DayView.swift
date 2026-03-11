import SwiftUI
import EventKit

struct DayView: View {
    @EnvironmentObject var eventKitManager: EventKitManager
    @ObservedObject var viewModel: CalendarViewModel
    let events: [EKEvent]
    let onEventTapped: (EKEvent) -> Void

    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 70

    var body: some View {
        VStack(spacing: 0) {
            dayHeader
            Divider()
            allDaySection
            Divider()
            timeGrid
        }
    }

    // MARK: - Day Header

    private var dayHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayOfWeekString)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                Text(dateString)
                    .font(.title2.weight(.semibold))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - All Day Section

    @ViewBuilder
    private var allDaySection: some View {
        let allDay = viewModel.allDayEvents(for: viewModel.selectedDate, from: events)
        if !allDay.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("ALL DAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)

                ForEach(allDay, id: \.eventIdentifier) { event in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 8, height: 8)

                        Text(event.title ?? "Untitled")
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(cgColor: event.calendar.cgColor).opacity(0.1))
                    .cornerRadius(4)
                    .onTapGesture { onEventTapped(event) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Time Grid

    private var timeGrid: some View {
        ScrollView {
            ScrollViewReader { proxy in
                ZStack(alignment: .topLeading) {
                    // Grid lines (hour + half-hour)
                    gridLines

                    // Events overlay
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: timeColumnWidth + 12)

                        ZStack(alignment: .topLeading) {
                            if viewModel.isToday(viewModel.selectedDate) {
                                currentTimeIndicator
                            }

                            ForEach(viewModel.timedEvents(for: viewModel.selectedDate, from: events), id: \.eventIdentifier) { event in
                                DayEventBlock(
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
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: timeColumnWidth, alignment: .trailing)
                            .padding(.trailing, 12)
                            .offset(y: -7)

                        Rectangle()
                            .fill(Color(nsColor: .separatorColor).opacity(0.4))
                            .frame(height: 0.5)
                    }

                    Spacer()

                    // Half-hour line
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: timeColumnWidth + 12)

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

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        let offset = CGFloat(hour - viewModel.dayHours.first!) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        return HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
        .offset(y: offset - 5)
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

    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.selectedDate)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }

    private func hourString(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Day Event Block (with resize handle)

struct DayEventBlock: View {
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
    private var baseHeight: CGFloat { max(CGFloat(duration) * hourHeight, 24) }
    private var currentHeight: CGFloat { max(baseHeight + dragHeight, 15) }

    var body: some View {
        VStack(spacing: 0) {
            // Event content
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title ?? "Untitled")
                        .font(.subheadline.weight(.medium))

                    Text(timeRangeString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let location = event.location, !location.isEmpty, currentHeight > 50 {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(8)

            Spacer(minLength: 0)

            // Resize handle
            HStack(spacing: 2) {
                Spacer()
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(nsColor: .separatorColor).opacity(isDragging ? 0.8 : 0.3))
                    .frame(width: 30, height: 3)
                Spacer()
            }
            .frame(height: 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        isDragging = true
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
        .frame(height: currentHeight, alignment: .top)
        .background(Color(cgColor: event.calendar.cgColor).opacity(isDragging ? 0.15 : 0.1))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(cgColor: event.calendar.cgColor).opacity(0.2), lineWidth: isDragging ? 1.5 : 0)
        )
        .padding(.trailing, 16)
        .offset(y: topOffset)
        .onTapGesture(perform: onTap)
    }

    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }
}
