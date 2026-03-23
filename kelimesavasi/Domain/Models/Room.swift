import Foundation

struct Room: Codable, Sendable {
    let id: String
    var host: Player
    var guest: Player?
    var config: GameConfig
    var phase: GamePhase

    init(id: String = UUID().uuidString, host: Player, config: GameConfig = .default) {
        self.id = id
        self.host = host
        self.guest = nil
        self.config = config
        self.phase = .waiting
    }

    var isFull: Bool { guest != nil }
}
