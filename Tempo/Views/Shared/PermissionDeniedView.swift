import SwiftUI

struct PermissionDeniedView: View {
    let type: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: type == "Calendar" ? "calendar.badge.exclamationmark" : "checklist.unchecked")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("\(type) Access Required")
                .font(.title2.weight(.semibold))

            Text("Tempo needs access to your \(type.lowercased()) to display and manage your data. Please grant access in System Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("Open System Settings") {
                openPrivacySettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func openPrivacySettings() {
        let urlString: String
        if type == "Calendar" {
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        } else {
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
