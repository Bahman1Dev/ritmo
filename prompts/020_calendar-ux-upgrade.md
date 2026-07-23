# 020 — Calendar (Journey) UX/UI Upgrade

> **Agent instructions:** Read this file fully, then execute all tasks in order (P1 → P2 → P3). Do not repeat work already done in the codebase — verify current state first, then implement only what is missing. Follow `DESIGN_SYSTEM_PAGES.md` and existing theme (`lib/core/theme/ritmo_theme.dart`) exactly. All user-facing text is Persian (fa), RTL, font `Vazirmatn`, digits via `toPersianDigits`. Do NOT add new pub dependencies. Do NOT touch scope covered by `prompts/019_calendar-fixes.md` (event bus / cache invalidation) — it is done.

## Context

The Journey calendar lives in `lib/features/calendar/presentation/`:

- `journey_screen.dart` (~422 L) — scaffold, hero, pinch-to-zoom scale switching (`JourneyScale`: hours24 / week / month / year), "go to today" FAB, `UniversalPlannerSheet` FAB.
- `journey_controller.dart` (~608 L) — `ChangeNotifier`; `selectedDate`, `scrolledDate`, `loadRange`, `agendas` map keyed by `toIso8601String().substring(0,10)`, `computeFreeTime`, `getSuggestionForDate`, `getSummaryForDate`, conflict detection, sleep blocks.
- `journey_widgets.dart` (~594 L) — hero, tab switcher, heatmap card, station card, empty state, skeleton.
- `widgets/timeline_grid.dart` (~1387 L) — day/week timeline. `pxPerMinute = 2.0`, 24h grid, drag-to-reschedule with 15-min snap (`snapPx = pxPerMinute * 15`), `_draggingItem`, `_LiveNowLine` (Timer.periodic 30 s), sleep blocks, conflict layout (`overlapsGroup`, lanes), tap on empty slot opens `UniversalPlannerSheet` prefilled.
- `widgets/density_grid.dart` (~380 L) — month/year heatmap by `totalCompletionRate`, Jalali via `shamsi_date`.

The strong foundation (zoom scales, drag, now-line, conflicts, suggestions) exists. This prompt is pure UX polish + interaction upgrades. **No schema/DB changes. No new services.**

---

## P1 — Core interaction fixes (do these first)

### Task 1 — Auto-scroll timeline to "now"
**File:** `widgets/timeline_grid.dart`, `journey_screen.dart`

- The main `SingleChildScrollView` (~line 128) has no `ScrollController`. Add one owned by `TimelineGrid`'s state.
- On first layout, if the visible range contains today (`_isToday`), jump (no animation on first build) to offset `(currentMinutes - 60) * pxPerMinute`, clamped to `[0, totalHeight - viewportHeight]`. For non-today dates keep offset 0 (or 8:00 * 60 * pxPerMinute — pick 8:00 for consistency, so users never land on an empty midnight wall).
- When the user taps the existing "برو به امروز" button (`journey_screen.dart` ~line 161): after `setSelectedDate(today)`, also animate the timeline to the now-offset (300 ms, `Curves.easeOutCubic`). Expose this via a method on the grid state (e.g. `GlobalKey` or a `ValueListenable`/callback passed down — choose the least invasive pattern already used in this codebase).
- Preserve scroll offset across `setState` rebuilds (controller keeps it automatically — just don't recreate it).

### Task 2 — Edge auto-scroll while dragging an item
**File:** `widgets/timeline_grid.dart`

- Today, when `_draggingItem != null`, physics become `NeverScrollableScrollPhysics`, so an item cannot be dragged to an off-screen hour. Keep the physics lock, but add edge auto-scroll:
  - During `onLongPressMoveUpdate`, if the pointer's global Y is within 80 px of the viewport top/bottom edge, start a per-frame ticker (or `Timer.periodic` ~16 ms) that scrolls the controller by a speed proportional to edge proximity (e.g. 4–14 px/frame), and simultaneously updates `_draggingTop` so the ghost stays under the finger.
  - Stop the ticker when the pointer leaves the edge zone, on `onLongPressEnd`, and on dispose.
  - Re-clamp the final drop with the existing snap + clamp logic (~lines 582–596). The 15-min snap and conflict handling must keep working unchanged.

### Task 3 — Horizontal swipe between days/weeks
**Files:** `widgets/timeline_grid.dart` or `journey_screen.dart` (choose the cleanest seam), `journey_controller.dart`

- In `JourneyScale.hours24`, wrap the timeline in a `PageView.builder` (infinite-ish: index ↔ date offset from an anchor date) so swiping right/left (RTL-aware: in RTL, swipe direction should feel natural — test both) moves to previous/next day via `controller.setSelectedDate(...)`.
- In `JourneyScale.week`, the same gesture moves by 7 days.
- Requirements:
  - Keep the current pinch-to-zoom `GestureDetector` working — `PageView` must not swallow scale gestures (use `PageView` default drag + the existing raw scale detector on the parent; verify pinch still switches scales).
  - Preserve the vertical scroll offset when swiping between days (pass the shared `initialScrollOffset` / reuse one controller strategy per page — simplest: store last offset in the grid state and apply to new page's controller on creation).
  - Call `controller.ensureRange` / `loadRange` for the newly visible date so agendas prefetch (the controller already loads ranges — prefetch ±1 page).
  - Haptic `HapticFeedback.selectionClick()` on page settle.

---

## P2 — Timeline interaction polish

### Task 4 — Two-step tap on empty slots (ghost chip instead of instant sheet)
**File:** `widgets/timeline_grid.dart` (~line 176)

- Replace "tap empty slot → immediately open `UniversalPlannerSheet`" with:
  1. First tap: show an inline ghost chip at the snapped 15-min position: `+ افزودن در ۱۴:۱۵` (gold outline, subtle fade-in 150 ms). Persian digits.
  2. Tap on the chip: open `UniversalPlannerSheet` prefilled with that time (existing behavior).
  3. Chip auto-dismisses after 3 s, on scroll, on tap elsewhere, or on date change.
- Keep long-press-on-item drag behavior untouched.

### Task 5 — Richer drag feedback
**File:** `widgets/timeline_grid.dart`

While dragging an item:
- **Snap haptics:** fire `HapticFeedback.selectionClick()` each time the snapped target minute changes (i.e. once per 15-min tick, not per pixel).
- **Delta label:** the floating time label must also show the delta from the original start, e.g. `۱۵:۳۰ (+۴۵ دقیقه)` / `(−۳۰ دقیقه)`. Hide delta when 0.
- **Conflict preview:** while hovering, compute whether the candidate slot overlaps another timed item (reuse the existing overlap logic used for `isConflict` / `overlapsGroup` — extract a small helper if needed). If conflicting, tint the drag ghost border/label red (`Colors.warning`-equivalent from `RitmoColors`); do NOT block the drop (current behavior of allowing conflicts stays).

### Task 6 — Free-gap suggestion chips
**Files:** `widgets/timeline_grid.dart`, `journey_controller.dart`

- The controller already has `computeFreeTime` and `getSuggestionForDate`. Connect them to the day timeline:
  - For today (and future days), detect gaps ≥ 45 min between consecutive timed items within waking hours (exclude sleep blocks).
  - Render a subtle centered chip inside each gap: `۲ ساعت خالی — پیشنهاد بده` (muted color, alpha ~0.6, no heavy borders — it must read as background, not content).
  - Tap → fetch the suggestion for that gap (`getSuggestionForDate` scoped to the gap's time window; if the current API only works per-date, add an optional `{int? fromMinute, int? toMinute}` parameter — additive, non-breaking) and open `UniversalPlannerSheet` prefilled with the suggested item + gap start time.
  - Max 3 chips per day (largest gaps first) to avoid noise. Hide all chips for past days.

### Task 7 — "Now" pill (current activity strip)
**Files:** `widgets/timeline_grid.dart` or `journey_screen.dart`, data from `journey_controller.dart`

- When viewing **today** in hours24 scale, show a slim sticky pill at the top of the timeline area:
  - If a timed item is in progress: `الان: ریاضی — ۲۵ دقیقه مانده` + a small check button (calls the same complete action as the item's detail sheet, e.g. `completeOccurrence`/`completeRoutine` via existing `AgendaActionHandler`/`RoutineActions` path) — reuse, don't duplicate logic.
  - If free: `الان آزاد هستی تا ۱۶:۰۰` (next timed item start).
  - Update it from the same 30 s tick as `_LiveNowLine` (lift the timer or add a second lightweight one — prefer sharing).
  - Tap on the pill scrolls to the now-line (reuse Task 1's scroll method).
  - Hide when scrolled to now already AND the pill's item is visible? — keep it simple: always visible for today, 32–36 px tall, glass style consistent with `glassCardLight`.

---

## P3 — Week/month views, hierarchy, a11y

### Task 8 — Readable week view
**File:** `widgets/timeline_grid.dart`

- Current week view renders 7 `Expanded` columns → ~40 dp each, unreadable labels.
- Change: in `JourneyScale.week`, render items as **color blocks only** (category color via `RoutineCategoryHelper.getCategoryColor`, rounded 4 px, no text) with a 2 px completion indicator (checkmark dot for done items ≥ 30 min tall).
- Day headers become the primary navigation: tapping a day header zooms into that day (`setSelectedDate` + `setScale(JourneyScale.hours24)`) — this handler partially exists (~line 1161); make the affordance visible: header of a tappable day gets an underline/chevron and today's header gets the gold treatment it already has.
- Long-press a block in week view → show a small tooltip-style overlay with title + time (no full sheet).

### Task 9 — Density grid legend + streak
**File:** `widgets/density_grid.dart`

- Under the month grid, add a one-line legend, RTL: `کمتر` + 5 swatch squares using the exact same color ramp as the cells (reuse the cell color function — extract it so legend and cells can't drift) + `بیشتر`.
- Above or beside the legend, show current streak: consecutive days (ending today) with `totalCompletionRate ≥ 0.5` → `🔥 ۶ روز پیاپی`. Compute from already-loaded agenda summaries only — do not add DB queries; if data for a day isn't loaded, stop counting there.
- Year view: same legend, smaller.

### Task 10 — Pinch-zoom discoverability
**Files:** `journey_screen.dart`

- One-time coach mark (persist flag in the app's existing settings/prefs mechanism — find how other one-time flags are stored, e.g. onboarding flags, and use the same store; key: `journey_pinch_hint_shown`):
  - On the 2nd visit to the Journey screen (not the 1st — don't pile onto first impressions), show a dismissible overlay hint near the tab switcher: `با دو انگشت باز/بسته کنید تا نما عوض شود` with a small pinch icon, auto-dismiss 5 s or on any scale change.
  - Never show again after dismissal or after the user performs a pinch scale change even once.

### Task 11 — Visual hierarchy: dim the past, discipline the gold
**Files:** `widgets/timeline_grid.dart`

- In today's hours24 view, overlay elapsed time with a subtle scrim: from 00:00 to the now-line, `colors.bg.withValues(alpha: 0.35)` (pointer-transparent — `IgnorePointer`), so past hours visually recede. Items stay tappable through it. No dim for other days.
- Gold audit within calendar files only: `goldAccent` currently marks many things. Keep gold for: now-line, today markers, selected state, primary FAB. Agenda item blocks should lean on category colors (`getCategoryColor`) with gold reserved as accent. Adjust only clear violations; do not restyle the whole screen.

### Task 12 — Semantics / accessibility pass
**Files:** all 5 calendar files

- Wrap interactive elements with `Semantics`:
  - Agenda item block: label `«ریاضی، ۱۴:۰۰ تا ۱۵:۰۰، انجام‌شده»` (title, time range, status), `button: true`, hint for long-press drag: `برای جابه‌جایی نگه دارید`.
  - Density grid cell: `«۱۲ تیر، ۳ فعالیت، ۸۰٪ تکمیل»`; placeholder/future cells `excludeSemantics`.
  - Now-line: `liveRegion: false`, label `«زمان حال، ۱۴:۳۵»`.
  - Tab switcher, FABs, header nav arrows: proper labels (some `IconButton`s in `density_grid.dart` have none).
- Respect `MediaQuery.disableAnimations` for the breathing/glow animations in `journey_widgets.dart` (skip repeat animations when true).

---

## Constraints & Definition of Done

- `flutter analyze` → 0 new warnings/errors.
- No new dependencies; no changes under `lib/core/domain/` except the optional additive parameter in Task 6.
- All strings Persian, digits via `toPersianDigits`, layout RTL-safe, `Vazirmatn` font, existing `RitmoColors`/`RitmoTheme` tokens only.
- 60 fps: edge auto-scroll ticker and now-pill updates must not rebuild the whole grid (scope `setState`/`AnimatedBuilder` narrowly).
- Drag + snap + conflict lanes + sleep blocks + pinch scale switching must all still work after Tasks 1–3 (regression-test manually: drag an item across a day boundary of the viewport, pinch on every scale, swipe during load).
- Update `walkthrough.md` with a short section "Journey UX upgrade (020)" listing what changed.
- Write a completion report to `prompts/020_REPORT.md`: per task — done/partial/skipped + why, files touched, known issues.
