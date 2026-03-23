    import XCTest
@testable import kelimesavasi

// MARK: - GameResult Computation Tests
final class GameResultTests: XCTestCase {

    private var evaluator: GuessEvaluator!
    private var repo: WordRepository!
    private var engine: WordleGameEngine!

    private let localPlayer  = Player(id: "p1", name: "Local",    isHost: true)
    private let remotePlayer = Player(id: "p2", name: "Opponent", isHost: false)

    override func setUp() {
        super.setUp()
        evaluator = GuessEvaluator()
        repo      = WordRepository()
        engine    = WordleGameEngine(evaluator: evaluator, wordRepository: repo)
    }

    // MARK: - Solo results

    func test_solo_solved_wins() {
        var session = GameSession(mode: .solo, targetWord: "kitap")
        let guess = Guess(word: "kitap",
                          evaluation: [.correct, .correct, .correct, .correct, .correct],
                          isEvaluated: true)
        session.guesses = [guess]
        session.phase = .won
        session.endTime = Date()

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: nil)
        XCTAssertEqual(result.winnerID, "p1")
        XCTAssertFalse(result.isDraw)
        XCTAssertTrue(result.iWon)
    }

    func test_solo_notSolved_noWinner() {
        var session = GameSession(mode: .solo, targetWord: "kitap")
        let wrongGuess = Guess(word: "aaaaa",
                               evaluation: [.absent, .absent, .absent, .absent, .absent],
                               isEvaluated: true)
        session.guesses = Array(repeating: wrongGuess, count: 6)
        session.phase = .lost
        session.endTime = Date()

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: nil)
        XCTAssertNil(result.winnerID)
        XCTAssertFalse(result.isDraw)
        XCTAssertFalse(result.iWon)
    }

    // MARK: - Duel results

    func test_duel_localSolved_opponentNot_localWins() {
        var session = GameSession(mode: .duel, targetWord: "kitap")
        let win = Guess(word: "kitap",
                        evaluation: [.correct, .correct, .correct, .correct, .correct],
                        isEvaluated: true)
        session.guesses = [win]
        session.phase = .won
        session.endTime = Date()

        let oppPerf = PlayerPerformance(playerID: "p2", playerName: "Opp",
                                        guessCount: 6, solved: false, duration: 200)

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: oppPerf)
        XCTAssertEqual(result.winnerID, "p1")
        XCTAssertTrue(result.iWon)
        XCTAssertFalse(result.isDraw)
    }

    func test_duel_localNotSolved_opponentSolved_opponentWins() {
        var session = GameSession(mode: .duel, targetWord: "kitap")
        let wrong = Guess(word: "aaaaa",
                          evaluation: [.absent, .absent, .absent, .absent, .absent],
                          isEvaluated: true)
        session.guesses = Array(repeating: wrong, count: 6)
        session.phase = .lost
        session.endTime = Date()

        let oppPerf = PlayerPerformance(playerID: "p2", playerName: "Opp",
                                        guessCount: 3, solved: true, duration: 60)

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: oppPerf)
        XCTAssertEqual(result.winnerID, "p2")
        XCTAssertFalse(result.iWon)
        XCTAssertTrue(result.iLost)
    }

    func test_duel_bothSolved_fewerGuessesWins() {
        var session = makeSolvedSession(guessCount: 3, duration: 90)

        let oppPerf = PlayerPerformance(playerID: "p2", playerName: "Opp",
                                        guessCount: 5, solved: true, duration: 80)

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: oppPerf)
        XCTAssertEqual(result.winnerID, "p1", "Fewer guesses should win")
    }

    func test_duel_bothSolved_sameGuesses_fasterWins() {
        var session = makeSolvedSession(guessCount: 3, duration: 50)

        let oppPerf = PlayerPerformance(playerID: "p2", playerName: "Opp",
                                        guessCount: 3, solved: true, duration: 80)

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: oppPerf)
        XCTAssertEqual(result.winnerID, "p1", "Faster time should win when guess counts equal")
    }

    func test_duel_bothSolved_identical_isDraw() {
        let start = Date()
        var session = makeSolvedSession(guessCount: 3, duration: 50, startOverride: start)

        let oppPerf = PlayerPerformance(playerID: "p2", playerName: "Opp",
                                        guessCount: 3, solved: true, duration: 50)

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: oppPerf)
        XCTAssertTrue(result.isDraw)
        XCTAssertNil(result.winnerID)
    }

    func test_duel_neitherSolved_isDraw() {
        var session = GameSession(mode: .duel, targetWord: "kitap")
        let wrong = Guess(word: "aaaaa",
                          evaluation: [.absent, .absent, .absent, .absent, .absent],
                          isEvaluated: true)
        session.guesses = Array(repeating: wrong, count: 6)
        session.phase = .lost
        session.endTime = Date()

        let oppPerf = PlayerPerformance(playerID: "p2", playerName: "Opp",
                                        guessCount: 6, solved: false, duration: 200)

        let result = engine.computeResult(session: session, localPlayer: localPlayer, opponentPerformance: oppPerf)
        XCTAssertTrue(result.isDraw)
    }

    // MARK: - Helpers

    private func makeSolvedSession(guessCount: Int, duration: TimeInterval, startOverride: Date? = nil) -> GameSession {
        let start = startOverride ?? Date()
        var session = GameSession(mode: .duel, targetWord: "kitap")
        session.startTime = start
        let winGuess = Guess(word: "kitap",
                             evaluation: [.correct, .correct, .correct, .correct, .correct],
                             isEvaluated: true)
        let wrongGuess = Guess(word: "aaaaa",
                               evaluation: [.absent, .absent, .absent, .absent, .absent],
                               isEvaluated: true)
        let preceding = Array(repeating: wrongGuess, count: max(0, guessCount - 1))
        session.guesses = preceding + [winGuess]
        session.phase = .won
        session.endTime = start.addingTimeInterval(duration)
        return session
    }
}

// MARK: - GameSession convenience init for tests
private extension GameSession {
    init(mode: GameMode, targetWord: String) {
        self.init(mode: mode, config: .default, targetWord: targetWord)
    }
}
