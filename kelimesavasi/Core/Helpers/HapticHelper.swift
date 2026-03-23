import UIKit

final class HapticHelper {
    static let shared = HapticHelper()
    private init() {}

    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    func keyPress() {
        lightImpact.impactOccurred(intensity: 0.7)
    }

    func submitGuess() {
        impact.impactOccurred()
    }

    func invalidWord() {
        notification.notificationOccurred(.warning)
    }

    func win() {
        notification.notificationOccurred(.success)
    }

    func lose() {
        notification.notificationOccurred(.error)
    }

    func select() {
        selection.selectionChanged()
    }
}
