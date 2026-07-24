# ۰۲۳_REPORT — گزارش نهایی بازسازی و فعال‌سازی «ورزش تکمیلی»

## ۱. ممیزی PASS 0
- ممیزی کامل ۱۸ بند PASS 0 انجام شد و قبل از دستکاری کدها به تایید کاربر رسید.
- نسخه دیتابیس از **51** به **52** ارتقا یافت.

## ۲. جداول و ستون‌های جدید دیتابیس (MigrationV52)
- **`ss_workout_plan`**: ستون‌های `week INTEGER DEFAULT 1` و `executionMode TEXT DEFAULT 'LINEAR'`.
- **`ss_plan_schedule`**: جدول گره‌زننده پلن‌های تمرینی ورزشی به تاریخ‌های واقعی تقویم ریتمو.
- **`ss_user_profile`**: ستون‌های `programStartDate TEXT` و `deloadEveryNWeeks INTEGER DEFAULT 4`.
- **`ss_exercise_pr`**: جدول ثبت رکوردهای شخصی کاربر (`MAX_WEIGHT`, `MAX_REPS`, `MAX_VOLUME`, `MAX_DURATION`).
- **`ss_session_set_log`**: جدول ثبت ریز ست‌های انجام‌شده در هر جلسه تمرینی.

## ۳. اصلاحات شناسه و الگوی ساخت (Golden Rule & Single Source of Truth)
- افزودن شناسه‌های استاندارد ورزشی به `RitmoIdFactory` (`ssPlan`, `ssCrossRef`, `ssSession`, `ssSetLog`, `ssSchedule`, `ssPr`, `ssDecision`, `ssCustomExercise`).
- ایجاد `SSProgramCalendar` به عنوان تنها منبع محاسبه هفته فعال، روزهای شمسی و غیبت برنامه.
- ایجاد `SSProfileRepository` جهت مدیریت کش و دسترسی به پروفایل ورزشی کاربر.
- جایگزینی نوشتن مستقیم SQL روی جدول `routines` در `SSSettingsScreen` با اجرای دستورات `RitmoExecutionKernel`.

## ۴. یکی‌سازی صفحات جلسه تمرین (T4)
- صفحات موازی و تکراری `sports/presentation/workout_session_screen.dart` و `sports/presentation/screens/workout_session_screen.dart` به طور کامل با `git rm` پاک‌سازی شدند.
- تنها صفحه کانونی جلسه تمرین `SSWorkoutSessionScreen` است.

## ۵. موتور تطبیقی و استریک هوشمند (T10, T13, T15)
- الگوریتم استریک به‌روزرسانی شد تا روزهای استراحت برنامه‌ریزی‌شده (`REST`) استریک کاربر را نشکند.
- ایجاد `SSAdaptiveScheduler` جهت بازتولید هفتگی برنامه بر اساس سیگنال‌های پیشرفت (`EASY`/`HARD`) و نرخ تکمیل جلسات.
- ثبت خودکار جلسات پایان‌یافته در `workout_logs` و انتشار رویداد `RitmoEventType.workoutLogChanged`.

## ۶. شیت حرکت سفارشی (T27)
- ایجاد شیت `SSCustomExerciseSheet` جهت اضافه کردن حرکت سفارشی (`isCustom = 1`) طبق قانون طلایی تفویض.
