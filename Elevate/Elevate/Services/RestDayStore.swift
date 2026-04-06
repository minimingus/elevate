import Foundation

/// Lightweight UserDefaults-backed store for rest days.
/// A rest day preserves a streak without requiring a step goal to be met.
/// Limit: 1 rest day per calendar week.
struct RestDayStore {
    private static let key = "restDayDates"
    private static let fmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    static var all: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: key) }
    }

    static func isRestDay(_ date: Date) -> Bool {
        all.contains(dayKey(date))
    }

    static func markToday() {
        var days = all
        days.insert(dayKey(Date()))
        all = days
    }

    /// True if the user can still mark today as a rest day (not already marked, and no other rest day this week).
    static func canMarkRestDayToday() -> Bool {
        guard !isRestDay(Date()) else { return false }
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let startOfWeek = calendar.date(from: comps) else { return false }
        let thisWeekCount = all.filter { str in
            guard let date = fmt.date(from: str) else { return false }
            return date >= startOfWeek
        }.count
        return thisWeekCount == 0
    }

    /// Returns the set of day offsets (0 = today, 1 = yesterday…) that are rest days, for the weekly chart.
    static func restDayIndices(for days: Int = 7) -> Set<Int> {
        var indices = Set<Int>()
        let calendar = Calendar.current
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            if isRestDay(date) { indices.insert(offset) }
        }
        return indices
    }

    private static func dayKey(_ date: Date) -> String {
        fmt.string(from: Calendar.current.startOfDay(for: date))
    }
}
