# 🧭 نقشه‌راه تکمیل ایده‌ی اصلی ریتمو (Vision Completion Roadmap)

> **مکمل** `EXECUTION_PLAN.md` (که فقط بهینه‌سازیِ موجود بود). این سند ویژگی‌های **شاخصِ نیمه‌کاره‌ی ایده‌ی اصلی** را تکمیل می‌کند.
> **نقش‌ها:** Claude = معمار/پلن · Gemini 3.5 Flash = کدنویس
> **محدوده:** فقط موارد ۴، ۵، ۶، ۷ از ایده‌ی اصلی. (موارد ۸–۱۱ توسط مالک محصول عمداً حذف شده‌اند.)

## ✅ تصمیم‌های تأییدشده‌ی طراحی (Locked Decisions)
1. **مبنای پیشروی:** انجام موفق (Completion-based) — مقدار فقط بعد از N جلسه‌ی **واقعاً انجام‌شده** جلو می‌رود؛ اگر کاربر چند روز انجام ندهد عقب نمی‌افتد. (مطابق روح «عادت‌سازی».)
2. **نقش AI:** دستیار — AI پیشنهاد می‌دهد، کاربر قبل از ذخیره ویرایش/تأیید می‌کند.
3. **توالی اجرا:** `WS-1 → WS-2 → WS-3`.

## 🔑 بینش معماری محوری
موارد #۶ (افزایش تدریجی مدت) و #۷ (شیفت تدریجی ساعت خواب) **یک الگو** هستند: مقداری که در طول زمان به‌سمت هدف حرکت می‌کند. هر دو با **یک موتور واحد** و دو حالت پیاده می‌شوند:
- `DURATION_RAMP`: مدت ↑ (مثلاً ورزش ۱۰→۶۰ دقیقه، +۵)
- `TIME_SHIFT`: ساعت ↓ (مثلاً خواب ۰۱:۰۰→۲۳:۰۰، −۱۵ دقیقه)

---

# WS-1 — موتور پیشروی (Progression Engine) | پوشش #۶ و #۷

**هدف:** زنده‌کردن `RoutineType.progressive` و افزودن مقدارِ متحرک به روتین‌ها.

### مدل داده (مهاجرت به نسخه ۹ دیتابیس)
ستون‌های جدید روی جدول `routines`:
| ستون | نوع | معنا |
|------|-----|------|
| `progressionMode` | TEXT | `NONE` \| `DURATION_RAMP` \| `TIME_SHIFT` (پیش‌فرض `NONE`) |
| `progressionStart` | INTEGER | مقدار شروع (دقیقه؛ برای TIME_SHIFT = دقیقه از نیمه‌شب) |
| `progressionTarget` | INTEGER | مقدار هدف |
| `progressionStep` | INTEGER | گام هر پیشروی (مثلاً ۵ یا ۱۵) |
| `progressionEveryN` | INTEGER | بعد از چند انجام موفق، یک گام جلو برود |
| `progressionCurrent` | INTEGER | مقدار فعلی (با `progressionStart` مقداردهی اولیه) |
| `progressionDoneSinceAdvance` | INTEGER | شمارنده‌ی انجام‌ها از آخرین پیشروی (پیش‌فرض ۰) |

### منطق موتور (`lib/core/domain/engines/progression_engine.dart` — فایل جدید)
- `int currentTargetMinutes(routineMap)`: اگر `progressionMode == NONE` → همان `targetDurationMinutes`؛ وگرنه `progressionCurrent`.
- `Future<void> onCompletion(db, routineId)`: شمارنده +۱. اگر `done >= everyN`:
  - `DURATION_RAMP`: `current = min(current + step, target)`
  - `TIME_SHIFT`: `current = max(current - step, target)`
  - شمارنده صفر شود؛ مقادیر persist شوند.
- پیشروی فقط روی **انجام موفق** رخ می‌دهد (نه تعویق/skip).

### اتصال
- در مسیر ثبت تکمیل روتین (همان‌جا که در `routine_completions` insert می‌شود) → `ProgressionEngine.onCompletion(...)` صدا زده شود.
- شیت نیت و تایمر معکوس به‌جای مقدار ثابت، `currentTargetMinutes(...)` را بخوانند.

### UI
- در [routine_create_flow.dart](lib/features/routines/presentation/routine_create_flow.dart): انتخاب «ثابت / تدریجیِ مدت / تدریجیِ زمان» + ورودی‌های start/target/step/everyN.
- نمایش مقدار فعلی پیشروی روی کارت روتین (مثلاً «۲۵ از ۶۰ دقیقه»).

**معیار پذیرش WS-1:** ساخت روتین تدریجی ممکن باشد؛ پس از N انجام موفق، مقدار هدف یک گام جلو برود؛ تعویق/skip اثری نگذارد؛ تست واحد سبز.

---

# WS-2 — خردکردن سلسله‌مراتبی هدف | پوشش #۴

**هدف:** فعال‌کردن کاملِ سلسله‌مراتب سالانه→ماهانه→هفتگی→روزانه و نمایش «قدم امروز».

### مدل داده (نسخه ۹)
- `goals.goalType` این سطوح را بپذیرد: `ANNUAL` \| `MONTHLY` \| `WEEKLY` \| `DAILY` (علاوه بر انواع موجود). سلسله‌مراتب از `parentGoalId` موجود استفاده می‌کند.
- جدول `goal_steps`: افزودن `scheduledDate TEXT NULL` و `linkedRoutineId TEXT NULL`.

### UI
- بازطراحی [goals_management_sheet.dart](lib/features/today/presentation/widgets/goals_management_sheet.dart) به‌صورت **درختی** (هدف سالانه → باز شدن به ماه‌ها → هفته‌ها → روزها).
- **نمایش «قدم امروز»** روی داشبورد: کوئری `goal_steps` با `scheduledDate == today` و نمایش در یک کارت کوچک.

**معیار پذیرش WS-2:** ساخت هدف سالانه و افزودن زیرهدف/قدم در سطوح مختلف؛ قدم روزانه روی داشبورد ظاهر شود؛ تست سبز.

---

# WS-3 — خردکردن با هوش مصنوعی (دستیار) | پوشش #۵

**هدف:** کاربر هدف کلان را وارد کند، AI زیرهدف‌ها/قدم‌ها را **پیشنهاد** دهد، کاربر ویرایش/تأیید کند.

### اقدام
- قالب prompt جدید در [ai_prompt_engine.dart](lib/core/ai/ai_prompt_engine.dart) برای «تجزیه‌ی هدف» با خروجی **JSON سختگیرانه**:
  ```json
  { "subGoals": [ { "title": "...", "level": "MONTHLY", "targetDate": "1404-08-30",
      "steps": [ { "title": "..." } ] } ] }
  ```
- دکمه‌ی «خرد کردن با هوش مصنوعی» در شیت اهداف → فراخوانی [ai_gateway.dart](lib/core/ai/ai_gateway.dart) → پارس JSON → **صفحه‌ی پیش‌نمایش قابل‌ویرایش** → در تأیید، ذخیره در سلسله‌مراتب WS-2.
- مدیریت خطا: اگر JSON نامعتبر بود، از `ai_fallback_engine` استفاده و به کاربر پیام بده (بدون کرش).

**معیار پذیرش WS-3:** از یک هدف سالانه، AI پیشنهاد سلسله‌مراتبی بدهد؛ کاربر ویرایش و ذخیره کند؛ داده‌ها در WS-2 درست بنشینند؛ تست سبز.

---

# 🤖 تسک‌های آماده برای Gemini (به ترتیب، یکی‌یکی)

> قوانین سخت `AGENT_PROMPT.md` (یک تسک در هر مرحله، `flutter analyze`+`flutter test` بعد از هرکدام، بدون ریفکتور نامرتبط، حفظ معماری RIE) اینجا هم کاملاً برقرار است.

### تسک F1 — مهاجرت اسکیما نسخه ۹
**فایل:** `lib/core/database/database_helper.dart`
**اقدام:** `version` را به ۹ ببر. در `onUpgrade` (و در `onCreate` برای نصب تازه) ستون‌های پیشروی را به `routines` و ستون‌های `scheduledDate`/`linkedRoutineId` را به `goal_steps` اضافه کن (با `ALTER TABLE ... ADD COLUMN`). مقادیر پیش‌فرض امن بده.
**تأیید:** `migration_test.dart` پاس؛ نصب تازه و ارتقا از نسخه ۸ هر دو کار کنند.

### تسک F2 — ساخت ProgressionEngine
**فایل:** `lib/core/domain/engines/progression_engine.dart` (جدید)
**اقدام:** متدهای `currentTargetMinutes` و `onCompletion` را طبق بخش WS-1 پیاده کن. هیچ UI‌ای دست نزن.
**تأیید:** تست واحد جدید `test/progression_engine_test.dart`: بعد از `everyN` انجام، `current` یک گام درست (↑ برای DURATION، ↓ برای TIME_SHIFT) جلو برود و در سقف/کف clamp شود.

### تسک F3 — اتصال موتور به مسیر تکمیل روتین
**فایل‌ها:** مسیری که `routine_completions` در آن insert می‌شود (`alarm_scheduler_service.dart` و/یا شیت نیت).
**اقدام:** پس از ثبت تکمیل **موفق**، `ProgressionEngine.onCompletion(...)` صدا زده شود. تعویق/skip نباید موتور را جلو ببرد.
**تأیید:** تست رفتاری؛ analyze/test سبز.

### تسک F4 — UI پیشروی در فرم ساخت روتین
**فایل:** `lib/features/routines/presentation/routine_create_flow.dart`
**اقدام:** انتخاب «ثابت/تدریجیِ مدت/تدریجیِ زمان» + ورودی‌های start/target/step/everyN. ذخیره در ستون‌های جدید.
**تأیید:** ساخت و ذخیره‌ی روتین تدریجی بدون خطا؛ شیت نیت مقدار `currentTargetMinutes` را نشان دهد.

### تسک F5 — افزودن سطوح هدف و فیلدهای goal_steps در UI
**فایل:** `lib/features/today/presentation/widgets/goals_management_sheet.dart`
**اقدام:** پشتیبانی از `goalType` سطوح (ANNUAL/MONTHLY/WEEKLY/DAILY) و فیلد `scheduledDate` برای قدم‌ها.
**تأیید:** ساخت هدف چندسطحی؛ analyze/test سبز.

### تسک F6 — نمای درختی اهداف + قدم امروز روی داشبورد
**فایل‌ها:** `goals_management_sheet.dart` + `now_dashboard_screen.dart`
**اقدام:** نمایش درختیِ والد/فرزند؛ کارت «قدم امروز» روی داشبورد (کوئری `goal_steps.scheduledDate == today`).
**تأیید:** قدم روزانه روی داشبورد دیده شود.

### تسک F7 — قالب prompt تجزیه‌ی هدف
**فایل:** `lib/core/ai/ai_prompt_engine.dart`
**اقدام:** قالب جدید با خروجی JSON سختگیرانه‌ی بخش WS-3.
**تأیید:** تست واحد ساختار prompt (مثل `ai_gateway_test.dart`) پاس.

### تسک F8 — فلوی «خرد کردن با AI» + پیش‌نمایش قابل‌ویرایش
**فایل‌ها:** `goals_management_sheet.dart` (یا شیت جدید) + `ai_gateway.dart`
**اقدام:** دکمه → فراخوانی AI → پارس JSON → پیش‌نمایش ویرایش‌پذیر → ذخیره در سلسله‌مراتب. مدیریت خطای JSON با fallback.
**تأیید:** مسیر کامل بدون کرش؛ داده درست ذخیره شود.

### تسک F9 — صحت‌سنجی و مستندات
**اقدام:** `flutter analyze` (۰/۰) · `flutter test` (همه سبز) · smoke run · به‌روزرسانی این سند و `REMAINING_DEVELOPMENT.md`.

---

## 🚦 Definition of Done (نقشه‌راه ایده)
- [x] روتین تدریجی (مدت و زمان) ساخته و پس از انجام موفق، مقدار جلو می‌رود
- [x] تعویق/skip موتور پیشروی را جلو نمی‌برد
- [x] هدف سالانه به ماهانه/هفتگی/روزانه خرد می‌شود (دستی)
- [x] قدم امروز روی داشبورد دیده می‌شود
- [x] «خرد کردن با AI» پیشنهاد می‌دهد و کاربر ویرایش/ذخیره می‌کند
- [x] `flutter analyze` صفر ایراد · همه‌ی تست‌ها سبز · بدون کرش در smoke run
