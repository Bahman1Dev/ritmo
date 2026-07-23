# ADR 0007: Typed Payloads over Maps

## Status
Accepted

## Context
Data transfer between UI, logic controllers, and database layers was often done using dynamic JSON maps (`Map<String, dynamic>`). This resulted in lack of type safety, potential spelling mistakes on keys (e.g. `op_type` vs `opType`), and runtime crashes that couldn't be caught by the compiler.

## Decision
We decided to ban raw Map data structures in domain and application logic in favor of typed payloads:
1. **Freezed Payloads**: Use `@freezed` to define immutable payloads (e.g., `SportsPlannerPayload`, `WorshipPlannerPayload`).
2. **Type Safety**: The Strategy interface must accept these strongly-typed payload classes.
3. **Serialization**: Any mapping to SQLite database structures must be done inside the repository implementation layer, keeping maps localized strictly to database inputs/outputs.
4. **Compile-time validation**: Properties must be typed fields rather than dynamic keys.

## Consequences
### Positive
* Type Safety: The compiler guarantees that all required fields are present and have the correct type.
* IDE Autocomplete: Developers get autocompletion and compiler validation when writing payload mappings.
* Safety: Reduces runtime crashes due to database key typos or incorrect type conversions.

### Negative
* Generated Code Boilerplate: Requires running `build_runner build` to generate Freezed and JSON serializable code files.

## Alternatives Considered
* *Standard Dart classes*: Using standard classes with manual `copyWith` and `toMap` methods. Rejected because Freezed provides much cleaner syntax, built-in equality comparison (`==`), and robust constructor generation with minimal hand-written code.
