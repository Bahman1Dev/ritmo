# ADR 0007: تجمیع ماژول ورزش در ورزش تکمیلی و حرکت (Supplementary Sports Consolidation)

## تاریخ
۲۵ ژوئیه ۲۰۲۶

## وضعیت
پذیرفته‌شده (Accepted)

## زمینه (Context)
ماژول قدیمی `sports` (مبتنی بر `sports_screen.dart` و `workout_split_days`) به‌صورت مرده و یتیم در پروژه باقی مانده بود و UI جدید لایهٔ حرکت (پرامپت ۰۲۴) روی آن قرار گرفته بود بدون اینکه از هاب سیستم‌ها قابل دسترس باشد. در مقابل، ماژول `supplementary_sports` دارای موتور کامل برنامه‌ریزی قدرتی، انیمیشن‌ها، صدا و تایمر هوشمند بود.

## تصمیم (Decision)
۱. کل لایهٔ حرکت (`Movement Layer`) شامل ریپازیتوری، شیت کانونی، انالوگ بودجه و تحلیل از `features/sports/movement/` به `features/supplementary_sports/movement/` منتقل گردید.
۲. منطق ارزیابی آمادگی روزانه به `SSReadinessService` منتقل شد.
۳. داشبورد `SSHomeDashboardScreen` به یک داشبورد ۴تبی (امروز، برنامه، حرکت، پیشرفت) ارتقا یافت.
۴. پوشهٔ `lib/features/sports/` به‌طور کامل حذف گردید.
۵. دیتابیس طی `MigrationV54` داده‌های قدیمی split را به `ss_user_profile` مهاجرت داد و جدول `workout_split_days` و جدول موازی `ss_workout_set_log` را DROP نمود.

## عواقب (Consequences)
- صفر کد مرده در حوزهٔ ورزش.
- دسترسی کامل کاربر به لایهٔ حرکت، بودجهٔ MET-min و تمرینات قدرتی از هاب «ورزش و حرکت».
- حفظ کامل داده‌های قبلی کاربر.
