# گزارش اجرای پرامپت ۰۲۶ — تجمیع ماژول ورزش و بازطراحی داشبورد

---

## 🟢 خلاصه دستاوردها

### ۱. انتقال کامل لایهٔ حرکت (Movement Layer)
- انتقال فیزیکی پوشه از `lib/features/sports/movement/` به `lib/features/supplementary_sports/movement/`.
- به‌روزرسانی تمام importهای پروژه به مسیر جدید `supplementary_sports/movement/`.

### ۲. ارتقای سرویس آمادگی (`SSReadinessService`)
- ایجاد `SSReadinessService` جهت سنجش میزان آمادگی روزانه کاربر (ترکیب خواب، کوفتگی و خستگی) و تعیین Tier پیشنهادی (`full`, `light`, `minimal`, `rest`).

### ۳. ارتقای داشبورد به ۴ تب (`SSHomeDashboardScreen`)
- **تب ۰ — امروز**: شامل هدر، بنر آمادگی بدنی، کارت اصلی شروع تمرین قدرتی، حلقه بودجهٔ حرکت و نوار تداوم.
- **تب ۱ — برنامه**: مدیریت برنامه‌های قدرتی (`SSPlanOverviewScreen`).
- **تب ۲ — حرکت (جدید)**: صفحهٔ جامع لایهٔ حرکت (`SSMovementTabScreen`) شامل حلقه بودجه، پیشنهادهای هوشمند، دکمه ثبت سریع ⚡، تایم‌لاین این هفته و لینک تحلیل کامل.
- **تب ۳ — پیشرفت**: آمار پیشرفت قدرتی و حرکتی (`SSProgressScreen`).

### ۴. رفع رگرسیون‌های ۰۲۵ و مهاجرت schema V54
- پیاده‌سازی `MovementCompletion` در `CompletionGateway`.
- افزودن رویداد `completionRecorded` به `RitmoEventType`.
- ارتقای `ActionRouter` برای باز کردن کانونی `showMovementLogSheet`.
- ارتقای دیتابیس به **نسخهٔ ۵۴ (`MigrationV54`)** جهت مهاجرت داده‌های `workout_split_days` به `ss_user_profile` و حذف جداول اضافه/موازی.

### ۵. پاکسازی کامل پوشهٔ قدیمی
- حذف کامل پوشهٔ `lib/features/sports/` و اصلاح تمام ارجاعات یتیم در پروژه.

---

## 🧪 وضعیت تحلیل استاتیک
- اجرای `flutter analyze` بدون هیچ‌گونه خطا یا هشدار.
