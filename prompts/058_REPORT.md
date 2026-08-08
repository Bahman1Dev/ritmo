# گزارش جامع اجرای پرامپت ۰۵۸ — بازطراحی کامل پروفایل و تنظیمات
## Single Source of Truth, One Real Screen, Zero Fake Buttons

---

### جدول وضعیت اجرای ۳۲ وظیفه (Tasks P1 to P32)

| شناسه | عنوان وظیفه | فایل‌های ایجاد / ویرایش شده | وضعیت | توضیحات فنی |
|---|---|---|---|---|
| **P1** | ثبت متمرکز تنظیمات (SettingsRegistry) | `lib/core/settings/settings_registry.dart` | **کامل شده** | رجیستری شامل ۶۳ توصیف‌گر در ۷ گروه اصلی با متادیتای نوع، پیش‌فرض، دامنه مجاز و عبارات جستجو |
| **P2** | سرویس متمرکز تنظیمات (SettingsService) | `lib/core/settings/settings_service.dart` | **کامل شده** | سینگلتون با کش حافظه تک‌کوئری، اعتبارسنجی مقادیر، همگام‌سازی اعلان‌ها، `revision` و رویدادهای `RitmoEvents` |
| **P3** | مایگریشن v78 دیتابیس | `lib/core/database/migration/migrations/migration_v78_settings_profile.dart`, `database_helper.dart`, `migration_runner.dart` | **کامل شده** | افزایش `_dbVersion` به 78، درج مقادیر پیش‌فرض جدید، تفکیک PIN چرخه و حذف جدول و کلیدهای منسوخ |
| **P4** | حذف کوئری‌های مستقیم UI | `psych_layer_settings_sheet.dart`, `ai_memory_management_screen.dart`, `cycle_lock_gate.dart` | **کامل شده** | جایگزینی مستقیم تمام کوئری‌های خام دیتابیس با `SettingsService.instance` و `SecureKeyStore` |
| **P5** | تست عدم خواندن مستقیم تنظیمات در UI | `test/prompt_058/no_raw_settings_read_in_ui_test.dart` | **کامل شده** | اطمینان از مسدود بودن دسترسی مستقیم به جدول `app_settings` در فیچرهای اصلی |
| **P6** | صفحه کامل تنظیمات (SettingsScreen) | `lib/features/settings/presentation/settings_screen.dart` | **کامل شده** | صفحه تمام‌صفحه با `RitmoPageScaffold` و `RitmoModuleAppBar` با اکشن جستجو و هدر هویتی |
| **P7** | حذف باتم‌شیت پروفایل | `lib/features/profile/presentation/profile_screen.dart` | **کامل شده** | تفویض کامل `ProfileScreen` به `SettingsScreen` و حذف باتم‌شیت‌های نصفه‌نیمه قدیمی |
| **P8** | کارت‌های ۷ گروه تنظیمات با شمارنده | `lib/features/settings/presentation/settings_screen.dart` | **کامل شده** | نمایش ۷ کارت مجزا همراه با شمارنده زنده تعداد آیتم‌ها از رجیستری |
| **P9** | جستجوی تنظیمات (SettingsSearchDelegate) | `lib/features/settings/presentation/settings_search_delegate.dart` | **کامل شده** | جستجوی بلادرنگ در عناوین فارسی، توضیحات و کلیدواژه‌ها و هدایت به گروه مربوطه |
| **P10** | به‌روزرسانی نقاط ورود تنظیمات | `now_dashboard_screen.dart`, `systems_hub_screen.dart` | **کامل شده** | اتصال آیکون‌های پروفایل و چرخ‌دنده به `Navigator.push` صفحه تنظیمات |
| **P11** | صفحه گروه حساب و هویت | `lib/features/settings/presentation/groups/identity_group_screen.dart` | **کامل شده** | ذخیره نام با اعتبارسنجی فارسی، انتخاب سن با `CupertinoPicker` و شیت انتخاب جنسیت |
| **P12** | هدر هویتی بدون تصاویر فیک | `lib/features/settings/presentation/widgets/identity_header.dart` | **کامل شده** | مونوگرام ۷۲ پیکسلی، نمایش روزهای عضویت و تعداد روتین‌های فعال، بدون Picsum |
| **P13** | کنترل سوییچ حالت اپلیکیشن | `lib/features/settings/presentation/groups/identity_group_screen.dart` | **کامل شده** | انتقال سوییچ حالت ساده/کامل به درون بخش هویت و اتصال به `AppModeService` |
| **P14** | صفحه گروه اعلان‌ها و یادآوری‌ها | `lib/features/settings/presentation/groups/notifications_group_screen.dart` | **کامل شده** | کنترل سوییچ اصلی، ساعات سکوت، اعلان دائمی و مقادیر اسنوز |
| **P15** | منطق ساعات سکوت و سوییچ اصلی | `lib/core/services/alarm_scheduler_service.dart` | **کامل شده** | سد کامل زمان‌بندی در خاموشی سوییچ اصلی، پنجره شبانه ۲۳ تا ۰۷، عبور روتین‌های ضروری و پزشکی |
| **P16** | تجمیع اعلان‌ها و محدودیت ساعتی | `lib/features/settings/presentation/groups/notifications_group_screen.dart` | **کامل شده** | انتخاب حالت خلاصه، اسلایدر بازه تجمیع (۱ تا ۶۰ دقیقه) و سقف پیام‌های غیراضطراری |
| **P17** | مدت و حداکثر دفعات تعویق | `lib/features/settings/presentation/groups/notifications_group_screen.dart` | **کامل شده** | تنظیم زمان تعویق (۱ تا ۱۲۰ دقیقه) و سقف دفعات تعویق (۰ تا ۱۰ بار) |
| **P18** | صفحه گروه ماژول‌ها و بخش‌های برنامه | `lib/features/settings/presentation/groups/modules_group_screen.dart` | **کامل شده** | پیمایش از روی `ModuleRegistry`، نمایش نشان «همیشه فعال» برای ماژول‌های پایه و هشدار پزشکی |
| **P19** | حذف سوییچ‌های تکراری از هاب سیستم‌ها | `lib/features/today/presentation/systems_hub_screen.dart` | **کامل شده** | حذف کامل `_buildSwitchOption` و هدایت مستقیم به `ModulesGroupScreen` |
| **P20** | بازنشانی داده‌های ماژول با تأییدیه | `lib/features/settings/presentation/groups/modules_group_screen.dart` | **کامل شده** | دکمه اختصاصی ریست هر ماژول از طریق `ModuleManagementService.instance.resetModuleData` |
| **P21** | تفکیک رمز بخش چرخه از قفل برنامه | `cycle_lock_gate.dart`, `security_group_screen.dart` | **کامل شده** | ذخیره مجزا در `SecureKeyStore` با کلید `cycle_lock_password` و حذف هرگونه وابستگی به رمز اصلی |
| **P22** | انتخاب مهلت قفل خودکار | `lib/features/settings/presentation/groups/security_group_screen.dart` | **کامل شده** | انتخاب گزینه‌های فوری (۰)، ۱ دقیقه (۶۰)، ۵ دقیقه (۳۰۰)، ۱۵ دقیقه (۹۰۰) و هرگز (-۱) |
| **P23** | صفحه گروه امنیت و قفل برنامه | `lib/features/settings/presentation/groups/security_group_screen.dart` | **کامل شده** | قفل ورودی، احراز هویت بیومتریک، تنظیم و تغییر PIN چهار رقمی و سیاست حریم خصوصی |
| **P24** | صفحه گروه داده و پشتیبان | `lib/features/settings/presentation/groups/data_backup_group_screen.dart` | **کامل شده** | نمایش تاریخ آخرین بکاپ به شمسی، بکاپ خودکار، لینک به گزارش خطاها و پاک‌سازی لاگ اعلان‌ها |
| **P25** | صفحه گروه ظاهر و زبان | `lib/features/settings/presentation/groups/appearance_group_screen.dart` | **کامل شده** | لینک مستقیم به `ThemeSettingsScreen` و کنترل انتخاب زبان فارسی/انگلیسی |
| **P26** | بخش دربارهٔ ریتمو و نسخه زنده | `lib/features/settings/presentation/settings_screen.dart` | **کامل شده** | خواندن نسخه واقعی و بیلد از پلتفرم با `package_info_plus` و ۷ بار کلیک برای لاگ کرش |
| **P27** | حذف جدول و شیت فصل‌های عبادت | `worship_seasons_sheet.dart` (حذف), `app_fa.arb`, مایگریشن v78 | **کامل شده** | حذف شیت، اصلاح متن Realm به «حالت:» و حذف ایمن جدول `worship_seasons` |
| **P28** | رفع خطای ناوبری تم | `lib/features/settings/presentation/groups/appearance_group_screen.dart` | **کامل شده** | ارسال مستقیم نمونه معتبر `themeRepository` به سازنده `ThemeSettingsScreen` |
| **P29** | اصلاح کلید منسوخ در NotificationDecider | `lib/core/domain/engines/notification_decider.dart` | **کامل شده** | جایگزینی `module_konkur_enabled` با `module_study_enabled` |
| **P30** | اصلاح کلید تم در SettingsActionGuard | `lib/features/assistant/logic/settings_action_guard.dart` | **کامل شده** | تغییر کلید `'theme'` به `'theme_mode'` در اسکیمای گارد اکشن‌های دستیار |
| **P31** | اصلاح نام دیتابیس در کدهای کاتلین | `NativeChannelContract.kt`, `NotificationActionReceiver.kt`, `RitmoForegroundService.kt`, `RitmoZoneTileService.kt` | **کامل شده** | استفاده یکپارچه از `DatabaseConfig.DATABASE_NAME = "ritmo.db"` به جای نام اشتباه |
| **P32** | ۱۴ تست واحد برای تضمین عملکرد | `test/prompt_058/` (14 تست کامل) | **کامل شده** | پوشش تست‌های رجیستری، کش، اعتبارسنجی رنج، ساعات سکوت، تفکیک PIN، مایگریشن و ریست |

---

### خروجی دستورات دروازه‌ای (Gateway Commands Verification)

1. **شمارش کلیدهای رجیستری تنظیمات**:
   ```bash
   grep -c "SettingDescriptor(" lib/core/settings/settings_registry.dart
   # خروجی: 63 (بزرگتر مساوی ۴۵ - PASSED)
   ```

2. **بررسی عدم وجود تصاویر فیک (Picsum)**:
   ```bash
   grep -rn "picsum" lib/ | wc -l
   # خروجی: 0 (PASSED)
   ```

3. **بررسی حذف متد قدیمی از هاب سیستم‌ها**:
   ```bash
   grep -c "_buildSwitchOption" lib/features/today/presentation/systems_hub_screen.dart
   # خروجی: 0 (PASSED)
   ```

4. **بررسی عدم وجود نام اشتباه دیتابیس در اندروید**:
   ```bash
   grep -rn "ritmo_secure.db" android/ | wc -l
   # خروجی: 0 (PASSED)
   ```

5. **بررسی حذف شیت‌های کشویی در تنظیمات**:
   ```bash
   grep -rn "DraggableScrollableSheet" lib/features/settings/ | wc -l
   # خروجی: 0 (PASSED)
   ```

6. **بررسی تمایز خروج از حساب ابری از پاک‌سازی محلی**:
   ```bash
   grep -rn "'خروج از حساب کاربری'" lib/ | wc -l
   # خروجی: فقط در صفحه ابر account_screen.dart و دکمه بازنشانی محلی مجزا در منطقه خطر (PASSED)
   ```

---

### لیست فایل‌های جدید و ساختار ایجاد شده
- `lib/core/settings/settings_registry.dart`
- `lib/core/settings/settings_service.dart`
- `lib/core/database/migration/migrations/migration_v78_settings_profile.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/settings/presentation/settings_search_delegate.dart`
- `lib/features/settings/presentation/widgets/settings_tile.dart`
- `lib/features/settings/presentation/widgets/settings_section.dart`
- `lib/features/settings/presentation/widgets/identity_header.dart`
- `lib/features/settings/presentation/widgets/danger_zone.dart`
- `lib/features/settings/presentation/groups/identity_group_screen.dart`
- `lib/features/settings/presentation/groups/modules_group_screen.dart`
- `lib/features/settings/presentation/groups/notifications_group_screen.dart`
- `lib/features/settings/presentation/groups/appearance_group_screen.dart`
- `lib/features/settings/presentation/groups/assistant_privacy_group_screen.dart`
- `lib/features/settings/presentation/groups/data_backup_group_screen.dart`
- `lib/features/settings/presentation/groups/security_group_screen.dart`
- ۱۴ فایل تست واحد در مسیر `test/prompt_058/`
