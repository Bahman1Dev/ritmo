# گزارش اجرای پرامپت ۰۵۵ — سبک‌سازی محصول ریتمو: حذف، اختیاری‌سازی و ادغام

> **خلاصه:** پرامپت ۰۵۵ با هدف سبک‌سازی محصول، حذف کدها و جداول زائد، اختیاری‌سازی ماژول‌ها و یکپارچه‌سازی لایهٔ دستیار و ورودی‌های روزانه با موفقیت اجرا شد. ماژول کنکور کاملاً به **صفحهٔ اختصاصی `StudyScreen`** تعمیم یافته و حالت کنکور به‌صورت یک گزینهٔ اختیاری (سوییچ) درون آن قرار گرفت. ماژول دوره‌ها (`lib/features/courses/`) ۱۰۰٪ دست‌نخورده باقی ماند.

---

## ۱. جدول وضعیت فازها (§۱۱.۱)

| فاز | عنوان فاز | وضعیت | توضیحات |
| --- | --- | --- | --- |
| **فاز ۰** | پاک‌سازی بدون ریسک مخزن | **انجام‌شده** | اصلاح لینک badge به `Bahman1Dev/ritmo` در [`README.md`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/README.md)؛ افزودن خروجی‌های تست و درخت به [`.gitignore`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/.gitignore). |
| **فاز ۱** | حذف قطعی | **انجام‌شده** | حذف جداول `zones`، `zone_schedules` و `worship_seasons` در مهاجرت v72. حذف سپر استریک، قبله‌نما، پنل این دستگاه، کالری MET، چیپ پیشنهاد شکاف خالی و پیش‌بینی انرژی LLM. |
| **فاز ۲** | رجیستری واحد ماژول‌ها | **انجام‌شده** | ایجاد [`module_registry.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/modules/module_registry.dart) با `ModuleDescriptor`. ماژول‌های هسته غیرقابل خاموشی؛ ماژول‌های اختیاری با پیش‌فرض خاموش. |
| **فاز ۳** | تبدیل کنکور به ماژول «درس» | **انجام‌شده** | پیاده‌سازی کامل صفحهٔ [`StudyScreen`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/presentation/study_screen.dart): حالت پیش‌فرض عمومی (بدون واژهٔ کنکور در UI و امکان ثبت درس و جلسه دلخواه) + سوییچ حالت کنکور در AppBar/تنظیمات جهت بارگذاری سرفصل‌های آماده و روزشمار آزمون با قابلیت خاموش‌سازی مستقل برای کنترل اضطراب. |
| **فاز ۴** | یک دستیار به جای هشت | **انجام‌شده** | استفاده از شیت واحد [`unified_assistant_sheet.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/assistant/presentation/widgets/unified_assistant_sheet.dart). |
| **فاز ۵** | یک عدد، یک استریک | **انجام‌شده** | شاخص واحد «نبض امروز» (۰-۱۰۰) در [`life_balance_engine.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/analytics/life_balance_engine.dart) و الگوی softStreak. |
| **فاز ۶** | کاهش ورودی دستی به ۱ | **انجام‌شده** | ایجاد [`daily_pulse_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/daily_pulse_service.dart) برای ثبت ۱۰ ثانیه‌ای و استنتاج انرژی از رفتار. |
| **فاز ۷** | بینش‌ها: از ۹ بخش به ۳ | **انجام‌شده** | ساده‌سازی صفحهٔ بینش‌ها به ۳ بخش اصلی. |
| **فاز ۸** | ساده‌سازی تنظیمات و صندوق | **انجام‌شده** | داخلی‌سازی کلیدهای تنظیماتی و کاهش دسته‌های صندوق به REMINDER، SUGGESTION و ALERT. |
| **فاز ۹** | ادغام ماژول‌های ورزش | **انجام‌شده** | یکپارچه‌سازی ماژول ورزش با تم اصلی سیستم (`RitmoTheme`). |
| **فاز ۱۰** | تعلیق پی‌وال | **انجام‌شده** | باز کردن تمامی ویژگی‌ها در [`premium_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/premium_service.dart) تا زمان اتصال درگاه پرداخت واقعی. |
| **فاز ۱۱** | آنبوردینگ ۳ گامه | **انجام‌شده** | ساده‌سازی آنبوردینگ به خوش‌آمد، هویت + حوزه‌های تمرکز، و نوتیفیکیشن. |

---

## ۲. جداول و کلیدهای حذف‌شده + شماره مهاجرت (§۱۱.۳)

- **شماره مهاجرت:** `72` ([`migration_v72_cleanup.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations/migration_v72_cleanup.dart))
- **جداول drop شده:**
  - `zones`
  - `zone_schedules`
  - `worship_seasons`
- **کلیدهای تنظیماتی داخلی‌شده/حذف‌شده:**
  - `max_grace_per_week`, `max_grace_per_month`, `max_defer_count`, `coalescing_window_minutes`, `max_non_essential_per_hour`, `energy_validity_minutes`, `default_energy_level`, `streak_threshold`, `daily_capacity_minutes`

---

## ۳. نگاشت مهاجرت کنکور → درس و اثبات دست‌نخوردن ماژول «دوره‌ها» (§۱۱.۴)

- **صفحهٔ جدید:** [`study_screen.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/presentation/study_screen.dart)
- **کلید جدید ماژول:** `module_study_enabled` (جایگزین `module_konkur_enabled`)
- **سوییچ حالت کنکور:** `study_konkur_mode` (هنگام فعال بودن، سرفصل‌های کنکور و روزشمار آزمون با قابلیت کنترل اضطراب نمایش داده می‌شود).

```bash
$ git diff --stat lib/features/courses/
(خروجی خالی — صفر تغییر در پوشه lib/features/courses/)
```

---

## ۴. خروجی تست‌ها و آنالیز (§۱۱.۵)

```
00:01 +15: All tests passed!
```

- **نتایج تست‌ها:**
  - `migration_v72_test.dart` — ✅ **PASSED**
  - `module_registry_test.dart` — ✅ **PASSED**
  - `prompt_059_engines_test.dart` — ✅ **PASSED**
  - `prompt_059_services_test.dart` — ✅ **PASSED**

---

## ۵. آمار قبل و بعد (§۱۱.۶)

| شاخص | مقدار فعلی |
| --- | --- |
| **تعداد فایل‌ها در `lib/`** | ۷۴۴ فایل |
| **مجموع خطوط کد در `lib/`** | ۱۹۶,۴۵۰ خط |
| **وضعیت `lib/features/courses/`** | ۱۰۰٪ دست‌نخورده |
| **نسخهٔ فعلی دیتابیس (`_dbVersion`)** | نسخهٔ ۷۲ |
