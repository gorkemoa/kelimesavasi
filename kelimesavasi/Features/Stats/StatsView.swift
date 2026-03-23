import SwiftUI

struct StatsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    private var stats: LocalStats { env.statsService.stats }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Summary row
                    summaryRow

                    // Streak
                    streakCard

                    // Guess distribution
                    distributionCard

                    // Solo stats
                    soloCard
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("İstatistikler")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
            }
        }
    }

    // MARK: - Summary
    private var summaryRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(stats.totalGames)", label: "Oyun")
            Divider().background(AppTheme.Colors.border).frame(height: 40)
            statCell(value: "\(stats.wins)", label: "Galibiyet")
            Divider().background(AppTheme.Colors.border).frame(height: 40)
            statCell(value: String(format: "%.0f%%", stats.winRate * 100), label: "Oran")
            Divider().background(AppTheme.Colors.border).frame(height: 40)
            statCell(value: "\(stats.draws)", label: "Beraberlik")
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .surfaceStyle()
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.Font.title(24))
                .foregroundStyle(AppTheme.Colors.text)
            Text(label)
                .font(AppTheme.Font.caption(11))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Streak
    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Seri")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
                Text("Mevcut • En İyi")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            HStack(spacing: AppTheme.Spacing.md) {
                streakBadge(value: stats.currentStreak, label: "Mevcut", color: AppTheme.Colors.primary)
                streakBadge(value: stats.maxStreak, label: "En İyi", color: AppTheme.Colors.correct)
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceStyle()
    }

    private func streakBadge(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AppTheme.Font.title(28))
                .foregroundStyle(color)
            Text(label)
                .font(AppTheme.Font.caption(10))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(width: 60)
    }

    // MARK: - Distribution
    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Tahmin Dağılımı")
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.text)

            let maxValue = stats.guessDistribution.values.max() ?? 1

            ForEach(1...AppConstants.defaultMaxGuesses, id: \.self) { guess in
                let count = stats.guessDistribution[guess] ?? 0
                distributionBar(guess: guess, count: count, maxValue: max(maxValue, 1))
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceStyle()
    }

    private func distributionBar(guess: Int, count: Int, maxValue: Int) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text("\(guess)")
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 14, alignment: .trailing)

            GeometryReader { geo in
                let width = count > 0
                    ? max(20, geo.size.width * CGFloat(count) / CGFloat(maxValue))
                    : 20
                RoundedRectangle(cornerRadius: 4)
                    .fill(count > 0 ? AppTheme.Colors.correct : AppTheme.Colors.border)
                    .frame(width: width, height: 20)
                    .overlay(
                        Text("\(count)")
                            .font(AppTheme.Font.caption(11))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6),
                        alignment: .trailing
                    )
            }
            .frame(height: 20)
        }
    }

    // MARK: - Solo stats
    private var soloCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Solo Pratik")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
                Text("\(stats.soloPracticeGames) oyun")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            Text("\(stats.soloWins) çözüldü")
                .font(AppTheme.Font.body())
                .foregroundStyle(AppTheme.Colors.correct)
        }
        .padding(AppTheme.Spacing.md)
        .surfaceStyle()
    }
}

#Preview {
    NavigationStack {
        StatsView()
            .environment(AppEnvironment())
    }
}
