import Foundation
import Observation

@Observable
final class AppStore {
    var recipes: [Recipe]
    var mealPlanEntries: [MealPlanEntry]
    var shoppingLists: [ShoppingList]
    var preferences: UserPreferences
    var household: Household?
    var selectedWeekStart: Date

    private let storageURL: URL
    private let calendar = Calendar(identifier: .gregorian)

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL.documentsDirectory
        let folderURL = supportDirectory.appending(path: "MealFlow", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        storageURL = folderURL.appending(path: "snapshot.json")

        if let snapshot = Self.load(from: storageURL) {
            recipes = snapshot.recipes
            mealPlanEntries = snapshot.mealPlanEntries
            shoppingLists = snapshot.shoppingLists
            preferences = snapshot.preferences
            household = snapshot.household
            selectedWeekStart = snapshot.selectedWeekStart
        } else {
            recipes = SampleData.recipes
            mealPlanEntries = SampleData.mealPlanEntries
            shoppingLists = []
            preferences = UserPreferences()
            household = SampleData.household
            selectedWeekStart = WeekMath.startOfWeek(for: .now, calendar: calendar)
            generateShoppingList()
            save()
        }
    }

    var weekDates: [Date] {
        WeekMath.daysInWeek(startingAt: selectedWeekStart, calendar: calendar)
    }

    var currentShoppingList: ShoppingList? {
        shoppingLists.first(where: { calendar.isDate($0.weekStartDate, inSameDayAs: selectedWeekStart) })
    }

    func recipe(for id: UUID?) -> Recipe? {
        guard let id else { return nil }
        return recipes.first(where: { $0.id == id })
    }

    func entry(for date: Date, mealType: MealType = .dinner) -> MealPlanEntry? {
        mealPlanEntries.first {
            calendar.isDate($0.date, inSameDayAs: date) && $0.mealType == mealType
        }
    }

    func entries(for date: Date) -> [MealPlanEntry] {
        mealPlanEntries
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.mealType.rawValue < $1.mealType.rawValue }
    }

    func upsertRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        } else {
            recipes.insert(recipe, at: 0)
        }
        save()
    }

    func deleteRecipes(at offsets: IndexSet) {
        let ids = offsets.map { recipes[$0].id }
        for offset in offsets.sorted(by: >) {
            recipes.remove(at: offset)
        }
        mealPlanEntries.removeAll { entry in
            guard let recipeID = entry.recipeID else { return false }
            return ids.contains(recipeID)
        }
        regenerateCurrentWeekIfNeeded()
        save()
    }

    func toggleFavorite(for recipeID: UUID) {
        guard let index = recipes.firstIndex(where: { $0.id == recipeID }) else { return }
        recipes[index].isFavorite.toggle()
        save()
    }

    func assignRecipe(_ recipe: Recipe, to date: Date, mealType: MealType = .dinner) {
        if let index = mealPlanEntries.firstIndex(where: {
            calendar.isDate($0.date, inSameDayAs: date) && $0.mealType == mealType
        }) {
            mealPlanEntries[index].recipeID = recipe.id
            mealPlanEntries[index].customMealName = nil
            mealPlanEntries[index].scheduledReminders = ReminderScheduler.scheduledReminders(
                for: mealPlanEntries[index],
                recipe: recipe,
                preferences: preferences.reminderPreferences,
                calendar: calendar
            )
        } else {
            var entry = MealPlanEntry(date: calendar.startOfDay(for: date), mealType: mealType, recipeID: recipe.id)
            entry.scheduledReminders = ReminderScheduler.scheduledReminders(
                for: entry,
                recipe: recipe,
                preferences: preferences.reminderPreferences,
                calendar: calendar
            )
            mealPlanEntries.append(entry)
        }
        generateShoppingList()
        save()
    }

    func assignCustomMeal(_ name: String, to date: Date, mealType: MealType) {
        if let index = mealPlanEntries.firstIndex(where: {
            calendar.isDate($0.date, inSameDayAs: date) && $0.mealType == mealType
        }) {
            mealPlanEntries[index].recipeID = nil
            mealPlanEntries[index].customMealName = name
            mealPlanEntries[index].scheduledReminders = []
        } else {
            mealPlanEntries.append(
                MealPlanEntry(
                    date: calendar.startOfDay(for: date),
                    mealType: mealType,
                    recipeID: nil,
                    customMealName: name
                )
            )
        }
        generateShoppingList()
        save()
    }

    func removeMeal(on date: Date, mealType: MealType = .dinner) {
        mealPlanEntries.removeAll {
            calendar.isDate($0.date, inSameDayAs: date) && $0.mealType == mealType
        }
        generateShoppingList()
        save()
    }

    func toggleMealCompleted(_ entryID: UUID) {
        guard let index = mealPlanEntries.firstIndex(where: { $0.id == entryID }) else { return }
        mealPlanEntries[index].isCompleted.toggle()
        if mealPlanEntries[index].isCompleted, let recipeID = mealPlanEntries[index].recipeID,
           let recipeIndex = recipes.firstIndex(where: { $0.id == recipeID }) {
            recipes[recipeIndex].timesCooked += 1
            recipes[recipeIndex].lastCookedDate = mealPlanEntries[index].date
        }
        save()
    }

    func changeWeek(by offset: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: offset * 7, to: selectedWeekStart) else { return }
        selectedWeekStart = WeekMath.startOfWeek(for: newDate, calendar: calendar)
        save()
    }

    func jumpToCurrentWeek() {
        selectedWeekStart = WeekMath.startOfWeek(for: .now, calendar: calendar)
        save()
    }

    func repetitionInsight(for recipeID: UUID, on date: Date) -> RepetitionInsight {
        MealPlanAnalytics.repetitionInsight(
            for: recipeID,
            on: date,
            entries: mealPlanEntries,
            calendar: calendar
        )
    }

    func suggestedRecipes(for date: Date) -> [RecipeSuggestion] {
        RecipeSuggestionEngine.rankedRecipes(
            recipes: recipes,
            existingEntries: mealPlanEntries,
            targetDate: date,
            calendar: calendar
        )
    }

    func generateShoppingList() {
        let weekEntries = mealPlanEntries.filter { entry in
            weekDates.contains(where: { calendar.isDate($0, inSameDayAs: entry.date) })
        }
        let list = ShoppingListGenerator.generate(
            weekStartDate: selectedWeekStart,
            entries: weekEntries,
            recipes: recipes,
            existingList: currentShoppingList
        )

        if let index = shoppingLists.firstIndex(where: { calendar.isDate($0.weekStartDate, inSameDayAs: selectedWeekStart) }) {
            shoppingLists[index] = list
        } else {
            shoppingLists.append(list)
        }
        save()
    }

    func addManualShoppingItem(name: String, quantity: Double, unit: String, category: IngredientCategory) {
        var list = currentShoppingList ?? ShoppingList(weekStartDate: selectedWeekStart, generatedFromEntryIDs: [], items: [])
        list.items.append(
            ShoppingListItem(
                ingredientName: name,
                totalQuantity: quantity,
                unit: unit,
                category: category,
                isManuallyAdded: true
            )
        )
        updateShoppingList(list)
    }

    func toggleShoppingItem(_ itemID: UUID) {
        guard var list = currentShoppingList,
              let index = list.items.firstIndex(where: { $0.id == itemID }) else { return }
        list.items[index].isChecked.toggle()
        updateShoppingList(list)
    }

    func clearCheckedItems() {
        guard var list = currentShoppingList else { return }
        list.items.removeAll(where: \.isChecked)
        updateShoppingList(list)
    }

    func updatePreference<Value>(_ keyPath: WritableKeyPath<UserPreferences, Value>, value: Value) {
        preferences[keyPath: keyPath] = value
        refreshScheduledReminders()
        save()
    }

    func createHousehold(name: String, ownerDisplayName: String) {
        household = Household(
            name: name,
            members: [HouseholdMember(userID: UUID().uuidString, displayName: ownerDisplayName, role: .owner)],
            sharedRecipeIDs: recipes.map(\.id),
            inviteCode: HouseholdService.generateInviteCode()
        )
        save()
    }

    func joinHousehold(code: String, displayName: String) {
        let member = HouseholdMember(userID: UUID().uuidString, displayName: displayName, role: .member)
        if household == nil {
            household = Household(name: "Shared Home", members: [member], inviteCode: code.uppercased())
        } else {
            household?.members.append(member)
        }
        save()
    }

    func leaveHousehold() {
        household = nil
        save()
    }

    func importRecipe(from draft: RecipeImportDraft) {
        upsertRecipe(draft.toRecipe(defaultServings: preferences.defaultServings))
    }

    func exportShoppingListText() -> String {
        guard let list = currentShoppingList else { return "" }
        return ShoppingListShareFormatter.text(for: list)
    }

    func progressText() -> String {
        guard let list = currentShoppingList else { return "No shopping list yet" }
        let checked = list.items.filter(\.isChecked).count
        return "\(checked) of \(list.items.count) items checked"
    }

    private func regenerateCurrentWeekIfNeeded() {
        if currentShoppingList != nil {
            generateShoppingList()
        }
    }

    private func updateShoppingList(_ list: ShoppingList) {
        if let index = shoppingLists.firstIndex(where: { calendar.isDate($0.weekStartDate, inSameDayAs: list.weekStartDate) }) {
            shoppingLists[index] = list
        } else {
            shoppingLists.append(list)
        }
        save()
    }

    private func refreshScheduledReminders() {
        for index in mealPlanEntries.indices {
            guard let recipeID = mealPlanEntries[index].recipeID,
                  let recipe = recipe(for: recipeID) else {
                mealPlanEntries[index].scheduledReminders = []
                continue
            }
            mealPlanEntries[index].scheduledReminders = ReminderScheduler.scheduledReminders(
                for: mealPlanEntries[index],
                recipe: recipe,
                preferences: preferences.reminderPreferences,
                calendar: calendar
            )
        }
    }

    private func save() {
        let snapshot = Snapshot(
            recipes: recipes,
            mealPlanEntries: mealPlanEntries,
            shoppingLists: shoppingLists,
            preferences: preferences,
            household: household,
            selectedWeekStart: selectedWeekStart
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: storageURL, options: [.atomic])
    }

    private static func load(from url: URL) -> Snapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private struct Snapshot: Codable {
        var recipes: [Recipe]
        var mealPlanEntries: [MealPlanEntry]
        var shoppingLists: [ShoppingList]
        var preferences: UserPreferences
        var household: Household?
        var selectedWeekStart: Date
    }
}
