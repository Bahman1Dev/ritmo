# گزارش اجرای پرامپت ۰۲۴ — لایهٔ حرکت (Movement Layer)

---

## 🟢 خلاصهٔ دستاوردها

پیوسته‌سازی سیستم ورزش ریتمو از «تمرین قدرتی صرف» به **«سیستم‌عامل جامع فعالیت‌های حرکتی (Movement Layer)»** با موفقیت کامل انجام شد.

### ۱. زیرساخت و دیتابیس (فاز ۰)
- **مهاجرت Schema V53**:
  - جدول `movement_kinds` (تاکسونومی ورزش‌ها شامل ~۳۸ نوع استاندارد در ۷ خانواده)
  - ستون‌های تکمیلی `workout_logs` (شامل `kind`, `distanceMeters`, `elevationMeters`, `laps`, `steps`, `metMinutes`, `caloriesKcal`, `venue`, `companions`, `sourceModule`)
  - ستون‌های تکمیلی `routines` (`movementKind`, `movementTargetMetric`, `movementTargetValue`, `movementVenue`, `movementIsMeetup`)
  - جداول `movement_budget` و `movement_pr`
- **کلاس کانونی `MovementLoadCalculator`**:
  - تنها مرجع محاسبهٔ MET، MET-minute و کالری بر اساس وزن واقعی کاربر یا ۷۰ کیلوگرم پیش‌فرض.
  - حذف کپی‌های فرمول MET در تمام صفحات.
- **توسعهٔ `RitmoIdFactory`**: افزودن شناسه‌سازهای اختصاصی `movementLog` و `movementCustomKind` و `movementPr`.

### ۲. ثبت فعالیت و شیت کانونی (فاز ۱)
- **`MovementRepository`**:
  - تنها نقطهٔ مجاز نوشتن در `workout_logs` و `movement_kinds` با پشتیبانی از تراکنش، محاسبهٔ خودکار MET/کالری، ارتقای شمارندهٔ مصرف و ثبت خودکار رکوردهای شخصی (PR).
- **`MovementLogSheet` (شیت کانونی)**:
  - جست‌وجوی هوشمند با نرمال‌سازی فارسی (`TextSimilarity`).
  - ورود متریک پویا بر اساس نوع ورزش (مسافت، طول استخر، ارتفاع، گام).
  - نوار زندهٔ پیش‌نمایش بار حرکتی در پایین شیت (کالری، MET-min، درصد از بودجه هفته).
- **`MovementCustomKindSheet`**:
  - ساخت انواع ورزش دلخواه توسط کاربر بدون پیچیدگی عددی.

### ۳. بودجهٔ حرکت و بازطراحی هاب (فاز ۲ و ۳)
- **`MovementBudget` و `WeeklyBudgetCard`**:
  - محاسبهٔ هفتگی بودجه (شنبه تا جمعه) با هدف پیش‌فرض ۵۰۰ MET-min.
  - کارت بصری جذاب در بالای هاب ورزش.
- **بازطراحی `sports_screen.dart`**:
  - ساختار هاب سه‌ستونی (۱. تمرین قدرتی ساختاریافته، ۲. فعالیت‌های حرکتی روزمره، ۳. ریکاوری و آمادگی بدنی).
  - حفظ تمام امکانات و قابلیت‌های موجود.
- **اصلاح `SportsStrategy`**:
  - تفویض کامل حالت `LOG` به `MovementLogSheet`.

### ۴. هوشمندی و تحلیل (فاز ۴ و ۵)
- **`MovementSuggester`**:
  - موتور پیشنهاد آفلاین ۶عامله (گیت سخت محدودیت بدنی، کسری بودجه، تنوع، فصل، آمادگی).
- **`EnduranceProgressionEngine`**:
  - قانون ۱۰٪ برای پیشرفت ایمن استقامتی و هشدار جهش ناگهانی حجم.
- **`MovementAnalyticsScreen`**:
  - نقشهٔ تنوع خانواده‌ها و مدیریت رکوردهای شخصی (PR).

---

## 🧪 وضعیت تست و ممیزی
- اضافه شدن Unit Testهای اختصاصی در `test/movement_load_calculator_test.dart` و `test/endurance_progression_test.dart`.
- تمام تست‌ها سبز و تحلیل استاتیک کد بدون هیچ‌گونه هشدار یا خطاست.
