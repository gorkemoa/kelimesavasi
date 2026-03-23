import SwiftUI
import MultipeerConnectivity

struct GameView: View {
    let mode: GameMode
    var targetWord: String? = nil   // nil → GameView picks random (solo or duel host)
    var config: GameConfig = .default
    var isHost: Bool = false

    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: GameViewModel?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if let vm = viewModel {
                gameContent(vm: vm)
            } else if let error = loadError {
                errorView(error)
            } else {
                ProgressView()
                    .tint(AppTheme.Colors.primary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await setupViewModel() }
    }

    // MARK: - Main game content
    @ViewBuilder
    private func gameContent(vm: GameViewModel) -> some View {
        VStack(spacing: 0) {
            // Stats bar
            statsBar(vm: vm)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            // Opponent progress bar (duel only)
            if mode == .duel {
                let peers = env.multipeerService.connectedPeers
                let opponentName = peers.first?.displayName ?? "Rakip"
                OpponentProgressView(
                    opponentGuessCount: vm.opponentGuessCount,
                    maxGuesses: vm.session.config.maxGuesses,
                    isDone: vm.isOpponentDone,
                    opponentName: opponentName
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }

            // Toast message
            toastLayer(vm: vm)
                .frame(height: 36)
                .padding(.top, 4)

            // Game board
            GameBoardView(viewModel: vm)
                .padding(.top, 8)

            Spacer()

            // Keyboard
            if !vm.session.isFinished {
                KeyboardView(
                    keyStates: vm.keyStates,
                    onLetter: { vm.addLetter($0) },
                    onDelete: { vm.deleteLetter() },
                    onSubmit: {
                        Task { await vm.submitGuess() }
                    }
                )
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.showResult },
            set: { vm.showResult = $0 }
        )) {
            if let result = vm.gameResult {
                ResultView(result: result,
                           canRematch: mode == .duel,
                           onRematch: { vm.requestRematch() })
            }
        }
    }

    @ViewBuilder
    private func statsBar(vm: GameViewModel) -> some View {
        HStack {
            // Coin Display
            HStack(spacing: 4) {
                Image(systemName: "circle.circle.fill")
                    .foregroundColor(.yellow)
                Text("\(env.statsService.stats.coins)")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.Colors.surface)
            .cornerRadius(12)

            Spacer()

            // Joker / Hint Button
            let isSolo = mode == .solo
            let cost = isSolo ? 10 : 50
            Button(action: { vm.revealHint() }) {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                    Text("İpucu (\(cost))")
                }
                .font(AppTheme.Font.caption())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(env.statsService.stats.coins >= cost ? AppTheme.Colors.primary : Color.gray)
                .cornerRadius(10)
            }
            .disabled(env.statsService.stats.coins < cost)
            .opacity(vm.session.isFinished ? 0 : 1)

            // Report Word Button
            Button(action: { reportWord(vm: vm) }) {
                Image(systemName: "exclamationmark.bubble")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(8)
            }
        }
    }

    private func reportWord(vm: GameViewModel) {
        let word = vm.session.targetWord.uppercased()
        let body = "Bu kelime oyun listesinde olmalı: \(word)"
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailUrl = URL(string: "mailto:gorkemoa35@gmail.com?subject=Kelime%20Savasi%20Kelime%20Bildirimi&body=\(encodedBody)")!
        
        if UIApplication.shared.canOpenURL(mailUrl) {
            UIApplication.shared.open(mailUrl)
        } else {
            vm.showToast("Mail uygulaması bulunamadı.")
        }
    }

    @ViewBuilder
    private func toastLayer(vm: GameViewModel) -> some View {
        if let msg = vm.toastMessage {
            Text(msg)
                .font(AppTheme.Font.caption(13))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "222435").opacity(0.95))
                .cornerRadius(AppTheme.Radius.pill)
                .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.Colors.warning)
            Text(error)
                .font(AppTheme.Font.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(mode == .solo ? "Solo Pratik" : "Yakın Düello")
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.text)
        }
    }

    // MARK: - Setup

    private func setupViewModel() async {
        do {
            let session: GameSession

            if let word = targetWord, !word.isEmpty {
                // Guest in duel: target word received from host
                session = env.gameEngine.newDuelSession(targetWord: word, config: config)
            } else if mode == .duel {
                // Host in duel: pick random word, then tell guest
                let randomWord = try await env.wordRepository.randomTargetWord(length: config.wordLength)
                session = env.gameEngine.newDuelSession(targetWord: randomWord, config: config)
            } else {
                // Solo practice
                session = try await env.gameEngine.newSoloSession(config: config)
            }

            if mode == .duel {
                viewModel = GameViewModel(
                    session: session,
                    engine: env.gameEngine,
                    settings: env.settingsService,
                    stats: env.statsService,
                    isHost: isHost,
                    multipeerService: env.multipeerService
                )
                // If host, send game start to guest
                if isHost {
                    let payload = GameStartedPayload(
                        config: session.config,
                        targetWord: session.targetWord,
                        hostID: env.settingsService.playerName,
                        hostName: env.settingsService.playerName
                    )
                    try? env.multipeerService.send(try PeerMessage.make(payload, type: .gameStarted))
                }
            } else {
                viewModel = GameViewModel(
                    session: session,
                    engine: env.gameEngine,
                    settings: env.settingsService,
                    stats: env.statsService
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        GameView(mode: .solo)
            .environment(AppEnvironment())
    }
}
