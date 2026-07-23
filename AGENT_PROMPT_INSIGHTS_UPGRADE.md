# 🤖 پرامپت اجرایی — «ارتقای موتورِ بینش» (Insights Engine v2) — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ I1…I10 را یک‌سره تا آخر اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: موتورِ بینش از یک «شمارنده‌ی روتین» به یک **موتورِ بینشِ همبستگی‌محور، آماراً امن، حساس به چرخه و قابل‌اقدام** ارتقا یابد. هر ۹ نقصِ شناسایی‌شده حل شود.

## ⛔️ قواعد (یک‌بار)
- **زبانِ همبستگی، نه علّی** (قیدِ سند): هرگز «X باعثِ Y شد»؛ فقط «همراه با / مرتبط با / در روزهایی که…». این قید مطلق است.
- خصوصیِ چرخه: هیچ واژه/دادهٔ صریحِ چرخه در بینش‌های عمومی ظاهر نشود؛ تأثیر فقط غیرمستقیم و از `CycleConsentBridge`.
- موتور **خالص و بازتولیدپذیر** بماند: هر بینش `sourceMetric` + `calculationWindow` + (جدید) `strength`/`confidence` داشته باشد. متن در l10n، نه هاردکد.
- منطقِ موجود را گسترش بده؛ سازگاریِ عقب‌رو با مصرف‌کننده‌ها (از جمله `AGENT_PROMPT_INBOX_PRODUCERS` که `entityId='${type.name}_${sourceMetric}'` می‌سازد) حفظ شود.
- فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.

## 📁 محیط (تأییدشده از کد)
- موتور: `lib/core/analytics/insight_generation_engine.dart` (`static generate(...)` + `CachedEngine`). مدل: `InsightResult {type, params, sourceMetric, calculationWindow}` و `enum InsightType {learningGrowth, healthDecline, morningLead, fatigueWarning, productiveWeekday, gatheringData}` در `lib/core/domain/engines/engine_enums.dart`.
- رندر: `insights_screen.dart` (~خط ۱۱۶۳) با `switch` روی `InsightType` و پیام‌های l10n (`l10n.learningGrowthInsightMessage(...)` و …). ورودیِ موتور در ~خط ۲۵۳ ساخته می‌شود.
- **منابعِ دادهٔ آمادهٔ بین‌دامنه‌ای:**
  - جدولِ `daily_rhythm` (per-day): `scheduledCount`, `successCount`, `completion_ratio`, `rhythmScore`, `energyDrained`, `energyRecharged`, `lifeBalanceScore`, `isGraceDay`. → برای **نرخ** و **روند** به‌جای شمارشِ خام.
  - `EnergyAnalyticsOutput`: `peakPerformanceWindow`, `mostProductiveWeekday`, `mostFatiguedWindow`, `currentDynamicEnergy`.
  - `SleepEngineOutput`: `sleepEnergyCorrelation`(-1..1), `sleepMoodCorrelation`, `correlationInsight` — **همبستگیِ از قبل محاسبه‌شده**.
  - `CycleConsentBridge.isUserMenstruating()` (bool، غیرمستقیم).
  - `routine_occurrences` (scheduled/done per day) برای نرمال‌سازیِ دقیق در صورت نیاز.
- 🐞 بدهیِ اسکیما: در `calculateWorshipCorrelation` نام ستون‌ها بین `start_date/startDate` و `end_date/endDate` ناهماهنگ است (`worship_seasons`).

## 🎯 نگاشتِ ۹ نقص → تسک‌ها
۱ کوریِ بین‌دامنه‌ای → **I3** · ۲ نبودِ همبستگی → **I3** · ۳ شکنندگیِ آماری → **I2** · ۴ نرمال‌نشدن → **I2** · ۵ پنجره‌های ناهمگون → **I4** · ۶ حساسیتِ چرخه → **I5** · ۷ غیرقابل‌اقدام → **I6** · ۸ تکراری/بی‌تازگی → **I7** · ۹ ناسازگاریِ اسکیما → **I8**.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**I1 — گسترشِ مدل (`engine_enums.dart`).**
- به `InsightResult` فیلدهای جدید (با مقدارِ پیش‌فرض برای سازگاریِ عقب‌رو): `double strength = 0.0` (شدت/قدرتِ ۰..۱)، `String severity = 'INFO'` (`POSITIVE`/`INFO`/`WATCH`)، `String? actionType` (مثلاً `open_module`/`assistant_suggest`)، `String? linkModule`، `Map<String,dynamic>? actionParams`.
- enum `InsightType` را گسترش بده: `sleepEnergyCorrelation`, `sleepMoodCorrelation`, `energyCompletionLink`, `consistencyScore`, `bestDomainOfWeek`, `streakHighlight`, `goalProgress`, `worshipConsistency`, `noisyDataSuppressed` (برای موارد رد‌شده، فقط داخلی).
- `toMap/fromMap` اگر دارد به‌روزرسانی شود.

**I2 — آمارِ امن: نرخ + حداقلِ نمونه (نقص ۳ و ۴).** یک helperِ مشترک بساز و در همهٔ بینش‌های مقایسه‌ای استفاده کن:
- به‌جای شمارشِ خام، **نرخِ تکمیل** = `successCount/scheduledCount` (از `daily_rhythm`) یا completed/occurrences محاسبه شود.
- **گیتِ حداقلِ نمونه:** هیچ بینشِ درصدی منتشر نشود مگر مخرجِ هر دو بازه `>= kMinSample` (پیش‌فرض ۵). درصدها روی مخرجِ کوچک رد شوند.
- `strength` را از اندازهٔ اثر + حجمِ نمونه بساز (مثلاً نرمال‌شده)؛ بینش‌های کم‌قدرت (`strength < 0.2`) منتشر نشوند (یا `noisyDataSuppressed` داخلی).
- `learningGrowth`/`healthDecline` را با همین قواعد بازنویسی کن (نه `prev>0` تنها).

**I3 — بینش‌های همبستگی و بین‌دامنه‌ای (نقص ۱ و ۲ — هستهٔ ارتقا).** ورودیِ موتور (`InsightGenerationEngineInput`) و call-siteِ `insights_screen` (~خط ۲۵۳) را گسترش بده تا این‌ها را هم بگیرد: `sleepEnergyCorrelation`, `sleepMoodCorrelation` (از `SleepEngineOutput`)، ردیف‌های اخیرِ `daily_rhythm`، و `isMenstruating`. سپس بینش‌های جدید تولید کن (همه با زبانِ «مرتبط با»):
- **خواب↔انرژی / خواب↔خلق:** اگر `|correlation| >= 0.3` → `InsightResult(type: sleepEnergyCorrelation, params:{'coef': r}, strength:|r|, severity: r>0?'POSITIVE':'WATCH')`. (از همبستگیِ از قبل محاسبه‌شده استفاده کن؛ دوباره حساب نکن.)
- **انرژی↔تکمیل:** همبستگیِ Pearson بین `energyRecharged`(یا `currentDynamicEnergy` روزانه) و `completion_ratio` روی `daily_rhythm`. اگر معنادار → `energyCompletionLink`.
- **ثبات (consistency):** انحرافِ معیارِ `completion_ratio` در ۱۴ روز → نمرهٔ ثبات؛ `consistencyScore` با severity مناسب.
- **بهترین دامنهٔ هفته / بهترین روز:** از داده‌های موجود.
- یک helperِ `pearson(List<num> x, List<num> y)` بساز (یا اگر در `sleep_engine`/جایی هست، reuse کن — دوباره ننویس).

**I4 — پنجره‌های یکدست + confidence (نقص ۵).**
- یک enum/ثابتِ پنجره تعریف کن (`LAST_7_VS_PREV_7`, `LAST_14`, `LAST_30`, `ALL_TIME`) و همهٔ بینش‌ها یکی از این‌ها را در `calculationWindow` بگذارند.
- `morningLead` را هم به یک پنجرهٔ مشخص (مثلاً `LAST_14`) ببر، نه `all_time`.
- `confidence` را در `strength` منعکس کن (تابعِ حجمِ نمونه).

**I5 — قاب‌بندیِ حساس به چرخه (نقص ۶).** اگر `isMenstruating == true`:
- بینش‌های «افت» (مثل `healthDecline`) **منتشر نشوند یا با severity=`INFO` و لحنِ نرم** قاب شوند (نه `WATCH`/هشدار). 
- هیچ اشاره‌ای به علت نشود (نه صریح نه ضمنی به چرخه). فقط شدت/severity تعدیل شود.
- این منطق پشتِ `CycleConsentBridge` باشد و اگر کاربر مرد/غیرفعال بود بی‌اثر.

**I6 — بینشِ قابل‌اقدام (نقص ۷).** برای بینش‌هایی که اقدام دارند `actionType`/`linkModule`/`actionParams` را پر کن:
- مثال: `morningLead` → `actionType:'assistant_suggest'`, پیشنهادِ «جابجاییِ روتین‌های سنگین به صبح»؛ `fatigueWarning` → `linkModule:'energy'`.
- در `insights_screen` رندرِ کارتِ بینش یک دکمهٔ اختیاری «اقدام» نشان دهد که طبقِ `actionType` عمل کند (deep-link یا باز کردنِ دستیار با متنِ از پیش). از مسیرهای موجود استفاده کن.

**I7 — تنوع، تازگی و رتبه‌بندی (نقص ۸).**
- بینش‌ها بر اساسِ `strength*severityWeight` مرتب شوند و **حداکثرِ N** (مثلاً ۶) منتشر شود تا فید شلوغ/تکراری نشود.
- بینش‌های جدید: `streakHighlight` (از streak)، `goalProgress` (از `goals/goal_steps`)، `worshipConsistency` (از خروجیِ موجودِ worship correlation). 
- چرخش: اگر چند بینشِ هم‌قدرت بود، تنوعِ نوع را ترجیح بده (نه همه از یک دامنه).

**I8 — تمیزکاریِ اسکیمای `worship_seasons` (نقص ۹).** نامِ ستون‌ها را یکدست کن: یک نامِ متعارف (`startDate`/`endDate`) انتخاب کن؛ اگر مهاجرتِ rename لازم است با الگوی موجود (`_safeAddColumn` + کپیِ مقدار) انجام بده و fallbackهای `start_date`/`end_date` در `calculateWorshipCorrelation` را حذف کن. اگر ریسکِ مهاجرت بالاست، حداقل یک helperِ واحدِ `seasonStart(s)/seasonEnd(s)` بساز و همه‌جا از آن استفاده کن (نه تکرارِ fallback). در گزارش بنویس کدام مسیر را رفتی.

**I9 — l10n.** برای هر نوعِ بینشِ جدید پیامِ فارسی/انگلیسی به `app_fa.arb`/`app_en.arb` اضافه کن (با placeholderها مثل الگوی موجود) و در `switch`ِ `insights_screen` رِندر کن. لحن: آرام، غیرقضاوتی، همبستگی‌محور.

**I10 — اعتبارسنجی (یک‌بار).**
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز. **تست‌های واحد اضافه کن:** (۱) مخرجِ کوچک (prev=۲،last=۱) هیچ بینشِ درصدی تولید نکند؛ (۲) همبستگیِ `|r|<0.3` بینش ندهد؛ (۳) با `isMenstruating=true` بینشِ «افت» منتشر نشود یا severity نرم شود؛ (۴) خروجی هرگز واژهٔ صریحِ چرخه نداشته باشد.
- در گزارش: فهرستِ بینش‌های جدید، نحوهٔ حلِ هر ۹ نقص، و مسیرِ انتخابیِ I8.
