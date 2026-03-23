import Foundation

final class StatsStorage {
    private let defaults = UserDefaults.standard
    private let key = AppConstants.statsStorageKey

    func load() -> LocalStats {
        guard let data = defaults.data(forKey: key),
              let stats = try? JSONDecoder().decode(LocalStats.self, from: data) else {
            return .empty
        }
        return stats
    }

    func save(_ stats: LocalStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: key)
    }
}
