import UIKit

enum HapticService {
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func scorePoint() {
        medium.impactOccurred()
    }

    static func gameWon() {
        heavy.impactOccurred(intensity: 0.7)
    }

    static func matchOver() {
        notification.notificationOccurred(.success)
    }

    static func undo() {
        light.impactOccurred()
    }

    static func settingChanged() {
        selection.selectionChanged()
    }

    static func recordToggle() {
        medium.impactOccurred(intensity: 0.6)
    }

    static func buttonPress() {
        light.impactOccurred(intensity: 0.5)
    }
}
