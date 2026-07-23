# 🤖 پرامپت اجرایی — صفحه‌ی «عبادت» (Worship) — برای Gemini 3.5 Flash

> فایل **خودبسنده**. کل آن را عیناً به Gemini بده. هدف: ساخت کامل صفحه‌ی عبادت — اوقات شرعی، یادآوری نماز با تعویق، مستحبات، قرآن و ذکر، بدهی‌های عبادی، فصول عبادی.
> فایل اصلی: `lib/features/worship/presentation/worship_screen.dart` (جدید)

---

## ⛔️ قوانین سخت
1. **هر بار فقط یک تسک.** بعد از هر تسک `flutter analyze` و `flutter test` اجرا و گزارش کن. error/تست شکست‌خورده‌ی جدید → برگردان و گزارش بده.
2. **فقط فایل‌های نام‌برده‌ی هر تسک را تغییر بده.** ریفکتور نامرتبط ممنوع.
3. **متن‌ها فارسی و RTL.** فونت `Vazirmatn`. ارقام فارسی. کلیدهای جدید l10n به `app_fa.arb` و `app_en.arb` اضافه کن.
4. **رنگ/اندازه/رادیوس هاردکد نکن** — از `RitmoTheme` استفاده کن.
5. **هرگز قرمز برای نماز نخوانده.** لحن: محترمانه، تشویقی، گرم. «در انتظار توست» نه «قضا شدی».
6. **تسک W1 (مهاجرت) حساس است:** بعد از آن توقف کن و منتظر تأیید انسانی بمان.
7. چیزی مبهم بود → بپرس، حدس نزن.

## 📁 محیط پروژه
- Flutter، ریشه `ritmo/`. دیتابیس SQLite، **نسخه‌ی فعلی را از کد بخوان**.
- `PrayerTimeProvider` در `lib/core/services/prayer_time_provider.dart` — متدهای `getPrayerTimesForDate(cityId, date)` و `cachePrayerTimes(cityId, date)`.
- `prayer_times_cache` (date, cityId, fajr, sunrise, dhuhr, asr, maghrib, isha, midnightShari, calculationMethod, ihtiyatMinutes).
- `iran_cities` (id, province, city, latitude, longitude) — ۴۰۰+ شهر ایران.
- `worship_debts` (id, debtType, title, totalCount, remainingCount, dailyTarget, autoCreated, isArchived).
- `worship_seasons` (id, seasonType, title, startDate, endDate, calendar, behaviorJson, isActive, priority_weight).
- `cycle_logs` (cycleStartDate, suppressedPrayer, fastDebtCreated) — برای تشخیص قاعدگی.
- `app_settings` — کلیدهای `prayer_city_id`، `prayer_calculation_method`، `ihtiyat_minutes`.
- `pending_reminders` — دارای `snoozeUntil` (برای تعویق استفاده می‌شود).
- `alarm_scheduler_service` — برای زمان‌بندی یادآوری‌ها.

## 🔒 تصمیم‌های قطعی (تغییر نده)
1. **سه تاریخ در Hero:** شمسی + قمری + میلادی. (قمری با کتابخانه‌ی `hijri` یا محاسبه‌ی محلی.)
2. **یادآوری نماز، نه اذان:** نوتیفیکیشن متنی ساده. **با قابلیت تعویق (Snooze):** کاربر ۱۵/۳۰/۶۰ دقیقه یا زمان دلخواه به تعویق بیندازد.
3. **حداکثر ۳ بار تعویق** برای یک نماز؛ بعد فقط «خواندم» فعال.
4. **بدهی خودکار = پیشنهاد + تأیید کاربر.** هرگز بدون تأیید ثبت نشود.
5. **جهت قبله:** حذف کامل — ساخته نمی‌شود.
6. **همه‌ی یادآوری‌ها اختیاری** (پیش‌فرض نمازهای واجب روشن، بقیه خاموش).
7. **اتصال به چرخه:** اگر `isMenstruating`، نمازهای واجب امروز غیرفعال با پیام محترمانه. فردا خودکار برمی‌گردد.
8. **اتصال به بارداری:** اگر کاربر باردار، روزه غیرفعال.

---

# 🗂 صف تسک‌ها

## ▣ تسک W1 — مهاجرت دیتابیس: جدول `worship_practices` 🔴
**فایل:** `lib/core/database/database_helper.dart`
**اقدام:** نسخه را یک واحد بالا ببر. این جدول را در `onCreate` و `onUpgrade` اضافه کن:
```sql
CREATE TABLE worship_practices (
    id TEXT PRIMARY KEY,
    practiceType TEXT NOT NULL,        -- 'PRAYER' / 'MUSTAHAB' / 'QURAN' / 'DHIKR'
    subType TEXT,                      -- 'FAJR','DHUHR','ASR','MAGHRIB','ISHA' / 'NIGHT_PRAYER','NAFILAH','ZIARAT','DUA' / 'PAGE','AYAH','MINUTE' / 'TASBIH','SALAWAT','ESTEGHFAR','CUSTOM'
    title TEXT NOT NULL,
    dailyTarget INTEGER DEFAULT 1,
    dailyDone INTEGER DEFAULT 0,
    totalTarget INTEGER,
    totalDone INTEGER DEFAULT 0,
    reminderEnabled INTEGER DEFAULT 0,
    reminderTime TEXT,
    reminderOffsetMinutes INTEGER,
    deferCount INTEGER DEFAULT 0,      -- تعداد تعویق امروز (حداکثر ۳)
    lastDeferredUntil INTEGER,         -- زمان تعویق فعلی (epoch)
    sortOrder INTEGER DEFAULT 0,
    isActive INTEGER DEFAULT 1,
    notes TEXT,
    dailyDoneDate TEXT,                -- تاریخ آخرین dailyDone (برای ریست روزانه)
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL
);
CREATE INDEX idx_wp_type ON worship_practices(practiceType);
CREATE INDEX idx_wp_active ON worship_practices(isActive);
```
همچنین `app_settings` رکورد `module_religion_enabled = 'true'` (اگر نیست) و `prayer_city_id` (پیش‌فرض: تهران) را seed کن.
**تأیید:** مهاجرت پاس. **توقف کن و منتظر تأیید انسانی بمان.**

## ▣ تسک W2 — مدل‌های داده
**فایل جدید:** `lib/features/worship/models/worship_models.dart`
**اقدام:** کلاس‌های Dart:
- `WorshipPractice` — `toMap()`/`fromMap()`، `isDeferExhausted` (deferCount>=3)، `needsReset(date)` (dailyDoneDate != today → صفر شود).
- `PrayerTime` — wrapper برای `prayer_times_cache`، متد `nextPrayer(now)` (کدام نماز بعدی است)، `countdown(nextPrayer)`.
- `WorshipDebt` — `toMap()`/`fromMap()`، `progressPercent`، `daysToFinish`.
- `WorshipSeason` — `toMap()`/`fromMap()`، `isActiveNow()`.
- `HijriDate` — wrapper برای تاریخ هجری قمری. از کتابخانه‌ی `hijri` (اگر در pubspec هست) یا محاسبه‌ی محلی.
**تأیید:** analyze/test سبز.

## ▣ تسک W3 — کارت Hero اوقات شرعی + شمارش معکوس
**فایل جدید:** `lib/features/worship/presentation/widgets/prayer_times_hero.dart`
**اقدام:**
1. کارت پهن شیشه‌ای با گرادیان سحرگاه تا شب (`#F5D78A → #C4953B → #1A2744`).
2. **ردیف بالا: ۵ وقت اصلی** در نوار افقی: فجر · طلوع · ظهر · غروب · مغرب · عشا. هر کدام: نام فارسی + ساعت با ارقام فارسی + آیکون.
3. **ردیف وسط: شمارش معکوس زنده** تا نماز بعدی: «⏳ تا اذان [ظهر]: ۲ ساعت و ۱۵ دقیقه». `Timer.periodic` هر ۳۰ ثانیه. زیر ۱۵ دقیقه → برجسته‌تر. وقت نماز → «🕌 الآن وقت اذان [مغرب] است».
4. **ردیف پایین:** 📍 شهر (قابل لمس → W4) · 🗓 سه تاریخ (شمسی، قمری، میلادی).
5. خواندن داده: `PrayerTimeProvider.instance.cachePrayerTimes(...)` در `initState`، سپس از `prayer_times_cache` کوئری.
**تأیید:** شمارش معکوس زنده؛ سه تاریخ؛ analyze/test سبز.

## ▣ تسک W4 — انتخاب شهر + تنظیمات محاسبه
**فایل جدید:** `lib/features/worship/presentation/widgets/prayer_city_picker.dart`
**اقدام:**
1. شیت جست‌وجوی شهر: `TextField` جست‌وجو (نام شهر یا استان) + `ListView` فیلترشده از `iran_cities`.
2. انتخاب → `app_settings['prayer_city_id']` → `PrayerTimeProvider.cachePrayerTimes` → بازسازی W3.
3. **تنظیمات محاسبه** (در همین شیت یا از ⚙️ هدر): روش محاسبه (دانشگاه تهران / MWL / ISNA / ام‌القری) + دقایق احتیاط (اسلایدر ۰–۳۰).
**تأیید:** جست‌وجو، انتخاب شهر، بازتاب در اوقات؛ analyze/test سبز.

## ▣ تسک W5 — بخش ۱: نمازهای واجب + تعویق
**فایل جدید:** `lib/features/worship/presentation/widgets/obligatory_prayers_section.dart`
**اقدام:**
1. ۵ ردیف نماز واجب: [✅ تیک یادآوری] [نام] [ساعت امروز] ⏰ [X دقیقه قبل] [⬜ انجام].
2. **تیک یادآوری:** فعال/غیرفعال کردن `reminderEnabled`. پیش‌فرض همه روشن. ذخیره در `worship_practices`.
3. **آفست یادآوری:** قابل تنظیم per-namaz (صبح ۱۰دق، ظهر ۱۵دق، مغرب ۵دق...).
4. **چک‌باکس انجام:** تیک → `dailyDone = dailyTarget`.
5. **نوار وضعیت:** «امروز: ✅ ✅ ✅ ⬜ ⬜ — ۳ از ۵».
6. **مکانیک تعویق (Snooze):** وقتی یادآوری fire می‌شود:
   - اعلان با دو دکمه: «🕌 خواندم» / «⏰ یادآوری مجدد».
   - «یادآوری مجدد» ← دیالوگ: ۱۵ دقیقه / ۳۰ دقیقه / ۱ ساعت / زمان دلخواه.
   - ذخیره در `pending_reminders` با `snoozeUntil` + افزایش `deferCount`.
   - اگر `deferCount >= 3`: فقط «خواندم» فعال است (بدون تعویق).
   - اگر `snoozeUntil > وقت نماز بعدی`: هشدار «وقت نماز [بعدی] نزدیک است».
7. **شرط قاعدگی:** اگر `isMenstruating` → همه چک‌باکس‌ها غیرفعال + متن: «امروز نماز به دلیل عادت ماهانه واجب نیست 💜». فردا خودکار برمی‌گردد.
**تأیید:** روشن/خاموش، چک‌باکس، تعویق با محدودیت ۳ بار، حالت قاعدگی؛ analyze/test سبز.

## ▣ تسک W6 — بخش ۲: مستحبات
**فایل جدید:** `lib/features/worship/presentation/widgets/mustahab_section.dart`
**اقدام:**
1. لیست پیش‌فرض (غیرفعال): نماز شب، نافله صبح/ظهر/عصر/مغرب/عشا، نماز اول ماه، زیارت عاشورا، دعای عهد، دعای کمیل، دعای ندبه، نماز جعفر طیار.
2. هر ردیف: تیک فعال‌سازی + نام + زمان + (برای مناسبتی: «امروز پنجشنبه است»).
3. **➕ افزودن مستحب سفارشی:** نام + زمان + تکرار (روزانه/هفتگی/مناسبتی).
4. ذخیره در `worship_practices (practiceType='MUSTAHAB')`.
**تأیید:** CRUD مستحبات؛ analyze/test سبز.

## ▣ تسک W7 — بخش ۳: قرآن و ذکر
**فایل جدید:** `lib/features/worship/presentation/widgets/quran_dhikr_section.dart`
**اقدام:**
1. **هدف روزانه قرآن:** تنظیم (صفحه/آیه/دقیقه). نوار پیشرفت `████████░░ ۸ از ۱۰`. دکمه‌های ➕➖ بزرگ. روند هفتگی (نمودار میله‌ای ساده). «🎉 امروز هدفت کامل شد».
2. **شمارشگر ذکر:** لیست اذکار با دکمه‌های شمارش بزرگ (قابل لمس حین ذکر):
   - تسبیحات حضرت زهرا (الله اکبر ۳۴، الحمدلله ۳۳، سبحان الله ۳۳).
   - صلوات، استغفار.
   - **➕ افــزودن ذکر سفارشی:** نام + هدف روزانه.
3. هر ذکر: پیشرفت `dailyDone/dailyTarget` + دکمه‌ی ریست `🔄`.
4. ریست خودکار روزانه (`dailyDoneDate != today → dailyDone=0`).
5. ذخیره در `worship_practices (practiceType='QURAN'/'DHIKR')`.
**تأیید:** شمارشگر +۱، ریست روزانه، پیشرفت؛ analyze/test سبز.

## ▣ تسک W8 — بخش ۴: بدهی‌های عبادی
**فایل جدید:** `lib/features/worship/presentation/widgets/worship_debts_section.dart`
**اقدام:**
1. کارت هر بدهی: نوار پیشرفت + `daysToFinish` (پویا: «اگه روزی ۳ تا بخونی، ۲۴ روزه تموم میشه»).
2. چک‌باکس‌های امروز = `dailyTarget`. هر تیک → `remainingCount` کم شود.
3. **➕ ثبت بدهی جدید:** عنوان + نوع (نماز/روزه/کفاره) + `totalCount` + `dailyTarget`.
4. **آرشیو:** تمام‌شده‌ها → لیست جداگانه («شما توانستید تمام کنید ✅»).
5. **پیشنهاد پایان روز:** اگر نماز امروز تیک نخورده و `isMenstruating` نیست → دیالوگ ملایم: «نماز عصر و عشا امروز رو نرسیدی — می‌خوای به بدهی‌ها اضافه کنم؟» (تأیید کاربر الزامی).
**تأیید:** CRUD + محاسبه پویا + پیشنهاد پایان روز؛ analyze/test سبز.

## ▣ تسک W9 — بخش ۵: فصول عبادی
**فایل:** `lib/features/worship/presentation/widgets/worship_seasons_section.dart`
**اقدام:** منطق `WorshipSeasonsSheet` موجود را به یک ویجت بخش ارتقا بده:
1. **فصل‌های پیش‌فرض:** رمضان، محرم، ذی‌حجه، ایام‌البیض، شب‌های قدر.
2. هر فصل: عنوان + بازه تاریخ + تقویم مبنا + وزن اولویت + فعال/غیرفعال.
3. **➕ افزودن/ویرایش:** شیت (همان منطق `WorshipSeasonsSheet` با بهبود بصری).
4. **تأثیر روی RIE:** `priority_weight` فصل‌های فعال، وزن روتین‌های عبادی را در `context_engine` تغییر می‌دهد (منطق موجود).
**تأیید:** CRUD + فصل‌های پیش‌فرض؛ analyze/test سبز.

## ▣ تسک W10 — مونتاژ صفحه اصلی عبادت
**فایل:** `lib/features/worship/presentation/worship_screen.dart`
**اقدام:**
1. `Scaffold` + هدر: «عبادت» + دکمهٔ 🏙 (شهر) + ⚙️ (تنظیمات).
2. `RefreshIndicator` برای بازسازی اوقات شرعی.
3. **ساختار عمودی (ListView):**
   ```
   prayer_times_hero.dart
   menstruation_notice.dart (شرطی: زن + در قاعدگی)
   obligatory_prayers_section.dart
   mustahab_section.dart
   quran_dhikr_section.dart
   worship_debts_section.dart
   worship_seasons_section.dart
   ```
4. **کارت قاعدگی شرطی:** فقط اگر `userGender == 'FEMALE'` و `cycle_logs` نشان دهد امروز در دوره است. متن محترمانه: «امروز نماز و روزه به دلیل عادت ماهانه واجب نیست 💜».
5. **تنظیمات ⚙️:** شیت با روش محاسبه + دقایق احتیاط + آفست‌های یادآوری.
**تأیید:** صفحه کامل با همه بخش‌ها + شرط‌ها؛ analyze/test سبز.

## ▣ تسک W11 — یکپارچگی AI (دستیار عبادی)
**فایل:** شیت جدید `ai_worship_assistant_sheet.dart`
**اقدام:** دکمهٔ 🤖 در هدر عبادت.
**عملکردهای مجاز AI:**
1. «چه سوره‌ای امروز بخونم؟» — پیشنهاد سوره بر اساس روز هفته/مناسبت.
2. «برنامه ختم قرآن تو ۳ ماه بچین» — محاسبه صفحات/روز.
3. «چند تا نماز قضا دارم، چجوری جبران کنم؟» — برنامه‌ی تدریجی.
**ممنوعات:** تفسیر قرآن، فتوا، توصیه‌ی فقهی، قضاوت دربارهٔ عبادت کاربر.
**تأیید:** سه عملکرد بالا کار کنند؛ analyze/test سبز.

## ▣ تسک W12 — پرداخت بصری + تست نهایی
**فایل:** همهٔ `lib/features/worship/`
**اقدام:**
1. رنگ‌ها: کهربایی-طلایی `#D4A843`، گرادیان Hero، بک‌گراند گرم `#FFF8EC` (روشن) / `#1E1E2C` (تاریک).
2. RTL + ارقام فارسی. فاصله‌گذاری مضارب ۸. حداقل لمسی ۴۸dp.
3. `flutter analyze` → بدون error/warning جدید.
4. `flutter test` → همه سبز + **تست‌های جدید:** شمارش معکوس، تعویق (max 3)، ریست روزانه ذکر، `daysToFinish` بدهی، تاریخ هجری، شرط قاعدگی.
5. `flutter run -d chrome` + تست دستی کل فلو.
6. `DESIGN_SYSTEM_WORSHIP.md` را به‌روز کن.
**تأیید:** همه سبز.

---

## 📤 قالب گزارش (بعد از هر تسک)
```
## تسک [W?]: [عنوان]
- فایل‌ها: ...
- خلاصه: ...
- flutter analyze: [قبل → بعد]
- flutter test: [N passed, M failed]
- وضعیت: ✅ / ⚠️ / ❌
```
**یادآوری: بعد از W1 توقف کن و منتظر تأیید انسانی بمان.**
