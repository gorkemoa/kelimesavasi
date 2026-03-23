import Foundation

enum GameMode: String, Codable, Hashable, Sendable {
    case solo
    case duel

    var displayName: String {
        switch self {
        case .solo: return "Solo Pratik"
        case .duel: return "Yakın Düello"
        }
    }
}
