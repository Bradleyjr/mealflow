import SwiftUI

struct ShopView: View {
    @Environment(AppStore.self) private var store
    @State private var showingAddItem = false
    @State private var shoppingMode = false
    @State private var showingShareText = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PantryHeader(
                    eyebrow: shoppingMode ? "Market Mode" : "Shopping Basket",
                    title: shoppingMode ? "Big text, quick taps, one calm grocery run" : "Everything you need for the week, sorted into one basket",
                    detail: shoppingMode ? "Built for aisles, cart handles, and one-thumb checkoffs." : "Ingredients gather here automatically and still leave room for paper towels.",
                    icon: shoppingMode ? "basket" : "cart"
                )

                CozyStatRow(items: [
                    ("Progress", store.progressText(), AppTheme.sage),
                    ("Manual", "\(manualItemCount)", AppTheme.butter),
                    ("Sections", "\(activeCategoryCount)", AppTheme.terracotta)
                ])

                if let list = store.currentShoppingList, !list.items.isEmpty {
                    ForEach(IngredientCategory.allCases) { category in
                        let items = list.items.filter { $0.category == category }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                CozySectionHeader(
                                    title: categoryTitle(category),
                                    detail: "\(items.filter { !$0.isChecked }.count) left"
                                )
                                VStack(spacing: 12) {
                                    ForEach(items) { item in
                                        shoppingItemRow(item)
                                    }
                                }
                            }
                            .mealFlowCard(padding: 18)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        CozySectionHeader(
                            title: "No shopping list yet",
                            detail: "Plan a few meals first and this basket will fill itself."
                        )
                        CozyPill(label: "Waiting on the weekly plan", tint: AppTheme.butter, systemImage: "calendar")
                    }
                    .mealFlowCard(padding: 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 130)
        }
        .cozySurface()
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Refresh") {
                        CozyFeedback.tap()
                        store.generateShoppingList()
                    }
                    Button(shoppingMode ? "Standard View" : "Shopping Mode") {
                        CozyFeedback.tap()
                        shoppingMode.toggle()
                    }
                    Button("Share Text") {
                        CozyFeedback.tap()
                        showingShareText = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Add Item") {
                    showingAddItem = true
                }
                Button("Clear Checked") {
                    store.clearCheckedItems()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Text(store.progressText())
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.soil)
                Spacer()
                if shoppingMode {
                    CozyPill(label: "Shopping mode", tint: AppTheme.sage, systemImage: "hand.tap")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                ManualShoppingItemView()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingShareText) {
            NavigationStack {
                ShoppingListShareView(text: store.exportShoppingListText())
            }
        }
    }

    private var manualItemCount: Int {
        store.currentShoppingList?.items.filter(\.isManuallyAdded).count ?? 0
    }

    private var activeCategoryCount: Int {
        IngredientCategory.allCases.filter { category in
            store.currentShoppingList?.items.contains(where: { $0.category == category }) == true
        }.count
    }

    @ViewBuilder
    private func shoppingItemRow(_ item: ShoppingListItem) -> some View {
        Button {
            CozyFeedback.tap(style: .soft)
            store.toggleShoppingItem(item.id)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(shoppingMode ? .title : .title3)
                    .foregroundStyle(item.isChecked ? AppTheme.sage : AppTheme.terracotta)
                    .symbolEffect(.bounce, value: item.isChecked)
                    .frame(minWidth: 30)

                VStack(alignment: .leading, spacing: 6) {
                    Text(lineText(for: item))
                        .font(shoppingMode ? .title3.weight(.semibold) : .body.weight(.semibold))
                        .foregroundStyle(AppTheme.soil)
                        .strikethrough(item.isChecked)
                        .multilineTextAlignment(.leading)
                    Text(item.sourceRecipes.isEmpty ? "Added by hand" : "For: \(item.sourceRecipes.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let note = item.mismatchNote {
                        Text(note)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.berry)
                    }
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(item.isChecked ? AppTheme.sage.opacity(0.08) : AppTheme.panel.opacity(0.7))
            )
        }
        .buttonStyle(.plain)
    }

    private func lineText(for item: ShoppingListItem) -> String {
        let quantity = item.totalQuantity == floor(item.totalQuantity)
            ? "\(Int(item.totalQuantity))"
            : item.totalQuantity.formatted()
        return "\(quantity) \(item.unit) \(item.ingredientName)"
    }

    private func categoryTitle(_ category: IngredientCategory) -> String {
        switch category {
        case .produce: return "Garden produce"
        case .meat: return "Butcher block"
        case .dairy: return "Fridge staples"
        case .pantry: return "Pantry shelf"
        case .frozen: return "Freezer aisle"
        case .bakery: return "Bakery"
        case .other: return "Odds and ends"
        }
    }
}

private struct ShoppingListShareView: View {
    @Environment(\.dismiss) private var dismiss
    let text: String

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? "No unchecked items to share." : text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .cozySurface()
        .navigationTitle("Share List")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct ManualShoppingItemView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = 1.0
    @State private var unit = "whole"
    @State private var category = IngredientCategory.other

    var body: some View {
        Form {
            TextField("Item", text: $name)
            TextField("Quantity", value: $quantity, format: .number)
                .keyboardType(.decimalPad)
            TextField("Unit", text: $unit)
            Picker("Category", selection: $category) {
                ForEach(IngredientCategory.allCases) { category in
                    Text(category.rawValue.capitalized).tag(category)
                }
            }
        }
        .navigationTitle("Add Item")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    CozyFeedback.tap()
                    store.addManualShoppingItem(name: name, quantity: quantity, unit: unit, category: category)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
