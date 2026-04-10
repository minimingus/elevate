import WatchConnectivity
import Foundation

/// Pushes session state to the Apple Watch and handles start/stop commands from it.
@MainActor
final class PhoneConnectivityService: NSObject {
    static let shared = PhoneConnectivityService()

    /// Called when the Watch sends "start" or "stop".
    var onCommand: ((String) -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends current state to Watch via applicationContext (persisted) +
    /// sendMessage (low-latency, best-effort when reachable).
    func push(isRunning: Bool, steps: Int, floors: Int, elapsed: Int,
              todaySteps: Int, streak: Int, goal: Int) {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isWatchAppInstalled else { return }
        let payload: [String: Any] = [
            "isRunning": isRunning,
            "steps": steps,
            "floors": floors,
            "elapsed": elapsed,
            "todaySteps": todaySteps,
            "streak": streak,
            "goal": goal
        ]
        try? WCSession.default.updateApplicationContext(payload)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }
}

extension PhoneConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {
        guard let command = message["command"] as? String else { return }
        Task { @MainActor in self.onCommand?(command) }
    }
}
