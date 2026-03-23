import Foundation
import Observation

@Observable
final class SettingsService {
    var playerName: String {
        didSet { defaults.set(playerName, forKey: AppConstants.settingsPlayerNameKey) }
    }
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: AppConstants.settingsSoundKey) }
    }
    var hapticEnabled: Bool {
        didSet { defaults.set(hapticEnabled, forKey: AppConstants.settingsHapticKey) }
    }

    private let defaults = UserDefaults.standard

    init() {
        let name = UserDefaults.standard.string(forKey: AppConstants.settingsPlayerNameKey)
        playerName  = name?.isEmpty == false ? name! : "Oyuncu"
        soundEnabled  = UserDefaults.standard.object(forKey: AppConstants.settingsSoundKey) as? Bool ?? true
        hapticEnabled = UserDefaults.standard.object(forKey: AppConstants.settingsHapticKey) as? Bool ?? true
    }

    func resetToDefaults() {
        playerName    = "Oyuncu"
        soundEnabled  = true
        hapticEnabled = true
    }
}
