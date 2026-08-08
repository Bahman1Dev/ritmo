import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @learningGrowthInsightTitle.
  ///
  /// In fa, this message translates to:
  /// **'رشد چشمگیر یادگیری 📈'**
  String get learningGrowthInsightTitle;

  /// No description provided for @learningGrowthInsightMessage.
  ///
  /// In fa, this message translates to:
  /// **'فعالیت‌های یادگیری شما در این هفته نسبت به هفته گذشته {percent}٪ رشد داشته است. مسیر مطالعه خود را ادامه دهید!'**
  String learningGrowthInsightMessage(int percent);

  /// No description provided for @healthDeclineInsightTitle.
  ///
  /// In fa, this message translates to:
  /// **'توجه به سلامت و ورزش ⚠️'**
  String get healthDeclineInsightTitle;

  /// No description provided for @healthDeclineInsightMessage.
  ///
  /// In fa, this message translates to:
  /// **'تعداد روتین‌های سلامتی شما در ۷ روز گذشته {percent}٪ کاهش یافته است. تلاش کنید دوباره آنها را در برنامه قرار دهید.'**
  String healthDeclineInsightMessage(int percent);

  /// No description provided for @morningLeadInsightTitle.
  ///
  /// In fa, this message translates to:
  /// **'برتری عملکرد صبحگاهی ☀️'**
  String get morningLeadInsightTitle;

  /// No description provided for @morningLeadInsightMessage.
  ///
  /// In fa, this message translates to:
  /// **'روتین‌های صبحگاهی شما (۶:۰۰ تا ۱۲:۰۰) نرخ تکمیل بالاتری نسبت به روتین‌های عصرگاهی دارند. برای کارهای مهم‌تر روی صبح‌ها سرمایه‌گذاری کنید.'**
  String get morningLeadInsightMessage;

  /// No description provided for @fatigueWarningInsightTitle.
  ///
  /// In fa, this message translates to:
  /// **'بازه حساس خستگی ⚡'**
  String get fatigueWarningInsightTitle;

  /// No description provided for @fatigueWarningInsightMessage.
  ///
  /// In fa, this message translates to:
  /// **'بازه زمانی {window} شایع‌ترین دوره خستگی و از دست رفتن روتین‌های شماست. در این ساعات تسک‌های سبک‌تر قرار دهید.'**
  String fatigueWarningInsightMessage(String window);

  /// No description provided for @productiveWeekdayInsightTitle.
  ///
  /// In fa, this message translates to:
  /// **'روز درخشان شما 🌟'**
  String get productiveWeekdayInsightTitle;

  /// No description provided for @productiveWeekdayInsightMessage.
  ///
  /// In fa, this message translates to:
  /// **'روز «{weekday}» پربازده‌ترین روز هفته برای شماست. کارهای سنگین و پروژه‌های خود را در این روز برنامه‌ریزی کنید.'**
  String productiveWeekdayInsightMessage(String weekday);

  /// No description provided for @gatheringDataInsightTitle.
  ///
  /// In fa, this message translates to:
  /// **'در حال شناخت ریتم شما 🔍'**
  String get gatheringDataInsightTitle;

  /// No description provided for @gatheringDataInsightMessage.
  ///
  /// In fa, this message translates to:
  /// **'ریتمو برای ارائه تحلیل‌های معتبر نیاز به داده‌های بیشتری دارد. لطفاً به ثبت فعالیت‌های خود ادامه دهید.'**
  String get gatheringDataInsightMessage;

  /// No description provided for @contextExplanationRest.
  ///
  /// In fa, this message translates to:
  /// **'استراحت و بازیابی انرژی 🌿'**
  String get contextExplanationRest;

  /// No description provided for @contextExplanationEssential.
  ///
  /// In fa, this message translates to:
  /// **'سیستم زندگی «{title}» به دلیل اهمیت حیاتی، در اولویت بالاتر قرار گرفت.'**
  String contextExplanationEssential(String title);

  /// No description provided for @contextExplanationSick.
  ///
  /// In fa, this message translates to:
  /// **'به دلیل کسالت و بیماری، روتین‌های فیزیکی تعلیق شده و روتین «{title}» پیشنهاد می‌شود.'**
  String contextExplanationSick(String title);

  /// No description provided for @contextExplanationExam.
  ///
  /// In fa, this message translates to:
  /// **'با توجه به بازه امتحانات، روتین‌های یادگیری و مطالعه نظیر «{title}» تقویت شده‌اند.'**
  String contextExplanationExam(String title);

  /// No description provided for @contextExplanationBusy.
  ///
  /// In fa, this message translates to:
  /// **'به دلیل تراکم بالای برنامه‌های امروز، اقدام بهینه بعدی روتین «{title}» است.'**
  String contextExplanationBusy(String title);

  /// No description provided for @contextExplanationWorship.
  ///
  /// In fa, this message translates to:
  /// **'با توجه به فصل عبادی جاری ({season})، روتین «{title}» پیشنهاد می‌شود.'**
  String contextExplanationWorship(String season, String title);

  /// No description provided for @contextExplanationZone.
  ///
  /// In fa, this message translates to:
  /// **'با توجه به حضور در زون فعال، روتین «{title}» جهت همگامی با ریتم جاری پیشنهاد می‌شود.'**
  String contextExplanationZone(String title);

  /// No description provided for @contextExplanationLowEnergy.
  ///
  /// In fa, this message translates to:
  /// **'با توجه به سطح انرژی پایین، نسخه متناسب از روتین «{title}» پیشنهاد می‌شود.'**
  String contextExplanationLowEnergy(String title);

  /// No description provided for @contextExplanationDynamic.
  ///
  /// In fa, this message translates to:
  /// **'با تحلیل پویای ریتم روزانه، روتین «{title}» به عنوان بهترین اقدام بهینه بعدی پیشنهاد می‌شود.'**
  String contextExplanationDynamic(String title);

  /// No description provided for @hormonalMenstrualAdjustment1.
  ///
  /// In fa, this message translates to:
  /// **'فعالیت‌های سنگین را کاهش دهید'**
  String get hormonalMenstrualAdjustment1;

  /// No description provided for @hormonalMenstrualAdjustment2.
  ///
  /// In fa, this message translates to:
  /// **'بین کارها استراحت کوتاه اضافه کنید'**
  String get hormonalMenstrualAdjustment2;

  /// No description provided for @hormonalMenstrualAdjustment3.
  ///
  /// In fa, this message translates to:
  /// **'روی کارهای سبک و ضروری تمرکز کنید'**
  String get hormonalMenstrualAdjustment3;

  /// No description provided for @hormonalMenstrualAdjustment4.
  ///
  /// In fa, this message translates to:
  /// **'آب کافی بنوشید و استراحت کافی داشته باشید'**
  String get hormonalMenstrualAdjustment4;

  /// No description provided for @hormonalPreCycleAdjustment1.
  ///
  /// In fa, this message translates to:
  /// **'ممکن است خستگی بدنی یا نوسانات انرژی خفیف را تجربه کنید 🔋'**
  String get hormonalPreCycleAdjustment1;

  /// No description provided for @hormonalPreCycleAdjustment2.
  ///
  /// In fa, this message translates to:
  /// **'اولویت‌دهی به کارهای مهم در ساعات اولیه روز ⏰'**
  String get hormonalPreCycleAdjustment2;

  /// No description provided for @hormonalPreCycleAdjustment3.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد می‌شود زمان خواب شبانه را افزایش دهید 🌙'**
  String get hormonalPreCycleAdjustment3;

  /// No description provided for @hormonalPostCycleAdjustment1.
  ///
  /// In fa, this message translates to:
  /// **'سطح انرژی و توانایی تمرکز در حال افزایش است 📈'**
  String get hormonalPostCycleAdjustment1;

  /// No description provided for @hormonalPostCycleAdjustment2.
  ///
  /// In fa, this message translates to:
  /// **'زمان عالی برای شروع برنامه‌ها یا یادگیری کارهای جدید 🎓'**
  String get hormonalPostCycleAdjustment2;

  /// No description provided for @hormonalContextMenstrual.
  ///
  /// In fa, this message translates to:
  /// **'به دلیل فاز قاعدگی فعال، پیشنهاد می‌شود فعالیت‌های بدنی سبک‌تری داشته باشید و زمان ریکاوری را افزایش دهید. 🌸'**
  String get hormonalContextMenstrual;

  /// No description provided for @hormonalContextPreCycle.
  ///
  /// In fa, this message translates to:
  /// **'در فاز پیش از قاعدگی (Pre-cycle)، احتمال خستگی یا حساسیت عاطفی ملایم وجود دارد. انعطاف‌پذیری برنامه به آسایش شما کمک می‌کند. 🧘'**
  String get hormonalContextPreCycle;

  /// No description provided for @hormonalContextPostCycle.
  ///
  /// In fa, this message translates to:
  /// **'در فاز پس از قاعدگی (Post-cycle)، سطح آمادگی ذهنی و انرژی بدنی رو به افزایش است. زمان خوبی برای چالش‌های جدید است. ⚡'**
  String get hormonalContextPostCycle;

  /// No description provided for @hormonalContextNormal.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت بدنی در حالت عادی و متعادل قرار دارد. 🍃'**
  String get hormonalContextNormal;

  /// No description provided for @hormonalContextNoData.
  ///
  /// In fa, this message translates to:
  /// **'هنوز داده کافی برای پیش‌بینی دقیق وضعیت شما وجود ندارد.'**
  String get hormonalContextNoData;

  /// No description provided for @hormonalContextDisabled.
  ///
  /// In fa, this message translates to:
  /// **'ماژول چرخه بدنی فعال نیست.'**
  String get hormonalContextDisabled;

  /// No description provided for @medicineStockAlert.
  ///
  /// In fa, this message translates to:
  /// **'موجودی داروی «{title}» رو‌به‌اتمام است (موجودی فعلی: {count}).'**
  String medicineStockAlert(String title, int count);

  /// No description provided for @timeConflictAlert.
  ///
  /// In fa, this message translates to:
  /// **'تداخل زمانی بین روتین‌های «{title1}» و «{title2}» شناسایی شد.'**
  String timeConflictAlert(String title1, String title2);

  /// No description provided for @pulseCardMoodGood.
  ///
  /// In fa, this message translates to:
  /// **'امروز روز خوبی بوده 🌱'**
  String get pulseCardMoodGood;

  /// No description provided for @pulseCardMoodExcellent.
  ///
  /// In fa, this message translates to:
  /// **'ریتم زندگی شما عالی است! 🌟'**
  String get pulseCardMoodExcellent;

  /// No description provided for @pulseCardMoodRestore.
  ///
  /// In fa, this message translates to:
  /// **'بیا ریتم زندگی را بازیابی کنیم 🌿'**
  String get pulseCardMoodRestore;

  /// No description provided for @pulseCardTitle.
  ///
  /// In fa, this message translates to:
  /// **'نبض زندگی'**
  String get pulseCardTitle;

  /// No description provided for @pulseCardTrend.
  ///
  /// In fa, this message translates to:
  /// **'روند این هفته +۱۱٪'**
  String get pulseCardTrend;

  /// No description provided for @currentEnergyTitle.
  ///
  /// In fa, this message translates to:
  /// **'انرژی فعلی'**
  String get currentEnergyTitle;

  /// No description provided for @manageEnergy.
  ///
  /// In fa, this message translates to:
  /// **'مدیریت انرژی'**
  String get manageEnergy;

  /// No description provided for @currentRealmTitle.
  ///
  /// In fa, this message translates to:
  /// **'قلمرو فعلی'**
  String get currentRealmTitle;

  /// No description provided for @outOfRealm.
  ///
  /// In fa, this message translates to:
  /// **'خارج از قلمرو'**
  String get outOfRealm;

  /// No description provided for @noActiveSchedule.
  ///
  /// In fa, this message translates to:
  /// **'بدون زمان‌بندی فعال'**
  String get noActiveSchedule;

  /// No description provided for @logNewDailyRealm.
  ///
  /// In fa, this message translates to:
  /// **'ثبت قلمرو جدید روزانه'**
  String get logNewDailyRealm;

  /// No description provided for @routinesConnectedToRealm.
  ///
  /// In fa, this message translates to:
  /// **'{count} روتین متصل به این قلمرو'**
  String routinesConnectedToRealm(int count);

  /// No description provided for @addRealm.
  ///
  /// In fa, this message translates to:
  /// **'افزودن قلمرو ›'**
  String get addRealm;

  /// No description provided for @manageRealm.
  ///
  /// In fa, this message translates to:
  /// **'مدیریت قلمرو ›'**
  String get manageRealm;

  /// No description provided for @energyLevelHigh.
  ///
  /// In fa, this message translates to:
  /// **'بالا'**
  String get energyLevelHigh;

  /// No description provided for @energyLevelLow.
  ///
  /// In fa, this message translates to:
  /// **'پایین'**
  String get energyLevelLow;

  /// No description provided for @energyLevelMedium.
  ///
  /// In fa, this message translates to:
  /// **'متوسط'**
  String get energyLevelMedium;

  /// No description provided for @energyDescHigh.
  ///
  /// In fa, this message translates to:
  /// **'آماده برای کارهای عمیق و تمرکز سنگین'**
  String get energyDescHigh;

  /// No description provided for @energyDescLow.
  ///
  /// In fa, this message translates to:
  /// **'زمان مناسب برای استراحت و کار سبک'**
  String get energyDescLow;

  /// No description provided for @energyDescMedium.
  ///
  /// In fa, this message translates to:
  /// **'مناسب برای مطالعه، پروژه‌ها و روتین‌ها'**
  String get energyDescMedium;

  /// No description provided for @contextNormal.
  ///
  /// In fa, this message translates to:
  /// **'عادی 🍃'**
  String get contextNormal;

  /// No description provided for @contextSick.
  ///
  /// In fa, this message translates to:
  /// **'بیماری 🤒'**
  String get contextSick;

  /// No description provided for @contextTravel.
  ///
  /// In fa, this message translates to:
  /// **'سفر ✈️'**
  String get contextTravel;

  /// No description provided for @contextExam.
  ///
  /// In fa, this message translates to:
  /// **'امتحانات 📚'**
  String get contextExam;

  /// No description provided for @contextBusy.
  ///
  /// In fa, this message translates to:
  /// **'مشغله زیاد 🔥'**
  String get contextBusy;

  /// No description provided for @contextWorship.
  ///
  /// In fa, this message translates to:
  /// **'فصل عبادی'**
  String get contextWorship;

  /// No description provided for @energyLevelHighSymbol.
  ///
  /// In fa, this message translates to:
  /// **'بالا 🔥'**
  String get energyLevelHighSymbol;

  /// No description provided for @energyLevelLowSymbol.
  ///
  /// In fa, this message translates to:
  /// **'پایین 💤'**
  String get energyLevelLowSymbol;

  /// No description provided for @energyLevelMediumSymbol.
  ///
  /// In fa, this message translates to:
  /// **'متوسط ⚡'**
  String get energyLevelMediumSymbol;

  /// No description provided for @outOfRealmSymbol.
  ///
  /// In fa, this message translates to:
  /// **'خارج از قلمرو 🌐'**
  String get outOfRealmSymbol;

  /// No description provided for @resolveScheduleConflict.
  ///
  /// In fa, this message translates to:
  /// **'⚡ رفع تداخل برنامه'**
  String get resolveScheduleConflict;

  /// No description provided for @labelContext.
  ///
  /// In fa, this message translates to:
  /// **'بستر:'**
  String get labelContext;

  /// No description provided for @labelEnergy.
  ///
  /// In fa, this message translates to:
  /// **'انرژی:'**
  String get labelEnergy;

  /// No description provided for @labelRealm.
  ///
  /// In fa, this message translates to:
  /// **'حالت:'**
  String get labelRealm;

  /// No description provided for @quickSystemsTitle.
  ///
  /// In fa, this message translates to:
  /// **'سیستم‌های سریع'**
  String get quickSystemsTitle;

  /// No description provided for @systemWorships.
  ///
  /// In fa, this message translates to:
  /// **'عبادات'**
  String get systemWorships;

  /// No description provided for @systemHealth.
  ///
  /// In fa, this message translates to:
  /// **'سلامت'**
  String get systemHealth;

  /// No description provided for @systemGoals.
  ///
  /// In fa, this message translates to:
  /// **'اهداف'**
  String get systemGoals;

  /// No description provided for @systemEducation.
  ///
  /// In fa, this message translates to:
  /// **'آموزش'**
  String get systemEducation;

  /// No description provided for @worshipItemsToday.
  ///
  /// In fa, this message translates to:
  /// **'۳ مورد امروز'**
  String get worshipItemsToday;

  /// No description provided for @medicineToday.
  ///
  /// In fa, this message translates to:
  /// **'{count} دارو امروز'**
  String medicineToday(int count);

  /// No description provided for @goalsAndPlans.
  ///
  /// In fa, this message translates to:
  /// **'اهداف و برنامه‌ها'**
  String get goalsAndPlans;

  /// No description provided for @activeCourse.
  ///
  /// In fa, this message translates to:
  /// **'۱ دوره فعال'**
  String get activeCourse;

  /// No description provided for @disabled.
  ///
  /// In fa, this message translates to:
  /// **'غیرفعال'**
  String get disabled;

  /// No description provided for @moduleDisabled.
  ///
  /// In fa, this message translates to:
  /// **'ماژول غیرفعال است'**
  String get moduleDisabled;

  /// No description provided for @restAndRecovery.
  ///
  /// In fa, this message translates to:
  /// **'استراحت و بازیابی 🌿'**
  String get restAndRecovery;

  /// No description provided for @minutesLight.
  ///
  /// In fa, this message translates to:
  /// **'{minutes} دقیقه (سبک)'**
  String minutesLight(int minutes);

  /// No description provided for @minutes.
  ///
  /// In fa, this message translates to:
  /// **'{minutes} دقیقه'**
  String minutes(int minutes);

  /// No description provided for @freeTime.
  ///
  /// In fa, this message translates to:
  /// **'زمان آزاد'**
  String get freeTime;

  /// No description provided for @smartAssistantTitle.
  ///
  /// In fa, this message translates to:
  /// **'دستیار هوشمند ریتمو'**
  String get smartAssistantTitle;

  /// No description provided for @focusOnThisToday.
  ///
  /// In fa, this message translates to:
  /// **'امروز روی این تمرکز کن:'**
  String get focusOnThisToday;

  /// No description provided for @balanceAndImprovement.
  ///
  /// In fa, this message translates to:
  /// **'🎯 تعادل و بهبود مستمر'**
  String get balanceAndImprovement;

  /// No description provided for @bestNextAction.
  ///
  /// In fa, this message translates to:
  /// **'بهترین کار بعدی برای شما'**
  String get bestNextAction;

  /// No description provided for @reasonForSuggestion.
  ///
  /// In fa, this message translates to:
  /// **'دلیل پیشنهاد:'**
  String get reasonForSuggestion;

  /// No description provided for @reasonEssential.
  ///
  /// In fa, this message translates to:
  /// **'این روتین به دلیل اهمیت حیاتی در اولویت است 🎯'**
  String get reasonEssential;

  /// No description provided for @reasonActiveZone.
  ///
  /// In fa, this message translates to:
  /// **'شما در زون «{zone}» هستید 💼'**
  String reasonActiveZone(String zone);

  /// No description provided for @reasonEnergyLevel.
  ///
  /// In fa, this message translates to:
  /// **'سطح انرژی شما {energy} است ⚡'**
  String reasonEnergyLevel(String energy);

  /// No description provided for @reasonSick.
  ///
  /// In fa, this message translates to:
  /// **'به دلیل کسالت، برنامه به حالت بهینه سبک تغییر یافته 🤒'**
  String get reasonSick;

  /// No description provided for @reasonExam.
  ///
  /// In fa, this message translates to:
  /// **'با توجه به بازه امتحانات، اولویت یادگیری افزایش یافته 📚'**
  String get reasonExam;

  /// No description provided for @reasonBusy.
  ///
  /// In fa, this message translates to:
  /// **'به دلیل شلوغی برنامه امروز، این کار پیشنهاد بهینه است ⏳'**
  String get reasonBusy;

  /// No description provided for @reasonWorship.
  ///
  /// In fa, this message translates to:
  /// **'با توجه به فصل عبادی جاری ({season}) 🌙'**
  String reasonWorship(String season);

  /// No description provided for @reasonCompleted.
  ///
  /// In fa, this message translates to:
  /// **'کارهای امروز با موفقیت تکمیل شده‌اند ✨'**
  String get reasonCompleted;

  /// No description provided for @reasonRestTime.
  ///
  /// In fa, this message translates to:
  /// **'زمان استراحت و ریکاوری است 🍃'**
  String get reasonRestTime;

  /// No description provided for @start.
  ///
  /// In fa, this message translates to:
  /// **'شروع'**
  String get start;

  /// No description provided for @whyThisSuggestion.
  ///
  /// In fa, this message translates to:
  /// **'چرا این پیشنهاد؟'**
  String get whyThisSuggestion;

  /// No description provided for @todaysTasksTitle.
  ///
  /// In fa, this message translates to:
  /// **'کارهای امروز'**
  String get todaysTasksTitle;

  /// No description provided for @resolveConflictBtn.
  ///
  /// In fa, this message translates to:
  /// **'⚡ رفع تداخل'**
  String get resolveConflictBtn;

  /// No description provided for @viewAll.
  ///
  /// In fa, this message translates to:
  /// **'مشاهده همه'**
  String get viewAll;

  /// No description provided for @routineDoneMsg.
  ///
  /// In fa, this message translates to:
  /// **'روتین «{title}» انجام شد! 🌟'**
  String routineDoneMsg(String title);

  /// No description provided for @routineDoneLightMsg.
  ///
  /// In fa, this message translates to:
  /// **'روتین «{title}» به صورت سبک انجام شد! ⚡'**
  String routineDoneLightMsg(String title);

  /// No description provided for @routineDoneMinimalMsg.
  ///
  /// In fa, this message translates to:
  /// **'روتین «{title}» به صورت حداقلی انجام شد! 🌿'**
  String routineDoneMinimalMsg(String title);

  /// No description provided for @routineSkippedMsg.
  ///
  /// In fa, this message translates to:
  /// **'روتین «{title}» رد شد. ✕'**
  String routineSkippedMsg(String title);

  /// No description provided for @routinePostponedMsg.
  ///
  /// In fa, this message translates to:
  /// **'روتین «{title}» به تعویق افتاد. ⏳'**
  String routinePostponedMsg(String title);

  /// No description provided for @loggedAtTime.
  ///
  /// In fa, this message translates to:
  /// **'ثبت شده در {time} دقیقه پیش'**
  String loggedAtTime(int time);

  /// No description provided for @loggedAtTimeWithNote.
  ///
  /// In fa, this message translates to:
  /// **'ثبت شده در {time} دقیقه پیش ({note})'**
  String loggedAtTimeWithNote(int time, String note);

  /// No description provided for @basedOnCalculationsAndDefaults.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس محاسبات و مقادیر پیش‌فرض'**
  String get basedOnCalculationsAndDefaults;

  /// No description provided for @basedOnDefaults.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس پیش‌فرض'**
  String get basedOnDefaults;

  /// No description provided for @worshipDebt.
  ///
  /// In fa, this message translates to:
  /// **'بدهی عبادی'**
  String get worshipDebt;

  /// No description provided for @snoozeTimeMinutes.
  ///
  /// In fa, this message translates to:
  /// **'{count} دقیقه'**
  String snoozeTimeMinutes(int count);

  /// No description provided for @snoozeTimeHours.
  ///
  /// In fa, this message translates to:
  /// **'{count} ساعت'**
  String snoozeTimeHours(int count);

  /// No description provided for @welcomeUser.
  ///
  /// In fa, this message translates to:
  /// **'سلام {name}'**
  String welcomeUser(String name);

  /// No description provided for @noRoutinesToday.
  ///
  /// In fa, this message translates to:
  /// **'هیچ روتینی برای امروز باقی نمانده است. ✨'**
  String get noRoutinesToday;

  /// No description provided for @timeLabel.
  ///
  /// In fa, this message translates to:
  /// **'ساعت:'**
  String get timeLabel;

  /// No description provided for @checkinReminderTitle.
  ///
  /// In fa, this message translates to:
  /// **'ثبت وضعیت صبحگاهی (چک‌این) ☀️'**
  String get checkinReminderTitle;

  /// No description provided for @checkinReminderDesc.
  ///
  /// In fa, this message translates to:
  /// **'ثبت وضعیت به ریتمو کمک می‌کند برنامه‌تان را متناسب با سطح انرژی‌تان تنظیم کند.'**
  String get checkinReminderDesc;

  /// No description provided for @reflectionReminderTitle.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تأمل و خودارزیابی روزانه 🌙'**
  String get reflectionReminderTitle;

  /// No description provided for @reflectionReminderDesc.
  ///
  /// In fa, this message translates to:
  /// **'زمانی را برای ارزیابی امروز و یادگیری‌های آن اختصاص دهید.'**
  String get reflectionReminderDesc;

  /// No description provided for @laterOrDismiss.
  ///
  /// In fa, this message translates to:
  /// **'بعداً / صرف‌نظر'**
  String get laterOrDismiss;

  /// No description provided for @yesRecord.
  ///
  /// In fa, this message translates to:
  /// **'بله، ثبت کنم'**
  String get yesRecord;

  /// No description provided for @criticalSystemAlerts.
  ///
  /// In fa, this message translates to:
  /// **'هشدارهای بحرانی سیستم ⚠️'**
  String get criticalSystemAlerts;

  /// No description provided for @worshipPrayer.
  ///
  /// In fa, this message translates to:
  /// **'نماز'**
  String get worshipPrayer;

  /// No description provided for @worshipFast.
  ///
  /// In fa, this message translates to:
  /// **'روزه'**
  String get worshipFast;

  /// No description provided for @totalDebtsLabel.
  ///
  /// In fa, this message translates to:
  /// **'تعداد کل قضاها'**
  String get totalDebtsLabel;

  /// No description provided for @dailyTargetLabel.
  ///
  /// In fa, this message translates to:
  /// **'هدف انجام روزانه'**
  String get dailyTargetLabel;

  /// No description provided for @cancelBtn.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get cancelBtn;

  /// No description provided for @registerDebtBtn.
  ///
  /// In fa, this message translates to:
  /// **'ثبت بدهی'**
  String get registerDebtBtn;

  /// No description provided for @timeConflictWarning.
  ///
  /// In fa, this message translates to:
  /// **'هشدار تداخل زمانی'**
  String get timeConflictWarning;

  /// No description provided for @medMinIntervalAlert.
  ///
  /// In fa, this message translates to:
  /// **'فاصله زمانی مجاز بین هر بار مصرف این دارو (حداقل {minInterval} ساعت) رعایت نشده است. آیا مایل به ثبت مصرف هستید؟'**
  String medMinIntervalAlert(double minInterval);

  /// No description provided for @overdoseDanger.
  ///
  /// In fa, this message translates to:
  /// **'خطر بیش‌مصرف (اوردوز)'**
  String get overdoseDanger;

  /// No description provided for @medMaxDosesAlert.
  ///
  /// In fa, this message translates to:
  /// **'تعداد دفعات مصرف مجاز روزانه این دارو ({maxDoses} بار در روز) به سقف خود رسیده است. مصرف بیشتر خطرناک است. آیا مطمئن به ثبت هستید؟'**
  String medMaxDosesAlert(int maxDoses);

  /// No description provided for @dosageUnit.
  ///
  /// In fa, this message translates to:
  /// **'1 عدد'**
  String get dosageUnit;

  /// No description provided for @medLoggedSuccess.
  ///
  /// In fa, this message translates to:
  /// **'مصرف داروی «{title}» با موفقیت ثبت شد.'**
  String medLoggedSuccess(String title);

  /// No description provided for @noCancel.
  ///
  /// In fa, this message translates to:
  /// **'خیر، لغو ثبت'**
  String get noCancel;

  /// No description provided for @yesLog.
  ///
  /// In fa, this message translates to:
  /// **'بله، ثبت مصرف'**
  String get yesLog;

  /// No description provided for @refillStockTitle.
  ///
  /// In fa, this message translates to:
  /// **'شارژ مجدد موجودی: {title}'**
  String refillStockTitle(String title);

  /// No description provided for @refillCountLabel.
  ///
  /// In fa, this message translates to:
  /// **'تعداد داروی اضافه شده'**
  String get refillCountLabel;

  /// No description provided for @refillStockBtn.
  ///
  /// In fa, this message translates to:
  /// **'شارژ موجودی'**
  String get refillStockBtn;

  /// No description provided for @niyyahTitle.
  ///
  /// In fa, this message translates to:
  /// **'آماده‌سازی و شروع: {title}'**
  String niyyahTitle(String title);

  /// No description provided for @completionModeFull.
  ///
  /// In fa, this message translates to:
  /// **'کامل 🎯'**
  String get completionModeFull;

  /// No description provided for @completionModeLight.
  ///
  /// In fa, this message translates to:
  /// **'سبک ⚡'**
  String get completionModeLight;

  /// No description provided for @completionModeMinimal.
  ///
  /// In fa, this message translates to:
  /// **'حداقلی 🌿'**
  String get completionModeMinimal;

  /// No description provided for @startFocusTimer.
  ///
  /// In fa, this message translates to:
  /// **'شروع تایمر تمرکز'**
  String get startFocusTimer;

  /// No description provided for @logWithoutTimer.
  ///
  /// In fa, this message translates to:
  /// **'ثبت فوری بدون تایمر'**
  String get logWithoutTimer;

  /// No description provided for @contextEngineExplanation.
  ///
  /// In fa, this message translates to:
  /// **'سیستم بر اساس موتور تحلیل بافت (Context Engine)، شرایط زمانی و انرژی فعلی شما را سنجیده است.'**
  String get contextEngineExplanation;

  /// No description provided for @ritmoSmartAnalysis.
  ///
  /// In fa, this message translates to:
  /// **'تحلیل هوشمند ریتمو ✨'**
  String get ritmoSmartAnalysis;

  /// No description provided for @understood.
  ///
  /// In fa, this message translates to:
  /// **'فهمیدم'**
  String get understood;

  /// No description provided for @energyManagementTitle.
  ///
  /// In fa, this message translates to:
  /// **'مدیریت و تحلیل انرژی ریتمو'**
  String get energyManagementTitle;

  /// No description provided for @currentDynamicEnergyLabel.
  ///
  /// In fa, this message translates to:
  /// **'درصد پویای انرژی فعلی شما: {label}'**
  String currentDynamicEnergyLabel(String label);

  /// No description provided for @whyThisNumberTitle.
  ///
  /// In fa, this message translates to:
  /// **'چرا این عدد؟ (فرمول محاسبه پویای انرژی)'**
  String get whyThisNumberTitle;

  /// No description provided for @calculating.
  ///
  /// In fa, this message translates to:
  /// **'در حال محاسبه...'**
  String get calculating;

  /// No description provided for @setBaseEnergyLabel.
  ///
  /// In fa, this message translates to:
  /// **'تنظیم سطح انرژی پایه ثبت دستی:'**
  String get setBaseEnergyLabel;

  /// No description provided for @factorsAffectingEnergyLabel.
  ///
  /// In fa, this message translates to:
  /// **'فاکتورهای مؤثر بر خستگی یا افت انرژی امروز:'**
  String get factorsAffectingEnergyLabel;

  /// No description provided for @factorPoorSleep.
  ///
  /// In fa, this message translates to:
  /// **'خواب ضعیف 🛌'**
  String get factorPoorSleep;

  /// No description provided for @factorHighStress.
  ///
  /// In fa, this message translates to:
  /// **'استرس بالا 🧠'**
  String get factorHighStress;

  /// No description provided for @factorPhysicalFatigue.
  ///
  /// In fa, this message translates to:
  /// **'خستگی جسمی 🏋️'**
  String get factorPhysicalFatigue;

  /// No description provided for @factorLackOfFocus.
  ///
  /// In fa, this message translates to:
  /// **'عدم تمرکز ذهنی 🎯'**
  String get factorLackOfFocus;

  /// No description provided for @moodNotesPlaceholder.
  ///
  /// In fa, this message translates to:
  /// **'توضیحات کوتاه یا خلق‌و‌خو (اختیاری)'**
  String get moodNotesPlaceholder;

  /// No description provided for @lackOfFocusStr.
  ///
  /// In fa, this message translates to:
  /// **'عدم تمرکز ذهنی'**
  String get lackOfFocusStr;

  /// No description provided for @energyUpdatedSuccess.
  ///
  /// In fa, this message translates to:
  /// **'سطح انرژی با موفقیت به روز شد.'**
  String get energyUpdatedSuccess;

  /// No description provided for @saveStatusBtn.
  ///
  /// In fa, this message translates to:
  /// **'ثبت و ذخیره‌سازی وضعیت'**
  String get saveStatusBtn;

  /// No description provided for @aiSmartAnalysisTitle.
  ///
  /// In fa, this message translates to:
  /// **'تحلیل هوشمند دستیار ریتمو (AI)'**
  String get aiSmartAnalysisTitle;

  /// No description provided for @dataSentToAiLabel.
  ///
  /// In fa, this message translates to:
  /// **'داده‌های ارسالی به هوش مصنوعی جهت تحلیل:'**
  String get dataSentToAiLabel;

  /// No description provided for @bulletCalculatedEnergy.
  ///
  /// In fa, this message translates to:
  /// **'• درصد پویای محاسبه شده فعلی: {percent}٪\n'**
  String bulletCalculatedEnergy(int percent);

  /// No description provided for @bulletReportedFactors.
  ///
  /// In fa, this message translates to:
  /// **'• عوامل موقت گزارش شده: {factors}\n'**
  String bulletReportedFactors(String factors);

  /// No description provided for @bulletBiologicalClock.
  ///
  /// In fa, this message translates to:
  /// **'• فاز ساعت زیستی بدن در ساعت فعلی روز\n'**
  String get bulletBiologicalClock;

  /// No description provided for @bulletSleepHistory.
  ///
  /// In fa, this message translates to:
  /// **'• تاریخچه خواب اخیر و وضعیت روتین‌های تکمیل‌شده'**
  String get bulletSleepHistory;

  /// No description provided for @agreeToSendData.
  ///
  /// In fa, this message translates to:
  /// **'با ارسال امن داده‌های فوق جهت تحلیل موافقم.'**
  String get agreeToSendData;

  /// No description provided for @noRecommendationFound.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهادی یافت نشد.'**
  String get noRecommendationFound;

  /// No description provided for @networkErrorMsg.
  ///
  /// In fa, this message translates to:
  /// **'خطا در اتصال به شبکه یا دریافت پاسخ.'**
  String get networkErrorMsg;

  /// No description provided for @analyzeAndGetRecommendation.
  ///
  /// In fa, this message translates to:
  /// **'تحلیل و دریافت پیشنهاد ✨'**
  String get analyzeAndGetRecommendation;

  /// No description provided for @analyzingDataMsg.
  ///
  /// In fa, this message translates to:
  /// **'در حال تحلیل داده‌های خواب و روتین‌ها توسط هوش مصنوعی...'**
  String get analyzingDataMsg;

  /// No description provided for @reAnalyze.
  ///
  /// In fa, this message translates to:
  /// **'تحلیل مجدد 🔄'**
  String get reAnalyze;

  /// No description provided for @localEnergyEngineReport.
  ///
  /// In fa, this message translates to:
  /// **'گزارش آماری موتور تحلیل انرژی (محلی):'**
  String get localEnergyEngineReport;

  /// No description provided for @insufficientData.
  ///
  /// In fa, this message translates to:
  /// **'داده ناکافی'**
  String get insufficientData;

  /// No description provided for @goldenHourLabel.
  ///
  /// In fa, this message translates to:
  /// **'ساعت طلایی بازدهی:'**
  String get goldenHourLabel;

  /// No description provided for @fatigueWindowLabel.
  ///
  /// In fa, this message translates to:
  /// **'بازه بیشترین خستگی:'**
  String get fatigueWindowLabel;

  /// No description provided for @productiveDayLabel.
  ///
  /// In fa, this message translates to:
  /// **'پربازده‌ترین روز:'**
  String get productiveDayLabel;

  /// No description provided for @healthScreenTitle.
  ///
  /// In fa, this message translates to:
  /// **'سلامت'**
  String get healthScreenTitle;

  /// No description provided for @medicationsToday.
  ///
  /// In fa, this message translates to:
  /// **'داروهای امروز'**
  String get medicationsToday;

  /// No description provided for @doctorVisits.
  ///
  /// In fa, this message translates to:
  /// **'نوبت‌های پزشک'**
  String get doctorVisits;

  /// No description provided for @healthMonitoring.
  ///
  /// In fa, this message translates to:
  /// **'پایش سلامت'**
  String get healthMonitoring;

  /// No description provided for @medicalDocuments.
  ///
  /// In fa, this message translates to:
  /// **'مدارک پزشکی'**
  String get medicalDocuments;

  /// No description provided for @pregnancyTracker.
  ///
  /// In fa, this message translates to:
  /// **'بارداری'**
  String get pregnancyTracker;

  /// No description provided for @vaccinations.
  ///
  /// In fa, this message translates to:
  /// **'واکسن‌ها'**
  String get vaccinations;

  /// No description provided for @allergies.
  ///
  /// In fa, this message translates to:
  /// **'آلرژی‌ها'**
  String get allergies;

  /// No description provided for @medicalProfile.
  ///
  /// In fa, this message translates to:
  /// **'پرونده پزشکی'**
  String get medicalProfile;

  /// No description provided for @doctorVisitsTabUpcoming.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌رو'**
  String get doctorVisitsTabUpcoming;

  /// No description provided for @doctorVisitsTabPast.
  ///
  /// In fa, this message translates to:
  /// **'گذشته'**
  String get doctorVisitsTabPast;

  /// No description provided for @doctorVisitsNoUpcoming.
  ///
  /// In fa, this message translates to:
  /// **'هیچ نوبت پیش‌رویی ثبت نشده است.'**
  String get doctorVisitsNoUpcoming;

  /// No description provided for @doctorVisitsNoPast.
  ///
  /// In fa, this message translates to:
  /// **'هیچ نوبت گذشته‌ای ثبت نشده است.'**
  String get doctorVisitsNoPast;

  /// No description provided for @doctorVisitsAddTitle.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نوبت پزشک'**
  String get doctorVisitsAddTitle;

  /// No description provided for @doctorVisitsEditTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش نوبت پزشک'**
  String get doctorVisitsEditTitle;

  /// No description provided for @doctorVisitsDoctorName.
  ///
  /// In fa, this message translates to:
  /// **'نام پزشک'**
  String get doctorVisitsDoctorName;

  /// No description provided for @doctorVisitsSpecialty.
  ///
  /// In fa, this message translates to:
  /// **'تخصص (اختیاری)'**
  String get doctorVisitsSpecialty;

  /// No description provided for @doctorVisitsClinicName.
  ///
  /// In fa, this message translates to:
  /// **'نام کلینیک (اختیاری)'**
  String get doctorVisitsClinicName;

  /// No description provided for @doctorVisitsClinicAddress.
  ///
  /// In fa, this message translates to:
  /// **'آدرس (اختیاری)'**
  String get doctorVisitsClinicAddress;

  /// No description provided for @doctorVisitsClinicPhone.
  ///
  /// In fa, this message translates to:
  /// **'تلفن (اختیاری)'**
  String get doctorVisitsClinicPhone;

  /// No description provided for @doctorVisitsReason.
  ///
  /// In fa, this message translates to:
  /// **'علت مراجعه (اختیاری)'**
  String get doctorVisitsReason;

  /// No description provided for @doctorVisitsNotes.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت‌ها (اختیاری)'**
  String get doctorVisitsNotes;

  /// No description provided for @doctorVisitsDateTime.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ و ساعت نوبت'**
  String get doctorVisitsDateTime;

  /// No description provided for @doctorVisitsReminder.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری قبل از نوبت'**
  String get doctorVisitsReminder;

  /// No description provided for @doctorVisitsType.
  ///
  /// In fa, this message translates to:
  /// **'نوع نوبت'**
  String get doctorVisitsType;

  /// No description provided for @doctorVisitsTypeInPerson.
  ///
  /// In fa, this message translates to:
  /// **'حضوری'**
  String get doctorVisitsTypeInPerson;

  /// No description provided for @doctorVisitsTypeOnline.
  ///
  /// In fa, this message translates to:
  /// **'آنلاین'**
  String get doctorVisitsTypeOnline;

  /// No description provided for @doctorVisitsTypeTelephone.
  ///
  /// In fa, this message translates to:
  /// **'تلفنی'**
  String get doctorVisitsTypeTelephone;

  /// No description provided for @doctorVisitsReminderNone.
  ///
  /// In fa, this message translates to:
  /// **'بدون یادآوری'**
  String get doctorVisitsReminderNone;

  /// No description provided for @doctorVisitsReminder15m.
  ///
  /// In fa, this message translates to:
  /// **'۱۵ دقیقه قبل'**
  String get doctorVisitsReminder15m;

  /// No description provided for @doctorVisitsReminder30m.
  ///
  /// In fa, this message translates to:
  /// **'۳۰ دقیقه قبل'**
  String get doctorVisitsReminder30m;

  /// No description provided for @doctorVisitsReminder1h.
  ///
  /// In fa, this message translates to:
  /// **'۱ ساعت قبل'**
  String get doctorVisitsReminder1h;

  /// No description provided for @doctorVisitsReminder2h.
  ///
  /// In fa, this message translates to:
  /// **'۲ ساعت قبل'**
  String get doctorVisitsReminder2h;

  /// No description provided for @doctorVisitsReminder1d.
  ///
  /// In fa, this message translates to:
  /// **'۱ روز قبل'**
  String get doctorVisitsReminder1d;

  /// No description provided for @doctorVisitsSave.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره نوبت'**
  String get doctorVisitsSave;

  /// No description provided for @doctorVisitsDeleteConfirm.
  ///
  /// In fa, this message translates to:
  /// **'آیا مطمئن هستید که می‌خواهید این نوبت را حذف کنید؟'**
  String get doctorVisitsDeleteConfirm;

  /// No description provided for @doctorVisitsAddAttachment.
  ///
  /// In fa, this message translates to:
  /// **'افزودن نسخه یا مدرک'**
  String get doctorVisitsAddAttachment;

  /// No description provided for @doctorVisitsDelete.
  ///
  /// In fa, this message translates to:
  /// **'حذف نوبت'**
  String get doctorVisitsDelete;

  /// No description provided for @doctorVisitsCancel.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get doctorVisitsCancel;

  /// No description provided for @doctorVisitsConfirm.
  ///
  /// In fa, this message translates to:
  /// **'تایید'**
  String get doctorVisitsConfirm;

  /// No description provided for @bloodSugarTitle.
  ///
  /// In fa, this message translates to:
  /// **'قند خون'**
  String get bloodSugarTitle;

  /// No description provided for @bloodSugarValue.
  ///
  /// In fa, this message translates to:
  /// **'میزان قند خون (mg/dL)'**
  String get bloodSugarValue;

  /// No description provided for @bloodSugarFasting.
  ///
  /// In fa, this message translates to:
  /// **'ناشتا'**
  String get bloodSugarFasting;

  /// No description provided for @bloodSugarBeforeMeal.
  ///
  /// In fa, this message translates to:
  /// **'قبل از غذا'**
  String get bloodSugarBeforeMeal;

  /// No description provided for @bloodSugarAfterMeal.
  ///
  /// In fa, this message translates to:
  /// **'بعد از غذا'**
  String get bloodSugarAfterMeal;

  /// No description provided for @bloodSugarBedtime.
  ///
  /// In fa, this message translates to:
  /// **'قبل از خواب'**
  String get bloodSugarBedtime;

  /// No description provided for @bloodSugarRandom.
  ///
  /// In fa, this message translates to:
  /// **'تصادفی'**
  String get bloodSugarRandom;

  /// No description provided for @bloodSugarDiabeticFlag.
  ///
  /// In fa, this message translates to:
  /// **'کاربر مبتلا به دیابت است'**
  String get bloodSugarDiabeticFlag;

  /// No description provided for @bloodSugarInRange.
  ///
  /// In fa, this message translates to:
  /// **'در محدوده نرمال'**
  String get bloodSugarInRange;

  /// No description provided for @bloodSugarLow.
  ///
  /// In fa, this message translates to:
  /// **'پایین (افت قند)'**
  String get bloodSugarLow;

  /// No description provided for @bloodSugarHigh.
  ///
  /// In fa, this message translates to:
  /// **'بالا (قند خون بالا)'**
  String get bloodSugarHigh;

  /// No description provided for @bloodSugarSave.
  ///
  /// In fa, this message translates to:
  /// **'ثبت قند خون'**
  String get bloodSugarSave;

  /// No description provided for @bloodSugarHistory.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه سنجش‌ها'**
  String get bloodSugarHistory;

  /// No description provided for @bloodSugarEnterValue.
  ///
  /// In fa, this message translates to:
  /// **'لطفاً میزان قند خون را وارد کنید'**
  String get bloodSugarEnterValue;

  /// No description provided for @bloodSugarLastLog.
  ///
  /// In fa, this message translates to:
  /// **'آخرین سنجش: {value} {type}'**
  String bloodSugarLastLog(Object type, Object value);

  /// No description provided for @bloodPressureTitle.
  ///
  /// In fa, this message translates to:
  /// **'فشار خون'**
  String get bloodPressureTitle;

  /// No description provided for @bloodPressureSystolic.
  ///
  /// In fa, this message translates to:
  /// **'فشار سیستولیک (میلی‌متر جیوه)'**
  String get bloodPressureSystolic;

  /// No description provided for @bloodPressureDiastolic.
  ///
  /// In fa, this message translates to:
  /// **'فشار دیاستولیک (میلی‌متر جیوه)'**
  String get bloodPressureDiastolic;

  /// No description provided for @bloodPressurePulse.
  ///
  /// In fa, this message translates to:
  /// **'ضربان قلب (بار در دقیقه)'**
  String get bloodPressurePulse;

  /// No description provided for @bloodPressureArm.
  ///
  /// In fa, this message translates to:
  /// **'دست مورد استفاده'**
  String get bloodPressureArm;

  /// No description provided for @bloodPressureArmLeft.
  ///
  /// In fa, this message translates to:
  /// **'دست چپ'**
  String get bloodPressureArmLeft;

  /// No description provided for @bloodPressureArmRight.
  ///
  /// In fa, this message translates to:
  /// **'دست راست'**
  String get bloodPressureArmRight;

  /// No description provided for @bloodPressurePosition.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت بدن'**
  String get bloodPressurePosition;

  /// No description provided for @bloodPressurePositionSitting.
  ///
  /// In fa, this message translates to:
  /// **'نشسته'**
  String get bloodPressurePositionSitting;

  /// No description provided for @bloodPressurePositionStanding.
  ///
  /// In fa, this message translates to:
  /// **'ایستاده'**
  String get bloodPressurePositionStanding;

  /// No description provided for @bloodPressurePositionLying.
  ///
  /// In fa, this message translates to:
  /// **'خوابیده'**
  String get bloodPressurePositionLying;

  /// No description provided for @bloodPressureSave.
  ///
  /// In fa, this message translates to:
  /// **'ثبت فشار خون'**
  String get bloodPressureSave;

  /// No description provided for @bloodPressureHistory.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه فشار خون'**
  String get bloodPressureHistory;

  /// No description provided for @bloodPressureLastLog.
  ///
  /// In fa, this message translates to:
  /// **'آخرین فشار: {systolic}/{diastolic}'**
  String bloodPressureLastLog(Object diastolic, Object systolic);

  /// No description provided for @vitalSignsTitle.
  ///
  /// In fa, this message translates to:
  /// **'علائم حیاتی'**
  String get vitalSignsTitle;

  /// No description provided for @vitalSignsWeight.
  ///
  /// In fa, this message translates to:
  /// **'وزن'**
  String get vitalSignsWeight;

  /// No description provided for @vitalSignsTemperature.
  ///
  /// In fa, this message translates to:
  /// **'دمای بدن'**
  String get vitalSignsTemperature;

  /// No description provided for @vitalSignsSpo2.
  ///
  /// In fa, this message translates to:
  /// **'اکسیژن خون'**
  String get vitalSignsSpo2;

  /// No description provided for @vitalSignsWaist.
  ///
  /// In fa, this message translates to:
  /// **'دور کمر'**
  String get vitalSignsWaist;

  /// No description provided for @vitalSignsHeight.
  ///
  /// In fa, this message translates to:
  /// **'قد (سانتی‌متر)'**
  String get vitalSignsHeight;

  /// No description provided for @vitalSignsSave.
  ///
  /// In fa, this message translates to:
  /// **'ثبت علامت حیاتی'**
  String get vitalSignsSave;

  /// No description provided for @vitalSignsValue.
  ///
  /// In fa, this message translates to:
  /// **'مقدار'**
  String get vitalSignsValue;

  /// No description provided for @vitalSignsHistory.
  ///
  /// In fa, this message translates to:
  /// **'سابقه علائم حیاتی'**
  String get vitalSignsHistory;

  /// No description provided for @vitalSignsLastWeight.
  ///
  /// In fa, this message translates to:
  /// **'آخرین وزن: {value} کیلوگرم'**
  String vitalSignsLastWeight(Object value);

  /// No description provided for @vitalSignsBmi.
  ///
  /// In fa, this message translates to:
  /// **'شاخص توده بدنی (BMI): {value} ({label})'**
  String vitalSignsBmi(Object label, Object value);

  /// No description provided for @vitalSignsBmiUnderweight.
  ///
  /// In fa, this message translates to:
  /// **'کمبود وزن'**
  String get vitalSignsBmiUnderweight;

  /// No description provided for @vitalSignsBmiNormal.
  ///
  /// In fa, this message translates to:
  /// **'نرمال'**
  String get vitalSignsBmiNormal;

  /// No description provided for @vitalSignsBmiOverweight.
  ///
  /// In fa, this message translates to:
  /// **'اضافه وزن'**
  String get vitalSignsBmiOverweight;

  /// No description provided for @vitalSignsBmiObese.
  ///
  /// In fa, this message translates to:
  /// **'چاقی'**
  String get vitalSignsBmiObese;

  /// No description provided for @medicalDocumentsTitle.
  ///
  /// In fa, this message translates to:
  /// **'مدارک پزشکی'**
  String get medicalDocumentsTitle;

  /// No description provided for @medicalDocumentsAddTitle.
  ///
  /// In fa, this message translates to:
  /// **'ثبت مدرک جدید'**
  String get medicalDocumentsAddTitle;

  /// No description provided for @medicalDocumentsEditTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش مدرک'**
  String get medicalDocumentsEditTitle;

  /// No description provided for @medicalDocumentsDocTitle.
  ///
  /// In fa, this message translates to:
  /// **'عنوان مدرک'**
  String get medicalDocumentsDocTitle;

  /// No description provided for @medicalDocumentsCategory.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌بندی'**
  String get medicalDocumentsCategory;

  /// No description provided for @medicalDocumentsDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ آزمایش / مدرک'**
  String get medicalDocumentsDate;

  /// No description provided for @medicalDocumentsLabName.
  ///
  /// In fa, this message translates to:
  /// **'نام آزمایشگاه / مرکز درمان'**
  String get medicalDocumentsLabName;

  /// No description provided for @medicalDocumentsSummary.
  ///
  /// In fa, this message translates to:
  /// **'خلاصه گزارش'**
  String get medicalDocumentsSummary;

  /// No description provided for @medicalDocumentsDoctorNotes.
  ///
  /// In fa, this message translates to:
  /// **'توصیه پزشک'**
  String get medicalDocumentsDoctorNotes;

  /// No description provided for @medicalDocumentsUserNotes.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت کاربر'**
  String get medicalDocumentsUserNotes;

  /// No description provided for @medicalDocumentsSelectImages.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تصاویر مدارک'**
  String get medicalDocumentsSelectImages;

  /// No description provided for @medicalDocumentsHistory.
  ///
  /// In fa, this message translates to:
  /// **'آرشیو مدارک پزشکی'**
  String get medicalDocumentsHistory;

  /// No description provided for @medicalDocumentsNoDocs.
  ///
  /// In fa, this message translates to:
  /// **'هیچ مدرک یا آزمایشی ثبت نشده است.'**
  String get medicalDocumentsNoDocs;

  /// No description provided for @medicalDocumentsDeleteConfirm.
  ///
  /// In fa, this message translates to:
  /// **'آیا مطمئن هستید که می‌خواهید این مدرک و تمامی تصاویر آن را حذف کنید؟'**
  String get medicalDocumentsDeleteConfirm;

  /// No description provided for @medicalDocumentsSave.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره مدرک'**
  String get medicalDocumentsSave;

  /// No description provided for @medicalDocumentsCount.
  ///
  /// In fa, this message translates to:
  /// **'{count} مدرک ثبت شده'**
  String medicalDocumentsCount(int count);

  /// No description provided for @vaccineName.
  ///
  /// In fa, this message translates to:
  /// **'نام واکسن'**
  String get vaccineName;

  /// No description provided for @vaccineDiseaseTarget.
  ///
  /// In fa, this message translates to:
  /// **'بیماری هدف'**
  String get vaccineDiseaseTarget;

  /// No description provided for @vaccineDoseNumber.
  ///
  /// In fa, this message translates to:
  /// **'شماره دوز'**
  String get vaccineDoseNumber;

  /// No description provided for @vaccineTotalDoses.
  ///
  /// In fa, this message translates to:
  /// **'تعداد کل دوزها'**
  String get vaccineTotalDoses;

  /// No description provided for @vaccineDateAdministered.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تزریق'**
  String get vaccineDateAdministered;

  /// No description provided for @vaccineNextDoseDue.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ دوز بعدی'**
  String get vaccineNextDoseDue;

  /// No description provided for @vaccineBatchNumber.
  ///
  /// In fa, this message translates to:
  /// **'شماره سری (بچ)'**
  String get vaccineBatchNumber;

  /// No description provided for @vaccineClinicName.
  ///
  /// In fa, this message translates to:
  /// **'نام کلینیک / مرکز تزریق'**
  String get vaccineClinicName;

  /// No description provided for @vaccineNotes.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت‌ها'**
  String get vaccineNotes;

  /// No description provided for @vaccineSave.
  ///
  /// In fa, this message translates to:
  /// **'ثبت واکسیناسیون'**
  String get vaccineSave;

  /// No description provided for @vaccineDaysUntilDue.
  ///
  /// In fa, this message translates to:
  /// **'{days} روز تا دوز بعدی'**
  String vaccineDaysUntilDue(int days);

  /// No description provided for @vaccineOverdue.
  ///
  /// In fa, this message translates to:
  /// **'⚠️ دوز بعدی تأخیر دارد ({days} روز تأخیر)'**
  String vaccineOverdue(int days);

  /// No description provided for @vaccineNoDoses.
  ///
  /// In fa, this message translates to:
  /// **'هیچ واکسنی ثبت نشده است.'**
  String get vaccineNoDoses;

  /// No description provided for @allergyName.
  ///
  /// In fa, this message translates to:
  /// **'ماده حساسیت‌زا (آلرژن)'**
  String get allergyName;

  /// No description provided for @allergyCategory.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌بندی آلرژی'**
  String get allergyCategory;

  /// No description provided for @allergyCategoryFood.
  ///
  /// In fa, this message translates to:
  /// **'غذایی'**
  String get allergyCategoryFood;

  /// No description provided for @allergyCategoryDrug.
  ///
  /// In fa, this message translates to:
  /// **'دارویی'**
  String get allergyCategoryDrug;

  /// No description provided for @allergyCategoryEnvironment.
  ///
  /// In fa, this message translates to:
  /// **'محیطی'**
  String get allergyCategoryEnvironment;

  /// No description provided for @allergyCategoryOther.
  ///
  /// In fa, this message translates to:
  /// **'سایر'**
  String get allergyCategoryOther;

  /// No description provided for @allergyReaction.
  ///
  /// In fa, this message translates to:
  /// **'واکنش بدنی / علائم'**
  String get allergyReaction;

  /// No description provided for @allergySeverity.
  ///
  /// In fa, this message translates to:
  /// **'شدت حساسیت'**
  String get allergySeverity;

  /// No description provided for @allergySeverityMild.
  ///
  /// In fa, this message translates to:
  /// **'خفیف'**
  String get allergySeverityMild;

  /// No description provided for @allergySeverityModerate.
  ///
  /// In fa, this message translates to:
  /// **'متوسط'**
  String get allergySeverityModerate;

  /// No description provided for @allergySeveritySevere.
  ///
  /// In fa, this message translates to:
  /// **'شدید'**
  String get allergySeveritySevere;

  /// No description provided for @allergySeverityLifeThreatening.
  ///
  /// In fa, this message translates to:
  /// **'تهدیدکننده حیات ⚠️'**
  String get allergySeverityLifeThreatening;

  /// No description provided for @allergyDiagnosedDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تشخیص'**
  String get allergyDiagnosedDate;

  /// No description provided for @allergySave.
  ///
  /// In fa, this message translates to:
  /// **'ثبت آلرژی'**
  String get allergySave;

  /// No description provided for @allergyNoAllergies.
  ///
  /// In fa, this message translates to:
  /// **'هیچ آلرژی ثبت نشده است.'**
  String get allergyNoAllergies;

  /// No description provided for @allergyDeleteConfirm.
  ///
  /// In fa, this message translates to:
  /// **'آیا مطمئن هستید که می‌خواهید این آلرژی را حذف کنید؟'**
  String get allergyDeleteConfirm;

  /// No description provided for @pregnancyTitle.
  ///
  /// In fa, this message translates to:
  /// **'بارداری'**
  String get pregnancyTitle;

  /// No description provided for @pregnancyLmp.
  ///
  /// In fa, this message translates to:
  /// **'اولین روز آخرین قاعدگی (LMP)'**
  String get pregnancyLmp;

  /// No description provided for @pregnancyEdd.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تخمینی زایمان (EDD)'**
  String get pregnancyEdd;

  /// No description provided for @pregnancyStart.
  ///
  /// In fa, this message translates to:
  /// **'شروع پایش بارداری'**
  String get pregnancyStart;

  /// No description provided for @pregnancyEnd.
  ///
  /// In fa, this message translates to:
  /// **'غیرفعال‌سازی پایش'**
  String get pregnancyEnd;

  /// No description provided for @pregnancyWeek.
  ///
  /// In fa, this message translates to:
  /// **'هفته {week} بارداری (روز {day})'**
  String pregnancyWeek(int week, int day);

  /// No description provided for @pregnancyTrimester1.
  ///
  /// In fa, this message translates to:
  /// **'سه ماهه اول'**
  String get pregnancyTrimester1;

  /// No description provided for @pregnancyTrimester2.
  ///
  /// In fa, this message translates to:
  /// **'سه ماهه دوم'**
  String get pregnancyTrimester2;

  /// No description provided for @pregnancyTrimester3.
  ///
  /// In fa, this message translates to:
  /// **'سه ماهه سوم'**
  String get pregnancyTrimester3;

  /// No description provided for @pregnancyNoTracker.
  ///
  /// In fa, this message translates to:
  /// **'پایش فعال بارداری وجود ندارد.'**
  String get pregnancyNoTracker;

  /// No description provided for @cycleSosButton.
  ///
  /// In fa, this message translates to:
  /// **'کمک فوری تسکین درد'**
  String get cycleSosButton;

  /// No description provided for @cyclePregnancyActivate.
  ///
  /// In fa, this message translates to:
  /// **'🤰 فعالسازی حالت بارداری'**
  String get cyclePregnancyActivate;

  /// No description provided for @cyclePregnancyConfirmPrompt.
  ///
  /// In fa, this message translates to:
  /// **'آیا باردار هستید؟ با فعالسازی این حالت، پیگیری چرخه قاعدگی متوقف میشود و اطلاعات دوران بارداری نمایش داده میشود.'**
  String get cyclePregnancyConfirmPrompt;

  /// No description provided for @cyclePregnancyDeactivate.
  ///
  /// In fa, this message translates to:
  /// **'بازگشت به حالت عادی'**
  String get cyclePregnancyDeactivate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
