import SwiftUI

struct SessionDetailView: View {
    let session: ClimbSession
    let personalBests: PersonalBests
    let onDelete: () -> Void

    @State private var shareImage: Image? = nil
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: Header
                VStack(spacing: 4) {
                    Text(session.startDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .font(.subheadline.bold())
                    HStack(spacing: 4) {
                        Text(session.startDate.formatted(date: .omitted, time: .shortened))
                        Text("–")
                        Text(session.endDate.formatted(date: .omitted, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // MARK: Hero steps
                VStack(spacing: 2) {
                    Text("\(session.steps)")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                    Text("steps")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // MARK: Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailStatCell(value: "\(session.floors)", label: "Floors", icon: "building.2.fill", color: .blue)
                    DetailStatCell(value: formatElevation(session.elevationMeters), label: "Elevation", icon: "arrow.up.right", color: .green)
                    DetailStatCell(value: formatDuration(session.duration), label: "Duration", icon: "clock.fill", color: .purple)
                    DetailStatCell(value: formatPace(session), label: "Pace (spm)", icon: "speedometer", color: .orange)
                }
                .padding(.horizontal, 20)

                // MARK: PB comparison
                if personalBests.maxSteps > 0 {
                    let pct = min(1.0, Double(session.steps) / Double(personalBests.maxSteps))
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(Int(pct * 100))% of your best session")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            if session.id == personalBests.bestSessionId {
                                Label("Personal Best", systemImage: "trophy.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.yellow)
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: geo.size.width * pct, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                }

                // MARK: Landmark comparison
                if let landmark = landmarkComparison(for: session.steps) {
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
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                // MARK: Share
                if let shareImage {
                    ShareLink(
                        item: shareImage,
                        preview: SharePreview("My Elevate session", image: shareImage)
                    ) {
                        Label("Share Session", systemImage: "square.and.arrow.up")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                }

                // MARK: Delete
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Session", systemImage: "trash")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this session?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("This will remove the session from your history and the leaderboard.")
        }
        .task { await renderShareCard() }
    }

    // MARK: - Helpers

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        if m == 0 { return "\(s)s" }
        return "\(m)m \(s)s"
    }

    private func formatElevation(_ m: Double) -> String {
        m < 10 ? String(format: "%.1fm", m) : "\(Int(m))m"
    }

    private func formatPace(_ s: ClimbSession) -> String {
        guard s.duration >= 1 else { return "—" }
        let spm = Double(s.steps) / (s.duration / 60)
        return spm < 1 ? "—" : "\(Int(spm))"
    }

    @MainActor
    private func renderShareCard() async {
        let summary = SessionSummary(
            steps: session.steps,
            floors: session.floors,
            elevationMeters: session.elevationMeters,
            duration: session.duration,
            newlyUnlocked: []
        )
        let renderer = ImageRenderer(content: ShareCard(summary: summary))
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Subview

private struct DetailStatCell: View {
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
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
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
