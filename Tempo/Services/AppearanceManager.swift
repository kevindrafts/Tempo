import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    @Published var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appearanceMode") ?? "System"
        self.mode = AppearanceMode(rawValue: saved) ?? .system
        applyAppearance()
    }

    func cycle() {
        let all = AppearanceMode.allCases
        let currentIndex = all.firstIndex(of: mode) ?? 0
        mode = all[(currentIndex + 1) % all.count]
    }

    private func applyAppearance() {
        DispatchQueue.main.async {
            switch self.mode {
            case .system:
                NSApp.appearance = nil
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}
