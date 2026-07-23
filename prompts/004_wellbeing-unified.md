# 🤖 پرامپت اجرایی — یکپارچه‌سازی کامل صفحه «حال و تعادل» (حذف تب‌ها، یک صفحه واحد، یک دستیار)

> ⛔️ **هیچ Implementation Plan، سند طراحی، فایل TODO یا خلاصه‌ی برنامه نساز.** این فایل خودش نقشه‌ی اجراست — مستقیم شروع به تغییر کد کن و تسک‌ها را یک‌سره تا انتها اجرا کن.
> قبل از هر تغییر وضعیت فعلی فایل‌ها را بخوان؛ اگر بخشی قبلاً مطابق همین طرح پیاده شده، تکرارش نکن.
> **بازنویسی کامل لایه presentation این بخش مجاز و مطلوب است.** لایه داده/منطق (engineها، کوئری‌ها، جدول‌ها) را نشکن.

## 🎯 هدف

صفحه «حال و تعادل» الان یک شِل با سوییچر سه‌بخشی است (`enum WellbeingSection { energy, sleep, reflection }`) که سه صفحه‌ی جدا را در `IndexedStack` نشان می‌دهد — سه دنیای ایزوله با سه دستیار AI جدا. باید به **یک صفحه‌ی اسکرولی واحد** تبدیل شود که انرژی، خواب و خودارزیابی را به‌صورت یک داستان پیوسته روایت کند، با **یک دستیار AI یکپارچه** که به داده‌ی هر سه حوزه دسترسی دارد.

## 📁 وضعیت فعلی (تأییدشده از کد — خودت دوباره verify کن)

- `lib/features/wellbeing/presentation/wellbeing_screen.dart` (۲۹۷ خط): AppBar + سوییچر سه‌دکمه‌ای + `IndexedStack` با `EnergyMoodScreen(embedded: true)` / `SleepScreen(embedded: true)` / `ReflectionScreen(embedded: true)`؛ برای انرژی و خواب در صورت خاموش بودن ماژول، `_buildActivationCTA` تمام‌صفحه با کلیدهای `module_energy_enabled` / `module_sleep_enabled`.
- سه صفحه‌ی میزبان‌شده:
  - `energy/presentation/energy_mood_screen.dart` (۳۲۸ خط) + ویجت‌ها: `energy_hero`, `energy_today_section`, `energy_patterns_section`, `energy_trends_section`, `quick_log_sheet`, `ai_energy_assistant_sheet` (پارامترها: `currentEnergy`, `explanations`, `correlationInsight`, `isUserMenstruating`, `isEnergyTuned`, ...).
  - `sleep/presentation/sleep_screen.dart` (۲۹۵ خط) + ویجت‌ها: `sleep_hero`, `sleep_last_night_section`, `sleep_patterns_section`, `sleep_trends_section`, `sleep_log_sheet`, `sleep_target_sheet` (شیت هدف خواب بار اول خودکار باز می‌شود)، `ai_sleep_assistant_sheet` (پارامترها: `target`, `logs`, `onSaved`).
  - `reflection/presentation/reflection_screen.dart` (۴۶۴ خط) + ویجت‌ها: `reflection_hero`, `journal_timeline_section`, `reflection_correlation_section`, `reflection_trends_section`, `ai_reflection_assistant_sheet` (پارامترها: `todayCheckinDone`, `todayReflectionDone`, `onSaved`).
- نقاط ورود خارجی که **نباید بشکنند** (امضای `WellbeingScreen(initialSection:)` حفظ شود):
  - `assistant/logic/assistant_action_registry.dart:271` → `WellbeingSection.sleep`
  - `today/presentation/now_dashboard_screen.dart:395,397` → sleep / energy
  - `today/presentation/systems_hub_screen.dart:469`
- زبان طراحی مرجع: کارت‌های هاب سیستم‌ها (شعاع ۲۸، حباب شیشه‌ای آیکن)، `RitmoTheme.buildBackgroundContainer`، `context.colors`، `Vazirmatn`، RTL.

## 🔒 تصمیم‌های قطعی طراحی

### ۱. صفحه واحد — بازنویسی کامل `wellbeing_screen.dart`

سوییچر و `IndexedStack` حذف. یک `CustomScrollView`/اسکرول واحد از بالا به پایین:

1. **هدر سفارشی:** عنوان «حال و تعادل» + دکمه‌ی برگشت + دکمه‌ی دستیار AI یکپارچه (آیکن `CupertinoIcons.sparkles` در حباب شیشه‌ای — الگوی هاب سلامت).
2. **Hero یکپارچه «نبض تعادل»:** یک کارت بزرگ که سه سیگنال زنده را کنار هم نشان می‌دهد: انرژی فعلی (از داده‌ی energy)، خواب دیشب (مدت/کیفیت از داده‌ی sleep)، و وضعیت چک‌این امروز (از reflection). سه پاره‌ی بصری هم‌خانواده (مثلاً سه قوس/دیال کوچک با رنگ هویتی هر حوزه: انرژی `#EC4899`، خواب `#8B5CF6`، خودارزیابی — رنگ فعلی reflection را از کد بردار). تپ روی هر پاره → اسکرول نرم به بخش مربوطه.
3. **ردیف اقدام سریع:** سه دکمه‌ی جمع‌وجور: «ثبت انرژی» (باز کردن `QuickLogSheet`)، «ثبت خواب» (`SleepLogSheet`)، «چک‌این امروز» (فلوی چک‌این reflection موجود). شیت‌های موجود عیناً بازاستفاده شوند.
4. **بخش «انرژی و حال»:** هدر بخش با آیکن/رنگ هویتی + محتوای اصلی از ویجت‌های موجود energy (today + patterns) با چیدمان فشرده‌تر.
5. **بخش «خواب و بیداری»:** هدر بخش + last night + دسترسی به هدف خواب (`SleepTargetSheet` — رفتار «بار اول خودکار باز شود» حذف؛ به‌جایش اگر هدف تعریف نشده، کارت دعوت درون بخش).
6. **بخش «خودارزیابی»:** هدر بخش + چک‌این/ژورنال (timeline اخیر، فشرده — مثلاً ۳ آیتم آخر + «همه»).
7. **بخش یکپارچه «روند و همبستگی»:** سه بخش trends جدا + `reflection_correlation_section` در یک بخش واحد ادغام شوند — سوییچر کوچک داخلی (انرژی/خواب/خودارزیابی) یا چیدمان پشت‌سرهم فشرده؛ خودت بهترین را انتخاب کن، اما یک جا باشد نه سه جا.
8. **Gating ماژول‌ها به‌صورت درون‌خطی:** اگر `module_energy_enabled` یا `module_sleep_enabled` خاموش بود، به‌جای CTA تمام‌صفحه، همان بخش به یک **کارت فعال‌سازی جمع‌وجور** تبدیل شود (آیکن + یک خط توضیح + دکمه فعال‌سازی با همان کلید setting) و بقیه‌ی صفحه عادی کار کند. پاره‌ی مربوطه در Hero هم حالت «غیرفعال» بگیرد.
9. **ناوبری ورودی:** `initialSection` دیگر تب عوض نمی‌کند — بعد از build اول، اسکرول خودکار نرم به بخش مربوطه (با `GlobalKey`/`ScrollController`). امضای سازنده و enum عیناً حفظ شوند تا سه call site خارجی نشکنند.
10. **لمس‌های جاندار:** انیمیشن ورود پلکانی بخش‌ها، skeleton loading، ارقام فارسی، هر دو تم روشن/تاریک.

### ۲. دستیار AI یکپارچه — فایل جدید `wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart`

- سه شیت `ai_energy_assistant_sheet`، `ai_sleep_assistant_sheet`، `ai_reflection_assistant_sheet` با **یک شیت واحد** جایگزین شوند.
- ساختار چت (حباب پیام، streaming، typing indicator، کپی، خطاها) را از یکی از سه شیت موجود — کامل‌ترینشان — بردار؛ دوباره اختراع نکن.
- **Context یکپارچه:** system prompt جدید که داده‌ی هر سه حوزه را یک‌جا به مدل بدهد: وضعیت انرژی فعلی + توضیحات و همبستگی (همان ورودی‌های شیت انرژی فعلی، شامل `isUserMenstruating`/`isEnergyTuned`)، هدف و لاگ‌های خواب، و وضعیت چک‌این/ژورنال امروز. حوزه‌های ماژول-خاموش از context حذف شوند.
- **چیپ‌های پرسش سریع** دسته‌بندی‌شده بر اساس سه حوزه + چند پرسش میان‌حوزه‌ای («چرا وقتی بد می‌خوابم انرژیم کم است؟»).
- هر قابلیت عملیاتی (action) که شیت‌های فعلی دارند (مثل ثبت از داخل چت با `onSaved`) در شیت واحد حفظ شود.
- موتور/سرویس فراخوانی AI همانی باشد که سه شیت فعلی استفاده می‌کنند — هیچ سرویس جدیدی نساز.

### ۳. تکلیف فایل‌های قدیمی

- `energy_mood_screen.dart`، `sleep_screen.dart`، `reflection_screen.dart`: منطق load/state لازمشان به صفحه واحد (یا کنترلرهای سبک محلی در `wellbeing/`) منتقل شود. بعد از مهاجرت، اگر `grep` تأیید کرد هیچ‌جای دیگر اپ import نمی‌شوند، **حذفشان کن**؛ اگر جایی دیگر استفاده می‌شوند فقط از wellbeing قطعشان کن و گزارش بده.
- سه شیت دستیار قدیمی بعد از جایگزینی و تأیید عدم استفاده، حذف شوند.
- ویجت‌های section/hero/sheet (لیست‌شده در بالا) حفظ و بازاستفاده می‌شوند؛ refactor آزاد (مثلاً حذف پارامترهای مربوط به حالت embedded).

## ⛔️ خارج از محدوده (دست نزن)

- هیچ تغییری در دیتابیس: نه جدول، نه ستون، نه migration، نه کلید `app_settings` (کلیدهای موجود با همان نام/فرمت خوانده/نوشته شوند).
- Engineها و منطق محاسبات (انرژی، خواب، همبستگی) — فقط فراخوانی.
- منطق اعلان‌ها و یادآورها.
- ماژول‌ها و صفحه‌های دیگر اپ؛ سه call site خارجی فقط باید بدون تغییر کامپایل و کار کنند.

## ✅ Definition of Done

1. صفحه «حال و تعادل» یک اسکرول واحد است: هیچ سوییچر تب و `IndexedStack`ای وجود ندارد؛ Hero «نبض تعادل» + اقدام سریع + سه بخش + بخش یکپارچه‌ی روند/همبستگی.
2. یک دستیار AI واحد با context هر سه حوزه از دکمه‌ی هدر باز می‌شود؛ سه شیت قدیمی حذف شده‌اند و همه‌ی قابلیت‌هایشان (چیپ‌ها، ثبت از چت، streaming) در شیت واحد موجود است.
3. هر سه ثبت سریع (انرژی، خواب، چک‌این) کار می‌کنند و بعد از ثبت، Hero و بخش مربوطه بدون خروج از صفحه به‌روز می‌شوند.
4. gating ماژول‌ها درون‌خطی است و خاموش بودن انرژی یا خواب بقیه‌ی صفحه را نمی‌شکند.
5. `WellbeingScreen(initialSection: WellbeingSection.sleep)` از سه call site خارجی بدون تغییر آن فایل‌ها کار می‌کند و به بخش خواب اسکرول می‌شود.
6. فایل‌های صفحه/شیت قدیمی که دیگر استفاده نمی‌شوند حذف شده‌اند (با تأیید grep).
7. RTL، ارقام فارسی، هر دو تم، skeleton و empty state سالم.
8. `flutter analyze` روی فایل‌های تغییرکرده error جدید ندارد.
9. گزارش نهایی: فهرست فایل‌های ساخته/تغییرکرده/حذف‌شده + خلاصه یک‌خطی هر کدام.
