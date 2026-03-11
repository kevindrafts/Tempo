import SwiftUI
import EventKit

struct EventDetailPanel: View {
    let date: Date
    let events: [EKEvent]
    let onEventTapped: (EKEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(formattedDate)
                    .font(.headline)
                Spacer()
                Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            if events.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(events, id: \.eventIdentifier) { event in
                            eventRow(event)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func eventRow(_ event: EKEvent) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Untitled")
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if event.isAllDay {
                        Text("All day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(timeString(event))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(event.calendar.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onEventTapped(event)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func timeString(_ event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }
}
