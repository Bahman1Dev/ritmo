# گزارش نهایی اجرای پرامپت اجرایی فوری — رفع ریشه‌ای شکست ذخیره در آنبوردینگ و ناهمخوانی قرارداد کانال‌های بومی

تاریخ تکمیل: ۲۹ ژوئیه ۲۰۲۶  
نویسنده: مهندس ارشد نرم‌افزار (Antigravity AI)

---

## ۱. جدول کامل A-0 پیش و پس از اصلاح (تطابق کامل ۱۰۰٪)

| نام کانال | نام متد | جهت | وضعیت پیش از اصلاح | وضعیت پس از اصلاح |
| :--- | :--- | :---: | :---: | :---: |
| `com.ritmo.app/alarms` | `scheduleExactAlarm` | `Dart → Kotlin` | ❌ ناهمخوان (`scheduleExactAlarm` vs `scheduleAlarm`) | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/alarms` | `cancelAlarm` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/alarms` | `checkExactAlarmPermission` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/alarms` | `requestExactAlarmPermission` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/keystore` | `getOrCreateKey` | `Dart → Kotlin` | ❌ ناهمخوان (`getOrCreateKey` vs `getDeviceMasterKey`) | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/foreground_service` | `startStatusMode` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/foreground_service` | `startTimerMode` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/foreground_service` | `stopService` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/widget` | `refreshWidgets` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/launch_intent` | `getLaunchIntent` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/myket_billing` | `init` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/myket_billing` | `getProductDetails` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/myket_billing` | `purchase` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/myket_billing` | `restorePurchases` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/myket_billing` | `dispose` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/notif_action_bg` | `dispatcherReady` | `Dart → Kotlin` | ✅ منطبق | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/notif_action_bg` | `completeRoutineDirect` | `Kotlin → Dart` | ✅ منطبق (معکوس) | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/notif_action_bg` | `updatePersistentStatus` | `Kotlin → Dart` | ✅ منطبق (معکوس) | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/notif_action_bg` | `changeZoneDirect` | `Kotlin → Dart` | ✅ منطبق (معکوس) | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/notif_action_bg` | `changeEnergyDirect` | `Kotlin → Dart` | ✅ منطبق (معکوس) | ✅ **منطبق ۱۰۰٪** |
| `com.ritmo.app/notif_action_bg` | `handleAction` | `Kotlin → Dart` | ✅ منطبق (معکوس) | ✅ **منطبق ۱۰۰٪** |

---

## ۲. گزارش تفکیکی واحدهای کاری (WU)

- **WU A-5 & A-6 (منبع واحد حقیقت):**
  - فایل `lib/core/platform/native_channel_contract.dart` در دارت و `android/app/src/main/kotlin/ir/ritmo/app/NativeChannelContract.kt` در کتولین ایجاد شدند و تمام رشته‌های جادویی کانال‌ها و متدها با این ثابت‌های ایزوله جایگزین گردیدند.

- **WU A-7 & A-8 (تست‌های نگهبان و خودکار Parity):**
  - تست [channel_contract_parity_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/platform/channel_contract_parity_test.dart) ایجاد شد تا مطمئن شویم هر دو فایل قرارداد ۱۰۰٪ همگام هستند.
  - تست [no_magic_channel_string_test.dart](file:///mnt/c/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/platform/no_magic_channel_string_test.dart) ایجاد گردید تا از ورود هرگونه رشته جادویی خامی بیرون از فایل‌های قرارداد در کدبیس جلوگیری کند.

- **WU A-9 & A-10 (مقاوم‌سازی NativeBridge):**
  - در تمام شاخه‌های `notImplemented` سمت کتولین، هشدار صریح `Log.w` اضافه شد.
  - کدهای `NativeBridge` به صورت اختصاصی `MissingPluginException` و `PlatformException` را هدایت می‌کنند و لاگ رسمی همراه با کانتکست ثبت می‌نمایند.

- **WU A-13 تا A-16 (بازطراحی مسیر ذخیرهٔ آنبوردینگ):**
  - متد `OnboardingController.save()` بازطراحی شد.
  - گام‌های بحرانی دیتابیس (`app_settings` و `OnboardingGate.markCompleted`) انجام گرفته و بلافاصله `OnboardingDraftStore.clear()` و `onFinished()` صدا زده می‌شوند تا کاربر در صفحه آنبوردینگ حبس نشود.
  - فراخوانی‌های جانبی (ویجت، آلارم‌ها و رویدادها) به `_postSaveBestEffort()` منتقل شدند تا شکست احتمالی آن‌ها لایه ناوبری کاربر را متوقف نکند.
  - شناسه روتین‌های آنبوردینگ قطعی (`'onboarding_routine_${t.id}'`) شد تا اجرای مجدد آنبوردینگ کاملاً Idempotent شده و روتین تکراری نسازد.

---

## ۳. پاسخ صریح به سوال کلیدی نگهبان (Guard Question)

> **«اگر کسی فردا نام یک متد کانال را در یک سمت تغییر دهد، چه اتفاقی می‌افتد؟»**  
> **پاسخ:** تست `channel_contract_parity_test.dart` در CI بلافاصله قرمز شده و با پیام صریح زیر بیلد را متوقف می‌سازد:  
> `Channel contract mismatch! Constant X with value Y exists in Dart (native_channel_contract.dart) but NOT in Kotlin (NativeChannelContract.kt).`

---

## ۴. نتیجه‌گیری نهایی
مسیر آنبوردینگ کاربر کاملاً ایمن، غیرمسدودکننده و Idempotent شد و قرارداد کانال‌های بومی اندروید ۱۰۰٪ همگام‌سازی و قفل گردید. ✅
