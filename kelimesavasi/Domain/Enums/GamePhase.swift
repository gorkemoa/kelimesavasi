import Foundation

enum GamePhase: String, Codable, Equatable, Sendable {
    case waiting   // waiting for opponent / pre-game
    case playing   // actively guessing
    case won       // player solved the word
    case lost      // ran out of guesses
    case finished  // duel finished (both players done)
}
