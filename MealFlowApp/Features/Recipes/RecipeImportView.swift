import SwiftUI

struct RecipeImportView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var sourceMode = 0
    @State private var sourceInput = ""
    @State private var draft: RecipeImportDraft?
    @State private var showingEditor = false

    var body: some View {
        Form {
            Picker("Source", selection: $sourceMode) {
                Text("URL HTML").tag(0)
                Text("Recognized Text").tag(1)
            }
            .pickerStyle(.segmented)

            Section(sourceMode == 0 ? "Paste HTML or page source" : "Paste recognized recipe text") {
                TextField("Recipe source", text: $sourceInput, axis: .vertical)
                    .lineLimit(8...16)
            }

            if let draft {
                Section("Preview") {
                    LabeledContent("Title", value: draft.title ?? "Untitled")
                    LabeledContent("Ingredients", value: "\(draft.ingredients.count)")
                    LabeledContent("Steps", value: "\(draft.instructions.count)")
                }
            }
        }
        .navigationTitle("Import Recipe")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Parse") {
                    parse()
                }
                Button("Review") {
                    showingEditor = true
                }
                .disabled(draft == nil)
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let draft {
                NavigationStack {
                    RecipeEditorView(importDraft: draft)
                }
            }
        }
    }

    private func parse() {
        draft = if sourceMode == 0 {
            RecipeImporter.parseHTML(sourceInput)
        } else {
            RecipeImporter.parseRecognizedText(sourceInput)
        }
    }
}
