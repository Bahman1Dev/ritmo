# ADR 0003: Pipeline-Based Intelligence Engine

## Status
Accepted

## Context
The `RitmoIntelligenceEngine` evaluated visible/hidden routines, scores, and focus recommendations in a single 548-line class. It directly executed queries on the SQLite database (`db.query`), violating domain-infrastructure boundary rules and making unit testing of business rules impossible without complex SQLite mocks.

## Decision
We decided to refactor the engine into a pure pipeline architecture:
1. **Context Snapshot**: An immutable, pure data container (`ContextSnapshot`) holds all settings, exception records, completed routines, cycles, and energy metrics.
2. **Context Resolver**: An infrastructure component queries the database and builds the `ContextSnapshot` once.
3. **Filter Pipeline**: A pipeline runs routines through independent, chainable filters (e.g. `ZoneFilter`, `EnergyFilter`, `BiologicalFilter`).
4. **Scoring Engine**: Evaluates relevance scores through independent scorers (e.g. `TimeRelevanceScorer`, `FocusBonusScorer`).
5. **Robust Exception Catching**: If the pipeline or any filter throws an unexpected exception during execution, the engine must catch it, log it, and fallback to a basic visible routine list instead of crashing the background runner.

## Consequences
### Positive
* 100% Pure Domain Logic: The filters and scorers do not import Flutter or SQLite.
* Unit Testability: The entire scoring and filtering logic can be tested with basic mock context snapshots in milliseconds.
* Performance: Pre-fetching all context data once resolves the N+1 database query problem.

### Negative
* Higher object creation: Pipeline and Scorer objects are instantiated dynamically per evaluation.

## Alternatives Considered
* *SQL-driven logic*: Offloading evaluation to complex SQL queries. Rejected because SQLite lacks the advanced mathematical scoring, list operations, and state machine capabilities required by the RIE.
