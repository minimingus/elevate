import Foundation
import Supabase

// MARK: - Row types (mirror Supabase table columns)

struct SessionRow: Codable {
    let id: UUID
    let userId: UUID
    let startDate: Date
    let endDate: Date
    let steps: Int
    let floors: Int
    let calories: Double

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case steps, floors, calories
    }
}

struct UserProfile: Codable {
    let userId: UUID
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
    }
}

struct LeaderboardEntry: Codable, Identifiable {
    let displayName: String
    let weeklySteps: Int
    let rank: Int
    var id: String { displayName }

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case weeklySteps = "weekly_steps"
        case rank
    }
}

struct AchievementRow: Codable {
    let userId: UUID
    let achievementId: String
    let unlockedDate: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case achievementId = "achievement_id"
        case unlockedDate = "unlocked_date"
    }
}

// MARK: - Service

actor SupabaseService {
    static let shared = SupabaseService()

    private let client = SupabaseClient(
        supabaseURL: URL(string: "https://refyvpjqweolwagnrkcg.supabase.co")!,
        supabaseKey: "sb_publishable_ojyh0_ejmgwQ-gBhOxMM1A_3YKEhntq"
    )

    private init() {}

    // MARK: - Auth

    /// Signs in anonymously on first launch. Supabase SDK persists the session
    /// in the Keychain automatically, so this survives app reinstalls.
    func ensureSignedIn() async throws {
        if client.auth.currentUser != nil { return }
        try await client.auth.signInAnonymously()
    }

    private var currentUserId: UUID {
        get throws {
            guard let user = client.auth.currentUser else {
                throw SupabaseError.notAuthenticated
            }
            return user.id
        }
    }

    // MARK: - Sessions

    func uploadSession(_ session: ClimbSession) async throws {
        try await ensureSignedIn()
        let row = SessionRow(
            id: session.id,
            userId: try currentUserId,
            startDate: session.startDate,
            endDate: session.endDate,
            steps: session.steps,
            floors: session.floors,
            calories: session.calories
        )
        try await client.from("climb_sessions").upsert(row).execute()
    }

    func fetchSessions() async throws -> [SessionRow] {
        try await ensureSignedIn()
        return try await client
            .from("climb_sessions")
            .select()
            .order("start_date", ascending: false)
            .execute()
            .value
    }

    // MARK: - Achievements

    func uploadAchievement(id: String, unlockedDate: Date) async throws {
        try await ensureSignedIn()
        let row = AchievementRow(
            userId: try currentUserId,
            achievementId: id,
            unlockedDate: unlockedDate
        )
        try await client.from("achievements").upsert(row).execute()
    }

    func fetchAchievements() async throws -> [AchievementRow] {
        try await ensureSignedIn()
        return try await client
            .from("achievements")
            .select()
            .execute()
            .value
    }

    // MARK: - Profile

    func fetchProfile() async throws -> UserProfile? {
        try await ensureSignedIn()
        let userId = try currentUserId
        let profiles: [UserProfile] = try await client
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return profiles.first
    }

    func saveProfile(displayName: String) async throws {
        try await ensureSignedIn()
        let profile = UserProfile(userId: try currentUserId, displayName: displayName)
        try await client.from("user_profiles").upsert(profile).execute()
    }

    func deleteProfile() async throws {
        try await ensureSignedIn()
        let userId = try currentUserId
        try await client
            .from("user_profiles")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }

    // MARK: - Leaderboard

    func fetchLeaderboard() async throws -> [LeaderboardEntry] {
        try await ensureSignedIn()
        return try await client.rpc("weekly_leaderboard").execute().value
    }
}

enum SupabaseError: Error {
    case notAuthenticated
}
