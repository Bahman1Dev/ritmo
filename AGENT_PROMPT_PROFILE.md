# 🤖 پرامپت اجرایی — تکمیلِ «پروفایل و تنظیمات کاربری» (Profile) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. کلِ صفِ P1 تا P10 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: صفحه‌ی پروفایل پوسته‌ای کامل ولی پر از استاب است. این استاب‌ها را **واقعی** کن و کدِ مرده را پاک کن — بدونِ شکستنِ چیزهای واقعیِ موجود.
> سندِ طراحی: `DESIGN_SYSTEM_PROFILE.md`. فایلِ اصلی: `lib/features/profile/presentation/profile_screen.dart`.

## ⛔️ قواعد (یک‌بار)
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (`shamsi_date`). l10n جدید به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ `RitmoTheme`/`context.colors`. رنگِ پایه: آبی `#5B8AF5`.
- داده‌ی دیتابیس تستی است؛ ستون/کلیدِ جدید با `DEFAULT`/`INSERT OR IGNORE`.
- فقط فایل‌های مرتبطِ هر تسک. ابهامِ واقعی → بپرس.
- **صداقت:** هیچ دکمه‌ای ادعای کاری که انجام نمی‌دهد نکند. اگر قابلیتی هنوز نیست، صادقانه بگو.
- **این‌ها را نشکن:** `BackupService` (موجود و واقعی)، `CycleLockGate` و منطقِ `app_lock_password`/`cycle_biometric_enabled`، `CyclePrivacyGuard` (چرخه فقط برای زن)، `RealmManagementSheet`، `themeRepository`/`localeRepository`، محاسبه‌ی «نبضِ زندگی»، و دیالوگِ هشدارِ پزشکیِ خاموش‌کردنِ ماژولِ دارو.
- **رمزِ موجود plaintext است** (`cycle_lock_gate` plaintext مقایسه می‌کند) — سازگار بمان؛ هش نکن.

## 🔒 تصمیم‌های قطعی
1. **پریمیومِ واقعیِ درون‌برنامه:** پرچمِ `is_premium` + سرویسِ قفل/بازکردنِ ویژگی + فعال‌سازی با کدِ لایسنس/پرومو (اعتبارسنجیِ محلی). درگاهِ پرداخت فعلاً نه.
2. **پنلِ واقعیِ «این دستگاه»:** ثبتِ دستگاهِ فعلی در جدولِ `devices` با شناسه‌ی پایدار و مدل/پلتفرمِ واقعی؛ شفافیتِ نبودِ همگام‌سازیِ ابری.
3. **قفلِ کلِ برنامه:** `AppLockGate` در ریشه + واقعی‌کردنِ سِت‌شیت‌های PIN/بیومتریک. قفلِ چرخه نشکند.
4. **پکیج‌های جدید:** `file_picker`, `share_plus`, `device_info_plus`, `package_info_plus`.

## 📁 محیط (تأییدشده از کد)
- DB SQLite؛ **نسخه‌ی فعلی را از کد بخوان** و مهاجرت = نسخه‌ی فعلی + ۱ (احتمالاً ۲۲؛ چون سلامت ۲۱ را گرفت). الگوی `_migrateToVNN` + `if (oldVersion < NN)` + هم‌تراز در `_createDB`. `_safeAddColumn` موجود است.
- هویتِ کاربر در `app_settings`: `user_name`/`user_gender`/`user_age`/`user_avatar_path`. ماژول‌ها: `module_religion_enabled`, `module_medicine_enabled`, `module_cycle_enabled`, `module_konkur_enabled`, `module_courses_enabled`, `module_goals_enabled`, `module_progressive_habits_enabled`, `module_assistant_enabled`, `module_energy_enabled`, `module_sleep_enabled`.
- بک‌آپِ واقعی: `BackupService.exportBackup(passcode)` و `restoreBackup(json, passcode)` در `lib/core/services/backup_service.dart`. (web پشتیبانی نمی‌شود — هندل کن.)
- قفلِ موجود: `lib/features/cycle/presentation/widgets/cycle_lock_gate.dart` با `app_lock_password` (PIN ۴ رقمی plaintext) و `cycle_biometric_enabled` و `local_auth`. الگوی PIN-keypad را از همین‌جا الگو بگیر.
- `CyclePrivacyGuard.isVisible({'user_gender': ...})` برای زنانه‌بودن.
- پکیج‌های موجود: `local_auth`, `encrypt`/`crypto`/`pointycastle`, `image_picker`, `url_launcher`, `path_provider`, `path`, `shared_preferences`, `flutter_secure_storage`.
- ورودِ صفحه: `systems_hub_screen.dart` و `now_dashboard_screen.dart` آن را به‌صورتِ `DraggableScrollableSheet` باز می‌کنند. ریشه‌ی برنامه برای `AppLockGate` را از `main.dart`/اپِ ریشه پیدا کن.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**P1 — پکیج‌ها + مهاجرت.** به `pubspec.yaml` اضافه و `pub get`: `file_picker`, `share_plus`, `device_info_plus`, `package_info_plus`. مهاجرت نسخه‌ی فعلی→+۱: جدولِ `devices (id TEXT PK, deviceName TEXT, platform TEXT, model TEXT, firstSeenAt INTEGER, lastActiveAt INTEGER, isCurrent INTEGER DEFAULT 1)` (هم در `_migrateToVNN` و هم `_createDB`). seed با `INSERT OR IGNORE`: `is_premium='false'`, `premium_plan=''`, `premium_activated_at=''`, `premium_license=''`, `app_lock_enabled='false'`, `app_biometric_enabled='false'`, `notif_master_enabled='true'`, `notif_quiet_enabled='false'`, `notif_quiet_start='00:00'`, `notif_quiet_end='07:00'`.

**P2 — PremiumService** (`lib/core/services/premium_service.dart`): `isPremium()`, `activateWithCode(String code)` (اعتبارسنجیِ محلی؛ ست‌کردنِ `is_premium`/`premium_plan`/`premium_activated_at`/`premium_license`), `deactivate()`, `enum PremiumFeature {...}`, `isFeatureUnlocked(PremiumFeature)`. فهرستِ ویژگی واقعی و قابلِ‌قفل تعریف کن. تست: فعال‌سازی با کدِ معتبر/نامعتبر، گیتِ ویژگی.

**P3 — صفحه‌ی پریمیومِ واقعی** (`_showPremiumUpgradeSheet` در profile + در صورت نیاز `widgets/premium_sheet.dart`): وضعیتِ واقعیِ `is_premium` (نشانِ طلایی اگر فعال)، فهرستِ پلن‌ها، ورودیِ کدِ لایسنس/پرومو → `PremiumService.activateWithCode` با بازخوردِ واقعی (موفق/ناموفق). دکمه‌ی جعلیِ اسنک‌بار حذف. اگر درگاهِ پرداخت نیست، صادقانه «به‌زودی». 

**P4 — DeviceService + پنلِ دستگاه** (`lib/core/services/device_service.dart` + `_showDevicesSheet`): در استارتِ برنامه `registerCurrentDevice()` (شناسه‌ی پایدار از `device_info_plus` ذخیره‌شده در `flutter_secure_storage`/settings؛ `firstSeenAt` یک‌بار، `lastActiveAt` هر بار، مدل/پلتفرمِ واقعی). پنل: فهرستِ واقعیِ `devices` + کارتِ «این دستگاه» + یادداشتِ صادقانه‌ی نبودِ همگام‌سازیِ ابری. ردیفِ پروفایل تعدادِ واقعی را نشان دهد (نه «۱ دستگاه» هاردکد).

**P5 — AppLockGate + امنیتِ واقعی** (`lib/core/security/app_lock_gate.dart` + سِت‌شیت‌های profile): `AppLockGate` آینه‌ی `CycleLockGate` برای کلِ برنامه، فعال فقط وقتی `app_lock_enabled='true'`؛ قفل در `paused/inactive`؛ بیومتریک اگر `app_biometric_enabled='true'`. در ریشه‌ی برنامه بپیچان. `_showPasswordLockSheet` واقعی: تنظیم/تغییر/حذفِ PIN ۴ رقمی (نوشتن `app_lock_password` + `app_lock_enabled`). `_showFingerprintSheet` واقعی: بررسیِ `local_auth.canCheckBiometrics` و توگلِ `app_biometric_enabled`. **`CycleLockGate` و `cycle_biometric_enabled` نشکنند.**

**P6 — بک‌آپ/بازیابیِ واقعی** (`_showBackupSheet`): «ایجادِ پشتیبان» → گرفتنِ عبارتِ‌عبور → `BackupService.exportBackup(passcode)` → ذخیره/اشتراک با `share_plus`/`file_picker`. «بازیابی» → انتخابِ فایل با `file_picker` → عبارتِ‌عبور → `BackupService.restoreBackup` با دیالوگِ هشدارِ جایگزینیِ داده. web: پیامِ صادقِ عدمِ پشتیبانی. اسنک‌بارهای جعلی حذف.

**P7 — تکمیلِ ماژول‌ها + پاکسازیِ کدِ مرده** (`_showModulesManagementSheet`): همه‌ی ماژول‌ها (عبادت، دارو، چرخه[فقط زن]، کنکور، دوره‌ها، اهداف، عاداتِ پیش‌رونده، دستیار، انرژی، خواب) با برچسب/آیکنِ درست و توگلِ persist + لغو/زمان‌بندیِ آلارم (دیالوگِ هشدارِ دارو حفظ شود). کدِ مرده پاک شود: `_buildHeader`/`_buildQuickStatus`/`_buildStatusCard`/`_showEnergySelectionSheet`/`_showEnergyLogSheet`/`_showCountGoalsSheet`/`_showContextSelectionSheet` و فیلدهای هاردکدِ `_currentEnergy`/`_currentContext` اگر بلااستفاده‌اند حذف، یا اگر در UI می‌مانند به داده‌ی واقعی وصل شوند. ردیفِ «ثبتِ سطحِ انرژی» اگر بی‌کارکرد است حذف.

**P8 — تنظیماتِ اعلانِ واقعی** (`_showNotificationsSheet`): توگلِ اصلیِ `notif_master_enabled` + توگل + ساعتِ سکوت (`notif_quiet_enabled`/`notif_quiet_start`/`notif_quiet_end`). با زمان‌بندیِ آلارمِ موجود سازگار شود (هنگام خاموش‌بودنِ master یا داخلِ بازه‌ی سکوت، اعلان زمان‌بندی نشود) — `alarm_scheduler_service`/`notification_decider` را نشکن، فقط شرطِ احترام به این کلیدها را اضافه کن.

**P9 — درباره/بازخورد/راهنمای واقعی:** «درباره ریتمو» نسخه‌ی واقعی از `package_info_plus`. «بازخورد» ذخیره‌ی محلی یا `mailto:` با `url_launcher` (اسنک‌بارِ جعلی حذف). «راهنما» محتوای واقعیِ کوتاه.

**P10 — پایان.** مطمئن شو قفلِ چرخه، بک‌آپِ موجود، زمان‌بندیِ آلارم، و زنانه‌بودنِ چرخه سالم‌اند؛ هیچ دکمه‌ی جعلی نمانده؛ کدِ مرده پاک شده. اگر چیزی تغییر کرد `DESIGN_SYSTEM_PROFILE.md` را به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: `PremiumService` (فعال‌سازی/گیت)، مهاجرتِ نصبِ‌تازه≡ارتقا (`devices` + کلیدها در هر دو مسیر)، ثبتِ دستگاه، روشن/خاموشِ قفلِ کلِ برنامه.
- دستی: ارتقا به پریمیوم با کد → دیدنِ نشانِ طلایی → پنلِ واقعیِ این دستگاه → تنظیم/حذفِ PIN و قفل‌شدنِ برنامه در بازگشت از پس‌زمینه → بک‌آپ‌گرفتن و بازیابی → دیدنِ همه‌ی ماژول‌ها و توگل → ساعتِ سکوتِ اعلان → نسخه‌ی واقعی در «درباره» → سالم‌بودنِ قفلِ چرخه.

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی P1..P10: ...
- نسخه‌ی مهاجرت: ...
- پکیج‌های اضافه‌شده: file_picker, share_plus, device_info_plus, package_info_plus
- flutter analyze / flutter test: ...
- بازبینیِ سلامتِ قفلِ چرخه/بک‌آپ/آلارم + حذفِ کدِ مرده و دکمه‌های جعلی: ...
- ابهامات: ...
```
