import Foundation
import Combine
import MultipeerConnectivity

// MARK: - Lobby Phase
enum LobbyPhase: Equatable {
    case choosingRole
    case hosting
    case joining
    case connecting
    case waitingForStart   // guest waiting for host to send game start
    case error(String)

    var description: String {
        switch self {
        case .choosingRole:   return "Rol seç"
        case .hosting:        return "Oyun kuruluyor…"
        case .joining:        return "Oyunlar aranıyor…"
        case .connecting:     return "Bağlanıyor…"
        case .waitingForStart: return "Host oyunu başlatıyor…"
        case .error(let msg): return msg
        }
    }
}

// MARK: - NearbyLobbyViewModel
final class NearbyLobbyViewModel: ObservableObject {

    @Published var phase: LobbyPhase = .choosingRole
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var pendingInviteFrom: MCPeerID?
    @Published private(set) var isHost = false

    private var gameStarted = false
    /// Tracks if onGameReady has been called to prevent multiple navigations in one session.
    private var didNavigateToGame = false
    /// Prevents handleConnected from being triggered more than once per physical connection.
    /// MC can fire .connected multiple times; this flag stops duplicate handshake starts.
    private var handshakeStarted = false
    private let sessionManager: MultipeerSessionManager
    private let discoveryService: NearbyDiscoveryService
    private let settings: SettingsService
    private let wordRepository: WordRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Watchdog task that times out the guest if gameStarted is never received.
    private var guestWatchdogTask: Task<Void, Never>?

    var onGameReady: ((String?, GameConfig, Bool) -> Void)?  // (targetWord, config, isHost)

    init(sessionManager: MultipeerSessionManager,
         discoveryService: NearbyDiscoveryService,
         settings: SettingsService,
         wordRepository: WordRepositoryProtocol) {
        self.sessionManager  = sessionManager
        self.discoveryService = discoveryService
        self.settings        = settings
        self.wordRepository  = wordRepository
        subscribeToMessages()
        subscribeToServices()
    }

    // MARK: - Service observation

    private func subscribeToServices() {
        // Connection state — handle connect, drop, and never-connected cases
        sessionManager.$connectionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .connected:
                    // Guard against duplicate .connected events for the same connection.
                    // MC can fire .connected multiple times; without this guard,
                    // handshake state (receivedPlayerReady, pendingTargetWord) gets reset mid-flow.
                    guard !gameStarted, !handshakeStarted else { return }
                    handshakeStarted = true
                    handleConnected(isHost: isHost)
                case .disconnected:
                    // Capture before resetting — if handshakeStarted is false this is a
                    // phantom cleanup event (from session recreation) — do NOT show error.
                    let wasHandshaking = handshakeStarted
                    handshakeStarted = false
                    guestWatchdogTask?.cancel()
                    guestWatchdogTask = nil
                    
                    if gameStarted {
                        // We are already in or transitioning to a game. 
                        // Do NOT reset gameStarted or phase here, as MC can bounce connections 
                        // during handshake. If the connection is truly lost, the GameViewModel 
                        // or the user dismissing the view will handle it.
                        // Resetting here while the Host's retry loop is active causes 
                        // the "repeated navigation" bug.
                    } else if wasHandshaking {
                        let activePhase = phase == .hosting || phase == .joining ||
                                          phase == .connecting || phase == .waitingForStart
                        if activePhase {
                            phase = .error("Bağlantı kesildi. Lütfen tekrar deneyin.")
                        }
                    }
                    // else: phantom disconnect from cleanup — ignore silently
                default:
                    break
                }
            }
            .store(in: &cancellables)

        discoveryService.$discoveredPeers
            .receive(on: RunLoop.main)
            .sink { [weak self] peers in self?.discoveredPeers = peers }
            .store(in: &cancellables)

        discoveryService.$pendingInviteFrom
            .receive(on: RunLoop.main)
            .sink { [weak self] invite in self?.pendingInviteFrom = invite }
            .store(in: &cancellables)
    }

    // MARK: - Host flow

    func startHosting() {
        isHost = true
        gameStarted = false
        didNavigateToGame = false
        handshakeStarted = false
        phase = .hosting
        sessionManager.updatePlayerName(settings.playerName)
        discoveryService.startAdvertising(peer: sessionManager.myPeerID)
    }

    // MARK: - Guest flow

    func startJoining() {
        isHost = false
        gameStarted = false
        didNavigateToGame = false
        handshakeStarted = false
        phase = .joining
        sessionManager.updatePlayerName(settings.playerName)
        discoveryService.startBrowsing(peer: sessionManager.myPeerID)
    }

    func invitePeer(_ peer: MCPeerID) {
        guard let session = sessionManager.session else { return }
        phase = .connecting
        discoveryService.invitePeer(peer, to: session)
    }

    // MARK: - Invitation handling (host receives invite from guest)

    func acceptInvitation() {
        discoveryService.acceptPendingInvitation(session: sessionManager.session)
        phase = .connecting
    }

    func declineInvitation() {
        discoveryService.declinePendingInvitation()
        phase = .hosting
    }

    // MARK: - Cancel

    func cancelIfNeeded() {
        guard !gameStarted else { return }
        cancel()
    }

    func cancel() {
        guestWatchdogTask?.cancel()
        guestWatchdogTask = nil
        handshakeStarted = false
        gameStarted = false
        didNavigateToGame = false
        discoveryService.stopAll()
        sessionManager.disconnect()
        phase = .choosingRole
    }

    // MARK: - Peer messages

    private func subscribeToMessages() {
        sessionManager.incomingMessages
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                self?.handleMessage(message)
            }
            .store(in: &cancellables)
    }

    private func handleMessage(_ message: PeerMessage) {
        switch message.type {
        case .gameStarted:
            // Guest receives game start from host.
            guard !gameStarted,
                  let payload = try? message.decode(GameStartedPayload.self) else { return }
            guestWatchdogTask?.cancel()
            guestWatchdogTask = nil
            gameStarted = true
            phase = .connecting
            
            if !didNavigateToGame {
                didNavigateToGame = true
                onGameReady?(payload.targetWord, payload.config, false)
            }

        case .rematchRequest:
            NotificationCenter.default.post(name: NSNotification.Name("PeerRematchRequested"), object: nil)

        case .rematchAccepted:
            NotificationCenter.default.post(name: NSNotification.Name("RestartGame"), object: nil)
            Task { @MainActor [weak self] in
                guard let self else { return }
                gameStarted = false
                didNavigateToGame = false
                handshakeStarted = true  // session still connected — skip re-trigger from subscriber
                // Allow the game screen to dismiss before restarting handshake
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if isHost {
                    phase = .connecting
                    pickTargetWordAndStart()
                } else {
                    phase = .waitingForStart
                    startGuestWatchdog()
                }
            }

        default:
            break
        }
    }

    // MARK: - Handshake

    func handleConnected(isHost: Bool) {
        discoveryService.stopAll()
        if isHost {
            phase = .connecting
            pickTargetWordAndStart()
        } else {
            phase = .waitingForStart
            startGuestWatchdog()
        }
    }

    // MARK: - Host: pick word and broadcast gameStarted for up to 30 seconds
    //
    // DESIGN NOTE: We do NOT use a playerReady → gameStarted round-trip.
    // The old design broke because GameViewModel.subscribeToMessages() overwrites
    // sessionManager.messageHandler when the host navigates to GameView, so any
    // subsequent playerReady messages from the guest are silently discarded.
    //
    // Instead, the host starts an independent Task.detached that keeps sending
    // gameStarted for 30 s. This task is completely decoupled from messageHandler,
    // so it survives the GameViewModel overwrite and delivers the message once
    // MC's data channels finish negotiating (which can take 5–15 s).

    private func pickTargetWordAndStart() {
        Task { @MainActor [weak self] in
            guard let self, !gameStarted else { return }
            let word = (try? await wordRepository.randomTargetWord(length: GameConfig.default.wordLength)) ?? "kitap"
            guard !gameStarted else { return }  // re-check after async gap
            gameStarted = true

            guard let msg = try? PeerMessage.make(
                GameStartedPayload(config: .default, targetWord: word,
                                   hostID: settings.playerName, hostName: settings.playerName),
                type: .gameStarted
            ) else { return }

            // Navigate host to game immediately.
            if !didNavigateToGame {
                didNavigateToGame = true
                onGameReady?(word, .default, true)
            }

            // Keep sending gameStarted in a fire-and-forget background task.
            // Task.detached is intentional: we want this to outlive the LobbyViewModel
            // and continue even after GameViewModel replaces the messageHandler.
            // 60 attempts × 500 ms = 30 seconds of retrying.
            let mgr = sessionManager
            Task.detached(priority: .high) {
                for _ in 0..<60 {
                    mgr.trySend(msg)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
    }

    // MARK: - Guest: wait passively for gameStarted with a 40-second timeout

    private func startGuestWatchdog() {
        guestWatchdogTask?.cancel()
        guestWatchdogTask = Task { [weak self] in
            // 40 seconds — enough for even the slowest MC channel negotiation
            try? await Task.sleep(nanoseconds: 40_000_000_000)
            await MainActor.run { [weak self] in
                guard let self, !gameStarted, phase == .waitingForStart else { return }
                phase = .error("Oyun başlatılamadı. Tekrar deneyin.")
            }
        }
    }
}
