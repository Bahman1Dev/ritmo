# 🤖 پرامپت اجرایی برای ایجنت کدنویس (Google Gemini 3.5 Flash)

> این فایل پرامپت کامل و خودبسنده‌ای است که باید عیناً به ایجنت کدنویس داده شود.
> ایجنت باید تسک‌ها را **به ترتیب** و **یکی‌یکی** اجرا کند و بعد از هر تسک تأیید (verify) بگیرد.

---

## ⛔️ قوانین سخت (هرگز نقض نکن)

1. **هر بار فقط یک تسک.** تا تأیید نشدن تسک فعلی، سراغ تسک بعدی نرو.
2. **بعد از هر تسک این دو فرمان را اجرا کن** و خروجی را گزارش بده:
   ```bash
   flutter analyze
   flutter test
   ```
   اگر error یا تست‌شکست جدید ظاهر شد، **همان تسک را برگردان (revert)** و قبل از ادامه گزارش بده. تعداد warning/error نباید نسبت به قبل **بیشتر** شود.
3. **فقط فایل‌های نام‌برده در هر تسک را تغییر بده.** ریفکتور یا «بهبود» کد نامرتبط ممنوع.
4. **هیچ رشته‌ی فارسی موجود را ترجمه/حذف نکن** مگر تسک صراحتاً بگوید.
5. **هیچ مقدار محاسباتی، رنگ یا اندازه را هاردکد نکن.** از تم/سرویس/ثابت‌های موجود استفاده کن.
6. **معماری RIE را نگه‌دار:** ترتیب لایه‌ها `Module Gate > Biological > Essential > Context > Energy > Time` و قانون «انجام روتین فقط از طریق شیت نیت» دست‌نخورده بماند.
7. **منطق و ظاهر را تغییر نده** مگر تسک صراحتاً بخواهد. در تسک‌های «انتقال/ریفکتور»، خروجی بصری باید بایت‌به‌بایت یکسان بماند.
8. اگر چیزی مبهم بود، **حدس نزن** — توقف کن و سؤال بپرس.

## 📁 محیط پروژه

- نوع: اپ Flutter، مسیر ریشه: `ritmo/`
- وضعیت پایه: ۰ خطای کامپایل، ۴۰ جدول دیتابیس (نسخه ۸)، ۱۲ فایل تست.
- زبان رابط: فارسی (راست‌چین).
- الگوی مرجع برای کار با موتورها: `lib/features/today/presentation/insights_screen.dart` خطوط ۱۹۸–۲۳۰.
- API گذرگاه موتور:
  ```dart
  await RitmoEngineBus.instance.execute<InputType, OutputType>(EngineClass, InputType(...));
  ```

---

# 🗂 صف تسک‌ها (به ترتیب اجرا کن)

## ▣ تسک ۱ — افزودن انرژی لحظه‌ای به خروجی موتور انرژی
**فایل:** `lib/core/analytics/energy_analytics_engine.dart`
**اقدام:**
1. به کلاس `EnergyAnalyticsOutput` فیلد جدید اضافه کن: `final double currentDynamicEnergy;` و آن را در سازنده (با `required` یا مقدار پیش‌فرض `0.0`) قرار بده.
2. اگر متد `calculate()` برای محاسبه‌ی `currentDynamicEnergy` به ورودی جدیدی نیاز دارد (مثل ساعت فعلی یا زون)، آن را به `EnergyAnalyticsEngineInput` اضافه کن (با مقدار پیش‌فرض تا فراخوانی‌های قبلی نشکنند).
3. داخل `calculate()` مقدار `currentDynamicEnergy` را با فراخوانی متد استاتیک موجود `calculateDynamicEnergy(...)` پر کن و در `EnergyAnalyticsOutput` برگردان.
4. متد استاتیک `calculateDynamicEnergy` را **حذف نکن** (هنوز ممکن است جای دیگری استفاده شود).
**تأیید:** `flutter analyze` بدون خطای جدید؛ `flutter test` (به‌ویژه `analytics_engines_test.dart`) سبز.

## ▣ تسک ۲ — مهاجرت داشبورد به گذرگاه موتور
**فایل:** `lib/features/today/presentation/now_dashboard_screen.dart`
**وضعیت فعلی:** این چهار فراخوانی استاتیک وجود دارد:
- خط ~۵۵۶: `EnergyAnalyticsEngine.calculateDynamicEnergy(...)`
- خط ~۶۰۵: `EnergyAnalyticsEngine.calculatePeakPerformanceWindow(...)`
- خط ~۶۱۰: `EnergyAnalyticsEngine.calculateMostFatiguedWindow(...)`
- خط ~۶۱۴: `EnergyAnalyticsEngine.calculateMostProductiveWeekday(...)`
**اقدام:**
1. این چهار فراخوانی استاتیک را با **یک** فراخوانی گذرگاه جایگزین کن:
   ```dart
   final energyOut = await RitmoEngineBus.instance
       .execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(
     EnergyAnalyticsEngine,
     EnergyAnalyticsEngineInput(/* همان داده‌هایی که الان به متدهای استاتیک پاس می‌شوند */),
   );
   ```
2. مقادیر را از خروجی بخوان:
   - انرژی لحظه‌ای ← `energyOut.currentDynamicEnergy`
   - پنجره اوج ← `energyOut.peakPerformanceWindow`
   - پنجره خستگی ← `energyOut.mostFatiguedWindow`
   - پربازده‌ترین روز ← `energyOut.mostProductiveWeekday`
3. importهای لازم را اضافه کن (`ritmo_engine_bus.dart` و `energy_analytics_engine.dart`). دقیقاً از الگوی `insights_screen.dart` خطوط ۲۰۰–۲۱۱ تقلید کن.
**تأیید:** داشبورد همان مقادیر قبلی را نشان دهد؛ هیچ فراخوانی استاتیک `EnergyAnalyticsEngine.` در این فایل نماند (`grep` بزن). `flutter analyze` و `flutter test` سبز.

## ▣ تسک ۳ — مهاجرت LifeBalance در داشبورد (شرطی)
**فایل:** `lib/features/today/presentation/now_dashboard_screen.dart`
**اقدام:** اگر داشبورد امتیاز تعادل زندگی را با فراخوانی استاتیک `LifeBalanceEngine.` محاسبه می‌کند، آن را هم به `bus.execute<LifeBalanceEngineInput, LifeBalanceEngineOutput>(...)` منتقل کن. اگر چنین فراخوانی‌ای نبود، این تسک را رد کن و گزارش بده «موردی یافت نشد».
**تأیید:** مثل تسک ۲.

## ▣ تسک ۴ — تست مهاجرت گذرگاه
**فایل:** `test/engines_test.dart` (یا فایل تست جدید `test/dashboard_bus_test.dart`)
**اقدام:** تستی بنویس که:
1. `EngineRegistry` بسازد و `EnergyAnalyticsEngine` را register کند، `RitmoEngineBus.init(...)`.
2. دوبار `execute(...)` با ورودی یکسان صدا بزند و تأیید کند بار دوم **cache hit** است (`diagnostics.getMetrics(...).cacheHits > 0`).
3. تأیید کند `currentDynamicEnergy` در خروجی مقدار معتبر دارد.
**تأیید:** تست جدید پاس شود.

## ▣ تسک ۵ — جایگزینی `withOpacity` منسوخ در کل پروژه
**محدوده:** تمام فایل‌های `lib/`
**اقدام:** هر `SOMETHING.withOpacity(VALUE)` را به `SOMETHING.withValues(alpha: VALUE)` تبدیل کن. **مورد‌به‌مورد** و فقط در کد واقعی (نه داخل رشته یا کامنت). فایل‌ها را گروهی پردازش کن اما بعد از هر چند فایل analyze بگیر.
**تأیید:** `grep -rn "withOpacity" lib/` خروجی خالی؛ `flutter analyze` تعداد info را شدیداً کاهش دهد؛ ظاهر تغییر نکند.

## ▣ تسک ۶ — حذف importها و متغیرهای بلااستفاده
**فایل‌های شناخته‌شده (و هر مورد دیگری که analyze نشان دهد):**
- `lib/features/today/presentation/widgets/reshuffle_preview_sheet.dart` (خط ۹: import بلااستفاده)
- `lib/features/today/presentation/widgets/morning_checkin_sheet.dart` (خط ۱۳۲: متغیر `isDarkMode`)
- `test/ai_gateway_test.dart` (خط ۲)
- `test/rie_test.dart` (خطوط ۹، ۲۱۸، ۳۲۳)
**اقدام:** هر `unused_import` را حذف کن؛ هر `unused_local_variable` را یا حذف کن یا اگر منطقاً لازم بوده، استفاده‌اش کن.
**تأیید:** warningهای `unused_*` در `flutter analyze` به ۰ برسند؛ تست‌ها سبز.

## ▣ تسک ۷ — رفع lintهای جزئی باقی‌مانده
**اقدام:** موارد امن باقی‌مانده در `flutter analyze` مثل `unnecessary_brace_in_string_interps` (نمونه: `temporary_event_create_sheet.dart` خط ۷۹) را رفع کن. فقط تغییرات بی‌خطر.
**تأیید:** هدف: `flutter analyze` → **0 errors, 0 warnings** و info حداقلی.

## ▣ تسک ۸ — ماژولار کردن داشبورد: استخراج ویجت‌ها
**فایل مبدأ:** `lib/features/today/presentation/now_dashboard_screen.dart`
**فایل‌های مقصد (جدید):** پوشه‌ی `lib/features/today/presentation/widgets/dashboard/`
**اقدام:** ویجت‌های زیر را **با cut-paste** (بدون تغییر منطق/ظاهر) به فایل جدا منتقل کن و در صفحه‌ی اصلی فراخوانی کن. هر ویجت را در یک ساب‌تسک جدا و با analyze/test جدا انجام بده:
1. کارت «نبض زندگی» → `pulse_card.dart`
2. کارت «زون فعلی» → `zone_card.dart`
3. نوار دسترسی سریع افقی → `quick_actions_bar.dart`
4. فهرست عمودی زیرسیستم‌ها → `subsystems_list.dart`
5. بنر دستیار هوشمند → `assistant_banner.dart`
**قید بحرانی:** هیچ پیکسلی از ظاهر نباید تغییر کند. فقط پارامترهای لازم را به سازنده‌ی ویجت جدید پاس بده.
**تأیید:** پس از هر ساب‌تسک `flutter analyze` و `flutter test` سبز؛ در پایان `flutter run -d chrome` و مقایسه‌ی چشمی داشبورد با قبل.

## ▣ تسک ۹ — ماژولار کردن داشبورد: استخراج کنترلر داده
**فایل مقصد (جدید):** `lib/features/today/presentation/dashboard_controller.dart`
**اقدام:** متدهای بارگذاری/محاسبه‌ی داده (`_load*`، کوئری‌های دیتابیس، فراخوانی Bus) را به کلاس `DashboardController` منتقل کن. صفحه فقط نتایج را مصرف کند.
**تأیید:** `now_dashboard_screen.dart` زیر ~۱٬۵۰۰ خط؛ رفتار یکسان؛ تست‌ها سبز.

## ▣ تسک ۱۰ — حسابرسی بومی‌سازی
**اقدام:** فایل جدید `l10n_audit.md` بساز که per-file تعداد رشته‌های فارسی هاردکد (متن‌های نمایش‌داده‌شده به کاربر که از `AppLocalizations` نمی‌آیند) را فهرست کند. اولویت: داشبورد، روتین‌ها، پروفایل، تقویم، بینش‌ها.
**تأیید:** گزارش تولید شود (این تسک کد تولیدی ندارد).

## ▣ تسک ۱۱ — استخراج رشته‌ها به ARB (صفحه‌به‌صفحه)
**فایل‌ها:** `lib/l10n/app_fa.arb`، `lib/l10n/app_en.arb`، و صفحه‌ی هدف.
**اقدام (برای هر صفحه، جداگانه):**
1. رشته‌های فارسی هاردکد را به `app_fa.arb` با کلید معنادار اضافه کن.
2. معادل انگلیسی را در `app_en.arb` با همان کلید اضافه کن.
3. در کد، رشته را با `AppLocalizations.of(context)!.key` جایگزین کن.
4. `flutter gen-l10n` سپس `flutter analyze`.
**ترتیب صفحات:** داشبورد → روتین‌ها → پروفایل → تقویم → بینش‌ها → بقیه.
**تأیید:** بعد از هر صفحه، analyze و test سبز؛ هیچ کلید گمشده.

## ▣ تسک ۱۲ — فعال‌سازی انتخاب زبان انگلیسی
**فایل:** `lib/features/profile/presentation/profile_screen.dart` (خط ~۱۷۶۵)
**اقدام:** برچسب «English (به زودی)» را به «English» تغییر بده و گزینه را فعال کن تا `locale` اپ را عوض کند. مطمئن شو `MaterialApp` به تغییر locale واکنش نشان می‌دهد.
**تأیید:** تعویض زبان در پروفایل، صفحات اصلیِ بومی‌سازی‌شده را به انگلیسی برگرداند بدون رشته‌ی گمشده یا کرش.

## ▣ تسک ۱۳ — صحت‌سنجی نهایی و مستندات
**اقدام:**
1. `flutter analyze` → باید 0 error / 0 warning باشد.
2. `flutter test` → همه سبز.
3. `flutter run -d chrome` و طی‌کردن مسیر کامل: آنبوردینگ → داشبورد → ساخت روتین + شیت نیت → تقویم → پروفایل → دستیار → کنکور → چرخه بدن. هر کرش یا پرش تم را گزارش بده.
4. `EXECUTION_PLAN.md` و `REMAINING_DEVELOPMENT.md` را به‌روز کن (تسک‌های انجام‌شده را علامت بزن).
**تأیید:** چک‌لیست «Definition of Done» در `EXECUTION_PLAN.md` کامل علامت بخورد.

---

## 📤 قالب گزارش بعد از هر تسک

```
## تسک [شماره]: [عنوان]
- فایل‌های تغییر‌یافته: ...
- خلاصه‌ی تغییر: ...
- flutter analyze: [X errors, Y warnings, Z info]  (قبل: ... / بعد: ...)
- flutter test: [N passed, M failed]
- وضعیت: ✅ موفق / ⚠️ نیازمند بازبینی / ❌ برگردانده شد
- نکات/ابهامات: ...
```

اگر هر تأییدی شکست خورد، تغییرات همان تسک را برگردان و قبل از ادامه منتظر دستور بمان.
