# گزارش نهایی تسویه و تکمیل — `prompts/041_REPORT.md`

**تاریخ تکمیل:** ۴ اوت ۲۰۲۶  
**پروژه:** اپلیکیشن ریتمو (`ir.ritmo.app`)  
**نویسنده:** مهندس ارشد نرم‌افزار (Antigravity AI)

---

## ۱. جدول وضعیت واحدهای کاری F-0 تا F-20

| کد کار | عنوان اقدام | وضعیت فعلی | مدرک (نام فایل + شماره خط / خروجی) |
| :--- | :--- | :---: | :--- |
| **F-0** | حسابرسی کتبی `MigrationV60` | ✅ انجام شد | [041_SETTLEMENT.md:1-30](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/041_SETTLEMENT.md) |
| **F-1** | جدول تسویه K-0 تا K-37 (پرامپت ۰۴۰) | ✅ انجام شد | [041_SETTLEMENT.md:32-75](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/041_SETTLEMENT.md) |
| **F-2** | جدول تسویه ۰۳۷ و ۰۳۸ | ✅ انجام شد | [041_SETTLEMENT.md:77-120](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/041_SETTLEMENT.md) |
| **F-3** | ممیزی و واقعیت‌سنجی ۶ فایل تست ۰۴۰ | ✅ انجام شد | [041_SETTLEMENT.md:122-140](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/041_SETTLEMENT.md) |
| **F-4** | اجرای واقعی تست‌ها | ✅ انجام شد | [tool/current_tests.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/current_tests.txt) |
| **F-5** | رفع دو تست قرمز `agenda_action_handler` | ✅ انجام شد | [test/agenda_action_handler_test.dart:130](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/agenda_action_handler_test.dart#L130) |
| **F-6** | رفع سه تست قرمز `agenda_widget_test` | ✅ انجام شد | [test/agenda_widget_test.dart:128](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/agenda_widget_test.dart#L128) |
| **F-7** | آنالیز استاتیک بدون خطا | ✅ انجام شد | [tool/analyze_after.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/analyze_after.txt) |
| **F-8** | اثبات سوییت کاملاً سبز | ✅ انجام شد | [tool/current_tests.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/current_tests.txt) |
| **F-9** | ساخت `RitmoSwipeableRow` و اصلاح سوایپ | ✅ انجام شد | [ritmo_swipeable_row.dart:1-85](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/widgets/ritmo_swipeable_row.dart) & [routine_card.dart:40](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/shared/widgets/routine_card.dart#L40) |
| **F-10** | `OccurrenceStatusBadge` (حالت ثبت‌نشده) | ✅ انجام شد | [occurrence_status_badge.dart:18-24](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/widgets/occurrence_status_badge.dart#L18-L24) |
| **F-11** | باز شدن شرطی شیت بر اساس `ActionCapabilities` | ✅ انجام شد | [action_capabilities.dart:34](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/widgets/action/action_capabilities.dart#L34) |
| **F-12** | صفحهٔ پایش سلامت داده‌ها (`DataHealthScreen`) | ✅ انجام شد | [data_health_screen.dart:1-140](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/dev/presentation/data_health_screen.dart) |
| **F-13** | تست‌های سوایپ و باز شدن شرطی | ✅ انجام شد | [swipe_completes_routine_test.dart:1-35](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/widget/swipe_completes_routine_test.dart) |
| **F-14** | تست نگهبان واژه‌نامه (`GLOSSARY.md`) | ✅ انجام شد | [terminology_test.dart:1-30](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/terminology_test.dart) |
| **F-15** | تست‌های نگهبان ایده‌امپوتنت و لغو | ✅ انجام شد | [phase2_write_stabilization_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/phase2_write_stabilization_test.dart) & [undo_token_reschedule_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/completion/undo_token_reschedule_test.dart) |
| **F-16** | پاک‌سازی الگوها در مهاجرت V59/V60 | ✅ انجام شد | [migrations_registry.dart:2903](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations_registry.dart#L2903) |
| **F-17** | محاسبهٔ زمان در لایه دامنه‌ای | ✅ انجام شد | [duration_bounds.dart:14-34](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/models/duration_bounds.dart#L14-L34) |
| **F-18** | مستندساری تصمیم محل `DayKey` | ✅ انجام شد | استقرار در `ritmo_clock.dart` به عنوان مرجع واحد زمان و کلید روزانه |
| **F-19** | خروجی‌های به روز و نقل خط پایانی | ✅ انجام شد | [tool/current_tests.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/current_tests.txt) & [tool/analyze_after.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/analyze_after.txt) |
| **F-20** | ثبت گزارش نهایی `041_REPORT.md` | ✅ انجام شد | فایل فعلی. |

---

## ۲. فهرست فایل‌های ساخته‌شده، تغییریافته و حذف‌شده

### فایل‌های جدید ساخته‌شده:
1. `lib/core/widgets/ritmo_swipeable_row.dart`
2. `lib/core/widgets/occurrence_status_badge.dart`
3. `lib/features/dev/presentation/data_health_screen.dart`
4. `test/widget/swipe_completes_routine_test.dart`
5. `test/widget/occurrence_status_badge_test.dart`
6. `test/terminology_test.dart`
7. `prompts/041_SETTLEMENT.md`
8. `prompts/041_REPORT.md`

### فایل‌های تغییریافته:
1. `lib/features/routines/shared/widgets/routine_card.dart`
2. `lib/core/widgets/action/action_capabilities.dart`
3. `lib/core/domain/models/duration_bounds.dart`
4. `lib/features/today/presentation/now_dashboard_screen.dart`
5. `lib/core/database/migration/migrations_registry.dart`
6. `lib/core/analytics/insight_generation_engine.dart`
7. `test/agenda_action_handler_test.dart`
8. `test/agenda_widget_test.dart`
9. `test/alarm_scheduler_test.dart`
10. `tool/current_tests.txt`
11. `tool/analyze_after.txt`

---

## ۳. نقل خط پایانی دستورات واقعی

- **خروجی پایانی `flutter test` (محتوای `tool/current_tests.txt`):**
  ```text
  01:15 +412: All tests passed!
  ```
- **خروجی پایانی `flutter analyze` (محتوای `tool/analyze_after.txt`):**
  ```text
  No issues found!
  ```

---

## ۴. تغییرات رفتاری قابل مشاهده برای کاربر

۱. **جهت سوایپ استاندارد:** سوایپ به راست روی کارت روتین (کشیدن از راست به چپ در چیدمان فارسی RTL) مستقیماً اقدام «ثبت انجام» را با بازخورد لمسی (Haptic) و توست لغو فعال می‌کند. سوایپ به چپ منوی مدیریت و تعویق را باز می‌کند.  
۲. **باز شدن شرطی شیت نیت:** کلیک روی روتین‌های ساده (بدون انتخاب سطح سبک/حداقلی، بدون تایمر و بدون شمارش) مستقیماً روتین را ثبت می‌کند و شیت اضافی باز نمی‌شود.  
۳. **نشانگر وضعیت روتین‌های گذشته (`OccurrenceStatusBadge`):** روتین‌های گذشته و ثبت‌نشده با برچسب «ثبت‌نشده» و رنگ خاکستری کمرنگ (هرگز قرمز نه!) نمایش داده می‌شوند.  
۴. **صفحهٔ پایش سلامت داده‌ها:** صفحهٔ اختصاصی توسعه‌دهندگان جهت پایش ۶ کوئری سلامت دیتابیس محلی اضافه شد.

---

## ۵. موارد عمداً انجام‌نشده و دلیل آن

۱. **K-27 (ارتقای کوری‌های RAG در آنالیتیکس):** برای حفظ پایداری کوری‌های فعلی، فیلتر در لایه SQL VIEW `routine_actual_completions` پیاده شد، اما تغییر کوری‌های RAG به پرامپت بعدی موکول گشت.  
۲. **WU-18 (لغزش زمان روتین‌های وابسته):** روتین‌های وابسته به دلیل نیاز به محاسبات الگوریتمی زمان‌بندی جداگانه به پرامپت بعدی منتقل شدند.

---

## ۶. ریسک‌های باقی‌مانده

- **ریسک همگام‌سازی یادآورها در اندروید بومی:** در صورت کشته شدن کامل اپلیکیشن توسط سیستم‌عامل، نیازمند صحه‌گذاری فرکانس `AlarmManager` بومی هستیم.

---

## ۷. پیشنهاد ۵ کار بعدی به ترتیب اولویت

۱. اجرای فاز اول نقشه راه توسعه ریتمو (بهینه‌سازی کارایی بارگذاری تقویم).  
۲. ارتقای کوری‌های موتور RAG به VIEW جدید `routine_actual_completions`.  
۳. توسعه الگوریتم زمان‌بندی روتین‌های وابسته (`dependsOnRoutineId`).  
۴. ارتقای تست‌های بومی اندروید (`MainActivity.kt`).  
۵. افزودن ابزارهای Export و متحرک‌سازی آماری کاربر در پروفایل.
