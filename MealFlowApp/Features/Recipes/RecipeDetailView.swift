import SwiftUI

struct RecipeDetailView: View {
    @Environment(AppStore.self) private var store
    let recipeID: UUID
    @State private var selectedServings = 4
    @State private var planDate = Date()
    @State private var showingPlanPicker = false
    @State private var showingCookingMode = false

    var body: some View {
        ScrollView {
            if let recipe = store.recipe(for: recipeID) {
                VStack(alignment: .leading, spacing: 20) {
                    hero(for: recipe)

                    CozyStatRow(items: [
                        ("Servings", "\(selectedServings)", AppTheme.butter),
                        ("Made", "\(recipe.timesCooked)x", AppTheme.sage),
                        ("Difficulty", recipe.difficulty.rawValue.capitalized, AppTheme.terracotta)
                    ])

                    VStack(alignment: .leading, spacing: 12) {
                        CozySectionHeader(
                            title: "Ingredients",
                            detail: "Scale the card like you are cooking for one more chair at the table."
                        )
                        Stepper("Scale servings: \(selectedServings)", value: $selectedServings, in: 1...12)
                            .tint(AppTheme.terracotta)

                        ForEach(scaledIngredients(for: recipe)) { ingredient in
                            HStack(alignment: .top, spacing: 14) {
                                Text(quantityText(for: ingredient))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.soil)
                                    .frame(width: 84, alignment: .leading)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ingredient.name)
                                        .foregroundStyle(AppTheme.soil)
                                    if let notes = ingredient.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppTheme.panel.opacity(0.72))
                            )
                        }
                    }
                    .mealFlowCard()

                    VStack(alignment: .leading, spacing: 12) {
                        CozySectionHeader(
                            title: "Instructions",
                            detail: "Written like recipe-card steps, not a wall of text."
                        )
                        ForEach(recipe.instructions) { step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(step.stepNumber)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.soil)
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.sage.opacity(0.17), in: Circle())
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(step.text)
                                        .foregroundStyle(AppTheme.soil)
                                    if let timer = step.timerMinutes {
                                        CozyPill(label: "\(timer) min timer", tint: AppTheme.butter, systemImage: "timer")
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppTheme.panel.opacity(0.68))
                            )
                        }
                    }
                    .mealFlowCard()

                    if !recipe.prepRequirements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            CozySectionHeader(
                                title: "Prep needed",
                                detail: "Little reminders for tomorrow-you."
                            )
                            ForEach(recipe.prepRequirements) { requirement in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(requirement.description)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.soil)
                                    Text("Needs \(Int(requirement.leadTimeHours)) hours lead time")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(AppTheme.terracotta.opacity(0.12))
                                )
                            }
                        }
                        .mealFlowCard()
                    }

                    if let notes = recipe.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            CozySectionHeader(title: "Notes", detail: "The little grandmother wisdom you do not want to lose.")
                            Text(notes)
                                .foregroundStyle(AppTheme.soil)
                        }
                        .mealFlowCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 120)
                .onAppear {
                    selectedServings = recipe.servings
                }
            }
        }
        .cozySurface()
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button("Add to Meal Plan") {
                    CozyFeedback.tap()
                    showingPlanPicker = true
                }
                .buttonStyle(CozySecondaryButtonStyle())

                Button("Start Cooking") {
                    CozyFeedback.tap(style: .medium)
                    showingCookingMode = true
                }
                .buttonStyle(CozyPrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showingPlanPicker) {
            if let recipe = store.recipe(for: recipeID) {
                NavigationStack {
                    Form {
                        DatePicker("Meal date", selection: $planDate, displayedComponents: .date)
                        Button("Add to Dinner Plan") {
                            store.assignRecipe(recipe, to: planDate, mealType: .dinner)
                            showingPlanPicker = false
                        }
                    }
                    .navigationTitle("Plan Recipe")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .sheet(isPresented: $showingCookingMode) {
            if let recipe = store.recipe(for: recipeID) {
                NavigationStack {
                    CookingModeView(recipe: recipe, servings: selectedServings)
                }
            }
        }
    }

    @ViewBuilder
    private func hero(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.terracotta.opacity(0.88), AppTheme.soil.opacity(0.84), AppTheme.sage.opacity(0.66)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 290)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.20))
                        .padding(24)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let subtitle = recipe.subtitle, !subtitle.isEmpty {
                            CozyPill(label: subtitle, tint: .white.opacity(0.85))
                        }
                        Text(recipe.title)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            if let prep = recipe.prepTimeMinutes {
                                CozyPill(label: "Prep \(prep)m", tint: .white.opacity(0.88), systemImage: "clock")
                            }
                            if let cook = recipe.cookTimeMinutes {
                                CozyPill(label: "Cook \(cook)m", tint: .white.opacity(0.88), systemImage: "flame")
                            }
                        }
                    }
                    .padding(22)
                }
        }
    }

    private func quantityText(for ingredient: Ingredient) -> String {
        if ingredient.quantity == floor(ingredient.quantity) {
            return "\(Int(ingredient.quantity)) \(ingredient.unit)"
        }
        return "\(ingredient.quantity.formatted()) \(ingredient.unit)"
    }

    private func scaledIngredients(for recipe: Recipe) -> [Ingredient] {
        guard recipe.servings > 0 else { return recipe.ingredients }
        let factor = Double(selectedServings) / Double(recipe.servings)
        return recipe.ingredients.map { ingredient in
            var ingredient = ingredient
            ingredient.quantity *= factor
            return ingredient
        }
    }
}
