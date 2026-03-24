import SwiftUI

struct HomeView: View {
    let onNavigate: (AppRoute) -> Void
    @EnvironmentObject var env: AppEnvironment

    @State private var glowPulse = false
    @State private var heroVisible = false
    @State private var buttonsVisible = false
    @State private var tileScale: [CGFloat] = [1, 1, 1, 1, 1]

    private let tileLetters = ["S", "A", "V", "A", "Ş"]
    private let tileStates: [TileState] = [.correct, .correct, .present, .absent, .correct]

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()

                heroSection
                    .opacity(heroVisible ? 1 : 0)
                    .offset(y: heroVisible ? 0 : 24)

                Spacer()

                menuSection
                    .opacity(buttonsVisible ? 1 : 0)
                    .offset(y: buttonsVisible ? 0 : 32)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer(minLength: AppTheme.Spacing.md)

                bottomBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                heroVisible = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.35)) {
                buttonsVisible = true
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            animateTilesOnAppear()
        }
    }

    // MARK: - Background
    private var backgroundLayer: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            // Top blue ambient glow
            EllipticalGradient(
                colors: [AppTheme.Colors.primary.opacity(glowPulse ? 0.20 : 0.10), .clear],
                center: .init(x: 0.5, y: 0),
                endRadiusFraction: 0.55
            )
            .ignoresSafeArea()
            .frame(height: 380)
            .frame(maxHeight: .infinity, alignment: .top)

            // Bottom purple tint
            EllipticalGradient(
                colors: [Color(hex: "4A3F8F").opacity(0.14), .clear],
                center: .init(x: 0.5, y: 1),
                endRadiusFraction: 0.55
            )
            .ignoresSafeArea()
            .frame(height: 300)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Brand badge
            Text("⚔️  KELİME SAVAŞI")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(AppTheme.Colors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(AppTheme.Colors.primary.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1))

            // Main title
            VStack(spacing: 2) {
                Text("Hızlı Düşün")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Hızlı Yaz • Kazan")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            // Animated demo tiles
            HStack(spacing: 7) {
                ForEach(0..<tileLetters.count, id: \.self) { i in
                    heroTile(letter: tileLetters[i], state: tileStates[i])
                        .scaleEffect(tileScale[i])
                }
            }
        }
    }

    private func heroTile(letter: String, state: TileState) -> some View {
        let color: Color = {
            switch state {
            case .correct: return AppTheme.Colors.correct
            case .present: return AppTheme.Colors.present
            default:       return AppTheme.Colors.absent
            }
        }()
        return Text(letter)
            .font(.system(size: 21, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .fill(color)
                    .shadow(color: color.opacity(0.45), radius: 8, x: 0, y: 4)
            )
    }

    private func animateTilesOnAppear() {
        for i in 0..<tileLetters.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    tileScale[i] = 1.18
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        tileScale[i] = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Menu
    private var menuSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // PRIMARY: Yakın Düello
            Button { onNavigate(.nearbyLobby) } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Yakın Düello")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Yakındaki oyuncu ile 1v1 düello")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Gradients.primaryButton)
                .cornerRadius(AppTheme.Radius.lg)
                .shadow(color: AppTheme.Colors.primary.opacity(0.40), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(ScaleButtonStyle())

            // SECONDARY: Solo Pratik
            Button { onNavigate(.soloGame) } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.surfaceHigh)
                            .frame(width: 50, height: 50)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Solo Pratik")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.text)
                        Text("Tek başına kelime bul, becerini geliştir")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textDisabled)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.Radius.lg)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .stroke(AppTheme.Colors.border, lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())

            // Quick actions row
            HStack(spacing: AppTheme.Spacing.sm) {
                quickActionButton(icon: "chart.bar.fill", label: "İstatistik") { onNavigate(.stats) }
                quickActionButton(icon: "gearshape.fill", label: "Ayarlar") { onNavigate(.settings) }
            }
        }
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.Radius.md)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(AppTheme.Colors.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        let streak = env.statsService.stats.currentStreak
        return Group {
            if streak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(streak) günlük seri devam ediyor!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            } else {
                Color.clear.frame(height: AppTheme.Spacing.xl)
            }
        }
    }
}

// MARK: - Scale press button style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        HomeView { _ in }
            .environmentObject(AppEnvironment())
    }
}
