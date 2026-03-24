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
                GameLoadingView(mode: mode)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExitToMainMenu"))) { _ in
            env.multipeerService.disconnect()
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RestartGame"))) { _ in
            viewModel?.showResult = false
            dismiss()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .task { await setupViewModel() }
    }

    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.warning.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.Colors.warning)
            }
            Text("Kelime Yüklenemedi")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(error)
                .font(AppTheme.Font.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await setupViewModel() }
            } label: {
                Label("Tekrar Dene", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.Gradients.primaryButton)
                    .cornerRadius(AppTheme.Radius.lg)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Image(systemName: mode == .solo ? "brain.head.profile" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(mode == .solo ? "Solo Pratik" : "Yakın Düello")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.text)
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                if mode == .duel {
                    env.multipeerService.disconnect()
                }
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.surface)
                    .clipShape(Circle())
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
                           onRematch: { 
                                if viewModel.toastMessage == "Rakip rövanş istiyor!" {
                                    viewModel.acceptRematch()
                                } else {
                                    viewModel.requestRematch()
                                }
                           },
                           onMainMenu: {
                                viewModel.showResult = false
                                env.multipeerService.disconnect()
                                // No direct access to parent 'dismiss' here, 
                                // so we use a notification or rely on viewModel state if needed,
                                // but the most reliable way is to let the parent handle it.
                                NotificationCenter.default.post(name: NSNotification.Name("ExitToMainMenu"), object: nil)
                           })
            }
        }
    }

    @ViewBuilder
    private var statsBar: some View {
        HStack {
            // Coin balance
            HStack(spacing: 5) {
                Image(systemName: "circle.circle.fill")
                    .foregroundStyle(AppTheme.Colors.gold)
                    .font(.system(size: 14))
                Text("\(env.statsService.stats.coins)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.text)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.Radius.md)

            Spacer()

            let isSolo = mode == .solo
            let cost = isSolo ? 10 : 50
            Button(action: { viewModel.revealHint() }) {
                HStack(spacing: 5) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13))
                    Text("İpucu · \(cost)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if env.statsService.stats.coins >= cost {
                        AppTheme.Gradients.primaryButton
                    } else {
                        Color.gray.opacity(0.4)
                    }
                }
                .cornerRadius(AppTheme.Radius.md)
            }
            .disabled(env.statsService.stats.coins < cost || viewModel.session.isFinished)
            .opacity(viewModel.session.isFinished ? 0 : 1)
            .buttonStyle(ScaleButtonStyle())

            Button(action: reportWord) {
                Image(systemName: "exclamationmark.bubble")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.Colors.surface)
                    .cornerRadius(AppTheme.Radius.md)
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(Color(hex: "1C1F2E").opacity(0.96))
                        .overlay(Capsule().stroke(AppTheme.Colors.border, lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            Color.clear
        }
    }
}

// MARK: - Branded loading screen
private struct GameLoadingView: View {
    let mode: GameMode
    @State private var rotation: Double = 0
    @State private var appear = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Tile row animation placeholder
            HStack(spacing: 7) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(AppTheme.Colors.surfaceHigh)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                .stroke(AppTheme.Colors.border, lineWidth: 1)
                        )
                        .opacity(appear ? 1 : 0)
                        .scaleEffect(appear ? 1 : 0.7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(i) * 0.08), value: appear)
                }
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                // Spinner
                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.border, lineWidth: 2.5)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.Colors.primary.opacity(0.1), AppTheme.Colors.primary],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(rotation))
                }
                .onAppear {
                    withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }

                Text(mode == .solo ? "Kelime Seçiliyor..." : "Düello Başlıyor...")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .onAppear { appear = true }
    }
}

#Preview {
    NavigationStack {
        GameView(mode: .solo)
            .environmentObject(AppEnvironment())
    }
}

