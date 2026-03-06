import Foundation

protocol HouseholdSyncing {
    func push(snapshot: HouseholdSnapshot) async throws
    func pull() async throws -> HouseholdSnapshot
}

struct HouseholdSnapshot: Codable, Sendable {
    var recipes: [Recipe]
    var mealPlanEntries: [MealPlanEntry]
    var shoppingLists: [ShoppingList]
    var household: Household?
}

struct LocalOnlyHouseholdSyncService: HouseholdSyncing {
    func push(snapshot: HouseholdSnapshot) async throws {
        _ = snapshot
    }

    func pull() async throws -> HouseholdSnapshot {
        HouseholdSnapshot(recipes: [], mealPlanEntries: [], shoppingLists: [], household: nil)
    }
}

enum SyncImplementationNotes {
    static let cloudKitPlan = """
    Replace LocalOnlyHouseholdSyncService with a CloudKit-backed implementation that syncs recipes, meal plans, shopping lists, and household membership records. Preserve the local-first store contract and merge by record identity instead of replacing arrays wholesale.
    """
}
