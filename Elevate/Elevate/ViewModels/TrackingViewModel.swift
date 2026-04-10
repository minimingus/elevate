import Foundation
import Combine
import SwiftData
import WidgetKit

struct SessionSummary: Identifiable {
    let id = UUID()
    let steps: Int
    let floors: Int
    let elevationMeters: Double
    let duration: TimeInterval
    let newlyUnlocked: [Achievement]
}

@MainActor
final class TrackingViewModel: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var steps: Int = 0
    @Published private(set) var floors: Int = 0
    @Published private(set) var elevationMeters: Double = 0
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published var summary: SessionSummary? = nil

    /// Steps per minute — 0 until at least 1 minute has elapsed
    var pace: Double {
        guard elapsedTime >= 1 else { return 0 }
        return Double(steps) / (elapsedTime / 60.0)
    }

    private let pipeline: SensorPipeline
    private let sessionRepo: SessionRepository
    private let achievementRepo: AchievementRepository
    private let healthKit: HealthKitService
    private var startDate: Date?
    private var timer: AnyCancellable?
    private var pipelineCancellables = Set<AnyCancellable>()
    private var goalHapticFired = false
    private var todayStepsBaseline: Int = 0  // steps from prior sessions today (loaded at session start)

    init(pipeline: SensorPipeline, sessionRepo: SessionRepository,
         achievementRepo: AchievementRepository, healthKit: HealthKitService) {
        self.pipeline = pipeline
        self.sessionRepo = sessionRepo
        self.achievementRepo = achievementRepo
        self.healthKit = healthKit
    }

    func start() async {
        guard !isRunning else { return }
        pipelineCancellables.removeAll()
        timer?.cancel()
        isRunning = true
        let now = Date()
        startDate = now
        elapsedTime = 0
        summary = nil
        goalHapticFired = false

        pipeline.$steps
            .receive(on: RunLoop.main)
            .sink { [weak self] s in
                guard let self else { return }
                let previous = self.steps
                self.steps = s
                if s > previous { HapticService.step() }
                let goal = UserDefaults.standard.dailyStepGoal
                if !self.goalHapticFired && goal > 0 && s >= goal {
                    self.goalHapticFired = true
                    HapticService.goalReached()
                }
            }
            .store(in: &pipelineCancellables)

        pipeline.$floors
            .receive(on: RunLoop.main)
            .sink { [weak self] f in self?.floors = f }
            .store(in: &pipelineCancellables)

        pipeline.$elevationMeters
            .receive(on: RunLoop.main)
            .sink { [weak self] e in self?.elevationMeters = e }
            .store(in: &pipelineCancellables)

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
                let elapsed = Int(self.elapsedTime)
                Task {
                    await LiveActivityService.shared.update(
                        steps: self.steps,
                        floors: self.floors,
                        elapsedSeconds: elapsed
                    )
                }
                self.pushWatchState()
            }

        todayStepsBaseline = (try? sessionRepo.todaySteps()) ?? 0
        pipeline.start()
        HapticService.sessionStart()
        LiveActivityService.shared.start(at: now)
        pushWatchState()
    }

    func stop() async {
        timer?.cancel()
        timer = nil
        pipelineCancellables.removeAll()
        let (finalSteps, finalFloors, finalElevation) = pipeline.stop()
        let end = Date()
        let start = startDate ?? end
        isRunning = false

        let session = ClimbSession(
            startDate: start, endDate: end,
            steps: finalSteps, floors: finalFloors,
            elevationMeters: finalElevation
        )

        try? sessionRepo.save(session)
        try? await healthKit.write(session: session)
        Task { try? await SupabaseService.shared.uploadSession(session) }

        let allSessions = (try? sessionRepo.fetchAll()) ?? []
        let lifetimeSteps = (try? sessionRepo.lifetimeSteps()) ?? 0
        let streak = currentStreak(from: allSessions)
        let candidateIds = AchievementEngine.evaluate(
            session: session, allSessions: allSessions,
            currentStreak: streak, lifetimeSteps: lifetimeSteps
        )
        let alreadyUnlocked = Set(((try? achievementRepo.fetchAll()) ?? [])
            .compactMap { $0.unlockedDate != nil ? $0.id : nil })
        let toUnlock = candidateIds.subtracting(alreadyUnlocked)
        try? achievementRepo.unlock(ids: toUnlock)
        if !toUnlock.isEmpty {
            HapticService.achievementUnlocked()
            let unlockDate = Date()
            for id in toUnlock {
                Task { try? await SupabaseService.shared.uploadAchievement(id: id, unlockedDate: unlockDate) }
            }
        }

        let newAchievements = ((try? achievementRepo.fetchAll()) ?? [])
            .filter { toUnlock.contains($0.id) }

        summary = SessionSummary(
            steps: finalSteps, floors: finalFloors,
            elevationMeters: finalElevation,
            duration: session.duration,
            newlyUnlocked: newAchievements
        )

        let todaySteps = (try? sessionRepo.todaySteps()) ?? finalSteps
        // App Group sharing requires a paid developer account — guarded for local dev
        if let sharedDefaults = UserDefaults(suiteName: "group.com.mingus.Elevate") {
            sharedDefaults.set(todaySteps, forKey: "todaySteps")
            sharedDefaults.set(UserDefaults.standard.dailyStepGoal, forKey: "dailyStepGoal")
            sharedDefaults.set(streak, forKey: "currentStreak")
            WidgetCenter.shared.reloadAllTimelines()
        }

        await LiveActivityService.shared.end(
            steps: finalSteps, floors: finalFloors,
            elapsedSeconds: Int(end.timeIntervalSince(start))
        )

        // Push idle state to Watch (session ended)
        let streak = currentStreak(from: (try? sessionRepo.fetchAll()) ?? [])
        PhoneConnectivityService.shared.push(
            isRunning: false, steps: 0, floors: 0, elapsed: 0,
            todaySteps: (try? sessionRepo.todaySteps()) ?? finalSteps,
            streak: streak,
            goal: UserDefaults.standard.dailyStepGoal
        )

        NotificationService.shared.scheduleDaily(
            currentStreak: streak,
            todaySteps: todaySteps,
            dailyGoal: UserDefaults.standard.dailyStepGoal
        )
        HapticService.sessionStop()
    }

    var dailyGoalProgress: Double {
        let goal = UserDefaults.standard.dailyStepGoal
        guard goal > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(goal))
    }

    // MARK: - Private

    private func currentStreak(from sessions: [ClimbSession]) -> Int {
        calculateStreak(from: sessions, goal: UserDefaults.standard.dailyStepGoal)
    }

    private func pushWatchState() {
        PhoneConnectivityService.shared.push(
            isRunning: isRunning,
            steps: steps,
            floors: floors,
            elapsed: Int(elapsedTime),
            todaySteps: todayStepsBaseline + steps,
            streak: 0,   // streak not needed during active session
            goal: UserDefaults.standard.dailyStepGoal
        )
    }
}
