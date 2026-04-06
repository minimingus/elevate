enum CalorieEstimator {
    /// Estimates calories burned climbing stairs.
    /// Formula: steps × weightKg × 0.0017 (MET-based approximation for stair climbing)
    static func calories(steps: Int, weightKg: Double = 70.0) -> Double {
        Double(steps) * weightKg * 0.0017
    }
}
