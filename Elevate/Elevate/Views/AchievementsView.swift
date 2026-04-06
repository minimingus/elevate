import SwiftUI

struct AchievementsView: View {
    @ObservedObject var vm: AchievementViewModel

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Progress header
                    let unlocked = vm.achievements.filter(\.isUnlocked).count
                    let total = vm.achievements.count

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACHIEVEMENTS")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .tracking(1.5)
                            Text("\(unlocked) of \(total) unlocked")
                                .font(.headline)
                            ProgressView(value: Double(unlocked), total: Double(max(total, 1)))
                                .tint(.green)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 64, height: 64)
                            Text("\(Int(Double(unlocked) / Double(max(total, 1)) * 100))%")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // MARK: Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(vm.achievements) { achievement in
                            AchievementCell(achievement: achievement)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("Achievements")
            .onAppear { vm.load() }
        }
    }
}

private struct AchievementCell: View {
    let achievement: AchievementDisplay

    var body: some View {
        VStack(spacing: 10) {
            Text(achievement.emoji)
                .font(.system(size: 44))
                .grayscale(achievement.isUnlocked ? 0 : 1)
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)

            VStack(spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let progress = achievement.progress {
                Text(progress)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }

            if achievement.isUnlocked {
                Label("Unlocked", systemImage: "checkmark.circle.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            achievement.isUnlocked
                ? Color.green.opacity(0.08)
                : Color(.secondarySystemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    achievement.isUnlocked ? Color.green.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
