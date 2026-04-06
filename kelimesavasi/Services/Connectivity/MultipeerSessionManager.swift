import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Connection State
enum ConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
}

// MARK: - MultipeerSessionManager
final class MultipeerSessionManager: NSObject, ObservableObject {

    // Observed state
    @Published var connectedPeers: [MCPeerID] = []
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?

    /// All received peer messages are published here.
    /// Any number of ViewModels can subscribe without overwriting each other.
    let incomingMessages = PassthroughSubject<PeerMessage, Never>()

    @Published private(set) var session: MCSession?
    @Published private(set) var myPeerID: MCPeerID

    init(playerName: String) {
        myPeerID = MCPeerID(displayName: playerName)
        super.init()
        createSession()
    }

    func updatePlayerName(_ name: String) {
        if myPeerID.displayName != name {
            myPeerID = MCPeerID(displayName: name)
        }
        createSession()
    }

    private func createSession() {
        if let old = session {
            old.delegate = nil
            old.disconnect()
        }
        let s = MCSession(peer: myPeerID,
                          securityIdentity: nil,
                          encryptionPreference: .none)
        s.delegate = self
        session = s
        connectedPeers.removeAll()
        connectionState = .disconnected
    }

    // MARK: - Sending

    func send(_ message: PeerMessage) throws {
        guard let session, !session.connectedPeers.isEmpty else {
            throw NSError(domain: "MultipeerSessionManager", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Not connected to any peers"])
        }
        let data = try JSONEncoder().encode(message)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    func disconnect() {
        connectedPeers.removeAll()
        connectionState = .disconnected
        session?.delegate = nil
        session?.disconnect()
        let s = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        s.delegate = self
        session = s
    }

    @discardableResult
    func trySend(_ message: PeerMessage) -> Bool {
        guard let session, !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(message) else { return false }
        return (try? session.send(data, toPeers: session.connectedPeers, with: .reliable)) != nil
    }
}

// MARK: - MCSessionDelegate (nonisolated — called on background threads by framework)
extension MultipeerSessionManager: MCSessionDelegate {

    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID,
                             didChange state: MCSessionState) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch state {
            case .connected:
                if !connectedPeers.contains(peerID) { connectedPeers.append(peerID) }
                connectionState = .connected
                lastError = nil
            case .connecting:
                connectionState = .connecting
            case .notConnected:
                connectedPeers.removeAll { $0 == peerID }
                connectionState = connectedPeers.isEmpty ? .disconnected : .connected
            @unknown default: break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data,
                             fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(PeerMessage.self, from: data) else {
            return
        }
        Task { @MainActor [weak self] in
            self?.incomingMessages.send(message)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream,
                             withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession,
                             didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}

    nonisolated func session(_ session: MCSession,
                             didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID,
                             at localURL: URL?, withError error: Error?) {}
}
