
---

```
# پرامپت ۰۲۹ — مخزن مرکزی «همه برنامه‌ها» + رفع باگ‌های وابسته

> **پیش‌نیاز اجرا:** پرامپت ۰۲۸ باید کامل اجرا و merge شده باشد.
> **زبان UI:** فارسی · **اعداد:** همیشه از `toPersianDigits()` · **فونت:** `Vazirmatn`
> **دیتابیس:** ⛔ هیچ جدول جدید، هیچ مهاجرت جدید، هیچ ستون جدید.

---

## PASS 0 — راستی‌آزمایی اجباری قبل از هر تغییر

این دستورها را اجرا کن و خروجی هرکدام را در گزارش پایانی بنویس. **اگر شرط توقف برقرار شد، هیچ فایلی را تغییر نده و فقط گزارش بده.**

```

# P0-1 : تأیید اجرای ۰۲۸

rg -n "class TimelineSplitDayView" lib/features/calendar/presentation/widgets/

rg -n "splitBoundaryMinutes|HourAxisSide" lib/features/calendar/presentation/utils/calendar_tokens.dart

# P0-2 : ساختار هدر تقویم

rg -n "[Icons.search](http://Icons.search)_rounded|CalendarSearchDelegate|[Icons.space](http://Icons.space)_dashboard_outlined|Icons.refresh" \

lib/features/calendar/presentation/journey_screen.dart

# P0-3 : امضای فعلی دلیگیت جست‌وجو

rg -n "class CalendarSearchDelegate|required this.items|final List<AgendaItem> items" \

lib/features/calendar/presentation/widgets/calendar_search_delegate.dart

# P0-4 : کد مردهٔ احتمالی

rg -n "RoutinesListScreen|routines_list_screen" lib/ test/

# P0-5 : ستون‌های واقعی جداول

rg -n "CREATE TABLE routines|CREATE TABLE routine_schedules|CREATE TABLE routine_occurrences|CREATE TABLE pending_reminders" \

lib/core/database/

# P0-6 : وابستگی‌ها برای گزارش اثر حذف

rg -n "linkedRoutineId|dependsOnRoutineId|linkedGoalId" lib/

# P0-7 : رویدادهای موجود (⛔ حق ساخت رویداد جدید نداری)

rg -n "enum RitmoEventType|routineChanged|courseChanged|goalChanged|worshipChanged|completionRecorded" \

lib/core/domain/engines/ritmo_event_type.dart

# P0-8 : کلید یتیم ماژول

rg -n "module_sports_enabled" lib/ android/

# P0-9 : ریپازیتوری‌های منبع

rg -n "class CoursesRepository|class GoalsRepository|class MovementRepository|class MedicationSaveHelper" lib/

# P0-10 : Opener های پلنر (قانون «پنجرهٔ همان ماژول»)

rg -n "setCourseSheetOpener|setGoalSheetOpener|setMustahabSheetOpener|setSportsLogSheetOpener" lib/

```

**شرط‌های توقف:**
| شرط | اقدام |
|---|---|
| `TimelineSplitDayView` وجود ندارد | ⛔ توقف کامل — ۰۲۸ اجرا نشده |
| ساختار `Row` سه‌آیکنی هدر تقویم متفاوت است | ⛔ توقف — گزارش بده ساختار واقعی چیست |
| `RitmoEventType` فاقد یکی از پنج رویداد بالاست | ⚠️ ادامه بده ولی در گزارش قید کن |

اگر نام ستونی که در این پرامپت آمده با خروجی `P0-5` نمی‌خواند، **نام واقعی کد را مبنا بگیر** و در گزارش تفاوت را بنویس.

---

## بخش ۱ — تعریف مفهومی (این را قبل از کدزدن بخوان)

ریتمو سه لایهٔ متمایز دارد که تا امروز هیچ‌جا از هم تفکیک نشده‌اند:

| لایه | مثال | جدول |
|---|---|---|
| **تعریف** | «مطالعهٔ شب، ۴۵ دقیقه، شنبه تا چهارشنبه» | `routines`, `courses`, `goals`, `worship_practices` |
| **زمان‌بندی** | «ساعت ۲۲:۰۰» | `routine_schedules` |
| **رخداد** | «سه‌شنبه ۱۴۰۴/۰۵/۰۳ انجام شد» | `routine_occurrences`, `routine_completions` |

`DayAgendaService` لایهٔ **رخداد** یک روز را می‌دهد.
`AllPlansService` که در این پرامپت می‌سازی لایهٔ **تعریف** را بدون قید تاریخ می‌دهد.

**قانون طلایی:** مخزن یک **نمای فقط‌خواندنی تجمیعی** است. هیچ نوشتنی مستقیم در آن انجام نمی‌شود؛ هر عمل نوشتن به مالک اصلی داده (ریپازیتوری/کامند موجود) واگذار می‌شود.

⛔ **ممنوعیت مطلق:** ساختن جدول آینه‌ای مثل `registry_items` که کپی تعاریف را نگه دارد. با هشت مسیر موازی ثبت انجام که در اپ وجود دارد، این جدول ظرف یک هفته پر از ردیف زامبی می‌شود و اصل تک‌منبع‌حقیقت را نقض می‌کند.

---

## بخش ۲ — لایهٔ دامنه

### T1 — `lib/features/registry/domain/registry_entry.dart`

```

enum RegistryDomain {

routine, course, goal, worship, worshipDebt,

medicine, konkur, movementKind, workoutPlan, doctorVisit,

}

extension RegistryDomainX on RegistryDomain {

String get faLabel { / *روتین، دوره، هدف، عبادت، بدهی عبادی، دارو، کنکور، حرکت، برنامهٔ تمرین، نوبت پزشک* / }

IconData get icon { / *دقیقاً همان آیکن‌های timeline_item_card.dart* / }

Color color(BuildContext c) { / *دقیقاً همان رنگ‌های timeline_item_card.dart* / }

String get settingsKey; // مثلاً 'module_courses_enabled'؛ برای routine مقدار '' بده

}

enum RegistryStatus { active, paused, archived, completed, expired }

enum ReminderHealth {

off,      // 🔕 یادآور خاموش است — طبیعی

armed,    // 🔔 روشن و رکورد SCHEDULED دارد — سالم

silent,   // ⚠️ روشن است ولی هیچ رکورد SCHEDULED ندارد — نمی‌آید

overdue,  // 🔴 رکورد در گذشته مانده و state هنوز unknown است

}

```

```

class RegistryCapabilities {

final bool canEdit, canDelete, canArchive, canPause, canToggleReminder, canDuplicate;

const RegistryCapabilities({ / *همه با پیش‌فرض true* / });

/// نماز واجب و مستحبات پیش‌فرض: هیچ عملی مجاز نیست جز تنظیم یادآور

const RegistryCapabilities.systemGenerated()

: canEdit = false, canDelete = false, canArchive = false,

canPause = false, canToggleReminder = true, canDuplicate = false;

}

```

```

class RegistryEntry {

final String id;                 // '<domain>:<sourceId>' مثل 'routine:rt_abc'

final RegistryDomain domain;

final String sourceId;           // شناسهٔ خام در جدول مبدأ

final String title;

final String? subtitle;

final String scheduleSummary;    // 'شنبه تا چهارشنبه · ۰۸:۰۰'  یا  'بدون زمان‌بندی'

final String? nextRunDateStr;    // 'YYYY-MM-DD' یا null

final RegistryStatus status;

final ReminderHealth reminderHealth;

final int? streakDays;

final double? completionRate30d; // 0.0..1.0

final bool isEssential;

final RegistryCapabilities caps;

final AgendaItem agendaProxy;    // برای [ActionRouter.open](http://ActionRouter.open)

final Map<String, dynamic> meta;

}

```

**`agendaProxy` چیست:** یک `AgendaItem` سبک با `dateStr = nextRunDateStr ?? today` و `deepLink` صحیح، صرفاً برای اینکه بتوانیم `ActionRouter.open(context, item: e.agendaProxy)` را صدا بزنیم.
⛔ **هیچ شیت جدیدی برای مشاهده/ویرایش نساز.** قانون «پنجرهٔ همان ماژول» بی‌قید و شرط رعایت می‌شود.

### T2 — `lib/features/registry/domain/registry_query.dart`

```

enum RegistryLens { items, reminders, health }

enum RegistryGrouping { domain, timeOfDay, status, streak }

class RegistryQuery {

final RegistryLens lens;

final String searchText;

final Set<RegistryDomain> domainFilter;   // خالی = همه

final Set<RegistryStatus> statusFilter;   // پیش‌فرض {active, paused}

final RegistryGrouping grouping;

final bool showArchived;                  // پیش‌فرض false

}

```

### T3 — `lib/features/registry/domain/delete_impact_report.dart`

```

class DeleteImpactReport {

final int completionCount;       // تعداد ردیف در routine_completions

final int occurrenceCount;       // تعداد ردیف pending در routine_occurrences

final int activeReminderCount;   // pending_reminders با state SCHEDULED/unknown/delayed

final int longestStreakDays;

final List<String> orphanedDependents; // عنوان گام‌های هدف / دوره‌های متصل

final bool isIrreversible;

String toFaSentence();

// مثال خروجی: «۴۲ ثبت انجام · زنجیرهٔ ۱۲ روزه · ۳ یادآور فعال · ۱ گام هدف بی‌سرپرست می‌شود»

}

```

### T4 — `lib/features/registry/domain/registry_health_issue.dart`

```

enum HealthIssueKind {

routineWithoutSchedule,   // بازرس ۱

orphanReminder,           // بازرس ۲

silentReminder,           // بازرس ۳

expiredAlarm,             // بازرس ۴

duplicateTitle,           // بازرس ۵

orphanModuleData,         // بازرس ۶

orphanSettingsKey,        // بازرس ۷

invalidDuration,          // بازرس ۸

chronicTimeConflict,      // بازرس ۹

}

enum HealthSeverity { info, warning, critical }

class RegistryHealthIssue {

final HealthIssueKind kind;

final HealthSeverity severity;

final String title;          // فارسی، کوتاه

final String description;    // فارسی، توضیح پیامد

final String fixLabel;       // برچسب دکمهٔ رفع

final List<String> affectedIds;

final Future<void> Function(BuildContext) fix;  // رفع تک‌ضربه‌ای

}

```

---

## بخش ۳ — منابع داده

### T5 — `lib/features/registry/logic/sources/registry_source.dart`

```

abstract class RegistrySource {

RegistryDomain get domain;

String get moduleSettingsKey;               // '' یعنی همیشه فعال

Future<int> count({bool includeArchived = false});

Future<List<RegistryEntry>> fetch({

required int limit, required int offset, bool includeArchived = false,

});

}

```

### T6 تا T13 — پیاده‌سازی هشت منبع

| فایل | جدول مبدأ | نکتهٔ حیاتی |
|---|---|---|
| `routine_registry_source.dart` | `routines` + `routine_schedules` | فقط ردیف‌هایی که `itemType` دارویی نیستند |
| `course_registry_source.dart` | `courses` + `course_sessions` | `scheduleSummary` از جلسات ساخته می‌شود |
| `goal_registry_source.dart` | `goals` + `goal_steps` | زیرعنوان: «۳ از ۷ گام» |
| `worship_registry_source.dart` | `worship_practices` | نماز واجب و مستحب پیش‌فرض → `.systemGenerated()` |
| `worship_debt_registry_source.dart` | `worship_debts` | زیرعنوان: تعداد باقی‌مانده |
| `medicine_registry_source.dart` | `routines` با `itemType` دارویی | نمایش `medStockCount` اگر زیر `medRefillThreshold` بود |
| `konkur_registry_source.dart` | `konkur_subjects` + `konkur_topics` | |
| `movement_registry_source.dart` | `MovementRepository.getKinds()` + `ss_workout_plan` | فقط `isCustom` قابل حذف است |

**قواعد مشترک برای همهٔ منابع:**

1. اگر `moduleSettingsKey` خاموش باشد → `count()` صفر و `fetch()` لیست خالی برگرداند (بدون خطا).
2. ⛔ هیچ‌کدام حق ندارند `SELECT *` بزنند؛ فقط ستون‌های لازم.
3. `scheduleSummary` باید از یک تابع مشترک `ScheduleSummaryFormatter.format(...)` بیاید، نه منطق تکراری در هر منبع.
4. `daysOfWeek` با ترتیب فارسی `[6,7,1,2,3,4,5]` تفسیر شود (شنبه اول). اگر هر هفت روز بود → «هر روز». اگر پنج روز پیوسته بود → «شنبه تا چهارشنبه».
5. `streakDays` و `completionRate30d` **در فاز A محاسبه نشوند** (بخش ۴ را ببین).

### T14 — `reminder_registry_source.dart` (عدسی 🔔)

این منبع الگوی متفاوتی دارد — مستقیماً روی `pending_reminders` کار می‌کند و از همان JOIN موجود در `reminder_snapshot_service.dart` الگو می‌گیرد:

```

SELECT [pr.id](http://pr.id), pr.routineId, pr.scheduledTime, pr.state, pr.deferCount,

COALESCE(r.title, 'نوبت پزشک: '||dv.doctorName, 'کلاس: '||c.title, [pr.id](http://pr.id)) AS title,

CASE WHEN [r.id](http://r.id) IS NULL AND [dv.id](http://dv.id) IS NULL AND [cs.id](http://cs.id) IS NULL THEN 1 ELSE 0 END AS isOrphan

FROM pending_reminders pr

LEFT JOIN routines r        ON pr.routineId = [r.id](http://r.id)

LEFT JOIN doctor_visits dv  ON [pr.id](http://pr.id) = 'visit_' || [dv.id](http://dv.id)

LEFT JOIN course_sessions cs ON pr.courseSessionId = [cs.id](http://cs.id)

LEFT JOIN courses c         ON cs.courseId = [c.id](http://c.id)

WHERE pr.state IN ('unknown','delayed','SCHEDULED')

ORDER BY pr.scheduledTime ASC

```

**استثنا:** `routineId = 'cycle_private_reminder'` روتین واقعی نیست — یتیم حساب **نشود** و عنوانش «یادآور خصوصی» نمایش داده شود (بدون افشای جزئیات، طبق `CyclePrivacyGuard`).

---

## بخش ۴ — سرویس، کش و کارایی

### T15 — `lib/features/registry/logic/registry_index.dart`

تک‌نمونه (`RegistryIndex.instance`) با کش در حافظه.

**بارگذاری دوفازی — الزامی:**

| فاز | محتوا | بودجهٔ زمانی |
|---|---|---|
| **A** | `COUNT` گروهی هر دامنه + ۲۰ ردیف اول دامنهٔ فعال | **< ۸۰ms** |
| **B** | بقیهٔ ردیف‌ها + `streakDays` + `completionRate30d` با `Future.wait` موازی | پس‌زمینه |

در فاز A ردیف‌ها بدون آمار رندر می‌شوند و جای آمار یک `Shimmer` نازک می‌نشیند. فاز B که رسید، فقط همان بخش با `AnimatedSwitcher` (۱۵۰ms) جایگزین می‌شود — **کل لیست دوباره ساخته نشود**.

**«اجرای بعدی» — یک کوئری برای کل مخزن:**

```

SELECT routine_id, MIN(date) AS nextDate

FROM routine_occurrences

WHERE date >= ? AND status = 'pending'

GROUP BY routine_id

```

⛔ **حق نداری قاعدهٔ تکرار (`recurrenceRule`) را در حافظه بسط بدهی.** جدول `routine_occurrences` از قبل تولید شده؛ فقط بخوان.

**ابطال کش — فقط با رویدادهای موجود:**

```

RitmoEventType.routineChanged      → invalidate({routine, medicine})

RitmoEventType.courseChanged       → invalidate({course})

RitmoEventType.goalChanged         → invalidate({goal})

RitmoEventType.worshipChanged      → invalidate({worship, worshipDebt})

RitmoEventType.workoutLogChanged   → invalidate({movementKind, workoutPlan})

RitmoEventType.completionRecorded  → فقط آمار همان یک ردیف تازه شود، نه کل دامنه

```

⛔ **ساختن هیچ `RitmoEventType` جدیدی مجاز نیست.**

`dispose()` باید همهٔ اشتراک‌های `RitmoEventBus` را لغو کند.

### T16 — `registry_service.dart`

```

class RegistryService {

Future<List<RegistryEntry>> query(RegistryQuery q);

Future<int> healthIssueCount();          // برای نقطهٔ قرمز روی آیکن هدر

Future<DeleteImpactReport> impactOf(RegistryEntry e);

}

```

**جست‌وجو — نرمال‌سازی اجباری:**

```

String _normalizeFa(String s) => s

.replaceAll('ي', 'ی').replaceAll('ك', 'ک')

.replaceAll('u200c', ' ')                    // نیم‌فاصله

.replaceAll(RegExp(r'[u064B-u0652]'), '')   // اعراب

.replaceAll(RegExp(r's+'), ' ')

.trim().toLowerCase();

```

اول تطبیق زیررشته‌ای؛ اگر کمتر از ۳ نتیجه بود، `text_similarity` با آستانهٔ `0.62` هم اضافه شود (نتایج فازی با برچسب کمرنگ «شبیه»).

---

## بخش ۵ — ۹ بازرس سلامت

### T17 — `lib/features/registry/logic/registry_health_audit.dart`

هر بازرس یک متد مستقل با امضای `Future<RegistryHealthIssue?> _inspectX()` است. کل ممیزی با `Future.wait` موازی اجرا می‌شود و **نباید بیش از ۴۰۰ms** طول بکشد.

| # | بازرس | تشخیص | رفع تک‌ضربه‌ای | شدت |
|---|---|---|---|---|
| ۱ | روتین بدون زمان‌بندی | `routines LEFT JOIN routine_schedules` که `routine_schedules.id IS NULL` و `isArchived = 0` | باز کردن `UniversalPlannerSheet` در حالت ویرایش همان روتین | warning |
| ۲ | یادآور بی‌صاحب | `pending_reminders` که `routineId` در `routines` نیست، الگوی `visit_` ندارد، `courseSessionId` ندارد و `cycle_private_reminder` نیست | حذف رکورد + `cancelAlarm(id)` | critical |
| ۳ | یادآور بی‌صدا | روتین `notificationLevel` فعال دارد ولی هیچ ردیف `state='SCHEDULED'` در آینده ندارد | فراخوانی مجدد `AlarmSchedulerService` برای همان روتین | critical |
| ۴ | آلارم منقضی | `state='unknown'` و `scheduledTime < now − 24h` | `UPDATE pending_reminders SET state='expired'` | warning |
| ۵ | عنوان تکراری | دو تعریف هم‌دامنه با `text_similarity ≥ 0.90` | نمایش هر دو کنار هم + دکمهٔ «باز کردن» برای تصمیم دستی کاربر — ⛔ ادغام خودکار ممنوع | info |
| ۶ | دادهٔ ماژول خاموش | ردیف‌های دامنه‌ای که `module_*_enabled = false` است | نمایش تعداد + دکمهٔ «روشن کردن ماژول» یا «پاک‌سازی» (با تأیید دوم) | info |
| ۷ | کلید تنظیمات یتیم | وجود `module_sports_enabled` در `app_settings` | حذف کلید (بخش ۷ / B2 را ببین) | info |
| ۸ | مدت نامعتبر | `targetDurationMinutes > DurationBounds.maxMinutes` یا `<= 0` | `clamp` با `DurationBounds.sanitize()` | warning |
| ۹ | تداخل مزمن | دو تعریف با هم‌پوشانی زمانی در ≥ ۴ روز از هفته | باز کردن هر دو پشت سر هم برای اصلاح | warning |

**قواعد بازرس‌ها:**
- هر رفع باید **idempotent** باشد؛ زدن دوباره‌اش خطا ندهد.
- پس از هر رفع، `RegistryIndex.invalidate()` و ممیزی مجدد **فقط همان بازرس**.
- هیچ بازرسی حق `DELETE` روی جداول دادهٔ کاربر ندارد به‌جز بازرس ۲ (که فقط ردیف یتیم `pending_reminders` را پاک می‌کند) و بازرس ۷ (کلید تنظیمات).

---

## بخش ۶ — رابط کاربری

### T18 — `all_plans_screen.dart`

`Scaffold` تمام‌صفحه با `AppBar` سادهٔ فارسی «همه برنامه‌ها».

**چیدمان از بالا:**

1. **نوار جست‌وجو** — `TextField` با `debounce` ۲۵۰ms، آیکن پاک‌کردن، `textDirection: TextDirection.rtl`
2. **سگمنت عدسی** — سه گزینه با استایل `JourneyScaleSwitcher` موجود (تکرار نکن، همان ویجت را با پارامتر عمومی‌شده استفاده کن یا کپی سبک بساز):
   `📚 آیتم‌ها (۴۷)` · `🔔 یادآورها (۱۲)` · `🩺 سلامت` ← نقطهٔ قرمز اگر ناهنجاری > ۰
3. **چیپ‌های فیلتر افقی** — `همه · روتین · دوره · هدف · عبادت · دارو · کنکور · تمرین · بایگانی`
   چیپ دامنه‌های خاموش اصلاً نمایش داده نشود.
4. **`ListView.builder`** مجازی‌شده با `RepaintBoundary` روی هر ردیف و `itemExtent` ثابت (کارایی اسکرول)

**FAB:** `UniversalPlannerSheet` موجود — ⛔ هیچ مسیر ساخت جدیدی نساز.

### T19 — `registry_row.dart`

```

┌────────────────────────────────────────────────┐

│ [آیکن]  عنوان                        [نشان یادآور] │

│         شنبه تا چهارشنبه · ۰۸:۰۰ · بعدی: فردا      │

│         🔥 ۱۲ روز        ▓▓▓▓▓░░ ۷۳٪              │

└────────────────────────────────────────────────┘

```

- نوار لهجه‌ای عمودی سمت راست به رنگ دامنه، عرض `CalendarTokens.accentBarWidth`
- نشان یادآور: `off` خاکستری · `armed` سبز `emerald` · `silent` کهربایی · `overdue` قرمز
- ردیف بایگانی‌شده: کل کارت با `opacity 0.5` و برچسب «بایگانی»

**حرکات:**

| حرکت | نتیجه |
|---|---|
| ضربه | `ActionRouter.open(context, item: entry.agendaProxy)` |
| **کشیدن به چپ** | **بایگانی** (`isArchived = 1`) + `SnackBar` با «بازگردانی» ۵ ثانیه |
| کشیدن به راست | توقف موقت / ازسرگیری |
| فشار طولانی | ورود به حالت انتخاب چندتایی |

اگر `caps.canArchive == false` → `Dismissible` غیرفعال و هپتیک `RitmoHaptics.warning()` با توست «این مورد سیستمی است».

### T20 — `registry_bulk_bar.dart`

نوار پایین در حالت انتخاب چندتایی: `توقف · بایگانی · تغییر ساعت · حذف`

⛔ **حیاتی:** کل عملیات دسته‌جمعی باید **یک کامند واحد** روی `CommandStack` باشد، نه N کامند. یعنی یک `RegistryBulkCommand` که در `undo()` همهٔ تغییرات را با هم برمی‌گرداند.

### T21 — `delete_impact_dialog.dart`

حذف کامل **فقط** از منوی سه‌نقطهٔ داخل شیت جزئیات یا نوار دسته‌جمعی، و همیشه با این دیالوگ:

```

حذف «مطالعهٔ شب»؟

این موارد از بین می‌روند:

- ۴۲ ثبت انجام
- زنجیرهٔ ۱۲ روزه
- ۳ یادآور فعال
- ۱ گام هدف بی‌سرپرست می‌شود

[ بایگانی کن ]   [ حذف کامل ]

```

دکمهٔ «بایگانی کن» **پیش‌فرض و برجسته** است. پس از حذف، ۱۰ ثانیه پنجرهٔ برگشت با `CommandStack`.

### T22 — `registry_health_card.dart`

هر ناهنجاری یک کارت: آیکن شدت، عنوان، توضیح، دکمهٔ رفع. پس از رفع، کارت با انیمیشن `SizeTransition` ۲۰۰ms جمع می‌شود و یک ✅ سبز کوتاه نشان می‌دهد.

اگر هیچ ناهنجاری نبود: حالت خالی با «همه چیز مرتب است 🎉».

---

## بخش ۷ — اتصال به تقویم و رفع باگ‌ها

### T23 — آیکن هدر (`journey_screen.dart`)

فرزند سوم `Row` هدر (بین جست‌وجو و بازخوانی) اضافه شود. در RTL نتیجه می‌شود: `[خلاصه روز] [جست‌وجو] [همه برنامه‌ها] [بازخوانی]`

```

SizedBox(

width: 36, height: 36,

child: Stack(clipBehavior: Clip.none, children: [

IconButton(

padding: [EdgeInsets.zero](http://EdgeInsets.zero),

icon: const Icon(Icons.list_alt_rounded, size: 20),

tooltip: 'همه برنامه‌ها',

onPressed: _openAllPlans,

),

if (_registryHealthCount > 0)

Positioned(top: 7, left: 7, child: Container(

width: 7, height: 7,

decoration: const BoxDecoration(color: Color(0xffF43F5E), shape: [BoxShape.circle](http://BoxShape.circle)),

)),

]),

),

```

`_registryHealthCount` در `initState` و پس از رویدادهای `RitmoEventBus` تازه شود.

⛔ **`journey_smart_panel.dart` اصلاً باز نشود.** تب چهارمی در کار نیست.

### T24 — **باگ B1: جست‌وجوی تقویم فقط روز جاری را می‌گردد** 🔴

**وضعیت فعلی:**
```

delegate: CalendarSearchDelegate(items: snapshot?.items ?? [])

```
کاربر «مطالعهٔ شب» را می‌زند، امروز رخداد ندارد، **هیچ نتیجه‌ای نمی‌گیرد** — در حالی که فکر می‌کند دارد کل اپ را می‌گردد.

**رفع:**
```

CalendarSearchDelegate({

required this.items,                 // رخدادهای روز جاری (بدون تغییر)

required this.registryEntries,       // 🆕 تعاریف کل مخزن

})

```

نتایج در **دو گروه با هدر** نمایش داده شوند:
- `در این روز (۳)` → رفتار فعلی حفظ شود؛ `close(context, item)` و سپس `_openItemDetails`
- `همهٔ برنامه‌ها (۷)` → `ActionRouter.open(context, item: entry.agendaProxy)`

اگر گروه اول خالی بود، هدرش اصلاً رندر نشود. نرمال‌سازی فارسی T16 در هر دو گروه اعمال شود (الان حتی روز جاری هم `ی/ي` را تطبیق نمی‌دهد).

### T25 — **باگ B2: کلید یتیم `module_sports_enabled`** 🔴

ماژول «ورزش» حذف و در «ورزش تکمیلی» ادغام شده، ولی کلیدش هنوز در `allModuleKeys` هست و در `day_agenda_service.dart` هم چک می‌شود:
```

sportsEnabled = module_sports_enabled || module_supplementary_sports_enabled

```

**رفع:**
1. `'module_sports_enabled'` از `allModuleKeys` در `module_management_service.dart` حذف شود.
2. شرط بالا به فقط `module_supplementary_sports_enabled` ساده شود.
3. یک پاک‌سازی یک‌بارهٔ **بدون مهاجرت** در `RegistryHealthAudit` بازرس ۷: اگر کلید در `app_settings` بود، پیش از حذف مقدارش را با `OR` در کلید جدید ادغام کن، بعد حذف کن.
4. هر ارجاع باقی‌مانده در `lib/` و `android/` پاک شود.

### T26 — **باگ B3: کد مرده** 🔴

طبق `nimbalyst-local/plans/merge-calendar-routines.md` صفحهٔ `RoutinesListScreen` باید حذف می‌شد (۸۰۰–۱۰۰۰ خط تکراری با `calendar_screen.dart`).

اگر `P0-4` وجودش را تأیید کرد:
- فایل `routines_list_screen.dart` **کامل حذف** شود
- همهٔ `import` ها و ارجاع‌هایش پاک شوند
- هر مسیر ناوبری که به آن می‌رفت به `AllPlansScreen` تغییر کند
- تست‌های وابسته حذف یا بازنویسی شوند

اگر وجود نداشت، در گزارش بنویس «قبلاً حذف شده».

**همچنین:** هر ویجت/متد بدون ارجاع که در این کار به آن برخوردی حذف کن و در گزارش فهرست کن. `flutter analyze` باید صفر هشدار `unused_element` و `unused_import` بدهد.

### T27 — **باگ B4: حذف بدون بررسی وابستگی** 🔴

هیچ‌کدام از این سه ارجاع هنگام حذف بررسی نمی‌شوند:
`goal_steps.linkedRoutineId` · `courses.linkedGoalId` · `routines.dependsOnRoutineId`

**رفع:** `RegistryService.impactOf()` هر سه را کوئری کند و در `orphanedDependents` بگذارد. اگر لیست خالی نبود، متن دیالوگ پررنگ‌تر و دکمهٔ «حذف کامل» به رنگ خطر شود.

### T28 — **باگ B5: `state` آلارم‌های گذشته هرگز پاک نمی‌شود**

رکوردهای `unknown` که زمانشان گذشته برای همیشه در `pending_reminders` می‌مانند و کوئری‌های یادآور را سنگین می‌کنند.
**رفع:** بازرس ۴ + یک پاک‌سازی سبک در `EndOfDaySweep` (اگر وجود دارد) که رکوردهای قدیمی‌تر از ۳۰ روز با `state IN ('expired','CANCELLED','sent','opened')` را حذف کند.

### T29 — **باگ B6: مدت‌های غیرمنطقی**

`targetDurationMinutes` بدون کران ذخیره می‌شود و در تایم‌لاین کارت‌های غول‌پیکر می‌سازد (ریشهٔ باگی که در ۰۲۷ موضعی رفع شد).
**رفع:** بازرس ۸ + اعمال `DurationBounds.sanitize()` در نقطهٔ نوشتن `planner_controller.dart` هنگام ذخیره.

---

## بخش ۸ — تست‌ها

### T30 — تست‌های واحد

| فایل | آنچه اثبات می‌کند |
|---|---|
| `registry_entry_id_test.dart` | فرمت `'<domain>:<sourceId>'` و برگشت‌پذیری آن |
| `schedule_summary_formatter_test.dart` | «هر روز» · «شنبه تا چهارشنبه» · «بدون زمان‌بندی» · ترتیب `[6,7,1,2,3,4,5]` |
| `registry_search_normalize_test.dart` | `ي→ی` · `ك→ک` · نیم‌فاصله · اعراب · فازی با آستانهٔ `0.62` |
| `registry_capabilities_test.dart` | نماز واجب: `canDelete == false` |
| `registry_index_invalidation_test.dart` | `routineChanged` هر دو دامنهٔ `routine` و `medicine` را باطل می‌کند |
| `next_run_query_test.dart` | یک کوئری `GROUP BY` برای N روتین (شمارش تعداد کوئری‌ها) |
| `delete_impact_report_test.dart` | شناسایی هر سه نوع وابستگی |
| `health_audit_orphan_reminder_test.dart` | `cycle_private_reminder` و `visit_*` یتیم شمرده **نشوند** |
| `health_audit_idempotent_test.dart` | دوبار زدن هر رفع، خطا ندهد |
| `bulk_command_undo_test.dart` | بایگانی دسته‌جمعی ۵ آیتم با **یک** `undo` برمی‌گردد |
| `module_off_returns_empty_test.dart` | ماژول خاموش → `count() == 0` بدون استثنا |

### T31 — تست‌های ویجت

| فایل | آنچه اثبات می‌کند |
|---|---|
| `all_plans_two_phase_load_test.dart` | فاز A بدون آمار رندر می‌شود، فاز B فقط آمار را جایگزین می‌کند |
| `registry_swipe_archive_test.dart` | کشیدن به چپ = بایگانی، نه حذف |
| `registry_system_item_no_swipe_test.dart` | نماز واجب قابل کشیدن نیست |
| `calendar_search_two_groups_test.dart` | جست‌وجوی عبارتی که امروز رخداد ندارد، در گروه «همهٔ برنامه‌ها» نتیجه می‌دهد |
| `header_icon_badge_test.dart` | نقطهٔ قرمز فقط وقتی ناهنجاری > ۰ |
| `registry_rtl_layout_test.dart` | ترتیب چهار آیکن هدر در RTL |

---

## بخش ۹ — سناریوهای پذیرش

ایجنت باید هر سناریو را دستی اجرا و نتیجه را در گزارش بنویسد.

| # | سناریو | انتظار |
|---|---|---|
| S1 | آیکن «همه برنامه‌ها» را بزن | صفحهٔ تمام‌صفحه باز می‌شود، اولین رندر زیر ۸۰ms |
| S2 | یک روتین را ضربه بزن | همان شیت همیشگی روتین باز می‌شود، نه شیت جدید |
| S3 | یک دوره را ضربه بزن | شیت دورهٔ موجود باز می‌شود |
| S4 | روتین را به چپ بکش | بایگانی می‌شود + اسنک‌بار بازگردانی؛ با ضربه روی بازگردانی برمی‌گردد |
| S5 | نماز ظهر را به چپ بکش | حرکت انجام نمی‌شود، توست «مورد سیستمی» |
| S6 | فشار طولانی روی ۵ آیتم و بایگانی دسته‌جمعی | یک `undo` هر پنج را برمی‌گرداند |
| S7 | یک روتین با ۴۰+ ثبت را حذف کن | دیالوگ اثر با اعداد درست فارسی؛ «بایگانی کن» پیش‌فرض است |
| S8 | «مطالعه شب» را در جست‌وجوی تقویم بزن (امروز رخداد ندارد) | زیر گروه «همهٔ برنامه‌ها» پیدا می‌شود |
| S9 | «مطالعه شب» را با `ي` عربی بنویس | همان نتیجه می‌آید |
| S10 | عدسی 🩺 را باز کن | ۹ بازرس اجرا شده، زیر ۴۰۰ms |
| S11 | یک «یادآور بی‌صاحب» را رفع کن | رکورد حذف، آلارم کنسل، کارت جمع می‌شود، شمارندهٔ هدر کم می‌شود |
| S12 | همان رفع را دوباره بزن | خطا نمی‌دهد |
| S13 | ماژول دوره‌ها را خاموش کن و برگرد | چیپ «دوره» ناپدید می‌شود، هیچ ردیف دوره‌ای نیست، هیچ کرشی نیست |
| S14 | FAB را بزن | `UniversalPlannerSheet` موجود باز می‌شود |
| S15 | روتینی از مخزن ویرایش کن، به تقویم برگرد | تغییر بلافاصله دیده می‌شود (کش باطل شده) |
| S16 | تقویم را چک کن | نمای دو ستونی ۰۲۸ کاملاً سالم است |
| S17 | ۲۰۰ تعریف بساز و اسکرول کن | بدون jank، بدون بازساخت کل لیست |

---

## بخش ۱۰ — خطوط قرمز

⛔ **۱.** هیچ جدول، ستون یا مهاجرت جدیدی. اگر فکر کردی لازم است، متوقف شو و در گزارش بنویس چرا.

⛔ **۲.** هیچ `RitmoEventType` جدیدی.

⛔ **۳.** هیچ شیت ساخت/ویرایش جدیدی. هر افزودن یا ویرایش از **پنجرهٔ همان ماژول** انجام می‌شود:
`CreateCourseSheet` · `CreateGoalSheet` · `AddCustomMustahabSheet` · `MedicationFormSheet` · `showMovementLogSheet` · `UniversalPlannerSheet`

⛔ **۴.** این فایل‌های ۰۲۸ **اصلاً لمس نشوند**:
`timeline_split_day_view.dart` · `timeline_column_header.dart` · `timeline_overflow_card.dart` · `timeline_grid.dart` · `timeline_hour_axis.dart` · `timeline_layout_engine.dart` · `timeline_untimed_section.dart` · `journey_controller.dart` · `calendar_motion.dart` · `direct_manipulation_eligibility.dart`

⛔ **۵.** `journey_smart_panel.dart` و سه تب «خلاصه / پیشنهادها / زمان آزاد» دست‌نخورده بمانند.

⛔ **۶.** از `calendar_tokens.dart` فقط **بخوان**. توکن جدید لازم داشتی، در `lib/features/registry/presentation/registry_tokens.dart` بگذار.

⛔ **۷.** هیچ حذف دائمی بدون `DeleteImpactDialog`.

⛔ **۸.** هیچ ادغام خودکار عنوان‌های تکراری.

⛔ **۹.** هیچ `SELECT *` و هیچ کوئری داخل حلقه (N+1).

⛔ **۱۰.** `CyclePrivacyGuard` در همهٔ مسیرهای مخزن رعایت شود.

---

## فقط این فایل‌های خارج از `lib/features/registry/` مجاز به تغییرند

```

lib/features/calendar/presentation/journey_screen.dart              (فقط افزودن آیکن + پاس دادن registryEntries)

lib/features/calendar/presentation/widgets/calendar_search_delegate.dart  (پارامتر دوم + دو گروه)

lib/core/services/module_management_service.dart                    (حذف کلید یتیم)

lib/core/domain/agenda/day_agenda_service.dart                      (ساده‌سازی شرط sportsEnabled)

lib/features/routines/presentation/planner_controller.dart          (اعمال DurationBounds.sanitize)

lib/features/.../routines_list_screen.dart                          (حذف کامل)

```

هر فایل دیگری خارج از این فهرست لمس شد، دلیلش را در گزارش بنویس.

---

## گزارش پایانی — `prompts/029_REPORT.md`

بنویس و این‌ها را حتماً شامل شو:

1. خروجی هر ده دستور `PASS 0`
2. فهرست کامل فایل‌های ساخته‌شده، تغییریافته و **حذف‌شده**
3. برای هر T1–T31: ✅ انجام شد / ⚠️ جزئی (با توضیح) / ❌ انجام نشد (با دلیل)
4. برای هر باگ B1–B6: چه بود، کجا بود، چطور رفع شد، کدام تست اثباتش می‌کند
5. نتیجهٔ هر ۱۷ سناریو
6. خروجی کامل `flutter analyze` — باید **صفر issue** باشد
7. خروجی `flutter test` با تعداد تست‌های قبل و بعد
8. **زمان اندازه‌گیری‌شدهٔ فاز A** روی دیتاست ۲۰۰ تعریف
9. فهرست کد مردهٔ حذف‌شده
10. هر جایی که مجبور شدی از این پرامپت انحراف پیدا کنی و **چرا**

⛔ اگر تستی fail شد یا `flutter analyze` هشدار داد، **گزارش را «موفق» ننویس**.
```

---
