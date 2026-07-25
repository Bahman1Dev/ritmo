
---

## بند ۰ — قوانین اجرا (قبل از هر کاری بخوان)

1. این پرامپت **بعد از ۰۲۷** اجرا می‌شود. اگر `lib/core/domain/models/duration_bounds.dart` وجود ندارد، **متوقف شو** و گزارش بده.
2. نمای تک‌ستونی روز **کاملاً جایگزین** می‌شود. هیچ مسیر موازی، هیچ فلگ، هیچ حالت دوگانه. کدهای مسیر قدیمی **حذف فیزیکی** شوند، نه کامنت.
3. **قانون دائمی پروژه:** هنگام افزودن هر موردی که ماژول اختصاصی دارد (روتین، دوره، هدف، عبادت، دارو، ورزش)، باید **پنجرهٔ افزودن موجود در همان ماژول** باز شود. ساختن شیت جدید موازی ممنوع است.
4. هر تغییر رفتاری باید از مسیرهای کانونی موجود عبور کند: `ActionRouter`، `CompletionGateway`، `RitmoExecutionKernel`، `CommandStack`. دور زدن ممنوع.
5. اعداد جادویی ممنوع — همه چیز در `CalendarTokens`.
6. کد مرده (متد بدون فراخوان، ویجت یتیم، import بلااستفاده، فایل بی‌ارجاع) در پایان **پاک** شود.
7. در پایان `flutter analyze` باید **صفر خطا و صفر هشدار** بدهد.
8. فایل `prompts/028_REPORT.md` در پایان ساخته شود.

---

## PASS 0 — تشخیص قبل از تغییر

این‌ها را اجرا کن و خروجی را در گزارش بیاور:

```bash
rg -n "TimelineGrid\(" lib/
rg -n "pxPerMinute" lib/
rg -n "hourAxisWidth" lib/
rg -n "TimelineUntimedSection" lib/
rg -n "onSlotTap|_handleSlotTap" lib/
rg -n "ثبت برنامه جدید در ساعت" lib/
rg -n "AnimatedSwitcher" lib/features/calendar/
rg -n "_MoveItemCommand|_ResizeItemCommand" lib/
rg -n "totalTimelineHeight|calculateLayout" lib/
```

هدف: پیدا کردن همهٔ نقاط اتصال قبل از بازنویسی. اگر `TimelineGrid` جایی غیر از `journey_screen.dart` استفاده شده، آن را هم مهاجرت بده.

---

# فاز ۱ — چیدمان دو ستونی روز

### T1 — توکن‌های جدید در `calendar_tokens.dart`

```dart
// ─── Split Day Layout ───
/// مرز تقسیم روز به دو ستون (بر حسب دقیقه از نیمه‌شب).
/// ۷۲۰ = ساعت ۱۲:۰۰
static const int splitBoundaryMinutes = 720;

/// ارتفاع هر دقیقه در نمای دو ستونی.
static const double pxPerMinuteSplit = 1.0;

/// عرض محور ساعت در نمای دو ستونی.
static const double hourAxisWidthSplit = 36.0;

/// فاصلهٔ بین دو ستون.
static const double columnGap = 10.0;

/// حداکثر تعداد لِین هم‌پوشان در هر ستون.
static const int maxLanesSplit = 2;

/// حداقل عرض صفحه برای نمای دو ستونی؛ کمتر از این، تک‌ستونی fallback.
static const double splitMinScreenWidth = 340.0;

/// ارتفاع هدر هر ستون.
static const double columnHeaderHeight = 62.0;

static const double textTitleSplit = 13.0;
static const double textMetaSplit = 10.0;
```

`pxPerMinute = 1.2` فعلی را **حذف نکن** — هنوز برای fallback تک‌ستونی روی صفحه‌های باریک لازم است.

---

### T2 — `TimelineLayoutEngine` بازه‌آگاه شود

فایل: `lib/features/calendar/presentation/logic/timeline_layout_engine.dart`

سازنده و `calculateLayout` باید بازهٔ دلخواه بگیرند، نه همیشه ۰..۱۴۴۰:

```dart
class TimelineLayoutEngine {
  const TimelineLayoutEngine({
    this.pxPerMinute = CalendarTokens.pxPerMinute,
    this.minItemHeight = 28.0,
    this.defaultDurationMinutes = DurationBounds.defaultMinutes,
    this.rangeStartMinutes = 0,
    this.rangeEndMinutes = 1440,
    this.maxLanes,           // null = بی‌نهایت (رفتار قبلی)
  });

  final int rangeStartMinutes;
  final int rangeEndMinutes;
  final int? maxLanes;

  int get rangeDurationMinutes => rangeEndMinutes - rangeStartMinutes;
  double get totalTimelineHeight => rangeDurationMinutes * pxPerMinute;
}
```

قواعد الزامی:

- **فیلتر بازه:** آیتمی وارد این ستون می‌شود که `startMinutes < rangeEndMinutes && endMinutes > rangeStartMinutes` باشد. یعنی آیتم‌هایی که مرز را قطع می‌کنند در **هر دو** ستون ظاهر می‌شوند.
- **بریدن در مرز:** برای هر ستون، `visibleStart = max(startMinutes, rangeStart)` و `visibleEnd = min(endMinutes, rangeEnd)`.
- `top = (visibleStart - rangeStartMinutes) * pxPerMinute`
- `height` از `visibleEnd - visibleStart` محاسبه شود، ولی **متن کارت همیشه مدت و بازهٔ واقعی کامل را نشان دهد**.
- دو فیلد جدید روی `TimelineLayoutItem`:

```dart
final bool isClippedAtStart;   // از ستون قبلی ادامه دارد
final bool isClippedAtEnd;     // به ستون بعدی ادامه دارد
```

- **سقف لِین:** اگر `maxLanes != null` و تعداد لِین‌های هم‌پوشان از آن بیشتر شد:
    - آیتم‌ها بر اساس `isEssential` سپس `priority` نزولی مرتب شوند
    - `maxLanes - 1` تای اول لِین مستقل بگیرند
    - بقیه در یک `TimelineLayoutItem` تجمیعی با فیلد جدید `overflowCount` قرار بگیرند و لیستشان در `overflowItems` نگه داشته شود

```dart
final int overflowCount;                  // 0 یعنی کارت عادی
final List<AgendaItem> overflowItems;
```

⚠️ `DurationBounds.sanitize` و `maxRenderMinutes` از ۰۲۷ **دست‌نخورده** باقی می‌مانند و قبل از این محاسبات اعمال می‌شوند.

---

### T3 — `TimelineHourAxis` بازه‌آگاه و دوطرفه

فایل: `lib/features/calendar/presentation/widgets/timeline_hour_axis.dart`

```dart
enum HourAxisSide { leading, trailing }

class TimelineHourAxis extends StatelessWidget {
  const TimelineHourAxis({
    super.key,
    required this.pxPerMinute,
    this.rangeStartMinutes = 0,
    this.rangeEndMinutes = 1440,
    this.width = CalendarTokens.hourAxisWidth,
    this.side = HourAxisSide.leading,
    this.labelFontSize = CalendarTokens.textLabel,
  });
}
```

- برچسب‌ها فقط برای ساعت‌های داخل بازه رسم شوند: از `ceil(rangeStart/60)` تا `floor(rangeEnd/60)`.
- `top = ((h * 60) - rangeStartMinutes) * pxPerMinute - 7`
- `side` تعیین می‌کند متن `textAlign` راست‌چین باشد یا چپ‌چین و خطوط شبکه از کدام لبه شروع شوند.
- فرمت برچسب با `toPersianDigits` و الگوی `HH:۰۰` حفظ شود.

**جهت‌گیری محورها (طبق موکاپ):** محور هر ستون روی **لبهٔ بیرونی** صفحه قرار می‌گیرد.

- ستون صبح (سمت راست صفحه) → `side: HourAxisSide.trailing` (محور در لبهٔ راست)
- ستون بعدازظهر (سمت چپ صفحه) → `side: HourAxisSide.leading` (محور در لبهٔ چپ)

---

### T4 — `TimelineGrid` بازه‌آگاه شود

فایل: `lib/features/calendar/presentation/widgets/timeline_grid.dart`

پارامترهای جدید:

```dart
final int rangeStartMinutes;
final int rangeEndMinutes;
final int? maxLanes;
final HourAxisSide axisSide;
final double hourAxisWidth;
final ScrollController? scrollController;   // برای اسکرول مستقل
final ValueChanged<AgendaItem>? onOverflowTap;
```

تغییرات لازم داخل بدنه:

- `totalHeight` از موتور چیدمان با همان بازه گرفته شود.
- **خط «الان»:** فقط رسم شود اگر `nowMinutes` داخل `[rangeStart, rangeEnd)` باشد. مختصاتش `(_nowMinutes - rangeStart) * pxPerMinute`. پیل زمان (`۱۴:۳۵`) با پس‌زمینهٔ `Colors.redAccent`، شعاع `CalendarTokens.radiusPill`، فونت ۱۱، در لبهٔ محور بچسبد.
- **دیمر گذشته:** ارتفاعش بر اساس همان بازه محاسبه شود؛ اگر کل بازه گذشته است، کل ستون دیم شود.
- **بلوک خواب:** با همان منطق برش بازه در هر ستون جدا رسم شود. اگر پنجرهٔ خواب هر دو ستون را قطع می‌کند، در هر دو ظاهر شود.
- **`onSlotTap`:** مقدار دقیقهٔ برگشتی باید `rangeStart` را اضافه کند، وگرنه ضربه در ستون بعدازظهر ساعت صبح می‌دهد. این یک باگ بسیار محتمل است — تست جدا برایش بنویس.
- **`_handleAutoEdgeScroll`:** از `scrollController` تزریق‌شده استفاده کند نه `PrimaryScrollController`.
- کلید کارت‌ها یکتا بماند: `ValueKey('item_${id}_${rangeStart}_${startMinutes}_${laneIndex}')`.

---

### T5 — کارت سرریز (`+n`)

فایل جدید: `lib/features/calendar/presentation/widgets/timeline_overflow_card.dart`

وقتی `overflowCount > 0`:

- کارتی با پس‌زمینهٔ `outlineVariant` با `alphaDomainFill`
- متن مرکزی: `'+${toPersianDigits('$overflowCount')} مورد دیگر'`
- لمس → `showModalBottomSheet` با فهرست `overflowItems`؛ لمس هر ردیف → `ActionRouter.open(context, item: item)`
- این کارت **درگ‌شدنی و resize‌شدنی نیست**.

---

### T6 — هدر ستون

فایل جدید: `lib/features/calendar/presentation/widgets/timeline_column_header.dart`

```dart
class TimelineColumnHeader extends StatelessWidget {
  const TimelineColumnHeader({
    super.key,
    required this.title,        // 'صبح' | 'بعدازظهر'
    required this.icon,
    required this.rangeLabel,   // '۰۰:۰۰ – ۱۲:۰۰'
    required this.isActive,     // آیا ساعت فعلی در این ستون است
  });
}
```

- ارتفاع `CalendarTokens.columnHeaderHeight`
- عنوان فونت ۱۵ بولد، بازه فونت ۱۱ با `textSecondary`
- آیکن‌ها: صبح → `Icons.wb_twilight_rounded` · بعدازظهر → `Icons.wb_sunny_rounded`
- اگر `isActive` باشد، یک هالهٔ ملایم `CalendarTokens.emerald` با `alphaDomainActive` پشت آیکن بنشیند
- عناوین و بازه‌ها از یک منبع واحد بیایند، نه هاردکد در دو جا:

```dart
class SplitDayRange {
  const SplitDayRange({required this.startMinutes, required this.endMinutes,
                       required this.titleFa, required this.icon});
  static const morning = SplitDayRange(startMinutes: 0, endMinutes: CalendarTokens.splitBoundaryMinutes, titleFa: 'صبح', ...);
  static const afternoon = SplitDayRange(startMinutes: CalendarTokens.splitBoundaryMinutes, endMinutes: 1440, titleFa: 'بعدازظهر', ...);
}
```

---

### T7 — ویجت اصلی `TimelineSplitDayView`

فایل جدید: `lib/features/calendar/presentation/widgets/timeline_split_day_view.dart`

```dart
class TimelineSplitDayView extends StatefulWidget {
  const TimelineSplitDayView({
    super.key,
    required this.items,
    required this.isToday,
    this.sleepStartMinutes,
    this.sleepEndMinutes,
    this.highlightedItemId,
    this.onItemTap,
    this.onItemMove,
    this.onItemResize,
    this.onSlotTap,
    this.onScheduleUntimed,
    this.onOverflowTap,
  });
}
```

ساختار:

```
LayoutBuilder
 └─ اگر width < splitMinScreenWidth → TimelineGrid تک‌ستونی (۰..۱۴۴۰)
 └─ وگرنه Directionality(rtl) → Row
      ├─ Expanded( ستون صبح )        ← سمت راست صفحه در RTL
      ├─ SizedBox(width: columnGap)
      └─ Expanded( ستون بعدازظهر )   ← سمت چپ صفحه
```

هر ستون:

```
Container(
  decoration: BoxDecoration(
    color: surfaceVariant,
    borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
    border: Border.all(color: outlineVariant.withValues(alpha: CalendarTokens.alphaCardBorder)),
  ),
  child: Column([
    TimelineColumnHeader(...),
    Expanded(
      child: SingleChildScrollView(
        controller: _morningController,   // یا _afternoonController
        child: TimelineGrid(
          rangeStartMinutes: range.startMinutes,
          rangeEndMinutes: range.endMinutes,
          pxPerMinute: CalendarTokens.pxPerMinuteSplit,
          hourAxisWidth: CalendarTokens.hourAxisWidthSplit,
          maxLanes: CalendarTokens.maxLanesSplit,
          axisSide: ...,
          scrollController: ...,
        ),
      ),
    ),
  ]),
)
```

🔴 **ترتیب حیاتی:** چون `Directionality` روی `rtl` است، **اولین فرزند `Row` سمت راست رندر می‌شود**. پس ستون صبح باید فرزند اول باشد. این را در کامنت کد صریح بنویس، وگرنه در ریفکتور بعدی جابه‌جا می‌شود.

**اسکرول مستقل:** دو `ScrollController` جدا (`_morningController`, `_afternoonController`) در `initState` ساخته و در `dispose` آزاد شوند. هیچ همگام‌سازی‌ای بینشان نباشد.

**اسکرول اولیهٔ هوشمند** در `WidgetsBinding.instance.addPostFrameCallback`:

- ستونی که ساعت فعلی در آن است → اسکرول به `(nowMinutes - rangeStart - 60) * pxPerMinute` با `clamp(0, maxScrollExtent)`
- ستون دیگر → اسکرول به اولین آیتم آن ستون، یا ۰ اگر خالی است
- اگر روز امروز نیست، هر دو ستون به اولین آیتمشان
- انیمیشن با `CalendarTokens.durationEmphasis` و `curveEmphasis`

**حالت خالی هر ستون:** به‌جای متن تمام‌صفحهٔ فعلی، متن کوچک وسط ستون: `'برنامه‌ای در این بازه نیست'` با فونت ۱۲ و `textSecondary`.

---

### T8 — اتصال در `journey_screen.dart` و حذف مسیر قدیمی

- در متد ساخت نمای روز، کل بلوک `Stack[Column[TimelineUntimedSection, Expanded(PrimaryScrollController → SingleChildScrollView → TimelineGrid)]]` **حذف** و با این جایگزین شود:

```
Column([
  TimelineUntimedSection(...),
  Expanded(child: TimelineSplitDayView(...)),
])
```

- `PrimaryScrollController` و `SingleChildScrollView` بیرونی حذف شوند (چون اسکرول به داخل ستون‌ها منتقل شده). padding پایین به داخل هر ستون منتقل شود: `MediaQuery.padding.bottom + kBottomNavigationBarHeight + 80`.
- `_scrollToMinutesValue` و `_scrollToTimeString` باید بدانند به کدام ستون اسکرول کنند. امضا را عوض کن:

```dart
void _scrollToMinutes(int minutes) {
  final isMorning = minutes < CalendarTokens.splitBoundaryMinutes;
  final controller = isMorning ? ... : ...;
  final offset = ((minutes - (isMorning ? 0 : CalendarTokens.splitBoundaryMinutes) - 60)
      .clamp(0, 1440)) * CalendarTokens.pxPerMinuteSplit;
  ...
}
```

این را از طریق یک `GlobalKey<TimelineSplitDayViewState>` یا یک کنترلر سبک انجام بده — انتخاب با تو، ولی **یک** مکانیزم باشد نه دو تا.

- `_openItemDetails` بدون تغییر بماند: `highlightItem` → اسکرول → `ActionRouter.open`.

---

# فاز ۲ — درگ‌اند‌دراپ آیتم‌های بدون زمان‌بندی

### T9 — واجد شرایط بودن

فایل: `lib/features/calendar/presentation/logic/direct_manipulation_eligibility.dart`

```dart
/// آیا این آیتمِ بدون زمان را می‌توان روی تایم‌لاین نشاند؟
static bool isSchedulable(AgendaItem item) {
  if (item.isTimed) return false;
  switch (item.domain) {
    case AgendaDomain.cycle:
    case AgendaDomain.worshipDebt:
      return false;
    case AgendaDomain.prayer:
      return false;   // زمان نماز از پنجرهٔ شرعی می‌آید، دستی تعیین نمی‌شود
    default:
      return true;
  }
}

/// آیا این آیتمِ زمان‌دار را می‌توان از زمان‌بندی خارج کرد؟
static bool isUnschedulable(AgendaItem item) =>
    item.isTimed && isDraggable(item) && !item.isFixed;
```

⛔ هیچ شرط موازی جدیدی جای دیگر ننویس. همهٔ مصرف‌کننده‌ها فقط از این کلاس بپرسند.

---

### T10 — چیپ‌های بخش بدون زمان‌بندی درگ‌شدنی شوند

فایل: `lib/features/calendar/presentation/widgets/timeline_untimed_section.dart`

- هر چیپ اگر `isSchedulable` بود در `LongPressDraggable<AgendaItem>` بپیچد با:
    - `delay: Duration(milliseconds: 300)` (کمتر از ۴۰۰ کارت‌ها، چون چیپ کوچک‌تر است)
    - `feedback`: همان چیپ با `Transform.scale(1.08)` و `Material(elevation: 8)`
    - `childWhenDragging`: `Opacity(0.3)`
    - `onDragStarted`: `RitmoHaptics.tap()`
- چیپ غیرواجد شرایط با `Opacity(0.55)` و بدون `LongPressDraggable`.

---

### T11 — پذیرش رها شدن روی ستون‌ها

در `TimelineGrid`:

- کل ناحیهٔ شبکه در یک `DragTarget<AgendaItem>` بپیچد که **هم** آیتم بدون زمان (زمان‌بندی جدید) **و هم** کارت زمان‌دار (جابه‌جایی موجود) را می‌پذیرد.
- 🔴 هر دو ستون باید در **یک** `DragTarget` مشترک سطح‌بالا هماهنگ باشند تا درگ از ستون صبح به ستون بعدازظهر ممکن شود. پیشنهاد: `DragTarget` را در `TimelineSplitDayView` بگذار و مختصات را با `RenderBox.globalToLocal` به ستون درست نگاشت کن.
- `onMove`: ghost آبی موجود (`Colors.blue` alpha `0.25`) رسم شود، **به‌علاوهٔ یک بَج زمان زنده**:
    - محتوا: `toPersianDigits(minutesToTimeString(snappedStart))`
    - در هر بار تغییر مقدار snap شده → `RitmoHaptics.tap()` (حس مغناطیس ۱۵ دقیقه‌ای)
- `onAcceptWithDetails`:
    - محاسبه: `rawMinutes = (localY / pxPerMinuteSplit) + rangeStart`
    - `start = TimelineSnappingHelper.snapStartMinutes(rawMinutes, durationMinutes: dur)`
    - `dur = item.durationMinutes ?? DurationBounds.defaultMinutes` سپس `DurationBounds.sanitize(dur)`
    - فراخوانی `onScheduleUntimed(item, start, dur)`

---

### T12 — لغو زمان‌بندی (درگ معکوس)

- `TimelineUntimedSection` خودش یک `DragTarget<AgendaItem>` شود که آیتم‌های `isUnschedulable` را می‌پذیرد.
- وقتی درگ یک کارت زمان‌دار شروع شد و بخش بدون زمان خالی است، آن بخش باید ظاهر شود با نوار خط‌چین و متن `'اینجا رها کن تا از زمان‌بندی خارج شود'`، با انیمیشن `durationStandard`.
- در `agenda_action_handler.dart` متد جدید:

```dart
Future<void> clearAgendaItemTime({required AgendaItem item});
```

که `timeOfDay` را `null` می‌کند. حتماً از همان مسیر کانونی `updateAgendaItemTimeAndDuration` استفاده کن یا اگر ممکن نبود، دقیقاً کنارش و با همان الگوی تراکنشی.

---

### T13 — کامندهای برگشت‌پذیر و رفع اسلات‌تپ ناتمام

در `journey_controller.dart`، کنار `_MoveItemCommand` و `_ResizeItemCommand`:

```dart
class _ScheduleItemCommand extends UndoableCommand { ... }    // بدون زمان → زمان‌دار
class _UnscheduleItemCommand extends UndoableCommand { ... }  // زمان‌دار → بدون زمان
```

هر دو با `CommandStack.instance.push` ثبت شوند و `undo` واقعی داشته باشند. بعد از موفقیت: `RitmoHaptics.success()` + `RitmoToast.show` با دکمهٔ «واگرد».

**و رفع کد ناتمام `_handleSlotTap`:** شیت موقت فعلی با متن `'ثبت برنامه جدید در ساعت X'` و توست `'کارت موقت ثبت سریع رویداد در ساعت X ایجاد شد.'` را **کامل حذف کن**. جایگزین: یک شیت انتخاب دامنه با فونت و استایل `RitmoActionSheet` که شش گزینه دارد و هر گزینه **پنجرهٔ افزودن موجود همان ماژول** را با `presetTime` باز می‌کند:

| گزینه | مقصد |
| --- | --- |
| روتین جدید | شیت افزودن روتین موجود در ماژول روتین‌ها |
| جلسهٔ دوره | شیت افزودن دورهٔ موجود (`setCourseSheetOpener`) |
| گام هدف | شیت افزودن گام موجود در ماژول اهداف |
| مطالعهٔ کنکور | `KonkurStudySheet` با `subjects` و `topics` **واقعی** از دیتابیس |
| فعالیت حرکتی | `showMovementLogSheet` |
| یادآور دارو | شیت افزودن دارو موجود |

🔴 هیچ‌کدام از این شیت‌ها را از نو نساز. اگر شیتی `presetTime` نمی‌پذیرد، فقط یک پارامتر اختیاری به همان شیت اضافه کن.

---

# فاز ۳ — انیمیشن‌های پرمیوم

### T14 — زیرساخت حرکت

فایل جدید: `lib/features/calendar/presentation/utils/calendar_motion.dart`

```dart
class CalendarMotion {
  /// آیا انیمیشن‌ها باید کاهش یابند؟
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations ||
      _userReduceMotion;   // از app_settings کلید 'reduce_motion'

  static Duration d(BuildContext context, Duration base) =>
      reduced(context) ? Duration.zero : base;
}
```

کلید `reduce_motion` با پیش‌فرض `'false'` به `seed_service` اضافه شود و یک سوییچ در تنظیمات ظاهر شود.

---

### T15 — گذار بین مقیاس‌ها و تاریخ‌ها

در `journey_screen.dart`، `AnimatedSwitcher` فعلی با `SharedAxisTransition` جایگزین شود:

- **تغییر مقیاس** (روز↔هفته↔ماه↔سال) → `SharedAxisTransitionType.scaled`
- **تغییر تاریخ** در همان مقیاس → `SharedAxisTransitionType.horizontal`
- 🔴 **در RTL جهت را معکوس کن.** «روز بعد» باید از سمت **چپ** وارد شود. اگر این را رعایت نکنی، حس عقب‌گرد زمانی می‌دهد. یک تست ویجت برای جهت بنویس.
- مدت: `CalendarTokens.durationEmphasis` · منحنی: `curveEmphasis`
- `KeyedSubtree(key: ValueKey('${scale}_${y}_${m}_${d}'))` حفظ شود.

---

### T16 — کارت → شیت (Container Transform)

- لمس کارت تایم‌لاین باید با `OpenContainer` (از `animations`) یا یک `Hero` سفارشی به شیت جزئیات تبدیل شود، نه پرش از پایین.
- `transitionDuration: CalendarTokens.durationEmphasis`
- `closedShape` با `radiusCard 16` → `openShape` با `radiusSheet 24`
- اگر پکیج `animations` در `pubspec.yaml` نیست، اضافه‌اش کن و در گزارش قید کن.
- 🔴 مسیر همچنان باید از `ActionRouter.open` عبور کند. انیمیشن نباید مسیر منطقی را دور بزند.

---

### T17 — ریزحرکت‌ها

| # | انیمیشن | مشخصات |
| --- | --- | --- |
| ۱ | ورود پلکانی کارت‌ها | fade + ۸px بالا آمدن · تأخیر ۲۰ms بین کارت‌ها · **سقف مجموع ۲۵۰ms** — با `math.min(index * 20, 250)` |
| ۲ | نبض خط «الان» | `AnimatedOpacity` بین `0.7` و `1.0` · دورهٔ ۲ ثانیه · فقط وقتی ستون visible است · با `TickerMode` مدیریت شود |
| ۳ | ثبت انجام | جاروی رنگ راست→چپ روی کارت با `ShaderMask` · سپس کشیده شدن تیک · `durationEmphasis` · `RitmoHaptics.success()` |
| ۴ | مورف چیپ→کارت | بعد از رها شدن، کارت با `scale 0.9 → 1.0` و fade وارد شود، نه ظهور ناگهانی |
| ۵ | تعویض تب ستون فعال | هدر ستونی که `isActive` می‌شود، هالهٔ آیکنش با `durationStandard` روشن شود |

---

### T18 — بودجهٔ عملکرد

- هر کارت داخل `RepaintBoundary`.
- `TimelineGridLines` داخل `RepaintBoundary` جدا (چون ثابت است و نباید با هر فریم انیمیشن دوباره نقاشی شود).
- `_startMinuteTimer` فقط وقتی `isToday` است فعال باشد؛ در `dispose` حتماً `cancel` شود.
- هدف: **۶۰fps پایدار** روی پروفایل میان‌رده هنگام درگ. اگر `flutter run --profile` افت فریم نشان داد، در گزارش بنویس کدام لایه مقصر بود.

---

# فاز ۴ — پاکسازی، تست، گزارش

### T19 — حذف کد مرده

بعد از اتمام فازهای ۱ تا ۳، این‌ها باید حذف شده باشند:

- مسیر رندر تک‌ستونی داخل `journey_screen.dart` (به‌جز fallback عرض کم که در `TimelineSplitDayView` متمرکز است)
- شیت موقت `'ثبت برنامه جدید در ساعت X'` و توست همراهش
- هر `import` بلااستفاده بعد از جابه‌جایی‌ها
- هر متد در `journey_screen.dart` / `timeline_grid.dart` که پس از ریفکتور هیچ فراخوانی ندارد
- خروجی `rg -n "PrimaryScrollController" lib/features/calendar/` باید خالی باشد

سپس اجرا کن و خروجی را در گزارش بیاور:

```bash
flutter analyze
dart fix --dry-run
```

---

### T20 — تست‌ها

فایل‌های جدید در `test/`:

| فایل | چه چیزی را تضمین می‌کند |
| --- | --- |
| `split_day_range_filter_test.dart` | آیتم ۱۱:۳۰–۱۲:۳۰ در **هر دو** ستون ظاهر شود با `isClippedAtEnd`/`isClippedAtStart` درست |
| `split_day_slot_tap_offset_test.dart` | ضربه در وسط ستون بعدازظهر عدد ≥۷۲۰ برگرداند، نه <۷۲۰ |
| `split_day_now_line_test.dart` | خط الان فقط در یک ستون رسم شود |
| `split_day_max_lanes_test.dart` | ۴ آیتم هم‌پوشان → ۱ کارت + کارت سرریز با `overflowCount == 3` |
| `split_day_rtl_order_test.dart` | ستون صبح در RTL سمت راست رندر شود |
| `untimed_drag_schedule_test.dart` | درگ چیپ → `timeOfDay` ست شود و مدت `DurationBounds.sanitize` شده باشد |
| `untimed_drag_eligibility_test.dart` | `cycle`، `worshipDebt` و `prayer` درگ‌شدنی نباشند |
| `unschedule_undo_test.dart` | لغو زمان‌بندی + واگرد، حالت اولیه را برگرداند |
| `narrow_screen_fallback_test.dart` | عرض ۳۲۰ → تک‌ستونی رندر شود |
| `reduce_motion_test.dart` | با `disableAnimations` همهٔ مدت‌ها صفر شوند |

تست‌های موجود ۰۲۷ (`timeline_layout_max_height_test`, `duration_bounds_test`, …) باید **همچنان سبز** باشند. اگر شکستند، تست را دستکاری نکن — کد را درست کن.

---

### T21 — گزارش

`prompts/028_REPORT.md` شامل: خروجی PASS 0، فهرست فایل‌های ساخته/تغییریافته/حذف‌شده، خروجی `flutter analyze`، تعداد کل تست‌های سبز، و هر انحرافی از این پرامپت با دلیل.

---

## سناریوهای پذیرش

| # | سناریو | نتیجهٔ انتظاری |
| --- | --- | --- |
| S1 | باز کردن تقویم در ساعت ۱۴:۳۵ | دو ستون؛ ستون بعدازظهر روی ~۱۳:۳۵ اسکرول‌شده با پیل `۱۴:۳۵`؛ ستون صبح روی اولین رویدادش |
| S2 | نماز مغرب و عشا ۱۹:۱۰–۲۰:۰۰ | فقط در ستون بعدازظهر، ارتفاع ۵۰ دقیقه، بدون سرریز |
| S3 | خواب ۲۳:۳۰–۰۷:۰۰ | در ستون بعدازظهر از ۲۳:۳۰ تا لبه با نشانگر «ادامه دارد»؛ در ستون صبح از ۰۰:۰۰ تا ۰۷:۰۰ |
| S4 | ۴ رویداد هم‌زمان ساعت ۱۰ | یک کارت اصلی + کارت `+۳`؛ لمس → شیت فهرست |
| S5 | ضربه روی خلأ ساعت ۱۶ در ستون چپ | شیت انتخاب دامنه با `presetTime = ۱۶:۰۰`؛ انتخاب «روتین جدید» → **همان** شیت افزودن روتین ماژول روتین‌ها |
| S6 | درگ چیپ «ریاضیات» به ساعت ۰۹:۰۰ | بَج زمان زنده حین درگ؛ پس از رها شدن کارت با مدت پیش‌فرض ظاهر شود؛ توست با «واگرد» |
| S7 | درگ همان کارت از ستون صبح به ستون بعدازظهر ساعت ۲۱ | جابه‌جایی موفق بین دو ستون بدون گیر کردن روی مرز |
| S8 | درگ یک کارت زمان‌دار به بخش بالا | از زمان‌بندی خارج شود و به چیپ تبدیل شود |
| S9 | تلاش برای درگ کارت «چرخه ماهانه» | اصلاً درگ شروع نشود |
| S10 | عرض صفحه ۳۲۰ | تک‌ستونی ۰..۱۴۴۰ با `pxPerMinute` قدیمی |
| S11 | جابه‌جایی روز به روز بعد | ورود از سمت چپ (RTL)، مدت ۳۰۰ms |
| S12 | فعال کردن «کاهش حرکت» | همهٔ گذارها آنی، بدون هیچ خطا |
| S13 | اسکرول ستون صبح | ستون بعدازظهر **تکان نخورد** |

---

## خطوط قرمز 🔒

1. `DurationBounds` و منطق `isTruncated` از ۰۲۷ **دست‌نخورده** بمانند. این پرامپت فقط چیدمان و تعامل را عوض می‌کند، نه اعتبارسنجی مدت.
2. هیچ تغییری در `CompletionGateway`، `RitmoExecutionKernel`، `ProgressionEngine` و ماژول ورزش تکمیلی داده نشود.
3. هیچ شیت افزودن جدیدی ساخته نشود — فقط شیت‌های موجود ماژول‌ها فراخوانی شوند.
4. زمان نماز هرگز با درگ تغییر نکند؛ پنجرهٔ شرعی منبع حقیقت است.
5. هیچ حالت موازی تک‌ستونی/دو‌ستونی برای کاربر باقی نماند؛ تک‌ستونی فقط fallback خودکار عرض کم است.
6. ترتیب RTL (صبح = راست) نباید در هیچ ریفکتوری عوض شود — با تست محافظت شده است.

---
