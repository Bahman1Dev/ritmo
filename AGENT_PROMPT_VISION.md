# 🤖 پرامپت اجرایی برای Gemini 3.5 Flash — تکمیل ایده‌ی اصلی ریتمو

> این فایل **خودبسنده** است. کل آن را عیناً به Gemini بده. ایجنت نیازی به خواندن سند دیگری ندارد.
> هدف: تکمیل ۴ ویژگی نیمه‌کاره‌ی ایده‌ی اصلی → افزایش تدریجی، هدف خواب، خردکردن سلسله‌مراتبی هدف، خردکردن با AI.

---

## ⛔️ قوانین سخت (هرگز نقض نکن)

1. **هر بار فقط یک تسک.** تا تأیید نشدن تسک فعلی، سراغ بعدی نرو.
2. **بعد از هر تسک این دو فرمان را اجرا کن و خروجی را گزارش بده:**
   ```bash
   flutter analyze
   flutter test
   ```
   اگر error یا تستِ شکست‌خورده‌ی جدید ظاهر شد، **همان تسک را برگردان (revert)** و قبل از ادامه گزارش بده. تعداد error/warning نباید نسبت به قبل بیشتر شود.
3. **فقط فایل‌های نام‌برده‌ی هر تسک را تغییر بده.** ریفکتور یا «بهبود» کد نامرتبط ممنوع.
4. **هیچ رشته‌ی فارسی موجود را ترجمه/حذف نکن.** متن‌های جدید UI را فارسی بنویس.
5. **هیچ مقدار محاسباتی/رنگ/اندازه را هاردکد نکن.** از تم/سرویس/ثابت‌های موجود استفاده کن.
6. **معماری RIE را نگه‌دار:** ترتیب لایه‌ها `Module Gate > Biological > Essential > Context > Energy > Time` و قانون «انجام روتین فقط از طریق شیت نیت». این‌ها دست‌نخورده بمانند.
7. **تسک F1 (مهاجرت دیتابیس) حساس‌ترین تسک است.** بعد از F1 توقف کن و منتظر تأیید انسانی بمان؛ تا تأیید نگرفتی سراغ F2 نرو.
8. اگر چیزی مبهم بود، **حدس نزن** — توقف کن و سؤال بپرس.

## 📁 محیط پروژه
- اپ Flutter، ریشه: `ritmo/`. زبان رابط: **فارسی (راست‌چین)**. فونت: `Vazirmatn`.
- دیتابیس: SQLite، در حال حاضر **نسخه ۸**، فایل `lib/core/database/database_helper.dart`.
- وضعیت پایه: ۰ خطای کامپایل، ۱۲ فایل تست سبز.
- enum بلااستفاده‌ای که زنده می‌شود: `RoutineType.progressive` در `lib/core/domain/models.dart`.
- روتین‌ها از قبل این فیلدها را دارند: `targetDurationMinutes`, `lightDurationMinutes`, `minimalDurationMinutes`.
- ماژول AI کامل و آماده است: `lib/core/ai/` شامل `ai_gateway.dart`, `ai_prompt_engine.dart`, `ai_fallback_engine.dart`.
- جداول موجود: `goals (id, parentGoalId, title, description, goalType, status, targetDate, createdAt, updatedAt)` و `goal_steps (id, goalId, title, isCompleted, displayOrder, createdAt)` و `bedtime_diagnostics (date, reason, note, createdAt)`.

## 🔒 تصمیم‌های قطعی طراحی (تغییر نده)
1. **مبنای پیشروی = انجام موفق (Completion-based).** مقدار فقط بعد از N جلسه‌ی واقعاً انجام‌شده جلو می‌رود. تعویق/skip اثری ندارد و کاربر را عقب نمی‌اندازد.
2. **نقش AI = دستیار.** AI پیشنهاد می‌دهد؛ کاربر قبل از ذخیره ویرایش/تأیید می‌کند. ذخیره‌ی خودکار بدون تأیید ممنوع.
3. **یک موتور واحد برای دو حالت:** `DURATION_RAMP` (مدت ↑) و `TIME_SHIFT` (ساعت ↓، مثل خواب).

---

# 🗂 صف تسک‌ها (به ترتیب اجرا کن)

## ▣ تسک F1 — مهاجرت اسکیما به نسخه ۹ 🔴 حساس
**فایل:** `lib/core/database/database_helper.dart`
**اقدام:**
1. مقدار `version` را از `8` به `9` تغییر بده (هر دو جای ظاهرشدن).
2. ستون‌های زیر را به جدول `routines` اضافه کن (هم در `onCreate` برای نصب تازه، هم در `onUpgrade` با `ALTER TABLE routines ADD COLUMN ...`):
   - `progressionMode TEXT NOT NULL DEFAULT 'NONE'`  (مقادیر مجاز: `NONE` / `DURATION_RAMP` / `TIME_SHIFT`)
   - `progressionStart INTEGER NOT NULL DEFAULT 0`  (دقیقه؛ در TIME_SHIFT = دقیقه از نیمه‌شب)
   - `progressionTarget INTEGER NOT NULL DEFAULT 0`
   - `progressionStep INTEGER NOT NULL DEFAULT 0`
   - `progressionEveryN INTEGER NOT NULL DEFAULT 1`
   - `progressionCurrent INTEGER NOT NULL DEFAULT 0`
   - `progressionDoneSinceAdvance INTEGER NOT NULL DEFAULT 0`
3. ستون‌های زیر را به جدول `goal_steps` اضافه کن (هم `onCreate` هم `onUpgrade`):
   - `scheduledDate TEXT`  (nullable)
   - `linkedRoutineId TEXT`  (nullable)
4. در `onUpgrade` حتماً نسخه‌بندی پلکانی را رعایت کن (اگر `oldVersion < 9` این ALTERها اجرا شوند). مراقب باش مهاجرت‌های نسخه‌های قبلی نشکنند.
**تأیید:** `test/migration_test.dart` پاس؛ سناریوی نصب تازه و ارتقا از نسخه ۸ هر دو سالم. **سپس توقف کن و منتظر تأیید انسانی بمان.**

## ▣ تسک F2 — ساخت موتور پیشروی
**فایل (جدید):** `lib/core/domain/engines/progression_engine.dart`
**اقدام:** کلاس `ProgressionEngine` با این منطق:
```
int currentTargetMinutes(Map routine):
    if routine['progressionMode'] == 'NONE': return routine['targetDurationMinutes'] ?? 0
    return routine['progressionCurrent']

Future<void> onCompletion(DatabaseExecutor db, String routineId):
    routine = خواندن روتین از db
    if progressionMode == 'NONE': return        // کاری نکن
    done = progressionDoneSinceAdvance + 1
    if done >= progressionEveryN:
        if mode == 'DURATION_RAMP': current = min(current + step, target)
        if mode == 'TIME_SHIFT':    current = max(current - step, target)
        done = 0
    update db: progressionCurrent = current, progressionDoneSinceAdvance = done
```
هیچ UI‌ای دست نزن. هیچ جای دیگری را تغییر نده.
**تأیید:** فایل تست جدید `test/progression_engine_test.dart`:
- بعد از `everyN` بار `onCompletion`، مقدار `current` دقیقاً یک `step` جلو برود (↑ برای DURATION، ↓ برای TIME_SHIFT).
- در `target` متوقف/clamp شود (از هدف رد نشود).
- با `progressionMode == 'NONE'` هیچ تغییری رخ ندهد.

## ▣ تسک F3 — اتصال موتور به مسیر تکمیل روتین
**فایل‌ها:** جایی که پس از تکمیل، در جدول `routine_completions` رکورد insert می‌شود — بررسی کن: `lib/core/services/alarm_scheduler_service.dart` و شیت نیت در `lib/features/routines/`.
**اقدام:** بلافاصله بعد از ثبت یک تکمیلِ **موفق**، `ProgressionEngine().onCompletion(db, routineId)` را صدا بزن. **برای تعویق/Snooze/skip این متد را صدا نزن.**
**تأیید:** تست رفتاری که نشان دهد فقط تکمیل موفق موتور را جلو می‌برد؛ analyze/test سبز.

## ▣ تسک F4 — UI پیشروی در فرم ساخت روتین
**فایل:** `lib/features/routines/presentation/routine_create_flow.dart`
**اقدام:**
1. یک انتخاب‌گر اضافه کن: «ثابت» / «تدریجیِ مدت» / «تدریجیِ زمان (خواب)».
2. اگر تدریجی انتخاب شد، ورودی‌های `start`, `target`, `step`, `everyN` نشان داده شود.
3. هنگام ذخیره، `progressionMode` و این مقادیر در ستون‌های جدید نوشته شوند و `progressionCurrent = progressionStart` قرار گیرد.
**تأیید:** ساخت و ذخیره‌ی روتین تدریجی بدون خطا؛ شیت نیت/تایمر باید `currentTargetMinutes` را نشان دهد (نه مقدار ثابت). analyze/test سبز.

## ▣ تسک F5 — سطوح هدف و فیلدهای جدید goal_steps در UI
**فایل:** `lib/features/today/presentation/widgets/goals_management_sheet.dart`
**اقدام:** پشتیبانی از `goalType` در سطوح `ANNUAL` / `MONTHLY` / `WEEKLY` / `DAILY` و امکان ست‌کردن `scheduledDate` برای هر قدم. سلسله‌مراتب از `parentGoalId` موجود استفاده می‌کند.
**تأیید:** ساخت هدف چندسطحی و قدم تاریخ‌دار بدون خطا؛ analyze/test سبز.

## ▣ تسک F6 — نمای درختی اهداف + کارت «قدم امروز» روی داشبورد
**فایل‌ها:** `goals_management_sheet.dart` و `lib/features/today/presentation/now_dashboard_screen.dart`
**اقدام:**
1. در شیت اهداف، والد/فرزند را به‌صورت درختی (قابل باز/بسته شدن) نمایش بده.
2. روی داشبورد یک کارت کوچک «قدم امروز» اضافه کن که `goal_steps` با `scheduledDate == today` را کوئری و نشان دهد.
**تأیید:** قدم روزانه روی داشبورد دیده شود؛ ظاهر بقیه‌ی داشبورد تغییر نکند؛ analyze/test سبز.

## ▣ تسک F7 — قالب prompt «تجزیه‌ی هدف»
**فایل:** `lib/core/ai/ai_prompt_engine.dart`
**اقدام:** یک قالب prompt جدید اضافه کن که از مدل می‌خواهد **فقط JSON معتبر** با این ساختار برگرداند:
```json
{ "subGoals": [
    { "title": "...", "level": "MONTHLY", "targetDate": "1404-08-30",
      "steps": [ { "title": "..." } ] } ] }
```
دستور بده مدل هیچ متن اضافه‌ای بیرون JSON ننویسد.
**تأیید:** تست واحد (هم‌سبک `test/ai_gateway_test.dart`) که ساختار prompt را بررسی کند؛ پاس.

## ▣ تسک F8 — فلوی «خرد کردن با هوش مصنوعی» (دستیار)
**فایل‌ها:** `goals_management_sheet.dart` (یا یک شیت جدید) + `lib/core/ai/ai_gateway.dart`
**اقدام:**
1. دکمه‌ی «خرد کردن با هوش مصنوعی» کنار هدف کلان.
2. فراخوانی `AiGateway` با قالب F7 → دریافت پاسخ.
3. **پارس JSON با try/catch.** اگر نامعتبر بود، از `ai_fallback_engine` پیام بده و کرش نکن.
4. نتیجه را در یک **پیش‌نمایش قابل‌ویرایش** نشان بده (کاربر بتواند عنوان‌ها را ویرایش/حذف کند).
5. فقط در صورت تأیید کاربر، زیرهدف‌ها (`goals` با `parentGoalId`) و قدم‌ها (`goal_steps`) ذخیره شوند.
**تأیید:** مسیر کامل بدون کرش؛ داده در سلسله‌مراتب درست بنشیند؛ analyze/test سبز.

## ▣ تسک F9 — صحت‌سنجی و مستندات
**اقدام:**
1. `flutter analyze` → باید نسبت به پایه error/warning جدید نداشته باشد.
2. `flutter test` → همه سبز.
3. `flutter run -d chrome` و تست دستی: ساخت روتین تدریجی → چند بار انجام موفق → دیدن جلو رفتن مقدار · ساخت هدف سالانه و خردکردن دستی · خردکردن با AI · دیدن قدم امروز روی داشبورد.
4. `ROADMAP_IDEA_COMPLETION.md` را به‌روز کن (تسک‌های انجام‌شده را علامت بزن).
**تأیید:** چک‌لیست Definition of Done کامل علامت بخورد.

---

## 📤 قالب گزارش بعد از هر تسک
```
## تسک [F?]: [عنوان]
- فایل‌های تغییر‌یافته: ...
- خلاصه‌ی تغییر: ...
- flutter analyze: [X errors, Y warnings]  (قبل: ... / بعد: ...)
- flutter test: [N passed, M failed]
- وضعیت: ✅ موفق / ⚠️ نیازمند بازبینی / ❌ برگردانده شد
- نکات/ابهامات: ...
```
اگر هر تأییدی شکست خورد، تغییرات همان تسک را برگردان و منتظر دستور بمان.
**یادآوری: بعد از تسک F1 حتماً توقف کن و منتظر تأیید انسانی بمان.**
