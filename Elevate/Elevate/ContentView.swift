import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var trackingVM: TrackingViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var achievementVM: AchievementViewModel

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showHistory = false
    @State private var showAchievements = false

    var body: some View {
        Group {
            if trackingVM.isRunning {
                ActiveSessionView(trackingVM: trackingVM) {
                    Task { await trackingVM.stop() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                IdleView(
                    historyVM: historyVM,
                    onStart: { Task { await trackingVM.start() } },
                    onHistory: { showHistory = true },
                    onAchievements: { showAchievements = true }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: trackingVM.isRunning)
        .sheet(isPresented: $showHistory) {
            HistoryView(vm: historyVM)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView(vm: achievementVM)
        }
        .sheet(item: $trackingVM.summary) { summary in
            SessionSummaryView(summary: summary) {
                trackingVM.summary = nil
                historyVM.load()
                achievementVM.load()
            }
        }
        .task {
            let hk = HealthKitService()
            try? await hk.requestPermission()
        }
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView()
        }
    }
}
