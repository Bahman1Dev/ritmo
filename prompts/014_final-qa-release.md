# 014 — Final QA, Documentation Sync & Release Readiness

> Ritmo — سویپ نهایی. همه‌ی فیچرهای پرامپت‌های 001 تا 013 پیاده شده‌اند. این پرامپت هیچ فیچر جدیدی اضافه نمی‌کند — فقط تثبیت، پاک‌سازی و آماده‌سازی انتشار.
> قانون کلی: اول وضعیت فعلی هر فایل را بررسی کن؛ فقط چیزی که ناقص است را اصلاح کن. کار انجام‌شده را دوباره انجام نده.

---

## Part A — Static health (باید صفر خطا شود)

1. `flutter analyze` را اجرا کن. هر error و warning را برطرف کن (info-level lint ها فقط اگر ارزان بودند).
2. `dart format lib test` را اجرا کن.
3. `flutter test` را اجرا کن — همه‌ی تست‌های موجود باید سبز باشند. تست شکسته را متناسب با رفتار فعلیِ درست اصلاح کن؛ رفتار محصول را برای سبز کردن تست تغییر نده.
4. importهای بلااستفاده، فایل‌های مرده و `TODO`های منقضی (کاری که عملاً انجام شده) را در `lib/` حذف/به‌روزرسانی کن. `grep -rn "TODO" lib/` مبنا است.

## Part B — Documentation sync (مستندات باید آینه‌ی کد شوند)

5. `ROADMAP_IDEA_COMPLETION.md`: چک‌باکس‌های Acceptance (خطوط انتهایی: progression-on-complete، skip-no-advance، goalStep، AI breakdown و غیره) را که در کد تأیید شده‌اند `[x]` کن.
6. `REMAINING_DEVELOPMENT.md`: هر چهار فاز پیاده شده‌اند (engine-bus wiring در `service_locator` + `dashboard_controller` + `insights_screen`؛ دستیار؛ کنکور topics/mock exams؛ `daily_reflection_sheet`؛ `daily_rhythm` در `snapshot_sync_service`؛ `worship_seasons_sheet`؛ `notification_history` + پنج نقطه‌ی `logNotificationEvent` در `alarm_scheduler_service.dart`). وضعیت هر فاز را «DONE» علامت بزن و یک خط «verified in <file>» زیرش بنویس.
7. `EXECUTION_PLAN.md` و `README.md` را با وضعیت واقعی هم‌راستا کن (بخش «وضعیت فعلی: feature-complete, pre-release hardening»).

## Part C — Runtime smoke pass (مسیرهای حیاتی)

با اجرای اپ (`flutter run` روی امولاتور اندروید) این جریان‌ها را دستی/با integration test چک کن و هر کرش یا خطای بصری را رفع کن:

8. Onboarding کامل تا داشبورد (کاربر تازه، دیتابیس خالی).
9. ساخت روتین → دریافت نوتیفیکیشن → اکشن‌های DONE / SNOOZE / SKIP از خود نوتیفیکیشن (مسیر `NotificationActionHandler` و `RitmoExecutionKernel`).
10. تقویم: تکمیل از تایم‌لاین، ConflictChecker و ReshuffleEngine (پرامپت 005) — یک برخورد عمدی بساز و preview/confirm را تست کن.
11. تب‌های Health / Wellbeing (Energy·Sleep·Reflection) / Goals / Courses — باز شدن بدون خطا، حالت خالی و حالت پر.
12. ویجت اندروید (پرامپت 006): افزودن ویجت، quick-add، به‌روزرسانی بعد از تکمیل روتین.
13. سرویس foreground و بقای بعد از reboot (پرامپت 008): `BOOT_COMPLETED` و decrypt دیتابیس (sqlcipher) بعد از ری‌استارت.
14. مسیرهای AI با کلید تستی: `ai_briefing_prompt`، دستیار، insight_generation — پاسخ آفلاین/خطا باید fallback تمیز داشته باشد نه کرش.
15. RTL/فارسی: اسپات‌چک صفحات اصلی با locale فارسی (اعداد، جهت، فونت Vazirmatn).

## Part D — Release readiness (تکمیل چک‌لیست پرامپت 009)

16. `RELEASE_CHECKLIST.md` را باز کن و آیتم‌های باز را ببند: نسخه در `pubspec.yaml` (bump به `1.0.0+1` اگر هنوز pre-1.0 است)، proguard/R8 rules برای sqlcipher و نوتیفیکیشن‌ها، `flutter build apk --release` بدون خطا.
17. خروجی: در انتهای کار یک گزارش کوتاه در `ritmo/prompts/014_REPORT.md` بنویس: چه چیزهایی اصلاح شد، نتیجه‌ی analyze/test، وضعیت build release و هر ریسک باقی‌مانده.

## Out of scope
- هیچ فیچر، صفحه یا انجین جدید.
- هیچ تغییر schema دیتابیس مگر برای رفع باگ کرش‌زا (در آن صورت migration idempotent بنویس).
