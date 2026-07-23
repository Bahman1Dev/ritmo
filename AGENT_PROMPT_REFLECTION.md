# 🤖 پرامپت اجرایی — سیستم «خودارزیابی و بازتاب» (Reflection) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. کلِ صفِ R1 تا R11 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: ارتقای خودارزیابی از یک شیتِ فقط‌نوشتنی به **صفحه‌ی کاملِ ژورنالینگ** — ثبتِ ساختاریافته + تایم‌لاینِ یکپارچه‌ی روز + استریک/روند + همبستگی + دستیار.
> سندِ طراحی: `DESIGN_SYSTEM_REFLECTION.md`. فایلِ اصلیِ جدید: `lib/features/reflection/presentation/reflection_screen.dart`.

## ⛔️ قواعد (یک‌بار)
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (`shamsi_date`؛ ذخیره ISO/epoch، نمایش شمسی). l10n جدید به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ `RitmoTheme`/`context.colors`. رنگِ پایه: فیروزه‌ای `#06B6D4`.
- لحنِ تشویقی و بدونِ قضاوت؛ روزِ بد «شکست» نیست؛ تأملِ ازدست‌رفته سرزنش نمی‌شود.
- داده‌ی دیتابیس تستی است؛ ستون‌های جدید nullable/با `DEFAULT`.
- فقط فایل‌های مرتبطِ هر تسک. ابهامِ واقعی → بپرس.
- **`morning_checkin_sheet` و پلِ انرژیِ آن (`energy_logs`/`default_energy_level`) را نشکن** و `daily_checkins`/`mood_logs` را تغییر نده. تأمل فقط از آن‌ها می‌خواند.
- AI هرگز مستقیم در DB نمی‌نویسد (Preview→Edit→Save).

## 🔒 تصمیم‌های قطعی
1. **مربیِ کاملِ تأمل:** صفحه + ثبتِ ساختاریافته + تاریخچه + استریک/روند + همبستگی + دستیار.
2. **پرسش‌های ساختاریافته (همه اختیاری):** حال + بردِ امروز + شکرگزاری + چالش + درس + تمرکزِ فردا.
3. **ژورنالِ یکپارچه‌ی روز:** چک‌اینِ صبح + تأملِ عصر در یک تایم‌لاین؛ چک‌اینِ صبح همچنان به انرژی پل می‌خورد.
4. **اتصالِ حالِ تأمل به تحلیلِ انرژی/حال بدونِ تکرار:** فقط‌خواندنی در همبستگی؛ هیچ نوشتنِ تکراری در `mood_logs`.

## 📁 محیط (تأییدشده از کد)
- DB SQLite، نسخه‌ی فعلی را از `database_helper.dart` بخوان؛ مهاجرت = **فعلی+۱** (`_migrateToVNN` + `if (oldVersion < NN)` + هم‌تراز در `_createDB`). `_safeAddColumn(db, table, column, typeDef)` موجود است.
- `daily_reflections (id PK, date UNIQUE, goodThing, reflectionNote, mood_score INTEGER, reflection_text, learnings, timestamp, createdAt)` — V2/V6.
- `daily_checkins (id PK, date UNIQUE, mood, note, createdAt)` — V2. منبعِ صبح.
- `morning_checkin_sheet.dart` → می‌نویسد در `daily_checkins` + `energy_logs` + `default_energy_level`. **دست‌نخورده بماند.**
- `daily_reflection_sheet.dart` → می‌نویسد در `daily_reflections` با `INSERT OR REPLACE` روی `date`.
- `energy_logs`, `mood_logs` (V17) — فقط برای خواندنِ همبستگی.
- کاشیِ هاب «خودارزیابی و بازتاب» در `systems_hub_screen.dart` (~خط ۳۶۰): `square_list_fill`, `#06B6D4`, `ModuleStatus.active`، الان `DailyReflectionSheet` را باز می‌کند. باید `ReflectionScreen` را باز کند (بدونِ گیتِ فعال‌سازی).
- بنرهای داشبورد در `now_dashboard_screen.dart` (~خط ۲۹۲۰ چک‌این، ~۳۰۷۴ تأمل) و `dashboard_controller.dart` (`hasReflection`/`needCheckin`) — نشکنند.
- الگوی موتور: `CachedEngine` (calculate/invalidate/canRun/dependencies) + `RitmoEngineBus`. مرجع: `lib/core/analytics/courses_engine.dart`.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**R1 — مهاجرت.** نسخه فعلی+۱. با `_safeAddColumn` به `daily_reflections` اضافه کن: `gratitude TEXT`, `wins TEXT`, `challenges TEXT`, `tomorrowFocus TEXT`. تنظیماتِ جدید با `INSERT OR IGNORE`: `reflection_reminder_enabled='true'`, `reflection_prompt_style='structured'`. جدولِ جدید لازم نیست؛ ماژول‌فلگِ جدید نساز.

**R2 — مدل‌ها** (`lib/features/reflection/models/reflection_models.dart`):
- `ReflectionEntry {date, moodScore, reflectionText, learnings, gratitude, wins, challenges, tomorrowFocus, createdAt}` (toMap/fromMap روی `daily_reflections`؛ نگاشتِ ستون‌های قدیمی حفظ شود).
- `CheckinEntry {date, mood, note}` (نمای fromMap روی `daily_checkins`).
- `JournalDay {dateIso, CheckinEntry? checkin, ReflectionEntry? reflection}` (برای تایم‌لاینِ یکپارچه).
- `ReflectionStats {currentStreak, longestStreak, entryCount, completionRate, avgMoodScore}` و `ReflectionCorrelation {metric, coefficient(double?), insight}`.

**R3 — موتورِ تأمل** (`lib/core/analytics/reflection_engine.dart`, `CachedEngine`):
- ورودی: `daily_reflections`, `daily_checkins`, `energy_logs`, `mood_logs`, `today`, `horizonDays`.
- خروجی: `currentStreak`/`longestStreak`، `entryCount`/`completionRate`، `avgMoodScore`، `moodTrend`، `themeFrequency` (واژگانِ پرتکرارِ متن، سبک)، `reflectionEnergyCorrelation`/`reflectionMoodCorrelation` (در [-1..1]، اگر داده کم بود null) + `correlationInsight`.
- منطقِ خالص (استریک/همبستگی) در helperِ تست‌پذیر. **فقط‌خواندنی.**
- تست: استریک (پیوسته/گسسته)، همبستگیِ مثبت/منفی/کم‌داده.

**R4 — شیتِ ثبتِ ساختاریافته** (بازنویسیِ `daily_reflection_sheet.dart` یا `widgets/reflection_entry_sheet.dart`): حال (۱..۵ ایموجی) + فیلدهای **اختیاری**: بردِ امروز، شکرگزاری، چالش، درسِ آموخته، تمرکزِ فردا + تأملِ آزاد. ذخیره در `daily_reflections` (ستون‌های جدید + قدیمی، `INSERT OR REPLACE` روی `date`). `onSaved` واقعی برای تازه‌سازی.

**R5 — تایم‌لاینِ یکپارچه‌ی روز** (`widgets/journal_timeline_section.dart`): از `daily_checkins` + `daily_reflections` فهرستِ `JournalDay`؛ هر روز یک کارت با چک‌اینِ صبح + تأملِ عصر؛ تپ → دیدن/ویرایش (بازکردنِ شیتِ R4 پیش‌پُر). حالتِ خالیِ تشویقی.

**R6 — هیرو + استریک** (`widgets/reflection_hero.dart`): وضعیتِ امروز (چک‌این/تأمل انجام شد؟) + نشانِ استریک از موتور + دکمه‌ی «ثبتِ تأملِ امروز»؛ اگر صبح است و چک‌این نشده، میان‌برِ `MorningCheckinSheet` (همان شیتِ موجود، نشکن).

**R7 — تبِ روند** (`widgets/reflection_trends_section.dart`): نمودارِ سادهٔ `mood_score` در چند هفته (CustomPainter، بدونِ پکیجِ جدید) + استریک + نرخِ تکمیل + پربسامدترین درس‌ها/تم‌ها.

**R8 — بخشِ همبستگی** (`widgets/reflection_correlation_section.dart`): `reflectionEnergyCorrelation`/`reflectionMoodCorrelation` + `correlationInsight` (صادق، غیرقطعیِ علّی). «روزهایی که تأمل می‌کنی، حالت معمولاً بهتره».

**R9 — مونتاژ + هاب** (`reflection_screen.dart` + `systems_hub_screen.dart`): Scaffold+rtl، هدر «خودارزیابی و بازتاب»+[🤖]، `RefreshIndicator`، هیرو + تب‌ها (امروز·تاریخچه·روند) + FABِ ثبت. در هاب: تپِ کاشی را از `DailyReflectionSheet` به `Navigator.push(ReflectionScreen())` تغییر بده (وضعیت «فعال» بماند، بدونِ گیت). بنرهای داشبورد نشکنند.

**R10 — دستیارِ AI** (`widgets/ai_reflection_assistant_sheet.dart`): دکمه‌ی 🤖. **پرسشِ پویای تأمل** بر اساسِ انرژی/رویدادِ امروز + خلاصه‌ی ملایمِ الگوها. از `AIGateway` موجود. Preview→Edit→Save برای هر پیشنهادِ قابلِ‌اعمال؛ بدونِ نوشتنِ کور.

**R11 — پایان.** مطمئن شو حالِ تأمل فقط‌خواندنی در همبستگی استفاده می‌شود و **هیچ نوشتنِ تکراری در `mood_logs`** نیست. پلِ انرژیِ چک‌اینِ صبح سالم است. اگر چیزی تغییر کرد `DESIGN_SYSTEM_REFLECTION.md` را به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: موتورِ تأمل (استریک/روند/همبستگی/کم‌داده)، مهاجرتِ نصبِ‌تازه≡ارتقا، ثبتِ ساختاریافته (نوشتن/خواندنِ ستون‌های جدید + قدیمی).
- دستی: بازکردنِ صفحه از هاب → ثبتِ تأملِ ساختاریافته → تایم‌لاینِ یکپارچه (صبح+عصر) → استریک/روند/همبستگی → سالم‌بودنِ پلِ انرژیِ چک‌اینِ صبح → نبودِ رکوردِ تکراریِ `mood_logs`.

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی R1..R11: ...
- نسخه‌ی مهاجرت: ...
- flutter analyze / flutter test: ...
- بازبینیِ عدمِ‌تکرارِ mood_logs + سلامتِ پلِ انرژی: ...
- ابهامات: ...
```
