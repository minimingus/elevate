import XCTest
@testable import Elevate

final class CalorieEstimatorTests: XCTestCase {

    func test_calories_defaultWeight() {
        // 100 steps * 70kg * 0.0017 = 11.9
        let result = CalorieEstimator.calories(steps: 100)
        XCTAssertEqual(result, 11.9, accuracy: 0.01)
    }

    func test_calories_customWeight() {
        // 200 steps * 80kg * 0.0017 = 27.2
        let result = CalorieEstimator.calories(steps: 200, weightKg: 80.0)
        XCTAssertEqual(result, 27.2, accuracy: 0.01)
    }

    func test_calories_zeroSteps() {
        XCTAssertEqual(CalorieEstimator.calories(steps: 0), 0.0)
    }
}
