# Ritmo Appwrite Core Function (`ritmo-core`)

این فانکشن اکشن‌های مربوط به احراز هویت پیامکی (`otp/request` و `otp/verify`) را مدیریت می‌کند.

## متغیرهای محیطی فانکشن در Appwrite Console:

| نام متغیر | توضیح |
| :--- | :--- |
| `APPWRITE_API_KEY` | کلید سرور با دسترسی محدود به `users` و `databases` |
| `DATABASE_ID` | شناسه دیتابیس (پیش‌فرض: `ritmo_db`) |
| `SMS_API_TOKEN` | توکن REST پنل پیامکی ایرانی |
| `SMS_PATTERN_ID` | شناسه الگوی OTP در پنل پیامک |

## نحوه استقرار (Deployment):
1. پوشه `backend/functions/core` به صورت زیپ یا از طریق Appwrite CLI / GitHub Integration استقرار داده شود.
2. زمان اجرای فانکشن روی Node.js 18 یا بالاتر تنظیم شود.
