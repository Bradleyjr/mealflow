import SwiftUI

struct CookingModeView: View {
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe
    let servings: Int
    @State private var completedStepIDs: Set<UUID> = []

    var body: some View {
        List {
            Section("Ingredients") {
                ForEach(scaledIngredients) { ingredient in
                    Text("\(formattedQuantity(ingredient.quantity)) \(ingredient.unit) \(ingredient.name)")
                }
            }

            Section("Steps") {
                ForEach(recipe.instructions) { step in
                    Button {
                        if completedStepIDs.contains(step.id) {
                            completedStepIDs.remove(step.id)
                        } else {
                            completedStepIDs.insert(step.id)
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: completedStepIDs.contains(step.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(completedStepIDs.contains(step.id) ? AppTheme.sage : .secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.text)
                                    .foregroundStyle(.primary)
                                    .strikethrough(completedStepIDs.contains(step.id))
                                if let timer = step.timerMinutes {
                                    Label("\(timer) min timer", systemImage: "timer")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Cooking Mode")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var scaledIngredients: [Ingredient] {
        guard recipe.servings > 0 else { return recipe.ingredients }
        let factor = Double(servings) / Double(recipe.servings)
        return recipe.ingredients.map { ingredient in
            var ingredient = ingredient
            ingredient.quantity *= factor
            return ingredient
        }
    }

    private func formattedQuantity(_ quantity: Double) -> String {
        quantity == floor(quantity) ? "\(Int(quantity))" : quantity.formatted()
    }
}
