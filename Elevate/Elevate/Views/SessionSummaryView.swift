import SwiftUI

// MARK: - Share card
// Landmark comparison is in StairLandmarks.swift

struct ShareCard: View {
    let summary: SessionSummary

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatElevationShare(_ m: Double) -> String {
        if m < 10 { return String(format: "%.1fm", m) }
        return "\(Int(m))m"
    }

    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 11/255)

            VStack(spacing: 0) {
                // Top accent bar
                Rectangle()
                    .fill(Color.green)
                    .frame(height: 4)

                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ELEVATE")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                                .tracking(3)
                            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "figure.stair.stepper")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }

                    // Big step count
                    VStack(spacing: 4) {
                        Text("\(summary.steps)")
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("steps climbed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Stats row
                    HStack(spacing: 0) {
                        CardStat(value: "\(summary.floors)", label: "floors")
                        Divider().frame(height: 36).background(Color(.systemGray4))
                        CardStat(value: formatDuration(summary.duration), label: "time")
                        Divider().frame(height: 36).background(Color(.systemGray4))
                        CardStat(value: formatElevationShare(summary.elevationMeters), label: "elev")
                    }

                    // Landmark
                    if let landmark = landmarkComparison(for: summary.steps) {
                        Text(landmark)
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 360, height: 320)
    }
}

private struct CardStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary view

struct SessionSummaryView: View {
    let summary: SessionSummary
    let onDone: () -> Void

    @State private var shareImage: Image? = nil
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: Header
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .opacity(appeared ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)
                    Text("Session Complete")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(Date.now.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)

                // MARK: Stats grid
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    SummaryStatCell(
                        value: "\(summary.steps)",
                        label: "Steps",
                        icon: "figure.stair.stepper",
                        color: .green
                    )
                    SummaryStatCell(
                        value: "\(summary.floors)",
                        label: "Floors",
                        icon: "building.2.fill",
                        color: .blue
                    )
                    SummaryStatCell(
                        value: formatDuration(summary.duration),
                        label: "Duration",
                        icon: "clock.fill",
                        color: .purple
                    )
                    SummaryStatCell(
                        value: formatElevation(summary.elevationMeters),
                        label: "Elevation",
                        icon: "arrow.up.right",
                        color: .green
                    )
                    SummaryStatCell(
                        value: formatPace(steps: summary.steps, duration: summary.duration),
                        label: "Pace (spm)",
                        icon: "speedometer",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)

                // MARK: Landmark comparison
                if let landmark = landmarkComparison(for: summary.steps) {
                    HStack(spacing: 10) {
                        Image(systemName: "mountain.2.fill")
                            .foregroundStyle(.green)
                        Text(landmark)
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // MARK: New achievements
                if !summary.newlyUnlocked.isEmpty {
                    VStack(spacing: 10) {
                        Text("NEW ACHIEVEMENTS")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .tracking(1.5)

                        ForEach(summary.newlyUnlocked, id: \.id) { achievement in
                            HStack(spacing: 12) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(achievement.name)
                                        .font(.subheadline.bold())
                                    Text(achievement.achievementDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("NEW")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.yellow)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.yellow.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                // MARK: Health sync indicator
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                        .font(.caption)
                    Text("Saved to Apple Health")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                Spacer().frame(height: 32)

                // MARK: Share + Done
                VStack(spacing: 12) {
                    if let shareImage {
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview("My Elevate session", image: shareImage)
                        ) {
                            Label("Share Session", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 20)
                    }

                    Button(action: onDone) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
        }
        .task {
            appeared = true
            await renderShareCard()
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatElevation(_ m: Double) -> String {
        if m < 10 { return String(format: "%.1fm", m) }
        return "\(Int(m))m"
    }

    private func formatPace(steps: Int, duration: TimeInterval) -> String {
        guard duration >= 1 else { return "—" }
        let spm = Double(steps) / (duration / 60.0)
        return spm < 1 ? "—" : "\(Int(spm))"
    }

    @MainActor
    private func renderShareCard() async {
        let renderer = ImageRenderer(content: ShareCard(summary: summary))
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

private struct SummaryStatCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Spacer()
            }
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(value)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
            }
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
