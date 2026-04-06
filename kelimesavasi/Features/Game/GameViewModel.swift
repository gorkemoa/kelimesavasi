import Foundation
import Combine
import MultipeerConnectivity

// MARK: - GameViewModel
final class GameViewModel: ObservableObject {

    // MARK: Game state
    @Published private(set) var session: GameSession
    @Published var currentInput: String = ""
    @Published var keyStates: [String: TileState] = [:]
    var phase: GamePhase { session.phase }

    // MARK: UI feedback
    @Published var shakingRow: Int?
    @Published var revealingRow: Int?
    @Published var toastMessage: String?
    @Published var gameResult: GameResult?
    @Published var showResult: Bool = false

    // MARK: Duel state
    var isHost: Bool
    @Published var opponentPerformance: PlayerPerformance?
    /// Separate @Published so the progress view re-renders on every update.
    /// (Mutating a nested value inside session does not reliably trigger SwiftUI.)
    @Published private(set) var opponentGuessCount: Int = 0
    @Published var isOpponentDone: Bool = false
    private var hasFinishedGame = false

    // MARK: Dependencies
    private let engine: WordleGameEngine
    private let settings: SettingsService
    private let stats: StatsService
    private let haptic = HapticHelper.shared
    private weak var multipeerService: MultipeerSessionManager?

    // MARK: Init (Solo)
    init(session: GameSession,
         engine: WordleGameEngine,
         settings: SettingsService,
         stats: StatsService) {
        self.session = session
        self.engine  = engine
        self.settings = settings
        self.stats   = stats
        self.isHost  = false
    }

    // MARK: Init (Duel)
    init(session: GameSession,
         engine: WordleGameEngine,
         settings: SettingsService,
         stats: StatsService,
         isHost: Bool,
         multipeerService: MultipeerSessionManager) {
        self.session = session
        self.engine  = engine
        self.settings = settings
        self.stats   = stats
        self.isHost  = isHost
        self.multipeerService = multipeerService
        subscribeToMessages()
    }

    // MARK: - Keyboard actions

    func addLetter(_ letter: String) {
        guard session.phase == .playing else { return }
        
        let wordLen = session.config.wordLength
        let hintsCount = session.revealedHints.count
        let remainingNeeded = wordLen - hintsCount
        
        guard currentInput.count < remainingNeeded else { return }
        
        currentInput += letter
        if settings.hapticEnabled { haptic.keyPress() }
    }

    func deleteLetter() {
        guard !currentInput.isEmpty else { return }
        currentInput.removeLast()
    }

    func revealHint() {
        guard session.phase == .playing else { return }

        let isSolo = session.mode == .solo
        let cost = isSolo ? 10 : 50

        let target = Array(session.targetWord)
        let wordLen = session.config.wordLength
        
        var unguessedIndices: [Int] = []
        for i in 0..<wordLen {
            let alreadyCorrect = session.guesses.contains { g in
                g.evaluation.count > i && g.evaluation[i] == .correct
            }
            if !alreadyCorrect {
                unguessedIndices.append(i)
            }
        }

        if let index = unguessedIndices.randomElement() {
            if stats.spendCoins(cost) {
                let letter = String(target[index])
                session.revealedHints[index] = letter
                showToast("İpucu: \(index + 1). harf '\(letter.uppercased())'")
                if settings.hapticEnabled { haptic.submitGuess() }
            } else {
                showToast("\(cost) Coin Gerekli!")
            }
        } else {
            showToast("Tüm harfleri buldun zaten!")
        }
    }

    @MainActor
    func submitGuess() async {
        guard session.phase == .playing else { return }
        
        // Build the word using revealed hints + current input
        let wordLen = session.config.wordLength
        var finalWordChars = Array(repeating: "", count: wordLen)
        let inputChars = Array(currentInput)
        var inputIdx = 0
        
        for i in 0..<wordLen {
            if let hint = session.revealedHints[i] {
                finalWordChars[i] = hint.lowercased()
            } else if inputIdx < inputChars.count {
                finalWordChars[i] = String(inputChars[inputIdx]).lowercased()
                inputIdx += 1
            }
        }
        
        let word = finalWordChars.joined()
        
        guard word.count == wordLen else { 
            showToast("Kelimeyi tamamlayın")
            return 
        }

        let valid = await engine.isValidWord(word, config: session.config)
        guard valid else {
            showToast("Bu kelime listede yok")
            triggerShake(row: session.currentGuessIndex)
            if settings.hapticEnabled { haptic.invalidWord() }
            return
        }

        let guess = engine.evaluateGuess(word, in: session)
        session.guesses.append(guess)
        currentInput = ""

        let row = session.guesses.count - 1
        triggerReveal(row: row)
        keyStates = engine.aggregateKeyStates(from: session.guesses)

        if settings.hapticEnabled { haptic.submitGuess() }

        // Win / lose check
        if guess.isCorrect {
            session.phase = .won
            session.endTime = Date()
            if settings.hapticEnabled { haptic.win() }
            finishGame()
        } else if session.guesses.count >= session.config.maxGuesses {
            session.phase = .lost
            session.endTime = Date()
            if settings.hapticEnabled { haptic.lose() }
            showToast(session.targetWord.uppercased())
            finishGame()
        }

        // Send progress to opponent in duel mode
        if session.mode == .duel {
            sendProgress()
            if guess.isCorrect || session.guesses.count >= session.config.maxGuesses {
                sendGameCompleted()
            }
        }
    }

    // MARK: - Tile accessors

    func tileLetter(row: Int, col: Int) -> String {
        if row < session.guesses.count {
            let chars = Array(session.guesses[row].word)
            return col < chars.count ? String(chars[col]) : ""
        } else if row == session.guesses.count {
            if let hint = session.revealedHints[col] {
                return hint
            }
            // Map currentInput chars to non-hint columns (skip hint slots)
            let inputIndex = (0..<col).filter { session.revealedHints[$0] == nil }.count
            let chars = Array(currentInput)
            return inputIndex < chars.count ? String(chars[inputIndex]) : ""
        }
        return ""
    }

    func tileState(row: Int, col: Int) -> TileState {
        if row < session.guesses.count {
            let eval = session.guesses[row].evaluation
            return col < eval.count ? eval[col] : .absent
        } else if row == session.guesses.count {
            if session.revealedHints[col] != nil {
                return .correct
            }
            let inputIndex = (0..<col).filter { session.revealedHints[$0] == nil }.count
            let chars = Array(currentInput)
            return inputIndex < chars.count ? .filled : .empty
        }
        return .empty
    }

    // MARK: - Rematch

    func requestRematch() {
        guard session.mode == .duel else { return }
        try? multipeerService?.send(
            PeerMessage(type: .rematchRequest, payload: Data())
        )
    }

    func acceptRematch() {
        try? multipeerService?.send(
            PeerMessage(type: .rematchAccepted, payload: Data())
        )
        NotificationCenter.default.post(name: NSNotification.Name("RestartGame"), object: nil)
    }

    // MARK: - Private helpers

    /// - Parameter immediate: when true, skips the tile-reveal delay and shows result right away.
    ///   Used when the opponent finishes and we need to sync both screens simultaneously.
    private func finishGame(immediate: Bool = false) {
        guard !hasFinishedGame else { return }
        hasFinishedGame = true
        let localPlayer = Player(name: settings.playerName)
        let result = engine.computeResult(session: session,
                                          localPlayer: localPlayer,
                                          opponentPerformance: opponentPerformance)
        gameResult = result
        stats.record(result: result)

        if immediate {
            showResult = true
        } else {
            // Delay matches tile flip animation so the board is visible before the sheet.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showResult = true
            }
        }
    }

    private func sendProgress() {
        guard let multipeerService else { return }
        let payload = ProgressPayload(guessCount: session.guesses.count)
        try? multipeerService.send(try PeerMessage.make(payload, type: .opponentProgress))
    }

    private func sendGameCompleted() {
        guard let multipeerService else { return }
        let lastGuess = session.guesses.last
        let solved = lastGuess?.isCorrect ?? false
        let perf = PlayerPerformance(
            playerID: settings.playerName,
            playerName: settings.playerName,
            guessCount: session.guesses.count,
            solved: solved,
            duration: session.duration
        )
        let payload = GameCompletedPayload(performance: perf)
        try? multipeerService.send(try PeerMessage.make(payload, type: .gameCompleted))
    }

    private func subscribeToMessages() {
        multipeerService?.incomingMessages
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                self?.handlePeerMessage(message)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func handlePeerMessage(_ message: PeerMessage) {
        switch message.type {
        case .opponentProgress:
            if let payload = try? message.decode(ProgressPayload.self) {
                session.opponentGuessCount = payload.guessCount
                opponentGuessCount = payload.guessCount   // triggers SwiftUI refresh
            }
        case .gameCompleted:
            if let payload = try? message.decode(GameCompletedPayload.self) {
                opponentPerformance = payload.performance
                opponentGuessCount = payload.performance.guessCount  // final count
                isOpponentDone = true
                if hasFinishedGame {
                    // I already finished — recompute result with full opponent data and
                    // make sure the sheet is shown immediately (no additional delay).
                    let localPlayer = Player(name: settings.playerName)
                    gameResult = engine.computeResult(
                        session: session,
                        localPlayer: localPlayer,
                        opponentPerformance: opponentPerformance
                    )
                    showResult = true
                } else {
                    // One person finished — end the game for everyone!
                    if !session.isFinished {
                        session.phase = .finished
                        session.endTime = Date()
                    }
                    finishGame(immediate: true)
                }
            }
        case .rematchRequest:
            showToast("Rakip rövanş istiyor!")
            NotificationCenter.default.post(name: NSNotification.Name("PeerRematchRequested"), object: nil)
        case .rematchAccepted:
            showToast("Rövanş kabul edildi!")
            // When rematch is accepted, tell the lobby to restart
            NotificationCenter.default.post(name: NSNotification.Name("RestartGame"), object: nil)
        default:
            break
        }
    }

    private func triggerShake(row: Int) {
        shakingRow = row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.shakingRow == row { self?.shakingRow = nil }
        }
    }

    private func triggerReveal(row: Int) {
        revealingRow = row
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(session.config.wordLength) * AppConstants.flipAnimationDelay + AppConstants.guessAnimationDuration) { [weak self] in
            if self?.revealingRow == row { self?.revealingRow = nil }
        }
    }

    func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.toastMessage == msg { self?.toastMessage = nil }
        }
    }

    /// For unit tests: directly inject a revealed hint at a column index.
    func _testing_setHint(_ letter: String, at col: Int) {
        session.revealedHints[col] = letter
    }
}
