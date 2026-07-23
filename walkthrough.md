# Walkthrough: Deterministic Routine Engine & Wizard Redesign

We have successfully implemented and verified the Deterministic Routine Engine, 5-Step Routine Creation Wizard, and the database schema upgrade (v8). All verification tests have passed.

---

## Changes Made

### 1. Database Schema Migration (v8)
* **File:** [database_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/database_helper.dart)
* **Changes:**
  * Incremented database version to `8`.
  * Implemented `_migrateToV8` migration to add:
    * `routine_occurrences` table (Primary Key: `routine_id`, `date`) representing deterministic daily executions.
    * `recurrenceRule` (TEXT) column in the `routine_schedules` table to persist custom recurrence structures.
    * `snoozeUntil` (INTEGER) column in `pending_reminders` to store temporary snooze intervals.
  * Updated `_createDB` to establish version 8 tables for new database initializations.

### 2. Recurrence & Occurrence Engines
* **Files:**
  * [models.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/models.dart) (added `RecurrenceRule` class and helpers)
  * [routine_occurrence_generator.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/engines/routine_occurrence_generator.dart)
* **Changes:**
  * Added core recurrence matching supporting daily, specific weekdays, interval-based recurrence, monthly days, and custom weekday patterns with multi-week intervals (e.g. "every 2 weeks on Saturday and Monday").
  * **Persian Week Alignment:** Adjusted weekly interval calculations to align with Saturday (first day of the week in the Persian calendar) instead of ISO Monday.
  * Added deterministic generators to build next 30 days of future occurrences and backfill the past 30 days.

### 3. Scheduler & State Sync Updates
* **Files:**
  * [alarm_scheduler_service.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/alarm_scheduler_service.dart)
  * [snapshot_sync_service.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/snapshot_sync_service.dart)
  * [reshuffle_preview_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/widgets/reshuffle_preview_sheet.dart)
* **Changes:**
  * Configured `AlarmSchedulerService` to schedule alarms using the deterministic `routine_occurrences` table.
  * Integrated notification state tracking (`sent`, `opened`, `delayed`, `unknown` - removing `ignored`).
  * Implemented handlers for `Done` (updating occurrences), `Snooze` (setting `snoozeUntil`), and `Skip`.

### 4. Redesigned 5-Step Routine Creation Wizard
* **File:** [routine_create_flow.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/routine_create_flow.dart)
* **Changes:**
  * Built a PageView wizard with step-by-step user-controlled setup:
    1. **Category Selection:** Core categories with module activation flags.
    2. **Routine Definition:** Text details, Type selection, and Zone.
    3. **Schedule & Recurrence:** Daily, workdays, custom weekdays, advanced rules, and multi-reminder times setup.
    4. **Versions & Difficulty:** Priority slider, optional AI Defaults assistant card, and expandable manual parameters override (with a new toggle for `_isEssential`).
    5. **Preview & Confirm:** Clear Farsi summary of all configuration fields.

### 5. Routine Editing Safety Dialog
* **File:** [routine_form_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/routine_form_screen.dart)
* **Changes:**
  * Added a safety confirmation dialog when editing a routine. It prompts the user to apply changes to either "All occurrences" or "Only future occurrences," safely cleaning up and regenerating future database entries without affecting past history.

### 6. Dashboard UX Integration
* **File:** [now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart)
* **Changes:**
  * Swapped static list queries with `routine_occurrences` lookups.
  * Enabled Done, Snooze, and Skip actions directly from dashboard task tiles.

### 7. Bug Fixes & Compiler Resolution
* Fixed weekly recurrence multi-week intervals offset math inside `RoutineOccurrenceGenerator` to align to Saturday.
* Declared `_isEssential` and `_isEssentialLocked` state variables in `routine_create_flow.dart`.
* Added missing imports (`dart:convert`, `sqflite_sqlcipher`, `routine_occurrence_generator.dart`) in `routine_form_screen.dart` to solve compilation/static analysis errors.

---

## Verification Results

### 1. Static Analysis
Ran static analysis to check code health:
```bash
flutter analyze
```
> [!NOTE]
> All files compile correctly. There are 0 static analysis errors.

### 2. Automated Tests
Ran the full test suite including the new `recurrence_engine_test.dart` and `execution_kernel_test.dart`:
```bash
flutter test
```
> [!TIP]
> **All 94 tests passed successfully.**

---

## Ritmo Execution Kernel (REK) Integration

We have successfully designed, implemented, and fully verified the **Ritmo Execution Kernel (REK)** architecture to unify state mutation, transaction isolation, and platform channel scheduling.

### 1. Centralized Command Architecture
* **File:** [ritmo_execution_kernel.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/engines/ritmo_execution_kernel.dart)
* **Design:** Introduced a command-driven singleton orchestrator that processes all execution events under a structured state machine.
* **Commands Implemented:**
  * `CreateRoutineCommand`: Inserts routine data and schedules, deterministically generating occurrences.
  * `EditRoutineCommand`: Safely edits routine schedules and metadata, cancels matching active reminders, and regenerates future occurrences.
  * `DeleteRoutineCommand`: Marks routine as archived, cancels pending alarms, and purges future occurrences.
  * `CompleteOccurrenceCommand`: Logs completions, sets status to `done`, and flags today's reminders as `opened`.
  * `SkipOccurrenceCommand`: Logs skips, sets status to `skipped`, and cancels remaining alarms.
  * `SnoozeReminderCommand`: Snoozes alarms for $N$ minutes, increments `deferCount`, and schedules native alarms.
  * `ConfirmReshuffleCommand`: Batches shifts of scheduled times for multiple reminders.

### 2. Separation of Database Transactions & Platform Channels
* **Logic:** Platform channel calls (e.g., scheduling/canceling alarms via `NativeBridge`) are gathered inside transaction scopes as queued closures and executing them sequentially *only after* the database transaction commits successfully. This prevents database write locks and handles cross-thread timing delays gracefully.
* **Event Propagation:** Command execution automatically invalidates analytical engine caches by firing events on the `RitmoEventBus` and triggers `RitmoEvents.notifyRoutineChanged()` to refresh the UI.

### 3. Verification & Code Quality
* **Kernel Unit Tests:** Added [execution_kernel_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/execution_kernel_test.dart) covering database transactions, stream event emissions, and platform channels (using default binary messenger mock handlers).
* **Static Analysis:** Verified the entire workspace using
### ۴. رفع اشکال نمودار خلق‌وخوی چرخه (Cycle Mood Chart Bug Fixes)
- **جلوگیری از نمایش نقاط اوج نامعتبر:** در مواردی که نمودار کاملاً خط صاف است (مانند داده‌های دمو که برای روزهای ۱ تا ۷ همگی کلافه ثبت شده بودند)، نقطه اوجی نشان داده نمی‌شود تا کاربر گمراه نشود.
- **جلوگیری از هم‌پوشانی متون و خروج از صفحه:** محدوده قرارگیری برچسب‌های نقاط اوج (مانند «اوج بی‌حوصلگی/اضطراب») اصلاح شد تا از چپ با برچسب‌های محور Y تداخل نداشته و از بالا نیز از کادر نمودار خارج نشوند.
- **تصحیح نحوه محاسبه روز چرخه در صورت تاخیر:** نحوه محاسبه روز چرخه بهینه شد تا در صورت تاخیر در شروع چرخه جدید، روزها به اشتباه به اول بازه منتقل (Wrap) نشوند.

---

## نتیجه تحلیل استاتیک (Static Analysis Results)
- تمامی فایل‌های اصلاح‌شده با اجرای مجدد `flutter analyze` بررسی و بدون هرگونه خطا (Error) یا هشدار (Warning) با موفقیت ثبت شدند.
* **Test Suite:** The full automated test suite successfully compiles and runs, with all **98 tests passing cleanly**.

---

## Theme Null-Safety Fix (Unexpected null value)

We fixed a runtime crash occurring when navigating to `RoutineCreateFlow` overlay screen via the `+` button on the home dashboard or other lists.

### 1. Root Cause
* Using force-unwrapping on `Theme.of(context).extension<RitmoColors>()!` fails when widgets are built outside the main widget context tree (e.g. inside `PageRouteBuilder`, modal sheets, or overlays) if the theme extension is not correctly resolved.

### 2. Implementation & Global Refactoring
* **File:** [ritmo_theme.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/theme/ritmo_theme.dart)
  * Introduced `RitmoThemeExtension` on `BuildContext` to define `context.colors`. It safely returns the custom `RitmoColors` theme extension, falling back to static light or dark theme presets based on the current brightness mode if the extension is unresolved.
* **Global Refactor:**
  * Replaced all occurrences of `Theme.of(context).extension<RitmoColors>()!` with `context.colors` across **26 files** in the entire codebase, making color access completely null-safe and robust globally.
* **Import Path Clean-up:**
  * Fixed a relative import path for `ritmo_orb.dart` in `pulse_card.dart` to make sure there are **0 compilation errors** in static analysis.

### 3. Verification & Code Quality
* Updated the `SubsystemsList` instantiation in [now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart) to pass all required parameters (`medicationRoutinesCount` and the four tap callback functions: `onWorshipTap`, `onHealthTap`, `onProjectsTap`, and `onEducationTap`).
* Verified compilation with `flutter analyze` (**0 errors, 157 issues/warnings**).
* Verified that all unit and widget tests pass successfully (**99 tests passed cleanly**).

---

## Eager PageView Evaluation Null-Safety Fix (Unexpected null value in Step 5 Preview)

We fixed a runtime crash occurring immediately when opening the `RoutineCreateFlow` overlay screen.

### 1. Root Cause
* The `RoutineCreateFlow` wizard uses a `PageView` to transition between 5 creation steps.
* A `PageView` eagerly builds all widgets in its child list literal `children: [...]` upon initialization, including `_buildStep5PreviewConfirm()`.
* In `_buildStep5PreviewConfirm()`, the widget attempted to access `_selectedCategory!.name` to display the selected category icon and name.
* Since the user starts on Step 1, `_selectedCategory` is initially `null`, causing an `Unexpected null value` null check exception immediately on opening the flow.

### 2. Implementation
* **File:** [routine_create_flow.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/routine_create_flow.dart)
  * Modified the text rendering condition for the preview widget to safely check if `_selectedCategory` is null before accessing its name: `_selectedCategory?.name ?? ''`.
  * This guarantees that when the page list literal is eagerly evaluated during construction, no null check errors are thrown.

### 3. Verification & Code Quality
* Verified compilation with `flutter analyze` (**0 errors**).
* Verified that all unit and widget tests pass successfully (**99 tests passed cleanly**).

---

## Today Dashboard Redesign (Tasks R1 - R6)

We have successfully completed the premium redesign of the Today Dashboard screen, introducing a highly clean, glassmorphic, and visually premium layout in full alignment with the Persian calendar and design system tokens.

### 1. Task R1: Premium "Life Pulse" (نبض زندگی) Card Redesign
* **File:** [pulse_card.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/widgets/dashboard/pulse_card.dart)
* **Changes:**
  * Wrapped the animated `RitmoOrb` sphere in a glassmorphic container with a radial gradient energy glow (`#6B9EFF` -> `#9B89FF`).
  * Displayed the score in large 44sp typography with dynamic color-coding (success green for score >= 80, primary blue for < 80).
  * Implemented a custom 7-day bar chart showing progress, with today's bar highlighted (thicker and brighter) and Persian weekday labels (د، س، چ، پ، ج، ش، ی) underneath.
  * Added a dynamic trend chip (`+۱۲٪ ↑` or `-۵٪ ↓` comparison) without using red warning colors.
  * Integrated fallback checks to stop the animated breathing/heartbeat and render a clean, static, monogrammed glass sphere when Reduced Motion is enabled.

### 2. Task R2: "Today's Summary" (خلاصه امروز) Card
* **New File:** [today_summary_card.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/widgets/dashboard/today_summary_card.dart)
* **Changes:**
  * Introduced a new summary card directly below `PulseCard` showing task progress.
  * Built a premium circular progress indicator showing completed vs total tasks, with Persian fraction text (e.g. `۳/۵`) at its center.
  * Added a "Next Step" (قدم بعدی) block highlighting the title, time, and a "شروع" button that triggers the Niyyah/intent sheet.
  * Created a congratulatory completion state when all tasks are complete (green seal checkmark + "امروزت کامل شد").

### 3. Task R3: Horizontal "My Systems" (سیستم‌های من) Strip
* **New File:** [my_systems_strip.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/widgets/dashboard/my_systems_strip.dart)
* **Changes:**
  * Removed the redundant subsystems grid from the bottom of the dashboard.
  * Created a compact, horizontal scrollable row of active systems only (Worship, Health, Projects, Education) represented by glassmorphic chips with dynamic category icons and colors.
  * Positioned it as Section 3 (below QuickActionsBar, above Critical Alerts).

### 4. Task R4: Clean Up Header & Action Pills
* **Files:**
  * [now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart)
  * [quick_actions_bar.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/widgets/dashboard/quick_actions_bar.dart)
* **Changes:**
  * Redesigned the header to cleanly align the user avatar, welcome greeting, Persian calendar date, a bell icon (with quick snackbar feedback), and the assistant chat icon (conditional on assistant module status).
  * Remapped action bar pills to use clean, glassmorphic styles with uniform radius and design tokens.

### 5. Task R5: Global Dashboard UX Polish
* **Changes:**
  * Unified all vertical spacing between cards to exactly 16px.
  * Removed all deprecated `withOpacity` calls, replacing them with modern `withValues(alpha: ...)` structures.
  * Created a staggered entry transition (`_FadeInSlide` wrapper) that fades and slides up elements on dashboard load over 200ms, immediately bypassing transitions if Reduced Motion is enabled.

### 6. Task R6: Final Verification
* Ran full automated checks: `flutter analyze` and `flutter test`.
* **All 107 tests passed successfully with 0 compile errors.**

---

## 🐛 Web/DDC Runtime Type Casting Fix (`firstWhere` crash on dashboard load)

### 1. Root Cause
* During web deployment, the Dart Dev Compiler (DDC) checks function type signatures strictly at runtime.
* The timeline items are built inside `DashboardController` by mapping active tasks, which was inferring the mapped elements as `Map<String, Object>` rather than `Map<String, dynamic>`.
* In `now_dashboard_screen.dart`, `tasksList.firstWhere` was called with `orElse: () => <String, dynamic>{}`.
* Because the runtime type of the list elements was `Map<String, Object>`, the signature of `firstWhere` expected `orElse` to return a `Map<String, Object>`.
* In Dart, `Map<String, dynamic>` is not a subtype of `Map<String, Object>` (as `dynamic` is not a subtype of `Object`). This caused a runtime casting exception (`_generalNullableAsCheckImplementation` error in DDC).

### 2. Implementation
* **File:** [dashboard_controller.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/dashboard_controller.dart)
  * Explicitly typed the mapped timeline item literal as `<String, dynamic>{ ... }` to ensure elements are created with the correct runtime type.
* **File:** [now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart)
  * Replaced the `.firstWhere` query on `tasksList` with a standard manual lookup loop. This completely avoids generic function signature type-casting checks in DDC and is 100% robust.

### 3. Verification
* Verified compilation with `flutter analyze`.
* Verified that all unit, widget, and layout tests pass successfully (**107 tests passed cleanly**).

---

## 🎨 ۷. حذف سه نقطه صفحه اصلی و بازطراحی تخت منوی کاربری ( iOS style Flat list)

### ۱. حذف آیکون سه نقطه بالا سمت چپ صفحه اصلی
* **تغییرات:** دکمه تنظیمات سه نقطه (`...`) به طور کامل از بالای داشبورد در [now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart) حذف شد و کنترل کامل باز کردن منو به کلیک روی عکس آواتار کاربر اختصاص یافت.

### ۲. بازطراحی تخت منوی کاربری (Flat List Profile Sheet)
* **محل پیاده‌سازی:** فایل [profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart)
* **تغییرات ظاهری (iOS Flat List Style):**
  * کارت‌های شیشه‌ای و حاشیه‌دار گروه‌ها حذف شدند؛ آیتم‌ها اکنون مستقیماً و به صورت تخت روی پس‌زمینه شیت قرار گرفته‌اند.
  * کادرهای پیش‌زمینه و رنگ‌های اختصاصی آیکون‌ها برداشته شده و تمامی آیکون‌ها به صورت خطی ساده (Outline) و تک‌رنگ (Monochrome) نقره‌ای/خاکستری نمایش داده می‌شوند.
  * جداکننده‌ها (Row Dividers) بین آیتم‌های منو برای ایجاد ظاهری مینیمال‌تر و خلوت‌تر حذف شدند.
  * عنوان هر بخش (بخش حساب، بخش برنامه و...) با فونت بولد و رنگ آبی پررنگ/روشن (`colors.primary`) بدون باکس حاشیه قرار داده شد.
  * دکمه خروج از حساب کاربری به صورت یک دایره قرمز رنگ توپر حاوی آیکون فلش سفید رو به راست (CupterinoIcons.arrow_right) در کنار نوشته قرمز رنگ طراحی گردید.
  * متد کمکی غیرکاربردی `_buildIOSMenuRow` از کلاس استیت حذف شد.

### ۳. اعتبارسنجی نهایی
* اجرای تحلیل ایستای پروژه (`flutter analyze`) تایید کرد که **هیچ خطای کامپایل یا هشدار ایستایی مربوط به کدهای جدید وجود ندارد**.
* تمامی **۱۰۷ تست خودکار با موفقیت پاس شدند**.

---

## 🔧 تغییرات فنی و پیاده‌سازی

### ۱. یکپارچه‌سازی UX یادآورها (Mustahab Section)
- در **فرم مستحب سفارشی**، انتخاب‌های مکرر روزانه/هفتگی حذف شدند و با یک دکمه‌ی اختصاصی **«افزودن یادآور»** جایگزین شدند.
- با کلیک روی این دکمه، همان فرم جامع یادآور (`WorshipReminderSettingsSheet`) باز می‌شود.
- وضعیت یادآور تنظیم شده (مثلاً: «یادآوری فعال است (تناوب: DAILY)») به‌صورت **Real-time** در پایین فرم نمایش داده می‌شود تا کاربر پیش از ثبت نهایی مستحب از تنظیمات خود مطلع باشد.

### ۲. اصلاح بخش قرآن و اذکار (Quran & Dhikr Section)
- آیکون چرخ‌دنده (⚙️) از **کارت قرائت قرآن** حذف و به **هدر بخش «قرآن و اذکار»** منتقل شد تا دسترسی منطقی‌تری داشته باشد.
- با کلیک روی این آیکون، ابتدا تنظیمات **هدف روزانه (تعداد صفحه)** قرار دارد و بلافاصله پس از آن، دکمه **«افزودن یادآور»** برای هدایت به تنظیمات جامع یادآور تعبیه شده است.

### ۳. مدیریت هوشمندِ State
- در افزودن مستحب و تنظیم قرآن، از کلاس واسط `WorshipPractice` (به‌صورت `_tempPractice`) برای ذخیره موقت وضعیت یادآور در لایه UI استفاده شد. به محض تأیید توسط کاربر، کلیه جزئیات یادآور (شامل زمان‌بندی، تناوب، و روزهای هفته) مستقیماً به همراه خودِ آیتم عبادی در دیتابیس `worship_practices` ذخیره (Insert/Update) می‌شود.

---

## ✅ نتیجه‌گیری
اکنون **تمام بخش‌های عبادات (مستحبات پیش‌فرض، سفارشی، و قرائت قرآن)** از یک فرم متمرکز استفاده می‌کنند. این تغییر ضمن **کاهش کدهای تکراری**، تجربه‌ی کاربری بسیار تمیز، منظم، و یکپارچه‌ای (UX) برای زمان‌بندی برنامه‌های مذهبی رقم زده است. 
- **تغییر تم تاریک کارت‌های عبادت:** تم پس‌زمینه و حاشیه‌ی کارت‌های اصلی بخش عبادت (شامل کارت نمازهای واجب، کارت مستحبات، کارت قرائت قرآن و کارت اذکار) در حالت تاریک از آبی-تیره به مشکی-زرد (پس‌زمینه مشکی خالص ذغالی با حاشیه‌ی بسیار ظریف طلایی با شفافیت ۱۵ درصد) تغییر داده شد تا پالت بصری بسیار منسجم‌تر و هماهنگ‌تری با زنگوله‌ها و دکمه‌های زرد ایجاد گردد.

کامل سیستم عبادات (Worship Features - Tasks W1 - W12)

سیستم عبادت اپلیکیشن ریتمو به صورت کامل با طراحی بسیار پرمیوم و در انطباق صد درصدی با قوانین سخت‌گیرانه فارسی/راست‌چین و پالت‌های رنگی بهینه‌شده بازطراحی و پیاده‌سازی گردید.

### ۱. مهاجرت پایگاه‌داده به نسخه ۱۲ (Task W1)
* ایجاد جدول جدید `worship_practices` و ثبت تنظیمات اولیه در کلاس [DatabaseHelper](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/database_helper.dart).

### ۲. پیاده‌سازی مدل‌های داده راست‌چین (Task W2)
* ایجاد کلاس‌های مدل منطبق در [worship_models.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/models/worship_models.dart).
* تبدیل‌کننده سراسری ارقام انگلیسی به فارسی (`toPersianDigits`).

### ۳. کارت هیرو و اوقات شرعی (Task W3)
* ساخت ابزارک [PrayerTimesHero](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/prayer_times_hero.dart).
* اوقات ۶ گانه، شمارش معکوس پویا (هایلایت کردن اختلاف زیر ۱۵ دقیقه و اعلام زنده وقت اذان).
* نمایش تاریخ‌های سه‌گانه (شمسی، میلادی، قمری با دریافت مستقیم آنلاین از API).

### ۴. بخش نمازهای واجب و منطق تعویق (Task W5)
- **حذف آمار شمارشی:** عبارت «امروز: ۰ از ۳» از هدر بخش نمازهای واجب حذف گردید.
- **تغییر آیکون تنظیم یادآور:** آیکون‌های زنگوله انفرادی از هر سطر نماز واجب برداشته شده و به صورت یک آیکون تنظیم عمومی در هدر «نمازهای واجب» سمت چپ قرار گرفت.
- **تنظیمات یکپارچه:** با کلیک روی این زنگوله عمومی، پنل جدید `_AllPrayersReminderSettingsSheet` باز می‌شود که امکان فعال‌سازی و تنظیم زمان اعلام یادآور (آفست پیش/پس از اذان) برای هر ۳ نماز واجب را به صورت یکجا فراهم می‌کند.
- **تغییر تم تاریک پنجره‌های عبادت:** تم پس‌زمینه و حاشیه کلیه‌ی باتم‌شیت‌ها و دیالوگ‌های بخش عبادت در حالت تاریک از آبی-مشکی به مشکی-زرد (پس‌زمینه مشکی خالص ذغالی با حاشیه‌ی نیمه‌شفاف طلایی) تغییر داده شد تا ظاهر لوکس‌تر و هماهنگ‌تری با پالت زرد ایجاد شود.


* ساخت ابزارک [ObligatoryPrayersSection](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/obligatory_prayers_section.dart).
* گروه بندی نمازها به ۳ سطر مجزا.
* محدودیت تعویق حداکثر ۳ بار، هماهنگ با `deferCount` و ذخیره در `pending_reminders`.
* ادغام هوشمند با سیستم عادت ماهانه بانوان جهت غیرفعال‌سازی محترمانه عبادات واجب روزانه.

### ۵. بخش مستحبات و شخصی‌سازی (Task W6)
* ایجاد ابزارک [MustahabSection](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/mustahab_section.dart) با قابلیت ثبت مستحبات دلخواه روزانه/هفتگی.

### ۶. بخش قرآن و ذکر شمار (Task W7)
* ساخت ابزارک [QuranDhikrSection](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/quran_dhikr_section.dart).
* تعیین هدف روزانه قرائت صفحات همراه با رسم نمودار میله‌ای هفتگی.
* ذکرهای روزانه با صفر شدن هوشمند در نیمه شب.

### ۷. بدهی‌های عبادی و پیش‌بینی پویا (Task W8)
* پیاده‌سازی [WorshipDebtsSection](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/worship_debts_section.dart) جهت مدیریت نمازها و روزه‌های قضا.
* پیش‌بینی هوشمند تاریخ پایان بدهی‌ها بر اساس میانگین و نرخ تکرار روزانه.
* ثبت خودکار بدهی‌ها در پایان روز با تایید کاربر.

### ۸. مناسبت‌های عبادی و دستیار هوشمند محلی (Task W9, W11)
* مدیریت مناسبت‌ها در [WorshipSeasonsSection](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/worship_seasons_section.dart).
* دستیار هوشمند صوتی/متنی [AIWorshipAssistantSheet](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart) جهت ارائه برنامه‌های خوانش قرآن و جبران قضای نماز بدون ورود به مسائل فقهی/فتوا.

### ۹. اعتبارسنجی و تست‌های خودکار (Task W12)
* رفع کامل هشدارهای کامپایلر در تمام صفحات جدید.
* نوشتن تست‌های جدید در [worship_feature_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/worship_feature_test.dart) و پاس شدن تمامی **۱۳۴ تست خودکار** بدون کوچک‌ترین مشکل یا تداخل.

---

## 🌙 پیاده‌سازی و بازطراحی سیستم چرخه بدن (Cycle Harmony - Tasks V1 - V10)

سیستم چرخه بدن ریتمو به صورت کامل، با امنیت بسیار بالا و با حفظ حریم خصوصی کامل طراحی، پیاده‌سازی و اعتبارسنجی شد.

### ۱. ارتقاء پایگاه‌داده به نسخه ۱۴ (Task V1)
* ایجاد جداول مجزای `cycle_periods` (برای دوره‌ها) و `cycle_day_logs` (برای علائم روزانه).
* تعریف تنظیمات و مقادیر اولیه مربوط به رضایت‌های سه‌گانه و پارامترهای پیش‌فرض چرخه.

### ۲. امنیت و حریم خصوصی مطلق (Task V2, V3)
* **پنهان‌سازی کامل از مردان:** پیاده‌سازی کلاس کمکی `CyclePrivacyGuard` جهت اعتبارسنجی و پنهان‌سازی کامل هرگونه سرنخ، کارت داشبورد، یا کاشی در سیستم هاب برای کاربران غیرزن.
* **قفل امنیتی پیش از دسترسی:** ایجاد ابزارک `CycleLockGate` برای احراز هویت با اثر انگشت/تشخیص چهره (`local_auth`) یا رمز عبور ۴ رقمی پشتیبان، پیش از بارگذاری یا اجرای هرگونه پرس‌وجو روی داده‌های چرخه.

### ۳. موتور محلی آفلاین چرخه (Task V4)
* ایجاد موتور هوشمند `CycleEngine` در [cycle_engine.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/engines/cycle_engine.dart) برای محاسبه فازهای ۴ گانه چرخه (پریود، فولیکولار، تخمک‌گذاری، لوتئال)، زمان تخمک‌گذاری، دوره باروری و شاخص‌های آماری به شکل کاملاً آفلاین و ایمن.

### ۴. فرآیند ورود و رضایت‌نامه (Task V5)
* ساخت ویزارد چند مرحله‌ای ورود کاربر شامل تعیین طول دوره، متوسط طول پریود، و فعال‌سازی اختیاری رضایت‌های متقابل.

### ۵. ثبت علائم روزانه و تاریخچه دوره‌ها (Task V6)
* ایجاد بخش تعاملی ثبت شدت خونریزی، خُلق‌وخو، علائم جسمی، سطح انرژی و یادداشت اختصاصی روزانه همراه با نمایش و حذف تاریخچه دوره‌ها.

### ۶. تقویم ماهیانه جلالی و هشدار بی‌نظمی (Task V7)
* ساخت تقویم ماهیانه شمسی راست‌چین با بازنمایی گرافیکی و رنگی فازهای چرخه و پیش‌بینی‌ها.
* پیاده‌سازی الگوریتم پویای شناسایی بی‌نظمی‌های چرخه (بر اساس نوسانات انحراف معیار طول دوره‌ها) و نمایش پیام‌های ارشادی غیرمستقیم.

### ۷. پل رضایت و یکپارچگی عبادات و عادات (Task V8)
* پیاده‌سازی [CycleConsentBridge](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/utils/cycle_consent_bridge.dart) جهت بررسی رضایت‌های کاربر.
* ادغام هوشمند با منطق عبادات (`isUserMenstruating`) برای مدیریت معافیت از نماز و روزه تنها در صورت موافقت کاربر با اتصال داده‌ها، و تنظیم پویای شدت عادات ورزشی.

### ۸. هشدارهای خصوصی و پیش‌نمایش توصیه‌های هوشمند (Task V9, V10)
* ایجاد اعلان‌های غیرمستقیم و خنثی در سیستم اندروید/آی‌او‌اس جهت پیشگیری از نشت اطلاعات به دیگران.
* ایجاد جریان دریافت و پیش‌نمایش توصیه‌های خودمراقبتی هوشمند با امکان اصلاح دستی متن توصیه‌ها پیش از ذخیره‌سازی قطعی.

### ۹. بازخورد و اصلاحات تکمیلی
* ایمپورت کلاس `CycleScreen` در کلاس [now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart) جهت رفع خطای استاتیک آنالیزور.
* به‌روزرسانی بانک اطلاعاتی موقت تست عبادات (`MockWorshipDatabase`) در [worship_feature_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/worship_feature_test.dart) به همراه اصلاح سناریوی تست شماره ۵ مطابق با آخرین ساختار جدول `cycle_periods` و نیاز به تنظیم کلید رضایت عبادی.
* رفع خطای کامپایل مربوط به متغیر تعریف‌نشده `settingsMap` در کلاس [alarm_scheduler_service.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/alarm_scheduler_service.dart) با واکشی و پرکردن مناسب آن از پایگاه‌داده.
* رفع خطای کامپایل مربوط به متغیر تعریف‌نشده `nowMs` در متد ثبت علائم روزانه در کلاس [cycle_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/cycle_screen.dart).
* رفع خطای کامپایل مربوط به نامشخص بودن کلاس کمکی `ConflictAlgorithm` در کلاس [cycle_lock_gate.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/widgets/cycle_lock_gate.dart) با اضافه کردن ایمپورت پکیج sqflite.
* پاس شدن موفقیت‌آمیز هر **۱۶۱ تست خودکار** پروژه بدون کوچک‌ترین رگرسیون.

---

## 🌙 بهبودهای ارتقاء تجربه کاربری چرخه بدن (Tasks V11 - V15)

در پاسخ به بازخورد کاربر، تغییرات و بهبودهای ظاهری و عملکردی زیر بر روی بخش «چرخه بدن» اعمال گردید:

### ۱. بازطراحی و راهنمای تقویم جلالی (Task V11)
* به پایین کارت تقویم ماهیانه، یک راهنمای تقویم دقیق (Legend) با فونت وزیرمتن و آیکون‌های متناسب اضافه شد.
* روز جاری (امروز) به صورت مجزا با یک کادر برجسته و مشخص متمایز گردید.

### ۲. کلید وضعیت قاعدگی همزمان با وضعیت پایگاه‌داده (Task V12)
* منطق فعال/غیرفعال بودن دکمه ثبت شروع/پایان قاعدگی به صورت پویا با وضعیت واقعی دیتابیس هماهنگ شد.

### ۳. توصیه‌های خودمراقبتی هوشمند تفکیک‌شده (Task V13)
* بخش توصیه‌های خودمراقبتی به یک چیدمان سه ستونی پرمیوم تقسیم شد: ورزش و حرکت، تغذیه و مایعات، ذهن و آرامش.
* امکان ثبت مستقیم توصیه‌ها با یک لمس دکمه در یادداشت امروز فراهم گردید.

### ۴. فرم شیک و بخش‌بندی‌شده ثبت علائم روزانه (Task V14)
* فرم ثبت علائم روزانه از حالت دیالوگ ساده به یک Bottom Sheet بسیار پرمیوم و دسته‌بندی‌شده ارتقاء یافت.

### ۵. تنظیمات پارامترهای پایه با به‌روزرسانی آنی (Task V15)
* امکان ویرایش «متوسط طول چرخه» و «متوسط طول دوره قاعدگی» در هر زمان فراهم شد.

---

## ⚡ پیاده‌سازی و بازطراحی سیستم «انرژی و حال روحی» (Energy & Mood - Tasks E1 - E11)

سیستم جدید «انرژی و حال روحی» مطابق با بالاترین استانداردهای رابط کاربری، قلم فارسی، رعایت اصول حریم خصوصی و به صورت کاملاً امن و آفلاین طراحی و پیاده‌سازی گردید.

### ۱. مهاجرت پایگاه‌داده به نسخه ۱۷ (Task E1)
* ارتقای پایگاه‌داده به نسخه ۱۷ با افزودن جدول جدید `mood_logs` برای ثبت احساسات.

### ۲. ساخت مدل‌های داده (Task E2)
* ایجاد کلاس‌های مدل نگاشت `MoodLog` ، `EnergyLog` و `QuickLogResult` در [energy_mood_models.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/energy/models/energy_mood_models.dart).

### ۳. موتور تحلیل احوال و الگوریتم همبستگی Pearson (Task E3)
* پیاده‌سازی موتور پردازش آفلاین `MoodEngine` جهت تحلیل احوال روزانه و محاسبه ضریب همبستگی Pearson.

### ۴. شیت ثبت سریع «الان چطورم؟» (Task E4)
* فرم شیک و مدرن شیشه‌ای برای ثبت در لحظه سطح انرژی و حال روحی.

### ۵. بخش هیرو و پالس انرژی پویا (Task E5)
* نمایش درصد پویای فعلی انرژی کاربر با فرم اورب پالس‌کننده به رنگ صورتی `#EC4899`.

### ۶. بخش «امروز» و نمودار نوسان درون‌روزی (Task E6)
* رسم منحنی نوسان پیوسته انرژی کاربر در طول ۲۴ ساعت روز جاری با استفاده از `CustomPainter`.

### ۷. بخش «الگوها» و تحلیل اوج کارایی (Task E7)
* استخراج و نمایش بازه پرانرژی روز (Peak Window) و پربارترین روز هفته.

### ۸. بخش «روند» و نمودار میله‌ای مقایسه‌ای (Task E8)
* مقایسه ۴ هفته اخیر انرژی و خوشایی کاربر با نمودارهای استوانه‌ای ستونی.

### ۹. مونتاژ نهایی و اتصال به هاب سیستم‌ها (Task E9)
* طراحی صفحه اصلی [energy_mood_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/energy/presentation/energy_mood_screen.dart).

### ۱۰. دستیار صوتی/متنی هوش مصنوعی محلی (Task E10)
* شیت چت با هوش مصنوعی محلی کاربر با تزریق پرونده زیستی.

### ۱۱. تضمین امنیت و رعایت قید محرمانگی چرخه (Task E11)
* تعدیل سطح انرژی فیزیکی به طور غیرمستقیم و خنثی با استفاده از متد کمکی `CycleConsentBridge.isEnergyTuned()` بدون اشاره مستقیم به قاعدگی برای کاربران مرد یا زمان خاموش بودن رضایت.

---

## Cycle Harmony Module Upgrade (v2)

We have successfully completed the **Cycle Harmony (v2)** upgrade, introducing personalized trends, symptom correlations, a Fiqh Qada Fasting Debt ledger, and strict privacy/fertility shielding constraints.

### 1. Worship Consent Verification in Fiqh Ledger
* **File:** [database_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/database_helper.dart)
* **Changes:** Added a strict query inside `addFastingDebtIfNeeded` to verify `cycle_consent_worship` is set to `'true'` in `app_settings` before inserting records.

### 2. Relative Import & Compilation Clean-ups
* Fixed wrong relative imports pointing to `../../logic/cycle_correlation.dart` and replaced `Colors.white80` with `Colors.white70` to fix compilation.

### 3. Database Migration Tests (v18 -> v19 -> v20)
* Added test cases for migrating from database version 18 to 19 and 19 to 20.

### 4. Expanded Cycle Unit Test Suite
* **File:** [cycle_engine_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/cycle_engine_test.dart)
* **Changes:** Added tests for CycleEngine Upgrades, Symptom & Metric Correlations, CycleConsentBridge Gates, and Fiqh Fasting Debt Ledger.

### 5. Daily Reflection Sheet Import Path Fix
* Fixed relative import path for `reflection_models.dart`.

---

## Cycle Harmony Repairs & Prediction Engine Simplification

We have successfully resolved all three issues within the Cycle Harmony module and simplified the prediction logic to deliver an honest, estimation-focused model. All 213 unit/widget tests are passing successfully.

### 1. Simplified & Honest Prediction Engine
* **File:** [cycle_engine.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/engines/cycle_engine.dart)
* **Changes:**
  * Simplified prediction math: Short delays (< 14 days late) project expected start date to the current cycle (`startDate + L`), while long delays (>= 14 days) project to the future cycle (`startDate + ((daysSinceStart / L).floor() + 1) * L`).
  * Removed arbitrary confidence percentage scores.
  * Replaced with a qualitative regularity label based on range dispersion (maximum cycle length - minimum cycle length):
    * If range <= 4 days: `"نسبتاً منظم"` (relatively regular)
    * If range > 4 days: `"نامنظم"` (irregular)
    * If recorded periods < 2: `"دادهٔ ناکافی"` (insufficient data)
  * Implemented min-to-max cycle prediction window (`nextPeriodWindowStart` to `nextPeriodWindowEnd`).
  * Added a medical/biological estimation disclaimer.

### 2. UI Repairs & Bug Resolutions
* **Files:**
  * [cycle_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/cycle_screen.dart)
  * [cycle_trends_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/widgets/cycle_trends_section.dart)
* **Changes:**
  * **Bug 1: Forgotten Period UI Gate**:
    * Identified stale/open periods (>= 12 days old) in `_loadData()` and flagged them as `_forgottenPeriod`.
    * Rendered a clean warning banner card at the top of the dashboard for manual resolution ("Close with average length" or "Edit dates").
    * Updated the quick action button to ignore forgotten periods. If the active period is stale, the button remains active as "ثبت شروع قاعدگی" (Record start of period), letting the user record a new period without database clutter.
  * **Bug 2: Edit Period Sheet & Persian Date Picker**:
    * Added pencil edit buttons next to delete buttons in the history list.
    * Implemented `_EditPeriodSheet` with a Persian date picker, date range validation, and toggle support for period end.
  * **Bug 3: Fiqh Qada Ledger Sync**:
    * Save operations on edited periods query existing fasting debt records to preserve `isResolved` status and update the ledger correctly. Open periods delete their corresponding debt to avoid orphan records.
    * Delete operations in `_deletePeriod()` perform clean purges on both `cycle_periods` and `fasting_debt`.
  * **Date Normalization**:
    * Normalized date comparisons in calendar highlight helpers using `DateTime(year, month, day)` to bypass DST/timezone offset issues.
  * **Trends Badge**:
    * Replaced the circular regularity percentage score widget in `cycle_trends_section.dart` with a text badge displaying `widget.engineOutput.regularityLabel`.

### 3. Verification & Testing
* **File:** [cycle_engine_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/cycle_engine_test.dart)
* **Changes:**
  * Added three new tests validating the prediction projection for late cycles, low-data fallback checks, and regularity label calculations.
* **Test Suite:**
  * Executed `flutter test` showing **all 213 tests passed successfully**.

---

## 💊 Medication Page Trends & Analysis Loading Fix

We resolved an issue where the "Trends & Analysis" tab on the Medication page was stuck in a loading state.

### 1. Root Cause
* The `energy_logs` table has a `loggedAt` column but **no `createdAt` column** in its database schema.
* Three queries in the health module were using `orderBy: 'createdAt DESC'` on the `energy_logs` table, causing SQLite to throw a `"no such column: createdAt"` exception.
* The exception prevented `_engineOutput` from initializing (remaining `null`), which left the trends UI page perpetually waiting/spinning on loading.

### 2. Implementation
* **Files Modified:**
  * [health_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/health/presentation/health_screen.dart#L176)
  * [ai_health_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart#L114)
  * [doctor_visit_summary_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/health/presentation/widgets/doctor_visit_summary_sheet.dart#L62)
* **Changes:**
  * Swapped the query ordering on `energy_logs` to use the correct schema field: `orderBy: 'loggedAt DESC'`.

### 3. Verification & Testing
* All 213 unit/widget tests successfully compile and pass, ensuring a solid build.

---

## 🛠️ Profile screen syntax corruption & compilation fix

We fixed a compiler syntax crash and restored the correct structure of the profile management sheet.

### 1. Root Cause
* An inline replacement corrupted the boundary between the `_showPremiumUpgradeSheet()` method and the `_buildSwitchOption(...)` widget function, leaving dangling brackets, stray lines, and duplicate widget declarations.

### 2. Implementation
* **File:** [profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart)
  * Restored the complete and correct closing blocks of `_showPremiumUpgradeSheet()`.
  * Restored the missing `_buildPremiumFeature` helper method.
  * Properly closed the children list and method body of `_showModulesManagementSheet()`, deleting the duplicate module switch options that were causing build warnings and syntax mismatches.

### 3. Verification & Testing
* Verified compilation with `flutter analyze` (**0 errors**).
* Verified that all unit and widget tests pass successfully (**all 213 tests passed cleanly**).

---

## 🐛 Routine Form Screen firstWhere Exception Fix

We resolved a runtime crash occurring on the Routine Edit form screen.

### 1. Root Cause
* When opening the Routine Edit screen for a routine, `_loadRoutineData` performed `firstWhere` lookups on enums (`Category`, `EnergyRule`, `DependencyType`) based on database values.
* If any of these values were stored as null, empty, or differently in older database configurations, `firstWhere` threw a `StateError: No element` exception, causing a blank screen/crash on load.

### 2. Implementation
* **File:** [routine_form_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/routine_form_screen.dart)
  * Added `orElse` fallback parameters to all three `firstWhere` lookup calls:
    * `Category.values.firstWhere(..., orElse: () => Category.personal)`
    * `EnergyRule.values.firstWhere(..., orElse: () => EnergyRule.none)`
    * `DependencyType.values.firstWhere(..., orElse: () => DependencyType.afterCompletion)`
  * This guarantees complete null-safety and backwards compatibility for all legacy routine records.

### 3. Verification & Testing
* Verified compilation with `flutter analyze` (**0 errors**).
* Verified that all unit and widget tests pass successfully (**all 213 tests passed cleanly**).

---

## 🔒 App Lock Session Timeout & Focus Loss Fix

We resolved an issue where clicking outside the app window (causing window focus loss/blur) would immediately lock the app, and re-entering the passcode would reset the navigation stack back to the main/home page.

### 1. Root Cause
* The application lifecycle observer in `AppLockGate` was immediately setting `_isLocked = true` when receiving `AppLifecycleState.paused` (which is dispatched by Flutter Web/Desktop as soon as the window loses focus).
* Because it locked immediately, any quick task switch or focus loss locked the app. Rebuilding the layout to display the lock screen on top of the navigation stack could cause the window or focus state to change, and on some platforms, resetting focus when resuming would rebuild the app root.

### 2. Implementation
* **File:** [app_lock_gate.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/security/app_lock_gate.dart)
  * Added a `_pausedAt` timestamp state variable to record exactly when the app was sent to the background/paused.
  * Replaced the immediate lock behavior in `didChangeAppLifecycleState` with a robust session timeout check:
    * When paused, we store the current time in `_pausedAt`.
    * When resumed, we compare the elapsed time against `app_lock_timeout_seconds` from settings (defaulting to 300 seconds / 5 minutes).
    * If the elapsed time exceeds the timeout, the app locks.
    * If the elapsed time is less than the timeout, the app remains completely unlocked, preserving the user's exact navigation stack (like registering a routine or settings screen) and form fields intact.
  * Added dynamic settings loading on both pause and resume so that any passcode settings changes made in the profile screen are applied immediately without requiring an app restart.

### 3. Verification & Testing
* Verified the code compiles successfully with 0 errors via `dart.exe analyze` (**all checks passed**).
* Ran the entire test suite via `flutter test` verifying that **all 213 unit/widget tests pass cleanly** with no regression.

---

## 🤖 AI Assistant Timeout Increase & Typewriter Typing Effect

We resolved the `TimeoutException` occurring after 12 seconds in the AI assistants by increasing the default timeout and implementing a premium typewriter-style typing animation for AI responses.

### 1. Root Cause
* The timeout for AI network requests was hardcoded to `12` seconds, causing requests to fail with a `TimeoutException` on slow or high-latency network connections.
* The response text was loaded and displayed in the UI instantly, which lacked the premium interactive feel of modern conversational AI assistants.

### 2. Implementation
* **AIGateway Timeout Increase:**
  * Updated [ai_gateway.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/ai_gateway.dart) to increase the default timeout to **45 seconds** (`defaultTimeoutMs = 45000`).
  * Updated [courses_ai_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/courses/logic/courses_ai_helper.dart) and [konkur_ai_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/konkur/logic/konkur_ai_helper.dart) to increase their HTTP timeout to **45 seconds**.
  * Updated all regional AI sheets ([ai_energy_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/energy/presentation/widgets/ai_energy_assistant_sheet.dart), [ai_sleep_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/sleep/presentation/widgets/ai_sleep_assistant_sheet.dart), [ai_worship_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart), and [ai_health_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart)) to use **45 seconds** timeouts for their direct API connection post requests.
* **Typewriter Typing Effect:**
  * Implemented a smooth typewriter rendering loop in the main [assistant_chat_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/assistant/presentation/assistant_chat_screen.dart) and all four regional assistant sheets.
  * When a response is received, a timer gradually appends characters (3 characters every 15ms) to the chat bubble, providing a live typing effect while auto-scrolling to the bottom to match modern AI chat expectations.

### 3. Verification & Testing
* Verified the workspace compiles successfully with 0 errors via `flutter analyze`.
* Executed the entire test suite confirming that **all 213 unit/widget tests pass cleanly**.

---

## 📅 امکان افزودن دوره‌های قبلی قاعدگی و جلوگیری از تداخل (Adding Past Period Cycles)

در پاسخ به درخواست کاربر، امکان ثبت مستقیم دوره‌های قبلی در بخش «تاریخچه دوره‌های قبلی» با رابط کاربری اختصاصی، منطق پایگاه‌داده بهینه‌شده و فرآیند اعتبارسنجی دقیق تاریخ‌ها به برنامه اضافه شد.

### ۱. دکمه جدید ثبت دوره قبلی در تاریخچه
* **فایل:** [cycle_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/cycle_screen.dart)
* **تغییرات:** یک دکمه تعاملی تخت با عنوان فارسی «افزودن دوره قبلی» (`TextButton.icon` حاوی آیکون `CupertinoIcons.plus` به رنگ صورتی دکوراتیو `#F28A80`) در بالای بخش لیست تاریخچه دوره‌ها افزوده شد.

### ۲. تعمیم و بازطراحی شیت به فرم دو کاره (ویرایش / افزودن)
* **تغییرات:** شیت ویرایش سابق (`_EditPeriodSheet`) به یک فرم دو منظوره بسیار منعطف با نام `_AddEditPeriodSheet` تبدیل شد:
  * در حالت افزودن، عنوان شیت به «افزودن دوره قاعدگی جدید» و دکمه ذخیره به «افزودن دوره» تغییر می‌یابد و تاریخ اولیه روی امروز تنظیم می‌گردد.
  * در حالت ویرایش، اطلاعات دوره انتخابی بارگذاری شده و تغییرات آن بروزرسانی می‌شود.

### ۳. الگوریتم تشخیص و جلوگیری از تداخل دوره‌ها (Overlap Validation)
* **منطق فیلترینگ:** متدهای کمکی `rangesOverlap` و `_validatePeriodDates` به عنوان گیت‌های اعتبارسنجی اضافه شدند تا از ثبت چندین دوره در بازه‌های زمانی همپوشان جلوگیری کنند:
  * تداخل تاریخ پایان هر دو دوره فعال/تکمیل‌شده بررسی می‌شود.
  * از ثبت تاریخ‌های شروع و پایان در آینده جلوگیری می‌گردد.
  * در صورت بروز هرگونه تداخل، پیام مناسبی نظیر «تداخل با دوره ثبت شده دیگر (شروع از تاریخ X)» با فونت وزیرمتن و در کادر هشداری قرمز شیشه ای نمایش می‌یابد.

### ۴. همگام‌سازی فقهی خودکار بدهی‌های عبادی (Fasting Debt Sync)
* **تغییرات:** منطق تراکنش‌های دیتابیس در متد `_savePeriod` ادغام شد:
  * برای دوره‌های تکمیل‌شده جدید، در صورت وجود رضایت عبادی (`cycle_consent_worship == 'true'`) بدهی روزه قضا معادل روزهای دوره محاسبه شده و در جدول `fasting_debt` به صورت کاملاً امن با شناسه منحصربفرد درج می‌شود.
  * در صورت تغییر بازه زمانی یا حذف دوره، بدهی‌های معادل نیز بلافاصله بروزرسانی یا به صورت فیزیکی پاک می‌شوند.

### ۵. اعتبارسنجی نهایی
* بررسی و تحلیل ساختاری بدون هیچ خطای کامپایلر انجام شد.
* با اجرای `flutter test` تمامی **۲۱۳ تست خودکار** بدون خطا با موفقیت پاس شدند.

---

## 🌙 بهبودها و اصلاحات بخش عبادت و چرخه بدن (Worship & Cycle Harmony Improvements - Tasks 1-11)

ما مجموعه ۱۱ مورد بهبود و رفع اشکال در بخش‌های «عبادت» و «چرخه بدن» اپلیکیشن ریتمو را با رعایت کامل راست‌چین بودن، قلم فارسی و استانداردهای طراحی سیستم اعمال نمودیم.

### ۱. ارتقای پایگاه‌داده به نسخه ۲۴ و مقداردهی اولیه شهرها (Task 1)
* **فایل:** [database_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/database_helper.dart)
* **تغییرات:**
  * نسخه پایگاه‌داده به `24` ارتقا یافت.
  * ستون جدید `allowQada` به جدول `worship_practices` اضافه شد.
  * تعداد ۳۹ شهرستان/بخش ایران همراه با مشخصات موقعیت جغرافیایی و مختصات به صورت مستقیم (با استفاده از `db.insert` به جای `db.batch` جهت تضمین سازگاری با سیستم Mock دیتابیس در تست‌های واحد) در جدول `iran_cities` درج شدند.

### ۲. رفع باگ عدم بروزرسانی و بازخوانی تب عبادت (Task 2)
* **فایل:** [worship_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/worship_screen.dart)
* **تغییرات:** شناسه بازسازی صفحه (`_rebuildKey`) حذف شد و به جای آن متدهای بازخوانی داده در لایه `didUpdateWidget` تمامی زیربخش‌های صفحه عبادت پیاده‌سازی شدند تا با تغییر اطلاعات یا تغییر زبانه، داده‌ها به صورت آنی و بدون لرزش تصویر بروزرسانی شوند.

### ۳. اصلاح بازه زمانی و برچسب‌های تنظیم یادآور نمازهای واجب (Task 3)
* **فایل:** [obligatory_prayers_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/obligatory_prayers_section.dart)
* **تغییرات:** محدوده اسلایدر تنظیم یادآور نمازهای واجب به بازه `[-60, 60]` تغییر یافت که در آن مقادیر منفی نشان‌دهنده دقایق پس از اذان و مقادیر مثبت نشان‌دهنده دقایق پیش از اذان هستند. همچنین برچسب‌ها با ارقام فارسی اصلاح شدند.

### ۴. بهبود رابط کاربری تنظیم یادآور مستحبات (Task 4)
* **فایل:** [mustahab_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/mustahab_section.dart)
* **تغییرات:** قابلیت انتخاب زمان یادآوری برای مستحبات با استفاده از Bottom Sheet اختصاصی انتخاب زمان (`CupertinoTimerPicker`) پیاده‌سازی شد.

### ۵. ادغام بخش‌های ذکر روزانه و حضرت زهرا (س) (Task 5)
* **فایل:** [quran_dhikr_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/quran_dhikr_section.dart)
* **تغییرات:** ذکرهای روزانه و تسبیحات حضرت زهرا (س) در یک کارت شیک ادغام شدند؛ کاربر می‌تواند از طریق یک منوی کشویی نوع ذکر را انتخاب کند یا با استفاده از دیالوگ اختصاصی، یک ذکر و تعداد هدف جدید ثبت نماید.

### ۶. یکپارچه‌سازی و اتصال بدهی‌های روزه چرخه بدن به عبادت (Task 6)
* **فایل‌ها:**
  * [cycle_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/cycle_screen.dart)
  * [cycle_consent_bridge.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/utils/cycle_consent_bridge.dart)
  * [worship_debts_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/worship_debts_section.dart)
* **تغییرات:** کلید فعال‌سازی رضایت با عنوان «ارسال بدهی‌ها به بخش عبادت» در شیت بدهی روزه چرخه بدن قرار گرفت. در صورت فعال بودن این رضایت، بدهی‌های روزه به بخش عبادت انتقال می‌یابند. تعداد روزهای تداخل دوره قاعدگی با ماه رمضان به صورت خودکار محاسبه شده و با پیشوند `debt_cycle_fast_` در جدول بدهی‌های عبادی همگام‌سازی دوطرفه می‌شوند.

### ۷. افزودن خودکار روزه ماه رمضان به عبادات واجب (Task 7)
* **فایل:** [obligatory_prayers_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/obligatory_prayers_section.dart)
* **تغییرات:** در صورت قرارگیری در بازه مناسبت ماه رمضان، آیتم «روزه ماه رمضان» به عنوان یک عمل واجب پویا در بالای بخش نمازهای واجب درج می‌شود. عدم انجام آن باعث ثبت بدهی روزه قضا از نوع `FAST` در جدول بدهی‌ها می‌گردد.

### ۸. قابلیت ثبت قضا برای مستحبات شخصی و دکمه رد کردن (Task 8)
* **فایل‌ها:**
  * [worship_models.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/models/worship_models.dart)
  * [mustahab_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/mustahab_section.dart)
* **تغییرات:**
  * فیلد `allowQada` به مدل داده مستحبات اضافه شد.
  * گزینه «ثبت قضا در صورت عدم انجام» در شیت ایجاد مستحب جدید قرار گرفت.
  * دکمه رد کردن (`CupertinoIcons.clear_circled`) برای مستحبات فعال شد که در صورت فعال بودن گزینه فوق، پنجره تایید اضافه کردن به بدهی‌های قضا را نمایش می‌دهد.

### ۹. بهبود تنظیمات بخش قرآن (Task 9)
* **فایل:** [quran_dhikr_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/quran_dhikr_section.dart)
* **تغییرات:** سوئیچ فعال‌سازی بخش قرآن و دکمه تنظیم صفحه هدف روزانه با امکان بازخوانی و بروزرسانی آنی وضعیت صفحه فعلی و هدف اضافه شد.

### ۱۰ و ۱۱. اصلاح و بومی‌سازی شیت مناسبت‌های عبادی (Tasks 10 & 11)
* **فایل:** [worship_seasons_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/widgets/worship_seasons_sheet.dart)
* **تغییرات:**
  * نمایش تاریخ مناسبت‌ها با استفاده از تابع کمکی جدید `_formatDateToJalali` به تقویم هجری شمسی بومی‌سازی شد و تمامی ارقام به فارسی تبدیل شدند.
  * دکمه چشم برای فعال/غیرفعال‌سازی نمایش مناسبت‌ها در صفحه اصلی اصلاح شد و وضعیت آن با دیتابیس هماهنگ گردید.

### ۱۲. راه‌اندازی و اعتبارسنجی تست‌ها (Task 12)
* اجرای تحلیل ایستای کل پروژه بدون هیچگونه خطا (`0 errors`).
* اجرای موفق تمامی ۲۱۳ تست واحد و ابزارک بدون کوچک‌ترین شکست یا اثر جانبی منفی روی رفتارهای پیشین برنامه.


---

## 📅 اصلاح مشکلات چرخه بدن (رفع داده‌های ناکافی، تقویم و انتقال جنسیت)

ما تمامی موارد گزارش شده در بخش چرخه بدن (شامل داده‌های ناکافی برای پیش‌بینی و ریتم، خطای به روز نشدن تقویم و ناهماهنگی در تعیین جنسیت در پروفایل کاربری) را برطرف کرده و عملکرد آن را یکپارچه نمودیم.

### ۱. یکپارچه‌سازی و رفع تداخل مسیرهای منوی تنظیمات کاربری
* **ریشه یابی:** دکمه منوی پروفایل برای چرخه بدن به اشتباه صفحه قدیمی و منسوخ شده `CycleHarmonyScreen` را باز می‌کرد که داده‌ها را در جدول مجزای `cycle_logs` ثبت می‌نمود. در حالی که داشبورد و صفحه جدید چرخه (`CycleScreen`) داده‌ها را از جدول `cycle_periods` می‌خواندند. این موضوع باعث عدم همگام‌سازی و بروز خطای "دادهٔ ناکافی" در هر دو بخش و عدم تغییر روزهای هایلایت تقویم می‌گردید.
* **پیاده‌سازی:** مسیر منوی "چرخه بدن و هماهنگی" در [profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart) اصلاح شد تا مستقیماً به صفحه جدید و مدرن `CycleScreen` ارجاع دهد.

### ۲. مهاجرت و انتقال خودکار اطلاعات از جدول قدیمی
* **پیاده‌سازی:** در متد بارگذاری اطلاعات [cycle_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/cycle_screen.dart)، یک منطق مهاجرت خودکار داده اضافه شد:
  * در صورتی که دیتابیس `cycle_periods` خالی باشد ولی در جدول قدیمی `cycle_logs` رکوردهایی وجود داشته باشند، رکوردهای قدیمی به صورت دسته‌ای (Batch transaction) به جدول جدید کپی می‌شوند.
  * تنظیمات قدیمی طول چرخه (`cycle_length_days` و `period_duration_days`) نیز به صورت خودکار به تنظیمات جدید (`cycle_avg_length` و `cycle_avg_period`) منتقل می‌گردند.
  * این فرآیند باعث انتقال یکپارچه سوابق ثبت شده قبلی کاربر و برطرف شدن خطای داده‌های ناکافی و هماهنگی آنی تقویم می‌شود.

### ۳. هماهنگی خودکار ماژول چرخه با تغییر جنسیت در پروفایل
* **ریشه یابی:** در صورتی که در آنبوردینگ اولیه جنسیت کاربر مشخص نشده بود و بعداً در پروفایل روی زن ("FEMALE") تنظیم می‌شد، فعال‌ساز ماژول چرخه همچنان غیرفعال باقی می‌ماند و این ناهماهنگی باعث بروز رفتار نامطلوب و عدم بارگذاری بخش چرخه می‌شد.
* **پیاده‌سازی:** در فرم ذخیره ویرایش پروفایل [profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart)، در صورت تعیین جنسیت زن، تنظیم `'module_cycle_enabled'` به طور خودکار برابر `'true'` قرار می‌گیرد (و برای سایر جنسیت‌ها `'false'`) و مجدداً اعلان‌ها و هشدارهای پس‌زمینه بروزرسانی می‌شوند.

### ۴. اعتبارسنجی و تست‌های خودکار
* کدهای تغییر یافته فاقد هرگونه هشدار یا خطای کامپایلی در تحلیل ایستای Flutter هستند.
* با اجرای دستور `flutter test` تمامی **۲۱۳ تست خودکار** پروژه با موفقیت کامل پاس شدند.

---

## 🌙 ارتقاء تکمیلی شهرستان‌ها، یادآور مستحبات و تب چرخه بدن (Iranian Counties, Mustahab Reminders & Cycle Qada Tab Improvements)

ما سه بهبود جدید در سیستم‌های «عبادت» و «چرخه بدن» اعمال و آزمایش کردیم:

### ۱. مقداردهی کامل تمامی ۳۶۲ شهرستان ایران
* **فایل:** [database_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/database_helper.dart)
* **تغییرات:**
  * ارتقای پایگاه‌داده به نسخه ۲۵.
  * استخراج فهرست کامل ۳۶۲ شهرستان و مرکز استان ایران به همراه مشخصات طول و عرض جغرافیایی دقیق و درج ایمن و یک‌به‌یک (بدون استفاده از `db.batch()` جهت حفظ سازگاری با سیستم Mock در تست‌های واحد) در زمان نصب اول و مهاجرت.

### ۲. ارتقای شیت یادآوری مستحبات (اضافه شدن بازه تکرار و تیک قضا)
* **فایل‌ها:**
  * [worship_models.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/models/worship_models.dart)
  * [mustahab_section.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/mustahab_section.dart)
* **تغییرات:**
  * اضافه شدن فیلد `reminderFrequency` (روزانه، هفتگی، ماهانه) به مدل داده و جدول `worship_practices`.
  * بازطراحی شیت ویرایش یادآور مستحبات شامل: دکمه سوئیچ روشن/خاموش یادآور، نوار دکمه‌ای مدرن سه‌حالته تکرار (روزانه، هفتگی، ماهانه)، ساعت اعلام یادآوری و سوئیچ ثبت قضا در صورت عدم انجام (`allowQada`).

### ۳. شرط نمایش تب روزه قضا در چرخه بدن
* **فایل:** [cycle_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/cycle_screen.dart)
* **تغییرات:** نمایش تب «روزه قضا» در نوار زبانه چرخه بدن منوط به فعال بودن کلی سیستم عبادت (`module_religion_enabled == 'true'`) در تنظیمات پروفایل کاربری شد.

---

## 🎨 بازطراحی بصری صفحه سیستم‌ها (Systems Hub Redesign)

صفحه سیستم‌ها (Systems Hub) به صورت کامل بر اساس طرح پیشنهادی تصویب‌شده، بازطراحی و پیاده‌سازی گردید. هدف این بازطراحی ارتقای زیبایی بصری به سطح پرمیوم، بهبود خوانایی با دسته‌بندی موضوعی و پیاده‌سازی افکت‌های نوری مدرن بود.

### ۱. دسته‌بندی موضوعی سیستم‌ها (Categorized Layout)
* **فایل:** [systems_hub_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/systems_hub_screen.dart)
* **تغییرات:** ماژول‌ها و سیستم‌های مختلف از حالت گرید یکنواخت به چهار دسته‌بندی موضوعی مجزا و تفکیک‌شده با نشانگرهای صورتی رنگ عمودی در کنار عنوان هر بخش تقسیم شدند:
  * **سلامت و بیولوژی:** شامل «چرخه بدن»، «دارو»، «خواب و بیداری» و «انرژی و حالت روحی».
  * **رشد و برنامه‌ریزی:** شامل «دوره‌های آموزشی»، «کنکور» و «اهداف و برنامه‌ها».
  * **توازن و معنویت:** شامل «عبادت» و «خودارزیابی و بازتاب».
  * **بستر هوشمند:** شامل «دستیار هوشمند».

### ۲. کارت‌های شیشه‌ای با درخشش ملایم نئونی (Neon Glow Glass Cards)
* پس‌زمینه کارت‌ها با استفاده از استایل شیشه‌ای `RitmoTheme.glassCardLight` پیاده‌سازی شد.
* برای هر کارت، یک درخشش ملایم اختصاصی (`boxShadow` با شعاع بلور ۲۰ و پخش‌شدگی ۱) متناسب با رنگ اصلی آیکون آن ماژول (صورتی برای چرخه بدن و انرژی، قرمز برای دارو، بنفش برای خواب و کنکور، طلایی برای عبادت، فیروزه‌ای برای دستیار هوشمند و خودارزیابی) اعمال گردید تا حس مدرن و پرمیوم بودن را به کاربر منتقل کند.

### ۳. نشانگرهای وضعیت مدرن (Status Badges)
نشانگرهای وضعیت هر سیستم (فعال، غیرفعال، راه‌اندازی و قفل‌شده) با رنگ‌های هماهنگ و پس‌زمینه شیشه‌ای نیمه‌شفاف بازطراحی شدند تا وضعیت جاری هر ماژول به صورت سریع و زیبا به کاربر نشان داده شود.

---

## 💬 حل مشکل خطای ارتباط دستیار صوتی و تنظیمات هوش مصنوعی (AI Settings UI)

به دلیل مسدود بودن و فیلترینگ دامنه‌های مستقیم Cloudflare (مانند `api.cloudflare.com`) در شبکه داخل کشور، فراخوانی مستقیم دستیار هوشمند با خطای ارتباطی (Unexpected EOF) مواجه می‌شد. برای حل ریشه‌ای این مشکل به صورت عمومی و دائمی، یک بخش پیکربندی اختصاصی برای هوش مصنوعی به برنامه اضافه گردید.

### ۱. افزودن شیت تنظیمات هوش مصنوعی (AI Settings Sheet)
* **فایل:** [profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart)
* **تغییرات:** 
  * یک ردیف جدید با عنوان «تنظیمات هوش مصنوعی (AI)» و آیکون درخشان صورتی رنگ در بخش تنظیمات برنامه (بخش برنامه) در پروفایل کاربری اضافه شد.
  * با کلیک روی آن، شیت شیشه‌ای و زیبای `_showAiSettingsSheet` باز می‌شود که فیلدهای «آدرس سرویس‌دهنده (Base URL)»، «کلید API» و «نام مدل» را به صورت مستقیم از جدول `app_settings` پایگاه‌داده خوانده و امکان ویرایش یا ذخیره آن‌ها را به کاربر می‌دهد.

### ۲. دکمه میان‌بر و سازگاری با OpenRouter (بدون فیلترینگ)
* در شیت تنظیمات هوش مصنوعی دکمه میان‌بر «تنظیم OpenRouter 🚀» اضافه گردید که با یک لمس، آدرس بیس را روی سرویس‌دهنده معتبر و بدون فیلتر `https://openrouter.ai/api/v1/chat/completions` و مدل رایگان و پرسرعت `google/gemma-2-9b-it:free` تنظیم می‌کند. کاربر با دریافت کلید API رایگان از سایت OpenRouter می‌تواند به آسانی از تمام امکانات هوش مصنوعی برنامه بدون نیاز به پروکسی بهره‌مند شود.
* همچنین دکمه «بازنشانی پیش‌فرض 🔄» برای حذف فیلدهای سفارشی و بازگشت به مقادیر اولیه ریتمو تعبیه شده است.

### ۳. یکپارچگی سراسری با تمامی دستیارهای اختصاصی
* با ذخیره مقادیر در پایگاه‌داده، تمام ماژول‌های فرعی هوش مصنوعی اعم از دستیار چرخه بدن ([ai_cycle_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart))، دستیار خواب، انرژی، سلامت و عبادت به صورت پویا از تنظیمات شخصی‌سازی شده کاربر استفاده خواهند کرد.

---

## 🎯 یکپارچه‌سازی پنجره نیت انجام، بازطراحی تعویق و اصلاحات تست‌ها

بر اساس بازخورد و نیازهای جدید، بخش تعامل با روتین‌ها و رفتار کلیک روی آن‌ها یکپارچه گردید و پنجره‌های تکراری اقدامات حذف شدند. همچنین سیستم تعویق (اسنوز) بازطراحی شده و مشکلات مربوط به تست‌های واحد برطرف شدند:

### ۱. یکپارچه‌سازی شیت «نیت انجام» و حذف «اقدامات روتین»
* **فایل‌ها:**
  * [routines_list_screen.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/routines_list_screen.dart)
  * [calendar_screen.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/calendar_screen.dart)
  * [now_dashboard_screen.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart)
* **تغییرات:**
  * پنجره قدیمی «اقدامات روتین» به طور کامل از صفحه لیست روتین‌ها حذف شد.
  * با کلیک روی هر روتین در لیست روتین‌ها، شیت مدرن و زیبای **«نیت انجام»** (Niyyah Sheet) باز می‌شود (دقیقاً مشابه رفتار بخش تقویم و داشبورد).

### ۲. شخصی‌سازی و نمایش شرطی نسخه‌های روتین (Tiers)
* **تغییرات:**
  * در شیت «نیت انجام»، ردیف دکمه‌های نسخه‌های سه‌گانه (کامل، سبک، حداقلی) به صورت هوشمند و شرطی بررسی می‌شوند.
  * اگر یک روتین فاقد مقادیر نسخه سبک و حداقلی باشد (`lightDurationMinutes == null || lightDurationMinutes == 0`)، بخش انتخاب نسخه به طور کامل پنهان شده و کارت‌های خالی نمایش داده نمی‌شوند.
  * در صورت وجود نسخه‌ها، تنها گزینه‌های معتبر (غیر صفر) نمایش داده می‌شوند.

### ۳. بازطراحی کامل و پریمیوم شیت تعویق روتین (Routine Snooze)
* **فایل‌ها:**
  * [routine_snooze_bottom_sheet.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/widgets/routine_snooze_bottom_sheet.dart)
* **تغییرات:**
  * شیت جدید `RoutineSnoozeBottomSheet` با طراحی شیشه‌ای (Glassmorphism) فوق‌العاده شیک و نوار کشیدنی بالایی پیاده‌سازی شد.
  * دکمه تعویق سادهٔ ۱۵ دقیقه‌ای قبلی حذف گردید و با زدن تعویق، شیت جدید باز می‌شود که گزینه‌های انتخابی انعطاف‌پذیر (۵، ۱۰، ۱۵ و ۳۰ دقیقه) را به همراه آیکون‌های متناسب و نمایش اعداد به فارسی ارائه می‌دهد.
  * پس از انتخاب مدت زمان، یادآوری روتین مستقیماً از طریق `AlarmSchedulerService` به تعویق می‌افتد و پیام اطلاع‌رسانی زیبا (SnackBar) نمایش داده می‌شود.

### ۴. افزودن دکمه «مشاهده جزئیات»
* **تغییرات:**
  * دکمه «مشاهده جزئیات» به انتهای شیت نیت انجام در تمامی صفحات (تقویم، لیست روتین‌ها و داشبورد امروز) اضافه شد.
  * با کلیک روی آن، پنجره جزئیات روتین باز می‌شود که آمار کل انجام‌ها، زنجیره تداوم فعلی (Streak) و تاریخچه ۳ انجام آخر را به همراه جزئیات نوع انجام نمایش می‌دهد.

### ۵. حل باگ تست‌های واحد و بازگرداندن موفقیت ۱۰۰٪ تست‌ها
* **فایل‌ها:**
  * [alarm_scheduler_test.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/alarm_scheduler_test.dart)
  * [execution_kernel_test.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/execution_kernel_test.dart)
* **علت بروز مشکل:** با فراخوانی متدهای ثبت وقوع روتین‌ها و تغییرات تقویم، موتور تولید وقوع روتین متد `db.batch()` را فراخوانی می‌کرد. در محیط تست‌های واحد، دیتابیس‌های Mock به دلیل نداشتن متد `batch` با خطای خطیر نوع داده مواجه می‌شدند (`type 'Null' is not a subtype of type 'Batch'`).
* **تغییرات:**
  * کلاس‌های `AlarmSchedulerMockBatch` و `MockBatch` را برای شبیه‌سازی تراکنش‌های گروهی و ثبت دسته‌ای پیاده‌سازی کردیم.
  * متد `batch()` را در تمام پیاده‌سازی‌های Mock پایگاه داده و Mock تراکنش بازنویسی کردیم.
  * با اجرای دستور `flutter test`، تمامی **۲۱۹ تست** برنامه با موفقیت و وضعیت کاملاً سبز پاس شدند.

---

## 🐛 رفع مشکل هنگ کردن تایمر تمرکز پویا در هنگام کلیک روی دکمه اتمام روتین (Deadlock Fix)

### ۱. علت بروز مشکل
* در زمان اتمام روتین (دکمه سبز تایید) در کلاس `ActiveTimerOverlay` و یا تعلیق آن، متدهای `completeOccurrence` و `skipOccurrence` در کلاس `AlarmSchedulerService` فراخوانی می‌شدند.
* هر دوی این متدها کل منطق خود را در قالب یک بلاک تراکنشی دیتابیس `db.transaction((txn) async { ... })` اجرا می‌کردند.
* در انتهای این بلاک تراکنش، متد `CentralInboxService.markActionedForEntity` فراخوانی می‌شد. اما این متد به جای استفاده از شیء تراکنش فعلی (`txn`)، مجدداً شیء دیتابیس اصلی را فراخوانی می‌کرد (`DatabaseHelper.instance.database`) و بر روی آن دستور به‌روزرسانی (`update`) اجرا می‌کرد.
* از آنجا که تراکنش دیتابیس فعلی هنوز باز بود و قفل انحصاری داشت، فراخوانی به‌روزرسانی روی دیتابیس اصلی منتظر اتمام تراکنش می‌ماند و تراکنش هم منتظر اتمام متد به‌روزرسانی می‌ماند. این قفل متقابل (Deadlock) باعث فریز و هنگ کامل کل دیتابیس و به تبع آن کل واسط کاربری (UI) برنامه می‌شد.

### ۲. تغییرات اعمال شده
* **فایل:** [central_inbox_service.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/central_inbox_service.dart)
  * متدهای `push` و `markActionedForEntity` به‌روزرسانی شدند تا یک پارامتر اختیاری `DatabaseExecutor? executor` دریافت کنند. در صورت پاس داده شدن این پارامتر، عملیات دیتابیس مستقیماً روی تراکنش (`executor`) انجام می‌شود؛ در غیر این صورت به سراغ نمونه پیش‌فرض دیتابیس می‌رود.
* **فایل:** [alarm_scheduler_service.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/alarm_scheduler_service.dart)
  * در متدهای `completeOccurrence` و `skipOccurrence`، مقدار تراکنش فعلی (`txn`) به فراخوانی `CentralInboxService.markActionedForEntity` به عنوان `executor: txn` پاس داده شد تا عملیات در بستر تراکنش جاری انجام شود و تداخلی ایجاد نگردد.

---

## 🎨 بازطراحی رفتار کلیک بر روی روتین‌های انجام‌شده و افزودن قابلیت لغو انجام (Undo)

### ۱. رفتار جدید کلیک بر روی کارهای تیک‌خورده (انجام‌شده)
* قبلاً با کلیک بر روی هر روتینی (حتی اگر انجام شده و تیک‌خورده بود)، مجدداً شیت «نیت انجام» باز می‌شد که از نظر تجربه کاربری نامناسب بود.
* اکنون با کلیک بر روی روتین‌های انجام‌شده در داشبورد امروز و صفحه تقویم، مستقیماً **شیت جزئیات و آمار روتین** (`RoutineDetailsSheet`) نمایش داده می‌شود. این کار باعث می‌شود کاربر آمار پیشرفت، زنجیره تداوم (Streak) و تاریخچه روتین خود را مشاهده کند و حس بازخورد مثبت دریافت نماید.

### ۲. اضافه شدن دکمه «لغو ثبت انجام» (Undo Completion)
* متد جدید `undoCompletion` به کلاس `AlarmSchedulerService` اضافه گردید. این متد سوابق تکمیل را از جدول `routine_completions` حذف کرده، وضعیت وقوع امروز روتین را در `routine_occurrences` مجدداً به `pending` تغییر می‌دهد و یادآوری‌های مربوطه را به حالت فعال (`unknown`) بازمی‌گرداند.
* در شیت جزئیات روتین، در صورتی که روتین در تاریخ انتخابی/امروز انجام شده باشد، دکمه شیک و متناسب «لغو ثبت انجام این روتین» اضافه شده است.
* با کلیک روی آن، یک دیالوگ تأیید فارسی با رنگ‌بندی هشدار ظاهر شده و در صورت تایید کاربر، ثبت انجام لغو، داده‌های صفحه بلافاصله به‌روزرسانی شده و آلارم‌های غیرفعال‌شده به صورت خودکار مجدداً در سیستم محلی برنامه‌ریزی می‌شوند.

### ۳. فارسی‌سازی تاریخ‌ها و زمان‌ها در صفحه جزئیات روتین (Persian/Shamsi Format)
* **تغییرات:** تاریخ‌های میلادی خام (مانند `2026-06-28`) در بخش «آخرین انجام‌ها»ی شیت جزئیات روتین با وارد کردن پکیج `shamsi_date` به قالب تقویم خورشیدی تبدیل شدند (مانند `۱۴۰۵/۰۴/۰۷`).
* همچنین روزهای هفته معادل آن در تقویم فارسی (مانند `یکشنبه`) محاسبه و به ابتدای رشته تاریخ اضافه گردید تا به صورت `یکشنبه ۱۴۰۵/۰۴/۰۷` نمایش داده شود. زمان‌ها نیز با استفاده از کلاس `PersianDigits` به ارقام فارسی تبدیل شدند.

---

## 🛠️ رفع خطای کامپایل مربوط به تایپ کلاس خروجی تحلیل هوش مصنوعی (AI Quality Gate Compilation Fix)

### ۱. علت بروز مشکل
* در فایل تحلیل کیفی دروازه هوش مصنوعی ([ai_quality_gate.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/engines/helpers/ai_quality_gate.dart))، در تعریف پارامتر متد `filterDigest` به اشتباه از نام تایپ `BehaviorSnapshot` استفاده شده بود.
* از آنجا که نام کلاس اصلی در مدل‌های رفتار به صورت `BehavioralSnapshot` (با پسوند al) تعریف شده است، این عدم تطابق باعث بروز خطای کامپایل `Type 'BehaviorSnapshot' not found` و عدم اجرای موفق برنامه می‌گردید.

### ۲. تغییرات اعمال شده
* امضای متد `filterDigest` در فایل `ai_quality_gate.dart` اصلاح شده و نام تایپ از `BehaviorSnapshot` به `BehavioralSnapshot` تغییر یافت تا با تعریف اصلی کلاس همخوانی کامل داشته باشد.

---

## 🎨 اصلاح و بهبود تم روشن در بخش‌های مختلف برنامه (Light Theme Fixes & Optimizations)

### ۱. تعریف دقیق طرح رنگ (ColorScheme) در تنظیمات تم
* برای هماهنگی رنگ المان‌های بومی اندروید/آی‌اواس و ویجت‌های استاندارد Material 3 (مانند Cupertino/Material Switch، Dialogها، CalendarPicker و دکمه‌ها)، مشخصه `colorScheme` به هر دو متد `lightTheme` و `darkTheme` در [ritmo_theme.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/theme/ritmo_theme.dart) افزوده شد تا از تداخل رنگ‌های پیش‌فرض فلاتر (مانند بنفش پیش‌فرض) با رنگ‌های اختصاصی ریتمو جلوگیری شود.

### ۲. اصلاح متون سفید سخت‌کد شده در داشبورد امروز (Now Dashboard)
* هدر عنوان بخش‌های «گام‌های امروز اهداف»، «📚 مطالعه امروز» و «📚 مطالعه امروز (کنکور)» به همراه عنوان دیالوگ تحلیل هوشمند که دارای رنگ سفید سخت‌کد شده (`Colors.white`) بودند، در [now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart) با `colors.textPrimary` جایگزین شدند تا در تم روشن کاملاً خوانا و مشکی‌رنگ دیده شوند.

### ۳. اصلاح رنگ متون در بخش تحلیل‌های هوشمند (AI Insights)
* متون کمکی لودینگ تحلیل عمیق، جداکننده‌ها و بدنه نتایج تحلیل که در کارت‌های شیشه‌ای نمایش داده می‌شدند، در [insights_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/insights_screen.dart) پویا و به `colors.textPrimary` و `colors.textSecondary` متصل شدند تا تداخل کنتراست در تم روشن رفع شود.

### ۴. خواناسازی مراحل راه‌اندازی چرخه بدن (Cycle Setup Flow)
* در [cycle_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/cycle_screen.dart)، استپ‌های ثبت طول چرخه، خونریزی و اتصالات رضایت که به علت بک‌گراند صورتی/سفید تم روشن ناپدید شده بودند، بازنویسی شدند تا به جای رنگ سفید سخت‌کد شده از `colors.textPrimary` و `colors.textSecondary` استفاده کنند.

---

## 🛠️ حل تداخل نسخه‌ای Gradle 9.1، Built-in Kotlin و ارتقای پلاگین‌ها (Gradle 9.1 & Plugin Upgrade Fix)

### ۱. اصلاح و ارتقای نسخه‌های پلاگین در `pubspec.yaml`
* **تغییرات:** پلاگین‌های درگیر پروژه به آخرین نسخه سازگار با ساختار Kotlin اندروید ارتقا یافتند:
  * `share_plus: ^13.2.0`
  * `device_info_plus: ^13.2.0`
  * `package_info_plus: ^10.2.0`
  * `file_picker: ^12.0.0-beta.7` (نسخه بتا جهت هماهنگی با `win32` 6.x)
* **رفع تداخل Win32:** برای حل تداخل نسخه‌ای Win32 بین پلاگین‌های `share_plus` و `file_picker` و رفع خطاهای کامپایل FFI در سیستم‌های ویندوزی، بخش `dependency_overrides` در فایل [pubspec.yaml](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/pubspec.yaml) اضافه شد:
  ```yaml
  dependency_overrides:
    win32: ^6.3.0
    flutter_secure_storage_windows: ^4.2.2
  ```

### ۲. تنظیمات فایل‌های Gradle و غیرفعال‌سازی موقت Built-in Kotlin
* در [settings.gradle.kts](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/android/settings.gradle.kts)، نسخه `com.android.application` به مقدار پیش‌فرض `9.0.1` تغییر یافت.
* در [gradle.properties](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/android/gradle.properties)، مقدار `android.builtInKotlin=false` تنظیم شد تا موقتاً تداخل کامپایل کاتلین در پلاگین‌های قدیمی برطرف گردد.
* در [build.gradle.kts](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/android/app/build.gradle.kts)، مقدار `compileSdk = 36` بازگردانده شد.

### ۳. ایجاد اسکریپت سراسری دور زدن تحریم‌های مخازن گوگل (Global Init Script Redirect)
* برای حل مشکل خطاهای ۵۰2 (Bad Gateway) و زمان انتظار SSL (TLS Handshake Timeout) ناشی از مسدود بودن سرورهای گوگل در ایران، یک فایل تنظیمات سراسری در مسیر `C:\Users\bahman\.gradle\init.gradle` ایجاد شد.
* این فایل تمام درخواست‌های دانلود مخازن Gradle (شامل `pluginManagement` و `dependencyResolutionManagement`) را به سرورهای آینه داخلی **Chrepo** (`http://gradle.chrepo.ir` با پشتیبانی از پروتکل غیرامن) و **Aliyun** هدایت می‌کند.

### ۴. سازگار سازی کدها با نسخه‌های جدید پلاگین‌ها (Dart Compile Fixes)
* **کد `local_auth` (نسخه 3.x):** متد `authenticate` در فایل‌های [profile_screen.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart) و [cycle_lock_gate.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/widgets/cycle_lock_gate.dart) و [app_lock_service.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/security/app_lock_service.dart) با پارامترهای جدید (`persistAcrossBackgrounding` و `biometricOnly`) جایگزین گردید.
* **کد `workmanager` (نسخه 0.9.x):** مقدار `ExistingWorkPolicy.replace` به `ExistingPeriodicWorkPolicy.replace` و مقدار `NetworkType.not_required` به `NetworkType.notRequired` در فایل‌های [main.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/main.dart) و [backup_screen.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/backup_screen.dart) اصلاح شد.
* **کد `google_sign_in` (نسخه 7.x):** کلاس `GoogleSignIn` در [google_drive_backup_service.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/google_drive_backup_service.dart) به حالت تک‌فرزندی (Singleton) بازنویسی شد و متدهای ورود و دریافت هدر احراز هویت با متدهای جدید (`attemptLightweightAuthentication` و `authorizationHeaders`) تطبیق یافتند.
* **رفع باگ متغیر گم‌شده:** تعریف متغیر `settingsMap` در ویجت `FutureBuilder` صفحه پروفایل انجام شد.

---

## 🎨 اصلاح تداخل‌های رنگی و خوانایی صفحه «حال و تعادل» در تم روشن (Wellbeing Screen Light Theme Fixes)

### ۱. اصلاح کارت ضربان تعادل (Balance Pulse Hero Card)
* **عنوان‌ها و برچسب‌های آماری:** رنگ متن عنوان‌ها و برچسب‌ها که دارای رنگ سفید سخت‌کد شده (`Colors.white54`) بودند و در پس‌زمینه کارت شیشه‌ای روشن ناپدید می‌شدند، به `colors.textSecondary` و `colors.textPrimary` تغییر یافت تا کنتراست عالی برقرار شود.
* **آیکون‌ها و وضعیت‌های غیرفعال:** مقدار رنگ آیکون‌ها و متون برای ماژول‌های غیرفعال از `Colors.white24` به رنگ پویای `colors.textSecondary.withValues(alpha: 0.4)` تبدیل شد.
* **نشانگر دایره‌ای شاخص سلامت:** بک‌گراند خاکستری دایره پیشرفت از `Colors.white.withValues(alpha: 0.08)` به `colors.textPrimary.withValues(alpha: 0.08)` تغییر یافت.
* **جداکننده‌ها:** خط جداکننده ستون‌ها از `Colors.white10` به `colors.border.withValues(alpha: 0.2)` تغییر پیدا کرد.
* **متن وضعیت چک‌این:** رنگ وضعیت "نشده" برای چک‌این از `Colors.orangeAccent` (که روی پس‌زمینه سفید کنتراست ضعیفی داشت) به رنگ پویای هشدار تم (`colors.warning`) منتقل شد.

### ۲. اصلاح کارت تحلیل‌های هوشمند (Smart Insights Card)
* **رنگ متن توصیه‌ها:** متن داخل کارت توصیه هوشمند («اطلاعات خودارزیابی موقتاً در دسترس نیست.» یا توصیه‌های ناشی از خواب و انرژی) از رنگ سفید سخت‌کد شده به `colors.textPrimary` تغییر داده شد تا در پس‌زمینه کارت شیشه‌ای تم روشن به راحتی خوانده شود.

### ۳. دکمه‌های سریع ثبت عملکرد (Quick Action Buttons)
* **برچسب‌های متنی دکمه‌ها:** برچسب متنی دکمه‌های «ثبت انرژی»، «ثبت خواب» و «چک‌این امروز» از رنگ سفید خام (`Colors.white`) روی پس‌زمینه رنگی روشن به رنگ خودِ آیکون‌ها متصل شد تا جلوه بصری و کنتراست بهتری پیدا کند.

### ۴. اصلاح کارت راه‌اندازی هدف خواب (Sleep Setup Card)
* **متون راهنما:** عنوان «هدف خواب خود را تعیین کنید 🌙» و متن راهنمای مربوط به آن که داخل کارت شیشه‌ای دارای رنگ‌های سخت‌کد شده `Colors.white` و `Colors.white70` بودند، به `colors.textPrimary` و `colors.textSecondary` متصل شدند.

### ۵. آیکون قفل تحلیل‌ها (Trends Inactive State Lock Icon)
* آیکون قفل نشان‌دهنده غیرفعال بودن نمودارها در بخش تعادل از `Colors.white30` به `colors.textSecondary.withValues(alpha: 0.4)` تغییر یافت.

---

## 🛠️ رفع کراش عدم وجود ProviderScope در ماژول ورزش تکمیلی (No ProviderScope Crash Fix)

### ۱. شرح مشکل
* در ماژول ورزش تکمیلی (Supplementary Sports)، صفحاتی نظیر `SSWorkoutSessionScreen` به صورت `ConsumerStatefulWidget` (با استفاده از سیستم مدیریت وضعیت Riverpod) پیاده‌سازی شده‌اند.
* به دلیل اینکه کل اپلیکیشن در ریشه خود مجهز به `ProviderScope` نبود، هنگام تلاش برای خواندن/تماشا کردن مقادیر پرووایدرها با استفاده از `ref.watch` یا `ref.read` در متد `build` این صفحات، کراش شدید با پیغام خطای `Bad state: No ProviderScope found` رخ می‌داد.

### ۲. تغییرات اعمال شده
* فایل [main.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/main.dart) اصلاح شده و پکیج `flutter_riverpod` ایمپورت گردید.
* کل ویجت ریشه اپلیکیشن (`RitmoApp`) در متد `runApp` درون یک `ProviderScope` به عنوان فرزند مستقیم `RestartWidget` محصور شد.
* با قرارگیری `ProviderScope` بعد از `RestartWidget` و قبل از `RitmoApp`، نه تنها در تمام صفحات برنامه پرووایدرهای ریورپاد در دسترس قرار گرفتند، بلکه با خروج کاربر یا ریست دیتابیس (توسط `RestartWidget`) وضعیت تمام پرووایدرهای ریورپاد نیز به طور ایمن ریست و پاکسازی می‌شود.

---

## 🎨 اصلاح و بهبود نمایش انیمیشن‌های ورزشی (Exercise Animations Fixes & Optimization)

### ۱. شرح مشکلات انیمیشن
* **تکراری بودن انیمیشن‌ها:** فایل‌های انیمیشن بسیار متنوعی در مسیر `assets/animations/custom` با نام‌گذاری‌های `hw_*.json` وجود داشتند. اما به دلیل عدم وجود مکانیسم نگاشت شناسه حرکات (که در دیتابیس با فرمت `boXXX_name` ذخیره شده‌اند)، برنامه شناسه حرکات را تشخیص نداده و تقریباً تمام حرکات را با انیمیشن پیش‌فرض دسته‌بندی (مثلاً شنا برای کل سینه و اسکوات برای کل پا) نمایش می‌داد.
* **ثابت ماندن انیمیشن‌ها (تکون نخوردن):** هنگام جابجایی بین تمرینات مختلف در صفحه تمرین، به دلیل استفاده از یک نمونه ویجت مشترک و عدم تغییر کلید (`key`) آن در درخت ویجت‌ها، وضعیت داخلی پخش‌کننده لاتی (`_SSLottiePlayerState`) مجدداً استفاده می‌شد. در این فرآیند متد `reset` بر روی کنترلر انیمیشن اجرا شده و انیمیشن در فریم اول متوقف می‌ماند و دیگر حرکت نمی‌کرد.
* **عدم اعمال سرعت انیمیشن:** مشخصه `speed` در کنترلر انیمیشن Lottie نادیده گرفته می‌شد و سرعت تنظیم شده اعمال نمی‌شد.

### ۲. تغییرات اعمال شده برای حل مشکلات
* **نگاشت هوشمند کد حرکات به انیمیشن‌ها:** با افزودن یک عبارت باقاعده (RegExp) به متد `SSLottiePlayer.forExercise` در [ss_lottie_player.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart)، کدهایی نظیر `bo109_deep_breathing` و `bo009_squats` به ترتیب به شناسه‌های انیمیشن واقعی `hw_109` و `hw_9` نگاشت شدند. این امر باعث باز شدن بیش از ۳۰۰ انیمیشن ورزشی منحصربفرد و رفع کامل انیمیشن‌های تکراری شد.
* **افزودن کلید پویا (ValueKey):** در زمان ساخت `SSLottiePlayer.forExercise` در بدنه ویجت `SSExerciseAnimationCard` یک `ValueKey` با مقدار `exerciseId` اعمال گردید. با این کار، در زمان رفتن به حرکت بعدی، فلاتر مجبور به ساخت مجدد استیت و لود انیمیشن جدید از ابتدا می‌شود که مشکل ایستایی و تکان نخوردن انیمیشن را به طور کامل حل می‌کند.
* **تنظیم سرعت پخش:** مدت‌زمان انیمیشن کنترلر بر اساس مشخصه سرعت پخش بخش‌پذیر شد (`composition.duration / widget.speed`) تا سرعت پخش انیمیشن‌ها (مانند زمان استراحت با سرعت کندتر) دقیقاً طبق استاندارد اعمال شود.

---

## 🎨 اصلاح و بهبود تم روشن در بخش آنبوردینگ اولیه (Onboarding Light Theme Contrast Fixes)

### ۱. شرح مشکلات تم روشن در آنبوردینگ
* **عدم خوانایی متون و آیکون‌ها:** تمام متون، دکمه‌های جهت‌یابی، گزینه‌ها و بخش‌های مختلف آنبوردینگ با استفاده از رنگ‌های سفید ثابت نظیر `Colors.white`، `Colors.white70` و `Colors.white54` مقداردهی شده بودند. به همین دلیل در حالت تم روشن که پس‌زمینه کارت شیشه‌ای به صورت سفید نیمه‌شفاف است، تمامی محتویات به صورت سفید روی سفید نمایش داده شده و کاملاً ناپدید و غیرقابل استفاده می‌شدند.
* **ثابت ماندن استایل گوی متحرک (RitmoOrb):** گوی تنفسی و ضربان قلب در وسط صفحه آنبوردینگ به صورت سخت‌کد شده از استایل‌های تم تاریک استفاده می‌کرد و تغییر تم تأثیری روی کنتراست رنگ‌های آن نداشت.
* **غیرقابل رویت بودن دکمه‌های غیرفعال و رد کردن (Skip):** دکمه‌های غیرفعال «ادامه» و لینک «رد کردن» به دلیل داشتن مقادیر سفید سخت‌کد شده روی پس‌زمینه سفید کارت محو می‌شدند.

### ۲. تغییرات اعمال شده برای حل مشکلات
* **پویاسازی تمام استپ‌های آنبوردینگ:** فایل‌های زیر که مراحل مختلف آنبوردینگ را تشکیل می‌دهند اصلاح شده و متغیرهای رنگی آن‌ها به `colors.textPrimary`، `colors.textSecondary` و `colors.border` متصل گردیدند:
  * [step_welcome.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/steps/step_welcome.dart)
  * [step_identity.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/steps/step_identity.dart)
  * [step_day_arc.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/steps/step_day_arc.dart)
  * [step_focus.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/steps/step_focus.dart)
  * [step_first_routine.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/steps/step_first_routine.dart)
  * [step_notifications.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/steps/step_notifications.dart)
  * [step_celebration.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/steps/step_celebration.dart)
* **پویاسازی گوی بومی ریتمو (RitmoOrb):** فایل [ritmo_orb.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/ritmo_orb.dart) ویرایش شد؛ پارامتر `isDarkMode` به یک متغیر nullable تبدیل شد تا به طور خودکار تم فعلی سیستم را از طریق `Theme.of(context).brightness` تشخیص دهد و رنگ‌های بازتاب بیرونی و داخلی خود را بر اساس آن تنظیم کند.
* **پویاسازی صفحه اصلی آنبوردینگ:** دکمه‌های ناوبری بالا، دکمه رد کردن، نوارهای پیشرفت بالای کارت و دکمه ادامه در فایل [onboarding_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/presentation/onboarding_screen.dart) به تم پویا متصل شدند.

---

## 🧠 پیاده‌سازی سیستم حافظه شناختی هوش مصنوعی دستیار (Ritmo AI Memory System)

پیرو دستورالعمل سند `016_ai-memory-system.md`، معماری کامل سیستم حافظه بلندمدت و هوشمند دستیار ریتمو به صورت کاملاً لوکال و آفلاین طراحی، پیاده‌سازی و یکپارچه‌سازی گردید.

### ۱. پایگاه‌داده و مهاجرت جداول (مرحله A)
* **فایل:** [database_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/database_helper.dart)
* جدول آزمایشی قدیمی `ss_ai_memory` به طور کامل حذف شد و جدول استاندارد جدید `ai_memory` با فیلدهای شناسه، فکت، نوع (MemoryType)، منبع (MemorySource)، دامنه (Domain)، سطح اهمیت، حساسیت، وضعیت، تعداد دفعات ارجاع، تاریخ انقضا و زمان‌های ثبت/ویرایش ایجاد گردید.

### ۲. مدل‌ها و ساختار حافظه (مرحله B)
* **فایل:** [memory_models.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/memory/memory_models.dart)
* کلاس‌های مدل `MemoryEntry` و کلاس دستورالعملی `MemoryOp` به همراه انوم‌های مربوطه (`MemoryType`, `MemorySource`, `MemoryStatus`) منطبق بر طراحی افزوده شدند.

### ۳. سرویس اصلی موتور حافظه ریتمو (مرحله C)
* **فایل:** [ai_memory_service.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/memory/ai_memory_service.dart)
* **الگوریتم بازیابی:** پیاده‌سازی روش امتیازدهی ترکیبی با وزن‌های اختصاصی بر اساس:
  - **تازگی با تابع کاهش نمایی:** زمان نیمه‌عمر ۷ روزه.
  - **شباهت محتوایی:** بررسی هم‌پوشانی توکن‌های فارسی (Jaccard similarity).
  - **بونوس دامنه‌ای:** بونوس اختصاصی ۲.۰ در صورت تطابق دقیق دامنه.
* **پاک‌سازی و هرس خودکار:** آرشیو کردن فکت‌های غیرپین کم‌اهمیت قدیمی (بیش از ۶۰ روز) و اعمال حد آستانه ظرفیت (حداکثر ۳۰ فکت عمومی و ۱۵ فکت برای هر دامنه).
* **شبکه ایمنی صریح (Deterministic Safety Net):** شناسایی دستی فکت‌هایی که کاربر با عبارات کلیدی (مانند «یادت باشه»، «یادت بمونه»، «فراموش نکن»، «به خاطر بسپار»، «remember») می‌نویسد و ثبت آن با حداکثر اهمیت.

### ۴. پردازش و تحکیم حافظه در پس‌زمینه (مرحله B)
* **فایل:** [memory_consolidator.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/memory/memory_consolidator.dart)
* کلاس `MemoryConsolidator` جهت استخراج خودکار علایق و اولویت‌های کاربر از روی پیام‌های گفتگو به کمک هوش مصنوعی پیاده‌سازی شد. تحکیم حافظه پس از طی حداقل ۴ نوبت کاربر در سشن جاری به صورت پس‌زمینه و غیرهمزمان (با چک‌لیست فلگ در `app_settings` جهت پیشگیری از اجرای تکراری) فعال می‌شود. همچنین در صورت تجمیع بیش از ۱۰ اپیزود در یک دامنه، به طور خودکار بینش‌های خلاصه (Insight) ایجاد می‌شوند.

### ۵. اتصال به چت و تزریق هوشمند (مرحله D & E)
* **فایل:** [chat_action_parser.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/chat/chat_action_parser.dart)
* سیستم پارسر برای استخراج و پیاده‌سازی تگ‌های عملیاتی حافظه `<memory_ops>...</memory_ops>` از پاسخ دستیار آماده و مجهز گردید.
* **فایل:** [streaming_chat_service.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/chat/streaming_chat_service.dart)
* فکت‌های بازیابی شده با کوئری کاربر در بدنه System Prompt تزریق شده و عملیات ثبت حافظه حاصل از پاسخ دستیار به همراه راه‌اندازی فرآیند تحکیم پس‌زمینه پس از اتمام استریم اعمال می‌شوند.
* **فایل:** [conversation_context_builder.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/chat/conversation_context_builder.dart)
* متدهای بازیابی حافظه فعال به بدنه فرآیند ساخت سابقه گفتگو متصل شدند.

### ۶. کلاس اتصال و یکپارچه‌سازی شیت‌های تخصصی دستیار (مرحله E)
* **فایل:** [assistant_memory_binding.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ai/memory/assistant_memory_binding.dart)
* جهت به حداقل رساندن کدهای تکراری، کلاس واسط برای اتصال تمامی شیت‌های تخصصی دستیار هوشمند ساخته شد و در شیت‌های زیر با موفقیت تزریق و یکپارچه گردید:
  - **کنکور:** [konkur_ai_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/konkur/logic/konkur_ai_helper.dart)
  - **دوره‌ها:** [courses_ai_helper.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/courses/logic/courses_ai_helper.dart)
  - **دوره ماهیانه:** [ai_cycle_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart)
  - **اهداف:** [ai_goals_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/goals/presentation/widgets/ai_goals_assistant_sheet.dart)
  - **سلامت:** [ai_health_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart)
  - **ورزش تکمیلی:** [ss_ai_coach_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart) (با پاک‌سازی و حذف کامل جداول قدیمی تست حافظه ورزش)
  - **بهزیستی:** [ai_wellbeing_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart)
  - **معنویت و عبادت:** [ai_worship_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart)

### ۷. صفحه مدیریت حافظه دستیار (مرحله F)
* **فایل:** [ai_memory_management_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/ai_memory_management_screen.dart)
* صفحه شیک و شیشه‌ای پرمیوم و راست‌چین در بخش تنظیمات پروفایل پیاده‌سازی شد که قابلیت‌های زیر را در اختیار کاربر می‌گذارد:
  - فعال/غیرفعال کردن سراسری سیستم حافظه دستیار.
  - فعال/غیرفعال کردن سیستم یادگیری تدریجی خودکار.
  - افزودن فکت به صورت صریح و دستی در حوزه مشخص.
  - مشاهده فکت‌های فعال تفکیک‌شده و گروه‌بندی‌شده بر اساس حوزه‌ها به همراه نشانگر نوع و سطح اهمیت.
  - پین کردن/خارج کردن از حالت پین فکت‌ها.
  - ویرایش مستقیم یا بایگانی کردن فکت‌ها.
  - بخش تاشو فکت‌های بایگانی‌شده با قابلیت بازیابی یا حذف نهایی و فیزیکی.
  - دکمه پاک‌سازی نهایی و دو مرحله‌ای کل حافظه.
* **فایل:** [profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart)
  - دکمه ورود به صفحه مدیریت حافظه با آیکون مغز و افکت‌های طراحی در انتهای شیت تنظیمات هوش مصنوعی (AI) متصل گردید.





