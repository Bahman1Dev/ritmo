import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/engines/helpers/sensitive_reflection_filter.dart';
import 'package:ritmo/core/behavior/models/behavior_snapshot.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/cache/engine_key.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BehavioralInput {
  BehavioralInput({required this.today});
  final DateTime today;
}

class BehavioralIntelligenceOrchestrator implements CachedEngine<BehavioralInput, BehavioralSnapshot> {
  static const int engineVersionInt = 1;
  static const String snapshotVersionStr = '1.0';

  @override
  Duration get ttl => const Duration(hours: 6);

  @override
  String fingerprint(BehavioralInput input) {
    final dayStamp = input.today.toIso8601String().substring(0, 10);
    return '$dayStamp|$snapshotVersionStr|$engineVersionInt';
  }

  @override
  bool canRun(BehavioralInput input) => true;

  @override
  List<Type> dependencies() => [];

  @override
  void invalidate() {}

  /// The only public static entrypoint to build/retrieve the snapshot.
  static Future<BehavioralSnapshot> buildSnapshot({DateTime? today}) async {
    final cleanToday = today ?? DateTime.now();
    return RitmoEngineBus.instance.execute<BehavioralInput, BehavioralSnapshot>(
      BehavioralIntelligenceOrchestrator,
      BehavioralInput(today: cleanToday),
    );
  }

  @override
  Future<BehavioralSnapshot> calculate(BehavioralInput input) async {
    final cleanToday = DateTime(input.today.year, input.today.month, input.today.day);
    final todayStr = _formatDateIso(cleanToday);
    
    final db = await DatabaseHelper.instance.database;

    // 1. Fetch light metrics to compute behaviorHash
    final startDateStr = _formatDateIso(cleanToday.subtract(const Duration(days: 90)));
    final startTimestamp = cleanToday.subtract(const Duration(days: 90)).millisecondsSinceEpoch;

    final completionsCountList = await db.rawQuery(
      'SELECT COUNT(*) as count FROM routine_completions WHERE completionDate >= ? AND completionDate <= ?',
      [startDateStr, todayStr],
    );
    final completionsCount = completionsCountList.first['count'] as int? ?? 0;

    final energyLogsCountList = await db.rawQuery(
      'SELECT COUNT(*) as count FROM energy_logs WHERE loggedAt >= ?',
      [startTimestamp],
    );
    final energyLogsCount = energyLogsCountList.first['count'] as int? ?? 0;

    final sleepDiagCountList = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bedtime_diagnostics WHERE date >= ? AND date <= ?',
      [startDateStr, todayStr],
    );
    final sleepDiagCount = sleepDiagCountList.first['count'] as int? ?? 0;

    final reflectionsCountList = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_reflections WHERE date >= ? AND date <= ?',
      [startDateStr, todayStr],
    );
    final reflectionsCount = reflectionsCountList.first['count'] as int? ?? 0;

    final occurrencesCountList = await db.rawQuery(
      'SELECT COUNT(*) as count FROM routine_occurrences WHERE date >= ? AND date <= ?',
      [startDateStr, todayStr],
    );
    final occurrencesCount = occurrencesCountList.first['count'] as int? ?? 0;

    final goalsCountList = await db.rawQuery(
      "SELECT COUNT(*) as count FROM goals WHERE status = 'ACTIVE'",
    );
    final goalsCount = goalsCountList.first['count'] as int? ?? 0;

    final behaviorHash = Object.hash(
      completionsCount,
      energyLogsCount,
      sleepDiagCount,
      reflectionsCount,
      occurrencesCount,
      goalsCount,
    );



    // 3. Load full data from last 90 days for analysis
    final routinesList = await db.query('routines', where: 'isArchived = 0');
    final occurrencesList = await db.query(
      'routine_occurrences',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, todayStr],
    );
    final completionsList = await db.query(
      'routine_completions',
      where: 'completionDate >= ? AND completionDate <= ?',
      whereArgs: [startDateStr, todayStr],
    );
    final dailyRhythms = await db.query(
      'daily_rhythm',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, todayStr],
    );
    final energyLogs = await db.query(
      'energy_logs',
      where: 'loggedAt >= ?',
      whereArgs: [startTimestamp],
    );
    final sleepDiag = await db.query(
      'bedtime_diagnostics',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, todayStr],
    );
    final goals = await db.query('goals', where: "status = 'ACTIVE'");
    final reflections = await db.query(
      'daily_reflections',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, todayStr],
    );
    final worshipPractices = await db.query('worship_practices');
    final studySessions = await db.query('konkur_study_sessions');

    // 4. Zero-Leak Filter routines to exclude cycle/medical details
    final filteredRoutines = routinesList.where((r) {
      final category = (r['category'] as String?)?.toLowerCase() ?? '';
      final title = (r['title'] as String?)?.toLowerCase() ?? '';
      if (category == 'medical' || category == 'cycle') return false;
      for (final kw in SensitiveReflectionFilter.cycleKeywords) {
        if (title.contains(kw)) return false;
      }
      return true;
    }).toList();

    final filteredRoutineIds = filteredRoutines.map((r) => r['id']! as String).toSet();
    final filteredOccurrences = occurrencesList.where((o) => filteredRoutineIds.contains(o['routine_id']! as String)).toList();
    final filteredCompletions = completionsList.where((c) => filteredRoutineIds.contains(c['routineId']! as String)).toList();

    // 5. Sequential engine executions with performance logging in kDebugMode
    final stopwatch = Stopwatch();

    // -- 1. Historical
    stopwatch.start();
    final historical = _runHistorical(
      cleanToday,
      filteredRoutines,
      filteredOccurrences,
      filteredCompletions,
      energyLogs,
      sleepDiag,
      dailyRhythms,
      studySessions,
    );
    stopwatch.stop();
    final historicalMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 2. Baseline
    stopwatch.start();
    final baseline = _runBaseline(historical, dailyRhythms, worshipPractices);
    stopwatch.stop();
    final baselineMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 3. Trend
    stopwatch.start();
    final trends = _runTrends(cleanToday, dailyRhythms, energyLogs, sleepDiag, studySessions, goals);
    stopwatch.stop();
    final trendsMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 4. Habit
    stopwatch.start();
    final habits = _runHabitStrength(cleanToday, filteredRoutines, filteredOccurrences, filteredCompletions);
    stopwatch.stop();
    final habitsMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 5. Time Preference
    stopwatch.start();
    final timePreferences = _runTimePreference(filteredRoutines, filteredCompletions);
    stopwatch.stop();
    final timePreferencesMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 6. Sequence
    stopwatch.start();
    final sequences = _runBehavioralSequence(filteredCompletions);
    stopwatch.stop();
    final sequencesMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 7. Evidence
    stopwatch.start();
    final coverageForEvidence = _runDataCoverage(sleepDiag, energyLogs, filteredOccurrences, goals, studySessions, reflections, worshipPractices);
    final evidence = _runEvidenceConfidence(coverageForEvidence, cleanToday, sleepDiag, energyLogs, filteredOccurrences);
    stopwatch.stop();
    final evidenceMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 8. Sparse Data
    stopwatch.start();
    final sparseData = _runDataCoverage(sleepDiag, energyLogs, filteredOccurrences, goals, studySessions, reflections, worshipPractices);
    stopwatch.stop();
    final sparseDataMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 9. Adaptive Suggestion
    stopwatch.start();
    final adaptiveSuggestions = await _runAdaptiveSuggestion();
    stopwatch.stop();
    final adaptiveSuggestionsMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 10. Behavior Profile
    stopwatch.start();
    final profile = _runPersonalBehaviorProfile(filteredRoutines);
    stopwatch.stop();
    final profileMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 11. Reflection Memory
    stopwatch.start();
    final reflectionsSummary = _runReflectionMemory(reflections);
    stopwatch.stop();
    final reflectionsMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // -- 12. Fingerprint
    stopwatch.start();
    final fingerprint = _runBehavioralFingerprint(behaviorHash, historical, baseline, trends, habits.items, evidence, sparseData);
    stopwatch.stop();
    final fingerprintMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    if (kDebugMode) {
      debugPrint('[BI_ORCHESTRATOR] Sub-Engine Performance Metrics:');
      debugPrint('  Historical: $historicalMs ms');
      debugPrint('  Baseline: $baselineMs ms');
      debugPrint('  Trend: $trendsMs ms');
      debugPrint('  Habit: $habitsMs ms');
      debugPrint('  Time Preference: $timePreferencesMs ms');
      debugPrint('  Sequence: $sequencesMs ms');
      debugPrint('  Evidence: $evidenceMs ms');
      debugPrint('  Sparse Data: $sparseDataMs ms');
      debugPrint('  Adaptive Suggestion: $adaptiveSuggestionsMs ms');
      debugPrint('  Behavior Profile: $profileMs ms');
      debugPrint('  Reflection Memory: $reflectionsMs ms');
      debugPrint('  Fingerprint: $fingerprintMs ms');
      debugPrint('  Total calculated in ${historicalMs + baselineMs + trendsMs + habitsMs + timePreferencesMs + sequencesMs + evidenceMs + sparseDataMs + adaptiveSuggestionsMs + profileMs + reflectionsMs + fingerprintMs} ms');
    }

    return BehavioralSnapshot(
      historical: historical,
      baseline: baseline,
      trends: trends,
      habits: habits,
      timePreferences: timePreferences,
      sequences: sequences,
      evidence: evidence,
      sparseData: sparseData,
      adaptiveSuggestions: adaptiveSuggestions,
      profile: profile,
      reflections: reflectionsSummary,
      fingerprint: fingerprint,
      generatedAt: DateTime.now(),
      engineVersion: engineVersionInt,
      snapshotVersion: snapshotVersionStr,
      behaviorHash: behaviorHash,
    );
  }

  // --- SUB-ENGINE CALCULATIONS ---

  HistoricalBehaviorSummary _runHistorical(
    DateTime today,
    List<Map<String, dynamic>> routines,
    List<Map<String, dynamic>> occurrences,
    List<Map<String, dynamic>> completions,
    List<Map<String, dynamic>> energyLogs,
    List<Map<String, dynamic>> sleepDiag,
    List<Map<String, dynamic>> dailyRhythms,
    List<Map<String, dynamic>> studySessions,
  ) {
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    final thirtyDaysAgoStr = _formatDateIso(thirtyDaysAgo);

    final occurrences30d = occurrences.where((o) => (o['date'] as String).compareTo(thirtyDaysAgoStr) >= 0).toList();
    final doneOccurrences30d = occurrences30d.where((o) => o['status'] == 'done' || o['status'] == 'completed').length;
    final routineCompletion30d = occurrences30d.isNotEmpty ? doneOccurrences30d / occurrences30d.length : 0.0;

    final doneOccurrences90d = occurrences.where((o) => o['status'] == 'done' || o['status'] == 'completed').length;
    final routineCompletion90d = occurrences.isNotEmpty ? doneOccurrences90d / occurrences.length : 0.0;

    var totalEnergy = 0.0;
    var energyCount = 0;
    for (final log in energyLogs) {
      final level = log['energyLevel']?.toString().toUpperCase() ?? 'MEDIUM';
      final val = level == 'HIGH' ? 3.0 : (level == 'LOW' ? 1.0 : 2.0);
      totalEnergy += val;
      energyCount++;
    }
    final averageEnergy = energyCount > 0 ? totalEnergy / energyCount : 2.0;

    var totalSleep = 0.0;
    var sleepCount = 0;
    for (final diag in sleepDiag) {
      final duration = diag['durationMinutes'] as num?;
      if (duration != null && duration > 0) {
        totalSleep += duration.toDouble() / 60.0;
        sleepCount++;
      }
    }
    final averageSleep = sleepCount > 0 ? totalSleep / sleepCount : 7.0;

    var totalRhythm = 0.0;
    var rhythmCount = 0;
    for (final rhythm in dailyRhythms) {
      final score = rhythm['rhythmScore'] as num? ?? rhythm['rhythm_score'] as num? ?? 0;
      totalRhythm += score.toDouble() / 100.0;
      rhythmCount++;
    }
    final rhythmAverage = rhythmCount > 0 ? totalRhythm / rhythmCount : 0.0;

    var totalStudy = 0.0;
    var studyDaysCount = 0;
    final studyMinutesPerDay = <String, int>{};
    for (final sess in studySessions) {
      final duration = sess['durationMinutes'] as num? ?? sess['duration_minutes'] as num?;
      final date = sess['date']?.toString();
      if (duration != null && date != null) {
        studyMinutesPerDay[date] = (studyMinutesPerDay[date] ?? 0) + duration.toInt();
      }
    }
    if (studyMinutesPerDay.isNotEmpty) {
      totalStudy = studyMinutesPerDay.values.map((v) => v.toDouble() / 60.0).reduce((a, b) => a + b);
      studyDaysCount = studyMinutesPerDay.length;
    }
    final studyAverage = studyDaysCount > 0 ? totalStudy / studyDaysCount : 0.0;

    var consistencyScore = 0.0;
    if (occurrences.isNotEmpty) {
      var streak = 0;
      var maxStreak = 0;
      final activeDates = occurrences.map((o) => o['date'] as String).toSet();
      final sortedDates = activeDates.toList()..sort();
      for (var i = 0; i < sortedDates.length; i++) {
        final dOccs = occurrences.where((o) => o['date'] == sortedDates[i]).toList();
        final done = dOccs.where((o) => o['status'] == 'done' || o['status'] == 'completed').length;
        final rate = done / dOccs.length;
        if (rate > 0.6) {
          streak++;
          if (streak > maxStreak) maxStreak = streak;
        } else {
          streak = 0;
        }
      }
      consistencyScore = min(1.0, maxStreak / 30.0);
    }

    final strongestHabits = <String>[];
    final weakestHabits = <String>[];
    final occByRoutine = <String, List<Map<String, dynamic>>>{};
    for (final o in occurrences) {
      final rId = o['routine_id'] as String;
      occByRoutine.putIfAbsent(rId, () => []).add(o);
    }
    final routineRates = <({String id, double rate})>[];
    occByRoutine.forEach((rId, list) {
      final done = list.where((o) => o['status'] == 'done' || o['status'] == 'completed').length;
      routineRates.add((id: rId, rate: done / list.length));
    });
    routineRates.sort((a, b) => b.rate.compareTo(a.rate));
    
    for (final rr in routineRates.take(3)) {
      final title = routines.firstWhere((r) => r['id'] == rr.id, orElse: () => {'title': 'نامشخص'})['title'] as String;
      strongestHabits.add(title);
    }
    for (final rr in routineRates.reversed.take(3)) {
      final title = routines.firstWhere((r) => r['id'] == rr.id, orElse: () => {'title': 'نامشخص'})['title'] as String;
      weakestHabits.add(title);
    }

    return HistoricalBehaviorSummary(
      routineCompletion30d: double.parse((routineCompletion30d * 100).toStringAsFixed(1)),
      routineCompletion90d: double.parse((routineCompletion90d * 100).toStringAsFixed(1)),
      averageEnergy: double.parse(averageEnergy.toStringAsFixed(2)),
      averageSleep: double.parse(averageSleep.toStringAsFixed(2)),
      rhythmAverage: double.parse((rhythmAverage * 100).toStringAsFixed(1)),
      studyAverage: double.parse(studyAverage.toStringAsFixed(2)),
      consistencyScore: double.parse((consistencyScore * 100).toStringAsFixed(1)),
      strongestHabits: strongestHabits,
      weakestHabits: weakestHabits,
    );
  }

  PersonalBaseline _runBaseline(
    HistoricalBehaviorSummary historical,
    List<Map<String, dynamic>> rhythms,
    List<Map<String, dynamic>> worshipPractices,
  ) {
    var worshipWeight = 0.0;
    if (worshipPractices.isNotEmpty) {
      final done = worshipPractices.where((w) => w['status'] == 'completed' || w['status'] == 'done').length;
      worshipWeight = done / worshipPractices.length;
    }

    return PersonalBaseline(
      avgSleep: historical.averageSleep,
      avgEnergy: historical.averageEnergy,
      avgRhythm: historical.rhythmAverage,
      avgStudy: historical.studyAverage,
      avgReflection: 2.5,
      avgPrayer: double.parse((worshipWeight * 100).toStringAsFixed(1)),
      avgWorkout: 3.5,
    );
  }

  TrendSummary _runTrends(
    DateTime today,
    List<Map<String, dynamic>> dailyRhythms,
    List<Map<String, dynamic>> energyLogs,
    List<Map<String, dynamic>> sleepDiag,
    List<Map<String, dynamic>> studySessions,
    List<Map<String, dynamic>> goals,
  ) {
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final sevenDaysAgoStr = _formatDateIso(sevenDaysAgo);

    TrendDirection getTrend(List<({String date, double val})> data) {
      if (data.length < 5) return TrendDirection.STABLE;
      final recent = data.where((d) => d.date.compareTo(sevenDaysAgoStr) >= 0).map((d) => d.val).toList();
      final older = data.where((d) => d.date.compareTo(sevenDaysAgoStr) < 0).map((d) => d.val).toList();
      if (recent.isEmpty || older.isEmpty) return TrendDirection.STABLE;

      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final olderAvg = older.reduce((a, b) => a + b) / older.length;

      final diff = recentAvg - olderAvg;
      final pct = olderAvg > 0 ? (diff / olderAvg) : diff;

      if (pct > 0.08) return TrendDirection.UP;
      if (pct < -0.08) return TrendDirection.DOWN;
      
      var variance = 0.0;
      final allVals = data.map((d) => d.val).toList();
      final avg = allVals.reduce((a, b) => a + b) / allVals.length;
      for (final v in allVals) {
        variance += pow(v - avg, 2);
      }
      variance /= allVals.length;
      if (variance > 0.4) return TrendDirection.VOLATILE;

      return TrendDirection.STABLE;
    }

    final energyData = energyLogs.map((e) {
      final dateStr = _formatDateIso(DateTime.fromMillisecondsSinceEpoch(e['loggedAt'] as int? ?? e['timestamp'] as int? ?? 0));
      final lvl = e['energyLevel']?.toString().toUpperCase() ?? 'MEDIUM';
      final val = lvl == 'HIGH' ? 3.0 : (lvl == 'LOW' ? 1.0 : 2.0);
      return (date: dateStr, val: val);
    }).toList();

    final sleepData = sleepDiag.map((s) {
      final dateStr = s['date'] as String;
      final dur = (s['durationMinutes'] as num? ?? 420.0).toDouble() / 60.0;
      return (date: dateStr, val: dur);
    }).toList();

    final rhythmData = dailyRhythms.map((r) {
      final dateStr = r['date'] as String;
      final score = (r['rhythmScore'] as num? ?? r['rhythm_score'] as num? ?? 0).toDouble();
      return (date: dateStr, val: score);
    }).toList();

    final studyMinutes = <String, int>{};
    for (final sess in studySessions) {
      final dur = sess['durationMinutes'] as num? ?? sess['duration_minutes'] as num?;
      final date = sess['date']?.toString();
      if (dur != null && date != null) {
        studyMinutes[date] = (studyMinutes[date] ?? 0) + dur.toInt();
      }
    }
    final studyData = studyMinutes.entries.map((e) => (date: e.key, val: e.value.toDouble() / 60.0)).toList();

    return TrendSummary(
      energy: getTrend(energyData),
      sleep: getTrend(sleepData),
      rhythm: getTrend(rhythmData),
      study: getTrend(studyData),
      goals: goals.isNotEmpty ? TrendDirection.UP : TrendDirection.STABLE,
    );
  }

  HabitStrengthSummary _runHabitStrength(
    DateTime today,
    List<Map<String, dynamic>> routines,
    List<Map<String, dynamic>> occurrences,
    List<Map<String, dynamic>> completions,
  ) {
    final items = <HabitStrength>[];

    for (final routine in routines) {
      final rId = routine['id'] as String;
      final rTitle = routine['title'] as String;
      
      final rOccs = occurrences.where((o) => o['routine_id'] == rId).toList();
      final done = rOccs.where((o) => o['status'] == 'done' || o['status'] == 'completed').length;
      final rate = rOccs.isNotEmpty ? done / rOccs.length : 0.0;

      var streak = 0;
      var maxStreak = 0;
      final sortedOccs = rOccs..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      for (final occ in sortedOccs) {
        final status = occ['status'] as String? ?? '';
        if (status == 'done' || status == 'completed') {
          streak++;
          if (streak > maxStreak) maxStreak = streak;
        } else {
          streak = 0;
        }
      }

      var reminderDependency = 0.1;
      if (routine['notificationLevel']?.toString().toUpperCase() != 'NONE') {
        reminderDependency = 0.5;
      }

      final strengthScore = (rate * 50) + (min(30, maxStreak) * 1.5) + (10 * (1.0 - reminderDependency));
      
      var stage = HabitStage.NEW;
      if (strengthScore > 80) {
        stage = HabitStage.AUTOMATIC;
      } else if (strengthScore > 60) {
        stage = HabitStage.STRONG;
      } else if (strengthScore > 40) {
        stage = HabitStage.STABLE;
      } else if (strengthScore > 20) {
        stage = HabitStage.BUILDING;
      }

      items.add(HabitStrength(
        routineId: rId,
        routineTitle: rTitle,
        strengthScore: double.parse(strengthScore.toStringAsFixed(1)),
        stage: stage,
        completionRate: double.parse((rate * 100).toStringAsFixed(1)),
        streakScore: maxStreak.toDouble(),
        consistencyScore: double.parse((rate * 100).toStringAsFixed(1)),
        reminderDependency: reminderDependency,
        resilienceScore: 6.5,
      ));
    }

    return HabitStrengthSummary(items: items);
  }

  TimePreferenceSummary _runTimePreference(
    List<Map<String, dynamic>> routines,
    List<Map<String, dynamic>> completions,
  ) {
    final windows = <String, PreferredWindow>{};

    for (final routine in routines) {
      final rId = routine['id'] as String;
      final title = routine['title'] as String;
      
      final rComps = completions.where((c) => c['routineId'] == rId).toList();
      if (rComps.isEmpty) continue;

      var totalMinutes = 0;
      for (final comp in rComps) {
        final timestamp = comp['completionTime'] as int? ?? 0;
        if (timestamp > 0) {
          final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          totalMinutes += dt.hour * 60 + dt.minute;
        }
      }
      final avgMinutes = totalMinutes ~/ rComps.length;
      final startHour = avgMinutes ~/ 60;
      final startMinute = avgMinutes % 60;

      final confidence = min(1, rComps.length / 10.0);

      windows[title] = PreferredWindow(
        startHour: startHour,
        startMinute: startMinute,
        endHour: (startHour + 1) % 24,
        endMinute: startMinute,
        confidence: double.parse(confidence.toStringAsFixed(2)),
      );
    }

    return TimePreferenceSummary(windows: windows);
  }

  BehavioralSequenceSummary _runBehavioralSequence(
    List<Map<String, dynamic>> completions,
  ) {
    final chains = <BehaviorChain>[];
    final compsByDate = <String, List<Map<String, dynamic>>>{};
    for (final c in completions) {
      final date = c['completionDate'] as String? ?? '';
      if (date.isNotEmpty) {
        compsByDate.putIfAbsent(date, () => []).add(c);
      }
    }

    final chainCounts = <String, int>{};
    compsByDate.forEach((date, list) {
      list.sort((a, b) => (a['completionTime'] as int? ?? 0).compareTo(b['completionTime'] as int? ?? 0));
      for (var i = 0; i < list.length - 1; i++) {
        final firstId = list[i]['routineId'] as String;
        final secondId = list[i+1]['routineId'] as String;
        final pairKey = '$firstId->$secondId';
        chainCounts[pairKey] = (chainCounts[pairKey] ?? 0) + 1;
      }
    });

    final sortedPairs = chainCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedPairs.take(5)) {
      final split = entry.key.split('->');
      chains.add(BehaviorChain(
        events: split,
        confidence: min(1, entry.value / 15.0),
        observations: entry.value,
      ));
    }

    return BehavioralSequenceSummary(chains: chains);
  }

  EvidenceConfidenceSummary _runEvidenceConfidence(
    SparseDataSummary coverage,
    DateTime today,
    List<Map<String, dynamic>> sleepDiag,
    List<Map<String, dynamic>> energyLogs,
    List<Map<String, dynamic>> occurrences,
  ) {
    var count = 0;
    if (coverage.enoughSleep) { count++; }
    if (coverage.enoughEnergy) { count++; }
    if (coverage.enoughRoutine) { count++; }
    if (coverage.enoughGoals) { count++; }
    if (coverage.enoughStudy) { count++; }
    if (coverage.enoughReflection) { count++; }
    if (coverage.enoughPrayer) { count++; }

    final completeness = count / 7.0;
    final observations = sleepDiag.length + energyLogs.length + occurrences.length;

    var level = EvidenceLevel.UNKNOWN;
    if (completeness > 0.8) {
      level = EvidenceLevel.HIGH;
    } else if (completeness > 0.5) {
      level = EvidenceLevel.MEDIUM;
    } else if (completeness > 0.2) {
      level = EvidenceLevel.LOW;
    }

    return EvidenceConfidenceSummary(
      level: level,
      score: double.parse((completeness * 10).toStringAsFixed(1)),
      observations: observations,
      completeness: double.parse(completeness.toStringAsFixed(2)),
      freshness: 0.9,
      consistency: 0.75,
      limitations: coverage.missing.map((m) => m.reason).toList(),
    );
  }

  SparseDataSummary _runDataCoverage(
    List<Map<String, dynamic>> sleepDiag,
    List<Map<String, dynamic>> energyLogs,
    List<Map<String, dynamic>> occurrences,
    List<Map<String, dynamic>> goals,
    List<Map<String, dynamic>> studySessions,
    List<Map<String, dynamic>> reflections,
    List<Map<String, dynamic>> worshipPractices,
  ) {
    final missing = <MissingData>[];

    final enoughSleep = sleepDiag.length >= 14;
    if (!enoughSleep) {
      missing.add(MissingData(domain: 'sleep', reason: 'سوابق خواب ثبت‌شده برای تحلیل روند کافی نیست.', requiredSamples: 14, currentSamples: sleepDiag.length));
    }

    final enoughEnergy = energyLogs.length >= 14;
    if (!enoughEnergy) {
      missing.add(MissingData(domain: 'energy', reason: 'ثبت سطوح انرژی روزانه برای مدل‌سازی زیستی ناکافی است.', requiredSamples: 14, currentSamples: energyLogs.length));
    }

    final enoughRoutine = occurrences.length >= 14;
    if (!enoughRoutine) {
      missing.add(MissingData(domain: 'routines', reason: 'تعداد روزهای رصد روتین‌های روزانه کم است.', requiredSamples: 14, currentSamples: occurrences.length));
    }

    final enoughGoals = goals.isNotEmpty;
    if (!enoughGoals) {
      missing.add(MissingData(domain: 'goals', reason: 'هیچ هدف فعالی در سیستم برنامه‌ریزی شما تعریف نشده است.', requiredSamples: 1, currentSamples: goals.length));
    }

    final enoughStudy = studySessions.length >= 7;
    if (!enoughStudy) {
      missing.add(MissingData(domain: 'study', reason: 'داده‌های زمان مطالعه برای تحلیل انضباط آموزشی پراکنده است.', requiredSamples: 7, currentSamples: studySessions.length));
    }

    final enoughReflection = reflections.length >= 7;
    if (!enoughReflection) {
      missing.add(MissingData(domain: 'reflections', reason: 'داده‌های خودمراقبتی و بازخورد روزانه کافی نیست.', requiredSamples: 7, currentSamples: reflections.length));
    }

    final enoughPrayer = worshipPractices.length >= 5;
    if (!enoughPrayer) {
      missing.add(MissingData(domain: 'worship', reason: 'برنامه‌های عبادی و سوابق اجرای آن‌ها برای ردیابی مداومت کم است.', requiredSamples: 5, currentSamples: worshipPractices.length));
    }

    return SparseDataSummary(
      enoughSleep: enoughSleep,
      enoughEnergy: enoughEnergy,
      enoughRoutine: enoughRoutine,
      enoughGoals: enoughGoals,
      enoughStudy: enoughStudy,
      enoughReflection: enoughReflection,
      enoughPrayer: enoughPrayer,
      missing: missing,
    );
  }

  Future<AdaptiveSuggestionProfile> _runAdaptiveSuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    
    final dismissTime = prefs.getInt('suggest_telemetry_dismissTime') ?? 3;
    final readingTime = prefs.getInt('suggest_telemetry_readingTime') ?? 12;
    final actionDelay = prefs.getInt('suggest_telemetry_actionDelay') ?? 4;
    final manualOverride = prefs.getInt('suggest_telemetry_manualOverride') ?? 0;
    final undoRate = prefs.getDouble('suggest_telemetry_undoRate') ?? 0.05;

    var style = SuggestionStyle.GENTLE;
    if (manualOverride > 3) {
      style = SuggestionStyle.ANALYTICAL;
    } else if (readingTime < 8) {
      style = SuggestionStyle.DIRECT;
    }

    var freq = SuggestionFrequency.NORMAL;
    if (dismissTime > 5 || undoRate > 0.15) {
      freq = SuggestionFrequency.LOW;
    } else if (actionDelay < 3) {
      freq = SuggestionFrequency.HIGH;
    }

    return AdaptiveSuggestionProfile(
      style: style,
      frequency: freq,
      complexity: SuggestionComplexity.SHORT,
    );
  }

  PersonalBehaviorProfile _runPersonalBehaviorProfile(
    List<Map<String, dynamic>> routines,
  ) {
    final essentialCount = routines.where((r) => r['isEssential'] == 1).length;
    final routineStyle = essentialCount > 3 ? RoutineStyle.RIGID : RoutineStyle.FLEXIBLE;

    return PersonalBehaviorProfile(
      version: 'v1',
      decisionStyle: DecisionStyle.BALANCED,
      planningStyle: PlanningStyle.STRUCTURED,
      motivationStyle: MotivationStyle.MIXED,
      routineStyle: routineStyle,
    );
  }

  ReflectionMemorySummary _runReflectionMemory(List<Map<String, dynamic>> reflections) {
    final cleanReflections = reflections.where((r) {
      final isPrivate = (r['isPrivate'] as int? ?? 0) == 1;
      if (isPrivate) return false;

      final text = r['reflection_text']?.toString() ?? '';
      final note = r['reflectionNote']?.toString() ?? '';
      final learnings = r['learnings']?.toString() ?? '';
      final wins = r['wins']?.toString() ?? '';
      final challenges = r['challenges']?.toString() ?? '';

      return !SensitiveReflectionFilter.isSensitive(text) &&
             !SensitiveReflectionFilter.isSensitive(note) &&
             !SensitiveReflectionFilter.isSensitive(learnings) &&
             !SensitiveReflectionFilter.isSensitive(wins) &&
             !SensitiveReflectionFilter.isSensitive(challenges);
    }).toList();

    final topicCount = <String, int>{};
    final stopWords = {
      'و', 'از', 'در', 'به', 'که', 'من', 'ما', 'این', 'آن', 'با', 'را', 'برای', 'است', 'بود', 'شد', 'یک', 'هم', 'تا', 'کرد', 'کند', 'روی', 'اما', 'ولی', 'یا', 'دارد', 'داشت', 'بودم', 'شدم'
    };

    final victories = <PersonalVictory>[];
    final problems = <RecurringProblem>[];
    final commitments = <Commitment>[];

    for (final r in cleanReflections) {
      final date = DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now();

      final wins = r['wins']?.toString() ?? '';
      if (wins.isNotEmpty && wins.length > 5) {
        victories.add(PersonalVictory(title: wins, date: date));
      }

      final challenges = r['challenges']?.toString() ?? '';
      if (challenges.isNotEmpty && challenges.length > 5) {
        problems.add(RecurringProblem(problem: challenges, count: 1));
      }

      final tomorrowFocus = r['tomorrowFocus']?.toString() ?? '';
      if (tomorrowFocus.isNotEmpty && tomorrowFocus.length > 5) {
        commitments.add(Commitment(domain: 'focus', promise: tomorrowFocus));
      }

      final allText = '${r['reflection_text'] ?? ''} ${r['reflectionNote'] ?? ''} ${r['learnings'] ?? ''}';
      final words = allText.split(RegExp(r'[\s\p{P}]+', unicode: true));
      for (var word in words) {
        word = word.trim().toLowerCase();
        if (word.length < 3 || stopWords.contains(word)) continue;
        topicCount[word] = (topicCount[word] ?? 0) + 1;
      }
    }

    final recurringTopics = topicCount.entries.map((e) {
      return RecurringTopic(topic: e.key, count: e.value, lastMention: DateTime.now());
    }).toList();
    recurringTopics.sort((a, b) => b.count.compareTo(a.count));

    final groupedProblems = <String, int>{};
    for (final p in problems) {
      groupedProblems[p.problem] = (groupedProblems[p.problem] ?? 0) + 1;
    }
    final finalProblems = groupedProblems.entries.map((e) => RecurringProblem(problem: e.key, count: e.value)).toList();
    finalProblems.sort((a, b) => b.count.compareTo(a.count));

    return ReflectionMemorySummary(
      recurringTopics: recurringTopics.take(10).toList(),
      victories: victories.take(5).toList(),
      recurringProblems: finalProblems.take(5).toList(),
      commitments: commitments.take(5).toList(),
    );
  }

  BehavioralFingerprint _runBehavioralFingerprint(
    int behaviorHash,
    HistoricalBehaviorSummary historical,
    PersonalBaseline baseline,
    TrendSummary trends,
    List<HabitStrength> habits,
    EvidenceConfidenceSummary evidence,
    SparseDataSummary coverage,
  ) {
    var stabilityScore = 50.0;
    if (habits.isNotEmpty) {
      final avgStreak = habits.map((h) => h.streakScore).reduce((a, b) => a + b) / habits.length;
      stabilityScore = min(100.0, 40.0 + (avgStreak * 3.0));
    }

    return BehavioralFingerprint(
      fingerprintVersion: 'v1',
      stabilityScore: double.parse(stabilityScore.toStringAsFixed(1)),
      consistencyScore: historical.consistencyScore,
      adaptabilityScore: 65,
      routineStrength: historical.routineCompletion90d,
      planningStrength: baseline.avgWorkout,
      resilienceScore: 70,
      selfAwarenessScore: evidence.score * 10,
      strongestPatterns: historical.strongestHabits,
      emergingPatterns: historical.strongestHabits.take(1).toList(),
      unstablePatterns: historical.weakestHabits,
    );
  }

  String _formatDateIso(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
