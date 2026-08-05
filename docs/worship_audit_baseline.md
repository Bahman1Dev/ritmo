# گزارش خط پایه و ممیزی اولیه (Baseline Audit — Prompt 048)

تاریخ ممیزی: ۲۰۲۶-۰۸-۰۶
شناسه سند: پرامپت ۰۴۸ · مادول عبادت

---

## ۱. نتیجهٔ بررسی‌های V-1 و V-2

### V-1: بازگردانی remainingCount در Undo
- **نتیجه:** ✅ **تأیید شد** (V-1 Confirmed).
- **مستندات:** در [completion_gateway.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart#L425) دستور زیر موجود است:
  `UPDATE worship_debts SET remainingCount = remainingCount + ?, isArchived = 0, updatedAt = ? WHERE id = ?`
- **تصمیم:** اجرای تسک W-17 **لازم نیست**.

### V-2: ردیف‌های wp_asr و wp_isha و سوئیچ show_asr_isha_prayers
- **نتیجه:** ❌ **رد شد** (V-2 Rejected).
- **مستندات:** در `obligatory_prayers_section.dart` فقط ۳ ردیف `wp_fajr`، `wp_dhuhr` («نماز ظهر و عصر») و `wp_maghrib` («نماز مغرب و عشا») seed می‌شوند. با وجود سوئیچ `show_asr_isha_prayers` در تنظیمات، ردیف‌های `wp_asr` و `wp_isha` فعال نمی‌شوند.
- **تصمیم:** اجرای تسک **W-18 اجباری است**.

---

## ۲. وضعیت دو منبع حقیقت (dailyDone vs worship_completions)

- **فایل‌هایی که از `dailyDone` می‌خوانند:**
  - [obligatory_prayers_section.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/obligatory_prayers_section.dart)
  - [mustahab_section.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/mustahab_section.dart)
  - [quran_dhikr_section.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/presentation/widgets/quran_dhikr_section.dart)
- **فایل‌هایی که از `worship_completions` می‌خوانند:**
  - [worship_completion_repository.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/features/worship/logic/worship_completion_repository.dart)
  - [completion_gateway.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/domain/completion/completion_gateway.dart)
  - [end_of_day_sweep.dart](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/end_of_day_sweep.dart)

---

## ۳. آمار فراخوانی‌های مستقیم دیتابیس در لایهٔ Presentation
- `obligatory_prayers_section.dart`: ~۶ فراخوانی مستقیم
- `mustahab_section.dart`: ~۵ فراخوانی مستقیم
- `quran_dhikr_section.dart`: ~۴ فراخوانی مستقیم
- `worship_debts_section.dart`: ~۷ فراخوانی مستقیم
- `worship_seasons_section.dart`: ~۴ فراخوانی مستقیم
- `prayer_times_hero.dart`: ~۳ فراخوانی مستقیم
- `worship_screen.dart`: ~۳ فراخوانی مستقیم
- **مجموع:** ~۳۲ فراخوانی مستقیم دیتابیس در UI (هدف فاز ۱ و P-1: رساندن به **صفر**).

---

## ۴. لیست رنگ‌های هاردکدشده در مادول عبادت
- `0xffD4A843` (طلایی): موجود در `worship_debts_section.dart`, `mustahab_section.dart`, `worship_reminder_settings_sheet.dart`, `ai_worship_assistant_sheet.dart`
- `0xff5B8AF5` (آبی): اسپینر لودینگ در `worship_seasons_sheet.dart`
- **تصمیم:** تمام رنگ‌ها به `context.colors` یا `context.modules.worship` منتقل می‌شوند.

---

## ۵. مهاجرت‌های بعدی
- آخرین مهاجرت موجود: `MigrationV65` (نسخه ۶۵)
- شماره مهاجرت‌های جدید:
  - **M1:** `MigrationV66` (انتقال Seed ویجت‌ها به مهاجرت دیتابیس)
  - **M2:** `MigrationV67` (ستون‌های جدید افزودنی + جدول `worship_day_context`)
  - **M3:** `MigrationV68` (Backfill کامل `worship_completions`)

---

## ۶. خط پایه Analyzer و Test
- نسخه دیتابیس پایه: **۶۵**
- تمام تست‌های فاز ۰ بررسی شدند.
