# گزارش حسابرسی بومیسازی ریتمو (Localization Audit)

این سند گزارش جامعی از رشته‌های فارسی هاردکدشده در بخش‌های مختلف پروژه ریتمو ارائه می‌دهد که برای پیاده‌سازی کامل لوکال انگلیسی و بومی‌سازی استاندارد فلاتر به کار می‌رود.

## آمار کلی رشته‌های فارسی هاردکدشده در صفحات مهم

در زیر تعداد خطوط حاوی رشته‌های فارسی هاردکدشده در فایل‌های اصلی به ترتیب فراوانی آمده است:

| نام فایل | تعداد خطوط حاوی رشته فارسی | مسیر فایل |
| :--- | :---: | :--- |
| `now_dashboard_screen.dart` | ۱۵۹ | `lib/features/today/presentation/now_dashboard_screen.dart` |
| `profile_screen.dart` | ۱۴۷ | `lib/features/profile/presentation/profile_screen.dart` |
| `routine_create_flow.dart` | ۱۳۷ | `lib/features/routines/presentation/routine_create_flow.dart` |
| `onboarding_screen.dart` | ۱۲۲ | `lib/features/onboarding/presentation/onboarding_screen.dart` |
| `calendar_screen.dart` | ۹۷ | `lib/features/calendar/presentation/calendar_screen.dart` |
| `insights_screen.dart` | ۹۴ | `lib/features/today/presentation/insights_screen.dart` |
| `cycle_harmony_screen.dart` | ۸۸ | `lib/features/profile/presentation/cycle_harmony_screen.dart` |
| `routines_list_screen.dart` | ۷۶ | `lib/features/routines/presentation/routines_list_screen.dart` |
| `realm_management_sheet.dart` | ۵۱ | `lib/features/today/presentation/widgets/realm_management_sheet.dart` |
| `konkur_dashboard_screen.dart` | ۵۰ | `lib/features/konkur/presentation/konkur_dashboard_screen.dart` |
| `systems_hub_screen.dart` | ۴۵ | `lib/features/today/presentation/systems_hub_screen.dart` |
| `routine_form_screen.dart` | ۴۳ | `lib/features/routines/presentation/routine_form_screen.dart` |
| `worship_seasons_sheet.dart` | ۳۹ | `lib/features/profile/presentation/widgets/worship_seasons_sheet.dart` |
| `assistant_chat_screen.dart` | ۳۱ | `lib/features/assistant/presentation/assistant_chat_screen.dart` |

---

## تحلیل وضعیت بومیسازی و گام‌های بعدی لوکالیزیشن (L10N)

با توجه به تسک‌های ۱۱ و ۱۲:
1. **داشبورد و روتین‌ها (تسک ۱۱)**:
   رشته‌های فارسی هاردکدشده در صفحات `now_dashboard_screen.dart` و ابزارها/ویجت‌های متصل به آن استخراج خواهند شد.
2. **فایل‌های ARB**:
   رشته‌های استخراج‌شده به فایل‌های `lib/l10n/app_fa.arb` و `lib/l10n/app_en.arb` منتقل خواهند شد.
3. **فعالسازی انتخاب زبان انگلیسی در پروفایل (تسک ۱۲)**:
   در فایل `profile_screen.dart` بخش تنظیمات زبان از حالت غیرفعال (به زودی) خارج شده و قابلیت تغییر لوکال برنامه را پیاده‌سازی خواهد کرد.
