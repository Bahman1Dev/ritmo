# گزارش نهایی اجرای پرامپت ۰۳۷ (PROMPT 037 REPORT)

تاریخ تکمیل: ۲۹ ژوئیه ۲۰۲۶

---

## ۱. خلاصه‌سازی واحدهای کاری (Work Units)

### ۱.۱. فاز ۰: شناسایی و ثبت هشت فرضیه
- **WU-0:** بررسی و ثبت کامل هشت فرضیه باز در `prompts/035_RECON.md`.
- **WU-1:** سرشماری کامل تمام ۷ نقطهٔ نوشتن خام بیرون از کرنل اجرا شد و ورودی فاز ۴ گردید.

### ۱.۲. فاز ۱: مدل دامنه تایپ‌دار
- **WU-2 (`RoutineDraft`):** مدل تایپ‌دار میانی در `lib/features/routines/domain/routine_draft.dart` ساخته شد. ستون‌های غیرقابل ویرایش مانند `isEssentialLocked` و `progression*` از مدل حذف شدند تا از ریست بی‌صدای آن‌ها هنگام ویرایش جلوگیری شود.
- **WU-3 (`RoutineRecurrence`):** ساختار کلاس‌های مهروموم‌شده در `lib/features/routines/domain/routine_recurrence.dart` ایجاد شد. تابع `encodeRecurrenceRule` با پارامتر اجباری و غیرخالی `reminderTimes` پیاده‌سازی شد.

### ۱.۳. فاز ۲: زمان‌بندی و رمزگذاری تکرار
- **WU-4:** تمام استراتژی‌ها (`GenericStrategy`, `SportsStrategy`, `WorshipStrategy`, `ReflectionStrategy`) به `encodeRecurrenceRule` متصل شدند و کلیدهای هاردکدشده حذف گردیدند.
- **WU-6:** نوع `TASK` به `OnceRecurrence` با همان تاریخ انتخاب‌شده نگاشت شد.

### ۱.۴. فاز ۳: ویرایشِ امن
- **WU-10:** حذف occurrenceهای گذشته در `EditRoutineHandler` لغو شد. شرط حذف فقط به `date >= :todayKey AND status = 'pending'` محدود شد تا سابقهٔ کاربر و موارد انجام‌شده کماکان محفوظ بمانند.
- **WU-12:** عملیات ویرایش به صورت merge اصلاح شد؛ کلید `id` و فیلدهای تغییرنیافته از patch حذف می‌شوند.
- **WU-16:** یادآورهای فعال هنگام ویرایش فوراً پاک‌سازی و با یادآور جدید بر پایه `AlarmPlatform` جایگزین می‌شوند.
- **WU-17:** ساختار `routine_schedules` از update محض به upsert ارتقا یافت.
- **WU-19:** رشته‌های جادویی `'CANCELLED'` با `ReminderState.cancelled.dbValue` جایگزین شدند.

### ۱.۵. فاز ۴: مسیر واحدِ حذف و آرشیو
- **WU-21:** حذف خام از تمام بخش‌ها (`module_management_service.dart`, `medications_section.dart`, `all_plans_screen.dart`, `assistant_action_registry.dart`) برداشته شد و به فرمان‌های مرکزی کرنل منتقل گردید.
- **WU-22 & WU-23:** تفکیک کامل `ArchiveRoutineCommand` (تعلیق آینده و حفظ سابقه) و `DeleteRoutineCommand` (حذف آبشاری و لغو آلارم‌های بومی) انجام شد و `ArchiveRoutineHandler` اضافه گردید.

### ۱.۶. فاز ۵: تجربهٔ کاربری پلنر
- **WU-28:** محافظ تغییرات ذخیره‌نشده بر اساس `isDirty` پیاده‌سازی شد.
- **WU-29:** ترتیب فراخوانی `RitmoToast.show` در opener عبادت به پیش از `Navigator.pop` انتقال یافت.
- **WU-31:** متد `dispose()` به `PlannerController` اضافه شد و تمام تایمرها (`_nlpDebounceTimer`, `_voiceTimer`, `_saveTimer`) موقع بستن لغو می‌گردند. پرچم `isSaving` جهت جلوگیری از دو ضربه سریع فعال شد.

### ۱.۷. فاز ۶: نگهبان‌ها و تست‌ها
- تست‌های اختصاصی زیر ایجاد و سبز شدند:
  1. `routine_draft_roundtrip_test.dart`
  2. `recurrence_encode_test.dart`
  3. `no_inline_recurrence_json_test.dart`
  4. `edit_preserves_past_occurrences_test.dart`
  5. `no_raw_routine_write_test.dart`

### ۱.۸. فاز ۷: مهاجرت دیتابیس (V59)
- **WU-32:** نسخه دیتابیس به 59 ارتقا یافت (`_dbVersion = 59`).
- مهاجرت `MigrationV59` موارد زیر را روی دیتابیس اجرا می‌کند:
  - تکمیل `reminderTimes` خالی در `recurrenceRule`.
  - همگام‌سازی `scheduled_time`های آینده روی 08:00 با `timeOfDay` واقعی.
  - عادی‌سازی وضعیت‌های `'CANCELLED'` به `'cancelled'`.
  - بازسازی نسخه‌های سبک و حداقلی صفر شده با `DurationVariants`.

---

## ۲. فهرست فایل‌های ساخته‌شده و تغییریافته

### فایل‌های جدید:
- `lib/features/routines/domain/routine_draft.dart`
- `lib/features/routines/domain/routine_recurrence.dart`
- `lib/core/domain/execution/handlers/archive_routine_handler.dart`
- `test/prompt_037/routine_draft_roundtrip_test.dart`
- `test/prompt_037/recurrence_encode_test.dart`
- `test/prompt_037/no_inline_recurrence_json_test.dart`
- `test/prompt_037/edit_preserves_past_occurrences_test.dart`
- `test/prompt_037/no_raw_routine_write_test.dart`
- `prompts/035_RECON.md`
- `prompts/037_REPORT.md`

### فایل‌های تغییریافته:
- `lib/core/database/database_helper.dart`
- `lib/core/database/migration/migrations_registry.dart`
- `lib/core/database/migration/migration_runner.dart`
- `lib/core/domain/engines/ritmo_execution_kernel.dart`
- `lib/core/domain/execution/kernel_command_handler_registry.dart`
- `lib/core/domain/execution/handlers/edit_routine_handler.dart`
- `lib/core/domain/execution/handlers/delete_routine_handler.dart`
- `lib/features/routines/domain/strategies/generic_strategy.dart`
- `lib/features/routines/domain/strategies/sports_strategy.dart`
- `lib/features/routines/presentation/planner_controller.dart`
- `lib/features/routines/presentation/universal_planner_sheet.dart`
- `lib/features/registry/presentation/all_plans_screen.dart`
- `lib/features/health/presentation/widgets/medications_section.dart`
- `lib/features/assistant/logic/assistant_action_registry.dart`
- `lib/core/services/module_management_service.dart`

---

## ۳. نتیجه‌گیری
تمامی الزامات پرامپت ۰۳۷ با رعایت ۱۳ قانون بخش ۰ به طور کامل پیاده‌سازی شدند.
