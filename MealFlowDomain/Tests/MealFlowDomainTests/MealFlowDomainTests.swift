import Foundation
import Testing
@testable import MealFlowDomain

@Test func startOfWeekAnchorsToMonday() {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]

    let date = formatter.date(from: "2026-03-05")!
    let weekStart = WeekMath.startOfWeek(for: date, calendar: Calendar(identifier: .gregorian))

    #expect(formatter.string(from: weekStart) == "2026-03-02")
}

@Test func repetitionInsightTriggersAfterThirdUseInRollingWindow() {
    let calendar = Calendar(identifier: .gregorian)
    let recipeID = UUID()
    let baseDate = calendar.startOfDay(for: .now)

    let entries = [
        MealPlanEntry(date: calendar.date(byAdding: .day, value: -20, to: baseDate)!, recipeID: recipeID),
        MealPlanEntry(date: calendar.date(byAdding: .day, value: -10, to: baseDate)!, recipeID: recipeID),
        MealPlanEntry(date: baseDate, recipeID: recipeID)
    ]

    let insight = MealPlanAnalytics.repetitionInsight(
        for: recipeID,
        on: baseDate,
        entries: entries,
        calendar: calendar
    )

    #expect(insight.countInRollingWindow == 3)
    #expect(insight.shouldAlert)
}

@Test func shoppingListAggregatesDuplicateIngredientsAndPreservesManualItems() {
    let weekStart = WeekMath.startOfWeek(for: .now)
    let recipeOne = Recipe(
        title: "Tacos",
        ingredients: [
            Ingredient(name: "Ground Beef", quantity: 1, unit: "lb", category: .meat),
            Ingredient(name: "Lime", quantity: 2, unit: "whole", category: .produce)
        ]
    )
    let recipeTwo = Recipe(
        title: "Chili",
        ingredients: [
            Ingredient(name: "Ground Beef", quantity: 2, unit: "lb", category: .meat)
        ]
    )
    let entries = [
        MealPlanEntry(date: weekStart, recipeID: recipeOne.id),
        MealPlanEntry(date: weekStart.addingTimeInterval(86_400), recipeID: recipeTwo.id)
    ]
    let existing = ShoppingList(
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
        recipes: [recipeOne, recipeTwo],
        existingList: existing
    )

    let beef = try #require(list.items.first(where: { $0.normalizedKey == "ground beef|lb" }))
    #expect(beef.totalQuantity == 3)
    #expect(Set(beef.sourceRecipes) == Set(["Tacos", "Chili"]))
    #expect(list.items.contains(where: { $0.ingredientName == "Paper Towels" && $0.isManuallyAdded }))
}

@Test func shoppingListFlagsUnitMismatchesByIngredientName() {
    let weekStart = WeekMath.startOfWeek(for: .now)
    let recipe = Recipe(
        title: "Breakfast",
        ingredients: [
            Ingredient(name: "Milk", quantity: 2, unit: "cups", category: .dairy),
            Ingredient(name: "Milk", quantity: 1, unit: "pint", category: .dairy)
        ]
    )
    let entry = MealPlanEntry(date: weekStart, recipeID: recipe.id)

    let list = ShoppingListGenerator.generate(
        weekStartDate: weekStart,
        entries: [entry],
        recipes: [recipe]
    )

    #expect(list.items.count == 2)
    #expect(list.items.allSatisfy { $0.mismatchNote != nil })
}

@Test func recipeImporterParsesJSONLDRecipe() {
    let html = """
    <html><head>
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "Recipe",
      "name": "Skillet Pasta",
      "recipeYield": "4 servings",
      "prepTime": "PT10M",
      "cookTime": "PT20M",
      "recipeIngredient": ["1 lb pasta", "2 whole lemon"],
      "recipeInstructions": [
        {"@type":"HowToStep", "text":"Boil the pasta"},
        {"@type":"HowToStep", "text":"Finish with lemon"}
      ]
    }
    </script></head></html>
    """

    let draft = RecipeImporter.parseHTML(html, sourceURL: "https://example.com")
    #expect(draft.title == "Skillet Pasta")
    #expect(draft.servings == 4)
    #expect(draft.prepTimeMinutes == 10)
    #expect(draft.ingredients.count == 2)
    #expect(draft.instructions.count == 2)
}

@Test func reminderSchedulerMovesOvernightPrepToPreviousEvening() {
    let calendar = Calendar(identifier: .gregorian)
    let mealDate = ISO8601DateFormatter().date(from: "2026-03-05T00:00:00Z")!
    let recipe = Recipe(
        title: "Roast",
        prepRequirements: [
            PrepRequirement(description: "Defrost roast", leadTimeHours: 10, reminderText: "Take roast out of freezer")
        ]
    )
    let entry = MealPlanEntry(date: mealDate, recipeID: recipe.id)
    let preferences = ReminderPreferences(prepRemindersEnabled: true, preferredMorningHour: 8, preferredEveningHour: 20, assumedDinnerHour: 18)

    let reminders = ReminderScheduler.scheduledReminders(for: entry, recipe: recipe, preferences: preferences, calendar: calendar)

    let reminder = try #require(reminders.first)
    let hour = calendar.component(.hour, from: reminder.triggerDate)
    #expect(hour == 20)
}

@Test func shoppingListShareFormatterOmitsCheckedItems() {
    let list = ShoppingList(
        weekStartDate: .now,
        generatedFromEntryIDs: [],
        items: [
            ShoppingListItem(ingredientName: "Milk", totalQuantity: 1, unit: "gallon", category: .dairy, isChecked: false),
            ShoppingListItem(ingredientName: "Bread", totalQuantity: 1, unit: "loaf", category: .bakery, isChecked: true)
        ]
    )

    let text = ShoppingListShareFormatter.text(for: list)
    #expect(text.contains("Milk"))
    #expect(!text.contains("Bread"))
}

@Test func inviteCodesUseExpectedLength() {
    let code = HouseholdService.generateInviteCode()
    #expect(code.count == 6)
}
