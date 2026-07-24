
```
# ۰۲۲ — بازسازی کامل «ایجاد ایستگاه جدید»

تو ایجنت کدنویس ارشد پروژهٔ **ریتمو** (اپ Flutter فارسی/RTL) هستی.
این سند **نقشهٔ اجرای نهایی** است. برای خودت نقشهٔ جدید نکش، طراحی جایگزین
پیشنهاد نده، و ترتیب تسک‌ها را عوض نکن. مستقیم برو سراغ اجرا.

---

# بخش ۰ — زمینه، دامنه و پیش‌نیازها

## ۰٫۱ مسئله

«ایجاد ایستگاه جدید» امروز **چهار مسیر موازی نوشتن** دارد و در هر ماژول
تخصصی (دوره، هدف، عبادت، ورزش، دارو) بین «شیت کانونی همان ماژول» و
«استراتژی داخل پلنر» تقسیم شده است. نتیجه: تکثیر رکورد، دور ریختن ورودی
کاربر، شناسه‌های ناسازگار، و رفرش‌نشدن UI.

این پرامپت پلنر را به **یک لایهٔ هماهنگ‌کننده** تبدیل می‌کند که خودش فقط
روتین/یادآور/کار می‌سازد و بقیه را به ماژول مالک تفویض می‌کند.

## ۰٫۲ نقشهٔ فایل‌ها

### هستهٔ پلنر (دامنهٔ اصلی کار)
```

lib/features/routines/presentation/

├── universal_planner_sheet.dart          -- پوستهٔ شیت، PageView سه‌مرحله‌ای، محل wire شدن openerها

├── planner_controller.dart               -- ChangeNotifier، ~۱۰۰ فیلد، save(context)

├── quick_add_parser.dart                 -- پارسر زبان طبیعی فارسی

├── routine_create_flow.dart              -- ⚠️ فلوی قدیمی موازی — بازنشسته می‌شود

└── widgets/

├── planner_natural_input.dart

├── planner_category_grid.dart

├── planner_timeline_picker.dart

├── planner_duration_picker.dart

├── planner_advanced_section.dart

├── planner_submit_button.dart

└── planner_journey_preview.dart

lib/features/routines/domain/

├── payloads/planner_payloads.dart        -- WorshipPlannerPayload, GoalPlannerPayload, ...

└── strategies/

├── planner_category_strategy.dart    -- قرارداد Strategy

├── planner_strategy_registry.dart    -- ترتیب resolve

├── planner_save_context.dart         -- ⚠️ ~۴۹ فیلد

├── generic_strategy.dart             -- ✅ می‌ماند

├── medical_strategy.dart             -- ⚠️ کد مرده (early-return در controller)

├── reflection_strategy.dart          -- ⚠️ ConflictAlgorithm.replace مخرب

├── worship_strategy.dart             -- ⚠️ نصفش حذف می‌شود

├── sports_strategy.dart              -- ⚠️ نصفش حذف می‌شود

├── course_strategy.dart              -- ❌ کامل حذف می‌شود

└── goal_strategy.dart                -- ❌ کامل حذف می‌شود

```

### شیت‌های کانونی ماژول‌ها (مالک واقعی داده)
```

lib/features/courses/presentation/widgets/create_course_sheet.dart

lib/features/goals/presentation/widgets/create_goal_sheet.dart

lib/features/worship/presentation/widgets/mustahab_section.dart   -- AddCustomMustahabSheet

lib/features/health/presentation/widgets/medication_form_sheet.dart

lib/features/health/presentation/widgets/medication_preview_sheet.dart

lib/features/sports/presentation/widgets/sports_quick_log_sheet.dart

```

### لایهٔ داده و کرنل
```

lib/core/kernel/ritmo_execution_kernel.dart

lib/core/domain/engines/ritmo_event_bus.dart

lib/core/domain/agenda/day_agenda_service.dart

lib/core/domain/agenda/sources/goal_steps_agenda_source.dart

lib/core/analytics/{goals_engine,courses_engine}.dart

lib/features/goals/logic/{goals_repository,goal_progress_calculator}.dart

lib/features/courses/logic/courses_repository.dart

lib/core/database/schema/schema_manager.dart

lib/core/database/schema/tables/{routine,goal,course,worship,sports,zone}_tables.dart

lib/core/database/database_helper.dart

lib/core/database/migration/migrations_registry.dart

```

## ۰٫۳ زیرساخت‌های موجود — بساز نکن، استفاده کن

| نیاز | از این استفاده کن |
|---|---|
| نوشتن روتین | `RitmoExecutionKernel.instance.execute(CreateRoutineCommand / EditRoutineCommand)` |
| جابه‌جایی هوشمند | `ReshuffleEngine.decideReshuffle(...)` از طریق `RitmoEngineBus` |
| اجندای روز | `DayAgendaService` |
| تخمین مدت | `DurationEstimator` |
| فراخوانی AI | `AiGateway` (timeout ۴۵۰۰۰ms) |
| رویداد | `RitmoEventBus().fire(RitmoEvent(...))` |
| توست | `RitmoToast.show(context, ...)` |
| تاریخ شمسی | `RitmoDatePicker` + package `shamsi_date` |
| هپتیک | `RitmoHaptics` |
| رنگ | `context.colors.*` — هرگز رنگ هاردکد |
| پیشرفت هدف | `goalProgress(goalId, allGoals, stepsByGoal, visited)` |

## ۰٫۴ پیش‌نیازهای بیرونی

⛔ **قبل از شروع PASS 0 این‌ها را تأیید کن. اگر برقرار نیستند، توقف کن و گزارش بده.**

1. تسک‌های `C1`–`C7` از `AGENT_PROMPT_COURSES_V2.md` merge شده باشند.
   مشخصاً: `CreateCourseSheet` وقتی با `initialValues` حاوی شناسهٔ یک دورهٔ
   موجود باز می‌شود، باید **همان دوره را update کند**، نه دورهٔ جدید بسازد.
2. اگر برقرار نیست، **وارد فاز ۱ نشو** — چون پلنر را به شیتی وصل می‌کنی که
   خودش باگ تکثیر دارد.

پیش‌نیازهای داخلی اهداف در **فاز ۰** همین سند انجام می‌شوند.

---

# بخش ۱ — قوانین سراسری

این ۱۲ قانون بر تک‌تک تسک‌ها حاکم‌اند.

## ۱. 🏅 قانون طلایی — تفویض به ماژول مالک

> **هر موجودیتی که ماژول اختصاصی دارد، فقط و فقط از پنجرهٔ افزودنِ خودِ
> همان ماژول ساخته و ویرایش می‌شود.**

پلنر برای این موجودیت‌ها **یک خط هم در دیتابیس نمی‌نویسد**. فقط شیت کانونی
همان ماژول را **از پیش پر شده** باز می‌کند و کار را به آن می‌سپارد. کاربر
باید دقیقاً همان فرم، همان ظاهر، همان دکمه‌ها و همان اعتبارسنجی‌ای را ببیند
که وقتی از داخل خود ماژول اقدام می‌کند.

| موجودیت / دسته | پنجرهٔ کانونی | opener |
|---|---|---|
| `COURSE` | `CreateCourseSheet` | `openCourseSheet(initialValues:)` |
| `GOAL` | `CreateGoalSheet` | `openGoalSheet(templateData:)` |
| `Category.religious` (مستحب) | `AddCustomMustahabSheet` | `openWorshipSheet(prefill:)` |
| `Category.medical` (دارو) | `MedicationFormSheet` → `MedicationPreviewSheet` | `openMedicalSheet(MedicationFormData)` |
| `Category.fitness` + `LOG` | `showSportsQuickLogSheet` | `openSportsLogSheet(...)` |
| `Category.fitness` + `ROUTINE` | خودِ پلنر | `CreateRoutineCommand` |
| بدهی عبادی | خودِ پلنر (شیت کانونی ندارد) | `CreateWorshipDebtCommand` |
| روتین / یادآور / کار / بازتاب | خودِ پلنر | Command کرنل |

**ممنوعیت مطلق:** از داخل `lib/features/routines/` هرگز
`CoursesRepository`، `GoalsRepository`، یا `db.insert/update` روی جداول
`courses`، `course_sessions`، `goals`، `goal_steps`، `worship_practices`،
`workout_logs` صدا زده نشود.

## ۲. تک نقطهٔ نوشتن

هر موجودیت **دقیقاً یک** نقطهٔ ساخت کاربری و **دقیقاً یک** لایهٔ نوشتن دارد.
جدول تأیید در تسک T31.

## ۳. 🗑 کد مرده پاک شود — نه کامنت، نه نگه‌داشتن «برای احتیاط»

هر چیزی که بعد از تغییرات این سند دیگر فراخوانی نمی‌شود، **فایلش حذف شود**:

- کلاس‌ها و فایل‌های استراتژی بازنشسته → `git rm`
- متدهای بدون فراخوان در `PlannerController` → حذف
- فیلدهای بدون مصرف در `PlannerSaveContext` و payloadها → حذف
- شاخه‌های `if` که شرطشان دیگر هرگز true نمی‌شود → حذف
- importهای بلااستفاده → حذف
- ویجت‌هایی که دیگر ساخته نمی‌شوند → حذف

**ممنوع:** کامنت‌کردن کد به‌جای حذف، گذاشتن `// deprecated` و رها کردن،
یا نگه‌داشتن فایل خالی. `git` تاریخچه را نگه می‌دارد؛ نیازی به نگه‌داشتن
جسد در درخت کد نیست.

**استثنا:** اگر حذف یک مورد باعث شکستن جایی خارج از دامنهٔ این سند می‌شود،
حذفش نکن و در REPORT زیر عنوان «کد مردهٔ خارج از دامنه» با مسیر دقیق فایل
و دلیل ثبت کن.

بعد از هر فاز `dart analyze` باید **صفر warning از نوع unused** بدهد.

## ۴. تنها مسیر نوشتن روتین: کرنل

هیچ `db.insert`/`db.update` مستقیمی روی `routines` و `routine_schedules`
از لایهٔ presentation. همه از `RitmoExecutionKernel` و داخل یک تراکنش.

## ۵. بدون حذف قابلیت

هر قابلیتی که امروز کاربر دارد باید بعد از این تغییرات هم داشته باشد
(احتمالاً با UI بهتر). اگر جایی مجبور به حذف شدی، در REPORT توجیه کن.

## ۶. بدون رشتهٔ جادویی

نوع رویداد، itemType، دسته، وضعیت — همه enum یا ثابت نام‌دار.

## ۷. فارسی، RTL، Vazirmatn

همهٔ متن‌های کاربر فارسی. `Directionality(textDirection: TextDirection.rtl)`.
فونت `Vazirmatn`. همهٔ اعداد نمایشی از `toPersianDigits()` رد شوند.

## ۸. بدون وابستگی جدید

هیچ package جدیدی به `pubspec.yaml` اضافه نشود — **تنها استثنا** تسک T28
(ورودی صوتی) که مجوز صریح دارد.

## ۹. بدون رنگ هاردکد

فقط `context.colors.*`. اگر رنگ لازم داری که در پالت نیست، به
`ritmo_theme.dart` اضافه کن.

## ۱۰. سبز بودن بعد از هر تسک

`flutter analyze` و `flutter test` بعد از **هر تسک** سبز. تسک بعدی را
با درخت قرمز شروع نکن.

## ۱۱. کامیت جدا به ازای هر تسک

پیام: `022/T<n>: <خلاصهٔ فارسی>`

## ۱۲. جزئیات اجرایی

- هر استفاده از `BuildContext` بعد از `await` با `if (!context.mounted) return;`
- تاریخ در دیتابیس همیشه ISO `YYYY-MM-DD`؛ شمسی فقط لایهٔ نمایش
- شناسه‌ها همیشه از `PlannerIdFactory` (تسک T10)

---

# PASS 0 — ممیزی اجباری قبل از هر تغییر

هیچ فایلی را تغییر نده تا این ۱۶ مورد را تأیید کنی. سپس **توقف کن**.

| # | چه چیزی را تأیید کن | از کجا |
|---|---|---|
| 1 | نسخهٔ فعلی دیتابیس (عدد دقیق) | `database_helper.dart` + `migrations_registry.dart` |
| 2 | امضای `RitmoExecutionKernel.execute` و لیست کامل Commandهای موجود | `lib/core/kernel/` |
| 3 | امضای `CreateRoutineCommand` و `EditRoutineCommand` | همان |
| 4 | امضای `ReshuffleEngine.decideReshuffle` | `lib/core/domain/engines/` |
| 5 | API عمومی `DayAgendaService` و کلیدهای کش آن | `day_agenda_service.dart` |
| 6 | امضای `DurationEstimator` | مسیرش را پیدا کن |
| 7 | مقادیر دقیق `enum Category` | `routine_models.dart` |
| 8 | مقادیر دقیق itemType، recurrenceType، scheduleType | `routine_tables.dart` |
| 9 | ورودی‌های `CreateCourseSheet` — آیا `zoneId` و `description` را از `initialValues` می‌خواند؟ | `create_course_sheet.dart` |
| 10 | ورودی‌های `CreateGoalSheet` — آیا `templateData` کلیدهای `parentGoalId` و `steps[].scheduledDate` را می‌خواند؟ | `create_goal_sheet.dart` |
| 11 | امضای `AddCustomMustahabSheet` — چه پارامترهایی می‌گیرد؟ | `mustahab_section.dart` |
| 12 | امضای `showSportsQuickLogSheet` و `MedicationFormSheet.show` | فایل‌هایشان |
| 13 | کدام ماژول ورزشی زنده است: `features/sports` یا `features/supplementary_sports`؟ آیا `workout_logs` جدول legacy است؟ | `sports_local_datasource_impl.dart` |
| 14 | همهٔ نقاط ورود به پلنر (grep زیر) | — |
| 15 | کلیدهای `app_settings` و `SharedPreferences` مرتبط | `system_tables.dart` |
| 16 | تأیید پیش‌نیاز دوره‌ها (بند ۰٫۴) | `create_course_sheet.dart` |

### grep نقاط ورود
```

grep -rn "UniversalPlannerSheet|RoutineCreateFlow" lib/

grep -rn "showAddStationSheet|openPlanner" lib/

```

### grep وضعیت اولیهٔ مسیرهای موازی — نتیجه را ثبت کن
```

grep -rn "CoursesRepository|GoalsRepository" lib/features/routines/

grep -rnE "db.(insert|update)(s*'(courses|goals|goal_steps|worship_practices|workout_logs)'" lib/

grep -rnE "'worship_practice_|'workout_manual_|'step_${|*sub*$i" lib/

```

### جدول تأیید ۲۱ مشکل
جدول زیر را پر کن. برای هر مورد: مسیر فایل و شمارهٔ خط، و
✅ تأیید شد / ⚠️ متفاوت است (توضیح بده) / ❌ وجود ندارد.

**بحرانی:**
1. `RoutineCreateFlow` و `UniversalPlannerSheet` دو فلوی موازی با دو مسیر نوشتن
2. `isEditing` در Worship/Course/Goal نادیده گرفته می‌شود → تکثیر رکورد
3. `Category.custom` به‌زور یعنی Goal و `Category.learning` به‌زور یعنی Course
4. `isSaving` ست نمی‌شود → دابل‌تپ رکورد تکراری می‌سازد
5. `ReflectionStrategy` با `ConflictAlgorithm.replace` دادهٔ قبلی را پاک می‌کند
6. early-return دارو در `PlannerController.save` → `MedicalStrategy` کد مرده است

**جدی:**
7. `isModuleEnabled` در همهٔ استراتژی‌ها `=> true` هاردکد
8. اعتبارسنجی فقط «عنوان خالی» را می‌گیرد
9. تداخل زمانی فقط هشدار بصری است، مانع ذخیره نمی‌شود
10. ظرفیت روز کاملاً نادیده گرفته می‌شود
11. `CourseStrategy` فیلدهای جمع‌آوری‌شده را دور می‌ریزد
12. `GoalStrategy` همهٔ گام‌ها را روی یک تاریخ می‌گذارد
13. `GoalStrategy` همیشه `linkedRoutineId: null` و `parentGoalId: null`
14. `WorshipStrategy` فیلدهای `worshipSelectedDays` و `worshipRepeatType` را نمی‌نویسد
15. `WorshipStrategy` شاخهٔ DEBT هیچ رویدادی fire نمی‌کند
16. `SportsStrategy` شاخهٔ LOG: `tier` هاردکد `'FULL'` و `muscleGroups` خالی
17. `GoalsRepository` هیچ رویدادی fire نمی‌کند
18. شناسهٔ گام هدف `step_${goalId}_$i` وابسته به ایندکس → تصادم
19. `goals.progressCache` همیشه صفر می‌ماند
20. `BuildContext` روی async gap بدون گارد
21. رشتهٔ جادویی برای نوع رویداد در event bus

### قالب گزارش PASS 0
```

## PASS 0 — گزارش ممیزی

### الف) نسخهٔ دیتابیس و کرنل

### ب) امضاهای دقیق (کد واقعی، کپی‌شده)

### ج) قراردادهای ورودی شیت‌های کانونی (۹–۱۲)

### د) پاسخ سؤال ماژول ورزشی (۱۳)

### ه) خروجی grepها

### و) جدول تأیید ۲۱ مشکل

### ز) انحرافات از این سند و پیشنهاد اصلاح

```

⛔ **توقف و تأیید انسانی.** تا تأیید نگرفتی وارد فاز ۰ نشو.

---

# فاز ۰ — پیش‌نیازهای بیرون از پلنر

بدون این سه تسک، تفویض باگ را منتقل می‌کند به‌جای اینکه رفعش کند.

## T1 — شناسهٔ پایدار برای گام هدف و زیرهدف

**فایل جدید:** `lib/core/utils/ritmo_id_factory.dart`

```

class RitmoIdFactory {

static String _stamp() {

final now = [DateTime.now](http://DateTime.now)();

return '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch % 100000}';

}

static String routine()       => 'routine_${_stamp()}';

static String schedule(String routineId) => 'sched_${routineId}_${_stamp()}';

static String goal()          => 'goal_${_stamp()}';

static String goalStep()      => 'gs_${_stamp()}';

static String worshipPractice() => 'wp_custom_${_stamp()}';

static String worshipDebt()   => 'wd_${_stamp()}';

static String workoutLog()    => 'wl_${_stamp()}';

static String reflection(String dateIso) => 'reflection_$dateIso';

}

```

در این فایل‌ها جایگزین کن:
- `lib/features/goals/logic/goals_repository.dart` — `'step_${mainGoalId}_$i'` و
  `'goal_${mainGoalId}_sub_$i'` → `RitmoIdFactory.goalStep()` / `.goal()`
- `lib/features/today/presentation/widgets/goals_management_sheet.dart` — همان

**مهاجرت داده لازم نیست.** شناسه‌های قدیمی معتبر می‌مانند.

**تست:** یک هدف با ۳ گام بساز، ویرایشش کن، ۲ گام اضافه کن.
هیچ `UNIQUE constraint failed` نگیر و هیچ گام قبلی گم نشود.

## T2 — رویداد بعد از هر نوشتن در اهداف

در `GoalsRepository`، در متدهای `saveGoal`، `updateGoal`، `deleteGoal`،
`updateGoalStatus`، و متد تیک‌زدن گام — **بعد از پایان تراکنش**:

```

RitmoEventBus().fire(RitmoEvent(

type: RitmoEventType.goalChanged,   // enum در T12 ساخته می‌شود

timestamp: [DateTime.now](http://DateTime.now)(),

payload: {'goalId': goalId},

));

```

تا وقتی T12 انجام نشده، موقتاً رشتهٔ `'GoalChanged'` بگذار و در T12 یکپارچه کن.

الگوی مرجع: `CoursesRepository`.

**تأیید:** از صفحهٔ اهداف یک هدف با گامِ امروز بساز → بدون ری‌استارت اپ،
گام در «امروز» ظاهر شود.

## T3 — تأیید پیش‌نیاز دوره‌ها

بند ۰٫۴ را عملاً تست کن: یک دورهٔ موجود را از `course_detail_screen`
ویرایش کن. اگر دورهٔ دوم ساخته شد، **⛔ توقف** و گزارش بده.

---

# فاز ۱ — تفویض و پاک‌سازی کد مرده

قلب این سند. بعد از این فاز، پلنر دیگر برای هیچ ماژول تخصصی نمی‌نویسد.

## T4 — مسیریابی بر اساس itemType

**فایل جدید:** `lib/features/routines/domain/planner_item_type.dart`

```

enum PlannerItemType {

routine('ROUTINE'),

reminder('REMINDER'),

task('TASK'),

reflect('REFLECT'),

event('EVENT'),

goal('GOAL'),

course('COURSE');

const PlannerItemType(this.code);

final String code;

static PlannerItemType fromCode(String c) =>

values.firstWhere((e) => e.code == c, orElse: () => routine);

}

```

- `PlannerStrategyRegistry.resolve` باید **اول** `itemType` را ببیند، بعد
  `Category`. اتصال «`Category.custom` یعنی هدف» و
  «`Category.learning` یعنی دوره» **حذف** شود.
- در `planner_category_grid.dart`، دستهٔ «یادگیری» و «شخصی‌سازی‌شده» یک
  انتخاب فرعی نشان دهند: «ایستگاه عادی» یا «دورهٔ آموزشی» / «هدف».
- ترتیب جدید registry بعد از حذف‌های T6:
  `Reflection → Worship → Sports → Generic`

## T5 — قرارداد کامل تفویض

در `PlannerController`، امضای openerها را کامل کن:

```

void Function({Map<String, dynamic>? initialValues})? openCourseSheet;      // موجود ✅

void Function({Map<String, dynamic>? templateData})? openGoalSheet;         // امضا اصلاح شود

void Function({Map<String, dynamic>? prefill})? openWorshipSheet;           // از VoidCallback ارتقا

void Function([MedicationFormData?])? openMedicalSheet;                     // موجود ✅

void Function({

WorkoutTier? presetTier,

List<MuscleGroup>? presetGroups,

int? durationMinutes,

})? openSportsLogSheet;                                                     // جدید

VoidCallback? openSportsScreen;                                             // موجود ✅

```

در `universal_planner_sheet.dart` همهٔ setterها را wire کن. الگو دقیقاً
همان `setCourseSheetOpener` فعلی:

```

_controller.setSportsLogSheetOpener(({presetTier, presetGroups, durationMinutes}) {

showSportsQuickLogSheet(

context,

presetTier: presetTier,

presetGroups: presetGroups,

onLogged: () {

widget.onSaved();

Navigator.pop(context);

},

);

});

```

**قانون یکسان برای همه:** بعد از ذخیره در شیت کانونی، هر دو شیت بسته شوند
و `widget.onSaved()` صدا زده شود.

**متد مشترک تفویض** در `PlannerController`:

```

/// اگر این آیتم مالک اختصاصی دارد، شیت کانونی‌اش را باز می‌کند و true برمی‌گرداند.

bool _delegateToOwnerModule(BuildContext context) { ... }

```

این متد در ابتدای `save(context)` و همچنین در دکمهٔ «ادامه» مرحلهٔ اول
صدا زده شود (کاربر نباید سه مرحله جلو برود و بعد به شیت دیگری پرتاب شود —
**تفویض باید در نخستین لحظهٔ ممکن رخ دهد**).

## T6 — حذف کامل CourseStrategy و GoalStrategy

### حذف
```

git rm lib/features/routines/domain/strategies/course_strategy.dart

git rm lib/features/routines/domain/strategies/goal_strategy.dart

```
از `planner_strategy_registry.dart` و همهٔ importها پاک کن.

### جایگزین: سازندهٔ داده برای شیت کانونی

`_buildCourseInitialValues()` — **دقیقاً همان کلیدهایی** که
`course_detail_screen._editCourse` می‌سازد، به‌علاوهٔ آنچه پلنر جمع کرده:

```

{

'title': title,

'description': description.isNotEmpty ? description : null,

'sessionDurationMinutes': targetDuration,

'preferredTime': formatTime(selectedTime),

'zoneId': selectedZoneId,

'energyRule': energyRule,

// بقیهٔ کلیدها را از قرارداد ثبت‌شده در PASS 0 بند ۹ بگیر

}

```

`_buildGoalTemplateData()` — توجه: `steps` آرایه‌ای از **Map** است، نه رشته:

```

{

'title': title,

'description': description.isNotEmpty ? description : null,

'goalType': goalType,

'targetDate': formatDate(goalTargetDate),

'parentGoalId': selectedParentGoalId,

'steps': [goalSteps.map](http://goalSteps.map)((s) => {

'title': s.title,

'scheduledDate': s.scheduledDate == null ? null : formatDate(s.scheduledDate!),

'linkedRoutineId': s.linkedRoutineId,

}).toList(),

}

```

⚠️ اگر طبق PASS 0 بندهای ۹ و ۱۰ مشخص شد که شیت‌های کانونی این کلیدها را
نمی‌خوانند، **آن‌ها را به شیت اضافه کن**. این تنها مجوز لمس
`create_course_sheet.dart` و `create_goal_sheet.dart` در کل این سند است، و
فقط برای خواندن کلیدهای بیشتر — نه تغییر ظاهر یا منطق ذخیره.

## T7 — تفکیک عبادت

`worship_strategy.dart` می‌ماند ولی نصف می‌شود:

**شاخهٔ `MUSTAHAB` → حذف کامل.** جایش تفویض:
```

openWorshipSheet?.call(prefill: {

'title': title,

'reminderTime': formatTime(selectedTime),

'reminderAnchor': worshipReminderAnchor,

'reminderOffsetMinutes': worshipOffsetMinutes,

'dailyTarget': worshipDailyTarget,

'reminderDaysOfWeek': worshipSelectedDays.join(','),

'reminderFrequency': worshipRepeatType,

});

```
در `AddCustomMustahabSheet` پارامتر `prefill` را اضافه کن (فرم را از آن
پر کند). `practice` موجود برای حالت ویرایش دست‌نخورده بماند.

**شاخهٔ `DEBT` می‌ماند** (شیت کانونی ندارد) ولی اصلاح شود:
- `db.insert` خام → `CreateWorshipDebtCommand` کرنل (T11)
- شناسه از `RitmoIdFactory.worshipDebt()`
- بعد از موفقیت `RitmoEventType.worshipChanged` fire شود — **این باگ فعلی است**

**قرارداد شناسه و subType:** هر مستحبی که کاربر دستی می‌سازد باید
`subType = 'CUSTOM'` داشته باشد، **هرگز `null`**. الگوی dedup را از
`assistant_action_registry` کپی کن: قبل از درج
`SELECT ... WHERE title = ? AND isActive = 1`؛ اگر بود، update کن و به کاربر
بگو «این مورد از قبل هست، به‌روزرسانی شد».

## T8 — تفکیک ورزش

`sports_strategy.dart` می‌ماند ولی نصف می‌شود:

**شاخهٔ `LOG` → حذف کامل.** جایش `openSportsLogSheet` (T5).
دلیل: شیت کانونی `tier` واقعی، `muscleGroups`، و `location` را از
`WorkoutSuggester.readLocation(db)` می‌گیرد، در حالی که استراتژی `tier` را
`'FULL'` هاردکد و `muscleGroups` را خالی می‌گذاشت.

**شاخهٔ `ROUTINE` می‌ماند** و از `CreateRoutineCommand` کرنل رد می‌شود.

**دربارهٔ بند ۱۳ PASS 0:** اگر `workout_logs` جدول legacy است، فقط در
REPORT ثبت کن. **در این پرامپت مهاجرت داده انجام نده** و
`setSportsScreenOpener` را تغییر نده تا تصمیم انسانی گرفته شود.

## T9 — 🗑 پاک‌سازی کد مرده

طبق قانون ۳. این تسک اختیاری نیست.

### الف) فایل‌های حذفی
```

git rm lib/features/routines/presentation/routine_create_flow.dart

git rm lib/features/routines/domain/strategies/medical_strategy.dart

```
- `RoutineCreateFlow`: همهٔ فراخوان‌هایش (از grep بند ۱۴ PASS 0) به
  `UniversalPlannerSheet` تغییر کنند. **هیچ قابلیتی از این فلو نباید گم شود** —
  قبل از حذف، فهرست قابلیت‌هایش را در REPORT بنویس و تیک بزن که هرکدام
  در پلنر جدید کجاست.
- `MedicalStrategy`: به‌خاطر early-return دارو در `PlannerController.save`
  هرگز اجرا نمی‌شود. کد مردهٔ قطعی.

### ب) پاک‌سازی داخل فایل‌های باقی‌مانده
- `PlannerSaveContext`: هر فیلدی که بعد از T6–T8 مصرف‌کننده ندارد حذف شود
  (همهٔ فیلدهای `course*` و `goal*` مربوط به ذخیره، و فیلدهای worship/sports
  شاخه‌های حذف‌شده).
- `planner_payloads.dart`: `CoursePlannerPayload` اگر فقط برای ذخیره بود حذف؛
  اگر برای جمع‌آوری ورودی جهت تفویض لازم است بماند.
- `PlannerController`: متدهای save اختصاصی هر دسته که دیگر صدا زده نمی‌شوند.
- شاخه‌های `if/switch` روی `Category` که حالا مرده‌اند.
- همهٔ importهای بلااستفاده.

### ج) تأیید
```

dart analyze --fatal-infos

grep -rn "RoutineCreateFlow|MedicalStrategy|CourseStrategy|GoalStrategy" lib/

```
دستور دوم باید **صفر نتیجه** بدهد.

در REPORT جدول پر کن:

| فایل/نماد حذف‌شده | خطوط | دلیل | جایگزین |
|---|---|---|---|

---

# فاز ۲ — یکپارچگی نوشتن

## T10 — کارخانهٔ شناسه در پلنر

`RitmoIdFactory` (از T1) را در سراسر `lib/features/routines/` جایگزین همهٔ
`'routine_$now'`، `'sched_$routineId'`، `'reflection_$todayStr'` و مشابه کن.

```

grep -rnE "'(routine|sched|reflection|worship|workout)_\$" lib/features/routines/

```
باید صفر شود.

## T11 — Commandهای کرنل برای باقی‌ماندهٔ نوشتن‌ها

این پنج Command ساخته شوند (بقیه در ماژول خودشان می‌مانند):

| Command | جدول | جایگزین چه چیزی |
|---|---|---|
| `CreateWorshipDebtCommand` | `worship_debts` | `db.insert` خام در WorshipStrategy |
| `CreateWorkoutRoutineCommand` | `routines` + `routine_schedules` | شاخهٔ ROUTINE در SportsStrategy |
| `UpsertReflectionCommand` | `reflections` | `ReflectionStrategy` |
| `CreateRoutineCommand` | موجود ✅ | — |
| `EditRoutineCommand` | موجود ✅ | — |

**همه داخل یک تراکنش.** خطا → rollback کامل + `RitmoToast` فارسی.

⚠️ `UpsertReflectionCommand` باید `ConflictAlgorithm.replace` را با یک
**upsert غیرمخرب** جایگزین کند: فقط فیلدهایی که کاربر پر کرده به‌روز شوند،
بقیه دست‌نخورده بمانند. باگ فعلی: بازتاب دوم روز، بازتاب اول را پاک می‌کند.

## T12 — enum برای نوع رویداد

**فایل جدید:** `lib/core/domain/engines/ritmo_event_type.dart`

```

enum RitmoEventType {

routineChanged('RoutineChanged'),

courseChanged('CourseChanged'),

courseSessionCompleted('CourseSessionCompleted'),

goalChanged('GoalChanged'),

reflectionChanged('ReflectionChanged'),

workoutLogChanged('WorkoutLogChanged'),

worshipChanged('WorshipChanged');

const RitmoEventType(this.wireName);

final String wireName;

}

```

- `RitmoEvent.type` را از `String` به `RitmoEventType` تغییر بده.
- همهٔ `fire('...')`های رشته‌ای در کل `lib/` به‌روز شوند.
- رشتهٔ موقت T2 هم اینجا یکپارچه شود.

```

grep -rnE "fire(RitmoEvent(s*type:s*'" lib/

```
باید صفر شود.

## T13 — `isModuleEnabled` واقعی

امروز همه‌جا `=> true`. باید از `app_settings` بخواند:
`module_worship_enabled`, `module_sports_enabled`, `module_goals_enabled`,
`module_courses_enabled`, `module_health_enabled`.

اگر ماژول غیرفعال بود، دسته در `planner_category_grid` **خاکستری** شود و
با tap شیت فعال‌سازی موجود (`_showActivationDialog` در `PlannerController`)
باز شود — نه اینکه پنهان شود.

## T14 — خروج SQL خام از کنترلر

**فایل جدید:** `lib/features/routines/data/routines_repository.dart`

همهٔ `db.rawQuery` و `db.query` مستقیم از `PlannerController` و ویجت‌های
پلنر به این کلاس منتقل شود. کنترلر فقط repository را صدا بزند.

## T15 — شکستن `PlannerSaveContext`

بعد از پاک‌سازی T9 هنوز بزرگ است. به sealed class بشکن:

```

sealed class PlannerSaveContext {

final PlannerCommonContext common;   // title, description, itemType, category,

// selectedTime, targetDuration, zoneId,

// priority, energyRule, isEditing, routineToEdit

}

final class GenericSaveContext extends PlannerSaveContext { ... }

final class WorshipDebtSaveContext extends PlannerSaveContext { ... }

final class SportsRoutineSaveContext extends PlannerSaveContext { ... }

final class ReflectionSaveContext extends PlannerSaveContext { ... }

```

`routineToEdit` از `Map<String, dynamic>` به مدل تایپ‌دار `Routine` تبدیل شود.

---

# فاز ۳ — اعتبارسنجی، تداخل، و قفل ذخیره

## T16 — قفل ذخیره و رفع دابل‌تپ

- `isSaving` در ابتدای `save()` **قبل از هر await** ست شود، در `finally` آزاد.
- `PlannerSubmitButton` وقتی `isSaving` است: غیرفعال + `CircularProgressIndicator`.
- گرادیان هاردکد `0xff8B5CF6 → 0xff10B981` با `context.colors` جایگزین شود.
- در `isEditing` هم قفل اعمال شود.

## T17 — `PlannerValidator`

**فایل جدید:** `lib/features/routines/domain/planner_validator.dart`

منطق خالص و تست‌پذیر. خروجی `List<PlannerIssue>` با
`severity: error | warning`.

| # | شرط | شدت | پیام فارسی |
|---|---|---|---|
| 1 | عنوان خالی | error | لطفاً عنوان فعالیت را وارد کنید |
| 2 | عنوان < ۲ کاراکتر | error | عنوان خیلی کوتاه است |
| 3 | عنوان > ۱۰۰ کاراکتر | error | عنوان نباید بیش از ۱۰۰ نویسه باشد |
| 4 | مدت ≤ ۰ | error | مدت باید بیشتر از صفر باشد |
| 5 | مدت > ۴۸۰ دقیقه | warning | مدت بیش از ۸ ساعت است. مطمئنی؟ |
| 6 | `CUSTOM_DAYS` بدون روز انتخابی | error | حداقل یک روز هفته را انتخاب کن |
| 7 | ساعت داخل بازهٔ خواب | warning | این ساعت داخل زمان خواب توست |
| 8 | `dependsOnRoutineId` حلقه می‌سازد | error | این وابستگی حلقه ایجاد می‌کند |
| 9 | تداخل کامل با ایستگاه موجود | error | با «X» کاملاً تداخل دارد |
| 10 | تداخل جزئی | warning | با «X» هم‌پوشانی دارد |
| 11 | عبور از ظرفیت روز | warning | ظرفیت امروز پر می‌شود |
| 12 | عنوان مشابه ایستگاه موجود | warning | «X» از قبل وجود دارد |
| 13 | تاریخ گام هدف در گذشته | warning | تاریخ این گام گذشته است |

`error` مانع ذخیره؛ `warning` با «به‌هرحال ادامه بده» قابل عبور.
اجرای اعتبارسنجی روی هر تغییر با debounce ۳۵۰ms.

## T18 — `PlannerConflictResolver`

**فایل جدید:** `lib/features/routines/domain/planner_conflict_resolver.dart`
**ویجت جدید:** `widgets/planner_conflict_card.dart`

وقتی تداخل هست، به‌جای متن قرمز، یک کارت با سه گزینهٔ **عملی**:

1. **انتقال به نزدیک‌ترین شکاف آزاد** — از `StationTimeRecommender` (T24).
   دکمه: «انتقال به ۱۷:۳۰»
2. **کوتاه کردن این ایستگاه** — تا جایی که تداخل حل شود.
   دکمه: «کوتاه به ۲۰ دقیقه»
3. **جابه‌جایی ایستگاه دیگر** — از `ReshuffleEngine` با پیش‌نمایش.
   دکمه: «جابه‌جایی «X» به فردا»

هر گزینه پیش‌نمایش نتیجه را نشان دهد قبل از اعمال.

## T19 — نوار ظرفیت روز

ویجت باریک بالای مرحلهٔ زمان:

`۴ ساعت و ۲۰ دقیقه از ۶ ساعت ظرفیت امروز` + نوار پیشرفت

- ظرفیت از `app_settings['daily_capacity_minutes']` (پیش‌فرض `360`)
- بالای ۹۰٪ → رنگ هشدار
- بالای ۱۰۰٪ → قرمز + warning شمارهٔ ۱۱

⚠️ **دامنهٔ محاسبه:** چون `GoalStepsAgendaSource` گام‌های هدف با
`scheduledDate == today` و `goals.status = 'ACTIVE'` را وارد اجندای روز
می‌کند، محاسبهٔ ظرفیت باید **روتین‌ها + جلسات دوره + گام‌های هدف** را بشمارد.

گام هدف `targetDurationMinutes` ندارد؛ تخمین پیش‌فرض **۱۵ دقیقه** بگذار و
در REPORT ثبت کن که این عدد فعلاً قابل تنظیم نیست (بدهی فنی).

---

# فاز ۴ — تجربهٔ کاربری

## T20 — حالت «تک‌نفس»

ویزارد سه‌مرحله‌ای برای یک ایستگاه سادهٔ روزمره زیاده‌روی است.

- **پیش‌فرض جدید:** یک صفحهٔ واحد شامل عنوان، دسته، ساعت، مدت.
- «تنظیمات بیشتر ▾» بقیه را باز کند.
- ویزارد سه‌مرحله‌ای حذف **نمی‌شود** — پشت
  `SharedPreferences['planner_prefers_wizard']` می‌ماند، با یک سوییچ در
  منوی سه‌نقطهٔ شیت.
- **ویجت جدید** `widgets/planner_entity_chips.dart`: چیپ‌های خلاصه
  (`⏰ ۱۷:۳۰` · `⏳ ۳۰ دقیقه` · `📍 خانه` · `🔁 روزهای کاری`) که با tap
  همان بخش را باز می‌کنند. جایگزین اسکرول طولانی.

## T21 — صفحهٔ خالی هوشمند

**فایل جدید:** `widgets/planner_empty_state.dart`

وقتی کاربر هنوز چیزی ننوشته:
- ۳ تا ۵ چیپ «ایستگاه پرتکرار» از `frequentStations`
- ۲ چیپ «الگوی زمانی» از `StationTimeRecommender` — مثل «۷:۰۰ صبح، معمولاً آزادی»
- یک چیپ «بستهٔ آماده» (T27)
- اگر کاربر جدید است، ۳ نمونهٔ آمادهٔ فارسی

## T22 — Undo، «ذخیره و بعدی»، پیش‌نویس ماندگار

**Undo:** بعد از ذخیره، `RitmoToast` با دکمهٔ «لغو» به مدت ۵ ثانیه.
لغو یعنی اجرای Command معکوس از کرنل (نه حذف مستقیم).

**«ذخیره و بعدی»:** دکمهٔ فرعی کنار CTA اصلی. شیت بسته نشود، فرم ریست شود
ولی دسته/ساعت/منطقه حفظ شوند. شمارنده: «۳ ایستگاه ثبت شد».

**پیش‌نویس ماندگار:** هر ۲ ثانیه در `SharedPreferences['planner_draft']`
به‌صورت JSON. دیالوگ «ادامه ویرایش / دور انداختن» موجود، به‌جای فقط عنوان،
از پیش‌نویس واقعی بازیابی کند. بعد از ذخیرهٔ موفق پاک شود.

## T23 — گام‌های هدف تایپ‌دار

در `planner_payloads.dart`:

```

class PlannerGoalStepInput {

String title = '';

DateTime? scheduledDate;

String? linkedRoutineId;

}

class GoalPlannerPayload {

String goalType = 'DAILY';

DateTime goalTargetDate = [DateTime.now](http://DateTime.now)().add(const Duration(days: 30));

List<PlannerGoalStepInput> goalSteps = [PlannerGoalStepInput()];

String? selectedParentGoalId;   // جدید

void reset() { ... }

}

```

در UI مرحلهٔ گام‌ها، هر ردیف علاوه بر عنوان:
- یک `RitmoDatePicker` کوچک برای تاریخ گام (اختیاری، پیش‌فرض `null`)
- یک dropdown «اتصال به ایستگاه» با روتین‌های فعال

و بالای فرم یک dropdown «زیرمجموعهٔ هدف…» با `activeGoals`.
خالی = هدف سطح‌بالا.

این داده مستقیم به `_buildGoalTemplateData()` (T6) می‌رود.

---

# فاز ۵ — هوشمندسازی

## T24 — `StationTimeRecommender`

**فایل جدید:** `lib/core/analytics/station_time_recommender.dart`

الگوی `CachedEngine` را از `courses_engine.dart` کپی کن.

برای هر شکاف ۱۵ دقیقه‌ای در بازهٔ بیداری، امتیاز:

```

score = freeSlot        × 3.0

- energyFit       × 2.5
- zoneFit         × 2.0
- historyFit      × 2.0
- adjacency       × 1.0
- preferredHour   × 1.0

− overloadPenalty × 2.0

− sleepPenalty    × 3.0

− fragmentation   × 1.0

```

- `freeSlot` — از `DayAgendaService`
- `energyFit` — از `app_settings['energy_profile']` و `energyRule` ایستگاه
- `zoneFit` — منطقهٔ فعال آن ساعت
- `historyFit` — ساعت‌هایی که کاربر ایستگاه‌های مشابه را واقعاً انجام داده
  (از `routine_completions`)
- `adjacency` — چسبیدن به ایستگاه موجود، برای کاهش تکه‌تکه شدن روز
- `sleepPenalty` — از `wake_time` / `sleep_time`

بالاترین امتیاز پیشنهاد شود؛ سه گزینهٔ برتر در «پیشنهاد ✨».
مصرف‌کننده‌ها: T18 (حل تداخل)، T21 (صفحهٔ خالی)، دکمهٔ پیشنهاد.

## T25 — تشخیص مورد تکراری

**فایل جدید:** `lib/core/utils/text_similarity.dart` — فاصلهٔ Levenshtein
نرمال‌شده، با نرمال‌سازی فارسی (ی/ي، ک/ك، حذف اعراب و نیم‌فاصله).

هنگام تایپ عنوان، اگر شباهت با یک ایستگاه فعال ≥ **۰٫۸** بود:

> ⚠️ «تمرین صبحگاهی» از قبل وجود دارد.
> [ویرایش همان] [به‌هرحال بساز]

## T26 — پارسر و AI

**الف) fallback خودکار:** منطق `showAiParseAction` امروز برعکس است. درست:
اگر `QuickAddParser` چیزی استخراج نکرد **و** طول متن > ۱۵ نویسه بود،
خودکار `AiGateway` صدا زده شود. شاخص بارگذاری کوچک کنار فیلد.
timeout ۴۵ ثانیه؛ در صورت شکست، سکوت و ادامهٔ فرم دستی.

**ب) یادگیری:** `rejectedEntities` امروز persist نمی‌شود. یک جدول کوچک
`planner_rejections (id, pattern, entityType, count, updatedAt)` بساز.
اگر کاربر یک استخراج را ۲ بار رد کرد، دیگر پیشنهاد نشود.

**ج) الگوهای جدید پارسر** — این ۹ مورد را اضافه کن:

| ورودی | باید استخراج شود |
|---|---|
| «هر روز صبح» | `EVERY_DAY` + ۰۷:۰۰ |
| «یک روز در میان» | `INTERVAL_DAYS` = ۲ |
| «آخر هفته‌ها» | `CUSTOM_DAYS` = پنجشنبه، جمعه |
| «بعد از ناهار» | anchor = `LUNCH` |
| «قبل از خواب» | anchor = `SLEEP`, offset منفی |
| «هر ۳ ساعت» | `INTERVAL_HOURS` = ۳ |
| «نیم ساعت» | duration = ۳۰ |
| «یک ربع» | duration = ۱۵ |
| «تا آخر ماه» | targetDate = پایان ماه شمسی جاری |

**د) پارس روی هر کاراکتر** — debounce موجود ۳۵۰ms را حفظ کن، ولی پارس
سنگین فقط روی مکث ≥ ۶۰۰ms یا submit اجرا شود.

## T27 — بسته‌های ایستگاه

**جدول جدید** (نسخهٔ DB = فعلی + ۱، از PASS 0 بند ۱):

```

CREATE TABLE station_bundles (

id TEXT PRIMARY KEY,

title TEXT NOT NULL,

emoji TEXT,

description TEXT,

itemsJson TEXT NOT NULL,

isBuiltIn INTEGER NOT NULL DEFAULT 0,

usageCount INTEGER NOT NULL DEFAULT 0,

createdAt INTEGER NOT NULL,

updatedAt INTEGER NOT NULL

);

CREATE INDEX idx_station_bundles_usage ON station_bundles(usageCount DESC);

```

چهار بستهٔ پیش‌فرض seed شود:
`🌅 صبح ورزشی` · `🌙 شب آرام` · `💼 روز کاری متمرکز` · `💧 پایه‌های سلامت`

⚠️ **محدودیت طبق قانون ۱:** `itemsJson` فقط اجازه دارد
`itemType ∈ {ROUTINE, REMINDER, TASK}` داشته باشد. **بسته حق ندارد دوره،
هدف، دارو یا مستحب بسازد** — چون آن‌ها باید از شیت کانونی خودشان بیایند.
اگر بسته‌ای چنین آیتمی داشت، هنگام اجرا نادیده گرفته شود و در پیش‌نمایش
warning نشان داده شود.

جریان: انتخاب بسته → پیش‌نمایش قابل ویرایش (تیک/حذف هر آیتم، تنظیم ساعت‌ها)
→ ذخیرهٔ همه در **یک تراکنش**.

## T28 — ورودی صوتی

تنها تسکی که مجوز افزودن package دارد (`speech_to_text` یا معادل).

- آیکن میکروفن کنار فیلد عنوان
- تبدیل گفتار فارسی به متن → مستقیم به `QuickAddParser`
- اگر مجوز رد شد یا در دسترس نبود، آیکن پنهان شود (نه خطا)
- در REPORT بنویس چه package و چه نسخه‌ای اضافه شد و چرا

## T29 — تکمیل خودکار هدف و زنده کردن `progressCache`

در `GoalsRepository`، هر بار که یک `goal_step` تیک می‌خورد یا برداشته می‌شود:

1. پیشرفت را با `goalProgress(goalId, allGoals, stepsByGoal, visited)` حساب کن.
2. در همان تراکنش `goals.progressCache` را به‌روز کن.
   **این ستون امروز همیشه صفر است و عملاً مرده.**
3. اگر پیشرفت = `1.0` و هدف فرزندی ندارد →
   `status = 'COMPLETED'`, `updatedAt = now`.
4. اگر تیک برداشته شد و هدف `COMPLETED` بود → برگرد به `ACTIVE`.
5. `progressCache` والدها را بازگشتی به‌روز کن (از `visited` برای جلوگیری
   از حلقه استفاده کن — در `goal_progress_calculator` موجود است).

⚠️ **قانونی که نباید بشکنی:** طبق `AGENT_PROMPT_COURSES`، تکمیل یک دوره
**هرگز** نباید `goal_steps.isCompleted` را خودکار تغییر دهد. این تسک فقط
مسیر معکوس است: گام → هدف.

## T30 — اتصال هوشمند گام به ایستگاه

بزرگ‌ترین فرصت از دست رفتهٔ فعلی: پلنر تنها جایی است که کاربر همزمان
ایستگاه می‌سازد، ولی `linkedRoutineId` همیشه `null` می‌ماند — در نتیجه
`GoalStep.hasLinkedRoutine` و `linkedRoutineStatus` در `GoalsEngine` هرگز
مقدار نمی‌گیرند.

وقتی کاربر گام هدف می‌نویسد و عنوانش با یک روتین فعال شباهت ≥ **۰٫۷** دارد
(از `TextSimilarity` در T25)، یک چیپ پیشنهاد:

> 🔗 «تمرین روزانه» به این گام وصل شود؟   [بله] [نه]

با «بله» → `linkedRoutineId` ست شود.
سقف: حداکثر یک پیشنهاد در هر گام. رد شدن در `planner_rejections` ثبت شود.

---

# فاز ۶ — تست، ممیزی، گزارش

## T31 — تست‌های اجباری

| فایل تست | چه چیزی |
|---|---|
| `test/planner_validator_test.dart` | هر ۱۳ قانون T17، مثبت و منفی |
| `test/planner_conflict_resolver_test.dart` | سه گزینه + حالت بدون شکاف آزاد |
| `test/station_time_recommender_test.dart` | فرمول امتیاز، جریمهٔ خواب، تکه‌تکه شدن |
| `test/text_similarity_test.dart` | نرمال‌سازی ی/ي، ک/ك، نیم‌فاصله |
| `test/quick_add_parser_test.dart` | هر ۹ الگوی جدید T26-ج |
| `test/ritmo_id_factory_test.dart` | یکتایی زیر فراخوانی سریع پیاپی |
| `test/planner_delegation_test.dart` | **کلیدی** — برای هر دستهٔ تفویضی تأیید کن opener صدا زده می‌شود و هیچ نوشتنی در DB رخ نمی‌دهد |
| `test/goal_progress_test.dart` | T29: تکمیل خودکار، برگشت، والد بازگشتی |
| `test/planner_capacity_test.dart` | T19 شامل گام‌های هدف |
| `test/station_bundles_test.dart` | تراکنش + رد شدن آیتم غیرمجاز |

## T32 — ممیزی نهایی «صفر مسیر موازی»

هر ردیف باید **صفر نتیجه** بدهد:

```

# ۱) نوشتن ماژول‌های تخصصی از داخل پلنر

grep -rn "CoursesRepository|GoalsRepository" lib/features/routines/

grep -rn "workout_logs|worship_practices|worship_debts" lib/features/routines/

# ۲) SQL خام روی جداول تخصصی از داخل پلنر

grep -rnE "db.(insert|update)(s*'(courses|course_sessions|goals|goal_steps)'" lib/features/routines/

# ۳) بازماندهٔ نمادهای حذف‌شده

grep -rn "CourseStrategy|GoalStrategy|MedicalStrategy|RoutineCreateFlow" lib/

# ۴) شناسه‌های قدیمی

grep -rnE "'worship_practice_|'workout_manual_|'step_${|*sub*$i" lib/

# ۵) رشتهٔ جادویی رویداد

grep -rnE "fire(RitmoEvent(s*type:s*'" lib/

# ۶) subType خالی برای مستحب

grep -rn "subType': null" lib/features/

```

اگر ردیف ۲ نتیجه‌ای در `education_management_sheet.dart` یا
`goals_management_sheet.dart` داد، **دست نزن** — در REPORT زیر «خارج از دامنه»
ثبت کن.

### جدول نهایی تک نقطهٔ نوشتن

| موجودیت | جدول | تنها نقطهٔ ساخت کاربری | تنها لایهٔ نوشتن | تأیید |
|---|---|---|---|---|
| دوره | `courses` | `CreateCourseSheet` | `CoursesRepository` | ☐ |
| جلسهٔ دوره | `course_sessions` | `CreateCourseSheet` | `CoursesRepository` | ☐ |
| هدف | `goals` | `CreateGoalSheet` | `GoalsRepository` | ☐ |
| گام هدف | `goal_steps` | `CreateGoalSheet` | `GoalsRepository` | ☐ |
| مستحب | `worship_practices` | `AddCustomMustahabSheet` | همان | ☐ |
| بدهی عبادی | `worship_debts` | پلنر | `CreateWorshipDebtCommand` | ☐ |
| دارو | `routines` (medical) | `MedicationFormSheet` + Preview | `MedicationSaveHelper` | ☐ |
| لاگ تمرین | `workout_logs` | `sports_quick_log_sheet` | همان | ☐ |
| روتین/یادآور/کار | `routines` | پلنر | کرنل | ☐ |
| بازتاب | `reflections` | پلنر | `UpsertReflectionCommand` | ☐ |

**استثنای مجاز:** seedهای خودکار عبادت (`wp_quran`, `wp_fajr`, `wp_dhikr_*`,
`wp_fasting_ramadan`) ساخت کاربری نیستند — دست نزن.

## T33 — مستندسازی و بستن

**فایل جدید:** `prompts/022_REPORT.md` شامل:
1. گزارش کامل PASS 0
2. جدول ۲۱ مشکل با وضعیت نهایی (رفع شد / جزئی / منتقل شد)
3. جدول کد مردهٔ حذف‌شده (T9 بند ج)
4. فهرست قابلیت‌های `RoutineCreateFlow` و محل جدید هرکدام
5. خروجی ممیزی T32
6. جدول تک نقطهٔ نوشتن با تیک
7. نسخهٔ DB قبل و بعد
8. package اضافه‌شده در T28
9. **بدهی فنی خارج از دامنه** — حداقل این موارد:
   - `education_management_sheet.dart` و `goals_management_sheet.dart` در
     `features/today/` نشسته‌اند و repository را دور می‌زنند
   - `worship_seasons_sheet.dart` در `features/profile/` است و ستون‌ها را
     دوبار با camelCase و snake_case می‌نویسد
   - دو ماژول ورزشی موازی `sports` و `supplementary_sports`
   - `goals.isPrivate` هیچ‌وقت نوشته نمی‌شود
   - `_calculateMomentum` منطق تحلیلی داخل `goals_screen` است، نه موتور
   - تخمین ۱۵ دقیقه‌ای گام هدف در محاسبهٔ ظرفیت، قابل تنظیم نیست

**ADR جدید:** `docs/adr/0003-planner-delegates-to-owner-modules.md` —
قانون طلایی را به‌عنوان تصمیم معماری ثبت کن تا در آینده کسی دوباره مسیر
موازی نسازد.

**به‌روزرسانی:** `docs/adr/0001-strategy-pattern-for-planner.md` — بخش
Consequences را با محدودشدن دامنهٔ Strategy به‌روز کن.

---

# ترتیب اجرای الزامی

```

PASS 0  ⛔ توقف و تأیید انسانی

↓

فاز ۰    T1 → T2 → T3          (پیش‌نیاز بیرونی)

↓

فاز ۱    T4 → T5 → T6 → T7 → T8 → T9    (تفویض + پاک‌سازی)

↓

فاز ۲    T10 → T11 → T12 → T13 → T14 → T15

↓

فاز ۳    T16 → T17 → T18 → T19

↓

فاز ۴    T20 → T21 → T22 → T23

↓

فاز ۵    T24 → T25 → T26 → T27 → T28 → T29 → T30

↓

فاز ۶    T31 → T32 → T33

```

جابه‌جا نکن. فاز ۱ باید کامل شود قبل از هر کار UI، وگرنه روی مسیرهای
موازی UI می‌سازی.

---

# سناریوهای پذیرش دستی

بعد از T33، هر ۲۴ مورد را روی دستگاه واقعی اجرا کن و نتیجه را در REPORT بنویس.

**تفویض — بخش حیاتی:**
1. پلنر → «یادگیری» → «دورهٔ آموزشی» → **همان `CreateCourseSheet` بخش
   دوره‌های آموزشی** باز شود، از پیش پر با عنوان و ساعت واردشده. ظاهر و
   دکمه‌ها عیناً مثل باز کردن از صفحهٔ دوره‌ها.
2. همان برای «هدف» → `CreateGoalSheet` با گام‌ها، تاریخ هر گام، و والد.
3. همان برای «عبادت» → `AddCustomMustahabSheet` پر شده.
4. همان برای «دارو» → `MedicationFormSheet` → `MedicationPreviewSheet`.
5. همان برای «ورزش / ثبت تمرین» → `showSportsQuickLogSheet` با tier و
   گروه عضلانی درست.
6. در هر پنج مورد، بعد از ذخیره هر دو شیت بسته شوند و صفحهٔ مبدأ رفرش شود.
7. با breakpoint تأیید کن که در این پنج مورد **هیچ نوشتنی** از داخل
   `lib/features/routines/` رخ نمی‌دهد.
8. تفویض در **نخستین لحظه** رخ دهد — کاربر نباید سه مرحله جلو برود و بعد
   به شیت دیگری پرتاب شود.

**درستی داده:**
9. یک هدف با ۳ گام بساز، ویرایش کن، ۲ گام اضافه کن → بدون خطا، بدون گم شدن.
10. یک دورهٔ موجود را ویرایش کن → دورهٔ دوم ساخته نشود.
11. یک مستحب با عنوان تکراری بساز → پیام «از قبل هست، به‌روزرسانی شد».
12. دو بازتاب در یک روز ثبت کن → اولی پاک نشود.
13. همهٔ گام‌های یک هدف را تیک بزن → وضعیت خودکار `COMPLETED` و
    `progressCache` = ۱٫۰. یکی را بردار → برگردد به `ACTIVE`.
14. از صفحهٔ اهداف هدفی با گام امروز بساز → بدون ری‌استارت در «امروز» ظاهر شود.

**رفتار پلنر:**
15. دکمهٔ ذخیره را سریع دوبار بزن → فقط یک رکورد.
16. ایستگاهی بساز که با موجودی تداخل کامل دارد → ذخیره مسدود، سه گزینهٔ عملی.
17. آنقدر ایستگاه اضافه کن تا ظرفیت رد شود → نوار قرمز + warning.
18. «فردا ساعت ۸ برم باشگاه» بنویس و بدون tap روی فلش «ادامه» بزن →
    عنوان تمیز «برم باشگاه» و ساعت ۰۸:۰۰ استخراج شده باشد.
19. متن مبهم بنویس → fallback خودکار AI اجرا شود.
20. یک ایستگاه با عنوان مشابه موجود بساز → هشدار تکراری.
21. شیت را وسط کار ببند و دوباره باز کن → پیش‌نویس بازیابی شود.
22. بعد از ذخیره «لغو» بزن → رکورد برگردد.
23. «ذخیره و بعدی» را سه بار بزن → سه ایستگاه، شیت باز، شمارنده درست.
24. بستهٔ «🌅 صبح ورزشی» را اجرا کن → همهٔ آیتم‌ها در یک تراکنش، و اگر
    آیتم غیرمجاز داشت نادیده گرفته شود با warning.

---

# یادآوری نهایی

- «نسخهٔ فعلی + ۱» عمداً نوشته شده. عدد واقعی را در PASS 0 از
  `database_helper.dart` و `migrations_registry.dart` بخوان.
- اگر جایی این سند با کد واقعی تناقض داشت، **کد واقعی مرجع است** —
  ولی تناقض را در REPORT ثبت کن و اگر بر معماری اثر دارد، توقف کن.
- قانون طلایی (بند ۱) بر هر تسک دیگری اولویت دارد. اگر تسکی تو را وادار
  به شکستن آن کرد، توقف کن و بپرس.
```
