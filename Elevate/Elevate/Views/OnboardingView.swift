import SwiftUI
import CoreMotion
import Combine

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
            GoalPage(goal: $dailyStepGoal, onNext: { withAnimation { page = 3 } })
                .tag(2)
            CalibrationPage(onFinish: {
                Task {
                    try? await HealthKitService().requestPermission()
                    hasCompletedOnboarding = true
                }
            })
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            PageIndicator(count: 4, current: page)
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
    let onNext: () -> Void

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

            OnboardingButton(title: "Continue", action: onNext)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }
}

// MARK: - Page 4: Calibration

private final class AltimeterRecorder: ObservableObject {
    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()
    private var lastAltitude: Double?
    @Published var altitudeGain: Double = 0

    func start() {
        altitudeGain = 0
        lastAltitude = nil
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            let alt = data.relativeAltitude.doubleValue
            DispatchQueue.main.async {
                if let last = self.lastAltitude {
                    let delta = alt - last
                    if delta > 0 { self.altitudeGain += delta }
                }
                self.lastAltitude = alt
            }
        }
    }

    func stop() { altimeter.stopRelativeAltitudeUpdates() }
}

private struct CalibrationPage: View {
    let onFinish: () -> Void

    @StateObject private var recorder = AltimeterRecorder()
    @AppStorage("riserHeightMeters") private var savedRiserHeight: Double = 0.175
    @State private var phase: Phase = .idle
    @State private var countdown = 15
    @State private var stepCount = 14
    @State private var countdownTask: Task<Void, Never>?

    enum Phase { case idle, recording, review }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon / countdown / checkmark
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                switch phase {
                case .idle:
                    Image(systemName: "stairs")
                        .font(.system(size: 52))
                        .foregroundStyle(iconColor)
                case .recording:
                    Text("\(countdown)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(iconColor)
                        .contentTransition(.numericText())
                case .review:
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: phase == .review)

            Spacer()

            // Content
            VStack(spacing: 12) {
                switch phase {
                case .idle:
                    Text("Calibrate Your Stairs")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text("Stand at the bottom of a staircase, tap Start, then climb one full flight at your normal pace.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                case .recording:
                    Text("Keep climbing!")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                    Text(String(format: "%.2f m gained", recorder.altitudeGain))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.purple)
                        .contentTransition(.numericText())
                    Text("Tap Done when you reach the top")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                case .review:
                    Text(recorder.altitudeGain > 0.1 ? "Nice climb!" : "Ready to go!")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                    if recorder.altitudeGain > 0.1 {
                        Text(String(format: "Measured %.2f m of altitude gain.", recorder.altitudeGain))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        VStack(spacing: 6) {
                            Text("How many steps was that flight?")
                                .font(.subheadline.bold())
                            Stepper("\(stepCount) steps", value: $stepCount, in: 4...40)
                                .font(.system(.body, design: .rounded).bold())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("No altitude data was detected. This may happen on a device without a barometer.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                switch phase {
                case .idle:
                    OnboardingButton(title: "Start Calibration") { startRecording() }
                    skipButton
                case .recording:
                    OnboardingButton(title: "Done — I'm at the top") { finishRecording() }
                case .review:
                    OnboardingButton(
                        title: recorder.altitudeGain > 0.1 ? "Save & Continue" : "Continue"
                    ) { saveAndFinish() }
                    if recorder.altitudeGain > 0.1 { skipButton }
                }

                Text("Elevate will request Health access to save your climbing sessions.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }

    private var iconColor: Color {
        phase == .review ? .green : .purple
    }

    private var skipButton: some View {
        Button("Skip for now", action: onFinish)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func startRecording() {
        withAnimation { phase = .recording }
        countdown = 15
        recorder.start()
        countdownTask = Task {
            for remaining in stride(from: 14, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run { countdown = remaining }
            }
            await MainActor.run { finishRecording() }
        }
    }

    private func finishRecording() {
        countdownTask?.cancel()
        recorder.stop()
        withAnimation { phase = .review }
    }

    private func saveAndFinish() {
        if recorder.altitudeGain > 0.1, stepCount > 0 {
            savedRiserHeight = recorder.altitudeGain / Double(stepCount)
        }
        onFinish()
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
