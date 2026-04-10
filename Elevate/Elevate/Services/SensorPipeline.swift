import CoreMotion
import Combine
import Foundation
import UIKit

/// Counts stair steps using accelerometer peak detection (50 Hz) gated by barometer climbing state.
/// The accelerometer gives sub-20 ms step latency; the barometer suppresses flat-walking false positives
/// and tracks elevation/floors.
@MainActor
final class SensorPipeline: ObservableObject {
    @Published private(set) var steps: Int = 0
    @Published private(set) var floors: Int = 0
    @Published private(set) var elevationMeters: Double = 0
    @Published private(set) var isClimbing: Bool = false

    private let floorHeightMeters: Double = 3.0

    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()
    private var stepDetector = StepDetector(threshold: 0.28, debounceInterval: 0.32, windowSize: 5)
    private let operationQueue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()

    private var sessionStart: Date?
    private var lastAltitude: Double? = nil
    private var altitudeGainMeters: Double = 0
    private var lastClimbTime: Date = .distantPast
    // Accelerometer steps accumulated while barometer hasn't yet confirmed climbing.
    // Released once barometer sees positive altitude delta; discarded after flat timeout.
    private var pendingSteps: Int = 0
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func start() {
        guard sessionStart == nil else { return }
        steps = 0
        floors = 0
        elevationMeters = 0
        isClimbing = false
        lastAltitude = nil
        altitudeGainMeters = 0
        lastClimbTime = .distantPast
        pendingSteps = 0
        stepDetector = StepDetector(threshold: 0.28, debounceInterval: 0.32, windowSize: 5)
        sessionStart = Date()

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ElevateClimbing") {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }

        startAccelerometer()
        startAltimeter()
        startPedometer()
    }

    func stop() -> (steps: Int, floors: Int, elevationMeters: Double) {
        motionManager.stopAccelerometerUpdates()
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

    /// Accelerometer at 50 Hz — detects each footfall immediately.
    private func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 50.0
        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, _ in
            guard let self, let data else { return }
            // Use vertical (Z) acceleration magnitude for peak detection.
            let z = abs(data.acceleration.z)
            let now = Date()
            Task { @MainActor in
                self.processAccelSample(z, at: now)
            }
        }
    }

    private func processAccelSample(_ z: Double, at now: Date) {
        guard stepDetector.processSample(z, at: now) else { return }
        if isClimbing {
            steps += 1
        } else {
            // Buffer steps — barometer may not have fired yet but user may already be climbing.
            pendingSteps += 1
        }
    }

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

        if delta > 0.005 {
            altitudeGainMeters += delta
            floors = Int(altitudeGainMeters / floorHeightMeters)
            elevationMeters = altitudeGainMeters
            isClimbing = true
            lastClimbTime = Date()
            // Release any accelerometer steps buffered before the barometer fired.
            if pendingSteps > 0 {
                steps += pendingSteps
                pendingSteps = 0
            }
        } else if Date().timeIntervalSince(lastClimbTime) > 3.0 {
            isClimbing = false
            pendingSteps = 0   // discard — user was on flat ground
        }
    }

    private func startPedometer() {
        guard CMPedometer.isFloorCountingAvailable(), let start = sessionStart else { return }
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            guard let self, let data else { return }
            let pedometerFloors = data.floorsAscended?.intValue ?? 0
            Task { @MainActor in
                if pedometerFloors > self.floors {
                    self.floors = pedometerFloors
                }
            }
        }
    }
}
