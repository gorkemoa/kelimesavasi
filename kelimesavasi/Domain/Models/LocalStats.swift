import Foundation

struct LocalStats: Codable, Sendable {
    var totalGames: Int
    var wins: Int
    var losses: Int
    var draws: Int
    var soloPracticeGames: Int
    var soloWins: Int
    var currentStreak: Int
    var maxStreak: Int
    var currentLevel: Int
    var coins: Int
    var guessDistribution: [Int: Int]  // guessCount → frequency

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(wins) / Double(totalGames)
    }

    var averageGuesses: Double {
        let total = guessDistribution.reduce(0) { $0 + $1.key * $1.value }
        let count = guessDistribution.values.reduce(0, +)
        guard count > 0 else { return 0 }
        return Double(total) / Double(count)
    }

    static let empty = LocalStats(
        totalGames: 0, wins: 0, losses: 0, draws: 0,
        soloPracticeGames: 0, soloWins: 0,
        currentStreak: 0, maxStreak: 0, currentLevel: 1, coins: 0, guessDistribution: [:]
    )
}
