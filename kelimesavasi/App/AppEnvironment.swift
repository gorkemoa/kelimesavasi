import Foundation
import Observation

@Observable
final class AppEnvironment {
    let wordRepository: WordRepository
    let gameEngine: WordleGameEngine
    let settingsService: SettingsService
    let statsService: StatsService
    let multipeerService: MultipeerSessionManager
    let discoveryService: NearbyDiscoveryService

    init() {
        let settings = SettingsService()
        let repo = WordRepository()
        self.settingsService   = settings
        self.wordRepository    = repo
        self.gameEngine        = WordleGameEngine(wordRepository: repo)
        self.statsService      = StatsService()
        self.multipeerService  = MultipeerSessionManager(playerName: settings.playerName)
        self.discoveryService  = NearbyDiscoveryService()
    }
}
