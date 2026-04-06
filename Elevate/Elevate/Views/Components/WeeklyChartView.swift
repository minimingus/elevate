import SwiftUI

struct WeeklyChartView: View {
    /// 7 values, index 0 = today, index 6 = 6 days ago
    let dailySteps: [Int]
    /// Offsets that are marked as rest days (shown with a moon, grey bar)
    var restDayIndices: Set<Int> = []

    private var maxSteps: Int {
        dailySteps.max().flatMap { $0 > 0 ? $0 : nil } ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(dailySteps.enumerated().reversed()), id: \.offset) { offset, steps in
                let isRest = restDayIndices.contains(offset)
                VStack(spacing: 5) {
                    if isRest && steps == 0 {
                        Text("🌙")
                            .font(.system(size: 9))
                            .transition(.opacity)
                    } else if steps > 0 {
                        Text("\(steps)")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(offset == 0 ? .green : .secondary)
                            .transition(.opacity)
                    } else {
                        Spacer().frame(height: 12)
                    }
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRest && steps == 0
                              ? Color(.systemGray4)
                              : (offset == 0 ? Color.green : Color.green.opacity(0.3)))
                        .frame(height: barHeight(for: steps))
                        .animation(.easeInOut(duration: 0.5), value: steps)
                    Text(dayLabel(for: offset))
                        .font(.system(size: 10, weight: offset == 0 ? .bold : .regular))
                        .foregroundStyle(offset == 0 ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 108)
    }

    private func barHeight(for steps: Int) -> CGFloat {
        max(4, CGFloat(steps) / CGFloat(maxSteps) * 72)
    }

    private func dayLabel(for offset: Int) -> String {
        if offset == 0 { return "Today" }
        let day = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day)
    }
}
