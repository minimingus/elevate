import XCTest
@testable import Elevate

final class StepDetectorTests: XCTestCase {

    func test_noStep_whenSamplesAreBelowThreshold() {
        var detector = StepDetector(threshold: 0.3, debounceInterval: 0.3, windowSize: 5)
        let now = Date()
        let results = (0..<5).map { i in
            detector.processSample(0.1, at: now.addingTimeInterval(Double(i) * 0.02))
        }
        XCTAssertFalse(results.contains(true))
    }

    func test_stepDetected_whenPeakExceedsThreshold() {
        var detector = StepDetector(threshold: 0.3, debounceInterval: 0.3, windowSize: 5)
        let now = Date()
        _ = detector.processSample(0.05, at: now)
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.02))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.04))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.06))
        let detected = detector.processSample(0.45, at: now.addingTimeInterval(0.08))
        XCTAssertTrue(detected)
    }

    func test_debounce_preventsDoubleCount() {
        var detector = StepDetector(threshold: 0.3, debounceInterval: 0.3, windowSize: 5)
        let now = Date()
        _ = detector.processSample(0.05, at: now)
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.02))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.04))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.06))
        let first = detector.processSample(0.45, at: now.addingTimeInterval(0.08))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.10))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.12))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.14))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.16))
        let second = detector.processSample(0.45, at: now.addingTimeInterval(0.18))
        XCTAssertTrue(first)
        XCTAssertFalse(second)
    }

    func test_stepDetected_afterDebounceExpires() {
        var detector = StepDetector(threshold: 0.3, debounceInterval: 0.3, windowSize: 5)
        let now = Date()
        _ = detector.processSample(0.05, at: now)
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.02))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.04))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.06))
        _ = detector.processSample(0.45, at: now.addingTimeInterval(0.08))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.50))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.52))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.54))
        _ = detector.processSample(0.05, at: now.addingTimeInterval(0.56))
        let second = detector.processSample(0.45, at: now.addingTimeInterval(0.58))
        XCTAssertTrue(second)
    }
}
