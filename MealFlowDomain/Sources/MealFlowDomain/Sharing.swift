import Foundation

public enum ShoppingListShareFormatter {
    public static func text(for list: ShoppingList) -> String {
        let grouped = Dictionary(grouping: list.items.filter { !$0.isChecked }, by: \.category)
        let orderedCategories = IngredientCategory.allCases.filter { grouped[$0] != nil }
        let lines = orderedCategories.flatMap { category -> [String] in
            let header = category.rawValue.capitalized
            let items = grouped[category, default: []].map { item in
                let quantity = item.totalQuantity == floor(item.totalQuantity)
                    ? "\(Int(item.totalQuantity))"
                    : item.totalQuantity.formatted()
                return "- \(quantity) \(item.unit) \(item.ingredientName)"
            }
            return [header] + items + [""]
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
