# Ritmo Design System — Unified Action Sheets

## Overview
This document defines the architecture and grammar for bottom action sheets in the Ritmo application.

## Core Pattern: One Shell, Three Behaviors, N Contents

### 1. The Shell: `RitmoSheetScaffold`
Located at `lib/core/ux/ritmo_sheet_scaffold.dart`.
- Single visual primitive for glassmorphism backdrop, handle bar, RTL text direction, keyboard inset padding, height constraints, and haptics.
- Exposes static `RitmoSheetScaffold.present<T>()`.

### 2. The Three Behaviors

1. **`RitmoActionSheet`** (`lib/core/widgets/action/ritmo_action_sheet.dart`)
   - 5-Zone Architecture:
     - Zone 1: Identity Header (Domain Icon, Title, Subtitle, Domain Badge)
     - Zone 2: Domain ActionBody (`ActionBody`)
     - Zone 3: Single Primary Submit Action (Full width)
     - Zone 4: Secondary & Handoff Actions (Max 2 in a row)
     - Zone 5: Collapsible ExpansionTile for Destructive / Skip / Edit actions.
   - Lifecycle: Submissions execute INSIDE sheet. On failure, sheet stays open displaying the error message.

2. **`RitmoPickerSheet`** (`lib/core/widgets/sheet/ritmo_picker_sheet.dart`)
   - Selection-only generic list picker returning `Future<T?>`. Never writes directly.

3. **`RitmoFormSheet`** (`lib/core/widgets/sheet/ritmo_form_sheet.dart`)
   - Multi-step form wizard shell with progress bar, next/previous buttons, step validation, and loading spinners.

## Rules for Adding New Domain Bodies
1. Inherit from `ActionBody` (`lib/core/widgets/action/action_sheet_registry.dart`).
2. Declare capabilities via `ActionCapabilities`.
3. Provide `getSubmitActions(context)` and `getHandoffActions(context)`.
4. Register in `ActionSheetRegistry` during app initialization.
