# 017 - AI Day Planner ("روزم رو بچین") — Implementation Report

## Feature Summary

قابلیت **برنامه‌ریز روز با هوش مصنوعی** با نام نمایشی «روزم رو بچین» به دستیار ریتمو اضافه شد. کاربر با زبان طبیعی فارسی برنامه روزش را شرح می‌دهد و سیستم آن را تحلیل، زمان‌بندی، اعتبارسنجی و به صورت اتمیک در پایگاه داده ثبت می‌کند.

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/assistant/models/day_plan_models.dart` | مدل‌های داده: `DayPlanDraft`, `DayPlanItemDraft`, `DayPlanQuestion`, `DayPlanSuggestion` |
| `lib/features/assistant/logic/day_plan_composer.dart` | آهنگساز هوشمند: تبدیل زبان طبیعی فارسی به JSON ساختاریافته با کمک AI Gateway |
| `lib/features/assistant/logic/duration_estimator.dart` | موتور تخمین ۵ لایه مدت زمان: صریح کاربر → تاریخچه → حافظه شناختی → جدول پیش‌فرض ایرانی → LLM |
| `lib/features/assistant/logic/day_plan_validator.dart` | اعتبارسنج محلی: حل اوقات شرعی، زنجیره‌ها، بافرها، تداخل‌ها و بهینه‌سازی خواب |
| `lib/features/assistant/presentation/widgets/ai_day_planner_preview_sheet.dart` | رابط تعاملی تایم‌لاین عمودی با ویرایش درون‌خطی |

## Files Modified

| File | Changes |
|------|---------|
| `lib/core/database/database_helper.dart` | اضافه شدن جدول `day_plan_commits` برای Undo |
| `lib/features/assistant/models/assistant_models.dart` | ثبت `applyDayPlan` در enum `AssistantActionType` |
| `lib/features/assistant/logic/assistant_action_registry.dart` | پیاده‌سازی اکشن اتمیک `applyDayPlan` + متد `undoLastDayPlanCommit` |
| `lib/features/chat/presentation/ai_chat_screen.dart` | یکپارچه‌سازی Day Planner: دکمه ورود، تشخیص خودکار، سوال شفاف‌سازی، Quick Replies، بنر Undo، حلقه یادگیری |

---

## Architecture

```
┌─────────────────────────────────┐
│   Chat Screen (ai_chat_screen)  │
│   ┌─────────────────────────┐   │
│   │ _isDayPlanQuery() ─────►│   │  Smart Routing
│   │ Quick Replies & Undo    │   │
│   └───────────┬─────────────┘   │
│               │                 │
│   ┌───────────▼─────────────┐   │
│   │  DayPlanComposer        │   │  LLM → JSON
│   │  (AI Gateway + Memory)  │   │
│   └───────────┬─────────────┘   │
│               │                 │
│   ┌───────────▼─────────────┐   │
│   │  DurationEstimator      │   │  5-Layer Duration
│   │  (User→History→Memory→  │   │
│   │   Default→LLM)          │   │
│   └───────────┬─────────────┘   │
│               │                 │
│   ┌───────────▼─────────────┐   │
│   │  DayPlanValidator       │   │  Time Resolution
│   │  (Anchors, Conflicts,   │   │  + Enrichment
│   │   Sleep Optimization)   │   │
│   └───────────┬─────────────┘   │
│               │                 │
│   ┌───────────▼─────────────┐   │
│   │  Preview Sheet (Timeline)│  │  User Review
│   │  Edit → Confirm         │   │
│   └───────────┬─────────────┘   │
│               │                 │
│   ┌───────────▼─────────────┐   │
│   │  AssistantActionRegistry │  │  Atomic Transaction
│   │  applyDayPlan + Undo    │   │  + day_plan_commits
│   └─────────────────────────┘   │
│                                 │
│   ┌─────────────────────────┐   │
│   │  Learning Loop          │   │  Background Memory
│   │  (actual vs estimated)  │   │  Update
│   └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Smart Routing (تشخیص خودکار)
- تشخیص مستقیم عبارت «روزم رو بچین» / «برنامه روز»
- شمارش کلمات کلیدی (≥3 از لیست فعالیت‌ها) برای جملات طبیعی‌تر
- حالت clarification: سوالات شفاف‌سازی + Quick Replies

### 2. Atomic Execution (ثبت اتمیک)
- تمام ثبت‌ها در یک `db.transaction` برای تضمین یکپارچگی
- جدول `day_plan_commits` شناسه‌های ایجاد شده را ذخیره می‌کند
- Undo طی ۲۴ ساعت از طریق بنر بالای چت یا دکمه Toast

### 3. Module Routing (مسیریابی ماژول)
- `worship` → جدول `worship_practices` (مستقیم DB)
- `sleep` → تنظیمات `app_settings` (بیداری/خواب)
- سایر → `routines` + `routine_schedules` + `OccurrenceGenerator` (جریان استاندارد)

### 4. Learning Loop (حلقه یادگیری)
- مقایسه مدت زمان واقعی (`routine_completions`) با تخمینی (`targetDurationMinutes`)
- اگر اختلاف ≥ ۱۵ دقیقه در ≥ ۳ نمونه: ذخیره واقعیت جدید در حافظه شناختی
- اجرای خودکار در پس‌زمینه هنگام بارگذاری برنامه

---

## Testing Notes

### Manual Verification
1. ✅ ساختار فایل‌ها و ایمپورت‌ها بررسی شد
2. ✅ امضای تمام متدها و کلاس‌ها با API موجود سازگار است
3. ✅ `ChatRepository.addMessage` به‌جای متد ناموجود `saveMessage` استفاده شد
4. ✅ `RecurrenceRule.fromMap` و `RoutineOccurrenceGenerator.generateFutureOccurrences` از مدل‌های موجود استفاده می‌کنند

### Recommended Testing
- **روش Hot Reload**: در IDE خود `flutter run` بزنید و سپس:
  1. صفحه چت دستیار را باز کنید
  2. دکمه «روزم رو بچین ✨» را بزنید
  3. جمله‌ای مثل «ساعت ۶ بیدار میشم، نماز صبح، صبحانه، ۸ تا ۱ سرکارم، ناهار، بعدش یک ساعت ورزش، شام ساعت ۸» بنویسید
  4. شیت پیش‌نمایش تایم‌لاین عمودی باید باز شود
  5. دکمه «تأیید و ثبت برنامه روز» را بزنید
  6. بنر Undo بالای چت باید ظاهر شود

---

## Status: ✅ COMPLETE
