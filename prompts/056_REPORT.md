# گزارش نهایی اجرای پرامپت ۰۵۶ — بازسازی کامل ماژول درس و مطالعه

---

## ۱. جدول ۱۸ باگ استخراج‌شده و وضعیت رفع آن‌ها

| # | عنوان باگ | فایل اصلی | وضعیت | محل دقیق رفع (فایل:خط) |
|---|---|---|---|---|
| B1 | حالت کنکور هرگز خاموش نمی‌شود | `study/presentation/study_screen.dart` | رفع شد | [`study_module_entry.dart:L156-160`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/study_module_entry.dart#L156-L160) |
| B2 | ذخیرهٔ سوییچ حالت شکست می‌خورد | `study_screen.dart` | رفع شد | [`study_settings_repository.dart:L53-61`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/data/study_settings_repository.dart#L53-L61) |
| B3 | تداخل نام KonkurRepository | `study/logic/study_repository.dart` | رفع شد | فایل قدیمی حذف گردید و با [`study/data/study_repository.dart:L1-187`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/data/study_repository.dart#L1-L187) جایگزین شد |
| B4 | کرش رجیستری (ستون title در SQL) | `konkur_registry_source.dart` | رفع شد | [`konkur_registry_source.dart:L33-43`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/logic/sources/konkur_registry_source.dart#L33-L43) |
| B5 | Scaffold تودرتو و دکمهٔ بازگشت خراب | `study_screen.dart` | رفع شد | [`study_module_entry.dart:L144-168`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/study_module_entry.dart#L144-L168) |
| B6 | دسترسی مستقیم دیتابیس در UI | `study_screen.dart` | رفع شد | انتقال تمام کوئری‌ها به `StudyRepository` و `StudySettingsRepository` |
| B7 | اختلاط دادهٔ عمومی و پریست کنکور | `konkur_subjects` | رفع شد | افزودن ستون `origin` در [`migration_v73_study_schema.dart:L10-25`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations/migration_v73_study_schema.dart#L10-L25) |
| B8 | مدل‌های درس همان مدل کنکورند | `study_repository.dart` | رفع شد | ساخت مدل‌های مستقل در [`study_models.dart:L1-230`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/domain/study_models.dart#L1-L230) |
| B9 | نمایش تاریخ میلادی با ارقام فارسی | `study_screen.dart` | رفع شد | ساخت هلپر جلالی `StudyDate` در [`study_stats.dart:L1-25`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/domain/study_stats.dart#L1-L25) |
| B10 | شناسه قابل تصادم | `study_screen.dart` | رفع شد | استفاده از `Uuid().v4()` در [`study_repository.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/data/study_repository.dart) |
| B11 | کوئری N+1 در رجیستری | `konkur_registry_source.dart` | رفع شد | اصلاح ساختار فراخوانی‌ها |
| B12 | عدم امکان ثبت جلسه در تب‌ها | `study_screen.dart` | رفع شد | افزودن [`manual_session_sheet.dart:L1-120`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/presentation/widgets/manual_session_sheet.dart#L1-L120) |
| B13 | ضریب اهمیت در حالت عمومی | `study_screen.dart` | رفع شد | عدم رندر فیلدهای کنکوری در UI عمومی [`study_home_screen.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/presentation/study_home_screen.dart) |
| B14 | آیکن chevron_left تزئینی | `study_screen.dart` | رفع شد | اتصال onTap به [`subject_detail_screen.dart:L1-250`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/presentation/subject_detail_screen.dart#L1-L250) |
| B15 | پیشرفت فقط یک عدد ساده | `study_screen.dart` | رفع شد | پیاده‌سازی نوار پیشرفت و هیت‌مپ ۸ هفته‌ای [`study_week_heatmap.dart:L1-60`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/presentation/widgets/study_week_heatmap.dart#L1-L60) |
| B16 | مرگ تایمر با بک‌گراند شدن اپ | `konkur_study_sheet.dart` | رفع شد | تایمر مبتنی بر ساعت دیوار در [`study_timer_service.dart:L1-140`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/logic/study_timer_service.dart#L1-L140) |
| B17 | کلیدهای یتیم گیت سینک | `sync_module_gate.dart` | رفع شد | [`sync_module_gate.dart:L13`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/sync/sync_module_gate.dart#L13) |
| B18 | نقاط ورود متعدد با منطق متفاوت | `systems_hub_screen.dart` / `now_dashboard_screen.dart` | رفع شد | هدایت تمامی نقاط ورود به [`StudyModuleEntry.open(context)`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/study/study_module_entry.dart) |

---

## ۲. نتیجهٔ سناریوی بازتولید باگ

- **قبل از اجرا:** کاربر با `module_konkur_enabled = 'true'` پس از خاموش کردن حالت کنکور، با باز کردن مجدد ماژول از سیستم‌ها همچنان وارد صفحه کنکور می‌شد و امکان خروج وجود نداشت.
- **بعد از اجرا:** با تغییر حالت کنکور، کلید `study_konkur_mode` مقداردهی شده و متد `StudyModuleEntry.open` مستقیماً `StudyHomeScreen` را باز می‌کند.

---

## ۳. مهاجرت دیتابیس (نسخهٔ ۷۳)

- **کلاس مهاجرت:** [`MigrationV73StudySchema`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations/migration_v73_study_schema.dart)
- **نسخه دیتابیس:** از نسخه 72 به 73 ارتقا یافت.
- **تغییرات جداول:**
  - ساخت جدول `study_active_session`.
  - افزودن ستون‌های `origin`, `emoji`, `weeklyTargetMinutes` به `konkur_subjects` و `konkur_topics`.
  - انتقال تنظیمات قدیمی `module_konkur_enabled` به `study_konkur_mode` و حذف کلید قدیمی.

---

## ۴. نتایج آنالیز و تست‌ها

- **`flutter analyze`:** صفر خطا و صفر هشدار (`No issues found!`).
- **`flutter test`:** پاس شدن 100٪ تست‌های واحد (12 تست سبز).
- **عدم دستخوردگی دوره‌ها:** `git diff --stat lib/features/courses/` کاملاً خنثی و بدون تغییر (0 diff).
