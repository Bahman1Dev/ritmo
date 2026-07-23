# 🤖 پرامپت اجرایی — «دسته‌بندیِ اعلان‌ها + WorkManager» — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ B1…B5 و W1…W4 را **یک‌سره تا آخر** اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: (۱) اعلان‌های غیرحیاتی به‌جای ۵–۸ زنگِ پشت‌سرهم، در یک گروهِ واحد جمع شوند (ضدِ اورلودِ ذهنی/ADHD)؛ (۲) یک کارِ دوره‌ایِ پایدار با WorkManager که حتی با اپِ بسته آلارم‌های آینده را بازچیند و snapshotِ روز را بگیرد.

## ⛔️ قواعد (یک‌بار)
- معماری: **Flutter مغز و منطق، Kotlin فقط لایه‌ی OS**. هیچ منطقِ دیتابیس در Kotlin نوشته نشود؛ Kotlin فقط تنظیماتِ آینه‌شده در SharedPreferences را می‌خواند.
- منطقِ موجود را بازنویسی نکن؛ فقط گسترش بده. توابعِ موجود: `AlarmSchedulerService.scheduleNextAlarms()` (که خودش `SnapshotSyncService.syncAll()` را هم صدا می‌زند).
- متن‌های فارسی/RTL، ارقامِ فارسی در نمایش.
- فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.
- خارج از scope: Health/Sensor (نساز).

## 📁 محیط (تأییدشده از کد)
- تنظیماتِ زیر **از قبل seed شده‌اند** در `app_settings` (در `database_helper.dart` حدود خط ۶۲۹): `digest_mode='false'`، `coalescing_window_minutes='10'`، `max_non_essential_per_hour='3'`. (مهاجرتِ جدید لازم **نیست**.)
- جدولِ `notification_history(id, routineId, notificationType, sentAt, actionTaken)` و `DatabaseHelper.instance.logNotificationEvent(...)` موجودند.
- اعلانِ آلارم در `BootReceiver.kt` → `showAlarmNotification(context, id, title, isEssential)` به‌صورت **تک‌تک** نمایش داده می‌شود (کانال‌های `RitmoEssentialChannel` / `RitmoNormalChannel`). آلارم‌ها مستقل زنگ می‌زنند.
- snapshot به SharedPreferences در `lib/core/utils/snapshot_helper.dart` نوشته می‌شود (`active_reminders_snapshot`, `widget_snapshot`)؛ این تابع از `SnapshotSyncService.syncAll()` صدا زده می‌شود. Kotlin این مقادیر را با پیشوندِ `flutter.` می‌خواند.
- `scheduleNextAlarms()` فقط از UI صدا زده می‌شود (calendar/onboarding/profile) — **هیچ زمان‌بندِ دوره‌ای ندارد**.
- `workmanager` در `pubspec.yaml` **نیست**.

---

# 🗂 بخشِ B — دسته‌بندی و دایجستِ اعلان‌ها (Notification Batching)

**استراتژیِ قطعی:** چون آلارم‌ها native و مستقل زنگ می‌زنند، coalescing را با **Android Notification Group + Summary** پیاده کن (نه با نگه‌داشتنِ زمانیِ دستی). حیاتی‌ها **هرگز** گروه/موکول نمی‌شوند.

**B1 — آینه‌کردنِ تنظیمات در SharedPreferences.** در `snapshot_helper.dart` (همان‌جا که snapshot نوشته می‌شود) و در مسیرِ `SnapshotSyncService.syncAll()`، این سه کلید را از `app_settings` بخوان و در prefs بنویس تا Kotlin بدونِ DB بخواند:
- `notif_digest_mode` (bool string)، `notif_coalescing_window_minutes` (int)، `notif_max_non_essential_per_hour` (int).
- اگر تابعِ مناسبی برای خواندنِ settings آنجا نیست، `Map<String,String> settings` را پارامتر بده یا از `DatabaseHelper` بخوان. روی web no-op.

**B2 — گروه‌بندیِ اعلانِ غیرحیاتی.** در `BootReceiver.kt` → `showAlarmNotification`:
- یک ثابت `GROUP_KEY_NON_ESSENTIAL = "ritmo_non_essential"` و `SUMMARY_NOTIF_ID = 8888` تعریف کن.
- مسیرِ **حیاتی** (`isEssential = true`): دقیقاً مثل حالا — مستقل، `PRIORITY_HIGH`، بدونِ group. دست‌نخورده.
- مسیرِ **غیرحیاتی**:
  - به `NotificationCompat.Builder` اضافه کن: `.setGroup(GROUP_KEY_NON_ESSENTIAL)`.
  - بعد از `notify(id.hashCode(), ...)`، یک **summary notification** بساز/به‌روزرسانی کن (`SUMMARY_NOTIF_ID`، همان کانالِ `RitmoNormalChannel`): `.setGroupSummary(true).setGroup(GROUP_KEY_NON_ESSENTIAL)`, با `setContentTitle("یادآوری‌های این بازه")` و یک شمارنده در متن (مثلاً «۳ کار این بازه»). شمارنده را با `getActiveNotifications()` (API 23+) بشمار یا از prefsِ B3 بگیر.
  - دکمه‌های اکشن (از پرامپتِ قبل، اگر موجود است) روی خودِ آیتم‌های گروه بمانند، نه روی summary.

**B3 — نرخ‌گیر (Rate limit) با پنجره‌ی لغزانِ prefs.** فقط برای غیرحیاتی:
- در `BootReceiver` یک کلیدِ prefs مثل `non_essential_fire_timestamps` نگه‌دار: یک JSON array از epochmillisِ آخرین زنگ‌های غیرحیاتی.
- هنگام زنگِ غیرحیاتی: ورودی‌های قدیمی‌ترِ از ۱ ساعت را حذف کن، سپس timestampِ جدید را اضافه کن.
- اگر تعداد (در ۱ ساعتِ اخیر) **بیشتر از** `notif_max_non_essential_per_hour` شد: اعلانِ فردی را **بی‌صدا/کم‌اهمیت** کن (`setPriority(PRIORITY_LOW)` و بدونِ صدا/لرزش) و فقط در گروه بماند؛ summary همچنان به‌روزرسانی شود. (موکول‌به‌دایجستِ بعدی = همین کاهشِ اهمیت.)

**B4 — حالتِ دایجست (`notif_digest_mode == "true"`).** فقط غیرحیاتی:
- اعلانِ فردی **محتوای کامل نشان ندهد** (یا اصلاً نمایش داده نشود)؛ فقط summary به‌روزرسانی شود با شمارنده و عنوانِ «خلاصه‌ی این بازه». حیاتی‌ها مستثنا و فوری.

**B5 — لاگ.** بعد از هر زنگ، رویداد در `notification_history` با `actionTaken='sent'` لاگ شود (اگر مسیرِ Dart این کار را نمی‌کند، در سمتِ Dartِ زمان‌بندی این از قبل انجام می‌شود؛ در Kotlin لاگ نزن). فقط مطمئن شو دوباره‌کاری/دوبار-لاگ رخ ندهد.

---

# 🗂 بخشِ W — WorkManager (زمان‌بندیِ پایدارِ پس‌زمینه)

**W1 — وابستگی.** به `pubspec.yaml` اضافه کن: `workmanager` (آخرین نسخه‌ی پایدار)؛ `flutter pub get`. اگر buildِ اندروید به‌خاطرِ AGP/نسخه خطا داد، نسخه را تا سازگاری پایین/بالا ببر و در گزارش ذکر کن.

**W2 — entrypointِ پس‌زمینه.** فایلِ جدید `lib/core/services/background_worker.dart`:
- ```dart
  @pragma('vm:entry-point')
  void ritmoCallbackDispatcher() {
    Workmanager().executeTask((taskName, inputData) async {
      try {
        await AlarmSchedulerService.scheduleNextAlarms(); // شاملِ syncAll
        return true;
      } catch (e) {
        return false;
      }
    });
  }
  ```
- نکته: `scheduleNextAlarms` به DB رمزنگاری‌شده نیاز دارد؛ چون کلید از `flutter_secure_storage` می‌آید، در isolateِ پس‌زمینه بدونِ سیم‌کشیِ اضافه کار می‌کند.

**W3 — مقداردهیِ اولیه و ثبتِ کارِ دوره‌ای.** در `lib/main.dart` (فقط `if (!kIsWeb)`، بعد از init):
- `Workmanager().initialize(ritmoCallbackDispatcher, isInDebugMode: false);`
- یک کارِ دوره‌ای ثبت کن:
  ```dart
  Workmanager().registerPeriodicTask(
    'ritmo_periodic_reschedule',
    'ritmoRescheduleTask',
    frequency: const Duration(hours: 6),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.notRequired),
    backoffPolicy: BackoffPolicy.linear,
  );
  ```
  (WorkManager خودش پس از ریبوت کار را بازمی‌گرداند؛ نیازی به BootReceiverِ اضافه نیست.)

**W4 — هم‌زیستی با AlarmManager.** WorkManager اینجا فقط «بیمه‌ی پایداری/بازچینش» است، نه جایگزینِ آلارم‌های دقیق. مطمئن شو `scheduleNextAlarms` ایدمپوتنت است (هست: idۀ یکتا + `ConflictAlgorithm.ignore`) تا اجرای دوره‌ای آلارمِ تکراری نسازد. چیزی در منطقِ آلارمِ دقیق تغییر نده.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز.
- `flutter build apk --debug` → موفق.
- در گزارشِ نهایی بنویس: (الف) چند آلارمِ غیرحیاتی نزدیک‌به‌هم → باید زیرِ یک summary جمع شوند و حیاتی جدا بماند؛ (ب) با `digest_mode=true` رفتار چطور می‌شود؛ (پ) کارِ WorkManager با چه دوره‌ای ثبت شد و چه می‌کند.
