import Foundation
import MultipeerConnectivity
import Observation

// MARK: - NearbyDiscoveryService
@Observable
final class NearbyDiscoveryService: NSObject {

    var discoveredPeers: [MCPeerID] = []
    var pendingInviteFrom: MCPeerID?
    var lastError: String?

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // Set by NearbyLobbyViewModel to handle incoming invitations
    var invitationResponseHandler: ((Bool, MCSession?) -> Void)?

    // MARK: - Host side

    func startAdvertising(peer: MCPeerID) {
        stopAll()
        let adv = MCNearbyServiceAdvertiser(
            peer: peer,
            discoveryInfo: ["v": "1"],
            serviceType: AppConstants.multipeerServiceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv
    }

    // MARK: - Guest side

    func startBrowsing(peer: MCPeerID) {
        stopAll()
        let br = MCNearbyServiceBrowser(peer: peer,
                                        serviceType: AppConstants.multipeerServiceType)
        br.delegate = self
        br.startBrowsingForPeers()
        browser = br
    }

    func invitePeer(_ peerID: MCPeerID, to session: MCSession) {
        browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    // MARK: - Common

    func stopAll() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        discoveredPeers.removeAll()
    }

    func acceptPendingInvitation(session: MCSession?) {
        invitationResponseHandler?(true, session)
        invitationResponseHandler = nil
        pendingInviteFrom = nil
    }

    func declinePendingInvitation() {
        invitationResponseHandler?(false, nil)
        invitationResponseHandler = nil
        pendingInviteFrom = nil
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NearbyDiscoveryService: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor [weak self] in
            self?.pendingInviteFrom = peerID
            self?.invitationResponseHandler = invitationHandler
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor [weak self] in
            self?.lastError = error.localizedDescription
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NearbyDiscoveryService: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor [weak self] in
            guard let self, !discoveredPeers.contains(peerID) else { return }
            discoveredPeers.append(peerID)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor [weak self] in
            self?.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor [weak self] in
            self?.lastError = error.localizedDescription
        }
    }
}
