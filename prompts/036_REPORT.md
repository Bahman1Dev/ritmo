# گزارش اجرای پرامپت ۰۳۶ — یکپارچه‌سازی پنجره‌های کنش و رفع باگ نیت انجام

## خلاصه نتایج و دستاوردها

۱. **رفع کامل باگ بسته شدن زودهنگام (Premature Pop Bug):**
   - در ویجت `routine_niyyah_sheet.dart` و پوسته جدید `ritmo_action_sheet.dart` دستور `Navigator.pop` به بعد از اتمام موفقیت‌آمیز تابع `onSubmit` منتقل شد.
   - اضافه شدن محافظ `_busy` علیه دوبارزدن همزمان و نمایش Indicator در حال اجرا داخل دکمه‌ها.

۲. **معماری «یک پوسته، سه رفتار، N محتوا»:**
   - **اسکلت یکتا:** `RitmoSheetScaffold` ساخت و پیاده‌سازی شد.
   - **رفتار کنش:** `RitmoActionSheet` با گرامر ۵ ناحیه‌ای و مدیریت خطای داخل بدنه بازنویسی گردید.
   - **رفتار انتخاب:** `RitmoPickerSheet` جنریک بدون دسترسی به دیتابیس پیاده‌سازی شد.
   - **رفتار فرم:** `RitmoFormSheet` چندمرحله‌ای ساخته شد.

۳. **قراردادها و تایپ‌ها:**
   - تعریف `ActionSheetResult`, `HandoffIntent`, `SubmitAction`, `HandoffAction`, `ActionCapabilities`, `ActionSheetRegistry`.

۴. **اصلاح داده عبادات و نماز:**
   - ثبت تاریخ‌دار عبادات در دیتابیس از طریق `WorshipCompletionRepository` و جدول `worship_completions`.
   - ایجاد `PrayerCompletion` و اضافه کردن آن به `CompletionGateway`.
   - ایجاد `PrayerActionBody` با نوار فضیلت، چیپ‌های کیفیت و کنش «ثبت قضا».

۵. **مهاجرت ناوبری و مسیر کنکور:**
   - انتقال دستور «به فردا منتقل کن» به `RoutineReschedule`.
   - تبدیل `ProfileScreen` به یک مسیر صفحه مستقل با `MaterialPageRoute` (خروج از BottomSheet).

## جدول متریک قبل و بعد

| سنجه | قبل | بعد | هدف |
| --- | --- | --- | --- |
| باگ pop پیش از کنش | دارد | **صفر (کاملاً رفع شد)** | ۰ |
| پوسته شیشه‌ای یکتا | پراکنده | **RitmoSheetScaffold** | ۱ |
| گرامر ۵ ناحیه‌ای کنش | ندارد | **RitmoActionSheet** | پیاده شد |
| قراردادهای تایپ‌شده | نداشت | **کامل** | ۱۰۰٪ |
