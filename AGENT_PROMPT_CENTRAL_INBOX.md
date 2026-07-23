# 🤖 پرامپت اجرایی — «مرکز یادآوریِ متمرکز» (Central Inbox / Reminder Hub) — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ H1…H9 را یک‌سره تا آخر اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: یک **خطِ تجمیعِ واحد** بساز که همهٔ سیستم‌ها (روتین/یادآوری، بینش، milestone، هشدارهای حیاتی، پیشنهادهای دستیار، چک‌این/بازتاب) رویدادهایشان را به آن می‌فرستند؛ سپس در سطوحِ اصلیِ اپ (نبض زندگی، بینش، یک Hubِ اعلان با بدج) نمایش داده شوند. هر آیتم به منبعش deep-link دارد.

## ⛔️ قواعد (یک‌بار)
- معماری: Flutter مغز/UI. یک منبعِ حقیقتِ واحد برای آیتم‌های قابل‌نمایش؛ سیستم‌ها فقط push می‌کنند.
- منطقِ موجود را نشکن: `notification_history` (لاگِ آماری) و `pending_reminders` (منبعِ آلارم) و `assistant_suggestions` سرِ جایشان می‌مانند. این Inbox یک **لایهٔ نمایشیِ تجمیعی** است، نه جایگزینِ آن‌ها.
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ شمسی در نمایش. رنگ/اندازه از `RitmoTheme`/`context.colors`؛ هاردکد نکن.
- فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.

## 📁 محیط (تأییدشده از کد)
- سطوحِ اصلی (۵ تب در `home_navigation_shell.dart`): `SystemsHubScreen` (قلمروها، index 0)، `InsightsScreen` (بینش، 1)، `NowDashboardScreen` (نبض زندگی، 2)، `RoutinesListScreen` (3)، `CalendarScreen` (4).
- `NowDashboardScreen` (`lib/features/today/presentation/now_dashboard_screen.dart`) از قبل `_buildCriticalAlertsSection()` (خط ~۳۱۰۴) و `_buildCheckinReminderCard()`/`_buildReflectionSuggestionCard()` دارد — اینجا جای طبیعیِ فیدِ مرکزی است.
- `InsightsScreen` (`lib/features/today/presentation/insights_screen.dart`) با `RitmoEngineBus.execute(InsightGenerationEngine,...)` بینش‌ها را می‌گیرد.
- رویدادها: `RitmoEventBus` (singleton، `fire(RitmoEvent{type,timestamp,payload})` + `onEvents` stream) در `lib/core/domain/engines/ritmo_event_bus.dart`.
- جداولِ موجودِ مرتبط: `notification_history(routineId,notificationType,sentAt,actionTaken)`، `assistant_suggestions(title,body,suggestionType,status,createdAt)`، `pending_reminders`.
- نسخهٔ فعلیِ DB از `database_helper.dart` (`version: 23`). الگوی مهاجرت: تابعِ `_migrateToVNN` + شاخهٔ `if (oldVersion < NN)` در `onUpgrade` + هم‌تراز در `_createDB`. `_safeAddColumn` موجود است.

## 🔒 تصمیم‌های قطعی
- **یک جدولِ واحد `inbox_items`** به‌عنوان فیدِ تجمیعی. **این جدول فقط «لایهٔ نمایشیِ رویداد» است، نه منبعِ حقیقت** — داده را تکرار نمی‌کند، فقط به منبع اشاره می‌کند (ضدِ «God Table»). متنِ آیتم کوتاه؛ هیچ analytics/cache/state اصلی اینجا نگه‌داری نمی‌شود.
- **یک سرویسِ واحد `CentralInboxService`** که تنها نقطهٔ ورود برای push/خواندن/علامت‌خواندن است؛ همهٔ سیستم‌ها از همین عبور می‌کنند.
- **لایهٔ گاردِ اجباری `InboxPolicy`** بینِ سیستم‌ها و جدول: بدونِ عبور از Policy هیچ push نشود (ضدِ spam). شاملِ فیلترِ معناداری + سقفِ نرخ + سازندهٔ dedupeKeyِ قوی.
- **چرخهٔ حیات:** `UNREAD → READ → ARCHIVED → EXPIRED`. هر آیتم `expiresAt` دارد و پس از انقضا/کهنگی جارو می‌شود (retention).
- **deep-link ساختاریافته** (نه route خام): `{linkModule, linkEntityId, linkAction}` تا با تغییرِ مسیرها نشکند.
- نمایش در سه نقطه: (۱) بدج + Hubِ اعلان قابل‌دسترسی از همهٔ تب‌ها، (۲) خلاصهٔ بالای نبض زندگی، (۳) آیتم‌های نوع `INSIGHT` در صفحهٔ بینش.
- چرخه: هیچ آیتمی با محتوای صریحِ چرخه در Inbox عمومی نوشته نشود (یادآورهای خصوصیِ چرخه با متنِ غیرمستقیمِ موجود خودشان می‌مانند).

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**H1 — مهاجرت + جدول.** نسخهٔ DB = فعلی+۱. در `_createDB` و تابعِ مهاجرتِ جدید (`CREATE TABLE IF NOT EXISTS`):
```sql
CREATE TABLE inbox_items (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,         -- REMINDER, INSIGHT, MILESTONE, ALERT, SUGGESTION, CHECKIN, REVIEW
  sourceSystem TEXT NOT NULL,     -- routines, goals, konkur, courses, sleep, energy, worship, health, assistant, reflection, system
  title TEXT NOT NULL,
  body TEXT,
  priority INTEGER NOT NULL DEFAULT 0,   -- 0 normal, 1 important, 2 critical
  linkModule TEXT,                -- deep-link ساختاریافته: ماژول مقصد (routines, goals, ...)
  linkEntityId TEXT,              -- شناسه‌ی موجودیت مقصد
  linkAction TEXT,                -- اکشن مقصد (open_detail, open_list, ...)
  payloadJson TEXT,               -- داده‌ی اضافی اختیاری
  status TEXT NOT NULL DEFAULT 'UNREAD',  -- UNREAD, READ, ARCHIVED, EXPIRED, ACTIONED
  createdAt INTEGER NOT NULL,
  readAt INTEGER,
  expiresAt INTEGER,              -- زمان انقضا (برای retention/EXPIRED)
  dedupeKey TEXT                  -- یکتا؛ sourceSystem|entityId|eventType|dateBucket
);
CREATE INDEX idx_inbox_status ON inbox_items(status);
CREATE INDEX idx_inbox_createdAt ON inbox_items(createdAt);
CREATE UNIQUE INDEX idx_inbox_dedupe ON inbox_items(dedupeKey);
```

**H2 — مدل.** `lib/core/domain/models/inbox_item.dart`: کلاسِ `InboxItem` (با فیلدهای بالا + `linkModule/linkEntityId/linkAction`) + enumهای `InboxCategory`, `InboxPriority`, `InboxStatus` + `toMap/fromMap`. برچسب/آیکن/رنگِ فارسی برای هر category.

**H3 — لایهٔ گارد `InboxPolicy` (ضدِ spam — مهم).** `lib/core/services/inbox_policy.dart`:
- `bool shouldPush({required InboxCategory category, required int priority, required String sourceSystem})` — فیلترِ معناداری:
  - `REMINDER` → فقط `priority>=1` یا essential (روتین‌های معمولیِ روزمره فید نشوند؛ آن‌ها در صفحهٔ روتین‌اند).
  - `INSIGHT` → فقط بینشِ معنادار (نه هر snapshot).
  - `SUGGESTION` → throttle.
  - `ALERT`/`MILESTONE`/`CHECKIN`/`REVIEW` → مجاز.
- `Future<bool> withinRateLimit(InboxCategory category)` — سقفِ روزانه از روی شمارشِ `createdAt` امروز: مثلاً `INSIGHT`≤۵/روز، `SUGGESTION`≤۵/روز، `REMINDER`(فیدشده)≤۱۰/روز. مازاد رد شود.
- `String buildDedupeKey({required String sourceSystem, required String entityId, required String eventType, String? dateBucket})` → `'$sourceSystem|$entityId|$eventType|${dateBucket ?? today}'`. **همهٔ تولیدکننده‌ها از این استفاده کنند** (نه dedupeKeyِ دستی).
- `int defaultTtlDays(InboxCategory category)` → مثلاً REMINDER=۲، INSIGHT=۷، SUGGESTION=۳، ALERT=۱، MILESTONE=۳۰.

**H4 — سرویسِ مرکزی.** `lib/core/services/central_inbox_service.dart` (static methods):
- `push({required category, required sourceSystem, required entityId, required eventType, required title, body, priority=0, linkModule, linkEntityId, linkAction, payload, dateBucket})`:
  1. اگر `!InboxPolicy.shouldPush(...)` یا `!await InboxPolicy.withinRateLimit(category)` → بی‌سروصدا return.
  2. `dedupeKey = InboxPolicy.buildDedupeKey(...)`؛ `expiresAt = now + defaultTtlDays*86400000`.
  3. درج با `ConflictAlgorithm.ignore` روی `dedupeKey` (تکرار خنثی).
  4. `RitmoEventBus().fire(RitmoEvent(type:'inbox_updated', ...))`.
- `unreadCount()`، `getItems({statusFilter, limit})` (مرتب با **priority decay**: `ORDER BY` بر اساسِ نمره‌ای که از `priority` منهای کهنگیِ روز ساخته می‌شود؛ یا ساده: `ORDER BY priority DESC, createdAt DESC` ولی آیتم‌های `EXPIRED` حذف)، `markRead(id)`، `markAllRead()`، `archive(id)`، `expireOverdue()` (آیتم‌های `expiresAt < now` و غیرِ ARCHIVED → `EXPIRED`)، `purgeOld(days)`.

**H4b — اتصالِ تولیدکننده‌ها (مهم‌ترین تسک).** هرجا سیستمی رویدادِ قابل‌نمایش تولید می‌کند، یک `CentralInboxService.push(...)` اضافه کن (منطقِ موجود را حذف نکن). همه از `entityId/eventType` معنادار استفاده کنند تا dedupe قوی باشد:
- **یادآوری روتین:** در `alarm_scheduler_service.dart` کنارِ `logNotificationEvent(actionTaken:'sent')` → `push(category:REMINDER, sourceSystem:'routines', entityId: routineId, eventType:'reminder', priority: isEssential?2:0, linkModule:'routines', linkEntityId: routineId, linkAction:'open_detail')`. هنگام `opened/cancelled` → `markRead/archive`.
- **بینش:** در `InsightGenerationEngine` (یا `insights_screen.dart`) برای بینشِ معنادار → `push(category:INSIGHT, sourceSystem:'system', entityId: insightKey, eventType:'insight', linkModule:'insights', linkAction:'open_list')`.
- **Milestone:** مسیرِ `MilestoneEngine` → `push(category:MILESTONE, entityId: milestoneId, eventType:'milestone', priority:1)`.
- **هشدارِ حیاتی:** معادلِ `_buildCriticalAlertsSection` → `push(category:ALERT, priority:2, eventType:'critical_alert')`.
- **پیشنهادِ دستیار:** هنگام درجِ `assistant_suggestions` با `status='PENDING'` → `push(category:SUGGESTION, sourceSystem:'assistant', entityId: suggestionId, eventType:'suggestion', linkModule:'assistant', linkAction:'open_chat')`.
- **چک‌این/بازتاب:** `_buildCheckinReminderCard`/`_buildReflectionSuggestionCard` → `push(category:CHECKIN/REVIEW, ...)`.
- شکّ در محل دقیق → نزدیک‌ترین نقطهٔ تولید؛ Policy و dedupe بقیه را امن می‌کنند.

**H5 — صفحهٔ Hub اعلان + navigatorِ ساختاریافته.** 
- `lib/features/inbox/presentation/inbox_screen.dart`: لیست (مرتب با priority+decay، بدونِ EXPIRED)، گروهِ خوانده/نخوانده، swipe→archive، «خواندنِ همه»، empty state آرام.
- `lib/features/inbox/logic/inbox_navigator.dart`: `open(BuildContext, InboxItem)` که از `{linkModule, linkEntityId, linkAction}` به صفحهٔ درست resolve می‌کند (یک `switch` روی `linkModule`). اگر ماژول/موجودیت پیدا نشد → graceful (به تبِ مرتبط برود یا پیامِ کوتاه)، نه crash. تپ روی آیتم → `markRead` + `InboxNavigator.open`.

**H6 — بدجِ اعلان.** یک آیکنِ زنگ با بدجِ `unreadCount()` در نقطه‌ای که از همهٔ تب‌ها دیده شود (هدرِ `NowDashboardScreen` یا `home_navigation_shell`). با `RitmoEventBus.onEvents` (فیلترِ `inbox_updated`) خودش را refresh کند. تپ → `InboxScreen`.

**H7 — خلاصه در نبض زندگی.** در `NowDashboardScreen` یک بخشِ کوچکِ «آخرین یادآوری‌ها/اعلان‌ها» (۳ آیتمِ نخواندهٔ اخیر) بالای صفحه، با دکمهٔ «همه» → `InboxScreen`. از `_buildCriticalAlertsSection` استفادهٔ مجدد کن یا کنارش بگذار.

**H8 — تزریق در بینش.** در `InsightsScreen` آیتم‌های `category=INSIGHT` از Inbox را به‌عنوان «بینش‌های جدید/نخوانده» در بالای لیست نشان بده (بدونِ دوباره‌کاری با بینش‌های موتور — از `dedupeKey` برای جلوگیری استفاده کن).

**H9 — چرخهٔ حیات و نگه‌داری (lifecycle + retention).** در مسیرِ راه‌اندازی/refreshِ داشبورد (`main.dart` یا `NowDashboardScreen` init):
- `await CentralInboxService.expireOverdue()` → آیتم‌های منقضی (`expiresAt < now`، غیرِ ARCHIVED) به `EXPIRED` بروند و در فید نمایش داده نشوند.
- `await CentralInboxService.purgeOld(30)` → آیتم‌های ARCHIVED/EXPIREDِ قدیمی‌تر از ۳۰ روز حذف فیزیکی شوند (جدول God Table/بی‌نهایت‌رشد نشود).
- هنگام پاک‌کردنِ دادهٔ کاربر/خروج (هرجا `notification_history` پاک می‌شود) `inbox_items` هم پاک شود.
- چرخهٔ حالت: `UNREAD → READ → ARCHIVED → EXPIRED` (و `ACTIONED` برای آیتمی که اکشنش انجام شد).

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز.
- مهاجرتِ DB: اجرا روی نسخهٔ قبلی بدونِ خطا (sanity).
- در گزارش بنویس: (الف) کدام سیستم‌ها push می‌کنند و چطور `InboxPolicy` جلوِ spam/تکرار/مازادِ نرخ را می‌گیرد؛ (ب) بدج کجاست و چطور با `inbox_updated` refresh می‌شود؛ (پ) نمونهٔ یک REMINDER از آلارم تا فید با deep-linkِ ساختاریافته؛ (ت) رفتارِ expire/purge و اینکه آیتمِ EXPIRED در فید نیست.
