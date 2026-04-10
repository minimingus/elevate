import SwiftUI

struct WatchActiveView: View {
    @EnvironmentObject var session: WatchSessionService

    private var elapsed: String {
        let m = session.elapsedSeconds / 60
        let s = session.elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 8) {

            // Big step count
            VStack(spacing: 2) {
                Text("\(session.steps)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.green)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("steps")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // Floors + time
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("\(session.floors)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("floors")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text(elapsed)
                        .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    Text("time")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            // Stop button
            Button {
                session.sendCommand("stop")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.horizontal, 4)
    }
}
