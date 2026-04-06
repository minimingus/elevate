import HealthKit
import Foundation

final class HealthKitService {
    private let store: HKHealthStore

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    private let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.flightsClimbed),
    ]
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.bodyMass),
    ]

    func requestPermission() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    /// Returns user's body mass in kg, or nil if unavailable.
    func bodyMassKg() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let type = HKQuantityType(.bodyMass)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        guard let sample = try? await descriptor.result(for: store).first else { return nil }
        return sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
    }

    func write(session: ClimbSession) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let stepSample = HKQuantitySample(
            type: HKQuantityType(.stepCount),
            quantity: HKQuantity(unit: .count(), doubleValue: Double(session.steps)),
            start: session.startDate,
            end: session.endDate
        )
        let flightSample = HKQuantitySample(
            type: HKQuantityType(.flightsClimbed),
            quantity: HKQuantity(unit: .count(), doubleValue: Double(session.floors)),
            start: session.startDate,
            end: session.endDate
        )
        try await store.save([stepSample, flightSample])
    }
}
