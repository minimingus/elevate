import SwiftUI

struct WatchIdleView: View {
    @EnvironmentObject var session: WatchSessionService

    private var progress: Double {
        guard session.goal > 0 else { return 0 }
        return min(1.0, Double(session.todaySteps) / Double(session.goal))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // Goal ring + today steps
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.green,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: progress)
                    VStack(spacing: 1) {
                        Text("\(session.todaySteps)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.green)
                        Text("steps")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 88, height: 88)

                // Streak
                if session.streak > 0 {
                    Label("\(session.streak)", systemImage: "flame.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                }

                // Start button
                Button {
                    session.sendCommand("start")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.stair.stepper")
                        Text("Start")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!session.isPhoneReachable)

                if !session.isPhoneReachable {
                    Text("Open Elevate on iPhone")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
