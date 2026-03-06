import Foundation

public enum WeekMath {
    public static func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
        var calendar = calendar
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    public static func daysInWeek(startingAt weekStart: Date, calendar: Calendar = .current) -> [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }
}

public struct RepetitionInsight: Equatable, Sendable {
    public let recipeID: UUID
    public let countInRollingWindow: Int
    public let shouldAlert: Bool

    public init(recipeID: UUID, countInRollingWindow: Int, shouldAlert: Bool) {
        self.recipeID = recipeID
        self.countInRollingWindow = countInRollingWindow
        self.shouldAlert = shouldAlert
    }
}

public enum MealPlanAnalytics {
    public static func repetitionInsight(
        for recipeID: UUID,
        on date: Date,
        entries: [MealPlanEntry],
        rollingDays: Int = 30,
        calendar: Calendar = .current
    ) -> RepetitionInsight {
        let start = calendar.date(byAdding: .day, value: -(rollingDays - 1), to: date) ?? date
        let count = entries.filter { entry in
            guard entry.recipeID == recipeID else { return false }
            return entry.date >= start && entry.date <= date
        }.count
        return RepetitionInsight(
            recipeID: recipeID,
            countInRollingWindow: count,
            shouldAlert: count >= 3
        )
    }
}

public struct RecipeSuggestion: Equatable, Sendable {
    public let recipe: Recipe
    public let score: Int
}

public enum RecipeSuggestionEngine {
    public static func rankedRecipes(
        recipes: [Recipe],
        existingEntries: [MealPlanEntry],
        targetDate: Date,
        favoritesBoost: Int = 10,
        calendar: Calendar = .current
    ) -> [RecipeSuggestion] {
        let weekStart = WeekMath.startOfWeek(for: targetDate, calendar: calendar)
        let weekDates = Set(WeekMath.daysInWeek(startingAt: weekStart, calendar: calendar))
        let plannedThisWeek = Set(existingEntries.compactMap { entry -> UUID? in
            guard weekDates.contains(calendar.startOfDay(for: entry.date)) else { return nil }
            return entry.recipeID
        })

        return recipes.compactMap { recipe in
            guard !plannedThisWeek.contains(recipe.id) else { return nil }

            var score = 0
            if recipe.timesCooked == 0 {
                score += 100
            }
            if let lastCookedDate = recipe.lastCookedDate {
                let days = calendar.dateComponents([.day], from: lastCookedDate, to: targetDate).day ?? 0
                score += max(days, 0)
            } else {
                score += 40
            }
            if recipe.isFavorite {
                score += favoritesBoost
            }
            return RecipeSuggestion(recipe: recipe, score: score)
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.recipe.title.localizedCaseInsensitiveCompare(rhs.recipe.title) == .orderedAscending
            }
            return lhs.score > rhs.score
        }
    }
}
