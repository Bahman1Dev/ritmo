# ADR 0005: Context Snapshot Pattern

## Status
Accepted

## Context
Core evaluation engines (e.g. `RitmoIntelligenceEngine`, `ReshuffleEngine`) need access to multiple runtime states, including active zones, completed tasks, biological cycle information, current energy level, and calendar exceptions. Resolving these dynamically inside the engine execution loops leads to mixed responsibilities and high database query latency.

## Decision
We decided to adopt the Context Snapshot Pattern:
1. **ContextSnapshot Entity**: Create an immutable class `ContextSnapshot` representing a point-in-time state of the user's environment.
2. **Pre-fetching**: All data required by the intelligence pipeline is retrieved in a single batch query in the application/infrastructure layer before starting evaluation.
3. **Pure Parameters**: The intelligence engine only accepts the list of routines and the `ContextSnapshot` as parameters.
4. **Mocking**: For tests, we instantiate a `ContextSnapshot` with fixed mock values instead of setting up mock databases.

## Consequences
### Positive
* High Performance: Reduces database round-trips by pre-fetching all required properties once.
* Pure Logic: Keeps the core intelligence logic as pure functions (`(Routines, ContextSnapshot) -> Output`).
* Simpler Tests: Developers can construct custom test scenarios by manually instantiating a `ContextSnapshot` without setting up mock SQLite instances.

### Negative
* Memory overhead: Holds all active context parameters in memory during the evaluation loop.

## Alternatives Considered
* *Lazy Loaded Context*: Accessing repositories lazily inside the engine. Rejected because it would require passing async repository references into the engine, making the engine impure and harder to test.
