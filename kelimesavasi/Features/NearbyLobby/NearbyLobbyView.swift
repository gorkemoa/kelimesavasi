import SwiftUI
import MultipeerConnectivity

// MARK: - NearbyLobbyView (thin wrapper — passes services to the inner view that owns the VM)
struct NearbyLobbyView: View {
    var onGameReady: (String?, GameConfig, Bool) -> Void
    @EnvironmentObject var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NearbyLobbyContentView(
            sessionManager: env.multipeerService,
            discoveryService: env.discoveryService,
            settings: env.settingsService,
            wordRepository: env.wordRepository,
            onGameReady: onGameReady
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Geri")
                    }
                    .foregroundStyle(AppTheme.Colors.primary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Yakın Düello")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
            }
        }
    }
}

// MARK: - NearbyLobbyContentView (@StateObject owns the VM so @Published changes re-render the UI)
private struct NearbyLobbyContentView: View {
    @StateObject private var vm: NearbyLobbyViewModel
    let onGameReady: (String?, GameConfig, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    init(sessionManager: MultipeerSessionManager,
         discoveryService: NearbyDiscoveryService,
         settings: SettingsService,
         wordRepository: WordRepositoryProtocol,
         onGameReady: @escaping (String?, GameConfig, Bool) -> Void) {
        self.onGameReady = onGameReady
        let vm = NearbyLobbyViewModel(
            sessionManager: sessionManager,
            discoveryService: discoveryService,
            settings: settings,
            wordRepository: wordRepository
        )
        vm.onGameReady = onGameReady
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()
            
            // Background ambient glow
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -150, y: -250)

            lobbyContent
        }
        .onDisappear { vm.cancelIfNeeded() }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content

    @ViewBuilder
    private var lobbyContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            switch vm.phase {
            case .choosingRole:
                roleChooser
            case .hosting:
                hostingView
            case .joining:
                joiningView
            case .connecting, .waitingForStart:
                connectingView
            case .error(let msg):
                errorView(msg)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.lg)
    }

    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Role chooser
    private var roleChooser: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // High-end Animated Icon
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(colors: [AppTheme.Colors.primary, .clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(vm.phase == .choosingRole ? 360 : 0))
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: vm.phase)
                
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.1))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulseScale = 1.15
                        }
                    }
            }

            VStack(spacing: AppTheme.Spacing.md) {
                Text("Yakın Düello")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Aynı ağdaki arkadaşınla\ngerçek zamanlı kelime kapışması.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 10)

            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
                lobbyActionButton(
                    title: "OYUN KUR",
                    subtitle: "Lider ol, arkadaşını davet et",
                    icon: "crown.fill",
                    gradient: [Color(hex: "FF512F"), Color(hex: "DD2476")]
                ) {
                    vm.startHosting()
                }
                
                lobbyActionButton(
                    title: "OYUNA KATIL",
                    subtitle: "Kurulu olan odayı bul",
                    icon: "person.2.fill",
                    gradient: [Color(hex: "4776E6"), Color(hex: "8E54E9")]
                ) {
                    vm.startJoining()
                }
            }
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }

    private func lobbyActionButton(title: String, subtitle: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                    .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Hosting view
    private var hostingView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.5)
                        .opacity(0.5)
                    
                    Image(systemName: "wifi")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .modifier(SymbolEffectModifier(effect: .variableColor))
                }
                .padding(.top, AppTheme.Spacing.xxl)

                Text("Oyun Kuruldu")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
                
                Text("Arkadaşının seni bulmasını bekliyoruz...")
                    .font(AppTheme.Font.body(14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            if let peer = vm.pendingInviteFrom {
                invitationCard(peer: peer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                VStack(spacing: AppTheme.Spacing.lg) {
                    ProgressView()
                        .tint(AppTheme.Colors.primary)
                    Text("Görünen Adın: \(UIDevice.current.name)")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(AppTheme.Colors.textDisabled)
                }
                .padding()
                .background(AppTheme.Colors.surface.opacity(0.5))
                .cornerRadius(AppTheme.Radius.lg)
            }

            Spacer()
            
            Button("Vazgeç") {
                withAnimation {
                    vm.cancel()
                    dismiss()
                }
            }
            .font(AppTheme.Font.body())
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
    }

    // MARK: - Joining view
    private var joiningView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Oyunlar Aranıyor")
                        .font(AppTheme.Font.headline())
                        .foregroundStyle(AppTheme.Colors.text)
                    Text("Yakındaki aktif odalar")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                ProgressView()
                    .tint(AppTheme.Colors.primary)
            }
            .padding(.top, AppTheme.Spacing.md)

            if vm.discoveredPeers.isEmpty {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer()
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.Colors.textDisabled)
                        .modifier(SymbolEffectModifier(effect: .pulse))
                    
                    Text("Henüz kimse oyun kurmadı...")
                        .font(AppTheme.Font.body())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    Text("Arkadaşının 'Oyun Kur' butonuna bastığından emin ol.")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(AppTheme.Colors.textDisabled)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(vm.discoveredPeers, id: \.displayName) { peer in
                            peerRow(peer: peer) { 
                                withAnimation {
                                    vm.invitePeer(peer)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()
            
            Button("Geri Dön") {
                withAnimation {
                    vm.cancel()
                }
            }
            .font(AppTheme.Font.body())
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
    }

    // MARK: - Connecting view
    private var connectingView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(AppTheme.Colors.primary, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(vm.phase == .connecting ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: vm.phase)
            }
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(vm.phase == .connecting ? "Bağlanıyor..." : "Hazırlanıyor...")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(AppTheme.Colors.text)
                
                Text("Rakip ile el sıkışılıyor")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }

    // MARK: - Error view
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            Image(systemName: "xmark.circle").font(.system(size: 48)).foregroundStyle(AppTheme.Colors.error)
            Text(msg).font(AppTheme.Font.body()).foregroundStyle(AppTheme.Colors.textSecondary).multilineTextAlignment(.center)
            lobbyActionButton(title: "Tekrar Dene", icon: "arrow.clockwise", isPrimary: true) {
                vm.phase = .choosingRole
            }
            lobbyActionButton(title: "Ana Menü", icon: "house", isPrimary: false) {
                vm.cancel()
                dismiss()
            }
            Spacer()
        }
    }

    // MARK: - Reusable components

    private func statusHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.Colors.primary)
            Text(title)
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.text)
            Text(subtitle)
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.xl)
    }

    private func invitationCard(peer: MCPeerID) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.primary.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bağlantı İsteği")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text("\(peer.displayName)")
                        .font(AppTheme.Font.headline())
                        .foregroundStyle(AppTheme.Colors.text)
                }
                Spacer()
            }
            .padding(.bottom, 4)

            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: { vm.declineInvitation() }) {
                    Text("Reddet")
                        .font(AppTheme.Font.body())
                        .foregroundStyle(AppTheme.Colors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.error.opacity(0.1))
                        .cornerRadius(AppTheme.Radius.md)
                }
                .buttonStyle(.plain)

                Button(action: { vm.acceptInvitation() }) {
                    Text("Kabul Et")
                        .font(AppTheme.Font.body())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Radius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceHigh)
        .cornerRadius(AppTheme.Radius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private func peerRow(peer: MCPeerID, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.surfaceHigh)
                        .frame(width: 44, height: 44)
                    Image(systemName: "iphone")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(peer.displayName)
                        .font(AppTheme.Font.headline())
                        .foregroundStyle(AppTheme.Colors.text)
                    Text("Oyna")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textDisabled)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .stroke(AppTheme.Colors.border.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - New Components

    struct LobbyMainButton: View {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppTheme.Font.headline())
                            .foregroundStyle(AppTheme.Colors.text)
                        Text(subtitle)
                            .font(AppTheme.Font.caption())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textDisabled)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.Radius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(AppTheme.Colors.border.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func lobbyActionButton(title: String, icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(AppTheme.Font.headline())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(isPrimary ? AppTheme.Colors.primary : AppTheme.Colors.surface)
                .cornerRadius(AppTheme.Radius.lg)
        }
        .buttonStyle(.plain)
    }

    private func cancelButton(action: @escaping () -> Void) -> some View {
        Button("İptal", action: action)
            .font(AppTheme.Font.body())
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .padding(.bottom, AppTheme.Spacing.lg)
    }
}

// MARK: - Compatibility Modifiers
struct SymbolEffectModifier: ViewModifier {
    enum EffectType { case bounce, variableColor, pulse }
    let effect: EffectType
    
    @State private var animate = false

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            switch effect {
            case .bounce:
                content.symbolEffect(.bounce, options: .repeating)
            case .variableColor:
                content.symbolEffect(.variableColor.iterative, options: .repeating)
            case .pulse:
                content.symbolEffect(.pulse, options: .repeating)
            }
        } else {
            // iOS 16 fallback: simple opacity or scale animation
            content
                .opacity(animate ? 0.5 : 1.0)
                .scaleEffect(effect == .bounce && animate ? 1.1 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                }
        }
    }
}

#Preview {
    NavigationStack {
        NearbyLobbyView { _, _, _ in }
            .environmentObject(AppEnvironment())
    }
}
