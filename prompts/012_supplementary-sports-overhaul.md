# پرامپت ۰۱۲ — بازسازی کامل و هوشمندسازی ماژول «ورزش تکمیلی» (Supplementary Sports Overhaul)

> **مخاطب:** ایجنت هوش مصنوعی کدنویس (Gemini).
> **نقش تو:** برنامه‌نویس ارشد Flutter. این سند یک اسپک کامل و خودبسنده است؛ بدون نیاز به سؤال، مرحله‌به‌مرحله پیاده‌سازی کن.
> **زبان UI:** فارسی، RTL. **زبان کد:** انگلیسی. **استک:** Flutter + `sqflite` + `get_it` + `flutter_riverpod ^3.0`.
> **پروژه:** `C:\Users\bahman\Desktop\Besme-Allah\Ritmo3\ritmo`

---

## ۰. چرا این پرامپت؟ (خلاصه‌ی مسئله)

ماژول فعلی `lib/features/supplementary_sports/` (~۱۲هزار خط) از نظر معماری تمیز است اما **۵ نقص جدی** دارد و مهم‌تر از آن، **داده‌ی غنی موجود در asset را دور می‌ریزد**. این پرامپت بر پایه‌ی مهندسی معکوس دو برنامه‌ی مرجع (`Fitify Pro` و `Home Workout`) نوشته شده که مستندشان در این دو فایل است — **قبل از شروع، هر دو را بخوان**:

- `C:\Users\bahman\Desktop\Besme-Allah\Ritmo3\varzesh\docs\master_prd.md` (PRD کامل UX/UI — منبع نهایی وایرفریم‌ها و State‌ها)
- `C:\Users\bahman\Desktop\Besme-Allah\Ritmo3\varzesh\docs\architectural_blueprints.md` (الگوهای معماری استخراج‌شده از `classes.dex` و `schema_42`)

### قوانین طلایی (از blueprints — نقض نکن)

1. **هیچ پردازش سنگینی در `WorkoutSessionScreen` انجام نشود.** کل منطق برنامه قبل از شروع جلسه در background محاسبه و به‌صورت داده‌ی آماده به UI تزریق می‌شود.
2. **موتور جایگزینی (Swap) از پیش محاسبه‌شده است** (جدول گراف `ss_exercise_similarity`)، نه محاسبه‌ی run-time.
3. **تایمر استراحت بر پایه‌ی Target Timestamp** است نه شمارنده‌ی معمولی (برای دور زدن Doze Mode).
4. **تعارض قوانین = Weighted Rules:** قوانین پزشکی (Hard) همیشه بر حجم تمرین (Soft) ارجحیت دارند.
5. **AI هرگز نباید موفقیت دروغین گزارش کند.** هر اعمال تغییر باید `rowsAffected` را چک کند.

---

## ۱. نقشه‌ی راه (۸ مرحله، به‌ترتیب اجرا شوند)

| # | مرحله | خروجی اصلی |
|---|---|---|
| A | غنی‌سازی مدل داده + Migration V38 + بازنویسی Seed | ستون‌های جدید `ss_exercise`، فیلدهای غنی persist می‌شوند |
| B | بازنویسی موتور تولید برنامه (`SSPlanGenerator`) | `goal` و `focusAreas` و ایمنی واقعی وارد منطق می‌شوند |
| C | حلقه‌ی بازخورد Progressive Overload واقعی | تولید هفته‌ی بعد از feeling logها تغذیه می‌شود |
| D | موتور جایگزینی حرکت (Swap Engine) | دکمه‌ی «جایگزین کن» به گراف similarity وصل می‌شود |
| E | تایمر خودکار هماهنگ با سرعت + تایمر استراحت Doze-safe | auto-timer از `duration/reps`، rest از timestamp |
| F | جایگزینی مربی فِیک با **کپی عینِ دستیار هوشمند عبادت** + تطبیق پرامپت/context با ورزش | دستیار واقعیِ متصل به `AIGateway`، پایان «موفقیت دروغین» |
| G | بازآرایی `WorkoutSessionScreen` به الگوی MVI + Riverpod | Single Source of Truth، رفع Race Condition |
| H | قابلیت‌های جدید (Neighbor-Friendly، Skip-Reason، Resume) + پاک‌سازی | تکمیل امکانات PRD |

---

## مرحله A — غنی‌سازی مدل داده و Seed

### A.1 مشکل فعلی
Seed در `lib/core/database/seed/seed_service.dart` (متد `seedSupplementarySports`) فقط زیرمجموعه‌ی کوچکی از فیلدهای هر حرکت را ذخیره می‌کند. این فیلدهای **موجود در asset** دور ریخته می‌شوند و باعث می‌شوند منطق مجبور به string-matching شکننده شود:

| فیلد در asset | پوشش | کاربرد حیاتی |
|---|---|---|
| `duration` (int, ثانیه) | ۲۶۸/۸۰۱ | تایمر خودکار |
| `reps` (int) | ۱۷۸/۸۰۱ | تایمر خودکار + نمایش |
| `reps_hint` (str) | زیاد | نحوه‌ی شمارش (`reps_count_change_sides`, `reps_count_half`, ...) |
| `impact` (int 0–3) | **۸۰۱/۸۰۱** | فیلتر ایمنی زانو/پرش |
| `noisy` (int 0–3) | **۸۰۱/۸۰۱** | قابلیت Neighbor-Friendly |
| `tools_required` (list) | ۸۰۱/۸۰۱ | فیلتر تجهیزات **صحیح** (جایگزین string-match) |
| `constraint_negative` (str) | ۱۰۰/۸۰۱ | محدودیت‌های اضافی |
| `weight_supported` (bool) | ۲۶۸/۸۰۱ | آیا افزودن وزنه معنا دارد |
| `weight_per_hand` (bool) | ۲۶۸/۸۰۱ | محاسبه‌ی وزن |
| `muscle_intensity` (dict) | ۲۰۵/۸۰۱ | هدف‌گیری دقیق focusAreas |
| `skill_required` (int) | زیاد | تطبیق با experienceLevel |
| `isolated_vs_compound` (int) | زیاد | انتخاب هوشمند بر اساس goal |
| `strength_vs_cardio` (int) | زیاد | انتخاب بر اساس goal |
| `change_sides` (bool) | ۸۰۱/۸۰۱ | تایمر نامتقارن |
| `reps_double` (bool) | ۲۶۸/۸۰۱ | جلوگیری از شمارش مضاعف |

> **نکته‌ی مهم:** فیلدهای `rep_duration_low/medium/high` و `harder`/`easier` در asset **صفر/غایب‌اند**. برای تایمر خودکار از `duration/reps` استفاده کن (نه rep_duration). برای swap از جدول `ss_exercise_similarity` استفاده کن (نه harder/easier).

### A.2 تغییر Schema
فایل `lib/core/database/schema/tables/supplementary_sports_tables.dart` — به `CREATE TABLE ss_exercise` این ستون‌ها را اضافه کن (با پیش‌فرض امن):

```sql
durationSeconds INTEGER DEFAULT 0,
defaultReps INTEGER DEFAULT 0,
repsHint TEXT,
toolsRequired TEXT DEFAULT '[]',        -- JSON array
constraintNegative TEXT,
weightSupported INTEGER DEFAULT 0,
weightPerHand INTEGER DEFAULT 0,
muscleIntensity TEXT DEFAULT '{}',      -- JSON map
skillRequired INTEGER DEFAULT 0,
strengthVsCardio REAL DEFAULT 0,        -- 0=قدرتی .. 100=هوازی (نرمالایز کن)
machineVsFreeweight REAL DEFAULT 0,
looksCool INTEGER DEFAULT 0,
stance TEXT
```

> فیلدهای `changeSides`, `noisy`, `impact`, `repsDouble`, `sexynessMale/Female`, `isolatedVsCompound` از قبل در schema هستند — فقط مطمئن شو seed مقادیرشان را درست پر می‌کند (الان `impact`/`noisy` را از asset می‌خواند ولی مقادیر دیگر ناقص‌اند).

### A.3 Migration V38
- در `lib/core/database/database_helper.dart`: `version: 37` → `version: 38` (هر دو نقطه).
- در `lib/core/database/migration/migrations_registry.dart`: کلاس `MigrationV38 extends Migration` بساز (دقیقاً الگوی کلاس‌های موجود مثل `MigrationV16` را دنبال کن)، با `int get version => 38;` و در متد `migrate`:
  1. برای هر ستون جدید بالا `ALTER TABLE ss_exercise ADD COLUMN ...` بزن (داخل try/catch تا اگر ستون موجود بود crash نکند).
  2. یک flag موقت در `app_settings` ست کن به نام `ss_reseed_v38 = 'true'` تا seed مجبور به re-seed کامل شود.
- کلاس جدید را در لیست/رجیستری migrationها ثبت کن (همان جایی که بقیه ثبت می‌شوند).

### A.4 بازنویسی Seed
در `seed_service.dart` متد `seedSupplementarySports`:
- شرط re-seed را گسترش بده: اگر `app_settings['ss_reseed_v38'] == 'true'` بود، `DELETE FROM ss_exercise WHERE isCustom = 0` بزن و بعد از seed موفق، flag را `'false'` کن. (شرط `count >= 800` فعلی مانع اعمال ستون‌های جدید می‌شود — این را با flag دور بزن.)
- در حلقه‌ی insert، **همه‌ی** فیلدهای جدول A.2 را از item بخوان. نکات:
  - `durationSeconds`: `item['duration']` (اگر null → ۰).
  - `defaultReps`: `item['reps']` (اگر null → ۰).
  - `toolsRequired`: `jsonEncode(item['tools_required'] ?? [])`.
  - `muscleIntensity`: `jsonEncode(item['muscle_intensity'] ?? {})`.
  - `weightSupported`/`weightPerHand`: bool → 0/1.
  - `strengthVsCardio`, `machineVsFreeweight`, `isolatedVsCompound`, `skillRequired`, `looksCool`: عدد خام asset. اگر بازه‌شان نامعلوم بود، خام ذخیره کن و در منطق نرمالایز کن.
- `ss_exercise_similarity` از قبل seed می‌شود؛ دست نزن ولی مطمئن شو اجرا می‌شود.

### A.5 مدل Dart
`lib/features/supplementary_sports/data/models/ss_exercise_model.dart` را با فیلدهای جدید گسترش بده (`fromMap`/`toMap`) تا منطق مراحل بعد بتواند typed بخواند. برای `toolsRequired` و `muscleIntensity` در `fromMap` با `jsonDecode` امن (try/catch → پیش‌فرض خالی) parse کن.

**پذیرش A:** بعد از اجرا، `SELECT durationSeconds, toolsRequired, impact FROM ss_exercise LIMIT 5` مقادیر واقعی برگرداند (نه همه صفر/خالی).

---

## مرحله B — بازنویسی موتور تولید برنامه (`SSPlanGenerator`)

فایل: `lib/features/supplementary_sports/data/repositories/ss_plan_generator.dart`

### B.1 مشکلات فعلی که باید حل شوند
1. **`profile.goal` تقریباً هیچ اثری ندارد** — فقط sets/reps ثابت. باید کل معماری برنامه را شکل دهد.
2. **`profile.focusAreas` کاملاً نادیده گرفته می‌شود.**
3. **فیلتر تجهیزات با string-matching روی نام** شکننده است → با `toolsRequired` جایگزین شود.
4. **فیلتر ایمنی با کلمات معدود** خطرناک است → با `impact` و `constraint_negative` تقویت شود.
5. **`baseWeight` برای دیتاست bodyweight بی‌معناست** → فقط وقتی `weightSupported == 1` اعمال شود.

### B.2 فیلتر تجهیزات صحیح (`_isExerciseAllowed`)
منطق قدیمی string-matching را حذف کن. به‌جایش:
```
toolsRequired = jsonDecode(ex['toolsRequired'])   // list of tool codes
if bodyweightOnly انتخاب شده: فقط حرکاتی که toolsRequired خالی است مجازند.
در غیر این صورت: هر tool در toolsRequired باید در نگاشت availableEquipment موجود باشد.
```
یک نگاشت `tool code → Equipment enum` بساز (مقادیر ممکن `tools_required` را از asset استخراج کن؛ چون دیتاست bodyweight است اکثراً خالی‌اند، اما ساختار باید درست باشد). اگر tool ناشناخته بود، محافظه‌کارانه رفتار کن (اجازه بده، مگر bodyweightOnly).

### B.3 فیلتر ایمنی مبتنی بر داده (`_satisfiesLimitations`) — Weighted Rules
اینها **Hard Rules** هستند و همیشه اعمال می‌شوند:
- `Limitation.noJumping` یا `kneeProblems`: هر حرکتی که `impact >= 2` باشد رد شود (به‌جای فقط keyword «پرش»). keyword فعلی را به‌عنوان لایه‌ی دوم نگه‌دار.
- `constraint_negative`: اگر مقدار داشت و با محدودیت کاربر تطابق داشت، رد شود (نگاشت ساده تعریف کن؛ اگر معنی کدها نامعلوم بود، صرفاً به‌عنوان سیگنال ریسک در نظر بگیر و با keyword ترکیب کن).
- بقیه‌ی limitationها (کمر/شانه/مچ/بارفیکس) منطق keyword فعلی را نگه‌دار اما تمیزتر.
- **قانون تعارض:** اگر بعد از اعمال Hard Rules لیست خالی شد، **هرگز Hard Rule را نقض نکن**؛ به‌جایش تعداد حرکت در جلسه را کم کن یا از دسته‌ی امن‌تر (stretching/warmup) پر کن.

### B.4 هدف‌گیری بر اساس `goal` (هسته‌ی جدید)
یک struct پیکربندی بر اساس goal تعریف کن که این‌ها را تعیین می‌کند:

| goal | sets | reps | rest (ثانیه) | اولویت انتخاب | دسته‌های تقویتی |
|---|---|---|---|---|---|
| `strength` | 5 | 5 | 120 | `isolatedVsCompound` پایین (چندمفصلی) + `skillRequired` هم‌تراز سطح | upper/lower/back |
| `muscleGain` | 4 | 10 | 75 | ترکیب compound سپس isolation، `sexyness` بالا | همه‌ی گروه‌های عضلانی |
| `fatLoss` | 3 | 15 | 45 | `strengthVsCardio` بالا | cardio, plyometric, core |
| `bodyRecomposition` | 3 | 12 | 60 | متعادل | متعادل |

سطح تجربه (`experienceLevel`) این‌ها را تعدیل کند: beginner → یک ست کمتر و فقط `skillRequired` پایین؛ advanced → یک ست بیشتر و اجازه‌ی `skillRequired` بالا.

### B.5 هدف‌گیری بر اساس `focusAreas`
هنگام انتخاب حرکات primary، حرکاتی که `muscle_intensity` آن‌ها روی گروه‌های عضلانی منتخب کاربر بالاست را وزن بیشتری بده. اگر `focusAreas` خالی بود، همان split متعادل فعلی. نگاشت `BodyArea enum → category/muscle keys` تعریف کن.

### B.6 معیار انتخاب (جایگزینی «sexyness» تنها)
مرتب‌سازی فعلی صرفاً بر اساس `sexynessMale/Female` است. آن را به یک **امتیاز ترکیبی وزن‌دار** تبدیل کن:
```
score = w1*goalFit + w2*focusAreaFit + w3*sexyness + w4*skillMatch
```
که `goalFit` از `isolatedVsCompound`/`strengthVsCardio` مطابق جدول B.4 می‌آید. `sexyness` بماند ولی فقط یک مؤلفه باشد نه معیار اصلی. برای تنوع، از میان top-N با `shuffle(random)` انتخاب کن (مثل الان).

### B.7 وزن (`baseWeight`)
فقط وقتی حرکت `weightSupported == 1` **و** کاربر تجهیزات وزنه دارد، `targetWeight` مقداردهی شود؛ در غیر این صورت `null`. اگر `weightPerHand == 1`، در توضیح نمایش «(هر دست)» لحاظ شود (در UI، نه اینجا).

**پذیرش B:** دو پروفایل با goal متفاوت (strength vs fatLoss) و focusAreas متفاوت، برنامه‌های **محسوساً متفاوت** (sets/reps/دسته‌ها) تولید کنند. کاربر با `kneeProblems` هیچ حرکت `impact>=2` نگیرد.

---

## مرحله C — حلقه‌ی بازخورد Progressive Overload واقعی

### C.1 مشکل فعلی
منطق هفته ۱–۴ کاملاً **استاتیک** است (هرکس در هفته ۳ دقیقاً +۱۵٪). متد `getExercisesReadyForProgression()` در `ss_session_repository_impl.dart` وجود دارد و feeling logها را تحلیل می‌کند اما **به ژنراتور وصل نیست**. `consecutiveEasyWeeks: 3` هم mock هاردکد است.

### C.2 راه‌حل
1. متد `getExercisesReadyForProgression()` را اصلاح کن تا `consecutiveEasyWeeks` **واقعی** را بشمارد (تعداد هفته‌های متوالی که آن حرکت اکثراً «EASY» خورده)، نه mock ثابت ۳.
2. امضای `generateWeeklyAndMonthlyPlan` را گسترش بده تا یک `Map<String, ProgressionSignal>` اختیاری (کلید = exerciseId) بپذیرد.
3. هنگام تولید crossref برای هر حرکت:
   - اگر سیگنال «آماده‌ی افزایش» بود → اگر `weightSupported`: +۵–۱۰٪ وزن؛ در غیر این صورت +۲ تکرار یا +۱ ست (Double Progression طبق PRD constraint ۲).
   - اگر اکثراً «HARD» بود → یک ست/تکرار کم یا وزن −۱۰٪.
   - اگر داده نبود → همان baseline goal.
4. منطق استاتیک هفته ۱–۴ را به‌عنوان **کف پایه** نگه‌دار، اما سیگنال بازخورد رویش سوار شود (Weighted: بازخورد کاربر > قاعده‌ی زمانی).

**پذیرش C:** حرکتی که ۳ هفته «EASY» خورده، در تولید بعدی sets/reps/weight بالاتری بگیرد و در `ProgressScreen` در لیست «آماده‌ی سنگین‌تر شدن» با عدد هفته‌ی **واقعی** ظاهر شود.

---

## مرحله D — موتور جایگزینی حرکت (Swap Engine)

### D.1 وضعیت
جدول `ss_exercise_similarity` از قبل seed شده اما **هیچ‌جا استفاده نمی‌شود**. blueprint می‌گوید این گراف از پیش محاسبه‌شده هسته‌ی روانی UX است.

### D.2 پیاده‌سازی
- در repository یک متد بساز:
  ```dart
  Future<List<SsExercise>> getSwapCandidates(String exerciseId, SsUserProfile profile, {int limit = 5})
  ```
  که: از `ss_exercise_similarity` بالاترین `similarityScore`ها را می‌گیرد (با ایندکس موجود `idx_ss_similarity_main`)، سپس کاندیداها را با همان فیلترهای مرحله B (`_isExerciseAllowed` + `_satisfiesLimitations`) غربال می‌کند و top-`limit` را برمی‌گرداند.
- **همه‌ی این محاسبه قبل از نمایش، در background** (قانون طلایی ۱). نتیجه به‌صورت لیست آماده به BottomSheet تزریق شود.
- دکمه‌ی «جایگزین کن» در `WorkoutSessionScreen` و «جایگزین» در `PlanDayDetailScreen` را به این متد وصل کن. انتخاب کاربر crossref را با حرکت جدید به‌روزرسانی کند (همان orderIndex, sets, reps).
- اگر similarity برای آن حرکت خالی بود → fallback: حرکات هم‌دسته (`category`) با بالاترین score ترکیبی.
- هر swap یک رکورد در `ss_decision_log` با `decisionType='EXERCISE_SWAPPED'` ثبت کند.

**پذیرش D:** لمس «جایگزین کن» روی «شنا»، فوراً (بدون لگ) لیست جایگزین‌های سازگار با محدودیت‌های کاربر نشان دهد.

---

## مرحله E — تایمرها (auto-timer + rest timer Doze-safe)

فایل: `lib/features/supplementary_sports/presentation/ss_workout_session_screen.dart`

### E.1 تایمر خودکارِ هماهنگ با سرعت انسان
blueprint: تایمر نباید عدد ثابت باشد. برای هر حرکت:
- اگر `durationSeconds > 0`: همان را به‌عنوان مدت حرکت استفاده کن.
- اگر `defaultReps > 0` و duration نبود: `perRep ≈ durationSeconds/defaultReps`؛ اگر duration هم نبود از پیش‌فرض معقول (~۳ ثانیه/تکرار) استفاده کن. مدت = `perRep * targetReps`.
- `change_sides == 1`: مدت را برای دو سمت (چپ/راست) دو برابر کن و در UI نشانگر «تعویض سمت» وسط حرکت بگذار.
- `reps_double == 1`: در شمارش تکرار، چپ+راست = ۱ تکرار (جلوگیری از شمارش مضاعف).

### E.2 تایمر استراحت Doze-safe (Target Timestamp)
مشکل فعلی: `Timer.periodic` هنگام خاموش شدن صفحه drift می‌کند / متوقف می‌شود.
- هنگام شروع استراحت، `restTargetTimestamp = DateTime.now().millisecondsSinceEpoch + restMillis` را ذخیره کن.
- نمایش هر ثانیه از **اختلاف `restTarget - now`** محاسبه شود، نه از شمارش دستی.
- `WidgetsBindingObserver` اضافه کن؛ در `didChangeAppLifecycleState` هنگام `resumed`، فوراً باقی‌مانده را از timestamp بازمحاسبه کن (پرش به ثانیه‌ی صحیح).
- مدت استراحت از جدول B.4 (بر اساس goal) بیاید، نه ثابت.
- **نکته‌ی Foreground/Notification:** زمان‌بندی صدای پایان استراحت حین خاموش‌بودن صفحه، از زیرساخت نوتیفیکیشن موجود پروژه استفاده کند (اگر `AlarmManager`/local notification هست از همان). اگر خارج از scope این پرامپت بود، حداقل timestamp-based بودن UI را پیاده کن و یک `// TODO(notif): schedule exact alarm` بگذار.

**پذیرش E:** استراحت ۶۰ ثانیه‌ای را شروع کن، صفحه را خاموش کن، ۳۰ ثانیه صبر کن، روشن کن → تایمر روی ~۳۰ باشد نه ۶۰ یا گیرکرده.

---

## مرحله F — جایگزینی مربی فِیک با کپی عینِ دستیار هوشمند عبادت

> **اصل حاکم بر این مرحله (تغییر رویکرد نسبت به نسخه‌ی قبلی پرامپت):**
> **سیستم AI جدیدی نساز.** پروژه از قبل یک دستیار هوشمند واقعی، کامل و متصل به سرور دارد که در بخش عبادت استفاده می‌شود. کارِ این مرحله فقط این است: آن دستیار را **عیناً کپی** کن و **فقط منطق و پرامپت‌هایش را با ورزش متناسب‌سازی** کن. هیچ چیز جدیدی از صفر طراحی نکن.

### F.0 وضعیت فعلی و چرا باید دور ریخته شود
فایل فعلی `lib/features/supplementary_sports/presentation/ss_ai_coach_chat_screen.dart` یک **مربیِ کاملاً فِیک** است:
- به هیچ مدل واقعی وصل نیست؛ کل پاسخ‌ها `Future.delayed` + `if (userText.contains('سبک'))` هاردکد است.
- پیشنهادها روی IDهای جعلی `ex_shoulder_press` و `plan_default_1` ساخته می‌شوند که در DB واقعی (IDهایی مثل `bo001_...`) **وجود ندارند**؛ `_acceptSuggestion` یک `UPDATE ... WHERE exerciseId='ex_shoulder_press'` می‌زند که **۰ ردیف** تغییر می‌دهد ولی «✅ با موفقیت اعمال شد» نشان می‌دهد (باگ «موفقیت دروغین»).
- `_isOffline` هم یک mock دستی است.

**این فایل را کامل بازنویسی کن** تا دقیقاً کلونِ دستیار عبادت باشد.

### F.1 مرجعِ کپی (این‌ها را بخوان و عیناً تقلید کن)
منبع طلایی که باید کپی شود:
- `lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart` — کل معماری شیت: استریم، حباب پیام، اکشن‌ها، تاریخچه‌ی session، swipe-to-delete با undo، typing indicator، top-toast.

زیرساخت مشترکی که **همان‌طور که هست** استفاده کن (دست نزن، فقط مصرف کن):
- `lib/core/ai/ai_gateway.dart` → `AIGateway.instance.sendCustomChatStream(messages: ...)` (همان متد استریمِ عبادت).
- `lib/core/ai/chat/chat_repository.dart` + `chat_models.dart` → `ChatRepository.instance` با `chatType: 'sports'` (زیرساخت از هر chatType دلخواه پشتیبانی می‌کند؛ کافی است رشته را عوض کنی).
- `lib/core/ai/chat/chat_action_parser.dart` → `ChatActionParser.parse()` برای استخراج تگ `<actions>`.
- `lib/features/assistant/logic/assistant_action_registry.dart` → `AssistantActionRegistry.executeAction(...)`.

### F.2 آنچه باید هنگام کپی «متناسب‌سازی» شود (فقط منطق و پرامپت)
یک فایل جدید `ss_ai_coach_sheet.dart` بساز که **ساختارش خط‌به‌خط از `ai_worship_assistant_sheet.dart` گرفته شده** و فقط این نقاط ورزشی شده باشند:

1. **`chatType`**: هر جا `'worship'` است → `'sports'`.
2. **`_loadWorshipContext()` → `_loadSportsContext()`**: به‌جای خواندن `worship_debts`/`worship_practices`، از DB بخوان:
   - `ss_user_profile` (goal، focusAreas، محدودیت‌ها، تجهیزات، سطح، مدت جلسه).
   - برنامه‌ی فعلی از `ss_workout_plan` + `ss_workout_exercise_crossref` → **لیست حرکات با `exerciseId` واقعی + نام + ست/تکرار/وزنِ هدف**.
   - خلاصه‌ی feeling logهای اخیر (از منطق مرحله C) برای هر حرکت.
   - این‌ها را در یک `StringBuffer` فارسی مثل نمونه‌ی عبادت بریز.
3. **`systemPrompt`**: متن سیستمی مذهبی را با متن ورزشی جایگزین کن (لحن مربی مشوق، فارسی، وزیری). قوانین سخت:
   - **ایمنی پزشکی**: درد/آسیب/مصدومیت → صرفاً هشدار توقف و ارجاع به پزشک؛ **بدون** تجویز درمانی و بدون action.
   - AI حق تجویز رژیم دارویی/مکمل تخصصی ندارد؛ فقط توصیه‌ی عمومی تغذیه‌ی ورزشی.
   - پیشنهاد تغییر برنامه فقط با تگ `<actions>` و **فقط روی `exerciseId`‌هایی که در «پرونده‌ی ورزشی کاربر» زیر پرامپت آمده‌اند** (نه ID خودساخته). این پرونده را دقیقاً مثل «پرونده‌ی مذهبی» به انتهای systemPrompt بچسبان.
   - اکشن‌های مجاز و فرمتشان (این‌ها **از قبل** در `AssistantActionRegistry` و enum `AssistantActionType` پیاده‌اند — فقط در پرامپت به مدل معرفی‌شان کن):
     - `swapExercise` → `{"oldExerciseId": "<id واقعی>", "newExerciseId": "<id واقعی از گراف similarity>"}`
     - `adjustWorkoutIntensity` → `{"sessionDuration": "15/30/45/60", "intensity": "LIGHT/MEDIUM/HARD"}`
     - `openPage` → برای هدایت خارج از حوزه‌ی ورزش (همان الگوی مسیرهای معتبر عبادت: `/sleep`, `/health`, `/worship`, ...).
4. **`_handleAction`**: عیناً مثل عبادت، دیالوگ تایید فارسی نشان بده، سپس `AssistantActionRegistry.executeAction(context, action.toAssistantAction(), () => _loadSportsContext())` را صدا بزن. **هیچ SQL مستقیمی در UI نزن** — رجیستری خودش `rowsAffected` را مدیریت می‌کند و «موفقیت دروغین» ساختاراً حذف می‌شود.
5. **پیام خوش‌آمد + quick replies**: ورزشی («این هفته را سبک‌تر کن 📉»، «یک حرکت جایگزین بده 🔄»، «تغذیه بعد تمرین 🍎»).
6. **رنگ لهجه**: به‌جای طلاییِ عبادت (`0xffD4A843`) از رنگ اصلی تم ورزش (`SupplementarySportsTheme` / `colors.primary`) استفاده کن.

### F.3 رفعِ ساختاریِ باگ «موفقیت دروغین»
چون کل مسیرِ اعمال از UI فِیک به `AssistantActionRegistry.executeAction` منتقل می‌شود، این باگ به‌صورت ریشه‌ای حل می‌شود: اکشن `swapExercise` (خط ~۹۳۷ رجیستری) و `adjustWorkoutIntensity` (خط ~۹۸۲) روی جداول واقعی کار می‌کنند. با این حال:
- در همان `executeAction` (case `swapExercise` و `adjustWorkoutIntensity`) بعد از `db.update` مقدار `rowsAffected` را چک کن؛ اگر `== 0` به‌جای toastِ موفقیت، toast صادقانه («این حرکت در برنامه‌ی فعال پیدا نشد») نشان بده و snapshot در `ss_plan_version_history` ذخیره **نکن**. اگر `> 0`: snapshot + پیام موفقیت.
- decision log (`ss_decision_log`) را با وضعیت واقعی (`AI_ACCEPTED` فقط وقتی `rowsAffected>0`) ثبت کن.

### F.4 نقطه‌ی فراخوانی (Entry Point)
- در `ss_home_dashboard_screen.dart` جایی که الان `SSAiCoachChatScreen` باز می‌شود، به `showModalBottomSheet(... builder: (_) => const SSAiCoachSheet())` تغییر بده (عیناً مثل نحوه‌ی باز شدن شیت عبادت در `worship_screen.dart` خطوط ۱۱۲–۱۱۷).
- فایل قدیمی `ss_ai_coach_chat_screen.dart` و کلاس‌های فِیکش (`_generateAiResponse`, `PlanChangeSuggestion` mock, `_isOffline`) را حذف کن.

### F.5 پیشنهاد درون‌متنی (Inline Suggestion) — طبق PRD ۴.۴
مربی نباید فقط در چت باشد. در `PlanDayDetailScreen` یک `InlineAiSuggestionCard` نشان بده که وقتی حرکتی چند هفته «EASY» خورده، همان‌جا پیشنهاد افزایش بدهد (دکمه‌ی «بله، ببر بالا / نه»). پذیرش باید **همان مسیر `AssistantActionRegistry.executeAction` با اکشن `adjustWorkoutIntensity`/`swapExercise`** را طی کند (نه SQL مستقیم) تا از حفاظ `rowsAffected` بهره ببرد.

**پذیرش F:**
- فایل مربی فِیک حذف شده و شیت جدید کلونِ دقیق دستیار عبادت است (استریم، تاریخچه، undo، toast همگی کار می‌کنند).
- پاسخ‌ها از `AIGateway` واقعی می‌آیند (نه `Future.delayed`)؛ آفلاین همان پیام خطای اتصالِ نمونه‌ی عبادت نشان داده می‌شود.
- پیشنهاد مربی فقط روی `exerciseId` واقعیِ برنامه ساخته می‌شود؛ اعمال از طریق رجیستری با چک `rowsAffected`؛ عدد جدید در `PlanDayDetailScreen` دیده می‌شود؛ **هیچ «موفقیت دروغین» رخ نمی‌دهد.**

---

## مرحله G — بازآرایی `WorkoutSessionScreen` به MVI + Riverpod

blueprint constraint ب: در صفحه‌ی تمرین فعال، فشار سریع دکمه‌ها در MVVM/set/State باعث Race Condition می‌شود. پروژه `flutter_riverpod ^3.0` دارد.

### G.1 کار
- منطق ۲۰۳۱ خطی و ۲۳ `setState` را به یک **Riverpod `Notifier`** (معادل StateFlow) با یک `SSWorkoutState` immutable منتقل کن.
- کلاس‌های `SSWorkoutIntent` که از قبل هستند (`SkipRestTimer`, `PauseResumeTimer`, ...) را به‌عنوان Intent نگه‌دار؛ یک متد `dispatch(SSWorkoutIntent)` که به‌صورت **ترتیبی** (reducer خالص) state را به‌روزرسانی کند → Single Source of Truth.
- `SSWorkoutState` شامل: `dayId, exercises (لیست ExerciseChecklistEntry با status DONE/CURRENT/UPCOMING), currentExerciseIndex, isShowingRestBanner, restTargetTimestamp, isShowingFeelingSheet` (مطابق PRD ۴.۳).
- Timerها (`_restTimer`, `_elapsedTimer`, `_autoDismissFeelingTimer`) و `AnimationController` را نگه‌دار اما فقط به‌عنوان side-effect؛ منبع حقیقت state باشد نه فیلدهای پراکنده.
- `dispose` صحیح فعلی (که همه‌ی timerها را cancel می‌کند) حفظ شود.

### G.2 Resume (ادامه از همان ست)
PRD ۴.۳ Edge Case: اگر کاربر اپ را وسط جلسه ببندد، با بازگشت **دقیقاً از `currentExerciseIndex`** ادامه دهد (وضعیت DONE‌های قبلی حفظ). state جلسه را در DB (یا یک جدول سبک/`ss_workout_session_log` باز) persist کن تا با restart اپ بازیابی شود.

**پذیرش G:** فشار سریع «انجام شد» + «جایگزین» + «رد استراحت» هیچ حالت ناسازگار/پرشی تولید نکند. بستن و بازکردن اپ وسط جلسه، از همان حرکت ادامه دهد.

---

## مرحله H — قابلیت‌های جدید و پاک‌سازی

### H.1 تمرین بی‌صدا (Neighbor-Friendly) — از blueprint
- در `SettingsScreen` و اختیاری در Onboarding یک toggle «حالت بی‌صدا (مناسب آپارتمان)» اضافه کن (در `ss_user_profile` یک ستون `neighborFriendly INTEGER DEFAULT 0` — در Migration V38 اضافه شود).
- وقتی فعال است، `SSPlanGenerator` حرکات با `noisy >= 2` را کنار بگذارد (Hard Rule سبک).

### H.2 «امروز نمی‌تونم» (Skip Reason) — PRD ۴.۲
BottomSheet با گزینه‌های [وقت ندارم / خسته‌ام / درد دارم / دلیل دیگه]. بسته به انتخاب:
- «درد دارم» → مسیر ایمنی: پیشنهاد استراحت + swap حرکات پرفشار.
- «وقت ندارم» → پیشنهاد نسخه‌ی کوتاه (targetCount کمتر).
- «خسته‌ام» → deload امروز.
هر انتخاب در `ss_decision_log` ثبت شود.

### H.3 نمایش‌های داده‌محور جدید
- در `PlanDayDetailScreen` و `WorkoutSessionScreen`: از `repsHint` برای نمایش صحیح شمارش استفاده کن (مثلاً «۱۸ تکرار (هر سمت)» برای `reps_count_change_sides`).
- نشانگر `impact`/`noisy` (آیکون کوچک) روی کارت حرکت.

### H.4 پاک‌سازی کد (بدهی فنی که در بررسی پیدا شد)
- `seed_service.dart` خط ~۲۸۰: `print()` → `debugPrint()`.
- `ss_plan_generator.dart`: متغیر محلی `FarsiMuscleNames` (خط ۸۰) → `farsiMuscleNames` (کانونشن Dart).
- بلوک تکراری تعیین `estimatedMinutes`/`targetCount` بر اساس `sessionDuration` را در یک helper واحد ادغام کن.
- **تقویم:** منطق `getCurrentStreak`/`getLast7DaysActivity`/`getMonthContinuityPercent` با `DateTime` میلادی است. بررسی کن بقیه‌ی اپ از تقویم شمسی (Jalali) استفاده می‌کند؛ اگر بله، مرزهای روز (start/end of day) را با همان lib شمسی پروژه هماهنگ کن تا streak درست محاسبه شود.

---

## ۲. چک‌لیست پذیرش نهایی (قبل از تحویل اجرا کن)

- [ ] `flutter analyze` بدون error جدید.
- [ ] Migration V38 روی دیتابیس نسخه‌ی قبلی بدون crash اجرا می‌شود و ستون‌های جدید + re-seed اعمال می‌شوند.
- [ ] `SELECT durationSeconds, toolsRequired, impact, muscleIntensity FROM ss_exercise` داده‌ی واقعی دارد.
- [ ] دو پروفایل با goal/focusAreas متفاوت، برنامه‌های محسوساً متفاوت می‌گیرند.
- [ ] کاربر با `kneeProblems`/`noJumping` هیچ حرکت `impact>=2` نمی‌گیرد.
- [ ] «جایگزین کن» فوری و سازگار با محدودیت‌ها کار می‌کند.
- [ ] تایمر استراحت بعد از خاموش/روشن‌کردن صفحه به ثانیه‌ی صحیح می‌پرد.
- [ ] مربی فِیک قدیمی حذف شده و شیت جدید **کلونِ دقیق دستیار عبادت** است؛ پاسخ‌ها از `AIGateway` واقعی می‌آیند (نه `Future.delayed`).
- [ ] پیشنهاد مربی فقط روی `exerciseId` واقعیِ برنامه ساخته می‌شود و اعمال از مسیر `AssistantActionRegistry.executeAction` با چک `rowsAffected` می‌گذرد؛ هیچ «موفقیت دروغین» رخ نمی‌دهد.
- [ ] بستن/بازکردن اپ وسط جلسه، از همان حرکت ادامه می‌دهد.
- [ ] حلقه‌ی Progressive Overload از feeling logها تغذیه می‌شود (نه mock).
- [ ] هیچ `print` باقی نمانده؛ نام‌گذاری‌ها اصلاح شده.

## ۳. قواعد کار
- **تغییرات را مرحله‌به‌مرحله (A→H) و اتمیک انجام بده؛ بعد از هر مرحله `flutter analyze` بگیر.**
- معماری لایه‌ای موجود (data/models, repositories, presentation) را حفظ کن.
- هیچ فایل موجودی را بدون خواندن کاملش تغییر نده.
- داده‌ی کاربر را در migration از دست نده (فقط `isCustom=0` را re-seed کن؛ حرکات سفارشی و logها دست‌نخورده بمانند).
- برای هر تصمیم غیربدیهی یک کامنت کوتاه فارسی/انگلیسی بگذار که «چرا».
