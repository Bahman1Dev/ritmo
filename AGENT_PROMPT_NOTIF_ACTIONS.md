# 🤖 پرامپت اجرایی — «پلِ اکشنِ نوتیفیکیشن» (Notification Action Bridge) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. لایه‌ی native آلارم/بوت **از قبل ساخته و سالم است**؛ این مرحله فقط **دکمه‌های اکشن روی نوتیف + پلِ اجرای کد Dart در پس‌زمینه** را اضافه می‌کند. کلِ صفِ N1 تا N8 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: وقتی آلارم زنگ می‌زند (حتی با اپِ بسته)، کاربر روی خودِ نوتیف بتواند **انجام شد / تعویق / رد کردن** را بزند و در دیتابیسِ رمزنگاری‌شده ثبت شود — بدون باز شدنِ UI.

## ⛔️ قواعد (یک‌بار)
- معماری: **Flutter مغز و منطق، Kotlin فقط لایه‌ی OS**. هیچ منطقِ تصمیم/دیتابیس در Kotlin نوشته نشود.
- ثبت در DB حتماً از طریقِ توابعِ **موجودِ** `AlarmSchedulerService` انجام شود (`completeOccurrence`, `snoozeReminder`, `skipOccurrence`). این توابع را **بازنویسی نکن**؛ فقط صدا بزن.
- متن‌های فارسی/RTL. l10n جدید (اگر لازم شد) به `app_fa.arb`/`app_en.arb`.
- فقط فایل‌های مرتبطِ این تسک. ابهامِ واقعی → بپرس.
- اجازه داری کدِ native فعلی این مقوله را **اصلاح** کنی (مالک تأیید کرد). معماریِ آلارم/بوتِ موجود را نشکن، فقط گسترش بده.

## 📁 محیط (تأییدشده از کد)
- **کلیدِ DB از `flutter_secure_storage` خوانده می‌شود** (نه از Keystore channel). یعنی هر isolate پس‌زمینه‌ای با `DatabaseHelper.instance.database` می‌تواند DB رمزنگاری‌شده را باز کند — **هیچ سیم‌کشیِ کلید لازم نیست**.
- آلارم native در `MainActivity.kt` (channel `com.ritmo.app/alarms`) با `setExactAndAllowWhileIdle` ثبت می‌شود و در `BootReceiver.kt` (اکشن `com.ritmo.app.ACTION_TRIGGER_ALARM`) زنگ می‌خورد و نوتیف نشان می‌دهد.
- نوتیفِ فعلی فقط `id` (همان `reminderId`)، `title`، `isEssential` را حمل می‌کند و **دکمه‌ی اکشن ندارد** — فقط با کلیک اپ باز می‌شود.
- توابعِ موجودِ Dart (در `lib/core/services/alarm_scheduler_service.dart`):
  - `completeOccurrence(String routineId, String dateStr, {String resultType='FULL'})`
  - `skipOccurrence(String routineId, String dateStr)`
  - `snoozeReminder(String reminderId, int snoozeMinutes)`
- جدول `pending_reminders` ستون‌های `id, routineId, originalTime, scheduledTime, state, ...` را دارد → از روی `reminderId` می‌توان `routineId` و `originalTime` (و از آن `dateStr`) را درآورد. **پس payload پل فقط به `{action, reminderId}` نیاز دارد.**
- تنظیماتِ `snooze_minutes` در جدول `app_settings` (اگر نبود پیش‌فرض `10`).
- یادآورهای خصوصیِ چرخه `routineId = 'cycle_private_reminder'` دارند که روتینِ واقعی **نیست** → برای آن‌ها فقط dismiss (بدون `completeOccurrence`).

## 🔒 تصمیم‌های قطعی
1. **مسیر:** نگه‌داشتنِ AlarmManager + BootReceiver native؛ افزودنِ دکمه‌های اکشن + یک `NotificationActionReceiver` که یک **Background FlutterEngine** را با الگوی **callback-handle** بالا می‌آورد و اکشن را به Dart پاس می‌دهد.
2. **پل دوطرفه:** native → entrypointِ Dart (`@pragma('vm:entry-point')`) → Dart از طریق توابعِ موجود در DB می‌نویسد.
3. سه اکشن: `DONE` («انجام شد ✅»)، `SNOOZE` («تعویق ⏰»)، `DISMISS` («رد کردن»).

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**N1 — entrypoint و هندلرِ Dart.** فایلِ جدید `lib/core/services/notification_action_dispatcher.dart`:
- یک تابعِ top-level با `@pragma('vm:entry-point') void notificationActionDispatcher()`:
  - `WidgetsFlutterBinding.ensureInitialized();`
  - `MethodChannel('com.ritmo.app/notif_action_bg')` بساز.
  - `setMethodCallHandler`: روی `'handleAction'` → `action` و `reminderId` را از `call.arguments` بخوان، `await NotificationActionHandler.handle(action, reminderId)` را صدا بزن، سپس `return true`.
  - بعد از ثبتِ هندلر، `channel.invokeMethod('dispatcherReady')` را صدا بزن تا native بفهمد آماده است.
- کلاس/کلاسِ کمکیِ `NotificationActionHandler` با متدِ static `handle(String action, String reminderId)`:
  - `final db = await DatabaseHelper.instance.database;`
  - رکوردِ `pending_reminders` با `id = reminderId` را بخوان. اگر نبود → فقط return.
  - `routineId = row['routineId']`؛ `dateStr` را از `originalTime` بساز (`DateTime.fromMillisecondsSinceEpoch(originalTime).toIso8601String().substring(0,10)`).
  - switch روی `action`:
    - `'DONE'` → اگر `routineId` در جدولِ `routines` وجود دارد: `await AlarmSchedulerService.completeOccurrence(routineId, dateStr)`؛ وگرنه فقط `state='opened'` کن.
    - `'SNOOZE'` → `snoozeMinutes` را از `app_settings` بخوان (پیش‌فرض ۱۰)، `await AlarmSchedulerService.snoozeReminder(reminderId, snoozeMinutes)`.
    - `'DISMISS'` → اگر روتینِ واقعی بود `await AlarmSchedulerService.skipOccurrence(routineId, dateStr)`؛ وگرنه فقط `state='opened'` کن.
  - همه را در try/catch بگذار (هرگز crash نده؛ خطا را log کن).

**N2 — ثبتِ callback handle در main.dart.** در `lib/main.dart` بعد از `WidgetsFlutterBinding.ensureInitialized()` و راه‌اندازیِ اولیه:
- import: `package:flutter/services.dart` (برای `PluginUtilities`) و `package:shared_preferences/shared_preferences.dart`.
- ```dart
  final handle = PluginUtilities.getCallbackHandle(notificationActionDispatcher)!.toRawHandle();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('notification_action_callback_handle', handle);
```
  (Kotlin این را با کلیدِ `flutter.notification_action_callback_handle` می‌خواند.) فقط روی غیرِ web اجرا شود (`if (!kIsWeb)`).

**N3 — دکمه‌های اکشن روی نوتیفِ آلارم.** در `BootReceiver.kt`، تابعِ `showAlarmNotification`:
- سه `addAction`ِ پس‌زمینه‌ای (background isolate): «انجام شد ✅»، «تعویق ⏰»، «رد کردن».
  - هر کدام `PendingIntent.getBroadcast` به `NotificationActionReceiver`، `action="com.ritmo.app.NOTIF_ACTION"`, extras: `actionType` (`DONE`/`SNOOZE`/`DISMISS`)، `reminderId=id`، `notifId=id.hashCode()`، `requestCode=(id+actionType).hashCode()`, فلگ `FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE`.
- یک `addAction`ِ چهارمِ **«الان انجام می‌دهم ⏱️»** که با بقیه فرق دارد: به‌جای ثبت در DB، **اپ را باز کرده و تایمرِ همان روتین را شروع می‌کند**:
  - `PendingIntent.getActivity` به `MainActivity` (نه broadcast)، با `action="com.ritmo.app.START_TIMER"`, extras: `reminderId=id`، فلگ `FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE`، و `Intent.FLAG_ACTIVITY_SINGLE_TOP`.
  - نوتیف را هم ببندد (`setAutoCancel(true)` کافی است؛ یا در سمتِ Flutterِ N9 بسته شود).
- نکته: برای روتینِ `isEssential` هم همهٔ دکمه‌ها باشند.

**N4 — NotificationActionReceiver (الگوی callback-handle).** فایلِ جدید `android/app/src/main/kotlin/com/example/ritmo/NotificationActionReceiver.kt` — یک `BroadcastReceiver`:
- در `onReceive`:
  - `actionType`, `reminderId`, `notifId` را از intent بخوان.
  - **نوتیف را فوراً ببند:** `NotificationManagerCompat.from(context).cancel(notifId)`.
  - `val pending = goAsync()` بگیر تا گیرنده تا پایانِ کارِ async زنده بماند.
  - handle را از `SharedPreferences("FlutterSharedPreferences")` با کلیدِ `flutter.notification_action_callback_handle` (Long) بخوان. اگر نبود → `pending.finish()` و return.
  - الگوی استانداردِ راه‌اندازیِ Background FlutterEngine (مثل android_alarm_manager_plus/workmanager):
    - روی main thread (`Handler(Looper.getMainLooper()).post { ... }`):
      - `FlutterInjector.instance().flutterLoader()` را `startInitialization(appContext)` + `ensureInitializationComplete(appContext, null)` کن.
      - یک `FlutterEngine(context)` بساز (در یک companion cache نگه‌دار تا برای اکشن‌های پشت‌سرهم دوباره ساخته نشود).
      - `val cb = FlutterCallbackInformation.lookupCallbackInformation(handle)`.
      - `engine.dartExecutor.executeDartCallback(DartCallback(assets, bundlePath, cb))`.
      - یک `MethodChannel(engine.dartExecutor.binaryMessenger, "com.ritmo.app/notif_action_bg")` بساز و handler ست کن:
        - وقتی Dart `'dispatcherReady'` فرستاد → `channel.invokeMethod("handleAction", mapOf("action" to actionType, "reminderId" to reminderId))`.
      - بعد از مهلتِ امن (مثلاً تأخیرِ ۸ ثانیه‌ای یا وقتی `handleAction` نتیجه برگرداند) `pending.finish()` را صدا بزن. (اگر سادگی را ترجیح می‌دهی: `handleAction` را با `Result` صدا بزن و در `success` همان‌جا `pending.finish()` کن.)
- importهای لازم: `io.flutter.embedding.engine.FlutterEngine`, `io.flutter.embedding.engine.dart.DartExecutor.DartCallback`, `io.flutter.view.FlutterCallbackInformation`, `io.flutter.FlutterInjector`, `io.flutter.plugin.common.MethodChannel`, `androidx.core.app.NotificationManagerCompat`.

**N5 — ثبت در AndroidManifest.** در `android/app/src/main/AndroidManifest.xml`:
- ```xml
  <receiver android:name=".NotificationActionReceiver" android:exported="false"/>
```
- (هم‌راستا با سندِ معماری) به intent-filterِ `BootReceiver` این اکشن‌ها را هم اضافه کن تا با تغییرِ ساعت/منطقه‌ی زمانی آلارم‌ها بازچیده شوند:
```xml
  <action android:name="android.intent.action.TIMEZONE_CHANGED"/>
  <action android:name="android.intent.action.TIME_SET"/>
```
  و در `BootReceiver.onReceive` این دو را هم مثل `BOOT_COMPLETED` به `restoreAlarmsFromSnapshot` وصل کن.

**N6 — رفعِ همسانیِ کانال‌ها.** مطمئن شو کانال‌هایی که `NotificationActionReceiver`/`BootReceiver` استفاده می‌کنند (`RitmoEssentialChannel`/`RitmoNormalChannel`) قبل از `notify` ساخته شده‌اند (همان منطقِ فعلیِ `showAlarmNotification` کافی است؛ فقط دست‌نخورده بماند).

**N7 — جلوگیری از نشتیِ engine.** در `NotificationActionReceiver` engine را در یک `companion object` به‌صورت nullable cache کن و فقط یک‌بار بساز؛ اگر موجود بود دوباره از همان استفاده کن (نه destroy بعد از هر اکشن — فقط reuse).

**N9 — فلوی «الان انجام می‌دهم → تایمر» (سمتِ Flutter).** اکشنِ `START_TIMER` اپ را باز می‌کند؛ Flutter باید intent را بخواند و تایمرِ روتین را شروع کند:
- در `MainActivity.kt`: چون `launchMode=singleTop`، علاوه بر `onCreate`، در `onNewIntent` هم intent را نگه‌دار و از طریقِ یک MethodChannel (مثلاً `com.ritmo.app/launch_intent`) `{action:'START_TIMER', reminderId}` را به Flutter بده (یا با یک getter که Flutter در startup صدا می‌زند).
- در سمتِ Flutter (مثلاً در `home_navigation_shell` یا `main` پس از آماده‌شدنِ UI): اگر `action=='START_TIMER'`:
  1. از `pending_reminders` با `id=reminderId` → `routineId` را بگیر.
  2. روتین را بخوان؛ `durationMinutes = targetDurationMinutes ?? 25` (پیش‌فرضِ منطقی اگر null).
  3. **تایمر را با همان مسیرِ موجود شروع کن** که `routines_list_screen`/`now_dashboard_screen` استفاده می‌کنند (درجِ `active_timers` + `NativeBridge.startTimerMode(title, durationSeconds, elapsedSeconds:0)` + نمایشِ `active_timer_overlay`). منطقِ تایمر را بازنویسی نکن؛ همان تابع/سرویسِ موجود را صدا بزن.
  4. نوتیفِ مربوط را ببند.
- اگر روتین/تایمر در دسترس نبود → graceful (فقط اپ روی صفحهٔ روتین باز شود)، نه crash.

**N8 — اعتبارسنجیِ نهایی (یک‌بار).**
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز.
- `flutter build apk --debug` → موفق (تأییدِ کامپایلِ Kotlin/manifest).
- در گزارشِ نهایی دو سناریوی تستِ دستی بنویس: (۱) «آلارمی برای ۱ دقیقه‌ی بعد، اپ را ببند، "انجام شد" را بزن → occurrence مربوطه `done` و نوتیف بسته.» (۲) «روی همان نوتیف "الان انجام می‌دهم" را بزن → اپ باز شده و تایمرِ آن روتین با مدتِ `targetDurationMinutes` شروع می‌شود.»

---

## ✅ خروجیِ موردِ انتظار
- زدنِ دکمه‌های نوتیف با **اپِ بسته** → ثبتِ درست در DB رمزنگاری‌شده از طریقِ توابعِ موجود.
- `DONE` → completion + لغوِ آلارم؛ `SNOOZE` → آلارمِ جدید طبقِ `snooze_minutes`؛ `DISMISS` → skip/opened؛ **`START_TIMER` → باز شدنِ اپ و شروعِ تایمرِ روتین**.
- هیچ crash، هیچ منطقِ دیتابیس در Kotlin، هیچ نشتیِ engine.
