import UIKit

enum HapticService {
    static func step() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func goalReached() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func sessionStart() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    static func sessionStop() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    static func achievementUnlocked() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}
