# Elevate — Stair Climbing Tracker: Design Spec

**Date:** 2026-04-04  
**Status:** Approved

---

## Context

The user wants an iOS app that uses iPhone sensors to track stair climbing, with the individual stair step as the unit of work. The motivation is dual: fitness tracking (log sessions, view progress) and gamification (streaks, achievements, personal bests). The app should sync data with Apple Health and lay groundwork for future uphill tracking and social features.

---

## Platform & Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Architecture:** MVVM
- **Persistence:** SwiftData
- **Sensors:** CoreMotion (`CMMotionManager`, `CMAltimeter`, `CMPedometer`)
- **Health sync:** HealthKit
- **Min iOS target:** iOS 17 (SwiftData requires iOS 17+)

---

## Sensor Strategy (Hybrid)

Three sensor sources working together:

1. **`CMMotionManager` (accelerometer @ 50Hz)** — vertical-axis (Z) peak detection. Each stair step produces a characteristic upward impulse pattern. A threshold-based peak detector counts individual steps.

2. **`CMAltimeter` (barometer)** — gates step counting. Steps are only counted when atmospheric pressure is decreasing (altitude rising). This distinguishes stair climbing from flat walking.

3. **`CMPedometer`** — runs in parallel. Provides floor count (displayed alongside step count as a reference metric). Used as a cross-check; not the authoritative step counter.

**Step detection algorithm:**
- Subscribe to accelerometer at 50Hz
- Buffer a rolling window of vertical-axis samples
- Detect peaks above a tunable threshold (initial: ~0.3g above baseline)
- Only emit a step event when the altimeter confirms altitude is rising
- Debounce: minimum 300ms between counted steps (prevents double-counting)

---

## Architecture

### MVVM Layers

```
View (SwiftUI)
  └── TrackingViewModel       — owns sensor pipeline, publishes session state
  └── HistoryViewModel        — reads sessions from repository
  └── AchievementViewModel    — reads achievements from repository

Repository
  └── SessionRepository       — SwiftData CRUD + HealthKit writes
  └── AchievementRepository   — SwiftData CRUD

Services
  └── SensorPipeline          — wraps CMMotionManager + CMAltimeter + CMPedometer
  └── StepDetector            — peak detection algorithm
  └── AchievementEngine       — evaluates unlock conditions post-session
  └── CalorieEstimator        — estimates calories from steps + body mass (reads HKQuantityType(.bodyMass) from HealthKit; falls back to 70kg default)
```

### Key Flows

**Start session:** User taps Start → `TrackingViewModel.startSession()` → `SensorPipeline.start()` → streams `stepCount`, `floors`, `elapsedTime`, `calories` via `@Published` properties.

**Stop session:** User taps Stop → `SensorPipeline.stop()` → `SessionRepository.save(session)` → `HealthKit.write(session)` → `AchievementEngine.evaluate(session)` → returns summary + any newly unlocked achievements.

---

## Data Model (SwiftData)

### `ClimbSession`
```swift
@Model class ClimbSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var steps: Int            // individual stair steps (from accelerometer)
    var floors: Int           // from CMPedometer (reference)
    var calories: Double      // estimated
    var duration: TimeInterval
    var type: ClimbType       // .stairs | .uphill (future)
    var shareToken: String?   // reserved for future social/leaderboard API
}

enum ClimbType: String, Codable {
    case stairs
    case uphill
}
```

### Daily Goal
Stored in `UserDefaults` as a single integer (`dailyStepGoal`, default: `400`). No per-day history — the goal is a global preference the user can change in a future Settings sheet.

### `Achievement`
```swift
@Model class Achievement {
    var id: String            // e.g. "first_climb", "streak_7"
    var name: String
    var achievementDescription: String
    var unlockedDate: Date?   // nil = locked
}
```

---

## HealthKit Integration

On session save, write:
- `HKQuantityType(.stepCount)` — session step count
- `HKQuantityType(.flightsClimbed)` — session floor count

HealthKit permission requested on first launch (usage description required in Info.plist).

---

## Navigation & Screen Flow

Single `ContentView` with two states (idle / active). Sheets for secondary screens. No tab bar.

```
ContentView (idle)
  ├── → ContentView (active session) [in-place animated transition on Start tap]
  │     └── → SessionSummaryView [sheet, on Stop tap]
  │           └── dismiss → ContentView (idle, updated)
  ├── → HistoryView [sheet]
  └── → AchievementsView [sheet]
```

### Idle State
- App name header
- Today's step count + daily goal progress bar
- 🔥 streak badge
- Large circular Start button (green, glowing)
- "History" and "Achievements" pill buttons at bottom

### Active Session State (animated transition from idle)
- Circular ring progress (fills toward daily goal, green)
- Step count inside ring (large)
- Below ring: floors · duration · calories in a row
- Pulsing "Detecting steps..." live indicator
- Red "Stop" button

### Session Summary Sheet
- "Session Complete" header + 🎉
- 2×2 stats grid (steps, floors, duration, calories)
- Achievement unlock banner (if any unlocked)
- "Saved to Apple Health" confirmation line
- "Done" button → dismiss

### History Sheet
- Weekly bar chart (steps per day, last 7 days)
- Scrollable session list, newest first
- Personal best sessions marked with 🏆

### Achievements Sheet
- 3-column badge grid
- Unlocked: full color + name
- Locked: greyed out + progress indicator (e.g. "47/100 steps")

---

## Gamification

### Streaks
- Increments each calendar day the user meets their daily step goal
- Breaks if a day is missed (no grace period in v1)
- Displayed as 🔥 N-day streak on idle screen

### Personal Bests
- Tracked per metric: most steps in a session, most floors, longest duration
- Record session marked with 🏆 in History

### Achievements (v1)

| ID | Name | Condition |
|---|---|---|
| `first_climb` | First Steps | Complete first session |
| `century` | Century Club | 100+ steps in one session |
| `floor_10` | High Rise | 10+ floors in one session |
| `streak_3` | Consistent | 3-day streak |
| `streak_7` | On Fire | 7-day streak |
| `lifetime_1k` | Stairmaster | 1,000 lifetime steps |

Achievements evaluated by `AchievementEngine` after each session completes.

### Social (Stretch Goal — Not v1)
`ClimbSession` has a reserved `shareToken: String?` field for future leaderboard API. No social features built in v1.

---

## Future: Uphill Mode

`ClimbType.uphill` is reserved in the data model. Detection would rely primarily on `CMAltimeter` (sustained altitude gain without the step cadence pattern of stairs). Switchable before starting a session.

---

## Verification Plan

1. **Sensor pipeline:** Walk up stairs with the app running. Step count should increment only while climbing (not while walking flat). Barometer gate is critical — test on flat ground to confirm no false positives.
2. **CMPedometer cross-check:** Floor count displayed should roughly match the number of flights climbed.
3. **HealthKit:** After a session, open the Health app and confirm step count and flights climbed appear under the correct date.
4. **Daily goal / streak:** Set a low goal (e.g. 10 steps), complete it, then check that the streak increments the next day.
5. **Achievements:** Complete a session with 100+ steps and confirm "Century Club" unlocks and animates in the summary sheet.
6. **SwiftData persistence:** Kill and relaunch the app — history sessions and achievements should persist.
