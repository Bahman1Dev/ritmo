# پرامپت ۰۱۹ — تثبیت و ارتقای بخش تقویم (Journey): رفع stale شدن داده، بهینه‌سازی بارگذاری، و تعاملات جدید

> **مخاطب:** ایجنت مصنوعی کدنویس Flutter.
> **زبان UI:** فارسی، RTL. **استک:** Flutter + `sqflite`.
> **زبان کد:** انگلیسی. **متن‌های UI:** فارسی. **فونت:** `Vazirmatn`. **اعداد:** همیشه از `toPersianDigits`.

---

## ⛔ دستورِ اجرا (قبل از هر چیز بخوان و مو‌به‌مو رعایت کن)

1. **هیچ Implementation Plan / Execution Plan / سند طراحی جداگانه‌ای نساز.** این فایل خودش پلن نهایی و تأییدشده است. مرحله‌ی برنامه‌ریزی تمام شده.
2. **مستقیم برو سراغ کدنویسی.** فاز به فاز، به همان ترتیبی که در بخش «۳) فازبندی اجرا» آمده جلو برو.
3. تنها کاری که قبل از کد مجاز است: **بخش «۰) راستی‌آزمایی پیش از اجرا»** — فقط تطبیق مسیر/خط‌های واقعی با فرض‌های این سند. اگر شماره خط جابه‌جا شده بود، معادل واقعی را پیدا کن و **بدون توقف برای تأیید مجدد** ادامه بده.
4. بعد از هر فاز: `flutter analyze` تمیز + build اجراشدنی، سپس فاز بعد. منتظر تأیید انسان بین فازها **نمان** مگر build بشکند یا داده‌ی فرض‌شده در بخش ۰ اصلاً وجود نداشته باشد.
5. خروجی هر مرحله = **کد واقعی و ویرایش فایل**، نه توضیح دادن اینکه «چه‌کار می‌خواهم بکنم».
6. **رفتار موجود را نشکن:** تشخیص تداخل (`getSuggestionForDate`)، pinch-to-zoom، tap-to-create با `UniversalPlannerSheet`، و bottom-sheetهای جزئیات روتین همه باید بعد از این تغییرات همان‌طور کار کنند.

---

## ۰) راستی‌آزمایی پیش از اجرا (فقط چک وجود — پلن نیست)

- [ ] `lib/features/calendar/presentation/journey_controller.dart` — لیسنر رویدادها حدود خط ۴۰–۴۷، `_initData` حدود خط ۱۱۷، `loadRange` حدود خط ۱۴۵، `getSuggestionForDate` حدود خط ۲۱۰، الگوریتم occupied-set حدود خط ۲۸۸–۳۱۲.
- [ ] `lib/features/calendar/presentation/widgets/timeline_grid.dart` — `Timer.periodic` حدود خط ۴۴، `_getDurationMinutes` حدود خط ۶۵، `_calculateWakingAndFreeHours` حدود خط ۸۶–۱۲۴.
- [ ] `lib/features/calendar/presentation/widgets/density_grid.dart` — رنگ‌بندی سلول‌ها بر اساس `totalCompletionRate` و guard سالِ جاری.
- [ ] `lib/core/domain/agenda/day_agenda_service.dart` — ستِ `_cacheInvalidatingEvents` و `_uiRefreshEvents` حدود خط ۴۲–۶۱، `invalidateDate`/`invalidateAll`.
- [ ] `lib/core/domain/engines/ritmo_event_bus.dart` — کلاس `RitmoEvent` (فیلدهای `type`, `timestamp`, `payload`) و `RitmoEventBus().fire(...)`.
- [ ] نقاط حذف روتین بدون رویداد: `lib/features/assistant/logic/assistant_action_registry.dart:1445` (داخل `txn.delete('routines', ...)`) و `lib/features/health/presentation/widgets/medications_section.dart:436`.
- [ ] ذخیره‌ی هدف خواب: `lib/features/sleep/presentation/widgets/sleep_target_sheet.dart:110` (کلیدهای `sleep_target_bedtime` / `sleep_target_wake` در `app_settings`).
- [ ] `lib/features/assistant/logic/duration_estimator.dart` — کلاس `DurationEstimator` و امضای متد تخمین مدت.
- [ ] `lib/features/routines/shared/routine_actions.dart` — الگوی `RoutineActions.completeRoutine/snoozeRoutine` برای دیدن نحوه‌ی آپدیت `timeOfDay` روتین (جدول `routines`، ستون `timeOfDay`، و اینکه بعد از ویرایش چه رویدادی fire می‌شود — فرض: `RoutineEdited`).
- [ ] رنگ‌های طلایی brand: `0xffD4A843` / `0xffE5BA5A` در `journey_screen.dart`، `journey_widgets.dart`، `timeline_grid.dart` و اینکه در `lib/core/theme/ritmo_theme.dart` (`RitmoColors`) معادلی دارند یا نه.

**قاعده:** چیزی را حدس نزن. اگر داده‌ای که این سند فرض کرده اصلاً وجود ندارد، فقط همان مورد را گزارش بده و برای بقیه ادامه بده.

---

## ۱) تشخیص — چه چیزهایی خراب/ضعیف است؟

این موارد در بازبینی کد تأیید شده‌اند (حدس نیستند):

1. **تقویم stale می‌ماند.** `JourneyController` فقط به `WorshipUpdated`، `AgendaItemToggled` و چهار رویداد روتین گوش می‌دهد. رویدادهای `PrayerCompleted`، `CourseSessionCompleted`، `GoalStepToggled`، `DayRolledOver`، `DataImported` نادیده گرفته می‌شوند → تیک نماز/درس/گام هدف از Home، رد شدن از نیمه‌شب، یا ایمپورت بکاپ در تقویم منعکس نمی‌شود.
2. **حذف روتین هیچ رویدادی ندارد.** دو نقطه‌ی حذف (`assistant_action_registry.dart:1445` و `medications_section.dart:436`) مستقیم `delete` می‌زنند؛ نه کش `DayAgendaService` باطل می‌شود نه تقویم و نه Home. روتین حذف‌شده تا ری‌استارت اپ روی تقویم می‌ماند.
3. **هر رویداد = reload کل ۳۹۵ روز.** `_handleAppEvent` با هر تیکِ یک روتین، `loadRange(_rangeStart, _rangeEnd)` را روی کل بازه صدا می‌زند + یک `notifyListeners` سراسری.
4. **بازه ثابت است.** `_rangeStart`/`_rangeEnd` فقط در `_initData` ست می‌شوند (۳۰- تا ۳۶۵+). ناوبری به خارج از بازه در نمای ماه/سال، سلول‌های بی‌صدا خالی نشان می‌دهد.
5. **«ساعات آزاد» دو پیاده‌سازی ناسازگار دارد.** کنترلر با occupied-set دقیق حساب می‌کند؛ `_calculateWakingAndFreeHours` در `timeline_grid.dart` مدت‌ها را ساده جمع می‌زند و همپوشانی‌ها را دوبار می‌شمارد → دو عدد متفاوت در یک صفحه.
6. **تنظیمات خواب فقط در init خوانده می‌شود.** تغییر هدف خواب از تنظیمات، بلوک‌های خواب تایم‌لاین را آپدیت نمی‌کند.
7. **rebuild کامل هر ۳۰ ثانیه** برای خط «اکنون» در `_TimelineGridState`.
8. **کمبودهای UX:** جابه‌جایی بلوک با درگ نیست؛ نشانگر تداخل فقط برای روز انتخابی است؛ مدت پیش‌فرض ۱۵ دقیقه‌ی ثابت به‌جای `DurationEstimator`؛ رنگ طلایی hardcode در چند فایل؛ رنگ‌بندی سلول‌های آینده در نمای سال گمراه‌کننده.

---

## ۲) اصول طراحی راه‌حل

- **رویداد → invalidation هدفمند:** اگر payload رویداد `date` دارد فقط همان تاریخ reload شود؛ اگر ندارد (مثل `RoutineDeleted` که ممکن است چند روز را متأثر کند یا `DataImported`) کل کش پاک و بازه‌ی *قابل‌مشاهده* reload شود.
- **بارگذاری تنبل (lazy):** بازه‌ی اولیه کوچک، گسترش خودکار هنگام ناوبری. هیچ سلولی نباید «بی‌صدا خالی» باشد — یا داده دارد یا placeholder لودینگ.
- **یک منبع حقیقت برای هر محاسبه:** ساعات آزاد فقط در کنترلر.
- **رویداد جدید فقط وقتی که واقعاً لازم است:** دو رویداد جدید تعریف می‌کنیم — `RoutineDeleted` و `SleepTargetUpdated` — و همه‌جا از همان `RitmoEventBus` موجود استفاده می‌کنیم.

---

## ۳) فازبندی اجرا

### فاز A — پوشش کامل رویدادها و invalidation (مهم‌ترین فاز)

**A1. رویداد `RoutineDeleted`:**
- در هر دو نقطه‌ی حذف، بعد از موفقیت حذف، fire کن:
  ```dart
  RitmoEventBus().fire(RitmoEvent(
    type: 'RoutineDeleted',
    timestamp: DateTime.now(),
    payload: {'routineId': id}, // date ندارد — عمداً، چون همه‌ی روزهای آینده متأثرند
  ));
  ```
- `assistant_action_registry.dart:1445`: چون داخل transaction است، fire را **بعد از commit موفق** بگذار نه داخل txn.
- `medications_section.dart:436`: همین الگو.
- در `day_agenda_service.dart`، `RoutineDeleted` را به `_cacheInvalidatingEvents` **و** `_uiRefreshEvents` اضافه کن (چون خارج از کرنل روتین fire می‌شود و Home هم باید refresh شود). payload بدون `date` است → مسیر موجود `invalidateAll()` خودش درست عمل می‌کند.
- اگر نقطه‌ی حذف دیگری هم برای روتین‌های عادی (نه wipe کامل مثل onboarding/main.dart) پیدا کردی، همان‌جا هم fire کن. wipe های کامل (`db.delete('routines')` بدون where) مشمول نیستند چون بعدشان restart/reseed می‌شود — فقط بررسی کن و اگر مسیر زنده‌ای بود گزارش بده.

**A2. رویداد `SleepTargetUpdated`:**
- در `sleep_target_sheet.dart` بعد از ذخیره‌ی موفق تنظیمات، fire کن با payload خالی (یا `{'bedtime': ..., 'wake': ...}`).

**A3. تکمیل لیسنر `JourneyController`:**
- لیست رویدادهای گوش‌داده‌شده را به این‌ها گسترش بده: رویدادهای فعلی + `PrayerCompleted`، `CourseSessionCompleted`، `GoalStepToggled`، `DayRolledOver`، `DataImported`، `RoutineDeleted`، `CycleStarted`، `CycleEnded`، `SleepTargetUpdated`.
- برای `SleepTargetUpdated`: فقط `_sleepBedtime`/`_sleepWake` را از `app_settings` دوباره بخوان و `notifyListeners()` — نیازی به reload آژندا نیست.
- به‌جای if-chain طولانی، یک `static const Set<String> _refreshEvents` تعریف کن (مثل الگوی `day_agenda_service.dart`).

### فاز B — reload هدفمند + گسترش بازه

**B1. `_handleAppEvent` هدفمند:**
```dart
Future<void> _handleAppEvent(RitmoEvent event) async {
  final date = event.payload['date'] as String?;
  if (date != null) {
    final d = DateTime.tryParse(date);
    if (d != null) {
      final map = await DayAgendaService.instance.agendaForDate(d)... // فقط همان روز
      _agendas[date] = ...;
      notifyListeners();
      return;
    }
  }
  // بدون date (RoutineDeleted, DayRolledOver, DataImported, ...):
  _agendas.clear();
  await loadRange(_visibleStart, _visibleEnd); // بازه‌ی قابل‌مشاهده، نه ۳۹۵ روز
  notifyListeners();
}
```
نکته: `DayAgendaService` خودش کشِ خودش را قبل از این invalidate کرده (لیسنر خودش را دارد)، پس این reload از DB تازه می‌خواند. اما **ترتیب تضمین‌شده نیست** — هر دو به یک broadcast stream گوش می‌دهند و listenerها به ترتیب subscribe اجرا می‌شوند؛ چون `DayAgendaService.instance` singleton است و در startup قبل از ساخت `JourneyController` ساخته می‌شود، ترتیب فعلی امن است. یک کامنت یک‌خطی همین‌جا بگذار که این وابستگی ترتیبی را ثبت کند.

**B2. بازه‌ی پویا:**
- بازه‌ی اولیه‌ی `_initData` را کوچک کن: `today-7` تا `today+45` (پوشش نمای ۲۴ساعت/هفته/ماه بدون تأخیر محسوس).
- متد جدید:
  ```dart
  Future<void> ensureRange(DateTime start, DateTime end) async
  ```
  اگر `[start,end]` خارج از `[_rangeStart,_rangeEnd]` بود، فقط قسمت کم‌شده را load کن، بازه را گسترش بده، `notifyListeners()`. یک flag ساده‌ی `_isExpanding` بگذار که همزمانی دوباره trigger نشود.
- نقاط فراخوانی: `setSelectedDate`، `updateScrolledDate`، تغییر ماه/سال در `density_grid.dart` (دکمه‌های chevron)، و `setScale`. با بافر: نمای هفته ±۱۴ روز، ماه ±۴۵ روز، سال کل سال جاریِ نمایش‌داده‌شده.
- در UI: وقتی تاریخی هنوز در `agendas` نیست **و** `isLoading`/`_isExpanding` فعال است، سلول/ستون placeholder کم‌رنگ (shimmer لازم نیست؛ همان رنگ `withValues(alpha: 0.05)`) نشان بده نه «خالی».

### فاز C — یکی‌کردن «ساعات آزاد» + مدت‌های واقعی‌تر

**C1.** الگوریتم occupied-set کنترلر (حدود خط ۲۸۸) را به یک متد عمومی و قابل‌استفاده‌ی مجدد ارتقا بده:
```dart
/// دقایق آزاد بیداری برای یک روز، با احتساب همپوشانی‌ها (merge بازه‌ها)
({int wakingMinutes, int freeMinutes}) computeFreeTime(DateTime date)
```
merge بازه‌های همپوشان قبل از جمع‌زدن الزامی است.

**C2.** `_calculateWakingAndFreeHours` در `timeline_grid.dart` را **حذف** کن و هدر summary تایم‌لاین را به `widget.controller.computeFreeTime(date)` وصل کن. `getSummaryForDate` کنترلر هم اگر محاسبه‌ی مستقل دیگری دارد به همین متد سوییچ شود. بعد از این فاز فقط **یک** پیاده‌سازی free-time باید در کل feature وجود داشته باشد (`grep` بگیر).

**C3.** `_getDurationMinutes` در `timeline_grid.dart`: به‌جای ثابتِ ۱۵ دقیقه برای آیتم‌های بدون مدت، از `DurationEstimator` استفاده کن (امضای واقعی‌اش را در فاز ۰ دیدی). اگر estimator برای آن نوع آیتم جوابی نداشت، همان ۱۵ دقیقه fallback بماند. نماز بدون window همان ۲۰ دقیقه بماند. **مهم:** اگر `DurationEstimator` نیاز به async/DB دارد، تخمین را موقع ساخت آژندا در کنترلر (یا `DayAgendaService`) انجام بده و روی `AgendaItem` cache کن — داخل `build` تایم‌لاین هیچ await ای مجاز نیست.

### فاز D — کارایی: خط «اکنون» ایزوله

- `Timer.periodic` و `setState` سراسری را از `_TimelineGridState` حذف کن.
- ویجت جدید `_LiveNowLine` (در همان فایل): `StatefulWidget` کوچکی که خودش `Timer.periodic(Duration(seconds: 30))` دارد و فقط خودش rebuild می‌شود. ورودی: `pxPerMinute` و offset ستون. جای فعلی خط زنده در درخت ویجت را با این جایگزین کن.
- هر استفاده‌ی دیگری از «الان» در build سراسری (مثل رنگ آیتم‌های گذشته/`isActive`) که به تایمر وابسته بود را بررسی کن: اگر با دقت ۳۰ثانیه لازم است، آن بخش را هم داخل یک `AnimatedBuilder`/ویجت ایزوله ببر؛ اگر دقت دقیقه‌ای کافی است، همان مقدار زمانِ frame فعلی کافی است و نیازی به rebuild دوره‌ای ندارد.

### فاز E — تعاملات جدید UX

**E1. درگ برای جابه‌جایی بلوک (فقط نمای ۲۴ساعت و هفته):**
- `LongPressDraggable`-style با `GestureDetector` روی بلوک‌های روتین (`domain == AgendaDomain.routine` و `!isCompleted`): long-press → haptic `mediumImpact` → بلوک شناور نیمه‌شفاف دنبال انگشت، snap به گام ۱۵ دقیقه، نمایش زمان جدید کنار بلوک حین درگ (`toPersianDigits`).
- رها کردن: `timeOfDay` روتین را در جدول `routines` آپدیت کن **از طریق همان مسیر موجودِ ویرایش روتین** (همان که `RoutineEdited` fire می‌کند) تا reminderها و بقیه‌ی سیستم sync بمانند — مستقیم UPDATE نزن مگر مسیر موجودی نباشد؛ اگر نبود، UPDATE + fire دستی `RoutineEdited` با `{'routineId': ..., 'date': ...}`.
- اگر زمان جدید با آیتم دیگری تداخل داشت: SnackBar فارسی «⏰ این زمان با «X» تداخل دارد» + دکمه‌ی «باشه، همین‌جا» برای اعمال به‌هرحال. تشخیص تداخل با همان occupied-set فاز C.
- درگ در نمای هفته فقط عمودی (تغییر ساعت در همان روز) — جابه‌جایی بین روزها فعلاً خارج از scope.
- آیتم‌های غیرروتین (نماز، درس، cycle و…) درگ نمی‌شوند؛ روی long-press آن‌ها همان رفتار فعلی (جزئیات) بماند.

**E2. نشانگر تداخل چندروزه در هدر هفته:**
- در هدر روزهای نمای هفته (`_buildDayHeaders` در `timeline_grid.dart`)، برای هر روز اگر `getSuggestionForDate(day)` غیر null بود یک dot نارنجی/قرمز کوچک زیر شماره‌ی روز نشان بده. tap روی هدر همان روز = انتخاب روز (رفتار فعلی حفظ شود؛ اگر tap-handler ندارد اضافه کن).
- `getSuggestionForDate` الان sync است و از `_agendas` می‌خواند، پس صدا زدنش برای ۷ روز در build ارزان است — ولی نتیجه را per-build برای هر روز memoize کن (یک `Map<String, bool>` ساده که با هر `notifyListeners` پاک می‌شود).

**E3. نمای سال — رنگ خنثی برای آینده:**
- در `density_grid.dart`: سلول روزها/ماه‌های **آینده** (بعد از امروز) هرگز نباید رنگ «تکمیل پایین» (قرمز/کم‌تراکم) بگیرند؛ رنگ خنثی `colors.border.withValues(alpha: 0.15)` بده. guard فعلی فقط سال جاری را پوشش می‌دهد — به همه‌ی مسیرهای رنگ‌بندی تعمیم بده. روزهای آینده‌ای که آیتم برنامه‌ریزی‌شده دارند می‌توانند tint آبی/طلایی خیلی ملایم بگیرند تا «برنامه دارد» از «خالی» تمیز داده شود.

### فاز F — پاک‌سازی رنگ‌ها

- دو رنگ طلایی `0xffE5BA5A` و `0xffD4A843` را به `RitmoColors` (یا همان‌جایی که پالت brand تعریف شده در `ritmo_theme.dart`) منتقل کن — مثلاً `RitmoColors.brandGold` / `RitmoColors.brandGoldDark` — و همه‌ی استفاده‌ها در `journey_screen.dart`، `journey_widgets.dart`، `timeline_grid.dart`، `density_grid.dart` را به ثابت جدید سوییچ کن. اگر ثابت معادل از قبل وجود دارد، همان را استفاده کن و ثابت جدید نساز. بقیه‌ی فایل‌های اپ خارج از scope این پرامپت‌اند (دست نزن).

---

## ۴) معیار پذیرش (بعد از فاز آخر همه را دستی چک کن)

1. تیک نماز از Home → سوییچ به تب تقویم → همان لحظه منعکس شده (بدون restart).
2. حذف روتین از بخش سلامت (داروها) یا از دستیار → روتین از تایم‌لاین و Home هر دو محو می‌شود.
3. تغییر هدف خواب از شیت خواب → بلوک‌های خواب تایم‌لاین بلافاصله جابه‌جا می‌شوند.
4. در نمای سال به ۲ سال بعد برو → سلول‌ها placeholder می‌شوند و سپس پر؛ هیچ سلول «بی‌صدا خالی» نیست. ماه‌های آینده خنثی‌رنگ‌اند نه قرمز.
5. عدد «ساعات آزاد» در Hero و در هدر تایم‌لاین برای یک روزِ دارای دو آیتم همپوشان **یکسان** است.
6. تیک یک روتین در تقویم: فقط همان روز reload می‌شود (با `debugPrint` موقت تأیید کن، بعد پاکش کن).
7. long-press روی بلوک روتین → درگ → رها → زمان جدید ذخیره و در Home هم منعکس شده؛ درگ روی زمان اشغال‌شده SnackBar تداخل می‌دهد.
8. روز دارای تداخل در هدر هفته dot هشدار دارد.
9. `flutter analyze` صفر خطا/وارنینگ جدید.
10. جستجوی `grep -rn "0xffD4A843\|0xffE5BA5A" lib/features/calendar` → صفر نتیجه.

---

## ۵) خارج از scope (عمداً — انجام نده)

- جابه‌جایی بلوک بین روزها در نمای هفته (درگ افقی).
- تغییر duration با درگِ لبه‌ی بلوک (resize).
- سیستم event sourcing جدید یا refactor کلی `RitmoEventBus`.
- تغییر رفتار `DayAgendaService` جز افزودن `RoutineDeleted` به دو Set موجود.
- هر تغییری در featureهای دیگر جز نقاط fire رویداد که در فاز A مشخص شد.
