import SwiftUI

enum Provider: String, CaseIterable, Identifiable {
    case anthropic = "Claude"
    case minimax   = "MiniMax"
    case zai       = "z.ai"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .anthropic: return "a.circle.fill"
        case .minimax:   return "m.circle.fill"
        case .zai:       return "z.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .anthropic: return Color(red: 0.84, green: 0.58, blue: 0.42)
        case .minimax:   return Color(red: 0.28, green: 0.68, blue: 0.97)
        case .zai:       return Color(red: 0.42, green: 0.84, blue: 0.65)
        }
    }

    var keychainKey: String { "APIMonitor_\(rawValue)_key" }
}
