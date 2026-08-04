# فاز ۰ — گزارش شناسایی و ممیزی کامل UX (`prompts/042_RECON.md`)

**تاریخ ایجاد:** ۵ اوت ۲۰۲۶  
**پروژه:** اپلیکیشن ریتمو (`ir.ritmo.app`)  
**نویسنده:** مهندس ارشد نرم‌افزار (Antigravity AI)

---

## 🟢 X-0 — سرشماری کامل مسیرهای اعلان (Notification Pathways Census)

جدول تمامی فراخوانی‌های اعلان جهت انتقال و یکدست‌سازی در فاز ۱:

| رديف | مسیر فایل | شماره خط | نوع فراخوانی | طبقه‌بندی الگویی |
| :---: | :--- | :---: | :--- | :---: |
| 1 | [lib/core/utils/ritmo_toast.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/utils/ritmo_toast.dart#L5) | 5 | `RitmoToast.show` | **الگوی رسمی مرجع** |
| 2 | [lib/core/ux/ritmo_snackbar.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/ux/ritmo_snackbar.dart#L41) | 41 | `RitmoToast.show` | **آداپتور رسمی** |
| 3 | [lib/core/domain/agenda/action_feedback.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/agenda/action_feedback.dart#L42) | 42 | `RitmoToast.show` | **الگوی رسمی** |
| 4 | [lib/features/routines/shared/routine_actions.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/shared/routine_actions.dart#L135) | 135 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۱/۸** (حذف در X-3) |
| 5 | [lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart#L1277) | 1277 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۲/۸** (حذف در X-3) |
| 6 | [lib/features/chat/presentation/ai_chat_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/chat/presentation/ai_chat_screen.dart#L1557) | 1557 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۳/۸** (حذف در X-3) |
| 7 | [lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart#L1563) | 1563 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۴/۸** (حذف در X-3) |
| 8 | [lib/features/goals/presentation/widgets/ai_goals_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/goals/presentation/widgets/ai_goals_assistant_sheet.dart#L1280) | 1280 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۵/۸** (حذف در X-3) |
| 9 | [lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart#L1188) | 1188 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۶/۸** (حذف در X-3) |
| 10 | [lib/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart#L1250) | 1250 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۷/۸** (حذف در X-3) |
| 11 | [lib/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart#L1480) | 1480 | `_TopToastWidget` | 🔴 **کپی پیاده‌سازی ۸/۸** (حذف در X-3) |
| 12 | [lib/features/today/presentation/now_dashboard_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/now_dashboard_screen.dart#L1159) | 1159 | `_showToast` (`ScaffoldMessenger`) | 🟠 **خام ۵‌گانه اصلی** (مهاجرت در X-4) |
| 13 | [lib/features/profile/presentation/backup_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/backup_screen.dart#L482) | 482 | `_showToast` (`ScaffoldMessenger`) | 🟠 **خام ۵‌گانه اصلی** (مهاجرت در X-4) |
| 14 | [lib/features/profile/presentation/profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart#L1153) | 1153 | `ScaffoldMessenger.showSnackBar` | 🟠 **خام ۵‌گانه اصلی** (مهاجرت در X-4) |
| 15 | [lib/features/profile/presentation/profile_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/profile_screen.dart#L2116) | 2116 | `ScaffoldMessenger.showSnackBar` | 🟠 **خام ۵‌گانه اصلی** (مهاجرت در X-4) |
| 16 | [lib/features/inbox/logic/inbox_navigator.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/inbox/logic/inbox_navigator.dart#L63) | 63 | `ScaffoldMessenger.showSnackBar` | 🟠 **خام ۵‌گانه اصلی** (مهاجرت در X-4) |
| 17 | [lib/features/profile/presentation/crash_reports_screen.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/profile/presentation/crash_reports_screen.dart#L109) | 109 | `ScaffoldMessenger.showSnackBar` | 🟠 **خام ۵‌گانه اصلی** (مهاجرت در X-4) |

---

## 🟢 X-1 — سرشماری رنگ و فونت هاردکد (Hardcoded Colors & Fonts Census)

### سرشماری کل:
- **تعداد کل `Color(0x...` در پوشه `lib/**/presentation/`:** **۴۷ مورد**
- **فونت‌های درون‌خطی (`fontFamily: 'Vazirmatn'`):** «خارج از دامنهٔ ۰۴۲ — به پرامپت موارد باقیمانده منتقل می‌شود».

### جدول ۴۷ مورد رنگ هاردکد در `lib/**/presentation/` (مبنای استثنای X-14 و پاک‌سازی X-12):

| ردیف | مسیر فایل | خط | کد رنگ هاردکد | مقصد تم |
| :---: | :--- | :---: | :--- | :--- |
| 1 | `konkur_hero.dart` | 65 | `Colors.yellowAccent` | `context.colors.warning` |
| 2 | `konkur_hero.dart` | 90 | `Colors.white24` | `context.colors.border` |
| 3 | `konkur_screen.dart` | 245 | `const Color(0xFF6366F1)` | `context.colors.primary` |
| 4 | `konkur_screen.dart` | 310 | `const Color(0xFF1E293B)` | `context.colors.card` |
| 5 | `ss_home_dashboard_screen.dart` | 45 | `const Color(0xFF121212)` | `context.colors.bg` |
| 6 | `ss_home_dashboard_screen.dart` | 82 | `const Color(0xFF10B981)` | `context.colors.success` |
| 7 | `ss_home_dashboard_screen.dart` | 120 | `const Color(0xFF1E293B)` | `context.colors.card` |
| 8 | `worship_screen.dart` | 88 | `const Color(0xFFD4A843)` | `context.colors.goldAccent` |
| 9 | `worship_screen.dart` | 142 | `const Color(0xFFE5BA5A)` | `context.colors.goldAccent` |
| 10 | `cycle_harmony_screen.dart` | 120 | `const Color(0xFFF43F5E)` | `context.colors.medicalRed` |
| 11 | `insights_screen.dart` | 145 | `Colors.white.withOpacity(0.04)` | `context.colors.border` |
| 12 | `ai_day_planner_preview_sheet.dart` | 102 | `const Color(0xffD4A843)` | `context.colors.goldAccent` |
| 13 | `assistant_action_preview_sheet.dart` | 20 | `const Color(0xffD4A843)` | `context.colors.goldAccent` |
| 14 | `assistant_action_preview_sheet.dart` | 20 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 15 | `assistant_action_preview_sheet.dart` | 50 | `const Color(0xff0C0C0C)` | `context.colors.card` |
| 16 | `assistant_action_preview_sheet.dart` | 52 | `const Color(0xffD4A843)` | `context.colors.goldAccent` |
| 17 | `assistant_action_preview_sheet.dart` | 55 | `const Color(0xffD4A843)` | `context.colors.goldAccent` |
| 18 | `assistant_action_preview_sheet.dart` | 65 | `const Color(0xff141414)` | `context.colors.card` |
| 19 | `assistant_action_preview_sheet.dart` | 67 | `const Color(0xffD4A843)` | `context.colors.goldAccent` |
| 20 | `assistant_action_preview_sheet.dart` | 84 | `const Color(0xffD4A843)` | `context.colors.goldAccent` |
| 21 | `assistant_action_preview_sheet.dart` | 207 | `const Color(0xffD4A843)` | `context.colors.goldAccent` |
| 22 | `assistant_briefing_section.dart` | 39 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 23 | `assistant_briefing_section.dart` | 42 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 24 | `assistant_briefing_section.dart` | 97 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 25 | `assistant_briefing_section.dart` | 104 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 26 | `assistant_briefing_section.dart` | 105 | `const Color(0xff8B5CF6)` | `context.colors.primary` |
| 27 | `assistant_briefing_section.dart` | 136 | `const Color(0xff10B981)` | `context.colors.success` |
| 28 | `assistant_briefing_section.dart` | 146 | `const Color(0xffF59E0B)` | `context.colors.warning` |
| 29 | `assistant_briefing_section.dart` | 274 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 30 | `assistant_briefing_section.dart` | 286 | `const Color(0xff10B981)` | `context.colors.success` |
| 31 | `assistant_briefing_section.dart` | 292 | `const Color(0xffF59E0B)` | `context.colors.warning` |
| 32 | `assistant_briefing_section.dart` | 296 | `const Color(0xff8B5CF6)` | `context.colors.primary` |
| 33 | `assistant_briefing_section.dart` | 300 | `const Color(0xffEC4899)` | `context.colors.primary` |
| 34 | `assistant_briefing_section.dart` | 304 | `const Color(0xff3B82F6)` | `context.colors.primary` |
| 35 | `assistant_briefing_section.dart` | 308 | `const Color(0xffEF4444)` | `context.colors.medicalRed` |
| 36 | `assistant_briefing_section.dart` | 312 | `const Color(0xff14B8A6)` | `context.colors.success` |
| 37 | `assistant_briefing_section.dart` | 316 | `const Color(0xff84CC16)` | `context.colors.success` |
| 38 | `assistant_briefing_section.dart` | 320 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 39 | `unified_assistant_sheet.dart` | 270 | `const Color(0xFF1E1E2C)` | `context.colors.sheetBackground` |
| 40 | `unified_assistant_sheet.dart` | 320 | `const Color(0xFF2C2C3E)` | `context.colors.card` |
| 41 | `journey_screen.dart` | 419 | `const Color(0xFFF43F5E)` | `context.colors.medicalRed` |
| 42 | `calendar_tokens.dart` | 8 | `const Color(0xFF10B981)` | `context.colors.success` |
| 43 | `now_pill.dart` | 119 | `const Color(0xffF43F5E)` | `context.colors.medicalRed` |
| 44 | `ai_chat_screen.dart` | 521 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 45 | `ai_chat_screen.dart` | 615 | `const Color(0xff1C1F2E)` | `context.colors.cardTitle` |
| 46 | `ai_chat_screen.dart` | 666 | `const Color(0xff06B6D4)` | `context.colors.primary` |
| 47 | `ai_chat_screen.dart` | 1084 | `const Color(0xff10B981)` | `context.colors.success` |

---

## 🟢 X-2 — تأیید پیش‌نیازها و ارزیابی موشکافانه

### ۱. آیا پرامپت ۰۴۱ (تسویه) تمام شده است؟
- **پاسخ:** **بله، ۱۰۰٪ تمام شده است.**
- **مدرک قانون مدرک:** در فایل [prompts/041_REPORT.md](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/prompts/041_REPORT.md#L68) خط پایانی عبارت است از: `01:15 +412: All tests passed!` و در [tool/current_tests.txt](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/tool/current_tests.txt): `01:15 +424: All tests passed!`. موارد F-9 تا F-17 با موفقیت پیاده‌سازی شده‌اند و در ۰۴۲ تکرار نمی‌شوند.

### ۲. بررسی مکتوب ۳ مورد K-31 و K-32 از پرامپت ۰۴۰ با مدرک:

1. **حذف `DomainSelectionSheet` روی اسلات خالی تقویم (K-31):**
   - **وضعیت:** ❌ **انجام نشده (ثبت واحد جدید X-19 از بقایای ۰۴۰).**
   - **مدرک کد:** در فایل [journey_screen.dart:577](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_screen.dart#L577) عبارت `DomainSelectionSheet.show(context, slotMinutes, timeStr);` فراخوانی شده است. در واحد **X-19** این فراخوانی حذف و مستقیماً `UniversalPlannerSheet.show(context: context, prefilledTime: ...)` باز خواهد شد.

2. **عنوان صفحهٔ مخزن روتین‌ها (K-32):**
   - **وضعیت:** ❌ **انجام نشده (ثبت واحد جدید X-20 از بقایای ۰۴۰).**
   - **مدرک کد:** در فایل [all_plans_screen.dart:147](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/presentation/all_plans_screen.dart#L147)، عنوان فعلی `'همه برنامه‌ها'` است که بر اساس واژه‌نامه GLOSSARY ممنوع است و باید به `'مخزن روتین‌ها'` تغییر یابد. این تغییر در واحد **X-20** انجام می‌شود.

3. **متن تأیید بایگانی (K-32):**
   - **وضعیت:** ✅ **صحیح است و ادعای «غیرقابل بازگشت» ندارد.**
   - **مدرک کد:** در فایل [delete_impact_dialog.dart:96](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/presentation/widgets/delete_impact_dialog.dart#L96)، گزینهٔ `'بایگانی کن'` به عنوان جایگزین امن `'حذف کامل'` ارائه شده و امکان بازگردانی آن وجود دارد.

---

## 🟢 واحدهای کاری مکمل اضافه شده (بقایای ۰۴۰):

- **X-19 (اصلاح K-31):** در [journey_screen.dart:577](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_screen.dart#L577)، حذف `DomainSelectionSheet.show` و باز کردن مستقیم `UniversalPlannerSheet.show` با `prefilledTime`.
- **X-20 (اصلاح K-32):** در [all_plans_screen.dart:147](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/registry/presentation/all_plans_screen.dart#L147)، اصلاح عنوان صفحه از `'همه برنامه‌ها'` به `'مخزن روتین‌ها'`.
