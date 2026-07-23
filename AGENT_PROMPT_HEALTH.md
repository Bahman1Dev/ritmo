# 🤖 پرامپت اجرایی — ارتقای سیستم «دارو و سلامت» (Health) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. کلِ صفِ H1 تا H10 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: ارتقای سلامت از سیستمِ «فقط ثبت/خواندن» به **مربیِ کاملِ سلامت** — افزودنِ لایه‌ی تحلیلی (روند/پایبندی/همبستگی/خلاصه برای پزشک) روی استخوان‌بندیِ بالغِ موجود، **بدونِ شکستنِ هیچ‌چیز**.
> سندِ طراحی: `DESIGN_SYSTEM_HEALTH.md`.
> ⚠️ این صفحه قبلاً **ساخته شده** (۱۰ بخشِ کاری، هشدارهای بحرانی، دستیارِ AI). این یک ارتقای **افزودنی** است، نه ساختِ از صفر. هیچ بخشِ موجود را بازنویسی/حذف نکن.

## ⛔️ قواعد (یک‌بار)
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (`shamsi_date`؛ ذخیره ISO/epoch، نمایش شمسی). l10n جدید به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ `RitmoTheme`/`context.colors`. رنگِ پایه: قرمز `#EF4444`.
- داده‌ی دیتابیس تستی است؛ ستون‌های جدید nullable/با `DEFAULT`.
- فقط فایل‌های مرتبطِ هر تسک. ابهامِ واقعی → بپرس.
- **این‌ها را نشکن:** هشدارهای بحرانی (قند/فشار/۵-۱-۱/موجودیِ دارو)، منطقِ PRN و overdose (`medical_engine.dart` + `prn_logs`)، ماژولِ بارداری (`userGender=='FEMALE'` + `module_pregnancy_enabled`)، زمان‌بندیِ یادآور (`alarm_scheduler_service`/`pending_reminders`)، گیتِ `module_medicine_enabled`، و شیتِ دستیارِ AI با حفاظِ پزشکی + OCRِ موک.
- **هرگز تشخیص/تجویز.** متنِ تحلیلی غیرقطعیِ علّی؛ هشدارها «به پزشک مراجعه کن».
- **محرمانگیِ چرخه:** صفحه‌ی سلامت هیچ ارجاعِ صریح به پریود/قاعدگی/تخمک‌گذاری ندارد و هیچ همبستگیِ سلامت↔چرخه اینجا ساخته نمی‌شود.
- AI هرگز مستقیم در DB نمی‌نویسد (Preview→Edit→Save).

## 🔒 تصمیم‌های قطعی
1. **مربیِ کاملِ سلامت:** روندِ علائم + پایبندیِ دارو + همبستگی + خلاصه‌ی آماده برای پزشک + همان هشدارها.
2. **جدولِ جدیدِ `medication_logs`** برای داروهای **زمان‌بندی‌شده** (taken/skipped). داروهای **PRN** همچنان در `prn_logs` موجود ثبت می‌شوند (تکراری نساز). موتورِ پایبندی از هر دو می‌خواند.
3. **OCR دست‌نخورده** (موکِ صادق)؛ فقط برچسبش صادقانه «آزمایشی/به‌زودی» شود.

## 📁 محیط (تأییدشده از کد)
- DB SQLite، **نسخه‌ی فعلی = ۲۰**؛ مهاجرت = **۲۱** (`_migrateToV21` + `if (oldVersion < 21)` + هم‌تراز در `_createDB`). `_safeAddColumn(db, table, column, typeDef)` موجود است.
- داروها: ردیف‌های `routines` با `category='medical'`/`'MEDICAL'`، ستون‌های `medStockCount`/`medRefillThreshold`/`minIntervalHours`/`maxDosesPerDay`. منطقِ موجودی/PRN/overdose در `lib/core/domain/engines/medical_engine.dart` (`checkOverdoseStatus`/`isRefillNeeded`) — **نشکن، فقط استفاده کن**.
- **`prn_logs (id, routineId, takenAt, dosage, createdAt)` موجود است** و داروهای PRN را لاگ می‌کند (`medications_section.dart` در آن insert می‌کند). نشکن؛ موتور از آن برای پایبندیِ PRN می‌خواند.
- علائم: `blood_sugar_logs(value,measurementType,loggedAt)`، `blood_pressure_logs(systolic,diastolic,pulse,loggedAt)`، `vital_signs_logs(vitalType,value,unit,loggedAt)` — V11. فقط برای خواندنِ روند.
- نوبت: `doctor_visits(...)` — برای خلاصه‌ی آماده.
- آستانه‌ها: تنظیماتِ `patient_has_diabetes`/`patient_has_hypertension` موجودند؛ برای «درصدِ در محدوده» استفاده کن.
- `energy_logs` و خواب (`bedtime_diagnostics`/V17) — فقط برای همبستگی.
- صفحه: `lib/features/health/presentation/health_screen.dart` (۱۰ بخشِ بازشونده + بنرِ هشدار + FABِ دستیار). مدل‌ها: `lib/features/health/models/health_models.dart`. بخشِ دارو: `lib/features/health/presentation/widgets/medications_section.dart`. دستیار: `widgets/ai_health_assistant_sheet.dart`.
- کاشیِ هاب «دارو» در `systems_hub_screen.dart` (~خط ۲۶۹): `bandage_fill`, `#EF4444`, گیتِ `module_medicine_enabled`, `HealthScreen` — دست‌نخورده.
- الگوی موتور: `CachedEngine` (calculate/invalidate/canRun/dependencies) + `RitmoEngineBus`. مرجع: `lib/core/analytics/courses_engine.dart`.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**H1 — مهاجرت.** نسخه ۲۰→۲۱. جدولِ `medication_logs (id TEXT PK, routineId TEXT NOT NULL, scheduledTime INTEGER, takenTime INTEGER, status TEXT NOT NULL DEFAULT 'TAKEN', note TEXT, createdAt INTEGER NOT NULL, FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE)` + ایندکس‌های `idx_medlog_routine(routineId)`/`idx_medlog_time(scheduledTime)`. هم در `_migrateToV21` و هم هم‌تراز در `_createDB`. تنظیماتِ جدید با `INSERT OR IGNORE`: `health_adherence_enabled='true'`, `health_trend_window_days='30'`.

**H2 — مدل‌ها** (`lib/features/health/models/health_models.dart` — افزودن، نه حذف):
- `MedicationLog {id, routineId, scheduledTime, takenTime, status(TAKEN|SKIPPED), note, createdAt}` (toMap/fromMap روی `medication_logs`).
- `TrendPoint {dateIso, value}` و `VitalTrend {metric, points, average, direction(up|down|stable), inRangePercent}`.
- `AdherenceStats {adherenceRate(double), currentStreak, longestStreak, missedPattern(String?)}`.
- `HealthCorrelation {metric, coefficient(double?), insight}`.
- `DoctorVisitSummary {generatedAtIso, medications, lastVitals(Map), trends, allergies, recentSymptoms}` (مدلِ ساده برای متنِ خلاصه).

**H3 — موتورِ سلامت** (`lib/core/analytics/health_engine.dart`, `CachedEngine`):
- ورودی: `blood_sugar_logs`, `blood_pressure_logs`, `vital_signs_logs`, `medication_logs`, `prn_logs`, داروهای `routines`, `energy_logs`, خواب, `today`, `windowDays`.
- خروجی: `List<VitalTrend>` (قند/سیستول/دیاستول/وزن/SpO2 با میانگین/جهت/درصدِ در محدوده با آستانه‌های دیابت/فشار)، `AdherenceStats` (زمان‌بندی‌شده از `medication_logs`، PRN از `prn_logs`)، `List<HealthCorrelation>` (فشار/قند ↔ انرژی/خواب؛ در [-1..1]، کم‌داده→null) + هشدارهای روندی (میانگینِ بازه‌ی اخیر vs قبل).
- منطقِ خالص (روند/جهت/پایبندی/استریک/همبستگی) در helperِ تست‌پذیر. **فقط‌خواندنی.**
- تست: روندِ صعودی/نزولی/پایدار، درصدِ در محدوده، پایبندیِ ۱۰۰٪/جزئی/استریکِ گسسته، همبستگیِ مثبت/منفی/کم‌داده.

**H4 — ثبتِ دوزِ زمان‌بندی‌شده** (در `medications_section.dart` یا `widgets/medication_log_action.dart`): کنارِ هر داروی زمان‌بندی‌شده‌ی فعال، دو دکمه‌ی «خوردم»/«رد کردم» → رکورد در `medication_logs` (status + scheduledTime + takenTime). **داروهای PRN را تغییر نده** — مسیرِ موجود (`prn_logs` + `checkOverdoseStatus`) دست‌نخورده بماند. شمارشِ موجودیِ موجود (`medStockCount`) را نشکن.

**H5 — نمودارِ روندِ علائم** (`widgets/health_trends_section.dart`): برای قند/فشار/وزن نمودارِ خطی در بازه (CustomPainter، بدونِ پکیجِ جدید) + خطِ محدوده‌ی سالم + برچسبِ جهتِ روند + درصدِ در محدوده. انتخابِ متریک (چیپ).

**H6 — کارتِ پایبندیِ دارو** (`widgets/adherence_card.dart`): `adherenceRate` (حلقه/درصد) + استریک + الگوی فراموشیِ ملایم («عصرها بیشتر فراموش می‌شود») از موتور. لحنِ بدونِ سرزنش.

**H7 — بخشِ همبستگی** (`widgets/health_correlation_section.dart`): `HealthCorrelation`‌ها + insightِ صادق و غیرقطعی. «روزهایی که بهتر می‌خوابی، فشارت معمولاً پایین‌تره». هیچ ارجاعِ چرخه.

**H8 — خلاصه‌ی آماده برای پزشک** (`widgets/doctor_visit_summary_sheet.dart`): از کارتِ نوبتِ پزشک یا دکمه‌ی مستقل، متنِ خلاصه‌ی قابلِ‌کپی/اشتراک تولید کن: داروهای فعال + آخرین قند/فشار/وزن + روندها + آلرژی‌ها + علائمِ اخیر. Copy + Share (از پکیجِ موجود اگر هست، وگرنه `Clipboard`). بدونِ پکیجِ سنگینِ جدید.

**H9 — مونتاژ + دستیار** (`health_screen.dart` + `ai_health_assistant_sheet.dart`): بخش/تبِ «روند و تحلیل» شاملِ H5+H6+H7 به صفحه اضافه شود (ساختارِ ۱۰‌بخشیِ موجود و بنرِ هشدار و FAB نشکنند). بافتِ دستیار با خلاصه‌ی روند/پایبندی غنی شود (همان حفاظِ پزشکی و OCRِ موک). برچسبِ OCR را صادقانه «آزمایشی» کن.

**H10 — پایان.** مطمئن شو هشدارهای بحرانی، منطقِ PRN/overdose، ماژولِ بارداری، یادآورها (`alarm_scheduler_service`/`pending_reminders`)، و گیتِ `module_medicine_enabled` سالم‌اند؛ هیچ ارجاع/همبستگیِ صریحِ چرخه در صفحه نیست؛ AI مستقیم در DB نمی‌نویسد. اگر چیزی تغییر کرد `DESIGN_SYSTEM_HEALTH.md` را به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: موتورِ سلامت (روند/جهت/درصدِ در محدوده/پایبندی/استریک/همبستگی/کم‌داده)، مهاجرتِ نصبِ‌تازه≡ارتقا (`medication_logs` در هر دو مسیر)، ثبتِ دوز (TAKEN/SKIPPED).
- دستی: بازکردن از هاب → ثبتِ دوزِ زمان‌بندی‌شده (و سالم‌بودنِ مسیرِ PRN) → دیدنِ پایبندی/استریک → نمودارِ روندِ قند/فشار/وزن → همبستگی → تولیدِ خلاصه برای پزشک (کپی/اشتراک) → سالم‌بودنِ هشدارهای بحرانی و ماژولِ بارداری → نبودِ ارجاعِ چرخه.

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی H1..H10: ...
- نسخه‌ی مهاجرت: 21
- flutter analyze / flutter test: ...
- بازبینیِ سلامتِ هشدارها/PRN/بارداری/یادآورها + نبودِ ارجاعِ چرخه: ...
- ابهامات: ...
```
