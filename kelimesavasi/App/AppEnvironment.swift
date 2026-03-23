import Foundation
import Combine

final class AppEnvironment: ObservableObject {
    @Published var wordRepository: WordRepository
    @Published var gameEngine: WordleGameEngine
    @Published var settingsService: SettingsService
    @Published var statsService: StatsService
    @Published var multipeerService: MultipeerSessionManager
    @Published var discoveryService: NearbyDiscoveryService

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
