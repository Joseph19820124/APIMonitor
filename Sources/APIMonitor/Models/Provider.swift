import SwiftUI

enum Provider: String, CaseIterable, Identifiable {
    case codex     = "Codex"
    case minimax   = "MiniMax"
    case zai       = "z.ai"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .codex:     return "terminal.fill"
        case .minimax:   return "m.circle.fill"
        case .zai:       return "z.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .codex:     return Color(red: 0.37, green: 0.65, blue: 0.98)
        case .minimax:   return Color(red: 0.28, green: 0.68, blue: 0.97)
        case .zai:       return Color(red: 0.42, green: 0.84, blue: 0.65)
        }
    }

    var requiresAPIKey: Bool {
        self != .codex
    }

    var keychainKey: String { "APIMonitor_\(rawValue)_key" }
}
