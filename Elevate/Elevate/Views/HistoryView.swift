import SwiftUI

struct HistoryView: View {
    @ObservedObject var vm: HistoryViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: Weekly overview
                    VStack(alignment: .leading, spacing: 14) {
                        Text("THIS WEEK")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .tracking(1.5)

                        WeeklyChartView(dailySteps: vm.weeklySteps)

                        Divider()
                            .background(Color(.systemGray5))

                        HStack {
                            let total = vm.weeklySteps.reduce(0, +)
                            let activeDays = vm.weeklySteps.filter { $0 > 0 }.count
                            Label("\(total) steps", systemImage: "figure.stair.stepper")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                            Spacer()
                            Text("\(activeDays) active day\(activeDays == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // MARK: Sessions list
                    if vm.sessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.stair.stepper")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(.systemGray4))
                            Text("No sessions yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Start climbing to see your history here.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 52)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ALL SESSIONS")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .tracking(1.5)
                                .padding(.horizontal, 4)

                            VStack(spacing: 1) {
                                ForEach(vm.sessions, id: \.id) { session in
                                    HistorySessionRow(
                                        session: session,
                                        isBest: session.id == vm.personalBests.bestSessionId
                                    )
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("History")
            .onAppear { vm.load() }
        }
    }
}

private struct HistorySessionRow: View {
    let session: ClimbSession
    let isBest: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Steps hero
            VStack(spacing: 1) {
                Text("\(session.steps)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(isBest ? .yellow : .green)
                Text("steps")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
            .frame(width: 72)
            .padding(.vertical, 16)

            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Meta
            VStack(alignment: .leading, spacing: 5) {
                Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.bold())
                HStack(spacing: 10) {
                    Label("\(session.floors) floor\(session.floors == 1 ? "" : "s")", systemImage: "building.2.fill")
                    Label(formatDuration(session.duration), systemImage: "clock")
                    if session.calories > 0 {
                        Label("\(Int(session.calories)) cal", systemImage: "flame.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 8)

            if isBest {
                VStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                        .font(.callout)
                    Text("BEST")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.yellow)
                }
                .padding(.trailing, 16)
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        if m == 0 { return "\(s)s" }
        return "\(m)m \(s)s"
    }
}
