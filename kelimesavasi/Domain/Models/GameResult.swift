import Foundation

struct PlayerPerformance: Codable, Sendable {
    let playerID: String
    let playerName: String
    let guessCount: Int
    let solved: Bool
    let duration: TimeInterval
}

struct GameResult: Codable, Sendable {
    let sessionID: String
    var mode: GameMode
    var winnerID: String?
    var isDraw: Bool
    var myPerformance: PlayerPerformance
    var opponentPerformance: PlayerPerformance?
    var targetWord: String

    var iWon: Bool {
        guard let winnerID else { return false }
        return winnerID == myPerformance.playerID
    }

    var iLost: Bool {
        guard !isDraw else { return false }
        return winnerID != myPerformance.playerID
    }
}
