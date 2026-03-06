import Foundation

enum SampleData {
    static let recipes: [Recipe] = [
        Recipe(
            title: "Weeknight Tacos",
            subtitle: "Quick skillet dinner",
            servings: 4,
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            difficulty: .easy,
            ingredients: [
                Ingredient(name: "Ground Beef", quantity: 1, unit: "lb", category: .meat),
                Ingredient(name: "Tortillas", quantity: 8, unit: "pieces", category: .bakery),
                Ingredient(name: "Shredded Cheese", quantity: 2, unit: "cups", category: .dairy),
                Ingredient(name: "Lime", quantity: 2, unit: "whole", category: .produce)
            ],
            instructions: [
                InstructionStep(stepNumber: 1, text: "Brown the beef in a skillet."),
                InstructionStep(stepNumber: 2, text: "Warm tortillas and set out toppings."),
                InstructionStep(stepNumber: 3, text: "Build tacos and serve.")
            ],
            prepRequirements: [
                PrepRequirement(description: "Move beef to the fridge to thaw", leadTimeHours: 8, reminderText: "Defrost the beef for tacos tonight.")
            ],
            tags: ["quick", "family", "mexican"],
            notes: "Great with avocado.",
            isFavorite: true
        ),
        Recipe(
            title: "Lemon Pasta",
            subtitle: "Bright pantry dinner",
            servings: 4,
            prepTimeMinutes: 10,
            cookTimeMinutes: 15,
            difficulty: .easy,
            ingredients: [
                Ingredient(name: "Spaghetti", quantity: 1, unit: "lb", category: .pantry),
                Ingredient(name: "Parmesan", quantity: 1, unit: "cup", category: .dairy),
                Ingredient(name: "Lemon", quantity: 2, unit: "whole", category: .produce),
                Ingredient(name: "Butter", quantity: 4, unit: "tbsp", category: .dairy)
            ],
            instructions: [
                InstructionStep(stepNumber: 1, text: "Cook pasta until al dente."),
                InstructionStep(stepNumber: 2, text: "Toss with butter, lemon, and parmesan."),
                InstructionStep(stepNumber: 3, text: "Season and serve.")
            ],
            tags: ["pasta", "quick"],
            notes: "Add spinach when available."
        ),
        Recipe(
            title: "Sheet Pan Salmon",
            subtitle: "Low-effort dinner",
            servings: 2,
            prepTimeMinutes: 10,
            cookTimeMinutes: 18,
            difficulty: .medium,
            ingredients: [
                Ingredient(name: "Salmon Fillets", quantity: 2, unit: "pieces", category: .meat),
                Ingredient(name: "Broccoli", quantity: 1, unit: "head", category: .produce),
                Ingredient(name: "Baby Potatoes", quantity: 1.5, unit: "lb", category: .produce)
            ],
            instructions: [
                InstructionStep(stepNumber: 1, text: "Roast potatoes until nearly tender."),
                InstructionStep(stepNumber: 2, text: "Add salmon and broccoli to the pan."),
                InstructionStep(stepNumber: 3, text: "Finish roasting until salmon flakes easily.")
            ],
            tags: ["healthy", "sheet-pan"],
            notes: "Finish with dill and lemon."
        )
    ]

    static let mealPlanEntries: [MealPlanEntry] = {
        let calendar = Calendar(identifier: .gregorian)
        let weekStart = WeekMath.startOfWeek(for: .now, calendar: calendar)
        return [
            MealPlanEntry(date: weekStart, recipeID: recipes[0].id),
            MealPlanEntry(date: weekStart, mealType: .lunch, customMealName: "Leftovers"),
            MealPlanEntry(date: calendar.date(byAdding: .day, value: 2, to: weekStart)!, recipeID: recipes[1].id),
            MealPlanEntry(date: calendar.date(byAdding: .day, value: 4, to: weekStart)!, recipeID: recipes[2].id)
        ]
    }()

    static let household = Household(
        name: "The Youngs",
        members: [
            HouseholdMember(userID: "local-owner", displayName: "Bradley", role: .owner),
            HouseholdMember(userID: "local-partner", displayName: "Partner", role: .member)
        ],
        sharedRecipeIDs: recipes.map(\.id),
        inviteCode: "MEAL42"
    )
}
