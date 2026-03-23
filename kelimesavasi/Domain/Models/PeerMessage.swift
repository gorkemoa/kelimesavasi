import Foundation

// MARK: - Message type tag
enum PeerMessageType: String, Codable, Sendable {
    case gameStarted
    case guessMade
    case opponentProgress
    case gameCompleted
    case rematchRequest
    case rematchAccepted
    case rematchDeclined
    case playerReady
}

// MARK: - Envelope
struct PeerMessage: Codable, Sendable {
    let type: PeerMessageType
    let payload: Data

    static func make<T: Encodable>(_ value: T, type: PeerMessageType) throws -> PeerMessage {
        let data = try JSONEncoder().encode(value)
        return PeerMessage(type: type, payload: data)
    }

    func decode<T: Decodable>(_ t: T.Type) throws -> T {
        try JSONDecoder().decode(t, from: payload)
    }
}

// MARK: - Typed payloads
struct GameStartedPayload: Codable, Sendable {
    let config: GameConfig
    let targetWord: String
    let hostID: String
    let hostName: String
}

struct GuessMadePayload: Codable, Sendable {
    let word: String
    let evaluation: [TileState]
    let guessIndex: Int
}

struct ProgressPayload: Codable, Sendable {
    let guessCount: Int
}

struct GameCompletedPayload: Codable, Sendable {
    let performance: PlayerPerformance
}
