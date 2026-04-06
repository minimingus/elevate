import SwiftData
import Foundation

@Model
final class ClimbSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var steps: Int
    var floors: Int
    var calories: Double
    var type: ClimbType
    var shareToken: String?

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        steps: Int,
        floors: Int,
        calories: Double,
        type: ClimbType = .stairs,
        shareToken: String? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.steps = steps
        self.floors = floors
        self.calories = calories
        self.type = type
        self.shareToken = shareToken
    }
}
