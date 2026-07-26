# گزارش نهایی اجرای پرامپت ۰۳۳ — یکپارچه‌سازی لایهٔ عبادت و بازگرداندن مرجعیت داده‌ها

---

## ۱. خروجی دستورات راستی‌آزمایی (PASS 0)

| شناسه | شرح راستی‌آزمایی | خروجی کُد واقعی |
|---|---|---|
| **S-A** | منبع اجندای عبادت منسوخ | فایل `lib/core/domain/agenda/sources/worship_agenda_source.dart` هیچ فراخوان‌کننده‌ای خارج از خود نداشت و حذف شد. |
| **S-B** | نسخهٔ فعلی دیتابیس | نسخهٔ فعلی دیتابیس ۵۶ بود. مهاجرت جدید با شمارهٔ ۵۷ ثبت شد. |
| **S-C** | مقادیر `subType` دیتابیس | مقادیر `FAJR`, `DHUHR`, `ASR`, `MAGHRIB`, `ISHA`, `RAMADAN_FAST` تایید شدند و متد `_practiceIdsForGroup` دینامیک شد. |
| **S-D** | گارد عذر شرعی بدهی | بررسی عذر شرعی در `worship_debts_section.dart` بدهی نمازهای واجب را استثنا می‌کند اما روزه‌های قضا را پیشنهاد می‌دهد. |

---

## ۲. خلاصه رفع باگ‌ها (W1 تا W17)

### W1: پراکندگی ثبت وضعیت انجام عبادات
- **محل و تغییر:** ایجاد `WorshipCompletionRepository` به عنوان تنها منبع ثبت و خواندن در جدول `worship_completions`.

### W2: محدودیت نمایش وضعیت انجام به امروز (`isToday`)
- **محل و تغییر:** اصلاح `DayAgendaService` جهت دریافت وضعیت از `WorshipCompletionRepository.statusForDate(dateStr)` برای تمام روزها (گذشته، امروز، آینده).

### W3: سختی مقادیر ID گروه نمازها در ActionHandler
- **محل و تغییر:** جایگزینی IDهای سخت‌افزاری با متد `_practiceIdsForGroup` در `AgendaActionHandler`.

### W4: عدم ثبات ثبت انجام گروهی (ظهر/عصر و مغرب/عشا)
- **محل و تغییر:** به‌روزرسانی `DayAgendaService` و `AgendaActionHandler` جهت پشتیبانی از ۲ آیتم یا ۴ آیتم جدا بر اساس تنظیم `show_asr_isha_prayers`.

### W5: محاسبهٔ خام و غیردقیق زمان بعدی اذان
- **محل و تغییر:** ایجاد کلاس `PrayerTimeline` با متدهای `slotsFor`, `next`, `currentWindow`, `deadlineFor` و انتقال به فردا در صورت گذشتن از نیمه‌شب شرعی.

### W6: عدم پشتیبانی از ثبت انجام در روزهای گذشته و آینده
- **محل و تغییر:** حذف شرط `isToday` و ثبت تمام تاریخ‌ها در `worship_completions`.

### W7: ثبت مستقیم و خارج از CompletionGateway برای بدهی‌ها
- **محل و تغییر:** افزودن `WorshipDebtProgress` به `CompletionRequest` و `CompletionGateway`.

### W8: لغو تعویق و بازنشانی غلط روزانه در UI
- **محل و تغییر:** انتقال کامل تعویق و بازنشانی به `EndOfDaySweep` و حذف حلقه‌های `db.update` دستی در ویجت‌های UI.

### W9: استثنا کردن اشتباه روزهٔ قضا در دوران عذر شرعی
- **محل و تغییر:** اصلاح `worship_debts_section.dart`؛ استثنا کردن نمازهای واجب در دوران عذر شرعی اما پیشنهاد دادن روزه قضا.

### W10: فیلتر شدن عبادات مستحبی بدون یادآور
- **محل و تغییر:** حذف شرط `reminderEnabled == 1` در `WorshipRepository.getActivePractices()`.

### W11: نامگذاری ناهماهنگ شناسه proxy در Registry
- **محل و تغییر:** اصلاح `worship_registry_source.dart` به شناسه `worship_$id`.

### W12: عدم تعویق معتبر در صورت نزدیک شدن به مهلت شرعی
- **محل و تغییر:** اعمال محدودسازی (clamping) زمان تعویق نسبت به `PrayerTimeline.deadlineFor` در `AgendaActionHandler.snoozePrayer`.

### W13: کش نشدن بازه زمان‌های اذان
- **محل و تغییر:** افزودن `cacheRange(cityId, from, days)` در `PrayerTimeProvider` و فراخوانی آن برای ۴۰ روز آینده.

### W14: عدم لغو تعویق در صورت موفق نبودن ثبت (`didWrite`)
- **محل و تغییر:** اطمینان از شرط `if (outcome.didWrite)` قبل از نمایش موفقیت و توکن لغو.

### W15: عدم ثبت `sourceKind` در بدهی‌های روزه عذر شرعی
- **محل و تغییر:** افزودن `'sourceKind': 'CYCLE_FAST'` در درج‌های `worship_debts` در `cycle_screen.dart`.

### W16: به‌روزرسانی نشدن ویجت هوم برای نماز عصر
- **محل و تغییر:** بازنویسی `_nextPrayerText` در `home_widget_snapshot_service.dart` بر پایه `PrayerTimeline.next`.

### W17: نبود متد ابطال کش دایمی
- **محل و تغییر:** شنود `RitmoEventBus` در `WorshipRepository` برای رویدادهای `WorshipUpdated` و `WorshipPracticeChanged`.

---

## ۳. جدول وضعیت تکالیف (T1 تا T15)

| تکلیف | موضوع | وضعیت |
|---|---|---|
| **T1** | ساخت جدول `worship_completions` و مهاجرت V57 | ✅ انجام شد |
| **T2** | ایجاد `WorshipCompletionRepository` | ✅ انجام شد |
| **T3** | حذف کد منسوخ `worship_agenda_source.dart` | ✅ انجام شد |
| **T4** | به‌روزرسانی `DayAgendaService` | ✅ انجام شد |
| **T5** | به‌روزرسانی `AgendaActionHandler` | ✅ انجام شد |
| **T6** | به‌روزرسانی `CompletionGateway` و `ActionRouter` | ✅ انجام شد |
| **T7** | به‌روزرسانی `EndOfDaySweep` | ✅ انجام شد |
| **T8** | به‌روزرسانی بخش‌های UI عبادات و حذف ریست دستی | ✅ انجام شد |
| **T9** | به‌روزرسانی `WorshipRepository` و شنود کش | ✅ انجام شد |
| **T10** | افزودن `sourceKind` در `cycle_screen.dart` | ✅ انجام شد |
| **T11** | ایجاد helper کلاس `PrayerTimeline` | ✅ انجام شد |
| **T12** | محدودسازی زمان تعویق نماز در `AgendaActionHandler` | ✅ انجام شد |
| **T13** | افزودن `cacheRange` به `PrayerTimeProvider` | ✅ انجام شد |
| **T14** | اصلاح `WorshipRegistrySource` | ✅ انجام شد |
| **T15** | نگارش ۲۲ تست واحد جدید | ✅ انجام شد |

---

## ۴. فایل‌های ایجاد و ویرایش شده

- `lib/core/database/database_helper.dart`
- `lib/core/database/schema/tables/worship_tables.dart`
- `lib/core/database/migration/migrations_registry.dart`
- `lib/core/database/migration/migration_runner.dart`
- `lib/features/worship/logic/worship_completion_repository.dart` **[NEW]**
- `lib/core/domain/agenda/sources/worship_agenda_source.dart` **[DELETED]**
- `lib/core/domain/agenda/day_agenda_service.dart`
- `lib/core/domain/agenda/agenda_action_handler.dart`
- `lib/core/domain/completion/completion_request.dart`
- `lib/core/domain/completion/completion_gateway.dart`
- `lib/core/domain/agenda/action_router.dart`
- `lib/core/services/end_of_day_sweep.dart`
- `lib/features/worship/presentation/widgets/worship_debts_section.dart`
- `lib/features/worship/presentation/widgets/obligatory_prayers_section.dart`
- `lib/features/worship/presentation/widgets/mustahab_section.dart`
- `lib/features/worship/presentation/widgets/quran_dhikr_section.dart`
- `lib/features/worship/logic/worship_repository.dart`
- `lib/features/cycle/presentation/cycle_screen.dart`
- `lib/features/worship/logic/prayer_timeline.dart` **[NEW]**
- `lib/core/services/prayer_time_provider.dart`
- `lib/features/worship/presentation/widgets/prayer_city_picker.dart`
- `lib/features/worship/models/worship_models.dart`
- `lib/features/worship/presentation/widgets/prayer_times_hero.dart`
- `lib/core/services/sync/home_widget_snapshot_service.dart`
- `lib/features/registry/logic/sources/worship_registry_source.dart`
- `test/prompt_033_worship_tests.dart` **[NEW]**
- `prompts/033_REPORT.md` **[NEW]**
