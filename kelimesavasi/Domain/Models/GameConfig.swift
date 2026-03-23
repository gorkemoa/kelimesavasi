import Foundation

struct GameConfig: Codable, Hashable, Sendable {
    var wordLength: Int
    var maxGuesses: Int

    static let `default` = GameConfig(
        wordLength: AppConstants.defaultWordLength,
        maxGuesses: AppConstants.defaultMaxGuesses
    )
}
