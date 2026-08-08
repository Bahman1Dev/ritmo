import 'package:flutter/foundation.dart' hide Category;
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:sqflite/sqflite.dart';

/// AgendaSource for the Sports & Supplementary Sports domain.
class SportsAgendaSource {
  SportsAgendaSource({
    required this.sportsPlansByDay,
    required this.sportsEnabled,
  });

  final Map<int, List<Map<String, dynamic>>> sportsPlansByDay;
  final bool sportsEnabled;

  static Future<SportsAgendaSource> load(
    Database db,
    Map<String, String> settingsMap,
  ) async {
    final sportsEnabled = settingsMap['module_sports_enabled'] == 'true' ||
        settingsMap['module_supplementary_sports_enabled'] == 'true';

    if (!sportsEnabled) {
      return SportsAgendaSource(sportsPlansByDay: const {}, sportsEnabled: false);
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
      debugPrint('[SportsAgendaSource] Load error: $e');
    }

    return SportsAgendaSource(
      sportsPlansByDay: sportsPlansByDay,
      sportsEnabled: sportsEnabled,
    );
  }

  List<AgendaItem> itemsForDate(DateTime date, String dateStr) {
    if (!sportsEnabled) return const [];

    final dayOfWeek = date.weekday;
    final plans = sportsPlansByDay[dayOfWeek] ?? const [];
    if (plans.isEmpty) return const [];

    final items = <AgendaItem>[];
    for (final plan in plans) {
      final planId = plan['id']?.toString() ?? 'plan_$dayOfWeek';
      final title = plan['workoutName'] as String? ?? plan['title'] as String? ?? 'تمرین ورزشی';
      final timeOfDay = plan['timeOfDay'] as String? ?? plan['targetTime'] as String?;
      final duration = plan['durationMinutes'] as int? ?? 45;

      items.add(AgendaItem(
        id: 'sport_${planId}_$dateStr',
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

    return items;
  }
}
