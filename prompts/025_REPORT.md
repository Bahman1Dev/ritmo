# 📊 025_REPORT.md — گزارش ممیزی و یکپارچه‌سازی تکمیل (Prompt 025)

## 0. ممیزی قبل از شروع (PASS 0)

### آمار اولیه (قبل):
1. **تعداد نقاط نوشتن در `routine_completions`**: ۷ مورد در کدهای عملیاتی (`CompleteOccurrenceHandler`, `SkipOccurrenceHandler`, `AlarmSchedulerService` x2, `AssistantActionRegistry` x2, `mock_data_seeder`).
2. **بررسی resultType در کد**: شامل مقادیر هاردکد شده `'COMPLETED'`, `'LIGHT'`, `'MINIMAL'`, `'SKIPPED'`.
3. **مورد مقادیر پیش‌فرض مدت‌زمان ساختگی**: مواردی از `?? 30`, `?? 20`, `?? 10` و `_safeDur` شناسایی شدند.
4. **دستورات کرنل و هندلرهای مرتبط**: `CompleteOccurrenceCommand`, `SkipOccurrenceCommand`, `SnoozeReminderCommand` موجودند اما سرویس‌های موازی نظیر `AlarmSchedulerService` نیز مستقیم دیتابیس را ویرایش می‌کردند.
5. **وزن‌های ریتم**: مقادیر `0.4` و `0.7` در چند فایل فیلتر و محاسبه (`energy_analytics_engine`, `rhythm_snapshot_service`, `today_snapshot_context_builder`) هاردکد شده بودند.

---

## ۱. نقشه راه فازهای ۶‌گانه

- **فاز ۰ — تعمیرات داده بنیادی (T1 تا T6)**:
  - T1: پیاده‌سازی enum واحد `CompletionResult` + Migration
  - T2: حذف مدت‌زمان‌های جعلی
  - T3: تصحیح باگ تاریخ در تعویق (`SnoozeReminderCommand`)
  - T4: زنده کردن نسخه سبک (۵۰٪) و حداقلی (۱۵٪ با سقف ۱۰ دقیقه) در `DurationVariants` + اسلایدر در `planner_duration_picker`
  - T5: پیشرفت تدریجی فقط روی نسخه کامل
  - T6: پاکسازی کد مرده انرژی

- **فاز ۱ — دروازه واحد (T7 تا T13)**:
  - T7-T9: پیاده‌سازی `CompletionRequest`, `CompletionOutcome`, `CompletionGateway`
  - T10: بازنویسی کامل `SnoozePolicy` + نردبان پایان تعویق + `EndOfDaySweep` + سیگنال‌های هوشمند
  - T11-T13: هدایت تمام ۸ مسیر تکمیل به `CompletionGateway`

- **فاز ۲ — مسیریاب اقدام (T14 تا T16)**:
  - T14-T16: پیاده‌سازی `ActionRouter` و ارجاع تمام دامنه‌ها

- **فاز ۳ — اسکلت مشترک (T17 تا T23)**:
  - T17-T23: پیاده‌سازی `RitmoActionSheet` و یکپارچه‌سازی شیت دامنه‌ها

- **فاز ۴ — تایمر واحد (T24 تا T26)**:
  - T24-T26: یکپارچه‌سازی `RitmoTimerService` بر اساس `targetTimestamp`

- **فاز ۵ — ارتقاها (T27 تا T31)**:
  - T27-T31: دلایل رد کردن (`skip_reasons`)، Undo سراسری، ثبت دسته‌ای و...

- **فاز ۶ — تست و گزارش نهایی (T32 تا T33)**
