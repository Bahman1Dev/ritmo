import 'package:flutter/foundation.dart' hide Category;
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:sqflite/sqflite.dart';

/// AgendaSource for Goal Steps domain.
class GoalStepsAgendaSource {
  GoalStepsAgendaSource({
    required this.goalStepsByDate,
  });

  final Map<String, List<Map<String, dynamic>>> goalStepsByDate;

  static Future<GoalStepsAgendaSource> load(
    Database db,
    DateTime start,
    DateTime end,
  ) async {
    final goalStepsByDate = <String, List<Map<String, dynamic>>>{};
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      final res = await db.rawQuery('''
        SELECT gs.*, g.title as goalTitle
        FROM goal_steps gs
        JOIN goals g ON gs.goalId = g.id
        WHERE gs.scheduledDate >= ? AND gs.scheduledDate <= ? AND g.status = 'ACTIVE'
      ''', [startStr, endStr]);

      for (final row in res) {
        final dateStr = row['scheduledDate'] as String?;
        if (dateStr != null) {
          goalStepsByDate
              .putIfAbsent(dateStr, () => [])
              .add(Map<String, dynamic>.from(row));
        }
      }
    } catch (e) {
      debugPrint('[GoalStepsAgendaSource] Load error: $e');
    }

    return GoalStepsAgendaSource(goalStepsByDate: goalStepsByDate);
  }

  List<AgendaItem> itemsForDate(String dateStr) {
    final rows = goalStepsByDate[dateStr] ?? const [];
    if (rows.isEmpty) return const [];

    final items = <AgendaItem>[];
    for (final row in rows) {
      final stepId = row['id'] as String;
      final stepTitle = row['title'] as String? ?? 'گام هدف';
      final goalTitle = row['goalTitle'] as String? ?? 'هدف';
      final isDone = row['isCompleted'] == 1;

      items.add(AgendaItem(
        id: 'goalStep_${stepId}_$dateStr',
        sourceId: stepId,
        domain: AgendaDomain.goalStep,
        itemType: AgendaItemType.flexible,
        title: '$goalTitle: $stepTitle',
        dateStr: dateStr,
        durationMinutes: 30,
        category: Category.personal,
        deepLink: AgendaDeepLink(domain: AgendaDomain.goalStep, targetId: stepId),
        completion: isDone ? AgendaCompletion.done : AgendaCompletion.pending,
        meta: {'goalStep': row},
      ));
    }

    return items;
  }
}
