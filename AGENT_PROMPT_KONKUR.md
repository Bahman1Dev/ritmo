# 🤖 پرامپت اجرایی — سیستم «کنکور» (Konkur) — برای Gemini 3.5 Flash

> فایلِ **خودبسنده**. کل آن را عیناً به Gemini بده. هدف: بازسازیِ کاملِ ماژولِ کنکور از یک CRUD ساده به یک سیستمِ کاملِ کنکور — روزشمار، بودجه‌بندی، برنامه‌سازِ هوشمند، ثبتِ مطالعه/تست با تایمر، کارنامه با درصدِ منفی‌دار و نمودارِ روند، اتصال به داشبورد، و دستیار AI.
> سندِ طراحیِ همراه (برای انسان): `DESIGN_SYSTEM_KONKUR.md`.
> فایلِ اصلیِ جدید: `lib/features/konkur/presentation/konkur_screen.dart` (جایگزینِ منطقیِ `konkur_dashboard_screen.dart`).

---

## ⛔️ قوانین سخت
1. **هر بار فقط یک تسک.** بعد از هر تسک `flutter analyze` و `flutter test` اجرا و گزارش کن. error یا تستِ شکست‌خورده‌ی جدید → برگردان و گزارش بده.
2. **فقط فایل‌های نام‌برده‌ی هر تسک را تغییر بده.** ریفکتورِ نامرتبط ممنوع.
3. **متن‌ها فارسی و RTL.** فونت `Vazirmatn`. ارقام فارسی. تاریخ‌ها **شمسی** (پکیجِ `shamsi_date` که نصب است). کلیدهای جدیدِ l10n به `app_fa.arb` و `app_en.arb`.
4. **رنگ/اندازه/رادیوس هاردکد نکن** — از `RitmoTheme` و `context.colors` استفاده کن. رنگِ پایه‌ی کنکور: بنفش `#8B5CF6`.
5. **لحنِ تشویقی.** برای عقب‌افتادگی هرگز سرزنش؛ «۳ روز عقبی، جبران می‌کنی 💪» نه «شکست خوردی». روزشمار آرام باشد، نه قرمزِ اضطراب‌آور.
6. **تسک‌های K1 و K14 حساس به مهاجرت‌اند:** بعد از هرکدام **توقف کن و منتظر تأیید انسانی بمان**.
7. **داده‌ی فعلی تستی است؛ حفظش مهم نیست.** ولی چون ستون‌ها را با `DEFAULT` اضافه می‌کنیم، رکوردهای قدیمی هم سالم می‌مانند. لازم نیست `INSERT...SELECT` برای انتقالِ داده بنویسی.
8. **درصدِ پیشرفت هرگز دستی تایپ نمی‌شود.** از سطحِ تسلطِ مباحث + جلسات مشتق می‌شود (جزئیات در K5). هیچ عددِ ساختگی نمایش نده.
9. چیزی مبهم بود → بپرس، حدس نزن.

## 📁 محیطِ پروژه (از کد تأیید شده)
- Flutter، ریشه `ritmo/`. دیتابیس SQLite (`sqflite_sqlcipher`).
- **نسخه‌ی دیتابیس:** در PASS 0 نسخه‌ی فعلی را از `database_helper.dart` بخوان و گزارش کن. مهاجرتِ این سیستم باید **نسخه‌ی فعلی + ۱** باشد. (اگر مهاجرتِ سیستمِ «چرخه» قبلاً v14 را گرفته باشد، این می‌شود **v15**؛ اگر نه، v14. عدد را بر اساسِ واقعیتِ کد تعیین کن و نامِ تابعِ مهاجرت را با همان عدد هماهنگ کن.)
- جداولِ موجودِ کنکور (در `_createDB`):
  - `konkur_subjects` (id, name, importanceFactor, progressPercentage, isArchived, createdAt, updatedAt)
  - `konkur_topics` (id, subjectId, parentTopicId, name, progressPercentage, studyTargetMinutes, studyCompletedMinutes, createdAt, updatedAt)
  - `konkur_mock_exams` (id, title, examDate, createdAt)
  - `konkur_mock_exam_results` (id, mockExamId, subjectId, percentage, correctAnswers, wrongAnswers, emptyAnswers, createdAt)
- صفحه‌ی فعلی `lib/features/konkur/presentation/konkur_dashboard_screen.dart` — منطقِ CRUDِ آن مرجع است؛ بازنویسی می‌شود نه ویرایش. **حذفش نکن تا K13.**
- `systems_hub_screen.dart` — کاشیِ کنکور از قبل به صفحه + شیتِ فعال‌سازی (`module_konkur_enabled`) وصل است (`_handleKonkurTap`). فقط مقصدِ Navigation در K13 به `KonkurScreen` تغییر می‌کند.
- `RitmoEngineBus` + الگوی `CachedEngine` — مرجعِ صحیح: `lib/features/today/presentation/insights_screen.dart` و `lib/core/analytics/courses_engine.dart`.
- `EnergyAnalyticsEngine` / `energy_logs` — برای انرژیِ فعلی (اتصالِ سبکِ K8).
- `now_dashboard_screen.dart` — برای قلابِ داشبوردِ امروز (K14).
- پکیجِ `shamsi_date` نصب است — برای تاریخِ شمسی. **تاریخ‌ها داخلی ISO `YYYY-MM-DD` ذخیره شوند (برای مرتب‌سازی/مقایسه) و شمسی نمایش داده شوند** (مثل `course_sessions.plannedDate`).
- `AiGateway` موجود — برای K15.

## 🔒 تصمیم‌های قطعی (تغییر نده)
1. **تراز/رتبه نداریم.** کارنامه فقط درصدِ منفی‌دار + نمودارِ روند. هیچ تخمینِ رتبه/ترازِ کشوری زده نشود.
2. **برنامه‌سازِ کامل + اتصال به داشبوردِ امروز.** موتورِ پخش مباحث را تا تاریخِ کنکور روی روزها می‌چیند؛ آیتمِ امروز در داشبورد دیده می‌شود (پشتِ سوییچ).
3. **مستقلِ کامل از «دوره‌ها».** تایمر و موتورِ کنکور جداست؛ از `courses` چیزی import نکن.
4. **هر ۵ رشته + ضرایب** از `konkur_presets.dart` seed شوند.
5. **فرمولِ درصد:** `((۳×صحیح) − غلط) / (۳×کل) × ۱۰۰` — همیشه خودکار، هرگز دستی.

## 🧭 تصمیم‌های معماری (هرگز نقض نشود)
- **منبعِ ساعتِ مطالعه/روند/استریک = فقط `konkur_study_sessions`.** هرگز در `routine_completions` یا `daily_rhythm` نوشته نشود. آمار مستقل است.
- **درصدِ آمادگیِ درس = میانگینِ وزن‌دارِ تسلطِ مباحثش بر اساسِ `examQuestionCount`** (بودجه‌بندی). نه میانگینِ ساده، نه تایپِ دستی.
- **AI هرگز مستقیم به DB نمی‌نویسد** — مسیرِ `AI Suggestion → Preview → User Edit → Save`.
- **برنامه‌ساز مباحثِ MASTERED را برای مطالعه‌ی تازه زمان‌بندی نمی‌کند** — فقط برای مرور (با فاصله) در `nextReviewDate`.

---

# 🗂 صفِ تسک‌ها

> **ترتیب:** PASS 0 → K1 → K2 → K3 → K4 → K5 → K6 → K7 → K8 → K9 → K10 → K11 → K12 → K13 → K14 → K16 → **K15 (AI، آخرین مرحله)**.

## ▣ PASS 0 — ممیزی (بدون تغییرِ کد) 🔍
**اقدام (فقط خواندن و گزارش):**
1. نسخه‌ی فعلیِ دیتابیس در `database_helper.dart` چند است؟ آخرین `if (oldVersion < N)` کدام است؟
2. آیا مهاجرتِ سیستمِ «چرخه» (v14) قبلاً اعمال شده؟ (تأثیر روی عددِ نسخه‌ی این سیستم.)
3. ساختارِ دقیقِ ۴ جدولِ کنکور و ایندکس‌هایشان را تأیید کن.
4. آیا جایی به‌جز `konkur_dashboard_screen.dart` به جداولِ کنکور کوئری می‌زند؟ (snapshot_sync، داشبورد، insights؟) لیست کن.
5. `courses_engine.dart` و `insights_screen.dart` را بخوان: امضای دقیقِ `CachedEngine` و نحوه‌ی ثبت در `RitmoEngineBus` چیست؟
**گزارش بده:** نسخه‌ی فعلی + عددِ نسخه‌ی پیشنهادیِ این سیستم، لیستِ مصرف‌کننده‌های جداولِ کنکور، امضای `CachedEngine`. **توقف کن و منتظر تأیید انسانی بمان.**

## ▣ تسک K1 — مهاجرت دیتابیس 🔴
**فایل:** `lib/core/database/database_helper.dart`
**اقدام:** نسخه را به (فعلی+۱) ببر. تابع `_migrateToVNN(db)` بساز و در `onUpgrade` با `if (oldVersion < NN)` صدا بزن. **همان ستون‌ها/جداول را در `_createDB` هم اضافه کن** تا نصبِ تازه و ارتقا یکسان شوند.

ستون‌های جدید (`ALTER TABLE ... ADD COLUMN`، بدونِ FK چون ALTER در SQLite قید FK نمی‌پذیرد):
```sql
-- konkur_subjects
subjectGroup TEXT NOT NULL DEFAULT 'SPECIALIZED'   -- GENERAL / SPECIALIZED
examQuestionCount INTEGER NOT NULL DEFAULT 0       -- تعداد کلِ تستِ درس در کنکور
orderIndex INTEGER NOT NULL DEFAULT 0
colorHex TEXT
isPreset INTEGER NOT NULL DEFAULT 0

-- konkur_topics
examQuestionCount INTEGER NOT NULL DEFAULT 0       -- بودجه‌بندیِ مبحث
masteryLevel TEXT NOT NULL DEFAULT 'NOT_STARTED'   -- NOT_STARTED/LEARNING/MASTERED/NEEDS_REVIEW
lastStudiedAt INTEGER
nextReviewDate TEXT                                -- ISO؛ مرورِ لایتنری
plannedDate TEXT                                   -- ISO؛ خروجیِ برنامه‌ساز
orderIndex INTEGER NOT NULL DEFAULT 0

-- konkur_mock_exams
provider TEXT
note TEXT

-- konkur_mock_exam_results
totalQuestions INTEGER NOT NULL DEFAULT 0
```
جداولِ جدید (در `_createDB` و در تابعِ مهاجرت با `CREATE TABLE IF NOT EXISTS`):
```sql
CREATE TABLE konkur_study_sessions (
  id TEXT PRIMARY KEY,
  topicId TEXT,
  subjectId TEXT,
  dateIso TEXT NOT NULL,              -- 'YYYY-MM-DD'
  durationMinutes INTEGER NOT NULL DEFAULT 0,
  mode TEXT NOT NULL DEFAULT 'STUDY', -- STUDY/TEST/REVIEW
  testsTotal INTEGER NOT NULL DEFAULT 0,
  testsCorrect INTEGER NOT NULL DEFAULT 0,
  testsWrong INTEGER NOT NULL DEFAULT 0,
  testsBlank INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  createdAt INTEGER NOT NULL
);
CREATE INDEX index_konkur_sessions_dateIso ON konkur_study_sessions(dateIso);
CREATE INDEX index_konkur_sessions_subjectId ON konkur_study_sessions(subjectId);

CREATE TABLE konkur_plan_items (
  id TEXT PRIMARY KEY,
  dateIso TEXT NOT NULL,              -- 'YYYY-MM-DD'
  subjectId TEXT,
  topicId TEXT,
  plannedMinutes INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING/DONE/SKIPPED
  createdAt INTEGER NOT NULL
);
CREATE INDEX index_konkur_plan_dateIso ON konkur_plan_items(dateIso);
```
کلیدهای جدیدِ `app_settings` (با `INSERT OR IGNORE`، در seed و در مهاجرت):
```
konkur_field='UNSET'
konkur_exam_date=''            -- ISO؛ خالی تا کاربر تعیین کند
konkur_setup_done='false'
konkur_daily_target_minutes='180'
konkur_show_in_dashboard='true'
```
(`module_konkur_enabled` را دست نزن.)
**تأیید:** مهاجرت روی دیتابیسِ قدیمی پاس؛ نصبِ تازه و ارتقا یکسان. **توقف کن و منتظر تأیید انسانی بمان.**

## ▣ تسک K2 — مدل‌های داده
**فایل جدید:** `lib/features/konkur/models/konkur_models.dart`
**اقدام:**
- `enum KonkurField { riyazi, tajrobi, ensani, honar, zaban }` + اکستنشنِ `label` فارسی و `code`.
- `enum MasteryLevel { notStarted, learning, mastered, needsReview }` + `label`/`emoji`/`fromString`/`name`. (نخوانده ⚪ / در حال خواندن 🔵 / مسلط 🟢 / نیاز به مرور 🟡)
- `KonkurSubject` — `toMap`/`fromMap`، گترِ `progressPercent` (از مباحث، در موتور پر می‌شود).
- `KonkurTopic` — `toMap`/`fromMap`، گترِ `isDue` (nextReviewDate <= today)، `weight` (examQuestionCount).
- `KonkurStudySession` — `toMap`/`fromMap`، گترِ `netPercent` (فرمولِ منفی‌دار اگر mode=TEST).
- `KonkurMockExam` + `KonkurMockResult` — `toMap`/`fromMap`، تابعِ ایستا `computeNetPercent(correct, wrong, total)` با فرمولِ منفی‌دار (clamp پایین به اجازه‌ی منفی، بالا ۱۰۰).
- `KonkurPlanItem` — `toMap`/`fromMap`، `isToday`.
**تأیید:** analyze/test سبز + تستِ واحدِ `computeNetPercent`.

## ▣ تسک K3 — پریستِ رشته‌ها و ضرایب
**فایل جدید:** `lib/features/konkur/data/konkur_presets.dart`
**اقدام:** یک نقشه‌ی داده‌محورِ قابلِ‌ویرایش: برای هر `KonkurField` لیستِ دروس با `(name, subjectGroup, importanceFactor=ضریب, examQuestionCount)` و برای هر درس لیستِ مباحثِ نمونه با `(name, examQuestionCount)`.
- حداقلِ دروسِ اختصاصیِ هر رشته (نظامِ جدید):
  - **ریاضی:** ریاضیات، فیزیک، شیمی.
  - **تجربی:** زمین‌شناسی، ریاضی، زیست‌شناسی، فیزیک، شیمی.
  - **انسانی:** ریاضی، اقتصاد، ادبیاتِ اختصاصی، عربیِ اختصاصی، تاریخ و جغرافیا، علومِ اجتماعی، فلسفه و منطق، روان‌شناسی.
  - **هنر:** درکِ عمومیِ هنر، ترسیمِ فنی، خلاقیتِ تصویری و تجسمی، خلاقیتِ نمایشی، خواصِ مواد، خلاقیتِ موسیقی.
  - **زبان:** زبانِ تخصصی.
- گروهِ **عمومی** (اختیاری، `subjectGroup='GENERAL'`): ادبیاتِ فارسی، عربی، دینی، زبانِ انگلیسی — به‌صورتِ یک مجموعه‌ی مشترک تعریف کن و در seed به‌صورتِ پیش‌فرض خاموش (یا با پرچمِ اختیاری) قرار بده، چون در نظامِ جدیدِ کنکورِ سراسری دروسِ عمومی حذف شده‌اند. در UIِ راه‌اندازی یک سوییچ «دروسِ عمومی را هم اضافه کن؟» بگذار.
- **مهمِ صداقت:** ضرایب و اعدادِ بودجه‌بندی را به‌صورتِ «seedِ پیش‌فرضِ قابلِ‌ویرایش» علامت بزن (کامنت). مقادیر را معقول بگذار ولی **در UI کاربر بتواند ضریبِ هر درس را ویرایش کند** — این پریست‌ها فقط نقطه‌ی شروع‌اند، نه ادعای رسمی‌بودن.
- تابعِ `seedFieldIntoDb(db, field, {includeGeneral})` که دروس و مباحث را با id یکتا، `isPreset=1` و `orderIndex` درج می‌کند.
**تأیید:** analyze/test سبز + تستِ seed برای یک رشته.

## ▣ تسک K4 — موتورِ برنامه‌ساز (منطقِ خالص)
**فایل جدید:** `lib/features/konkur/logic/konkur_planner.dart`
**اقدام:** کلاسِ خالص (بدون I/O، تست‌پذیر):
- `List<KonkurPlanItem> buildPlan({required List<KonkurSubject> subjects, required List<KonkurTopic> topics, required DateTime examDate, required DateTime from, required int dailyTargetMinutes})`:
  - فقط مباحثِ `masteryLevel != MASTERED`. اولویت = `topic.examQuestionCount × subject.importanceFactor` (نزولی)؛ مباحثِ `NEEDS_REVIEW` و `LEARNING` کمی زودتر.
  - تخصیصِ دقیقه بر اساسِ یک تخمینِ ساده (مثلاً سهمِ هر مبحث متناسب با وزنش از سقفِ روزانه)، پخش روی روزها از `from` تا `examDate`.
  - اگر روزها کم بودند، مباحثِ کم‌اولویت‌تر در انتها فشرده شوند (هشدارِ «بارِ سنگین» را موتور می‌سازد، نه این‌جا).
- `List<KonkurPlanItem> buildReviewSlots({required List<KonkurTopic> mastered, required DateTime from})`: برای مباحثِ `MASTERED` با `nextReviewDate <= horizon`، اسلاتِ مرورِ کوتاه.
- `int daysBehind(...)`: تعدادِ `plan_items` با `dateIso < today` و `status=PENDING`.
**تأیید:** تستِ واحد: پخشِ N مبحث تا تاریخِ کنکور با سقفِ روزانه؛ اولویتِ ضریب‌بالا؛ عقب‌افتادگی. analyze/test سبز.

## ▣ تسک K5 — موتورِ تحلیل (CachedEngine)
**فایل جدید:** `lib/core/analytics/konkur_engine.dart`
**اقدام:** `KonkurEngine implements CachedEngine<KonkurEngineInput, KonkurEngineOutput>` مطابقِ `courses_engine.dart`.
- ورودی: subjects, topics, sessions, mockExams+results, examDateIso, today, planItems.
- خروجی:
  - `daysUntilExam` (روزشمار).
  - `overallReadiness` (۰..۱): میانگینِ وزن‌دارِ آمادگیِ دروس با وزنِ `importanceFactor`. آمادگیِ هر درس = `Σ(masteryScore(topic) × topic.examQuestionCount) / Σ(examQuestionCount)` که `masteryScore`: NOT_STARTED=0، LEARNING=0.5، NEEDS_REVIEW=0.7، MASTERED=1.0.
  - `studyMinutesTotal`، `studyMinutesThisWeek` (از sessions).
  - `studyStreakDays` (روزهای متوالی با حداقل یک session).
  - `perSubjectReadiness: Map<subjectId,double>`.
  - `perSubjectTrend: Map<subjectId,List<double>>` (درصدِ آن درس در آزمون‌های متوالی، مرتب با تاریخ).
  - `budgetCoverage` (۰..۱): سهمِ بودجه‌بندیِ پوشش‌داده‌شده = `Σ(examQuestionCount مباحثِ غیرِ NOT_STARTED) / Σ(کل)`.
  - `weakestSubjects: List<subjectId>` (کم‌ترین آمادگی، وزن‌دار با ضریب).
  - `todayPlanItems: List<KonkurPlanItem>`.
- نکته: `progressPercentage` روی `konkur_topics`/`konkur_subjects` را موتور **به‌صورتِ مشتق** هم می‌تواند به‌روزرسانی کند (اختیاری برای سازگاریِ عقب‌رو)، ولی منبعِ حقیقت `masteryLevel` است.
**تأیید:** تستِ واحدِ خروجی‌ها؛ analyze/test سبز.

## ▣ تسک K6 — هیروی روزشمار + آمادگی
**فایل جدید:** `lib/features/konkur/presentation/widgets/konkur_hero.dart`
**اقدام:** کارتِ شیشه‌ای با گرادیانِ بنفش:
1. **روزشمارِ بزرگ:** «N روز تا کنکور» (آرام، نه قرمز). اگر `examDate` خالی → «تاریخِ کنکور را تعیین کن».
2. رینگ/نوارِ **آمادگیِ کلی** (`overallReadiness`).
3. ⏱ مطالعه‌ی این هفته + 🔥 استریک.
داده از `KonkurEngine` با `RitmoEngineBus`.
**تأیید:** اعدادِ فارسی و تاریخِ شمسیِ درست؛ analyze/test سبز.

## ▣ تسک K7 — جریانِ راه‌اندازیِ اولیه
**فایل جدید:** `lib/features/konkur/presentation/widgets/konkur_setup_flow.dart`
**اقدام:** وقتی `konkur_setup_done=false`، فلوِ چندمرحله‌ای:
1. انتخابِ رشته (۵ کارت).
2. سوییچِ «دروسِ عمومی هم اضافه شود؟».
3. seed با `seedFieldIntoDb` → نوشتنِ `konkur_field`.
4. انتخابِ تاریخِ کنکور (تقویمِ شمسی، ذخیره‌ی ISO در `konkur_exam_date`).
5. (اختیاری) سقفِ دقیقه‌ی روزانه → `konkur_daily_target_minutes`.
6. `konkur_setup_done=true`.
**تأیید:** seed درست؛ بعد از اتمام، صفحه‌ی اصلی باز شود؛ analyze/test سبز.

## ▣ تسک K8 — بخشِ «امروز / برنامه»
**فایل جدید:** `lib/features/konkur/presentation/widgets/konkur_today_section.dart`
**اقدام:**
1. آیتم‌های `konkur_plan_items(dateIso=today, PENDING)` → کارت با نامِ درس/مبحث + `plannedMinutes` + [▶ شروع][✓ انجام].
2. **▶ شروع** → بازکردنِ `konkur_study_sheet` (K10).
3. **✓ انجام** → ثبتِ سریعِ session + `status=DONE`.
4. نمای کلیِ برنامه: «X مبحثِ امروز / Y عقب‌افتاده». دکمه‌ی **«بازچینش برنامه»** → `konkur_planner.buildPlan` روی مباحثِ باقی‌مانده + پاک‌کردن plan_itemهای PENDINGِ آینده و درجِ تازه.
5. اتصالِ سبکِ انرژی: اگر انرژیِ فعلی پایین → پیامِ ملایم «انرژی‌ت پایینه، یه مبحثِ سبک‌تر چطوره؟» (بدونِ اجبار).
6. حالتِ خالی: «امروز برنامه‌ای نیست — یه مبحث انتخاب کن 🌿».
**تأیید:** نمایش، تیک، بازچینش؛ analyze/test سبز.

## ▣ تسک K9 — بخشِ بودجه‌بندی (دروس و مباحث)
**فایل جدید:** `lib/features/konkur/presentation/widgets/konkur_budget_section.dart`
**اقدام:**
1. درختواره: هر درس (`ExpansionTile`) با ضریب + % آمادگی + نوارِ پیشرفت.
2. زیرِ هر درس، مباحث با: نامِ مبحث + **عددِ بودجه‌بندی** («≈ N تست در کنکور») + چیپِ `MasteryLevel` (۴-حالته، با تپ تغییر می‌کند) + [مطالعه/تست] (→ K10).
3. نوارِ **پوششِ بودجه** بالای بخش (`budgetCoverage`).
4. [＋ افزودنِ درس] و [＋ افزودنِ مبحث] و ویرایش (نام، ضریب، بودجه). حذف.
5. تغییرِ `masteryLevel` → به‌روزرسانیِ مشتقِ `progressPercentage` (از طریقِ موتور یا helper).
**تأیید:** درخت، تغییرِ تسلط، بودجه، ویرایشِ ضریب؛ analyze/test سبز.

## ▣ تسک K10 — شیتِ ثبتِ مطالعه/تست (تایمر)
**فایل جدید:** `lib/features/konkur/presentation/widgets/konkur_study_sheet.dart`
**اقدام:** شیتِ مستقل (هیچ import از `courses`):
1. حالت: **مطالعه** یا **تست‌زنی** (سگمنت → `mode`).
2. **تایمرِ رو به جلو** (`Timer.periodic`)، توقف/ادامه/پایان. بدونِ Pomodoroِ اجباری.
3. اگر حالت = تست: ورودیِ صحیح/غلط/نزده + کلِ سؤال → نمایشِ زنده‌ی **درصدِ منفی‌دار**.
4. پایان → درجِ `konkur_study_sessions` (دقیقه + داده‌ی تست) + به‌روزرسانیِ `lastStudiedAt` مبحث + اگر plan_item امروز برای این مبحث بود → `DONE`.
5. پیشنهادِ ملایمِ ارتقای `masteryLevel` («این مبحث رو مسلط شدی؟») — اختیاری، با تأیید.
**تأیید:** تایمر، ثبت، درصدِ منفی‌دار؛ analyze/test سبز.

## ▣ تسک K11 — تبِ کارنامه + نمودارِ روند
**فایل جدید:** `lib/features/konkur/presentation/widgets/konkur_exams_section.dart`
**اقدام:**
1. لیستِ آزمون‌ها (`konkur_mock_exams` نزولی با تاریخِ شمسی + provider).
2. **ثبتِ کارنامه (شیت):** عنوان + provider + تاریخِ شمسی + برای هر درس: صحیح/غلط/نزده + کلِ سؤال → **درصد خودکار با `computeNetPercent`** (هرگز دستی). ذخیره در `konkur_mock_exam_results` (درصد + اجزا + totalQuestions).
3. **نمودارِ روند:** برای هر درس، درصد در آزمون‌های متوالی (`perSubjectTrend`) به‌صورتِ خطی/میله‌ای ساده (بدونِ پکیجِ جدید؛ با `CustomPainter` یا میله‌های ساده). محورِ افقی = تاریخِ آزمون.
4. کارتِ هر آزمون: میانگینِ درصد + چیپِ هر درس.
**تأیید:** ثبت با فرمولِ منفی‌دار، نمودارِ روند؛ analyze/test سبز.

## ▣ تسک K12 — تبِ آمار
**فایل جدید:** `lib/features/konkur/presentation/widgets/konkur_stats_section.dart`
**اقدام:** کارت‌های KPI از موتور: مطالعه‌ی کل (ساعت)، استریک، پوششِ بودجه، آمادگیِ کلی؛ + لیستِ **درس‌های ضعیف** (`weakestSubjects`) با پیشنهادِ تشویقیِ تمرکز. بدونِ سرزنش.
**تأیید:** اعدادِ درست؛ analyze/test سبز.

## ▣ تسک K13 — مونتاژِ صفحه‌ی اصلی + اتصال به هاب
**فایل‌ها:** `lib/features/konkur/presentation/konkur_screen.dart` (جدید) + `systems_hub_screen.dart` (ویرایشِ مقصدِ Navigation) + حذفِ `konkur_dashboard_screen.dart`.
**اقدام:**
1. `KonkurScreen`: Scaffold + Directionality(rtl) + هدر «کنکور» + [🤖] + [⚙ تنظیمات]. اگر `konkur_setup_done=false` → `konkur_setup_flow`. وگرنه:
   ```
   konkur_hero            (روزشمار + آمادگی)
   [تب‌ها/سکشن‌ها:] امروز/برنامه · بودجه‌بندی · کارنامه · آمار
   ```
   `RefreshIndicator` + بازخوانی از موتور.
2. تنظیماتِ صفحه: سوییچِ `konkur_show_in_dashboard`، ویرایشِ تاریخِ کنکور و سقفِ روزانه، تغییرِ رشته (با هشدار).
3. در `systems_hub_screen.dart`: در `_handleKonkurTap` مقصد را از `KonkurDashboardScreen` به `KonkurScreen` تغییر بده و importها را به‌روز کن.
4. فایلِ `konkur_dashboard_screen.dart` را حذف کن (بعد از اطمینان از نبودِ ارجاعِ دیگر).
**تأیید:** ورود از هاب، setup، صفحه‌ی کامل؛ analyze/test سبز.

## ▣ تسک K14 — قلابِ داشبوردِ امروز 🔴
**فایل:** `lib/features/today/presentation/now_dashboard_screen.dart`
**اقدام:** بخشِ «📚 مطالعه‌ی امروز (کنکور)» که `konkur_plan_items(today, PENDING)` را با [✓ انجام] نشان دهد. **فقط اگر** `module_konkur_enabled=true` **و** `konkur_show_in_dashboard=true` **و** آیتمی برای امروز باشد؛ وگرنه کاملاً پنهان. (این تسک به فایلِ مشترکِ داشبورد دست می‌زند → حساس.)
**تأیید:** نمایشِ شرطی درست، بدونِ شکستنِ داشبورد؛ analyze/test سبز. **توقف کن و منتظر تأیید انسانی بمان.**

## ▣ تسک K16 — پرداختِ بصری + تستِ نهایی + سند
**فایل‌ها:** کلِ `lib/features/konkur/`.
**اقدام:** RTL، ارقامِ فارسی، تاریخِ شمسی همه‌جا، فاصله‌گذاریِ مضربِ ۸، حداقلِ لمسیِ ۴۸dp، گرادیانِ بنفش. `flutter analyze` بدونِ error/warningِ جدید. `flutter test` همه سبز + تست‌های جدید: planner، `computeNetPercent`، readiness، streak، trend. `DESIGN_SYSTEM_KONKUR.md` را اگر چیزی تغییر کرد به‌روز کن.
**تأیید:** همه سبز.

## ▣ تسک K15 — دستیار AI (آخرین مرحله)
**فایل جدید:** `lib/features/konkur/presentation/widgets/ai_konkur_assistant_sheet.dart`
**پیش‌نیاز:** K1–K14 و K16 کامل و آزموده.
**اقدام:** دکمه‌ی 🤖. عملکردهای مجاز:
1. «برنامه‌ی مطالعه برام بچین» — ورودی: تاریخِ کنکور + سقفِ روزانه → پیشنهادِ توزیع (فیلدهای برنامه‌ساز را پیش‌پر کند، خودکار اجرا نکند).
2. «الان کدوم مبحث رو بخونم؟» — با بودجه‌بندی + عقب‌افتادگی + انرژی یک مبحث پیشنهاد.
3. «کارنامه‌ام رو تحلیل کن» — نقاطِ ضعف از `perSubjectTrend` (تشویقی، بدونِ تخمینِ رتبه).
4. «این درس رو به مبحث تقسیم کن» — لیستِ قابلِ‌ویرایشِ مباحثِ پیشنهادی.

**قانونِ مطلق — AI هرگز مستقیم به DB نمی‌نویسد:**
```
AI Suggestion → Preview → User Edit → Save (با تأییدِ صریح)
```
- خروجیِ «تقسیم به مبحث» لیستِ قابلِ‌ویرایش باشد، نه درجِ مستقیم.
- پیشنهادِ برنامه فیلدها را پیش‌پر کند، نه اینکه `buildPlan` را خودکار اجرا و ذخیره کند.
- **ممنوعات:** تدریسِ محتوا، خلاصه‌ی درسی، تخمینِ رتبه/تراز، قضاوتِ سرعتِ یادگیری.
از `AiGateway` موجود استفاده کن.
**تأیید:** چهار عملکرد + الزامِ Preview→Edit→Save؛ analyze/test سبز.

---

## 📤 قالبِ گزارش (بعد از هر تسک)
```
## تسک [K?]: [عنوان]
- فایل‌ها: ...
- خلاصه: ...
- flutter analyze: [قبل → بعد]
- flutter test: [N passed, M failed]
- وضعیت: ✅ / ⚠️ / ❌
```
**یادآوری: بعد از K1 و بعد از K14 توقف کن و منتظر تأیید انسانی بمان.**
