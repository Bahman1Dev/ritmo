
# بازسازی، اصلاح و هوشمندسازی سیستم «دوره‌های آموزشی» ریتمو

> **نقش تو:** مهندس ارشد Flutter روی پروژه‌ی Ritmo (ریشه: `ritmo/`).
> **زبان UI:** فارسی، RTL، فونت Vazirmatn، ارقام فارسی، فاصله‌گذاری مضارب ۸، حداقل لمسی ۴۸dp.
> **دیتابیس:** SQLite با `sqflite_sqlcipher` از طریق `DatabaseHelper`.
> **این سند نقشه‌ی نهایی است. برای خودت نقشه‌ی جدید نساز، ترتیب را عوض نکن، و تسک‌ها را ادغام نکن.**

---

## ⛔️ قوانین سراسری (نقض این‌ها = رد کار)

1. **هیچ ویجت/صفحه‌ای مستقیماً روی جداول `courses` و `course_sessions` ننویسد.** تنها نقطه‌ی نوشتن: `CoursesRepository`.
2. **AI هرگز مستقیم در DB نمی‌نویسد.** مسیر اجباری: `AI Suggestion → Preview → User Edit → Save (تأیید صریح)`.
3. **منبع completion دوره‌ها فقط `course_sessions`** است. هرگز در `routine_completions` یا `daily_rhythm` برای دوره رکورد نزن.
4. **اتصال به Goals یک‌طرفه است (Course → Goal).** تکمیل جلسه یا دوره هرگز `goal_steps.isCompleted = 1` نکند.
5. **بدون حذف قابلیت.** هیچ امکانی که الان کاربر دارد نباید از بین برود.
6. بعد از **هر تسک**: `flutter analyze` بدون error/warning جدید + `flutter test` سبز. تا سبز نشدی، تسک بعدی را شروع نکن.
7. رشته‌های ثابت وضعیت (`'ACTIVE'`, `'PENDING'`, …) را با enum/constant موجود جایگزین کن؛ magic string جدید نساز.
8. تاریخ‌ها **داخلی ISO `YYYY-MM-DD`** ذخیره شوند و **شمسی** نمایش داده شوند (پکیج `shamsi_date` نصب است).
9. هر تسک = یک commit مستقل با پیام `courses(v2): <task-id> <خلاصه>`.
10. اگر بین این سند و واقعیتِ کد تناقض دیدی، **کد را مبنا بگیر**، تناقض را در گزارش PASS 0 بنویس، اما مسیر کلی را تغییر نده.

---

## ▣ PASS 0 — ممیزی (بدون تغییر کد) 🔴

هیچ فایلی را تغییر نده. فقط این‌ها را بخوان و گزارش بده:

- `lib/features/courses/models/course_models.dart`
- `lib/features/courses/logic/courses_repository.dart`
- `lib/features/courses/logic/course_scheduler.dart`
- `lib/features/courses/logic/courses_ai_helper.dart`
- `lib/features/courses/presentation/courses_screen.dart`
- `lib/features/courses/presentation/course_detail_screen.dart`
- `lib/features/courses/presentation/widgets/create_course_sheet.dart`
- `lib/features/courses/presentation/widgets/study_timer_sheet.dart`
- `lib/features/courses/presentation/widgets/active_courses_section.dart`
- `lib/features/courses/presentation/widgets/completed_courses_section.dart`
- `lib/features/courses/presentation/widgets/ai_courses_assistant_sheet.dart`
- `lib/features/today/presentation/widgets/education_management_sheet.dart`
- `lib/core/analytics/courses_engine.dart`
- `lib/core/database/schema/tables/course_tables.dart`
- `lib/core/database/migration/migrations_registry.dart`
- `lib/core/database/database_helper.dart`
- `lib/features/routines/domain/strategies/course_strategy.dart`
- `lib/core/services/alarm_scheduler_service.dart` (فقط بخش‌های مرتبط با `courseSessionId`)
- `test/` — همه‌ی تست‌های مرتبط با course

**قالب گزارش (فقط متن، بدون کد):**

```

- نسخه فعلی DB در database_helper: ...
- شماره نسخه‌ی مهاجرت جدید من = فعلی + ۱ = ...
- امضای دقیق CreateCourseSheet: ...
- آیا CreateCourseSheet حالت ویرایش دارد؟ (بله/خیر + خط)
- مصرف‌کننده‌های education_management_sheet.dart (همه‌ی نقاط ورود): ...
- آیا completeSession بعد از تراکنش syncCourseAlarms صدا می‌زند؟ (بله/خیر)
- آیا updateCourseStatus یادآورها را لغو/بازسازی می‌کند؟ (بله/خیر)
- فهرست فایل‌های تست موجود مرتبط با courses: ...
- نام دقیق enum/constant های CourseStatus و completionStatus: ...
- الگوی رویداد: نام رویدادهای فعلی course در RitmoEventBus: ...
- الگوی مرجع تایمر ماندگار (active_timers) و امضای NotificationPlatform.startTimerMode: ...
- تناقض‌های این سند با کد: ...

```

**تأیید PASS 0:** فقط گزارش. **توقف کن و منتظر تأیید انسانی بمان.**

---

# فاز صفر — اصلاحات حیاتی (Blocking)

## ▣ C1 — مهاجرت دیتابیس 🔴

**فایل‌ها:** `lib/core/database/schema/tables/course_tables.dart`، `lib/core/database/migration/migrations_registry.dart`، `database_helper.dart`

نسخه‌ی DB را **فعلی + ۱** کن (عدد را از PASS 0 بگیر؛ در ادامه `vN` می‌نامیم). تابع `_migrateToVN(db)` بساز و در `onUpgrade` با `if (oldVersion < N)` صدا بزن. **همین تغییرات را در `_createDB`/`CourseTables.create` هم بگذار** تا نصب تازه و ارتقا یکسان شوند.

### ستون‌های جدید `course_sessions`

```

ALTER TABLE course_sessions ADD COLUMN completedAt INTEGER;

ALTER TABLE course_sessions ADD COLUMN isUserScheduled INTEGER NOT NULL DEFAULT 0;

ALTER TABLE course_sessions ADD COLUMN plannedStartTime TEXT;          -- 'HH:mm'

ALTER TABLE course_sessions ADD COLUMN estimatedDurationMinutes INTEGER;

ALTER TABLE course_sessions ADD COLUMN sectionTitle TEXT;              -- نام بخش/فصل

ALTER TABLE course_sessions ADD COLUMN learningObjective TEXT;

ALTER TABLE course_sessions ADD COLUMN difficulty INTEGER;             -- 1..5

ALTER TABLE course_sessions ADD COLUMN activityKind TEXT NOT NULL DEFAULT 'LEARN'; -- LEARN|PRACTICE|REVIEW|PROJECT|EXAM

ALTER TABLE course_sessions ADD COLUMN understandingScore INTEGER;     -- 1..5

ALTER TABLE course_sessions ADD COLUMN needsReview INTEGER NOT NULL DEFAULT 0;

ALTER TABLE course_sessions ADD COLUMN keyTakeaway TEXT;

ALTER TABLE course_sessions ADD COLUMN openQuestion TEXT;

ALTER TABLE course_sessions ADD COLUMN sourceSessionId TEXT;           -- برای جلسات مرور

ALTER TABLE course_sessions ADD COLUMN displayOrder INTEGER NOT NULL DEFAULT 0;

```

### ستون‌های جدید `courses`

```

ALTER TABLE courses ADD COLUMN adaptiveLastAppliedAt INTEGER;

ALTER TABLE courses ADD COLUMN masteryScore REAL NOT NULL DEFAULT 0;

ALTER TABLE courses ADD COLUMN reviewEnabled INTEGER NOT NULL DEFAULT 0;

```

### Backfill اجباری در همان مهاجرت

```

UPDATE course_sessions

SET completedAt = updatedAt

WHERE completionStatus = 'COMPLETED' AND completedAt IS NULL;

UPDATE course_sessions

SET displayOrder = sessionNumber

WHERE displayOrder = 0;

```

### ایندکس‌ها

```

CREATE INDEX IF NOT EXISTS idx_course_sessions_planned ON course_sessions(plannedDate, completionStatus);

CREATE INDEX IF NOT EXISTS idx_course_sessions_course_status ON course_sessions(courseId, completionStatus);

CREATE INDEX IF NOT EXISTS idx_course_sessions_completedAt ON course_sessions(completedAt);

CREATE INDEX IF NOT EXISTS idx_courses_status ON courses(status, isArchived);

CREATE INDEX IF NOT EXISTS idx_courses_linkedGoalId ON courses(linkedGoalId);

```

### Constraints (فقط در `_createDB` نصب تازه؛ برای ارتقا از rebuild-table استفاده نکن مگر ضروری)

در تعریف اولیه‌ی جداول اضافه کن:

```

-- courses

CHECK(totalSessions > 0),

CHECK(sessionDurationMinutes BETWEEN 1 AND 600),

CHECK(weeklyTargetSessions BETWEEN 1 AND 21),

CHECK(status IN ('ACTIVE','PAUSED','COMPLETED')),

FOREIGN KEY(linkedGoalId) REFERENCES goals(id) ON DELETE SET NULL

-- course_sessions

CHECK(completionStatus IN ('PENDING','COMPLETED','SKIPPED')),

CHECK(activityKind IN ('LEARN','PRACTICE','REVIEW','PROJECT','EXAM')),

CHECK(understandingScore IS NULL OR understandingScore BETWEEN 1 AND 5),

CHECK(difficulty IS NULL OR difficulty BETWEEN 1 AND 5)

```

> برای مسیر ارتقا، اگر افزودن CHECK به جدول موجود ممکن نیست، اعتبارسنجی معادل را در لایه‌ی دامنه (C4) اعمال کن و در گزارش بنویس.

**تأیید C1:** تست مهاجرت با FFI in-memory (هم‌سبک `database_helper_test.dart` موجود): مسیر `v1 → vN` و مسیر `v(N-1) → vN` هر دو بدون خطا؛ بررسی وجود همه‌ی ستون‌ها و ایندکس‌ها؛ بررسی backfill شدن `completedAt`.

---

## ▣ C2 — مدل‌ها

**فایل:** `lib/features/courses/models/course_models.dart`

- همه‌ی فیلدهای جدید C1 را به `Course` و `CourseSession` اضافه کن (constructor، `fromMap`، `toMap`، `copyWith`).
- `copyWith` را برای فیلدهای nullable با الگوی sentinel اصلاح کن تا **بتوان مقدار را به `null` برگرداند** (مثلاً پاک‌کردن `completedAt`). اگر الگوی sentinel در پروژه نیست، متد صریح `clearCompletedAt()` بساز.
- `enum CourseActivityKind { learn, practice, review, project, exam }` + extension `fromString`/`dbValue`.
- `enum SessionStatus { pending, completed, skipped }` + extension. `completionStatus` را از String خام به این enum منتقل کن (در `toMap`/`fromMap` تبدیل شود).
- getterهای مشتق: `isCompleted`, `isSkipped`, `isOverdue(todayStr)`, `unitLabelResolved`, `emojiResolved`.

**تأیید C2:** round-trip test: `Course/CourseSession → toMap → fromMap` برابر اصل باشد، شامل مقادیر null.

---

## ▣ C3 — یکسان‌سازی مسیر داده (حذف مسیر موازی) 🔴

**فایل:** `lib/features/today/presentation/widgets/education_management_sheet.dart`

**مشکل:** این شیت مستقیماً `db.insert('courses', ...)` و `db.insert('course_sessions', ...)` و `db.update` می‌زند؛ جلسات بدون `plannedDate` می‌سازد، یادآور نمی‌چیند، رویداد نمی‌فرستد، و تکمیل خودکار دوره را دور می‌زند.

**اقدام:**

1. تمام دسترسی مستقیم DB در این فایل حذف شود؛ همه چیز از `CoursesRepository` عبور کند.
2. دکمه‌ی «ایجاد دوره» داخل این شیت حذف و جایش دکمه‌ی «باز کردن دوره‌های آموزشی» بگذار که `Navigator.push` به `CoursesScreen` می‌کند.
3. تیک‌زدن جلسه در این شیت باید `CoursesRepository.completeSession(...)` را صدا بزند (نه `db.update`).
4. تمام نقاط ورود این شیت (از PASS 0) بررسی و در صورت افزونگی به `CoursesScreen` هدایت شوند.
5. `CourseStrategy` (`lib/features/routines/domain/strategies/course_strategy.dart`) هم بررسی شود: بعد از `createCourse` رویداد را از داخل Repository بفرست، نه از strategy (تا تکراری نشود).

**تأیید C3:** `grep` روی `'courses'` و `'course_sessions'` در کل `lib/features/**/presentation/**` → **صفر نتیجه‌ی نوشتن**. فقط `CoursesRepository` و لایه‌ی database مجاز است.

---

## ▣ C4 — اعتبارسنجی دامنه + مقاوم‌سازی Scheduler 🔴

**فایل جدید:** `lib/features/courses/logic/course_validation.dart`

```

class CourseValidationException implements Exception {

CourseValidationException(this.code, this.messageFa);

final String code;

final String messageFa;

}

class CourseValidator {

static void validateCourse(Course c) { / *...* / }

static List<int> normalizePreferredDays(List<int> days);

}

```

قواعد:
- `title.trim()` غیرخالی و حداکثر ۱۲۰ کاراکتر.
- `totalSessions` در بازه `1..500`.
- `sessionDurationMinutes` در بازه `1..600`.
- `weeklyTargetSessions` در بازه `1..21`.
- `preferredDays`: حذف تکراری، حذف مقادیر خارج از `0..6`، مرتب‌سازی؛ اگر خالی شد → `[6,1,3]`.
- `preferredTime` اگر `reminderEnabled` است باید `HH:mm` معتبر باشد.
- `weeklyTargetSessions` نباید از تعداد `preferredDays` بیشتر باشد وقتی `preferredDays` غیرخالی است → در این حالت `weeklyTarget = min(weeklyTarget, preferredDays.length)` و در گزارش UI به کاربر اطلاع بده.

**فایل:** `lib/features/courses/logic/course_scheduler.dart`

**مشکل فعلی:** حلقه با `safetyCounter < 10000` می‌چرخد و در ورودی نامعتبر **خروجی ناقص و بی‌صدا** برمی‌گرداند.

**اقدام:**

1. امضای جدید:

```

static List<DateTime> distributeSessions({

required int pendingCount,

required DateTime from,

required int weeklyTarget,

required List<int> preferredDays,

Map<DateTime, int> occupiedWeeklyCounts = const {},   // SaturdayOfWeek -> ظرفیت مصرف‌شده

Set<DateTime> blockedDates = const {},                 // تاریخ‌هایی که نباید استفاده شوند

});

```

2. در ابتدای متد `CourseValidator` را روی ورودی‌ها اعمال کن.
3. `weekCounts` را با `occupiedWeeklyCounts` مقداردهی اولیه کن (کپی، نه mutate ورودی).
4. اگر بعد از پایان حلقه `result.length != pendingCount` → **throw `CourseValidationException('SCHEDULE_INCOMPLETE', ...)`**. هرگز خروجی ناقص برنگردان.
5. سقف را از ۱۰۰۰۰ روز به ۷۳۰ روز کاهش بده؛ بیش از آن یعنی ورودی غیرمنطقی.
6. `daysBehind` باید `SKIPPED` را هم مثل تکمیل‌شده در نظر بگیرد (عقب‌افتاده حساب نشود).
7. متد جدید:

```

static Map<DateTime, int> weeklyOccupancy({

required List<CourseSession> sessions,   // جلسات قفل‌شده/انجام‌شده

});

```

**تأیید C4 (تست واحد اجباری):**
- ۷ جلسه، هفته‌ای ۳، روزهای `[6,1,3]` → دقیقاً ۷ تاریخ، حداکثر ۳ در هر هفته‌ی شنبه‌تا‌جمعه.
- `weeklyTarget = 0` → throw.
- `preferredDays = [9]` → normalize و بدون crash.
- با `occupiedWeeklyCounts` که هفته‌ی جاری را پر کرده → همه‌ی تاریخ‌ها از هفته‌ی بعد شروع شوند.
- `blockedDates` رعایت شود.
- `daysBehind` با جلسه‌ی `SKIPPED` → صفر.

---

## ▣ C5 — بازنویسی `CoursesRepository` (تراکنش، رویداد، یادآور) 🔴

**فایل:** `lib/features/courses/logic/courses_repository.dart`

### ۵.۱ متد جدید ویرایش (رفع باگ تکثیر دوره)

```

Future<void> saveCourse(Course course, {required bool isNew});

```

- `isNew == true` → `createCourse` (تولید ID جدید، تولید همه‌ی جلسات).
- `isNew == false` → `updateCourse` با **حفظ `id` و `createdAt` قبلی**.
- در حالت ویرایش، تشخیص خودکار نیاز به باززمان‌بندی:
  `needsReschedule = oldWeeklyTarget != new || oldPreferredDays != new || oldTotalSessions != new || oldPreferredTime != new || oldReminderEnabled != new`
- تغییر `totalSessions` به‌صورت تراکنشی:
  - **افزایش:** فقط جلسات جدید با `sessionNumber` ادامه‌دار اضافه شود؛ جلسات موجود دست‌نخورده.
  - **کاهش:** فقط از انتهای لیست و **فقط جلسات `PENDING`** حذف شوند. اگر جلسات تکمیل‌شده بیش از مقدار جدید بود → `CourseValidationException('CANNOT_SHRINK_BELOW_COMPLETED', 'تعداد جلسات نمی‌تواند کمتر از جلسات انجام‌شده باشد.')`.
- باززمان‌بندی هرگز جلسات با `isUserScheduled = 1` یا `COMPLETED` را تغییر ندهد؛ آن‌ها به `occupiedWeeklyCounts` و `blockedDates` تزریق شوند.

### ۵.۲ `completeSession`

```

Future<void> completeSession({

required String sessionId,

required int actualDurationMinutes,

String? note,

int? understandingScore,

bool needsReview = false,

String? keyTakeaway,

String? openQuestion,

});

```

- `completedAt = now`, `completionStatus = COMPLETED`, `updatedAt = now`.
- حذف `pending_reminders` مربوطه **داخل تراکنش** + جمع‌آوری `alarmId`ها و `cancelAlarm` **بعد از commit** (الگوی موجود `deleteCourse`).
- بعد از تراکنش: `syncCourseAlarms()` + `SnapshotSyncService.syncAll()` + fire رویداد.
- اگر جلسه‌ی PENDING باقی نماند → دوره `COMPLETED` با `completedAt`.
- اگر `needsReview == true` و `course.reviewEnabled` → ثبت درخواست مرور برای C13 (فقط علامت‌گذاری؛ ساخت جلسه‌ی مرور در C13).

### ۵.۳ متدهای جدید

```

Future<void> uncompleteSession(String sessionId);        // completedAt = null, status = PENDING, یادآور بازسازی

Future<void> skipSession(String sessionId, {String? reason});

Future<Map<String, List<CourseSession>>> getSessionsForCourses(Set<String> courseIds); // رفع N+1

Future<List<CourseSession>> getSessionsForDateRange(String fromIso, String toIso);

Future<void> reorderSessions(String courseId, List<String> orderedSessionIds);

```

### ۵.۴ یکپارچگی یادآور (اجباری)

یک متد خصوصی واحد بساز و **همه‌ی مسیرها از آن عبور کنند**:

```

Future<void> _rebuildRemindersForCourse(Transaction txn, Course course);

```

فراخوانی اجباری در: `createCourse`, `updateCourse`, `completeSession`, `uncompleteSession`, `skipSession`, `rescheduleSession`, `updateCourseStatus`, `deleteCourse`, `restoreCourse`.

قواعد:
- دوره‌ی `PAUSED` یا `COMPLETED` یا `isArchived` → **همه‌ی یادآورهای آینده لغو شوند**.
- بازگشت به `ACTIVE` → یادآورهای جلسات PENDING آینده بازسازی شوند.
- یادآور برای تاریخ گذشته هرگز ساخته نشود.
- `cancelAlarm` همیشه **خارج از تراکنش**.

### ۵.۵ رویداد واحد

یک نوع رویداد استاندارد:

```

RitmoEvent(

type: 'CoursesChanged',

timestamp: now,

payload: {'courseId': ..., 'sessionId': ..., 'reason': 'CREATE|UPDATE|COMPLETE|UNCOMPLETE|SKIP|RESCHEDULE|STATUS|DELETE'},

)

```

رویدادهای قدیمی (`CourseChanged`, `CourseSessionCompleted`) را حفظ کن اگر مصرف‌کننده دارند، اما `CoursesChanged` را همیشه هم بفرست و `DayAgendaService` را به آن وصل کن.

**تأیید C5 (تست Repository با FFI):**
- ویرایش دوره → تعداد ردیف `courses` **ثابت** بماند و ID تغییر نکند. (تست رگرسیون باگ تکثیر)
- کاهش `totalSessions` زیر تعداد completed → throw.
- تکمیل جلسه → `completedAt` پر شود و ردیف `pending_reminders` آن حذف شود.
- `uncompleteSession` → `completedAt` برابر `null`.
- `updateCourseStatus(PAUSED)` → صفر یادآور آینده.
- حذف دوره → صفر ردیف در هر سه جدول.

---

## ▣ C6 — اصلاح `CoursesEngine` 🔴

**فایل:** `lib/core/analytics/courses_engine.dart`

**مشکل:** آمار هفتگی فقط از جلسات دوره‌های `ACTIVE` ساخته می‌شود؛ در نتیجه با تکمیل آخرین جلسه، دوره `COMPLETED` می‌شود و آمار هفته **کاهش می‌یابد**. همچنین از `updatedAt` به‌عنوان زمان تکمیل استفاده می‌کند.

**اقدام:**

1. دو مجموعه‌ی صریح:
   - `planningCourses` = فقط `ACTIVE && !isArchived` → برای `todaySessions`, `behindSchedule`, `weeklyTargetSessions`, `estimatedEnd`.
   - `achievementSessions` = **همه‌ی جلسات همه‌ی دوره‌ها** (فعال، متوقف، تکمیل‌شده) → برای `weeklyDoneSessions`, `weeklyStudyMinutes`, `studyStreakDays`.
2. همه‌جا `completedAt` جایگزین `updatedAt` شود. اگر `completedAt == null` بود، fallback به `updatedAt` با یک `RitmoLog.warning`.
3. `weeklyStudyMinutes`: اگر `actualDurationMinutes == null` بود از `sessionDurationMinutes` دوره به‌عنوان تخمین استفاده کن و در خروجی `estimatedMinutesIncluded: true` بگذار.
4. همه‌ی `RitmoLog.debug` های پرسروصدای فعلی (لاگ به ازای هر جلسه) را حذف یا پشت `if (kDebugMode)` با نمونه‌گیری بگذار؛ در حلقه لاگ ننویس.
5. خروجی‌های جدید در `CoursesEngineOutput`:

```

final int weeklyDoneSessions;

final int weeklyTargetSessions;

final int weeklyStudyMinutes;

final int studyStreakDays;

final Map<String, int> behindSchedule;

final List<CourseSession> todaySessions;

final Map<String, DateTime?> estimatedEnd;

// جدید:

final Map<String, double> completionRate;      // courseId -> 0..1

final Map<String, double> scheduleAdherence;   // انجام‌شده/برنامه‌ریزی‌شده تا امروز

final Map<String, double> estimationAccuracy;  // actual/estimated

final Map<String, int> requiredWeeklyPace;     // برای رسیدن به targetEndDate

final List<SessionRecommendation> recommendations; // C10

final Map<String, double> masteryByCourse;     // C13

```

6. `invalidate()` را واقعی پیاده کن (کش داخلی + پاک‌سازی) و `dependencies()` را در صورت نیاز به `EnergyAnalyticsEngine` وصل کن.

**تأیید C6 (تست):**
- سناریو: دوره‌ی ۳ جلسه‌ای، ۲ جلسه قبلاً این هفته تکمیل، جلسه‌ی سوم امروز تکمیل → `weeklyDoneSessions == 3` (نه ۰ و نه ۲). **این تست رگرسیون اجباری است.**
- استریک با شکاف یک‌روزه محاسبه‌ی درست بدهد.
- جلسه‌ی `SKIPPED` در `weeklyDone` شمرده نشود ولی در `behindSchedule` هم نیاید.

---

## ▣ C7 — رفع باگ ویرایش در UI 🔴

**فایل‌ها:** `create_course_sheet.dart`، `course_detail_screen.dart`، `courses_screen.dart`

1. امضای جدید:

```

CreateCourseSheet({

super.key,

this.editingCourse,                 // null = ایجاد

this.initialValues,                 // فقط برای پیش‌پرکردن از AI

required this.onSaved,

});

```

2. در `_saveCourse`:
   - `isNew = widget.editingCourse == null`
   - در حالت ویرایش: `course = widget.editingCourse!.copyWith(...)` (حفظ `id`, `createdAt`, `status`, `completedAt`, `isArchived`).
   - فراخوانی `CoursesRepository.instance.saveCourse(course, isNew: isNew)`.
3. عنوان شیت و متن دکمه: `ایجاد دوره` ↔ `ذخیره تغییرات`.
4. در حالت ویرایش، اگر `needsReschedule` بود، **قبل از ذخیره** دیالوگ بپرس:
   «تغییر ریتم باعث جابه‌جایی ۷ جلسه‌ی برنامه‌ریزی‌شده می‌شود. ادامه می‌دهید؟» با گزینه‌های `ادامه` / `فقط اطلاعات را ذخیره کن` / `انصراف`.
5. `course_detail_screen._editCourse` → `CreateCourseSheet(editingCourse: _course, onSaved: _loadCourseData)`.
6. `catch (CourseValidationException e)` → نمایش `e.messageFa` با `RitmoToast`؛ هرگز خطای خام یا crash.
7. جلوگیری از double-tap: دکمه‌ی ذخیره در حین اجرا disable + spinner.

**تأیید C7 (widget test اجباری):** باز کردن شیت در حالت ویرایش، تغییر عنوان، ذخیره → در DB **یک** دوره با همان ID و عنوان جدید. (رگرسیون باگ تکثیر)

---

# فاز یک — پایداری، عملکرد، تست

## ▣ C8 — تایمر مطالعه‌ی ماندگار

**فایل جدید:** `lib/features/courses/logic/course_study_timer_service.dart`
**فایل:** `study_timer_sheet.dart`

**مشکل:** تایمر فقط در state ویجت است؛ بستن شیت یا رفتن به پس‌زمینه زمان را از بین می‌برد.

**اقدام:**

1. جدول جدید در همان مهاجرت `vN` (به C1 اضافه کن):

```

CREATE TABLE IF NOT EXISTS course_active_timers (

courseSessionId TEXT PRIMARY KEY,

courseId TEXT NOT NULL,

startedAt INTEGER NOT NULL,

pausedAccumulatedMs INTEGER NOT NULL DEFAULT 0,

state TEXT NOT NULL DEFAULT 'RUNNING',   -- RUNNING|PAUSED

targetDurationMinutes INTEGER,

updatedAt INTEGER NOT NULL,

FOREIGN KEY(courseSessionId) REFERENCES course_sessions(id) ON DELETE CASCADE

);

```

2. سرویس با API:

```

Future<void> start(CourseSession s, Course c);

Future<void> pause(String sessionId);

Future<void> resume(String sessionId);

Future<void> cancel(String sessionId);

Future<int> elapsedMinutes(String sessionId);

Future<CourseActiveTimer?> getActive();

```

3. **زمان همیشه از timestamp محاسبه شود**، نه شمارنده‌ی UI:
   `elapsedMs = pausedAccumulatedMs + (state == RUNNING ? now - startedAt : 0)`
4. اتصال به `NotificationPlatform.startTimerMode(...)` / `stopForegroundService()` دقیقاً مثل `active_timer_overlay.dart`.
5. `WidgetsBindingObserver`: در `resumed` زمان را از DB بازخوانی کن (نه از state).
6. حداکثر یک تایمر دوره‌ی فعال؛ اگر تایمر دیگری فعال بود، بپرس: «تایمر «X» در حال اجراست. متوقف و جدید شروع شود؟»
7. در باز شدن `CoursesScreen` و `now_dashboard_screen`، اگر تایمر فعال وجود دارد، نوار کوچک «ادامه‌ی جلسه‌ی X — ۱۲:۳۴» نمایش بده.
8. ثبت دستی مدت (بدون تایمر) همچنان کار کند.

**تأیید C8:** تست واحد سرویس: start → pause → (شبیه‌سازی گذشت زمان) → resume → elapsed درست؛ بازخوانی بعد از kill شبیه‌سازی‌شده مقدار درست بدهد.

---

## ▣ C9 — عملکرد و رفع N+1

**فایل:** `courses_screen.dart`، `course_detail_screen.dart`

1. حلقه‌ی `for (course in allCourses) getSessionsForCourse(...)` حذف و جایش `getSessionsForCourses(ids)` (C5).
2. `db.query('app_settings')` کامل → فقط کلیدهای لازم:
   `where: 'key IN (?,?,?)'` با `default_energy_level`, `module_courses_enabled`, `snooze_minutes`.
3. اجرای موتور را از `initState` مستقیم به `RitmoEngineBus` (الگوی `insights_screen.dart`) منتقل کن و به رویداد `CoursesChanged` گوش بده تا رفرش دستی لازم نباشد.
4. لیست‌ها `ListView.builder` با `itemExtent`/`prototypeItem` در صورت امکان؛ کارت‌ها `RepaintBoundary`.
5. skeleton فعلی حفظ شود.

**تأیید C9:** با ۲۰ دوره × ۵۰ جلسه، تعداد کوئری‌های بارگذاری صفحه ≤ ۴ (لاگ بشمار) و زمان بارگذاری در دیباگ زیر ۳۰۰ms.

---

## ▣ C10 — موتور پیشنهاد جلسه (هوشمندسازی واقعیِ انرژی)

**فایل جدید:** `lib/core/analytics/course_recommendation_engine.dart`

**مشکل:** `currentEnergyLevel` به موتور داده می‌شود ولی در انتخاب جلسه نقشی ندارد و `energyRule` عملاً بلااستفاده است.

**مدل:**

```

class SessionRecommendation {

final CourseSession session;

final Course course;

final double score;

final List<String> reasonsFa;   // حداکثر ۳ دلیل کوتاه فارسی

final RecommendationVariant variant; // full | light | postpone

}

```

**فرمول امتیاز (دقیقاً همین وزن‌ها را پیاده کن؛ به‌صورت constant قابل تنظیم):**

```

score =

urgency            * 3.0   // عقب‌افتادگی: min(daysBehind, 5) / 5

- deadlinePressure   * 2.5   // نزدیکی به targetEndDate یا مهلت هدف متصل
- energyFit          * 2.0   // تطابق energyRule با انرژی فعلی
- timeFit            * 1.5   // جا شدن مدت جلسه در بازه‌ی آزاد فعلی
- preferredTimeFit   * 1.0   // نزدیکی ساعت فعلی به preferredTime
- continuity         * 1.0   // ادامه‌ی دوره‌ای که اخیراً روی آن کار شده
- goalPriority       * 1.0   // اتصال به هدف فعال
- overloadPenalty    * 2.0   // اگر سقف هفتگی این دوره پر شده
- fatiguePenalty     * 1.5   // اگر امروز بیش از ۹۰ دقیقه مطالعه ثبت شده

```

**قواعد energyRule (اجباری):**
- `skip` + انرژی `LOW` → جلسه از پیشنهاد حذف شود (`variant = postpone`).
- `offerLight` + انرژی `LOW` → `variant = light` با مدت `max(10, duration ~/ 3)` دقیقه.
- `highEnergyOnly` + انرژی ≠ `HIGH` → حذف از پیشنهاد.
- `NONE` → بدون محدودیت.

**منابع ورودی:** `CoursesEngine`, `EnergyAnalyticsEngine`/`energy_logs`, `DayAgendaService` برای بازه‌های آزاد.

**خروجی UI:** کارت «الآن چه بخوانم؟» بالای `CoursesScreen` + بخش «📚 مطالعه‌ی امروز» در `now_dashboard_screen`:

```

🎬 فلاتر · جلسه ۵

۳۰ دقیقه · مناسب انرژی متوسط

دلیل: ۲ روز عقب افتاده · الآن ۴۵ دقیقه وقت آزاد داری

[▶ شروع] [⚡ نسخه ۱۵ دقیقه‌ای] [🕒 انتقال] [✕ امروز نه]

```

**دلیل پیشنهاد همیشه نمایش داده شود.** تصمیم نهایی با کاربر است؛ هیچ‌چیز خودکار اجرا نمی‌شود.

**تأیید C10:** تست واحد برای هر چهار `energyRule` × سه سطح انرژی (۱۲ حالت) + تست اینکه دوره‌ی `PAUSED` هرگز پیشنهاد نمی‌شود.

---

## ▣ C11 — برنامه‌ی جبرانی (Catch-up)

**فایل جدید:** `lib/features/courses/logic/course_catchup_planner.dart` + `widgets/catchup_sheet.dart`

وقتی `behindSchedule[courseId] >= 2`، در کارت دوره چیپ «⏳ ۳ جلسه عقب — برنامه‌ی جبران» نشان بده. با زدن آن، شیتی با این گزینه‌ها باز شود (هر گزینه با پیش‌نمایش تاریخ‌های جدید):

1. **انتقال به اولین زمان‌های آزاد** — بدون تغییر سقف هفتگی.
2. **تقسیم جلسه** — یک جلسه‌ی ۶۰ دقیقه‌ای → دو جلسه‌ی ۳۰ دقیقه‌ای (`sessionNumber` با ترتیب `displayOrder` حفظ شود).
3. **نسخه‌ی سبک ۱۵ دقیقه‌ای** برای جلسات عقب‌افتاده.
4. **کاهش موقت هدف هفتگی** برای ۲ هفته (با بازگشت خودکار و ثبت در `adaptiveLastAppliedAt`).
5. **فشرده‌سازی تا `targetEndDate`** — محاسبه‌ی `requiredWeeklyPace` و هشدار اگر غیرواقعی بود.
6. **علامت‌گذاری جلسات عقب‌افتاده به‌عنوان `SKIPPED`** — با دیالوگ تأیید صریح.

هیچ گزینه‌ای بدون تأیید کاربر اعمال نشود. همه از `CoursesRepository` عبور کنند.

**تأیید C11:** تست: دوره با ۳ جلسه‌ی عقب‌افتاده، اعمال گزینه‌ی ۱ → هیچ هفته‌ای از سقف عبور نکند و تعداد کل جلسات ثابت بماند.

---

## ▣ C12 — برنامه‌ریز تطبیقی (`isAdaptive` واقعی)

**فایل جدید:** `lib/features/courses/logic/course_adaptive_engine.dart`

ستون `isAdaptive` موجود ولی بلااستفاده است. حالا فعالش کن.

**شاخص‌های محاسبه‌شده (پنجره‌ی ۳ هفته‌ی اخیر):**
- `adherenceRate` = انجام‌شده / برنامه‌ریزی‌شده
- `avgDelayDays`
- `durationRatio` = میانگین `actualDurationMinutes / sessionDurationMinutes`
- `bestWeekdays` / `bestHours` (بر اساس نرخ تکمیل)
- `energySuccessMap`
- `rescheduleCount`

**قواعد پیشنهاد (فقط پیشنهاد، نه اعمال خودکار):**
- `adherenceRate < 0.6` → کاهش `weeklyTarget` یک واحد یا کاهش مدت جلسه به `duration * 0.75`.
- `adherenceRate > 0.95` و بدون عقب‌افتادگی برای ۲ هفته → پیشنهاد افزایش یک واحد.
- `durationRatio > 1.3` → پیشنهاد اصلاح `sessionDurationMinutes` به مقدار واقعی.
- روزهایی با نرخ تکمیل زیر ۳۰٪ → پیشنهاد حذف از `preferredDays`.
- حداکثر **یک پیشنهاد تطبیقی در هر ۷ روز** برای هر دوره (`adaptiveLastAppliedAt`).

**UI:** بنر داخل صفحه‌ی جزئیات دوره:

> «در ۳ هفته‌ی اخیر برنامه‌ی ۴ جلسه‌ای فقط ۶۰٪ اجرا شده. پیشنهاد: ۳ جلسه‌ی ۳۰ دقیقه‌ای در شنبه، دوشنبه، چهارشنبه.»
> `[اعمال کن]` `[بعداً]` `[دیگر پیشنهاد نده]`

`[دیگر پیشنهاد نده]` → `isAdaptive = 0`.

**تأیید C12:** تست با داده‌ی ساختگی سه هفته‌ای برای هر چهار قاعده + تست محدودیت ۷ روزه.

---

# فاز دو — سیستم یادگیری کامل

## ▣ C13 — سنجش تسلط و مرور فاصله‌دار

**فایل جدید:** `lib/features/courses/logic/course_review_engine.dart` + `widgets/session_debrief_sheet.dart`

1. **دیبریف بعد از تکمیل (حداکثر ۱۵ ثانیه کار کاربر، همه اختیاری و قابل رد کردن):**
   - «چقدر متوجه شدی؟» ۱..۵ (چیپ)
   - سوییچ «نیاز به مرور دارد»
   - «یک نکته‌ی کلیدی» (تک‌خطی)
   - «یک ابهام» (تک‌خطی)
   
   خروجی مستقیماً به `completeSession` (C5.2) داده شود.

2. **زمان‌بندی مرور (SM-2 ساده‌شده):**
   - `understandingScore <= 2` → مرور در `+1` و `+3` روز
   - `== 3` → `+2` و `+7` روز
   - `== 4` → `+7` روز
   - `== 5` → `+14` روز
   - `needsReview = true` همیشه حداقل یک مرور `+2` روز اضافه کند.

3. جلسه‌ی مرور یک `course_sessions` جدید است با:
   `activityKind = 'REVIEW'`, `sourceSessionId = <جلسه‌ی اصلی>`, `estimatedDurationMinutes = max(10, duration ~/ 3)`,
   و **در `totalSessions` و درصد پیشرفت دوره شمرده نمی‌شود** (در همه‌ی محاسبات درصد، `activityKind != 'REVIEW'` فیلتر شود).

4. **`masteryScore` دوره:**

```

mastery = 0.6 * (میانگین understandingScore جلسات LEARN / 5)

- 0.3 * (نرخ تکمیل مرورها)
- 0.1 * (1 - نرخ needsReview باز)

```

در کارت تکمیل‌شده‌ها علاوه بر «۱۰۰٪ مشاهده»، «تسلط: ۷۸٪» هم نشان بده.

5. مرور فقط وقتی فعال است که `course.reviewEnabled == 1` (سوییچ در فرم ساخت/ویرایش، پیش‌فرض خاموش برای دوره‌های `VIDEO`، روشن برای `BOOK`/`SKILL`).

**تأیید C13:** تست: تکمیل با نمره ۲ → دو جلسه‌ی REVIEW با تاریخ درست ساخته شود و درصد پیشرفت دوره تغییر نکند.

---

## ▣ C14 — ساخت سرفصل با AI (Preview قابل‌ویرایش)

**فایل‌ها:** `courses_ai_helper.dart`، `ai_courses_assistant_sheet.dart`، فایل جدید `widgets/ai_syllabus_preview_sheet.dart`

1. حالت جدید در دستیار: **«ساخت سرفصل»** در کنار حالت فعلی «پیشنهاد ریتم».
2. ورودی‌های مجاز کاربر: نام کتاب، فهرست مطالب چسبانده‌شده، سرفصل دوره، مهارت هدف، تاریخ آزمون/پایان.
3. خروجی JSON اجباری مدل:

```

{

"title": "...",

"courseType": "VIDEO|BOOK|SKILL|CUSTOM",

"unitLabel": "جلسه",

"provider": "...",

"sections": [

{

"sectionTitle": "مبانی",

"sessions": [

{

"sessionTitle": "...",

"learningObjective": "...",

"estimatedDurationMinutes": 45,

"difficulty": 3,

"activityKind": "LEARN"

}

]

}

],

"weeklyTargetSessions": 3,

"preferredDays": [6,1,3],

"explanation": "..."

}

```

4. **اعتبارسنجی سخت‌گیرانه در `courses_ai_helper.dart`** (الگوی موجود را گسترش بده): پارس با `try/catch`، برش متن بین اولین `{` و آخرین `}`، clamp همه‌ی اعداد، فیلتر `preferredDays` به `0..6`، سقف ۲۰۰ جلسه، حذف عنوان‌های خالی. خروجی نامعتبر → `null` و پیام فارسی «نتوانستم سرفصل معتبری بسازم، دوباره تلاش کن یا دستی وارد کن». **هرگز crash نکن.**
5. `AIGateway` با `responseFormatJson: true` و timeout ۴۵ ثانیه (مطابق تنظیمات فعلی پروژه).
6. **`AiSyllabusPreviewSheet`:** لیست بخش‌ها و جلسات با امکان **ویرایش عنوان، تغییر مدت، تغییر نوع فعالیت، حذف، و جابه‌جایی (drag)**. شمارنده‌ی زنده: «۲۴ جلسه · مجموع ۱۸ ساعت · تخمین پایان: ۱۴ آذر».
7. فقط با دکمه‌ی صریح «تأیید و ساخت دوره» ذخیره شود — از مسیر `CoursesRepository.saveCourse(isNew: true)` با جلسات از پیش‌تعیین‌شده. برای این کار متد Repository زیر را اضافه کن:

```

Future<void> createCourseWithSessions(Course course, List<CourseSession> draftSessions);

```

8. تمام متن‌های AI فارسی؛ context ارسالی به مدل هرگز شامل داده‌ی چرخه، پزشکی، یا ردیف‌های `isPrivate = 1` نباشد (قواعد `AnalyticsPromptRules.core` را inject کن).

**تأیید C14:** تست پارسر با ۵ ورودی خراب (JSON ناقص، اعداد منفی، آرایه‌ی خالی، متن اضافه دور JSON، فیلد گمشده) → همه `null` یا خروجی نرمال‌شده، بدون exception.

---

## ▣ C15 — ادغام با تقویم و ظرفیت واقعی روز

1. `plannedStartTime` جلسات پر شود: از `preferredTime` یا از اولین بازه‌ی آزاد روز (`DayAgendaService`).
2. Scheduler هنگام انتخاب تاریخ، روزهایی که ظرفیت آزادشان کمتر از `sessionDurationMinutes` است را در `blockedDates` بگذارد.
3. جلسات دوره در `timeline_grid` تقویم به‌عنوان بلوک زمانی نمایش داده شوند (فقط خواندنی از سمت تقویم؛ ویرایش از صفحه‌ی دوره).
4. تشخیص تداخل با روتین‌ها/رویدادهای لنگر (نماز، خواب) → هشدار غیرمسدودکننده هنگام زمان‌بندی.
5. احترام به ساعت خواب/بیداری (`sleep_target_bedtime` / `sleep_target_wake` در `app_settings`).

**تأیید C15:** جلسه هرگز در بازه‌ی خواب زمان‌بندی نشود؛ تست واحد برای تداخل.

---

## ▣ C16 — داشبورد تحلیلی یادگیری

**فایل جدید:** `lib/features/courses/presentation/courses_insights_screen.dart` (ورود از آیکون 📊 در هدر `CoursesScreen`)

کارت‌ها:
1. دقایق مطالعه: این هفته / این ماه (نمودار میله‌ای ۸ هفته)
2. ثبات اجرای برنامه (`scheduleAdherence`) با روند
3. دقت تخمین مدت (`estimationAccuracy`) — «معمولاً ۲۰٪ بیشتر از تخمین طول می‌کشد»
4. بهترین روز و ساعت یادگیری (heatmap شمسی — از الگوی هیت‌مپ جلالی موجود در پروژه استفاده کن)
5. نرخ تکمیل و تسلط هر دوره
6. سرعت فعلی در برابر سرعت لازم + پیش‌بینی واقع‌بینانه‌ی پایان
7. تفکیک زمان: یادگیری / تمرین / مرور / پروژه (نمودار دونات)
8. استریک مطالعه

همه با رنگ‌های برند (سرمه‌ای تیره، طلایی `0xffD4A843`/`0xffE5BA5A`، زمردی)، RTL، ارقام فارسی. حالت خالی (`RitmoEmptyState`) وقتی داده کافی نیست: «برای تحلیل دقیق حداقل ۷ روز داده لازم است.»

---

## ▣ C17 — تست‌های اجباری (بدون این، کار ناتمام است)

فایل‌های تست جدید در `test/`:

| فایل | پوشش |
|---|---|
| `test/courses/course_scheduler_test.dart` | پخش، سقف هفتگی، occupancy، blockedDates، ورودی نامعتبر، daysBehind |
| `test/courses/courses_repository_test.dart` | FFI: create/update/complete/uncomplete/skip/reschedule/delete/restore + **رگرسیون تکثیر دوره** |
| `test/courses/courses_engine_test.dart` | **رگرسیون آمار هفته بعد از تکمیل دوره** + استریک + completedAt |
| `test/courses/course_recommendation_test.dart` | ۱۲ حالت energyRule × انرژی |
| `test/courses/course_adaptive_test.dart` | چهار قاعده + محدودیت ۷ روزه |
| `test/courses/course_review_test.dart` | زمان‌بندی مرور + عدم تأثیر بر درصد پیشرفت |
| `test/courses/courses_ai_parser_test.dart` | ۵ ورودی خراب |
| `test/courses/course_study_timer_test.dart` | start/pause/resume/elapsed/بازیابی |
| `test/courses/course_migration_test.dart` | `v1→vN` و `v(N-1)→vN` + backfill |
| `test/courses/create_course_sheet_widget_test.dart` | ویرایش ≠ ایجاد |

---

## ▣ C18 — مستندسازی و بستن کار

1. `DESIGN_SYSTEM_COURSES.md` را کامل به‌روز کن: schema جدید، جریان‌های جدید، ASCII wireframe صفحات جدید، قواعد امتیازدهی و مرور.
2. فایل جدید `docs/courses/COURSES_V2_REPORT.md` با: فهرست باگ‌های رفع‌شده، فایل‌های تغییریافته، شماره‌ی نسخه‌ی DB، تست‌های افزوده‌شده، و موارد عمداً انجام‌نشده.
3. همه‌ی رشته‌های فارسی جدید در فایل‌های `.arb` (l10n) قرار بگیرند اگر پروژه از l10n استفاده می‌کند.
4. اجرای نهایی:
   - `flutter analyze` → صفر error/warning جدید
   - `flutter test` → همه سبز
   - `flutter build apk --debug` → موفق

---

## ✅ سناریوی پذیرش نهایی (دستی روی امولاتور)

- [ ] ساخت دوره‌ی «آموزش فلاتر»، ۱۲ جلسه، ۴۵ دقیقه، هفته‌ای ۳، روزهای شنبه/دوشنبه/چهارشنبه، یادآور ۲۰:۰۰ → ۱۲ جلسه با تاریخ درست و ۱۲ یادآور ساخته شود.
- [ ] ویرایش عنوان دوره → **هیچ دوره‌ی تکراری ساخته نشود**؛ تعداد جلسات ثابت.
- [ ] تغییر هدف هفتگی از ۳ به ۲ → فقط جلسات PENDING جابه‌جا شوند، جلسات تکمیل‌شده دست‌نخورده.
- [ ] جابه‌جایی دستی یک جلسه → آن جلسه در باززمان‌بندی بعدی تغییر نکند.
- [ ] شروع تایمر، بستن شیت، بستن اپ، باز کردن مجدد → «ادامه‌ی جلسه» با زمان درست.
- [ ] تکمیل آخرین جلسه → دوره تکمیل شود و **آمار هفته کاهش نیابد**.
- [ ] برگرداندن یک جلسه به انجام‌نشده → دوره از COMPLETED به ACTIVE برگردد و یادآور بازسازی شود.
- [ ] توقف موقت دوره → هیچ یادآور آینده‌ای باقی نماند؛ ازسرگیری → یادآورها برگردند.
- [ ] با انرژی پایین و `energyRule = offerLight` → پیشنهاد «نسخه‌ی ۱۵ دقیقه‌ای» با دلیل نمایش داده شود.
- [ ] با ۳ جلسه عقب‌افتادگی → چیپ جبران و شیت با ۶ گزینه و پیش‌نمایش تاریخ.
- [ ] دیبریف بعد از جلسه با نمره ۲ → دو جلسه‌ی مرور ساخته شود، درصد پیشرفت تغییر نکند.
- [ ] چسباندن فهرست مطالب یک کتاب در دستیار → سرفصل قابل‌ویرایش با drag، سپس ساخت دوره.
- [ ] حذف دوره → هیچ ردیف یتیمی در `course_sessions`، `pending_reminders`، `course_active_timers` نماند.
- [ ] بازکردن صفحه با ۲۰ دوره → بدون لگ محسوس.

---

## 📋 ترتیب اجرای الزامی

```

PASS 0 (توقف برای تأیید انسانی)

→ C1 → C2 → C3 → C4 → C5 → C6 → C7   ← فاز صفر: تا اینجا هر باگ حیاتی باید بسته شده باشد

→ C8 → C9 → C17(بخش تست‌های فاز صفر)

→ C10 → C11 → C12

→ C13 → C14 → C15 → C16

→ C17(کامل) → C18

```

** اگر تسکی به‌خاطر واقعیت کد قابل اجرا نبود، **متوقف شو و بپرس** — خودت جایگزین اختراع نکن.
```
