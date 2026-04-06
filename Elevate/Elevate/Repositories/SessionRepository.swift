import Foundation
import SwiftData

@MainActor
final class SessionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ session: ClimbSession) throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func delete(_ session: ClimbSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    func fetchAll() throws -> [ClimbSession] {
        let descriptor = FetchDescriptor<ClimbSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func lifetimeSteps() throws -> Int {
        // Fetch only steps column to avoid loading all properties.
        var descriptor = FetchDescriptor<ClimbSession>()
        descriptor.propertiesToFetch = [\.steps]
        return try modelContext.fetch(descriptor).reduce(0) { $0 + $1.steps }
    }

    func todaySteps() throws -> Int {
        // Uses Calendar.current intentionally — local timezone matches the user's day boundary.
        let startOfDay = Calendar.current.startOfDay(for: Date())
        var descriptor = FetchDescriptor<ClimbSession>(
            predicate: #Predicate { $0.startDate >= startOfDay }
        )
        descriptor.propertiesToFetch = [\.steps]
        return try modelContext.fetch(descriptor).reduce(0) { $0 + $1.steps }
    }

    /// Returns step counts for the past `days` calendar days, index 0 = today, index 6 = 6 days ago.
    /// Uses Calendar.current intentionally — local timezone matches the user's day boundary.
    func weeklySteps(days: Int = 7) throws -> [Int] {
        let calendar = Calendar.current
        return try (0..<days).map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()),
                  let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: day)) else {
                return 0
            }
            let start = calendar.startOfDay(for: day)
            let descriptor = FetchDescriptor<ClimbSession>(
                predicate: #Predicate { $0.startDate >= start && $0.startDate < end }
            )
            return try modelContext.fetch(descriptor).reduce(0) { $0 + $1.steps }
        }
    }
}
