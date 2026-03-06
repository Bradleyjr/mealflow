import Foundation

public enum ShoppingListGenerator {
    public static func generate(
        weekStartDate: Date,
        entries: [MealPlanEntry],
        recipes: [Recipe],
        existingList: ShoppingList? = nil
    ) -> ShoppingList {
        let recipeIndex = Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, $0) })
        let previousGenerated = Dictionary(
            uniqueKeysWithValues: (existingList?.items ?? [])
                .filter { !$0.isManuallyAdded }
                .map { ($0.normalizedKey, $0) }
        )
        let manualItems = existingList?.items.filter(\.isManuallyAdded) ?? []

        var itemsByKey: [String: ShoppingListItem] = [:]
        var mismatchedUnitsByName: [String: Set<String>] = [:]

        for entry in entries {
            guard let recipeID = entry.recipeID, let recipe = recipeIndex[recipeID] else { continue }
            for ingredient in recipe.ingredients {
                let item = ShoppingListItem(
                    ingredientName: ingredient.name,
                    totalQuantity: ingredient.quantity,
                    unit: ingredient.unit,
                    category: ingredient.category,
                    sourceRecipes: [recipe.title]
                )
                let nameKey = item.normalizedName
                mismatchedUnitsByName[nameKey, default: []].insert(item.unit.lowercased())

                if var existing = itemsByKey[item.normalizedKey] {
                    existing.totalQuantity += item.totalQuantity
                    existing.sourceRecipes = Array(Set(existing.sourceRecipes + item.sourceRecipes)).sorted()
                    itemsByKey[item.normalizedKey] = existing
                } else {
                    var generated = item
                    if let previous = previousGenerated[item.normalizedKey] {
                        generated.isChecked = previous.isChecked
                    }
                    itemsByKey[item.normalizedKey] = generated
                }
            }
        }

        let generatedItems = itemsByKey.values.map { item -> ShoppingListItem in
            var item = item
            let units = mismatchedUnitsByName[item.normalizedName] ?? []
            if units.count > 1 {
                let alternateUnits = units.filter { $0 != item.unit.lowercased() }.sorted().joined(separator: ", ")
                item.mismatchNote = alternateUnits.isEmpty ? nil : "Also planned in \(alternateUnits)"
            }
            return item
        }
        .sorted {
            if $0.category == $1.category {
                return $0.ingredientName.localizedCaseInsensitiveCompare($1.ingredientName) == .orderedAscending
            }
            return $0.category.rawValue < $1.category.rawValue
        }

        return ShoppingList(
            weekStartDate: weekStartDate,
            generatedFromEntryIDs: entries.map(\.id),
            items: generatedItems + manualItems
        )
    }
}
