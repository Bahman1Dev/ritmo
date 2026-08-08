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
    this.prescriptionsByDate = const {},
  });

  final Map<int, List<Map<String, dynamic>>> sportsPlansByDay;
  final List<Map<String, dynamic>> movementRoutines;
  final bool sportsEnabled;
  final Map<String, Map<String, dynamic>> prescriptionsByDate;

  static Future<SsAgendaSource> load(
    Database db,
    Map<String, String> settingsMap,
  ) async {
    final sportsEnabled = settingsMap['module_sports_enabled'] == 'true' ||
        settingsMap['module_supplementary_sports_enabled'] == 'true';

    if (!sportsEnabled) {
      return SsAgendaSource(
        sportsPlansByDay: const {},
        movementRoutines: const [],
        sportsEnabled: false,
      );
    }

    // 1. Legacy ss_workout_plan (keyed by dayOfWeek)
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
      debugPrint('[SsAgendaSource] Legacy plan load error: $e');
    }

    // 2. New ss_session_prescription (keyed by dateIso)
    final prescriptionsByDate = <String, Map<String, dynamic>>{};
    try {
      final rows = await db.query('ss_session_prescription');
      for (final r in rows) {
        final dateIso = r['dateIso'] as String?;
        if (dateIso != null) {
          prescriptionsByDate[dateIso] = Map<String, dynamic>.from(r);
        }
      }
    } catch (_) {}

    // 3. Movement routines
    final movementRoutines = <Map<String, dynamic>>[];
    try {
      final rRows = await db.query(
        'routines',
        where: "category = 'fitness' AND isArchived = 0",
      );
      for (final r in rRows) {
        movementRoutines.add(Map<String, dynamic>.from(r));
      }
    } catch (_) {}

    return SsAgendaSource(
      sportsPlansByDay: sportsPlansByDay,
      movementRoutines: movementRoutines,
      sportsEnabled: sportsEnabled,
      prescriptionsByDate: prescriptionsByDate,
    );
  }

  List<AgendaItem> itemsForDate(DateTime date, String dateStr) {
    if (!sportsEnabled) return const [];

    final items = <AgendaItem>[];

    // 1. Prescription-based items (new system takes priority)
    final pres = prescriptionsByDate[dateStr];
    if (pres != null) {
      final presId = pres['id'] as String? ?? 'pres_$dateStr';
      final slotType = pres['slotType'] as String? ?? 'STRENGTH';
      final status = pres['status'] as String? ?? 'PLANNED';
      final headline = pres['headlineFa'] as String? ?? 'تمرین ورزشی';
      final targetMinutes = pres['targetMinutes'] as int? ?? 45;
      final coachNote = pres['coachNoteFa'] as String?;

      // Skip REST days — nothing on agenda
      if (slotType != 'REST') {
        final completion = switch (status) {
          'DONE' => AgendaCompletion.done,
          'PARTIAL' => AgendaCompletion.partial,
          'SKIPPED' => AgendaCompletion.skipped,
          _ => AgendaCompletion.pending,
        };

        items.add(AgendaItem(
          id: 'sport:pres:$presId:$dateStr',
          sourceId: presId,
          domain: AgendaDomain.sport,
          itemType: AgendaItemType.flexible,
          title: headline,
          subtitle: coachNote,
          dateStr: dateStr,
          durationMinutes: targetMinutes,
          category: Category.fitness,
          deepLink: AgendaDeepLink(domain: AgendaDomain.sport, targetId: presId),
          completion: completion,
          meta: {'prescription': pres},
        ));
      }

      // When prescriptions exist, skip legacy plans for this date
      return [...items, ..._movementItems(dateStr)];
    }

    // 2. Legacy ss_workout_plan fallback
    final dayOfWeek = date.weekday;
    final plans = sportsPlansByDay[dayOfWeek] ?? const [];
    for (final plan in plans) {
      final planId = plan['id']?.toString() ?? 'plan_$dayOfWeek';
      final title = plan['workoutName'] as String? ??
          plan['title'] as String? ??
          'تمرین ورزشی';
      final timeOfDay =
          plan['timeOfDay'] as String? ?? plan['targetTime'] as String?;
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

    // 3. Movement routines
    items.addAll(_movementItems(dateStr));

    return items;
  }

  List<AgendaItem> _movementItems(String dateStr) {
    final items = <AgendaItem>[];
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
