import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var householdName = ""
    @State private var displayName = ""
    @State private var inviteCode = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PantryHeader(
                    eyebrow: "Cottage Settings",
                    title: "Household details and little preferences",
                    detail: "Where the practical bits still feel warm and human.",
                    icon: "gearshape.2"
                )

                householdSection
                preferencesSection
                remindersSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 80)
        }
        .cozySurface()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var householdSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Household", detail: "Share the planning table with someone else.")

            if let household = store.household {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        CozyPill(label: household.name, tint: AppTheme.butter, systemImage: "house")
                        CozyPill(label: household.inviteCode, tint: AppTheme.sage, systemImage: "envelope")
                    }
                    ForEach(household.members) { member in
                        HStack {
                            Circle()
                                .fill(member.role == .owner ? AppTheme.terracotta.opacity(0.25) : AppTheme.sage.opacity(0.25))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Image(systemName: member.role == .owner ? "crown" : "person")
                                        .foregroundStyle(AppTheme.soil)
                                }
                            Text(member.displayName)
                                .foregroundStyle(AppTheme.soil)
                            Spacer()
                            Text(member.role.rawValue.capitalized)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.panel.opacity(0.65))
                        )
                    }
                    Button("Leave Household", role: .destructive) {
                        store.leaveHousehold()
                    }
                    .buttonStyle(CozySecondaryButtonStyle())
                }
            } else {
                TextField("Household name", text: $householdName)
                    .textFieldStyle(.roundedBorder)
                TextField("Display name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                Button("Create Household") {
                    CozyFeedback.tap()
                    store.createHousehold(name: householdName, ownerDisplayName: displayName.isEmpty ? "Owner" : displayName)
                    householdName = ""
                }
                .buttonStyle(CozyPrimaryButtonStyle())
                .disabled(householdName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Divider()

                TextField("Join code", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                Button("Join Household") {
                    CozyFeedback.tap()
                    store.joinHousehold(code: inviteCode, displayName: displayName.isEmpty ? "Member" : displayName)
                    inviteCode = ""
                }
                .buttonStyle(CozySecondaryButtonStyle())
                .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 6)
            }
        }
        .mealFlowCard()
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Preferences", detail: "The little defaults that make the app feel yours.")
            Stepper("Default servings: \(store.preferences.defaultServings)", value: bind(\.defaultServings), in: 1...12)
            Picker("Default meal", selection: bind(\.defaultMealType)) {
                ForEach(MealType.allCases) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            Picker("Theme", selection: bind(\.theme)) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            Picker("Measurement", selection: bind(\.measurementSystem)) {
                Text("US").tag("US")
                Text("Metric").tag("Metric")
            }
        }
        .mealFlowCard()
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Reminders", detail: "Gentle nudges instead of nagging.")
            Toggle("Prep reminders", isOn: reminderBinding(\.prepRemindersEnabled))
            Toggle("Weekly planning reminder", isOn: reminderBinding(\.weeklyPlanningReminderEnabled))
            Stepper("Morning reminder hour: \(store.preferences.reminderPreferences.preferredMorningHour):00", value: reminderBinding(\.preferredMorningHour), in: 6...11)
            Stepper("Evening reminder hour: \(store.preferences.reminderPreferences.preferredEveningHour):00", value: reminderBinding(\.preferredEveningHour), in: 17...22)
            Stepper("Assumed dinner hour: \(store.preferences.reminderPreferences.assumedDinnerHour):00", value: reminderBinding(\.assumedDinnerHour), in: 16...21)
        }
        .mealFlowCard()
    }

    private func bind<Value>(_ keyPath: WritableKeyPath<UserPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { store.preferences[keyPath: keyPath] },
            set: { store.updatePreference(keyPath, value: $0) }
        )
    }

    private func reminderBinding<Value>(_ keyPath: WritableKeyPath<ReminderPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { store.preferences.reminderPreferences[keyPath: keyPath] },
            set: { newValue in
                var reminders = store.preferences.reminderPreferences
                reminders[keyPath: keyPath] = newValue
                store.updatePreference(\.reminderPreferences, value: reminders)
            }
        )
    }
}
