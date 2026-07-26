# گزارش نهایی اجرای پرامپت ۰۳۴ — بازسازی آنبوردینگ اصلی: منبع حقیقت واحد، ذخیره‌سازی اتمیک و شخصی‌سازی هوشمند

---

## ۱. خروجی دستورات راستی‌آزمایی (PASS 0)

| شناسه | شرح راستی‌آزمایی | خروجی کُد واقعی |
|---|---|---|
| **P0-1** | `home_city_id` | فقط در `main.dart` گیت ورودی بود؛ در بقیه نقاط (عبادات/اسنپ‌شات) به عنوان fallback خوانده می‌شد. |
| **P0-2** | `onboarding_completed` | تنها در `onboarding_screen.dart` نوشته می‌شد ولی هیچ‌جا خوانده نمی‌شد. |
| **P0-3** | `_onboardingCompleted` | در `main.dart:184` بر اساس `routines.isNotEmpty` مقداردهی می‌شد. |
| **P0-4** | `allModuleKeys` | در `lib/core/services/module_management_service.dart:13` موجود بود. |
| **P0-5** | `module_sports_enabled` | ۲۲ مورد یافت شد که همگی مربوط به جریان آنبوردینگ قدیمی بودند. |
| **P0-6** | `module_supplementary_sports_enabled` | ۱۴ مورد فعال در سیستم کدهای اصلی و ماژول‌ها. |
| **P0-7** | ماژول‌های خواب/انرژی/عادات | در سیستم وجود داشتند اما آنبوردینگ هرگز کلید فعال‌سازی آن‌ها را نمی‌نوشت. |
| **P0-8** | `primary_focus_areas` | کلیدهای فارسی ذخیره می‌شدند (`['سلامتی', 'ورزش']`). |
| **P0-9** | `default_energy_level` | مقدار `'MEDIUM'` هاردکد ارسال می‌شد. |
| **P0-10** | `notif_permission_asked` | در آنبوردینگ نوشته می‌شد اما شل اصلی آن را نمی‌خواند. |
| **P0-11** | `_requestNotificationPermissionIfNeeded` | در `home_navigation_shell.dart:58` بدون چک کردن فیدبک آنبوردینگ اجرا می‌شد. |
| **P0-12** | بررسی پریمیوم ماژول‌ها | `PremiumService.instance.can` برای `coursesModule` و `konkurModule` بررسی شد. |
| **P0-13** | `CreateRoutineCommand` | در `ritmo_execution_kernel.dart:21` تعریف شده و آماده اجرا در تراکنش بود. |
| **P0-14** | `RoutineOccurrenceGenerator` | در `create_routine_handler.dart` به صورت خودکار فراخوانی می‌شد. |
| **P0-15** | `_dbVersion` | نسخه فعلی دیتابیس **۵۷** بود. نسخه جدید به **۵۸** ارتقا یافت. |
| **P0-16** | مهاجرت‌های V56-V57 | آخرین مهاجرت `MigrationV57` بود. |
| **P0-17** | شمای جدول `routines` | جدول‌های `routines` و `routine_schedules` تایید شدند. |

---

## ۲. وضعیت شرط‌های توقف (Stop Conditions S-A…S-E)

- **S-A:** خوانندگان `home_city_id` در عبادات و اسنپ‌شات شناسایی شدند؛ هنگام انتخاب شهر در آنبوردینگ، هر دو کلید `prayer_city_id` و `home_city_id` نوشته می‌شوند تا هیچ خواننده‌ای نشکند.
- **S-B:** نسخه دیتابیس ۵۷ بود → مهاجرت جدید با شماره **۵۸** (`MigrationV58`) ساخته شد.
- **S-C:** لیست کلیدهای ماژول از `ModuleManagementService.allModuleKeys` استخراج شد.
- **S-D:** متد `CreateRoutineCommand` و اجرا از طریق `RitmoExecutionKernel` تایید شد.
- **S-E:** متد `FocusArea.fromLegacyFaLabel` برای پشتیبانی دوطرفه از داده‌های فارسی قدیمی اضافه شد.

---

## ۳. خلاصه رفع باگ‌ها (O1 تا O18)

| کد | باگ | وضعیت | توضیحات |
|---|---|---|---|
| **O1** | سنجش آنبوردینگ با `home_city_id` | ✅ رفع شد | منبع حقیقت واحد به `OnboardingGate.isCompleted` تغییر یافت. |
| **O2** | وابسته بودن آنبوردینگ به `routines.isNotEmpty` | ✅ رفع شد | شرط حذف شد و پاک کردن روتین‌ها آنبوردینگ را برنمی‌گرداند. |
| **O3** | ذخیره‌سازی غیراتمیک | ✅ رفع شد | تمامی مراحل در یک `db.transaction` منفرد انجام می‌شوند. |
| **O4** | اعتبارسنجی متناقض و داده جعلی | ✅ رفع شد | دکمه skip به «بعداً تنظیم می‌کنم» تغییر یافت و هیچ داده جعلی نوشته نمی‌شود. |
| **O5** | کلید مرده `module_sports_enabled` | ✅ رفع شد | نگاشت «ورزش» به `module_supplementary_sports_enabled` اصلاح شد. |
| **O6** | نگاشت نشدن حوزه‌های خواب/استرس/خانواده | ✅ رفع شد | به ماژول‌های `sleep`, `energy`, `progressive_habits` نگاشت شدند. |
| **O7** | هاردکد خاموش بودن سیکل برای بانوان | ✅ رفع شد | سویچ اختیاری فعال‌سازی سیکل برای جنسیت `FEMALE` اضافه شد. |
| **O8** | روشن شدن ماژول‌های پریمیوم بدون اشتراک | ✅ رفع شد | بررسی `PremiumService.instance.can` اضافه شد و آیکن قفل قرار گرفت. |
| **O9** | درخواست تکراری مجوز اعلان‌ها | ✅ رفع شد | `home_navigation_shell.dart` کلید `notif_permission_asked` را چک می‌کند. |
| **O10** | عدم تولید occurrence برای روتین اول | ✅ رفع شد | تولید occurrenceها داخل تراکنش `CreateRoutineCommand` تضمین شد. |
| **O11** | نادیده گرفتن ساعت انتخابی برای روتین‌های عبادی | ✅ رفع شد | نوع زمان‌بندی `DAILY` با ساعت انتخابی کاربر حفظ می‌شود. |
| **O12** | مدت‌زمان روتین زیر ۵ دقیقه | ✅ رفع شد | عبور از `DurationBounds.sanitize(...)` اعمال شد. |
| **O13** | هاردکد بودن انرژی `MEDIUM` در اسنپ‌شات | ✅ رفع شد | پروفایل انرژی انتخابی کاربر به اسنپ‌شات منتقل می‌شود. |
| **O14** | عدم وجود گارد دابل‌تپ | ✅ رفع شد | متغیر `isSaving` اضافه شد و دکمه در زمان ذخیره غیرفعال است. |
| **O15** | دیالوگ خطای استثنای خام | ✅ رفع شد | پیام کاربرپسند فارسی همراه با دکمه‌های «تلاش مجدد» و «بستن» قرار گرفت. |
| **O16** | کلیدهای فارسی برای حوزه‌های تمرکز | ✅ رفع شد | انوم `FocusArea` با کدهای انگلیسی و پشتیبانی از برچسب فارسی ساخته شد. |
| **O17** | رگرسیون‌های UX | ✅ رفع شد | `PopScope`, `AnimatedSwitcher`, حداقل ابعاد لمس ۴۸dp و Semantics اصلاح شدند. |
| **O18** | پاک‌سازی جدول‌های کاربر از UI | ✅ رفع شد | تمام کد‌های `db.delete` روی جدول‌های روتین و زون از UI حذف شدند. |

---

## ۴. جدول وضعیت تکالیف (T1 تا T16)

| تکلیف | موضوع | وضعیت |
|---|---|---|
| **T1** | گیت ورودی واحد (`OnboardingGate`) | ✅ انجام شد |
| **T2** | مهاجرت نجات V58 و پاک‌سازی روتین‌های تکراری | ✅ انجام شد |
| **T3** | ذخیره‌سازی اتمیک در تراکنش دیتابیس | ✅ انجام شد |
| **T4** | ساخت روتین از مسیر رسمی `CreateRoutineCommand` | ✅ انجام شد |
| **T5** | نگاشت جامع ماژول‌ها (`OnboardingModuleMap`) | ✅ انجام شد |
| **T6** | انوم کدهای پایدار حوزه‌های تمرکز (`FocusArea`) | ✅ انجام شد |
| **T7** | مدیریت صادقانه مجوز اعلان‌ها | ✅ انجام شد |
| **T8** | انتقال سطح انرژی واقعی به اسنپ‌شات | ✅ انجام شد |
| **T9** | اصلاح رگرسیون‌های UX و دسترسی‌پذیری | ✅ انجام شد |
| **T10** | «رد کردن» صادقانه و ثبت آیتم‌های Inbox | ✅ انجام شد |
| **T11** | استنتاج هوشمند قوس روز (`DayArcInferencer`) | ✅ انجام شد |
| **T12** | انتخاب شهر درون‌ماژولی عبادات | ✅ انجام شد |
| **T13** | بستهٔ عادات پیشنهادی (`StarterPackCatalog`) | ✅ انجام شد |
| **T14** | پیش‌نمایش برنامه‌ریزی بدون ثبت دیتابیس | ✅ انجام شد |
| **T15** | ذخیره و بازیابی پیش‌نویس (`OnboardingDraft`) | ✅ انجام شد |
| **T16** | کنترلر حالت آنبوردینگ (`OnboardingController`) | ✅ انجام شد |

---

## ۵. فایل‌های ایجاد و ویرایش شده

**فایل‌های جدید:**
- `lib/features/onboarding/logic/onboarding_gate.dart`
- `lib/features/onboarding/logic/onboarding_controller.dart`
- `lib/features/onboarding/logic/onboarding_draft.dart`
- `lib/features/onboarding/logic/onboarding_module_map.dart`
- `lib/features/onboarding/logic/day_arc_inferencer.dart`
- `lib/features/onboarding/logic/starter_pack_catalog.dart`
- `lib/features/onboarding/models/focus_area.dart`
- `test/prompt_034_onboarding_tests.dart`
- `prompts/034_REPORT.md`

**فایل‌های ویرایش‌شده:**
- `lib/main.dart`
- `lib/core/database/database_helper.dart`
- `lib/core/database/migration/migrations_registry.dart`
- `lib/core/database/migration/migration_runner.dart`
- `lib/features/onboarding/presentation/onboarding_screen.dart`
- `lib/features/onboarding/presentation/steps/step_focus.dart`
- `lib/features/onboarding/presentation/steps/step_day_arc.dart`
- `lib/features/onboarding/presentation/steps/step_first_routine.dart`
- `lib/features/onboarding/presentation/steps/step_celebration.dart`
- `lib/features/today/presentation/home_navigation_shell.dart`
