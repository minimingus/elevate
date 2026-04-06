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
            let c = try Self.makeContainer()
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

    /// Attempts to open the SwiftData store; if the schema has changed and
    /// migration fails, deletes the local store and creates a fresh one.
    /// Local data will repopulate from Supabase on next load.
    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([ClimbSession.self, Achievement.self])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // Wipe the incompatible store and start fresh
            let storeURL = config.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            return try ModelContainer(for: schema, configurations: config)
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
