

---

# 📄 `prompts/025_completion-unification.md`

> **⚠️ ترتیب اجرا:** این پرامپت باید **قبل از ۰۲۴** اجرا شود، چون ۰۲۴ روی `MovementLogSheet` بنا شده و آن شیت باید از ابتدا روی اسکلت این پرامپت ساخته شود.
> 

> ترتیب کل پروژه: `COURSES_V2` → `022` → `023` → **`025`** → `024`.
> 

---

## ۰. زمینه و قواعد بنیادی

### ۰٫۱ مسئله در یک جمله

در ریتمو یک «قانون طلایی تفویض» برای **افزودن** آیتم‌ها برقرار شده است (هر ماژول تنها مالک پنجرهٔ افزودن خودش است)، اما همین قانون برای **انجام دادن** آیتم‌ها هرگز اعمال نشده. نتیجه: **هشت مسیر موازی نوشتن تکمیل**، **دو پیادهٔ کلمه‌به‌کلمه یکسان از تعویق**، **چهار تایمر مستقل**، و **یک قابلیت کامل (نسخهٔ سبک/حداقلی) که ساخته شده ولی هیچ مسیری آن را پر نمی‌کند و عملاً خاموش است**.

### ۰٫۲ سه اصل حاکم

1. **یک آیتم = یک اقدام = یک نقطهٔ نوشتن.** هر موجودیت دقیقاً یک لایهٔ مجاز برای نوشتن دارد.
2. **پنجرهٔ اقدام مالِ ماژول است.** همان‌طور که «افزودن دوره» فقط `CreateCourseSheet` را باز می‌کند، «ثبت جلسهٔ دوره» هم فقط باید شیت خودِ ماژول دوره‌ها را باز کند — از هر نقطه‌ای از اپ که صدا زده شود.
3. **قرارداد مشترک، نه ویجت مشترک.**
    
    ⛔ **ساخت `UniversalCompletionSheet` یا هر ویجت غول‌پیکر تک‌فایلی که همهٔ دامنه‌ها را با `if/switch` داخل خودش مدیریت کند، اکیداً ممنوع است.** اشتراک باید در سطح **اسپک و اسکلت** باشد، نه در سطح یک ویجت خدا.
    

### ۰٫۳ فایل‌هایی که قبل از شروع باید بخوانی

```
lib/features/routines/shared/routine_actions.dart
lib/features/routines/shared/widgets/routine_niyyah_sheet.dart
lib/features/routines/shared/widgets/routine_details_sheet.dart
lib/features/routines/shared/widgets/routine_snooze_bottom_sheet.dart
lib/features/routines/shared/widgets/routine_card.dart
lib/features/calendar/presentation/widgets/agenda_item_detail_sheet.dart
lib/features/calendar/presentation/journey_controller.dart
lib/features/calendar/presentation/logic/today_calendar_convergence_helper.dart
lib/features/today/presentation/now_dashboard_screen.dart
lib/features/courses/presentation/widgets/study_timer_sheet.dart
lib/features/konkur/presentation/widgets/konkur_study_sheet.dart
lib/features/konkur/presentation/widgets/konkur_today_section.dart
lib/features/worship/presentation/widgets/obligatory_prayers_section.dart
lib/features/worship/presentation/widgets/mustahab_section.dart
lib/features/goals/presentation/widgets/goals_card_list_section.dart
lib/features/health/presentation/widgets/medications_section.dart
lib/features/sports/presentation/widgets/sports_quick_log_sheet.dart
lib/features/sports/presentation/widgets/sports_cant_today_sheet.dart
lib/features/assistant/logic/assistant_action_registry.dart
lib/core/domain/agenda/agenda_action_handler.dart
lib/core/domain/agenda/day_agenda_service.dart
lib/core/domain/agenda/agenda_item.dart
lib/core/domain/engines/ritmo_execution_kernel.dart
lib/core/domain/engines/progression_engine.dart
lib/core/domain/engines/notification_decider.dart
lib/core/domain/engines/reshuffle_engine.dart
lib/core/domain/engines/rie/rie_pipeline.dart
lib/core/domain/execution/handlers/snooze_reminder_handler.dart
lib/core/domain/execution/handlers/skip_occurrence_handler.dart
lib/core/services/alarm_scheduler_service.dart
lib/core/services/notification_action_dispatcher.dart
lib/core/services/snapshot_sync_service.dart
lib/core/services/central_inbox_service.dart
lib/core/services/inbox_policy.dart
lib/core/analytics/energy_analytics_engine.dart
lib/features/routines/presentation/widgets/planner_duration_picker.dart
lib/features/supplementary_sports/presentation/ss_workout_session_notifier.dart  ← فقط خواندن، الگوی مرجع
android/app/src/main/kotlin/ir/ritmo/app/BootReceiver.kt
android/app/src/main/kotlin/ir/ritmo/app/RitmoForegroundService.kt
```

### ۰٫۴ ⛔ تصحیحات اجباری (باورهای غلط رایج)

| موضوع | واقعیت |
| --- | --- |
| `ss_session_set_log` | **وجود ندارد و ساخته نشود.** جدول واقعی `ss_workout_set_log` است. |
| «اسنوز از کرنل رد نمی‌شود» | **غلط است.** `RoutineActions.snoozeRoutine` از `SnoozeReminderCommand` عبور می‌کند. مشکل واقعی این است که `AlarmSchedulerService.snoozeReminder` یک **پیادهٔ دوم و کلمه‌به‌کلمه یکسان** است. |
| `setCourseSheetOpener` | از قبل `CreateCourseSheet` واقعی را باز می‌کند. **دست نزن.** |
| `CoursesRepository.updateCourse` | موجود است؛ بازنویسی نشود. |
| `MovementLogSheet` | متعلق به پرامپت ۰۲۴ است. در ۰۲۵ فقط جای خالی‌اش رزرو می‌شود. |
| ماژول ورزش تکمیلی | ⛔ **هیچ فایلی از `lib/features/supplementary_sports/` در این پرامپت ویرایش نشود.** |

### ۰٫۵ تصمیم‌های قطعی کاربر (غیرقابل تغییر)

| # | تصمیم |
| --- | --- |
| ۱ | هر شش فاز در یک تحویل؛ اما هر فاز کامیت مستقل و تست سبز. |
| ۲ | نسخهٔ سبک = **۵۰٪** هدف. |
| ۳ | نسخهٔ حداقلی = حداقل ممکن، صرفاً برای قطع‌نشدن زنجیره (فرمول T4). |
| ۴ | سقف تعویق = **۳ بار**؛ اما **بن‌بست و Exception اکیداً ممنوع** — نردبان خروج T10 اجباری است. |
| ۵ | تایمر ورزش تکمیلی دست‌نخورده. |
| ۶ | گزینهٔ «انتقال به فردا» برای روتین‌های `EVERY_DAY` **مخفی** باشد. |
| ۷ | دو وضعیت جدید `rescheduled` و `missed` به `routine_occurrences.status` اضافه شوند. |

---

## ۱. چهارده قانون سراسری

1. **نوشتن فقط توسط ماژول مالک.** هیچ صفحه‌ای خارج از ماژول، جدول آن ماژول را مستقیم ننویسد.
2. **بدون SQL خام در UI.** هیچ `db.insert/update/delete` در فایل‌های `presentation/`.
3. **دروازه خودش SQL نمی‌زند.** `CompletionGateway` فقط مسیریابی می‌کند و به ریپازیتوری/کرنل تفویض می‌کند.
4. **موفقیت دروغین ممنوع.** هیچ توست موفقیتی بدون بررسی `rowsAffected > 0` یا `didWrite == true` نمایش داده نشود.
5. **بدون عدد جادویی.** هر عدد یا از دیتابیس می‌آید یا از یک ثابت نام‌دار.
6. **بدون رشتهٔ جادویی.** هر مقدار وضعیت از enum می‌آید.
7. **کد مرده حذف فیزیکی شود** — نه کامنت، نه `@deprecated`، نه نگه‌داشتن «برای احتیاط». فایل پاک شود.
8. **تراکنش.** هر عملیات چندجدولی در یک تراکنش واحد.
9. **`RitmoIdFactory`** تنها منبع تولید شناسه.
10. **فقط Target Timestamp** برای تایمرها؛ ⛔ شمارندهٔ حافظه‌ای ممنوع.
11. **`context.mounted`** قبل از هر استفاده از context پس از `await`.
12. **RTL + `PersianDigits` + `Vazirmatn`** در تمام متن‌های جدید.
13. **بدون رگرسیون بصری.** رنگ‌ها، گرادیان‌ها، شعاع‌ها و انیمیشن‌های موجود عیناً حفظ شوند.
14. **هر فاز مستقلاً سبز.** `flutter analyze` بدون خطا و کل تست‌ها پاس، قبل از رفتن به فاز بعد.

---

## PASS 0 — ممیزی اجباری قبل از هر تغییر

این سیزده دستور را اجرا کن و خروجی هرکدام را در `prompts/025_REPORT.md` بخش «قبل» ثبت کن:

```bash
grep -rn "routine_completions" lib/ --include=*.dart
grep -rn "resultType" lib/ --include=*.dart
grep -rn "'COMPLETED'" lib/ --include=*.dart
grep -rn "?? 30\|?? 20\|?? 10\|_safeDur" lib/ --include=*.dart
grep -rn "CompleteOccurrenceCommand\|SkipOccurrenceCommand\|SnoozeReminderCommand" lib/
grep -rn "completeOccurrence\|skipOccurrence\|snoozeReminder" lib/
grep -rn "lightDurationMinutes\|minimalDurationMinutes" lib/
grep -rn "active_timers" lib/
grep -rn "Timer.periodic" lib/
grep -rn "AgendaItemToggled\|notifyRoutineChanged" lib/
grep -rn "showModalBottomSheet" lib/features/calendar/ lib/features/today/
grep -rn "pending_reminders" lib/
grep -rn "0\.4\|0\.7" lib/core/services/ lib/core/analytics/
```

⛔ **توقف اجباری:** اگر تعداد نقاط نوشتن در `routine_completions` بیشتر از هشت مورد فهرست‌شده در بند ۰٫۱ بود، **پیش نرو**. ابتدا فهرست کامل را در گزارش ثبت کن و همه را در T13 پوشش بده.

---

## فاز ۰ — تعمیرات دادهٔ بنیادی

### T1 — enum واحد نتیجه

فایل جدید `lib/core/domain/models/completion_result.dart`:

```dart
enum CompletionResult {
  full('FULL'),
  light('LIGHT'),
  minimal('MINIMAL'),
  partial('PARTIAL'),
  skipped('SKIPPED');

  const CompletionResult(this.dbValue);
  final String dbValue;

  static CompletionResult fromDb(String? v) => switch (v) {
        'FULL' || 'COMPLETED' => CompletionResult.full,
        'LIGHT'   => CompletionResult.light,
        'MINIMAL' => CompletionResult.minimal,
        'PARTIAL' => CompletionResult.partial,
        'SKIPPED' => CompletionResult.skipped,
        _ => CompletionResult.full,
      };

  /// وزن در محاسبهٔ ریتم روز. برای partial باید partialRatio پاس داده شود.
  double rhythmWeight([double? partialRatio]) => switch (this) {
        CompletionResult.full    => 1.0,
        CompletionResult.light   => 0.7,
        CompletionResult.minimal => 0.3,
        CompletionResult.partial => (partialRatio ?? 0.5).clamp(0.1, 0.9),
        CompletionResult.skipped => 0.0,
      };

  bool get keepsStreak => this != CompletionResult.skipped;
  bool get advancesProgression => this == CompletionResult.full;
}
```

**مهاجرت دیتابیس:**

```sql
UPDATE routine_completions SET resultType = 'FULL' WHERE resultType = 'COMPLETED';
ALTER TABLE routine_completions ADD COLUMN partialRatio REAL;
```

**پاک‌سازی اجباری:** هاردکدهای `resType == 'LIGHT' → 0.7` و `'MINIMAL' → 0.4` در `snapshot_sync_service` حذف فیزیکی شوند و از `CompletionResult.fromDb(...).rhythmWeight()` خوانده شوند. پس از این کار، عدد `0.4` به‌عنوان وزن نتیجه نباید در هیچ فایلی وجود داشته باشد.

`AgendaCompletion` هم باید `partial` را برای `PARTIAL` برگرداند (الان فقط `LIGHT`/`MINIMAL` را می‌شناسد).

### T2 — حذف مدت‌زمان‌های جعلی

تمام `?? 30`، `?? 20`، `?? 10` و تابع `_safeDur` در مسیرهای ثبت تکمیل حذف شوند. اگر مدت واقعی در دسترس نیست، **صفر ثبت شود، نه عدد ساختگی**.

**تنها استثنا:** `duration_estimator.dart` که عمداً fallback دارد — آنجا فقط `source: 'llm'` به `source: 'fallback'` تغییر کند تا در تحلیل‌ها قابل تفکیک باشد.

### T3 — تصحیح باگ تاریخ در تعویق

باگ فعلی در دو نقطه:

```dart
final dateStr = DateTime.fromMillisecondsSinceEpoch(origTimeMs).toIso8601String().substring(0,10);
```

اگر یادآور دیشب بوده و کاربر بامداد تعویق بزند، occurrence روز اشتباه به‌روزرسانی می‌شود.

**راه‌حل:** `SnoozeReminderCommand` پارامتر اجباری `required String dateStr` بگیرد. هندلر **هرگز** تاریخ را از `originalTime` استخراج نکند. تمام صداکننده‌ها به‌روز شوند.

### T4 — 🔴 زنده‌کردن نسخهٔ سبک و حداقلی

این بحرانی‌ترین تسک فاز صفر است. این قابلیت کامل ساخته شده اما هیچ مسیر ساختی مقادیرش را پر نمی‌کند و در عمل خاموش است.

فایل جدید `lib/core/domain/models/duration_variants.dart`:

```dart
class DurationVariants {
  static const int minimalFloor = 2;
  static const int minimalCap   = 10;
  static const int lightFloor   = 5;

  static int light(int target) =>
      (target * 0.5).round().clamp(lightFloor, target - 1);

  static int minimal(int target) =>
      (target * 0.15).round().clamp(minimalFloor, minimalCap);

  static bool supportsVariants(int target) => target > 5;
}
```

| هدف | سبک | حداقلی |
| --- | --- | --- |
| ۱۰ | ۵ | ۲ |
| ۲۰ | ۱۰ | ۳ |
| ۳۰ | ۱۵ | ۵ |
| ۶۰ | ۳۰ | ۹ |
| ۹۰ | ۴۵ | ۱۰ |
| ۱۲۰ | ۶۰ | ۱۰ |

**چرا سقف ۱۰ دقیقه:** نسخهٔ حداقلی نباید با نسخهٔ سبک رقابت کند. برای روتین دو ساعته، ۱۸ دقیقه دیگر «حداقلی» نیست و کاربر به‌جای نسخهٔ سبک آن را انتخاب می‌کند و پیشرفت واقعی متوقف می‌شود.

**UI:** در `planner_duration_picker.dart` یک بخش قابل‌جمع‌شدن با عنوان «نسخه‌های کوچک‌تر (برای روزهای سخت)»، پیش‌فرض بسته، زیرنویس «اگر روزی نتوانستی کامل انجام دهی، این‌ها زنجیره‌ات را زنده نگه می‌دارند.»، دو اسلایدر با مقادیر پیش‌محاسبه و برچسب «پیشنهاد ریتمو».

**اعتبارسنجی سخت:** `2 ≤ minimal < light < target`. اگر `target ≤ 5` هر دو غیرفعال شوند.

**`PlannerSaveContext`** دو فیلد `lightDuration` و `minimalDuration` بگیرد. سه نقطه‌ای که صریحاً `'lightDurationMinutes': 0` می‌نویسند (`SportsStrategy`، `assistant_action_registry`، و نقطهٔ سوم که در PASS 0 پیدا می‌کنی) به `DurationVariants` وصل شوند. در `EditRoutineCommand` هم قابل ویرایش باشد.

**مهاجرت داده‌های موجود:**

```sql
UPDATE routines
SET lightDurationMinutes   = MAX(5, MIN(CAST(ROUND(targetDurationMinutes*0.5) AS INTEGER), targetDurationMinutes-1)),
    minimalDurationMinutes = MAX(2, MIN(CAST(ROUND(targetDurationMinutes*0.15) AS INTEGER), 10))
WHERE targetDurationMinutes > 5
  AND category != 'medical'
  AND (lightDurationMinutes IS NULL OR lightDurationMinutes = 0);
```

⛔ داروها مستثنا — نصف‌کردن دوز دارو مفهوم ندارد.

### T5 — پیشرفت تدریجی فقط روی نسخهٔ کامل

`ProgressionEngine.onCompletion` فقط وقتی صدا زده شود که `result.advancesProgression == true`. نسخهٔ سبک، حداقلی، جزئی و رد‌شده **خنثی** باشند (نه پیشرفت، نه پس‌رفت).

### T6 — حذف کد مردهٔ انرژی

`energy_analytics_engine` برای `resultType == 'SNOOZED'` جریمهٔ ۵- می‌گذارد، اما تعویق **هرگز** ردیفی در `routine_completions` نمی‌نویسد. این شاخه هرگز اجرا نشده است.

**راه‌حل:** جریمهٔ تعویق از `pending_reminders.deferCount` و `routine_occurrences.status` محاسبه شود، نه از جدول تکمیل. شاخهٔ `'SNOOZED'` از خواندن `routine_completions` حذف فیزیکی شود.

---

## فاز ۱ — دروازهٔ واحد

### T7 — `completion_request.dart`

```
lib/core/domain/completion/completion_request.dart
```

sealed class با نه شاخه:

`RoutineCompletion` · `RoutineSkip` · `RoutineSnooze` · `CourseSessionCompletion` · `KonkurSessionCompletion` · `WorshipCompletion` · `GoalStepCompletion` · `MedicationTake` · `MovementCompletion`

🔒 `MovementCompletion` در این پرامپت فقط تعریف شود و پیاده‌سازی‌اش `UnimplementedError('پرامپت ۰۲۴')` بیندازد.

### T8 — `completion_outcome.dart`

```dart
class CompletionOutcome {
  final bool didWrite;
  final int streakDelta;
  final List<String> unlockedAchievements;
  final List<String> sideEffects;
  final String? undoToken;
  final String? errorMessage;
}
```

### T9 — `completion_gateway.dart`

```dart
Future<CompletionOutcome> submit(CompletionRequest request);
```

- ⛔ **هیچ SQL مستقیمی.** فقط `switch` روی نوع درخواست و تفویض به ریپازیتوری/کرنل مالک.
- پس از هر نوشتن موفق: `DayAgendaService.instance.invalidateDate(dateStr)` + انتشار رویداد.
- **هرگز خطا پرتاب نکند** — خطا در `errorMessage` برگردد.

### T10 — `snooze_policy.dart` (بازنویسی کامل)

**اصل حاکم:** تعویق یک تعلیق است، نه یک تصمیم. سیستم اجازه ندارد کاربر را معلق رها کند و اجازه ندارد او را با خطا مجازات کند. هر مسیر تعویق باید به یک وضعیت قطعی ختم شود.

```dart
enum SnoozeVerdict { allowed, lastCall, exhausted, blockedMedical, blockedMidnight }
enum ExitOption { doMinimalNow, lastWindowTonight, moveToTomorrow, skipWithReason }

class SnoozeDecision {
  final SnoozeVerdict verdict;
  final int allowedMinutes;
  final DateTime? snoozeUntil;
  final int deferCount;
  final int remaining;
  final String? userMessage;
  final List<ExitOption> exits;
}
```

`SnoozePolicy.evaluate(...)` یک تابع **خالص** است: ورودی می‌گیرد، تصمیم برمی‌گرداند، **هیچ SQL نمی‌زند و هیچ UI نشان نمی‌دهد**.

**سقف‌ها:**

| نوع | سقف |
| --- | --- |
| روتین معمولی | ۳ |
| عبادت | ۳ |
| دارو (`category == 'medical'`) | **۲** |
| `isEssential == 1` | **۲** |
| گام هدف / جلسهٔ دوره | ۳ |

سقف از `app_settings['snooze_max_defer_count']` (پیش‌فرض `'3'`) خوانده شود. ⛔ عدد ۳ در هیچ فایلی هاردکد نماند — از جمله در `agenda_action_handler` که الان `currentDeferCount >= 3` دارد.

**چهار گارد:**

1. **نیمه‌شب:** اگر `now + minutes` از `23:59` امروز بگذرد → `blockedMidnight`، پیشنهاد «انتقال به فردا».
2. **خواب:** اگر بعد از `app_settings['sleep_time']` بیفتد → پذیرفته ولی تا «۳۰ دقیقه قبل خواب» clamp شود، با پیام «تا قبل از خوابت جا می‌شود.»
3. **دارو:** اگر `minIntervalHours` با دوز بعدی نقض شود → `blockedMedical` با پیام «دوز بعدی ساعت X است؛ بیشتر از این نمی‌شود عقب انداخت.»
4. **چسبندگی:** دو تعویق با فاصلهٔ کمتر از ۲ دقیقه → تعویق قبلی **جایگزین** شود و `deferCount` بالا نرود.

**🎯 نردبان پایان تعویق:**

وقتی `verdict == exhausted`، ⛔ **هرگز Exception پرتاب نشود و هرگز SnackBar خطا نمایش داده نشود.** به‌جایش `RitmoActionSheet` با `SheetActionKind.deferExhausted`:

- **عنوان:** «این سومین بارِ امروز است»
- **متن:** «اشکالی ندارد — ولی بیایید تکلیفش را روشن کنیم تا معلق نماند.»
- بدون آیکون خطا، بدون رنگ قرمز. رنگ کارت `colors.warning` با شفافیت ۰٫۱۲.

| # | گزینه | رفتار |
| --- | --- | --- |
| ۱ | **«همین الان، نسخهٔ حداقلی (X دقیقه)»** | مستقیم به Gateway با `CompletionResult.minimal`. زنجیره حفظ می‌شود. **دکمهٔ اصلی و برجسته.** |
| ۲ | **«آخرین فرصت، امشب»** | تعویق ویژه و آخر تا `sleep_time − 45min`. `deferCount = cap + 1`، `state = 'last_call'`. پس از این، دکمهٔ تعویق حتی نمایش داده نشود. |
| ۳ | **«بگذار برای فردا»** | occurrence امروز → `status = 'rescheduled'`؛ occurrence فردا در همان ساعت. رد محسوب نمی‌شود، زنجیره را نمی‌شکند، ولی وزن ریتم امروز هم نمی‌گیرد. **برای روتین‌های `EVERY_DAY` این گزینه مخفی باشد.** |
| ۴ | **«امروز نمی‌توانم»** | شیت دلیل (T27) → `skip_reasons`  • `SKIPPED`. |

⛔ **هیچ دکمهٔ «بستن» یا «بعداً» وجود ندارد.** اگر کاربر شیت را با کشیدن به پایین ببندد، **هیچ چیز نوشته نشود** و آیتم در `snoozed` بماند تا جاروب پایان روز تکلیفش را روشن کند.

### T10-b — `EndOfDaySweep`

مشکل کشف‌نشده: آیتمی که snooze شده و کاربر تا نیمه‌شب سراغش نرفته، **برای همیشه در `status='snoozed'` می‌ماند** و نه در آمار می‌آید نه در بدهی‌ها.

```
lib/core/services/end_of_day_sweep.dart   ← فایل جدید
```

- روی تسک موجود `ritmo_periodic_reschedule` قلاب شود. ⛔ تسک Workmanager جدید ثبت نشود.
- هر `routine_occurrences` با `status IN ('snoozed','pending')` و `date < today`:
    - اگر `isEssential == 1` یا `category == 'medical'` → `status='missed'` + `CentralInboxService.push(category: ALERT, priority: 2, eventType: 'missed_essential')`
    - در غیر این صورت → `status='missed'` بی‌صدا
- ⛔ **`missed` هرگز ردیفی در `routine_completions` نمی‌نویسد.** این دقیقاً همان اشتباهی است که با `'SNOOZED'` رخ داد و کد مرده تولید کرد (T6).
- `pending_reminders` مربوطه → `state='expired'` و آلارم فیزیکی کنسل شود.
- **تفکیک آماری:** `skipped` = تصمیم آگاهانه · `missed` = رهاشده. این دو در هیچ تحلیلی یکی شمرده نشوند.

**مهاجرت وضعیت‌ها:** دو مقدار `rescheduled` و `missed` به دامنهٔ مجاز `routine_occurrences.status` اضافه شوند. هر نقطه‌ای که این ستون را می‌خواند بازبینی شود — به‌ویژه `routine_agenda_source`، `day_agenda_service`، `snapshot_sync_service`، `energy_analytics_engine` و تمام کوئری‌های `WHERE status = 'pending'`.

```dart
enum OccurrenceStatus { pending, done, snoozed, skipped, rescheduled, missed }
```

⛔ رشتهٔ خام برای status در کد جدید ممنوع.

### T10-c — یادگیری از الگوی تعویق

تعویق باارزش‌ترین سیگنال رفتاری اپ است و الان کاملاً دور ریخته می‌شود.

- منبع تحلیل: جدول موجود `notification_history` با `actionTaken='delayed'`. ⛔ جدول جدید ساخته نشود.
- **قاعده:** اگر یک آیتم در ۱۴ روز گذشته ≥ ۵ بار تعویق خورده و میانگین اختلاف زمان تعویق‌ها ≥ ۴۵ دقیقه باشد → پیشنهاد جابه‌جایی دائمی ساعت.
- خروجی: `CentralInboxService.push(category: SUGGESTION, ...)` با dedupeKey هفتگی.
- متن: «"مطالعهٔ شب" را معمولاً حدود ۲۲:۳۰ انجام می‌دهی، نه ۲۱:۰۰. ساعتش را جابه‌جا کنم؟» با دو دکمه؛ «نه، همین خوب است» الگو را ۳۰ روز خاموش کند.
- ⛔ **سیستم هرگز خودش ساعت را تغییر ندهد.**
- اگر پرامپت ۰۲۲ اجرا شده، ساعت پیشنهادی از `StationTimeRecommender` گرفته شود.

### T10-d — سیگنال روز پرفشار

اگر در یک روز ≥ ۵ آیتم مختلف تعویق بخورند، مشکل آیتم نیست، مشکل ظرفیت روز است:

- یک‌بار در روز (dedupe روزانه): «امروز روز شلوغی است. می‌خواهی برنامهٔ باقی روز را سبک کنم؟»
- دکمه مستقیم `ReshuffleEngine` موجود را صدا بزند که از قبل استراتژی فشرده‌سازی به نسخهٔ سبک دارد. ⛔ موتور جدید ساخته نشود.

### T11 — حذف پیاده‌های موازی

| مسیر | اقدام |
| --- | --- |
| `AlarmSchedulerService.snoozeReminder` | 🗑 حذف کامل |
| `AlarmSchedulerService.completeOccurrence` | ↻ نازک‌سازی به یک فراخوان Gateway، یا حذف اگر بی‌مصرف شد |
| `AlarmSchedulerService.skipOccurrence` | ↻ همان |
| `agenda_action_handler` تعویق عبادت | ↻ بازنویسی؛ `throw Exception` حذف شود |

### T12 — رویداد جدید

`RitmoEventType.completionRecorded` با payload:

```json
{"domain": "...", "itemId": "...", "dateStr": "...", "result": "...", "didWrite": true}
```

### T13 — اتصال هر هشت مسیر

| # | مسیر | اقدام |
| --- | --- | --- |
| ۱ | `RoutineActions.completeRoutine` | ↻ به Gateway |
| ۲ | `now_dashboard_screen._completeTask` | 🗑 حذف کامل، جایگزینی با Gateway |
| ۳ | `journey_controller.completeItem/skipItem` | ↻ به Gateway؛ `'COMPLETED'` حذف |
| ۴ | `today_calendar_convergence_helper.completeItem` | 🗑 حذف (کپی کلمه‌به‌کلمهٔ ۳) |
| ۵ | `active_timer_overlay._completeRoutine` | ↻ به Gateway |
| ۶ | `assistant_action_registry → completeRoutine` | ↻ حذف SQL خام، به Gateway |
| ۷ | `RitmoAgendaWidgetProvider.kt` | ↻ از طریق MethodChannel به Gateway |
| ۸ | `konkur_today_section` دیالوگ inline | 🗑 حذف، به `KonkurStudySheet` |

**تأیید نهایی فاز ۱:** `grep -rn "routine_completions" lib/ --include=*.dart` باید **دقیقاً یک فایل** برگرداند (ریپازیتوری روتین).

---

## فاز ۲ — مسیریاب اقدام

### T14 — `action_router.dart`

```
lib/core/domain/agenda/action_router.dart
ActionRouter.open(BuildContext context, {required AgendaItem item})
```

| `AgendaDomain` | شیت |
| --- | --- |
| `routine` | `RoutineNiyyahSheet` |
| `course` | `StudyTimerSheet` |
| `konkur` | `KonkurStudySheet` |
| `worship` | `WorshipQuickActionSheet` |
| `sport` | `MovementLogSheet` (۰۲۴ — فعلاً `SportsQuickLogSheet`) |
| `goalStep` | `GoalStepActionSheet` |
| `medication` | `MedicationTakeSheet` |

### T15 — حذف پنجرهٔ دوم تقویم

`agenda_item_detail_sheet.dart` **حذف فیزیکی** شود. دکمهٔ «تایم‌لاین» آن به اکشن `viewDetails` در شیت مالک منتقل شود.

### T16 — تمیزکاری

- `journey_controller`: منطق تکمیل حذف، فلگ‌های نمایشی حفظ.
- `now_dashboard`: تمام مسیرهای مستقیم به `ActionRouter`.
- `ss_home_dashboard._showCantTodayBottomSheet` (هر دو دکمه فقط `Navigator.pop`) 🗑 حذف. ⚠️ این تنها استثنای قانون «دست‌نزدن به ورزش تکمیلی» است چون کد کاملاً مرده است.
- `sports_cant_today_sheet` که `// TODO: Save missed reason` دارد → به T27 وصل شود.

---

## فاز ۳ — اسکلت مشترک

### T17 — `ritmo_action_sheet.dart`

```
lib/core/widgets/action/ritmo_action_sheet.dart

class ActionSheetSpec {
  final Widget header;
  final Widget body;
  final List<SheetAction> actions;
  final Widget? footer;
}

enum SheetActionKind {
  complete, completeWithVariant, startTimer, snooze,
  skip, cantToday, undo, edit, viewDetails, deferExhausted
}
```

اسکلت فقط چیدمان، انیمیشن، Glassmorphism، RTL و رفتار bottom sheet را می‌دهد. **محتوای هر دامنه در ویجت خودش می‌ماند.**

### T18 — بازنویسی `RoutineNiyyahSheet`

روی اسکلت، با حفظ کامل ظاهر فعلی (شامل گرادیان نارنجی MINIMAL با `alpha: 0.3` و `blurRadius: 8`). **کارت چهارم `PARTIAL`** با اسلایدر ۱۰٪ تا ۹۰٪ اضافه شود.

### T19–T23 — شیت‌های دامنه‌ها

- **T19** `WorshipQuickActionSheet`
- **T20** `GoalStepActionSheet`
- **T21** `KonkurStudySheet` یکپارچه — دیالوگ inline حذف، «فقط تیک بزن» با `durationMinutes: 0` (نه ۳۰)
- **T22** `MedicationTakeSheet`
- **T23** `StudyTimerSheet` روی اسکلت

---

## فاز ۴ — تایمر واحد

### T24 — `ritmo_timer_service.dart`

```sql
ALTER TABLE active_timers ADD COLUMN domain TEXT;
ALTER TABLE active_timers ADD COLUMN itemId TEXT;
ALTER TABLE active_timers ADD COLUMN mode TEXT;
ALTER TABLE active_timers ADD COLUMN direction TEXT;      -- 'DOWN' | 'UP'
ALTER TABLE active_timers ADD COLUMN targetTimestamp INTEGER;
```

- ⛔ **`db.delete('active_timers')` بدون شرط اکیداً ممنوع.**
- چند تایمر هم‌زمان مجاز، ولی **فقط یک Foreground Service**.
- محاسبه فقط از `targetTimestamp`؛ Doze-safe.

### T25 — تصحیح بازیابی تایمر

- `_startTimerFlow(routine, 'FULL')` هاردکد در `now_dashboard` حذف؛ حالت واقعی از ستون `mode` خوانده شود.
- `elapsed` از `targetTimestamp` بازمحاسبه شود.
- اگر اپ بعد از پایان تایمر باز شد → دیالوگ «تایمر تمام شده بود».

### T26 — مهاجرت سه تایمر

سه تایمر `Timer.periodic` (به‌جز ورزش تکمیلی) به سرویس واحد منتقل شوند.

🔒 `ss_workout_session_notifier` **دست‌نخورده** — فقط به‌عنوان الگوی مرجع Target Timestamp خوانده شود.

---

## فاز ۵ — ارتقاها

### T27 — دلیل رد کردن

```sql
CREATE TABLE skip_reasons (
  id TEXT PRIMARY KEY, itemId TEXT, domain TEXT, dateStr TEXT,
  reason TEXT, note TEXT, createdAt INTEGER
);
CREATE INDEX idx_skip_reasons_item ON skip_reasons(itemId);
```

شش دلیل: `«وقت نداشتم»` · `«انرژی نداشتم»` · `«حالم خوب نبود»` · `«یادم رفت»` · `«حوصله نداشتم»` · `«بیرون بودم»`

سه بار همان دلیل در ۱۴ روز → پیشنهاد متناسب با دلیل (کمبود وقت → کوتاه‌کردن؛ کمبود انرژی → جابه‌جایی به ساعت پرانرژی؛ فراموشی → تقویت یادآور).

### T28 — Undo سراسری

`CompletionGateway.undo(token)` — توست موفقیت هر اقدام دکمهٔ «لغو» داشته باشد (۸ ثانیه).

### T29 — ثبت دسته‌ای

چند آیتم در یک تراکنش واحد.

### T30 — پیش‌فرض هوشمند حالت

پیشنهاد نسخهٔ سبک از `rie_pipeline.suggestLightVersion` خوانده شود. ⛔ منطق جدید نوشته نشود.

### T31 — تیک بدون شیت

برای آیتم‌های `≤ 5` دقیقه، تپ مستقیم ثبت کند (با Undo)، بدون باز شدن شیت.

---

## فاز ۶ — تست، ممیزی، گزارش

### T32 — بیست‌وچهار فایل تست

```
completion_gateway_routing_test          completion_gateway_no_sql_test
completion_result_migration_test         rhythm_weight_single_source_test
snooze_future_date_test                  snooze_cap_test
snooze_midnight_guard_test               snooze_medical_cap_two_test
snooze_debounce_test                     snooze_exhausted_no_exception_test
last_call_blocks_further_snooze_test     end_of_day_sweep_test
missed_vs_skipped_separation_test        occurrence_status_enum_test
light_minimal_backfill_test              light_minimal_medical_excluded_test
duration_variants_bounds_test            minimal_cap_ten_test
progression_only_on_full_test            timer_target_timestamp_test
timer_multi_concurrent_test              timer_restore_mode_test
action_router_coverage_test              undo_token_test
skip_reason_pattern_test
```

### T33 — ممیزی قبل/بعد

جدول عددی: تعداد نقاط نوشتن، تعداد `Timer.periodic`، تعداد `showModalBottomSheet` در calendar/today، تعداد اعداد جادویی، تعداد خطوط حذف‌شده.

### T34 — مستندات

```
prompts/025_REPORT.md
docs/adr/0006-completion-gateway-and-action-router.md
DESIGN_SYSTEM_ACTION_SHEETS.md
```

---

## 🗑 جدول حذفی‌های اجباری

| فایل / تابع | دلیل |
| --- | --- |
| `agenda_item_detail_sheet.dart` | پنجرهٔ دوم موازی |
| `AlarmSchedulerService.snoozeReminder` | پیادهٔ دوم کلمه‌به‌کلمه |
| `today_calendar_convergence_helper.completeItem` | کپی `journey_controller` |
| `now_dashboard_screen._completeTask` | مسیر موازی |
| `ss_home_dashboard._showCantTodayBottomSheet` | هر دو دکمه فقط `Navigator.pop` |
| دیالوگ inline در `konkur_today_section` | مسیر موازی |
| شاخهٔ `'SNOOZED'` در `energy_analytics_engine` | هرگز اجرا نشده |
| `throw Exception('حداکثر تعداد تعویق...')` | بن‌بست UX |
| `_safeDur` و تمام `?? 30` در مسیر تکمیل | داده جعلی |
| هاردکد `0.7` و `0.4` در `snapshot_sync_service` | منبع دوگانه |
| `'lightDurationMinutes': 0` در سه استراتژی | خاموش‌کنندهٔ قابلیت |
| `_startTimerFlow(routine, 'FULL')` | حالت هاردکد |
| `db.delete('active_timers')` بدون شرط | حذف تایمرهای دیگر |

---

## ✅ سی سناریوی پذیرش

1. از تقویم روی روتین می‌زنم → فقط یک پنجره باز می‌شود، همان شیت نیت.
2. از داشبورد امروز روی همان روتین می‌زنم → **دقیقاً همان پنجره**.
3. از ویجت اندروید تیک می‌زنم → همان مسیر Gateway طی می‌شود.
4. از نوتیفیکیشن «انجام شد» می‌زنم → همان مسیر.
5. هیچ‌جا مقدار `'COMPLETED'` در دیتابیس نوشته نمی‌شود.
6. تیک بدون تایمر → `durationMinutes = 0` ثبت می‌شود، نه ۳۰.
7. روتین ۶۰ دقیقه‌ای می‌سازم → سبک ۳۰ و حداقلی ۹ خودکار ثبت شده.
8. هدف ۱۲۰ دقیقه → حداقلی دقیقاً ۱۰ (سقف).
9. داروی جدید می‌سازم → هیچ نسخهٔ سبک/حداقلی ندارد.
10. در شیت نیت هر چهار کارت (کامل/سبک/حداقلی/جزئی) دیده می‌شوند.
11. نسخهٔ جزئی با اسلایدر ۶۰٪ ثبت می‌کنم → `partialRatio = 0.6` و وزن ریتم ۰٫۶.
12. نسخهٔ سبک ثبت می‌کنم → پیشرفت تدریجی جلو **نمی‌رود**.
13. نسخهٔ کامل ثبت می‌کنم → پیشرفت تدریجی یک گام جلو می‌رود.
14. تعویق می‌زنم → هیچ ردیفی در `routine_completions` نوشته نمی‌شود.
15. بامداد ساعت ۱ روتین دیشب را تعویق می‌زنم → occurrence **دیروز** به‌روز می‌شود، نه امروز.
16. سه بار تعویق می‌زنم → بار سوم شیت چهارگزینه‌ای، **بدون هیچ پیام خطا**.
17. «نسخهٔ حداقلی» را می‌زنم → بدون شیت دوم ثبت می‌شود و زنجیره نمی‌شکند.
18. «آخرین فرصت امشب» → یادآور ۴۵ دقیقه قبل خواب؛ دکمهٔ تعویق دیگر ظاهر نمی‌شود.
19. روی روتین `EVERY_DAY` در نردبان، گزینهٔ «فردا» **دیده نمی‌شود**.
20. روی تسک تک‌باره، گزینهٔ «فردا» دیده می‌شود و occurrence فردا ساخته می‌شود.
21. شیت نردبان را می‌بندم → فردا آیتم `missed` است، نه `skipped`، و ردیف completion ندارد.
22. داروی با `minIntervalHours=6` را دو بار تعویق می‌زنم → بار دوم نردبان، **بدون گزینهٔ «فردا»**.
23. تعویق ۲۳:۵۰ به مدت ۳۰ دقیقه → رد می‌شود و «انتقال به فردا» پیشنهاد می‌شود.
24. دو بار پشت هم روی تعویق می‌زنم → `deferCount` فقط یک واحد بالا می‌رود.
25. یک روتین را ۶ روز پیاپی تعویق می‌زنم → در Inbox پیشنهاد جابه‌جایی ساعت؛ «نه» → ۳۰ روز سکوت.
26. در یک روز ۵ آیتم تعویق می‌زنم → **یک‌بار** پیشنهاد سبک‌سازی روز.
27. تایمر شروع می‌کنم، اپ را می‌بندم، ۲۰ دقیقه بعد باز می‌کنم → زمان **درست** نمایش داده می‌شود.
28. تایمر نسخهٔ سبک را شروع می‌کنم و اپ را می‌بندم → پس از بازگشت حالت همچنان «سبک» است، نه «کامل».
29. دو تایمر هم‌زمان → هر دو زنده می‌مانند، فقط یک نوتیف Foreground.
30. هر اقدامی که ثبت می‌کنم، توست دکمهٔ «لغو» دارد و لغو واقعاً کار می‌کند.

---

## 🚫 خطوط قرمز

- ⛔ `UniversalCompletionSheet` یا هر ویجت خدا ساخته نشود.
- ⛔ `CompletionGateway` هیچ SQL مستقیمی نزند.
- ⛔ هیچ فایلی از `supplementary_sports/` ویرایش نشود (تنها استثنا: T16، حذف کد مردهٔ `_showCantTodayBottomSheet`).
- ⛔ `MovementLogSheet` ساخته نشود — متعلق به ۰۲۴.
- ⛔ `ss_session_set_log` ساخته نشود.
- ⛔ کد مرده کامنت نشود، حذف فیزیکی شود.
- ⛔ هیچ Exception به‌عنوان مکانیزم UX استفاده نشود.
- ⛔ `missed` هرگز ردیف completion ننویسد.
- ⛔ اگر جایی مطمئن نیستی، **متوقف شو و بپرس** — مسیر موازی جدید نساز.

---

```bash
# PASS 0 — گام صفر: تشخیص وضعیت لایهٔ حرکت (۰۲۴)
ls lib/features/sports/movement/ 2>/dev/null
grep -rn "MovementLogSheet\|MovementRepository" lib/ --include=*.dart
grep -rn "movement_kinds" lib/core/database/
ls prompts/024_REPORT.md docs/adr/0005-*.md 2>/dev/null
```

**اگر خروجی غیرخالی بود → حالت «۰۲۴ زنده است»؛ این تغییرات در پرامپت اعمال شود:**

1. **بند ۰٫۴** — سطر «`MovementLogSheet` متعلق به ۰۲۴ است، ساخته نشود» حذف و جایگزین شود با: «`MovementLogSheet` از قبل موجود است؛ فقط روی اسکلت `ActionSheetSpec` (T17) منتقل شود، بدون تغییر در منطق `metMinutes`، `MovementSuggester` و `movement_budget`.»
2. **T7** — `MovementCompletion` دیگر `UnimplementedError` نیندازد؛ به `MovementRepository.log(...)` موجود تفویض کند و ⛔ هرگز مستقیم در `workout_logs` ننویسد.
3. **T14 جدول مسیریابی** — ردیف `sport` از «فعلاً `SportsQuickLogSheet`» به قطعیتِ `MovementLogSheet` تغییر کند.
4. **T16** — `sports_quick_log_sheet.dart` باید **حذف فیزیکی** شده باشد؛ اگر هنوز هست، این پرامپت حذفش کند و همهٔ صداکننده‌ها به `MovementLogSheet` وصل شوند.
5. **جدول تک‌نقطهٔ نوشتن** — ردیف «رویداد حرکت» از «(۰۲۴)» به «موجود» تغییر کند.
6. **دو سناریوی جدید** به فهرست پذیرش اضافه شود:
    - **S31:** پیاده‌روی را از تقویم تیک می‌زنم → `MovementLogSheet` باز می‌شود، نه شیت نیت روتین.
    - **S32:** پس از ثبت حرکت، `metMinutes` و بودجهٔ هفتگی دقیقاً مثل قبل از ۰۲۵ محاسبه می‌شوند (بدون رگرسیون).
7. **جملهٔ «۰۲۵ باید قبل از ۰۲۴ اجرا شود»** از هدر سند حذف شود.

**اگر خروجی خالی بود → ایجنت باید متوقف شود و گزارش دهد**، نه اینکه خودش لایهٔ حرکت را بسازد.

---

