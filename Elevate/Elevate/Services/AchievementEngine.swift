import Foundation

enum AchievementEngine {
    /// Returns IDs of achievements unlocked by this session.
    /// Caller is responsible for filtering out already-unlocked achievements before acting.
    static func evaluate(
        session: ClimbSession,
        allSessions: [ClimbSession],
        currentStreak: Int,
        lifetimeSteps: Int
    ) -> Set<String> {
        var unlocked = Set<String>()

        if allSessions.count == 1 {
            unlocked.insert("first_climb")
        }
        if session.steps >= 100 {
            unlocked.insert("century")
        }
        if session.floors >= 10 {
            unlocked.insert("floor_10")
        }
        if currentStreak >= 3 {
            unlocked.insert("streak_3")
        }
        if currentStreak >= 7 {
            unlocked.insert("streak_7")
        }
        if lifetimeSteps >= 1000 {
            unlocked.insert("lifetime_1k")
        }
        return unlocked
    }
}
