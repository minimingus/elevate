import ActivityKit
import Foundation

public struct ElevateActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var steps: Int
        public var floors: Int
        public var elapsedSeconds: Int

        public init(steps: Int, floors: Int, elapsedSeconds: Int) {
            self.steps = steps
            self.floors = floors
            self.elapsedSeconds = elapsedSeconds
        }
    }

    public var startDate: Date

    public init(startDate: Date) {
        self.startDate = startDate
    }
}
