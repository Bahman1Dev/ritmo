# چک‌لیست بازطراحی صفحه خانه، پروفایل و مدیریت روتین‌های ریتمو به سبک iOS 26

## صفحه خانه (Home Dashboard)
- [x] بازنویسی پوسته ناوبری اصلی (`home_navigation_shell.dart`)
  - [x] افزودن ۵ تب ناوبری (خانه، تقویم، +، گزارش‌ها، پروفایل)
  - [x] اعمال افکت شیشه‌ای نیمه‌شفاف برای نوار ناوبری پایین
  - [x] پیاده‌سازی دکمه شناور (+) میانی با گرادیان آبی-بنفش
- [x] حذف فاکتور سطح انرژی در موتور تصمیم‌گیری قدیمی (`context_engine.dart`)
  - [x] پاکسازی ارجاعات به `EnergyLevel` در منطق انتخاب تسک بعدی
- [x] اصلاح تم گرافیکی برنامه (`ritmo_theme.dart`)
  - [x] افزودن ویژگی‌های اختصاصی شیشه روشن iOS 26
- [x] بازنویسی کامل رابط کاربری صفحه اصلی داشبورد (`now_dashboard_screen.dart`)
  - [x] تغییر رنگ پس‌زمینه به گرادیان آبی-خاکستری بسیار ملایم شیک
  - [x] پیاده‌سازی هدر با نام ریتمو در مرکز، دکمه زنگوله اعلان در چپ و تصویر آواتار در راست
  - [x] طراحی کارت متقارن «نبض زندگی» با فونت سبز درشت و نمودار میله‌ای ۷ روزه
  - [x] طراحی کارت متقارن «زون فعلی» با جزئیات زمان و دکمه شیشه‌ای تغییر زون
  - [x] حذف کامل هرگونه محاسبه، ویجت و حالت مرتبط با باتری انسانی هاردکدشده
  - [x] پیاده‌سازی بنر دستیار هوشمند به صورت شرطی (فقط در صورت فعال بودن پرچم ماژول)
  - [x] پیاده‌سازی نوار ابزار دسترسی سریع افقی با ۴ دکمه گرد
  - [x] پیاده‌سازی فهرست عمودی زیرسیستم‌ها به صورت پویا (وابسته به فعال بودن پرچم هر ماژول در دیتابیس)
  - [x] افزودن افکت‌های جهش فنری و ترنزیشن‌های انیمیشنی روان زمان بارگذاری و تعامل

## صفحه پروفایل (Profile Screen)
- [x] بازنویسی کامل صفحه پروفایل با الهام از استانداردهای طراحی iOS 26 و Apple Settings
  - [x] طراحی هدر متمرکز شیک (Avatar در چپ، اطلاعات نام، نبض زندگی و روزهای تداوم در راست)
  - [x] پیاده‌سازی نوار وضعیت سریع افقی شامل زون، انرژی و بستر زندگی (تماماً کلیک‌پذیر)
  - [x] گروه‌بندی بخش‌های تنظیمات به سبک iOS با جداکننده‌های باریک (اطلاعات شخصی، ماژول‌ها، امنیت و...)
  - [x] نمایش وضعیت فعال زون، انرژی و بستر زندگی در سمت چپ نوار هر ردیف
  - [x] دکمه خروج مجزا و شیک با تم قرمز شیشه‌ای ملایم در انتهای صفحه

## مدیریت روتین‌ها (Routines Hub)
- [x] بازنویسی کامل صفحه روتین‌ها با الهام از استانداردهای طراحی iOS 26 و visionOS
  - [x] طراحی هدر با عنوان بزرگ «روتین‌ها» و سه دکمه شیشه‌ای شناور (جستجو، فیلتر، افزودن)
  - [x] پیاده‌سازی کارت هوشمند تمرکز اصلی امروز (Smart Focus Card) به سبک Apple Intelligence با پیشنهاد روتین غیرفعال و دلایل پیشنهاد
  - [x] طراحی خلاصه وضعیت پیشرفت روزانه شامل حلقه پیشرفت پیشرفته با درصد و تعداد کارهای باقی‌مانده و انجام‌شده
  - [x] پیاده‌سازی نوار فیلتر سگمنتد مدرن iOS (امروز، هفته، همه، تعویق شده، انجام شده)
  - [x] توسعه نوار سیستم‌های سریع افقی (Quick Systems Bar) به صورت کاملاً پویا و با قابلیت پرش اسکرول به دسته‌بندی مربوطه
  - [x] پیاده‌سازی سیستم دسته‌بندی پویای روتین‌ها (تولید خودکار در زمان اجرا بر اساس ماژول‌های فعال و روتین‌های موجود بدون هاردکد کردن)
  - [x] پیاده‌سازی سوایپ به راست برای باز کردن شیت نیت (Niyyah Sheet) به جای انجام مستقیم روتین (ممنوعیت انجام مستقیم در معماری ریتمو)
  - [x] پیاده‌سازی سوایپ به چپ برای دسترسی به تعویق، ویرایش و حذف
  - [x] پیاده‌سازی شیت نیت (Niyyah Sheet) تعاملی شیک شامل شروع با تایمر، ثبت انجام زودهنگام، نسخه سبک، قبلاً انجام داده‌ام و تعویق
  - [x] طراحی تایمر معکوس شیک و پیشرفته به صورت Bottom Sheet با حلقه پیشرفت و کلیدهای کنترل زمان و ثبت هوشمند انجام
  - [x] پیاده‌سازی دکمه شناور Ritmo Orb شیشه‌ای نفس‌کشنده با منوی بازشوی هوشمند و پویا بر اساس ماژول‌های فعال

## موتور هوش و پردازش تصمیم‌گیری ریتمو (Ritmo Intelligence Engine - RIE)
- [x] Phase 0: Setup & Configuration
    - [x] Add `get_it`, `freezed_annotation`, `json_annotation` to `dependencies` in `pubspec.yaml`
    - [x] Add `freezed`, `json_serializable`, `build_runner`, `very_good_analysis` to `dev_dependencies` in `pubspec.yaml`
    - [x] Update `analysis_options.yaml` to include strict lint rules
- [x] Phase 1: ADR Documentation
    - [x] Create `0001-strategy-pattern-for-planner.md`
    - [x] Create `0002-modular-database-schema.md`
    - [x] Create `0003-pipeline-based-intelligence-engine.md`
    - [x] Create `0004-service-locator-for-di.md`
    - [x] Create `0005-context-snapshot-pattern.md`
    - [x] Create `0006-guard-rails-dependency-rules.md`
    - [x] Create `0007-typed-payloads-over-maps.md`
- [x] Phase 2: Database Modularization
    - [x] Extract table schemas to separate files in `lib/core/database/schema/tables/`
    - [x] Create `SchemaManager` to orchestrate table creation
    - [x] Extract seed data to `lib/core/database/seed/` and `assets/data/iran_cities.json`
    - [x] Create `MigrationRunner` and extract v1-v34 migrations to separate classes
    - [x] Add `DatabaseExecutor` support to all query methods to allow transactional execution
    - [x] Refactor `DatabaseHelper` to be a lightweight facade
- [x] Phase 3: Migration Integration & Rollback Tests
    - [x] Implement `database_helper_test.dart` using FFI in-memory SQLite database
    - [x] Write integration test verifying v1 -> v34 migration and structural integrity
- [x] Phase 4: Planner Strategy Pattern
    - [x] Create typed Freezed payloads for all planner categories (`planner_payloads.dart`)
    - [x] Create `PlannerSaveContext` snapshot class (decoupled from UI/Controller classes)
    - [x] Create `PlannerCategoryStrategy` interface (`planner_category_strategy.dart`)
    - [x] Implement strategies for Worship, Sports, Medical, Course, Goal, Reflection, Generic
    - [x] Create `PlannerStrategyRegistry` for strategy resolution
    - [x] Refactor `universal_planner_sheet.dart` — save() now delegates to strategy registry (300-line if/else removed)
- [x] Phase 5: RIE Pipeline & Context Snapshot
    - [x] Create immutable `ContextSnapshot` model containing all pre-fetched data
    - [x] Implement `ContextResolver` to fetch database records and build `ContextSnapshot`
    - [x] Create `FilterPipeline` and implement chainable filters (Zone, Energy, Biological, etc.)
    - [x] Create `ScoringEngine` and implement modular scorers (Zone, Time, Focus, etc.)
    - [x] Refactor `RitmoIntelligenceEngine` to orchestrate resolver, pipeline, and scorers
- [x] Phase 6: AppBootstrapper & Service Locator
    - [x] Setup `GetIt` inside `service_locator.dart`
    - [x] Create `AppBootstrapper` with a standalone initializer for isolate compatibility
    - [x] Clean up `main.dart` to use bootstrapper and locator
- [x] Phase 7: Platform Interfaces
    - [x] Create platform interfaces for Alarm, Notification, and Backup services
    - [x] Extract platform implementations using locator
- [x] Phase 8: CI Pipeline
    - [x] Configure GitHub Actions build/test workflow
- [x] Phase 9: Integration & Golden Tests
    - [x] Add flow tests and UI regression Golden tests
- [x] Phase 10: Dependency Pinning & pubspec cleanup
    - [x] Pin dependencies and clean unused packages
- [x] تصحیح و اعمال اولویت‌ها در حل بستر روزانه (`resolveDailyBehavior`):
  `SICK > TRAVEL > EXAM > BUSY > WORSHIP > NORMAL`
- [x] پشتیبانی از ماژول عبادات و فصول عبادی (`worship_seasons`) در محاسبه اولویت بستر روز و اعمال تغییرات
- [x] همگام‌سازی کامل لایه‌های ممانعت (Layer 5) و امتیازدهی در RIE جهت جلوگیری از تناقض‌های رفتاری
- [x] ادغام و نمایش هشدارهای بحرانی سیستم (Critical Alerts) برای داروهای رو به اتمام و تداخل‌های همزمان روتین‌های روزانه

## ناوبری و هماهنگ‌سازی سراسری (Global Navigation & State Sync)
- [x] ایجاد کلاس اطلاع‌رسانی مرکزی `RitmoEvents` مبتنی بر `ValueNotifier` در `models.dart`
- [x] پیاده‌سازی سابسکرایب و شنود رویداد در داشبورد اصلی برای کشف تغییرات ایجاد شده در روتین‌ها
- [x] اتصال اطلاع‌رسان به فرایندهای ذخیره، ویرایش، حذف، تکمیل، تعویق و Snooze روتین‌ها در سایر صفحات
- [x] تضمین بروزرسانی بلادرنگ وضعیت هوم داشبورد همگام با ردیف‌های تغییریافته در مسیرها

## آزمایش و صحت‌سنجی نهایی
- [x] ایجاد فایل تست جامع `test/rie_test.dart` برای اعتبارسنجی تمام لایه‌های تصحیح شده RIE
- [x] اطمینان از عملکرد صد در صدی و هماهنگی کامل کدهای جدید بدون خطای کامپایل
