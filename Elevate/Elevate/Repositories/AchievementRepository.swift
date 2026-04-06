import Foundation
import SwiftData

@MainActor
final class AchievementRepository {
    private let modelContext: ModelContext

    static let defaults: [(id: String, name: String, desc: String)] = [
        ("first_climb",  "First Steps",   "Complete your first session"),
        ("century",      "Century Club",  "100+ steps in one session"),
        ("floor_10",     "High Rise",     "10+ floors in one session"),
        ("streak_3",     "Consistent",    "3-day streak"),
        ("streak_7",     "On Fire",       "7-day streak"),
        ("lifetime_1k",  "Stairmaster",   "1,000 lifetime steps"),
    ]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedIfNeeded()
    }

    private func seedIfNeeded() {
        let existing = (try? fetchAll()) ?? []
        let existingIds = Set(existing.map(\.id))
        for def in Self.defaults where !existingIds.contains(def.id) {
            modelContext.insert(Achievement(id: def.id, name: def.name,
                                            achievementDescription: def.desc))
        }
        do {
            try modelContext.save()
        } catch {
            assertionFailure("AchievementRepository: failed to seed defaults: \(error)")
        }
    }

    func fetchAll() throws -> [Achievement] {
        // Sorted by id for stable display order.
        let descriptor = FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.id)])
        return try modelContext.fetch(descriptor)
    }

    func unlock(ids: Set<String>) throws {
        let all = try fetchAll()
        let now = Date()
        for achievement in all where ids.contains(achievement.id) && achievement.unlockedDate == nil {
            achievement.unlockedDate = now
        }
        try modelContext.save()
    }

    func progress(for id: String, lifetimeSteps: Int, currentStreak: Int, sessions: [ClimbSession]) -> String? {
        switch id {
        case "century":
            let best = sessions.map(\.steps).max() ?? 0
            return "\(best)/100 steps"
        case "floor_10":
            let best = sessions.map(\.floors).max() ?? 0
            return "\(best)/10 floors"
        case "streak_3": return "\(currentStreak)/3 days"
        case "streak_7": return "\(currentStreak)/7 days"
        case "lifetime_1k": return "\(lifetimeSteps)/1,000 steps"
        default: return nil
        }
    }
}
