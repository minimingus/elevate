import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var profile: UserProfile? = nil
    @State private var isLoading = true
    @State private var showNameEntry = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Opt-in banner
                        if profile == nil {
                            Section {
                                OptInBanner { showNameEntry = true }
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                            }
                        }

                        // Weekly leaderboard
                        Section {
                            if entries.isEmpty {
                                Text("No climbers yet this week.\nBe the first!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(entries) { entry in
                                    LeaderboardRow(entry: entry, isMe: entry.displayName == profile?.displayName)
                                }
                            }
                        } header: {
                            HStack {
                                Text("This Week")
                                Spacer()
                                Text("Steps")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Manage profile
                        if profile != nil {
                            Section {
                                Button("Leave Leaderboard", role: .destructive) {
                                    Task { await removeProfile() }
                                }
                            } footer: {
                                Text("Removing your name hides you from the leaderboard. Your climbing data is kept.")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showNameEntry, onDismiss: {
                Task { await load() }
            }) {
                DisplayNameSheet(existing: profile?.displayName)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { msg in
                Text(msg)
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let entriesTask = SupabaseService.shared.fetchLeaderboard()
            async let profileTask = SupabaseService.shared.fetchProfile()
            (entries, profile) = try await (entriesTask, profileTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeProfile() async {
        do {
            try await SupabaseService.shared.deleteProfile()
            profile = nil
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Subviews

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isMe: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(entry.rank).opacity(0.15))
                    .frame(width: 36, height: 36)
                if entry.rank <= 3 {
                    Text(rankEmoji(entry.rank))
                        .font(.system(size: 18))
                } else {
                    Text("\(entry.rank)")
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(rankColor(entry.rank))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.subheadline.bold())
                    if isMe {
                        Text("you")
                            .font(.caption2.bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text("\(entry.weeklySteps)")
                .font(.system(.body, design: .rounded).bold())
                .foregroundStyle(isMe ? .green : .primary)
        }
        .listRowBackground(isMe ? Color.green.opacity(0.07) : Color.clear)
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
}

private struct OptInBanner: View {
    let onJoin: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Join the Leaderboard")
                .font(.headline)
            Text("Pick a display name to appear on the weekly leaderboard. This is completely optional.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Choose a Name", action: onJoin)
                .font(.subheadline.bold())
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.green)
                .clipShape(Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Display name sheet

struct DisplayNameSheet: View {
    let existing: String?
    @State private var name: String
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss

    init(existing: String?) {
        self.existing = existing
        _name = State(initialValue: existing ?? "")
    }

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display name", text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Your name on the leaderboard")
                } footer: {
                    Text("2–30 characters. This is the only information visible to other users.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Join Leaderboard" : "Change Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(!isValid || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await SupabaseService.shared.saveProfile(
                displayName: name.trimmingCharacters(in: .whitespaces)
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
