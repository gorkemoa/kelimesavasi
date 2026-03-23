import Foundation
import Combine

final class SettingsService: ObservableObject {
    @Published var playerName: String {
        didSet { UserDefaults.standard.set(playerName, forKey: AppConstants.settingsPlayerNameKey) }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: AppConstants.settingsSoundKey) }
    }
    @Published var hapticEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticEnabled, forKey: AppConstants.settingsHapticKey) }
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
