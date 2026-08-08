# راهنمای تغییرات و اقدامات انجام شده در پرامپت ۰۵۸ (Walkthrough)

## بازطراحی کامل بخش پروفایل و تنظیمات (Single Source of Truth, One Real Screen, Zero Fake Buttons)

---

### ۱. معماری تک‌مرجع حقیقت (Single Source of Truth)
- ایجاد **`SettingsRegistry`** (`lib/core/settings/settings_registry.dart`) شامل **۶۳ توصیف‌گر تنظیمات** با دسته‌بندی در ۷ گروه اصلی (`identity`, `modules`, `notifications`, `appearance`, `assistant`, `dataBackup`, `security`).
- ایجاد **`SettingsService`** (`lib/core/settings/settings_service.dart`) سینگلتون همراه با کش در حافظه (Memory Cache)، اعتبارسنجی مقادیر (حداقل، حداکثر، مقادیر مجاز)، پشتیبانی از ذخیره‌سازی در دیتابیس، SharedPreferences و SecureKeyStore، ثبت رویدادها در `RitmoEvents` و همگام‌سازی لحظه‌ای تنظیمات اعلان در اسنپ‌شات‌ها.

---

### ۲. ارتقای ساختار دیتابیس و مایگریشن v78
- افزایش شماره نسخه دیتابیس `_dbVersion` به **78** در `DatabaseHelper`.
- ثبت مایگریشن **`MigrationV78SettingsProfile`** برای:
  - مقداردهی اولیه تنظیمات جدید (`app_lock_timeout_seconds`, `notif_quiet_start`, `notif_quiet_end`, `digest_mode`, `coalescing_window_minutes`, و ...).
  - تفکیک کامل رمز عبور بخش چرخه (`cycle_lock_password`) از رمز ورود برنامه (`app_lock_password`).
  - حذف کلیدهای منسوخ مانند `module_konkur_enabled` و جایگزینی با `module_study_enabled`.
  - حذف ایمن جدول `worship_seasons`.

---

### ۳. صفحه تمام‌صفحه و اختصاصی تنظیمات (SettingsScreen)
- پیاده‌سازی صفحه تمام‌صفحه `SettingsScreen` بر پایه `RitmoPageScaffold` و `RitmoModuleAppBar` همراه با:
  - هدر هویتی اختصاصی (`IdentityHeader`) با مونوگرام ۷۲ پیکسلی و محاسبه روزهای عضویت و تعداد روتین‌های فعال.
  - جستجوی بلادرنگ تنظیمات (`SettingsSearchDelegate`).
  - ۷ کارت دسته‌بندی با شمارنده فعال تنظیمات.
  - بخش درباره ریتمو با نسخه و بیلد زنده از پلتفرم (۷ بار کلیک جهت ورود به گزارش خطاهای کرش).
  - منطقه خطر (`DangerZone`) برای بازنشانی کارخانه‌ای داده‌ها با الزام به تایپ عبارت «پاک کن» و تهیه نسخه پشتیبان اضطراری.

---

### ۴. صفحات هفت‌گانه گروه‌های تنظیمات
1. **حساب و هویت (`IdentityGroupScreen`)**: ویرایش نام با اعتبارسنجی فارسی، انتخاب سن با `CupertinoPicker`، انتخاب جنسیت با اکشن‌شیت، و انتخاب حالت اپلیکیشن (ساده / کامل).
2. **ماژول‌ها و بخش‌های برنامه (`ModulesGroupScreen`)**: پیمایش از روی `ModuleRegistry`، نمایش نشان «همیشه فعال» برای ماژول‌های اصلی، دیالوگ هشدار پزشکی قبل از غیرفعال‌سازی ماژول دارو، و اکشن بازنشانی مجزای هر ماژول.
3. **اعلان‌ها و یادآوری‌ها (`NotificationsGroupScreen`)**: کلید سراسری، تنظیم ساعات سکوت (با تفکیک بازه شبانه و عبور روتین‌های حیاتی و پزشکی)، حالت خلاصه‌سازی، بازه تجمیع، سقف پیام‌های غیراضطراری و زمان و سقف تعویق.
4. **ظاهر و زبان (`AppearanceGroupScreen`)**: اتصال مستقیم به `ThemeSettingsScreen` و کنترل زبان رابط کاربری.
5. **دستیار و حریم خصوصی (`AssistantPrivacyGroupScreen`)**: اتصال به `AiConnectionScreen` و `AiMemoryManagementScreen`، رضایت‌نامه ابری، لحن دستیار، ظرفیت روزانه و شیت تنظیمات روان‌شناختی.
6. **داده و پشتیبان (`DataBackupGroupScreen`)**: اتصال به `BackupScreen`، نمایش تاریخ آخرین پشتیبان به تقویم شمسی، پشتیبان خودکار، گزارش خطاها و پاک‌سازی لاگ اعلان‌ها.
7. **امنیت و قفل برنامه (`SecurityGroupScreen`)**: قفل اپلیکیشن، ورود با اثر انگشت/چهره، مهلت قفل خودکار، رمز اختصاصی بخش چرخه و سیاست حریم خصوصی.

---

### ۵. آزمون‌های واحد (Unit Tests)
- نگارش **۱۴ آزمون واحد** در پوشه `test/prompt_058/` جهت تضمین کارکرد صحیح بخش‌های رجیستری، کش، ساعات سکوت، تفکیک PIN، مایگریشن و اعتبارسنجی دامنه‌ها.
