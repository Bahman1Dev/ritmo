# AGENT_PROMPT_VARZESH_TAKMILI — پرامپت‌های کامل برای ایجنت هوش مصنوعی

> این فایل شامل ۶ پرامپت مستقل و مرحله‌به‌مرحله است. هر پرامپت را پس از تکمیل مرحله قبلی به ایجنت بدهید.
> پس از هر مرحله منتظر تایید کاربر بمانید.

---

## ═══════════════════════════════════════
## پرامپت شماره ۱ — زیرساخت، دیتابیس و Design Tokens
## ═══════════════════════════════════════

```
تو یک توسعه‌دهنده ارشد Flutter/Dart هستی. قرار است یک ماژول جدید به نام «ورزش تکمیلی» (Supplementary Sports) به اپلیکیشن Ritmo اضافه کنیم.

این ماژول باید در پوشه‌ی `lib/features/supplementary_sports/` ایجاد شود و کاملاً مستقل از ماژول sports فعلی باشد.

اپلیکیشن ریتمو از sqflite و get_it استفاده می‌کند. تمام کدها باید با Flutter + Dart + sqflite + get_it نوشته شوند. اپلیکیشن فارسی و RTL است.

═══ وظیفه این مرحله: Design Tokens + Data Layer ═══

━━━ بخش ۱: Design Tokens ━━━

یک فایل `supplementary_sports_theme.dart` در پوشه `lib/features/supplementary_sports/` بساز که حاوی موارد زیر باشد:

رنگ‌ها:
- Background Light: #FAFAF8  |  Dark: #121212
- Surface Light: #FFFFFF     |  Dark: #1E1E1E
- Primary Text Light: #1A1A1A|  Dark: #F0F0F0
- Secondary Text Light: #6B6B6B | Dark: #A0A0A0
- Success Light: #2E7D5B     |  Dark: #4CAF7D
- Warning Light: #C9822A     |  Dark: #E0A75E
- Danger Light: #C0392B      |  Dark: #E06C5C

تایپوگرافی (همه با فونت Vazirmatn):
- H1 (عنوان صفحه): 24sp، وزن Medium
- H2 (عنوان بخش): 18sp، وزن Medium
- Body (متن بدنه): 16sp، وزن Regular
- Caption (متن فرعی): 13sp، وزن Regular
- Button Label: 16sp، وزن Medium

Spacing Scale ثابت: 4, 8, 12, 16, 24, 32, 48 dp — هیچ مقدار دیگری استفاده نشود.

Corner Radius:
- دکمه‌ها و فیلدها: 12dp
- کارت‌ها: 16dp
- Bottom Sheet / Modal: فقط گوشه‌های بالا 20dp

حداقل Touch Target: 48×48dp برای تمام عناصر تعاملی.

━━━ بخش ۲: Database Tables ━━━

یک کلاس `SupplementarySportsTables` بساز. این کلاس باید جداول زیر را بسازد و به SchemaManager ریتمو اضافه شود:

جدول ۱: `ss_exercise` (مخزن حرکات — الگوبرداری دقیق از Fitify):
```sql
CREATE TABLE ss_exercise (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  nameEn TEXT,
  category TEXT NOT NULL,        -- عضله اصلی (chest, back, legs, ...)
  equipment TEXT,                -- تجهیزات لازم
  instructions TEXT,             -- راهنمای اجرا
  videoUrl TEXT,
  isCustom INTEGER DEFAULT 0,
  -- فیلدهای حیاتی Fitify که جلوی باگ می‌گیرند:
  changeSides INTEGER DEFAULT 0, -- آیا حرکت نامتقارن است؟ (لانژ، کرانچ پهلو) - Boolean
  noisy INTEGER DEFAULT 0,       -- میزان سر و صدای حرکت (برای «حالت بی‌صدا»)
  impact INTEGER DEFAULT 0,      -- میزان ضربه به زمین
  repsDouble INTEGER DEFAULT 0,  -- آیا چپ+راست = ۱ تکرار؟ Boolean
  repDurationLow REAL DEFAULT 0, -- زمان یک تکرار با سرعت پایین (ثانیه)
  repDurationMedium REAL DEFAULT 0, -- زمان یک تکرار با سرعت متوسط
  repDurationHigh REAL DEFAULT 0,   -- زمان یک تکرار با سرعت بالا
  sexynessMale REAL DEFAULT 0,   -- امتیاز جذابیت برای آقایان (الگوریتم انتخاب)
  sexynessFemale REAL DEFAULT 0, -- امتیاز جذابیت برای خانم‌ها
  isolatedVsCompound REAL DEFAULT 0 -- نسبت تک‌مفصلی به چندمفصلی
);
```

جدول ۲: `ss_workout_plan` (تعریف برنامه):
```sql
CREATE TABLE ss_workout_plan (
  id TEXT PRIMARY KEY,
  dayOfWeek INTEGER NOT NULL,  -- ۱=شنبه تا ۷=جمعه
  muscleGroups TEXT NOT NULL,  -- JSON array از نام گروه‌های عضلانی
  estimatedMinutes INTEGER DEFAULT 45,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
);
```

جدول ۳: `ss_workout_exercise_crossref` (جدول واسط — Many-to-Many):
```sql
CREATE TABLE ss_workout_exercise_crossref (
  id TEXT PRIMARY KEY,
  planId TEXT NOT NULL,
  exerciseId TEXT NOT NULL,
  orderIndex INTEGER NOT NULL,  -- ترتیب اجرا
  difficultyOffset REAL DEFAULT 0, -- این حرکت در این برنامه چقدر سخت‌تر/آسان‌تر از پیش‌فرض؟
  targetSets INTEGER DEFAULT 3,
  targetReps INTEGER DEFAULT 10,
  targetWeight REAL,            -- وزن پیش‌فرض (کیلو)
  FOREIGN KEY(planId) REFERENCES ss_workout_plan(id) ON DELETE CASCADE,
  FOREIGN KEY(exerciseId) REFERENCES ss_exercise(id) ON DELETE CASCADE
);
CREATE INDEX idx_ss_crossref_plan ON ss_workout_exercise_crossref(planId, orderIndex);
```

جدول ۴: `ss_workout_session_log` (لاگ جلسات):
```sql
CREATE TABLE ss_workout_session_log (
  id TEXT PRIMARY KEY,
  planId TEXT NOT NULL,
  startedAt INTEGER NOT NULL,
  finishedAt INTEGER,
  durationSeconds INTEGER DEFAULT 0,
  completedExercisesCount INTEGER DEFAULT 0,
  totalExercisesCount INTEGER DEFAULT 0,
  overallFeeling TEXT,  -- EASY | GOOD | HARD | null
  note TEXT,
  FOREIGN KEY(planId) REFERENCES ss_workout_plan(id) ON DELETE SET NULL
);
CREATE INDEX idx_ss_session_log_date ON ss_workout_session_log(startedAt);
```

جدول ۵: `ss_exercise_feeling_log` (بازخوردهای کیفی هر حرکت):
```sql
CREATE TABLE ss_exercise_feeling_log (
  id TEXT PRIMARY KEY,
  sessionLogId TEXT NOT NULL,
  exerciseId TEXT NOT NULL,
  feeling TEXT NOT NULL,  -- EASY | GOOD | HARD
  loggedAt INTEGER NOT NULL,
  FOREIGN KEY(sessionLogId) REFERENCES ss_workout_session_log(id) ON DELETE CASCADE
);
CREATE INDEX idx_ss_feeling_session ON ss_exercise_feeling_log(sessionLogId);
CREATE INDEX idx_ss_feeling_exercise ON ss_exercise_feeling_log(exerciseId, loggedAt);
```

جدول ۶: `ss_plan_version_history` (تاریخچه تغییرات):
```sql
CREATE TABLE ss_plan_version_history (
  id TEXT PRIMARY KEY,
  serializedPlan TEXT NOT NULL,  -- JSON کامل برنامه در آن لحظه
  changeReason TEXT,             -- «تغییر دستی» | «پیشنهاد AI پذیرفته شد»
  createdAt INTEGER NOT NULL
);
```

جدول ۷: `ss_exercise_similarity` (Pre-computed Graph جایگزینی — از Fitify):
```sql
CREATE TABLE ss_exercise_similarity (
  exerciseId TEXT NOT NULL,
  similarExerciseId TEXT NOT NULL,
  similarityScore REAL NOT NULL,
  PRIMARY KEY(exerciseId, similarExerciseId),
  FOREIGN KEY(exerciseId) REFERENCES ss_exercise(id) ON DELETE CASCADE
);
CREATE INDEX idx_ss_similarity_main ON ss_exercise_similarity(exerciseId, similarityScore DESC);
```

جدول ۸: `ss_user_profile` (پروفایل ورزشی کاربر):
```sql
CREATE TABLE ss_user_profile (
  id TEXT PRIMARY KEY DEFAULT 'default',
  goal TEXT NOT NULL,              -- MUSCLE_GAIN | FAT_LOSS | BODY_RECOMPOSITION | STRENGTH
  experienceLevel TEXT NOT NULL,   -- BEGINNER | INTERMEDIATE | ADVANCED
  trainingLocation TEXT NOT NULL,  -- HOME | GYM | OUTDOOR
  availableEquipment TEXT NOT NULL,-- JSON array
  daysPerWeek INTEGER DEFAULT 3,
  focusAreas TEXT,                 -- JSON array of BodyArea
  physicalLimitations TEXT,        -- JSON array of Limitation
  limitationNote TEXT,
  sessionDuration TEXT,            -- SHORT_30MIN | MEDIUM_45MIN | LONG_60MIN | FLEXIBLE
  gender TEXT,                     -- MALE | FEMALE
  onboardingCompleted INTEGER DEFAULT 0,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
);
```

━━━ بخش ۳: مدل‌های Dart ━━━

در پوشه `lib/features/supplementary_sports/data/models/` این فایل‌ها را بساز:

**`ss_exercise_model.dart`**: کلاس Dart برای جدول ss_exercise با تمام فیلدها، متدهای toMap() و fromMap().

**`ss_plan_models.dart`**: کلاس‌های WorkoutPlan، WorkoutExerciseCrossRef، PlanDaySummary.

**`ss_session_models.dart`**: کلاس‌های WorkoutSessionLog، ExerciseFeelingLog.

**`ss_user_profile_model.dart`**: کلاس UserProfile + Enum های زیر:
```dart
enum FitnessGoal { muscleGain, fatLoss, bodyRecomposition, strength }
enum ExperienceLevel { beginner, intermediate, advanced }
enum TrainingLocation { home, gym, outdoor }
enum Equipment { barbell, dumbbell, machine, resistanceBand, pullupBar, bodyweightOnly, kettlebell, cables }
enum BodyArea { chest, back, legs, shoulders, arms, core, glutes, fullBody }
enum Limitation { kneeProblems, backProblems, shoulderProblems, wristProblems, noPullUps, noJumping, none }
enum SessionDuration { short30, medium45, long60, flexible }
enum Feeling { easy, good, hard }
enum ExerciseStatus { done, current, upcoming }
```

━━━ بخش ۴: Repository Interface ━━━

در `lib/features/supplementary_sports/data/repositories/` این interface ها را بساز:

```dart
abstract class SSExerciseRepository {
  Future<List<SsExerciseModel>> getAllExercises();
  Future<List<SsExerciseModel>> getExercisesByCategory(String category);
  Future<List<SsExerciseModel>> getSimilarExercises(String exerciseId); // از جدول similarity
  Future<void> seedExercisesFromJson(String jsonString); // بارگذاری از فایل asset
}

abstract class SSPlanRepository {
  Future<SsUserProfile?> getUserProfile();
  Future<void> saveUserProfile(SsUserProfile profile);
  Future<List<WorkoutPlan>> getWeeklyPlan();
  Future<WorkoutPlan?> getTodayPlan();
  Future<List<WorkoutExerciseCrossRef>> getPlanExercises(String planId);
  Future<void> updateExerciseInPlan(WorkoutExerciseCrossRef updated);
  Future<void> addExerciseToPlan(String planId, WorkoutExerciseCrossRef exercise);
  Future<void> removeExerciseFromPlan(String planId, String exerciseId);
  Future<void> savePlanVersionSnapshot(String reason); // ذخیره snapshot برای Versioning
  Future<List<PlanVersionHistory>> getPlanVersionHistory();
  Future<void> restorePlanVersion(String versionId);
}

abstract class SSSessionRepository {
  Future<String> startSession(String planId); // برمی‌گرداند sessionId
  Future<void> logExerciseFeeling(String sessionId, String exerciseId, Feeling feeling);
  Future<void> finishSession(String sessionId, {required int completedCount, required int totalCount, String? overallFeeling});
  Future<bool> isTodaySessionLogged();
  Future<int> getCurrentStreak(); // روزهای متوالی
  Future<List<bool>> getLast7DaysActivity(); // هفت روز اخیر
  Future<int> getTotalSessionCount();
  Future<double> getMonthContinuityPercent();
  Future<List<ExerciseFeelingLog>> getRecentFeelings(int sessionCount);
  Future<List<ExerciseReadyForIncrease>> getExercisesReadyForProgression(); // حرکاتی که چند هفته EASY بوده‌اند
}
```

━━━ بخش ۵: تنظیمات اپلیکیشن ━━━

در `DatabaseHelper` ریتمو (یا در Migration) یک کلید جدید اضافه کن:
- کلید `module_supplementary_sports_enabled` در جدول `app_settings` با مقدار پیش‌فرض `false`.

در Migration جدید (version فعلی + 1) تمام جداول ss_ را بساز.

فقط کدهای این مرحله را بنویس. پس از اتمام منتظر تایید بمان.
```

---

## ═══════════════════════════════════════
## پرامپت شماره ۲ — کامپوننت‌های مشترک (Shared Widgets)
## ═══════════════════════════════════════

```
مرحله قبل تکمیل شد. حالا باید کامپوننت‌های مشترک این ماژول را در `lib/features/supplementary_sports/presentation/widgets/shared/` بسازی.

قوانین ثابت برای همه کامپوننت‌ها:
- فونت: Vazirmatn در همه جا
- جهت: RTL در همه جا
- Touch Target: حداقل 48×48dp
- هیچ عدد spacing به جز 4,8,12,16,24,32,48 استفاده نشود
- کنتراست رنگ حداقل WCAG AA باشد

━━━ ۱. SelectableCard ━━━
```dart
// در onboarding و plan edit استفاده می‌شود
Widget SelectableCard({
  required String title,
  required IconData icon,
  required bool selected,
  required VoidCallback onClick,
})
// وقتی selected=true: border رنگی + پس‌زمینه ملایم رنگی
// انیمیشن انتخاب: Scale 0.96 + تغییر رنگ در 150ms
// کارت باید حداقل 48dp ارتفاع داشته باشد
```

━━━ ۲. MultiSelectCard ━━━
```dart
// مثل SelectableCard اما چکباکس دارد و چند انتخاب ممکن است
Widget MultiSelectCard({
  required String title,
  required IconData icon,
  required bool selected,
  required VoidCallback onToggle,
})
```

━━━ ۳. OnboardingProgressBar ━━━
```dart
Widget OnboardingProgressBar({
  required int step,    // مرحله فعلی (مثلاً ۲)
  required int total,   // کل مراحل (۷)
})
// نمایش به صورت: ▬▬▬▭▭▭▭ (۲/۷)
// با انیمیشن روان هنگام رفتن به مرحله بعد
```

━━━ ۴. StepperInput ━━━
```dart
Widget StepperInput({
  required int value,
  required int min,
  required int max,
  required ValueChanged<int> onChanged,
})
// دکمه + و - در کنار عدد، با اعداد فارسی
```

━━━ ۵. PrimaryButton ━━━
```dart
Widget PrimaryButton({
  required String label,
  required VoidCallback? onPressed, // null = disabled
  bool isLoading = false,
})
// ارتفاع: 48dp (در صفحات ورزشی حین تمرین: 56dp)
// Corner Radius: 12dp
// فونت: 16sp Medium
```

━━━ ۶. SecondaryButton ━━━
```dart
Widget SecondaryButton({
  required String label,
  required VoidCallback? onPressed,
})
// بدون پس‌زمینه، فقط border
```

━━━ ۷. BottomSheetContainer ━━━
```dart
Widget BottomSheetContainer({
  required Widget child,
  String? title,
})
// Corner Radius بالا: 20dp
// handle bar بالا
// padding مناسب
```

━━━ ۸. LoadingShimmer ━━━
```dart
Widget LoadingShimmer({
  required double width,
  required double height,
  double borderRadius = 8,
})
// Shimmer animation که shape محتوای اصلی را تقلید می‌کند
// نه Spinner وسط صفحه
```

━━━ ۹. EmptyStateView ━━━
```dart
Widget EmptyStateView({
  required String message,      // پیام دوستانه
  required String actionLabel,  // متن دکمه اقدام
  required VoidCallback onAction,
  IconData? icon,
})
// هرگز فقط یک متن خشک نباشد — همیشه شامل اقدام پیشنهادی باشد
```

━━━ ۱۰. ContinuityBar ━━━
```dart
Widget ContinuityBar({
  required List<bool> daysCompleted, // ۷ روز اخیر
})
// ● برای روزهای با تمرین، ○ برای روزهای بدون تمرین
// با اعداد فارسی
// فشرده و یک خط — نه یک کارت بزرگ
```

━━━ ۱۱. ChatBubble ━━━
```dart
Widget ChatBubble({
  required String message,
  required bool isFromUser,
})
// پیام کاربر: راست-چین
// پیام AI: چپ-چین
```

━━━ ۱۲. StatCard ━━━
```dart
Widget StatCard({
  required String value,
  required String label,
})
// در Progress و Session Summary استفاده می‌شود
```

━━━ قوانین Loading/Empty/Error (همه صفحات) ━━━
- Loading: همیشه LoadingShimmer به شکل محتوای اصلی آن صفحه
- Empty: همیشه EmptyStateView با پیام دوستانه + دکمه اقدام
- Error: پیام کوتاه + دکمه «تلاش مجدد» — هرگز کد خطا به کاربر نشان داده نشود

━━━ قوانین انیمیشن (همه جا) ━━━
| تعامل | انیمیشن | زمان |
|---|---|---|
| تغییر صفحه | Slide + Fade | 250ms |
| انتخاب کارت Onboarding | Scale(0.96) + رنگ | 150ms |
| ثبت حرکت موفق | Check ✓ با Bounce | 300ms |
| باز شدن Bottom Sheet | Slide Up | 200ms |

━━━ قوانین Accessibility (همه جا) ━━━
- همه آیکون‌های تنها باید semanticsLabel فارسی داشته باشند
- پشتیبانی از بزرگنمایی فونت سیستم — هیچ متنی sp ثابت غیرقابل تغییر نباشد
- دکمه‌های حین تمرین (WorkoutSession) حداقل 56dp ارتفاع

فقط کدهای این مرحله را بنویس. پس از اتمام منتظر تایید بمان.
```

---

## ═══════════════════════════════════════
## پرامپت شماره ۳ — ثبت در سیستم‌های ریتمو + Onboarding (۷ مرحله)
## ═══════════════════════════════════════

```
مرحله قبل تکمیل شد. حالا باید:
الف) کارت «ورزش تکمیلی» را در SystemsHubScreen ریتمو ثبت کنی
ب) صفحه Onboarding کامل ۷ مرحله‌ای را بسازی

━━━ الف) ثبت در systems_hub_screen.dart ━━━

در فایل `lib/features/today/presentation/systems_hub_screen.dart`:

۱. یک flag جدید اضافه کن:
```dart
bool _supplementarySportsEnabled = false;
```

۲. در متد `_loadAllData` بخوان:
```dart
_supplementarySportsEnabled = _settingsMap['module_supplementary_sports_enabled'] == 'true';
```

۳. در متد `_buildModulesGrid`، داخل بخش `healthCards`، یک کارت جدید اضافه کن:
```dart
if (_matchesSearch('ورزش تکمیلی', 'برنامه تمرین هوشمند فیتنس')) {
  healthCards.add(
    _buildGridItem(
      index: cardIndex++,
      icon: Icons.fitness_center,
      iconColor: const Color(0xff22C55E),
      title: 'ورزش تکمیلی',
      description: 'برنامه تمرین هوشمند فیتنس',
      status: _supplementarySportsEnabled ? ModuleStatus.active : ModuleStatus.inactive,
      illustrationAsset: 'assets/images/supplementary_sports_card_top.png', // یا fallback به cycle_card_top.png
      onTap: () => _handleSupplementarySportsTap(colors),
      colors: colors,
      isDarkMode: isDarkMode,
    ),
  );
}
```

۴. متد `_handleSupplementarySportsTap` را اضافه کن:
```dart
void _handleSupplementarySportsTap(RitmoColors colors) {
  if (_supplementarySportsEnabled) {
    // برو به داشبورد اصلی ماژول
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SSHomeDashboardScreen()),
    ).then((_) => _loadAllData());
  } else {
    _showActivationSheet(
      title: 'فعال‌سازی ورزش تکمیلی',
      description: 'با فعال‌سازی این سیستم، می‌توانید برنامه تمرین هوشمند بر اساس سطح و اهداف خود دریافت کنید، حرکات را با بازخورد کیفی ثبت کنید و روند تداوم خود را دنبال کنید.',
      icon: Icons.fitness_center,
      iconColor: const Color(0xff22C55E),
      settingKey: 'module_supplementary_sports_enabled',
      onActivated: () {
        // اگر onboarding انجام نشده → برو به onboarding، وگرنه برو به داشبورد
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SSOnboardingFlow()),
        ).then((_) => _loadAllData());
      },
      colors: colors,
    );
  }
}
```

━━━ ب) صفحه OnboardingFlow ━━━

فایل: `lib/features/supplementary_sports/presentation/ss_onboarding_flow.dart`

کلاس State:
```dart
class SSOnboardingUiState {
  final int currentStep;     // ۱ تا ۷
  final int totalSteps = 7;
  final FitnessGoal? goal;
  final ExperienceLevel? experienceLevel;
  final TrainingLocation? trainingLocation;
  final Set<Equipment> availableEquipment;
  final int daysPerWeek;          // پیش‌فرض ۳
  final Set<BodyArea> focusAreas;
  final Set<Limitation> physicalLimitations;
  final String limitationNote;
  final SessionDuration? sessionDuration;
  final String? gender;          // MALE | FEMALE
  final bool isGeneratingPlan;
}
```

State باید بعد از هر استپ در SharedPreferences ذخیره شود تا اگر کاربر اپ را بست، از همان جا ادامه دهد.

۷ مرحله به این ترتیب:

مرحله ۱: هدف اصلی از ورزش
```
گزینه‌ها (تک‌انتخابی):
💪 عضله‌سازی (muscleGain)
🔥 کاهش چربی (fatLoss)
⚡ تناسب اندام (bodyRecomposition)
🏋 افزایش قدرت (strength)
```
→ با کلیک بدون نیاز به دکمه تایید، بلافاصله به مرحله ۲ برو.

مرحله ۲: سطح تجربه
```
گزینه‌ها (تک‌انتخابی):
🌱 تازه‌کار (beginner)
🏃 متوسط (intermediate)
🏆 پیشرفته (advanced)
```
→ تک‌انتخابی، بدون دکمه تایید.

مرحله ۳: محل تمرین
```
گزینه‌ها (تک‌انتخابی):
🏠 خانه (home)
🏋 باشگاه (gym)
🌳 فضای باز (outdoor)
```
→ تک‌انتخابی، بدون دکمه تایید.

مرحله ۴: تجهیزات موجود
```
گزینه‌ها (چند‌انتخابی - MultiSelectCard):
🏋 هالتر | 🏋 دمبل | 🖥 دستگاه‌ها | 🔴 کش مقاومتی
🔧 بارفیکس | 🤸 وزن بدن | 🔔 کتل‌بل | 🔩 کابل
```
→ چندانتخابی، نیاز به دکمه «ادامه» برای رفتن به مرحله بعد.

مرحله ۵: تعداد روزهای تمرین در هفته
```
با StepperInput از ۱ تا ۷، پیش‌فرض ۳
```
→ نیاز به دکمه «ادامه».

مرحله ۶: محدودیت جسمی (اختیاری)
```
گزینه‌ها (چندانتخابی):
🦵 مشکل زانو | 🔙 مشکل کمر | 💪 مشکل شانه
🤚 مشکل مچ | ⬆ نمی‌توانم بارفیکس بزنم | ⬇ نمی‌توانم بپرم
✓ بدون محدودیت
```
یک FreeTextField اختیاری برای توضیح بیشتر.
→ اگر رد شود، مقدار پیش‌فرض «بدون محدودیت» ثبت شود.

مرحله ۷: مدت هر جلسه
```
گزینه‌ها (تک‌انتخابی):
⏱ ۳۰ دقیقه (short30)
⏱ ۴۵ دقیقه (medium45)
⏱ ۶۰ دقیقه (long60)
♾ انعطاف‌پذیر (flexible)
```
→ با کلیک، GeneratePlanUseCase صدا زده شود.

پس از مرحله ۷:
- نمایش صفحه loading با پیام «در حال ساخت برنامه اختصاصی شما...»
- برنامه هفتگی در دیتابیس ذخیره شود
- کاربر به SSHomeDashboardScreen ارسال شود

Wireframe هر مرحله:
```
┌─────────────────────────────┐
│  ← بازگشت      ▬▬▬▭▭▭▭ (۲/۷) │  ← OnboardingProgressBar بالا
│                               │
│     [عنوان سوال H1]            │
│                               │
│   ┌─────────────────────┐   │
│   │   [آیکون] [گزینه ۱]  │   │  ← SelectableCard
│   └─────────────────────┘   │
│   ┌─────────────────────┐   │
│   │   [آیکون] [گزینه ۲]  │   │
│   └─────────────────────┘   │
│   ...                         │
└─────────────────────────────┘
```

نکات فنی:
- دکمه بازگشت باید به مرحله قبل برود و انتخاب‌های قبلی حفظ شوند
- در مراحل تک‌انتخابی: کلیک → بدون دکمه، بلافاصله استپ بعدی
- در مراحل چندانتخابی: کلیک → toggle، دکمه «ادامه» جداگانه
- ذخیره خودکار state در SharedPreferences بعد از هر استپ
- animation بین مراحل: Slide + Fade در 250ms

فقط کدهای این مرحله را بنویس. پس از اتمام منتظر تایید بمان.
```

---

## ═══════════════════════════════════════
## پرامپت شماره ۴ — داشبورد اصلی + نمای هفتگی + جزئیات روز
## ═══════════════════════════════════════

```
مرحله قبل تکمیل شد. حالا باید سه صفحه زیر را بسازی:

━━━ صفحه ۱: SSHomeDashboardScreen ━━━
فایل: `lib/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart`

این صفحه دارای یک Bottom Navigation با ۴ تب است:
- تب ۱ (خانه): SSHomeDashboardScreen
- تب ۲ (برنامه): SSPlanOverviewScreen
- تب ۳ (مربی): SSAiCoachChatScreen
- تب ۴ (پیشرفت): SSProgressScreen

اما این Bottom Nav فقط برای ماژول ورزش تکمیلی است، نه برای کل ریتمو.

State اصلی:
```dart
sealed class SSHomeUiState {
  const factory SSHomeUiState.loading() = _Loading;
  const factory SSHomeUiState.restDay({String? suggestion}) = _RestDay;
  const factory SSHomeUiState.workoutReady({
    required String dayName,
    required int exerciseCount,
    required int estimatedMinutes,
    required List<bool> continuity,
    String? aiSuggestion,
    required List<bool> weekTimeline,
  }) = _WorkoutReady;
  const factory SSHomeUiState.workoutCompleted({
    required String dayName,
    required String summary,
  }) = _WorkoutCompleted;
}
```

Wireframe صفحه (حالت workoutReady):
```
┌─────────────────────────────┐  ↑ Above the Fold
│  سلام 👋               ⚙️   │  
│                               │  
│  ┌─────────────────────────┐ │  ← TodayWorkoutCard — تنها عنصر با وزن بصری بالا
│  │   امروز: تمرین پا        │ │  
│  │   ۶ حرکت · حدود ۴۵ دقیقه│ │  
│  │                          │ │  
│  │   [ شروع تمرین ]         │ │  ← PrimaryButton بزرگ
│  │   امروز نمی‌تونم          │ │  ← SecondaryButton کوچک
│  └─────────────────────────┘ │  ↓
│ ┄┄┄┄┄┄┄(خط اسکرول)┄┄┄┄┄┄┄   │
│  ● ● ● ○ ○ ○ ○  تداوم هفته  │  ← ContinuityBar — کوچک و کمرنگ
│                               │
│  🤖 [پیشنهاد AI یک خط]       │  ← AiSuggestionBanner — فقط یک خط متن، بدون border
│                               │
│  ش ی د س چ پ ج               │  ← WeekMiniTimeline — کوچک
│  ✓ ✓ ✓ ● ○ ○ ○               │
├─────────────────────────────┤
│  خانه  برنامه  مربی  پیشرفت  │  ← Bottom Nav
└─────────────────────────────┘
```

قانون اصلی طراحی: Above the Fold فقط یک تصمیم → «شروع کن یا نه». بقیه اطلاعات جانبی هستند.

کامپوننت TodayWorkoutCard:
```dart
Widget TodayWorkoutCard({
  required String dayName,
  required int exerciseCount,
  required int estimatedMinutes,
  required VoidCallback onStart,
  required VoidCallback onCantToday,
})
```

کامپوننت AiSuggestionBanner:
```dart
Widget AiSuggestionBanner({
  required String message,
  required VoidCallback onOpenChat,
})
// فقط یک خط متن با آیکون 🤖 — بدون border، بدون سایه، بدون کارت بزرگ
```

کامپوننت WeekMiniTimeline:
```dart
Widget WeekMiniTimeline({
  required List<bool> days, // ۷ روز هفته
  required ValueChanged<int> onDayClick,
})
// نمایش حروف فارسی روزها: ش ی د س چ پ ج
```

Bottom Sheet «امروز نمی‌تونم»:
```
┌─────────────────────────────┐
│        چرا امروز نه؟          │
│                               │
│  [ وقت ندارم ]  [ خسته‌ام ]   │
│  [ درد دارم ]   [ دلیل دیگه ] │
└─────────────────────────────┘
```
پس از انتخاب هر گزینه: `AiCoachUseCase.handleSkipReason(reason)` فراخوانی شود.

رویدادها:
- `onStartWorkoutClicked()` → Navigate به SSWorkoutSessionScreen با planId امروز
- `onCantTodayClicked()` → باز شدن CantTodayBottomSheet
- `onDayInTimelineClicked(dayIndex)` → Navigate به SSPlanDayDetailScreen

Edge Cases:
- اگر از نیمه‌شب گذشته و تمرین دیروز انجام نشده → دیالوگ «می‌خوای جبران کنی یا رد شه؟»
- اولین بار بعد از Onboarding → TooltipOverlay سه‌قسمتی روی عناصر اصلی
- اگر چک‌این صبحگاهی فعال است و جواب نداده → نوار باریک بالای کارت («خوابت چطور بود؟») که قابل رد کردن است و هم‌وزن CTA اصلی نیست

━━━ صفحه ۲: SSPlanOverviewScreen ━━━
فایل: `lib/features/supplementary_sports/presentation/ss_plan_overview_screen.dart`

State:
```dart
class SSPlanOverviewUiState {
  final List<PlanDaySummary> weekDays;
  final String currentDayId;
  final bool isLoading;
}

class PlanDaySummary {
  final String id;
  final String dayName;       // شنبه، یکشنبه، ...
  final String muscleGroups;  // پا، سینه، ...
  final DayStatus status;     // completed | today | upcoming | rest
}
```

Wireframe:
```
┌─────────────────────────────┐
│  برنامه‌ی هفتگی               │
│                               │
│  [این هفته رو سبک‌تر/سنگین‌تر] │  ← این دکمه به SSAiCoachChatScreen لینک می‌شود با پیام پیش‌پر
│                               │
│  ┌─────────────────────────┐ │
│  │ شنبه      پا         ✓  │ │  ← WeekDayRow
│  ├─────────────────────────┤ │
│  │ یکشنبه    سرشانه     ✓  │ │
│  ├─────────────────────────┤ │
│  │ دوشنبه    سینه       ●  │ │  ← امروز (رنگ متفاوت)
│  ├─────────────────────────┤ │
│  │ سه‌شنبه    پشت        ○  │ │
│  └─────────────────────────┘ │
│  [بازسازی کامل هفته]          │
│  [تاریخچه‌ی تغییرات]          │
└─────────────────────────────┘
```

کامپوننت WeekDayRow:
```dart
Widget WeekDayRow({
  required String dayName,
  required String muscleGroup,
  required DayStatus status,
  required VoidCallback onTap,
})
// status: completed=✓ سبز | today=● accent | upcoming=○ خاکستری | rest=استراحت
```

رویدادها:
- کلیک روی هر ردیف → Navigate به SSPlanDayDetailScreen
- کلیک «سبک‌تر/سنگین‌تر» → Navigate به SSAiCoachChatScreen با پیام پیش‌پر
- کلیک «بازسازی کامل هفته» → دیالوگ تایید → GeneratePlanUseCase با پروفایل فعلی

━━━ صفحه ۳: SSPlanDayDetailScreen ━━━
فایل: `lib/features/supplementary_sports/presentation/ss_plan_day_detail_screen.dart`

State:
```dart
class SSPlanDayDetailUiState {
  final String dayName;
  final List<PlanExercise> exercises;
  final SSInlineAiSuggestion? inlineAiSuggestion;
  final bool isEditing;
  final bool isLoading;
}

class SSInlineAiSuggestion {
  final String id;
  final String message;
  final PlanChangeSuggestion change;
  final String primaryActionLabel;
}
```

Wireframe:
```
┌─────────────────────────────┐
│  ← دوشنبه — سینه              │
│                               │
│  ┌─────────────────────────┐ │
│  │ ⚡ پیشنهاد مربی:          │ │  ← InlineAiSuggestionCard (اگر وجود دارد)
│  │ سه هفته اخیر پرس سینه    │ │
│  │ برات راحت بوده.           │ │
│  │ وزنه‌اش رو ببرم بالا؟     │ │
│  │   [بله، ببر بالا]  [نه]  │ │
│  └─────────────────────────┘ │
│                               │
│  ┌─────────────────────────┐ │
│  │ پرس سینه هالتر           │ │  ← ExerciseEditableCard
│  │ ۳ ست × ۱۰ تکرار × ۴۰کیلو│ │
│  │        [ویرایش]  [حذف]  │ │
│  └─────────────────────────┘ │
│   ...                         │
│  [+ افزودن حرکت]              │
└─────────────────────────────┘
```

کامپوننت InlineAiSuggestionCard:
```dart
Widget InlineAiSuggestionCard({
  required String message,
  required String primaryActionLabel,
  required VoidCallback onAccept,
  required VoidCallback onDismiss,
})
// اگر چند پیشنهاد همزمان باشد → فقط مهم‌ترین یکی نشان داده شود
```

کامپوننت ExerciseEditableCard:
```dart
Widget ExerciseEditableCard({
  required PlanExercise exercise,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onSwap,
})
```

رویدادها:
- `onAdjustIntensityClicked()` → Navigate به SSAiCoachChatScreen با پیام پیش‌پر
- `onInlineSuggestionAccepted(suggestion)` → اعمال مستقیم تغییر + ذخیره snapshot در PlanVersionHistory
- `onInlineSuggestionDismissed(suggestion)`
- `onExerciseEditClicked(exercise)` → باز شدن EditExerciseBottomSheet
- `onExerciseSwapClicked(exercise)` → لیست جایگزین از SSExerciseRepository.getSimilarExercises()
- `onAddExerciseClicked()` → باز شدن AddExerciseBottomSheet
- `onRegenerateWeekClicked()` → دیالوگ تایید
- `onRestorePreviousVersion(versionId)` → بازیابی از PlanVersionHistory

Edge Cases:
- اگر آخرین حرکت یک روز حذف شود → هشدار «این روز خالی می‌ماند» + پیشنهاد جایگزین یا حذف کل روز
- هر تغییر (دستی یا AI) باید snapshot جدید در ss_plan_version_history بسازد

فقط کدهای این مرحله را بنویس. پس از اتمام منتظر تایید بمان.
```

---

## ═══════════════════════════════════════
## پرامپت شماره ۵ — موتور اجرای تمرین زنده (WorkoutSession) — مهم‌ترین بخش
## ═══════════════════════════════════════

```
مرحله قبل تکمیل شد. حالا باید پیچیده‌ترین بخش — SSWorkoutSessionScreen — را با بالاترین دقت پیاده‌سازی کنی.

⚠️ قانون طلایی (از architectural_blueprints.md):
هیچ پردازش سنگینی در این صفحه انجام نمی‌شود. تمام داده‌ها (لیست حرکات، اطلاعات جایگزین) باید قبل از ورود به صفحه آماده و inject شده باشند.

━━━ بخش ۱: معماری MVI ━━━

این صفحه باید از معماری MVI (Model-View-Intent) استفاده کند.
هیچ اکشنی نباید مستقیم state را تغییر دهد. همه اکشن‌ها از طریق Intent پردازش می‌شوند:

```dart
sealed class SSWorkoutIntent {
  const factory SSWorkoutIntent.markExerciseDone(String exerciseId) = _MarkDone;
  const factory SSWorkoutIntent.selectFeeling(String exerciseId, Feeling feeling) = _SelectFeeling;
  const factory SSWorkoutIntent.dismissFeelingSheet() = _DismissFeeling;
  const factory SSWorkoutIntent.swapExercise(String exerciseId) = _Swap;
  const factory SSWorkoutIntent.finishSession() = _Finish;
  const factory SSWorkoutIntent.skipRestTimer() = _SkipRest;
  const factory SSWorkoutIntent.addNoteToExercise(String exerciseId, String note) = _AddNote;
}
```

State:
```dart
class SSWorkoutSessionUiState {
  final String sessionId;        // id جلسه‌ای که در db شروع شد
  final String dayId;
  final List<SSExerciseChecklistEntry> exercises;
  final int currentExerciseIndex;
  final bool isShowingRestBanner;
  final int restRemainingSeconds;   // برای نمایش تایمر
  final int restTargetTimestamp;    // Unix timestamp پایان استراحت (برای Doze Mode)
  final bool isShowingFeelingSheet;
  final bool isFinished;
}

class SSExerciseChecklistEntry {
  final SsExerciseModel exercise;
  final int referenceSets;
  final int referenceReps;
  final double? referenceWeight;
  final ExerciseStatus status;  // done | current | upcoming
  final Feeling? feeling;       // null اگر ثبت نشده
  final String? optionalNote;
}
```

━━━ بخش ۲: رابط کاربری (Wireframe) ━━━

```
┌─────────────────────────────┐
│  ✕  تمرین امروز: سینه         │  ← دکمه بستن با دیالوگ تایید
│                               │
│  ┌─────────────────────────┐ │
│  │ ✓ پرس سینه هالتر         │ │  ← انجام‌شده: خط خورده + خاکستری
│  │   ۳ ست × ۱۰ تکرار × ۴۰کیلو│ │
│  ├─────────────────────────┤ │
│  │ ○ پرس سینه دمبل          │ │  ← حرکت فعلی: برجسته + accent color
│  │   ۳ ست × ۱۲ تکرار × ۱۶کیلو│ │  ← فقط text راهنما، قابل تایپ نیست!
│  │   [   انجام شد   ]       │ │  ← 56dp ارتفاع (بزرگ برای دست عرق‌کرده)
│  │   [جایگزین کن]           │ │
│  │   [یادداشت اختیاری ...]   │ │  ← اختیاری، کوچک، برجسته نباشد
│  ├─────────────────────────┤ │
│  │ ○ قفسه‌ی سینه دستگاه     │ │  ← بعدی: کمرنگ
│  │   ۳ ست × ۱۲ تکرار        │ │
│  └─────────────────────────┘ │
│   ⏱ استراحت: ۰۰:۴۵  [رد کن]  │  ← OptionalRestBanner (شناور بالای دکمه‌ها)
│        [پایان تمرین]          │
└─────────────────────────────┘
```

نکات UI:
- عدد ست/تکرار/وزنه فقط text راهنما — قابل تایپ نیست
- دکمه «انجام شد» و «جایگزین کن» حداقل 56dp ارتفاع (برای دست خسته)
- OptionalRestBanner شناور است، اجباری نیست، کاربر می‌تواند نادیده بگیرد

━━━ بخش ۳: QuickFeelingSheet ━━━

پس از زدن «انجام شد»، این Bottom Sheet کوچک باز می‌شود:
```
┌─────────────────────────────┐
│   این حرکت چطور بود؟          │
│                               │
│  [😌 راحت] [🙂 خوب بود] [😓 سخت] │
└─────────────────────────────┘
```
- با یک لمس، انتخاب می‌شود و sheet بسته می‌شود
- اگر کاربر لمس نکند: بعد از **۵ ثانیه** خودکار بسته می‌شود بدون ثبت بازخورد
- هیچوقت مانع سرعت کاربر نشود — ثبت بازخورد اجباری نیست

```dart
Widget QuickFeelingSheet({
  required ValueChanged<Feeling> onSelect,
  required VoidCallback onDismiss,
  Duration autoDismissAfter = const Duration(seconds: 5),
})
```

━━━ بخش ۴: تایمر Doze-Mode Safe ━━━

⚠️ به هیچ وجه از CountDownTimer ساده استفاده نکن — باگ Doze Mode ایجاد می‌کند!

الگوی صحیح:
```dart
// وقتی استراحت شروع می‌شود:
final int restDurationSeconds = 60;
final int targetTimestamp = DateTime.now().millisecondsSinceEpoch + (restDurationSeconds * 1000);
// این timestamp را در State ذخیره کن

// در هر rebuild یا resume اپ:
final int now = DateTime.now().millisecondsSinceEpoch;
final int remaining = ((targetTimestamp - now) / 1000).round().clamp(0, restDurationSeconds);
// remaining را نمایش بده — اگر گوشی خاموش شد و روشن شد، فوراً به ثانیه صحیح می‌رسیم
```

برای هشدار صوتی حین خاموش بودن صفحه:
- از WorkManager موجود ریتمو یا از AlarmManager (از طریق MethodChannel) استفاده کن
- پس از پایان استراحت یک Notification با صدا ارسال شود

━━━ بخش ۵: بازیابی state پس از بستن اپ ━━━

اگر کاربر وسط جلسه اپ را ببندد:
- state کامل (sessionId، currentExerciseIndex، لیست DONE ها) در SharedPreferences ذخیره شود
- با باز شدن مجدد، دقیقاً از همان `currentExerciseIndex` ادامه دهد
- وضعیت‌های DONE قبلی حفظ شوند

━━━ بخش ۶: پایان جلسه ━━━

دیالوگ تایید اگر هنوز حرکاتی مانده:
«هنوز X حرکت مانده. مطمئنی می‌خوای تموم کنی؟»
گزینه‌ها: «آره، امروز همینقدر بس بود» (بدون قضاوت) | «برگرد به تمرین»

پس از پایان جلسه:
- لاگ کامل در ss_workout_session_log ذخیره شود (تعداد انجام‌شده، کل، احساس کلی، مدت‌زمان)
- بازخوردهای کیفی هر حرکت در ss_exercise_feeling_log ذخیره شوند
- Navigate به SSSessionSummaryScreen

━━━ بخش ۷: SSSessionSummaryScreen ━━━

Wireframe:
```
┌─────────────────────────────┐
│      🎉 تمرین امروز تموم شد   │
│                               │
│   ۵ از ۶ حرکت انجام شد         │
│   حدود ۳۸ دقیقه               │
│                               │
│   احساس کلی امروز:             │
│   🙂 بیشتر «خوب بود»           │
│                               │
│   ۴ روز متوالیه که تمرین کردی! │
│   ● ● ● ● ○ ○ ○               │
│                               │
│      [ بازگشت به خانه ]       │
└─────────────────────────────┘
```

کامپوننت SessionSummaryCard:
```dart
Widget SessionSummaryCard({
  required int completedCount,
  required int totalCount,
  required int durationMinutes,
  Feeling? overallFeeling,
  required int continuityStreak,
  required List<bool> weeklyDots,
})
```

━━━ بخش ۸: SwapExercise — جایگزینی سریع ━━━

وقتی کاربر «جایگزین کن» می‌زند:
- نباید اینترنت یا LLM درخواست کند
- باید از جدول ss_exercise_similarity (Pre-computed) جایگزین را در میلی‌ثانیه پیدا کند

```dart
// در SSExerciseRepository:
Future<List<SsExerciseModel>> getSimilarExercises(String exerciseId) async {
  // join بین ss_exercise_similarity و ss_exercise
  // مرتب‌سازی بر اساس similarityScore DESC
  // بدون هیچ پردازش سنگین
}
```

لیست جایگزین در یک Bottom Sheet نمایش داده می‌شود. کاربر یکی را انتخاب می‌کند و جایگزینی فقط برای این جلسه اعمال می‌شود (نه در برنامه اصلی).

فقط کدهای این مرحله را بنویس. پس از اتمام منتظر تایید بمان.
```

---

## ═══════════════════════════════════════
## پرامپت شماره ۶ — مربی AI + صفحه پیشرفت + نوتیفیکیشن‌ها + تنظیمات
## ═══════════════════════════════════════

```
مرحله قبل تکمیل شد. این آخرین مرحله است.

━━━ صفحه ۱: SSAiCoachChatScreen ━━━
فایل: `lib/features/supplementary_sports/presentation/ss_ai_coach_chat_screen.dart`

State:
```dart
class SSAiCoachUiState {
  final List<SSChatMessage> messages;
  final List<String> quickReplies;
  final bool isAiTyping;
  final PlanChangeSuggestion? pendingSuggestion;
}

sealed class SSChatMessage {
  const factory SSChatMessage.text({
    required String content,
    required bool fromUser,
  }) = _TextMessage;
  
  const factory SSChatMessage.actionableSuggestion({
    required String description,
    required PlanChangeSuggestion change,
  }) = _ActionableSuggestion;
  
  const factory SSChatMessage.safetyWarning({
    required String content,
  }) = _SafetyWarning; // استایل بصری متفاوت — رنگ Danger
}

class PlanChangeSuggestion {
  final String exerciseId;
  final String action; // INCREASE_WEIGHT | DECREASE_WEIGHT | SWAP | REMOVE | ADD
  final Map<String, dynamic> parameters;
}
```

Wireframe:
```
┌─────────────────────────────┐
│  مربی هوشمند                  │
│  بر اساس برنامه و تاریخچه‌ات  │  ← AiAccessDisclosureBanner (شفافیت)
│                               │
│  ┌───────────────────┐      │
│  │ سلام! امروز چطوری؟│      │  ← ChatBubble (AI)
│  └───────────────────┘      │
│                               │
│        ┌───────────────────┐│
│        │ زانوم درد می‌کنه   ││  ← ChatBubble (User)
│        └───────────────────┘│
│                               │
│  ┌─────────────────────────┐│
│  │ باشه، اسکوات رو با       ││  ← ActionableSuggestionCard
│  │ لگ‌پرس جایگزین می‌کنم؟  ││
│  │   [تایید]      [نه]    ││
│  └─────────────────────────┘│
│                               │
│  [سبک‌ترش کن] [چی بخورم؟]    │  ← QuickReplyChipsRow
│  ┌─────────────────────────┐│
│  │  تایپ پیام...       [➤] ││  ← ChatInputBar
│  └─────────────────────────┘│
└─────────────────────────────┘
```

کامپوننت ActionableSuggestionCard:
```dart
Widget ActionableSuggestionCard({
  required String description,
  required VoidCallback onAccept,
  required VoidCallback onReject,
})
// وقتی کاربر تایید کرد: تغییر مستقیم روی WorkoutPlan اعمال شود (Function Calling)
// و یک پیام تاییدی در چت نمایش داده شود
```

کامپوننت QuickReplyChipsRow:
```dart
Widget QuickReplyChipsRow({
  required List<String> suggestions,
  required ValueChanged<String> onSelect,
})
// Quick Replies: «سبک‌ترش کن»، «سنگین‌ترش کن»، «چه غذایی بخورم؟»، «بعد از تمرین چیکار کنم؟»
```

رویدادها:
- `onSendMessage(text)` → ارسال به AI با context کامل (پروفایل + برنامه فعلی + خلاصه تاریخچه)
- `onSuggestionAccepted(change)` → اعمال مستقیم روی ss_workout_plan + snapshot در history
- `onSuggestionRejected(change)`
- `onQuickReplyClicked(text)` → معادل تایپ همان متن

Edge Cases:
- اگر پیام کاربر حاوی علائم خطرناک بود (درد شدید، تنگی نفس) → ChatMessage.safetyWarning با رنگ Danger + ارجاع به پزشک — بدون هیچ پیشنهاد تمرینی
- اگر اینترنت قطع بود → پیام «مربی هوشمند نیاز به اتصال اینترنت داره» + دکمه تلاش مجدد
- اگر از «سبک‌تر کن» در PlanOverviewScreen آمده → چت با پیام پیش‌پر شده باز شود

━━━ صفحه ۲: SSProgressScreen ━━━
فایل: `lib/features/supplementary_sports/presentation/ss_progress_screen.dart`

⚠️ قانون مهم: هیچ نمودار عددی وزنه (Line Chart) در این صفحه وجود ندارد!
تمرکز فقط بر تداوم و روند کیفی است.

State:
```dart
sealed class SSProgressUiState {
  const factory SSProgressUiState.empty() = _Empty;
  // حالت Empty: کاربر کمتر از ۳ جلسه داشته
  
  const factory SSProgressUiState.loaded({
    required int streakDays,
    required List<bool> weeklyDots,
    required List<Feeling> recentFeelings,  // آخرین N جلسه
    required int totalSessionCount,
    required double monthContinuityPercent,
    required List<ExerciseReadyForIncrease> exercisesReadyToProgress,
  }) = _Loaded;
}

class ExerciseReadyForIncrease {
  final String exerciseName;
  final int consecutiveEasyWeeks; // چند هفته متوالی EASY بوده
}
```

Wireframe:
```
┌─────────────────────────────┐
│  پیشرفت                      │
│                               │
│  ┌─────────────────────────┐│
│  │   ۴ روز متوالیه که       ││  ← ContinuityStreakCard — مهم‌ترین عدد صفحه
│  │   تمرین می‌کنی 🔥         ││
│  │   ● ● ● ● ○ ○ ○          ││
│  └─────────────────────────┘│
│                               │
│  روند احساس کلی (۴ هفته اخیر):│
│  ┌─────────────────────────┐│
│  │ 😌 😌 🙂 🙂 🙂 😓 🙂      ││  ← FeelingTrendStrip
│  └─────────────────────────┘│
│  بیشتر تمرین‌هات «خوب بود» بوده│
│                               │
│  ── آمار کلی ──               │
│  تعداد کل جلسات: ۴۲            │  ← OverallStatsGrid
│  درصد تداوم این ماه: ۸۵٪       │
│                               │
│  آماده‌ی سنگین‌تر شدن:          │
│  • پرس سینه هالتر (۳ هفته راحت) │  ← ReadyToProgressList
│  • اسکوات (۲ هفته راحت)        │
└─────────────────────────────┘
```

کامپوننت ContinuityStreakCard:
```dart
Widget ContinuityStreakCard({
  required int streakDays,
  required List<bool> weeklyDots,
})
```

کامپوننت FeelingTrendStrip:
```dart
Widget FeelingTrendStrip({
  required List<Feeling> recentFeelings,
})
// نمایش ایموجی‌ها: 😌=EASY, 🙂=GOOD, 😓=HARD
// اگر بیشتر GOOD: «بیشتر تمرین‌هات خوب بود» نمایش داده شود
```

کامپوننت ReadyToProgressList:
```dart
Widget ReadyToProgressList({
  required List<ExerciseReadyForIncrease> exercises,
})
// کلیک روی هر آیتم → Navigate به SSAiCoachChatScreen با پیام پیش‌پر
// «X هفته پرس سینه برات راحت بوده. می‌خوای وزنه‌اش رو ببریم بالا؟»
```

Edge Cases:
- حالت Empty (کمتر از ۳ جلسه): پیام «بعد از ۳ جلسه، روند تمرین‌هات اینجا نشون داده میشه» + یک نمای نمونه محو شده (Placeholder)

━━━ صفحه ۳: SSSettingsScreen ━━━
فایل: `lib/features/supplementary_sports/presentation/ss_settings_screen.dart`

Wireframe:
```
┌─────────────────────────────┐
│  ← تنظیمات ورزش تکمیلی       │
│                               │
│  پروفایل ورزشی                │
│  ┌─────────────────────────┐│
│  │ هدف: عضله‌سازی         ›  ││  ← قابل ویرایش (به Onboarding بازمی‌گردد)
│  │ سطح: متوسط              ›  ││
│  │ محل تمرین: باشگاه        ›  ││
│  └─────────────────────────┘│
│                               │
│  اعلان‌ها                     │
│  ┌─────────────────────────┐│
│  │ یادآوری روزانه تمرین [⚪→]││  ← Toggle + انتخاب ساعت
│  │ چک‌این صبحگاهی       [⚪→]││  ← Toggle اختیاری
│  └─────────────────────────┘│
└─────────────────────────────┘
```

━━━ بخش ۴: نوتیفیکیشن‌ها و پس‌زمینه ━━━

سه نوع نوتیفیکیشن باید پیاده‌سازی شود:

**۱. تایمر استراحت:**
- از AlarmManager (یا WorkManager موجود ریتمو) زمان‌بندی شود — نه CoroutineScope که با Kill شدن اپ می‌میرد
- اگر اپ Kill شد، در لحظه صحیح Notification با صدا ارسال شود
- کلیک روی notification → اپ باز می‌شود و WorkoutSession ادامه می‌یابد

**۲. یادآوری روزانه تمرین:**
- قابل تنظیم توسط کاربر (ساعت دلخواه)
- Navigate به SSHomeDashboardScreen

**۳. چک‌این صبحگاهی (اختیاری):**
- نوتیفیکیشن سبک «خوابت چطور بود؟»
- پاسخ روی شدت تمرین امروز اثر می‌گذارد

━━━ بخش ۵: منطق Progressive Overload ━━━

این منطق باید در SSSessionRepository پیاده‌سازی شود:

```dart
Future<List<ExerciseReadyForIncrease>> getExercisesReadyForProgression() async {
  // برای هر حرکت:
  // ۱. آخرین N هفته بازخوردهای کیفی را بخوان از ss_exercise_feeling_log
  // ۲. اگر ۳ هفته متوالی اکثر بازخوردها EASY بود → این حرکت آماده پیشرفت است
  // ۳. این حرکت را در ReadyToProgressList و در InlineAiSuggestion نشان بده
}
```

━━━ بخش ۶: DecisionLog ━━━

طبق Architecture Hard-Constraints در master_prd، یک جدول DecisionLog با این فیلدها باید اضافه شود:
```sql
CREATE TABLE IF NOT EXISTS ss_decision_log (
  id TEXT PRIMARY KEY,
  userId TEXT DEFAULT 'default',
  sessionId TEXT,
  exerciseId TEXT,
  decisionType TEXT NOT NULL,   -- «AI پیشنهاد داد» | «کاربر رد کرد» | «برنامه بازسازی شد»
  rejectionReason TEXT,
  createdAt INTEGER NOT NULL
);
```

━━━ چکلیست نهایی (از master_prd.md) ━━━

قبل از اتمام، مطمئن شو:
- [ ] Design Tokens (رنگ، تایپوگرافی، فاصله) در فایل اختصاصی تعریف شده
- [ ] Navigation بین صفحات ماژول کامل است
- [ ] OnboardingFlow با ذخیره state در SharedPreferences کار می‌کند
- [ ] جداول دیتابیس: ss_exercise، ss_workout_plan، ss_workout_exercise_crossref، ss_workout_session_log، ss_exercise_feeling_log، ss_plan_version_history، ss_exercise_similarity، ss_user_profile، ss_decision_log
- [ ] کامپوننت‌های مشترک مستقل ساخته شده‌اند
- [ ] HomeDashboardScreen با همه State ها (Loading, RestDay, WorkoutReady, WorkoutCompleted)
- [ ] WorkoutSessionScreen با MVI و بازیابی state پس از بستن اپ
- [ ] تایمر استراحت Doze-Mode Safe با Target Timestamp
- [ ] QuickFeelingSheet با auto-dismiss بعد از ۵ ثانیه
- [ ] جایگزینی حرکات از Pre-computed Graph بدون اینترنت
- [ ] AiCoachChatScreen با ActionableSuggestionCard و SafetyWarning
- [ ] ProgressScreen بدون نمودار وزنه — فقط تداوم و روند کیفی
- [ ] ReadyToProgressList بر اساس ۳ هفته متوالی EASY
- [ ] AlarmManager برای تایمر استراحت و یادآوری‌ها
- [ ] Accessibility: contentDescription فارسی، WCAG AA، Scalable Text
- [ ] کارت «ورزش تکمیلی» در systems_hub_screen.dart فعال است

کدهای این مرحله را بنویس. این آخرین مرحله است.
```
