import SwiftUI

struct ResultView: View {
    let result: GameResult
    var canRematch: Bool = false
    var onRematch: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    private var headline: String {
        if result.mode == .solo {
            return result.myPerformance.solved ? "Tebrikler! 🎉" : "Bilemedin 😔"
        }
        if result.isDraw { return "Beraberlik 🤝" }
        return result.iWon ? "Kazandın! 🏆" : "Kaybettin 😔"
    }

    private var headlineColor: Color {
        if result.isDraw { return AppTheme.Colors.warning }
        if result.mode == .solo {
            return result.myPerformance.solved ? AppTheme.Colors.correct : AppTheme.Colors.error
        }
        return result.iWon ? AppTheme.Colors.correct : AppTheme.Colors.error
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {

                    // Headline
                    Text(headline)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(headlineColor)
                        .padding(.top, AppTheme.Spacing.xxl)

                    // Target word reveal
                    targetWordCard

                    // Performance card
                    performanceCard(perf: result.myPerformance, isMine: true)

                    if let opp = result.opponentPerformance {
                        performanceCard(perf: opp, isMine: false)
                    }

                    // Actions
                    actionsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Target word
    private var targetWordCard: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("Hedef Kelime")
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack(spacing: 6) {
                ForEach(Array(result.targetWord.uppercased()), id: \.self) { ch in
                    Text(String(ch))
                        .font(AppTheme.Font.tile(24))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.Colors.correct)
                        .cornerRadius(AppTheme.Radius.sm)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .surfaceStyle()
    }

    // MARK: - Performance
    private func performanceCard(perf: PlayerPerformance, isMine: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(isMine ? "Sen" : perf.playerName)
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)

                HStack(spacing: AppTheme.Spacing.xs) {
                    Label("\(perf.guessCount) tahmin", systemImage: "number")
                    if perf.duration > 0 {
                        Label(String(format: "%.0fs", perf.duration), systemImage: "clock")
                    }
                }
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: perf.solved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(perf.solved ? AppTheme.Colors.correct : AppTheme.Colors.error)
        }
        .padding(AppTheme.Spacing.md)
        .surfaceStyle(elevated: isMine)
    }

    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if canRematch {
                Button {
                    onRematch?()
                    dismiss()
                } label: {
                    Label("Rövanş İste", systemImage: "arrow.clockwise")
                        .font(AppTheme.Font.headline())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Radius.lg)
                }
                .buttonStyle(.plain)
            }

            Button {
                dismiss()
            } label: {
                Text("Ana Menü")
                    .font(AppTheme.Font.body())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .surfaceStyle()
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    let myPerf = PlayerPerformance(playerID: "1", playerName: "Ben", guessCount: 4, solved: true, duration: 95)
    let oppPerf = PlayerPerformance(playerID: "2", playerName: "Ahmet", guessCount: 5, solved: false, duration: 120)
    let result = GameResult(sessionID: "test", mode: .duel, winnerID: "1", isDraw: false,
                            myPerformance: myPerf, opponentPerformance: oppPerf, targetWord: "kitap")
    ResultView(result: result, canRematch: true, onRematch: {})
}
