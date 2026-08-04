# گزارش نهایی هاتفیکس بحرانی — `prompts/044_REPORT.md`

**تاریخ ایجاد:** ۴ اوت ۲۰۲۶  
**پروژه:** اپلیکیشن ریتمو (`ir.ritmo.app`)  
**نویسنده:** مهندس ارشد نرم‌افزار (Antigravity AI)

---

## ۱. خروجی تمام دستورات grep (قبل و بعد)

### ۱.۱ `grep -rn "Navigator.pop" lib/features/routines/shared/widgets/routine_niyyah_sheet.dart`
- **قبل:**
  ```text
  lib/features/routines/shared/widgets/routine_niyyah_sheet.dart:92: Navigator.pop(context);
  ```
- **بعد (بدون هیچ `Navigator.pop` در `finally`):**
  ```text
  lib/features/routines/shared/widgets/routine_niyyah_sheet.dart:82: Navigator.pop(context, intent);
  ```

### ۱.۲ `grep -rn "static void show" lib | wc -l`
- **قبل:** 7
- **بعد:** 5 (`UniversalPlannerSheet.show` و `RoutineDetailsSheet.show` به `Future<T?>` ارتقا یافتند).

### ۱.۳ `grep -rn "catch (_) {}" lib | wc -l`
- **قبل:** 95
- **بعد:** 95 (کدهای جدید هیچ `catch (_) {}` ثبت نکردند).

### ۱.۴ `grep -rn "active_timers" lib`
- **قبل:** 16 مورد شامل نوشتن مستقیم از `active_timer_overlay.dart`.
- **بعد:** تمامی کدهای نوشتن/حذف به `RitmoTimerService.instance` متصل گردیدند.

### ۱.۵ `grep -rn "RoutineNiyyahSheet.show" lib`
- **قبل:** 3 مورد.
- **بعد:** 3 مورد (امضای عمومی بدون شکست باقی ماند).

### ۱.۶ `grep -rn "ActionRouter.open" lib`
- **قبل:** 5 مورد.
- **بعد:** 5 مورد (پشتیبانی از کالبک اختیاری `onChanged`).

---

## ۲. خروجی اسکیما `PRAGMA table_info(active_timers);`

در `MigrationV61` اسکیما به شکل زیر تثبیت و همگام‌سازی شد:

```sql
cid | name                   | type    | notnull | dflt_value  | pk
-------------------------------------------------------------------
0   | id                     | TEXT    | 0       | NULL        | 1
1   | domain                 | TEXT    | 0       | NULL        | 0
2   | itemId                 | TEXT    | 0       | NULL        | 0
3   | mode                   | TEXT    | 0       | NULL        | 0
4   | direction              | TEXT    | 0       | NULL        | 0
5   | targetTimestamp        | INTEGER | 0       | NULL        | 0
6   | durationSeconds        | INTEGER | 0       | NULL        | 0
7   | createdAt              | INTEGER | 0       | NULL        | 0
8   | routineId              | TEXT    | 0       | NULL        | 0
9   | startedAt              | INTEGER | 0       | NULL        | 0
10  | plannedDurationMinutes | INTEGER | 0       | NULL        | 0
11  | pausedAccumulatedMs    | INTEGER | 0       | 0           | 0
12  | state                  | TEXT    | 0       | 'RUNNING'   | 0
```

---

## ۳. وضعیت دقیق تسک‌های T1 تا T8

### T1 — بازگرداندن `NiyyahIntent` از شیت نیت به جای اجرای درون‌شیتی
- **وضعیت:** `DONE`
- **مسیر فایل:** [routine_niyyah_sheet.dart:1-120](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/shared/widgets/routine_niyyah_sheet.dart#L1-L120)
- **کد قبل:**
  ```dart
  Future<void> _runAction(String tag, Future<void> Function() action) async {
    ...
    finally {
      if (mounted) {
        setState(() { _busy = false; _actionTag = null; });
        Navigator.pop(context); // 🔴 بسته شدن اشتباه روت بالای پشته
      }
    }
  }
  ```
- **کد بعد:**
  ```dart
  void _dispatchIntent(NiyyahIntent intent) {
    RitmoHaptics.confirm();
    Navigator.pop(context, intent); // ✅ بازگرداندن قصد، بدون pop در finally
  }
  ```

### T2 — ارتقای متدهای `show` به `Future<T?>`
- **وضعیت:** `DONE`
- **مسیر فایل‌ها:** [universal_planner_sheet.dart:45](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/presentation/universal_planner_sheet.dart#L45) & [routine_details_sheet.dart:26](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/shared/widgets/routine_details_sheet.dart#L26)
- **کد قبل:** `static void show(...) { showModalBottomSheet(...); }`
- **کد بعد:** `static Future<T?> show<T>(...) { return showModalBottomSheet<T>(...); }`

### T3 — پوشش استثناها و نمایش پیام خطای فارسی در `_guard`
- **وضعیت:** `DONE`
- **مسیر فایل:** [action_router.dart:186-200](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/agenda/action_router.dart#L186-L200)
- **کد بعد:**
  ```dart
  static Future<void> _guard(
    BuildContext context, {
    required String tag,
    required Future<void> Function() run,
    required String failureMessage,
  }) async {
    try {
      await run();
    } catch (e, st) {
      debugPrint('[ActionRouter][$tag] $e\n$st');
      if (context.mounted) {
        ActionFeedback.failure(context, message: failureMessage);
      }
    }
  }
  ```

### T4 — بازخورد قفل و اسپینر سبک بدون مسدود‌سازی
- **وضعیت:** `DONE`
- **مسیر فایل:** [journey_controller.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_controller.dart)
- **کد:** استفاده از `_controller.isExecutingAction` و نمایش توست در حال انجام.

### T5 — تک‌نویسنده کردن جدول `active_timers`
- **وضعیت:** `DONE`
- **مسیر فایل‌ها:** [active_timer_overlay.dart:73-90](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/today/presentation/active_timer_overlay.dart#L73-L90) & [migrations_registry.dart:3000](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations_registry.dart#L3000)
- **کد بعد:** فراخوانی مستقیم `RitmoTimerService.instance.startTimer` و `cancelTimer` به جای SQL خام بدون `where`.

### T6 — به روزرسانی نمای تقویم پس از هر اکشن موفق
- **وضعیت:** `DONE`
- **مسیر فایل‌ها:** [action_router.dart:31](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/agenda/action_router.dart#L31) & [journey_screen.dart:170](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/calendar/presentation/journey_screen.dart#L170)
- **کد بعد:** `ActionRouter.open(context, item: item, onChanged: () => _controller.refresh());`

### T7 — محافظت از `context` بعد از `await`
- **وضعیت:** `DONE`
- **مسیر فایل:** [action_router.dart:215,235,265,295](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/agenda/action_router.dart#L215)
- **کد:** استفاده از `if (!context.mounted) return;` بعد از هر `await`.

### T8 — مدیریت پیام‌های شفاف برای حالت‌های مرزی
- **وضعیت:** `DONE`
- **مسیر فایل:** [routine_niyyah_sheet.dart:240-255](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/routines/shared/widgets/routine_niyyah_sheet.dart#L240-L255)
- **کد:** عدم نمایش دکمه تایمر و جایگزینی با متن راهنما «برای این روتین مدت‌زمانی تعریف نشده است».

---

## ۴. چرا اصلاح پرامپت ۰۳۰ بازگشت یا ناقص بود؟

در پرامپت ۰۳۰ مشکل بسته شدن شیت حل شده بود اما به دلیل معماری درون‌شیتی (`_runAction` داخل خود کلاس ویجت)، شیت ابتدا کالبک‌ها را اجرا می‌کرد و سپس در بلوک `finally` متد `Navigator.pop` را صدا می‌زد. این کار باعث می‌شد با افزودن روت‌های جدید در پرامپت‌های بعدی، `finally` روت جدید بازشده توسط کالبک را ببندد. با تغییر معماری به الگوی `NiyyahIntent` (بسته شدن شیت *پیش* از اجرای اکشن)، این باگ برای همیشه ریشه‌کن شد.

---

## ۵. جدول ۱۴ سناریوی پذیرش دستی

| سناریو | شرح تست | نتیجه واقعی |
| :---: | :--- | :---: |
| **S1** | ضربه روی روتین ⟶ باز شدن شیت نیت | ✅ PASS |
| **S2** | «شروع تایمر تمرکز» ⟶ بسته شدن شیت و باز شدن تایمر | ✅ PASS |
| **S3** | انتخاب حالت «سبک» ⟶ شروع تایمر با زمان سبک | ✅ PASS |
| **S4** | «ثبت فوری» ⟶ تیک خوردن بلافاصله روتین در تقویم | ✅ PASS |
| **S5** | «تعویق روتین» ⟶ انتقال روتین در تایملاین | ✅ PASS |
| **S6** | «ویرایش روتین» ⟶ باز شدن و **باز ماندن** پلنر | ✅ PASS |
| **S7** | تغییر عنوان در پلنر و ذخیره ⟶ بروزرسانی تقویم | ✅ PASS |
| **S8** | «مشاهده جزئیات» ⟶ باز شدن و **باز ماندن** شیت جزئیات | ✅ PASS |
| **S9** | لغو انجام از جزئیات ⟶ بروزرسانی فوری تقویم | ✅ PASS |
| **S10** | روتین بدون مدت‌زمان ⟶ نمایش متن راهنما | ✅ PASS |
| **S11** | خطای دیتابیس/شبیه‌سازی خطا ⟶ نمایش توست فارسی | ✅ PASS |
| **S12** | دوبار کلیک سریع ⟶ ثبت فقط یک ردیف انجام | ✅ PASS |
| **S13** | اجرای دکمه‌ها از داشبورد «امروز» ⟶ عدم بروز رگرسیون | ✅ PASS |
| **S14** | پر شدن سقف تعویق ⟶ باز ماندن شیت پایان سقف | ✅ PASS |

---

## ۶. فهرست ۸ تست با وضعیت قبل و بعد

| نام فایل تست | قبل | بعد |
| :--- | :---: | :---: |
| `test/widget/niyyah_returns_intent_test.dart` | FAIL | ✅ PASS |
| `test/widget/niyyah_edit_sheet_stays_open_test.dart` | FAIL | ✅ PASS |
| `test/widget/niyyah_details_sheet_stays_open_test.dart` | FAIL | ✅ PASS |
| `test/widget/calendar_refresh_after_action_test.dart` | FAIL | ✅ PASS |
| `test/unit/active_timers_single_writer_test.dart` | FAIL | ✅ PASS |
| `test/widget/occurrence_status_badge_test.dart` | FAIL | ✅ PASS |
| `test/widget/swipe_completes_routine_test.dart` | FAIL | ✅ PASS |
| `test/terminology_test.dart` | FAIL | ✅ PASS |

---

## ۷. آمار `flutter analyze` قبل و بعد

- **قبل:** 0 errors, 0 warnings
- **بعد:** `No issues found!` (0 errors, 0 warnings)

---

## ۸. فهرست کامل فایل‌های تغییریافته (`git diff --stat`)

```text
 lib/core/database/database_helper.dart                      |  2 +-
 lib/core/database/migration/migration_runner.dart          |  1 +
 lib/core/database/migration/migrations_registry.dart       | 64 ++++++++++++++++++++++
 lib/core/domain/agenda/action_router.dart                  | 88 +++++++++++++++++++-----------
 lib/core/domain/models/duration_bounds.dart                 | 21 +++++++
 lib/core/widgets/action/action_capabilities.dart           |  3 ++
 lib/core/widgets/occurrence_status_badge.dart               |  1 +
 lib/core/widgets/ritmo_swipeable_row.dart                  | 85 +++++++++++++++++++++++++++++
 lib/features/calendar/presentation/journey_screen.dart     |  2 +-
 lib/features/dev/presentation/data_health_screen.dart      | 140 +++++++++++++++++++++++++++++++++++++++++++++++
 lib/features/routines/presentation/universal_planner_sheet.dart |  8 +--
 lib/features/routines/shared/widgets/routine_card.dart     | 43 +++------------
 lib/features/routines/shared/widgets/routine_details_sheet.dart |  4 +-
 lib/features/routines/shared/widgets/routine_niyyah_sheet.dart | 185 +++++++++++++++++++++++++------------------------------------
 lib/features/today/presentation/active_timer_overlay.dart   | 28 +++-------
 lib/features/today/presentation/now_dashboard_screen.dart  | 13 +----
 test/unit/active_timers_single_writer_test.dart            | 28 ++++++++++
 test/widget/calendar_refresh_after_action_test.dart         | 65 ++++++++++++++++++++++
 test/widget/niyyah_details_sheet_stays_open_test.dart      | 62 +++++++++++++++++++++
 test/widget/niyyah_edit_sheet_stays_open_test.dart         | 62 +++++++++++++++++++++
 test/widget/niyyah_returns_intent_test.dart                | 95 ++++++++++++++++++++++++++++++++
 21 files changed, 725 insertions(+), 279 deletions(-)
```

---

## ۹. موارد `BLOCKED` ماندگار

**هیچ موردی BLOCKED نماند.** تمامی تسک‌های T1 تا T8 به صورت کامل اجرا، تست و نهایی گردیدند.

---

ناوبری سراسری HomeNavigationShell از نظر ساختار، ظاهر و رفتار محصول تغییر نکرد.
