# پرامپت ۰۱۵ — بازسازی کامل ورزش تکمیلی بر پایه‌ی مهندسی معکوس (Full Rebuild)

> **هدف نهایی:** ماژول «ورزش تکمیلی» (supplementary_sports) باید به یک کلون کامل و فارسی از تجربه‌ی اپ‌های رفرنس (Fitify Pro / Home Workout) تبدیل شود — رابط کاربری، آنبوردینگ، انیمیشن‌های تمرین، صداهای راهنما، آمار و پیشرفت، فرمول‌ها و موتورهای داخلی — و **فقط سیستم AI Coach فعلی از آن حفظ شود**.
>
> پرامپت ۰۱۲ فقط لایه‌ی منطق (پلن‌ساز، swap engine، progressive overload، AI coach واقعی) را ساخت. این پرامپت **بقیه‌ی کار** را انجام می‌دهد: دیتاست کامل، انیمیشن‌ها، صداها، و بازسازی تمام اسکرین‌ها طبق PRD.

---

## ⛔ قوانین مطلق (قبل از شروع بخوان)

1. **اول این چهار منبع را کامل بخوان — بدون خواندن این‌ها هیچ کدی ننویس:**
   - `C:\Users\bahman\Desktop\Besme-Allah\Ritmo3\varzesh\docs\master_prd.md` — سند ۷۲۲ خطی PRD: وایرفریم تک‌تک اسکرین‌ها، UiState ها، کامپوننت‌ها، Design Tokens، Navigation Graph، Edge Case ها. **این سند مرجع اصلی UI است؛ هر اسکرین باید دقیقاً طبق وایرفریم آن ساخته شود.**
   - `C:\Users\bahman\Desktop\Besme-Allah\Ritmo3\varzesh\docs\architectural_blueprints.md` — الگوهای معماری استخراج‌شده از Fitify (فیلدهای دیتابیس، الگوی many-to-many با difficultyOffset، تایمر Doze-safe با Target Timestamp، MVI، گراف swap از پیش محاسبه‌شده).
   - `C:\Users\bahman\Desktop\Besme-Allah\Ritmo3\varzesh\assets\data\fitify_schema_42.json` — اسکیمای کامل Room دیتابیس Fitify (نسخه ۴۲) به‌عنوان مرجع ساختار جداول.
   - چند رکورد اول `fitify_exercises_bodyweight.json` (ساختار در Stage B توضیح داده شده).
2. **PRD به سبک Kotlin/Compose نوشته شده** (data class ها، sealed class ها، NavGraph). تو باید معادل Flutter/Riverpod آن‌ها را بسازی: `data class` → مدل Dart با freezed-style یا کلاس immutable ساده (مطابق idiom فعلی پروژه)، `StateFlow/UiState` → Riverpod `Notifier` + state کلاس، `NavGraph` → روتینگ فعلی پروژه. **اسم‌ها را حفظ کن** (مثلاً `WorkoutSessionUiState`، `TodayWorkoutCard`) تا قابل ردیابی با PRD باشند.
3. **سیستم AI دست نخورد:** `ss_ai_coach_sheet.dart`، اتصال به AIGateway/ChatRepository/ChatActionParser/AssistantActionRegistry و اکشن‌های موجود حفظ می‌شوند. فقط در Stage K اکشن‌های جدید به آن اضافه می‌شود.
4. **هیچ mock/placeholder/TODO باقی نماند.** هر اسکرین یا کامل ساخته می‌شود یا اصلاً در navigation ظاهر نمی‌شود.
5. تمام متن‌های UI **فارسی** با فونت Vazirmatn و RTL. اعداد فارسی در نمایش (مطابق ابزارهای فعلی پروژه). تقویم جلالی در همه‌جا.
6. پس از هر Stage: `flutter analyze` باید صفر خطا باشد. تست‌های موجود نشکنند.
7. کارها را با TaskCreate ثبت کن و وضعیت هر Stage را آپدیت کن.

---

## Stage A — پایپ‌لاین Asset ها (انیمیشن، صدا، دیتا)

> ⛔ **تصمیم قطعی: از ویدیوهای `varzesh/assets/videos/` استفاده نمی‌شود.** نمایش حرکات فقط با **انیمیشن‌های Lottie** انجام می‌شود.

**انیمیشن‌ها از قبل داخل پروژه هستند:**
- `assets/animations/custom/` — **۳۲۱ انیمیشن Lottie استخراج‌شده از اپ Home Workout** با نام‌گذاری `hw_<ID>.json` (~22MB)
- `assets/animations/` — ۱۶ انیمیشن دسته‌ای/سیستمی: `workout_arms/back/cardio/chest/core/general/legs/shoulders/running` + `workout_complete/loading/rest/start/success/timer/trophy`
- ویجت `ss_lottie_player.dart` با کلاس `SSLottieAssets` موجود است (fallback دسته‌ای + keyword matching) — پایه‌ی کار است اما یک **باگ حیاتی** دارد (کار ۳).

منابع خامی که باید از varzesh کپی شوند:

| منبع | محتوا | مقصد در پروژه |
|---|---|---|
| `audio/` | ۱۰ فایل cue: `sound_go.mp3`, `sound_321rest.mp3`, `sound_321rest_yoga.mp3`, `sound_321rest_yoga_short.mp3`, `sound_change_sides.mp3`, `sound_go_yoga.mp3`, `fanfare.mp3`, `prism_chime.wav`, `prism_completed.wav`, `prism_success.wav` | `assets/ss_audio/` |
| `data/fitify_exercises_bodyweight.json` (~996KB) | دیتاست کامل تمرین‌های بدون‌وزنه با تمام امتیازها | `assets/data/` |
| `data/fitify_exercise_similarity_relations.json` (~1.1MB) | گراف شباهت از پیش محاسبه‌شده | `assets/data/` |

کارها:
1. فایل‌های audio و data را کپی و در `pubspec.yaml` رجیستر کن (`assets/ss_audio/` اضافه شود؛ `assets/data/` و `assets/animations/` از قبل رجیسترند).
2. **جدول mapping صریح `exercise_code → hw_ID`:** فایل `lib/features/supplementary_sports/data/seed/ss_exercise_animation_map.dart` بساز — برای **تک‌تک تمرین‌های دیتاست Fitify**، انیمیشن `hw_*` مناسب را با تطبیق معنایی نام حرکت تعیین کن (مثلاً `bo009_squats` → hw ای که واقعاً اسکوات نمایش می‌دهد). برای این کار محتوای keyword matching فعلی `SSLottieAssets` را به‌عنوان نقطه‌ی شروع بردار و لیست ۳۲۱ فایل `hw_*.json` موجود را مبنا قرار بده (فقط ID هایی که واقعاً وجود دارند). تمرینی که match مطمئن ندارد → `null` و fallback دسته‌ای: بالاترین امتیاز `category` رکورد تعیین می‌کند (core → `workout_core.json`، cardio → `workout_cardio.json` و…).
3. **رفع باگ resolver فعلی:** `SSLottieAssets.forExercise` الان عدد داخل id تمرین را با RegExp استخراج می‌کند و همان را `hw_N.json` فرض می‌کند — برای کدهای Fitify (`bo001_...`) این mapping **غلط و گمراه‌کننده** است (انیمیشن بی‌ربط نشان می‌دهد). این منطق عددی حذف و با جدول صریح کار ۲ جایگزین شود. زنجیره‌ی نهایی resolve: جدول صریح → keyword matching → fallback دسته‌ای → `workout_general.json`. هرگز کرش نه.
4. تست: `ss_animation_map_test.dart` — هر مسیر برگردانده‌شده برای تمام کدهای دیتاست، به فایل asset واقعاً موجود اشاره کند؛ تعداد تمرین‌های fallback خورده گزارش شود.
5. پخش صدا با پکیج صوتی موجود پروژه (اگر نیست `audioplayers`). یک `SsAudioCuePlayer` با متدهای معنایی: `playGo()`, `playCountdownToRest()`, `playChangeSides()`, `playWorkoutCompleted()` (fanfare), `playTick()`.

## Stage B — دیتابیس: Migration بعدی + Seed کامل دیتاست Fitify

ساختار هر رکورد `fitify_exercises_bodyweight.json` (کلید ریشه `exercises`، آرایه):

```json
{
  "code": "bo001_side_leg_lift",
  "title": "Side Leg Lift",
  "category": {"cardio":2,"plyometric":0,"lower_body":0,"upper_body":0,"shoulder_and_back":0,"core":5,"stretching":0,"yoga":0,"balance":1,"warmup":0},
  "stance": "F",
  "skill_required": 5, "skill_max": 8,
  "sexyness_m": 5, "sexyness_f": 5, "gym_sexyness_m": 5, "gym_sexyness_f": 5,
  "looks_cool": 2, "impact": 0, "noisy": 0, "change_sides": true,
  "sets": { "<set_code>": {"suitability":5,"difficulty":2,"order":0,"skill_required":-1,"skill_max":-1}, ... }
}
```

نکته‌ی حیاتی: بعضی set ها (مثل `full_body`, `hiit`, `tabata`, `sprint_cardio`, `fem_*`) به‌جای `suitability` واحد، چهار امتیاز تفکیکی دارند: `suitability_lowerbody`, `suitability_abscore`, `suitability_back`, `suitability_upperbody`. مدل داده باید هر دو حالت را پشتیبانی کند.

کارها:
1. **Migration نسخه‌ی بعدی** (نسخه فعلی DB را از `database_helper.dart` بخوان و +1 کن):
   - `ss_exercise` را با ستون‌های جامانده کامل کن (با schema فعلی مقایسه کن؛ فقط ستون‌های ناموجود اضافه شوند): `code` (کد Fitify، unique)، `title_en`، امتیازهای category به‌صورت ۱۰ ستون int (`cat_cardio` … `cat_warmup`)، `stance`، `skill_required`، `skill_max`، `sexyness_m`، `sexyness_f`، `looks_cool`، `impact`، `noisy`، `change_sides` (int 0/1)، `reps_double` (int)، `rep_duration_low/medium/high` (real — اگر در دیتاست/schema_42 موجود بود از آن، وگرنه پیش‌فرض معقول per-category)، `animation_asset` (text nullable — مسیر Lottie از جدول mapping کار A-2؛ NULL یعنی fallback دسته‌ای در runtime).
   - جدول جدید `ss_workout_set` (تعریف انواع تمرین/Set های Fitify): `id, code, title_fa, description_fa, icon, focus (json), difficulty_levels, is_female_oriented (fem_*), sort_order`.
   - `ss_exercise_set_suitability` (جدول واسط): `exercise_id, set_code, suitability, suitability_lowerbody, suitability_abscore, suitability_back, suitability_upperbody, difficulty, sort_order, skill_required, skill_max` (مقادیر `-1` یعنی ارث‌بری از خود تمرین).
   - `ss_exercise_similarity` را از `fitify_exercise_similarity_relations.json` **کامل re-seed** کن (ساختار JSON را اول بخوان و mapping دقیق بنویس).
2. **Seed کامل:** تمام رکوردهای دیتاست (همه، نه زیرمجموعه) وارد `ss_exercise` شوند. seed باید idempotent باشد (بر اساس `code` upsert).
3. **نام فارسی تمام تمرین‌ها:** جدول ستون `title_fa` دارد. یک فایل `lib/features/supplementary_sports/data/seed/ss_exercise_farsi_names.dart` بساز با Map کامل `code → (نام فارسی, توضیح یک‌خطی فارسی فرم صحیح حرکت)`. **برای تک‌تک تمرین‌های دیتاست** — نه فقط معروف‌ها. ترجمه‌ها باید اصطلاح رایج بدنسازی فارسی باشند (Squats → اسکوات، Mountain Climbers → کوهنوردی، Side Leg Lift → بالا بردن پا از پهلو).
4. Set های bodyweight که باید فعال شوند (gym_* ها فعلاً seed می‌شوند ولی `enabled=0`): `insane_six_pack`، `complex_core`، `light_cardio`، `low_impact`، `balance`، `a_upper_body`، `b_lower_body`، `healthy_posture`، `healthy_posture_more_stretching`، `lose_belly`، `obliques`، `full_body`، `hiit`، `sprint_cardio`، `tabata`، `fem_rounds`، `fem_hiit`، `fem_interval_training`، `fem_tabata` — برای هرکدام عنوان و توضیح فارسی جذاب بنویس (مثلاً `insane_six_pack` → «شکم شش‌تکه»، `lose_belly` → «آب کردن شکم»).
5. تست migration + seed: `test/supplementary_sports/db_seed_test.dart` — تعداد رکوردها، وجود suitability ها، سلامت similarity graph (هر ID مقصد واقعاً وجود دارد).

## Stage C — بازنویسی PlanGenerator بر اساس الگوریتم واقعی Fitify

`ss_plan_generator.dart` فعلی weighted-rules ساده دارد. آن را به الگوریتم set-based واقعی ارتقا بده:

1. **انتخاب Set بر اساس goal کاربر:** mapping صریح `goal/focusAreas → set_code` بنویس (مثلاً هدف «شکم» → `insane_six_pack`/`lose_belly`/`obliques`؛ «کاردیو کم‌فشار» → `low_impact`/`light_cardio`؛ کاربر خانم + هدف عمومی → واریانت‌های `fem_*`). جدول mapping را در کد مستند کن.
2. **چینش تمرین‌های یک جلسه از روی جدول suitability:**
   - فیلتر: `suitability > 0` برای set انتخابی؛ گیت مهارت (`skill_required` مؤثر ≤ سطح کاربر ≤ `skill_max` مؤثر، با قانون ارث‌بری `-1`)؛ فیلتر `impact`/`noisy` اگر حالت «بی‌صدا/همسایه‌دوست» فعال است؛ محدودیت‌های جسمی کاربر (constraintNegative موجود از ۰۱۲).
   - رتبه‌بندی: `score = suitability*W1 + sexyness(جنسیت کاربر)*W2 + looks_cool*W3 − |difficulty − سطح کاربر|*W4`؛ برای set های چهارامتیازی، suitability مؤثر = میانگین وزنی طبق focusAreas کاربر. وزن‌ها ثابت‌های نام‌دار و تست‌شده.
   - ترتیب اجرا: `sort_order`/`order` از جدول suitability (صفر یعنی آزاد)؛ warmup اول، stretching آخر.
   - `difficultyOffset` در `ss_workout_exercise_crossref` طبق blueprint اعمال شود.
3. **مدت‌زمان هر تمرین:** بر اساس `rep_duration_*` × تعداد تکرار هدف؛ تمرین‌های `change_sides=true` باید مدت زوج و cue وسط داشته باشند؛ `reps_double` در شمارش لحاظ شود (جلوگیری از شمارش مضاعف — طبق blueprint).
4. حلقه‌ی progressive overload و swap engine موجود از ۰۱۲ حفظ و به دیتای جدید وصل شوند (swap فقط از `ss_exercise_similarity` seed شده‌ی جدید).
5. تست: `plan_generator_v2_test.dart` — برای ۳ پروفایل متفاوت (مبتدی خانم با هدف شکم / متوسط آقا full_body / کاربر آپارتمان‌نشین با حالت بی‌صدا) خروجی پلن assert شود: هیچ تمرین خارج از گیت مهارت، هیچ تمرین noisy در حالت بی‌صدا، ترتیب warmup/stretching درست.

## Stage D — بازسازی WorkoutSessionScreen (قلب اپ) طبق PRD

`ss_workout_session_screen.dart` + `ss_workout_session_notifier.dart` را طبق بخش WorkoutSessionScreen در master_prd.md بازسازی کن:

1. **انیمیشن Lottie loop شونده‌ی تمرین** تمام‌عرض بالای صفحه (از زنجیره‌ی resolve کار A-3، با `SSLottiePlayer` موجود)؛ در استراحت‌ها `workout_rest.json` + نام و preview انیمیشن تمرین بعدی.
2. **State machine کامل** (همه state ها در `WorkoutSessionUiState` طبق PRD): `preparing → countdown(3-2-1 با sound_321) → exercising → changeSides (وسط تمرین‌های change_sides با sound_change_sides) → resting (OptionalRestBanner با دکمه‌ی رد کردن) → nextExercise → completed`.
3. **صداها و TTS فارسی:** شروع تمرین `sound_go` + TTS نام تمرین؛ ۳ ثانیه آخر استراحت `sound_321rest`؛ پایان جلسه `fanfare`. TTS با موتور موجود پروژه؛ اگر نیست `flutter_tts` با زبان fa-IR و fallback خاموش.
4. **تایمر Doze-safe** (الگوی blueprint): فقط target timestamp در state؛ `didChangeAppLifecycleState` → resync. تست unit برای jump-forward.
5. کنترل‌ها طبق PRD: pause/resume، skip، «نمی‌توانم این حرکت را انجام دهم» → شیت swap فوری از گراف شباهت (بدون هیچ محاسبه‌ی سنگین در فریم — قانون طلایی blueprint)، `QuickFeelingSheet` بعد از هر تمرین (سه حالت آسان/خوب/سخت — به feeling log موجود وصل است).
6. MVI: تمام تعامل‌ها به‌صورت intent وارد notifier شوند؛ هیچ setState پراکنده.
7. تست state machine: `workout_session_state_test.dart` (چرخه کامل Play→Pause→Rest→ChangeSides→Finish).

## Stage E — آنبوردینگ کامل طبق PRD

`ss_onboarding_flow.dart` را با فلوی PRD (بخش OnboardingFlow/OnboardingUiState) تطبیق کامل بده. قدم‌ها طبق PRD و فیلدهای موجود `ss_user_profile` (جنسیت، سن، قد/وزن، سطح تجربه/ExperienceLevel، هدف، focusAreas روی نقشه بدن، محدودیت‌های جسمی، تجهیزات/availableEquipment، محل تمرین/trainingLocation، مدت جلسه/sessionDuration، روزهای هفته، حالت بی‌صدا). هر قدمی که PRD دارد و فلوی فعلی ندارد اضافه شود؛ در پایان: محاسبه BMI + تولید پلن با `GeneratePlanUseCase` + انیمیشن «در حال ساخت برنامه...» (LoadingShimmer/پیام مرحله‌ای). BMI و بازه سالم در صفحه نتیجه نمایش داده شود.

## Stage F — HomeDashboard طبق PRD

طبق وایرفریم PRD: `TodayWorkoutCard` (تمرین امروز + مدت تخمینی + دکمه شروع بزرگ)، `ContinuityBar`/`WeekMiniTimeline` (نوار ۷ روز اخیر با حلقه‌های check)، `CantTodayBottomSheet` («امروز نمی‌توانم» → کاهش ۲۰٪ تکرارها و استراحت ۴۵ ثانیه توسط AI — منطق موجود از ۰۱۲)، کارت AI Coach، دسترسی به کتابخانه تمرین‌ها و پلن. Edge case های PRD (روز استراحت، پلن تمام‌شده → پیشنهاد پلن بعدی).

## Stage G — PlanOverview + PlanDayDetail طبق PRD

تقویم ۲۸ روزه (جلالی) با حلقه‌های وضعیت (انجام‌شده/امروز/آینده/ازدست‌رفته)، درصد پیشرفت پلن، `PlanDayDetailScreen` با لیست `ExerciseEditableCard` (تعویض/ویرایش ست‌وتکرار/حذف)، `PlanHistoryBottomSheet` و restore نسخه (اگر `ss_plan_version_history` از ۰۱۲ موجود است به آن وصل شو)، `InlineAiSuggestionCard` برای پیشنهادهای AI (اتصال به `PlanChangeSuggestion` موجود).

## Stage H — SessionSummary + فرمول کالری

طبق PRD: مدت واقعی، تعداد تمرین کامل‌شده، **کالری با فرمول MET**: `kcal = MET × وزن(kg) × مدت(h)` که MET هر تمرین از category امتیازها استخراج می‌شود (cardio/plyometric بالا → MET بالاتر؛ جدول MET نام‌دار و مستند در کد: مثلاً cardio≥4 → MET 8، core → MET 4، stretching/yoga → MET 2.5). fanfare + انیمیشن جشن (از assets/animations موجود). `FeelingTrendStrip` سه‌حالته. دکمه‌ی share/ثبت در تقویم اصلی Ritmo (اگر اتصال تقویم از ۰۱۳ موجود است).

## Stage I — ProgressScreen کامل (آمار)

طبق PRD (`ProgressUiState`, `ContinuityStreakCard`, `OverallStatsGrid`): streak فعلی و رکورد، مجموع جلسات/دقیقه/کالری، تقویم heatmap جلالی ماهانه، نمودار هفتگی (با پکیج چارت موجود پروژه)، `FeelingTrendStrip` روند feeling ها، وزن کاربر + ثبت وزن جدید و نمودار روند وزن، `ReadyToProgressList` (اتصال به `getExercisesReadyForProgression` موجود از ۰۱۲).

## Stage J — Settings طبق PRD

تنظیمات کامل: صدای مربی (TTS on/off + شمارش معکوس)، صدای cue ها، مدت استراحت پیش‌فرض، حالت بی‌صدا/همسایه‌دوست (سراسری)، یادآور روزانه تمرین (اتصال به AlarmSchedulerService موجود پروژه)، واحدها، ریست پلن/شروع دوباره آنبوردینگ (با تأیید دومرحله‌ای)، درباره‌ی داده‌ها.

## Stage K — اتصال AI (فقط افزودن، نه بازنویسی)

به `AssistantActionRegistry` اکشن‌های جدید اضافه کن (الگوی اکشن‌های موجود): `swap_exercise(code)`، `set_quiet_mode(on)`، `change_set_program(set_code)`، `reschedule_day(from,to)`. هر اکشن مثل قبل: اجرای واقعی + گزارش صادقانه نتیجه (هرگز موفقیت کاذب). دیتای context که به AI می‌رود شامل set فعلی، streak، و آخرین feeling ها باشد.

## Stage L — Design Tokens و Theme

`supplementary_sports_theme.dart` را با Design Tokens بخش پایانی master_prd.md همگام کن (رنگ‌ها، radius، spacing، تایپوگرافی — مقادیر دقیق را از سند بردار، از خودت اختراع نکن). موشن‌ها طبق PRD (Slide+Fade 250ms، Bounce 300ms و…).

## Stage M — تحقیق و پاک‌سازی

1. هر کد/ویجت orphan شده حذف شود؛ `flutter analyze` صفر خطا.
2. `flutter test test/supplementary_sports/` همه سبز.
3. **گزارش نهایی** در `prompts/015_REPORT.md`: هر Stage چه شد، لیست تمرین‌های بدون انیمیشن اختصاصی hw_ (که fallback دسته‌ای خورده‌اند)، تمرین‌های بدون ترجمه (باید صفر باشد)، تصمیم‌های مهم، و هر انحرافی از PRD با دلیل.

---

## ✅ چک‌لیست پذیرش نهایی

- [ ] تمام رکوردهای `fitify_exercises_bodyweight.json` در DB با نام فارسی seed شده‌اند
- [ ] هر تمرین در session/library انیمیشن Lottie معناً درست نمایش می‌دهد (جدول mapping صریح + fallback دسته‌ای)؛ باگ RegExp عددی `forExercise` حذف شده؛ هیچ کرشی برای کد بدون انیمیشن
- [ ] هر ۱۰ فایل صوتی در جای درست چرخه‌ی تمرین پخش می‌شوند
- [ ] پلن‌ساز set-based با گیت مهارت، فیلتر بی‌صدا، sexyness جنسیتی و difficultyOffset کار می‌کند
- [ ] state machine جلسه شامل countdown/changeSides/rest است و تایمر Doze-safe است
- [ ] آنبوردینگ تمام قدم‌های PRD را دارد و به تولید پلن ختم می‌شود
- [ ] داشبورد/پلن/جزئیات روز/خلاصه جلسه/پیشرفت/تنظیمات مطابق وایرفریم‌های PRD
- [ ] کالری با فرمول MET محاسبه و در خلاصه و آمار نمایش داده می‌شود
- [ ] streak و heatmap جلالی در ProgressScreen واقعی‌اند (نه mock)
- [ ] AI Coach دست‌نخورده + ۴ اکشن جدید واقعی
- [ ] `flutter analyze` = 0 خطا، همه تست‌ها سبز، گزارش 015_REPORT.md نوشته شده
