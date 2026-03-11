import SwiftUI

enum TempoTab: String {
    case calendar = "Calendar"
    case reminders = "Reminders"
}

struct ContentView: View {
    @EnvironmentObject var eventKitManager: EventKitManager
    @StateObject private var appearanceManager = AppearanceManager.shared
    @State private var selectedTab: TempoTab = .calendar

    var body: some View {
        VStack(spacing: 0) {
            // Global top bar with appearance toggle
            HStack {
                Spacer()

                Button(action: { appearanceManager.cycle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: appearanceManager.mode.iconName)
                            .font(.subheadline)
                        Text(appearanceManager.mode.rawValue)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Toggle appearance: \(appearanceManager.mode.rawValue)")
                .padding(.trailing, 12)
                .padding(.vertical, 4)
            }

            TabView(selection: $selectedTab) {
                CalendarTabView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(TempoTab.calendar)

                RemindersTabView()
                    .tabItem {
                        Label("Reminders", systemImage: "checklist")
                    }
                    .tag(TempoTab.reminders)
            }
        }
        .task {
            await eventKitManager.requestAllAccess()
        }
    }
}
