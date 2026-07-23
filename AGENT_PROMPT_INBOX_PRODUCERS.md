# 🤖 پرامپت اجرایی — «اتصالِ تولیدکننده‌های باقی‌مانده به مرکز یادآوری» — برای Gemini 3.5 Flash

> **این پرامپت خودش نقشه‌ی اجراست. بدونِ نوشتنِ Implementation Plan جداگانه، مستقیم کدنویسی کن.** فایلِ خودبسنده؛ کلِ صفِ P1…P4 را یک‌سره تا آخر اجرا کن. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی.
> هدف: تکمیلِ پوششِ مرکزِ یادآوری (`inbox_items`). چک‌این، بازتاب و هشدارِ حیاتی **از قبل وصل‌اند**؛ این مرحله **بینش‌ها، milestoneها و پیشنهادهای دستیار** را هم به Inbox می‌فرستد.

## ⛔️ قواعد (یک‌بار)
- منطقِ موجود را حذف/بازنویسی نکن؛ فقط `CentralInboxService.push(...)` اضافه کن.
- همهٔ pushها از `InboxPolicy` عبور می‌کنند (خودِ `push` این کار را می‌کند) — پس فیلترِ معناداری/نرخ/dedupe خودکار اعمال می‌شود. فقط `entityId`/`eventType` معنادار بده تا dedupe درست کار کند.
- فارسی/RTL. فقط فایل‌های مرتبط. ابهامِ واقعی → بپرس.

## 📁 محیط (تأییدشده از کد)
- `CentralInboxService.push({category, sourceSystem, entityId, eventType, title, body?, priority?, linkModule?, linkEntityId?, linkAction?, dateBucket?})` موجود است و خودش `InboxPolicy.shouldPush`/`withinRateLimit`/`buildDedupeKey` را صدا می‌زند.
- enumها: `InboxCategory.{REMINDER, INSIGHT, MILESTONE, ALERT, SUGGESTION, CHECKIN, REVIEW}`.
- **از قبل وصل (دست نزن):** در `now_dashboard_screen.dart` → `critical_alert` (INSIGHT)، `morning_checkin` (REMINDER)، `daily_reflection` (REMINDER).
- **نقاطِ تزریقِ این تسک، در `lib/features/today/presentation/insights_screen.dart`:**
  - `_milestones` (نوع `Milestone {id, title, description, progress, isUnlocked, unlockedAt}`) در `_loadData` پر می‌شود؛ یک حلقهٔ موجود `for (var milestone in _milestones)` (حوالی خط ۲۴۳) milestoneهای تازه‌آزادشده را با `unlockMilestone(...)` ثبت می‌کند — **همان‌جا** نقطهٔ ایده‌آلِ push است.
  - `_insights` (نوع `InsightResult {type(InsightType), params, sourceMetric, calculationWindow}`) حوالی خط ۲۵۳ پر می‌شود.
- `assistant_suggestions(id, title, body, suggestionType, status, createdAt)` جدولِ پیشنهادهاست (status پیش‌فرض `PENDING`).

## 🔒 تصمیم‌های قطعی
- Milestone فقط هنگامِ **تازه‌آزادشدن** فید شود (نه هر بار رندر). 
- بینش فقط برای آیتم‌های **معنادار**؛ dedupe روزانه تا با هر باز شدنِ صفحهٔ بینش تکرار نشود.
- چرخه: هیچ بینش/پیشنهادِ مرتبط با چرخه به Inbox عمومی نرود (اگر منبعی چنین چیزی تولید می‌کند، فیلتر کن).

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**P1 — Milestoneها.** در `insights_screen.dart`، داخلِ حلقهٔ موجودِ unlock (جایی که `milestone.isUnlocked && !unlockedMap.containsKey(milestone.id)` و `unlockMilestone(...)` صدا زده می‌شود)، بعد از unlock یک push اضافه کن:
```dart
await CentralInboxService.push(
  category: InboxCategory.MILESTONE,
  sourceSystem: 'milestone',
  entityId: milestone.id,
  eventType: 'milestone_unlocked',
  title: '🏆 ${milestone.title}',
  body: milestone.description,
  priority: 1,
  linkModule: 'insights',
  linkAction: 'open_list',
);
```
(چون فقط در شاخهٔ «تازه‌آزادشده» است، طبیعتاً یک‌بار فید می‌شود؛ `entityId=milestone.id` هم dedupe را تضمین می‌کند.)

**P2 — بینش‌ها.** پس از پر شدنِ `_insights` (حوالی خط ۲۵۳ به بعد)، روی بینش‌ها حلقه بزن و هر کدام را push کن:
- `entityId` پایدار بساز: `'${insight.type.name}_${insight.sourceMetric}'`.
- `eventType: 'insight'`، `dateBucket: <today yyyy-MM-dd>` (تا هر روز حداکثر یک‌بارِ هر بینش).
- `title`/`body`: از همان متنی که صفحهٔ بینش برای نمایشِ این `InsightResult` می‌سازد استفاده کن (همان helper/تابعِ رندرِ موجود را صدا بزن؛ متنِ جدید اختراع نکن).
- `category: InboxCategory.INSIGHT`، `sourceSystem: 'insight_engine'`، `linkModule: 'insights'`, `linkAction: 'open_list'`.
- `InboxPolicy` خودش نرخ/معناداری را محدود می‌کند؛ نیازی به فیلترِ دستیِ اضافه نیست، اما اگر بینش به‌وضوح کم‌اهمیت است می‌توانی skip کنی.

**P3 — پیشنهادهای دستیار.** هرجا ردیفی در `assistant_suggestions` با `status='PENDING'` **درج** می‌شود، بلافاصله push کن:
```dart
await CentralInboxService.push(
  category: InboxCategory.SUGGESTION,
  sourceSystem: 'assistant',
  entityId: suggestionId,
  eventType: 'suggestion',
  title: title,
  body: body,
  linkModule: 'assistant',
  linkAction: 'open_chat',
);
```
- اگر در کلِ کدبیس هیچ نقطهٔ درجِ `assistant_suggestions` وجود ندارد، این تسک N/A است — در گزارش ذکر کن که هنوز تولیدکننده‌ای ندارد و push آماده برای اتصالِ آینده کجاست.

**P4 — اعتبارسنجی (یک‌بار).**
- `flutter analyze` → بدونِ ارورِ جدید.
- `flutter test` → سبز.
- در گزارش: کدام تولیدکننده‌ها وصل شدند؛ تأیید اینکه باز/بسته شدنِ مکررِ صفحهٔ بینش، Inbox را spam نمی‌کند (به‌لطفِ dedupe/Policy)؛ و وضعیتِ P3 (وصل شد یا N/A).
