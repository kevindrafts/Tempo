import SwiftUI
import EventKit

struct RemindersSidebarView: View {
    @EnvironmentObject var eventKitManager: EventKitManager
    @ObservedObject var viewModel: RemindersViewModel
    let onListSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // All reminders list
            allRemindersRow

            Divider()
                .padding(.vertical, 4)

            // Individual lists
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(eventKitManager.reminderLists, id: \.calendarIdentifier) { list in
                        listRow(list)
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var allRemindersRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.full")
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text("All")
                .font(.subheadline.weight(.medium))

            Spacer()

            Text("\(viewModel.allIncompleteCount(from: eventKitManager.reminders))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(viewModel.isShowingAllList ? Color.accentColor.opacity(0.1) : .clear)
        .cornerRadius(6)
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectAllList()
            onListSelected()
        }
    }

    private func listRow(_ list: EKCalendar) -> some View {
        let isSelected = !viewModel.isShowingAllList && viewModel.selectedList?.calendarIdentifier == list.calendarIdentifier

        return HStack(spacing: 8) {
            Circle()
                .fill(Color(cgColor: list.cgColor))
                .frame(width: 10, height: 10)

            Text(list.title)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            let count = viewModel.reminderCount(for: list, from: eventKitManager.reminders)
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.1) : .clear)
        .cornerRadius(6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectList(list)
            onListSelected()
        }
    }
}
