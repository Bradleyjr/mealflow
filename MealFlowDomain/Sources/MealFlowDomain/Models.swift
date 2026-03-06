import Foundation

public enum RecipeDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy
    case medium
    case hard

    public var id: String { rawValue }
}

public enum IngredientCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case produce
    case meat
    case dairy
    case pantry
    case frozen
    case bakery
    case other

    public var id: String { rawValue }
}

public enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var id: String { rawValue }
}

public struct Ingredient: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var quantity: Double
    public var unit: String
    public var category: IngredientCategory
    public var isOptional: Bool
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        category: IngredientCategory,
        isOptional: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isOptional = isOptional
        self.notes = notes
    }
}

public struct InstructionStep: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var stepNumber: Int
    public var text: String
    public var timerMinutes: Int?

    public init(id: UUID = UUID(), stepNumber: Int, text: String, timerMinutes: Int? = nil) {
        self.id = id
        self.stepNumber = stepNumber
        self.text = text
        self.timerMinutes = timerMinutes
    }
}

public struct PrepRequirement: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var description: String
    public var leadTimeHours: Double
    public var reminderText: String

    public init(
        id: UUID = UUID(),
        description: String,
        leadTimeHours: Double,
        reminderText: String
    ) {
        self.id = id
        self.description = description
        self.leadTimeHours = leadTimeHours
        self.reminderText = reminderText
    }
}

public struct Recipe: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var subtitle: String?
    public var sourceURL: String?
    public var servings: Int
    public var prepTimeMinutes: Int?
    public var cookTimeMinutes: Int?
    public var totalTimeMinutes: Int?
    public var difficulty: RecipeDifficulty
    public var ingredients: [Ingredient]
    public var instructions: [InstructionStep]
    public var prepRequirements: [PrepRequirement]
    public var tags: [String]
    public var notes: String?
    public var isFavorite: Bool
    public var timesCooked: Int
    public var lastCookedDate: Date?
    public var dateAdded: Date

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        sourceURL: String? = nil,
        servings: Int = 4,
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        totalTimeMinutes: Int? = nil,
        difficulty: RecipeDifficulty = .easy,
        ingredients: [Ingredient] = [],
        instructions: [InstructionStep] = [],
        prepRequirements: [PrepRequirement] = [],
        tags: [String] = [],
        notes: String? = nil,
        isFavorite: Bool = false,
        timesCooked: Int = 0,
        lastCookedDate: Date? = nil,
        dateAdded: Date = .now
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.sourceURL = sourceURL
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.totalTimeMinutes = totalTimeMinutes ?? {
            switch (prepTimeMinutes, cookTimeMinutes) {
            case let (prep?, cook?):
                return prep + cook
            default:
                return nil
            }
        }()
        self.difficulty = difficulty
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepRequirements = prepRequirements
        self.tags = tags
        self.notes = notes
        self.isFavorite = isFavorite
        self.timesCooked = timesCooked
        self.lastCookedDate = lastCookedDate
        self.dateAdded = dateAdded
    }
}

public struct ScheduledReminder: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var mealPlanEntryId: UUID
    public var reminderText: String
    public var triggerDate: Date
    public var isDelivered: Bool
    public var isDismissed: Bool

    public init(
        id: UUID = UUID(),
        mealPlanEntryId: UUID,
        reminderText: String,
        triggerDate: Date,
        isDelivered: Bool = false,
        isDismissed: Bool = false
    ) {
        self.id = id
        self.mealPlanEntryId = mealPlanEntryId
        self.reminderText = reminderText
        self.triggerDate = triggerDate
        self.isDelivered = isDelivered
        self.isDismissed = isDismissed
    }
}

public struct MealPlanEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var date: Date
    public var mealType: MealType
    public var recipeID: UUID?
    public var customMealName: String?
    public var isCompleted: Bool
    public var scheduledReminders: [ScheduledReminder]

    public init(
        id: UUID = UUID(),
        date: Date,
        mealType: MealType = .dinner,
        recipeID: UUID? = nil,
        customMealName: String? = nil,
        isCompleted: Bool = false,
        scheduledReminders: [ScheduledReminder] = []
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.recipeID = recipeID
        self.customMealName = customMealName
        self.isCompleted = isCompleted
        self.scheduledReminders = scheduledReminders
    }
}

public struct ShoppingListItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var ingredientName: String
    public var totalQuantity: Double
    public var unit: String
    public var category: IngredientCategory
    public var isChecked: Bool
    public var sourceRecipes: [String]
    public var isManuallyAdded: Bool
    public var mismatchNote: String?

    public init(
        id: UUID = UUID(),
        ingredientName: String,
        totalQuantity: Double,
        unit: String,
        category: IngredientCategory,
        isChecked: Bool = false,
        sourceRecipes: [String] = [],
        isManuallyAdded: Bool = false,
        mismatchNote: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.totalQuantity = totalQuantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.sourceRecipes = sourceRecipes
        self.isManuallyAdded = isManuallyAdded
        self.mismatchNote = mismatchNote
    }

    public var normalizedKey: String {
        "\(ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(unit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    public var normalizedName: String {
        ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

public struct ShoppingList: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var weekStartDate: Date
    public var generatedFromEntryIDs: [UUID]
    public var items: [ShoppingListItem]

    public init(
        id: UUID = UUID(),
        weekStartDate: Date,
        generatedFromEntryIDs: [UUID],
        items: [ShoppingListItem]
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.generatedFromEntryIDs = generatedFromEntryIDs
        self.items = items
    }
}

public struct UserPreferences: Codable, Hashable, Sendable {
    public var defaultServings: Int
    public var defaultMealType: MealType
    public var theme: String
    public var measurementSystem: String
    public var weekStartsOnMonday: Bool
    public var reminderPreferences: ReminderPreferences

    public init(
        defaultServings: Int = 4,
        defaultMealType: MealType = .dinner,
        theme: String = "system",
        measurementSystem: String = "US",
        weekStartsOnMonday: Bool = true,
        reminderPreferences: ReminderPreferences = ReminderPreferences()
    ) {
        self.defaultServings = defaultServings
        self.defaultMealType = defaultMealType
        self.theme = theme
        self.measurementSystem = measurementSystem
        self.weekStartsOnMonday = weekStartsOnMonday
        self.reminderPreferences = reminderPreferences
    }
}
