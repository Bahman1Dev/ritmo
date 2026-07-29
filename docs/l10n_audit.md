# سند سرشماری و نقشه بومی‌سازی (Localization Audit & Sensitive Strings Map)

> **تاریخ سرشماری:** ۲۰۲۶-۰۷-۲۹  
> **مرجع اصلی:** فاز ۰ (پرامپت ۰۳۹ — ویرایش شده با دستور صریح کاربر)  
> **اسکریپت بازتولید خودکار:** `python tool/audit_l10n.py`  

---

> [!IMPORTANT]
> **دستور صریح کاربر:** استخراج ARB تا اطلاع ثانوی **متوقف** است. اپلیکیشن فعلاً فقط به‌صورت فارسی منتشر می‌شود. رشته‌های دسته (ب) هرگز نباید استخراج یا دستکاری شوند، زیرا مقادیر کلیدی دیتابیس/سید/انوم هستند و استخراج آن‌ها داده‌های موجود کاربران را خراب می‌کند.

---

## ۱. آمار سرشماری تجربی رشته‌های فارسی (تولیدشده با `tool/audit_l10n.py`)

- **تعداد کل رشته‌های فارسی هاردکد در سورس‌کد (`lib/`):** **۹٬۳۲۵** رشته
- **دسته‌بندی (الف) — رشته‌های صرفاً نمایشی در UI (`presentation/`):** **۶٬۰۲۸** رشته (۶۴٫۶٪)
- **دسته‌بندی (ب) — مقادیر دیتابیس / منطق / سید اولیه / انوم / کلیدها (`data/`, `logic/`, `seed/`, ...):** **۳٬۲۹۷** رشته (۳۵٫۴٪) — **قفل مطلق (دست‌نزنید)**

---

## ۲. نقشه رشته‌های حساس و مقادیر غیرقابل استخراج (دسته‌بندی ب)

رشته‌های هاردکد زیر **مطلقاً نباید بومی‌سازی یا دستکاری شوند**؛ زیرا مقادیر کلیدی دیتابیس، شناسه انوم‌ها، نام ماژول‌ها، یا تنظیمات سیستم هستند:

1. **مقادیر وضعیت‌ها و انوم‌های دیتابیس:**
   - `'CANCELLED'`, `'COMPLETED'`, `'SKIPPED'`, `'PENDING'`, `'ACTIVE'`, `'INACTIVE'`, `'ARCHIVED'`
   - `'DAILY'`, `'WEEKLY'`, `'CUSTOM_DAYS'`, `'ONCE'`, `'RECURRING'`
   - `'MUSTAHAB'`, `'DHIKR'`, `'QURAN'`, `'DEBT'`, `'PRAYER'`, `'FAST'`
   - `'WAKEFULNESS'`, `'FULL'`, `'LIGHT'`, `'MINIMAL'`, `'CUSTOM'`
   - `'DURATION_RAMP'`, `'TIME_SHIFT'`, `'NONE'`
   - `'MALE'`, `'FEMALE'`, `'WOMAN'`, `'MAN'`, `'ZAN'`, `'MARD'`

2. **اسامی جداول و ستون‌های دیتابیس:**
   - `routines`, `routine_schedules`, `routine_completions`, `routine_occurrences`
   - `goals`, `goal_steps`, `linkedRoutineId`, `targetDate`
   - `worship_completions`, `fasting_debt`, `cycle_periods`, `health_logs`
   - `konkur_topics`, `konkur_mock_exam_results`

3. **کلیدهای تنظیمات (`app_settings` & `SharedPreferences`):**
   - `'module_goals_enabled'`, `'module_cycle_enabled'`, `'module_religion_enabled'`, `'module_sports_enabled'`
   - `'user_gender'`, `'onboarding_completed'`, `'digest_mode'`, `'theme_mode'`, `'user_locale'`
   - `'notification_action_callback_handle'`, `'wm_registered_v2'`

---

## ۳. پرحجم‌ترین فایل‌های دسته‌بندی (الف) — نمایشی در UI

1. `features/profile/presentation/profile_screen.dart`: ۲۶۶ رشته
2. `features/cycle/presentation/cycle_screen.dart`: ۲۵۱ رشته
3. `features/cycle/presentation/widgets/cycle_pregnancy_mode.dart`: ۱۲۱ رشته
4. `features/routines/presentation/quick_add_parser.dart`: ۱۱۷ رشته
5. `features/supplementary_sports/presentation/ss_home_dashboard_screen.dart`: ۱۱۵ رشته
6. `features/profile/presentation/cycle_harmony_screen.dart`: ۱۰۷ رشته
7. `features/today/presentation/insights_screen.dart`: ۱۰۷ رشته
8. `features/today/presentation/systems_hub_screen.dart`: ۱۰۳ رشته
9. `features/chat/presentation/ai_chat_screen.dart`: ۹۰ رشته
10. `features/worship/presentation/worship_screen.dart`: ۸۷ رشته

---

## ۴. پرحجم‌ترین فایل‌های دسته‌بندی (ب) — دیتابیس و منطق (قفل‌ شده)

1. `features/konkur/data/konkur_curriculum.dart`: ۵۴۸ رشته (سرفصل‌های ثابت)
2. `features/supplementary_sports/data/seed/ss_exercise_farsi_names.dart`: ۴۵۸ رشته (نام‌های سید ورزش)
3. `l10n/app_localizations_fa.dart`: ۳۲۸ رشته
4. `core/database/seed/seed_service.dart`: ۱۴۵ رشته
5. `features/supplementary_sports/movement/data/seed/movement_kinds_seed.dart`: ۹۵ رشته
6. `features/konkur/data/konkur_presets.dart`: ۹۴ رشته
7. `core/database/seed/mock_data_seeder.dart`: ۸۸ رشته
8. `core/database/migration/migrations_registry.dart`: ۶۷ رشته
9. `features/assistant/logic/assistant_action_registry.dart`: ۶۴ رشته
10. `core/analytics/energy_analytics_engine.dart`: ۶۱ رشته
