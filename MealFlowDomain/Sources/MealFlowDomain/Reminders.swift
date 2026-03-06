import Foundation

public struct ReminderPreferences: Codable, Hashable, Sendable {
    public var prepRemindersEnabled: Bool
    public var weeklyPlanningReminderEnabled: Bool
    public var preferredMorningHour: Int
    public var preferredEveningHour: Int
    public var assumedDinnerHour: Int
    public var weeklyPlanningDay: Int

    public init(
        prepRemindersEnabled: Bool = false,
        weeklyPlanningReminderEnabled: Bool = false,
        preferredMorningHour: Int = 8,
        preferredEveningHour: Int = 20,
        assumedDinnerHour: Int = 18,
        weeklyPlanningDay: Int = 1
    ) {
        self.prepRemindersEnabled = prepRemindersEnabled
        self.weeklyPlanningReminderEnabled = weeklyPlanningReminderEnabled
        self.preferredMorningHour = preferredMorningHour
        self.preferredEveningHour = preferredEveningHour
        self.assumedDinnerHour = assumedDinnerHour
        self.weeklyPlanningDay = weeklyPlanningDay
    }
}

public enum ReminderScheduler {
    public static func scheduledReminders(
        for entry: MealPlanEntry,
        recipe: Recipe,
        preferences: ReminderPreferences,
        calendar: Calendar = .current
    ) -> [ScheduledReminder] {
        guard preferences.prepRemindersEnabled else { return [] }
        let dinnerTime = calendar.date(
            bySettingHour: preferences.assumedDinnerHour,
            minute: 0,
            second: 0,
            of: calendar.startOfDay(for: entry.date)
        ) ?? entry.date

        return recipe.prepRequirements.map { requirement in
            let rawTrigger = dinnerTime.addingTimeInterval(-(requirement.leadTimeHours * 3600))
            let startOfDay = calendar.startOfDay(for: entry.date)
            let earlyMorning = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: startOfDay) ?? startOfDay
            let adjustedTrigger: Date

            if rawTrigger < startOfDay {
                adjustedTrigger = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: calendar.date(bySettingHour: preferences.preferredEveningHour, minute: 0, second: 0, of: startOfDay) ?? rawTrigger
                ) ?? rawTrigger
            } else if rawTrigger < earlyMorning {
                adjustedTrigger = calendar.date(
                    bySettingHour: preferences.preferredMorningHour,
                    minute: 0,
                    second: 0,
                    of: startOfDay
                ) ?? rawTrigger
            } else {
                adjustedTrigger = rawTrigger
            }

            return ScheduledReminder(
                mealPlanEntryId: entry.id,
                reminderText: "\(recipe.title): \(requirement.reminderText)",
                triggerDate: adjustedTrigger
            )
        }
    }
}
