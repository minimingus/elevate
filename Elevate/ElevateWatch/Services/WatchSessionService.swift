import WatchConnectivity
import Foundation

/// Receives session state from the iPhone and sends start/stop commands back.
@MainActor
final class WatchSessionService: NSObject, ObservableObject {
    @Published var isRunning: Bool = false
    @Published var steps: Int = 0
    @Published var floors: Int = 0
    @Published var elapsedSeconds: Int = 0
    @Published var todaySteps: Int = 0
    @Published var streak: Int = 0
    @Published var goal: Int = 400
    @Published var isPhoneReachable: Bool = false

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["command": command], replyHandler: nil)
    }

    private func apply(_ context: [String: Any]) {
        if let v = context["isRunning"] as? Bool    { isRunning       = v }
        if let v = context["steps"] as? Int         { steps           = v }
        if let v = context["floors"] as? Int        { floors          = v }
        if let v = context["elapsed"] as? Int       { elapsedSeconds  = v }
        if let v = context["todaySteps"] as? Int    { todaySteps      = v }
        if let v = context["streak"] as? Int        { streak          = v }
        if let v = context["goal"] as? Int          { goal            = v }
    }
}

extension WatchSessionService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            let ctx = session.receivedApplicationContext
            if !ctx.isEmpty { self.apply(ctx) }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.isPhoneReachable = session.isReachable }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.apply(context) }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.apply(message) }
    }
}
