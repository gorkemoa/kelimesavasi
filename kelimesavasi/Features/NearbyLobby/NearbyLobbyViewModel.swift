import Foundation
import Observation
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
@Observable
final class NearbyLobbyViewModel {

    var phase: LobbyPhase = .choosingRole
    var discoveredPeers: [MCPeerID] = []
    var pendingInviteFrom: MCPeerID?
    private(set) var isHost = false
    private var gameStarted = false

    private let sessionManager: MultipeerSessionManager
    private let discoveryService: NearbyDiscoveryService
    private let settings: SettingsService

    var onGameReady: ((String?, GameConfig, Bool) -> Void)?  // (targetWord, config, isHost)

    init(sessionManager: MultipeerSessionManager,
         discoveryService: NearbyDiscoveryService,
         settings: SettingsService) {
        self.sessionManager  = sessionManager
        self.discoveryService = discoveryService
        self.settings        = settings
        subscribeToMessages()
    }

    // MARK: - Host flow

    func startHosting() {
        isHost = true
        phase = .hosting
        sessionManager.updatePlayerName(settings.playerName)
        discoveryService.startAdvertising(peer: sessionManager.myPeerID)
    }

    // MARK: - Guest flow

    func startJoining() {
        isHost = false
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
        discoveryService.stopAll()
        sessionManager.disconnect()
        phase = .choosingRole
    }

    // MARK: - Peer messages

    private func subscribeToMessages() {
        sessionManager.messageHandler = { [weak self] message in
            self?.handleMessage(message)
        }
    }

    private func handleMessage(_ message: PeerMessage) {
        switch message.type {
        case .gameStarted:
            guard let payload = try? message.decode(GameStartedPayload.self) else { return }
            discoveryService.stopAll()
            gameStarted = true
            onGameReady?(payload.targetWord, payload.config, false)

        default:
            break
        }
    }

    // Called when connection state becomes .connected (observed by the view)
    func handleConnected(isHost: Bool) {
        if isHost {
            discoveryService.stopAll()
            gameStarted = true
            onGameReady?(nil, .default, true)  // Host picks target word in GameView
        } else {
            phase = .waitingForStart
        }
    }
}
