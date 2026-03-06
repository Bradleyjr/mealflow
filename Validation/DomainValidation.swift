import Foundation

@main
struct DomainValidation {
    static func main() {
        validateWeekMath()
        validateRepetitionInsight()
        validateShoppingAggregation()
        validateUnitMismatchNotes()
        validateJSONLDImport()
        validateReminderScheduling()
        validateShareFormatting()
        print("MealFlowDomain validation passed")
    }

    private static func validateWeekMath() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let date = formatter.date(from: "2026-03-05")!
        let weekStart = WeekMath.startOfWeek(for: date, calendar: Calendar(identifier: .gregorian))
        precondition(formatter.string(from: weekStart) == "2026-03-02")
    }

    private static func validateRepetitionInsight() {
        let calendar = Calendar(identifier: .gregorian)
        let recipeID = UUID()
        let baseDate = calendar.startOfDay(for: .now)
        let entries = [
            MealPlanEntry(date: calendar.date(byAdding: .day, value: -20, to: baseDate)!, recipeID: recipeID),
            MealPlanEntry(date: calendar.date(byAdding: .day, value: -10, to: baseDate)!, recipeID: recipeID),
            MealPlanEntry(date: baseDate, recipeID: recipeID)
        ]

        let insight = MealPlanAnalytics.repetitionInsight(for: recipeID, on: baseDate, entries: entries, calendar: calendar)
        precondition(insight.countInRollingWindow == 3)
        precondition(insight.shouldAlert)
    }

    private static func validateShoppingAggregation() {
        let weekStart = WeekMath.startOfWeek(for: .now)
        let tacoRecipe = Recipe(
            title: "Tacos",
            ingredients: [
                Ingredient(name: "Ground Beef", quantity: 1, unit: "lb", category: .meat),
                Ingredient(name: "Lime", quantity: 2, unit: "whole", category: .produce)
            ]
        )
        let chiliRecipe = Recipe(
            title: "Chili",
            ingredients: [
                Ingredient(name: "Ground Beef", quantity: 2, unit: "lb", category: .meat)
            ]
        )
        let entries = [
            MealPlanEntry(date: weekStart, recipeID: tacoRecipe.id),
            MealPlanEntry(date: weekStart.addingTimeInterval(86_400), recipeID: chiliRecipe.id)
        ]
        let priorList = ShoppingList(
            weekStartDate: weekStart,
            generatedFromEntryIDs: [],
            items: [
                ShoppingListItem(
                    ingredientName: "Paper Towels",
                    totalQuantity: 1,
                    unit: "pack",
                    category: .other,
                    isChecked: true,
                    isManuallyAdded: true
                )
            ]
        )

        let list = ShoppingListGenerator.generate(
            weekStartDate: weekStart,
            entries: entries,
            recipes: [tacoRecipe, chiliRecipe],
            existingList: priorList
        )
        let beef = list.items.first { $0.normalizedKey == "ground beef|lb" }
        precondition(beef?.totalQuantity == 3)
        precondition(Set(beef?.sourceRecipes ?? []) == Set(["Tacos", "Chili"]))
        precondition(list.items.contains(where: { $0.ingredientName == "Paper Towels" && $0.isManuallyAdded }))
    }

    private static func validateUnitMismatchNotes() {
        let weekStart = WeekMath.startOfWeek(for: .now)
        let recipe = Recipe(
            title: "Breakfast",
            ingredients: [
                Ingredient(name: "Milk", quantity: 2, unit: "cups", category: .dairy),
                Ingredient(name: "Milk", quantity: 1, unit: "pint", category: .dairy)
            ]
        )
        let list = ShoppingListGenerator.generate(
            weekStartDate: weekStart,
            entries: [MealPlanEntry(date: weekStart, recipeID: recipe.id)],
            recipes: [recipe]
        )
        precondition(list.items.count == 2)
        precondition(list.items.allSatisfy { $0.mismatchNote != nil })
    }

    private static func validateJSONLDImport() {
        let html = """
        <script type="application/ld+json">
        {"@context":"https://schema.org","@type":"Recipe","name":"Soup","recipeYield":"4 servings","recipeIngredient":["1 whole onion"],"recipeInstructions":["Cook onions","Simmer soup"]}
        </script>
        """
        let draft = RecipeImporter.parseHTML(html, sourceURL: "https://example.com/soup")
        precondition(draft.title == "Soup")
        precondition(draft.ingredients.count == 1)
        precondition(draft.instructions.count == 2)
    }

    private static func validateReminderScheduling() {
        let formatter = ISO8601DateFormatter()
        let mealDate = formatter.date(from: "2026-03-05T00:00:00Z")!
        let recipe = Recipe(
            title: "Roast",
            prepRequirements: [PrepRequirement(description: "Defrost", leadTimeHours: 10, reminderText: "Defrost the roast")]
        )
        let entry = MealPlanEntry(date: mealDate, recipeID: recipe.id)
        let reminders = ReminderScheduler.scheduledReminders(
            for: entry,
            recipe: recipe,
            preferences: ReminderPreferences(prepRemindersEnabled: true),
            calendar: Calendar(identifier: .gregorian)
        )
        precondition(reminders.count == 1)
    }

    private static func validateShareFormatting() {
        let list = ShoppingList(
            weekStartDate: .now,
            generatedFromEntryIDs: [],
            items: [
                ShoppingListItem(ingredientName: "Milk", totalQuantity: 1, unit: "gallon", category: .dairy),
                ShoppingListItem(ingredientName: "Bread", totalQuantity: 1, unit: "loaf", category: .bakery, isChecked: true)
            ]
        )
        let text = ShoppingListShareFormatter.text(for: list)
        precondition(text.contains("Milk"))
        precondition(!text.contains("Bread"))
    }
}
