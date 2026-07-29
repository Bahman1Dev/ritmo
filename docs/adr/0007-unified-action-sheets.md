# ADR 0007: Unified Action Sheet Architecture

## Status
Accepted

## Context
Previously, bottom sheets across Ritmo were fragmented into disparate custom containers, each maintaining private `Navigator.pop` calls prior to asynchronous database operations. This caused silent failure bugs, double-taps, context leaks, and visual inconsistencies.

## Decision
We adopt the "One Shell, Three Behaviors, N Contents" architecture:
1. `RitmoSheetScaffold` handles all visual primitive constraints (glassmorphism, handles, keyboard padding, RTL, accessibility).
2. Action Sheets, Pickers, and Forms are strictly separated into three distinct behavioral contracts.
3. Submissions execute inside `RitmoActionSheet` prior to closing the modal context, preventing premature pop bugs.

## Consequences
- 100% elimination of premature `Navigator.pop` bugs.
- Single entry point for bottom modals (`RitmoSheetScaffold.present`).
- Guaranteed type safety for action sheet outputs.
