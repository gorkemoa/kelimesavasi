import SwiftUI
import MultipeerConnectivity

struct GameView: View {
    let mode: GameMode
    var targetWord: String? = nil   // nil → GameView picks random (solo or duel host)
    var config: GameConfig = .default
    var isHost: Bool = false

    @EnvironmentObject var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: GameViewModel?
    @State private var loadError: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if let vm = viewModel {
                GameContentView(viewModel: vm, mode: mode)
            } else if let error = loadError {
                errorView(error)
            } else {
                ProgressView()
                    .tint(AppTheme.Colors.primary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(mode == .duel)
        .toolbar { toolbarContent }
        .task { await setupViewModel() }
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
        if mode == .duel {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    env.multipeerService.disconnect()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Setup

    private func setupViewModel() async {
        do {
            let session: GameSession

            if let word = targetWord, !word.isEmpty {
                // Both host and guest: lobby VM picks the word and passes it here
                session = env.gameEngine.newDuelSession(targetWord: word, config: config)
            } else if mode == .duel {
                // Fallback: should not normally be reached; pick word locally
                let randomWord = try await env.wordRepository.randomTargetWord(length: config.wordLength)
                session = env.gameEngine.newDuelSession(targetWord: randomWord, config: config)
            } else {
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

// MARK: - GameContentView
// Separate struct with @ObservedObject so every @Published change on GameViewModel
// triggers a re-render (keyboard display, board tiles, toast, etc.)
private struct GameContentView: View {
    @ObservedObject var viewModel: GameViewModel
    let mode: GameMode
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        VStack(spacing: 0) {
            statsBar
                .padding(.horizontal, 16)
                .padding(.top, 4)

            if mode == .duel {
                let opponentName = env.multipeerService.connectedPeers.first?.displayName ?? "Rakip"
                OpponentProgressView(
                    opponentGuessCount: viewModel.opponentGuessCount,
                    maxGuesses: viewModel.session.config.maxGuesses,
                    isDone: viewModel.isOpponentDone,
                    opponentName: opponentName
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }

            toastLayer
                .frame(height: 36)
                .padding(.top, 4)

            GameBoardView(viewModel: viewModel)
                .padding(.top, 8)

            Spacer()

            if !viewModel.session.isFinished {
                KeyboardView(
                    keyStates: viewModel.keyStates,
                    onLetter: { viewModel.addLetter($0) },
                    onDelete: { viewModel.deleteLetter() },
                    onSubmit: { Task { await viewModel.submitGuess() } }
                )
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showResult },
            set: { viewModel.showResult = $0 }
        )) {
            if let result = viewModel.gameResult {
                ResultView(result: result,
                           canRematch: mode == .duel,
                           onRematch: { viewModel.requestRematch() })
            }
        }
    }

    @ViewBuilder
    private var statsBar: some View {
        HStack {
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

            let isSolo = mode == .solo
            let cost = isSolo ? 10 : 50
            Button(action: { viewModel.revealHint() }) {
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
            .opacity(viewModel.session.isFinished ? 0 : 1)

            Button(action: reportWord) {
                Image(systemName: "exclamationmark.bubble")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(8)
            }
        }
    }

    private func reportWord() {
        let word = viewModel.session.targetWord.uppercased()
        let body = "Bu kelime oyun listesinde olmalı: \(word)"
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailUrl = URL(string: "mailto:gorkemoa35@gmail.com?subject=Kelime%20Savasi%20Kelime%20Bildirimi&body=\(encodedBody)")!
        if UIApplication.shared.canOpenURL(mailUrl) {
            UIApplication.shared.open(mailUrl)
        } else {
            viewModel.showToast("Mail uygulaması bulunamadı.")
        }
    }

    @ViewBuilder
    private var toastLayer: some View {
        if let msg = viewModel.toastMessage {
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
}

#Preview {
    NavigationStack {
        GameView(mode: .solo)
            .environmentObject(AppEnvironment())
    }
}

