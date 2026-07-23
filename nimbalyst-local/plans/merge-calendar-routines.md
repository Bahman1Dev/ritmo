---
planStatus:
  planId: plan-merge-calendar-routines
  title: تلفیق روتین‌ها در تقویم + جایگزینی تب با دستیار هوشمند
  status: ready-for-development
  planType: refactor
  priority: high
  owner: Bahman
  stakeholders: []
  tags:
    - refactor
    - ui
    - calendar
    - routines
    - assistant
    - deduplication
  created: "2026-06-28"
  updated: "2026-06-28T00:00:00.000Z"
  progress: 0
---
# تلفیق روتین‌ها در تقویم + جایگزینی تب با دستیار هوشمند ریتمو

## هدف (Objective)

۱. تبدیل **تقویم** به تنها ظرف اصلی روتین‌ها؛ نقاط قوت منحصربه‌فرد صفحه‌ی روتین‌ها داخل **نمای روزِ تقویم** تزریق می‌شوند.
۲. **اسلات تب روتین‌ها در نوار پایین حذف نمی‌شود؛ محتوایش به «دستیار هوشمند ریتمو» (`AssistantScreen`) تغییر می‌کند.**
۳. حذف ~۸۰۰ تا ۱۰۰۰ خط کد تکراری با استخراج ویجت‌ها و توابع مشترک به لایه‌ی `shared/`.

**اصل راهنما:** هیچ قابلیتی برای کاربر از دست نرود.

## تصمیمات نهایی‌شده (Finalized Decisions)

- ✅ **تقویم ظرف اصلی است** (روتین‌ها در نمای روز تزریق می‌شوند).
- ✅ **تب روتین‌ها → دستیار هوشمند ریتمو** (ایندکس ۳ همان می‌ماند؛ فقط صفحه و آیکون/برچسب عوض می‌شوند). چون ایندکس جابه‌جا نمی‌شود، ریسک شکستن ناوبری حداقل است.
- ✅ **تب‌های فیلتر ناقص روتین‌ها (هفته / همه) تکمیل می‌شوند** (نه حذف).
- ✅ **بدون mockup** — مستقیم پیاده‌سازی.

## وضعیت فعلی (Current State)

| فایل | خطوط | نقش |
| --- | --- | --- |
| `lib/features/calendar/presentation/calendar_screen.dart` | ۲۲۶۱ | ظرف اصلی (نمای روز/هفته/ماه) |
| `lib/features/routines/presentation/routines_list_screen.dart` | ۲۱۶۷ | لیست روتین‌های امروز (حذف می‌شود) |
| `lib/features/assistant/presentation/assistant_screen.dart` | — | دستیار هوشمند (`const AssistantScreen()`) — جایگزین تب |
| `lib/features/today/presentation/home_navigation_shell.dart` | — | سیم‌کشی نوار پایین |

**ناوبری فعلی** (در `home_navigation_shell.dart`، لیست `_screens`):
- index 0: `SystemsHubScreen` (سیستم‌ها)
- index 1: `InsightsScreen` (بینش‌ها)
- index 2: `NowDashboardScreen` (دکمه‌ی مرکزی خانه)
- index 3: `RoutinesListScreen` (روتین‌ها) ← **به `AssistantScreen` تغییر می‌کند**
- index 4: `CalendarScreen` (تقویم) ← **ظرف نهایی روتین‌ها**

نوار پایین در `_buildCustomBottomBar` (RTL):
- خط ۱۶۹: آیتم تقویم → `_buildNavItem(4, ...)`
- خط ۱۷۲: آیتم روتین‌ها → `_buildNavItem(3, CupertinoIcons.list_bullet_below_rectangle, CupertinoIcons.list_bullet, 'روتین‌ها')` ← **آیکون و برچسب به دستیار تغییر می‌کند**

### کد تکراری شناسایی‌شده

| مورد | تقویم | روتین‌ها | وضعیت |
| --- | --- | --- | --- |
| `_getCategoryTitle` / `_getCategoryIconData` / `_getCategoryColor` | calendar 399-452 | routines 138-215 | ۱۰۰٪ یکسان |
| `_calculateStreak` | calendar 1938-1966 | routines 217-245 | ۱۰۰٪ یکسان |
| `_isCategoryModuleEnabled` | calendar 287-292 | routines 125-136 | ۱۰۰٪ یکسان |
| شیت نیّت (Niyyah Sheet) | calendar 1547-1811 | routines 1404-1657 | تقریباً یکسان |
| شیت جزئیات (Details Sheet) | calendar 1814-1936 | routines 2078-2165 | تقریباً یکسان |
| کارت روتین | calendar 1067-1210 | routines 1103-1280 | تقریباً یکسان |
| `_completeTask` / `_completeRoutine` | calendar 1984-2004 | routines 258-283 | منطق یکسان |
| `_snoozeRoutine` | calendar 2006-2043 | routines 285-326 | منطق یکسان |

### قابلیت‌های منحصربه‌فرد (نباید از دست بروند)

**فقط تقویم:** پیمایش روز/هفته/ماه، امتیاز ریتم هر روز، تشخیص تداخل، اوقات شرعی، روزهای استثنا (تعطیل/خاص)، تاریخ جلالی.

**فقط روتین‌ها (باید به نمای روز منتقل شوند):** کارت تمرکز هوشمند (Smart Focus)، حرکات Swipe (راست=نیّت، چپ=مدیریت)، دکمه‌ی شناور افزودن سریع (FAB)، جستجوی متنی، تب‌های فیلتر.

## معماری هدف (Target Architecture)

```
lib/features/routines/
  shared/                          ← لایه‌ی مشترک جدید
    routine_category_helper.dart   ← توابع دسته‌بندی + استریک (static)
    routine_actions.dart           ← complete / snooze / data-load مشترک
    widgets/
      routine_card.dart            ← کارت روتین مشترک
      routine_niyyah_sheet.dart    ← شیت نیّت مشترک
      routine_details_sheet.dart   ← شیت جزئیات مشترک
      smart_focus_card.dart        ← کارت تمرکز هوشمند (منتقل‌شده)

lib/features/calendar/presentation/
  calendar_screen.dart             ← ظرف نهایی؛ نمای روز نقاط قوت روتین‌ها را می‌گیرد

lib/features/today/presentation/
  home_navigation_shell.dart       ← اسلات ۳ به AssistantScreen تغییر می‌کند

lib/features/routines/presentation/
  routines_list_screen.dart        ← حذف می‌شود (فاز ۶)
```

## فازبندی (از کم‌ریسک به پرریسک)

> هر فاز مستقل، قابل کامپایل و قابل تست است. بعد از هر فاز `flutter analyze` اجرا و اپ باید بدون رگرسیون رفتاری کار کند.

### فاز ۰ — آماده‌سازی
- [ ] commit کردن تغییرات امنیتی AI روی شاخه‌ی فعلی
- [ ] ساخت شاخه‌ی `refactor/merge-calendar-routines`
- [ ] حسابرسی ارجاع‌ها: جستجوی `RoutinesListScreen`، `navigate_tab`، `onNavigateToTab`، و عدد ایندکس ۳ در کل کدبیس. (چون اسلات ۳ فقط محتوایش عوض می‌شود نه حذف، انتظار می‌رود کم‌ریسک باشد؛ ولی هر جایی که با فرض «ایندکس ۳ = روتین‌ها» کار می‌کند باید بازبینی شود.)

### فاز ۱ — استخراج توابع کمکی (صفر ریسک UI)
- [ ] ساخت `routines/shared/routine_category_helper.dart` با متدهای static: `getCategoryTitle`, `getCategoryIconData`, `getCategoryColor`, `calculateStreak`, `isCategoryModuleEnabled`
- [ ] جایگزینی استفاده‌ها در `calendar_screen.dart` و `routines_list_screen.dart`
- [ ] حذف نسخه‌های تکراری
- [ ] تست: هر دو صفحه دقیقاً مثل قبل

### فاز ۲ — ویجت کارت روتین مشترک
- [ ] ساخت `shared/widgets/routine_card.dart` با ورودی `Routine` + callbackها (`onComplete`, `onSnooze`, `onTap`, `onSwipeManage`)
- [ ] جایگزینی در `routines_list_screen.dart` (منبع اصلی)، سپس نمای روزِ تقویم
- [ ] تست: ظاهر و رفتار یکسان

### فاز ۳ — شیت‌های مشترک
- [ ] ساخت `shared/widgets/routine_niyyah_sheet.dart` (ورودی `Routine`، callbackهای تایمر/ثبت‌فوری/اسنوز/ویرایش/جزئیات)
- [ ] ساخت `shared/widgets/routine_details_sheet.dart`
- [ ] جایگزینی در هر دو صفحه
- [ ] تست: نیّت، تایمر، ثبت فوری، جزئیات و استریک

### فاز ۴ — منطق مشترک اکشن‌ها
- [ ] ساخت `shared/routine_actions.dart` با `completeRoutine`, `snoozeRoutine` و کوئری‌های مشترک تکمیل/اسنوز (به‌علاوه سینک `SnapshotSyncService` و `AlarmSchedulerService`)
- [ ] اتصال هر دو صفحه
- [ ] تست: تکمیل، اسنوز، سینک

### فاز ۵ — انتقال نقاط قوت روتین‌ها به نمای روزِ تقویم
- [ ] انتقال کارت تمرکز هوشمند به `shared/widgets/smart_focus_card.dart` و افزودن به بالای نمای روز
- [ ] افزودن حرکات Swipe به کارت‌های نمای روز (راست=نیّت، چپ=مدیریت). محدود به سطح کارت تا با پیمایش تاریخ تداخل نکند.
- [ ] افزودن دکمه‌ی شناور افزودن سریع (FAB) به تقویم
- [ ] افزودن جستجوی متنی به نمای روز
- [ ] **تکمیل تب‌های فیلتر**: «هفته» و «همه» را به‌طور کامل پیاده‌سازی کن (علاوه بر «امروز»، «تعویق‌شده»، «انجام‌شده» که کار می‌کنند). فیلتر باید روی منبع داده‌ی نمای روز اعمال شود.
- [ ] تست: نمای روزِ تقویم همه‌ی کارهای صفحه‌ی روتین‌ها را انجام دهد

### فاز ۶ — جایگزینی تب با دستیار + حذف صفحه‌ی روتین‌ها
- [ ] در `home_navigation_shell.dart`: در لیست `_screens`، اندیس ۳ از `const RoutinesListScreen()` به `const AssistantScreen()` تغییر کند
- [ ] import مربوط به `AssistantScreen` اضافه و import `RoutinesListScreen` حذف شود
- [ ] خط ۱۷۲: آیتم ناوبری به آیکون/برچسب دستیار تغییر کند (مثلاً `CupertinoIcons.sparkles` / «دستیار»). ایندکس همان ۳ می‌ماند.
- [ ] اطمینان از اینکه `AssistantScreen` جای دیگری به‌صورت تکراری در نوار نیست
- [ ] حذف فایل `routines_list_screen.dart` پس از اطمینان از عدم استفاده + پاک‌سازی importهای orphan
- [ ] تست کامل: پیمایش همه‌ی تب‌ها، دکمه‌ی مرکزی، رویدادهای `navigate_tab`، و باز شدن دستیار از تب جدید

### فاز ۷ — پاک‌سازی و تأیید نهایی
- [ ] `flutter analyze` کامل بدون خطای جدید
- [ ] تست دستی روی Chrome: `flutter run -d chrome --web-browser-flag "--disable-web-security" --dart-define-from-file=env.json`
- [ ] بررسی شمارش خطوط (هدف: کاهش ~۸۰۰ خط)
- [ ] به‌روزرسانی این سند (progress=100, status=in-review)

## ریسک‌ها و کاهش آن‌ها (Risks)

| ریسک | شدت | کاهش |
| --- | --- | --- |
| کدی جایی فرض کند «ایندکس ۳ = روتین‌ها» | کم | حسابرسی فاز ۰؛ ایندکس جابه‌جا نمی‌شود |
| تفاوت ظریف بین دو نسخه‌ی شیت/کارت گم شود | متوسط | فاز به فاز، هر بار یک صفحه، تست بعد از هر استخراج |
| تداخل Swipe با پیمایش تاریخ در نمای روز | متوسط | محدود کردن Swipe به سطح کارت |
| شلوغی نمای روز (Smart Focus + لیست + امتیاز + اوقات شرعی + جستجو + فیلتر) | متوسط | چیدمان بخش‌بندی‌شده و قابل جمع‌شدن (collapsible) |
| دستیار از تب جدید به‌درستی initialize نشود | کم | استفاده از `const AssistantScreen()` بدون آرگومان؛ تست باز/بسته شدن |

## معیار موفقیت (Definition of Done)

- نوار پایین: تب روتین‌ها جایش را به دستیار هوشمند داده؛ تقویم همه‌ی کارهای قبلی هر دو صفحه را انجام می‌دهد.
- هیچ قابلیتی از کاربر گرفته نشده؛ تب‌های فیلتر «هفته/همه» حالا کار می‌کنند.
- کد تکراری حذف و در لایه‌ی `shared/` متمرکز شده.
- `flutter analyze` بدون خطای جدید؛ اپ روی Chrome بدون رگرسیون.

---

## پرامپت کامل برای ایجنت هوش مصنوعی (Self-Contained Agent Prompt)

> این بخش را عیناً به ایجنت هوش مصنوعی بدهید. خودبسنده است و همه‌ی مسیرها، خطوط و ترتیب کار را دارد.

```text
شما یک مهندس ارشد Flutter هستید و روی پروژه‌ی «Ritmo3» کار می‌کنید (مسیر ریشه: ritmo/). زبان UI فارسی و RTL است و فونت Vazirmatn. هدف زیر را دقیقاً و فاز‌به‌فاز انجام بده. بعد از هر فاز حتماً `flutter analyze` بگیر و فقط وقتی خطای جدیدی نیست برو فاز بعد. هیچ قابلیتی نباید از کاربر گرفته شود.

=== هدف کلی ===
۱) صفحه‌ی «تقویم» (lib/features/calendar/presentation/calendar_screen.dart) تنها ظرف روتین‌ها شود و قابلیت‌های منحصربه‌فرد صفحه‌ی «روتین‌ها» (lib/features/routines/presentation/routines_list_screen.dart) داخل «نمای روزِ» تقویم تزریق شوند.
۲) در نوار پایین (lib/features/today/presentation/home_navigation_shell.dart) اسلات تب روتین‌ها (اندیس ۳) حذف نشود؛ محتوای آن از RoutinesListScreen به AssistantScreen (lib/features/assistant/presentation/assistant_screen.dart، سازنده‌ی const AssistantScreen()) تغییر کند. اندیس ۳ ثابت می‌ماند؛ فقط صفحه و آیکون/برچسب عوض می‌شوند.
۳) حدود ۸۰۰ تا ۱۰۰۰ خط کد تکراری بین دو صفحه با استخراج به یک لایه‌ی مشترک حذف شود.

=== کد تکراری که باید مشترک شود ===
- توابع دسته‌بندی و استریک (۱۰۰٪ یکسان): getCategoryTitle / getCategoryIconData / getCategoryColor / calculateStreak / isCategoryModuleEnabled.
  مکان فعلی: calendar_screen.dart خطوط ~287-292 و 399-452 و 1938-1966 ؛ routines_list_screen.dart خطوط ~125-136 و 138-215 و 217-245.
- شیت نیّت (Niyyah Sheet): calendar_screen.dart ~1547-1811 ؛ routines_list_screen.dart ~1404-1657.
- شیت جزئیات (Details Sheet): calendar_screen.dart ~1814-1936 ؛ routines_list_screen.dart ~2078-2165.
- کارت روتین: calendar_screen.dart ~1067-1210 ؛ routines_list_screen.dart ~1103-1280.
- منطق تکمیل و اسنوز: calendar_screen.dart ~1984-2043 ؛ routines_list_screen.dart ~258-326. (هر دو از DatabaseHelper, AlarmSchedulerService, SnapshotSyncService استفاده می‌کنند.)

=== قابلیت‌هایی که نباید گم شوند ===
فقط تقویم: نمای روز/هفته/ماه، امتیاز ریتم هر روز، تشخیص تداخل زمانی، اوقات شرعی، روزهای استثنا (NORMAL/SPECIAL/REST)، تاریخ جلالی.
فقط روتین‌ها (باید به نمای روزِ تقویم منتقل شوند): کارت تمرکز هوشمند (Smart Focus)، حرکات Swipe (راست=نیّت، چپ=مدیریت)، دکمه‌ی شناور افزودن سریع (FAB)، جستجوی متنی، تب‌های فیلتر.

=== معماری مقصد ===
یک لایه‌ی مشترک بساز:
lib/features/routines/shared/routine_category_helper.dart   (متدهای static)
lib/features/routines/shared/routine_actions.dart           (complete/snooze/load مشترک)
lib/features/routines/shared/widgets/routine_card.dart
lib/features/routines/shared/widgets/routine_niyyah_sheet.dart
lib/features/routines/shared/widgets/routine_details_sheet.dart
lib/features/routines/shared/widgets/smart_focus_card.dart

=== فازها (به همین ترتیب) ===

فاز ۱ (صفر ریسک): routine_category_helper.dart را بساز و هر ۵ تابع را به‌صورت static داخلش بگذار. هر دو صفحه را به آن وصل کن و نسخه‌های تکراری را حذف کن. analyze بگیر. مطمئن شو رفتار هر دو صفحه عوض نشده.

فاز ۲: routine_card.dart را بساز؛ یک Routine و callbackها (onComplete, onSnooze, onTap, onSwipeManage) بگیرد و کارت را با همان ظاهر فعلی (آیکون دسته، عنوان، زمان، چک‌مارک، نشان essential/energy، استریک) بسازد. اول در routines_list_screen.dart جایگزین کن، بعد در نمای روزِ تقویم. analyze بگیر.

فاز ۳: routine_niyyah_sheet.dart و routine_details_sheet.dart را بساز (ورودی استاندارد Routine). شیت نیّت باید سه حالت کامل/سبک/حداقلی، دکمه‌ی «شروع تایمر تمرکز» و «ثبت فوری بدون تایمر»، و گزینه‌های اسنوز/ویرایش/جزئیات را داشته باشد. در هر دو صفحه جایگزین کن. analyze بگیر.

فاز ۴: routine_actions.dart را بساز و منطق completeRoutine و snoozeRoutine و کوئری‌های تکرارشونده‌ی تکمیل/اسنوز (شامل سینک) را داخلش متمرکز کن. هر دو صفحه را به آن وصل کن. analyze بگیر.

فاز ۵: قابلیت‌های منحصربه‌فرد روتین‌ها را به نمای روزِ تقویم اضافه کن:
  - smart_focus_card.dart را بساز/منتقل کن و بالای نمای روز نشان بده.
  - حرکات Swipe را به کارت‌های نمای روز اضافه کن (راست=نیّت، چپ=مدیریت). Swipe را به سطح خود کارت محدود کن تا با ناوبری تاریخ تداخل نکند.
  - دکمه‌ی شناور افزودن سریع (FAB) که RoutineCreateFlow را باز می‌کند به تقویم اضافه کن.
  - جستجوی متنی روتین‌ها (بر اساس عنوان/توضیح) به نمای روز اضافه کن.
  - تب‌های فیلتر را کامل کن: علاوه بر «امروز/تعویق‌شده/انجام‌شده» که کار می‌کنند، فیلترهای «هفته» و «همه» را هم کاملاً پیاده‌سازی کن و روی منبع داده‌ی نمای روز اعمال کن.
  analyze بگیر و مطمئن شو نمای روزِ تقویم هر کاری که صفحه‌ی روتین‌ها می‌کرد را انجام می‌دهد.

فاز ۶: تب را جایگزین کن:
  - در home_navigation_shell.dart، در لیست _screens اندیس ۳ را از const RoutinesListScreen() به const AssistantScreen() تغییر بده. import لازم را اضافه و import روتین‌ها را حذف کن.
  - در _buildCustomBottomBar خط آیتم اندیس ۳ (فعلاً 'روتین‌ها' با CupertinoIcons.list_bullet_below_rectangle/list_bullet) را به آیکون و برچسب دستیار تغییر بده، مثل: _buildNavItem(3, CupertinoIcons.sparkles, CupertinoIcons.sparkles, 'دستیار'). اندیس را عوض نکن.
  - کل کدبیس را برای استفاده‌های دیگر RoutinesListScreen و فرض‌های «اندیس ۳ = روتین‌ها» (مثل navigate_tab، onNavigateToTab) بررسی و اصلاح کن.
  - بعد از اطمینان از عدم استفاده، فایل routines_list_screen.dart را حذف کن و importهای orphan را پاک کن.
  analyze بگیر.

فاز ۷: analyze کامل بدون خطای جدید. سپس با این دستور اجرا و دستی تست کن:
  flutter run -d chrome --web-browser-flag "--disable-web-security" --dart-define-from-file=env.json
  چک کن: همه‌ی تب‌ها کار کنند، تب دستیار باز شود، نمای روزِ تقویم همه‌ی اکشن‌های روتین (تکمیل/اسنوز/نیّت/Smart Focus/جستجو/فیلتر هفته و همه) را داشته باشد، و هیچ رگرسیونی نباشد.

=== قواعد ===
- بعد از هر فاز analyze بگیر؛ با خطای جدید جلو نرو.
- سبک کد، نام‌گذاری و چگالی کامنت‌ها را با کد اطراف هماهنگ کن. RTL و فونت Vazirmatn را حفظ کن.
- تغییر رفتاری ناخواسته نده؛ این یک refactor + جابه‌جایی تب است، نه بازطراحی.
- متن‌های فارسی موجود (مثل پیام‌های نیّت/اسنوز/سهمیه) را عیناً حفظ کن.
```
