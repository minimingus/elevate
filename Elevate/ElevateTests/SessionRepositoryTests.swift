import XCTest
import SwiftData
@testable import Elevate

@MainActor
final class SessionRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var repo: SessionRepository!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: ClimbSession.self, Achievement.self, configurations: config)
        repo = SessionRepository(modelContext: container.mainContext)
    }

    func test_save_persistsSession() throws {
        let session = ClimbSession(startDate: .now, endDate: Date(timeIntervalSinceNow: 60),
                                   steps: 100, floors: 3, calories: 12.0)
        try repo.save(session)
        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].steps, 100)
    }

    func test_fetchAll_returnsNewestFirst() throws {
        let old = ClimbSession(startDate: Date(timeIntervalSinceNow: -3600),
                               endDate: Date(timeIntervalSinceNow: -3540),
                               steps: 50, floors: 1, calories: 6)
        let recent = ClimbSession(startDate: .now, endDate: Date(timeIntervalSinceNow: 60),
                                  steps: 100, floors: 3, calories: 12)
        try repo.save(old)
        try repo.save(recent)
        let all = try repo.fetchAll()
        XCTAssertEqual(all[0].steps, 100) // recent first
    }

    func test_lifetimeSteps_sumsAllSessions() throws {
        let a = ClimbSession(startDate: .now, endDate: Date(timeIntervalSinceNow: 60), steps: 200, floors: 0, calories: 0)
        let b = ClimbSession(startDate: .now, endDate: Date(timeIntervalSinceNow: 60), steps: 300, floors: 0, calories: 0)
        try repo.save(a)
        try repo.save(b)
        XCTAssertEqual(try repo.lifetimeSteps(), 500)
    }

    func test_todaySteps_onlySumsToday() throws {
        let today = ClimbSession(startDate: .now, endDate: Date(timeIntervalSinceNow: 60),
                                 steps: 150, floors: 0, calories: 0)
        let yesterday = ClimbSession(
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: -86340),
            steps: 200, floors: 0, calories: 0)
        try repo.save(today)
        try repo.save(yesterday)
        XCTAssertEqual(try repo.todaySteps(), 150)
    }
}
