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
    private let sessionManager: MultipeerSessionManager
    private let discoveryService: NearbyDiscoveryService
    private let settings: SettingsService
    private let wordRepository: WordRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // Host handshake state
    private var pendingTargetWord: String?
    private var receivedPlayerReady = false

    // Guest handshake state
    private var playerReadyTask: Task<Void, Never>?

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
                    guard !gameStarted else { return }
                    handleConnected(isHost: isHost)
                case .disconnected:
                    playerReadyTask?.cancel()
                    playerReadyTask = nil
                    if gameStarted {
                        // User exited the game — reset lobby to initial state
                        gameStarted = false
                        phase = .choosingRole
                    } else {
                        let activePhase = phase == .hosting || phase == .joining ||
                                          phase == .connecting || phase == .waitingForStart
                        if activePhase {
                            phase = .error("Bağlantı kesildi. Lütfen tekrar deneyin.")
                        }
                    }
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
        receivedPlayerReady = false
        pendingTargetWord = nil
        phase = .hosting
        sessionManager.updatePlayerName(settings.playerName)
        discoveryService.startAdvertising(peer: sessionManager.myPeerID)
    }

    // MARK: - Guest flow

    func startJoining() {
        isHost = false
        gameStarted = false
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
        playerReadyTask?.cancel()
        playerReadyTask = nil
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
            // Guest receives game start from host
            guard let payload = try? message.decode(GameStartedPayload.self) else { return }
            playerReadyTask?.cancel()
            playerReadyTask = nil
            gameStarted = true
            onGameReady?(payload.targetWord, payload.config, false)

        case .playerReady:
            // Host receives ready signal from guest — MC channels are proven open
            receivedPlayerReady = true
            if pendingTargetWord != nil {
                triggerGameStart()
            }
            // else: word not yet picked, triggerGameStart() will be called from pickTargetWord()

        case .rematchRequest:
            // Forward to game VM if active
            NotificationCenter.default.post(name: NSNotification.Name("PeerRematchRequested"), object: nil)
        case .rematchAccepted:
            NotificationCenter.default.post(name: NSNotification.Name("RestartGame"), object: nil)
            if isHost {
                gameStarted = false
                receivedPlayerReady = false
                pendingTargetWord = nil
                pickTargetWord()
            } else {
                gameStarted = false
                startSendingPlayerReady()
            }
        default:
            break
        }
    }

    // MARK: - Host handshake

    func handleConnected(isHost: Bool) {
        if isHost {
            discoveryService.stopAll()
            phase = .connecting  // keep spinner while waiting for guest's playerReady
            receivedPlayerReady = false
            pendingTargetWord = nil
            pickTargetWord()
        } else {
            discoveryService.stopAll()
            phase = .waitingForStart
            startSendingPlayerReady()
        }
    }

    private func pickTargetWord() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let word = (try? await wordRepository.randomTargetWord(length: GameConfig.default.wordLength)) ?? "kitap"
            pendingTargetWord = word
            // If playerReady already arrived before word was picked, start now
            if receivedPlayerReady, !gameStarted {
                triggerGameStart()
            }
        }
    }

    private func triggerGameStart() {
        guard let word = pendingTargetWord, !gameStarted else { return }
        gameStarted = true
        // Send gameStarted to guest — MC channels are proven open at this point
        let payload = GameStartedPayload(
            config: .default,
            targetWord: word,
            hostID: settings.playerName,
            hostName: settings.playerName
        )
        try? sessionManager.send(try PeerMessage.make(payload, type: .gameStarted))
        onGameReady?(word, .default, true)
    }

    // MARK: - Guest handshake

    private func startSendingPlayerReady() {
        playerReadyTask?.cancel()
        playerReadyTask = Task { [weak self] in
            // Wait 1s for MC channels to stabilise before first send
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // Send every 600ms for up to ~20 seconds
            for attempt in 0..<34 {
                guard let self, !gameStarted else { return }
                try? self.sessionManager.send(PeerMessage(type: .playerReady, payload: Data()))
                try? await Task.sleep(nanoseconds: 600_000_000)

                // After 10s with no response, show timeout error
                if attempt == 16 {
                    await MainActor.run { [weak self] in
                        guard let self, !gameStarted, phase == .waitingForStart else { return }
                        phase = .error("Oyun başlatılamadı. Tekrar deneyin.")
                    }
                    return
                }
            }
        }
    }
}
