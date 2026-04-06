import ActivityKit
import WidgetKit
import SwiftUI
import ElevateShared

struct ElevateWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ElevateActivityAttributes.self) { context in
            // Lock Screen / Notification Center view
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(red: 10/255, green: 10/255, blue: 11/255))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.stair.stepper")
                            .foregroundStyle(.green)
                        Text("Elevate")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval(from: context.attributes.startDate))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("\(context.state.steps)")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("steps")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 2) {
                            Text("\(context.state.floors)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                            Text("floors")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
            } compactLeading: {
                Image(systemName: "figure.stair.stepper")
                    .foregroundStyle(.green)
                    .font(.caption.bold())
            } compactTrailing: {
                Text("\(context.state.steps)")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .monospacedDigit()
            } minimal: {
                Text("\(context.state.steps)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.green)
            }
            .widgetURL(URL(string: "elevate://session"))
            .keylineTint(.green)
        }
    }

    private func timerInterval(from start: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(start))
        let m = elapsed / 60
        let s = elapsed % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Lock screen view

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<ElevateActivityAttributes>

    var body: some View {
        HStack(spacing: 20) {
            // Steps hero
            VStack(spacing: 2) {
                Text("\(context.state.steps)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("STEPS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
            }

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("\(context.state.floors) floor\(context.state.floors == 1 ? "" : "s")")
                        .font(.caption.bold())
                }
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(formatElapsed(context.state.elapsedSeconds))
                        .font(.caption.bold())
                        .monospacedDigit()
                }
            }

            Spacer()

            Image(systemName: "figure.stair.stepper")
                .font(.title2.bold())
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
