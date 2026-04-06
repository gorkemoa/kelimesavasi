import SwiftUI

struct HomeView: View {
    let onNavigate: (AppRoute) -> Void
    @EnvironmentObject var env: AppEnvironment

    @State private var glowPulse = false
    @State private var heroVisible = false
    @State private var buttonsVisible = false
    @State private var tileScale: [CGFloat] = [1, 1, 1, 1, 1]

    private let tileLetters = ["O", "Y", "U", "N", "U"]
    private let tileStates: [TileState] = [.correct, .correct, .correct, .correct, .correct]

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                heroSection
                    .opacity(heroVisible ? 1 : 0)
                    .offset(y: heroVisible ? 0 : 20)
                    .padding(.top, 40) // Kırpılmayı önlemek için üstten boşluk

                Spacer()

                menuSection
                    .opacity(buttonsVisible ? 1 : 0)
                    .offset(y: buttonsVisible ? 0 : 30)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer()

                bottomBar
                    .opacity(buttonsVisible ? 1 : 0)
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                heroVisible = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                buttonsVisible = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            animateTilesOnAppear()
        }
    }

    // MARK: - Background
    private var backgroundLayer: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            // Subtle mesh gradient-like effect
            Circle()
                .fill(AppTheme.Colors.primary.opacity(glowPulse ? 0.15 : 0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -150, y: -250)

            Circle()
                .fill(Color(hex: "4A3F8F").opacity(glowPulse ? 0.12 : 0.06))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: 180, y: 300)
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            
            // Main title with Logo
            VStack(spacing: AppTheme.Spacing.md) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                Text("KELİME")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(Color(white: 0.95))

                Text("DÜELLOSU")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(AppTheme.Colors.primary)
            }

            // High-end Tiles Display
            HStack(spacing: 12) {
                ForEach(0..<tileLetters.count, id: \.self) { i in
                    heroTile(letter: tileLetters[i], state: tileStates[i])
                        .scaleEffect(tileScale[i])
                }
            }
            .padding(.top, 10)
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

        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.surfaceHigh, AppTheme.Colors.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)

            // Inner glow for premium look
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.12))

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [color.opacity(0.8), color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            Text(letter)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: color.opacity(0.4), radius: 3)
        }
        .frame(width: 60, height: 60)
        .overlay(
            // Top highlight reflection
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func animateTilesOnAppear() {
        for i in 0..<tileLetters.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.08) {
                withAnimation(.interpolatingSpring(stiffness: 120, damping: 12)) {
                    tileScale[i] = 1.0
                }
            }
        }
        // Set initial scale to 0.8 to animate up
        for i in 0..<tileScale.count {
            tileScale[i] = 0.8
        }
    }

    // MARK: - Menu
    private var menuSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // MAIN ACTION: SOLO PRATİK (ÖNE ÇIKAN)
            Button { onNavigate(.soloGame) } label: {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(.white.opacity(0.25)))

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("SOLO PRATİK")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Zihnini tazele, rekorlarını kır")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4776E6"), Color(hex: "8E54E9")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "8E54E9").opacity(0.4), radius: 20, x: 0, y: 10)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // SECONDARY ACTIONS
            HStack(spacing: AppTheme.Spacing.md) {
                // YAKIN DÜELLO
                menuSecondaryCard(
                    title: "DÜELLO",
                    sub: "Arkadaşınla",
                    icon: "antenna.radiowaves.left.and.right",
                    color: Color(hex: "FF512F"),
                    secondaryColor: Color(hex: "DD2476")
                ) {
                    onNavigate(.nearbyLobby)
                }

                // İSTATİSTİK
                menuSecondaryCard(
                    title: "SKOR",
                    sub: "Başarıların",
                    icon: "chart.bar.fill",
                    color: Color(hex: "1D976C"),
                    secondaryColor: Color(hex: "93F9B9")
                ) {
                    onNavigate(.stats)
                }
            }

            // Settings link
            Button { onNavigate(.settings) } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Ayarlar ve Profil")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.Colors.surface))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.Colors.border, lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 8)
        }
    }

    private func menuSecondaryCard(title: String, sub: String, icon: String, color: Color, secondaryColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.white.opacity(0.2)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
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
