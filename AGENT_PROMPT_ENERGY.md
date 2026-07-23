# 🤖 پرامپت اجرایی — سیستم «انرژی و حال روحی» (Energy & Mood) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. کلِ صفِ E1 تا E11 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: ساختِ صفحه‌ی اختصاصیِ انرژی و حال روی موتورِ تحلیلِ موجود — ثبتِ سریعِ هر‌زمان، حال به‌عنوان محورِ مستقل، رونماییِ تحلیل‌ها، روند/همبستگی، و دستیار.
> سندِ طراحی: `DESIGN_SYSTEM_ENERGY.md`. فایلِ اصلیِ جدید: `lib/features/energy/presentation/energy_mood_screen.dart`.

## ⛔️ قواعد (یک‌بار)
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (`shamsi_date`؛ ذخیره ISO/epoch، نمایش شمسی). l10n جدید به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ `RitmoTheme`/`context.colors`. رنگِ پایه: صورتی `#EC4899`.
- لحنِ تشویقی و بدونِ قضاوت؛ حالِ بد هرگز «اشتباه» نیست. توضیحِ علّی شفاف بماند («چرا این عدد؟»).
- داده‌ی دیتابیس تستی است؛ ستون‌های جدید با `DEFAULT`.
- فقط فایل‌های مرتبطِ هر تسک. ابهامِ واقعی → بپرس.
- **`EnergyAnalyticsEngine` و `energy_logs` را تغییر نده** (RIE به آن‌ها وابسته است). انرژی همان‌جا می‌ماند؛ فقط مصرف/نمایش اضافه می‌شود.

## 🔒 قیدِ محرمانگیِ چرخه (هرگز نقض نشود)
- در کلِ این صفحه و دستیار، **هیچ اشاره‌ی مستقیمی به قاعدگی/چرخه/پریود نشود.**
- اگر تعدیلِ انرژی از چرخه می‌آید، فقط از مسیرِ `lib/core/utils/cycle_consent_bridge.dart` و با لحنِ غیرمستقیم («بر اساس ریتمِ بدنی‌ات...»).
- برای کاربرِ مرد یا وقتی `cycle_consent_energy` خاموش است، هیچ ردّی دیده نشود. هیچ کوئریِ مستقیمی به جداولِ چرخه نزن — فقط از طریقِ Bridge.

## 🔒 تصمیم‌های قطعی
1. **دو محورِ مستقل + همبستگی:** انرژی (کم/متوسط/زیاد) و حال (احساس + خوشاییِ ۱..۵)، جدا ثبت، با تحلیلِ همبستگیِ صادق (مجاورتِ زمانی).
2. **ثبتِ سریعِ هر‌زمان** («الان چطورم؟») — چند ثبت در روز؛ منحنیِ انرژیِ روز.
3. **داشبوردِ تحلیلیِ کامل + دستیار** (اوج/خستگی/روزِ پربار + روند + همبستگی + AI).
4. **AI فقط دستیار:** توضیح/پیشنهاد، بدونِ نوشتنِ کور؛ قیدِ چرخه رعایت شود.

## 📁 محیط (تأییدشده از کد)
- دیتابیس SQLite؛ نسخه‌ی فعلی را بخوان، مهاجرت = فعلی+۱ (از `_safeAddColumn` و الگوی موجود؛ هم `_createDB` هم `onUpgrade`).
- `energy_logs (id, energyLevel[HIGH/MEDIUM/LOW], source['MANUAL'], note, loggedAt)`.
- `daily_checkins (id, date UNIQUE, mood, note, createdAt)` و `daily_reflections (… mood_score …)` — دست‌نخورده.
- `morning_checkin_sheet.dart` — مرجعِ نگاشتِ حال→انرژی و نوشتنِ `default_energy_level` (بازاستفاده کن، نشکن).
- `EnergyAnalyticsEngine` (`lib/core/analytics/energy_analytics_engine.dart`) — خروجی: `currentDynamicEnergy`, `currentDynamicEnergyExplanations`, `peakPerformanceWindow`, `mostProductiveWeekday`, `mostFatiguedWindow`. ورودی: energyLogs/routineCompletions/dailyRhythm/sleepDiagList/now. مرجعِ امضای `CachedEngine` (calculate/invalidate/canRun/dependencies).
- `RitmoEngineBus` + `insights_screen.dart` — الگوی فراخوانیِ موتور.
- `systems_hub_screen.dart` — کاشیِ «انرژی و حالت روحی» الان `_showComingSoonSheet(...)` است؛ باید مثل کنکور به صفحه + `_showActivationSheet(settingKey:'module_energy_enabled')` وصل شود.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**E1 — مهاجرت.** نسخه +۱. جدولِ جدید:
```sql
CREATE TABLE mood_logs (
  id TEXT PRIMARY KEY,
  mood TEXT NOT NULL,            -- CALM/HAPPY/ANXIOUS/SAD/ANGRY/TIRED/EXCITED/NEUTRAL/...
  valence INTEGER NOT NULL DEFAULT 3,  -- 1..5 (خوشاییِ ناخوشایند→خوشایند)
  note TEXT,
  loggedAt INTEGER NOT NULL
);
CREATE INDEX index_mood_logs_loggedAt ON mood_logs(loggedAt);
```
هم در `_createDB` هم در تابعِ مهاجرت (با `IF NOT EXISTS`). کلیدِ تنظیمات با `INSERT OR IGNORE`: `module_energy_enabled='false'`. (`energy_logs` را تغییر نده.)

**E2 — مدل‌ها** (`lib/features/energy/models/energy_mood_models.dart`):
- `enum EnergyLevel { low, medium, high }` + `label`/`fromString`/`score`(LOW=30/MED=65/HIGH=100) هماهنگ با موتور.
- `enum Mood { calm, happy, anxious, sad, angry, tired, excited, neutral }` + `label` فارسی + `emoji` + `defaultValence`(۱..۵).
- `MoodLog` (toMap/fromMap) و `EnergyLog` (نمای fromMap روی energy_logs).
- `QuickLogResult` (energyLevel?, mood?, valence?, note?).

**E3 — موتورِ حال + همبستگی** (`lib/core/analytics/mood_engine.dart`, `CachedEngine`):
- ورودی: moodLogs, energyLogs, today, horizonDays.
- خروجی: `dominantMood`, `moodTrend`(valence در روزهای متوالی), `moodByDaypart`(صبح/ظهر/عصر/شب)، `energyMoodCorrelation`(double در [-1..1] از جفت‌کردنِ لاگ‌ها بر اساس مجاورتِ زمانی؛ اگر داده کم بود null)، `correlationInsight`(متنِ صادق و غیرمستقیم).
- تست: همبستگیِ مثبت/منفی/کم‌داده.

**E4 — ثبتِ سریع** (`lib/features/energy/presentation/widgets/quick_log_sheet.dart`): «الان چطورم؟» — انتخابِ سطحِ انرژی (۳ سطح/اسلایدر) + احساس (شبکه‌ی ایموجی) + valence + یادداشت. ذخیره → `energy_logs` (اگر انرژی انتخاب شد) + `mood_logs` (اگر حال انتخاب شد) + به‌روزرسانیِ `default_energy_level`. کاربر می‌تواند فقط یکی را ثبت کند. منطقِ نگاشت را از `morning_checkin_sheet` وام بگیر.

**E5 — هیرو** (`lib/features/energy/presentation/widgets/energy_hero.dart`): انرژیِ پویای فعلی (٪) از `EnergyAnalyticsEngine` + چیپ‌های `currentDynamicEnergyExplanations` («چرا این عدد؟») + حالِ فعلی (آخرین `mood_logs`). دکمه‌ی «الان چطورم؟».

**E6 — تبِ امروز** (`widgets/energy_today_section.dart`): منحنیِ انرژیِ درون‌روزیِ امروز از `energy_logs` (CustomPainter ساده، بدونِ پکیجِ جدید) + فهرستِ لاگ‌های حالِ امروز + وضعیتِ کنونی با توضیح.

**E7 — تبِ الگوها** (`widgets/energy_patterns_section.dart`): `peakPerformanceWindow`، `mostProductiveWeekday`، `mostFatiguedWindow` از موتور، با کارت‌های تشویقی. اگر داده کافی نبود، پیامِ «هنوز در حالِ یادگیریِ الگوهای توام 🌿».

**E8 — تبِ روند** (`widgets/energy_trends_section.dart`): انرژی و حال در چند هفته (نمودارِ ساده) + احساسِ غالب + بینشِ `energyMoodCorrelation`/`correlationInsight` (صادق، غیرمستقیم).

**E9 — مونتاژ + هاب** (`energy_mood_screen.dart` + `systems_hub_screen.dart`): Scaffold+rtl، هدر «انرژی و حال روحی»+[🤖]، `RefreshIndicator`، هیرو + تب‌ها (امروز·الگوها·روند) + FABِ ثبتِ سریع. در هاب: کاشی را از «به‌زودی» به الگوی ماژول ببر (import، حذفِ `_showComingSoonSheet`/`customText`، اگر `module_energy_enabled` → push وگرنه `_showActivationSheet(settingKey:'module_energy_enabled')`).

**E10 — دستیار AI** (`widgets/ai_energy_assistant_sheet.dart`): دکمه‌ی 🤖. توضیحِ غیرمستقیمِ الگوها + پیشنهادِ ملایم (چیدنِ کارهای سنگین در اوج، سبک در خستگی). از `AiGateway` موجود. **قیدِ چرخه و عدمِ نوشتنِ کور رعایت شود؛ Preview→Edit→Save برای هر پیشنهادِ قابلِ‌اعمال.**

**E11 — پایان.** قیدِ چرخه را در کلِ صفحه بازبینی کن (هیچ ارجاعِ مستقیم). `DESIGN_SYSTEM_ENERGY.md` را اگر چیزی تغییر کرد به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: موتورِ حال (همبستگی/غالب/روند)، مهاجرتِ نصبِ‌تازه≡ارتقا، ثبتِ سریع (نوشتنِ هر دو/یکی).
- دستی: فعال‌سازی از هاب → چند ثبتِ سریعِ روز → منحنیِ انرژی → الگوها → روند/همبستگی → نبودِ هرگونه اشاره‌ی مستقیمِ چرخه (با کاربرِ مرد و زن).

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی E1..E11: ...
- نسخه‌ی مهاجرت: ...
- flutter analyze / flutter test: ...
- بازبینیِ قیدِ چرخه: ...
- ابهامات: ...
```
