import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/models/energy_context.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

class AssistantEngineInput { // from CycleConsentBridge.isEnergyTuned

  AssistantEngineInput({
    required this.routines,
    required this.routineCompletions,
    required this.sleepLogs,
    this.sleepTarget,
    required this.energyLogs,
    required this.moodLogs,
    required this.goals,
    required this.goalSteps,
    required this.konkurStudySessions,
    required this.today,
    this.isProactiveEnabled = true,
    this.isBriefingEnabled = true,
    this.isUserFemale = false,
    this.cycleConsent = false,
    this.isEnergyTuned = false,
  });
  final List<Map<String, dynamic>> routines;
  final List<Map<String, dynamic>> routineCompletions;
  final List<Map<String, dynamic>> sleepLogs;
  final Map<String, dynamic>? sleepTarget;
  final List<Map<String, dynamic>> energyLogs;
  final List<Map<String, dynamic>> moodLogs;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> goalSteps;
  final List<Map<String, dynamic>> konkurStudySessions;
  final DateTime today;
  final bool isProactiveEnabled;
  final bool isBriefingEnabled;
  final bool isUserFemale;
  final bool cycleConsent;
  final bool isEnergyTuned;
}

class AssistantEngineOutput {

  AssistantEngineOutput({
    required this.dailyBriefing,
    required this.nextActions,
    required this.systemHighlights,
    required this.dynamicSuggestions,
    this.todayEnergyContext,
  });
  final DailyBriefing dailyBriefing;
  final List<NextAction> nextActions;
  final List<BriefingItem> systemHighlights;
  final List<String> dynamicSuggestions;
  final EnergyContext? todayEnergyContext;
}

class AssistantEngine implements CachedEngine<AssistantEngineInput, AssistantEngineOutput> {
  @override
  Future<AssistantEngineOutput> calculate(AssistantEngineInput input) async {
    final cleanToday = DateTime(input.today.year, input.today.month, input.today.day);
    final todayStr = _formatDateIso(cleanToday);
    final yesterdayStr = _formatDateIso(cleanToday.subtract(const Duration(days: 1)));

    // 1. Generate system highlights
    final highlights = <BriefingItem>[];
    
    // Sleep Highlight
    final lastNightSleep = input.sleepLogs.where((log) => log['date'] == yesterdayStr).firstOrNull;
    if (lastNightSleep != null) {
      final qScore = lastNightSleep['quality'] as int? ?? 3;
      final duration = lastNightSleep['durationMinutes'] as int? ?? 0;
      final hours = (duration / 60).toStringAsFixed(1);
      highlights.add(BriefingItem(
        system: 'sleep',
        headline: 'خواب دیشب: $hours ساعت با کیفیت $qScore/۵',
      ));
    } else {
      highlights.add(BriefingItem(
        system: 'sleep',
        headline: 'خواب دیشب ثبت نشده است',
      ));
    }

    // Goals Highlight
    final overdueSteps = input.goalSteps.where((step) {
      final sDate = step['scheduledDate'] as String?;
      final isComp = (step['isCompleted'] as int? ?? 0) == 1;
      return sDate != null && sDate.compareTo(todayStr) < 0 && !isComp;
    }).toList();
    if (overdueSteps.isNotEmpty) {
      highlights.add(BriefingItem(
        system: 'goals',
        headline: '${overdueSteps.length} گام هدف عقب‌افتاده دارید',
      ));
    } else {
      highlights.add(BriefingItem(
        system: 'goals',
        headline: 'برنامه اهداف امروز مرتب است',
      ));
    }

    // Routines Highlight
    final todayCompletionsCount = input.routineCompletions.where((c) => c['completionDate'] == todayStr).length;
    final totalRoutines = input.routines.where((r) => (r['isArchived'] as int? ?? 0) == 0).length;
    highlights.add(BriefingItem(
      system: 'routines',
      headline: '$todayCompletionsCount از $totalRoutines روتین امروز انجام شده است',
    ));

    // Energy Highlight
    final latestEnergy = input.energyLogs.isNotEmpty ? input.energyLogs.last : null;
    if (latestEnergy != null) {
      final level = latestEnergy['energyLevel'] as String? ?? 'MEDIUM';
      final levelFa = level == 'HIGH' ? 'بالا' : (level == 'LOW' ? 'پایین' : 'متوسط');
      highlights.add(BriefingItem(
        system: 'energy',
        headline: 'آخرین وضعیت انرژی: $levelFa',
      ));
    }

    // Cycle Highlight (Zero-leak / Indirect via bridge)
    if (input.isUserFemale && input.cycleConsent && input.isEnergyTuned) {
      highlights.add(BriefingItem(
        system: 'cycle',
        headline: 'وضعیت بدنی: نیاز به استراحت و ریکاوری بیشتر',
      ));
    }

    // 2. Rank Next Actions
    final actions = <NextAction>[];

    // Sleep Action (Rank 1)
    if (lastNightSleep == null) {
      actions.add(NextAction(
        title: 'ثبت خواب دیشب',
        reason: 'خواب دیشب ثبت نشده است. برای پایش دقیق بدهی خواب و ثبات ریتم زیستی، لطفاً آن را ثبت کنید.',
        action: AssistantAction(
          type: AssistantActionType.logSleep,
          title: 'ثبت خواب دیشب',
          payload: {},
        ),
        rank: 1,
      ));
    }

    // Overdue Goals (Rank 2)
    if (overdueSteps.isNotEmpty) {
      actions.add(NextAction(
        title: 'بررسی اهداف عقب‌افتاده',
        reason: 'تعداد ${overdueSteps.length} گام هدف از روزهای گذشته باقی مانده است. پیشنهاد می‌کنیم آن‌ها را تیک بزنید یا باززمان‌بندی کنید.',
        action: AssistantAction(
          type: AssistantActionType.openPage,
          title: 'مشاهده صفحه اهداف',
          payload: {},
          targetRoute: '/goals',
        ),
        deepLinkRoute: '/goals',
        rank: 2,
      ));
    }

    // Low Energy (Rank 3)
    if (latestEnergy != null && latestEnergy['energyLevel'] == 'LOW') {
      actions.add(NextAction(
        title: 'ثبت وضعیت انرژی و روحیه',
        reason: 'سطح انرژی ثبت شده شما پایین است. پیشنهاد می‌کنیم با ثبت وضعیت فعلی، نوسان انرژی خود را پایش کنید.',
        action: AssistantAction(
          type: AssistantActionType.logEnergyMood,
          title: 'ثبت وضعیت انرژی',
          payload: {},
        ),
        rank: 3,
      ));
    }

    // Konkur Study (Rank 4)
    final konkurStudyToday = input.konkurStudySessions.where((s) => s['dateIso'] == todayStr).toList();
    if (input.konkurStudySessions.isNotEmpty && konkurStudyToday.isEmpty) {
      actions.add(NextAction(
        title: 'ثبت جلسه مطالعه کنکور',
        reason: 'امروز هنوز هیچ جلسه مطالعه‌ای برای دروس کنکور ثبت نکرده‌اید. پیشرفت خود را ثبت کنید.',
        action: AssistantAction(
          type: AssistantActionType.addKonkurItem,
          title: 'ثبت مطالعه کنکور',
          payload: {},
        ),
        rank: 4,
      ));
    }

    // Remaining Routines (Rank 5)
    final remainingRoutines = totalRoutines - todayCompletionsCount;
    if (remainingRoutines > 0) {
      actions.add(NextAction(
        title: 'اجرای روتین‌های روزانه',
        reason: '$remainingRoutines روتین فعال برای امروز باقی مانده است. برای حفظ زنجیره عادت‌های خود اقدام کنید.',
        action: AssistantAction(
          type: AssistantActionType.openPage,
          title: 'مشاهده روتین‌ها',
          payload: {},
          targetRoute: '/',
        ),
        deepLinkRoute: '/',
        rank: 5,
      ));
    }

    // Sort next actions by rank
    actions.sort((a, b) => a.rank.compareTo(b.rank));

    // 3. Generate Briefing text
    var briefingText = 'سلام! امروز برای شما برنامه‌ریزی منظمی آماده شده است. ';
    if (lastNightSleep == null) {
      briefingText += 'ابتدا خواب دیشب خود را ثبت کنید تا بدهی خواب شما محاسبه شود. ';
    } else {
      final hours = (lastNightSleep['durationMinutes'] as int? ?? 0) / 60;
      if (hours < 6.0) {
        briefingText += 'دیشب خواب کوتاهی داشتید؛ در طول روز استراحت‌های کوتاه فراموش نشود. ';
      } else {
        briefingText += 'خواب دیشب شما کافی بوده است؛ آماده یک روز پرانرژی باشید! ';
      }
    }

    if (overdueSteps.isNotEmpty) {
      briefingText += 'همچنین ${overdueSteps.length} گام هدف عقب‌افتاده دارید که نیازمند توجه است. ';
    }

    if (input.isUserFemale && input.cycleConsent && input.isEnergyTuned) {
      briefingText += 'بر اساس ریتم بدنی فعلی شما، پیشنهاد می‌کنیم امروز کارهای سبک‌تر را در اولویت قرار دهید. ';
    }

    // 4. Dynamic Suggestions
    final suggestions = _buildDynamicSuggestions(
      input,
      hasSleepData: lastNightSleep != null,
      hasLowEnergy: latestEnergy?['energyLevel'] == 'LOW',
      overdueGoalsCount: overdueSteps.length,
      remainingRoutines: totalRoutines - todayCompletionsCount,
      hasKonkurData: input.konkurStudySessions.isNotEmpty,
      todayKonkurSessionCount: konkurStudyToday.length,
    );

    // Apply configuration toggles
    final finalBriefing = DailyBriefing(
      text: input.isBriefingEnabled ? briefingText : '',
      highlights: input.isBriefingEnabled ? highlights : [],
      stats: {
        'todayCompletions': todayCompletionsCount,
        'totalRoutines': totalRoutines,
        'overdueGoalsCount': overdueSteps.length,
      },
    );

    final finalActions = input.isProactiveEnabled ? actions : <NextAction>[];

    final energyLevel = latestEnergy?['energyLevel'] as String? ?? 'MEDIUM';
    final sleepHours = lastNightSleep != null
        ? (lastNightSleep['durationMinutes'] as int? ?? 0) / 60.0
        : 7.0;

    final energyCtx = EnergyContext(
      energyLevel: energyLevel,
      sleepHoursLastNight: sleepHours,
      isCycleRestDay: input.isUserFemale && input.cycleConsent && input.isEnergyTuned,
    );

    return AssistantEngineOutput(
      dailyBriefing: finalBriefing,
      nextActions: finalActions,
      systemHighlights: input.isBriefingEnabled ? highlights : [],
      dynamicSuggestions: suggestions,
      todayEnergyContext: energyCtx,
    );
  }

  List<String> _buildDynamicSuggestions(AssistantEngineInput input, {
    required bool hasSleepData,
    required bool hasLowEnergy,
    required int overdueGoalsCount,
    required int remainingRoutines,
    required bool hasKonkurData,
    required int todayKonkurSessionCount,
  }) {
    final suggestions = <String>[];

    // Sleep-based
    if (!hasSleepData) {
      suggestions.add('خواب دیشب من چند ساعت بود؟ ثبتش کن');
    } else {
      suggestions.add('کیفیت خواب من در این هفته چطور بوده؟');
    }

    // Energy-based
    if (hasLowEnergy) {
      suggestions.add('با انرژی پایین امروز چه کارهایی انجام بدم؟');
    } else {
      suggestions.add('انرژی من الان در چه سطحیه؟');
    }

    // Goals-based
    if (overdueGoalsCount > 2) {
      suggestions.add('$overdueGoalsCount گام هدف عقب مونده — کمکم کن اولویت‌بندی کنم');
    } else if (overdueGoalsCount > 0) {
      suggestions.add('اهداف عقب‌افتاده‌ام رو با هم بررسی کنیم');
    } else {
      suggestions.add('هدف جدیدی بهم پیشنهاد بده');
    }

    // Routines-based
    if (remainingRoutines > 3) {
      suggestions.add('$remainingRoutines روتین باقی مونده — مهم‌ترینشون چیه؟');
    } else if (remainingRoutines > 0) {
      suggestions.add('روتین‌های باقی‌مانده امروزم چیه؟');
    } else {
      suggestions.add('همه روتین‌های امروز انجام شد! قدم بعدی چیه؟');
    }

    // Konkur-based
    if (hasKonkurData) {
      if (todayKonkurSessionCount == 0) {
        suggestions.add('امروز هنوز مطالعه کنکور ثبت نکردم — الان کدوم مبحث بخونم؟');
      } else {
        suggestions.add('پیشرفت مطالعه کنکورم امروز چطوره؟');
      }
    }

    // Always cap at 5
    return suggestions.take(5).toList();
  }

  @override
  Duration get ttl => const Duration(minutes: 15);

  @override
  String fingerprint(AssistantEngineInput input) {
    final dayStamp = _formatDateIso(input.today);
    final nowMins = input.today.hour * 60 + input.today.minute;
    final quarter = nowMins ~/ 15;
    final todayCompletionsCount = input.routineCompletions.length;
    final latestEnergy = input.energyLogs.isNotEmpty ? input.energyLogs.last['loggedAt'] ?? 0 : 0;
    final overdueCount = input.goalSteps.where((step) {
      final sDate = step['scheduledDate'] as String?;
      final isComp = (step['isCompleted'] as int? ?? 0) == 1;
      return sDate != null && sDate.compareTo(dayStamp) < 0 && !isComp;
    }).length;
    return '$dayStamp|$quarter|$todayCompletionsCount|$latestEnergy|$overdueCount';
  }

  @override
  void invalidate() {}

  @override
  bool canRun(AssistantEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
