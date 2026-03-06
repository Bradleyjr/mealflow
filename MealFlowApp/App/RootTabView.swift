import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                RecipesView()
            }
            .tabItem {
                Label("Recipes", systemImage: "square.grid.2x2.fill")
            }

            NavigationStack {
                PlanView()
            }
            .tabItem {
                Label("Plan", systemImage: "calendar.badge.clock")
            }

            NavigationStack {
                ShopView()
            }
            .tabItem {
                Label("Shop", systemImage: "basket.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.terracotta)
        .toolbarBackground(AppTheme.panel.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background {
            CozyBackground()
        }
    }
}
