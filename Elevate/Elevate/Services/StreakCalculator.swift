import Foundation

/// Counts consecutive calendar days (starting from today going backwards) where
/// the total steps from `sessions` met or exceeded `goal`.
/// Today counts only if its step total already meets the goal.
func calculateStreak(from sessions: [ClimbSession], goal: Int) -> Int {
    guard goal > 0 else { return 0 }
    let calendar = Calendar.current
    var streak = 0
    var checkDate = calendar.startOfDay(for: Date())
    while true {
        guard let end = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
        let daySteps = sessions.filter {
            $0.startDate >= checkDate && $0.startDate < end
        }.reduce(0) { $0 + $1.steps }
        if daySteps >= goal {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        } else {
            break
        }
    }
    return streak
}
