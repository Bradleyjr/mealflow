# MealFlow Implementation PRD

## Product Thesis

MealFlow succeeds only if dinner planning feels like one continuous household workflow instead of four disconnected tools. The product must keep state flowing from recipe collection into planning, shopping, and prep without duplicate data entry.

## Product Goal

Help a household decide what to cook, organize what to buy, and remember what must happen before dinner with as little friction as possible.

## Primary User

An iPhone user who cooks at home multiple nights per week and acts as the default household meal planner.

## MVP Scope

Phase 1 is the minimum usable loop:

1. Save and edit recipes manually.
2. Assign recipes to days in a weekly plan.
3. Generate a shopping list from planned meals.
4. Check off shopping items and add manual items.
5. Store everything locally on device.

## Post-MVP Scope

These ship after the core loop but should be modeled early to avoid schema churn:

- URL import and photo import
- Local notifications and prep reminders
- Household sync and CloudKit collaboration
- Cooking mode
- Widgets
- Multi-meal day UI beyond the dinner-first model

## Phase Completion Targets

- Phase 1: recipes, dinner planning, shopping list, local persistence
- Phase 2: URL/text import, reminder scheduling logic, repetition insights, cooking history
- Phase 3: household domain and sync boundary, shared list semantics, invite workflow
- Phase 4: cooking mode, shopping mode, export/share surfaces, richer day detail

## Experience Principles

- Dinner-first: default UX is about dinner, not general-purpose nutrition tracking.
- Warm and tactile: cards, rounded surfaces, food-forward imagery, gentle colors.
- Low-friction: every screen should answer a single question quickly.
- Native iOS: use standard navigation, sheet, search, swipe, menu, and list patterns.

## Information Architecture

- Recipes: collection, detail, create, edit
- Plan: current week by default, one primary meal slot per day
- Shop: generated list plus manual additions
- Settings: household placeholder, reminders placeholder, MVP preferences

## Domain Decisions

### Recipe

- Recipes are user-authored first.
- A recipe owns ingredients, steps, prep requirements, tags, and notes.
- Servings scaling affects displayed ingredient quantities only until cooking history and inventory exist.

### Meal Plan

- The canonical week anchor is Monday.
- MVP supports a default `dinner` slot even though the model leaves room for additional meal types later.
- A day may hold either a linked recipe or a custom meal label.

### Shopping List

- Shopping lists are derived from a meal plan.
- Manual items persist across regeneration.
- Checked state should be preserved for unchanged generated items whenever possible.
- Ingredient aggregation keys on normalized ingredient name plus exact unit match.

### Reminders

- Prep requirements remain in the model during MVP so notification work can land without schema churn.
- Reminder scheduling is deferred, but the service boundary should exist.

## Technical Plan

- Platform: SwiftUI, iOS 17, iPhone only
- State: observable app store with a path to SwiftData-backed repositories
- Domain: pure Swift models and business rules isolated from UI
- Persistence target: SwiftData in app layer, but core planning and shopping rules remain platform-agnostic
- Testing: pure-Swift rule tests for week math, repetition detection, and shopping aggregation

## MVP Success Criteria

The MVP is complete when a user can:

1. Create several recipes manually.
2. See them in a browsable collection.
3. Assign them across a week.
4. Generate a categorized shopping list.
5. Add manual grocery items.
6. Leave and reopen the app without losing local data.

## Design System Requirements

- Backgrounds use warm neutrals instead of stark white.
- Cards and list rows feel tactile but remain lightweight.
- Accent colors favor terracotta for primary action and sage for secondary states.
- Typography should prioritize readability and strong section hierarchy.
- All interactive controls must respect Dynamic Type and 44x44pt minimum tap targets.

## Engineering Risks

- SwiftData relationships become complex quickly if every nested entity is modeled as a first-class persisted object.
- Shopping list regeneration can destroy user trust if checked state is lost.
- Household sync should not be allowed to distort the local-first data model.

## Acceptance Checklist

- Recipe list, detail, and editor exist.
- Week planner exists with assign, remove, and completion actions.
- Shopping list generation works for repeated ingredients and unit mismatches.
- Settings expose enough preferences to support future notification and display behavior.
- The codebase separates UI from decision logic.
