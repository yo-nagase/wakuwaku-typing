import UIKit

@MainActor
enum Haptics {
    static var enabled = true

    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        guard enabled else { return }
        lightImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    static func tap() {
        guard enabled else { return }
        lightImpact.impactOccurred()
    }

    static func wrong() {
        guard enabled else { return }
        notification.notificationOccurred(.error)
    }

    static func success() {
        guard enabled else { return }
        heavyImpact.impactOccurred()
    }
}
