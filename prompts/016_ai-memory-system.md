# 016 — موتور حافظه شناختی ریتمو (Ritmo Memory Engine)

**نقش تو:** ایجنت کدنویس ارشد Flutter/Dart. این سند را کامل بخوان و دقیقاً اجرا کن.
**قانون طلایی:** قبل از هر Stage وضعیت فعلی کد را بررسی کن و فقط چیزی را بساز که وجود ندارد.

> ⚠️ **نکته مهم:** در `ss_ai_coach_sheet.dart` یک پیاده‌سازی آزمایشی حافظه (جدول `ss_ai_memory` و متد `_processMemoryTags`) وجود دارد. آن پیاده‌سازی **تستی بوده و مرجع نیست**. در Stage E حذفش می‌کنی. معماری این سند را بساز، نه آن را.

---

## ۱. هدف

یک **موتور حافظه بلندمدت سراسری** برای همه دستیارهای AI برنامه (چت اصلی + ۸ شیت دستیار حوزه‌ای: سلامت، چرخه، عبادات، بهزیستی، اهداف، کنکور، دوره‌ها، ورزش تکمیلی) که:

1. کاربر را **به‌تدریج** می‌شناسد (استخراج پس‌زمینه از گفتگوها).
2. دستور صریح «یادت باشه / یادت بمونه / فراموش نکن» را **فوراً و تضمینی** ذخیره می‌کند.
3. حافظه‌ی مرتبط را هوشمندانه (نه همه را) به system prompt هر دستیار تزریق می‌کند.
4. تناقض‌ها را حل می‌کند («دیگه گیاه‌خوار نیستم» باید حافظه قدیمی را به‌روز کند، نه اینکه کنارش بنشیند).
5. فراموشی طبیعی دارد: حافظه‌های کم‌اهمیتِ استفاده‌نشده محو می‌شوند؛ حافظه‌های صریح هرگز.
6. کاملاً شفاف و تحت کنترل کاربر است. همه‌چیز فقط لوکال در SQLite؛ هیچ sync ابری.

## ۲. مبانی طراحی (چرا این معماری؟)

این طراحی از سه سیستم مرجع صنعت گرفته شده — هنگام پیاده‌سازی به این منطق وفادار بمان:

- **دو لایه‌ی مجزا (الگوی حافظه ChatGPT):** «حافظه صریح» (پین‌شده، همیشه تزریق می‌شود، کاربر مدیریتش می‌کند) از «حافظه ضمنی» (پروفایلی که در پس‌زمینه از گفتگوها سنتز می‌شود) جداست و سوییچ کنترل جدا دارد.
- **پایپ‌لاین دومرحله‌ای (الگوی mem0):** نوشتن حافظه = ۱) استخراج فکت‌های کاندید از گفتگو، ۲) **ادغام**: مقایسه هر کاندید با حافظه‌های موجود و انتخاب یکی از عملیات `ADD / UPDATE / DELETE / NOOP`. این مرحله دوم است که از تکرار و تناقض جلوگیری می‌کند.
- **امتیازدهی بازیابی (الگوی Generative Agents استنفورد):** انتخاب حافظه برای تزریق با ترکیب وزن‌دارِ تازگی (decay نمایی) + اهمیت (نمره ۱تا۱۰ که LLM موقع نوشتن می‌دهد) + ربط به گفتگوی جاری.

**تصمیم فنی مهم:** از FTS5 و embedding استفاده نکن — SQLite سیستمی اندروید در همه نسخه‌ها FTS5 ندارد و corpus حافظه کوچک است (سقف چند صد رکورد). همه رکوردهای فعال را بخوان و امتیازدهی را در Dart انجام بده.

## ۳. Stage A — لایه داده

در `DatabaseHelper` جدول زیر را بساز (با همان الگوی ensure موجود). حافظه‌ها **جمله فارسی کامل** هستند، نه key/value:

```sql
CREATE TABLE IF NOT EXISTS ai_memory (
  id TEXT PRIMARY KEY,               -- uuid
  content TEXT NOT NULL,             -- فکت به زبان طبیعی: «به بادام‌زمینی حساسیت دارد»
  type TEXT NOT NULL,                -- identity|preference|constraint|goal|episode|insight
  domain TEXT NOT NULL DEFAULT 'core', -- core|health|cycle|worship|wellbeing|goals|konkur|courses|sports
  source TEXT NOT NULL,              -- explicit|implicit|reflection
  importance INTEGER NOT NULL,       -- 1..10 (LLM موقع استخراج می‌دهد؛ explicit همیشه 10)
  pinned INTEGER NOT NULL DEFAULT 0, -- explicit ⇒ 1؛ کاربر هم می‌تواند pin کند
  sensitive INTEGER NOT NULL DEFAULT 0, -- سلامت/چرخه ⇒ 1
  status TEXT NOT NULL DEFAULT 'active', -- active|archived
  sessionId TEXT,                    -- منشأ (برای «چرا این را می‌دانی؟»)
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  lastAccessedAt INTEGER NOT NULL,
  accessCount INTEGER NOT NULL DEFAULT 0,
  expiresAt INTEGER                  -- برای فکت‌های زمان‌دار («هفته بعد امتحان دارد»)
);
```

قواعد `type`:
- `identity` هویت پایدار (شغل، شرایط خانوادگی)، `preference` سلیقه‌ها، `constraint` محدودیت‌ها (آلرژی، درد زانو، محدودیت زمانی)، `goal` اهداف اعلام‌شده، `episode` رویداد مقطعی مهم، `insight` جمع‌بندی‌های تولیدشده در reflection.

## ۴. Stage B — سرویس مرکزی: `lib/core/ai/memory/`

سه فایل، هم‌سبک بقیه `core/ai`:

### `memory_models.dart`
`MemoryEntry` + enum ها + پارس/سریالایز.

### `ai_memory_service.dart` — کلاس `AiMemoryService` (singleton)

**بازیابی (خواندن):**
```
score = 0.5 × recency + 2.0 × (importance / 10) + 3.0 × relevance
```
- `recency = exp(-λ × ساعت از lastAccessedAt)` با نیمه‌عمر ۷ روز.
- `relevance` = همپوشانی توکنی نرمال‌شده بین متن پیام جاری کاربر و `content` (توکنایز ساده فارسی: جداسازی با فاصله/نیم‌فاصله، حذف stop-wordهای پرتکرار) **+ پاداش ثابت اگر domain رکورد با domain دستیار جاری یکی باشد**.
- خروجی `retrieve({required String domain, required String query})`:
  - همه `pinned=1` فعالِ مجاز (بدون امتیازدهی، سقف ۲۰)،
  - به‌علاوه حداکثر ۱۰ رکورد غیرپین با بالاترین score.
  - رکوردهای بازیابی‌شده: `lastAccessedAt` به‌روز و `accessCount++` (تقویت با استفاده).
  - رکوردهای `expiresAt` گذشته و `archived` هرگز برنمی‌گردند.
  - **قاعده حریم خصوصی:** رکوردهای `sensitive=1` فقط در domain خودشان و چت اصلی تزریق می‌شوند، نه در دستیارهای حوزه‌های دیگر.
- `buildPromptBlock(entries)`: بلوک فارسی «آنچه از قبل درباره کاربر می‌دانی» + قدمت تقریبی هر مورد («~۳ هفته پیش») + این جمله ثابت: «این موارد پس‌زمینه‌اند؛ اگر حرف فعلی کاربر با آن‌ها تناقض داشت، حرف فعلی او مقدم است.»

**نوشتن:**
- `applyOperations(List<MemoryOp> ops)` — اجرای ADD/UPDATE/DELETE/NOOP روی جدول. DELETE یعنی `status='archived'` (حذف فیزیکی فقط از UI).
- **فراموشی:** بعد از هر ادغام، رکوردهای غیرپینی که `importance ≤ 4` و بیش از ۶۰ روز access نشده‌اند → archive. سقف رکورد فعال غیرپین: ۳۰ برای core و ۱۵ برای هر domain (کم‌امتیازترین‌ها archive می‌شوند). پین‌شده‌ها هرگز خودکار archive نمی‌شوند.
- سوییچ‌ها در `app_settings`: `ai_memory_enabled` (کل سیستم، پیش‌فرض روشن) و `ai_memory_implicit_enabled` (فقط یادگیری تدریجی، پیش‌فرض روشن). خاموش ⇒ retrieve خالی / extraction انجام نمی‌شود. حافظه صریح حتی وقتی implicit خاموش است کار می‌کند.

### `memory_consolidator.dart` — استخراج و ادغام پس‌زمینه

- `Future<void> consolidateSession(String sessionId, String domain)`:
  1. transcript سشن را بخوان (فقط اگر ≥ ۴ پیام کاربر دارد).
  2. **یک** فراخوانی LLM از طریق `AiGateway` موجود با پرامپت استخراج+ادغام: transcript + فهرست حافظه‌های فعال مرتبط را بده و خروجی JSON بگیر:
     ```json
     [{"op":"ADD|UPDATE|DELETE|NOOP", "id":"برای UPDATE/DELETE", "content":"...", "type":"...", "domain":"...", "importance":7, "sensitive":false, "expiresAt":null}]
     ```
  3. `applyOperations` + ثبت `sessionId`.
  - پرامپت استخراج باید صریح بگوید: فقط فکت‌های **پایدار و آینده‌دار** (نه «کاربر امروز خسته بود»)، هر فکت یک جمله سوم‌شخص کوتاه، حداکثر ۵ عملیات per سشن، تناقض با حافظه موجود ⇒ UPDATE یا DELETE همان id.
  - fire-and-forget با try/catch کامل؛ شکستش هرگز نباید UX را خراب کند. برای هر سشن idempotent باشد (فلگ `memory_consolidated` در جدول سشن یا `app_settings`).
- **Reflection (سبک):** هر بار که تعداد `episode`های فعال یک domain به ۱۰ رسید، همان consolidator با پرامپت جمع‌بندی، آن‌ها را به ۱–۲ رکورد `insight` تبدیل و episodeها را archive می‌کند.

## ۵. Stage C — مسیر صریح («یادت باشه») — تضمینی

دو خط دفاعی، هر دو لازم:

1. **قرارداد پرامپت:** به system prompt همه دستیارها (متد `memoryInstruction()` در سرویس) اضافه می‌شود: اگر کاربر خواست چیزی به خاطر سپرده شود، در انتهای پاسخ تگ زیر را بفرست و در متن پاسخ، ذخیره‌شدن را کوتاه تأیید کن:
   ```
   <memory_ops>[{"op":"ADD","content":"...","type":"...","importance":10}]</memory_ops>
   ```
2. **تور ایمنی deterministic:** در لایه ارسال پیام (سرویس چت)، اگر متن کاربر با regex عبارات صریح match شد (`یادت باشه|یادت بمونه|فراموش نکن|به خاطر بسپار|remember`) ولی پاسخ مدل `<memory_ops>` نداشت، خودِ جمله کاربر را به‌عنوان ADD با `source='explicit'`, `importance=10`, `pinned=1` در صف consolidator بگذار.

هر آنچه از مسیر صریح می‌آید: `source='explicit'`, `pinned=1`.

## ۶. Stage D — اتصال به چت اصلی

- `ChatActionParser` (`lib/core/ai/chat/chat_action_parser.dart`): الان تگ `<memory>` را strip می‌کند و دور می‌ریزد. آن را به تگ جدید `<memory_ops>` ارتقا بده و payload خام را در `ParsedResponse` برگردان (فیلد `memoryOps`). strip از `cleanText` حفظ شود — تگ هرگز نباید در UI دیده شود.
- `StreamingChatService.send`: بعد از parse (خط ~۱۰۴)، `memoryOps` را به `AiMemoryService.applyOperations` بده و همان‌جا تور ایمنی Stage C را اجرا کن. جایی که summarizer سشن صدا زده می‌شود، `MemoryConsolidator.consolidateSession(sessionId, 'core')` را هم fire-and-forget صدا بزن.
- `ConversationContextBuilder.build`: به‌جای (و علاوه بر) سه کلید `app_settings`، خروجی `retrieve(domain: 'core', query: userText)` را بگیر و در `toMessages` بلوک حافظه را بعد از «پروفایل کاربر» بگذار.
- دستورالعمل `memoryInstruction()` به system prompt چت اصلی اضافه شود.

## ۷. Stage E — شیت‌های حوزه‌ای + حذف پیاده‌سازی تستی

- یک helper مشترک بساز (mixin یا کلاس کوچک، مثلاً `AssistantMemoryBinding`) که سه کار را کپسوله کند: تزریق بلوک حافظه + `memoryInstruction()` در system prompt، پردازش `<memory_ops>` پاسخ، و تریگر consolidation در بسته‌شدن شیت. شیت‌ها فقط `domain` بدهند — منطق تکراری در ۸ فایل ممنوع.
- به همه ۸ شیت متصلش کن: `ai_courses / ai_cycle / ai_goals / ai_health / ai_konkur / ai_wellbeing / ai_worship / ss_ai_coach`.
- **پاک‌سازی تست قبلی در `ss_ai_coach_sheet.dart`:** متد `_processMemoryTags`، خواندن مستقیم `ss_ai_memory` (~خط ۱۳۸) و دستورالعمل حافظه داخل پرامپتش (~خط ۴۶۵) را حذف کن و به helper مشترک وصلش کن. جدول `ss_ai_memory` را در مهاجرت DB drop کن — داده‌هایش تستی است، مهاجرت داده لازم نیست.
- domainهای `cycle` و `health`: رکوردها با `sensitive=1` ذخیره شوند.

## ۸. Stage F — UI مدیریت حافظه

صفحه «حافظه دستیار» کنار تنظیمات AI موجود در پروفایل، مطابق `DESIGN_SYSTEM_PROFILE.md` (کامپوننت جدید اختراع نکن):

- دو سوییچ: «حافظه» (کل) و «یادگیری خودکار از گفتگوها» (implicit) + توضیح یک‌خطی حریم خصوصی («فقط روی همین دستگاه»).
- لیست حافظه‌های active گروه‌بندی‌شده بر اساس domain با برچسب فارسی؛ هر آیتم: content، نشان نوع/صریح، قدمت.
- روی هر آیتم: pin/unpin، ویرایش متن، حذف (حذف فیزیکی). دکمه «پاک‌کردن کل حافظه» با دیالوگ تأیید دومرحله‌ای.
- بخش جمع‌شونده «بایگانی‌شده‌ها» با امکان بازگردانی.
- افزودن دستی حافظه توسط کاربر (فیلد متن ساده ⇒ ADD صریح pinned).

## ۹. ایمنی و کیفیت

- محتوای حافظه قبل از insert پاک‌سازی شود: strip هر تگ/براکت HTML-مانند، سقف ۳۰۰ کاراکتر. (حافظه نباید بردار تزریق پرامپت شود.)
- همه فراخوانی‌های LLM حافظه با try/catch کامل و بدون اثر روی UX اصلی.
- `flutter analyze` بدون خطا و warning جدید.

## ۱۰. معیار پذیرش

1. در چت اصلی: «یادت بمونه به بادام‌زمینی حساسیت دارم» ⇒ تأیید در پاسخ + رکورد explicit پین‌شده در DB ⇒ در سشن جدید و همچنین در شیت دستیار سلامت، مدل بدون یادآوری این را می‌داند.
2. چند سشن درباره برنامه خواب صحبت کن ⇒ بعد از پایان سشن، رکورد implicit مرتبط ساخته می‌شود (لاگ consolidation).
3. «دیگه گیاه‌خوار نیستم» ⇒ رکورد قدیمی UPDATE/archive می‌شود، نه رکورد متناقض دوم.
4. حافظه ثبت‌شده در دستیار چرخه (`sensitive=1`) در شیت کنکور تزریق **نمی‌شود** ولی در خود دستیار چرخه هست.
5. خاموش‌کردن «یادگیری خودکار» ⇒ consolidation متوقف؛ «یادت باشه» همچنان کار می‌کند. خاموش‌کردن سوییچ کل ⇒ هیچ تزریق/ذخیره‌ای.
6. تگ `<memory_ops>` در UI هیچ دستیاری دیده نمی‌شود؛ جدول `ss_ai_memory` دیگر وجود ندارد.
7. حذف و ویرایش از صفحه مدیریت واقعاً روی تزریق بعدی اثر می‌گذارد.

## ۱۱. Definition of Done

هر شش Stage پیاده، هر ۷ معیار پذیرش برقرار، analyze تمیز، و یک پاراگراف گزارش تغییرات در انتها.

## ۱۲. Out of Scope

- embedding، vector search، FTS5، هیچ پکیج جدید.
- تغییر `conversation_rag.dart` و `chat_session_summarizer.dart` (جز صدازدن consolidator کنار summarizer).
- sync ابری، export/import حافظه.
- بازطراحی UI چت یا شیت‌ها — فقط اتصال حافظه.
