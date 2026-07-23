# 🤖 پرامپت اجرایی — «دستیارِ هوش مصنوعیِ چرخه (SOS)» با رضایتِ صریح — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ S1…S7 را یک‌سره تا آخر اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: به بخشِ SOSِ چرخه یک **دستیارِ هوش مصنوعیِ همدل** اضافه کن که: (۱) **قبل از اولین گفتگو رضایتِ صریح** می‌گیرد؛ (۲) یک **کلیدِ اختیاری** دارد که اگر کاربر خودش خواست، اطلاعاتِ پریودش را به AI بفرستد؛ (۳) محدودیتِ شدیدِ فعلی را فقط در همین مسیرِ اختصاصی و با رضایت، **به‌درستی دور می‌زند** — نه با ضعیف‌کردنِ گاردِ عمومی.
> سندِ طراحی: `DESIGN_SYSTEM_CYCLE.md`.

## ⛔️ قواعد (یک‌بار)
- معماری نقش‌ها: Flutter مغز/UI. AI از طریقِ همان gateway و الگوی موجودِ ماژول‌ها.
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی. رنگِ پایه‌ی چرخه: صورتی `#EC4899`. رنگ/اندازه هاردکد نکن جز رنگِ برندِ صورتی که در همین ماژول مرسوم است.
- معماریِ موجودِ حریم/قفل را **نشکن:** کلِ این قابلیت **پشتِ `CycleLockGate` (PIN/بیومتریک)** است که از قبل دور صفحه‌ی چرخه هست — جای جدیدی بیرون از آن نساز.
- فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.

## 🔒 قیدهای محرمانگی (نقضشان = باگِ بحرانی — یک‌بار، اما قطعی)
1. **گاردِ عمومی دست‌نخورده:** «Zero-Leak Rule 0» در `lib/core/ai/ai_context_builder.dart` (لیستِ `cycleKeywords` → `out_of_scope`) را **حذف یا ضعیف نکن**. دستیارِ عمومیِ اپ هرگز نباید دربارهٔ پریود حرف بزند. این فیچر مسیرِ **اختصاصیِ جداگانه** است، نه بازکردنِ گاردِ عمومی. یک کامنت کوتاه بالای Rule 0 اضافه کن که این تمایز را توضیح دهد.
2. **باروری پنهان (قیدِ سخت):** حتی وقتی کاربر رضایتِ ارسالِ داده داده، **هرگز** `fertileWindowStart/End` و `ovulationDay` به AI نرود و AI هرگز دربارهٔ پنجرهٔ بارور/تخمک‌گذاری/برنامه‌ریزیِ بارداری چیزی نگوید (در systemPrompt صریح ممنوع شود).
3. **پیش‌فرضِ همه‌چیز خاموش:** بدونِ رضایتِ صریح هیچ گفتگویی شروع نشود؛ بدونِ opt-inِ صریح هیچ دادهٔ شخصیِ پریود ارسال نشود.
4. **on-device:** دادهٔ خام در دستگاه می‌ماند؛ فقط هنگام ارسالِ آگاهانه، خلاصهٔ متنی به gateway می‌رود. متنِ رضایت این را شفاف بگوید.

## 📁 محیط (تأییدشده از کد)
- SOS فعلی: `lib/features/cycle/presentation/widgets/cycle_sos_section.dart` (یک کارت + bottom sheetِ نکاتِ ایستا برای تسکینِ درد، بدون AI). در `cycle_screen.dart` خط ~۱۲۴۸ رندر می‌شود.
- الگوی استانداردِ AI sheet (کپی‌برداری کن): `lib/features/sleep/presentation/widgets/ai_sleep_assistant_sheet.dart` — چتِ stateful، context-stringِ محلی، فراخوانیِ مستقیمِ Cloudflare با `http.post`، استریمِ کاراکتری. **این sheetها از `AIContextBuilder` رد نمی‌شوند** → برای ما همین مطلوب است.
- کلیدهای gateway در `app_settings`: `ai_base_url`, `ai_api_key`, `ai_model` (با همان fallbackهای داخلِ فایلِ نمونه).
- خروجیِ موتور `CycleEngineOutput` (در `lib/core/domain/engines/cycle_engine.dart`): `currentPhase`(enum `CyclePhase`), `dayOfCycle`, `dayOfPeriod`, `nextPeriodWindowStart/End`, `isIrregular`, `stats`, `dataMaturity` — **و** `fertileWindowStart/End`, `ovulationDay` که **نباید** استفاده شوند. در صفحه به‌صورت `_engineOutput` در دست است.
- علائم/لاگ‌ها: جدولِ `cycle_day_logs (logDate, flowLevel, symptomsJson, mood, energyTag, note)`؛ در صفحه `_dayLogs` موجود است.
- تنظیماتِ آینهٔ طول/عادت: `cycle_avg_length`, `cycle_avg_period`.
- رضایت‌های موجودِ چرخه: `cycle_consent_worship/energy/reminders/dashboard` (الگوی ذخیره: insert در `app_settings`). از همین الگو پیروی کن.
- نوشتنِ تنظیم: `db.insert('app_settings', {'key':..,'value':..}, conflictAlgorithm: ConflictAlgorithm.replace)`.

## 🔒 تصمیم‌های قطعی
- دو تنظیمِ جدید: `cycle_consent_ai` (رضایتِ استفاده از دستیار) و `cycle_ai_share_data` (اجازهٔ ارسالِ دادهٔ شخصی) — هر دو پیش‌فرض `'false'`. **بدونِ مهاجرتِ دیتابیس** (فقط key/value با `INSERT OR IGNORE`).
- بدونِ داده (`cycle_ai_share_data=false`): دستیار فقط مربیِ عمومیِ تسکین/خودمراقبتیِ قاعدگی است.
- با داده (`=true`): context شاملِ فاز، روزِ چرخه/خونریزی، نظمی/نامنظمی، بلوغِ داده، علائمِ اخیر، طول/عادت، و پیش‌بینیِ بازهٔ پریودِ بعدی — **بدونِ هیچ دادهٔ باروری**.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**S1 — Seed تنظیمات.** در همان بلوکِ seedِ تنظیماتِ `cycle_screen.dart` (حوالی خط ۹۹، جایی که `cycle_avg_length` seed می‌شود) با `INSERT OR IGNORE` اضافه کن: `cycle_consent_ai='false'`، `cycle_ai_share_data='false'`. (نسخهٔ DB را بالا نبر.)

**S2 — گیتِ رضایت.** ویجت/تابعِ `showCycleAiConsentSheet(context)` بساز (می‌تواند در همان فایلِ S3 باشد): یک bottom sheet/دیالوگِ صورتی که شفاف توضیح می‌دهد:
- این گفتگو خصوصی و پشتِ قفل است؛ پاسخ‌ها مشاورهٔ خودمراقبتی است نه تشخیصِ پزشکی.
- دادهٔ شما در دستگاه می‌ماند و **فقط در صورتی** که خودتان کلیدِ ارسال را روشن کنید، خلاصه‌ای از وضعیت‌تان به سرویسِ هوش مصنوعی ارسال می‌شود.
- دکمه‌ها: «متوجه شدم، ادامه» (→ `cycle_consent_ai='true'` و باز شدنِ چت) و «بی‌خیال» (بستن).
- اگر `cycle_consent_ai` از قبل `'true'` بود، این گیت رد شود و مستقیم چت باز شود.

**S3 — Sheetِ دستیار.** فایلِ جدید `lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart` بر اساسِ الگوی `ai_sleep_assistant_sheet.dart`:
- ورودی‌ها: `CycleEngineOutput? engineOutput`, `List<Map<String,dynamic>> dayLogs`, `Map<String,String> settings`.
- UI چت + استریم + خواندنِ `ai_base_url/ai_api_key/ai_model` از settings، دقیقاً مثلِ نمونه. تمِ صورتی `#EC4899` به‌جای بنفش.
- پیامِ خوش‌آمدِ همدلانه (تسکینِ درد، علائمِ PMS، خودمراقبتی).

**S4 — کلیدِ ارسالِ داده + ساختِ context.** داخلِ sheet:
- یک `SwitchListTile`/چیپِ کوچک بالای چت: «ارسالِ وضعیتِ چرخه‌ام به دستیار (اختیاری)» که مقدارش `cycle_ai_share_data` است و با تغییر، در `app_settings` ذخیره می‌شود و state به‌روز می‌شود.
- تابعِ `_buildPersonalContext()` فقط وقتی switch روشن است یک String می‌سازد شاملِ: فازِ فعلی (برچسبِ فارسی)، `dayOfCycle`/`dayOfPeriod`، `isIrregular`، `dataMaturity`، `cycle_avg_length`/`cycle_avg_period`، تا ~۷ ردیفِ آخرِ `dayLogs` (تاریخ، `flowLevel`، `mood`، `energyTag`، علائمِ `symptomsJson`)، و «بازهٔ تقریبیِ پریودِ بعدی: `nextPeriodWindowStart`..`End`».
- **هرگز** `fertileWindowStart/End`/`ovulationDay` را اضافه نکن.
- وقتی switch خاموش است، هیچ بخشِ دادهٔ شخصی به systemPrompt افزوده نشود (فقط مربیِ عمومی).

**S5 — System Prompt.** systemPromptِ فارسی بساز با این قواعد: لحنِ آرام، محترمانه، بی‌قضاوت؛ تمرکز بر تسکینِ درد/علائم و خودمراقبتی؛ **ممنوع:** تجویزِ دارو، تشخیصِ بیماری، و **هرگونه** اشاره به باروری/تخمک‌گذاری/بارداری/برنامه‌ریزیِ بارداری؛ در علائمِ خطرناک (دردِ شدیدِ غیرعادی، خونریزیِ بسیار شدید، تب) ارجاع به پزشک. اگر context شخصی ضمیمه بود، با ظرافت از آن استفاده کند؛ اگر نبود، عمومی پاسخ دهد.

**S6 — نقطهٔ ورود در SOS.** در `cycle_sos_section.dart`:
- یک کارت/دکمهٔ جدیدِ «گفتگو با دستیارِ همدلِ ریتمو ✨» (یا یک بخش در همان sheetِ موجود) اضافه کن که `onTap` آن اول `showCycleAiConsentSheet` را اجرا کند و پس از رضایت، `ai_cycle_assistant_sheet` را باز کند. نکاتِ ایستای فعلیِ SOS را حفظ کن (حذف نکن).
- چون `CycleSosSection` فعلاً `const` و بدونِ داده است، امضایش را گسترش بده تا `engineOutput`/`dayLogs`/`settings` را از `cycle_screen.dart` بگیرد (در خط ~۱۲۴۸ پاس بده). اگر این داده‌ها هنوز null بودند، دکمهٔ AI صرفاً context شخصی نخواهد داشت (مشکلی نیست).

**S7 — تثبیتِ گاردِ عمومی.** فقط یک کامنتِ توضیحی بالای Rule 0 در `ai_context_builder.dart` اضافه کن (بدونِ تغییرِ منطق) که می‌گوید: دستیارِ عمومی هرگز دادهٔ چرخه نمی‌بیند؛ تنها مسیرِ مجاز، sheetِ اختصاصیِ پشتِ قفلِ چرخه با رضایتِ صریح است.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز.
- `flutter build apk --debug` → موفق.
- در گزارش بنویس: (الف) اولین ورود → گیتِ رضایت دیده می‌شود؛ پس از رد، دیگر دیده نمی‌شود. (ب) با switchِ خاموش، هیچ دادهٔ شخصی در requestBody نیست؛ با روشن، داده هست **ولی هیچ فیلدِ باروری ندارد**. (پ) Rule 0 دستِ‌نخورده و دستیارِ عمومی همچنان پریود را out_of_scope می‌کند.
