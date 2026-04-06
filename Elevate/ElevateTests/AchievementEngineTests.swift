import XCTest
@testable import Elevate

final class AchievementEngineTests: XCTestCase {

    private func makeSession(steps: Int, floors: Int = 0, duration: TimeInterval = 60) -> ClimbSession {
        ClimbSession(startDate: .now, endDate: Date(timeIntervalSinceNow: duration), steps: steps, floors: floors,
                     calories: 0)
    }

    func test_firstClimb_unlocksOnFirstSession() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 1),
            allSessions: [makeSession(steps: 1)],
            currentStreak: 0,
            lifetimeSteps: 1
        )
        XCTAssertTrue(ids.contains("first_climb"))
    }

    func test_firstClimb_doesNotUnlockOnSubsequentSession() {
        let previous = makeSession(steps: 10)
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 5),
            allSessions: [previous, makeSession(steps: 5)],
            currentStreak: 0,
            lifetimeSteps: 15
        )
        XCTAssertFalse(ids.contains("first_climb"))
    }

    func test_century_unlocksAt100Steps() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 100),
            allSessions: [makeSession(steps: 100)],
            currentStreak: 0,
            lifetimeSteps: 100
        )
        XCTAssertTrue(ids.contains("century"))
    }

    func test_century_doesNotUnlockBelow100Steps() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 99),
            allSessions: [makeSession(steps: 99)],
            currentStreak: 0,
            lifetimeSteps: 99
        )
        XCTAssertFalse(ids.contains("century"))
    }

    func test_floorTen_unlocksAt10Floors() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 10, floors: 10),
            allSessions: [makeSession(steps: 10, floors: 10)],
            currentStreak: 0,
            lifetimeSteps: 10
        )
        XCTAssertTrue(ids.contains("floor_10"))
    }

    func test_streak3_unlocksAt3DayStreak() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 10),
            allSessions: [makeSession(steps: 10)],
            currentStreak: 3,
            lifetimeSteps: 10
        )
        XCTAssertTrue(ids.contains("streak_3"))
    }

    func test_streak7_unlocksAt7DayStreak() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 10),
            allSessions: [makeSession(steps: 10)],
            currentStreak: 7,
            lifetimeSteps: 10
        )
        XCTAssertTrue(ids.contains("streak_7"))
    }

    func test_lifetime1k_unlocksAt1000LifetimeSteps() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 100),
            allSessions: [makeSession(steps: 100)],
            currentStreak: 0,
            lifetimeSteps: 1000
        )
        XCTAssertTrue(ids.contains("lifetime_1k"))
    }

    func test_floorTen_doesNotUnlockBelow10Floors() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 10, floors: 9),
            allSessions: [makeSession(steps: 10, floors: 9)],
            currentStreak: 0,
            lifetimeSteps: 10
        )
        XCTAssertFalse(ids.contains("floor_10"))
    }

    func test_streak3_doesNotUnlockBelow3DayStreak() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 10),
            allSessions: [makeSession(steps: 10)],
            currentStreak: 2,
            lifetimeSteps: 10
        )
        XCTAssertFalse(ids.contains("streak_3"))
    }

    func test_streak7_doesNotUnlockBelow7DayStreak() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 10),
            allSessions: [makeSession(steps: 10)],
            currentStreak: 6,
            lifetimeSteps: 10
        )
        XCTAssertFalse(ids.contains("streak_7"))
    }

    func test_lifetime1k_doesNotUnlockBelow1000Steps() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 100),
            allSessions: [makeSession(steps: 100)],
            currentStreak: 0,
            lifetimeSteps: 999
        )
        XCTAssertFalse(ids.contains("lifetime_1k"))
    }

    func test_streak7_alsoCascadesStreak3() {
        // A 7-day streak should also unlock streak_3 (badges cascade intentionally).
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 10),
            allSessions: [makeSession(steps: 10)],
            currentStreak: 7,
            lifetimeSteps: 10
        )
        XCTAssertTrue(ids.contains("streak_3"))
        XCTAssertTrue(ids.contains("streak_7"))
    }

    func test_multipleAchievementsCanUnlockAtOnce() {
        let ids = AchievementEngine.evaluate(
            session: makeSession(steps: 100, floors: 10),
            allSessions: [makeSession(steps: 100, floors: 10)],
            currentStreak: 7,
            lifetimeSteps: 1000
        )
        XCTAssertTrue(ids.contains("first_climb"))
        XCTAssertTrue(ids.contains("century"))
        XCTAssertTrue(ids.contains("floor_10"))
        XCTAssertTrue(ids.contains("streak_7"))
        XCTAssertTrue(ids.contains("lifetime_1k"))
    }
}
