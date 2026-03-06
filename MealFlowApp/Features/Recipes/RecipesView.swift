import SwiftUI

struct RecipesView: View {
    @Environment(AppStore.self) private var store
    @State private var searchText = ""
    @State private var showingEditor = false
    @State private var showingImport = false
    @State private var editingRecipe: Recipe?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PantryHeader(
                    eyebrow: "Recipe Box",
                    title: "A little shelf of comfort-food ideas",
                    detail: "Part handwritten card, part magical pantry. Keep the meals that feel like home.",
                    icon: "house.and.flag"
                )

                CozyStatRow(items: [
                    ("Saved", "\(store.recipes.count)", AppTheme.butter),
                    ("Favorites", "\(store.recipes.filter(\.isFavorite).count)", AppTheme.terracotta),
                    ("Cooked", "\(store.recipes.map(\.timesCooked).reduce(0, +))", AppTheme.sage)
                ])

                if filteredRecipes.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        CozySectionHeader(
                            title: "Your recipe box is still empty",
                            detail: "Add one favorite and the whole app starts to feel alive."
                        )
                        HStack(spacing: 12) {
                            Button("Add a Recipe") {
                                CozyFeedback.tap()
                                editingRecipe = nil
                                showingEditor = true
                            }
                            .buttonStyle(CozyPrimaryButtonStyle())

                            Button("Import") {
                                CozyFeedback.tap()
                                showingImport = true
                            }
                            .buttonStyle(CozySecondaryButtonStyle())
                        }
                    }
                    .mealFlowCard(padding: 22)
                } else {
                    CozySectionHeader(
                        title: searchText.isEmpty ? "Saved recipes" : "Search results",
                        detail: "Flip through the box like a stack of handwritten cards."
                    )

                    RecipeBoxCarousel(
                        recipes: filteredRecipes,
                        onEdit: { recipe in
                            editingRecipe = recipe
                            showingEditor = true
                        },
                        onFavorite: { recipe in
                            store.toggleFavorite(for: recipe.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .cozySurface()
        .navigationTitle("Recipes")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search title, tags, ingredients")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add Manually", systemImage: "square.and.pencil") {
                        CozyFeedback.tap()
                        editingRecipe = nil
                        showingEditor = true
                    }
                    Button("Import from URL or Text", systemImage: "square.and.arrow.down") {
                        CozyFeedback.tap()
                        showingImport = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                RecipeEditorView(existingRecipe: editingRecipe)
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingImport) {
            NavigationStack {
                RecipeImportView()
            }
            .presentationDetents([.large])
        }
    }

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return store.recipes
        }
        let query = searchText.lowercased()
        return store.recipes.filter { recipe in
            recipe.title.lowercased().contains(query) ||
            recipe.tags.joined(separator: " ").lowercased().contains(query) ||
            recipe.ingredients.contains(where: { $0.name.lowercased().contains(query) })
        }
    }
}

private struct RecipeBoxCarousel: View {
    let recipes: [Recipe]
    let onEdit: (Recipe) -> Void
    let onFavorite: (Recipe) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.soil.opacity(0.16), AppTheme.butter.opacity(0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 360)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppTheme.stroke, lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.soil.opacity(0.25))
                .frame(height: 20)
                .padding(.horizontal, 30)
                .offset(y: -18)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: -48) {
                    ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                        NavigationLink {
                            RecipeDetailView(recipeID: recipe.id)
                        } label: {
                            RecipeCard(recipe: recipe, accentIndex: index)
                                .frame(width: 252)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(recipe.isFavorite ? "Unfavorite" : "Favorite") {
                                onFavorite(recipe)
                            }
                            Button("Edit") {
                                onEdit(recipe)
                            }
                        }
                        .scrollTransition(.animated.threshold(.visible(0.2))) { content, phase in
                            content
                                .rotationEffect(.degrees(phase.isIdentity ? fanAngle(for: index) : fanAngle(for: index) * 1.35))
                                .offset(y: phase.isIdentity ? 0 : 12)
                                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                .opacity(phase.isIdentity ? 1 : 0.78)
                        }
                        .zIndex(Double(recipes.count - index))
                    }
                }
                .padding(.horizontal, 58)
                .padding(.vertical, 26)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private func fanAngle(for index: Int) -> Double {
        let pattern = [-6.0, -3.0, 0.0, 3.0, 6.0]
        return pattern[index % pattern.count]
    }
}

private struct RecipeCard: View {
    let recipe: Recipe
    let accentIndex: Int

    private var accent: Color {
        [AppTheme.terracotta, AppTheme.sage, AppTheme.butter, AppTheme.berry][accentIndex % 4]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.94), AppTheme.soil.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 154)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            if recipe.isFavorite {
                                Image(systemName: "heart.fill")
                                    .symbolRenderingMode(.multicolor)
                            }
                            Spacer()
                            Image(systemName: symbol(for: recipe))
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.28))
                        }

                        Spacer()

                        if let total = recipe.totalTimeMinutes {
                            CozyPill(label: "\(total) min", tint: .white.opacity(0.9), systemImage: "clock")
                        }

                        Text(recipe.title)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                    }
                    .padding(16)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.subtitle ?? "A warm keeper for your weekly rotation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    CozyPill(label: "\(recipe.servings) servings", tint: AppTheme.sage, systemImage: "person.2")
                    if recipe.timesCooked > 0 {
                        CozyPill(label: "\(recipe.timesCooked)x", tint: AppTheme.butter, systemImage: "flame")
                    }
                }
            }
        }
        .mealFlowCard(padding: 14)
        .shadow(color: AppTheme.soil.opacity(0.08), radius: 10, y: 8)
        .accessibilityElement(children: .combine)
    }

    private func symbol(for recipe: Recipe) -> String {
        if recipe.tags.contains("healthy") { return "leaf.circle.fill" }
        if recipe.tags.contains("pasta") { return "fork.knife.circle.fill" }
        if recipe.tags.contains("family") { return "house.circle.fill" }
        return "carrot.circle.fill"
    }
}
