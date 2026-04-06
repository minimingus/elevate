import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompleted = false
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 11/255).ignoresSafeArea()

            TabView(selection: $page) {
                WelcomePage().tag(0)
                HowItWorksPage().tag(1)
                PermissionsPage().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            // Dots + Next
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? Color.green : Color(.systemGray4))
                            .frame(width: i == page ? 10 : 7, height: i == page ? 10 : 7)
                            .animation(.spring(), value: page)
                    }
                }
                .padding(.bottom, 20)

                if page < 2 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 32)
                    }
                } else {
                    Button {
                        hasCompleted = true
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 32)
                    }
                }
            }
            .padding(.bottom, 48)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Pages

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            // Icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 120, height: 120)
                Image(systemName: "figure.stair.stepper")
                    .font(.system(size: 54))
                    .foregroundStyle(.green)
            }
            VStack(spacing: 12) {
                Text("Elevate")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Count every stair.\nCelebrate every climb.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct HowItWorksPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("How it works")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 20) {
                FeatureRow(icon: "barometer", color: .blue,
                           title: "Barometer gate",
                           desc: "Only counts steps when you're actually going up — no false counts on flat ground.")
                FeatureRow(icon: "waveform.path.ecg", color: .green,
                           title: "Accelerometer peaks",
                           desc: "Detects each individual stair step from your phone's motion sensor.")
                FeatureRow(icon: "heart.fill", color: .pink,
                           title: "Apple Health sync",
                           desc: "Sessions are saved to Health automatically as steps and flights climbed.")
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct PermissionsPage: View {
    @State private var motionDone = false
    @State private var notifDone = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Two quick permissions")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                PermissionRow(
                    icon: "sensors",
                    color: .orange,
                    title: "Motion & Fitness",
                    desc: "To count your steps and detect climbing.",
                    done: $motionDone
                ) {
                    // Motion is requested when the first session starts
                    motionDone = true
                }

                PermissionRow(
                    icon: "bell.fill",
                    color: .purple,
                    title: "Notifications",
                    desc: "Daily reminders and streak alerts.",
                    done: $notifDone
                ) {
                    Task {
                        await NotificationService.shared.requestPermission()
                        notifDone = true
                    }
                }
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(desc).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    @Binding var done: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: action) {
                Image(systemName: done ? "checkmark.circle.fill" : "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(done ? .green : .secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
