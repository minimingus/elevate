import ActivityKit
import Foundation
import ElevateShared

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()
    private var activity: Activity<ElevateActivityAttributes>?

    private init() {}

    func start(at date: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = ElevateActivityAttributes(startDate: date)
        let state = ElevateActivityAttributes.ContentState(steps: 0, floors: 0, elapsedSeconds: 0)
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil),
            pushType: nil
        )
    }

    func update(steps: Int, floors: Int, elapsedSeconds: Int) async {
        let state = ElevateActivityAttributes.ContentState(
            steps: steps, floors: floors, elapsedSeconds: elapsedSeconds
        )
        await activity?.update(.init(state: state, staleDate: nil))
    }

    func end(steps: Int, floors: Int, elapsedSeconds: Int) async {
        let state = ElevateActivityAttributes.ContentState(
            steps: steps, floors: floors, elapsedSeconds: elapsedSeconds
        )
        await activity?.end(
            .init(state: state, staleDate: nil),
            dismissalPolicy: .after(.now + 8)
        )
        activity = nil
    }
}
