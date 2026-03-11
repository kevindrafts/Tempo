import SwiftUI
import EventKit

@main
struct TempoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var eventKitManager = EventKitManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventKitManager)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            TempoCommands()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure window appearance
        if let window = NSApplication.shared.windows.first {
            window.setContentSize(NSSize(width: 1100, height: 700))
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
