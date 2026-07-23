# 🤖 پرامپت اجرایی — سیستم «اهداف و برنامه‌ها» (Goals & Plans) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. کلِ صفِ تسک‌ها را **یک‌سره تا آخر** اجرا کن؛ نیازی به تأییدِ میان‌راهی نیست. در پایان یک‌بار اعتبارسنجی کن و گزارشِ نهایی بده.
> هدف: ارتقای ماژولِ اهداف از یک شیتِ دفن‌شده به صفحه‌ی کامل — درختِ اهداف با مهلت/روزشمار، تایم‌لاینِ برنامه‌ی کل‌نگر، زنده‌کردنِ پلِ روتین↔گام، آرشیو، و اتصالِ واقعی به هاب.
> سندِ طراحی: `DESIGN_SYSTEM_GOALS.md`. فایلِ اصلیِ جدید: `lib/features/goals/presentation/goals_screen.dart`.

## ⛔️ قواعد (یک‌بار گفته می‌شوند)
- فارسی/RTL، فونت `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (پکیجِ `shamsi_date`؛ ذخیره ISO `YYYY-MM-DD`، نمایش شمسی). کلیدهای جدیدِ l10n به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ از `RitmoTheme`/`context.colors`. رنگِ پایه: کهربایی `#F59E0B`.
- لحنِ تشویقی؛ عقب‌افتادگی هرگز سرزنش نشود. روزشمار آرام.
- داده‌ی دیتابیس تستی است؛ حفظِ رکورد مهم نیست، ستون‌های جدید با `DEFAULT`.
- منطقِ موجودِ `goals_management_sheet.dart` را **بازاستفاده/استخراج کن، نه بازنویسی** (CRUD، خرد کردن با AI، پیش‌نمایشِ قابلِ‌ویرایش از قبل کار می‌کنند). داشبورد و breakdown نباید بشکنند.
- فقط فایل‌های مرتبطِ هر تسک را تغییر بده. ابهامِ واقعی → بپرس.

## 🔒 تصمیم‌های قطعی
1. **«برنامه‌ها» = تایم‌لاینِ کل‌نگر** که گام‌های هدف + جلساتِ دوره‌ها (`course_sessions.plannedDate`) + آیتم‌های کنکور (`konkur_plan_items.dateIso`) را در افقِ «این هفته/بعد + عقب‌افتاده» تجمیع می‌کند. فقط-خواندنی؛ هر آیتم به مبدأ لینک می‌دهد. **هیچ منبعِ چرخه‌ای نیاید.**
2. **پلِ روتین↔گام = پیشرفت‌دهی، بدون تیکِ خودکار.** انجامِ روتینِ متصل فقط آمار/نمایش را تغذیه می‌کند؛ `goal_steps.isCompleted` هرگز خودکار ۱ نشود.
3. **مهلت = روزشمارِ آرام + برجسته‌کردنِ گامِ عقب‌افتاده.**
4. **پیشرفتِ هدف مشتق است** (بی‌فرزند: گام‌های تیک‌خورده/کل؛ والد: میانگینِ بازگشتیِ فرزندان). در `routine_completions`/`daily_rhythm` ننویس.
5. **AI فقط دستیار:** Preview→Edit→Save (منطقِ موجود حفظ شود).

## 📁 محیط (تأییدشده از کد)
- دیتابیس SQLite؛ نسخه‌ی فعلی را از `database_helper.dart` بخوان و مهاجرت = فعلی+۱ (انتظار v16). از `_safeAddColumn` موجود استفاده کن؛ همان تغییر در `_createDB` و `onUpgrade`.
- `goals (id, parentGoalId, title, description, goalType[ANNUAL/MONTHLY/WEEKLY/DAILY], status[ACTIVE/COMPLETED], targetDate, createdAt, updatedAt)` — `targetDate` فعلاً بلااستفاده.
- `goal_steps (id, goalId, title, isCompleted, displayOrder, createdAt, scheduledDate, linkedRoutineId)` — `linkedRoutineId` ست می‌شود ولی مصرف نمی‌شود.
- `goals_management_sheet.dart` → `AIGateway.instance.breakDownGoal(...)`، tree، editable preview.
- `systems_hub_screen.dart` → کاشیِ اهداف الان `_showComingSoonSheet` با `customText:'به‌زودی'` است؛ باید مثل `_handleKonkurTap` به صفحه + شیتِ فعال‌سازی (`module_goals_enabled`) وصل شود.
- `now_dashboard_screen.dart` → گام‌های `scheduledDate==today` را با `JOIN goals` کوئری می‌کند (پشتِ `module_goals_enabled`)؛ نشکن.
- `CachedEngine` (calculate/invalidate/canRun/dependencies) + `RitmoEngineBus` — مرجع: `lib/core/analytics/courses_engine.dart`.
- مسیرِ تکمیلِ روتین که `ProgressionEngine().onCompletion(db, routineId)` در آن صدا زده می‌شود = نقطه‌ی قلابِ G5 (فقط تکمیلِ موفق، نه snooze/skip).

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم، بدون توقف)

**G1 — مهاجرت.** نسخه را +۱ کن، `_migrateToVNN` + `if (oldVersion < NN)`، و در `_createDB` هم‌تراز کن. تنها ستون:
`ALTER TABLE goals ADD COLUMN progressCache REAL NOT NULL DEFAULT 0;` (با `_safeAddColumn`). جدول/تنظیماتِ جدید لازم نیست؛ فقط مطمئن شو `module_goals_enabled` در seed هست (اگر نه، `INSERT OR IGNORE`).

**G2 — مدل‌ها** (`lib/features/goals/models/goal_models.dart`): `enum GoalLevel`+label؛ `Goal` (toMap/fromMap، `isOverdue`، `daysUntilTarget`)؛ `GoalStep` (toMap/fromMap، `isOverdue`، `hasLinkedRoutine`)؛ `enum TimelineSource{goalStep,courseSession,konkurPlan}`+icon/label؛ `TimelineItem(dateIso,title,source,sourceId,isDone,subtitle)`.

**G3 — محاسبه‌ی پیشرفت** (`lib/features/goals/logic/goal_progress_calculator.dart`، خالص): `double goalProgress(goalId, allGoals, stepsByGoal)` — والد: میانگینِ بازگشتیِ فرزندان؛ بی‌فرزند: تیک‌خورده/کل (بدونِ گام و COMPLETED→۱)؛ با مجموعه‌ی `visited` برای جلوگیری از حلقه.

**G4 — موتور** (`lib/core/analytics/goals_engine.dart`، مثل `courses_engine.dart`): ورودی goals/stepsByGoal/courseSessions/konkurPlanItems/routineCompletionStats/today/horizonDays. خروجی: `goalProgress`, `todaySteps`, `upcomingTimeline` (تجمیعِ سه منبع در افق، مرتب با تاریخ، بدونِ چرخه)، `overdueSteps`, `linkedRoutineStatus`(stepId→doneCount/streak)، `activeGoalsCount`, `completedGoalsCount`.

**G5 — پلِ روتین↔گام.** در نقطه‌ی `ProgressionEngine().onCompletion` (پس از تکمیلِ موفق)، اگر گامی `linkedRoutineId==routineId` دارد، موتور را invalidate کن تا UI تازه شود. `linkedRoutineStatus` به‌صورتِ زنده از `routine_completions` محاسبه شود. `isCompleted` را دست نزن. snooze/skip اثری ندارد.

**G6 — صفحه + استخراجِ منطق** (`lib/features/goals/presentation/goals_screen.dart`): Scaffold+rtl، هدر «اهداف و برنامه‌ها»+[🤖]+[＋ هدف]، `RefreshIndicator`، هیرو («X هدفِ فعال · Y گامِ این هفته» + نزدیک‌ترین مهلت)، تب‌ها: اهداف·تایم‌لاین·آرشیو. منطقِ CRUD/AI را از شیت به helper/کنترلرِ مشترک منتقل کن (رفتار نشکند). فرمِ ساخت/ویرایش: تاریخِ شمسی، `targetDate`، انتخابِ روتینِ متصل.

**G7 — تبِ اهداف** (`widgets/goals_tree_section.dart`): نمای درختیِ موجود + روزشمارِ `targetDate` (آرام؛ گذشته→تشویقی)، نوارِ پیشرفتِ مشتق از موتور، badgeِ گامِ عقب‌افتاده، چیپِ روتینِ متصل (نام+استریک، تپ→بازکردنِ روتین، تیکِ گام دستی)، تاریخِ شمسی.

**G8 — تبِ تایم‌لاین** (`widgets/goals_timeline_section.dart`): از `upcomingTimeline`+`overdueSteps`؛ گروه‌بندیِ روزانه (عقب‌افتاده بالا→امروز→فردا→...)، آیکنِ مبدأ+عنوان، تپ→ناوبری به مبدأ، حالتِ خالی، بدونِ چرخه.

**G9 — تبِ آرشیو** (`widgets/goals_archive_section.dart`): اهدافِ COMPLETED با 🏆+تاریخِ شمسی+«X گام»، بازگردانی/حذف، جدا از تبِ فعال.

**G10 — اتصال به هاب** (`systems_hub_screen.dart`): کاشیِ اهداف را از «به‌زودی» به الگوی ماژول (مثل `_handleKonkurTap`) ببر — importِ `GoalsScreen`، حذفِ `_showComingSoonSheet`/`customText`، اگر `module_goals_enabled` → push، وگرنه `_showActivationSheet(settingKey:'module_goals_enabled')`. وضعیتِ کاشی را از وجودِ هدف تعیین کن.

**G11 — پایان.** استخراجِ شیت اگر بلااستفاده شد یا حذف یا به کنترلرِ مشترک وصل (نشکند). اگر چیزی در طراحی تغییر کرد `DESIGN_SYSTEM_GOALS.md` را به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار، در پایان)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: محاسبه‌ی پیشرفتِ بازگشتی (+حلقه)، تجمیعِ تایم‌لاین، عقب‌افتادگی، پلِ روتین (عدمِ تیکِ خودکار)، مهاجرتِ نصبِ‌تازه≡ارتقا.
- دستی: فعال‌سازی از هاب → ساختِ هدفِ چندسطحی + خرد کردن با AI → روزشمار/عقب‌افتاده → تایم‌لاینِ سه‌منبعی → زنده‌شدنِ کارتِ «قدم امروز»ِ داشبورد.

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی هر تسک G1..G11: ...
- نسخه‌ی مهاجرت: ...
- flutter analyze: [نتیجه]
- flutter test: [N passed, M failed]
- ابهامات/نکات: ...
```
