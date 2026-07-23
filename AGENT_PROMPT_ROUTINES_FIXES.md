# 🤖 پرامپت اجرایی — «اصلاحِ بخشِ روتین‌ها» (Routines Consistency Fixes) — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ R1…R10 را یک‌سره تا آخر اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: رفعِ ناسازگاری‌های واقعیِ بخشِ روتین، مخصوصاً **همگراییِ همهٔ مسیرهای «انجام شد» روی یک سرویسِ واحد**، حذفِ مقادیرِ جعلی، enum واحد، و transaction.

## ⛔️ قواعد (یک‌بار)
- منطقِ موجود را نشکن؛ رفتارِ کاربر تغییری نکند جز اینکه **سازگار** شود. خروجیِ صحیح، نه بازطراحیِ UI.
- فارسی/RTL. فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.

## 📁 محیط (تأییدشده از کد)
- **دو مسیرِ تکمیلِ واگرا (مشکلِ اصلی):**
  - `lib/core/services/alarm_scheduler_service.dart` → `completeOccurrence(routineId, dateStr, {resultType='FULL'})`: occurrence را `done` می‌کند، `ProgressionEngine().onCompletion(db, routineId)` را اجرا، آلارمِ pending را **کنسل**، رویداد لاگ و `SnapshotSyncService.syncAll()` را صدا می‌زند. (مسیرِ نوتیف + AI از این استفاده می‌کنند.) ⚠️ اما `durationMinutes` را در completion ثبت نمی‌کند.
  - `lib/features/routines/presentation/routines_list_screen.dart` → `_completeRoutine(routineId, resultType, {duration})` (خط ~۲۵۷): فقط مستقیم در `routine_completions` می‌نویسد؛ occurrence/progression/کنسلِ آلارم/sync را **انجام نمی‌دهد**؛ و در خط ~۳۰۰ `SnapshotHelper.updateWidgetSnapshot(rhythmScore: 82, currentEnergyLevel: 'medium')` با مقادیرِ **هاردکدِ جعلی** صدا می‌زند.
- `_snoozeRoutine` (خط ~۳۰۹) یک ردیف در `routine_completions` با id `snooze_...` درج می‌کند (اسنوز نباید completion باشد).
- `ProgressionEngine.currentTargetMinutes(routine)`: اگر `progressionMode != 'NONE'` مقدارِ `progressionCurrent` را برمی‌گرداند (اگر ۰ باشد → تایمرِ صفر).
- جداول: `routine_completions(id, routineId, completionDate, completionTime, resultType, resultSource, durationMinutes, createdAt)`؛ `routine_occurrences(routine_id, date, scheduled_time, status)` (PK `(routine_id,date)`).
- مقادیرِ `resultType` پراکنده: `FULL, LIGHT, MINIMAL, SKIPPED, CANNOT_NOW, SNOOZED, DEFERRED`؛ `resultSource`: `USER, SYSTEM`. در چند فایل به‌صورت رشتهٔ خام (از جمله `insight_generation_engine.dart` که روی آن‌ها فیلتر می‌زند).
- `routine_occurrences` در `_migrateToV7` بدونِ `IF NOT EXISTS` ساخته شده (در `_createDB` هم هست).

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**R1 — منبعِ حقیقتِ واحد برای تکمیل (نقص ۱ و ۳ — مهم‌ترین).**
- `AlarmSchedulerService.completeOccurrence` را گسترش بده تا `{String resultType='FULL', int? durationMinutes}` بگیرد و `durationMinutes` را در ردیفِ completion ثبت کند (هم در مسیرِ insert هم update؛ منطقِ upsert بر اساسِ `(routineId, completionDate)` را حفظ/اضافه کن تا تکمیلِ تکراریِ همان روز ردیفِ تکراری نسازد).
- `_completeRoutine` در `routines_list_screen` را **بازنویسی کن** تا فقط `await AlarmSchedulerService.completeOccurrence(routineId, todayStr, resultType: resultType, durationMinutes: duration)` را صدا بزند، سپس SnackBar + `RitmoEvents.notifyRoutineChanged()` + `_loadData()`. منطقِ مستقیمِ نوشتن در `routine_completions` از این متد حذف شود.
- نتیجه: تیک‌زدن از لیست هم occurrence را `done` می‌کند، progression را جلو می‌برد، آلارم را کنسل و sync می‌کند — دقیقاً مثلِ مسیرِ نوتیف.

**R2 — حذفِ مقادیرِ جعلیِ ویجت (نسبت ۲).** فراخوانیِ هاردکدِ `updateWidgetSnapshot(rhythmScore: 82, currentEnergyLevel: 'medium')` را حذف کن. به‌روزرسانیِ snapshot از طریقِ `SnapshotSyncService.syncAll()` (که `completeOccurrence` صدا می‌زند و مقدارِ **واقعیِ** rhythm/energy را می‌نویسد) انجام شود. اگر `updateWidgetSnapshot` جای دیگری با مقادیرِ ثابت صدا زده می‌شود، آن‌ها را هم با مقدارِ واقعی جایگزین یا حذف کن.

**R3 — اسنوز ≠ تکمیل (نقص ۳/۷).** `_snoozeRoutine` نباید در `routine_completions` بنویسد. به‌جایش:
- occurrence را `status='snoozed'` کن و در صورتِ وجودِ یادآوریِ فعال، از `AlarmSchedulerService.snoozeReminder(...)` استفاده کن (یا آلارمِ روتین را با زمانِ جدید دوباره بچین). اگر هیچ `pending_reminder`ی نیست، فقط occurrence را snoozed و در صورتِ نیاز یک آلارمِ موقت ثبت کن.
- هیچ ردیفِ `snooze_...` در completions درج نشود.

**R4 — enum واحد برای نتیجه (نقص ۵).** فایلِ جدید `lib/core/domain/models/completion_result.dart`:
- `enum CompletionResultType { full, light, minimal, skipped, cannotNow, snoozed, deferred }` با `String get dbValue` (مقادیرِ بالا) و `static fromDb(String)`.
- `enum CompletionSource { user, system }` مشابه.
- در نقاطِ پرتکرار (completeOccurrence، _completeRoutine، insight engine filter) از این enum/ثابت‌ها استفاده کن به‌جای رشتهٔ خام. (نیازی به ریفکتورِ ۱۰۰٪ نیست؛ نقاطِ اصلیِ نوشتن/فیلتر را پوشش بده و رشته‌های خام را با `CompletionResultType.x.dbValue` جایگزین کن.)

**R5 — transaction (نقص ۶).** نوشتن‌های چندجدولیِ `completeOccurrence`/`skipOccurrence`/`snoozeReminder` را داخلِ `db.transaction((txn) async { ... })` بپیچ تا اتمیک شوند (completion + occurrence + pending_reminders + progression در یک تراکنش). فراخوانی‌های native (کنسلِ آلارم) و `syncAll` **بعد از** commitِ تراکنش انجام شوند (نه داخلِ آن). `ProgressionEngine.onCompletion(txn, ...)` با همان executorِ تراکنش صدا زده شود.

**R6 — seedِ progression (نقص ۷/۹).** در مسیرِ **ساختِ روتین** (`routine_create_flow.dart`/`routine_form_screen.dart`) وقتی `progressionMode != 'NONE'`، مطمئن شو `progressionCurrent` با `progressionStart` مقداردهی می‌شود (نه ۰). همچنین در `currentTargetMinutes`، اگر `progressionCurrent == 0 && progressionMode != 'NONE'`، به‌عنوان fallback `progressionStart` یا `targetDurationMinutes` برگردانده شود تا تایمرِ صفر رخ ندهد.

**R7 — یکدستیِ اسکیما (نقص ۸).** در `_migrateToV7` تعریفِ `routine_occurrences` را به `CREATE TABLE IF NOT EXISTS` تغییر بده (هماهنگ با بقیه). رفتار را تغییر نمی‌دهد، فقط مقاوم‌تر می‌کند.

**R8 — occurrenceهای چند‌باره در روز برای INTERVAL (نقص ۹).** برای روتین‌های `INTERVAL_HOURS` که می‌توانند چند بار در روز رخ دهند، PKِ `(routine_id, date)` کافی نیست. **حداقل**: این محدودیت را در گزارش مستند کن و یک گاردِ ساده بگذار که تکمیلِ دوم در همان روز، occurrence را خراب نکند (upsert امن). (تغییرِ PK اختیاری و پرریسک است — اگر انجام نمی‌دهی، صریحاً در گزارش بنویس که این edge-case باز است.)

**R9 — منطق در سرویس، نه ویجت (نقص ۴ — سبک، اختیاری اما توصیه‌شده).** اگر بدونِ ریسکِ زیاد ممکن است، توابعِ تکمیل/اسنوزِ منطقی را از `routines_list_screen` به یک سرویس (`RoutineActionsService` یا همان `AlarmSchedulerService`) منتقل کن و ویجت فقط صدا بزند. اگر ریسکِ رگرسیون بالاست، فقط R1/R3 را اعمال کن و این را در گزارش به‌عنوان بدهیِ باقی‌مانده ذکر کن.

**R10 — اعتبارسنجی (یک‌بار).**
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز. تست اضافه کن: (۱) تکمیل از مسیرِ لیست، `routine_occurrences.status` را `done` می‌کند و `pending_reminders` مربوط را کنسل/opened می‌کند (همگرایی با مسیرِ نوتیف)؛ (۲) اسنوز هیچ ردیفی در `routine_completions` نمی‌سازد؛ (۳) `currentTargetMinutes` برای روتینِ progression هرگز ۰ برنمی‌گرداند.
- در گزارش: تأییدِ همگراییِ دو مسیرِ تکمیل، حذفِ مقادیرِ هاردکد، نقاطِ enum‌شده، و وضعیتِ R8/R9.
