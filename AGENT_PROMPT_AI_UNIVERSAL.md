# 🤖 پرامپت اجرایی — «دستیارِ سراسری + کنترلِ تنظیمات» (AI Universal Access) — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ A1…A8 را یک‌سره تا آخر اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: دستیار یک **لایهٔ عاملِ کامل** شود — به دامنه‌های اپ **(جز چرخه و جز دارو/سلامت)** دسترسی بخواند و بتواند روتین/هدف/عبادت/بازتاب را بسازد/ویرایش/تکمیل/رد/حذف/جابجا کند و تنظیماتِ **رفتاری** را تغییر دهد؛ **همگی با تأییدِ صریحِ کاربر، اعتبارسنجیِ مقدار، و ثبت در دفترِ ممیزی**. هر آیتمِ علامت‌خوردهٔ `isPrivate` از AI پنهان بماند.
> 🚨 **اولویتِ ایمنی:** هیچ داده یا تنظیمِ پزشکی/دارویی هرگز به AI نرود و AI هرگز نتواند دارو/دوز/یادآوریِ دارو/رکوردِ سلامت را بخواند یا تغییر دهد. هر تغییر — هر چقدر کوچک — فقط با یک پنجرهٔ تأییدِ صریح اعمال شود.

## ⛔️ قواعد (یک‌بار)
- معماری: API ابری بدون پروکسی، با رضایتِ صریح (`assistant_cloud_consent`). الگوی موجود را گسترش بده، نشکن.
- **هر اکشن با تأییدِ صریحِ کاربر** اجرا می‌شود (Preview→Confirm). AI هرگز مستقیم در DB نمی‌نویسد.
- فارسی/RTL، `Vazirmatn`. فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.

## 🔒 قیدهای محرمانگی و امنیت (یک‌بار، قطعی)
1. **چرخه همیشه ممنوع:** «Zero-Leak Rule 0» در `ai_context_builder.dart` (لیستِ `cycleKeywords`) **دست‌نخورده** بماند. هیچ دادهٔ چرخه هرگز به context نرود و AI نتواند تنظیماتِ چرخه را تغییر دهد.
2. 🚨 **دارو/سلامت همیشه ممنوع (Rule 0.5 — ایمنیِ جانی):** AI هرگز نباید داده یا تنظیمِ پزشکی/دارویی را **بخواند یا تغییر دهد**. این‌ها کاملاً مستثنا هستند (نه toggle، نه رضایت):
  - **خواندن:** روتین‌های `category='medical'`، جدولِ `prn_logs` (دوز/مصرفِ دارو)، و کلِ دادهٔ ماژولِ سلامت (فشار خون، قند، آلرژی، ویزیت‌های پزشک، adherence/پایبندیِ دارویی، اسنادِ پزشکی). هیچ‌کدام در context نروند.
  - **نوشتن:** AI نتواند روتینِ پزشکی، یادآوریِ دارو، دوز، یا هر تنظیمِ مرتبط با سلامت/دارو را بسازد/تغییر دهد. کلیدواژه‌های دارویی (dose, dosage, medicine, medication, دارو, دوز, قرص, آمپول, نسخه) → اکشن رد شود.
  - **شفافیت:** اگر کاربر چنین چیزی خواست، AI با احترام توضیح دهد: «برای ایمنیِ سلامتت، تغییرِ دارو/یادآوریِ دارو/اطلاعاتِ پزشکی از طریقِ دستیار انجام نمی‌شود؛ این موارد را خودت در بخشِ سلامت مدیریت کن.» (این متن در systemPrompt و نیز به‌صورتِ fallbackِ کلاینت.)
1. **toggle هر آیتم:** هر ردیفی که ستونِ `isPrivate=1` دارد (مثلاً جدولِ `routines`) **نباید** در context برود. در همهٔ کوئری‌های دامنه شرطِ `isPrivate = 0` (یا `IS NULL OR =0`). (اگر جدولی `isPrivate` ندارد و کاربر باید بتواند پنهان کند، با `_safeAddColumn` ستونِ `isPrivate INTEGER NOT NULL DEFAULT 0` اضافه کن — حداقل `goals`, `daily_reflections`.)
2. **denylistِ امنیتیِ تنظیمات:** این کلیدها هرگز توسط AI تغییر نکنند: `app_lock_mode`, `app_lock_timeout_seconds`, `db_encryption_key`/هر کلیدِ رمز، `user_gender`, `assistant_cloud_consent`, `module_cycle_enabled`, `module_medicine_enabled`/`module_medical_enabled`, و هر کلیدِ با پیشوندِ `cycle_` یا مرتبط با سلامت/دارو.
3. **اعتبارسنجیِ مقدار (ضدِ prompt-injection):** AI فقط می‌تواند کلیدهای **داخلِ allowlistِ تعریف‌شده** را تغییر دهد، و هر مقدار باید از **schemaِ آن کلید** (نوع/بازه/enum) عبور کند. مثلاً `daily_capacity_minutes` فقط ۳۰..۷۲۰؛ مقدارِ `9999` رد می‌شود. این از تخریبِ رفتارِ کاربر با تزریق جلوگیری می‌کند.
4. **دفترِ ممیزی (Audit):** هر تغییری که AI اعمال می‌کند در جدولِ `assistant_audit_log` ثبت شود (کلید، مقدارِ قبلی/جدید، زمان) تا کاربر بتواند مرور/بازگردانی کند.

## 📁 محیط (تأییدشده از کد)
- `AIContextBuilder.buildContext({query, consent})` در `lib/core/ai/ai_context_builder.dart` فعلاً فقط ۵ دامنه را بر اساسِ کلیدواژه و consent می‌خواند: routines, goals, energy, sleep, planning. Rule 0 بالای آن است.
- `ConsentProfile` (همان فایل) از `app_settings` ساخته می‌شود.
- مسیرِ اجرا: `AIGateway.sendQuery/sendCopilotQuery` (`lib/core/ai/ai_gateway.dart`) → `AIContextBuilder.buildContext` → مدلِ ابری → `AIResponseProcessor.process/processCopilot` (`ai_response_processor.dart`) که آرایهٔ `actions` را پارس و انواعِ ناشناخته را دور می‌ریزد.
- پرامپتِ سیستم در `ai_prompt_engine.dart` انواعِ مجازِ اکشن را فهرست می‌کند (خط ~۲۶ و اسکیمای JSON خط ~۳۲).
- مدل‌ها در `lib/features/assistant/models/assistant_models.dart`: `enum AssistantActionType {createRoutine, createGoal, logSleep, logEnergyMood, addKonkurItem, createCourse, openPage}` (با `label`/`icon`/`fromString`) و `class AssistantAction {type, title, payload, targetRoute}`.
- اجرای اکشن در `lib/features/assistant/logic/assistant_action_registry.dart` (`executeAction(context, action, onComplete)` با `switch`؛ هر اکشن یک شیتِ از-پیش-پرشده باز می‌کند = همان Preview→Edit→Save).
- شیتِ پیش‌نمایش/تأیید: `assistant_action_preview_sheet.dart`.
- کلیدهای شناخته‌شدهٔ `app_settings` (از سند معماری): `gentleness_level, theme, streak_threshold, energy_validity_minutes, default_energy_level, digest_mode, coalescing_window_minutes, max_non_essential_per_hour, max_grace_per_week, max_grace_per_month, max_defer_count, daily_capacity_minutes, snooze_minutes, prayer_calculation_method, ihtiyat_minutes, home_city_id` و پرچم‌های ماژول `module_*_enabled` (جز `module_cycle_enabled`).

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**A1 — گسترشِ دامنه‌های context (با budget و استثنای پزشکی).** در `AIContextBuilder.buildContext` دامنه‌های جدید را اضافه کن (الگوی موجودِ کلیدواژه+consent+`relevantData[...]`): **worship/عبادت** (worship_practices/worship_debts)، **konkur/کنکور** (konkur_subjects/topics + آخرین mock results)، **courses/دوره** (courses/course_sessions)، **goals/اهداف** (goals/goal_steps)، **reflection/بازتاب** (daily_reflections)، **daily&#95;rhythm/نبض زندگی** (آخرین snapshotها)، **settings/تنظیمات** (فقط کلیدهای رفتاریِ غیرحساس).
- 🚨 **هیچ دامنهٔ پزشکی/سلامت اضافه نکن.** روتین‌های `category='medical'` را با `WHERE category != 'medical'` کنار بگذار؛ `prn_logs` و دادهٔ ماژولِ سلامت را اصلاً نخوان.
- **context budget (سقفِ سخت):** هر دامنه حداکثر چند ردیف (مثلاً routines≤۸، goals≤۵، logs≤۵، sessions≤۵)؛ فقط دامنه‌هایی که کلیدواژه‌شان در کوئری هست خوانده شوند (نه همه با هم)؛ هر ردیف فقط فیلدهای لازم. هدف: کوئریِ سبک، نه aggregationِ سنگین.
- در همه شرطِ `isPrivate=0` رعایت شود.
- **Rule 0 (چرخه) و Rule 0.5 (پزشکی) را تغییر نده.** اگر کوئری کلیدواژهٔ چرخه یا دارویی داشت → `out_of_scope`.
- کامنت بالای Rule 0/0.5: چرخه و سلامت/دارو تنها استثناهای کامل‌اند؛ بقیه با consent و budget در دسترس‌اند.

**A2 — افزودنِ انواعِ اکشنِ جدید (دستِ بازِ AI).** در `assistant_models.dart` به `AssistantActionType` این مقادیر را اضافه کن (+`label` فارسی +`icon`؛ در `fromString`/`switch`ها پوشش بده):
- `updateSetting` — «تغییر تنظیمات» (`slider_horizontal_3`)
- `completeRoutine` — «تیک زدن روتین» (`checkmark_circle`)
- `skipRoutine` — «رد کردن روتین» (`xmark_circle`)
- `editRoutine` — «ویرایش روتین» (`pencil`)
- `deleteRoutine` — «حذف روتین» (`trash`)
- `editGoal` — «ویرایش هدف» (`pencil_outline`)
- `completeGoalStep` — «تکمیل گامِ هدف» (`checkmark_seal`)
- `createWorshipItem` — «افزودن عبادت» (`moon_stars`)
- `logReflection` — «ثبت بازتاب» (`text_quote`)
- `rescheduleReminder` — «جابجاییِ یادآوری» (`clock`)
- این اکشن‌ها همگی **غیرپزشکی‌اند**؛ هر اکشنی که موجودیتِ `category='medical'` را هدف بگیرد در A4/A6 رد می‌شود.

**A3 — لایهٔ مجوز: allowlist + schema + اعتبارسنجی. فایلِ جدید lib/features/assistant/logic/settings&#95;action&#95;guard.dart:**
- `class SettingSchema { final String type; /* 'int'|'enum'|'bool' */ final int? min; final int? max; final List<String>? allowed; final String humanLabel; }`.
- `const Map<String, SettingSchema> kAiSettingsAllowlist = {...}` — **فقط** کلیدهای رفتاریِ مجاز با schema. نمونه‌ها:
  - `gentleness_level`: enum [`LOW`,`MEDIUM`,`HIGH`]
  - `daily_capacity_minutes`: int 30..720
  - `snooze_minutes`: int 1..120
  - `digest_mode`: bool
  - `coalescing_window_minutes`: int 1..60
  - `max_non_essential_per_hour`: int 1..20
  - `theme`: enum [`dark`,`light`,`system`]
  - `max_defer_count`: int 0..10
  - (هر کلیدِ رفتاریِ دیگر که امن است، با بازهٔ منطقی.)
- `bool isSettingChangeAllowed(String key)` → فقط اگر در allowlist باشد (و در denylistِ امنیتی/پزشکی نباشد و پیشوندِ `cycle_` نداشته باشد).
- `String? validateAndNormalize(String key, String value)` → اگر طبقِ schema معتبر بود مقدارِ نرمال‌شده، وگرنه `null` (رد). (int خارج از بازه، enum خارج از لیست، bool نامعتبر → `null`.)
- `Future<bool> applySettingChange(String key, String value)`: دوباره `isSettingChangeAllowed`+`validateAndNormalize` را چک کن (defense in depth)؛ مقدارِ قبلی را بخوان، در `app_settings` با `ConflictAlgorithm.replace` بنویس، در `assistant_audit_log` ثبت کن (تسکِ A9)، و `RitmoEventBus().fire('settings_changed')`. خروجی: موفق/ناموفق.

**A4 — اجرای اکشنِ updateSetting با پنجرهٔ تأییدِ صریح.** در `assistant_action_registry.dart` یک `case AssistantActionType.updateSetting`:
- `payload` شاملِ `{key, value, humanLabel}` است.
- اگر `!isSettingChangeAllowed(key)` → دیالوگِ محترمانه (برای کلیدِ پزشکی متنِ Rule 0.5؛ برای امنیتی متنِ امنیتی) و return.
- `normalized = validateAndNormalize(key, value)`؛ اگر `null` → پیامِ «مقدارِ پیشنهادی معتبر نیست» و return.
- یک **پنجرهٔ تأییدِ صریح** نشان بده (هرچقدر تغییر کوچک باشد — بدونِ استثنا): «تغییرِ «{humanLabel}» از «{مقدارِ فعلی}» به «{normalized}» — تأیید می‌کنید؟» با تأیید/لغو. روی تأیید → `applySettingChange` + `onComplete`. روی لغو → هیچ.

**A4b — اجرای اکشن‌های جدیدِ مدیریتی (CRUD + تکمیل) با گاردِ پزشکی.** در `assistant_action_registry.dart` برای هر اکشنِ جدید یک `case` اضافه کن. **قاعدهٔ مشترک (یک‌بار، روی همه):** پیش از اجرا، اگر موجودیتِ هدف `category='medical'` بود یا payload کلیدواژهٔ دارویی داشت → رد با متنِ Rule 0.5. هر اکشن از منطق/سرویس/شیتِ **موجود** استفاده کند (بازنویسی نکن) و در `assistant_audit_log` ثبت شود.
- `completeRoutine` (payload `{routineId, dateStr?}`): پس از تأیید → `AlarmSchedulerService.completeOccurrence(routineId, dateStr ?? today)`.
- `skipRoutine` (`{routineId, dateStr?}`): پس از تأیید → `AlarmSchedulerService.skipOccurrence(...)`.
- `editRoutine` (`{routineId, ...fields}`): روتینِ موجود را بخوان، شیتِ `RoutineFormScreen` را با مقادیرِ از-پیش-پرشده باز کن (همان Preview→Edit→Save) — کاربر تأیید/ذخیره می‌کند.
- `deleteRoutine` (`{routineId}`): یک دیالوگِ تأییدِ **صریحِ حذف** («حذفِ «{title}»؟ این عمل برگشت‌ناپذیر است») → روی تأیید، از مسیرِ حذفِ موجودِ روتین (آرشیو/حذف نرم اگر هست) استفاده کن.
- `editGoal` (`{goalId, ...}`): مشابهِ editRoutine با شیتِ هدفِ موجود.
- `completeGoalStep` (`{stepId}`): گامِ هدف را در `goal_steps` به‌عنوان انجام‌شده علامت بزن (از منطقِ موجودِ goals استفاده کن) + invalidate موتورِ goals.
- `createWorshipItem` (`{...}`): شیتِ افزودنِ عبادتِ موجود را باز کن.
- `logReflection` (`{...}`): شیت/مسیرِ ثبتِ بازتابِ موجود را باز کن.
- `rescheduleReminder` (`{reminderId، newTimeMs}`): فقط برای یادآوریِ **غیرپزشکی** → `NativeBridge.cancelAlarm` + ثبتِ مجددِ آلارم با زمانِ جدید (از مسیرِ موجودِ scheduler)؛ پنجرهٔ تأیید با زمانِ قدیم→جدید.
- اصول: اکشن‌های با اثرِ مخرب/برگشت‌ناپذیر (delete) **حتماً** دیالوگِ تأییدِ جداگانه دارند؛ بقیه پنجرهٔ تأییدِ استاندارد.

**A4c — پشتیبانیِ روتینِ بازه‌ای در createRoutine (یادآوریِ «هر N روز/ساعت»).** اکشنِ `createRoutine` را طوری گسترش بده که زمان‌بندیِ **INTERVAL** بسازد تا کاربر بتواند بگوید «هر ۲۵ روز یادآوری آرایشگاه» یا «هر ۴۸ ساعت حموم»:
- payloadِ گسترش‌یافته: `{title, category, routineType, timeOfDay?, recurrenceType?, intervalDays?, intervalHours?, durationMinutes?}` که `recurrenceType ∈ {EVERY_DAY, WORKDAYS, CUSTOM_DAYS, INTERVAL_DAYS, INTERVAL_HOURS, MONTHLY}`.
- زیرساخت از قبل هست: `routine_schedules.scheduleType='INTERVAL'` + `intervalHours`؛ `AlarmSchedulerService.onRoutineCompleted` آلارمِ بعدی را بعد از هر انجام دوباره می‌چیند؛ و `quick_add_parser.dart` همین الگوها را پارس می‌کند. **از همین مسیر/منطق استفاده کن** (نه پیاده‌سازیِ جدید).
- نگاشت: `INTERVAL_DAYS` با `intervalDays` → `intervalHours = intervalDays*24`؛ `INTERVAL_HOURS` با `intervalHours` مستقیم.
- `durationMinutes` (اگر داده شد) در `routines.targetDurationMinutes` بنشیند تا فلوی «الان انجام می‌دهم → تایمر» (پرامپتِ نوتیفیکیشن) برای آن روتین کار کند.
- مثلِ بقیهٔ createها، شیتِ `RoutineFormScreen` را با مقادیرِ از-پیش-پر باز کن (Preview→Edit→Save)؛ کاربر تأیید/ذخیره می‌کند.

**A5 — پرامپتِ سیستم.** در `ai_prompt_engine.dart` فهرستِ انواعِ مجازِ اکشن و اسکیمای JSON را به‌روزرسانی کن تا **همهٔ اکشن‌های جدید** (`updateSetting`, `completeRoutine`, `skipRoutine`, `editRoutine`, `deleteRoutine`, `editGoal`, `completeGoalStep`, `createWorshipItem`, `logReflection`, `rescheduleReminder`) را شامل شود، با payloadِ هر کدام:
- payloadها: `updateSetting` `{key,value,humanLabel}` · `completeRoutine`/`skipRoutine` `{routineId,dateStr?}` · `editRoutine` `{routineId,title?,description?,timeOfDay?,...}` · `deleteRoutine` `{routineId}` · `editGoal` `{goalId,...}` · `completeGoalStep` `{stepId}` · `createWorshipItem` `{...}` · `logReflection` `{...}` · `rescheduleReminder` `{reminderId,newTimeMs}`.
- در متنِ سیستم بنویس: AI می‌تواند روتین/هدف/عبادت/بازتاب را بسازد، ویرایش، تکمیل، رد، حذف یا جابجا کند و تنظیماتِ **رفتاریِ داخلِ allowlist** را تغییر دهد؛ اما **هرگز** موجودیت/تنظیماتِ امنیتی/قفل/جنسیت/چرخه/**پزشکی-دارویی** را؛ و هر اکشن فقط با تأییدِ صریحِ کاربر اجرا می‌شود.
- 🚨 **بندِ پزشکی در systemPrompt:** «دربارهٔ دارو، دوز، یادآوریِ دارو، یا هر اطلاعاتِ پزشکی/سلامت هیچ اکشن یا تغییری پیشنهاد نده. اگر کاربر خواست، محترمانه توضیح بده که این موارد برای ایمنی از دستیار خارج‌اند و باید در بخشِ سلامت دستی مدیریت شوند.»
- فهرستِ کوتاهِ کلیدهای allowlist و معنا/بازه‌شان را به پرامپت بده تا AI کلید/مقدارِ معتبر تولید کند.

**A6 — فیلترِ امنیتیِ خروجی (دفاع در عمق).** در `ai_response_processor.dart` هنگام پارسِ `actions`، این‌ها را **دور بریز** حتی اگر مدل قانون را نقض کند:
- `updateSetting` با `key` خارج از allowlist، یا با مقداری که از `validateAndNormalize` رد می‌شود.
- هر اکشنی که موجودیتِ پزشکی/دارویی را هدف بگیرد (مثلاً `createRoutine` با `category='medical'`، یا payload شاملِ کلیدواژه‌های دارویی).
- انواعِ ناشناخته (مثل قبل).

**A7 — toggle حریمِ آیتم در UI.** برای جداولی که `isPrivate` دارند/اضافه شد، در فرم/منوی آن آیتم یک سوییچِ کوچک «از دستیار هوش مصنوعی پنهان باشد» اضافه کن که `isPrivate` را ست می‌کند (حداقل در `routine_form_screen.dart`؛ اگر برای goals/reflection ستون اضافه کردی، آنجا هم). متنِ کوتاهِ راهنما.

**A8 — رضایتِ ابری (اگر از قبل نیست).** مطمئن شو پیش از اولین ارسالِ context، گیتِ `assistant_cloud_consent` بررسی می‌شود؛ اگر `'true'` نبود، یک‌بار دیالوگِ رضایت نشان بده که شفاف بگوید چه داده‌هایی (جز چرخه، سلامت/دارو و آیتم‌های خصوصی) ممکن است به سرویسِ ابری برود. روی پذیرش ست شود.

**A9 — دفترِ ممیزی + بازگردانی (Audit layer).** 
- جدولِ جدید (نسخهٔ DB فعلی+۱، در `_createDB` و مهاجرت): 
```sql
CREATE TABLE assistant_audit_log (
  id TEXT PRIMARY KEY,
  actionType TEXT NOT NULL,     -- updateSetting, createRoutine, ...
  targetKey TEXT,               -- کلید/شناسه‌ی هدف
  oldValue TEXT,
  newValue TEXT,
  appliedAt INTEGER NOT NULL
);
```
- `applySettingChange` (A3) هر تغییر را اینجا ثبت کند.
- یک نمای ساده در صفحهٔ دستیار/تنظیمات: «تغییراتِ اخیرِ دستیار» با امکانِ **بازگردانیِ** هر تغییر (نوشتنِ `oldValue` دوباره از طریقِ همان `applySettingChange`). این به کاربر کنترل و شفافیت می‌دهد.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز. تست‌های مرزِ امنیت را اضافه کن: (۱) context هرگز ردیفِ `isPrivate=1`، دادهٔ چرخه، یا دادهٔ پزشکی (`category='medical'`/`prn_logs`/سلامت) را شامل نشود؛ (۲) `validateAndNormalize('daily_capacity_minutes','9999')` باید `null` بدهد؛ (۳) `isSettingChangeAllowed` برای کلیدِ امنیتی/پزشکی/`cycle_*` باید `false` بدهد.
- `flutter build apk --debug` → موفق.
- در گزارش: (الف) دامنه‌های جدیدِ خواندنی + سقفِ budget هر کدام؛ (ب) فهرستِ کاملِ اکشن‌هایی که AI حالا می‌تواند (create/edit/complete/skip/delete/reschedule + updateSetting) و اینکه همه از پنجرهٔ تأیید عبور می‌کنند؛ (پ) نمونهٔ یک اکشنِ مدیریتی (مثلاً `completeRoutine`) و یک `updateSetting` معتبر که اعمال و در audit ثبت می‌شوند، و نمونه‌های رد (خارج از allowlist/بازه، و یک اکشنِ روی موجودیتِ `category='medical'`)؛ (ت) تأییدِ فعال‌بودنِ Rule 0 (چرخه)، Rule 0.5 (پزشکی)، `isPrivate`، اعتبارسنجیِ مقدار، و دفترِ ممیزی.
