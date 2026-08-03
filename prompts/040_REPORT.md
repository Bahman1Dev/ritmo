# گزارش نهایی پیاده‌سازی پرامپت ۰۴۰ — یکپارچه‌سازی مسیرهای ثبت انجام و گارد عدم تکرار

**تاریخ تکمیل:** ۳ اوت ۲۰۲۶  
**پروژه:** اپلیکیشن ریتمو (ir.ritmo.app)  
**نویسنده:** مهندس ارشد نرم‌افزار (Antigravity AI)

---

## 🎯 خلاصهٔ مأموریت

پرامپت ۰۴۰ با هدف حذف کلاسی از باگ‌های مرتبط با موازی‌کاری مسیرهای نوشتن دیتابیس در ثبت انجام روتین‌ها، رفع باگ‌های عدم ایده‌امپوتنت بودن، اصلاح لغو جابه‌جایی تاریخ‌ها (True Reschedule UNDO)، یکتا‌سازی کلید روز (`DayKey`) و جداسازی نمای انجام‌های واقعی در آنالیتیکس به صورت کامل و طی ۸ فاز (فاز ۰ تا فاز ۷) پیاده‌سازی و صحه‌گذاری شد.

---

## 📋 گزارش تفکیکی فازهای اجرا شده

### فاز ۰ — شناسایی و سرشماری تکمیلی (Reconnaissance)
- سرشماری ۳۷ نقطه نوشتن مستقیم دیتابیس در کدبیس و مستندسازی در [prompts/040_RECON.md](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/040_RECON.md).
- تایید وجود `PRIMARY KEY (routine_id, date)` روی جدول `routine_occurrences` از نسخهٔ ۸ مهاجرت دیتابیس.
- تایید عملکرد `ConflictAlgorithm.ignore` در `RoutineOccurrenceGenerator` و اصلاح شرط حذف در `EditRoutineHandler:93` به `status = 'pending'` تا سوابق گذشته کاربر هنگام ویرایش روتین محفوظ بماند.
- اضافه کردن امضای تراکنش اختیاری `execute(command, {Transaction? txn})` در `RitmoExecutionKernel` برای جلوگیری از Deadlock.

### فاز ۱ — مسیر واحد ثبت انجام (Single Write Path Router)
- ارتقای `CompleteOccurrenceCommand` شامل `partialRatio`, `resultSource`, `updatedAt`.
- ساخت دستورها و هندلرهای جدید `RescheduleOccurrenceCommand` / `RescheduleOccurrenceHandler` و `UndoCompletionCommand` / `UndoCompletionHandler`.
- تبدیل `CompletionGateway` به یک روتر محض (Pure Router) که کلیه ثبت‌های روتین را از طریق دستورهای رسمی کرنل اجرا کرده و پیام‌های خطای کاربرپسند به زبان فارسی تولید می‌کند.
- ایجاد تست نگهبان [single_completion_write_path_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/single_completion_write_path_test.dart) جهت مسدود کردن هرگونه نوشتن مستقیم SQL در لایه UI.

### فاز ۲ — تثبیت نوشتن و ایده‌امپوتنت‌سازی (Write Stabilization & Migration V60)
- ساخت کلاس `MigrationV60` جهت یکتا‌سازی جدول `routine_completions(routineId, completionDate, resultType)` پس از پاک‌سازی رکوردهای تکراری در [migrations_registry.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations_registry.dart) و ارتقای دیتابیس به نسخه ۶۰.
- الگوی `upsert` ایده‌امپوتنت در تمام هندلرهای کرنل (`CompleteOccurrenceHandler`, `SkipOccurrenceHandler`, `SnoozeReminderHandler`).
- لغو یادآورها در ۳ حالت (آینده، snooze، لغو).
- ایجاد تست‌های واحد در [phase2_write_stabilization_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/phase2_write_stabilization_test.dart).

### فاز ۳ — تعریف یکتای کلید روز (DayKey Single Definition)
- تثبیت کلاس `DayKey` در [ritmo_clock.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/time/ritmo_clock.dart) به عنوان مرجع واحد قالب‌بندی و محاسبات تاریخ روزانه در کل پروژه.
- ایجاد تست‌های نگهبان در [day_key_guard_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/time/day_key_guard_test.dart).

### فاز ۴ — طراحی Undo قطعی و مدیریت Reschedule (True Reschedule UNDO)
- پیاده‌سازی ساختار Sealed کلاس‌های `UndoToken` در [undo_token.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/undo_token.dart).
- پیاده‌سازی کامل لغو انتقال زمان (`reschedule undo`) در `CompletionGateway.undo` که وضعیت روز مبدا را به `pending` بازگردانده و رخداد زمان مقصد را پاک می‌کند.
- ذخیـره و بازیابی قطعی مقادیر پیشروی (`progressionCurrent` و `progressionDoneSinceAdvance`) در توکن لغو.
- ایجاد تست‌های واحد در [undo_token_reschedule_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/undo_token_reschedule_test.dart).

### فاز ۵ — تفکیک انجام واقعی در آنالیتیکس (Analytics VIEW)
- ساخت VIEW دیتابیس `routine_actual_completions` در [routine_tables.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/schema/tables/routine_tables.dart) و `MigrationV60`.
- این VIEW فقط ردیف‌های انجام واقعی (`FULL`, `PARTIAL`, `MINIMAL`, `DONE`, `LIGHT`, `COMPLETED`) را جدا کرده و موارد `SKIPPED` و `RESCHEDULED` را برای موتورهای محاسباتی آمار حذف می‌نماید.
- ایجاد تست‌های واحد در [routine_actual_completions_view_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/analytics/routine_actual_completions_view_test.dart).

### فاز ۶ — اصلاح ترمینولوژی و جداسازی مرز تقویم/مخزن
- انطباق تمام واژه‌ها با `docs/GLOSSARY.md`.
- بازنویسی متد بایگانی در [all_plans_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/presentation/all_plans_screen.dart) و استفاده از دستورهای رسمی کرنل (`ArchiveRoutineCommand` و `UnarchiveRoutineCommand`).
- ایجاد تست‌های واحد در [archive_routine_kernel_command_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/registry/archive_routine_kernel_command_test.dart).

### فاز ۷ — پرداخت و پولیش UX و صحه‌گذاری نهایی
- بررسی کامل رنگ‌ها و تم‌ها بر اساس `context.colors.*` و تایپوگرافی `Vazirmatn` و راست‌چین (RTL).
- صحه‌گذاری کامل ساختار تست‌ها و عدم وجود خطاهای استاتیک در تحلیل فلاتر.

---

## 🧪 تست‌های جدید اضافه شده

1. `test/completion/single_completion_write_path_test.dart`
2. `test/completion/phase2_write_stabilization_test.dart`
3. `test/time/day_key_guard_test.dart`
4. `test/completion/undo_token_reschedule_test.dart`
5. `test/analytics/routine_actual_completions_view_test.dart`
6. `test/registry/archive_routine_kernel_command_test.dart`

---

## ✅ نتیجه‌گیری
تمامی ۱۴ قانون مطلق پرامپت ۰۴۰ رعایت شدند. کلیهٔ ثبات‌های دیتابیس، ایده‌امپوتنت بودن انجام‌ها، مسیریابی یکتا، و سیستم Undo قطعی پیاده‌سازی و تأیید شدند.
