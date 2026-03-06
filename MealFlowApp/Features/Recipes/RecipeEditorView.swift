import SwiftUI

struct RecipeEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let existingRecipe: Recipe?

    @State private var title: String
    @State private var subtitle: String
    @State private var servings: Int
    @State private var prepMinutes: Int
    @State private var cookMinutes: Int
    @State private var difficulty: RecipeDifficulty
    @State private var notes: String
    @State private var tagsText: String
    @State private var ingredients: [Ingredient]
    @State private var instructions: [InstructionStep]
    @State private var prepRequirements: [PrepRequirement]

    init(existingRecipe: Recipe?) {
        self.existingRecipe = existingRecipe
        _title = State(initialValue: existingRecipe?.title ?? "")
        _subtitle = State(initialValue: existingRecipe?.subtitle ?? "")
        _servings = State(initialValue: existingRecipe?.servings ?? 4)
        _prepMinutes = State(initialValue: existingRecipe?.prepTimeMinutes ?? 10)
        _cookMinutes = State(initialValue: existingRecipe?.cookTimeMinutes ?? 20)
        _difficulty = State(initialValue: existingRecipe?.difficulty ?? .easy)
        _notes = State(initialValue: existingRecipe?.notes ?? "")
        _tagsText = State(initialValue: existingRecipe?.tags.joined(separator: ", ") ?? "")
        _ingredients = State(initialValue: existingRecipe?.ingredients ?? [
            Ingredient(name: "", quantity: 1, unit: "whole", category: .other)
        ])
        _instructions = State(initialValue: existingRecipe?.instructions ?? [
            InstructionStep(stepNumber: 1, text: "")
        ])
        _prepRequirements = State(initialValue: existingRecipe?.prepRequirements ?? [])
    }

    init(importDraft: RecipeImportDraft) {
        let recipe = importDraft.toRecipe()
        self.init(existingRecipe: recipe)
    }

    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Title", text: $title)
                TextField("Subtitle", text: $subtitle)
                Stepper("Servings: \(servings)", value: $servings, in: 1...12)
                Stepper("Prep: \(prepMinutes) min", value: $prepMinutes, in: 0...240, step: 5)
                Stepper("Cook: \(cookMinutes) min", value: $cookMinutes, in: 0...300, step: 5)
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(RecipeDifficulty.allCases) { difficulty in
                        Text(difficulty.rawValue.capitalized).tag(difficulty)
                    }
                }
            }

            Section("Ingredients") {
                ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Ingredient name", text: binding(forIngredientAt: index, keyPath: \.name))
                        HStack {
                            TextField("Qty", value: binding(forIngredientAt: index, keyPath: \.quantity), format: .number)
                                .keyboardType(.decimalPad)
                            TextField("Unit", text: binding(forIngredientAt: index, keyPath: \.unit))
                        }
                        Picker("Category", selection: binding(forIngredientAt: index, keyPath: \.category)) {
                            ForEach(IngredientCategory.allCases) { category in
                                Text(category.rawValue.capitalized).tag(category)
                            }
                        }
                    }
                }
                .onDelete { ingredients.remove(atOffsets: $0) }

                Button("Add Ingredient") {
                    ingredients.append(Ingredient(name: "", quantity: 1, unit: "whole", category: .other))
                }
            }

            Section("Instructions") {
                ForEach(Array(instructions.enumerated()), id: \.element.id) { index, _ in
                    TextField("Step \(index + 1)", text: binding(forInstructionAt: index, keyPath: \.text), axis: .vertical)
                        .lineLimit(2...5)
                }
                .onDelete { instructions.remove(atOffsets: $0); resequenceInstructions() }

                Button("Add Step") {
                    instructions.append(InstructionStep(stepNumber: instructions.count + 1, text: ""))
                }
            }

            Section("Prep Requirements") {
                ForEach(Array(prepRequirements.enumerated()), id: \.element.id) { index, _ in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Description", text: binding(forPrepRequirementAt: index, keyPath: \.description))
                        TextField("Reminder text", text: binding(forPrepRequirementAt: index, keyPath: \.reminderText))
                        TextField("Lead time (hours)", value: binding(forPrepRequirementAt: index, keyPath: \.leadTimeHours), format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                .onDelete { prepRequirements.remove(atOffsets: $0) }

                Button("Add Prep Step") {
                    prepRequirements.append(
                        PrepRequirement(description: "", leadTimeHours: 4, reminderText: "")
                    )
                }
            }

            Section("Notes & Tags") {
                TextField("Tags (comma separated)", text: $tagsText)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(existingRecipe == nil ? "New Recipe" : "Edit Recipe")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveRecipe()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func saveRecipe() {
        let recipe = Recipe(
            id: existingRecipe?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: subtitle.nilIfBlank,
            sourceURL: existingRecipe?.sourceURL,
            servings: servings,
            prepTimeMinutes: prepMinutes,
            cookTimeMinutes: cookMinutes,
            totalTimeMinutes: prepMinutes + cookMinutes,
            difficulty: difficulty,
            ingredients: ingredients.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            instructions: instructions.enumerated().map { index, step in
                InstructionStep(id: step.id, stepNumber: index + 1, text: step.text)
            }.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            prepRequirements: prepRequirements.filter { !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            tags: tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
            notes: notes.nilIfBlank,
            isFavorite: existingRecipe?.isFavorite ?? false,
            timesCooked: existingRecipe?.timesCooked ?? 0,
            lastCookedDate: existingRecipe?.lastCookedDate,
            dateAdded: existingRecipe?.dateAdded ?? .now
        )
        store.upsertRecipe(recipe)
        dismiss()
    }

    private func resequenceInstructions() {
        for index in instructions.indices {
            instructions[index].stepNumber = index + 1
        }
    }

    private func binding<Value>(getter: @escaping () -> Value, setter: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(get: getter, set: setter)
    }

    private func binding(forIngredientAt index: Int, keyPath: WritableKeyPath<Ingredient, String>) -> Binding<String> {
        binding(
            getter: { ingredients[index][keyPath: keyPath] },
            setter: { ingredients[index][keyPath: keyPath] = $0 }
        )
    }

    private func binding(forIngredientAt index: Int, keyPath: WritableKeyPath<Ingredient, Double>) -> Binding<Double> {
        binding(
            getter: { ingredients[index][keyPath: keyPath] },
            setter: { ingredients[index][keyPath: keyPath] = $0 }
        )
    }

    private func binding(forIngredientAt index: Int, keyPath: WritableKeyPath<Ingredient, IngredientCategory>) -> Binding<IngredientCategory> {
        binding(
            getter: { ingredients[index][keyPath: keyPath] },
            setter: { ingredients[index][keyPath: keyPath] = $0 }
        )
    }

    private func binding(forInstructionAt index: Int, keyPath: WritableKeyPath<InstructionStep, String>) -> Binding<String> {
        binding(
            getter: { instructions[index][keyPath: keyPath] },
            setter: { instructions[index][keyPath: keyPath] = $0 }
        )
    }

    private func binding(forPrepRequirementAt index: Int, keyPath: WritableKeyPath<PrepRequirement, String>) -> Binding<String> {
        binding(
            getter: { prepRequirements[index][keyPath: keyPath] },
            setter: { prepRequirements[index][keyPath: keyPath] = $0 }
        )
    }

    private func binding(forPrepRequirementAt index: Int, keyPath: WritableKeyPath<PrepRequirement, Double>) -> Binding<Double> {
        binding(
            getter: { prepRequirements[index][keyPath: keyPath] },
            setter: { prepRequirements[index][keyPath: keyPath] = $0 }
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
