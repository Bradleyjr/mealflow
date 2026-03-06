import SwiftUI

struct RecipePickerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let selectedDate: Date
    var mealType: MealType = .dinner
    @State private var searchText = ""

    var body: some View {
        List {
            if !suggested.isEmpty {
                Section("Suggested") {
                    ForEach(suggested, id: \.recipe.id) { suggestion in
                        recipeButton(recipe: suggestion.recipe, subtitle: "Suggestion score \(suggestion.score)")
                    }
                }
            }

            Section("All Recipes") {
                ForEach(filteredRecipes) { recipe in
                    recipeButton(
                        recipe: recipe,
                        subtitle: recipe.lastCookedDate.map { "Last made \($0.formatted(.dateTime.month().day()))" } ?? "Never cooked"
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            CozyBackground()
        }
        .searchable(text: $searchText)
        .navigationTitle("Pick Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var suggested: [RecipeSuggestion] {
        Array(store.suggestedRecipes(for: selectedDate).prefix(5))
    }

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return store.recipes
        }
        let query = searchText.lowercased()
        return store.recipes.filter { $0.title.lowercased().contains(query) }
    }

    @ViewBuilder
    private func recipeButton(recipe: Recipe, subtitle: String) -> some View {
        Button {
            CozyFeedback.tap()
            store.assignRecipe(recipe, to: selectedDate, mealType: mealType)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.soil)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }
}
