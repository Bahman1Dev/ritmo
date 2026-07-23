# ADR 0002: Modular Database Schema and Migrations

## Status
Accepted

## Context
The database helper class (`DatabaseHelper.dart`) had grown to 2664 lines. It served as a single God Object for schema definitions, database creation, Version 1 to 34 migrations, seeding default values, and execution of queries for every feature area. This led to high risk of regressions when editing database models, and made schema migration testing difficult.

## Decision
We decided to decompose `DatabaseHelper` into a modular architecture:
1. **Schema Manager**: Orchestrates database creation by delegating table definitions to feature-specific schema files (e.g. `routine_tables.dart`, `worship_tables.dart`).
2. **Migration Runner**: Runs individual, single-responsibility migration classes (v1 to v34) in sequential order. Each migration inherits from a base interface.
3. **Externalized Seed Data**: Move large dataset seeds (like Iran Cities list) out of compiled code into assets (`iran_cities.json`).
4. **Transaction Propagation**: Add support for an optional `DatabaseExecutor` parameter in all repository query methods. This enables executing multi-module write operations within a shared database transaction to prevent deadlocks and maintain consistency.
5. **Database Facade**: Keep `DatabaseHelper` as a lightweight facade exposing only connection hooks.

## Consequences
### Positive
* Maintainability: Changes to database tables or queries are isolated to feature modules.
* Reliability: Schema migrations can be tested incrementally (v1 to v34 upgrade and structure verification tests).
* Thread Safety: Shared transaction support guarantees write operations are atomic and deadlock-free.

### Negative
* Refactor effort: Relocating and updating 34+ migration queries requires meticulous attention to syntax and version sequences.

## Alternatives Considered
* *Raw migration scripts*: Keeping all migrations in raw SQL strings inside a single helper. Rejected because it makes migration testing and rollback verification impossible to run in isolation.
