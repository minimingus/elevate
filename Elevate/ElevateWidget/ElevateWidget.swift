import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct ElevateEntry: TimelineEntry {
    let date: Date
    let todaySteps: Int
    let dailyGoal: Int
    let currentStreak: Int
}

// MARK: - Provider

struct ElevateProvider: TimelineProvider {
    private let suiteName = "group.com.mingus.Elevate"

    func placeholder(in context: Context) -> ElevateEntry {
        ElevateEntry(date: .now, todaySteps: 247, dailyGoal: 400, currentStreak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (ElevateEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ElevateEntry>) -> Void) {
        let e = entry()
        // Refresh at next 15-min boundary
        let nextRefresh = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [e], policy: .after(nextRefresh)))
    }

    private func entry() -> ElevateEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        return ElevateEntry(
            date: .now,
            todaySteps: defaults?.integer(forKey: "todaySteps") ?? 0,
            dailyGoal: defaults?.integer(forKey: "dailyStepGoal") ?? 400,
            currentStreak: defaults?.integer(forKey: "currentStreak") ?? 0
        )
    }
}

// MARK: - Widget views

struct ElevateWidgetEntryView: View {
    var entry: ElevateEntry
    @Environment(\.widgetFamily) private var family

    var progress: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(1.0, Double(entry.todaySteps) / Double(entry.dailyGoal))
    }

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: smallView
        }
    }

    // MARK: Small
    private var smallView: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 11/255)
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.green,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .green.opacity(0.5), radius: 4)
                }
                .frame(width: 68, height: 68)
                .overlay {
                    VStack(spacing: 1) {
                        Text("\(entry.todaySteps)")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("steps")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }
                }

                if entry.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 11))
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: Medium
    private var mediumView: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 11/255)
            HStack(spacing: 16) {
                // Ring side
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.green,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .green.opacity(0.5), radius: 6)
                }
                .frame(width: 90, height: 90)
                .overlay {
                    VStack(spacing: 1) {
                        Text("\(entry.todaySteps)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("steps")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }

                // Stats side
                VStack(alignment: .leading, spacing: 8) {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.5)

                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: progress)
                            .tint(.green)
                            .scaleEffect(x: 1, y: 1.5)
                        Text("\(Int(progress * 100))% of \(entry.dailyGoal) goal")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    if entry.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 13))
                            Text("\(entry.currentStreak)-day streak")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                Spacer()
            }
            .padding(16)
        }
    }
}

// MARK: - Widget declaration

struct ElevateWidget: Widget {
    let kind = "ElevateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ElevateProvider()) { entry in
            ElevateWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Elevate")
        .description("Track your daily stair climbing progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
