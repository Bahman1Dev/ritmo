# 021: Add Station UX/UI Upgrade - Report

**Status**: Completed  
**Date**: 2026-07-22  

---

## Executed Improvements

### Priority 1: Core UX & Ergonomics
- **Live Debounced Parsing & Removable Chips**:
  - Implemented ~350ms debounced live parsing with `QuickAddParser` while typing in `PlannerNaturalInput`.
  - Added removable chips (`🕐 فردا ۸:۰۰`, `🔁 هر روز`, `⏱ ۳۰ دقیقه`) under the field with deletion (`✕`) support, adding removed items to `rejectedEntities` and recalculating clean titles using `QuickAddParser.cleanTitle`.
- **Quick Save Escape Hatch**:
  - Added an outlined gold `ذخیره سریع ⚡` CTA on Step 1 when a clean title and parsed/prefilled time are available.
  - Added a dismissible one-line educational hint under the text input persisted in `SharedPreferences`.
- **Submit Button Design-System Compliance**:
  - Removed hardcoded purple-to-green gradients from `PlannerSubmitButton`. Standardized with theme primary gold styling, loading spinner, and 40% opacity disabled state.
  - Standardized arrow/check icon orientation for RTL layout (`Icons.arrow_back_rounded` pointing left).
- **Advanced Section Accordion Animation**:
  - Replaced `AnimatedContainer` layout jumps with `AnimatedCrossFade` and smooth `AnimatedRotation` on the chevron icon.
  - Replaced dropdown with a 3-segmented priority chip row (`پایین`, `متوسط`, `بالا`).

### Priority 2: Intelligence & Guidance
- **Category Auto-Suggestion**:
  - Added keyword detection for natural input to pre-select matching categories with a `پیشنهاد ✨` badge on `PlannerCategoryGrid`.
- **Conflict-Aware Occupancy Bar**:
  - Integrated `DayAgendaService` and sleep settings to build a 24-hour horizontal occupancy custom painted bar (`TimeOccupancyPainter`) under the time wheels.
  - Rendered inline overlap warning `⚠️ تداخل با «...» (...)` when selected time overlaps existing stations.
  - Rendered up to 3 smart free-time suggestion chips (`۱۶:۰۰ — وقت آزاد`) for one-tap selection.
- **Duration Presets & AI Estimate**:
  - Added preset chips row (`۱۵`, `۳۰`, `۴۵`, `۶۰`, `۹۰`, `۱۲۰` دقیقه) under `PlannerDurationPicker`.
  - Integrated `DurationEstimator` to suggest intelligent activity durations (`⚡ پیشنهاد هوشمند: {n} دقیقه`).
- **Journey Preview & Draft Protection**:
  - Moved `PlannerJourneyPreview` out of step 3 into the sheet shell as a compact, collapsible preview row above the submit CTA.
  - Wrapped `UniversalPlannerSheet` in a `PopScope` to catch unsaved draft exits, prompting the user with a confirmation dialog (`ادامه ویرایش` / `دور انداختن`).

### Priority 3: Polish & Power Users
- **Frequent Stations Quick-Add**:
  - Rendered up to 3 quick-add chips for the user's most used title+category+time combinations from the last 30 days above the category grid.
- **AI Parse Fallback**:
  - Added `✨ تحلیل با هوش مصنوعی` inline action button when regex parser finds no time and input is ≥ 5 words, routing through `AIGateway.instance.parseQuickAdd`.

---

## Verification
- Run `flutter analyze lib/features/routines` clean pass.
