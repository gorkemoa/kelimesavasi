import Foundation
import MultipeerConnectivity
import Observation

// MARK: - Connection State
enum ConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
}

// MARK: - MultipeerSessionManager
@Observable
final class MultipeerSessionManager: NSObject {

    // Observed state
    var connectedPeers: [MCPeerID] = []
    var connectionState: ConnectionState = .disconnected
    var lastError: String?

    // Internal (not observed but updated on MainActor)
    var messageHandler: ((PeerMessage) -> Void)?

    private(set) var session: MCSession?
    private(set) var myPeerID: MCPeerID

    init(playerName: String) {
        myPeerID = MCPeerID(displayName: playerName)
        super.init()
        createSession()
    }

    func updatePlayerName(_ name: String) {
        myPeerID = MCPeerID(displayName: name)
        session?.disconnect()
        createSession()
    }

    private func createSession() {
        let s = MCSession(peer: myPeerID,
                          securityIdentity: nil,
                          encryptionPreference: .required)
        s.delegate = self
        session = s
    }

    // MARK: - Sending

    func send(_ message: PeerMessage) throws {
        guard let session, !session.connectedPeers.isEmpty else { return }
        let data = try JSONEncoder().encode(message)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    func disconnect() {
        session?.disconnect()
        connectedPeers.removeAll()
        connectionState = .disconnected
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
            return  // invalid payload – ignore silently
        }
        Task { @MainActor [weak self] in
            self?.messageHandler?(message)
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
