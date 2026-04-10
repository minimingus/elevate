import SwiftUI

@main
struct ElevateWatchApp: App {
    @StateObject private var session = WatchSessionService()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(session)
        }
    }
}
