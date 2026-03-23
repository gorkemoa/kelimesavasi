import Foundation

struct Player: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var isHost: Bool

    init(id: String = UUID().uuidString, name: String, isHost: Bool = false) {
        self.id = id
        self.name = name
        self.isHost = isHost
    }

    static let preview = Player(id: "preview-1", name: "Oyuncu", isHost: false)
}
