# 🤖 پرامپت اجرایی — «اصلاحِ بخشِ تقویم» (Calendar Consistency Fixes) — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ C1…C7 را یک‌سره تا آخر اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: تقویم به‌جای **بازپیاده‌سازیِ منطق**، از **منبعِ حقیقتِ واحد** بخواند تا روتین‌های INTERVAL درست نمایش داده شوند و نمره‌ی ریتم یکدست شود.
> پیش‌زمینه: پرامپتِ `AGENT_PROMPT_ROUTINES_FIXES.md` قبلاً اجرا شده؛ پس این‌ها **از قبل موجودند** و در این پرامپت فقط مصرف می‌شوند: `AlarmSchedulerService.completeOccurrence(routineId, dateStr, {String resultType='FULL', int? durationMinutes})` (occurrence را `done`، progression، کنسلِ آلارم، sync) و enumهای `CompletionResultType`/`CompletionSource` در `lib/core/domain/models/completion_result.dart`. صفحهٔ تقویم اما هنوز همگرا **نشده** و این پرامپت آن را هم انجام می‌دهد.

## ⛔️ قواعد (یک‌بار)
- منبعِ حقیقت: «کدوم روتین کِی رخ می‌دهد» = جدولِ `routine_occurrences` (که `RoutineOccurrenceGenerator` می‌سازد)؛ «نمره‌ی ریتمِ روز» = جدولِ `daily_rhythm`. تقویم نباید این‌ها را بازمحاسبه کند.
- منطقِ موجود را نشکن؛ خروجی صحیح، نه بازطراحیِ UI. فارسی/RTL، تقویمِ شمسی حفظ شود.
- فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.

## 📁 محیط (تأییدشده از کد) — `lib/features/calendar/presentation/calendar_screen.dart` (~۲۰۰۷ خط)
- 🐞 **تکرارِ واگرا:** `_getActiveRoutinesForDate(date)` (خط ~۱۶۱) فقط `schedule.daysOfWeek` را چک می‌کند → روتین‌های `INTERVAL_DAYS`/`INTERVAL_HOURS`/ماهانه/هفتگیِ-N **اشتباه یا اصلاً** نمایش داده نمی‌شوند. `RoutineOccurrenceGenerator.shouldOccurOnDate(date, rule)` و جدولِ `routine_occurrences` منطقِ درست را دارند.
- 🐞 **ریتمِ واگرا:** `_calculateRhythmScore(date)` (خط ~۱۹۷) با وزن‌های محلی (FULL=1.0/LIGHT=0.7/MINIMAL=0.4) دوباره حساب می‌کند؛ `daily_rhythm.rhythmScore`/`completion_ratio` منبعِ رسمی است.
- 🐞 **تعارضِ سطحی:** `_calculateConflicts` (خط ~۱۰۵) فقط `timeBased`های مجاور (i و i+1) را چک می‌کند؛ تعارضِ غیرمجاور و لنگرِ نماز و زون را نمی‌بیند.
- 🐞 **گیتِ ماژولِ ناقص:** `_isCategoryModuleEnabled` (خط ~۱۸۹) فقط religious/medical/learning؛ کنکور/بقیه و فیلترِ حریمِ چرخه اعمال نمی‌شود؛ رشته‌های category هاردکد.
- ✅ **خوب (دست نزن):** مدیریتِ تقویمِ شمسی (`shamsi_date`)، و سیستمِ `calendar_exceptions` (`_saveException`/`behavior` ∈ `NORMAL/SILENCE_ALL/ESSENTIAL_ONLY`) که با `AlarmSchedulerService` یکپارچه است.
- `routine_occurrences(routine_id, date, scheduled_time, status)`؛ `daily_rhythm(date, rhythmScore, completion_ratio, scheduledCount, successCount, ...)`.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**C1 — تکرار از منبعِ حقیقت (نقص ۲ — مهم‌ترین).** `_getActiveRoutinesForDate(date)` را بازنویسی کن:
- روشِ ترجیحی: روتین‌های فعالِ هر روز را از جدولِ `routine_occurrences` برای آن `date` بخوان (join با `routines`/`routine_schedules` برای title/time). این هم INTERVAL/ماهانه را درست نشان می‌دهد هم با بقیهٔ اپ یکدست است.
- اگر برای روزهای آینده occurrence تولید نشده، با `RoutineOccurrenceGenerator.shouldOccurOnDate(date, rule)` محاسبه کن (همان موتور، نه منطقِ daysOfWeekِ دستی). `rule` را مثلِ خودِ generator از `schedule.recurrenceRule` (JSON) یا fallbackِ `daysOfWeek` بساز.
- **منطقِ `daysOfWeek`-only را حذف کن.**

**C2 — نمره‌ی ریتم از `daily_rhythm` (نقص ۳).** `_calculateRhythmScore(date)` را طوری تغییر بده که اول از `daily_rhythm` برای آن `date` بخواند (`rhythmScore` یا `round(completion_ratio*100)`). فقط اگر ردیفی نبود (مثلاً روزِ آینده) به محاسبهٔ محلی به‌عنوان fallback برگرد — و همان وزن‌ها را در صورتِ امکان از منطقِ مشترک بگیر، نه ثابت‌های جدا. هدف: یک عددِ ریتم در کلِ اپ.

**C3 — همگراییِ تکمیل/اسنوزِ تقویم (نقص ۱/۶ — مهم).** صفحهٔ تقویم هنوز مستقیم در `routine_completions` می‌نویسد؛ همگرا کن:
- `_completeTask(Routine routine, String mode)` (خط ~۱۷۰۴) را **بازنویسی کن**: کلِ منطقِ insert/update مستقیم در `routine_completions` حذف شود و به‌جایش `await AlarmSchedulerService.completeOccurrence(routine.id, _getDateStr(_selectedDate), resultType: mode)`. سپس همان SnackBar + `_loadCalendarData()`. (دقت: `dateStr` همان روزِ انتخاب‌شدهٔ تقویم است، نه لزوماً امروز.)
- `_snoozeRoutine(routineId, minutes)` (خط ~۱۷۵۰) را **بازنویسی کن**: دیگر ردیفِ `snooze_...` در `routine_completions` درج نشود. به‌جایش occurrence را `status='snoozed'` کن و اگر `pending_reminder`ی هست از `AlarmSchedulerService.snoozeReminder(...)` استفاده کن (همان رویکردِ نسخهٔ روتین‌ها). هیچ ردیفِ completion برای اسنوز ساخته نشود.
- نتیجه: تیک/اسنوز از تقویم دقیقاً مثلِ لیست و نوتیف رفتار می‌کند (occurrence/progression/کنسلِ آلارم/sync).

**C4 — تعارضِ کامل‌تر (نقص ۴).** `_calculateConflicts` را بهبود بده:
- همهٔ جفت‌های زمان‌دار را (نه فقط مجاور) برای هم‌پوشانی چک کن (بازهٔ `[start, start+duration)` هرکدام با بقیه).
- روتین‌های لنگرِ نماز (`anchorEvent`/`anchorOffsetMinutes`) را در صورتِ وجودِ زمانِ حل‌شده لحاظ کن (اگر زمانِ نماز در دست نیست، نادیده بگیر اما crash نکن).
- خروجی همان ساختارِ فعلی؛ فقط پوششِ بیشتر. از O(n²) ساده استفاده کن (تعدادِ روتینِ روز کم است).

**C5 — گیتِ ماژول کامل (نقص ۵).** `_isCategoryModuleEnabled` را کامل کن: همهٔ ماژول‌ها (`konkur`, `goals`, …) را پوشش بده، از همان منطقِ مرکزیِ پرچمِ ماژول که جای دیگرِ اپ استفاده می‌شود (مثلِ `NotificationDecider._isModuleEnabled` یا معادلِ آن) بهره بگیر تا تکرار نشود، و **فیلترِ حریمِ چرخه** را اعمال کن (روتین‌های مرتبط با چرخه فقط طبقِ `CyclePrivacyGuard`/تنظیماتِ مربوط نمایش داده شوند). رشته‌های category را با همان enum/منبعِ موجود جایگزین کن.

**C6 — magic strings (نقص ۷).** enumِ `CompletionResultType` (در `lib/core/domain/models/completion_result.dart`) از قبل موجود است؛ در `_calculateRhythmScore` و هر جای تقویم به‌جای `'FULL'`/`'LIGHT'`/`'MINIMAL'` از `CompletionResultType.x.dbValue` (یا `fromDb`) استفاده کن.

**C7 — اعتبارسنجی (یک‌بار).**
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز. تست اضافه کن: (۱) یک روتینِ `INTERVAL_DAYS=25` در تاریخِ درست روی تقویم «فعال» تشخیص داده شود و در روزهای بینابین نه؛ (۲) نمره‌ی ریتمِ یک روز با مقدارِ `daily_rhythm` همان روز یکی باشد؛ (۳) تکمیل از تقویم `routine_occurrences.status` را `done` می‌کند و اسنوز هیچ ردیفِ completion نمی‌سازد.
- در گزارش: تأییدِ نمایشِ درستِ روتین‌های INTERVAL، یکدستیِ نمره‌ی ریتم، و همگراییِ تکمیل/اسنوزِ تقویم با مسیرِ مرکزی.
