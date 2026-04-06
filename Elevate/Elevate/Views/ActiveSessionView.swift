import SwiftUI

struct ActiveSessionView: View {
    @ObservedObject var trackingVM: TrackingViewModel
    let onStop: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ACTIVE SESSION")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(2)
                    Text(formatDuration(trackingVM.elapsedTime))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                Spacer()
                // Live badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulse ? 1.4 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                            value: pulse
                        )
                    Text("LIVE")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                        .tracking(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 36)

            // MARK: Ring
            RingProgressView(
                progress: trackingVM.dailyGoalProgress,
                steps: trackingVM.steps
            )
            .frame(width: 240, height: 240)

            // Goal label
            if trackingVM.dailyGoalProgress > 0 {
                Text("\(Int(trackingVM.dailyGoalProgress * 100))% of daily goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
            } else {
                Spacer().frame(height: 12 + 20)
            }

            Spacer().frame(height: 32)

            // MARK: Stats tiles
            HStack(spacing: 12) {
                SessionStatTile(
                    icon: "building.2.fill",
                    value: "\(trackingVM.floors)",
                    label: "Floors",
                    color: .blue
                )
                SessionStatTile(
                    icon: "arrow.up.right",
                    value: formatElevation(trackingVM.elevationMeters),
                    label: "Elevation",
                    color: .green
                )
                SessionStatTile(
                    icon: "speedometer",
                    value: trackingVM.pace < 1 ? "—" : "\(Int(trackingVM.pace))",
                    label: "spm",
                    color: .orange
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // MARK: Stop button
            Button(action: onStop) {
                HStack(spacing: 10) {
                    Image(systemName: "stop.fill")
                        .font(.headline)
                    Text("End Session")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.9, green: 0.15, blue: 0.15),
                                 Color(red: 0.75, green: 0.1, blue: 0.1)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.red.opacity(0.35), radius: 10, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear { pulse = true }
    }

    private func formatElevation(_ m: Double) -> String {
        if m < 10 { return String(format: "%.1fm", m) }
        return "\(Int(m))m"
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

private struct SessionStatTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
