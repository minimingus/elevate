import Foundation
import Combine

struct AchievementDisplay: Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let isUnlocked: Bool
    let progress: String?
}

private let achievementEmojis: [String: String] = [
    "first_climb": "🏅",
    "century":     "🏆",
    "floor_10":    "🏙️",
    "streak_3":    "✨",
    "streak_7":    "🔥",
    "lifetime_1k": "⭐",
]

@MainActor
final class AchievementViewModel: ObservableObject {
    @Published private(set) var achievements: [AchievementDisplay] = []

    private let achievementRepo: AchievementRepository
    private let sessionRepo: SessionRepository

    init(achievementRepo: AchievementRepository, sessionRepo: SessionRepository) {
        self.achievementRepo = achievementRepo
        self.sessionRepo = sessionRepo
    }

    func load() {
        let all = (try? achievementRepo.fetchAll()) ?? []
        let sessions = (try? sessionRepo.fetchAll()) ?? []
        let lifetimeSteps = sessions.reduce(0) { $0 + $1.steps }
        let streak = computeStreak(from: sessions)

        achievements = AchievementRepository.defaults.map { def in
            let model = all.first(where: { $0.id == def.id })
            let isUnlocked = model?.unlockedDate != nil
            let progress = isUnlocked ? nil :
                achievementRepo.progress(for: def.id, lifetimeSteps: lifetimeSteps,
                                         currentStreak: streak, sessions: sessions)
            return AchievementDisplay(
                id: def.id, name: def.name, description: def.desc,
                emoji: achievementEmojis[def.id] ?? "🎖️",
                isUnlocked: isUnlocked, progress: progress
            )
        }
    }

    private func computeStreak(from sessions: [ClimbSession]) -> Int {
        calculateStreak(from: sessions, goal: UserDefaults.standard.dailyStepGoal)
    }
}
