# 🤖 پرامپت اجرایی — سیستم «چرخه بدن» (محرمانه) — **ارتقا (v2)** — برای Gemini 3.5 Flash

> فایلِ خودبسنده. سیستم از قبل ساخته شده (v14)؛ این مرحله **عمیق‌سازی** است. کلِ صفِ C1 تا C12 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: ارتقای چرخه به **مربیِ کاملِ سلامت** (تحلیلِ روند + همبستگیِ علائم + پیش‌بینیِ شخصی‌سازی‌شده + فازِ PMS) + **پلِ فقهیِ کامل** (روزه‌ی قضا) — با حفظِ کاملِ محرمانگی و **پنهان‌کردنِ باروری**.
> سندِ طراحی: `DESIGN_SYSTEM_CYCLE.md`. فایل‌های اصلی موجود: `lib/features/cycle/presentation/cycle_screen.dart`، `cycle_lock_gate.dart`، `lib/core/domain/engines/cycle_engine.dart`، `lib/core/utils/cycle_consent_bridge.dart`، `cycle_privacy_guard.dart`.

## ⛔️ قواعد (یک‌بار)
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (`shamsi_date`؛ ذخیره ISO/epoch، نمایش شمسی). l10n جدید به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ `RitmoTheme`/`context.colors`. رنگِ پایه: صورتی `#EC4899`.
- لحنِ آرام و محترمانه و بدونِ قضاوت؛ بی‌نظمی «هشدارِ نرم» است نه تشخیصِ پزشکی (متن این را شفاف کند).
- داده‌ی دیتابیس تستی است؛ ستون‌های جدید با `DEFAULT`.
- فقط فایل‌های مرتبطِ هر تسک. ابهامِ واقعی → بپرس.
- معماریِ موجودِ حریم/قفل را **نشکن:** `CyclePrivacyGuard`, `CycleLockGate`, رضایت‌ها، `module_cycle_enabled`. فقط اضافه/عمیق کن.

## 🔒 قیدِ محرمانگی (هرگز نقض نشود — باگِ بحرانی)
- **پنهان‌سازیِ کامل از کاربرِ غیرِ زن:** هیچ ردّی از این مقوله جایی بیرون دیده نشود.
- **بیرون از این صفحه هیچ واژه‌ی صریحِ پریود/قاعدگی/چرخه** نوشته نشود. تأثیر بر بقیه‌ی سیستم‌ها فقط از `CycleConsentBridge` و با **لحنِ غیرمستقیم** («بر اساس ریتمِ بدنی‌ات این روزها...»).
- **باروری پنهان (قیدِ سخت):** هیچ پنجره‌ی بارور و هیچ تخمک‌گذاری در UI — نه در orb، نه در تقویم، نه هیچ‌جا. خروجی‌های باروریِ موتور به UI نروند.
- درونِ این صفحه (پشتِ PIN، vault) همبستگیِ صریح مجاز است؛ بیرون نه.
- AI هرگز مستقیم در DB نمی‌نویسد (Preview→Edit→Save).

## 🔒 تصمیم‌های قطعی
1. **مربیِ کاملِ سلامت:** روند + نمره‌ی نظم + همبستگیِ علائم + پیش‌بینیِ بازه‌ای + فازِ PMS.
2. **باروری پنهان** (بازگشت نسبت به v14).
3. **پلِ فقهیِ کامل با رضایت** (`cycle_consent_worship`): تعلیقِ غیرمستقیمِ عبادت + دفترِ روزه‌ی قضا.
4. **همبستگیِ دوسطحی:** درون‌چرخه صریح؛ بیرون فقط غیرمستقیم و با رضایت (انرژی=`cycle_consent_energy`، خواب=`cycle_consent_sleep`).

## 📁 محیط (تأییدشده از کد)
- DB SQLite، نسخه‌ی فعلی را از `database_helper.dart` بخوان؛ مهاجرت = **فعلی+۱** (`_migrateToVNN` + `if (oldVersion < NN)` + هم‌تراز در `_createDB`). `_safeAddColumn(db, table, column, typeDef)` موجود است.
- `cycle_periods (id PK, startDate, endDate, flowIntensity, isPredicted, note, createdAt, updatedAt)` و `cycle_day_logs (id PK, logDate UNIQUE, flowLevel, symptomsJson, mood, energyTag, note, createdAt, updatedAt)` — V14، دست‌نخورده.
- `cycle_engine.dart` (`CachedEngine`): خروجی شامل `currentPhase`, `dayOfCycle`, `dayOfPeriod`, `nextPeriodPrediction`, `fertileWindowStart/End`, `ovulationDay`, `isIrregular`, `stats`, `dataMaturity`. (خروجی‌های باروری دیگر در UI استفاده نشوند.)
- `CycleConsentBridge` (`isUserMenstruating`, `isEnergyTuned`) — تنها کانالِ مجازِ تأثیر بیرونی. مصرف‌کننده‌ها: `energy_mood_screen`/`mood_engine`/`assistant_engine`/`dashboard_controller`/`snapshot_sync_service`.
- `CyclePrivacyGuard.isVisible(settings) => user_gender=='FEMALE'`.
- `cycle_lock_gate.dart` — قفلِ PIN/بیومتریک، قفلِ خودکار در پس‌زمینه. حفظ شود.
- 🐞 پلِ فقهی stub: `addFastingDebtIfNeeded(...)` خالی (در cycle_screen ~خط ۱۳۰۷). باید پیاده شود.
- 🧹 legacy: `hormonal_intelligence_engine.dart` + جدولِ `cycle_logs` (استفاده در CycleHarmonyScreenِ پروفایل) — **نشکن و حذف نکن**؛ منبعِ حقیقتِ این سیستم `cycle_engine`+`cycle_periods` است.
- الگوی موتور: `CachedEngine` (calculate/invalidate/canRun/dependencies) + `RitmoEngineBus`. مرجع: `lib/core/analytics/courses_engine.dart`.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**C1 — مهاجرت.** نسخه فعلی+۱. جدولِ جدید:
```sql
CREATE TABLE fasting_debt (
  id TEXT PRIMARY KEY,
  dateIso TEXT NOT NULL,
  daysOwed INTEGER NOT NULL DEFAULT 1,
  reason TEXT,
  isResolved INTEGER NOT NULL DEFAULT 0,
  createdAt INTEGER,
  updatedAt INTEGER
);
```
هم در `_createDB` هم در تابعِ مهاجرت (`IF NOT EXISTS`). تنظیماتِ جدید با `INSERT OR IGNORE`: `cycle_consent_sleep='false'`, `cycle_fertility_visible='false'`, `cycle_pms_window_days='4'`. اصلاح: `cycle_length_days`/`period_duration_days` را با مقدارِ آینه‌ایِ `cycle_avg_length`/`cycle_avg_period` با `INSERT OR IGNORE` seed کن.

**C2 — مدل‌ها** (`lib/features/cycle/models/cycle_models.dart` — اگر هست گسترش بده): `SymptomStat {key, count, typicalCycleDay}`، `CycleTrendPoint {index, lengthDays, periodDays}`، `CycleCorrelation {metric, coefficient(double?[-1..1]), insight}`، `FastingDebt {id, dateIso, daysOwed, reason, isResolved}` (toMap/fromMap)، `BodyRhythmInfluence {energyDelta(double), indirectMessage}` (بدونِ هیچ واژه‌ی صریح).

**C3 — ارتقای موتور** (`cycle_engine.dart`):
- **پیش‌بینیِ بازه‌ای شخصی‌سازی‌شده:** از میانه + پراکندگیِ طولِ چرخه‌های تاریخی → `nextPeriodWindowStart/End` («حدوداً X تا Y روزِ دیگه») به‌جای نقطه‌ی خطی. مدتِ عادتِ شخصی از تاریخچه.
- `regularityScore` (۰..۱۰۰) و `trendPoints` (طول/مدتِ چند چرخه‌ی اخیر).
- `pmsWindowStart/End` = `cycle_pms_window_days` پیش از عادتِ بعدیِ پیش‌بینی‌شده.
- **باروری:** `fertileWindow`/`ovulationDay` را در UI استفاده نکن؛ اگر راحت‌تری از خروجیِ عمومی حذفشان کن (داخلی بمانند). هیچ‌جا رندر نشوند.
- منطقِ خالص در helperِ تست‌پذیر.

**C4 — همبستگی + آمارِ علائم** (`lib/features/cycle/logic/cycle_correlation.dart`، خالص و تست‌پذیر): جفت‌کردنِ `cycle_day_logs` با `energy_logs`/`mood_logs`/خواب(`bedtime_diagnostics`)/`routine_completions` بر اساسِ تاریخ → `List<CycleCorrelation>` (صادق، اگر داده کم بود coefficient=null). آمارِ علائم: فراوانی + خوشه‌بندیِ روزِ چرخه (`List<SymptomStat>`). فقط‌خواندنی.

**C5 — توسعه‌ی Bridge** (`cycle_consent_bridge.dart`): حفظِ `isUserMenstruating`/`isEnergyTuned`. افزودن:
- `Future<BodyRhythmInfluence?> bodyRhythmInfluence({required String forSystem})` — برای `energy` گیت با `cycle_consent_energy`، برای `sleep` گیت با `cycle_consent_sleep`؛ خروجی **غیرمستقیم و بدونِ واژه‌ی صریح**؛ اگر رضایت خاموش یا کاربر غیرِ این شرایط → `null`.
- متدهای پلِ فقهی: `Future<bool> isWorshipSuspended()` (گیت `cycle_consent_worship` + `isUserMenstruating`) و ثبت/خواندنِ `fasting_debt`.

**C6 — پلِ فقهی** (پیاده‌سازیِ `addFastingDebtIfNeeded` + سمتِ عبادت): با `cycle_consent_worship` در ایامِ عادت، روزهای روزه‌ی واجبِ ازدست‌رفته یک رکوردِ `fasting_debt` بسازند؛ وزنِ روتین‌های عبادیِ متأثر (نماز/روزه) در سمتِ عبادت **غیرمستقیم** تعلیق شود (از طریقِ `isWorshipSuspended`، بدونِ واژه‌ی صریح). یک نمای ساده‌ی **دفترِ روزه‌ی قضا** (لیست + «تسویه» = `isResolved=1`). بدونِ رضایت هیچ اثری.

**C7 — پاک‌سازیِ UIِ باروری.** در `cycle_screen.dart`: مارکرهای طلاییِ پنجره‌ی بارور و روزِ تخمک‌گذاری را از **تقویم** حذف کن؛ از **orb/نمایشِ فاز** هرگونه ارجاعِ تخمک‌گذاری را بردار (فازِ میان‌دوره را خنثی و سلامت‌محور بازنام‌گذاری کن). راهنمای رنگِ تقویم به‌روز شود: فقط عادتِ واقعی + بازه‌ی پیش‌بینی + پنجره‌ی PMS + نقطه‌ی روزهای دارای علامت.

**C8 — بخشِ روند و الگوها** (`widgets/cycle_trends_section.dart`): نمودارِ سادهٔ طول/مدت در چند چرخه (CustomPainter، بدونِ پکیجِ جدید) + `regularityScore` + آمار/خوشه‌ی علائم از C4 + هشدارِ نرمِ بی‌نظمی. حالتِ کم‌داده: «هنوز در حالِ یادگیریِ الگوی بدنتم 🌸».

**C9 — بخشِ همبستگیِ vault** (`widgets/cycle_correlation_section.dart`): همبستگیِ **صریحِ** علائم/حال/جریان با انرژی/خواب/روتین (از C4)، با لحنِ صادق و بدونِ قطعیتِ علّی. فقط درونِ این صفحه.

**C10 — خودمراقبتیِ فازی + کارتِ PMS.** خودمراقبتیِ فازیِ موجود را با خروجیِ موتور هماهنگ کن؛ اگر `pmsWindow` نزدیک است یک کارتِ آرامِ «روزهای پیش از عادت» با پیشنهادِ ملایم (بدونِ ارجاعِ باروری/تخمک‌گذاری). اگر AI استفاده شد: Preview→Edit→Save.

**C11 — تنظیمات/رضایت + یادآور.** پنلِ تنظیماتِ موجود: افزودنِ کلیدِ `cycle_consent_sleep` + توضیحِ شفافِ این‌که هر رضایت دقیقاً چه چیزِ غیرمستقیمی را بیرون می‌برد. یادآورهای discreet (`cycle_consent_reminders`) حفظ شوند. باروری همیشه پنهان.

**C12 — پایان.** کلِ مسیر را برای محرمانگی بازبینی کن: بیرون هیچ واژه‌ی صریح، باروری هیچ‌جا، تأثیرِ بیرونی فقط از Bridge و غیرمستقیم، کاربرِ غیرِ زن هیچ ردّی نبیند. `cycle_lock_gate` و رضایت‌ها دست‌نخورده کار کنند. اگر چیزی تغییر کرد `DESIGN_SYSTEM_CYCLE.md` را به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: موتور (پیش‌بینیِ بازه‌ای/نظم/روند/PMS)، همبستگی و آمارِ علائم (مثبت/منفی/کم‌داده)، Bridge (`bodyRhythmInfluence` غیرمستقیم + گیتِ رضایت + null وقتی خاموش)، پلِ فقهی (ثبتِ `fasting_debt` فقط با رضایت)، مهاجرتِ نصبِ‌تازه≡ارتقا.
- دستی: ورود با PIN → روند/الگوها → همبستگیِ vault → نبودِ هرگونه مارکرِ باروری/تخمک‌گذاری → با `cycle_consent_*` خاموش هیچ تأثیری بیرون نرود → با کاربرِ مرد هیچ ردّی دیده نشود → دفترِ روزه‌ی قضا با رضایتِ عبادت.

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی C1..C12: ...
- نسخه‌ی مهاجرت: ...
- flutter analyze / flutter test: ...
- بازبینیِ محرمانگی (پنهان‌بودنِ باروری + غیرمستقیم‌بودنِ بیرون + گیتِ جنسیت): ...
- ابهامات: ...
```
