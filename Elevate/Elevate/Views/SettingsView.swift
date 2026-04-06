import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyStepGoal") private var dailyStepGoal: Int = 400
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @Environment(\.dismiss) private var dismiss
    let onGoalChanged: () -> Void

    private let presets = [100, 200, 300, 400, 500, 750, 1000, 1500]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text("\(dailyStepGoal)")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(.green)
                            Text("steps / day")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 6)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(presets, id: \.self) { preset in
                                Button {
                                    dailyStepGoal = preset
                                    onGoalChanged()
                                } label: {
                                    Text("\(preset)")
                                        .font(.system(.callout, design: .rounded).bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(dailyStepGoal == preset ? Color.green : Color(.tertiarySystemBackground))
                                        .foregroundStyle(dailyStepGoal == preset ? .black : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Stepper("Custom: \(dailyStepGoal) steps", value: $dailyStepGoal, in: 50...5000, step: 50)
                            .onChange(of: dailyStepGoal) { onGoalChanged() }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Daily Step Goal")
                } footer: {
                    Text("Streak and progress are calculated against this goal.")
                }

                Section {
                    NavigationLink {
                        CalibrationPage(onFinish: { dismiss() })
                            .navigationTitle("Calibrate")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Calibrate Step Detection", systemImage: "ruler")
                    }
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Walk up one flight of stairs to fine-tune step counting for your specific staircase.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
                }

                #if DEBUG
                Section("Developer") {
                    Button("Reset Onboarding", role: .destructive) {
                        hasCompletedOnboarding = false
                        dismiss()
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
