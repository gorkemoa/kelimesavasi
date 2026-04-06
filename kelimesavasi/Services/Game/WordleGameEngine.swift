import Foundation

final class WordleGameEngine {
    private let evaluator: GuessEvaluator
    let wordRepository: WordRepositoryProtocol

    init(evaluator: GuessEvaluator = GuessEvaluator(),
         wordRepository: WordRepositoryProtocol) {
        self.evaluator = evaluator
        self.wordRepository = wordRepository
    }

    // MARK: - Session creation

    func newSoloSession(config: GameConfig = .default) async throws -> GameSession {
        let word = try await wordRepository.randomTargetWord(length: config.wordLength)
        return GameSession(mode: .solo, config: config, targetWord: word)
    }

    func newDuelSession(targetWord: String, config: GameConfig = .default) -> GameSession {
        GameSession(mode: .duel, config: config, targetWord: targetWord)
    }

    // MARK: - Guess evaluation

    func evaluateGuess(_ word: String, in session: GameSession) -> Guess {
        let states = evaluator.evaluate(guess: word, target: session.targetWord)
        return Guess(word: word, evaluation: states, isEvaluated: true)
    }

    func isValidWord(_ word: String, config: GameConfig = .default) async -> Bool {
        await wordRepository.isValid(word: word, length: config.wordLength)
    }

    // MARK: - Result computation

    func computeResult(
        session: GameSession,
        localPlayer: Player,
        opponentPerformance: PlayerPerformance?
    ) -> GameResult {
        let lastGuess = session.guesses.last
        let solved = lastGuess?.isCorrect ?? false

        let myPerf = PlayerPerformance(
            playerID: localPlayer.id,
            playerName: localPlayer.name,
            guessCount: session.guesses.count,
            solved: solved,
            duration: session.duration
        )

        var winnerID: String?
        var isDraw = false

        if let opp = opponentPerformance {
            switch (solved, opp.solved) {
            case (true, false):  winnerID = localPlayer.id
            case (false, true):  winnerID = opp.playerID
            case (true, true), (false, false):
                // Both solved OR both failed - comparison rules:
                // 1. Fewer guesses wins
                // 2. Faster duration wins
                if myPerf.guessCount < opp.guessCount {
                    winnerID = localPlayer.id
                } else if myPerf.guessCount > opp.guessCount {
                    winnerID = opp.playerID
                } else if myPerf.duration < opp.duration {
                    winnerID = localPlayer.id
                } else if myPerf.duration > opp.duration {
                    winnerID = opp.playerID
                } else {
                    isDraw = true
                }
            }
        } else {
            // Solo mode
            winnerID = solved ? localPlayer.id : nil
        }

        return GameResult(
            sessionID: session.id,
            mode: session.mode,
            winnerID: winnerID,
            isDraw: isDraw,
            myPerformance: myPerf,
            opponentPerformance: opponentPerformance,
            targetWord: session.targetWord
        )
    }

    // MARK: - Key state aggregation

    /// Builds a dictionary of letter → best TileState across all submitted guesses.
    func aggregateKeyStates(from guesses: [Guess]) -> [String: TileState] {
        var keyStates: [String: TileState] = [:]
        for guess in guesses where guess.isEvaluated {
            for (char, state) in zip(guess.word.lowercased(), guess.evaluation) {
                let key = String(char)
                keyStates[key] = betterState(keyStates[key], state)
            }
        }
        return keyStates
    }

    private func betterState(_ existing: TileState?, _ new: TileState) -> TileState {
        switch (existing, new) {
        case (.none, _):     return new
        case (.some(.correct), _): return .correct
        case (_, .correct): return .correct
        case (.some(.present), _): return .present
        case (_, .present): return .present
        default: return new
        }
    }
}
