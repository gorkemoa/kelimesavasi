import Foundation
import Observation

@Observable
final class StatsService {
    private(set) var stats: LocalStats
    private let storage: StatsStorage

    init(storage: StatsStorage = StatsStorage()) {
        self.storage = storage
        self.stats = storage.load()
    }

    func record(result: GameResult) {
        if result.mode == .solo {
            stats.soloPracticeGames += 1
            if result.iWon {
                stats.soloWins += 1
                stats.coins += 10
            }
        } else {
            stats.totalGames += 1
            if result.iWon {
                stats.wins += 1
                stats.currentStreak += 1
                stats.maxStreak = max(stats.maxStreak, stats.currentStreak)
                stats.coins += 25
            } else if result.isDraw {
                stats.draws += 1
                stats.currentStreak = 0
                stats.coins += 5
            } else {
                stats.losses += 1
                stats.currentStreak = 0
            }
        }

        let guessCount = result.myPerformance.guessCount
        if guessCount > 0 {
            stats.guessDistribution[guessCount, default: 0] += 1
        }

        storage.save(stats)
    }

    func spendCoins(_ amount: Int) -> Bool {
        guard stats.coins >= amount else { return false }
        stats.coins -= amount
        storage.save(stats)
        return true
    }

    func reset() {
        stats = .empty
        storage.save(stats)
    }
}
