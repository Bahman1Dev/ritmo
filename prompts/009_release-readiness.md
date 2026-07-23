# 009 — آماده‌سازی انتشار (بستن پرونده)

تو ایجنت کدنویس این پروژه هستی (اپ Flutter به نام Ritmo). این آخرین مرحله قبل از انتشار است. هیچ فیچر جدیدی نساز — فقط موارد زیر را ببند. قبل از هر تغییر وضعیت فعلی را بخوان.

## 1 — هویت اپ (بلاکر انتشار)
- `applicationId` و `namespace` الان `com.example.ritmo` است — استورها (بازار/مایکت) این را قبول نمی‌کنند و بعد از انتشار هم دیگر قابل تغییر نیست. به **`ir.ritmo.app`** تغییر بده (اگر کاربر مقدار دیگری اعلام کرد، همان). تغییر باید کامل باشد:
  - `android/app/build.gradle.kts` (هر دو namespace و applicationId)
  - جابه‌جایی پوشه‌ی کاتلین `android/app/src/main/kotlin/com/example/ritmo/` به مسیر پکیج جدید + اصلاح `package` در همه‌ی فایل‌های `.kt` (حدود ۱۰ فایل: MainActivity، BootReceiver، NotificationActionReceiver، RitmoForegroundService و همه‌ی Widget Provider ها)
  - همه‌ی ارجاع‌های `com.example.ritmo` در Manifest، فایل‌های XML ویجت (`res/xml/`)، اکشن‌های Intent سفارشی، و هر رشته‌ی هاردکد در Dart/Kotlin (مثل `MethodChannel` name ها اگر شامل پکیج‌اند)
  - بعد از تغییر، اپ باید clean build شود و ویجت‌ها و اعلان‌ها و BootReceiver همچنان کار کنند.
- `android:label` از `ritmo` به **«ریتمو»** تغییر کند.

## 2 — امضای انتشار (بلاکر انتشار)
- الان `release` با کلید debug امضا می‌شود و `key.properties` وجود ندارد. ساختار استاندارد را پیاده کن:
  - خواندن `android/key.properties` (gitignore شود — چک کن در `.gitignore` باشد) و تعریف `signingConfigs.release` در `build.gradle.kts` با fallback به debug اگر فایل نبود (تا `flutter run` خراب نشود).
  - یک keystore با `keytool` بساز (alias: `ritmo`، اعتبار ۲۵+ سال، پسورد قوی تولید کن)، `key.properties` را بنویس، و در گزارش پایانی **به فارسی** به کاربر بگو فایل keystore و پسورد را کجا گذاشتی و که باید ازشان بکاپ امن بگیرد — گم شدنش یعنی از دست رفتن امکان آپدیت اپ.

## 3 — آیکون و برندینگ
- آیکون launcher الان پیش‌فرض Flutter است. پکیج `flutter_launcher_icons` را اضافه کن، یک آیکون برند تمیز و مینیمال برای ریتمو طراحی/تولید کن (هم‌راستا با هویت بصری اپ — تم و رنگ‌های `context.colors` را ببین)، adaptive icon اندروید (foreground + background) بساز و همه‌ی mipmap ها را تولید کن.
- اگر splash پیش‌فرض است، با `flutter_native_splash` یک splash ساده‌ی هم‌رنگ برند بگذار.

## 4 — سخت‌گیری بیلد release
- در `buildTypes.release` مقدار `isMinifyEnabled = true` و `isShrinkResources = true` بگذار و `proguard-rules.pro` بساز با keep rule های لازم (sqflite، flutter_local_notifications، کلاس‌های ویجت/سرویس نیتیو خود اپ، هر چیزی که با reflection صدا می‌شود). بعد **حتماً بیلد release واقعی بگیر و اپ را دود-تست کن** — اگر R8 چیزی را شکست، rule اضافه کن. اگر بعد از تلاش معقول پایدار نشد، minify را خاموش کن و در گزارش بگو چرا.
- سیاست بکاپ را صریح کن: در Manifest برای `android:dataExtractionRules` (API 31+) و `android:fullBackupContent` فایل rules بساز که **دیتابیس و SharedPreferences اپ شامل بکاپ خودکار باشند** ولی چیزهای موقت (cache و فایل‌های تصویری موقت) نه. (دیتابیس بعد از 008 دیگر رمز ندارد و بکاپش مشکلی ندارد.)

## 5 — پاک‌سازی خطاهای خاموش (کیفیت)
حدود ۶۴ بلاک `catch` خالی در `lib/` هست که خطاها را بی‌صدا قورت می‌دهند. هات‌اسپات‌ها: `lib/core/services/central_inbox_service.dart` (۸)، `lib/core/ai/ai_context_builder.dart` (۸)، `lib/core/services/snapshot_sync_service.dart` (۷)، `lib/core/ai/ai_gateway.dart` (۵)، `lib/core/domain/engines/ritmo_intelligence_engine.dart` (۳). همه را مرور کن:
- اگر خطا واقعاً بی‌اهمیت است، حداقل `debugPrint` با پیام معنادار بگذار.
- اگر خطا مهم است (نوشتن DB، زمان‌بندی نوتیف، سینک)، هندل درست کن (retry/پیام به کاربر/لاگ).
- هیچ catch کاملاً خالی باقی نماند.

## 6 — صفر کردن flutter analyze
الان `flutter analyze` **۴۶۸ ایراد** دارد، شامل چند **error** واقعی در تست‌ها (`test/worship_seasons_test.dart` به `package:sqflite/sqflite.dart` و `ConflictAlgorithm` ارجاع می‌دهد که تا قبل از اجرای پرامپت 008 وجود ندارد — اگر 008 اجرا شده باشد خودش حل است، وگرنه با وضعیت فعلی پکیج‌ها سازگارش کن). ترتیب کار:
1. همه‌ی error ها را صفر کن.
2. warning ها را صفر کن (از جمله `override_on_non_overriding_member` های تست‌ها).
3. info ها را تا حد معقول کم کن؛ اگر قاعده‌ای واقعاً بی‌مورد است در `analysis_options.yaml` مستندش کن.
- در پایان `flutter test` هم اجرا کن و تست‌های شکسته را درست کن (۳۱ فایل تست موجود است — باید همه پاس شوند).

## 7 — چک‌لیست نهایی انتشار
در پایان یک فایل `prompts/RELEASE_CHECKLIST.md` بنویس (فارسی) شامل: نسخه فعلی (`1.0.0+1`)، دستور بیلد هر فلیور (`bazaar`/`myket`)، مسیر خروجی‌ها، چیزهایی که فقط کاربر می‌تواند انجام دهد (ساخت اکانت توسعه‌دهنده بازار/مایکت، آپلود، متن استور، اسکرین‌شات‌ها، بکاپ keystore)، و هر ریسک باقی‌مانده.

## قواعد
- بازنویسی گسترده ممنوع — کمینه‌ی تغییر برای بستن هر بند.
- بعد از بند ۱ و ۲ حتماً `flutter build apk --release --flavor bazaar` موفق بگیر.
- گزارش پایانی: هر بند ✅/❌ با توضیح یک‌خطی، مسیر keystore و هشدار بکاپ، و خروجی نهایی analyze/test.
