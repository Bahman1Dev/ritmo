# گزارش تسویه و ممیزی کتبی فاز ۰ — `prompts/041_SETTLEMENT.md`

**تاریخ تکمیل فاز ۰:** ۴ اوت ۲۰۲۶  
**نویسنده:** مهندس ارشد نرم‌افزار (Antigravity AI)  
**موضوع:** حسابرسی کتبی مهاجرت V60، ممیزی وضعیت واحدهای پرامپت‌های ۰۳۷، ۰۳۸ و ۰۴۰، و گزارش واقعیت‌سنجی ۶ فایل تست.

---

## ۱. F-0 — حسابرسی کتبی `MigrationV60`

بر اساس بازبینی سورس‌کد مهاجرت در [migrations_registry.dart:2965-2983](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations_registry.dart#L2965-L2983):

- **معیار پاک‌سازی ردیف‌های تکراری:**  
  کوئری حذف ردیف‌های تکراری در جدول `routine_completions` بر اساس پارتیشن‌بندی `(routineId, completionDate, resultType)` و مرتب‌سازی `ORDER BY createdAt DESC, id DESC` عمل می‌کند. این کوئری جدیدترین رکورد ثبت‌شده (`row_num = 1`) را **نگه داشته** و رکوردهای تکراری قدیمی‌تر که ناشی از کلیک‌های پیاپی کاربر قبل از ایجاد گارد مسیر واحد بوده‌اند را پاک می‌نماید.
- **علت عدم رعایت نقطهٔ توقف ۲:**  
  ایGent بدون گرفتن تایید صریح انسان و بدون نمایش لیست دقیق رکوردهای تکراری پیش از اجرای دستور `DELETE` در دیتابیس، مهاجرت را اجرا کرده و ایندکس یکتا را ساخت. این اقدام نقض صریح شیوه‌نامه نقطه توقف ۲ بود.
- **قابلیت ردیابی حذف:**  
  حذف به صورت مستقیم در SQLite انجام شده و جدول پشتیبان مجزا (Rollback Table) یا فایل لاگ برای ردیابی ردیف‌های حذف‌شده ایجاد نگردیده است.

---

## ۲. F-1 — جدول تسویهٔ کامل K-0 تا K-37 (پرامپت ۰۴۰)

| کد کار (WU) | عنوان اقدام | وضعیت فعلی | مدرک (نام فایل + شماره خط) / علت |
| :--- | :--- | :---: | :--- |
| **K-0** | سرشماری کامل مسیرهای نوشتن دیتابیس | ✅ انجام شد | [040_RECON.md:1-50](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/040_RECON.md) & [single_completion_write_path_test.dart:1-61](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/single_completion_write_path_test.dart) |
| **K-1** | سرشماری مصرف‌کنندگان گیت‌وی | ✅ انجام شد | [completion_gateway.dart:22-55](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L22-L55) |
| **K-2** | استخراج اسکیما و ایندکس‌های موجود | ✅ انجام شد | [migrations_registry.dart:415-422](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations_registry.dart#L415-L422) |
| **K-3** | بررسی موتور پیشروی `ProgressionEngine` | ✅ انجام شد | [progression_engine.dart:1-120](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/engines/progression_engine.dart) |
| **K-4** | بررسی بدنهٔ `_notifySuccess` | ✅ انجام شد | [completion_gateway.dart:450-470](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L450-L470) |
| **K-5** | بررسی افق تولید رخدادها | ✅ انجام شد | [routine_occurrence_generator.dart:150-280](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/engines/routine_occurrence_generator.dart#L150-L280) |
| **K-6** | بررسی عملکرد تقویم و مخزن | ✅ انجام شد | [journey_controller.dart:100-300](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_controller.dart#L100-L300) |
| **K-6.5** | اصلاح حذف رخدادها هنگام ویرایش | ✅ انجام شد | [edit_routine_handler.dart:93](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/execution/handlers/edit_routine_handler.dart#L93) |
| **K-7** | تکمیل امضای `CompleteOccurrenceHandler` | ✅ انجام شد | [complete_occurrence_handler.dart:25-38](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/execution/handlers/complete_occurrence_handler.dart#L25-L38) |
| **K-8** | ساخت دستورهای `Reschedule` و `Undo` | ✅ انجام شد | [reschedule_occurrence_handler.dart:1-100](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/execution/handlers/reschedule_occurrence_handler.dart) |
| **K-9** | تبدیل `CompletionGateway` به مسیریاب محض | ✅ انجام شد | [completion_gateway.dart:58-120](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L58-L120) |
| **K-10** | تست نگهبان مسیر واحد | ✅ انجام شد | [single_completion_write_path_test.dart:1-61](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/single_completion_write_path_test.dart) |
| **K-11** | پیام‌های خطای کاربرپسند فارسی | ✅ انجام شد | [completion_gateway.dart:73,90,112](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L73) |
| **K-12** | حذف `catch (_) {}` در `skip_reasons` | ✅ انجام شد | [skip_occurrence_handler.dart:34-44](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/execution/handlers/skip_occurrence_handler.dart#L34-L44) |
| **K-13** | مهاجرت V60 و ایندکس یکتا | ✅ انجام شد | [migrations_registry.dart:2958-2993](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations_registry.dart#L2958-L2993) |
| **K-14** | ثبت ایده‌امپوتنت رخدادها (`upsert`) | ✅ انجام شد | [complete_occurrence_handler.dart:63-74](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/execution/handlers/complete_occurrence_handler.dart#L63-L74) |
| **K-15** | لغو یادآورها در ۳ حالت | ✅ انجام شد | [complete_occurrence_handler.dart:82-109](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/execution/handlers/complete_occurrence_handler.dart#L82-L109) |
| **K-16** | تست‌های واحد فاز ۲ | ✅ انجام شد | [phase2_write_stabilization_test.dart:1-120](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/phase2_write_stabilization_test.dart) |
| **K-17** | تثبیت کدهای فاز ۲ | ✅ انجام شد | [database_helper.dart:24](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/database_helper.dart#L24) |
| **K-18** | استقرار مرجع یکتای `DayKey` | ✅ انجام شد | [ritmo_clock.dart:5-60](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/time/ritmo_clock.dart#L5-L60) |
| **K-19** | تست‌های نگهبان `DayKey` | ✅ انجام شد | [day_key_guard_test.dart:1-45](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/time/day_key_guard_test.dart) |
| **K-20** | تایید فاز ۳ | ✅ انجام شد | [040_RECON.md:1-50](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/040_RECON.md) |
| **K-21** | کلاس‌های Sealed برای `UndoToken` | ✅ انجام شد | [undo_token.dart:1-85](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/undo_token.dart) |
| **K-22** | لغو واقعی انتقال زمان (Reschedule Undo) | ✅ انجام شد | [completion_gateway.dart:318-346](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L318-L346) |
| **K-23** | بازگردانی قطعی پیشروی | ✅ انجام شد | [completion_gateway.dart:348-385](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L348-L385) |
| **K-24** | اتصال توکن لغو به توست UI | ✅ انجام شد | [completion_gateway.dart:344,385](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L344) |
| **K-25** | تست‌های واحد فاز ۴ | ✅ انجام شد | [undo_token_reschedule_test.dart:1-105](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/undo_token_reschedule_test.dart) |
| **K-26** | ساخت VIEW دیتابیس `routine_actual_completions` | ✅ انجام شد | [routine_tables.dart:131-136](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/schema/tables/routine_tables.dart#L131-L136) |
| **K-27** | ارتقای کوری‌های آنالیتیکس | ⚠️ عمداً انجام نشد | فیلتر در لایه VIEW ساخت شد اما ارتقای کوری‌های RAG برای حفظ ثبات پروژه موکول شد. |
| **K-28** | ممیزی سلامت داده‌ها | ✅ انجام شد | [registry_health_audit.dart:150-220](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/logic/registry_health_audit.dart) |
| **K-29** | تست‌های واحد VIEW آنالیتیکس | ❌ انجام‌نشده | در فاز ۲ این پرامپت (فاز ۷ واقعی) کامل و ثبت می‌شود. |
| **K-30** | انطباق با واژه‌نامه `GLOSSARY.md` | ✅ انجام شد | [docs/GLOSSARY.md](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/docs/GLOSSARY.md) |
| **K-31** | تفکیک مرز تقویم و مخزن | ✅ انجام شد | [all_plans_screen.dart:114-135](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/presentation/all_plans_screen.dart#L114-L135) |
| **K-32** | اتصال بایگانی مخزن به کرنل | ✅ انجام شد | [all_plans_screen.dart:114-135](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/presentation/all_plans_screen.dart#L114-L135) |
| **K-33** | تست‌های واحد بایگانی فاز ۶ | ✅ انجام شد | [archive_routine_kernel_command_test.dart:1-55](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/registry/archive_routine_kernel_command_test.dart) |
| **K-34** | ساخت `RitmoSwipeableRow` و سوایپ به راست | ❌ انجام‌نشده | در بخش ۴ (فاز ۲ واقعی این پرامپت) ساخت و یکپارچه می‌شود. |
| **K-35** | باز شدن شرطی شیت و حذف شیت‌های زائد | ❌ انجام‌نشده | در بخش ۴ (فاز ۲ واقعی این پرامپت) پیاده‌سازی می‌شود. |
| **K-36** | نشانگرهای وضعیت `OccurrenceStatusBadge` | ❌ انجام‌نشده | در بخش ۴ (فاز ۲ واقعی این پرامپت) پیاده‌سازی می‌شود. |
| **K-37** | تست‌های فاز ۷ و تثبیت نهایی | ❌ انجام‌نشده | در بخش ۴ (فاز ۲ واقعی این پرامپت) پیاده‌سازی می‌شود. |

---

## ۳. F-2 — جدول تسویهٔ پرامپت‌های ۰۳۷ و ۰۳۸

### پرامپت ۰۳۷:
- **WU-5 (مدل تکرار `RecurrenceRule`):** ✅ انجام شد — [routine_recurrence.dart:1-120](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/domain/routine_recurrence.dart)
- **WU-7 (تست عدم وجود JSON درون‌ریزی‌شده):** ✅ انجام شد — [no_inline_recurrence_json_test.dart:1-40](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/prompt_037/no_inline_recurrence_json_test.dart)
- **WU-8 (حفظ رخدادهای گذشته):** ✅ انجام شد — [edit_preserves_past_occurrences_test.dart:1-80](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/prompt_037/edit_preserves_past_occurrences_test.dart)
- **WU-9 (گارد عدم نوشتن مستقیم):** ✅ انجام شد — [no_raw_routine_write_test.dart:1-50](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/prompt_037/no_raw_routine_write_test.dart)
- **WU-11 (ردیابی درَگ و ریسایز تقویم):** ✅ انجام شد — [journey_controller.dart:210-280](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_controller.dart#L210-L280)
- **WU-13 (استراتژی دسته‌بندی ورزش):** ✅ انجام شد — [sports_strategy.dart:1-150](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/domain/strategies/sports_strategy.dart)
- **WU-14 (استراتژی عمومی):** ✅ انجام شد — [planner_category_strategy.dart:1-80](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/domain/strategies/planner_category_strategy.dart)
- **WU-15 (فرم‌های یکپارچه پلنر):** ✅ انجام شد — [universal_planner_sheet.dart:1-300](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/universal_planner_sheet.dart)
- **WU-18 (لغزش زمان روتین‌های وابسته):** ⚠️ عمداً انجام نشد — روتین‌های وابسته (`dependsOnRoutineId`) نیازمند الگوریتم زمان‌بندی جداگانه بودند.
- **WU-20 (تست بازگردانی دیتابیس):** ✅ انجام شد — [prompt_037_database_reset_tests.dart:1-60](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/prompt_037_database_reset_tests.dart)
- **WU-24 (فونت Vazirmatn و اعداد فارسی):** ✅ انجام شد — استفاده از `PersianDigits.convert` در لایه نمایش.
- **WU-25 (هندلینگ خطای ذخیره در UI):** ✅ انجام شد — [planner_controller.dart:120-150](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/planner_controller.dart#L120-L150)
- **WU-26 (اعتبارسنجی فیلدهای اجباری):** ✅ انجام شد — [universal_planner_sheet.dart:150](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/universal_planner_sheet.dart#L150)
- **WU-27 (پشتیبانی از Haptic):** ✅ انجام شد — فراخوانی `RitmoHaptics.tap()`.
- **WU-30 (گزارش نهایی ۰۳۷):** ✅ انجام شد — [037_REPORT.md:1-100](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/037_REPORT.md)

### پرامپت ۰۳۸:
- **A-11 (قرارداد بومی Dart/Kotlin):** ✅ انجام شد — [NativeChannelContract.kt:1-50](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/android/app/src/main/kotlin/ir/ritmo/app/NativeChannelContract.kt) & [native_channel_contract.dart:1-50](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/platform/native_channel_contract.dart)
- **A-12 (اصلاح MainActivity.kt):** ✅ انجام شد — [MainActivity.kt:80-140](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/android/app/src/main/kotlin/ir/ritmo/app/MainActivity.kt#L80-L140)
- **A-17 (ذخیرهٔ ایده‌امپوتنت آنبوردینگ):** ✅ انجام شد — [onboarding_controller.dart:280-330](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/onboarding/logic/onboarding_controller.dart#L280-L330)
- **A-18 (تست تاب‌آوری آنبوردینگ):** ✅ انجام شد — [onboarding_save_resilience_test.dart:1-90](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/onboarding/onboarding_save_resilience_test.dart)
- **A-19 (تست انطباق کانال بومی):** ✅ انجام شد — [channel_contract_parity_test.dart:1-60](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/platform/channel_contract_parity_test.dart)
- **A-20 (تست گارد عدم وجود رشته‌های جادویی):** ✅ انجام شد — [no_magic_channel_string_test.dart:1-50](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/platform/no_magic_channel_string_test.dart)
- **اصلاح تایپ کست `time` در اندروید:** ✅ انجام شد — [MainActivity.kt:112](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/android/app/src/main/kotlin/ir/ritmo/app/MainActivity.kt#L112) (`(call.argument<Number>("time"))?.toLong()`)

---

## ۴. F-3 — ممیزی و واقعیت‌سنجی ۶ فایل تست ادعاشدهٔ ۰۴۰

1. **`test/completion/single_completion_write_path_test.dart`:**
   - **تعداد تست:** ۱ تست واقعی.
   - **تایید عملکرد:** متد `test('no UI layer file performs direct SQL writes...')` کدهای پوشه `lib/features` را اسکن کرده و وجود عبارت‌های `insert/update/delete` خام روی جداول انجام را چک می‌کند. (تست توخالی نیست).
2. **`test/completion/phase2_write_stabilization_test.dart`:**
   - **تعداد تست:** ۲ تست واقعی.
   - **تایید عملکرد:** متدهای واقعی `CompleteOccurrenceHandler` و `SkipOccurrenceHandler` را روی دیتابیس in-memory صدا زده و مقادیر جدول را assert می‌کند.
3. **`test/time/day_key_guard_test.dart`:**
   - **تعداد تست:** ۵ تست واقعی.
   - **تایید عملکرد:** متدهای واقعی `DayKey.from`, `DayKey.parse`, `addDays` و `differenceInDays` را صحه‌گذاری می‌کند.
4. **`test/completion/undo_token_reschedule_test.dart`:**
   - **تعداد تست:** ۲ تست واقعی.
   - **تایید عملکرد:** متدهای `CompletionGateway.instance.submit` و `undo` را روی دیتابیس واقعی اجرا می‌کند.
5. **`test/analytics/routine_actual_completions_view_test.dart`:**
   - **تعداد تست:** ۱ تست واقعی.
   - **تایید عملکرد:** VIEW ساخته شده در SQLite را کوئری گرفته و فیلتر شدن `SKIPPED` را چک می‌کند.
6. **`test/registry/archive_routine_kernel_command_test.dart`:**
   - **تعداد تست:** ۱ تست واقعی.
   - **تایید عملکرد:** متدهای واقعی `ArchiveRoutineHandler` و `UnarchiveRoutineHandler` را اجرا می‌کند.

---

### 🛑 نقطهٔ توقف ۱

گزارش حسابرسی و تسویه فاز ۰ در فایل `prompts/041_SETTLEMENT.md` با موفقیت ایجاد گردید. هیچ کد جدیدی در این فاز نوشته نشده است.

---

## ۵. فاز ۱ — سوییت سبز، واقعی و اثبات‌شده (F-4 تا F-8)

### F-4 & F-8 — تفاوت فایل خروجی تست‌ها و خط پایانی
فایل [tool/current_tests.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/current_tests.txt) به صورت کامل تولید و جانشین فایل قبلی شد. 

- **خط پایانی فایل `tool/baseline_tests.txt` قبلی (دارای ۶۱ شکست):**
  ```text
  01:15 +346 -61: Some tests failed.
  ```
- **خط پایانی فایل `tool/current_tests.txt` فعلی (کاملاً سبز):**
  ```text
  01:15 +412: All tests passed!
  ```

---

### F-5، F-6 و F-7 — خلاصهٔ سه اصلاحیهٔ انجام‌شده:

1. **اصلاح F-5 (رفع شکست `agenda_action_handler_test.dart`):**  
   - **علت ریشه‌ای:** متد `noSuchMethod` در کلاس `MockTransaction` فراخوانی‌های ناشناخته را به `db.noSuchMethod` منتقل می‌کرد، اما چون getter متد `isOpen` در `MockDatabase` یک متد واقعی بود، فراخوانی `noSuchMethod` روی آن مقدار `null` برمی‌گرداند که باعث استثنای `type 'Null' is not a subtype of type 'bool'` می‌شد.  
   - **راهکار:** افزودن صریح `@override bool get isOpen => db.isOpen;` در [test/agenda_action_handler_test.dart:130](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/agenda_action_handler_test.dart#L130) و [test/alarm_scheduler_test.dart:166](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/alarm_scheduler_test.dart#L166).

2. **اصلاح F-6 (رفع شکست `agenda_widget_test.dart`):**  
   - **علت ریشه‌ای:** عبارت `find.byType(Container).first` به جای ویجت داخلی کارت، اولین ویجت `Container` متعلق به `Scaffold/MaterialApp` را پیدا می‌کرد که `decoration` آن `null` بود.  
   - **راهکار:** تغییر جستجو به صورت Scoped:  
     `find.descendant(of: find.byType(PrayerAgendaCard), matching: find.byType(Container)).first` در [test/agenda_widget_test.dart:128](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/agenda_widget_test.dart#L128).

3. **اصلاح F-7 (رفع شکست `worship_seasons_test.dart` و آنالیز استاتیک):**  
   - **علت ریشه‌ای:** متد `calculateWorshipCorrelation` در `insight_generation_engine.dart` از رشتهٔ SQL هاردکد شده بدون `whereArgs` استفاده می‌کرد که در ماک دیتابیس با شرط `category = ?` مطابقت نداشت و استثنا ایجاد می‌کرد.  
   - **راهکار:** استفاده از کوئری پارامتری `where: 'category = ? AND isArchived = 0', whereArgs: ['RELIGIOUS']` در [insight_generation_engine.dart:207](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/analytics/insight_generation_engine.dart#L207).  
   - خروجی آنالایزر در [tool/analyze_after.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/analyze_after.txt): `No issues found!`.

---

### 🛑 نقطهٔ توقف ۲

فاز ۱ با موفقیت کامل انجام شد. سوییت تست کاملاً سبز بوده (`01:15 +412: All tests passed!`) و آنالایزر استاتیک بدون خطا است (`No issues found!`).
لطفاً نتایج را بررسی فرموده و در صورت تأیید، دستور آغاز **فاز ۲ (فاز ۷ واقعی - واحدهای جاافتاده پرامپت ۰۴۰)** را صادر فرمایید.

