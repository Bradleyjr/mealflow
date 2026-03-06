import SwiftUI

struct DayDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let date: Date
    @State private var selectedMealType: MealType = .dinner
    @State private var showingPicker = false
    @State private var customMealName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PantryHeader(
                    eyebrow: "Day Detail",
                    title: date.formatted(.dateTime.weekday(.wide)),
                    detail: "Lay out the whole day like notes pinned to a kitchen corkboard.",
                    icon: "pin"
                )

                VStack(alignment: .leading, spacing: 12) {
                    CozySectionHeader(title: "Meals", detail: nil)
                    ForEach(MealType.allCases) { mealType in
                        mealRow(mealType)
                    }
                }
                .mealFlowCard()

                VStack(alignment: .leading, spacing: 12) {
                    CozySectionHeader(title: "Custom meal", detail: "For leftovers, takeout, or a spontaneous change of plans.")
                    Picker("Meal type", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { mealType in
                            Text(mealType.rawValue.capitalized).tag(mealType)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Leftovers, eating out, takeout", text: $customMealName)
                        .textFieldStyle(.roundedBorder)

                    Button("Save custom meal") {
                        CozyFeedback.tap()
                        store.assignCustomMeal(customMealName, to: date, mealType: selectedMealType)
                        customMealName = ""
                    }
                    .buttonStyle(CozySecondaryButtonStyle())
                    .disabled(customMealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .mealFlowCard()

                if !reminders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        CozySectionHeader(title: "Prep reminders", detail: "A calm nudge before dinner gets hectic.")
                        ForEach(reminders) { reminder in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.reminderText)
                                    .foregroundStyle(AppTheme.soil)
                                Text(reminder.triggerDate.formatted(.dateTime.month().day().hour().minute()))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppTheme.butter.opacity(0.18))
                            )
                        }
                    }
                    .mealFlowCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 80)
        }
        .cozySurface()
        .navigationTitle(date.formatted(.dateTime.month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                RecipePickerView(selectedDate: date, mealType: selectedMealType)
            }
        }
    }

    private var reminders: [ScheduledReminder] {
        store.entries(for: date).flatMap(\.scheduledReminders).sorted { $0.triggerDate < $1.triggerDate }
    }

    @ViewBuilder
    private func mealRow(_ mealType: MealType) -> some View {
        let entry = store.entry(for: date, mealType: mealType)
        let recipe = store.recipe(for: entry?.recipeID)

        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(entry == nil ? AppTheme.butter.opacity(0.35) : AppTheme.sage.opacity(0.24))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: entry == nil ? "plus" : "fork.knife")
                        .foregroundStyle(AppTheme.soil)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(mealType.rawValue.capitalized)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.soil)
                if let recipe {
                    Text(recipe.title)
                        .foregroundStyle(.primary)
                } else if let customMealName = entry?.customMealName {
                    Text(customMealName)
                        .foregroundStyle(.primary)
                } else {
                    Text("No meal assigned")
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Assign") {
                CozyFeedback.tap()
                selectedMealType = mealType
                showingPicker = true
            }
            .buttonStyle(CozySecondaryButtonStyle())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.panel.opacity(0.7))
        )
    }
}
