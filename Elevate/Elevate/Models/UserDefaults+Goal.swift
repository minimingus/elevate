import Foundation

extension UserDefaults {
    static let dailyStepGoalKey = "dailyStepGoal"

    var dailyStepGoal: Int {
        get { integer(forKey: Self.dailyStepGoalKey).nonZero ?? 400 }
        set { set(newValue, forKey: Self.dailyStepGoalKey) }
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
