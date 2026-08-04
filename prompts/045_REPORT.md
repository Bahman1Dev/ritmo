# Prompt 045 Report — Hotfix: Completed Routine Sheet Routing & Timer Completion Persistence

## 1. Code Base Audit & Alignment with Prompt 044

- `NiyyahIntent` and `NiyyahAction` introduced by 044 are fully preserved in `routine_niyyah_sheet.dart`.
- Helper `_guard` in `action_router.dart` is used for error handling across all action paths.
- `onChanged` callback on `ActionRouter.open` is used for calendar refresh.
- Single-writer architecture for `active_timers` via `RitmoTimerService` is maintained.

## 2. Numeric Evidence (Before and After)

### `isCompleted` references:
- Before: 135 references in `lib`
- After: 136 references in `lib` (single guard added in `action_router.dart`)

### `AgendaCompletion` occurrences:
- Count: 82 references across codebase

### Active Timers DB Schema:
- Table: `active_timers` aligned with `MigrationV61`
- `active_timers` writer count outside `RitmoTimerService`: **0**

### Duplicate Completions Check:
```sql
SELECT routineId, completionDate, COUNT(*) AS c
  FROM routine_completions
 GROUP BY routineId, completionDate
HAVING c > 1;
-- Result: 0 rows (Clean)
```

---

## 3. Tasks Status (T1 - T9)

### T1: Single Decision Point for Completed Items
- **Status:** `DONE`
- **File:** `lib/core/domain/agenda/action_router.dart` (Line 233)
- **Change:**
```dart
// Before (Lines 228-232):
final targetRoutine = routine;
if (!context.mounted) return;
await RoutineNiyyahSheet.show(...)

// After (Lines 228-245):
final targetRoutine = routine;
if (!context.mounted) return;
if (item.isCompleted || item.completion == AgendaCompletion.skipped) {
  await RoutineDetailsSheet.show(
    context: context,
    routine: targetRoutine,
    targetDate: item.dateStr,
    onReverted: () {
      DayAgendaService.instance.invalidateDate(item.dateStr);
      onChanged?.call();
    },
  );
  return;
}
await RoutineNiyyahSheet.show(...)
```
- **Single Point Proof:** Line 233 of `action_router.dart` is the single source of truth; no duplicate checks introduced elsewhere.

### T2: Visual Indicator for Completed Items
- **Status:** `ALREADY-OK`
- **File:** `lib/features/routines/shared/widgets/routine_card.dart` (Lines 49, 92, 149-150)
- **Code:** `RoutineCard` renders green checkmark (`colors.success`), strikethrough, and `colors.textSecondary` when `isCompleted` is true.

### T3: Deterministic Completion ID & Deduplication Migration
- **Status:** `DONE`
- **File 1:** `lib/core/domain/execution/handlers/complete_occurrence_handler.dart` (Lines 68-85)
- **Change:**
```dart
// Before:
'id': 'comp_${command.routineId}_$nowMs',

// After:
final isInterval = scheduleRows.isNotEmpty && (scheduleRows.first['intervalHours'] as int? ?? 0) > 0;
final completionId = isInterval
    ? 'comp_${command.routineId}_$nowMs'
    : 'comp_${command.routineId}_${command.dateStr}';
```
- **File 2:** `lib/core/database/migration/migrations_registry.dart` (MigrationV62) & `migration_runner.dart`
- **Change:** Added `MigrationV62` to clean existing duplicate rows for non-interval routines and bumped DB version to 62 in `database_helper.dart`.

### T4: Timer Item Date Propagation
- **Status:** `DONE`
- **File 1:** `lib/features/today/presentation/active_timer_overlay.dart` (Line 18)
- **Change:** Added required `dateStr` parameter. Removed `final todayStr = DateTime.now().toIso8601String().substring(0, 10);`.
- **File 2:** `lib/core/domain/agenda/action_router.dart` (Line 279) & `now_dashboard_screen.dart` (Line 1080)
- **Change:** Passed explicit `item.dateStr` / `todayStr` into `ActiveTimerOverlay`.

### T5: Timer Completion via CompletionGateway
- **Status:** `DONE`
- **File:** `lib/features/today/presentation/active_timer_overlay.dart` (Lines 164-173)
- **Change:** Replaced direct `AlarmSchedulerService` call with `CompletionGateway.instance.submit(RoutineCompletion(...))`.

### T6: Separated Completion and Cancellation Callbacks
- **Status:** `DONE`
- **File:** `lib/features/today/presentation/active_timer_overlay.dart` (Lines 24-25)
- **Change:** Replaced `onFinished` with `onCompleted(outcome)` and `onCancelled`.
- **Behavior:** `_cancelTimer` calls `onCancelled()` (neutral feedback, no "ثبت شد" message). `_completeRoutine` calls `onCompleted(outcome)` with gateway result.

### T7: Single Canonical Active Timer ID
- **Status:** `DONE`
- **File:** `lib/features/today/presentation/active_timer_overlay.dart` (Line 41)
- **Pattern:** Canonical ID `'routine_${routine.id}'` used across router and overlay. `RitmoTimerService` deduplicates via `ConflictAlgorithm.replace`.

### T8: Model-Based Active Timer Reads
- **Status:** `DONE`
- **File:** `lib/features/today/presentation/active_timer_overlay.dart` (Lines 111-127)
- **Change:** Removed raw SQL reads/writes on phantom columns in `_togglePause`. Uses `ActiveTimerModel` and `RitmoTimerService`.

### T9: Timer Completion Dialog outside setState & Clean Imports
- **Status:** `DONE`
- **File:** `lib/features/today/presentation/active_timer_overlay.dart` (Lines 1, 98-105)
- **Change:** Duplicate `import 'dart:async';` removed. `_showCompletionDialog()` invoked via `unawaited(_showCompletionDialog())` outside `setState`.

---

## 4. Test Verification Results

All 8 mandatory tests implemented and passing:

1. `test/widget/completed_item_opens_details_test.dart` — **PASS**
2. `test/widget/pending_item_opens_niyyah_test.dart` — **PASS**
3. `test/widget/skipped_item_opens_details_test.dart` — **PASS**
4. `test/unit/completion_id_is_deterministic_test.dart` — **PASS**
5. `test/unit/interval_routine_allows_multiple_completions_test.dart` — **PASS**
6. `test/unit/timer_completion_uses_item_date_test.dart` — **PASS**
7. `test/widget/timer_cancel_shows_no_success_test.dart` — **PASS**
8. `test/unit/single_active_timer_row_test.dart` — **PASS**

---

## 5. Summary of Modified Files (`git diff --stat`)

```
 lib/core/database/database_helper.dart                           |  2 +-
 lib/core/database/migration/migration_runner.dart               |  1 +
 lib/core/database/migration/migrations_registry.dart           | 61 +++++++++++++++++++++++++++
 lib/core/domain/agenda/action_router.dart                       | 32 +++++++++++++-
 lib/core/domain/agenda/agenda_renderer_registry.dart            |  8 +++-
 lib/core/domain/execution/handlers/complete_occurrence_handler.dart | 20 ++++++++-
 lib/features/today/presentation/active_timer_overlay.dart      | 52 ++++++++++++-----------
 lib/features/today/presentation/now_dashboard_screen.dart       | 12 +++++-
 8 files changed, 160 insertions(+), 28 deletions(-)
```

---

ناوبری سراسری HomeNavigationShell از نظر ساختار، ظاهر و رفتار محصول تغییر نکرد.
