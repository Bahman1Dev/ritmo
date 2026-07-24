// lib/features/supplementary_sports/domain/ss_agenda_source.dart

import 'package:flutter/foundation.dart' hide Category;
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:sqflite/sqflite.dart';

/// AgendaSource for the Supplementary Sports & Movement domain.
class SsAgendaSource {
  SsAgendaSource({
    required this.sportsPlansByDay,
    required this.movementRoutines,
    required this.sportsEnabled,
  });

  final Map<int, List<Map<String, dynamic>>> sportsPlansByDay;
  final List<Map<String, dynamic>> movementRoutines;
  final bool sportsEnabled;

  static Future<SsAgendaSource> load(
    Database db,
    Map<String, String> settingsMap,
  ) async {
    final sportsEnabled = settingsMap['module_sports_enabled'] == 'true' ||
        settingsMap['module_supplementary_sports_enabled'] == 'true';

    if (!sportsEnabled) {
      return SsAgendaSource(sportsPlansByDay: const {}, movementRoutines: const [], sportsEnabled: false);
    }

    final sportsPlansByDay = <int, List<Map<String, dynamic>>>{};
    try {
      final plans = await db.query('ss_workout_plan');
      for (final p in plans) {
        final dow = p['dayOfWeek'] as int?;
        if (dow != null) {
          sportsPlansByDay.putIfAbsent(dow, () => []).add(Map<String, dynamic>.from(p));
        }
      }
    } catch (e) {
      debugPrint('[SsAgendaSource] Load error: $e');
    }

    final movementRoutines = <Map<String, dynamic>>[];
    try {
      final rRows = await db.query('routines', where: "category = 'fitness' AND isArchived = 0");
      for (final r in rRows) {
        movementRoutines.add(Map<String, dynamic>.from(r));
      }
    } catch (_) {}

    return SsAgendaSource(
      sportsPlansByDay: sportsPlansByDay,
      movementRoutines: movementRoutines,
      sportsEnabled: sportsEnabled,
    );
  }

  List<AgendaItem> itemsForDate(DateTime date, String dateStr) {
    if (!sportsEnabled) return const [];

    final items = <AgendaItem>[];

    // 1. Structured SS plans
    final dayOfWeek = date.weekday;
    final plans = sportsPlansByDay[dayOfWeek] ?? const [];
    for (final plan in plans) {
      final planId = plan['id']?.toString() ?? 'plan_$dayOfWeek';
      final title = plan['workoutName'] as String? ?? plan['title'] as String? ?? 'تمرین ورزشی';
      final timeOfDay = plan['timeOfDay'] as String? ?? plan['targetTime'] as String?;
      final duration = plan['durationMinutes'] as int? ?? 45;

      items.add(AgendaItem(
        id: 'sport:plan:$planId:$dateStr',
        sourceId: planId,
        domain: AgendaDomain.sport,
        itemType: AgendaItemType.flexible,
        title: title,
        dateStr: dateStr,
        timeOfDay: timeOfDay,
        durationMinutes: duration,
        category: Category.fitness,
        deepLink: AgendaDeepLink(domain: AgendaDomain.sport, targetId: planId),
        completion: AgendaCompletion.pending,
        meta: {'workoutPlan': plan},
      ));
    }

    // 2. Movement routines
    for (final r in movementRoutines) {
      final rId = r['id'] as String;
      final title = r['title'] as String? ?? 'فعالیت حرکتی';
      final isMeetup = (r['movementIsMeetup'] as int? ?? 0) == 1;
      final duration = r['targetDurationMinutes'] as int? ?? 30;

      items.add(AgendaItem(
        id: 'sport:movement:$rId:$dateStr',
        sourceId: rId,
        domain: AgendaDomain.sport,
        itemType: isMeetup ? AgendaItemType.fixed : AgendaItemType.flexible,
        title: title,
        dateStr: dateStr,
        durationMinutes: duration,
        category: Category.fitness,
        deepLink: AgendaDeepLink(domain: AgendaDomain.sport, targetId: rId),
        completion: AgendaCompletion.pending,
        meta: {'routine': r},
      ));
    }

    return items;
  }
}

typedef SportsAgendaSource = SsAgendaSource;
