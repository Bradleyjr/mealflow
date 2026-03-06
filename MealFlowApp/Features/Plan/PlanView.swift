import SwiftUI

struct PlanView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedDate: Date?
    @State private var detailDate: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PantryHeader(
                    eyebrow: "Weekly Table",
                    title: "Plan dinners like lining up cozy evenings",
                    detail: "Fill the week, spot repeats, and turn the whole thing into one calm grocery trip.",
                    icon: "calendar.badge.plus"
                )

                CozyStatRow(items: [
                    ("Planned", "\(plannedCount)/7", AppTheme.sage),
                    ("This week", selectedWeekLabel, AppTheme.butter),
                    ("Ready to shop", currentWeekRecipeCount > 0 ? "Yes" : "Not yet", AppTheme.terracotta)
                ])

                CozySectionHeader(
                    title: "This week",
                    detail: "Tap a day to open the full day detail."
                )

                ForEach(Array(store.weekDates.enumerated()), id: \.element) { index, day in
                    DayPlanCard(
                        day: day,
                        index: index,
                        entry: store.entry(for: day),
                        recipe: store.recipe(for: store.entry(for: day)?.recipeID),
                        repetitionInsight: store.entry(for: day)?.recipeID.flatMap { store.repetitionInsight(for: $0, on: day) },
                        onToggleComplete: {
                            if let id = store.entry(for: day)?.id {
                                CozyFeedback.tap(style: .soft)
                                store.toggleMealCompleted(id)
                            }
                        },
                        onSwap: {
                            CozyFeedback.tap()
                            selectedDate = day
                        },
                        onRemove: {
                            store.removeMeal(on: day)
                        },
                        onOpen: {
                            detailDate = day
                        }
                    )
                    .scrollTransition(.animated.threshold(.visible(0.2))) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.97)
                            .opacity(phase.isIdentity ? 1 : 0.84)
                    }
                }

                Button {
                    CozyFeedback.tap(style: .medium)
                    store.generateShoppingList()
                } label: {
                    HStack {
                        Image(systemName: "basket")
                        Text("Generate Shopping List")
                        Spacer()
                        Text("\(currentWeekRecipeCount) meals")
                            .font(.footnote.weight(.semibold))
                            .opacity(0.82)
                    }
                }
                .buttonStyle(CozyPrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .cozySurface()
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("This Week") {
                    store.jumpToCurrentWeek()
                }
                Button {
                    store.changeWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.changeWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedDate != nil },
            set: { if !$0 { selectedDate = nil } }
        )) {
            if let selectedDate {
                NavigationStack {
                    RecipePickerView(selectedDate: selectedDate)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { detailDate != nil },
            set: { if !$0 { detailDate = nil } }
        )) {
            if let detailDate {
                NavigationStack {
                    DayDetailView(date: detailDate)
                }
            }
        }
    }

    private var plannedCount: Int {
        store.weekDates.reduce(into: 0) { result, day in
            if store.entry(for: day) != nil {
                result += 1
            }
        }
    }

    private var currentWeekRecipeCount: Int {
        store.weekDates.compactMap { store.entry(for: $0)?.recipeID }.count
    }

    private var selectedWeekLabel: String {
        selectedWeekStart.formatted(.dateTime.month(.abbreviated).day()) + " - " +
        selectedWeekEnd.formatted(.dateTime.month(.abbreviated).day())
    }

    private var selectedWeekStart: Date { store.weekDates.first ?? .now }
    private var selectedWeekEnd: Date { store.weekDates.last ?? .now }
}

private struct DayPlanCard: View {
    let day: Date
    let index: Int
    let entry: MealPlanEntry?
    let recipe: Recipe?
    let repetitionInsight: RepetitionInsight?
    let onToggleComplete: () -> Void
    let onSwap: () -> Void
    let onRemove: () -> Void
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(day.formatted(.dateTime.weekday(.wide)))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.soil)
                        Text(day.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let entry {
                        Button(action: onToggleComplete) {
                            Image(systemName: entry.isCompleted ? "checkmark.seal.fill" : "seal")
                                .font(.title2)
                                .foregroundStyle(entry.isCompleted ? AppTheme.sage : AppTheme.soil.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    } else {
                        CozyPill(label: "Open", tint: AppTheme.butter, systemImage: "sparkles")
                    }
                }

                if let recipe {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 10) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(index.isMultiple(of: 2) ? AppTheme.terracotta.opacity(0.26) : AppTheme.sage.opacity(0.22))
                                .frame(width: 64, height: 64)
                                .overlay {
                                    Image(systemName: index.isMultiple(of: 2) ? "fork.knife" : "carrot")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.soil.opacity(0.7))
                                }

                            VStack(alignment: .leading, spacing: 7) {
                                Text(recipe.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.soil)
                                    .multilineTextAlignment(.leading)
                                Text(recipe.subtitle ?? "Dinner plan")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                HStack(spacing: 8) {
                                    if let total = recipe.totalTimeMinutes {
                                        CozyPill(label: "\(total) min", tint: AppTheme.butter, systemImage: "clock")
                                    }
                                    CozyPill(label: recipe.difficulty.rawValue.capitalized, tint: AppTheme.sage)
                                }
                            }
                            Spacer(minLength: 0)
                        }

                        if let repetitionInsight, repetitionInsight.shouldAlert {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("This has shown up \(repetitionInsight.countInRollingWindow) times in the last month.")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(AppTheme.soil)
                                Text("Maybe keep it if it is a comfort-night classic, or swap in something fresher.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppTheme.terracotta.opacity(0.10))
                            )
                        }

                        HStack(spacing: 10) {
                            Button("Swap", action: onSwap)
                                .buttonStyle(CozySecondaryButtonStyle())
                            Button("Remove", role: .destructive, action: onRemove)
                                .buttonStyle(CozySecondaryButtonStyle())
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.terracotta)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tap to add a meal")
                                .font(.headline)
                                .foregroundStyle(AppTheme.soil)
                            Text("Pick a recipe, leftovers, or something simple.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mealFlowCard(padding: 18)
        }
        .buttonStyle(.plain)
    }
}
