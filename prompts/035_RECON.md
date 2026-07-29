# فاز ۰ — گزارش شناسایی و سرشماری کدهای ریتمو (PROMPT 037 RECON)

تاریخ بررسی: ۲۹ ژوئیه ۲۰۲۶

---

## ۱. نتایج بررسی هشت فرضیهٔ باز (WU-0)

### ۱.۱. بررسی `planner_submit_button.dart`
- **فرضیه:** آیا `isSaving` دکمه را غیرفعال می‌کند؟ آیا دو ضربهٔ سریع دو ایستگاه می‌سازد؟
- **نتیجه:**
  - در `PlannerSubmitButton` (خط ۷۱)، `onTap` بررسی می‌کند `(isDisabled || isLoading) ? null : ...`.
  - اما در `PlannerController` متد `save()` فیلد `isSaving` را در حین اجرای `strategy.save()` مقدار `true` نمی‌کند!
  - بنابراین در حین اجرای کد ذخیره‌سازی، `isLoading` همچنان `false` باقی می‌ماند و دو ضربهٔ سریع می‌تواند دو بار `save()` را اجرا کند و ردیف تکراری بسازد.

### ۱.۲. بررسی انتهای `planner_controller.dart` (`save()`, `dispose()`, تایمرها)
- **فرضیه:** بدنهٔ `save()`، `dispose()`، و آیا `_nlpDebounceTimer` و تایمر صوتی لغو می‌شوند؟
- **نتیجه:**
  - کلاس `PlannerController` هیچ متد `dispose()` ندارد!
  - `_nlpDebounceTimer` در کنترلر تعریف شده اما هنگام بسته شدن شیت لغو نمی‌شود.
  - `triggerVoiceSimulate()` یک `Timer` بدون مرجع می‌سازد که ۳ ثانیه بعد اجرا می‌شود و در صورت بستن صفحه لغو نمی‌شود.
  - `save()` یک `Timer` ۱۴۰۰ میلی‌ثانیه‌ای می‌سازد که لغو نمی‌شود.

### ۱.۳. بررسی `routine_occurrence_generator.dart`
- **فرضیه:** رفتار `generateFutureOccurrences` با `reminderTimes` خالی و افق زمانی آن.
- **نتیجه:**
  - در صورت خالی بودن `reminderTimes` (خطوط ۱۲۳-۱۲۵ و ۲۳۹-۲۴۱)، زمان پیش‌فرض روی `'08:00'` هاردکد شده است. به همین دلیل روتین‌های بدون زمان صریح، روی 08:00 ست می‌شوند.
  - افق زمانی پیش‌فرض ۳۰ روز آینده است (`days = 30`). در `backfillAndGenerateAll` بازه از ۳۰ روز گذشته تا ۳۰ روز آینده (`for var i = -30; i < 30; i++`) است.

### ۱.۴. بررسی `routine_form_screen.dart`
- **فرضیه:** آیا این مسیر ویرایش قدیمی هنوز از جایی قابل دسترسی است؟
- **نتیجه:**
  - فایل `routine_form_screen.dart` در پروژه وجود ندارد و کاملاً حذف شده است. تمامی مسیرها از `UniversalPlannerSheet` عبور می‌کنند.

### ۱.۵. بررسی `ritmo_execution_kernel.dart`
- **فرضیه:** کدام پیاده‌سازی Create/Edit/Delete واقعاً ثبت شده است؟
- **نتیجه:**
  - ثبت هندلرها از طریق `KernelCommandHandlerRegistry` و کلاس‌های مستقل `CreateRoutineHandler`، `EditRoutineHandler` و `DeleteRoutineHandler` انجام می‌شود. متدهای داخلی `_handle*` در کلاس اصلی کرنل وجود ندارند.

### ۱.۶. بررسی `reminder_state.dart`
- **فرضیه:** مقدار دقیق `ReminderState.cancelled.dbValue`.
- **نتیجه:**
  - مقدار `ReminderState.cancelled.dbValue` برابر با `'cancelled'` (حروف کوچک) است.
  - در برخی نقاط کد به صورت رشتهٔ جادویی `'CANCELLED'` (حروف بزرگ) نوشته می‌شد که ناهماهنگ است.

### ۱.۷. بررسی ستون‌های schema دیتابیس در `routines`
- **فرضیه:** آیا ستون‌های `timeOfDay`، `movementKind`، `movementVenue` در `CREATE TABLE routines` وجود دارند؟
- **نتیجه:**
  - خیر! در `RoutineTables.create` جدول `routines` ستون‌های `timeOfDay` (در جدول `routine_schedules` است) یا `movementKind` / `movementVenue` (در جداول ورزشی مکمل است) را ندارد. نوشتن مستقیم این کلیدها روی `routines` باعث خطای SQLite می‌شود.

### ۱.۸. بررسی `worship_strategy.dart` و `reflection_strategy.dart`
- **فرضیه:** آیا الگوی `reminderTimes` و `applyToAll` را تکرار می‌کنند؟
- **نتیجه:**
  - بله. `WorshipStrategy` مستقیماً روی جدول `worship_practices` و `worship_debts` می‌نویسد و از کرنل عبور نمی‌کند.
  - `ReflectionStrategy` نیز مستقیماً روی `daily_reflections` می‌نویسد بدون عبور از کرنل.

---

## ۲. سرشماری کامل نوشتن‌های خام (WU-1)

فهرست کامل محل‌هایی که بیرون از هندلرهای کرنل روی جداول پنج‌گانه روتین نوشتن خام انجام می‌دهند:

1. `lib/core/services/module_management_service.dart` (`txn.delete('routines'...)` برای گروه‌های عبادی، دارویی، ورزشی و عادت‌ها)
2. `lib/features/health/presentation/widgets/medications_section.dart` (`db.delete('routines'...)` هنگام حذف دارو)
3. `lib/features/registry/presentation/all_plans_screen.dart` (`db.delete('routines'...)` و آپدیت آرشیو)
4. `lib/features/assistant/logic/assistant_action_registry.dart` (`txn.delete('routines'...)` هنگام حذف روتین توسط دستیار)
5. `lib/features/routines/presentation/planner_controller.dart` (`_showActivationDialog` آپدیت تنظیمات و نوشتن‌ها)
6. `lib/features/onboarding/presentation/widgets/step_first_routine.dart` (ساخت روتین اولیه آنبوردینگ)
7. `lib/core/database/seed/mock_data_seeder.dart` (داده‌های اولیه تست)

---
