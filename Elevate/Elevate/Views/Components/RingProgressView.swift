import SwiftUI

struct RingProgressView: View {
    let progress: Double   // 0.0–1.0
    let steps: Int
    var lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)

            // Progress arc with glow
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.green,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.green.opacity(0.55), radius: 10, x: 0, y: 0)
                .animation(.easeInOut(duration: 0.4), value: progress)

            // Center content
            VStack(spacing: 2) {
                Text("\(steps)")
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("STEPS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }
        }
    }
}
