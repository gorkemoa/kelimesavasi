import SwiftUI
import MultipeerConnectivity

// MARK: - NearbyLobbyView (thin wrapper — passes services to the inner view that owns the VM)
struct NearbyLobbyView: View {
    var onGameReady: (String?, GameConfig, Bool) -> Void
    @EnvironmentObject var env: AppEnvironment

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
            lobbyContent
        }
        .onDisappear { vm.cancelIfNeeded() }
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
        .padding(.top, AppTheme.Spacing.lg)
    }

    // MARK: - Role chooser
    private var roleChooser: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.Colors.primary)
                Text("Yakın Düello")
                    .font(AppTheme.Font.title())
                    .foregroundStyle(AppTheme.Colors.text)
                Text("Aynı Wi-Fi veya Bluetooth ağında\nbir arkadaşınla oyna")
                    .font(AppTheme.Font.body(14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppTheme.Spacing.xl)

            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
                lobbyActionButton(title: "Oyun Kur", icon: "crown", isPrimary: true) {
                    vm.startHosting()
                }
                lobbyActionButton(title: "Oyuna Katıl", icon: "arrow.right.circle", isPrimary: false) {
                    vm.startJoining()
                }
            }

            Spacer()
        }
    }

    // MARK: - Hosting view
    private var hostingView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            statusHeader(icon: "wifi", title: "Oyun kuruldu", subtitle: "Yakındaki oyuncuları bekliyorsunuz…")

            if let peer = vm.pendingInviteFrom {
                invitationCard(peer: peer)
            }

            Spacer()
            cancelButton { vm.cancel(); dismiss() }
        }
    }

    // MARK: - Joining view
    private var joiningView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            statusHeader(icon: "magnifyingglass", title: "Oyunlar aranıyor…", subtitle: "Çevredeki oyun odaları listeleniyor")

            if vm.discoveredPeers.isEmpty {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ProgressView()
                        .tint(AppTheme.Colors.primary)
                        .scaleEffect(1.4)
                    Text("Yakın cihazlar bekleniyor…")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .surfaceStyle()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.discoveredPeers, id: \.displayName) { peer in
                            peerRow(peer: peer) { vm.invitePeer(peer) }
                        }
                    }
                }
            }

            Spacer()
            cancelButton { vm.cancel(); dismiss() }
        }
    }

    // MARK: - Connecting view
    private var connectingView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            ProgressView()
                .tint(AppTheme.Colors.primary)
                .scaleEffect(1.8)
            Text(vm.phase.description)
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.text)
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
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("\(peer.displayName) katılmak istiyor")
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.text)

            HStack(spacing: AppTheme.Spacing.md) {
                Button("Reddet") { vm.declineInvitation() }
                    .font(AppTheme.Font.body())
                    .foregroundStyle(AppTheme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .surfaceStyle()
                    .buttonStyle(.plain)

                Button("Kabul Et") { vm.acceptInvitation() }
                    .font(AppTheme.Font.body())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.Radius.lg)
                    .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.md)
        .surfaceStyle(elevated: true)
    }

    private func peerRow(peer: MCPeerID, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(peer.displayName)
                    .font(AppTheme.Font.body())
                    .foregroundStyle(AppTheme.Colors.text)
                Spacer()
                Text("Katıl")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .padding(AppTheme.Spacing.md)
            .surfaceStyle()
        }
        .buttonStyle(.plain)
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

#Preview {
    NavigationStack {
        NearbyLobbyView { _, _, _ in }
            .environmentObject(AppEnvironment())
    }
}
