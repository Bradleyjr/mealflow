import Foundation

public struct RecipeImportDraft: Codable, Equatable, Sendable {
    public var title: String?
    public var subtitle: String?
    public var sourceURL: String?
    public var servings: Int?
    public var prepTimeMinutes: Int?
    public var cookTimeMinutes: Int?
    public var ingredients: [Ingredient]
    public var instructions: [InstructionStep]
    public var notes: String?

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        sourceURL: String? = nil,
        servings: Int? = nil,
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        ingredients: [Ingredient] = [],
        instructions: [InstructionStep] = [],
        notes: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.sourceURL = sourceURL
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.ingredients = ingredients
        self.instructions = instructions
        self.notes = notes
    }

    public func toRecipe(defaultServings: Int = 4) -> Recipe {
        Recipe(
            title: title ?? "Imported Recipe",
            subtitle: subtitle,
            sourceURL: sourceURL,
            servings: servings ?? defaultServings,
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            difficulty: .easy,
            ingredients: ingredients,
            instructions: instructions
        )
    }
}

public enum RecipeImporter {
    public static func parseHTML(_ html: String, sourceURL: String? = nil) -> RecipeImportDraft {
        if let jsonLDDraft = parseJSONLDRecipe(in: html, sourceURL: sourceURL) {
            return jsonLDDraft
        }
        return parseHeuristicText(html, sourceURL: sourceURL)
    }

    public static func parseRecognizedText(_ text: String) -> RecipeImportDraft {
        parseHeuristicText(text, sourceURL: nil)
    }

    private static func parseJSONLDRecipe(in html: String, sourceURL: String?) -> RecipeImportDraft? {
        let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return nil
        }
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)
        for match in matches {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            let jsonText = html[range].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = jsonText.data(using: .utf8) else { continue }
            if let draft = decodeRecipeJSONLD(data: data, sourceURL: sourceURL) {
                return draft
            }
        }
        return nil
    }

    private static func decodeRecipeJSONLD(data: Data, sourceURL: String?) -> RecipeImportDraft? {
        let object = try? JSONSerialization.jsonObject(with: data)
        if let draft = recipeDraft(from: object, sourceURL: sourceURL) {
            return draft
        }
        return nil
    }

    private static func recipeDraft(from object: Any?, sourceURL: String?) -> RecipeImportDraft? {
        if let array = object as? [Any] {
            for item in array {
                if let draft = recipeDraft(from: item, sourceURL: sourceURL) {
                    return draft
                }
            }
            return nil
        }

        guard let dictionary = object as? [String: Any] else { return nil }
        if let graph = dictionary["@graph"] as? [Any] {
            for item in graph {
                if let draft = recipeDraft(from: item, sourceURL: sourceURL) {
                    return draft
                }
            }
        }

        let typeValue = dictionary["@type"]
        let isRecipe: Bool = {
            if let type = typeValue as? String {
                return type.lowercased() == "recipe"
            }
            if let types = typeValue as? [String] {
                return types.map { $0.lowercased() }.contains("recipe")
            }
            return false
        }()
        guard isRecipe else { return nil }

        let ingredients = (dictionary["recipeIngredient"] as? [String] ?? []).map(parseIngredientLine)
        let instructions = parseInstructionNodes(dictionary["recipeInstructions"])
        return RecipeImportDraft(
            title: dictionary["name"] as? String,
            subtitle: dictionary["description"] as? String,
            sourceURL: sourceURL,
            servings: parseServings(dictionary["recipeYield"]),
            prepTimeMinutes: parseISO8601Duration(dictionary["prepTime"] as? String),
            cookTimeMinutes: parseISO8601Duration(dictionary["cookTime"] as? String),
            ingredients: ingredients,
            instructions: instructions,
            notes: dictionary["description"] as? String
        )
    }

    private static func parseInstructionNodes(_ node: Any?) -> [InstructionStep] {
        if let instructions = node as? [String] {
            return instructions.enumerated().map { index, value in
                InstructionStep(stepNumber: index + 1, text: value)
            }
        }
        if let instructions = node as? [[String: Any]] {
            return instructions.enumerated().compactMap { index, item in
                if let text = item["text"] as? String {
                    return InstructionStep(stepNumber: index + 1, text: text)
                }
                return nil
            }
        }
        if let text = node as? String {
            return text
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .enumerated()
                .map { InstructionStep(stepNumber: $0.offset + 1, text: $0.element) }
        }
        return []
    }

    private static func parseHeuristicText(_ text: String, sourceURL: String?) -> RecipeImportDraft {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let title = lines.first
        var ingredients: [Ingredient] = []
        var instructions: [InstructionStep] = []
        var inIngredients = false
        var inInstructions = false

        for line in lines {
            let lowercase = line.lowercased()
            if lowercase.contains("ingredient") {
                inIngredients = true
                inInstructions = false
                continue
            }
            if lowercase.contains("instruction") || lowercase.contains("direction") || lowercase.contains("method") {
                inInstructions = true
                inIngredients = false
                continue
            }
            if inIngredients {
                ingredients.append(parseIngredientLine(line))
            } else if inInstructions {
                instructions.append(InstructionStep(stepNumber: instructions.count + 1, text: line.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789. "))))
            }
        }

        return RecipeImportDraft(
            title: title,
            sourceURL: sourceURL,
            ingredients: ingredients,
            instructions: instructions
        )
    }

    private static func parseIngredientLine(_ line: String) -> Ingredient {
        let tokens = line.split(separator: " ").map(String.init)
        let quantity = Double(tokens.first ?? "") ?? 1
        let unit = tokens.count > 1 ? tokens[1] : "whole"
        let name = tokens.dropFirst(min(tokens.count, 2)).joined(separator: " ")
        let resolvedName = name.isEmpty ? line : name
        return Ingredient(
            name: resolvedName,
            quantity: quantity,
            unit: unit,
            category: IngredientCategorizer.category(for: resolvedName)
        )
    }

    private static func parseServings(_ value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let stringValue = value as? String {
            return Int(stringValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
        }
        if let array = value as? [String] {
            return array.compactMap(parseServings).first
        }
        return nil
    }

    private static func parseISO8601Duration(_ value: String?) -> Int? {
        guard let value else { return nil }
        let regex = try? NSRegularExpression(pattern: #"PT(?:(\d+)H)?(?:(\d+)M)?"#)
        let nsRange = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex?.firstMatch(in: value, range: nsRange) else { return nil }
        var minutes = 0
        if let range = Range(match.range(at: 1), in: value), let hours = Int(value[range]) {
            minutes += hours * 60
        }
        if let range = Range(match.range(at: 2), in: value), let mins = Int(value[range]) {
            minutes += mins
        }
        return minutes == 0 ? nil : minutes
    }
}

public enum IngredientCategorizer {
    public static func category(for ingredientName: String) -> IngredientCategory {
        let name = ingredientName.lowercased()
        if ["beef", "chicken", "pork", "turkey", "salmon", "shrimp"].contains(where: name.contains) { return .meat }
        if ["milk", "cheese", "yogurt", "butter", "cream"].contains(where: name.contains) { return .dairy }
        if ["bread", "bun", "tortilla", "bagel"].contains(where: name.contains) { return .bakery }
        if ["frozen", "peas", "fries"].contains(where: name.contains) { return .frozen }
        if ["lemon", "lime", "onion", "garlic", "broccoli", "spinach", "potato"].contains(where: name.contains) { return .produce }
        if ["rice", "pasta", "flour", "salt", "beans", "oil"].contains(where: name.contains) { return .pantry }
        return .other
    }
}
