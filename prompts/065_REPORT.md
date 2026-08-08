# گزارش پرامپت ۰۶۵

## ۱. خروجی پیش‌پرواز

### ۱.۱ بررسی ۱: آیا باس فرمان از جایی dispatch می‌شود؟
یافته‌ها با `grep_search`:
تنها ارجاع به `RitmoCommandBus.instance.dispatch` در فایل زیر وجود دارد:
```
lib/features/assistant/presentation/widgets/unified_assistant_sheet.dart:245:            await RitmoCommandBus.instance.dispatch(
```
که البته هنوز در عمل به موتور دستیار سراسری متصل نشده است.

### ۱.۲ بررسی ۲: آیا پرسوناها اصلاً راه‌اندازی می‌شوند؟ و با چه ترتیبی؟
یافته‌ها با `grep_search`:
```
lib/core/di/service_locator.dart:59:    registerAllRitmoCommands();
lib/core/domain/commands/commands_registry.dart:12: void registerAllRitmoCommands() {
lib/core/domain/personas/persona_registry.dart:27:  void initStandardPersonas() {
```
تابع `initStandardPersonas` در هیچ‌کدام از کدهای اصلی یا راه‌اندازی فراخوانی نشده است (همان نقص B-10).

### ۱.۳ بررسی ۳: مسیر واقعی اجرای اکشن امروز
یافته‌ها با `grep_search`:
متد `AssistantActionRegistry.executeAction` هنوز در تمام شیت‌های اختصاصی دستیارها و داشبوردها برای اجرای کارها فراخوانی می‌شود:
```
lib/features/assistant/presentation/widgets/ai_day_planner_preview_sheet.dart:618
lib/features/assistant/presentation/widgets/ai_weekly_planner_preview_sheet.dart:112
lib/features/assistant/presentation/widgets/assistant_action_preview_sheet.dart:229
lib/features/chat/presentation/ai_chat_screen.dart:1076
lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart:613
lib/features/goals/presentation/widgets/ai_goals_assistant_sheet.dart:216
lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart:470
lib/features/supplementary_sports/presentation/ss_plan_day_detail_screen.dart:221
lib/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart:360
lib/features/today/presentation/widgets/ai_briefing_card.dart:224
lib/features/today/presentation/widgets/dashboard/assistant_card.dart:382
lib/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart:602
lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart:371
```

### ۱.۴ بررسی ۴: همهٔ شیت‌های دستیار تخصصی که هنوز زنده‌اند
فایل‌های پیدا شده:
- `lib/features/courses/presentation/widgets/ai_courses_assistant_sheet.dart`
- `lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart`
- `lib/features/goals/presentation/widgets/ai_goals_assistant_sheet.dart`
- `lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart`
- `lib/features/konkur/presentation/widgets/ai_konkur_assistant_sheet.dart`
- `lib/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart`
- `lib/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart`
- `lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart`
- `lib/features/assistant/presentation/widgets/unified_assistant_sheet.dart` (شیت یکپارچه)

### ۱.۵ بررسی ۵: اسکیمای واقعی جداول کلیدی (نقص B-02)

**جدول `goals`:**
```sql
      CREATE TABLE IF NOT EXISTS goals (
          id TEXT PRIMARY KEY,
          parentGoalId TEXT,
          title TEXT NOT NULL,
          description TEXT,
          goalType TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'ACTIVE',
          targetDate TEXT,
          progressCache REAL NOT NULL DEFAULT 0,
          isPrivate INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(parentGoalId) REFERENCES goals(id) ON DELETE CASCADE
      );
```

**جدول `bedtime_diagnostics`:**
```sql
      CREATE TABLE IF NOT EXISTS bedtime_diagnostics (
          date TEXT PRIMARY KEY,
          reason TEXT NOT NULL,
          note TEXT,
          createdAt INTEGER NOT NULL,
          bedtimeAt INTEGER,
          wakeAt INTEGER,
          durationMinutes INTEGER,
          quality INTEGER NOT NULL DEFAULT 3,
          awakenings INTEGER NOT NULL DEFAULT 0
      );
```
*توجه: فیلد `id` در این جدول وجود ندارد (کلید اصلی `date` است) و `quality` از نوع INTEGER است. کد فعلی Sleep فرمان فیلد id و رشته 'GOOD' را به عنوان quality ارسال می‌کند که باعث کرش می‌شود.*

**جدول `assistant_audit_log`:**
```sql
      CREATE TABLE IF NOT EXISTS assistant_audit_log (
          id TEXT PRIMARY KEY,
          actionType TEXT NOT NULL,
          targetKey TEXT,
          oldValue TEXT,
          newValue TEXT,
          appliedAt INTEGER NOT NULL
      );
```

**جدول `routine_schedules`:**
```sql
      CREATE TABLE routine_schedules (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          scheduleType TEXT NOT NULL,
          timeOfDay TEXT,
          anchorEvent TEXT,
          anchorOffsetMinutes INTEGER,
          windowEndAnchor TEXT,
          escalationLeadMinutes INTEGER,
          escalationPolicy TEXT NOT NULL DEFAULT 'NONE',
          daysOfWeek TEXT,
          intervalHours INTEGER,
          targetCount INTEGER,
          startDate TEXT,
          stepValueMinutes INTEGER NOT NULL DEFAULT 0,
          targetTimeOfDay TEXT,
          currentStepOffsetMinutes INTEGER NOT NULL DEFAULT 0,
          advanceAfterSuccessDays INTEGER NOT NULL DEFAULT 2,
          regressOnFailure INTEGER NOT NULL DEFAULT 1,
          recurrenceRule TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
```

### ۱.۶ بررسی ۶: نسخهٔ فعلی دیتابیس و آخرین مهاجرت ثبت‌شده
- در فایل `lib/core/database/database_helper.dart` نسخه دیتابیس برابر است با: `_dbVersion = 80`.
- در فایل `lib/core/database/migration/migration_runner.dart` آخرین کلاس مهاجرت ثبت شده `MigrationV80AiOpencodeDefaults()` است.

### ۱.۷ بررسی ۷: آیا کلید theme واقعاً وجود دارد؟
فایل `settings_registry.dart` فقط دارای دو فیلد تم است:
- `theme_mode`
- `theme_palette`
فیلد `theme` وجود ندارد که باعث ریجکت شدن دائمی تم در اکشن‌های دستیار قبلی می‌شد.

### ۱.۸ بررسی ۸: همهٔ مسیرهای ناوبری اپ
بعضی از کلاس‌های Screen کلیدی ثبت شده در اپ:
- `CalendarScreen` و `JourneyScreen`
- `CoursesScreen` و `CourseDetailScreen`
- `CycleScreen`
- `GoalsScreen`
- `HealthScreen`
- `KonkurScreen`
- `ProfileScreen` و `ThemeSettingsScreen`
- `SimpleTasksScreen`
- `StudyHomeScreen`
- `SSHomeDashboardScreen`

### ۱.۹ بررسی ۹: آیا AssistantActionType هنوز مصرف‌کننده دارد؟
بله، این enum در کدهای `ai_prompt_engine.dart`، `chat_action_parser.dart`، `chat_models.dart`، `assistant_engine.dart`، `assistant_action_registry.dart` و `assistant_models.dart` به وفور استفاده شده است.

### ۱.۱۰ بررسی ۱۰: تصادم نام CommandContext
دو کلاس با نام `CommandContext` تعریف شده‌اند:
- `lib/core/domain/commands/ritmo_command.dart` در خط ۲۷
- `lib/core/domain/execution/command_context.dart` در خط ۳
که باعث تصادم شده است.

---

## ۲. شمارهٔ مهاجرت انتخاب‌شده و دلیل
شماره مهاجرت انتخابی **۸۱** خواهد بود (`MigrationV81AgentLayer`).
**دلیل:** آخرین مهاجرت در دیتابیس نسخه ۸۰ است، بنابراین نسخه جدید ۸۱ نام‌گذاری می‌شود تا ترتیب لاجیک مهاجرت‌ها به صورت متوالی حفظ شود.

---

## ۳. جدول کاتالوگ فرمان‌ها
*(پس از اجرای مراحل فاز B این جدول تکمیل می‌شود)*

---

## ۴. اثبات اتصال
*(پس از حذف بخش‌های قدیمی و متصل کردن باس فرمان تکمیل می‌شود)*

---

## ۵. جدول diff یازده شیت قدیمی
*(پس از بازنویسی شیت‌ها و حذف موارد اضافه تکمیل می‌شود)*

---

## ۶. نتیجهٔ ۲۴ سناریوی پذیرش
*(پس از انجام آزمون‌های پذیرش روی دیتابیس شبیه‌سازی شده تکمیل می‌شود)*

---

## ۷. نتیجهٔ ۱۲ تست ضدپسرفت
*(پس از پیاده‌سازی و اجرای آزمون‌های تست تکمیل می‌شود)*

---

## ۸. تأثیر اصلاح B-16
*(پس از بازنویسی Consent Profile و رفع مشکل Consent روتین‌ها برای کاربران غیرچرخه‌ای تکمیل می‌شود)*

---

## ۹. آنچه انجام نشد و چرا
*(در انتهای اجرای پرامپت نوشته می‌شود)*

---

## ۱۰. ریسک‌های باقی‌مانده
*(در انتهای اجرای پرامپت نوشته می‌شود)*
