# گزارش نهایی اجرای پرامپت ۰۳۰ — هات‌فیکس بحرانی ActionRouter

---

## ۱. خروجی دستورات راستی‌آزمایی (PASS 0)

| شناسه | شرح راستی‌آزمایی | خروجی کُد واقعی |
|---|---|---|
| **P0-1** | وضعیت فعلی روتر | `ActionRouter.open` دارای تابع‌های خالی `async {}`, `() {}` برای `onStartTimer`, `onSnooze`, `onEdit`, `onViewDetails` بود. |
| **P0-2** | امضای سرویس تایمر | `RitmoTimerService.instance.startTimer({required String id, required String domain, required String itemId, required String mode, required int durationMinutes, TimerDirection direction})` |
| **P0-3** | امضای اورلی تایمر | `ActiveTimerOverlay({required Routine routine, required String completionMode, required VoidCallback onFinished})` |
| **P0-4** | الگوی مرجع تایمر در now_dashboard | `Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveTimerOverlay(routine: routine, completionMode: mode, onFinished: () { Navigator.pop(context); _loadDashboardData(); })))` |
| **P0-5** | امضاهای RoutineActions | `completeRoutine({required BuildContext context, required String routineId, required String resultType, required String dateStr, int? durationMinutes, VoidCallback? onDone})` و `snoozeRoutine(...)` |
| **P0-6** | شیت جزئیات روتین | `RoutineDetailsSheet.show({required BuildContext context, required Routine routine, String? targetDate, VoidCallback? onReverted})` |
| **P0-7** | سیاست تعویق | `SnoozePolicy.evaluate(...)` ساختار `SnoozeDecision` با وضعیت‌های `allowed`, `lastCall`, `exhausted`, `blockedMedical`, `blockedMidnight` برمی‌گرداند. |
| **P0-8** | خروجی گیت‌وی | `CompletionOutcome` دارای `didWrite` (موفقیت)، `errorMessage` و `undoToken` است. |
| **P0-9** | امضای شیت کنکور | `KonkurStudySheet({required List<KonkurSubject> subjects, required List<KonkurTopic> topics, required VoidCallback onSaved})` |
| **P0-10** | ابطال کش اجندا | `DayAgendaService.instance.invalidateDate(dateStr)` و `invalidateAll()` |
| **P0-11** | ویرایش روتین از پلنر | `UniversalPlannerSheet.show(context, routineToEdit: routine.toMap(), onSaved: ...)` |
| **P0-12** | نام دامنه دارو | در `AgendaDomain.medicine` مقدار `'medicine'` است اما `CompletionGateway` رشته `'medication'` ارسال می‌کرد. |

---

## ۲. خلاصه رفع باگ‌ها (B1 تا B12)

### B1: `onStartTimer` خالی بود
- **کد قبل:** `onStartTimer: (selectedMode) async {}`
- **کد بعد:** محاسبه زمان با `_minutesForMode` + فراخوانی `RitmoTimerService.instance.startTimer` + نمایش `ActiveTimerOverlay` و فراخوانی `ActionFeedback.success`.
- **تست اثبات:** `test/widget/niyyah_start_timer_test.dart`

### B2: `onSnooze` خالی بود
- **کد قبل:** `onSnooze: () {}`
- **کد بعد:** ارزیابی `SnoozePolicy.evaluate` و انجام تعویق یا نمایش `_showExitOptionsSheet` در صورت اتمام سقف بدون پرتاب استثنا.
- **تست اثبات:** `test/unit/snooze_verdict_exhausted_test.dart` و `test/widget/niyyah_snooze_test.dart`

### B3: `onEdit` خالی بود
- **کد قبل:** `onEdit: () {}`
- **کد بعد:** باز کردن `UniversalPlannerSheet.show(context, routineToEdit: routine.toMap(), onSaved: ...)`
- **تست اثبات:** `test/widget/niyyah_edit_opens_planner_test.dart`

### B4: `onViewDetails` خالی بود
- **کد قبل:** `onViewDetails: () {}`
- **کد بعد:** باز کردن `RoutineDetailsSheet.show(context: context, routine: routine, targetDate: item.dateStr)`
- **تست اثبات:** `test/widget/niyyah_details_test.dart`

### B5: `onCompleteInstantly` بدون بازخورد
- **کد قبل:** ارسال به گیت‌وی بدون ابطال کش، توست یا هپتیک.
- **کد بعد:** برسی outcome گیت‌وی + فراخوانی `ActionFeedback.success` شامل `undoToken` و ابطال کش تاریخ.
- **تست اثبات:** `test/widget/niyyah_instant_log_test.dart`

### B6: شکست خاموش هنگام نال بودن `meta['routine']`
- **کد قبل:** اگر `meta['routine']` نال بود هیچ شاخه `else` ای وجود نداشت.
- **کد بعد:** جستجوی روتین از دیتابیس بر اساس `item.sourceId` و در صورت عدم یافتن، نمایش `ActionFeedback.failure`.
- **تست اثبات:** `test/widget/router_missing_meta_test.dart`

### B7: دو مسیر موازی ثبت روتین
- **کد قبل:** `RoutineActions.completeRoutine` از `CompleteOccurrenceCommand` مستقیماً استفاده می‌کرد.
- **کد بعد:** `RoutineActions.completeRoutine` داخلاً از `CompletionGateway.instance.submit` عبور می‌کند و امضای عمومی را حفظ کرده است.
- **تست اثبات:** `test/unit/routine_actions_uses_gateway_test.dart`

### B8: ثبت بی‌صدای دامنه‌های غیرروتین
- **کد قبل:** ثبت آنی بدون هیچ شیت تأیید یا پیام به کاربر.
- **کد بعد:** ایجاد `_showDomainConfirmationSheet` قبل از ثبت برای دامنه‌های عبادت، دوره، هدف و دارو.
- **تست اثبات:** `test/widget/prayer_confirm_sheet_test.dart`

### B9: `KonkurStudySheet` همیشه خالی
- **کد قبل:** پاس دادن `subjects: const []` و `topics: const []`.
- **کد بعد:** خواندن دروس واقعی از `KonkurRepository.instance` و بررسی فعال بودن ماژول.

### B10: شاخه سیکل خالی بود
- **کد قبل:** `case AgendaDomain.cycle: break;`
- **کد بعد:** رعایت `CyclePrivacyGuard` و راهنمایی کاربر یا نمایش پیام بدون افشای اطلاعات.

### B11: ناهماهنگی نام دامنه دارو
- **کد قبل:** گیت‌وی رشته `'medication'` ارسال می‌کرد اما روتر `'medicine'` داشت.
- **کد بعد:** یکسان‌سازی روی `'medicine'` در تمام لایه‌ها.
- **تست اثبات:** `test/unit/medicine_domain_string_test.dart`

### B12: ارتقای شاخه ورزش
- **کد بعد:** ارتقای `onLogged` در `showMovementLogSheet` به `ActionFeedback.success`.

---

## ۳. جدول وضعیت تکالیف (T1 تا T17)

| تکلیف | موضوع | وضعیت |
|---|---|---|
| **T1** | ساخت `ActionFeedback` | ✅ انجام شد |
| **T2** | بررسی تمام خروجی‌های گیت‌وی | ✅ انجام شد |
| **T3** | پیاده‌سازی `onStartTimer` | ✅ انجام شد |
| **T4** | پیاده‌سازی `onSnooze` و `_showExitOptionsSheet` | ✅ انجام شد |
| **T5** | پیاده‌سازی `onEdit` با `UniversalPlannerSheet` | ✅ انجام شد |
| **T6** | پیاده‌سازی `onViewDetails` | ✅ انجام شد |
| **T7** | ارتقای `onCompleteInstantly` | ✅ انجام شد |
| **T8** | پوشش نال بودن `meta['routine']` | ✅ انجام شد |
| **T9** | بازنویسی بدنه `RoutineActions.completeRoutine` | ✅ انجام شد |
| **T10** | ساخت `_showDomainConfirmationSheet` | ✅ انجام شد |
| **T11** | بارگذاری دروس واقعی کنکور | ✅ انجام شد |
| **T12** | پوشش دامنه سیکل با گارد حریم خصوصی | ✅ انجام شد |
| **T13** | یکسان‌سازی رشته دامنه دارو روی `'medicine'` | ✅ انجام شد |
| **T14** | ارتقای شاخه ورزش به `ActionFeedback.success` | ✅ انجام شد |
| **T15** | اصلاح امضای `RoutineNiyyahSheet.show` به `Future<void>` | ✅ انجام شد |
| **T16** | ساخت ۵ تست واحد | ✅ انجام شد |
| **T17** | ساخت ۸ تست ویجت | ✅ انجام شد |

---

## ۴. پاسخ صریح به سؤال کلیدی (بخش ۶ پرامپت ۰۳۰)

**پاسخ:** 
قبل از رفع این باگ، «ثبت فوری» روتین از طریق `ActionRouter` **در دیتابیس ثبت می‌شد** (`CompletionGateway.instance.submit` صدا زده می‌شد)، اما:
1. هیچ کشی ابطال نمی‌شد (`invalidateDate` صدا زده نمی‌شد).
2. هیچ توستی به کاربر نشان داده نمی‌شد.
3. هیچ بازخوردی (هپتیک / لغو Undo) وجود نداشت.
در نتیجه کاربر تصور می‌کرد هیچ اتفاقی نیفتاده است در حالی که روتین در پایگاه‌داده ثبت شده بود. با افزودن `ActionFeedback.success` و ابطال کش تاریخ، این مشکل کاملاً رفع شد.

---

## ۵. صداکنندگان `RoutineActions` و تأیید نشکستن آن‌ها

صداکنندگان شناسایی‌شده:
1. `lib/core/domain/agenda/agenda_renderer_registry.dart:338` -> `completeRoutine`
2. `lib/core/domain/agenda/agenda_renderer_registry.dart:348` -> `completeRoutine`
3. `lib/core/domain/agenda/agenda_renderer_registry.dart:361` -> `snoozeRoutine`
4. `lib/features/today/presentation/now_dashboard_screen.dart:954` -> `snoozeRoutine`

همهٔ امضاهای عمومی حفظ شدند و تمامی فراخوان‌ها بدون تغییر به کار خود ادامه می‌دهند.

---

## ۶. نتایج ابزارها و تست‌ها

- **`flutter analyze`**: **صفر مشکل (0 issues)**
- **تعداد تست‌ها قبل از اجرای پرامپت ۰۳۰**: ۱۰۷ تست (همه پاس)
- **تعداد تست‌ها بعد از اجرای پرامپت ۰۳۰**: ۱۲۰ تست (همه پاس — ۱۳ تست جدید اضافه شد)
