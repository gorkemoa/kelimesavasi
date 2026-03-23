import SwiftUI

struct HomeView: View {
    let onNavigate: (AppRoute) -> Void
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                Spacer()

                // Action buttons
                VStack(spacing: AppTheme.Spacing.md) {
                    menuButton(
                        title: "Solo Pratik",
                        subtitle: "Tek başına oyna",
                        icon: "text.cursor",
                        action: { onNavigate(.soloGame) }
                    )

                    menuButton(
                        title: "Yakın Düello",
                        subtitle: "Yakındaki oyuncu ile 1v1",
                        icon: "antenna.radiowaves.left.and.right",
                        isPrimary: true,
                        action: { onNavigate(.nearbyLobby) }
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer()

                // Bottom nav
                bottomBar
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("KELIME")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .tracking(4)
                .foregroundStyle(AppTheme.Colors.primary)

            Text("DÜELLO")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.Colors.text)

            // Demo tiles
            HStack(spacing: 5) {
                ForEach(["K", "E", "L", "İ", "M"], id: \.self) { letter in
                    demoTile(letter: letter)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.xxl)
    }

    private func demoTile(letter: String) -> some View {
        let tileStates: [TileState] = [.correct, .correct, .present, .absent, .correct]
        let letters = ["K", "E", "L", "İ", "M"]
        let idx = letters.firstIndex(of: letter) ?? 0
        let bg: Color = {
            switch tileStates[min(idx, tileStates.count - 1)] {
            case .correct: return AppTheme.Colors.correct
            case .present: return AppTheme.Colors.present
            default:       return AppTheme.Colors.absent
            }
        }()
        return Text(letter)
            .font(AppTheme.Font.tile(20))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(bg)
            .cornerRadius(AppTheme.Radius.sm)
    }

    // MARK: - Menu button
    private func menuButton(
        title: String,
        subtitle: String,
        icon: String,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isPrimary ? .white : AppTheme.Colors.primary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Font.headline())
                        .foregroundStyle(AppTheme.Colors.text)
                    Text(subtitle)
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(isPrimary ? .white.opacity(0.7) : AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                isPrimary
                    ? LinearGradient(colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryDim],
                                     startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [AppTheme.Colors.surface, AppTheme.Colors.surface],
                                     startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(AppTheme.Radius.lg)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        HStack {
            Spacer()
            bottomBarItem(icon: "chart.bar", label: "İstatistik") { onNavigate(.stats) }
            Spacer()
            bottomBarItem(icon: "gearshape", label: "Ayarlar") { onNavigate(.settings) }
            Spacer()
        }
        .padding(.bottom, AppTheme.Spacing.xl)
        .padding(.top, AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface.ignoresSafeArea(edges: .bottom))
    }

    private func bottomBarItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                Text(label)
                    .font(AppTheme.Font.caption(11))
            }
            .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeView { _ in }
            .environmentObject(AppEnvironment())
    }
}
