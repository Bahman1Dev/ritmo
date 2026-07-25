# گزارش پیاده‌سازی پرامپت 028: تایم‌لاین دو ستونه روزانه، درگ و دراپ رویدادهای بدون زمان و انیمیشن‌های پرمیوم

## خلاصه اجرایی
پیاده‌سازی موفقیت‌آمیز چیدمان دو ستونه تایم‌لاین (Split-Day Timeline)، قابلیت زمان‌بندی و از زمان‌بندی خارج کردن رویدادها از طریق کشیدن و رها کردن (Drag & Drop)، دستورات واگردپذیر (Reversible Commands)، شیت انتخاب دامنه برای ایجاد برنامه‌های جدید و انیمیشن‌های جهت‌دار محور مشترک (Shared Axis Transitions) انجام گردید.

---

## ۱. جدول وضعیت وظایف (Task Execution Registry)

| شناسه | عنوان وظیفه | وضعیت | فایل اصلی متأثر |
| :--- | :--- | :---: | :--- |
| **T1** | توکن‌ها و ثابت‌های نمای دو ستونه (Split Day Tokens) | ✅ کامل | `lib/features/calendar/presentation/utils/calendar_tokens.dart` |
| **T2** | بهینه‌سازی موتور چیدمان تایم‌لاین (Range-Aware Layout Engine) | ✅ کامل | `lib/features/calendar/presentation/logic/timeline_layout_engine.dart` |
| **T3** | محور ساعت آگاه از محدوده (Range-Aware Hour Axis & Side) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_hour_axis.dart` |
| **T4** | بازطراحی شبکه گرید تایم‌لاین (Timeline Grid Overhaul) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_grid.dart` |
| **T5** | کارت رویدادهای سرریز شده (Overflow Item Card Widget) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_overflow_card.dart` |
| **T6** | هدر ستون‌های صبح و بعدازظهر (Column Header Widget) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_column_header.dart` |
| **T7** | ویجت تایم‌لاین دو ستونه (Split Day View Main Widget) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_split_day_view.dart` |
| **T8** | ادغام نمای دو ستونه در صفحه اصلی (Journey Screen Integration) | ✅ کامل | `lib/features/calendar/presentation/journey_screen.dart` |
| **T9** | امکان‌پذیری زمان‌بندی رویدادهای بدون زمان (Eligibility Extensions) | ✅ کامل | `lib/features/calendar/presentation/logic/direct_manipulation_eligibility.dart` |
| **T10** | کشیدن رویدادهای بدون زمان (Untimed LongPressDraggable) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_untimed_section.dart` |
| **T11** | دریافت رویدادهای بدون زمان روی گرید (Grid DragTarget Handling) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_split_day_view.dart` |
| **T12** | رها کردن رویداد روی بخش بدون زمان (Unschedule DragTarget) | ✅ کامل | `lib/features/calendar/presentation/widgets/timeline_untimed_section.dart` |
| **T13** | دستورات واگردپذیر و شیت دامنه‌ها (Reversible Commands & Domain Sheet) | ✅ کامل | `lib/features/calendar/presentation/journey_controller.dart` |
| **T14** | زیرساخت انیمیشن و کاهش حرکت (Motion & Reduce Motion Infrastructure) | ✅ کامل | `lib/features/calendar/presentation/utils/calendar_motion.dart` |
| **T15** | انیمیشن تعویض مقیاس و تاریخ (Shared Axis Transitions) | ✅ کامل | `lib/features/calendar/presentation/journey_screen.dart` |
| **T16** | افزودن بسته `animations: ^2.0.11` به `pubspec.yaml` | ✅ کامل | `pubspec.yaml` |
| **T17** | بازنگری ردیابی رویدادها (Event Tracking Review) | ✅ کامل | `lib/core/domain/engines/ritmo_event_bus.dart` |
| **T18** | آزمون‌های واحد و ویجت (Unit & Widget Tests) | ✅ کامل | `test/split_day_*.dart`, `test/untimed_*.dart` |
| **T19** | تحلیل استاتیک و پایداری (Static Analysis Zero Errors) | ✅ کامل | `flutter analyze` (Zero Errors) |
| **T20** | ثبت گزارش نهایی پیاده‌سازی (Final Implementation Report) | ✅ کامل | `prompts/028_REPORT.md` |

---

## ۲. جزئیات معماری و تغییرات پیاده‌سازی شده

### ۲.۱. چیدمان دو ستونه تایم‌لاین (Split-Day 2-Column Timeline Layout)
- **محدوده‌ها (Ranges):**
  - **ستون صبح (Morning Column):** دقیقه ۰ تا ۷۲۰ (ساعت ۰۰:۰۰ الی ۱۲:۰۰) با محور ساعت در سمت راست (`HourAxisSide.trailing`).
  - **ستون بعدازظهر (Afternoon Column):** دقیقه ۷۲۰ تا ۱۴۴۰ (ساعت ۱۲:۰۰ الی ۲۴:۰۰) با محور ساعت در سمت چپ (`HourAxisSide.leading`).
- **ترتیب RTL در فارسی:**
  - استفاده از `Directionality(textDirection: TextDirection.rtl)` در `TimelineSplitDayView`. اولین فرزند در `Row` (ستون صبح) در سمت **راست** صفحه و دومین فرزند (ستون بعدازظهر) در سمت **چپ** قرار می‌گیرد.
- **نمایش رویدادهای متقاطع (Cross-Boundary Items):**
  - رویدادهایی که از مرز ۱۲:۰۰ عبور می‌کنند (مثلاً ۱۱:۳۰ تا ۱۲:۳۰) به صورت هوشمند برش خورده و در هر دو ستون نمایش داده می‌شوند:
    - در ستون صبح: با پرچم `isClippedAtEnd = true` و ارتفاع مربوط به ۱۱:۳۰ الی ۱۲:۰۰.
    - در ستون بعدازظهر: با پرچم `isClippedAtStart = true` و ارتفاع مربوط به ۱۲:۰۰ الی ۱۲:۳۰.
- **مدیریت هم‌زمانی و کارت سرریز (`+n مورد دیگر`):**
  - حداکثر مسیر هم‌زمان روی ۲ تنظیم شده (`maxLanes = 2`). در صورت وجود بیش از ۲ رویداد هم‌زمان، رویداد دوم به عنوان کارت سرریز به رنگ خنثی با عنوان `+n مورد دیگر` نمایش داده شده و با لمس آن شیت اختصاصی `TimelineOverflowCard` باز می‌شود.
- **بازگشت خودکار در صفحه‌نمایش‌های باریک (Narrow Screen Fallback):**
  - در عرض کمتر از ۳۴۰ پیکسل (`splitMinScreenWidth = 340.0`)، برنامه به صورت خودکار به تایم‌لاین تک‌ستونه تک‌محدوده‌ای (۰..۱۴۴۰) بازمی‌گردد.

### ۲.۲. تعاملات مستقیم و زمان‌بندی رویدادها (Direct Manipulation & Drag-to-Schedule)
- **کشیدن چیپ‌های بدون زمان (Untimed Drag-to-Schedule):**
  - چیپ‌های بخش بدون زمان با `LongPressDraggable` کشیده می‌شوند.
  - چیپ‌های فاقد قابلیت زمان‌بندی (مانند دامنه‌های `cycle`, `worshipDebt`, `prayer`) به صورت غیرفعال با شفافیت `0.55` نمایش داده شده و قابلیت درگ ندارند.
- **خارج کردن از زمان‌بندی (Unschedule DragTarget):**
  - بخش بدون زمان (`TimelineUntimedSection`) به عنوان `DragTarget<AgendaItem>` عمل کرده و در صورت رها کردن رویداد زمان‌دار روی آن، زمان زمان‌بندی پاک شده (`clearAgendaItemTime`) و به بخش بدون زمان منتقل می‌شود.
- **شیت انتخاب دامنه برای اسلات‌های خالی (Domain Selection Sheet):**
  - لمس اسلات خالی در تایم‌لاین شیت `DomainSelectionSheet` را با ۶ گزینه‌ی ساخت روتین، جلسه دوره آموزشی، گام هدف، مطالعه کنکور، فعالیت ورزشی و یادآور دارو همراه با زمان پیش‌فرض انتخاب شده باز می‌کند.

### ۲.۳. پترن دستورات واگردپذیر (Undoable Command Pattern)
- پیاده‌سازی کلاس‌های `_ScheduleItemCommand` و `_UnscheduleItemCommand` متصل به `CommandStack.instance`.
- نمایش پیام توست اطلاع‌رسانی (`RitmoToast`) با کلید "واگرد" (Undo) پس از هر تغییر زمان‌بندی یا خارج کردن از زمان‌بندی.

### ۲.۴. انیمیشن‌های پرمیوم و پشتیبانی از Reduce Motion
- استفاده از بسته `animations` و کلاس `PageTransitionSwitcher` همراه با `SharedAxisTransition`:
  - **تغییر مقیاس (Scale Switching):** انیمیشن `SharedAxisTransitionType.scaled`.
  - **تغییر تاریخ (Date Navigation):** انیمیشن `SharedAxisTransitionType.horizontal` با رعایت جهت RTL (پیمایش به روز بعد از سمت چپ وارد می‌شود).
- کلاس `CalendarMotion` تمام زمان‌بندی‌ها را کنترل کرده و در صورت فعال بودن `userReduceMotion` (کاهش حرکت)، تمامی مدت زمان انیمیشن‌ها را برابر `Duration.zero` قرار می‌دهد.

---

## ۳. وضعیت آزمون‌ها و تحلیل استاتیک

```bash
# تحلیل استاتیک دارت:
flutter analyze
-> 0 Errors (صفر خطا در کل پروژه)

# آزمون‌های واحد و ویجت اختصاصی پرامپت 028:
test/split_day_range_filter_test.dart        ✅ پاس شد
test/split_day_max_lanes_test.dart            ✅ پاس شد
test/untimed_drag_eligibility_test.dart       ✅ پاس شد
test/reduce_motion_test.dart                  ✅ پاس شد
test/split_day_rtl_order_test.dart           ✅ پاس شد
test/narrow_screen_fallback_test.dart         ✅ پاس شد
test/journey_interaction_test.dart            ✅ پاس شد
test/timeline_layout_max_height_test.dart     ✅ پاس شد
```

---

## ۴. جمع‌بندی
تمامی احکام و دستورات پرامپت 028 با دقت کامل و طبق استانداردهای ارشد مهندسی پیاده‌سازی و اعتبارسنجی گردید.
