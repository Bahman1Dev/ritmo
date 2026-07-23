# 021 — Add Station (UniversalPlannerSheet) UX/UI Upgrade

> **Agent instructions:** Read this file fully, then execute all tasks in order (P1 → P2 → P3). Do not repeat work already done in the codebase — verify current state first, then implement only what is missing. Follow `DESIGN_SYSTEM_PAGES.md`, `DESIGN_ADD_ITEM_FLOW.md` and the existing theme (`lib/core/theme/ritmo_theme.dart`) exactly. All user-facing text is Persian (fa), RTL, font `Vazirmatn`, digits via `toPersianDigits`. Do NOT add new pub dependencies. Do NOT change the DB schema or any repository/service contracts. Do NOT touch the category-specific sheets themselves (medical / worship / courses / goals openers) — only the planner flow around them.

## Context

The "add new station" flow lives in `lib/features/routines/presentation/`:

- `widgets/universal_planner_sheet.dart` — the bottom sheet shell: 3-step `PageView` wizard (`controller.currentPage` 0..2, `controller.updatePage`), header, progress, hosts the step widgets below.
- `planner_controller.dart` — `ChangeNotifier`; `title`, `description`, `priority`, `targetDuration`, `adjustDuration`, `selectedCategory`, `selectedTimeStr`, `isEditing`, `isAdvancedExpanded`, `save(context)`, quick-add parsing entry point.
- `widgets/planner_natural_input.dart` — free-text title field. **Known bug (~lines 54–55):** `onChanged` writes the raw text into `controller.title`; the `QuickAddParser` only runs on the trailing arrow-icon tap or keyboard submit. If the user types «فردا ساعت ۸ برم باشگاه» and hits «ادامه» without tapping the arrow, the station title keeps the date/time text inside it and nothing is parsed.
- `widgets/planner_category_grid.dart` — ~9-category grid on step 1; some categories (medical, worship, courses, goals) redirect out of this flow into dedicated sheets via `setMedicalSheetOpener` / `setWorshipSheetOpener` / `setCourseSheetOpener` etc.
- `widgets/planner_timeline_picker.dart` — hour/minute wheels + sunrise/sunset shortcut chips.
- `widgets/planner_duration_picker.dart` — duration row, only ±15-minute `IconButton`s.
- `widgets/planner_advanced_section.dart` — collapsible description + priority. **Known bug (~lines 51–57):** body is conditionally mounted with `if (controller.isAdvancedExpanded)` and wrapped in `AnimatedContainer`, so the expand animation never actually plays (the subtree is freshly built each time).
- `widgets/planner_submit_button.dart` — gradient CTA. Hardcoded off-palette gradient `0xff8B5CF6` → `0xff10B981` (~lines 29–30), emoji in label (`➜`, `➕`), no disabled state, no loading state, no double-tap guard.
- `widgets/planner_journey_preview.dart` — shows the previous/next station around the new one. Great differentiator, but only surfaces on step 3.

Available infrastructure to reuse (do not duplicate): `QuickAddParser` (regex fa parser), `DurationEstimator` (AI duration estimate, already used elsewhere), `JourneyController.computeFreeTime` + conflict detection in `lib/features/calendar/presentation/journey_controller.dart`, routines history in the local DB.

**No schema/DB changes. No new services. No new dependencies.**

---

## P1 — Core flow fixes (do these first)

### Task 1 — Live parsing + removable chips in the natural input
**Files:** `widgets/planner_natural_input.dart`, `planner_controller.dart`

- Run `QuickAddParser` live while typing, debounced ~350 ms (a `Timer` in the widget/controller — no new deps). Remove the arrow-tap-only parsing path; keep keyboard submit as "advance to next step".
- Render each parsed entity as a removable chip row directly under the field, RTL, gold-outline style consistent with the theme:
  - `🕐 فردا ۸:۰۰ ✕` (time/date) · `🔁 هر روز ✕` (recurrence) · `⏱ ۳۰ دقیقه ✕` (duration) — only show chips for entities actually parsed.
  - Tapping `✕` removes that entity: the controller un-applies it (e.g. clears the parsed time) AND remembers the rejected span so re-parsing the unchanged text does not resurrect it.
- **Clean-title guarantee:** `controller.title` must always be the input text minus the accepted parsed spans, trimmed. Whatever path leads to `save()` (submit button, quick save from Task 2, keyboard submit), the stored title must never contain date/time/recurrence text that was parsed into fields.
- The parsed time/duration/recurrence must be visibly reflected on steps 2–3 (they already bind to the controller — just verify after the refactor).
- Persian digits in chips via `toPersianDigits`. Haptic `HapticFeedback.selectionClick()` when a chip appears.

### Task 2 — "Quick save" escape hatch from the 3-step wizard
**Files:** `widgets/universal_planner_sheet.dart`, `widgets/planner_submit_button.dart`, `planner_controller.dart`

- When, on step 1, the controller has a non-empty clean title AND a parsed (or prefilled) time, show a secondary button above/beside the main CTA: `ذخیره سریع ⚡` (outlined, theme gold — not a second gradient).
- Tapping it calls `controller.save(context)` immediately with current values + sensible defaults (default duration from category strategy if unset), skipping steps 2–3.
- The main CTA keeps the existing step-by-step behavior for users who want full control.
- Add a one-line hint under the input the first time the quick-save button appears (dismiss forever after first quick save; persist the flag in the existing prefs mechanism).

### Task 3 — Submit button: design-system compliance + states
**File:** `widgets/planner_submit_button.dart`

- Replace the hardcoded purple→green gradient with the app's standard CTA treatment from `ritmo_theme.dart` / `DESIGN_SYSTEM_PAGES.md` (gold/glass language). Remove emoji from labels; use icons (`Icons.arrow_back_rounded` for "ادامه" in RTL, `Icons.check_rounded` for save) placed correctly for RTL.
- Disabled state: on step 1 with an empty clean title, render at 40% opacity and ignore taps.
- Loading + double-tap guard: `save()` sets an `isSaving` flag on the controller; while true, show a small `CircularProgressIndicator` inside the button and ignore further taps. Reset on completion/failure.

### Task 4 — Fix the advanced-section expand animation
**File:** `widgets/planner_advanced_section.dart`

- Replace the `if (...) AnimatedContainer` pattern with `AnimatedSize` (or `AnimatedCrossFade`) so the body actually animates open/closed (250 ms, `Curves.easeOutCubic`). Rotate the chevron with an `AnimatedRotation`.
- Replace the priority `DropdownButtonFormField` + `⚠️` emoji items with a 3-segment chip row (`پایین` / `متوسط` / `بالا`), selected chip filled with theme accent, mapping to the same `0.5 / 1.0 / 1.5` values.

---

## P2 — Smarter defaults, less typing

### Task 5 — Category auto-suggestion from the parsed text
**Files:** `planner_controller.dart`, `widgets/planner_category_grid.dart` (+ the `QuickAddParser` if the keyword map belongs there)

- Add a keyword→category map (fa): e.g. «قرص، دارو» → medical; «نماز، قرآن، دعا» → worship; «باشگاه، دویدن، ورزش» → sports; «درس، مطالعه، کلاس» → study/courses; extend per existing category keys.
- When the debounced parse detects a category, pre-select it in the grid (visually highlighted with a small `پیشنهادی ✨` badge) — the user can still tap another category to override; a manual choice wins over subsequent auto-suggestions for this session of the sheet.
- **Redirect guard:** when the auto-suggested category is one that opens a dedicated sheet (medical/worship/courses/goals), do NOT auto-redirect. Keep the user in this flow; only redirect on an explicit tap, and when redirecting, pass the already-typed clean title into the target sheet's prefill (extend the opener callbacks' arguments only if they already accept prefill — otherwise stash it on the shared controller/registry the openers already read).

### Task 6 — Conflict-aware time picking
**Files:** `widgets/planner_timeline_picker.dart`, `planner_controller.dart`, read-only use of `JourneyController.computeFreeTime` / conflict detection

- Under the time wheels, add a miniature 24-h horizontal bar for the target date: occupied blocks in muted/dim fill, free gaps in a lighter theme tone, a marker at the currently picked time. Purely read-only, ~24 px tall, RTL-correct (00:00 at the right).
- If the picked time overlaps an existing station, show an inline warning row: `⚠️ تداخل با «{title}» ({time})` in the theme's warning color — non-blocking, saving stays allowed (the journey timeline already handles conflict layout).
- Above the bar, render up to 3 suggested-slot chips from `computeFreeTime` for that date, sized to fit `targetDuration` (e.g. `۱۶:۰۰ — ۱ ساعت آزاد`); tapping one sets the wheels. Reuse the suggestion logic — do not re-derive free time in the planner.

### Task 7 — Duration presets + AI estimate
**File:** `widgets/planner_duration_picker.dart`, `planner_controller.dart`

- Add a preset chip row under the existing stepper: `۱۵` `۳۰` `۴۵` `۶۰` `۹۰` `۱۲۰` دقیقه (Persian digits); tapping sets `targetDuration`, selected chip highlighted. Keep the ±15 stepper for fine-tuning.
- If `DurationEstimator` returns an estimate for the current title/category, show one extra chip: `⚡ پیشنهاد هوشمند: {n} دقیقه` — applied on tap, never auto-applied. Debounce/reuse the estimator the same way it is consumed elsewhere in the app; no new service calls per keystroke.

### Task 8 — Journey preview on every step + draft protection
**Files:** `widgets/universal_planner_sheet.dart`, `widgets/planner_journey_preview.dart`

- Move `PlannerJourneyPreview` out of step 3 into the sheet shell so it is visible (compact, collapsible) as soon as a time is known — it should live-update as the user changes time on step 2.
- Draft protection: if the sheet is dismissed (swipe-down / tap-outside / back) while `title` is non-empty and not saved, intercept with a small confirm (`ادامه ویرایش` / `دور انداختن`). Use `showModalBottomSheet`'s `isDismissible`/`WillPopScope`-equivalent wiring already available in the shell; do not block dismissal when the form is empty.

---

## P3 — Delight (only after P1–P2 are verified)

### Task 9 — "Frequent stations" quick-add row
**Files:** `widgets/universal_planner_sheet.dart` (+ a small query helper in `planner_controller.dart` reading the existing routines store)

- At the top of step 1 (below the natural input), show up to 3 chips of the user's most frequent recent stations, e.g. `🏋️ باشگاه ۱۷:۰۰` — derived from existing routines data (most-used title+category+time combos over the last 30 days). No new tables; compute in memory from what the repository already returns.
- Tapping a chip fills the whole form (title, category, time, duration) and lands the user on the quick-save state from Task 2. Hide the row while the user is typing (non-empty input) and in edit mode (`isEditing`).

### Task 10 — AI parse fallback for complex phrases
**Files:** `widgets/planner_natural_input.dart`, `planner_controller.dart`, reuse the existing AI plumbing from the ai-day-planner feature (prompts 017/018) — no new endpoints

- When the debounced regex parse finds no time AND the input is ≥ 5 words, show a subtle inline action under the field: `✨ تحلیل با هوش مصنوعی`.
- On tap, send the raw text through the existing AI planner service to extract {title, time, recurrence, duration, category}; apply results through the exact same chip pipeline as Task 1 (so every AI-extracted entity is individually removable).
- Show a small inline spinner during the call; on failure or empty result, show a quiet toast `چیزی پیدا نشد` and leave the form untouched. Never call the AI automatically — only on explicit tap.

---

## Acceptance checklist

- [ ] Typing «فردا ساعت ۸ برم باشگاه» then tapping the main CTA (never the arrow) yields a station titled «برم باشگاه» at tomorrow 08:00 — no date/time text in the title.
- [ ] Every parsed entity appears as a removable chip; removing one un-applies it and it does not reappear while the text is unchanged.
- [ ] Quick save from step 1 creates a valid station without visiting steps 2–3.
- [ ] Submit button uses theme CTA styling, disables on empty title, shows a spinner during save, and a rapid double-tap creates exactly one station.
- [ ] Advanced section visibly animates open/closed; priority is a chip row, no emoji.
- [ ] Time picker shows the day's occupancy bar, up to 3 free-slot chips, and a non-blocking conflict warning.
- [ ] Duration presets + optional AI-estimate chip work; ±15 stepper still works.
- [ ] Journey preview is visible from the moment a time exists and live-updates.
- [ ] Dismissing the sheet with a non-empty unsaved title asks for confirmation; empty sheet dismisses freely.
- [ ] Frequent-station chips fill the form in one tap and hide while typing / in edit mode.
- [ ] `flutter analyze` clean; all existing planner/category-sheet flows (medical, worship, courses, goals) still open correctly on explicit category tap.

After completion, write a short report to `prompts/021_REPORT.md` following the format of `020_REPORT.md`: what was done per task, files touched, anything skipped and why.
