import Foundation

struct GameSession: Codable, Sendable {
    let id: String
    var mode: GameMode
    var config: GameConfig
    var targetWord: String
    var guesses: [Guess]
    var phase: GamePhase
    var startTime: Date
    var endTime: Date?
    var opponentGuessCount: Int
    var revealedHints: [Int: String] // colIndex -> Letter

    init(id: String = UUID().uuidString,
         mode: GameMode,
         config: GameConfig = .default,
         targetWord: String) {
        self.id = id
        self.mode = mode
        self.config = config
        self.targetWord = targetWord
        self.guesses = []
        self.phase = .playing
        self.startTime = Date()
        self.opponentGuessCount = 0
        self.revealedHints = [:]
    }

    var currentGuessIndex: Int { guesses.count }
    var remainingGuesses: Int { config.maxGuesses - guesses.count }
    var isFinished: Bool { phase == .won || phase == .lost || phase == .finished }

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }
}
