# ADR 0001: Strategy Pattern for Universal Planner

## Status
Accepted

## Context
The Universal Planner Sheet (`universal_planner_sheet.dart`) and `PlannerController` were acting as God Objects. The controller had over 100 fields, 10+ category-specific save methods, and mixed UI state, NLP parsing, validation, and database operations. The UI widgets had huge conditional logic and switches on `Category` to render subsystem forms (Sports, Worship, Medical, etc.). This made adding new categories high-risk and hard to maintain.

## Decision
We decided to extract category-specific UI forms, validation, and saving operations into a Strategy Pattern:
1. Define a generic `PlannerCategoryStrategy<P extends PlannerPayload>` interface in the domain layer.
2. Define typed Freezed models (`SportsPlannerPayload`, `WorshipPlannerPayload`, etc.) to hold category configuration parameters instead of generic JSON maps.
3. Decouple strategy implementations from presentation controller state. Strategy methods must not depend on or import UI-specific controller classes (like `PlannerController`). Instead, the UI controller maps its values to payloads, and strategies validate/save these payloads using pure repositories.
4. Separate the NLP quick-add feature to a dedicated `QuickAddParserService`.

## Consequences
### Positive
* Single Responsibility: Each category form, validator, and mapper lives in its own strategy class.
* Extensibility: Adding a new planner category only requires creating a new strategy class and payload, without touching existing categories.
* Testability: Validation and database mapping can be fully unit-tested in isolation without mocking Flutter UI classes.

### Negative
* File Count: Increases the number of files in `lib/features/routines/` (adds payload and strategy files per category).

## Alternatives Considered
* *Conditional Controller subclasses*: Creating subclasses of `PlannerController` for each category. Rejected because it would still require central switches in the UI sheet and wouldn't solve the tight coupling between UI widgets and domain models.
