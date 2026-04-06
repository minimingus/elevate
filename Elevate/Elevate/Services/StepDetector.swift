import Foundation

struct StepDetector {
    private var samples: [Double] = []
    private var lastStepTime: Date = .distantPast
    let threshold: Double
    let debounceInterval: TimeInterval
    let windowSize: Int

    init(threshold: Double = 0.3, debounceInterval: TimeInterval = 0.3, windowSize: Int = 5) {
        precondition(windowSize >= 2, "windowSize must be at least 2")
        self.threshold = threshold
        self.debounceInterval = debounceInterval
        self.windowSize = windowSize
        samples.reserveCapacity(windowSize)
    }

    /// Returns true if a step was detected.
    ///
    /// After a step is detected the sample buffer is cleared, creating a brief detection
    /// gap of `windowSize` samples before the next peak can be evaluated (in addition to
    /// the `debounceInterval`). This is intentional — it prevents the same impulse from
    /// triggering multiple detections.
    mutating func processSample(_ verticalAcceleration: Double, at time: Date) -> Bool {
        samples.append(verticalAcceleration)
        if samples.count > windowSize { samples.removeFirst() }
        guard samples.count == windowSize else { return false }
        // Debounce checked before peak to short-circuit cheaply on rapid samples.
        guard time.timeIntervalSince(lastStepTime) >= debounceInterval else { return false }

        let peak = samples.max()!
        let baseline = samples.min()!
        guard peak - baseline > threshold else { return false } // exclusive: range must strictly exceed threshold

        lastStepTime = time
        samples.removeAll()
        return true
    }
}
