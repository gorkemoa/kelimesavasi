import Foundation

enum AppConstants {
    static let defaultWordLength = 5
    static let defaultMaxGuesses = 6
    static let multipeerServiceType = "nwd-game"
    static let wordFileName = "kelimeler"
    static let wordFileExtension = "txt"
    static let statsStorageKey = "nwd_local_stats"
    static let settingsPlayerNameKey = "nwd_player_name"
    static let settingsSoundKey = "nwd_sound_enabled"
    static let settingsHapticKey = "nwd_haptic_enabled"
    static let rematchTimeoutSeconds: TimeInterval = 30
    static let guessAnimationDuration: Double = 0.35
    static let flipAnimationDelay: Double = 0.1
}
