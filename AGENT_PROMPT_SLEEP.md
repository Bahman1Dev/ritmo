# 🤖 پرامپت اجرایی — سیستم «خواب و بیداری» (Sleep) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. کلِ صفِ S1 تا S11 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: ساختِ صفحه‌ی اختصاصیِ خواب روی جدولِ موجود — هدف‌گذاری + ثبتِ صبحگاهی، بدهیِ خواب، ثبات، روند، همبستگی با انرژی/حال، روزشمار + یادآور، و دستیار.
> سندِ طراحی: `DESIGN_SYSTEM_SLEEP.md`. فایلِ اصلیِ جدید: `lib/features/sleep/presentation/sleep_screen.dart`.

## ⛔️ قواعد (یک‌بار)
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (`shamsi_date`؛ ذخیره ISO/epoch، نمایش شمسی). l10n جدید به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ `RitmoTheme`/`context.colors`. رنگِ پایه: بنفش `#8B5CF6`. آیکن: `CupertinoIcons.moon_stars_fill`.
- لحنِ تشویقی و بدونِ قضاوت؛ خوابِ بد هرگز «شکست» نیست. روزشمار آرام، نه مضطرب. توضیحِ علّی شفاف بماند.
- داده‌ی دیتابیس تستی است؛ ستون‌های جدید با `DEFAULT`.
- فقط فایل‌های مرتبطِ هر تسک. ابهامِ واقعی → بپرس.
- **`EnergyAnalyticsEngine` و `energy_logs`/`mood_logs` را تغییر نده.** خواب فقط آن‌ها را می‌خواند؛ چیزی در آن‌ها نمی‌نویسد.
- **هیچ ارجاعی به چرخه/قاعدگی** در این صفحه نیاید (محرمانه و خارج از این سیستم).

## 🔒 پلِ موتورِ انرژی (نباید بشکند)
`EnergyAnalyticsEngine.calculateDynamicEnergy` از `bedtime_diagnostics` ستون‌های `reason`/`note` را می‌خواند و اگر کلیدواژه‌ی خوابِ بد (`ضعیف/کم/دیر/خستگی/بی‌خوابی/poor/late/bad/restless/tired/insomnia`) ببیند، **−۱۵٪** اعمال می‌کند. پس هنگامِ ثبت، **همیشه `reason`/`note` را هم پر کن** متناسب با کیفیت/مدت:
- کیفیت ۱–۲ یا مدتِ خیلی‌کم → `reason` شاملِ «ضعیف» یا «کم».
- کیفیتِ خوب → `reason` بدونِ کلیدواژه‌ی بد.
این تنها راهِ زنده‌کردنِ آن پل بدونِ دست‌زدن به موتور است.

## 🔒 تصمیم‌های قطعی
1. **مربیِ کاملِ خواب:** هدف + بدهیِ خواب + ثبات + کیفیت + روند + همبستگی با انرژی/حال + دستیار.
2. **هدف‌گذاری + ثبتِ صبحگاهی:** هدف یک‌بار تنظیم می‌شود؛ هر صبح واقعیتِ دیشب ثبت → برنامه در برابر واقعیت.
3. **یادآورِ آرام + روزشمارِ هدف:** روزشمارِ درون‌برنامه‌ای تا زمانِ خوابِ هدف + یادآورِ ملایمِ wind-down (اختیاری).
4. **AI فقط دستیار:** توضیح/پیشنهاد، Preview→Edit→Save، بدونِ نوشتنِ کور.

## 📁 محیط (تأییدشده از کد)
- دیتابیس SQLite؛ نسخه‌ی فعلی **۱۶** است → مهاجرت **v17** (هم `_createDB` هم `onUpgrade` با `_safeAddColumn`).
- `bedtime_diagnostics (date TEXT PK, reason TEXT NOT NULL, note TEXT, createdAt INTEGER)` — موجود. (`reason` NOT NULL است؛ همیشه مقدار بده.)
- `energy_logs (id, energyLevel[HIGH/MEDIUM/LOW], source, note, loggedAt)` و `mood_logs (id, mood, valence 1..5, note, loggedAt)` — برای همبستگی فقط **خوانده** می‌شوند.
- `EnergyAnalyticsEngine` (`lib/core/analytics/energy_analytics_engine.dart`) — مصرف‌کننده‌ی `bedtime_diagnostics`؛ دست‌نخورده.
- `morning_checkin_sheet.dart` — مرجعِ نگاشتِ کیفیت/حال→انرژی (بازاستفاده کن، نشکن).
- `CachedEngine` (calculate/invalidate/canRun/dependencies) + `RitmoEngineBus` — مرجع: `courses_engine.dart` / `mood_engine.dart`.
- `systems_hub_screen.dart` — کاشیِ «خواب و بیداری» الان `_showComingSoonSheet(...)` با `customText:'به‌زودی'` و رنگِ `#8B5CF6` است؛ باید مثل کنکور/اهداف به صفحه + `_showActivationSheet(settingKey:'module_sleep_enabled')` وصل شود (الگوی `_handleKonkurTap`، state flag، `_loadAllData`).

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**S1 — مهاجرت.** نسخه را به v17 ببر. `bedtime_diagnostics` را با `_safeAddColumn` گسترش بده:
```
bedtimeAt INTEGER, wakeAt INTEGER, durationMinutes INTEGER,
quality INTEGER NOT NULL DEFAULT 3, awakenings INTEGER NOT NULL DEFAULT 0
```
همان ستون‌ها را در تعریفِ `_createDB` هم‌تراز کن. تنظیمات با `INSERT OR IGNORE`:
`module_sleep_enabled='false'`, `sleep_target_bedtime='23:30'`, `sleep_target_wake='07:00'`, `sleep_target_duration_minutes='450'`, `sleep_winddown_reminder='false'`, `sleep_winddown_minutes='30'`, `sleep_setup_done='false'`.

**S2 — مدل‌ها** (`lib/features/sleep/models/sleep_models.dart`):
- `enum SleepQuality { terrible, poor, fair, good, excellent }` (۱..۵) + `label` فارسی + `emoji` + `score`/`fromInt`.
- `SleepLog` (toMap/fromMap روی bedtime_diagnostics؛ getterهای `durationFromTimes`، `isOnTarget`، `deviationMinutes`).
- `SleepTarget` (bedtime HH:mm، wake HH:mm، durationMinutes) از تنظیمات + parse/format.

**S3 — موتورِ خواب** (`lib/core/analytics/sleep_engine.dart`, `CachedEngine`):
- ورودی: sleepLogs, target, energyLogs, moodLogs, today, horizonDays.
- خروجی: `lastNight`, `avgDurationMinutes`, `avgQuality`, `sleepDebtMinutes` (جمعِ کسری نسبت به مدتِ هدف در پنجره)، `consistencyScore` (۰..۱۰۰ از پراکندگیِ ساعتِ خواب/بیداری)، `durationTrend`/`qualityTrend`، `bestBedtimeWindow` (ساعتِ خواب با بهترین انرژی/حالِ فردا)، `sleepEnergyCorrelation`/`sleepMoodCorrelation` (در [-1..1]؛ جفت‌کردنِ خوابِ هر شب با انرژی/حالِ فردا؛ کم‌داده→null) + `correlationInsight` (صادق، غیرمستقیم).
- منطقِ خالصِ بدهی/ثبات/همبستگی در helperِ تست‌پذیر. تست: بدهی، ثبات، همبستگیِ مثبت/منفی/کم‌داده.

**S4 — شیتِ ثبتِ دیشب** (`lib/features/sleep/presentation/widgets/sleep_log_sheet.dart`): ساعتِ خواب + ساعتِ بیداری (مدت خودکار) + کیفیت (ایموجیِ ۱..۵) + بیدارشدن‌ها + یادداشت. ذخیره در `bedtime_diagnostics` با `date`ِ شبِ مربوطه (INSERT OR REPLACE روی PK)، ستون‌های ساختاریافته **و** `reason`/`note`ِ مشتق (پلِ موتور). به‌روزرسانیِ `default_energy_level` با همان نگاشتِ `morning_checkin_sheet`.

**S5 — شیتِ هدف‌گذاری** (`widgets/sleep_target_sheet.dart`): ساعتِ خوابِ هدف + بیداریِ هدف + مدتِ هدف (خودکار از اختلاف، قابلِ‌تنظیم) + کلیدِ یادآورِ wind-down + دقیقه‌ی wind-down → نوشتن در تنظیمات، `sleep_setup_done='true'`. این شیت در اولین فعال‌سازی از هاب باز می‌شود.

**S6 — هیرو** (`widgets/sleep_hero.dart`): خلاصه‌ی دیشب (مدتِ بزرگ + کیفیت + چیپِ «به هدف رسیدی»/«۴۰ دقیقه کم») + **روزشمارِ آرام تا زمانِ خوابِ هدف** + دکمه‌ی «ثبتِ خوابِ دیشب». اگر دیشب ثبت نشده: دعوتِ ملایم به ثبت.

**S7 — تبِ دیشب** (`widgets/sleep_last_night_section.dart`): جزئیاتِ دیشب + **برنامه در برابر واقعیت** (هدف vs واقعی، انحراف) + هدفِ امشب + کلیدِ یادآورِ wind-down (روشن/خاموش).

**S8 — تبِ الگوها** (`widgets/sleep_patterns_section.dart`): `consistencyScore`، `avgDurationMinutes`، `sleepDebtMinutes` (با لحنِ تشویقی)، `bestBedtimeWindow`. کم‌داده → «هنوز در حالِ یادگیریِ الگوی خوابتم 🌙».

**S9 — تبِ روند** (`widgets/sleep_trends_section.dart`): مدت/کیفیت در چند هفته (CustomPainterِ ساده، بدونِ پکیجِ جدید) + بینشِ `sleepEnergyCorrelation`/`sleepMoodCorrelation`/`correlationInsight` (صادق، غیرمستقیم).

**S10 — مونتاژ + هاب** (`sleep_screen.dart` + `systems_hub_screen.dart`): Scaffold+rtl، هدر «خواب و بیداری»+[🤖]، `RefreshIndicator`، هیرو + تب‌ها (دیشب·الگوها·روند) + FABِ «ثبتِ خوابِ دیشب». در هاب: کاشی را از «به‌زودی» به الگوی ماژول ببر (import، state flag `_sleepEnabled` در `_loadAllData`، حذفِ `_showComingSoonSheet`/`customText`، اگر `module_sleep_enabled` → push وگرنه `_showActivationSheet(settingKey:'module_sleep_enabled', onActivated: openSleepTargetSheet→push)`). وضعیتِ کاشی از همان flag.

**S11 — دستیار + یادآور + پایان.**
- `widgets/ai_sleep_assistant_sheet.dart`: دکمه‌ی 🤖، مربیِ خواب — توضیحِ غیرمستقیمِ الگوها + پیشنهادِ ملایم (wind-down زودتر، ساعتِ بیداریِ ثابت). از `AiGateway` موجود، Preview→Edit→Save.
- **یادآورِ wind-down:** اگر زیرساختِ نوتیفیکیشنِ محلیِ موجود در پروژه باشد، یک یادآورِ آرام در «زمانِ خواب منهای دقیقه‌ی wind-down» زمان‌بندی کن؛ اگر نبود، فقط روزشمارِ درون‌برنامه‌ای بماند (پکیجِ جدیدِ سنگین اضافه نکن). 
- بازبینیِ نهایی: هیچ ارجاعِ چرخه، پلِ موتور سالم. اگر چیزی تغییر کرد `DESIGN_SYSTEM_SLEEP.md` را به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: موتورِ خواب (بدهی/ثبات/همبستگی)، مهاجرتِ نصبِ‌تازه≡ارتقا، ثبتِ دیشب (نوشتنِ ساختاریافته + پلِ `reason`/`note`).
- دستی: فعال‌سازی از هاب → هدف‌گذاری → ثبتِ چند شب → روزشمار → الگوها (بدهی/ثبات) → روند/همبستگی → اطمینان از فعال‌شدنِ جریمه‌ی −۱۵٪ انرژی بعد از ثبتِ خوابِ ضعیف → نبودِ هرگونه ارجاعِ چرخه.

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی S1..S11: ...
- نسخه‌ی مهاجرت: ...
- flutter analyze / flutter test: ...
- صحتِ پلِ موتورِ انرژی (reason/note): ...
- ابهامات: ...
```
