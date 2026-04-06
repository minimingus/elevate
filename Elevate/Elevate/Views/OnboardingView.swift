import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("dailyStepGoal") private var dailyStepGoal: Int = 400
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            WelcomePage(onNext: { withAnimation { page = 1 } })
                .tag(0)
            HowItWorksPage(onNext: { withAnimation { page = 2 } })
                .tag(1)
            GoalPage(goal: $dailyStepGoal, onFinish: {
                Task {
                    try? await HealthKitService().requestPermission()
                    hasCompletedOnboarding = true
                }
            })
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            PageIndicator(count: 3, current: page)
                .padding(.top, 60)
        }
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "figure.stair.stepper")
                        .font(.system(size: 52))
                        .foregroundStyle(.green)
                }

                VStack(spacing: 12) {
                    Text("Welcome to Elevate")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text("Every stair you climb counts.\nElevate tracks your steps, floors, and progress — automatically.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                FeatureRow(icon: "bolt.fill", color: .yellow, text: "Counts stairs in real time using your iPhone's sensors")
                FeatureRow(icon: "trophy.fill", color: .orange, text: "Earn achievements as you hit milestones")
                FeatureRow(icon: "flame.fill", color: .red, text: "Build streaks by climbing every day")
            }
            .padding(.horizontal, 32)

            Spacer()

            OnboardingButton(title: "Get Started", action: onNext)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }
}

// MARK: - Page 2: How it works

private struct HowItWorksPage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "iphone.motion")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                }

                VStack(spacing: 12) {
                    Text("How It Works")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text("Keep your iPhone in your pocket or hand while climbing. Elevate detects each step using the accelerometer and barometer.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                FeatureRow(icon: "waveform.path.ecg", color: .blue, text: "Accelerometer detects the up-down motion of each step")
                FeatureRow(icon: "barometer", color: .cyan, text: "Barometer confirms you're gaining altitude")
                FeatureRow(icon: "heart.fill", color: .pink, text: "Results saved to Apple Health automatically")
            }
            .padding(.horizontal, 32)

            Spacer()

            OnboardingButton(title: "Continue", action: onNext)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }
}

// MARK: - Page 3: Goal + Permissions

private struct GoalPage: View {
    @Binding var goal: Int
    let onFinish: () -> Void

    private let presets = [200, 400, 600, 800, 1000]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "target")
                        .font(.system(size: 52))
                        .foregroundStyle(.green)
                }

                VStack(spacing: 12) {
                    Text("Set Your Daily Goal")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text("How many stair steps do you want to climb each day? You can change this anytime.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(goal)")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.3), value: goal)
                    Text("steps")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            withAnimation { goal = preset }
                        } label: {
                            Text("\(preset)")
                                .font(.system(.callout, design: .rounded).bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(goal == preset ? Color.green : Color(.secondarySystemBackground))
                                .foregroundStyle(goal == preset ? .black : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                Stepper("", value: $goal, in: 50...5000, step: 50)
                    .labelsHidden()
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 10) {
                OnboardingButton(title: "Let's Go", action: onFinish)

                Text("Elevate will request Health access to read your body mass and save climbing sessions.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}

// MARK: - Shared components

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

private struct OnboardingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .green.opacity(0.35), radius: 10, y: 5)
        }
    }
}

private struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.green : Color(.systemGray4))
                    .frame(width: i == current ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.3), value: current)
            }
        }
    }
}
