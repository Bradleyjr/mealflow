import SwiftUI
import WidgetKit

struct MealFlowWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
}

struct MealFlowWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MealFlowWidgetEntry {
        MealFlowWidgetEntry(date: .now, title: "Tonight's Dinner", subtitle: "Sheet Pan Salmon")
    }

    func getSnapshot(in context: Context, completion: @escaping (MealFlowWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MealFlowWidgetEntry>) -> Void) {
        let entry = MealFlowWidgetEntry(date: .now, title: "Tonight's Dinner", subtitle: "Weeknight Tacos")
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600 * 6))))
    }
}

struct MealFlowWidgetView: View {
    var entry: MealFlowWidgetProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.95, blue: 0.91), Color(red: 0.90, green: 0.83, blue: 0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(entry.subtitle)
                    .font(.headline)
                Text("Open MealFlow to view the full plan and shopping list.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct MealFlowWidget: Widget {
    let kind = "MealFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MealFlowWidgetProvider()) { entry in
            MealFlowWidgetView(entry: entry)
        }
        .configurationDisplayName("Tonight's Dinner")
        .description("Shows the next planned meal.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct MealFlowWidgets: WidgetBundle {
    var body: some Widget {
        MealFlowWidget()
    }
}
