# گزارش فاز ۰ (شناسایی و سرشماری مسیرهای ثبت انجام و داده‌ها) — `prompts/039_RECON.md`

تاریخ بررسی: ۲۹ ژوئیه ۲۰۲۶  
نویسنده: مهندس ارشد نرم‌افزار (Antigravity AI)

---

## K-0 — سرشماری کامل مسیرهای نوشتن در `routine_completions` و `routine_occurrences`

تمامی فایل‌ها به صورت فیزیکی باز گردیده و با شماره خط دقیق استخراج شده‌اند (بدون هیچ علامت «...» یا حدسیات):

| فایل | خط | جدول | عملیات | از طریق کرنل؟ | توضیحات |
| :--- | :---: | :--- | :---: | :---: | :--- |
| `lib/core/database/seed/mock_data_seeder.dart` | 664 | `routine_occurrences` | INSERT | ❌ خیر | دیتای اولیه آزمایشی |
| `lib/core/database/seed/mock_data_seeder.dart` | 672 | `routine_completions` | INSERT | ❌ خیر | دیتای اولیه آزمایشی |
| `lib/core/database/migration/migrations_registry.dart` | 2853-2855 | `routine_completions` / `routine_occurrences` | DELETE | ❌ خیر | مهاجرت دیتابیس V58 |
| `lib/core/domain/completion/completion_gateway.dart` | 64 | `routine_completions` | INSERT | ❌ خیر | ثبت روتین مستقیم در گیت‌وی |
| `lib/core/domain/completion/completion_gateway.dart` | 78-80 | `routine_occurrences` | UPDATE | ❌ خیر | به‌روزرسانی وضعیت به `done` |
| `lib/core/domain/completion/completion_gateway.dart` | 96 | `routine_completions` | INSERT | ❌ خیر | ثبت رد روتین در گیت‌وی |
| `lib/core/domain/completion/completion_gateway.dart` | 120-122 | `routine_occurrences` | UPDATE | ❌ خیر | به‌روزرسانی وضعیت به `skipped` |
| `lib/core/domain/completion/completion_gateway.dart` | 145-147 | `routine_occurrences` | UPDATE | ❌ خیر | به‌روزرسانی وضعیت مبدأ تعویق |
| `lib/core/domain/completion/completion_gateway.dart` | 150 | `routine_completions` | INSERT | ❌ خیر | ثبت تعویق در گیت‌وی |
| `lib/core/domain/completion/completion_gateway.dart` | 195-197 | `routine_occurrences` | UPDATE | ❌ خیر | به‌روزرسانی وضعیت مبدأ تعویق |
| `lib/core/domain/completion/completion_gateway.dart` | 200 | `routine_occurrences` | INSERT | ❌ خیر | ساخت رخداد مقصد تعویق |
| `lib/core/domain/completion/completion_gateway.dart` | 219 | `routine_completions` | INSERT | ❌ خیر | ثبت تعویق در گیت‌وی |
| `lib/core/domain/completion/completion_gateway.dart` | 421 | `routine_completions` | DELETE | ❌ خیر | لغو (Undo) روتین |
| `lib/core/domain/completion/completion_gateway.dart` | 424-426 | `routine_occurrences` | UPDATE | ❌ خیر | لغو وضعیت رخداد به `pending` |
| `lib/core/domain/completion/completion_gateway.dart` | 448 | `routine_completions` | DELETE | ❌ خیر | لغو (Undo) روتین با شناسه |
| `lib/core/domain/completion/completion_gateway.dart` | 451-453 | `routine_occurrences` | UPDATE | ❌ خیر | لغو وضعیت رخداد به `pending` |
| `lib/core/domain/completion/completion_gateway.dart` | 536-538 | `routine_occurrences` | DELETE | ❌ خیر | لغو تعویق روتین |
| `lib/core/domain/completion/completion_gateway.dart` | 542-544 | `routine_occurrences` | UPDATE | ❌ خیر | بازگردانی رخداد مبدأ تعویق |
| `lib/core/domain/completion/completion_gateway.dart` | 554 | `routine_completions` | DELETE | ❌ خیر | حذف رکورد تعویق |
| `lib/core/domain/execution/handlers/complete_occurrence_handler.dart` | 24 | `routine_completions` | INSERT | ✅ بله | هندلر کرنل ثبت انجام روتین |
| `lib/core/domain/execution/handlers/complete_occurrence_handler.dart` | 61-63 | `routine_occurrences` | UPDATE | ✅ بله | هندلر کرنل به‌روزرسانی وضعیت رخداد |
| `lib/core/domain/execution/handlers/skip_occurrence_handler.dart` | 23 | `routine_completions` | INSERT | ✅ بله | هندلر کرنل ثبت رد روتین |
| `lib/core/domain/execution/handlers/skip_occurrence_handler.dart` | 35-37 | `routine_occurrences` | UPDATE | ✅ بله | هندلر کرنل به‌روزرسانی وضعیت رد روتین |
| `lib/core/domain/execution/handlers/delete_routine_handler.dart` | 37 | `routine_occurrences` | DELETE | ✅ بله | حذف رخدادهای روتین حذف‌شده |
| `lib/core/domain/execution/handlers/delete_routine_handler.dart` | 38 | `routine_completions` | DELETE | ✅ بله | حذف ثبت‌های انجام روتین حذف‌شده |
| `lib/core/domain/execution/handlers/archive_routine_handler.dart` | 58 | `routine_occurrences` | DELETE | ✅ بله | حذف رخدادهای آینده روتین بایگانی‌شده |
| `lib/core/domain/execution/handlers/edit_routine_handler.dart` | 94 | `routine_occurrences` | DELETE/INSERT | ✅ بله | بازتولید رخدادها پس از ویرایش |
| `lib/core/domain/execution/handlers/snooze_reminder_handler.dart` | 60 | `routine_occurrences` | UPDATE | ✅ بله | به‌روزرسانی تعویق یادآور |
| `lib/core/domain/engines/routine_occurrence_generator.dart` | 147-156 | `routine_occurrences` | INSERT | ❌ خیر | تولید رخدادهای ۳۰ روز آینده |
| `lib/core/domain/engines/routine_occurrence_generator.dart` | 171-175 | `routine_occurrences` | DELETE | ❌ خیر | پاک‌سازی رخدادهای آینده قبل از تولید مجدد |
| `lib/core/domain/engines/routine_occurrence_generator.dart` | 186-189 | `routine_occurrences` | DELETE | ❌ خیر | پاک‌سازی تمامی رخدادها هنگام حذف روتین |
| `lib/core/domain/engines/routine_occurrence_generator.dart` | 263-272 | `routine_occurrences` | INSERT | ❌ خیر | بک‌فیل ۳۰ روز گذشته و آینده در استارت اپ |
| `lib/core/services/alarm_scheduler_service.dart` | 314 | `routine_completions` | INSERT | ❌ خیر | ثبت انجام خودکار آلارم/تایمر سرویس پیش‌زمینه |
| `lib/core/services/alarm_scheduler_service.dart` | 332 | `routine_occurrences` | UPDATE | ❌ خیر | به‌روزرسانی وضعیت آلارم به done |
| `lib/core/services/alarm_scheduler_service.dart` | 450 | `routine_completions` | INSERT | ❌ خیر | ثبت انجام مستقیم پس‌زمینه |
| `lib/core/services/module_management_service.dart` | 294 | `routine_completions` | DELETE | ❌ خیر | پاک‌سازی هنگام غیرفعال کردن ماژول |
| `lib/features/assistant/logic/assistant_action_registry.dart` | 435 | `routine_completions` | INSERT | ❌ خیر | ثبت مستقیم انجام توسط دستیار هوشمند |

---

## K-1 — سرشماری مصرف‌کنندگان (`CompletionGateway` vs `RitmoExecutionKernel`)

### ۱. مصرف‌کنندگانی که از `CompletionGateway.instance.submit(...)` استفاده می‌کنند:
- [routine_actions.dart:22](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/shared/routine_actions.dart#L22) ➔ اکشن‌های مستقیم شیت روتین
- [prayer_action_body.dart:51](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/prayer_action_body.dart#L51) ➔ ثبت نمازها
- [worship_debts_section.dart:130](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/worship_debts_section.dart#L130) ➔ ثبت پیشرفت بدهی عبادی

### ۲. مصرف‌کنندگانی که مستقیماً `RitmoExecutionKernel.instance.execute(...)` را صدا می‌زنند:
- [now_dashboard_screen.dart:624](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart#L624) ➔ دکمه ثبت انجام داشبورد اصلی
- [journey_controller.dart:191](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_controller.dart#L191) ➔ ثبت انجام تقویم (CompleteOccurrenceCommand)
- [journey_controller.dart:220](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_controller.dart#L220) ➔ رد روتین در تقویم (SkipOccurrenceCommand)
- [today_calendar_convergence_helper.dart:69](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/logic/today_calendar_convergence_helper.dart#L69) ➔ همگرایی داشبورد و تقویم
- [medications_section.dart:252, 362](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/health/presentation/widgets/medications_section.dart#L252) ➔ ثبت مصرف دارو
- [notification_action_dispatcher.dart:36, 143](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/notification_action_dispatcher.dart#L36) ➔ ثبت انجام از اکشن نوتیفیکیشن اندروید

**نتیجه:** رفتار اپ کاملاً دوگانه و چندمسیره است.

---

## K-2 — اسکیمای دقیق دیتابیس (خواندن از `routine_tables.dart`)

### ۱. جدول `routine_completions` (خطوط ۸۱ تا ۱۰۱):
- `id`: `TEXT PRIMARY KEY` (`NOT NULL`)
- `routineId`: `TEXT NOT NULL`
- `completionDate`: `TEXT NOT NULL` (فرمت: `yyyy-MM-dd`)
- `completionTime`: `INTEGER NOT NULL` (میلی‌ثانیه UTC)
- `resultType`: `TEXT NOT NULL`
- `resultSource`: `TEXT NOT NULL DEFAULT 'USER'`
- `debtId`: `TEXT` (اختیاری)
- `durationMinutes`: `INTEGER` (اختیاری)
- `delayMinutes`: `INTEGER` (اختیاری)
- `note`: `TEXT` (اختیاری)
- `actual_duration_minutes`: `INTEGER` (اختیاری)
- `createdAt`: `INTEGER NOT NULL`
- **محدودیت UNIQUE روی `(routineId, completionDate)`:** ❌ وجود ندارد.
- **ایندکس‌ها:**
  - `index_routine_completions_routineId` روی `routineId`
  - `index_routine_completions_completionDate` روی `completionDate`

### ۲. جدول `routine_occurrences` (خطوط ۱۰۲ تا ۱۱۵):
- `routine_id`: `TEXT NOT NULL`
- `date`: `TEXT NOT NULL` (فرمت: `yyyy-MM-dd`)
- `scheduled_time`: `TEXT` (اختیاری، مثلاً `'08:00'`)
- `status`: `TEXT NOT NULL DEFAULT 'pending'`
- **کلید اصلی (PRIMARY KEY):** `PRIMARY KEY (routine_id, date)` ➔ این یعنی محدودیت UNIQUE روی ترکیب `(routine_id, date)` برقرار است.
- **ایندکس‌ها:**
  - `index_routine_occurrences_routine_id` روی `routine_id`
  - `index_routine_occurrences_date` روی `date`

### ۳. مقادیر مجاز در عمل:
- **`status` در `routine_occurrences`:** `'pending'`, `'done'`, `'skipped'`, `'rescheduled'`.
- **`resultType` در `routine_completions`:** `'FULL'`, `'PARTIAL'`, `'MINIMAL'`, `'SKIPPED'`, `'RESCHEDULED'`, `'DONE'`.
- **`resultSource` در `routine_completions`:** `'USER'`, `'NOTIFICATION'`, `'TIMER'`, `'AUTO'`.

---

## K-3 — امضای دقیق موتور پیشروی (`ProgressionEngine`)

- **فایل:** `lib/core/domain/engines/progression_engine.dart`
- **امضای متد `onCompletion` (خط ۲۲):**
  ```dart
  Future<void> onCompletion(DatabaseExecutor db, String routineId, [CompletionResult? result]) async
  ```
- **علت کامپایل دو فراخوانی با آرگومان‌های متفاوت:** پارامتر سوم `[CompletionResult? result]` یک پارامتر اختیاری موقعیتی (Optional Positional Parameter) است. فراخوانی با ۲ آرگومان یا ۳ آرگومان در دارت مجاز است.
- **متد معکوس (`onUndo` یا مشابه):** ❌ **وجود ندارد!** لغو انجام روتین پیشروی را عقب نمی‌برد.
- **ستون‌هایی که در جدول `routines` تغییر می‌دهد (خطوط ۵۲ تا ۶۱):**
  - `progressionCurrent` (مقدار پیشروی فعلی)
  - `progressionDoneSinceAdvance` (تعداد انجام‌ها از آخرین ارتقا)
  - `updatedAt` (میلی‌ثانیه زمان ویرایش)

---

## K-4 — بدنهٔ کامل `_notifySuccess` در `completion_gateway.dart`

**خطوط ۵۷۴ تا ۵۹۴ در `completion_gateway.dart`:**
```dart
  void _notifySuccess({
    required String domain,
    required String itemId,
    required String dateStr,
    required String result,
  }) {
    DayAgendaService.instance.invalidateDate(dateStr);
    RitmoEventBus().fire(
      RitmoEvent(
        type: RitmoEventType.completionRecorded.code,
        timestamp: DateTime.now(),
        payload: {
          'domain': domain,
          'itemId': itemId,
          'dateStr': dateStr,
          'result': result,
          'didWrite': true,
        },
      ),
    );
  }
```
- **بررسی عملکرد:**
  - آیا `DayAgendaService.instance.invalidateDate(dateStr)` را صدا می‌زند؟ ✅ بله.
  - آیا رویداد به `RitmoEventBus` می‌فرستد؟ ✅ بله (`RitmoEventType.completionRecorded`).
  - آیا ویجت بومی را تازه (refresh) می‌کند؟ ❌ **خیر!** هیچ فراخوانی به `NativeBridge.refreshWidgets()` یا `SnapshotHelper` ندارد.

---

## K-5 — محل و نحوهٔ کار تولیدکننده رخدادها (`RoutineOccurrenceGenerator`)

- **فایل:** `lib/core/domain/engines/routine_occurrence_generator.dart`
- **افق تولید رخدادها:** ۳۰ روز آینده (`days = 30` در متد `generateFutureOccurrences`).
- **زمان‌های اجرای مجدد:**
  - هنگام ساخت روتین جدید (`CreateRoutineHandler:44`)
  - هنگام ویرایش روتین (`EditRoutineHandler:94`)
  - هنگام بایگانی روتین (`ArchiveRoutineHandler:58`)
  - هنگام استارت اپلیکیشن (`AlarmSchedulerService:397` از طریق `backfillAndGenerateAll`).
- **آیا رخدادهای گذشته را بک‌فیل می‌کند؟** ✅ بله، متد `backfillAndGenerateAll` بازه -۳۰ روز گذشته تا +۳۰ روز آینده را پیمایش کرده و رخدادهای غایب را با `ConflictAlgorithm.ignore` درج می‌کند.

---

## K-6 — بررسی تقویم و مخزن

### ۱. در `journey_screen.dart` و `journey_controller.dart`:
- `onItemResize`: متد `commitItemResize` در `journey_controller.dart:285` دستور `_ResizeItemCommand` را در `CommandStack` اجرا می‌کند که تعریف کلی روتین را در دیتابیس ویرایش می‌کند (نه فقط رخداد آن روز را).
- `onItemMove`: متد `commitItemDrag` در `journey_controller.dart:257` دستور `_MoveItemCommand` را اجرا می‌کند که زمان `timeOfDay` تعریف کل روتین را تغییر می‌دهد.
- `unscheduleItem`: زمان‌بندی روتین را حذف می‌کند.

### ۲. در `TimelineSplitDayView`:
- نمایش ۴ وضعیت:
  - `pending` ➔ نمایش در لایه زمان‌بندی‌شده بدون استایل تیک
  - `done` ➔ نمایش با آیکون سبز و خط کم‌رنگ
  - `skipped` ➔ نمایش با استایل خط‌خورده
  - `rescheduled` ➔ نمایش با نشانگر انتقال زمان

### ۳. در `all_plans_screen.dart` (مخزن روتین‌ها):
- کلیک روی سطر (خط ۴۵۷): متد `ActionRouter.open(context, item: entry.agendaProxy)` را فراخوانی کرده و شیت اقدام/ویرایشگر را باز می‌کند.
- آیکون بایگانی (خط ۴۶۶ و ۱۱۴): متد `_archiveEntry` مستقیماً کوری SQL خام `db.update('routines', {'isArchived': 1})` اجرا می‌کند!

---

### 🛑 نقطهٔ توقف ۱ — تحویل گزارش

فاز ۰ به صورت کامل انجام شد. منتظر تأیید شما جهت آغاز فاز ۱ (یک مسیر نوشتن، فقط یکی) هستم.
