import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';

class ConsentProfile {

  const ConsentProfile({
    this.routinesConsent = true,
    this.goalsConsent = true,
    this.energyConsent = true,
    this.sleepConsent = true,
    this.planningConsent = true,
    this.cycleConsentChat = false,
  });
  final bool routinesConsent;
  final bool goalsConsent;
  final bool energyConsent;
  final bool sleepConsent;
  final bool planningConsent;
  final bool cycleConsentChat;

  static Future<ConsentProfile> loadFromDb() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      
      return ConsentProfile(
        routinesConsent: settingsMap['cycle_consent_reminders'] == 'true' || settingsMap['module_progressive_habits_enabled'] == 'true',
        goalsConsent: settingsMap['cycle_consent_dashboard'] == 'true' || settingsMap['module_goals_enabled'] == 'true',
        energyConsent: settingsMap['cycle_consent_energy'] == 'true' || settingsMap['module_energy_enabled'] == 'true',
        sleepConsent: settingsMap['cycle_consent_energy'] == 'true' || settingsMap['module_sleep_enabled'] == 'true',
        planningConsent: settingsMap['cycle_consent_dashboard'] == 'true' || settingsMap['module_goals_enabled'] == 'true',
        cycleConsentChat: settingsMap['cycle_consent_chat'] == 'true' || settingsMap['module_cycle_enabled'] == 'true' || settingsMap['cycle_setup_done'] == 'true',
      );
    } catch (e, st) {
      debugPrint('Error loading ConsentProfile from DB: $e\n$st');
      return const ConsentProfile();
    }
  }
}

class AIContextBuilder {
  static Future<Map<String, dynamic>> buildContext({
    required String query,
    required ConsentProfile consent,
  }) async {
    final cleanQuery = query.toLowerCase().trim();

    // Check specific menstrual/hormonal cycle keywords (only if consent/module not enabled)
    final cycleKeywords = [
      'menstrual', 'period', 'pregnancy', 'contraceptive', 'hormonal',
      'چرخه قاعدگی', 'سیکل قاعدگی', 'قاعدگی', 'پریود', 'عادت ماهیانه', 'پریودی'
    ];
    if (!consent.cycleConsentChat) {
      for (final kw in cycleKeywords) {
        if (cleanQuery.contains(kw)) {
          return {
            'query': query,
            'relevant_data': {},
            'user_state': {'status': 'out_of_scope', 'reason': 'cycle_disabled'},
            'scope': 'narrow'
          };
        }
      }
    }

    // Rule 0.5 Check: Medical / drug safety guard (safety of life)
    // The assistant is strictly prohibited from accessing, creating, or changing medical logs,
    // prescriptions, medications, dosages, or routine reminders of medical nature.
    final medicalKeywords = [
      'dose', 'dosage', 'medicine', 'medication', 'medical', 'prescription', 'health',
      'دارو', 'دوز', 'قرص', 'آمپول', 'نسخه', 'پزشکی', 'پزشک', 'سلامت', 'بیماری', 'درمان'
    ];
    for (final kw in medicalKeywords) {
      if (cleanQuery.contains(kw)) {
        return {
          'query': query,
          'relevant_data': {},
          'user_state': {'status': 'out_of_scope', 'reason': 'medical_safety'},
          'scope': 'narrow'
        };
      }
    }

    final relevantData = <String, dynamic>{};
    final userState = <String, dynamic>{};
    var matchedDomains = 0;

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Routines Domain (No medical, respect isPrivate)
      final isRoutinesQuery = cleanQuery.contains('routine') || cleanQuery.contains('habit') || cleanQuery.contains('روتین') || cleanQuery.contains('عادت');
      if (isRoutinesQuery && consent.routinesConsent) {
        matchedDomains++;
        final routines = await db.query(
          'routines',
          where: "isArchived = 0 AND isPrivate = 0 AND category != 'medical'",
          limit: 8, // budget: max 8
        );
        relevantData['routines'] = routines.map((r) => {
          'id': r['id'],
          'title': r['title'],
          'category': r['category'],
          'isEssential': r['isEssential'],
        }).toList();
      }

      // 2. Goals Domain (Respect isPrivate)
      final isGoalsQuery = cleanQuery.contains('goal') || cleanQuery.contains('target') || cleanQuery.contains('هدف') || cleanQuery.contains('اهداف') || cleanQuery.contains('گام');
      if (isGoalsQuery && consent.goalsConsent) {
        matchedDomains++;
        final goals = await db.query(
          'goals',
          where: "status = 'ACTIVE' AND isPrivate = 0",
          limit: 5, // budget: max 5
        );
        relevantData['goals'] = goals.map((g) => {
          'id': g['id'],
          'title': g['title'],
          'description': g['description'],
        }).toList();

        // Query goal steps if goals found
        if (goals.isNotEmpty) {
          final goalIds = goals.map((g) => "'${g['id']}'").join(',');
          final steps = await db.query(
            'goal_steps',
            where: 'goalId IN ($goalIds)',
            limit: 5,
          );
          relevantData['goal_steps'] = steps.map((s) => {
            'id': s['id'],
            'goalId': s['goalId'],
            'title': s['title'],
            'isCompleted': s['isCompleted'],
          }).toList();
        }
      }

      // 3. Energy Domain
      final isEnergyQuery = cleanQuery.contains('energy') || cleanQuery.contains('mood') || cleanQuery.contains('خلق') || cleanQuery.contains('انرژی') || cleanQuery.contains('خستگی');
      if (isEnergyQuery && consent.energyConsent) {
        matchedDomains++;
        final energyLogs = await db.query('energy_logs', orderBy: 'loggedAt DESC', limit: 5); // budget: max 5
        relevantData['recent_energy_levels'] = energyLogs.map((e) => {
          'level': e['energyLevel'],
          'note': e['note'],
        }).toList();
      }

      // 4. Sleep Domain
      final isSleepQuery = cleanQuery.contains('sleep') || cleanQuery.contains('bedtime') || cleanQuery.contains('خواب') || cleanQuery.contains('بیداری');
      if (isSleepQuery && consent.sleepConsent) {
        matchedDomains++;
        final sleepDiag = await db.query('bedtime_diagnostics', orderBy: 'createdAt DESC', limit: 5); // budget: max 5
        relevantData['recent_sleep_diagnostics'] = sleepDiag.map((s) => {
          'reason': s['reason'],
          'note': s['note'],
        }).toList();
      }

      // 5. Planning Domain
      final isPlanningQuery = cleanQuery.contains('plan') || cleanQuery.contains('schedule') || cleanQuery.contains('برنامه‌ریزی') || cleanQuery.contains('برنامه');
      if (isPlanningQuery && consent.planningConsent) {
        matchedDomains++;
        final settings = await db.query('app_settings');
        final capacity = settings.firstWhere((s) => s['key'] == 'daily_capacity_minutes', orElse: () => {'value': '360'})['value'];
        relevantData['planning_capacity_minutes'] = capacity;
      }

      // 6. Worship Domain
      final isWorshipQuery = cleanQuery.contains('worship') || cleanQuery.contains('prayer') || cleanQuery.contains('namaz') || cleanQuery.contains('dhikr') || cleanQuery.contains('عبادت') || cleanQuery.contains('نماز') || cleanQuery.contains('دعا') || cleanQuery.contains('ذکر') || cleanQuery.contains('قضا');
      if (isWorshipQuery && consent.planningConsent) {
        matchedDomains++;
        try {
          final practices = await db.query('worship_practices', limit: 5);
          relevantData['worship_practices'] = practices.map((p) => {
            'id': p['id'],
            'title': p['title'],
            'type': p['type'],
            'targetCount': p['targetCount'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
        try {
          final debts = await db.query('worship_debts', limit: 5);
          relevantData['worship_debts'] = debts.map((d) => {
            'id': d['id'],
            'title': d['title'],
            'debtCount': d['debtCount'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
      }

      // 7. Konkur Domain
      final isKonkurQuery = cleanQuery.contains('konkur') || cleanQuery.contains('exam') || cleanQuery.contains('test') || cleanQuery.contains('mock') || cleanQuery.contains('درس') || cleanQuery.contains('کنکور') || cleanQuery.contains('تست') || cleanQuery.contains('آزمون');
      if (isKonkurQuery && consent.planningConsent) {
        matchedDomains++;
        try {
          final subjects = await db.query('konkur_subjects', limit: 5);
          relevantData['konkur_subjects'] = subjects.map((s) => {
            'id': s['id'],
            'name': s['name'],
            'targetPercentage': s['targetPercentage'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
        try {
          final mockExams = await db.query('konkur_mock_exams', limit: 3);
          relevantData['konkur_mock_exams'] = mockExams.map((m) => {
            'id': m['id'],
            'title': m['title'],
            'date': m['examDate'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
      }

      // 8. Courses Domain
      final isCoursesQuery = cleanQuery.contains('course') || cleanQuery.contains('session') || cleanQuery.contains('study') || cleanQuery.contains('دوره') || cleanQuery.contains('کلاس') || cleanQuery.contains('جلسه');
      if (isCoursesQuery && consent.planningConsent) {
        matchedDomains++;
        try {
          final courses = await db.query('courses', where: "status = 'ACTIVE'", limit: 5);
          relevantData['courses'] = courses.map((c) => {
            'id': c['id'],
            'title': c['title'],
            'provider': c['provider'],
            'weeklyTargetSessions': c['weeklyTargetSessions'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
      }

      // 9. Reflection Domain (Respect isPrivate)
      final isReflectionQuery = cleanQuery.contains('reflection') || cleanQuery.contains('diary') || cleanQuery.contains('journal') || cleanQuery.contains('بازتاب') || cleanQuery.contains('خلاصه') || cleanQuery.contains('روزنگار');
      if (isReflectionQuery && consent.planningConsent) {
        matchedDomains++;
        try {
          final reflections = await db.query(
            'daily_reflections',
            where: 'isPrivate = 0',
            orderBy: 'createdAt DESC',
            limit: 5,
          );
          relevantData['daily_reflections'] = reflections.map((r) => {
            'id': r['id'],
            'date': r['date'],
            'reflection_text': r['reflection_text'],
            'learnings': r['learnings'],
            'wins': r['wins'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
      }

      // 10. Daily Rhythm Domain
      final isRhythmQuery = cleanQuery.contains('rhythm') || cleanQuery.contains('pulse') || cleanQuery.contains('snapshot') || cleanQuery.contains('نبض') || cleanQuery.contains('گزارش');
      if (isRhythmQuery && consent.planningConsent) {
        matchedDomains++;
        try {
          final rhythm = await db.query(
            'daily_rhythm',
            orderBy: 'date DESC',
            limit: 3,
          );
          relevantData['daily_rhythm'] = rhythm.map((r) => {
            'date': r['date'],
            'rhythm_score': r['rhythm_score'],
            'completion_ratio': r['completion_ratio'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
      }

      // 11. Settings Domain (Only safe allowlisted keys)
      final isSettingsQuery = cleanQuery.contains('setting') || cleanQuery.contains('config') || cleanQuery.contains('option') || cleanQuery.contains('تنظیم') || cleanQuery.contains('تنظیمات');
      if (isSettingsQuery) {
        matchedDomains++;
        try {
          final settings = await db.query('app_settings');
          final allowedKeys = [
            'gentleness_level',
            'daily_capacity_minutes',
            'snooze_minutes',
            'digest_mode',
            'coalescing_window_minutes',
            'max_non_essential_per_hour',
            'theme',
            'max_defer_count',
            'streak_threshold',
            'energy_validity_minutes',
            'default_energy_level',
            'max_grace_per_week',
            'max_grace_per_month',
            'prayer_calculation_method',
            'ihtiyat_minutes'
          ];
          final filteredSettings = settings.where((s) => allowedKeys.contains(s['key'])).toList();
          relevantData['settings'] = filteredSettings.map((s) => {
            'key': s['key'],
            'value': s['value'],
          }).toList();
        } catch (e, st) {
          debugPrint('Error in AIContextBuilder query domain: $e\n$st');
        }
      }

      userState['consent_enabled'] = true;
      userState['matched_domains_count'] = matchedDomains;
    } catch (e) {
      userState['error'] = e.toString();
    }

    var scope = 'narrow';
    if (matchedDomains > 3) {
      scope = 'broad';
    } else if (matchedDomains > 1) {
      scope = 'medium';
    }

    return {
      'query': query,
      'relevant_data': relevantData,
      'user_state': userState,
      'scope': scope
    };
  }
}
