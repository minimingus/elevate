import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var session: WatchSessionService

    var body: some View {
        Group {
            if session.isRunning {
                WatchActiveView()
            } else {
                WatchIdleView()
            }
        }
        .animation(.easeInOut, value: session.isRunning)
    }
}
