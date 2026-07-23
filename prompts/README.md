# پوشه پرامپت‌های اجرایی (Agent Prompts)

این پوشه محل ذخیره پرامپت‌های اجرایی است که توسط Claude (نقش: برنامه‌ریز/معمار) نوشته می‌شود و توسط Gemini (نقش: ایجنت کدنویس) اجرا می‌شود.

## قرارداد نام‌گذاری

```
NNN_short-task-name.md
```

مثال: `001_fix-calendar-sync.md` — شماره ترتیبی سه‌رقمی + نام کوتاه تسک.

## نحوه اجرا توسط Gemini

دستور کوتاهی که به Gemini داده می‌شود:

```
Read the file ritmo/prompts/<FILENAME>.md and execute all its directives exactly. Do not repeat work that is already done in the codebase — verify current state first, then implement only what is missing.
```

## اصول نوشتن پرامپت (برای Claude)

1. **بدون تکرار**: قبل از نوشتن پرامپت، وضعیت فعلی کد بررسی می‌شود تا کار انجام‌شده دوباره درخواست نشود (صرفه‌جویی در کردیت).
2. **سطح بالا برای مدل قوی**: Gemini مدل توانمندی است — پرامپت‌ها هدف، معماری، قیود و معیار پذیرش (acceptance criteria) را مشخص می‌کنند، نه کد خط‌به‌خط.
3. **ارجاع به اسناد**: به `architecture.md` و `ui-ux-design.md` و فایل‌های `DESIGN_SYSTEM_*.md` ارجاع داده می‌شود به‌جای کپی محتوا.
4. **معیار پایان**: هر پرامپت بخش «Definition of Done» دارد تا ایجنت بداند کی کار تمام است.
5. **محدوده صریح**: بخش «Out of Scope» دارد تا ایجنت وارد کارهای اضافی نشود.
