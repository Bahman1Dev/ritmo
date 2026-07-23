// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get learningGrowthInsightTitle => 'رشد چشمگیر یادگیری 📈';

  @override
  String learningGrowthInsightMessage(int percent) {
    return 'فعالیت‌های یادگیری شما در این هفته نسبت به هفته گذشته $percent٪ رشد داشته است. مسیر مطالعه خود را ادامه دهید!';
  }

  @override
  String get healthDeclineInsightTitle => 'توجه به سلامت و ورزش ⚠️';

  @override
  String healthDeclineInsightMessage(int percent) {
    return 'تعداد روتین‌های سلامتی شما در ۷ روز گذشته $percent٪ کاهش یافته است. تلاش کنید دوباره آنها را در برنامه قرار دهید.';
  }

  @override
  String get morningLeadInsightTitle => 'برتری عملکرد صبحگاهی ☀️';

  @override
  String get morningLeadInsightMessage =>
      'روتین‌های صبحگاهی شما (۶:۰۰ تا ۱۲:۰۰) نرخ تکمیل بالاتری نسبت به روتین‌های عصرگاهی دارند. برای کارهای مهم‌تر روی صبح‌ها سرمایه‌گذاری کنید.';

  @override
  String get fatigueWarningInsightTitle => 'بازه حساس خستگی ⚡';

  @override
  String fatigueWarningInsightMessage(String window) {
    return 'بازه زمانی $window شایع‌ترین دوره خستگی و از دست رفتن روتین‌های شماست. در این ساعات تسک‌های سبک‌تر قرار دهید.';
  }

  @override
  String get productiveWeekdayInsightTitle => 'روز درخشان شما 🌟';

  @override
  String productiveWeekdayInsightMessage(String weekday) {
    return 'روز «$weekday» پربازده‌ترین روز هفته برای شماست. کارهای سنگین و پروژه‌های خود را در این روز برنامه‌ریزی کنید.';
  }

  @override
  String get gatheringDataInsightTitle => 'در حال شناخت ریتم شما 🔍';

  @override
  String get gatheringDataInsightMessage =>
      'ریتمو برای ارائه تحلیل‌های معتبر نیاز به داده‌های بیشتری دارد. لطفاً به ثبت فعالیت‌های خود ادامه دهید.';

  @override
  String get contextExplanationRest => 'استراحت و بازیابی انرژی 🌿';

  @override
  String contextExplanationEssential(String title) {
    return 'سیستم زندگی «$title» به دلیل اهمیت حیاتی، در اولویت بالاتر قرار گرفت.';
  }

  @override
  String contextExplanationSick(String title) {
    return 'به دلیل کسالت و بیماری، روتین‌های فیزیکی تعلیق شده و روتین «$title» پیشنهاد می‌شود.';
  }

  @override
  String contextExplanationExam(String title) {
    return 'با توجه به بازه امتحانات، روتین‌های یادگیری و مطالعه نظیر «$title» تقویت شده‌اند.';
  }

  @override
  String contextExplanationBusy(String title) {
    return 'به دلیل تراکم بالای برنامه‌های امروز، اقدام بهینه بعدی روتین «$title» است.';
  }

  @override
  String contextExplanationWorship(String season, String title) {
    return 'با توجه به فصل عبادی جاری ($season)، روتین «$title» پیشنهاد می‌شود.';
  }

  @override
  String contextExplanationZone(String title) {
    return 'با توجه به حضور در زون فعال، روتین «$title» جهت همگامی با ریتم جاری پیشنهاد می‌شود.';
  }

  @override
  String contextExplanationLowEnergy(String title) {
    return 'با توجه به سطح انرژی پایین، نسخه متناسب از روتین «$title» پیشنهاد می‌شود.';
  }

  @override
  String contextExplanationDynamic(String title) {
    return 'با تحلیل پویای ریتم روزانه، روتین «$title» به عنوان بهترین اقدام بهینه بعدی پیشنهاد می‌شود.';
  }

  @override
  String get hormonalMenstrualAdjustment1 => 'فعالیت‌های سنگین را کاهش دهید';

  @override
  String get hormonalMenstrualAdjustment2 =>
      'بین کارها استراحت کوتاه اضافه کنید';

  @override
  String get hormonalMenstrualAdjustment3 =>
      'روی کارهای سبک و ضروری تمرکز کنید';

  @override
  String get hormonalMenstrualAdjustment4 =>
      'آب کافی بنوشید و استراحت کافی داشته باشید';

  @override
  String get hormonalPreCycleAdjustment1 =>
      'ممکن است خستگی بدنی یا نوسانات انرژی خفیف را تجربه کنید 🔋';

  @override
  String get hormonalPreCycleAdjustment2 =>
      'اولویت‌دهی به کارهای مهم در ساعات اولیه روز ⏰';

  @override
  String get hormonalPreCycleAdjustment3 =>
      'پیشنهاد می‌شود زمان خواب شبانه را افزایش دهید 🌙';

  @override
  String get hormonalPostCycleAdjustment1 =>
      'سطح انرژی و توانایی تمرکز در حال افزایش است 📈';

  @override
  String get hormonalPostCycleAdjustment2 =>
      'زمان عالی برای شروع برنامه‌ها یا یادگیری کارهای جدید 🎓';

  @override
  String get hormonalContextMenstrual =>
      'به دلیل فاز قاعدگی فعال، پیشنهاد می‌شود فعالیت‌های بدنی سبک‌تری داشته باشید و زمان ریکاوری را افزایش دهید. 🌸';

  @override
  String get hormonalContextPreCycle =>
      'در فاز پیش از قاعدگی (Pre-cycle)، احتمال خستگی یا حساسیت عاطفی ملایم وجود دارد. انعطاف‌پذیری برنامه به آسایش شما کمک می‌کند. 🧘';

  @override
  String get hormonalContextPostCycle =>
      'در فاز پس از قاعدگی (Post-cycle)، سطح آمادگی ذهنی و انرژی بدنی رو به افزایش است. زمان خوبی برای چالش‌های جدید است. ⚡';

  @override
  String get hormonalContextNormal =>
      'وضعیت بدنی در حالت عادی و متعادل قرار دارد. 🍃';

  @override
  String get hormonalContextNoData =>
      'هنوز داده کافی برای پیش‌بینی دقیق وضعیت شما وجود ندارد.';

  @override
  String get hormonalContextDisabled => 'ماژول چرخه بدنی فعال نیست.';

  @override
  String medicineStockAlert(String title, int count) {
    return 'موجودی داروی «$title» رو‌به‌اتمام است (موجودی فعلی: $count).';
  }

  @override
  String timeConflictAlert(String title1, String title2) {
    return 'تداخل زمانی بین روتین‌های «$title1» و «$title2» شناسایی شد.';
  }

  @override
  String get pulseCardMoodGood => 'امروز روز خوبی بوده 🌱';

  @override
  String get pulseCardMoodExcellent => 'ریتم زندگی شما عالی است! 🌟';

  @override
  String get pulseCardMoodRestore => 'بیا ریتم زندگی را بازیابی کنیم 🌿';

  @override
  String get pulseCardTitle => 'نبض زندگی';

  @override
  String get pulseCardTrend => 'روند این هفته +۱۱٪';

  @override
  String get currentEnergyTitle => 'انرژی فعلی';

  @override
  String get manageEnergy => 'مدیریت انرژی';

  @override
  String get currentRealmTitle => 'قلمرو فعلی';

  @override
  String get outOfRealm => 'خارج از قلمرو';

  @override
  String get noActiveSchedule => 'بدون زمان‌بندی فعال';

  @override
  String get logNewDailyRealm => 'ثبت قلمرو جدید روزانه';

  @override
  String routinesConnectedToRealm(int count) {
    return '$count روتین متصل به این قلمرو';
  }

  @override
  String get addRealm => 'افزودن قلمرو ›';

  @override
  String get manageRealm => 'مدیریت قلمرو ›';

  @override
  String get energyLevelHigh => 'بالا';

  @override
  String get energyLevelLow => 'پایین';

  @override
  String get energyLevelMedium => 'متوسط';

  @override
  String get energyDescHigh => 'آماده برای کارهای عمیق و تمرکز سنگین';

  @override
  String get energyDescLow => 'زمان مناسب برای استراحت و کار سبک';

  @override
  String get energyDescMedium => 'مناسب برای مطالعه، پروژه‌ها و روتین‌ها';

  @override
  String get contextNormal => 'عادی 🍃';

  @override
  String get contextSick => 'بیماری 🤒';

  @override
  String get contextTravel => 'سفر ✈️';

  @override
  String get contextExam => 'امتحانات 📚';

  @override
  String get contextBusy => 'مشغله زیاد 🔥';

  @override
  String get contextWorship => 'فصل عبادی';

  @override
  String get energyLevelHighSymbol => 'بالا 🔥';

  @override
  String get energyLevelLowSymbol => 'پایین 💤';

  @override
  String get energyLevelMediumSymbol => 'متوسط ⚡';

  @override
  String get outOfRealmSymbol => 'خارج از قلمرو 🌐';

  @override
  String get resolveScheduleConflict => '⚡ رفع تداخل برنامه';

  @override
  String get labelContext => 'بستر:';

  @override
  String get labelEnergy => 'انرژی:';

  @override
  String get labelRealm => 'قلمرو:';

  @override
  String get quickSystemsTitle => 'سیستم‌های سریع';

  @override
  String get systemWorships => 'عبادات';

  @override
  String get systemHealth => 'سلامت';

  @override
  String get systemGoals => 'اهداف';

  @override
  String get systemEducation => 'آموزش';

  @override
  String get worshipItemsToday => '۳ مورد امروز';

  @override
  String medicineToday(int count) {
    return '$count دارو امروز';
  }

  @override
  String get goalsAndPlans => 'اهداف و برنامه‌ها';

  @override
  String get activeCourse => '۱ دوره فعال';

  @override
  String get disabled => 'غیرفعال';

  @override
  String get moduleDisabled => 'ماژول غیرفعال است';

  @override
  String get restAndRecovery => 'استراحت و بازیابی 🌿';

  @override
  String minutesLight(int minutes) {
    return '$minutes دقیقه (سبک)';
  }

  @override
  String minutes(int minutes) {
    return '$minutes دقیقه';
  }

  @override
  String get freeTime => 'زمان آزاد';

  @override
  String get smartAssistantTitle => 'دستیار هوشمند ریتمو';

  @override
  String get focusOnThisToday => 'امروز روی این تمرکز کن:';

  @override
  String get balanceAndImprovement => '🎯 تعادل و بهبود مستمر';

  @override
  String get bestNextAction => 'بهترین کار بعدی برای شما';

  @override
  String get reasonForSuggestion => 'دلیل پیشنهاد:';

  @override
  String get reasonEssential =>
      'این روتین به دلیل اهمیت حیاتی در اولویت است 🎯';

  @override
  String reasonActiveZone(String zone) {
    return 'شما در زون «$zone» هستید 💼';
  }

  @override
  String reasonEnergyLevel(String energy) {
    return 'سطح انرژی شما $energy است ⚡';
  }

  @override
  String get reasonSick =>
      'به دلیل کسالت، برنامه به حالت بهینه سبک تغییر یافته 🤒';

  @override
  String get reasonExam =>
      'با توجه به بازه امتحانات، اولویت یادگیری افزایش یافته 📚';

  @override
  String get reasonBusy =>
      'به دلیل شلوغی برنامه امروز، این کار پیشنهاد بهینه است ⏳';

  @override
  String reasonWorship(String season) {
    return 'با توجه به فصل عبادی جاری ($season) 🌙';
  }

  @override
  String get reasonCompleted => 'کارهای امروز با موفقیت تکمیل شده‌اند ✨';

  @override
  String get reasonRestTime => 'زمان استراحت و ریکاوری است 🍃';

  @override
  String get start => 'شروع';

  @override
  String get whyThisSuggestion => 'چرا این پیشنهاد؟';

  @override
  String get todaysTasksTitle => 'کارهای امروز';

  @override
  String get resolveConflictBtn => '⚡ رفع تداخل';

  @override
  String get viewAll => 'مشاهده همه';

  @override
  String routineDoneMsg(String title) {
    return 'روتین «$title» انجام شد! 🌟';
  }

  @override
  String routineDoneLightMsg(String title) {
    return 'روتین «$title» به صورت سبک انجام شد! ⚡';
  }

  @override
  String routineDoneMinimalMsg(String title) {
    return 'روتین «$title» به صورت حداقلی انجام شد! 🌿';
  }

  @override
  String routineSkippedMsg(String title) {
    return 'روتین «$title» رد شد. ✕';
  }

  @override
  String routinePostponedMsg(String title) {
    return 'روتین «$title» به تعویق افتاد. ⏳';
  }

  @override
  String loggedAtTime(int time) {
    return 'ثبت شده در $time دقیقه پیش';
  }

  @override
  String loggedAtTimeWithNote(int time, String note) {
    return 'ثبت شده در $time دقیقه پیش ($note)';
  }

  @override
  String get basedOnCalculationsAndDefaults =>
      'بر اساس محاسبات و مقادیر پیش‌فرض';

  @override
  String get basedOnDefaults => 'بر اساس پیش‌فرض';

  @override
  String get worshipDebt => 'بدهی عبادی';

  @override
  String snoozeTimeMinutes(int count) {
    return '$count دقیقه';
  }

  @override
  String snoozeTimeHours(int count) {
    return '$count ساعت';
  }

  @override
  String welcomeUser(String name) {
    return 'سلام $name';
  }

  @override
  String get noRoutinesToday => 'هیچ روتینی برای امروز باقی نمانده است. ✨';

  @override
  String get timeLabel => 'ساعت:';

  @override
  String get checkinReminderTitle => 'ثبت وضعیت صبحگاهی (چک‌این) ☀️';

  @override
  String get checkinReminderDesc =>
      'ثبت وضعیت به ریتمو کمک می‌کند برنامه‌تان را متناسب با سطح انرژی‌تان تنظیم کند.';

  @override
  String get reflectionReminderTitle => 'ثبت تأمل و خودارزیابی روزانه 🌙';

  @override
  String get reflectionReminderDesc =>
      'زمانی را برای ارزیابی امروز و یادگیری‌های آن اختصاص دهید.';

  @override
  String get laterOrDismiss => 'بعداً / صرف‌نظر';

  @override
  String get yesRecord => 'بله، ثبت کنم';

  @override
  String get criticalSystemAlerts => 'هشدارهای بحرانی سیستم ⚠️';

  @override
  String get worshipPrayer => 'نماز';

  @override
  String get worshipFast => 'روزه';

  @override
  String get totalDebtsLabel => 'تعداد کل قضاها';

  @override
  String get dailyTargetLabel => 'هدف انجام روزانه';

  @override
  String get cancelBtn => 'انصراف';

  @override
  String get registerDebtBtn => 'ثبت بدهی';

  @override
  String get timeConflictWarning => 'هشدار تداخل زمانی';

  @override
  String medMinIntervalAlert(double minInterval) {
    return 'فاصله زمانی مجاز بین هر بار مصرف این دارو (حداقل $minInterval ساعت) رعایت نشده است. آیا مایل به ثبت مصرف هستید؟';
  }

  @override
  String get overdoseDanger => 'خطر بیش‌مصرف (اوردوز)';

  @override
  String medMaxDosesAlert(int maxDoses) {
    return 'تعداد دفعات مصرف مجاز روزانه این دارو ($maxDoses بار در روز) به سقف خود رسیده است. مصرف بیشتر خطرناک است. آیا مطمئن به ثبت هستید؟';
  }

  @override
  String get dosageUnit => '1 عدد';

  @override
  String medLoggedSuccess(String title) {
    return 'مصرف داروی «$title» با موفقیت ثبت شد.';
  }

  @override
  String get noCancel => 'خیر، لغو ثبت';

  @override
  String get yesLog => 'بله، ثبت مصرف';

  @override
  String refillStockTitle(String title) {
    return 'شارژ مجدد موجودی: $title';
  }

  @override
  String get refillCountLabel => 'تعداد داروی اضافه شده';

  @override
  String get refillStockBtn => 'شارژ موجودی';

  @override
  String niyyahTitle(String title) {
    return 'آماده‌سازی و شروع: $title';
  }

  @override
  String get completionModeFull => 'کامل 🎯';

  @override
  String get completionModeLight => 'سبک ⚡';

  @override
  String get completionModeMinimal => 'حداقلی 🌿';

  @override
  String get startFocusTimer => 'شروع تایمر تمرکز';

  @override
  String get logWithoutTimer => 'ثبت فوری بدون تایمر';

  @override
  String get contextEngineExplanation =>
      'سیستم بر اساس موتور تحلیل بافت (Context Engine)، شرایط زمانی و انرژی فعلی شما را سنجیده است.';

  @override
  String get ritmoSmartAnalysis => 'تحلیل هوشمند ریتمو ✨';

  @override
  String get understood => 'فهمیدم';

  @override
  String get energyManagementTitle => 'مدیریت و تحلیل انرژی ریتمو';

  @override
  String currentDynamicEnergyLabel(String label) {
    return 'درصد پویای انرژی فعلی شما: $label';
  }

  @override
  String get whyThisNumberTitle => 'چرا این عدد؟ (فرمول محاسبه پویای انرژی)';

  @override
  String get calculating => 'در حال محاسبه...';

  @override
  String get setBaseEnergyLabel => 'تنظیم سطح انرژی پایه ثبت دستی:';

  @override
  String get factorsAffectingEnergyLabel =>
      'فاکتورهای مؤثر بر خستگی یا افت انرژی امروز:';

  @override
  String get factorPoorSleep => 'خواب ضعیف 🛌';

  @override
  String get factorHighStress => 'استرس بالا 🧠';

  @override
  String get factorPhysicalFatigue => 'خستگی جسمی 🏋️';

  @override
  String get factorLackOfFocus => 'عدم تمرکز ذهنی 🎯';

  @override
  String get moodNotesPlaceholder => 'توضیحات کوتاه یا خلق‌و‌خو (اختیاری)';

  @override
  String get lackOfFocusStr => 'عدم تمرکز ذهنی';

  @override
  String get energyUpdatedSuccess => 'سطح انرژی با موفقیت به روز شد.';

  @override
  String get saveStatusBtn => 'ثبت و ذخیره‌سازی وضعیت';

  @override
  String get aiSmartAnalysisTitle => 'تحلیل هوشمند دستیار ریتمو (AI)';

  @override
  String get dataSentToAiLabel => 'داده‌های ارسالی به هوش مصنوعی جهت تحلیل:';

  @override
  String bulletCalculatedEnergy(int percent) {
    return '• درصد پویای محاسبه شده فعلی: $percent٪\n';
  }

  @override
  String bulletReportedFactors(String factors) {
    return '• عوامل موقت گزارش شده: $factors\n';
  }

  @override
  String get bulletBiologicalClock => '• فاز ساعت زیستی بدن در ساعت فعلی روز\n';

  @override
  String get bulletSleepHistory =>
      '• تاریخچه خواب اخیر و وضعیت روتین‌های تکمیل‌شده';

  @override
  String get agreeToSendData => 'با ارسال امن داده‌های فوق جهت تحلیل موافقم.';

  @override
  String get noRecommendationFound => 'پیشنهادی یافت نشد.';

  @override
  String get networkErrorMsg => 'خطا در اتصال به شبکه یا دریافت پاسخ.';

  @override
  String get analyzeAndGetRecommendation => 'تحلیل و دریافت پیشنهاد ✨';

  @override
  String get analyzingDataMsg =>
      'در حال تحلیل داده‌های خواب و روتین‌ها توسط هوش مصنوعی...';

  @override
  String get reAnalyze => 'تحلیل مجدد 🔄';

  @override
  String get localEnergyEngineReport => 'گزارش آماری موتور تحلیل انرژی (محلی):';

  @override
  String get insufficientData => 'داده ناکافی';

  @override
  String get goldenHourLabel => 'ساعت طلایی بازدهی:';

  @override
  String get fatigueWindowLabel => 'بازه بیشترین خستگی:';

  @override
  String get productiveDayLabel => 'پربازده‌ترین روز:';

  @override
  String get healthScreenTitle => 'سلامت';

  @override
  String get medicationsToday => 'داروهای امروز';

  @override
  String get doctorVisits => 'نوبت‌های پزشک';

  @override
  String get healthMonitoring => 'پایش سلامت';

  @override
  String get medicalDocuments => 'مدارک پزشکی';

  @override
  String get pregnancyTracker => 'بارداری';

  @override
  String get vaccinations => 'واکسن‌ها';

  @override
  String get allergies => 'آلرژی‌ها';

  @override
  String get medicalProfile => 'پرونده پزشکی';

  @override
  String get doctorVisitsTabUpcoming => 'پیش‌رو';

  @override
  String get doctorVisitsTabPast => 'گذشته';

  @override
  String get doctorVisitsNoUpcoming => 'هیچ نوبت پیش‌رویی ثبت نشده است.';

  @override
  String get doctorVisitsNoPast => 'هیچ نوبت گذشته‌ای ثبت نشده است.';

  @override
  String get doctorVisitsAddTitle => 'ثبت نوبت پزشک';

  @override
  String get doctorVisitsEditTitle => 'ویرایش نوبت پزشک';

  @override
  String get doctorVisitsDoctorName => 'نام پزشک';

  @override
  String get doctorVisitsSpecialty => 'تخصص (اختیاری)';

  @override
  String get doctorVisitsClinicName => 'نام کلینیک (اختیاری)';

  @override
  String get doctorVisitsClinicAddress => 'آدرس (اختیاری)';

  @override
  String get doctorVisitsClinicPhone => 'تلفن (اختیاری)';

  @override
  String get doctorVisitsReason => 'علت مراجعه (اختیاری)';

  @override
  String get doctorVisitsNotes => 'یادداشت‌ها (اختیاری)';

  @override
  String get doctorVisitsDateTime => 'تاریخ و ساعت نوبت';

  @override
  String get doctorVisitsReminder => 'یادآوری قبل از نوبت';

  @override
  String get doctorVisitsType => 'نوع نوبت';

  @override
  String get doctorVisitsTypeInPerson => 'حضوری';

  @override
  String get doctorVisitsTypeOnline => 'آنلاین';

  @override
  String get doctorVisitsTypeTelephone => 'تلفنی';

  @override
  String get doctorVisitsReminderNone => 'بدون یادآوری';

  @override
  String get doctorVisitsReminder15m => '۱۵ دقیقه قبل';

  @override
  String get doctorVisitsReminder30m => '۳۰ دقیقه قبل';

  @override
  String get doctorVisitsReminder1h => '۱ ساعت قبل';

  @override
  String get doctorVisitsReminder2h => '۲ ساعت قبل';

  @override
  String get doctorVisitsReminder1d => '۱ روز قبل';

  @override
  String get doctorVisitsSave => 'ذخیره نوبت';

  @override
  String get doctorVisitsDeleteConfirm =>
      'آیا مطمئن هستید که می‌خواهید این نوبت را حذف کنید؟';

  @override
  String get doctorVisitsAddAttachment => 'افزودن نسخه یا مدرک';

  @override
  String get doctorVisitsDelete => 'حذف نوبت';

  @override
  String get doctorVisitsCancel => 'انصراف';

  @override
  String get doctorVisitsConfirm => 'تایید';

  @override
  String get bloodSugarTitle => 'قند خون';

  @override
  String get bloodSugarValue => 'میزان قند خون (mg/dL)';

  @override
  String get bloodSugarFasting => 'ناشتا';

  @override
  String get bloodSugarBeforeMeal => 'قبل از غذا';

  @override
  String get bloodSugarAfterMeal => 'بعد از غذا';

  @override
  String get bloodSugarBedtime => 'قبل از خواب';

  @override
  String get bloodSugarRandom => 'تصادفی';

  @override
  String get bloodSugarDiabeticFlag => 'کاربر مبتلا به دیابت است';

  @override
  String get bloodSugarInRange => 'در محدوده نرمال';

  @override
  String get bloodSugarLow => 'پایین (افت قند)';

  @override
  String get bloodSugarHigh => 'بالا (قند خون بالا)';

  @override
  String get bloodSugarSave => 'ثبت قند خون';

  @override
  String get bloodSugarHistory => 'تاریخچه سنجش‌ها';

  @override
  String get bloodSugarEnterValue => 'لطفاً میزان قند خون را وارد کنید';

  @override
  String bloodSugarLastLog(Object type, Object value) {
    return 'آخرین سنجش: $value $type';
  }

  @override
  String get bloodPressureTitle => 'فشار خون';

  @override
  String get bloodPressureSystolic => 'فشار سیستولیک (میلی‌متر جیوه)';

  @override
  String get bloodPressureDiastolic => 'فشار دیاستولیک (میلی‌متر جیوه)';

  @override
  String get bloodPressurePulse => 'ضربان قلب (بار در دقیقه)';

  @override
  String get bloodPressureArm => 'دست مورد استفاده';

  @override
  String get bloodPressureArmLeft => 'دست چپ';

  @override
  String get bloodPressureArmRight => 'دست راست';

  @override
  String get bloodPressurePosition => 'وضعیت بدن';

  @override
  String get bloodPressurePositionSitting => 'نشسته';

  @override
  String get bloodPressurePositionStanding => 'ایستاده';

  @override
  String get bloodPressurePositionLying => 'خوابیده';

  @override
  String get bloodPressureSave => 'ثبت فشار خون';

  @override
  String get bloodPressureHistory => 'تاریخچه فشار خون';

  @override
  String bloodPressureLastLog(Object diastolic, Object systolic) {
    return 'آخرین فشار: $systolic/$diastolic';
  }

  @override
  String get vitalSignsTitle => 'علائم حیاتی';

  @override
  String get vitalSignsWeight => 'وزن';

  @override
  String get vitalSignsTemperature => 'دمای بدن';

  @override
  String get vitalSignsSpo2 => 'اکسیژن خون';

  @override
  String get vitalSignsWaist => 'دور کمر';

  @override
  String get vitalSignsHeight => 'قد (سانتی‌متر)';

  @override
  String get vitalSignsSave => 'ثبت علامت حیاتی';

  @override
  String get vitalSignsValue => 'مقدار';

  @override
  String get vitalSignsHistory => 'سابقه علائم حیاتی';

  @override
  String vitalSignsLastWeight(Object value) {
    return 'آخرین وزن: $value کیلوگرم';
  }

  @override
  String vitalSignsBmi(Object label, Object value) {
    return 'شاخص توده بدنی (BMI): $value ($label)';
  }

  @override
  String get vitalSignsBmiUnderweight => 'کمبود وزن';

  @override
  String get vitalSignsBmiNormal => 'نرمال';

  @override
  String get vitalSignsBmiOverweight => 'اضافه وزن';

  @override
  String get vitalSignsBmiObese => 'چاقی';

  @override
  String get medicalDocumentsTitle => 'مدارک پزشکی';

  @override
  String get medicalDocumentsAddTitle => 'ثبت مدرک جدید';

  @override
  String get medicalDocumentsEditTitle => 'ویرایش مدرک';

  @override
  String get medicalDocumentsDocTitle => 'عنوان مدرک';

  @override
  String get medicalDocumentsCategory => 'دسته‌بندی';

  @override
  String get medicalDocumentsDate => 'تاریخ آزمایش / مدرک';

  @override
  String get medicalDocumentsLabName => 'نام آزمایشگاه / مرکز درمان';

  @override
  String get medicalDocumentsSummary => 'خلاصه گزارش';

  @override
  String get medicalDocumentsDoctorNotes => 'توصیه پزشک';

  @override
  String get medicalDocumentsUserNotes => 'یادداشت کاربر';

  @override
  String get medicalDocumentsSelectImages => 'انتخاب تصاویر مدارک';

  @override
  String get medicalDocumentsHistory => 'آرشیو مدارک پزشکی';

  @override
  String get medicalDocumentsNoDocs => 'هیچ مدرک یا آزمایشی ثبت نشده است.';

  @override
  String get medicalDocumentsDeleteConfirm =>
      'آیا مطمئن هستید که می‌خواهید این مدرک و تمامی تصاویر آن را حذف کنید؟';

  @override
  String get medicalDocumentsSave => 'ذخیره مدرک';

  @override
  String medicalDocumentsCount(int count) {
    return '$count مدرک ثبت شده';
  }

  @override
  String get vaccineName => 'نام واکسن';

  @override
  String get vaccineDiseaseTarget => 'بیماری هدف';

  @override
  String get vaccineDoseNumber => 'شماره دوز';

  @override
  String get vaccineTotalDoses => 'تعداد کل دوزها';

  @override
  String get vaccineDateAdministered => 'تاریخ تزریق';

  @override
  String get vaccineNextDoseDue => 'تاریخ دوز بعدی';

  @override
  String get vaccineBatchNumber => 'شماره سری (بچ)';

  @override
  String get vaccineClinicName => 'نام کلینیک / مرکز تزریق';

  @override
  String get vaccineNotes => 'یادداشت‌ها';

  @override
  String get vaccineSave => 'ثبت واکسیناسیون';

  @override
  String vaccineDaysUntilDue(int days) {
    return '$days روز تا دوز بعدی';
  }

  @override
  String vaccineOverdue(int days) {
    return '⚠️ دوز بعدی تأخیر دارد ($days روز تأخیر)';
  }

  @override
  String get vaccineNoDoses => 'هیچ واکسنی ثبت نشده است.';

  @override
  String get allergyName => 'ماده حساسیت‌زا (آلرژن)';

  @override
  String get allergyCategory => 'دسته‌بندی آلرژی';

  @override
  String get allergyCategoryFood => 'غذایی';

  @override
  String get allergyCategoryDrug => 'دارویی';

  @override
  String get allergyCategoryEnvironment => 'محیطی';

  @override
  String get allergyCategoryOther => 'سایر';

  @override
  String get allergyReaction => 'واکنش بدنی / علائم';

  @override
  String get allergySeverity => 'شدت حساسیت';

  @override
  String get allergySeverityMild => 'خفیف';

  @override
  String get allergySeverityModerate => 'متوسط';

  @override
  String get allergySeveritySevere => 'شدید';

  @override
  String get allergySeverityLifeThreatening => 'تهدیدکننده حیات ⚠️';

  @override
  String get allergyDiagnosedDate => 'تاریخ تشخیص';

  @override
  String get allergySave => 'ثبت آلرژی';

  @override
  String get allergyNoAllergies => 'هیچ آلرژی ثبت نشده است.';

  @override
  String get allergyDeleteConfirm =>
      'آیا مطمئن هستید که می‌خواهید این آلرژی را حذف کنید؟';

  @override
  String get pregnancyTitle => 'بارداری';

  @override
  String get pregnancyLmp => 'اولین روز آخرین قاعدگی (LMP)';

  @override
  String get pregnancyEdd => 'تاریخ تخمینی زایمان (EDD)';

  @override
  String get pregnancyStart => 'شروع پایش بارداری';

  @override
  String get pregnancyEnd => 'غیرفعال‌سازی پایش';

  @override
  String pregnancyWeek(int week, int day) {
    return 'هفته $week بارداری (روز $day)';
  }

  @override
  String get pregnancyTrimester1 => 'سه ماهه اول';

  @override
  String get pregnancyTrimester2 => 'سه ماهه دوم';

  @override
  String get pregnancyTrimester3 => 'سه ماهه سوم';

  @override
  String get pregnancyNoTracker => 'پایش فعال بارداری وجود ندارد.';

  @override
  String get cycleSosButton => 'کمک فوری تسکین درد';

  @override
  String get cyclePregnancyActivate => '🤰 فعالسازی حالت بارداری';

  @override
  String get cyclePregnancyConfirmPrompt =>
      'آیا باردار هستید؟ با فعالسازی این حالت، پیگیری چرخه قاعدگی متوقف میشود و اطلاعات دوران بارداری نمایش داده میشود.';

  @override
  String get cyclePregnancyDeactivate => 'بازگشت به حالت عادی';
}
