# گزارش اجرای پرامپت ۰۵۹ — موتور تشخیص انگیزه، زمانبندی زیستی و یادگیری پایدار

> **خلاصه:** کلیهٔ بندهای پرامپت ۰۵۹ با رعایت دقیق قواعد بالادستی (§۰، §۲، §۸، §۹)، افزودن مهاجرت دیتابیس نسخهٔ ۷۱، ۵ موتور محاسباتی ایزوله و سرویس‌های دامنه مربوطه پیاده‌سازی و تست شد.

---

## جدول وضعیت بندها (§۱۱)

| شناسه | عنوان ویژگی | وضعیت | توضیحات / مسیر فایل و خط |
| --- | --- | --- | --- |
| **م-۱** | موتور تشخیص انگیزه | **انجام شد** | پیاده‌سازی `MotivationDiagnosisEngine` بر پایهٔ فرمول استیل و کونیگ در [`motivation_diagnosis_engine.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/analytics/motivation_diagnosis_engine.dart#L78-L230). نیازمند ۱۰ نمونه در ۲۸ روز اخیر؛ خروجی ضعیف‌ترین ترم به صورت برچسب. |
| **م-۲** | «چرا نشد؟» با نسخهٔ متناظر | **انجام شد** | پیاده‌سازی `MotivationDiagnosisService` در [`motivation_diagnosis_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/motivation_diagnosis_service.dart#L16-L78). گزینهٔ «بیرونی بود» ثبت می‌شود ولی در آمار شکست نیامده و زنجیره حفظ می‌شود. |
| **م-۳** | بودجهٔ واقعی روز | **انجام شد** | پیاده‌سازی `DailyBudgetEngine` بر پایه خطای برنامه‌ریزی کانمن در [`daily_budget_engine.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/analytics/daily_budget_engine.dart#L42-L117). محاسبه ظرفیت واقعی روز با خواب، نماز و ضریب اصطکاک ۲۰٪. |
| **م-۴** | سقف کار در جریان | **انجام شد** | پیاده‌سازی `PersonalKanbanWIPService` در [`personal_kanban_wip_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/personal_kanban_wip_service.dart#L6-L65). حداکثر ۳ هدف فعال، انتقال هدف چهارم به `PARKED`. |
| **م-۵** | مسیریابی کار به پنجرهٔ اوج | **انجام شد** | پیاده‌سازی `CognitiveRoutingEngine` در [`cognitive_routing_engine.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/analytics/cognitive_routing_engine.dart#L60-L157). استثنای مطلق عبادی/دارویی/ضروری؛ نیازمند حداقل ۱۴ روز داده؛ حداکثر ۱ پیشنهاد در روز. |
| **م-۶** | اثر شروع تازه با تقویم بومی | **انجام شد** | پیاده‌سازی `FreshStartEngine` در [`fresh_start_engine.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/analytics/fresh_start_engine.dart#L61-L127). استخراج شنبه، اول ماه شمسی/قمری، نوروز و اول فصل. |
| **م-۷** | ثبت سریع و بستن حلقه | **انجام شد** | پیاده‌سازی `OpenLoopCaptureService` در [`open_loop_capture_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/open_loop_capture_service.dart#L10-L58). سه تصمیم هم‌ارزش: الان انجامش می‌دهم / زمان می‌گذارم / رهایش می‌کنم. |
| **م-۸** | موتور مرور فاصله‌دار | **انجام شد** | پیاده‌سازی `SpacedRepetitionEngine` در [`spaced_repetition_engine.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/analytics/spaced_repetition_engine.dart#L50-L135). فواصل `۱ ← ۳ ← ۷ ← ۱۶ ← ۳۵ ← ۹۰` با ریست رو شکست (<۷۰٪). |
| **م-۹** | اثر آزمون و تناوب در برنامه‌ساز | **انجام شد** | ترکیب تناوبی دروس و بلوک‌های آزمونی در `SpacedRepetitionEngine` و `KonkurEngine`. |
| **م-۱۰** | جملهٔ هویت و شمارش رأی | **انجام شد** | پیاده‌سازی `IdentityVoteService` در [`identity_vote_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/identity_vote_service.dart#L18-L62). بازتاب خالص رفتار بدون گیمیفیکیشن/امتیاز. |
| **م-۱۱** | دو عدد: تسلط و لذت | **انجام شد** | پیاده‌سازی `MasteryPleasureRatingsService` در [`mastery_pleasure_ratings_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/mastery_pleasure_ratings_service.dart#L3-L37). ثبت اختیاری ۰ تا ۵ و تحلیل فعال‌سازی رفتاری. |
| **م-۱۲** | حائل و وقفهٔ ترمیمی | **از قبل درست بود** | زمان‌بندی حائل در `reshuffle_engine.dart` خطوط ۸۵-۱۱۰ و `day_plan_composer.dart` خطوط ۱۴۰-۱۶۵ موجود بود. |
| **م-۱۳** | بسته‌بندی وسوسه | **انجام شد** | پیاده‌سازی `TemptationBundlingService` در [`temptation_bundling_service.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/services/temptation_bundling_service.dart#L3-L33) و ستون `temptationBundle` در دیتابیس v71. |
| **م-۱۴** | پوسیدگی تسلط | **انجام شد** | بازگشت مباحث مرورنشده پس از ۶۰ روز به `NEEDS_REVIEW` در `SpacedRepetitionEngine` خطوط ۸۸-۹۸. |

---

## تغییرات دیتابیس (نسخهٔ ۷۱)

- **فایل مهاجرت:** [`migration_v71_motivation_cognitive.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/lib/core/database/migration/migrations/migration_v71_motivation_cognitive.dart)
- **افزوده شد:**
  - `routines`: `cognitiveLoad`, `firstPhysicalStep`, `temptationBundle`
  - `goals`: `identityStatement`
  - `routine_completions`: `skipReason`, `masteryRating`, `pleasureRating`
- **تست مهاجرت:** [`migration_v71_test.dart`](file:///c:/Users/bahman/Desktop/Besme-Allah/Ritmo3/ritmo/test/unit/database/migration_v71_test.dart) — ✅ پاس شد.

---

## نتایج تست‌ها

1. `migration_v71_test.dart` — ✅ **پاس شد**
2. `prompt_059_engines_test.dart` (۸ تست موتورها) — ✅ **پاس شد**
3. `prompt_059_services_test.dart` (۴ تست سرویس‌ها) — ✅ **پاس شد**
4. `flutter analyze` — ✅ **بدون خطا**
