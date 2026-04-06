import SwiftUI
import SwiftData

@main
struct ElevateApp: App {
    let container: ModelContainer
    @StateObject private var trackingVM: TrackingViewModel
    @StateObject private var historyVM: HistoryViewModel
    @StateObject private var achievementVM: AchievementViewModel

    init() {
        do {
            let c = try ModelContainer(for: ClimbSession.self, Achievement.self)
            container = c
            let sessionRepo = SessionRepository(modelContext: c.mainContext)
            let achievementRepo = AchievementRepository(modelContext: c.mainContext)
            let pipeline = SensorPipeline()
            let healthKit = HealthKitService()

            _trackingVM = StateObject(wrappedValue: TrackingViewModel(
                pipeline: pipeline,
                sessionRepo: sessionRepo,
                achievementRepo: achievementRepo,
                healthKit: healthKit
            ))
            _historyVM = StateObject(wrappedValue: HistoryViewModel(sessionRepo: sessionRepo))
            _achievementVM = StateObject(wrappedValue: AchievementViewModel(
                achievementRepo: achievementRepo,
                sessionRepo: sessionRepo
            ))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(trackingVM)
                .environmentObject(historyVM)
                .environmentObject(achievementVM)
                .preferredColorScheme(.dark)
        }
    }
}
