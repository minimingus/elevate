import SwiftUI

struct IdleView: View {
    @ObservedObject var historyVM: HistoryViewModel
    let onStart: () -> Void
    let onHistory: () -> Void
    let onAchievements: () -> Void
    let onLeaderboard: () -> Void

    @State private var showSettings = false
    @AppStorage("dailyStepGoal") private var dailyStepGoal: Int = 400

    private var goalProgress: Double {
        guard dailyStepGoal > 0 else { return 0 }
        return min(1.0, Double(historyVM.todaySteps) / Double(dailyStepGoal))
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Elevate")
                        .font(.largeTitle.bold())
                    Text(Date.now.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if historyVM.currentStreak > 0 {
                    Label("\(historyVM.currentStreak)", systemImage: "flame.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 24)

            // MARK: Today card
            VStack(spacing: 16) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .tracking(1.5)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(historyVM.todaySteps)")
                                .font(.system(size: 56, weight: .heavy, design: .rounded))
                                .foregroundStyle(.green)
                            Text("steps")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 6)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        if let last = historyVM.sessions.first {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Last session")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(last.steps) steps · \(last.floors) floors")
                                    .font(.caption.bold())
                            }
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Label("Goal: \(dailyStepGoal)", systemImage: "target")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Progress bar
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green)
                                .frame(width: geo.size.width * goalProgress, height: 10)
                                .animation(.easeInOut(duration: 0.4), value: goalProgress)
                        }
                    }
                    .frame(height: 10)
                    HStack {
                        Text("\(Int(goalProgress * 100))% of daily goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if goalProgress >= 1 {
                            Label("Goal reached!", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)

            // MARK: Stats row
            HStack(spacing: 12) {
                StatTile(
                    value: "\(historyVM.personalBests.maxSteps)",
                    label: "Best session",
                    icon: "trophy.fill",
                    color: .yellow
                )
                StatTile(
                    value: "\(historyVM.sessions.count)",
                    label: "Total sessions",
                    icon: "figure.stair.stepper",
                    color: .blue
                )
                StatTile(
                    value: "\(historyVM.personalBests.maxFloors)",
                    label: "Best floors",
                    icon: "building.2.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Spacer()

            // MARK: Start button
            Button(action: onStart) {
                HStack(spacing: 12) {
                    Image(systemName: "figure.stair.stepper")
                        .font(.title2.bold())
                    Text("Start Climbing")
                        .font(.title3.bold())
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .green.opacity(0.35), radius: 12, y: 6)
            }
            .padding(.horizontal)

            // MARK: Nav row
            HStack(spacing: 12) {
                Button(action: onHistory) {
                    Label("History", systemImage: "chart.bar.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button(action: onAchievements) {
                    Label("Badges", systemImage: "trophy.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button(action: onLeaderboard) {
                    Label("Leaderboard", systemImage: "list.number")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .onAppear { historyVM.load() }
        .sheet(isPresented: $showSettings) {
            SettingsView { historyVM.load() }
        }
    }
}

// MARK: - Subviews

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

