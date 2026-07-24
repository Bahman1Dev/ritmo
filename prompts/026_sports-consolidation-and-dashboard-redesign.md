
---

## بند ۰ — زمینه و قوانین غیرقابل مذاکره

### ۰٫۱ وضعیت واقعی مخزن (تأییدشده با خواندن فایل‌ها)

| واقعیت | جزئیات |
| --- | --- |
| ماژول «ورزش» **غیرقابل دسترس است** | `systems_hub_screen.dart` فقط `SSHomeDashboardScreen`/`SSIntroScreen` را باز می‌کند. هیچ ارجاعی به `SportsScreen` نیست |
| کل خروجی UI پرامپت ۰۲۴ **مرده است** | `WeeklyBudgetCard`، هاب سه‌ستونی و `MovementAnalyticsScreen` روی `sports_screen.dart` نشسته‌اند |
| زیرساخت ۰۲۴ **سالم است** | `movement_kinds`, `MovementRepository`, `MovementLoadCalculator`, `MovementBudgetService`, `MovementSuggester`, `EnduranceProgressionEngine`, `movement_pr`, `movement_budget` |
| پرامپت ۰۲۳ **فقط بک‌اند بود** | صفر تغییر در `ss_home_dashboard_screen.dart` |
| `sports_quick_log_sheet.dart` **زنده و مخرب است** | SQL خام روی `workout_logs` بدون `metMinutes`/`caloriesKcal`/`kind`/PR/EventBus |

### ۰٫۲ هدف این پرامپت

۱. انتقال **هر چیز ارزشمند** از `lib/features/sports/` به `lib/features/supplementary_sports/`

۲. **بازطراحی کامل** `SSHomeDashboardScreen` به یک داشبورد چهارتبی

۳. **حذف فیزیکی کامل** پوشهٔ `lib/features/sports/`

۴. رفع سه رگرسیون پرامپت ۰۲۵ که مستقیماً به این کار گره خورده‌اند

### ۰٫۳ ⛔ ۱۱ قانون سراسری

۱. **تفویض به مالک ماژول** — هر «افزودن» یا «ثبت انجام» باید پنجرهٔ موجود همان ماژول را باز کند. ساخت مسیر موازی ممنوع.

۲. **تک‌نقطهٔ نوشتن** — `workout_logs` فقط از `MovementRepository`. `routines` فقط از `RitmoExecutionKernel`. `ss_*` فقط از ریپازیتوری‌های `SS*`.

۳. **کد مرده پاک شود** — هیچ فایل، متد، import، ثابت یا enum بلااستفاده باقی نماند. `git rm` واقعی، نه کامنت‌کردن.

۴. **صفر SQL خام در `presentation/`** — همهٔ کوئری‌ها به لایهٔ داده منتقل شوند.

۵. **بدون ویجت خدا** — هیچ کلاسی بیش از ۴۰۰ خط نشود؛ ویجت‌ها را در `widgets/` بشکنید.

۶. **شناسه‌ها فقط از `RitmoIdFactory`** — هیچ `'xx_${millisecondsSinceEpoch}'` دستی.

۷. **بدون از دست رفتن داده** — هر جدول/ستونی که کاربر داده دارد باید مهاجرت داده شود، نه حذف.

۸. **فارسی و RTL** — همهٔ متن‌ها فارسی، `Directionality(textDirection: TextDirection.rtl)`، فونت `Vazirmatn`، اعداد با `toPersianDigits()`.

۹. **بدون Exception به کاربر** — هیچ `throw Exception(...)` که به UI برسد.

۱۰. **هر فاز = یک کامیت مستقل با `flutter analyze` صفر خطا و تست سبز.**

۱۱. **بدون Riverpod جدید** — پروژه روی `StatefulWidget` + سرویس singleton است؛ الگو را عوض نکنید.

### ۰٫۴ 🔒 خطوط قرمز — دست نزن

- منطق تایمر `ss_workout_session_notifier.dart` (`timerTargetTimestamp`, `_startRest`, `SsAudioCuePlayer`)
- `SSPlanGenerator`, `SSCompensationService`, `SSExerciseAnimationMap`, `SSExerciseFarsiNames`
- محاسبات `MovementLoadCalculator` (MET، MET-min، کالری)
- `MovementSuggester` و `EnduranceProgressionEngine`
- seedهای `movement_kinds`

---

## PASS 0 — ممیزی اجباری قبل از هر تغییر

اجرا کن و **خروجی هر کدام را در گزارش بنویس**. اگر بند ۹ یا ۱۰ غیرمنتظره بود، **توقف کن و گزارش بده**.

```bash
# ۱ — فهرست کامل پوشهٔ ورزش
find lib/features/sports -type f -name "*.dart" | sort

# ۲ — چه کسانی از پوشهٔ sports import می‌کنند؟
grep -rn "features/sports/" lib/ test/ --include=*.dart | grep -v "^lib/features/sports/"

# ۳ — نویسندگان workout_logs
grep -rn "workout_logs" lib/ --include=*.dart

# ۴ — استفاده از شیت مرده
grep -rn "showSportsQuickLogSheet\|SportsQuickLogSheet" lib/

# ۵ — ارجاع به SportsScreen
grep -rn "SportsScreen\|SportsDashboardScreen" lib/

# ۶ — جداول ورزش قدیمی
grep -rn "workout_split_days\|workout_recovery_logs\|workout_sessions\|performed_exercises" lib/

# ۷ — دو جدول موازی ست‌لاگ (خطای ۰۲۳)
grep -rn "ss_session_set_log\|ss_workout_set_log" lib/

# ۸ — رگرسیون‌های ۰۲۵
grep -rn "UnimplementedError" lib/core/domain/completion/
grep -rn "workoutLogChanged" lib/core/domain/

# ۹ — 🔴 تداخل شمارهٔ مهاجرت
grep -rn "MigrationV5[0-9]" lib/core/database/
cat lib/core/database/migrations/migrations_registry.dart

# ۱۰ — نسخهٔ فعلی دیتابیس
grep -rn "version:" lib/core/database/database_helper.dart

# ۱۱ — منبع ورزش در اجندا
grep -rn "SportsAgendaSource\|AgendaDomain.sport" lib/
```

**⚠️ بند ۹ بحرانی است:** گزارش ۰۲۴ می‌گوید «Schema V53» و گزارش ۰۲۵ می‌گوید «`MigrationV53`». اگر دو مهاجرت هم‌شماره وجود دارد، **قبل از هر کار دیگری** یکی را به `V54` تغییر شماره بده و ترتیب اجرا را در `migrations_registry.dart` درست کن. مهاجرت این پرامپت `V55` خواهد بود (یا شمارهٔ بعدیِ واقعی).

---

## فاز ۱ — انتقال لایهٔ حرکت

### T1 — جابه‌جایی فیزیکی پوشه

با `git mv` (تا تاریخچه حفظ شود):

```
lib/features/sports/movement/  →  lib/features/supplementary_sports/movement/
```

شامل:

```
movement/domain/{movement_kind,movement_event,movement_suggester,movement_budget,endurance_progression}.dart
movement/data/{movement_repository.dart, seed/movement_kinds_seed.dart}
movement/presentation/{movement_log_sheet,movement_kind_picker,movement_custom_kind_sheet,movement_analytics_screen}.dart
movement/presentation/widgets/weekly_budget_card.dart
```

سپس **همهٔ importها در کل پروژه** به‌روزرسانی شوند:

```
package:ritmo/features/sports/movement/  →  package:ritmo/features/supplementary_sports/movement/
```

`lib/core/analytics/movement_load_calculator.dart` **در core می‌ماند** (جای درستش است).

### T2 — انتقال منطق «نسخهٔ پیشنهادی امروز»

`WorkoutSuggester` یک قابلیت واقعی و ارزشمند دارد که در ورزش تکمیلی وجود ندارد: تعیین `WorkoutTier` از روی **خواب دیشب + ریکاوری + فاز چرخه**.

بساز: `lib/features/supplementary_sports/domain/ss_readiness_service.dart`

```dart
enum SSReadinessTier { full, light, minimal, rest }

class SSReadinessVerdict {
  final SSReadinessTier tier;
  final String reasonFa;      // پیام انسانی فارسی
  final String emoji;
  final int score;            // 0..100
  final int? sleepMinutes;
  final int recoveryLoad;     // 0..6
  final bool isMenstrualPhase;
}

class SSReadinessService {
  static final instance = SSReadinessService._();
  Future<SSReadinessVerdict> evaluateToday();
}
```

منطق دقیقاً از `WorkoutSuggester.buildToday` منتقل شود (⚠️ فقط منطق tier، نه بخش split):

| شرط | tier | پیام |
| --- | --- | --- |
| فاز قاعدگی | `light` | `'فاز قاعدگی — نسخهٔ سبک‌تر پیشنهاد می‌شه 💜'` |
| خواب `< 300` دقیقه | `minimal` | `'دیشب خیلی کم خوابیدی (X ساعت) — نسخهٔ حداقلی تا زنجیره نشکنه ⚡'` |
| خواب `< 360` دقیقه | `light` | `'دیشب کم خوابیدی — نسخهٔ سبک پیشنهاد می‌شه 🔋'` |
| `soreness + fatigue >= 4` | `light` | `'بدنت هنوز خسته/کوفته‌ست — نسخهٔ سبک 💤'` |
| `soreness + fatigue >= 2` | `light` | `'کمی کوفتگی داری — ملایم تمرین کن 🟡'` |
| در غیر این صورت | `full` | `'انرژی و ریکاوری خوبه — نسخهٔ کامل 🔥'` |
| روز `REST` برنامه | `rest` | `'امروز روز استراحته — ریکاوری و کشش سبک'` |

**🔧 دو اصلاح اجباری هنگام انتقال:**

- `_isMenstrualPhase` در کد فعلی همیشه `false` برمی‌گرداند (کد مرده). آن را به منبع واقعی وصل کن: خواندن از جداول ماژول چرخه با احترام به `cycle_consent_worship`/`module_cycle_enabled`. اگر منبع واقعی در دسترس نیست، **متد را حذف کن** و شرط را بردار — نگه‌داشتن یک شاخهٔ همیشه‌غلط ممنوع است.
- `WorkoutSuggester.isTodayLogged` هر ردیف `workout_logs` را حساب می‌کند. در نسخهٔ جدید باید بین **تمرین قدرتی** (`sourceModule = 'SS'`) و **فعالیت حرکتی** (`sourceModule = 'MOVEMENT'`) تفکیک شود.

### T3 — انتقال ریکاوری

`workout_recovery_logs` دادهٔ واقعی کاربر دارد → **جدول حفظ شود**، فقط مالکیتش منتقل شود.

- `sports_recovery_card.dart` → `lib/features/supplementary_sports/presentation/widgets/ss_recovery_card.dart`
- بازنویسی با تم `SupplementarySportsTheme` (رنگ `0xFF2E7D5B`، پس‌زمینهٔ `0xFF0B0F19`)
- SQL خام حذف شود → متدهای جدید در `SSProfileRepository`:
    
    ```dart
    Future<RecoveryLog?> todayRecovery();
    Future<void> saveRecovery({required int soreness, required int fatigue, required int hydration});
    Future<bool> isTodayRecoveryLogged();
    ```
    

### T4 — انتقال «امروز نمی‌تونم»

`sports_cant_today_sheet.dart` → `lib/features/supplementary_sports/presentation/widgets/ss_cant_today_sheet.dart`

باید از `CompletionGateway` با `RoutineSkip` استفاده کند و دلیل را در جدول `skip_reasons` (ساختهٔ ۰۲۵) بنویسد. شش دلیل استاندارد:

> «وقت نداشتم» · «انرژی نداشتم» · «حالم خوب نبود» · «یادم رفت» · «حوصله نداشتم» · «بیرون بودم»
> 

⛔ **همچنین حذف کن:** متد مردهٔ `_showCantTodayBottomSheet` داخل `ss_home_dashboard_screen.dart`.

### T5 — تصمیم دربارهٔ Split قدیمی

جداول `workout_split_days` و enum `MuscleGroup`/`SportsLocation`/`SplitDay` مربوط به سیستم برنامه‌ریزی قدیمی‌اند که **کاملاً با `ss_workout_plan` + `ss_plan_schedule` جایگزین شده‌اند**.

**اقدام:**

- مهاجرت یک‌بارهٔ داده: اگر `workout_split_days` ردیف دارد و کاربر آنبوردینگ ورزش تکمیلی را کامل نکرده، `sports_days_per_week` و `sports_goal_focus` را به `ss_user_profile` منتقل کن تا آنبوردینگ پیش‌پر شود.
- `SportsLocation` (`home`/`gym`) → به `ss_user_profile.trainingLocation` منتقل شود اگر معادلی ندارد.
- سپس جدول `workout_split_days` و کلید‌های `app_settings` مربوطه (`sports_setup_done`, `sports_days_per_week`, `sports_goal_focus`, `sports_location`) **حذف شوند**.
- `MuscleGroup` — بررسی کن آیا `SSExerciseModel` معادل دارد. اگر بله، `MuscleGroup` حذف شود. اگر نه، به `lib/features/supplementary_sports/data/models/ss_exercise_model.dart` منتقل شود.

### T6 — رفع خطای جدول موازی ست‌لاگ (میراث ۰۲۳)

پرامپت ۰۲۳ به اشتباه `ss_session_set_log` ساخت در حالی که `ss_workout_set_log` از قبل بود.

- تعیین کن کدام واقعاً داده دارد و در کد استفاده می‌شود
- دادهٔ جدول بازنده را به برنده مهاجرت بده
- جدول بازنده را `DROP` کن و همهٔ ارجاعاتش را پاک کن
- در گزارش بنویس کدام ماند و چرا

---

## فاز ۲ — رفع سه رگرسیون پرامپت ۰۲۵

این‌ها بلاکر حذف پوشهٔ ورزش‌اند و باید همین‌جا حل شوند.

### T7 — `MovementCompletion` پیاده شود

در `lib/core/domain/completion/completion_gateway.dart`:

```dart
// قبل:
final MovementCompletion _ => throw UnimplementedError('پرامپت ۰۲۴'),

// بعد:
final MovementCompletion req => _handleMovementCompletion(req),
```

```dart
Future<CompletionOutcome> _handleMovementCompletion(MovementCompletion req) async {
  final event = MovementEvent(
    id: RitmoIdFactory.movementLog(),
    kindCode: req.kindCode,
    durationMinutes: req.durationMinutes,
    intensity: req.intensity,
    loggedAt: req.loggedAt,
    sourceModule: 'MOVEMENT',
    // ... سایر متریک‌ها
  );
  final res = await MovementRepository.instance.logEvent(event);
  _notifySuccess(domain: 'movement', itemId: event.id, dateStr: req.dateStr, result: 'FULL');
  return CompletionOutcome.success(undoToken: event.id);
}
```

⛔ **نوشتن مستقیم در `workout_logs` از داخل Gateway مطلقاً ممنوع.**

### T8 — رویداد درست شلیک شود

الان `_notifySuccess` برای **همهٔ** دامنه‌ها `RitmoEventType.workoutLogChanged` می‌فرستد — یعنی تکمیل نماز هم رویداد «تغییر لاگ تمرین» می‌زند.

به `lib/core/domain/engines/ritmo_event_type.dart` اضافه کن:

```dart
completionRecorded('CompletionRecorded'),
```

و در `_notifySuccess`:

```dart
RitmoEventBus().fire(RitmoEvent(
  type: RitmoEventType.completionRecorded.code,
  timestamp: DateTime.now(),
  payload: {'domain': domain, 'itemId': itemId, 'dateStr': dateStr, 'result': result},
));
```

**علاوه بر آن**، وقتی `domain == 'movement'`، رویداد `workoutLogChanged` هم شلیک شود (چون `MovementRepository` خودش این کار را می‌کند، مراقب شلیک دوتایی باش — یکی کافی است).

### T9 — `ActionRouter` برای ورزش درست شود

در `lib/core/domain/agenda/action_router.dart`:

```dart
case AgendaDomain.sport:
  await showMovementLogSheet(
    context,
    presetDate: DateTime.parse(item.dateStr),
    presetDurationMinutes: item.durationMinutes,
    onLogged: () {
      DayAgendaService.instance.invalidateDate(item.dateStr);
    },
  );
  break;
```

و `import '.../sports_quick_log_sheet.dart'` حذف شود.

> 🔎 **توجه:** `ActionRouter` مشکلات دیگری هم دارد (دامنه‌های `course`/`worship`/`goalStep`/`medicine` بدون هیچ شیتی مستقیم submit می‌کنند، و `KonkurStudySheet` با لیست خالی باز می‌شود). **آن‌ها در حوزهٔ این پرامپت نیستند** — دست نزن. فقط `sport` را درست کن و در گزارش یادداشت بگذار.
> 

---

## فاز ۳ — 🎨 بازطراحی کامل داشبورد ورزش تکمیلی

### T10 — ساختار جدید ناوبری

`SSHomeDashboardScreen` از **۳ تب به ۴ تب** ارتقا یابد:

| # | تب | آیکن | محتوا |
| --- | --- | --- | --- |
| ۰ | **امروز** | `CupertinoIcons.flame_fill` | `SSHomeDashboardTabContent` بازطراحی‌شده |
| ۱ | **برنامه** | `CupertinoIcons.calendar` | `SSPlanOverviewScreen` (موجود) |
| ۲ | **حرکت** 🆕 | `CupertinoIcons.figure_walk` | `SSMovementTabScreen` (جدید) |
| ۳ | **پیشرفت** | `CupertinoIcons.chart_bar_alt_fill` | `SSProgressScreen`  • بخش حرکت |

`_selectedIndex.clamp(0, 2)` در سه جا باید به `clamp(0, 3)` تغییر کند.

### T11 — بازطراحی تب «امروز»

فایل: `lib/features/supplementary_sports/presentation/widgets/home/` (ویجت‌های زیر هرکدام فایل جدا)

از بالا به پایین:

**۱. `SSHeroHeader`** — سلام شخصی + تاریخ شمسی + هفتهٔ فعال برنامه

```
سلام بهمن 👋
شنبه ۴ مرداد · هفتهٔ ۳ از ۴ (هفتهٔ اوج)
```

هفته را از `SSProgramCalendar` بگیر. اگر هفتهٔ دیلود است، بج نارنجی «هفتهٔ ریکاوری 🌙».

**۲. `SSReadinessBanner`** 🆕 — خروجی `SSReadinessService`

- نوار افقی با رنگ متناسب tier: `full`=سبز `0xFF10B981` · `light`=زرد `0xFFF59E0B` · `minimal`=نارنجی `0xFFEF6C00` · `rest`=آبی‌خاکستری `0xFF64748B`
- ایموجی + پیام فارسی + امتیاز آمادگی به‌صورت دایرهٔ کوچک
- قابل کلیک → باز شدن `SSRecoveryCard` برای به‌روزرسانی

**۳. `SSTodayActionCard`** — کارت اصلی، بزرگ و برجسته

- **اگر روز تمرین است:** نام تمرین، تعداد حرکت، دقیقهٔ تخمینی، دکمهٔ بزرگ «شروع تمرین 🔥» → `SSWorkoutSessionScreen(planId:)`
- **اگر تمرین امروز انجام شده:** حالت جشن — تیک سبز، خلاصهٔ جلسه، دکمهٔ ثانویهٔ «مشاهدهٔ جزئیات»
- **اگر روز استراحت است:** پیشنهاد کشش/حرکت سبک + دکمهٔ «ثبت فعالیت حرکتی» → `showMovementLogSheet`
- **اگر برنامه تمام شده:** دکمهٔ «ساخت برنامهٔ هفتهٔ بعد» → `SSAdaptiveScheduler`
- دکمهٔ متنی کوچک پایین کارت: **«امروز نمی‌تونم 😓»** → `ss_cant_today_sheet`

**۴. `SSWeeklyBudgetRing`** 🆕 — نسخهٔ بازطراحی‌شدهٔ `WeeklyBudgetCard`

- حلقهٔ پیشرفت دایره‌ای برای `achievedMetMinutes / weeklyMetMinutesTarget`
- زیرش: «X از ۵۰۰ MET-min» + «Y روز فعال از Z»
- خط پیش‌بینی: اگر `projectedTotal >= target` → «با این روند به هدف می‌رسی ✅»؛ وگرنه → «برای رسیدن به هدف، N دقیقه پیاده‌روی تند کافیه 🚶»
- کلیک → تب «حرکت»

**۵. `SSQuickActionsRow`** 🆕 — چهار دکمهٔ گرد افقی

| ایموجی | برچسب | عمل |
| --- | --- | --- |
| ⚡ | ثبت فعالیت | `showMovementLogSheet(context)` |
| 🌿 | ریکاوری | `SSRecoveryCard` به‌صورت شیت |
| 🤖 | مربی AI | `SSAiCoachSheet` (موجود) |
| ⚙️ | تنظیمات | `SSSettingsScreen` (موجود) |

**۶. `SSContinuityStrip`** — نوار تداوم ۷ روز اخیر (منطق فعلی حفظ شود، فقط بصری ارتقا یابد)

- هر روز یک مربع گرد: پر = تمرین قدرتی · نیم‌پر = فقط فعالیت حرکتی · خالی = هیچ · خط‌دار = روز استراحت برنامه‌ریزی‌شده
- زیرش استریک: «🔥 ۱۲ روز پیوسته»

**۷. `SSAiSuggestionCard`** — پیشنهاد مربی (اگر `aiSuggestion != null`)

### T12 — تب جدید «حرکت»

فایل: `lib/features/supplementary_sports/presentation/ss_movement_tab_screen.dart`

**۱. هدر:** حلقهٔ بودجهٔ هفتگی بزرگ + تفکیک `byFamily` به‌صورت نوار انباشته با رنگ هر خانواده

**۲. `MovementSuggester` زنده:** سه کارت پیشنهاد امروز بر اساس امتیازدهی ۹عاملهٔ موجود، هر کدام با دکمهٔ «ثبت» که `showMovementLogSheet(presetKind: ...)` را با نوع پیش‌پرشده باز می‌کند

**۳. دکمهٔ اصلی:** «ثبت فعالیت جدید ⚡» تمام‌عرض

**۴. تایم‌لاین این هفته:** فهرست `snapshot.events` — هر ردیف: ایموجی + نام + مدت + MET-min + کالری + بج PR اگر رکورد بود. Dismissible برای حذف → `MovementRepository.deleteEvent`. کلیک → ویرایش → `MovementRepository.updateEvent`

**۵. کارت تنوع:** نقشهٔ ۷ خانواده — کدام‌ها این هفته لمس شده‌اند. خانوادهٔ لمس‌نشده با پیام تشویقی

**۶. دکمهٔ متنی پایین:** «تحلیل کامل و رکوردها» → `MovementAnalyticsScreen`

### T13 — ارتقای تب «پیشرفت»

به `SSProgressScreen` سه بخش اضافه شود (بدون خراب‌کردن محتوای فعلی):

- **رکوردهای شخصی حرکتی** از `movement_pr` (`MAX_DISTANCE`, `MAX_DURATION`, `MAX_ELEVATION`, `MAX_LAPS`)
- **نمودار MET-min ۸ هفتهٔ اخیر** — ستونی، با خط هدف ۵۰۰
- **رکوردهای قدرتی** از `ss_exercise_pr` (`MAX_WEIGHT`, `MAX_REPS`, `MAX_VOLUME`)

### T14 — سیستم طراحی

همهٔ ویجت‌های جدید باید از `SupplementarySportsTheme` استفاده کنند. اگر ثابت لازم ندارد، اضافه کن:

```
پس‌زمینهٔ اصلی      0xFF0B0F19
پس‌زمینهٔ نوار پایین  0xFF0F172A
مرز                 0xFF1E293B
سبز اصلی            0xFF10B981
سبز عمیق            0xFF2E7D5B
هشدار               0xFFF59E0B
خطر                 0xFFEF4444
شعاع کارت           20
فاصلهٔ استاندارد     12 / 16 / 24 / 32
فونت                Vazirmatn
```

بساز: `DESIGN_SYSTEM_SUPPLEMENTARY_SPORTS.md` با فهرست کامل ویجت‌ها، رنگ‌ها و الگوهای تعاملی.

---

## فاز ۴ — اتصال‌ها

### T15 — `systems_hub_screen`

- عنوان ماژول از «ورزش تکمیلی» به **«ورزش و حرکت»** تغییر کند
- توضیحش بازنویسی شود تا لایهٔ حرکت را هم پوشش دهد
- اگر ورودی مجزایی برای ماژول «ورزش» قدیمی باقی مانده، حذف شود

### T16 — `SportsAgendaSource`

- به `lib/features/supplementary_sports/domain/ss_agenda_source.dart` منتقل شود
- باید **هر دو** را تولید کند: جلسات تمرین قدرتی از `ss_plan_schedule` و روتین‌های حرکتی از `routines` با `movementKind != null`
- شناسه‌ها: `'sport:plan:$planId'` و `'sport:movement:$routineId'`
- `AgendaDomain.sport` بدون تغییر بماند

### T17 — `SportsStrategy`

- حالت `LOG` قطعاً به `showMovementLogSheet` تفویض کند
- ⛔ `'lightDurationMinutes': 0` هاردکد حذف شود — از `DurationVariants` (ساختهٔ ۰۲۵) استفاده کند

### T18 — ویجت اندروید و اعلان‌ها

`grep -rn "sports\|workout" android/app/src/main/kotlin/` بزن و هر ارجاع به مسیرهای حذف‌شده را اصلاح کن.

---

## فاز ۵ — 🗑 حذف کامل پوشهٔ ورزش

### T19 — جدول حذفی‌های اجباری

بعد از اتمام فازهای ۱ تا ۴، این‌ها با `git rm` حذف شوند:

| فایل | دلیل |
| --- | --- |
| `lib/features/sports/presentation/sports_screen.dart` | صفحهٔ یتیم |
| `lib/features/sports/presentation/screens/sports_dashboard_screen.dart` | موازی و مرده (Riverpod) |
| `lib/features/sports/presentation/screens/progress_screen.dart` | «در حال توسعه» — پوسته |
| `lib/features/sports/presentation/screens/split_builder_screen.dart` | Split منسوخ |
| `lib/features/sports/presentation/widgets/sports_quick_log_sheet.dart` | 🔴 SQL خام مخرب |
| `lib/features/sports/presentation/widgets/sports_quick_feeling_sheet.dart` | جذب‌شده در `MovementLogSheet` |
| `lib/features/sports/presentation/widgets/sports_setup_card.dart` | آنبوردینگ `SS` جایگزین |
| `lib/features/sports/presentation/widgets/sports_split_editor.dart` | `SSPlanOverviewScreen` جایگزین |
| `lib/features/sports/presentation/widgets/sports_today_workout_card.dart` | `SSTodayActionCard` جایگزین |
| `lib/features/sports/logic/workout_suggester.dart` | منتقل به `SSReadinessService` |
| `lib/features/sports/models/workout_split_models.dart` | منتقل / منسوخ |
| `lib/features/sports/data/exercise_suggestions.dart` | `SSExerciseModel` جایگزین |
| باقی‌ماندهٔ `lib/features/sports/**` | همه — پوشه باید **کاملاً** خالی و حذف شود |

**⚠️ استثنا:** اگر `sports_local_datasource_impl.migrateLegacyLogs` هنوز برای کاربران قدیمی لازم است، **قبل از حذف** آن را به یک مهاجرت یک‌بارهٔ دیتابیس تبدیل کن، سپس فایل را حذف کن.

### T20 — بررسی جداول یتیم

بعد از حذف، این جداول را بررسی کن:

| جدول | تصمیم |
| --- | --- |
| `workout_logs` | ✅ بماند — مالکش `MovementRepository` |
| `workout_recovery_logs` | ✅ بماند — مالکش `SSProfileRepository` |
| `workout_split_days` | 🗑 بعد از مهاجرت داده حذف شود |
| `workout_sessions` / `performed_exercises` | 🗑 اگر `migrateLegacyLogs` اجرا شده و داده منتقل شده |
| `movement_kinds` / `movement_budget` / `movement_pr` | ✅ بمانند |

هر `DROP TABLE` باید داخل مهاجرت جدید باشد، نه حذف مستقیم از schema.

### T21 — تأیید نهایی

```bash
# باید هیچ خروجی‌ای نداشته باشند:
ls lib/features/sports/ 2>/dev/null
grep -rn "features/sports/" lib/ test/ --include=*.dart
grep -rn "SportsScreen\|WorkoutSuggester\|showSportsQuickLogSheet" lib/

# باید دقیقاً یک نتیجه بدهد (movement_repository.dart):
grep -rn "insert('workout_logs'" lib/

flutter analyze lib/ test/    # صفر خطا، صفر هشدار
```

---

## فاز ۶ — تست و گزارش

### T22 — فایل‌های تست اجباری

```
test/movement_migration_path_test.dart        ← importها بعد از جابه‌جایی درست‌اند
test/ss_readiness_service_test.dart           ← هر ۶ شاخهٔ tier
test/movement_completion_gateway_test.dart    ← MovementCompletion دیگر throw نمی‌کند
test/movement_single_writer_test.dart         ← فقط MovementRepository در workout_logs می‌نویسد
test/completion_event_type_test.dart          ← دامنهٔ غیرورزشی، workoutLogChanged شلیک نمی‌کند
test/action_router_sport_test.dart            ← sport → MovementLogSheet
test/weekly_budget_snapshot_test.dart         ← هفتهٔ شمسی از شنبه، projectedTotal
test/split_migration_test.dart                ← دادهٔ workout_split_days گم نمی‌شود
test/set_log_table_dedup_test.dart            ← فقط یک جدول ست‌لاگ ماند
test/sports_folder_removed_test.dart          ← هیچ فایلی به features/sports ارجاع ندهد
```

### T23 — اسناد خروجی

بساز:

- `prompts/026_REPORT.md` — خروجی کامل PASS 0، فهرست فایل‌های منتقل‌شده، فهرست فایل‌های حذف‌شده، شمارهٔ مهاجرت نهایی، نتیجهٔ تست‌ها
- `docs/adr/0007-sports-consolidation-into-supplementary-sports.md`
- `DESIGN_SYSTEM_SUPPLEMENTARY_SPORTS.md`

به‌روزرسانی کن:

- `docs/adr/0002-modular-database-schema.md` با جداول جدید/حذف‌شده و شمارهٔ نسخهٔ صحیح

---

## ✅ سناریوهای پذیرش

| # | سناریو | انتظار |
| --- | --- | --- |
| S1 | باز کردن «ورزش و حرکت» از هاب سیستم‌ها | داشبورد چهارتبی جدید باز شود |
| S2 | خواب دیشب ۴ ساعت | بنر آمادگی نارنجی، پیام «نسخهٔ حداقلی» |
| S3 | ثبت ریکاوری با کوفتگی ۳ + خستگی ۲ | بنر به زرد تغییر کند، بدون ری‌استارت |
| S4 | تب «حرکت» → ثبت پیاده‌روی ۳۰ دقیقه | حلقهٔ بودجه فوراً به‌روز شود، `metMinutes` محاسبه شود |
| S5 | ثبت اولین شنای ۵۰ طول | بج PR سبز + توست «🎉 رکورد جدید ثبت شد!» |
| S6 | تیک زدن آیتم ورزشی از تقویم | `MovementLogSheet` باز شود، **نه** شیت نیت و نه شیت قدیمی |
| S7 | شروع تمرین قدرتی از تب «امروز» | `SSWorkoutSessionScreen` با تایمر دست‌نخورده |
| S8 | «امروز نمی‌تونم» + انتخاب دلیل | ردیف در `skip_reasons` نوشته شود، بدون Exception |
| S9 | کاربر قدیمی با دادهٔ `workout_split_days` | آنبوردینگ `SS` پیش‌پر شود، هیچ داده‌ای گم نشود |
| S10 | نصب تازهٔ اپ | همهٔ مهاجرت‌ها بدون تداخل شماره اجرا شوند |
| S11 | تکمیل یک نماز | رویداد `completionRecorded` شلیک شود، **نه** `workoutLogChanged` |
| S12 | حذف یک فعالیت حرکتی از تایم‌لاین هفته | بودجه و تنوع فوراً به‌روز شوند |
| S13 | `grep -rn "features/sports/" lib/` | صفر نتیجه |
| S14 | `flutter analyze` | صفر خطا و صفر هشدار |
| S15 | بدون رگرسیون در ورزش تکمیلی | تایمر، صدای مربی، انیمیشن‌ها، پیشرفت — همه سالم |

---

## ⛔ خطوط قرمز نهایی

۱. هیچ دادهٔ کاربر گم نشود — هر `DROP` بعد از مهاجرت

۲. تایمر و صوت `ss_workout_session_notifier` دست‌نخورده

۳. محاسبات MET دست‌نخورده

۴. `sports_quick_log_sheet` باید **فیزیکاً** حذف شود، نه کامنت

۵. هیچ Riverpod جدیدی وارد نشود

۶. هیچ ویجت بیش از ۴۰۰ خط

۷. هیچ SQL خامی در `presentation/`

۸. اگر تداخل شمارهٔ مهاجرت (PASS 0 بند ۹) واقعی بود، **قبل از هر کار دیگری** حل شود

۹. هر فاز کامیت جداگانه با تست سبز

۱۰. مشکلات دیگر `ActionRouter` (دامنه‌های course/worship/goalStep/medicine/konkur) در حوزهٔ این پرامپت نیست — فقط یادداشت شود

---

