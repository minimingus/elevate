import CoreMotion
import Combine
import Foundation
import UIKit

/// Counts stair steps using altitude gain from the barometer.
/// Formula: steps = cumulative altitude gain (m) / riser height (0.175 m)
/// This is immune to flat walking — only upward altitude change is counted.
@MainActor
final class SensorPipeline: ObservableObject {
    @Published private(set) var steps: Int = 0
    @Published private(set) var floors: Int = 0
    @Published private(set) var elevationMeters: Double = 0
    @Published private(set) var isClimbing: Bool = false

    // Tuning constants — riserHeightMeters is calibrated per user in onboarding
    private var riserHeightMeters: Double = 0.175
    private let floorHeightMeters: Double = 3.0     // ~10 ft per floor

    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()
    private let operationQueue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()

    private var sessionStart: Date?
    private var lastAltitude: Double? = nil
    private var altitudeGainMeters: Double = 0
    private var lastClimbTime: Date = .distantPast
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func start() {
        guard sessionStart == nil else { return }
        let saved = UserDefaults.standard.double(forKey: "riserHeightMeters")
        riserHeightMeters = saved > 0.05 ? saved : 0.175
        steps = 0
        floors = 0
        elevationMeters = 0
        isClimbing = false
        lastAltitude = nil
        altitudeGainMeters = 0
        sessionStart = Date()

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ElevateClimbing") {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }

        startAltimeter()
        startPedometer()
    }

    func stop() -> (steps: Int, floors: Int, elevationMeters: Double) {
        altimeter.stopRelativeAltitudeUpdates()
        pedometer.stopUpdates()
        sessionStart = nil
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        return (steps, floors, elevationMeters)
    }

    // MARK: - Private

    private func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: operationQueue) { [weak self] data, _ in
            guard let self, let data else { return }
            let altitude = data.relativeAltitude.doubleValue
            Task { @MainActor in
                self.processAltitude(altitude)
            }
        }
    }

    private func processAltitude(_ altitude: Double) {
        defer { lastAltitude = altitude }
        guard let last = lastAltitude else { return }

        let delta = altitude - last

        if delta > 0 {
            // Accumulate every positive delta — barometer noise floor is < 1 cm
            // so no threshold needed; thresholding causes lost altitude and lag
            altitudeGainMeters += delta
            let newSteps = Int(altitudeGainMeters / riserHeightMeters)
            if newSteps > steps {
                steps = newSteps
            }
            floors = Int(altitudeGainMeters / floorHeightMeters)
            elevationMeters = altitudeGainMeters
            isClimbing = true
            lastClimbTime = Date()
        } else if Date().timeIntervalSince(lastClimbTime) > 2.0 {
            isClimbing = false
        }
    }

    /// CMPedometer provides floor count as a cross-check / fallback.
    private func startPedometer() {
        guard CMPedometer.isFloorCountingAvailable(), let start = sessionStart else { return }
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            guard let self, let data else { return }
            let pedometerFloors = data.floorsAscended?.intValue ?? 0
            Task { @MainActor in
                // Use pedometer floors only if barometer hasn't counted more
                if pedometerFloors > self.floors {
                    self.floors = pedometerFloors
                }
            }
        }
    }
}
