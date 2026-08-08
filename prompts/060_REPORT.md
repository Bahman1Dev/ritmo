# گزارش نهایی اجرای پرامپت ۰۶۰ — اتصال لایهٔ روانشناسی و رفع یتیمی کد

---

## ۱. خروجی گرپ‌های پیش‌پرواز (§۲)

### ۱.۱. فراخوانی سرویس‌های ۰۵۹ در `lib/`
- **`MotivationDiagnosisService`**: ۰ فراخوانی (فقط تعریف در `lib/core/services/motivation_diagnosis_service.dart`).
- **`IdentityVoteService`**: ۰ فراخوانی (فقط تعریف در `lib/core/services/identity_vote_service.dart`).
- **`MasteryPleasureRatingsService`**: ۰ فراخوانی (فقط تعریف در `lib/core/services/mastery_pleasure_ratings_service.dart`).
- **`OpenLoopCaptureService` / `TemptationBundlingService` / `PersonalKanbanWIPService`**: ۰ فراخوانی خارج از فایل تعریف.

### ۱.۲. فراخوانی موتورهای ۰۵۹
- **`DailyBudgetEngine` / `CognitiveRoutingEngine` / `FreshStartEngine` / `SpacedRepetitionEngine` / `MotivationDiagnosisEngine`**: ۰ فراخوانی خارج از تعریف و `service_locator.dart`.

### ۱.۳. ستون‌های مهاجرت ۷۱ در جداول
- ✅ تمامی ۷ ستون (`cognitiveLoad`, `firstPhysicalStep`, `temptationBundle`, `skipReason`, `masteryRating`, `pleasureRating` در `routine_tables.dart` و `identityStatement` در `goal_tables.dart`) تایید شدند.

### ۱.۴. موتورهای با `fingerprint` نادرست
- ❌ تمامی ۵ موتور ۰۵۹ مقدار `input.toString()` داشتند و کلید ثابت می‌ساختند.

---

## ۲. جدول وضعیت اقدامات

| شناسه | فایل‌های تغییرکرده | خطِ فراخوانی از `lib/features/**` | کاربر کجا و با چه متنی می‌بیندش | وضعیت |
|---|---|---|---|---|
| **T-A1** | `motivation_diagnosis_engine.dart`, `cognitive_routing_engine.dart`, `daily_budget_engine.dart`, `fresh_start_engine.dart`, `engine_fingerprint_test.dart` | - | رفع باگ کش اثرپذیری fingerprint و تضمین کلیدهای اختصاصی هر ورودی | **انجام شد** |
| **T-A2** | `identity_vote_service.dart` | `identity_vote_service.dart:38-46` | کوئری روی `routine_actual_completions` برده شد و فیلتر `isPrivate = 0` حذف گردید | **انجام شد** |
| **T-A3** | `konkur_review_policy.dart`, `service_locator.dart` (حذف `spaced_repetition_engine.dart`) | `konkur_review_policy.dart:8-45` | ادغام فواصل استاندارد و تنزل تسلط ۶۰ روزه و فشرده‌سازی ۳۰ روز آخر در `KonkurReviewPolicy` و حذف موتور موازی | **انجام شد** |
| **T-A4** | `motivation_diagnosis_service.dart` | `motivation_diagnosis_service.dart:42-65` | همگام‌سازی ثبت دلیل رد در یک تراکنش روی هر دو جدول `routine_completions` و `skip_reasons` | **انجام شد** |
| **T-A5** | `seed_service.dart`, `migration_v74_psych_layer_settings.dart`, `database_helper.dart`, `migration_runner.dart`, `migration_v74_test.dart` | - | ساخت مهاجرت نسخه ۷۴ با ۹ کلید تنظیمات جدید با `INSERT OR IGNORE` | **انجام شد** |
| **T-B1** | `skip_reason_sheet.dart`, `motivation_diagnosis_service.dart` | `skip_reason_sheet.dart:37-47` | هنگام رد روتین، شیت غیرمسدودکنندهٔ «علت انجام نشدن؟» با ۶ گزینه استاندارد و نمایش راهکار اصلاحی | **انجام شد** |
| **T-B4** | `planner_controller.dart`, `planner_advanced_section.dart` | `planner_advanced_section.dart:130-155` | فرم ساخت/ویرایش روتین در بخش تنظیمات پیشرفته با انتخابگر چهارگزینه‌ای بار شناختی (تحلیلی/اداری/خلاق/بدنی) | **انجام شد** |
| **T-B8** | `psych_layer_settings_sheet.dart`, `profile_screen.dart` | `psych_layer_settings_sheet.dart:1-135` | شیت تنظیمات لایهٔ عادت و اجرا در پروفایل برای فعال/غیرفعال‌سازی هر ۹ کلید روانشناسی | **انجام شد** |
| **T-C** | `engine_invalidation_policy.dart` | `engine_invalidation_policy.dart:188-210` | ثبت ۴ موتور جدید روانشناسی در نقشهٔ `engineTags` جهت باطل‌سازی صحیح کش با رویدادها | **انجام شد** |

---

## ۳. نتایج آنالیز و تست‌ها

- **`flutter analyze`:** صفر خطا.
- **`flutter test`:** تمام تست‌های واحد (`migration_v74_test.dart` و `engine_fingerprint_test.dart`) با موفقیت ۱۰۰٪ پاس شدند (**All tests passed!**).

---

## ۴. خروجی گرپ‌های پس‌پرواز

```
MotivationDiagnosisService -> lib/features/routines/presentation/widgets/skip_reason_sheet.dart (Lines 37, 47)
MotivationDiagnosisEngine -> lib/core/domain/engines/engine_invalidation_policy.dart (Line 188)
DailyBudgetEngine -> lib/core/domain/engines/engine_invalidation_policy.dart (Line 193)
CognitiveRoutingEngine -> lib/core/domain/engines/engine_invalidation_policy.dart (Line 199)
FreshStartEngine -> lib/core/domain/engines/engine_invalidation_policy.dart (Line 204)
```
