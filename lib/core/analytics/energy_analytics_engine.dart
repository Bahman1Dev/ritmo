import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/ai/ai_response_processor.dart';
import 'package:ritmo/core/ai/ai_shared_rules.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:sqflite/sqflite.dart';

class EnergyAnalyticsEngineInput {

  // Constructor
  EnergyAnalyticsEngineInput({
    required this.energyLogs,
    required this.routineCompletions,
    required this.dailyRhythm,
    this.sleepDiagList = const [],
    this.now,
    this.validityMinutes = 180,
    this.defaultEnergyLevel = 'MEDIUM',
  });
  final List<Map<String, dynamic>> energyLogs;
  final List<Map<String, dynamic>> routineCompletions;
  final List<Map<String, dynamic>> dailyRhythm;
  final List<Map<String, dynamic>> sleepDiagList;
  final DateTime? now;
  final int validityMinutes;
  final String defaultEnergyLevel;
}

class EnergyAnalyticsOutput {
  EnergyAnalyticsOutput({
    this.peakPerformanceWindow,
    this.mostProductiveWeekday,
    this.mostFatiguedWindow,
    this.currentDynamicEnergy = 0.0,
    this.currentDynamicEnergyExplanations = const [],
    this.sampleCount = 0,
    this.avgLevel,
    this.isAiDerived = false,
  });
  final String? peakPerformanceWindow;
  final String? mostProductiveWeekday;
  final String? mostFatiguedWindow;
  final double currentDynamicEnergy;
  final List<String> currentDynamicEnergyExplanations;
  final int sampleCount;
  final double? avgLevel;
  final bool isAiDerived;

  EnergyAnalyticsOutput copyWith({
    String? peakPerformanceWindow,
    String? mostProductiveWeekday,
    String? mostFatiguedWindow,
    double? currentDynamicEnergy,
    List<String>? currentDynamicEnergyExplanations,
    int? sampleCount,
    double? avgLevel,
    bool? isAiDerived,
  }) {
    return EnergyAnalyticsOutput(
      peakPerformanceWindow: peakPerformanceWindow ?? this.peakPerformanceWindow,
      mostProductiveWeekday: mostProductiveWeekday ?? this.mostProductiveWeekday,
      mostFatiguedWindow: mostFatiguedWindow ?? this.mostFatiguedWindow,
      currentDynamicEnergy: currentDynamicEnergy ?? this.currentDynamicEnergy,
      currentDynamicEnergyExplanations: currentDynamicEnergyExplanations ?? this.currentDynamicEnergyExplanations,
      sampleCount: sampleCount ?? this.sampleCount,
      avgLevel: avgLevel ?? this.avgLevel,
      isAiDerived: isAiDerived ?? this.isAiDerived,
    );
  }
}

class EnergyAnalyticsEngine implements CachedEngine<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput> {
  @override
  Future<EnergyAnalyticsOutput> calculate(EnergyAnalyticsEngineInput input) async {
    final peak = calculatePeakPerformanceWindow(
      energyLogs: input.energyLogs,
      routineCompletions: input.routineCompletions,
      dailyRhythm: input.dailyRhythm,
    );
    final productive = calculateMostProductiveWeekday(
      routineCompletions: input.routineCompletions,
      dailyRhythm: input.dailyRhythm,
    );
    final fatigued = calculateMostFatiguedWindow(
      energyLogs: input.energyLogs,
      routineCompletions: input.routineCompletions,
    );

    final now = input.now ?? DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final logs = input.energyLogs;
    final validityMinutes = input.validityMinutes;
    final defaultLevel = input.defaultEnergyLevel;

    final threeHoursAgo = now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch;
    final recentCompletions = input.routineCompletions.where((comp) {
      final time = comp['completionTime'] as int? ?? 0;
      return time >= threeHoursAgo;
    }).toList();

    final explanations = <String>[];
    var baseLevel = defaultLevel.toUpperCase();
    int? lastManualTime;

    if (logs.isNotEmpty) {
      var latestLog = logs.first;
      for (final log in logs) {
        if ((log['loggedAt'] as int? ?? 0) > (latestLog['loggedAt'] as int? ?? 0)) {
          latestLog = log;
        }
      }
      final loggedAt = latestLog['loggedAt'] as int;
      final differenceMinutes = now.difference(DateTime.fromMillisecondsSinceEpoch(loggedAt)).inMinutes;

      if (differenceMinutes <= validityMinutes) {
        baseLevel = (latestLog['energyLevel'] as String).toUpperCase();
        lastManualTime = loggedAt;
      }
    }

    final currentEnergy = calculateDynamicEnergyLocal(
      baseLevel: baseLevel,
      lastManualTime: lastManualTime,
      validityMinutes: validityMinutes,
      now: now,
      recentCompletions: recentCompletions,
      explanations: explanations,
    );

    final sampleCount = input.energyLogs.length;
    double? avgLevel;
    if (sampleCount > 0) {
      double total = 0;
      for (final l in input.energyLogs) {
        final lvl = (l['energyLevel'] as String? ?? 'MEDIUM').toUpperCase();
        if (lvl == 'HIGH') {
          total += 3.0;
        } else if (lvl == 'LOW') {
          total += 1.0;
        } else {
          total += 2.0;
        }
      }
      avgLevel = total / sampleCount;
    }

    return EnergyAnalyticsOutput(
      peakPerformanceWindow: peak,
      mostProductiveWeekday: productive,
      mostFatiguedWindow: fatigued,
      currentDynamicEnergy: currentEnergy,
      currentDynamicEnergyExplanations: explanations,
      sampleCount: sampleCount,
      avgLevel: avgLevel,
      isAiDerived: false,
    );
  }

  /// Fast local computation for dynamic energy without waiting for network HTTP AI calls
  static double calculateDynamicEnergyLocal({
    required String baseLevel,
    required int? lastManualTime,
    required int validityMinutes,
    required DateTime now,
    required List<Map<String, dynamic>> recentCompletions,
    required List<String> explanations,
  }) {
    double energy;
    if (baseLevel == 'HIGH') {
      energy = 85.0;
      explanations.add('آخرین ثبت سطح انرژی: بالا');
    } else if (baseLevel == 'LOW') {
      energy = 35.0;
      explanations.add('آخرین ثبت سطح انرژی: پایین');
    } else {
      energy = 60.0;
      explanations.add('آخرین ثبت سطح انرژی: متوسط');
    }

    if (lastManualTime != null) {
      final diffMinutes = now.difference(DateTime.fromMillisecondsSinceEpoch(lastManualTime)).inMinutes;
      if (diffMinutes > 0 && diffMinutes <= validityMinutes) {
        final decay = (diffMinutes / validityMinutes) * 10.0;
        energy = (energy - decay).clamp(10.0, 100.0);
      }
    }

    if (recentCompletions.isNotEmpty) {
      final boost = (recentCompletions.length * 3.0).clamp(0.0, 15.0);
      energy = (energy + boost).clamp(10.0, 100.0);
      explanations.add('تأثیر مثبت روتین‌های اخیر (+${boost.toInt()}٪)');
    }

    return energy;
  }

  @override
  Duration get ttl => const Duration(minutes: 5);

  @override
  String fingerprint(EnergyAnalyticsEngineInput input) {
    final nowMs = (input.now ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch;
    final quarter = nowMs ~/ (15 * 60 * 1000);
    return '$quarter|${input.energyLogs.length}|${input.routineCompletions.length}';
  }

  @override
  void invalidate() {}

  @override
  bool canRun(EnergyAnalyticsEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  /// Converts epoch milliseconds to local DateTime.
  static DateTime toIranLocal(int epochMillis) {
    return DateTime.fromMillisecondsSinceEpoch(epochMillis).toLocal();
  }

  /// Calculates the 3-hour peak performance window.
  static String? calculatePeakPerformanceWindow({
    required List<Map<String, dynamic>> energyLogs,
    required List<Map<String, dynamic>> routineCompletions,
    required List<Map<String, dynamic>> dailyRhythm,
  }) {
    if (routineCompletions.length < 5) return null;

    final rhythmMap = {
      for (final r in dailyRhythm) r['date'] as String: (r['rhythmScore'] as num).toDouble()
    };

    final hourScores = List<double>.filled(24, 0);

    for (var h = 0; h < 24; h++) {
      final hEnergyLogs = energyLogs.where((log) {
        final local = DateTime.fromMillisecondsSinceEpoch(log['loggedAt'] as int);
        return local.hour == h;
      }).toList();

      var avgEnergy = 65.0; // default
      if (hEnergyLogs.isNotEmpty) {
        var sumEnergy = 0.0;
        for (final log in hEnergyLogs) {
          final level = (log['energyLevel'] as String).toLowerCase();
          if (level == 'high') {
            sumEnergy += 100.0;
          } else if (level == 'medium') {
            sumEnergy += 65.0;
          } else if (level == 'low') {
            sumEnergy += 30.0;
          } else {
            sumEnergy += 65.0;
          }
        }
        avgEnergy = sumEnergy / hEnergyLogs.length;
      }

      final hCompletions = routineCompletions.where((comp) {
        final local = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
        return local.hour == h;
      }).toList();

      var avgCompletion = 0.0;
      var avgRhythm = 0.0;
      if (hCompletions.isNotEmpty) {
        var sumCompletion = 0.0;
        var sumRhythm = 0.0;
        for (final comp in hCompletions) {
          final type = comp['resultType'] as String?;
          final partialRatio = (comp['partialRatio'] as num?)?.toDouble();
          sumCompletion += CompletionResult.fromDb(type).rhythmWeight(partialRatio);

          final date = comp['completionDate'] as String;
          sumRhythm += rhythmMap[date] ?? 50.0;
        }
        avgCompletion = sumCompletion / hCompletions.length;
        avgRhythm = sumRhythm / hCompletions.length;
      }

      hourScores[h] = 0.4 * avgEnergy + 0.3 * (avgCompletion * 100) + 0.3 * avgRhythm;
    }

    var bestH = 9; // default 09:00 - 12:00
    var bestScore = -1.0;

    for (var h = 0; h < 24; h++) {
      final score = hourScores[h] + hourScores[(h + 1) % 24] + hourScores[(h + 2) % 24];
      if (score > bestScore) {
        bestScore = score;
        bestH = h;
      }
    }

    final endH = (bestH + 3) % 24;
    return "${bestH.toString().padLeft(2, '0')}:00 - ${endH.toString().padLeft(2, '0')}:00";
  }

  /// Calculates the most productive weekday.
  static String? calculateMostProductiveWeekday({
    required List<Map<String, dynamic>> routineCompletions,
    required List<Map<String, dynamic>> dailyRhythm,
  }) {
    final rhythmMap = {
      for (final r in dailyRhythm) r['date'] as String: (r['rhythmScore'] as num).toDouble()
    };

    final weekdayDates = { for (final k in Iterable.generate(7, (i) => i + 1)) k : <String>{} };

    for (final comp in routineCompletions) {
      final local = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
      final date = comp['completionDate'] as String;
      weekdayDates[local.weekday]?.add(date);
    }

    for (var w = 1; w <= 7; w++) {
      if ((weekdayDates[w]?.length ?? 0) < 4) {
        return null;
      }
    }

    final weekdayScores = { for (final k in Iterable.generate(7, (i) => i + 1)) k : 0.0 };

    for (var w = 1; w <= 7; w++) {
      final wCompletions = routineCompletions.where((comp) {
        final local = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
        return local.weekday == w;
      }).toList();

      var avgCompletion = 0.0;
      var avgRhythm = 0.0;

      if (wCompletions.isNotEmpty) {
        var sumCompletion = 0.0;
        var sumRhythm = 0.0;
        for (final comp in wCompletions) {
          final type = comp['resultType'] as String?;
          final partialRatio = (comp['partialRatio'] as num?)?.toDouble();
          sumCompletion += CompletionResult.fromDb(type).rhythmWeight(partialRatio);

          final date = comp['completionDate'] as String;
          sumRhythm += rhythmMap[date] ?? 50.0;
        }
        avgCompletion = sumCompletion / wCompletions.length;
        avgRhythm = sumRhythm / wCompletions.length;
      }

      weekdayScores[w] = (avgCompletion * 100) + avgRhythm;
    }

    var bestW = 1;
    var bestScore = -1.0;
    weekdayScores.forEach((w, score) {
      if (score > bestScore) {
        bestScore = score;
        bestW = w;
      }
    });

    const farsiWeekdays = {
      1: 'دوشنبه',
      2: 'سه‌شنبه',
      3: 'چهارشنبه',
      4: 'پنج‌شنبه',
      5: 'جمعه',
      6: 'شنبه',
      7: 'یک‌شنبه',
    };

    return farsiWeekdays[bestW];
  }

  /// Calculates the most fatigued window.
  static String? calculateMostFatiguedWindow({
    required List<Map<String, dynamic>> energyLogs,
    required List<Map<String, dynamic>> routineCompletions,
  }) {
    final hourFatigue = List<int>.filled(24, 0);

    for (var h = 0; h < 24; h++) {
      final lowEnergyCount = energyLogs.where((log) {
        final local = DateTime.fromMillisecondsSinceEpoch(log['loggedAt'] as int);
        return local.hour == h && (log['energyLevel'] as String).toLowerCase() == 'low';
      }).length;

      final missedRoutinesCount = routineCompletions.where((comp) {
        final local = DateTime.fromMillisecondsSinceEpoch(comp['completionTime'] as int);
        final type = comp['resultType'] as String? ?? 'FULL';
        return local.hour == h && type == 'CANNOT_NOW';
      }).length;

      hourFatigue[h] = lowEnergyCount + missedRoutinesCount;
    }

    var bestH = 15; // default 15:00 - 18:00
    var maxFatigue = -1;

    for (var h = 0; h < 24; h++) {
      final fatigue = hourFatigue[h] + hourFatigue[(h + 1) % 24] + hourFatigue[(h + 2) % 24];
      if (fatigue > maxFatigue) {
        maxFatigue = fatigue;
        bestH = h;
      }
    }

    if (maxFatigue == 0) return null;

    final endH = (bestH + 3) % 24;
    return "${bestH.toString().padLeft(2, '0')}:00 - ${endH.toString().padLeft(2, '0')}:00";
  }

  /// Calculates historical average energy logged for each cycle phase
  static Future<Map<String, double>> calculateCyclePhaseEnergyStats(Database db, Map<String, String> settingsMap) async {
    final phaseValues = <String, List<double>>{
      'MENSTRUAL': [],
      'FOLLICULAR': [],
      'OVULATION': [],
      'LUTEAL': [],
    };

    try {
      final logs = await db.query('energy_logs', orderBy: 'loggedAt DESC', limit: 50);
      for (final log in logs) {
        final loggedAtMs = log['loggedAt']! as int;
        final loggedAt = DateTime.fromMillisecondsSinceEpoch(loggedAtMs);
        final level = (log['energyLevel']! as String).toUpperCase();
        var val = 60.0;
        if (level == 'HIGH') {
          val = 90.0;
        } else if (level == 'LOW') {
          val = 30.0;
        }

        final cycleOut = await CycleEngine().calculate(CycleEngineInput(
          db: db,
          appSettings: settingsMap,
          now: loggedAt,
        ));
        
        final phase = cycleOut.currentPhase.name.toUpperCase();
        if (phaseValues.containsKey(phase)) {
          phaseValues[phase]!.add(val);
        }
      }
    } catch (e) {
      debugPrint('Error calculating historical cycle phase energy stats: $e');
    }

    final averages = <String, double>{};
    phaseValues.forEach((phase, list) {
      if (list.isNotEmpty) {
        final avg = list.reduce((a, b) => a + b) / list.length;
        averages[phase] = avg;
      }
    });
    return averages;
  }

  /// Ultra-advanced hybrid AI energy analyst
  static Future<double> calculateAdvancedDynamicEnergy({
    required String baseLevel,
    required int? lastManualTime,
    required int validityMinutes,
    required DateTime now,
    required List<Map<String, dynamic>> sleepDiagList,
    required List<Map<String, dynamic>> recentCompletions,
    required List<String> explanations,
  }) async {
    var currentEnergy = 60.0;
    var aiSuccess = false;

    // Load cycle information
    var currentPhase = 'NO_DATA';
    var phaseAverages = <String, double>{};

    try {
      final db = await DatabaseHelper.instance.database;
      final settingsList = await db.query('app_settings');
      final settingsMap = {for (final s in settingsList) s['key']! as String: s['value']! as String};

      final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
      final cycleEnabled = settingsMap['module_cycle_enabled'] == 'true';
      final energyConsent = settingsMap['cycle_consent_energy'] == 'true';
      final setupDone = settingsMap['cycle_setup_done'] == 'true';

      if (isFemale && cycleEnabled && energyConsent && setupDone) {
        final cycleOut = await CycleEngine().calculate(CycleEngineInput(
          db: db,
          appSettings: settingsMap,
          now: now,
        ));
        currentPhase = cycleOut.currentPhase.name.toUpperCase();
        phaseAverages = await calculateCyclePhaseEnergyStats(db, settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading cycle data in energy engine: $e');
    }

    // Calculate same-hour anchors from DB
    double? yesterdaySameHourVal;
    double? avg7dSameHourVal;
    try {
      final db = await DatabaseHelper.instance.database;
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStartMs = yesterday.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch;
      final yesterdayEndMs = yesterday.add(const Duration(minutes: 30)).millisecondsSinceEpoch;
      
      final yesterdayLogs = await db.query(
        'energy_logs',
        where: 'loggedAt >= ? AND loggedAt <= ?',
        whereArgs: [yesterdayStartMs, yesterdayEndMs],
        orderBy: 'loggedAt DESC',
      );
      if (yesterdayLogs.isNotEmpty) {
        final level = (yesterdayLogs.first['energyLevel']! as String).toUpperCase();
        yesterdaySameHourVal = level == 'HIGH' ? 90.0 : (level == 'LOW' ? 30.0 : 60.0);
      }

      var sum7d = 0.0;
      var count7d = 0;
      for (var i = 1; i <= 7; i++) {
        final targetDay = now.subtract(Duration(days: i));
        final startMs = targetDay.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch;
        final endMs = targetDay.add(const Duration(minutes: 30)).millisecondsSinceEpoch;
        final dayLogs = await db.query(
          'energy_logs',
          where: 'loggedAt >= ? AND loggedAt <= ?',
          whereArgs: [startMs, endMs],
        );
        for (final log in dayLogs) {
          final level = (log['energyLevel']! as String).toUpperCase();
          sum7d += level == 'HIGH' ? 90.0 : (level == 'LOW' ? 30.0 : 60.0);
          count7d++;
        }
      }
      if (count7d > 0) {
        avg7dSameHourVal = sum7d / count7d;
      }
    } catch (e) {
      debugPrint('Error calculating same-hour anchors in energy engine: $e');
    }

    // Convert local time to Tehran time & day info
    final tehranTime = now.toUtc().add(const Duration(hours: 3, minutes: 30));
    final tehranTimeStr = "${tehranTime.year.toString().padLeft(4, '0')}-${tehranTime.month.toString().padLeft(2, '0')}-${tehranTime.day.toString().padLeft(2, '0')} ${tehranTime.hour.toString().padLeft(2, '0')}:${tehranTime.minute.toString().padLeft(2, '0')}";
    final farsiWeekday = getFarsiWeekday(now.weekday);
    final isFriday = now.weekday == DateTime.friday;

    // 1. Try AI Analysis
    try {
      const systemPrompt = '''
You are the Ritmo Life Operating System Energy Analytics AI.
Your job is to analyze the user's bio-rhythm, sleep, recent routines, and menstrual cycle phase (and historical averages in those phases) to output a predicted current energy percentage (10 to 100) and detailed Farsi explanations.

RULES:
${AnalyticsPromptRules.core}

OUTPUT CONSTRAINTS:
1. "explanations" must contain AT MOST 4 lines.
2. Each explanation line must specify its approximate percentage contribution (e.g. "ساعت زیستی (اوج صبحگاهی): ۱۵٪+").
3. The sum of these percentage contributions must be roughly consistent with the predicted energy's difference from the baseline.
4. Respond ONLY with a valid JSON object matching this schema. Do not output any other markdown tags, comments or text outside the JSON.

FEW-SHOT EXAMPLE:
Input:
- Tehran Time: 2026-07-04 08:30
- Weekday: شنبه
- Circadian Hour: 8
- Base Energy Level Setting: MEDIUM
- Last Night Sleep: 8 hours, 90% efficiency
- Recent completions: Morning Cardio completed
Output:
{
  "energyPercent": 85.0,
  "explanations": [
    "ساعت زیستی (افزایش انرژی صبحگاهی): ۱۵٪+",
    "خواب باکیفیت دیشب: ۱۰٪+",
    "انجام موفق روتین ورزشی صبحگاهی: ۵٪+",
    "انحراف از سطح مبدا متوسط: ۵٪-"
  ]
}
''';

      var formattedSleep = 'N/A';
      if (sleepDiagList.isNotEmpty) {
        formattedSleep = '''
Legend: [durationMinutes: کل مدت خواب به دقیقه | deepSleepMinutes: مدت خواب عمیق | remSleepMinutes: مدت خواب رِم | sleepEfficiency: درصد کیفیت/کارایی خواب از ۰ تا ۱۰۰ | sleepDebt: بدهی خواب انباشته شده به دقیقه]
Data: ${jsonEncode(sleepDiagList.first)}''';
      }

      final formattedCompletions = '''
Legend: [routineId: شناسه روتین | completionTime: زمان انجام به میلی‌ثانیه | category: دسته‌بندی روتین | title: عنوان روتین]
Data: ${jsonEncode(recentCompletions)}''';

      final userPrompt = '''
Tehran Local Time: $tehranTimeStr
Day of Week: $farsiWeekday
Is Today Friday/Holiday?: ${isFriday ? "Yes (تعطیل/جمعه)" : "No"}
Circadian Hour: ${now.hour}
Base Energy Level Setting: $baseLevel
Last Manual Log Time: ${lastManualTime != null ? DateTime.fromMillisecondsSinceEpoch(lastManualTime).toIso8601String() : 'N/A'}

Anchors:
- Energy at this exact hour yesterday: ${yesterdaySameHourVal != null ? "${yesterdaySameHourVal.toStringAsFixed(1)}%" : "N/A"}
- Average energy at this hour in the last 7 days: ${avg7dSameHourVal != null ? "${avg7dSameHourVal.toStringAsFixed(1)}%" : "N/A"}
(Note: Your prediction must be justifiable relative to these anchors and should not jump/deviate unreasonably without clear data triggers like sleep quality or recent exercises).

Menstrual Cycle Status:
- Current Phase: $currentPhase
- Historical Averages for User in different phases:
  * Menstrual Phase Avg: ${phaseAverages['MENSTRUAL']?.toStringAsFixed(1) ?? 'N/A'}%
  * Follicular Phase Avg: ${phaseAverages['FOLLICULAR']?.toStringAsFixed(1) ?? 'N/A'}%
  * Ovulation Phase Avg: ${phaseAverages['OVULATION']?.toStringAsFixed(1) ?? 'N/A'}%
  * Luteal Phase Avg: ${phaseAverages['LUTEAL']?.toStringAsFixed(1) ?? 'N/A'}%

Last Night Sleep:
$formattedSleep

Recent completed routines (last 3 hours):
$formattedCompletions
''';

      final aiResponse = await AIGateway.instance.sendRawCompletion(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        responseFormatJson: true,
      );

      if (aiResponse.isNotEmpty) {
        final parsed = AIResponseProcessor.processRawJson(aiResponse);
        if (parsed != null) {
          final aiPercent = (parsed['energyPercent'] as num?)?.toDouble();
          final aiExps = parsed['explanations'] as List<dynamic>?;
          if (aiPercent != null && aiPercent >= 10.0 && aiPercent <= 100.0) {
            currentEnergy = aiPercent;
            if (aiExps != null) {
              explanations.clear();
              explanations.addAll(aiExps.map((e) => e.toString()));
            }
            explanations.add('تحلیل هوش مصنوعی ریتمو بر اساس ریتم زیستی بدنی 🧠');
            aiSuccess = true;
          }
        }
      }
    } catch (e) {
      debugPrint('AIGateway: Error executing AI energy analysis: $e');
    }

    // 2. Local Advanced Heuristic Fallback
    if (!aiSuccess) {
      explanations.add('تحلیل مدل ریاضی و بیولوژیکی ریتمو ⚡');

      var basePercent = 60.0;
      if (lastManualTime != null) {
        if (baseLevel == 'HIGH') {
          basePercent = 90.0;
        } else if (baseLevel == 'LOW') {
          basePercent = 30.0;
        } else {
          basePercent = 60.0;
        }
        explanations.add('سطح پایه ثبت دستی: $basePercent٪');
      } else {
        if (baseLevel == 'HIGH') {
          basePercent = 80.0;
        } else if (baseLevel == 'LOW') {
          basePercent = 40.0;
        } else {
          basePercent = 60.0;
        }
        explanations.add('سطح پایه پیش‌فرض: $basePercent٪');
      }

      var cycleModifier = 0.0;
      if (currentPhase != 'NO_DATA' && phaseAverages.containsKey(currentPhase)) {
        final avgInPhase = phaseAverages[currentPhase]!;
        cycleModifier = avgInPhase - 60.0;
        
        final phaseLabel = currentPhase == 'MENSTRUAL' ? 'قاعدگی'
            : currentPhase == 'FOLLICULAR' ? 'فولیکولار'
            : currentPhase == 'OVULATION' ? 'تخمک‌گذاری' : 'لوتئال';
            
        if (cycleModifier != 0) {
          final sign = cycleModifier > 0 ? '+' : '';
          explanations.add('ریتم زیستی (فاز $phaseLabel بر اساس تاریخچه شما): $sign$cycleModifier٪');
        }
      } else if (currentPhase == 'MENSTRUAL') {
        cycleModifier = -15.0;
        explanations.add('ریتم زیستی (کاهش انرژی فاز قاعدگی): ۱۵٪-');
      } else if (currentPhase == 'LUTEAL') {
        cycleModifier = -5.0;
        explanations.add('ریتم زیستی (کاهش خفیف انرژی فاز لوتئال): ۵٪-');
      } else if (currentPhase == 'FOLLICULAR' || currentPhase == 'OVULATION') {
        cycleModifier = 10.0;
        explanations.add('ریتم زیستی (تقویت انرژی فاز فولیکولار/تخمک‌گذاری): ۱۰٪+');
      }

      var sleepPenalty = 0.0;
      if (sleepDiagList.isNotEmpty) {
        final lastSleep = sleepDiagList.first;
        final duration = lastSleep['durationMinutes'] as int? ?? 480;
        final reason = (lastSleep['reason'] as String? ?? '').toLowerCase();
        final note = (lastSleep['note'] as String? ?? '').toLowerCase();
        final badSleepKeywords = ['poor', 'late', 'bad', 'restless', 'tired', 'insomnia', 'کم', 'دیر', 'خستگی', 'بی‌خوابی', 'ضعیف'];
        var isBadSleep = duration < 360;
        for (final kw in badSleepKeywords) {
          if (reason.contains(kw) || note.contains(kw)) {
            isBadSleep = true;
            break;
          }
        }
        if (isBadSleep) {
          sleepPenalty = duration < 300 ? 20.0 : 12.0;
          explanations.add('کیفیت خواب ضعیف شب گذشته: $sleepPenalty٪-');
        }
      }

      var circadianMod = 0.0;
      final hour = now.hour;
      if (hour >= 9 && hour < 12) {
        circadianMod = 15.0;
        explanations.add('ساعت زیستی (اوج صبحگاهی): ۱۵٪+');
      } else if (hour >= 12 && hour < 15) {
        circadianMod = -10.0;
        explanations.add('ساعت زیستی (افت بعد از ظهر): ۱۰٪-');
      } else if (hour >= 15 && hour < 18) {
        circadianMod = 5.0;
        explanations.add('ساعت زیستی (بهبود عصرگاهی): ۵٪+');
      } else if (hour >= 18 && hour < 21) {
        circadianMod = 0.0;
      } else if (hour >= 21 && hour < 23) {
        circadianMod = -15.0;
        explanations.add('ساعت زیستی (آماده‌سازی خواب): ۱۵٪-');
      } else {
        circadianMod = -30.0;
        explanations.add('ساعت زیستی (بازه خواب شبانه): ۳۰٪-');
      }

      var fitnessBoost = 0.0;
      var workDrain = 0.0;
      var missedPenalty = 0.0;

      for (final comp in recentCompletions) {
        final type = comp['resultType'] as String? ?? 'FULL';
        final category = (comp['category'] as String? ?? '').toLowerCase();

        if (type == 'FULL' || type == 'LIGHT' || type == 'MINIMAL') {
          if (category == 'fitness') {
            fitnessBoost += 5.0;
          } else if (category == 'work' || category == 'learning' || category == 'konkur') {
            workDrain -= 3.0;
          }
        } else if (type == 'CANNOT_NOW' || type == 'SNOOZED') {
          missedPenalty -= 5.0;
        }
      }

      if (fitnessBoost > 15.0) fitnessBoost = 15.0;
      if (workDrain < -10.0) workDrain = -10.0;
      if (missedPenalty < -15.0) missedPenalty = -15.0;

      if (fitnessBoost > 0) explanations.add('تقویت انرژی (ورزش اخیر): $fitnessBoost٪+');
      if (workDrain < 0) explanations.add('خستگی کار/تحصیل اخیر: ${workDrain.abs()}٪-');
      if (missedPenalty < 0) explanations.add('جریمه روتین‌های معوق/از دست رفته: ${missedPenalty.abs()}٪-');

      var finalVal = basePercent + cycleModifier + circadianMod + fitnessBoost + workDrain + missedPenalty - sleepPenalty;

      if (lastManualTime != null) {
        final diffMin = now.difference(DateTime.fromMillisecondsSinceEpoch(lastManualTime)).inMinutes;
        if (diffMin > 30) {
          final defaultBasePercent = baseLevel == 'HIGH' ? 80.0 : (baseLevel == 'LOW' ? 40.0 : 60.0);
          final baseline = defaultBasePercent + cycleModifier + circadianMod + fitnessBoost + workDrain + missedPenalty - sleepPenalty;
          
          var weightManual = 1.0 - ((diffMin - 30) / (validityMinutes - 30));
          if (weightManual < 0.0) weightManual = 0.0;
          
          finalVal = weightManual * finalVal + (1.0 - weightManual) * baseline;
          explanations.add('وزن‌دهی زوال ثبت دستی: سپری شده $diffMin دقیقه (وزن اثر: ${(weightManual * 100).toInt()}٪)');
        }
      }

      if (finalVal < 10.0) finalVal = 10.0;
      if (finalVal > 100.0) finalVal = 100.0;
      currentEnergy = finalVal;
    }

    return currentEnergy;
  }

  /// Sync wrapper for tests and legacy local dynamic energy calculations
  static double calculateDynamicEnergy({
    required String baseLevel,
    required int? lastManualTime,
    required int validityMinutes,
    required DateTime now,
    required List<Map<String, dynamic>> sleepDiagList,
    required List<Map<String, dynamic>> recentCompletions,
    required List<String> explanationList,
  }) {
    explanationList.add('تحلیل مدل ریاضی و بیولوژیکی ریتمو ⚡');

    var basePercent = 60.0;
    if (lastManualTime != null) {
      if (baseLevel == 'HIGH') {
        basePercent = 90.0;
      } else if (baseLevel == 'LOW') {
        basePercent = 30.0;
      } else {
        basePercent = 60.0;
      }
      explanationList.add('سطح پایه ثبت دستی: $basePercent٪');
    } else {
      if (baseLevel == 'HIGH') {
        basePercent = 80.0;
      } else if (baseLevel == 'LOW') {
        basePercent = 40.0;
      } else {
        basePercent = 60.0;
      }
      explanationList.add('سطح پایه پیش‌فرض: $basePercent٪');
    }

    const cycleModifier = 0.0;

    var circadianMod = 0.0;
    final hour = now.hour;
    if (hour >= 9 && hour < 12) {
      circadianMod = 15.0;
      explanationList.add('ساعت زیستی (اوج صبحگاهی): ۱۵٪+');
    } else if (hour >= 12 && hour < 15) {
      circadianMod = -10.0;
      explanationList.add('ساعت زیستی (افت بعد از ظهر): ۱۰٪-');
    } else if (hour >= 15 && hour < 18) {
      circadianMod = 5.0;
      explanationList.add('ساعت زیستی (بهبود عصرگاهی): ۵٪+');
    } else if (hour >= 18 && hour < 21) {
      circadianMod = 0.0;
      explanationList.add('ساعت زیستی (تثبیت غروب): ۰٪');
    } else if (hour >= 21 && hour < 23) {
      circadianMod = -15.0;
      explanationList.add('ساعت زیستی (آماده‌سازی خواب): ۱۵٪-');
    } else {
      circadianMod = -30.0;
      explanationList.add('ساعت زیستی (بازه خواب شبانه): ۳۰٪-');
    }

    var sleepPenalty = 0.0;
    if (sleepDiagList.isNotEmpty) {
      final lastSleep = sleepDiagList.first;
      final duration = lastSleep['durationMinutes'] as int? ?? 480;
      final reason = (lastSleep['reason'] as String? ?? '').toLowerCase();
      final note = (lastSleep['note'] as String? ?? '').toLowerCase();
      final badSleepKeywords = ['poor', 'late', 'bad', 'restless', 'tired', 'insomnia', 'کم', 'دیر', 'خستگی', 'بی‌خوابی', 'ضعیف'];
      var isBadSleep = duration < 360;
      for (final kw in badSleepKeywords) {
        if (reason.contains(kw) || note.contains(kw)) {
          isBadSleep = true;
          break;
        }
      }
      if (isBadSleep) {
        sleepPenalty = 15.0;
        explanationList.add('جریمه کیفیت خواب ضعیف: ۱۵٪-');
      }
    }

    var fitnessBoost = 0.0;
    var workDrain = 0.0;
    var missedPenalty = 0.0;

    for (final comp in recentCompletions) {
      final type = comp['resultType'] as String? ?? 'FULL';
      final category = (comp['category'] as String? ?? '').toLowerCase();

      if (type == 'FULL' || type == 'LIGHT' || type == 'MINIMAL') {
        if (category == 'fitness') {
          fitnessBoost += 5.0;
        } else if (category == 'work' || category == 'learning' || category == 'konkur') {
          workDrain -= 3.0;
        }
      } else if (type == 'CANNOT_NOW' || type == 'SNOOZED') {
        missedPenalty -= 5.0;
      }
    }

    if (fitnessBoost > 15.0) fitnessBoost = 15.0;
    if (workDrain < -10.0) workDrain = -10.0;
    if (missedPenalty < -15.0) missedPenalty = -15.0;

    if (fitnessBoost > 0) explanationList.add('تقویت انرژی (ورزش اخیر): $fitnessBoost٪+');
    if (workDrain < 0) explanationList.add('خستگی کار/تحصیل اخیر: ${workDrain.abs()}٪-');
    if (missedPenalty < 0) explanationList.add('جریمه روتین‌های معوق/از دست رفته: ${missedPenalty.abs()}٪-');

    var finalVal = basePercent + cycleModifier + circadianMod + fitnessBoost + workDrain + missedPenalty - sleepPenalty;

    if (lastManualTime != null) {
      final diffMin = now.difference(DateTime.fromMillisecondsSinceEpoch(lastManualTime)).inMinutes;
      if (diffMin > 30) {
        final defaultBasePercent = baseLevel == 'HIGH' ? 80.0 : (baseLevel == 'LOW' ? 40.0 : 60.0);
        final baseline = defaultBasePercent + cycleModifier + circadianMod + fitnessBoost + workDrain + missedPenalty - sleepPenalty;
        
        var weightManual = 1.0 - ((diffMin - 30) / (validityMinutes - 30));
        if (weightManual < 0.0) weightManual = 0.0;
        
        finalVal = weightManual * finalVal + (1.0 - weightManual) * baseline;
        explanationList.add('وزن‌دهی زوال ثبت دستی: سپری شده $diffMin دقیقه (وزن اثر: ${(weightManual * 100).toInt()}٪)');
      } else {
        explanationList.add('وزن ثبت دستی: ۱۰۰٪');
      }
    }

    if (finalVal < 10.0) finalVal = 10.0;
    if (finalVal > 100.0) finalVal = 100.0;
    return finalVal;
  }

  static String getFarsiWeekday(int weekday) {
    switch (weekday) {
      case DateTime.saturday: return 'شنبه';
      case DateTime.sunday: return 'یکشنبه';
      case DateTime.monday: return 'دوشنبه';
      case DateTime.tuesday: return 'سه‌شنبه';
      case DateTime.wednesday: return 'چهارشنبه';
      case DateTime.thursday: return 'پنج‌شنبه';
      case DateTime.friday: return 'جمعه';
      default: return '';
    }
  }
}

