# 🤖 پرامپت اجرایی — صفحه‌ی «دوره‌های آموزشی» (Courses) — برای Gemini 3.5 Flash

> فایل **خودبسنده**. کل آن را عیناً به Gemini بده. هدف: ارتقای ماژول دوره‌ها از یک Bottom Sheet ساده به یک صفحه‌ی کامل با زمان‌بندی ریتمیک، تایمر مطالعه، اتصال به انرژی/اهداف، تب دستاوردها و دستیار AI.
> فایل اصلی جدید: `lib/features/courses/presentation/courses_screen.dart`

---

## ⛔️ قوانین سخت
1. **هر بار فقط یک تسک.** بعد از هر تسک `flutter analyze` و `flutter test` اجرا و گزارش کن. error/تست شکست‌خورده‌ی جدید → برگردان و گزارش بده.
2. **فقط فایل‌های نام‌برده‌ی هر تسک را تغییر بده.** ریفکتور نامرتبط ممنوع.
3. **متن‌ها فارسی و RTL.** فونت `Vazirmatn`. ارقام فارسی. کلیدهای جدید l10n به `app_fa.arb` و `app_en.arb`.
4. **رنگ/اندازه/رادیوس هاردکد نکن** — از `RitmoTheme` و `context.colors` استفاده کن. (رنگ پایه‌ی دوره‌ها: آبی `#3B82F6`.)
5. **لحن تشویقی.** برای عقب‌افتادگی هرگز سرزنش؛ «۲ روز عقبی، جبران می‌کنی 💪» نه «شکست خوردی».
6. **تسک C1 (مهاجرت) حساس است:** بعد از آن توقف کن و منتظر تأیید انسانی بمان.
7. **داده‌ی موجود را خراب نکن.** دوره‌ها/جلسات قبلی باید با ستون‌های جدید (مقدار پیش‌فرض) سالم بمانند.
8. چیزی مبهم بود → بپرس، حدس نزن.

## 📁 محیط پروژه
- Flutter، ریشه `ritmo/`. دیتابیس SQLite، نسخه‌ی فعلی **۱۲** (در `database_helper.dart`).
- جدول موجود `courses` (id, title, totalSessions, sessionDurationMinutes, activityType, zoneId, isArchived, energyRule, createdAt, updatedAt).
- جدول موجود `course_sessions` (id, courseId, sessionNumber, plannedDate, completionStatus, actualDurationMinutes, note, createdAt, updatedAt).
- ویجت موجود `lib/features/today/presentation/widgets/education_management_sheet.dart` — منطق CRUD آن مرجع است (دوباره‌نویسی نکن؛ منطق ذخیره/تیک را از آن وام بگیر).
- `systems_hub_screen.dart` — کاشی «دوره‌های آموزشی» الان `_showComingSoonSheet(...)` صدا می‌زند؛ باید مثل دارو/کنکور به صفحه‌ی واقعی + شیت فعال‌سازی وصل شود (`module_courses_enabled`).
- `RitmoEngineBus` + الگوی `CachedEngine` — مرجع صحیح: `lib/features/today/presentation/insights_screen.dart`.
- `alarm_scheduler_service` — برای یادآوری جلسات.
- **یادآوری جلسات (مهم):** جدول `pending_reminders` از قبل ستون `courseSessionId` (FK به `course_sessions`) دارد — زیرساخت یادآوری دوره از قبل پیش‌بینی شده. ⚠️ اما `pending_reminders.routineId` با `NOT NULL` تعریف شده، پس برای یادآوری جلسه‌ی دوره باید این گیر را حل کنی. در PASS 0 بررسی و گزارش کن `alarm_scheduler_service` چطور رکورد می‌سازد، و راهکار را (یکی از این‌ها) پیشنهاد بده: (الف) مهاجرت `routineId` به nullable، یا (ب) مسیر زمان‌بندی مجزا برای دوره‌ها. **بدون تأیید انسانی هیچ‌کدام را پیاده نکن.**
- `EnergyAnalyticsEngine` / `energy_logs` — برای انرژی فعلی.
- جدول `goals` (id, parentGoalId, title, ...) و `goal_steps` — برای اتصال هدف.

## 🔒 تصمیم‌های قطعی (تغییر نده)
1. **نوع دوره:** `VIDEO`(جلسه) / `BOOK`(فصل) / `SKILL`(تمرین) / `CUSTOM`(برچسب دلخواه). برچسب واحد همه‌جا استفاده شود.
2. **زمان‌بندی ریتمیک:** «هفته‌ای N جلسه» + روزهای ترجیحی → پخش خودکار `plannedDate` روی واحدهای PENDING + یادآوری. تاریخ دستی هم در جزئیات ممکن است.
3. **دوره‌ها به `routines` اضافه نمی‌شوند.** زمان‌بندی مستقل در `course_sessions.plannedDate`.
4. **تب تکمیل‌شده‌ها** با مدال 🏆 + آمار کل (ساعت/مدت).
5. **تایمر مطالعه اختیاری؛** «انجام» مستقل هم کار می‌کند.
6. **اتصال‌ها:** انرژی (کارت جلسه‌ی امروز) + اهداف (یک‌طرفه، فقط تغذیه‌ی درصد) + داشبورد امروز (hook) + AI.

## 🧭 تصمیم‌های معماری قطعی (بسیار مهم — هرگز نقض نشود)
- **منبع Completion دوره‌ها = فقط `course_sessions.completionStatus`.** هرگز در `routine_completions` (FK به `routines` دارد) یا `daily_rhythm` (تجمیع روتین‌هاست) نوشته نشود. آمار دوره‌ها مستقل محاسبه می‌شود.
- **اتصال به Goals یک‌طرفه است (Course → Goal، فقط اطلاع‌رسانی).** تکمیل جلسه یا حتی تکمیل کل دوره **هرگز** نباید `goal_steps.isCompleted` را خودکار `1` کند. تنها کاری که مجاز است: نمایش/تغذیه‌ی درصد پیشرفت دوره در UI هدف. مثال خطرناکی که باید جلوگیری شود: هدف «قبولی ارشد» / قدم «مطالعه فصل ۵» — اتمام یک جلسه‌ی دوره نباید آن قدم را ببندد.
- **AI هرگز مستقیم به DB نمی‌نویسد.** هر خروجی AI باید از مسیر `AI Suggestion → Preview → User Edit → Save` عبور کند. اعمال کور ممنوع.
- **`weeklyTargetSessions` فعلاً ثابت است،** اما ستون `isAdaptive` از همین حالا در schema اضافه می‌شود (پیش‌فرض 0، فعلاً بلااستفاده) تا بعداً تطبیق هوشمند با انرژی/دارو/رمضان ممکن شود.

---

# 🗂 صف تسک‌ها

> **ترتیب اجرا (مهم):** PASS 0 → C1 → C2 → C3 → C4 → C12(اسکلت) → C10 → C9 → C6 → C8 → C7 → C11 → C5 → C14 → **C13 (AI، آخرین مرحله)**.
> منطق: اول قابلیت اصلی کامل و آزموده کار کند، بعد AI رویش سوار شود. AI از وسط پروژه برداشته شده و تقریباً آخر است.

## ▣ PASS 0 — ممیزی وضعیت موجود (بدون تغییر کد) 🔍
**هدف:** قبل از هر کدنویسی، جریان فعلی را مستند کن تا تصمیم‌ها روی واقعیت کد بنا شوند.
**اقدام (فقط خواندن و گزارش — NO CODE CHANGES):**
1. `education_management_sheet.dart` را بخوان: جریان فعلی ساخت دوره/جلسه و تیک زدن چیست؟
2. جدول `course_sessions` را بررسی کن: مقادیر فعلی `completionStatus` چیست؟ (`PENDING`/`COMPLETED`/...).
3. جدول `routine_completions` و `daily_rhythm` را بررسی کن: آیا هیچ‌جا جلسه‌ی دوره در آن‌ها ثبت می‌شود؟ (انتظار: خیر).
4. جست‌وجو کن آیا داشبورد امروز یا یادآوری فعلاً به `course_sessions` قلاب (hook) دارد؟
5. `alarm_scheduler_service` و جدول `pending_reminders` را بررسی کن: چطور رکورد یادآوری ساخته می‌شود؟ آیا `routineId` (که `NOT NULL` است) مانع ثبت یادآوری برای جلسه‌ی دوره می‌شود؟ راهکار پیشنهاد بده (nullable کردن `routineId` یا مسیر مجزا) — **بدون پیاده‌سازی**.
**گزارش بده:**
```
- جریان completion فعلی: ...
- مقادیر status موجود: ...
- قلاب‌های داشبورد موجود: ...
- قلاب‌های یادآوری موجود (courseSessionId): ...
- گیر routineId NOT NULL + راهکار پیشنهادی: ...
- تأیید: منبع completion دوره‌ها = course_sessions (بله/خیر + دلیل)
```
**تأیید:** فقط گزارش متنی. **توقف کن و منتظر تأیید انسانی بمان.** (هیچ فایلی تغییر نکند.)

## ▣ تسک C1 — مهاجرت دیتابیس 🔴
**فایل:** `lib/core/database/database_helper.dart`
**اقدام:** نسخه را ۱۲ → **۱۳** کن. تابع `_migrateToV13(db)` بساز و در `onUpgrade` با `if (oldVersion < 13)` صدا بزن. همان ستون‌ها را در `_createDB` (تعریف اولیه‌ی `courses`/`course_sessions`) هم اضافه کن تا نصب تازه و ارتقا یکسان شوند.

ستون‌های جدید `courses` (همه با `ALTER TABLE courses ADD COLUMN`):
```sql
courseType TEXT NOT NULL DEFAULT 'VIDEO'    -- VIDEO/BOOK/SKILL/CUSTOM
unitLabel TEXT                              -- برچسب واحد دلخواه (برای CUSTOM)
emoji TEXT                                  -- ایموجی دوره
colorHex TEXT                               -- رنگ دوره
provider TEXT                               -- منبع (یودمی/فرادرس/...)، اختیاری
weeklyTargetSessions INTEGER NOT NULL DEFAULT 3
isAdaptive INTEGER NOT NULL DEFAULT 0       -- آماده برای تطبیق هوشمند آینده؛ فعلاً بلااستفاده
preferredDays TEXT                          -- CSV روزهای هفته مثل '6,1,3' (شنبه=6...)
preferredTime TEXT                          -- 'HH:mm'
reminderEnabled INTEGER NOT NULL DEFAULT 0
linkedGoalId TEXT                           -- → goals(id)
status TEXT NOT NULL DEFAULT 'ACTIVE'       -- ACTIVE/COMPLETED/PAUSED
completedAt INTEGER
targetEndDate TEXT                          -- مهلت دلخواه (اختیاری)
```
ستون جدید `course_sessions`:
```sql
sessionTitle TEXT                           -- نام واحد اختیاری (مثل نام فصل)
```
نکته: `ALTER TABLE ... ADD COLUMN` با `FOREIGN KEY` در SQLite کار نمی‌کند؛ `linkedGoalId` را بدون قید FK اضافه کن (در کد به‌صورت منطقی هندل می‌شود). seed: `app_settings` رکورد `module_courses_enabled` را دست نزن (پیش‌فرض غیرفعال می‌ماند تا کاربر فعال کند).
**تأیید:** مهاجرت روی دیتابیس قدیمی پاس؛ دوره‌های قبلی سالم. **توقف کن و منتظر تأیید انسانی بمان.**

## ▣ تسک C2 — مدل‌های داده
**فایل جدید:** `lib/features/courses/models/course_models.dart`
**اقدام:**
- `enum CourseType { video, book, skill, custom }` + اکستنشن `unitLabel` (جلسه/فصل/تمرین/دلخواه) و `emoji`/`label` فارسی.
- `Course` — `toMap()`/`fromMap()`، گتر `progressPercent`، `isBehindSchedule`، `unitLabelResolved` (اگر CUSTOM از `unitLabel`).
- `CourseSession` — `toMap()`/`fromMap()`، `isCompleted`، `isScheduledToday`، `isOverdue`.
- `CourseStatus` ثابت‌ها (ACTIVE/COMPLETED/PAUSED).
**تأیید:** analyze/test سبز.

## ▣ تسک C3 — موتور زمان‌بندی ریتمیک
**فایل جدید:** `lib/features/courses/logic/course_scheduler.dart`
**اقدام:** کلاس خالص (بدون I/O، تست‌پذیر):
- `List<DateTime> distributeSessions({required int pendingCount, required DateTime from, required int weeklyTarget, required List<int> preferredDays})` — تاریخ‌ها را روی روزهای ترجیحی پخش می‌کند تا سقف هفتگی، سپس هفته‌ی بعد. اگر `preferredDays` خالی بود، روزهای متوالی.
- `int daysBehind({required List<CourseSession> sessions, required DateTime today})` — تعداد واحدهای PENDING با `plannedDate < today`.
- `DateTime? estimatedEndDate({required int remaining, required int weeklyTarget, required DateTime from})`.
**تأیید:** تست واحد برای پخش (مثلاً ۷ واحد، هفته‌ای ۳، روزهای [۶,۱,۳]) + عقب‌افتادگی؛ analyze/test سبز.

## ▣ تسک C4 — موتور تحلیل (CachedEngine)
**فایل جدید:** `lib/core/analytics/courses_engine.dart`
**اقدام:** `CoursesEngine implements CachedEngine<CoursesEngineInput, CoursesEngineOutput>` مطابق الگوی موتورهای موجود.
- ورودی: `courses`, `sessions`, `currentEnergyLevel`, `today`.
- خروجی: `weeklyDoneSessions`, `weeklyTargetSessions`, `weeklyStudyMinutes`, `studyStreakDays`, `behindSchedule` (Map<courseId,int>), `todaySessions`, `estimatedEnd` (Map<courseId,DateTime?>).
- از `course_scheduler.dart` برای محاسبات استفاده کن.
**تأیید:** تست واحد خروجی‌ها؛ analyze/test سبز.

## ▣ تسک C5 — کارت Hero هفتگی
**فایل جدید:** `lib/features/courses/presentation/widgets/courses_weekly_hero.dart`
**اقدام:** کارت شیشه‌ای با گرادیان آبی→نیلی:
1. نوار پیشرفت هفتگی «X از Y جلسه».
2. ⏱ مجموع ساعت مطالعه‌ی این هفته.
3. 🔥 استریک مطالعه + تعداد دوره‌های فعال.
داده از `CoursesEngine` با `RitmoEngineBus`.
**تأیید:** نمایش درست اعداد فارسی؛ analyze/test سبز.

## ▣ تسک C6 — بخش جلسات امروز + شرط انرژی
**فایل جدید:** `lib/features/courses/presentation/widgets/today_sessions_section.dart`
**اقدام:**
1. کوئری جلسات `plannedDate == today` و `PENDING`.
2. هر کارت: ایموجی دوره + عنوان + «[برچسب‌واحد] X» + [▶ شروع] [✓ انجام].
3. **▶ شروع** → باز کردن `study_timer_sheet.dart` (تسک C8).
4. **✓ انجام** → مودال تکمیل (مدت واقعی + یادداشت) → `completionStatus='COMPLETED'`، `actualDurationMinutes`.
5. حالت خالی: «امروز جلسه‌ای برنامه‌ریزی نشده 🌿».
6. **انرژی:** اگر انرژی فعلی پایین و `energyRule=='skip'` → کارت کم‌رنگ + «امروز استراحت». `offerLight` → «یه جلسه‌ی کوتاه‌تر چطوره؟».
**تأیید:** تیک، مودال، شرط انرژی؛ analyze/test سبز.

## ▣ تسک C7 — بخش دوره‌های فعال
**فایل جدید:** `lib/features/courses/presentation/widgets/active_courses_section.dart`
**اقدام:**
1. کارت هر دوره‌ی `status=ACTIVE`: ایموجی/رنگ، عنوان، نوع، نوار پیشرفت، «X از Y [واحد]»، «هفته‌ای N»، badge وضعیت (🟢 به‌روز / 🟡 X روز عقب / ⏸ متوقف).
2. تپ → `course_detail_screen.dart` (تسک C9).
3. دکمه‌ی **＋ دوره** (در هدر صفحه‌ی اصلی) → شیت ساخت دوره (تسک C10).
**تأیید:** لیست + badge؛ analyze/test سبز.

## ▣ تسک C8 — تایمر مطالعه
**فایل جدید:** `lib/features/courses/presentation/widgets/study_timer_sheet.dart`
**اقدام:** شیت با تایمر رو به جلو (`Timer.periodic` هر ثانیه)، دکمه‌های توقف/ادامه/پایان. در پایان، دقیقه‌ی سپری‌شده به مودال تکمیل پاس داده می‌شود و واحد COMPLETED می‌شود. بدون Pomodoro اجباری.
**تأیید:** شروع/توقف/پایان + ثبت مدت؛ analyze/test سبز.

## ▣ تسک C9 — صفحه‌ی جزئیات دوره
**فایل جدید:** `lib/features/courses/presentation/course_detail_screen.dart`
**اقدام:**
1. هدر: ایموجی + عنوان + [⚙ ویرایش].
2. خلاصه: نوار پیشرفت، کل ساعت، میانگین جلسه/هفته، 🏁 تخمین پایان (از موتور)، 🎯 هدف متصل (اگر هست).
3. **بخش ریتم:** اسلایدر/استپر «هفته‌ای N»، انتخاب روزهای ترجیحی (چیپ‌های هفته)، 🔔 یادآوری + ساعت. دکمه‌ی **«بازچینش زمان‌بندی»** → `course_scheduler.distributeSessions` روی واحدهای PENDING + ثبت یادآوری‌ها.
4. **لیست واحدها:** تیک، تاریخ برنامه‌ریزی، مدت واقعی، یادداشت، عنوان واحد (`sessionTitle`)، [▶][✓]. **＋ افزودن واحد**.
5. ویرایش (شیت): عنوان، نوع، ایموجی/رنگ، `provider`، قانون انرژی، `linkedGoalId`، آرشیو/حذف.
6. **تکمیل دوره:** وقتی همه‌ی واحدها COMPLETED → `status='COMPLETED'`, `completedAt`. **اتصال هدف یک‌طرفه:** اگر `linkedGoalId` دارد، فقط درصد پیشرفت دوره در UI هدف نمایش/تغذیه شود. **هرگز `goal_steps.isCompleted` را خودکار تغییر نده** — حتی با تکمیل کامل دوره. (دلیل: یک قدمِ هدف ممکن است معنایی فراتر از این دوره داشته باشد.)
**تأیید:** ویرایش، بازچینش، تیک واحد، تکمیل دوره؛ analyze/test سبز.

## ▣ تسک C10 — شیت ساخت دوره
**فایل جدید:** `lib/features/courses/presentation/widgets/create_course_sheet.dart`
**اقدام:** فرم تک‌صفحه‌ای:
1. نوع دوره (سگمنت VIDEO/BOOK/SKILL/CUSTOM) → برچسب واحد به‌روز شود؛ برای CUSTOM فیلد `unitLabel`.
2. عنوان + ایموجی + رنگ + `provider` (اختیاری).
3. تعداد کل واحد + مدت پیش‌فرض هر واحد.
4. ریتم: هفته‌ای N + روزهای ترجیحی + ساعت یادآوری + سوییچ یادآوری.
5. قانون انرژی (همان dropdown موجود: NONE/skip/offerLight/highEnergyOnly).
6. هدف متصل (اختیاری، از `goals`).
7. ذخیره → ساخت `courses` + N رکورد `course_sessions` (منطق از `education_management_sheet.dart`) + پخش `plannedDate` با scheduler + ثبت یادآوری‌ها.
**تأیید:** ساخت کامل با زمان‌بندی؛ analyze/test سبز.

## ▣ تسک C11 — بخش تکمیل‌شده‌ها (دستاوردها)
**فایل جدید:** `lib/features/courses/presentation/widgets/completed_courses_section.dart`
**اقدام:** بخش تاشده (پیش‌فرض بسته). دوره‌های `status='COMPLETED'`: 🏆 مدال + عنوان + تاریخ تکمیل + «کل: X ساعت در Y هفته». پیام «تو این دوره رو تموم کردی 🎉». امکان بازگردانی به فعال یا حذف.
**تأیید:** نمایش + آمار کل؛ analyze/test سبز.

## ▣ تسک C12 — مونتاژ صفحه‌ی اصلی + اتصال به هاب
**فایل‌ها:** `lib/features/courses/presentation/courses_screen.dart` (جدید) + `lib/features/today/presentation/systems_hub_screen.dart` (ویرایش).
**اقدام:**
1. `courses_screen.dart`: Scaffold + هدر «دوره‌های آموزشی» + [🤖] + [＋ دوره]. `RefreshIndicator`. ListView:
   ```
   courses_weekly_hero
   today_sessions_section
   active_courses_section
   completed_courses_section
   ```
2. در `systems_hub_screen.dart`: کاشی دوره‌ها را مثل `_handleMedicineTap` بازنویسی کن:
   - اگر `_coursesEnabled` → `Navigator.push` به `CoursesScreen`.
   - اگر نه → `_showActivationSheet(...)` با `settingKey: 'module_courses_enabled'` و توضیح مناسب، سپس ورود به صفحه.
   - `import` صفحه‌ی جدید را اضافه کن و `_showComingSoonSheet('دوره‌های آموزشی', ...)` را حذف کن.
**تأیید:** ورود از هاب، فعال‌سازی، صفحه‌ی کامل؛ analyze/test سبز.

## ▣ تسک C13 — یکپارچگی AI (دستیار دوره‌ها) — آخرین مرحله
**فایل جدید:** `lib/features/courses/presentation/widgets/ai_courses_assistant_sheet.dart`
**پیش‌نیاز:** همه‌ی تسک‌های قبلی (C1–C12, C14) کامل و آزموده. AI آخرین لایه است که روی قابلیت کاملِ کارکننده سوار می‌شود.
**اقدام:** دکمه‌ی 🤖 هدر. عملکردهای مجاز:
1. «برنامه‌ی مطالعه برام بچین» — ورودی تعداد واحد + مهلت/ریتم → پیشنهاد `weeklyTargetSessions` + روزها.
2. «کدوم دوره عقب افتادم؟» — خلاصه‌ی `behindSchedule` + جبران ملایم.
3. «این دوره رو به واحد تقسیم کن» — تولید عناوین واحد (`sessionTitle`).
4. «امروز چی بخونم؟» — با انرژی + عقب‌افتادگی یک جلسه پیشنهاد.

**قانون مطلق — AI هرگز مستقیم به DB نمی‌نویسد:**
هر خروجی AI باید این مسیر را طی کند:
```
AI Suggestion  →  Preview (نمایش به کاربر)  →  User Edit (قابل ویرایش)  →  Save (با تأیید صریح)
```
- خروجی «تقسیم به واحد» باید به‌صورت لیست قابل‌ویرایش نمایش داده شود (کاربر بتواند هر عنوان را تغییر/حذف کند) — هرگز مستقیم در `sessionTitle` ذخیره نشود.
- پیشنهاد ریتم باید فیلدهای فرم را پیش‌پر کند، نه اینکه scheduler را خودکار اجرا کند.
**ممنوعات:** تدریس محتوا، خلاصه‌ی درسی طولانی، قضاوت سرعت یادگیری.
از `AiGateway` موجود استفاده کن.
**تأیید:** چهار عملکرد + الزام Preview→Edit→Save؛ analyze/test سبز.

## ▣ تسک C14 — داشبورد امروز (hook) + پرداخت بصری + تست نهایی
**فایل‌ها:** `lib/features/today/presentation/now_dashboard_screen.dart` (افزودن بخش)، کل `lib/features/courses/`.
**اقدام:**
1. در داشبورد امروز یک بخش «📚 مطالعه‌ی امروز» اضافه کن که جلسات `course_sessions(plannedDate=today, PENDING)` را نشان دهد با [✓ انجام] (می‌تواند ویجت `today_sessions_section` را بازاستفاده کند). اگر جلسه‌ای نبود، بخش پنهان شود.
2. رنگ‌ها/گرادیان آبی، RTL، ارقام فارسی، فاصله‌گذاری مضارب ۸، حداقل لمسی ۴۸dp.
3. `flutter analyze` بدون error/warning جدید.
4. `flutter test` همه سبز + **تست‌های جدید:** پخش زمان‌بندی، عقب‌افتادگی، تخمین پایان، استریک، تکمیل دوره.
5. `DESIGN_SYSTEM_COURSES.md` را به‌روز کن.
**تأیید:** همه سبز + بخش داشبورد.

---

## 📤 قالب گزارش (بعد از هر تسک)
```
## تسک [C?]: [عنوان]
- فایل‌ها: ...
- خلاصه: ...
- flutter analyze: [قبل → بعد]
- flutter test: [N passed, M failed]
- وضعیت: ✅ / ⚠️ / ❌
```
**یادآوری: بعد از C1 توقف کن و منتظر تأیید انسانی بمان.**
