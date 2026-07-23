# 🤖 پرامپت اجرایی — سیستم «دستیار هوشمند» (AI Co-pilot) — برای Gemini 3.5 Flash

> فایلِ خودبسنده. کلِ صفِ A1 تا A11 را **یک‌سره تا آخر** اجرا کن؛ توقفِ میان‌راهی لازم نیست. در پایان یک‌بار اعتبارسنجی و گزارشِ نهایی بده.
> هدف: ارتقای دستیار از یک چت‌باکسِ واکنشی به **مغز/کماندسنترِ اپ** — بریفینگِ روزانه + «بهترین اقدامِ بعدی» (سنتزِ چندسیستمی) + توانِ اقدامِ عملی با Preview→Edit→Save.
> سندِ طراحی: `DESIGN_SYSTEM_ASSISTANT.md`. فایلِ اصلیِ جدید: `lib/features/assistant/presentation/assistant_screen.dart`.

## ⛔️ قواعد (یک‌بار)
- فارسی/RTL، `Vazirmatn`، ارقامِ فارسی، تاریخِ **شمسی** (`shamsi_date`؛ ذخیره ISO/epoch، نمایش شمسی). l10n جدید به `app_fa.arb`/`app_en.arb`.
- رنگ/اندازه هاردکد نکن؛ `RitmoTheme`/`context.colors`. رنگِ پایه: فیروزه‌ای `#06B6D4`.
- لحنِ هم‌خلبانِ آرام؛ پیشنهاد نه دستور؛ عقب‌افتادگی هرگز سرزنش نشود. شفافیتِ علّی («چرا این پیشنهاد؟»).
- داده‌ی دیتابیس تستی است؛ ستون‌های جدید با `DEFAULT`.
- فقط فایل‌های مرتبطِ هر تسک. ابهامِ واقعی → بپرس.
- **`sendQuery`ِ موجود را نشکن** و دستیارهای درون‌صفحه‌ای (انرژی/خواب/کنکور/...) را تغییر نده. قابلیت‌های جدید را **اضافه** کن.
- **AI هرگز مستقیم در DB نمی‌نویسد:** هر اقدام از مسیرِ `Preview → Edit → Save` و repositoryِ همان سیستم.

## 🔒 قیدِ محرمانگیِ چرخه (هرگز نقض نشود)
- در بریفینگ، چت و اقدام‌ها **هیچ اشاره‌ی مستقیمی به قاعدگی/چرخه/پریود** نشود.
- تعدیلِ غیرمستقیم فقط از `lib/core/utils/cycle_consent_bridge.dart` («بر اساس ریتمِ بدنی‌ات...»). برای کاربرِ مرد یا رضایتِ خاموش هیچ ردّی نباشد. کوئریِ مستقیم به جداولِ چرخه ممنوع.
- فیلترِ zero-leakِ موجود در `AIResponseProcessor`/گیتوی روی خروجیِ هم‌خلبان هم اعمال شود.

## 🔒 تصمیم‌های قطعی
1. **هم‌خلبانِ فعالِ کامل:** چت + بریفینگِ خودکار + «بهترین اقدامِ بعدی» + اقدامِ عملی.
2. **کماندسنتر (بریفینگ اول):** صفحه با تبِ «امروز» (بریفینگ + اقدام‌ها) باز می‌شود؛ چت تبِ دوم.
3. **اقدام در همه‌ی سیستم‌ها** با Preview→Edit→Save؛ بازاستفاده از شیت‌های موجود (پیش‌پُرشده).

## 📁 محیط (تأییدشده از کد)
- DB SQLite، نسخه‌ی فعلی **۱۷**؛ مهاجرت = **۱۸** (`_safeAddColumn`؛ هم `_createDB` هم تابعِ مهاجرت). `_safeAddColumn(db, table, column, typeDef)` موجود است.
- `assistant_chats (id, sender['user'/'assistant'], message, createdAt)` + `assistant_suggestions (id, title, body, suggestionType, createdAt)` — هر دو در V2.
- `assistant_chat_screen.dart` — چتِ فعلی: `sendQuery(query, consent: ConsentProfile())` و **چسباندنِ متادیتای دیباگ به متنِ پیام** (باید حذف شود) + لاگِ حریم در `notification_history`.
- `lib/core/ai/`:
  - `AIGateway.instance` — `sendQuery({query, consent, promptType})`, `breakDownGoal(...)`, `parseQuickAdd(...)`. کانفیگ از `app_settings` (`ai_base_url/ai_api_key/ai_model/ai_timeout`)، OpenRouter، retry/timeout. **این الگو را برای متدِ جدید بازاستفاده کن.**
  - `AIContextBuilder.buildContext({query, consent})` + `ConsentProfile(routinesConsent, goalsConsent, energyConsent, sleepConsent, planningConsent)`.
  - `AIPromptEngine.buildSystemPrompt(PromptType)` + `buildUserPrompt(...)` (enum `PromptType{assistant,insight,explanation,suggestion}`).
  - `AIResponseProcessor.process(...)` (فیلترِ zero-leak + استریپِ ```json)، `AICacheManager`, `AIRateLimiter`, `AIFallbackEngine`.
- موتورها (الگوی `CachedEngine`: calculate/invalidate/canRun/dependencies + `RitmoEngineBus`): `EnergyAnalyticsEngine`, `mood_engine`, `sleep_engine`, `goals_engine`, `courses_engine`. مرجع: `lib/core/analytics/courses_engine.dart`.
- `systems_hub_screen.dart` — کاشیِ «دستیار هوشمند» (`CupertinoIcons.sparkles`, `#06B6D4`, `module_assistant_enabled`) از قبل وصل است و به `AssistantChatScreen()` می‌رود؛ فقط مقصد را به `AssistantScreen()` تغییر بده.
- شیت‌های موجودِ ساخت/ثبت برای بازاستفاده در اقدام‌ها: `create_goal_sheet.dart` (+`breakDownGoal`)، شیتِ ساختِ روتین، `sleep_log_sheet`، `quick_log_sheet` (انرژی/حال)، شیت‌های کنکور/دوره.

---

# 🗂 صفِ تسک‌ها (پشتِ‌سرِ‌هم)

**A1 — مهاجرت.** نسخه ۱۷→۱۸ (`_migrateToVNN` + `if (oldVersion < 18)` + هم‌تراز در `_createDB`). با `_safeAddColumn` به `assistant_chats` اضافه کن:
`actionsJson TEXT` و `meta TEXT`. تنظیماتِ جدید با `INSERT OR IGNORE`: `assistant_briefing_enabled='true'`, `assistant_proactive_enabled='true'`. (`module_assistant_enabled` از قبل seed است.)

**A2 — مدل‌ها** (`lib/features/assistant/models/assistant_models.dart`):
- `enum AssistantActionType { createRoutine, createGoal, logSleep, logEnergyMood, addKonkurItem, createCourse, openPage }` + `label`/`icon`.
- `AssistantAction { type, title, Map<String,dynamic> payload, String? targetRoute }` (toJson/fromJson).
- `ChatMessage { id, sender, message, createdAt, List<AssistantAction> actions, String? meta }` (toMap/fromMap با `actionsJson`).
- `NextAction { title, reason, AssistantAction? action, String? deepLinkRoute, int rank }`.
- `BriefingItem { system, headline }` و `DailyBriefing { text, List<BriefingItem> highlights, Map<String,dynamic> stats }`.

**A3 — موتورِ سنتز** (`lib/core/analytics/assistant_engine.dart`, `CachedEngine`):
- ورودی (همه فقط‌خواندنی): خروجی/دادهٔ انرژی، حال، خواب، اهداف (گام‌های امروز/عقب‌افتاده)، روتین‌ها، کنکور/دوره‌های امروز، `today`.
- خروجی: `dailyBriefing`، `nextActions` (رتبه‌بندی‌شده با دلیل + اقدامِ قابلِ‌اعمالِ اختیاری)، `systemHighlights`، `dynamicSuggestions` (چیپِ چت).
- منطقِ خالصِ رتبه‌بندی در helperِ تست‌پذیر (مثلاً: خوابِ ثبت‌نشده، گامِ عقب‌افتاده، انرژیِ پایینِ بازه → اقدامِ پیشنهادی). **هیچ نوشتنی.** قیدِ چرخه فقط از `CycleConsentBridge`.
- تست: ساختِ بریفینگ، رتبه‌بندیِ اقدام‌ها، حالتِ کم‌داده، نبودِ نشتِ چرخه.

**A4 — اصلاحِ زیرساختِ AI** (`lib/core/ai/`):
- helperِ ساختِ `ConsentProfile` واقعی از `app_settings`/رضایت‌ها (به‌جای `ConsentProfile()` خالی).
- `AIPromptEngine`: مقدارِ جدیدِ `PromptType.copilot` + systemPromptِ هم‌خلبان که خروجی را در قالبِ `{"reply": "...", "actions": [{"type","title","payload"}]}` می‌خواهد (فقط از انواعِ A2؛ هیچ نوشتنِ مستقیم؛ همان قواعدِ zero-leak/correlation-not-causation). متدِ `buildCopilotUserPrompt(query, context, availableActions)`.
- پردازشگرِ خروجیِ هم‌خلبان: یا `AICopilotResponseProcessor` جدید یا توسعه‌ی `AIResponseProcessor` که `{reply, actions}` را پارس و اعتبارسنجی کند (نوع‌های ناشناخته دور ریخته شوند) + فیلترِ zero-leak.
- `AIGateway.sendCopilotQuery({query, consent, extraContext})` → `{reply, actions, meta}` با بازاستفاده از `_loadConfig`/retry/cache/rate-limit؛ **`sendQuery` دست‌نخورده.**

**A5 — رجیستریِ اقدام** (`lib/features/assistant/logic/assistant_action_registry.dart`): نگاشتِ `AssistantActionType` → (label/icon + سازنده‌ی پیش‌نمایش + ذخیره از repositoryِ همان سیستم). تا حدِ ممکن **شیتِ موجودِ همان سیستم را پیش‌پُرشده باز کن** (مثلاً `createGoal`→`create_goal_sheet` با عنوان/توضیحِ پیش‌پُر؛ `logSleep`→شیتِ خواب). `openPage` = فقط دیپ‌لینک. اصل: AI فقط `payload` می‌دهد؛ ذخیره دستِ کاربر است.

**A6 — شیتِ پیش‌نمایشِ اقدام** (`widgets/assistant_action_preview_sheet.dart`): پیش‌نمایشِ `AssistantAction` با فیلدهای **قابلِ‌ویرایش**، دکمه‌ی «ذخیره» که رجیستری را صدا می‌زند، و «انصراف». برای اقدام‌های پیچیده، به شیتِ موجودِ همان سیستم (پیش‌پُر) مسیر بده. بدونِ نوشتنِ کور.

**A7 — کماندسنتر** (`widgets/assistant_briefing_section.dart`): کارتِ **بریفینگِ امروز** (متن + آمارِ کلیدی) + کارت‌های **«بهترین اقدامِ بعدی»** از `nextActions` (هرکدام: عنوان + دلیل + «اعمال»→پیش‌نمایش یا «برو به...»→دیپ‌لینک) + highlightهای هر سیستم. حالتِ کم‌داده: «هنوز دارم اپت رو می‌شناسم ✨».

**A8 — چتِ اقدام‌پذیرِ تمیز** (بازنویسیِ `assistant_chat_screen.dart` به ویجتِ تبِ چت): از `sendCopilotQuery` استفاده کن؛ **متادیتای دیباگ را از متنِ پیام حذف کن** (به ستونِ `meta` برود)؛ حباب‌های خوانا؛ پاسخ‌هایی که `actions` دارند **کارتِ اقدام** نشان دهند (اعمال→پیش‌نمایش)؛ چیپ‌ها از `dynamicSuggestions` (پویا، نه هاردکد)؛ پاکسازیِ تاریخچه و لاگِ `notification_history` حفظ شود؛ `actionsJson` ذخیره شود.

**A9 — مونتاژ + هاب** (`assistant_screen.dart` + `systems_hub_screen.dart`): Scaffold+rtl، هدر «دستیار هوشمند ریتمو»+`sparkles`، دو تب: **امروز** (کماندسنتر) · **گفتگو** (چت)، `RefreshIndicator`. در هاب: مقصدِ کاشیِ دستیار را از `AssistantChatScreen()` به `AssistantScreen()` تغییر بده (گیت و فعال‌سازیِ موجود حفظ شود).

**A10 — سنتزِ پویا/فعال.** `dynamicSuggestions` و `nextActions` از وضعیتِ واقعیِ موتور تولید شوند (گامِ عقب‌افتاده، خوابِ ثبت‌نشده، انرژیِ پایین...). اگر `assistant_proactive_enabled=false` کارت‌های فعال پنهان شوند؛ اگر `assistant_briefing_enabled=false` بریفینگ پنهان شود.

**A11 — پایان.** قیدِ چرخه را در کلِ بریفینگ/چت/اقدام بازبینی کن (هیچ ارجاعِ مستقیم؛ فقط Bridge). مطمئن شو `ConsentProfile` واقعی پاس می‌شود و متنِ پیام دیگر متادیتای دیباگ ندارد. اگر چیزی تغییر کرد `DESIGN_SYSTEM_ASSISTANT.md` را به‌روز کن.

---

## ✅ اعتبارسنجیِ نهایی (یک‌بار)
- `flutter analyze` بدونِ error/warningِ جدید.
- `flutter test` همه سبز + تست‌های جدید: موتورِ سنتز (بریفینگ/رتبه‌بندیِ اقدام/کم‌داده)، پردازشگرِ `{reply,actions}` (نوعِ ناشناخته دور ریخته شود)، مهاجرتِ نصبِ‌تازه≡ارتقا، نبودِ نشتِ چرخه در خروجی.
- دستی: فعال‌سازی از هاب → کماندسنتر با بریفینگ و اقدام‌ها → «اعمال» یک اقدام → پیش‌نمایش/ویرایش/ذخیره → چتِ تمیز بدونِ متادیتا → چیپِ پویا → نبودِ هرگونه اشاره‌ی مستقیمِ چرخه (کاربرِ مرد و زن).

## 📤 گزارشِ نهایی
```
- فایل‌های ساخته/تغییر: ...
- خلاصه‌ی A1..A11: ...
- نسخه‌ی مهاجرت: 17→18
- flutter analyze / flutter test: ...
- بازبینیِ قیدِ چرخه + Preview→Edit→Save: ...
- ابهامات: ...
```
