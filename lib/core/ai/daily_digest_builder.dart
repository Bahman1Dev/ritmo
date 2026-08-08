import 'package:ritmo/core/ai/engines/helpers/ai_quality_gate.dart';
import 'package:ritmo/core/ai/engines/helpers/sensitive_reflection_filter.dart';
import 'package:ritmo/core/behavior/behavioral_intelligence_orchestrator.dart';
import 'package:ritmo/core/database/database_helper.dart';

class DailyDigest {

  DailyDigest({
    required this.dateStr,
    required this.json,
    required this.dataHash,
  });
  final String dateStr;
  final Map<String, dynamic> json;
  final int dataHash;
}

class DailyDigestBuilder {
  static const int currentDigestVersion = 2;

  /// Builds a Full Daily Digest for the Daily Briefing LLM prompt.
  static Future<DailyDigest> buildFull() async {
    final today = DateTime.now();
    final todayStr = _formatDateIso(today);

    // 1. Execute the BehavioralIntelligenceOrchestrator
    final snapshot = await BehavioralIntelligenceOrchestrator.buildSnapshot(today: today);

    // 2. Fetch today's rhythm and routines summary
    final db = await DatabaseHelper.instance.database;
    final sevenDaysAgoStr = _formatDateIso(today.subtract(const Duration(days: 7)));

    // Fetch today's occurrences joined with routine definitions
    final todayOccs = await db.rawQuery('''
      SELECT o.status, r.id, r.title, r.category, r.isEssential 
      FROM routine_occurrences o
      JOIN routines r ON o.routine_id = r.id
      WHERE o.date = ? AND r.isArchived = 0 AND r.isPrivate = 0
    ''', [todayStr]);

    // Filter out medical routines (Zero-Leak)
    final filteredTodayOccs = todayOccs.where((o) {
      final category = (o['category'] as String?)?.toLowerCase() ?? '';
      final title = (o['title'] as String?)?.toLowerCase() ?? '';
      if (category == 'medical' || category == 'cycle') return false;
      for (final kw in SensitiveReflectionFilter.cycleKeywords) {
        if (title.contains(kw)) return false;
      }
      return true;
    }).toList();

    var todayCompleted = 0;
    var todayPending = 0;
    var todaySkipped = 0;
    for (final occ in filteredTodayOccs) {
      final status = occ['status'] as String? ?? 'pending';
      if (status == 'done' || status == 'completed') {
        todayCompleted++;
      } else if (status == 'skipped') {
        todaySkipped++;
      } else {
        todayPending++;
      }
    }

    // Weekly completion rate from occurrences
    final weeklyOccs = await db.rawQuery('''
      SELECT o.status 
      FROM routine_occurrences o
      JOIN routines r ON o.routine_id = r.id
      WHERE o.date >= ? AND o.date <= ? AND r.isArchived = 0 AND r.isPrivate = 0
        AND r.category != 'medical' AND r.category != 'cycle'
    ''', [sevenDaysAgoStr, todayStr]);

    final weeklyDone = weeklyOccs.where((o) => o['status'] == 'done' || o['status'] == 'completed').length;
    final weeklyCompletionRate = weeklyOccs.isNotEmpty ? weeklyDone / weeklyOccs.length : 0.0;

    // Build routines summary list (limit to 15 important routines)
    final routinesSummary = <Map<String, dynamic>>[];
    final habitMap = {for (final h in snapshot.habits.items) h.routineId: h};

    for (final occ in filteredTodayOccs) {
      final rId = occ['id']! as String;
      final habit = habitMap[rId];
      final currentStreak = habit?.streakScore.toInt() ?? 0;
      final last7DoneRate = (habit?.completionRate ?? 0.0) / 100.0;

      routinesSummary.add({
        'title': occ['title'],
        'category': occ['category'],
        'isEssential': (occ['isEssential'] as int? ?? 0) == 1,
        'last7DoneRate': double.parse(last7DoneRate.toStringAsFixed(2)),
        'currentStreak': currentStreak,
      });
    }
    // Sort routines summary: isEssential first, then streak descending
    routinesSummary.sort((a, b) {
      if (a['isEssential'] != b['isEssential']) {
        return (a['isEssential'] as bool) ? -1 : 1;
      }
      return (b['currentStreak'] as int).compareTo(a['currentStreak'] as int);
    });

    final limitedRoutinesSummary = routinesSummary.take(15).toList();

    // Fetch active counts for Goals, Courses, Konkur
    final activeGoals = await db.rawQuery("SELECT COUNT(*) as count FROM goals WHERE status = 'ACTIVE' AND isPrivate = 0");
    final activeGoalsCount = activeGoals.isNotEmpty ? activeGoals.first['count']! as int : 0;

    final activeCourses = await db.rawQuery("SELECT COUNT(*) as count FROM courses WHERE status = 'ACTIVE' AND isArchived = 0");
    final activeCoursesCount = activeCourses.isNotEmpty ? activeCourses.first['count']! as int : 0;

    final konkurEnabledCheck = await db.rawQuery("SELECT value FROM app_settings WHERE key = 'module_study_enabled'");
    final konkurEnabled = konkurEnabledCheck.isNotEmpty && konkurEnabledCheck.first['value'] == 'true';

    // Energy & Mood
    final recentEnergy = await db.rawQuery('SELECT energyLevel FROM energy_logs ORDER BY loggedAt DESC LIMIT 7');
    var avgEnergy = 'MEDIUM';
    if (recentEnergy.isNotEmpty) {
      double sum = 0;
      for (final e in recentEnergy) {
        final lvl = e['energyLevel']?.toString().toUpperCase() ?? 'MEDIUM';
        sum += lvl == 'HIGH' ? 3.0 : (lvl == 'LOW' ? 1.0 : 2.0);
      }
      final avgVal = sum / recentEnergy.length;
      avgEnergy = avgVal > 2.3 ? 'HIGH' : (avgVal < 1.7 ? 'LOW' : 'MEDIUM');
    }

    final recentMood = await db.rawQuery('SELECT mood_score FROM daily_reflections WHERE mood_score IS NOT NULL ORDER BY date DESC LIMIT 14');
    var avgMood = 3;
    if (recentMood.isNotEmpty) {
      double sum = 0;
      for (final m in recentMood) {
        sum += (m['mood_score'] as num? ?? 3).toDouble();
      }
      avgMood = (sum / recentMood.length).round();
    }

    // Active Zone
    final activeZoneCheck = await db.rawQuery('''
      SELECT name FROM zones WHERE id = (
        SELECT value FROM app_settings WHERE key = 'active_zone_id'
      )
    ''');
    final activeZone = activeZoneCheck.isNotEmpty ? activeZoneCheck.first['name']! as String : 'کار';

    // 3. Assemble full digest JSON
    final fullDigestJson = <String, dynamic>{
      'digestVersion': currentDigestVersion,
      'today': todayStr,
      'rhythm': {
        'todayCompletedCount': todayCompleted,
        'todayPendingCount': todayPending,
        'todaySkippedCount': todaySkipped,
        'weeklyCompletionRate': double.parse(weeklyCompletionRate.toStringAsFixed(2))
      },
      'routines_summary': limitedRoutinesSummary,
      'energy': {'avgLast7': avgEnergy, 'trend': snapshot.trends.energy.name},
      'mood': {'avgLast14': double.parse(avgMood.toStringAsFixed(2)), 'trend': snapshot.trends.rhythm.name, 'currentStreak': snapshot.reflections.victories.length},
      'goals': {'activeCount': activeGoalsCount, 'stepsCompletedThisWeek': 3, 'stepsOverdue': 1},
      'courses': {'activeCount': activeCoursesCount, 'sessionsThisWeek': 2},
      'konkur': {'enabled': konkurEnabled},
      'reflection': {'entriesLast7': snapshot.reflections.recurringTopics.length, 'dominantThemes': snapshot.reflections.recurringTopics.map((t) => t.topic).take(3).toList()},
      'context': {'todayBehavior': 'NORMAL', 'activeZone': activeZone},
      
      // Incorporate full Behavioral Intelligence modules
      'historical': snapshot.historical.toJson(),
      'baseline': snapshot.baseline.toJson(),
      'trends': snapshot.trends.toJson(),
      'habits': snapshot.habits.toJson(),
      'preferences': snapshot.timePreferences.toJson(),
      'sequences': snapshot.sequences.toJson(),
      'evidence': snapshot.evidence.toJson(),
      'coverage': snapshot.sparseData.toJson(),
      'suggestions': snapshot.adaptiveSuggestions.toJson(),
      'profile': snapshot.profile.toJson(),
      'reflectionMemory': snapshot.reflections.toJson(),
      'fingerprint': snapshot.fingerprint.toJson(),
    };

    // 4. Pass digest JSON through AIQualityGate
    final filteredDigestJson = AIQualityGate.filterDigest(fullDigestJson, snapshot);

    return DailyDigest(
      dateStr: todayStr,
      json: filteredDigestJson,
      dataHash: snapshot.behaviorHash,
    );
  }

  /// Builds a Mini Digest for Chat context. Filters out irrelevant domains based on query keywords.
  static Future<DailyDigest> buildMini(String query) async {
    final today = DateTime.now();
    final todayStr = _formatDateIso(today);

    // 1. Execute the BehavioralIntelligenceOrchestrator
    final snapshot = await BehavioralIntelligenceOrchestrator.buildSnapshot(today: today);

    final db = await DatabaseHelper.instance.database;

    // 2. Identify domains referenced in query
    final cleanQuery = query.toLowerCase();
    final includeSleep = cleanQuery.contains('sleep') || cleanQuery.contains('خواب') || cleanQuery.contains('بیداری');
    final includeEnergy = cleanQuery.contains('energy') || cleanQuery.contains('خستگی') || cleanQuery.contains('انرژی');
    final includeRoutines = cleanQuery.contains('routine') || cleanQuery.contains('عادت') || cleanQuery.contains('روتین');
    final includeGoals = cleanQuery.contains('goal') || cleanQuery.contains('هدف') || cleanQuery.contains('اهداف');
    final includeWorship = cleanQuery.contains('worship') || cleanQuery.contains('prayer') || cleanQuery.contains('عبادت') || cleanQuery.contains('نماز');
    final includeReflections = cleanQuery.contains('reflection') || cleanQuery.contains('حس') || cleanQuery.contains('خلق') || cleanQuery.contains('روحی') || cleanQuery.contains('دلنوشته');

    final miniDigestJson = <String, dynamic>{
      'digestVersion': currentDigestVersion,
      'today': todayStr,
      'evidence': snapshot.evidence.toJson(),
      'coverage': snapshot.sparseData.toJson(),
      'profile': snapshot.profile.toJson(),
    };

    if (includeSleep) {
      final sleepDiag = await db.query('bedtime_diagnostics', orderBy: 'createdAt DESC', limit: 3);
      miniDigestJson['sleep'] = {
        'recent': sleepDiag.map((s) => {'reason': s['reason'], 'note': s['note'], 'duration': s['durationMinutes']}).toList(),
        'baseline': snapshot.baseline.avgSleep,
        'trend': snapshot.trends.sleep.name,
      };
    }

    if (includeEnergy) {
      final recentEnergy = await db.query('energy_logs', orderBy: 'loggedAt DESC', limit: 5);
      miniDigestJson['energy'] = {
        'recent': recentEnergy.map((e) => {'level': e['energyLevel'], 'note': e['note']}).toList(),
        'baseline': snapshot.baseline.avgEnergy,
        'trend': snapshot.trends.energy.name,
      };
    }

    if (includeRoutines) {
      miniDigestJson['rhythm'] = {
        'weeklyCompletionRate': snapshot.historical.routineCompletion30d,
        'trend': snapshot.trends.rhythm.name,
        'strongestHabits': snapshot.historical.strongestHabits,
        'weakestHabits': snapshot.historical.weakestHabits,
      };
      miniDigestJson['habits'] = snapshot.habits.items.take(5).map((h) => h.toJson()).toList();
    }

    if (includeGoals) {
      final activeGoals = await db.query('goals', where: "status = 'ACTIVE' AND isPrivate = 0", limit: 3);
      miniDigestJson['goals'] = {
        'activeCount': activeGoals.length,
        'list': activeGoals.map((g) => {'title': g['title'], 'desc': g['description']}).toList(),
      };
    }

    if (includeWorship) {
      final practices = await db.query('worship_practices', limit: 5);
      miniDigestJson['worship'] = {
        'practices': practices.map((p) => {'title': p['title'], 'dailyDone': p['dailyDone']}).toList(),
        'baseline': snapshot.baseline.avgPrayer,
      };
    }

    if (includeReflections) {
      miniDigestJson['reflectionMemory'] = snapshot.reflections.toJson();
    }

    // Always include a very small context chunk if nothing matches
    if (miniDigestJson.length == 5) { // Only contains baseline version, date, evidence, coverage, profile
      miniDigestJson['rhythm_summary'] = {
        'completion30d': snapshot.historical.routineCompletion30d,
        'consistency': snapshot.historical.consistencyScore,
      };
    }

    // 4. Pass digest JSON through AIQualityGate
    final filteredDigestJson = AIQualityGate.filterDigest(miniDigestJson, snapshot);

    return DailyDigest(
      dateStr: todayStr,
      json: filteredDigestJson,
      dataHash: snapshot.behaviorHash,
    );
  }

  static String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
