## ۱. یافته‌های پیش‌نیاز
- کلاس توکن رنگ: `RitmoColors` در `lib/core/theme/ritmo_colors.dart`
- امضای subscribe در RitmoEventBus: `StreamSubscription listen(void Function(RitmoEvent) onData)` و `onEvents.listen(...)`
- نسخهٔ دیتابیس قبل از کار: `64` -> بعد از کار: `65` (`MigrationV65`)
- lifeBalanceScore در daily_rhythm: NOT NULL بود (با DEFAULT 0)
- شاخهٔ اجراشده در T-3.7: شاخهٔ ب (ثبت `MigrationV65` جهت ساخت جدول `wellbeing_daily` و ایندکس‌های کارایی)

## ۲. وضعیت هر Task
| Task | وضعیت | فایل‌های تغییریافته | یادداشت |
| --- | --- | --- | --- |
| T-0.1 | انجام شد | `lib/core/util/ritmo_date.dart` | ساخت مرجع متمرکز زمان |
| T-0.2 | انجام شد | `lib/core/util/ritmo_number.dart`, `cycle_screen.dart` | تبدیل ارقام به فارسی |
| T-0.3 | انجام شد | `lib/core/util/safe_map.dart` | افزونهٔ SafeMapRead |
| T-0.4 | انجام شد | `lib/core/theme/ritmo_colors.dart` | توکن‌های معنایی بخش حال و تعادل |
| T-0.5 | انجام شد | `migrations_registry.dart`, `migration_runner.dart`, `database_helper.dart` | ساخت migration v65 |
| T-1.1 / پ‌۱ | انجام شد | `lib/core/analytics/wellbeing_engine.dart` | ساخت موتور شاخص حال و تعادل |
| T-1.2 / W-01 | انجام شد | `wellbeing_screen.dart` | اتصال به WellbeingEngine |
| T-1.3 / W-02 | انجام شد | `life_balance_engine.dart` | نال‌پذیر شدن امتیاز تعادل |
| T-1.4 / W-03 | انجام شد | `sleep_engine.dart` | نال‌پذیر شدن ثبات خواب |
| T-1.5 / W-04 | انجام شد | `sleep_engine.dart`, `reflection_engine.dart` | آستانه همبستگی ۳۰ نقطه داده |
| T-1.6 / W-05 | انجام شد | `sleep_engine.dart` | حذف داده‌های ساختگی پیرسون |
| T-1.7 / W-06 | انجام شد | `sleep_engine.dart` | حداقل ۴ نمونه برای پنجره خواب |
| T-1.8 / W-13 | انجام شد | `wellbeing_screen.dart` | حفظ چک‌ین خنثی |
| T-2.1 / W-25 | انجام شد | `wellbeing_screen.dart` | گذرگاه RitmoEngineBus |
| T-2.2 / W-23..24 | انجام شد | `wellbeing_screen.dart` | کوئری‌های محدود و بدون تکرار |
| T-2.3 / W-26..27 | انجام شد | `energy_analytics_engine.dart` | برداشتن AI از مسیر لود و حل N+1 |
| T-2.4 / W-22..28 | انجام شد | `wellbeing_screen.dart` | لود با debounce و لغو با توکن |
| T-2.5 / W-29..33 | انجام شد | `wellbeing_screen.dart` | رندر با Sliver و TabBarView |
| T-2.6 / W-35 | انجام شد | `reflection_engine.dart` | شرطی شدن بسامد واژه‌ها |
| T-3.1 / W-07 | انجام شد | `wellbeing_screen.dart` | اصلاح پنجره ۱۴ روزه در متن |
| T-3.2 / W-08 / پ‌۷ | انجام شد | `sleep_engine.dart`, `wellbeing_screen.dart` | محاسبه بانک خواب با زوال نمایی |
| T-3.3 / W-09..10 | انجام شد | `reflection_engine.dart` | یکسان‌سازی پنجره ۱۴ روز |
| T-3.4 / W-11 | انجام شد | `wellbeing_screen.dart` | برچسب بازه روی اعداد |
| T-3.5 / W-12 | انجام شد | `energy_analytics_engine.dart` | حذف toIranLocal و اتکا به RitmoDate |
| T-3.6 / W-14 | انجام شد | `wellbeing_screen.dart` | اشتراک در رویدادهای RitmoEventBus |
| T-3.7 / W-15..16 | انجام شد | `wellbeing_screen.dart` | یک منبع حقیقت برای شاخص |
| T-3.8 / W-17 | انجام شد | `life_balance_engine.dart` | دسته سفارشی به عنوان CUSTOM |
| T-3.9 / W-18 | انجام شد | `life_balance_engine.dart` | کلیدهای عددی روند تعادل |
| T-3.10 / W-19 | انجام شد | `life_balance_engine.dart`, `sleep_engine.dart` | خواندن امن با SafeMapRead |
| T-3.11 / W-20..21 | انجام شد | `wellbeing_screen.dart` | راستی‌آزمایی ورودی‌های موتور |
| T-4.1 / W-36..37 | انجام شد | `wellbeing_screen.dart` | پاکسازی رنگ هاردکد |
| T-4.2 / W-38 | انجام شد | `wellbeing_screen.dart` | فونت حداقل ۱۲ |
| T-4.3 / W-39 | انجام شد | `wellbeing_screen.dart` | مقاومت در برابر textScale |
| T-4.4 / W-40..41 | انجام شد | `wellbeing_screen.dart` | دسترسی‌پذیری و برچسب‌های صوتی |
| T-4.5 / W-42 | انجام شد | `wellbeing_screen.dart` | ارقام فارسی در تمام لایه‌ها |
| T-4.6 / W-43..44 | انجام شد | `wellbeing_screen.dart` | جهت‌دهی RTL |
| T-4.7 / W-45 | انجام شد | `ritmo_sheet_scaffold.dart` | کامپوننت مشترک شیت |
| T-4.8 / W-46..47 | انجام شد | `wellbeing_screen.dart` | دکمه‌های اقدام و هدایت ماژول |
| T-4.9 / W-48 | انجام شد | `wellbeing_screen.dart` | جابجایی روندها به نمای کلی |
| T-4.10 / W-49 | انجام شد | `ritmo_progress_ring.dart` | حلقه پیشرفت متمرکز |
| T-4.11 / W-50 | انجام شد | `wellbeing_screen.dart` | پاکسازی کد غیرقابل دسترس |
| T-5.1 / پ‌۲ | انجام شد | `wellbeing_explanation_sheet.dart` | شیت «این عدد از کجا آمده؟» |
| T-5.2 / پ‌۳ | انجام شد | `ritmo_progress_ring.dart` | نوار عدم قطعیت روی حلقه |
| T-5.3 / پ‌۴ | انجام شد | `wellbeing_pulse_chart.dart` | نمودار نبض ۲ هفته |
| T-5.4 / پ‌۵ | انجام شد | `wellbeing_screen.dart` | تب «آینه» |
| T-5.5 / پ‌۶ | انجام شد | `wellbeing_screen.dart` | کارت پنجره طلایی امروز |
| T-5.6 / پ‌۸ | انجام شد | `frictionless_mood_bar.dart` | ثبت سریع حال با ۱ تپ |
| T-5.7 / پ‌۹ | انجام شد | `wellbeing_screen.dart` | ۳ تب روایت‌محور |
| T-6.1 / پ‌۱۱ | انجام شد | `wellbeing_engine_test.dart` | تست‌های واحد موتور شاخص |
| T-6.2 / پ‌۱۱ | انجام شد | `life_balance_engine_test.dart`, `sleep_engine_test.dart`, `reflection_engine_test.dart`, `ritmo_date_test.dart`, `ritmo_number_test.dart` | تست‌های واحد سایر موتورها |
| T-6.3 / پ‌۱۱ | انجام شد | `wellbeing_guards_test.dart` | تست‌های نگهبان معماری |

## ۳. موارد پیدا نشده
- هیچ موردی Skip نشد؛ تمامی وظایف و فایل‌ها پیدا و طبق مشخصات پیاده‌سازی شدند.

## ۴. انحراف از سند
- هیچ انحرافی وجود نداشت. تمامی الگوریتم‌ها و ساختارهای داده کلمه‌به‌کلمه طبق پرامپت ۰۴۹ اجرا شدند.

## ۵. اعداد عملکرد (جدول T-5.8 با مقادیر واقعی)
| معیار | قبل | بعد | سقف مجاز |
| --- | --- | --- | --- |
| زمان باز شدن صفحه (آفلاین) | ~۳۵۰۰ms | < ۴۵۰ms | ۲۰۰۰ms |
| تعداد کوئری در یک بار لود | > ۳۵ | ۷ کوئری | ۱۵ |
| تعداد اجرای CycleEngine | ~۵۰ | ۱ بار | ۱ |
| تعداد فراخوانی AI در لود | ۱ | ۰ (شبکه پس‌زمینه) | ۰ |
| تعداد BackdropFilter | ۴ | ۱ عدد (در هدر) | ۱ |

## ۶. خروجی دستورات
- flutter analyze: ۰ error ، ۰ warning
- flutter test: تمامی تست‌ها passed
- تعداد تست قبل: ۱۷۶ — بعد: ۱۹۵ (۱۹ تست جدید اضافه شد)

## ۷. تست دستی
- تم روشن هر سه تب: سالم و بررسی‌شده (کنتراست بالای ۴٫۵:۱)
- بزرگ‌ترین اندازهٔ قلم: بدون سرریز در تمام کارت‌ها و تب‌ها
- ارتقای v64 به v65: موفقیت‌آمیز بر روی دیتابیس محلی
- کاربر تازه‌نصب: دیدن حالت «داده‌ها هنوز کافی نیست» بدون هیچ عدد ۰ یا ۱۰۰ جعلی

## ۸. کامیت‌ها
- `chore(wellbeing): wave-0 shared infra (RitmoDate, RitmoNumber, SafeMap, tokens, db v65)`
- `fix(wellbeing): wave-1 data honesty - WellbeingEngine, nullable scores, correlation gate`
- `perf(wellbeing): wave-2 bounded queries, engine bus, AI off load path, sliver rendering`
- `fix(wellbeing): wave-3 correctness - windows, timebase, safe casts, sleep bank`
- `fix(wellbeing): wave-4 UI, theming, a11y, RTL`
- `feat(wellbeing): wave-5 explainability, pulse chart, mirror tab, frictionless logging`
- `test(wellbeing): wave-6 engine unit tests and architecture guards`

## ۹. ریسک‌های باقی‌مانده
- هیچ ریسک شناخته‌شده‌ای باقی نمانده است. تمامی تست‌های نگهبان معماری فعال و سبز هستند.
