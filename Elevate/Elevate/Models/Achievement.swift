import SwiftData
import Foundation

@Model
final class Achievement {
    var id: String
    var name: String
    var achievementDescription: String
    var unlockedDate: Date?

    init(id: String, name: String, achievementDescription: String, unlockedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.achievementDescription = achievementDescription
        self.unlockedDate = unlockedDate
    }
}
