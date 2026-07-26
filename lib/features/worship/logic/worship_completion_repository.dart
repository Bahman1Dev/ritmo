import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/worship/logic/worship_repository.dart';
import 'package:sqflite/sqflite.dart';

class WorshipDayStatus {
  const WorshipDayStatus({
    required this.recordId,
    required this.resultType,
    required this.countDone,
    this.countTarget,
  });

  final String recordId;
  final String resultType; // DONE | SKIPPED | PARTIAL | QADA_ADDED | MISSED
  final int countDone;
  final int? countTarget;

  bool get isDone => resultType == 'DONE';
  bool get isSkipped => resultType == 'SKIPPED';
  bool get isMissed => resultType == 'MISSED';
}

class WorshipCompletionRepository {
  WorshipCompletionRepository._();
  static final instance = WorshipCompletionRepository._();

  /// Gets worship status for a single date for specified practiceIds (or all if omitted).
  Future<Map<String, WorshipDayStatus>> statusForDate(
    String dateStr, {
    List<String>? practiceIds,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await DatabaseHelper.instance.database;

    String whereClause = 'dateStr = ?';
    List<dynamic> whereArgs = [dateStr];

    if (practiceIds != null && practiceIds.isNotEmpty) {
      whereClause += ' AND practiceId IN (${List.filled(practiceIds.length, '?').join(',')})';
      whereArgs.addAll(practiceIds);
    }

    final rows = await db.query(
      'worship_completions',
      where: whereClause,
      whereArgs: whereArgs,
    );

    final resultMap = <String, WorshipDayStatus>{};
    for (final row in rows) {
      final pid = row['practiceId']! as String;
      resultMap[pid] = WorshipDayStatus(
        recordId: row['id']! as String,
        resultType: row['resultType']! as String,
        countDone: row['countDone'] as int? ?? 1,
        countTarget: row['countTarget'] as int?,
      );
    }

    return resultMap;
  }

  /// Single batch query to load status for a range of dates [fromDateStr, toDateStr].
  /// Returns Map<dateStr, Map<practiceId, WorshipDayStatus>>.
  Future<Map<String, Map<String, WorshipDayStatus>>> statusForRange(
    String fromDateStr,
    String toDateStr,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'worship_completions',
      where: 'dateStr >= ? AND dateStr <= ?',
      whereArgs: [fromDateStr, toDateStr],
    );

    final rangeMap = <String, Map<String, WorshipDayStatus>>{};
    for (final row in rows) {
      final dateStr = row['dateStr']! as String;
      final pid = row['practiceId']! as String;
      final status = WorshipDayStatus(
        recordId: row['id']! as String,
        resultType: row['resultType']! as String,
        countDone: row['countDone'] as int? ?? 1,
        countTarget: row['countTarget'] as int?,
      );

      rangeMap.putIfAbsent(dateStr, () => <String, WorshipDayStatus>{})[pid] = status;
    }

    return rangeMap;
  }

  /// Log practice completion for date. Idempotent REPLACE.
  Future<String> logDone({
    required String practiceId,
    required String dateStr,
    required String practiceType,
    int countDone = 1,
    int? countTarget,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final recordId = 'wc_${practiceId}_$dateStr';

    await db.transaction((txn) async {
      await txn.insert(
        'worship_completions',
        {
          'id': recordId,
          'practiceId': practiceId,
          'dateStr': dateStr,
          'practiceType': practiceType,
          'resultType': 'DONE',
          'countDone': countDone,
          'countTarget': countTarget,
          'loggedAt': nowMs,
          'createdAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Sync derived dailyDone on worship_practices
      await txn.update(
        'worship_practices',
        {
          'dailyDone': countDone,
          'dailyDoneDate': dateStr,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [practiceId],
      );
    });

    DayAgendaService.instance.invalidateDate(dateStr);
    WorshipRepository.instance.invalidateCache();
    RitmoEventBus().fire(RitmoEvent(
      type: 'WorshipUpdated',
      timestamp: DateTime.now(),
      payload: {'date': dateStr, 'practiceId': practiceId},
    ));

    return recordId;
  }

  /// Log practice skip for date. Idempotent REPLACE.
  Future<String> logSkip({
    required String practiceId,
    required String dateStr,
    required String practiceType,
    String? reason,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final recordId = 'wc_${practiceId}_$dateStr';

    await db.transaction((txn) async {
      await txn.insert(
        'worship_completions',
        {
          'id': recordId,
          'practiceId': practiceId,
          'dateStr': dateStr,
          'practiceType': practiceType,
          'resultType': 'SKIPPED',
          'countDone': 0,
          'reason': reason,
          'loggedAt': nowMs,
          'createdAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Sync derived dailyDone on worship_practices (-1 for skipped)
      await txn.update(
        'worship_practices',
        {
          'dailyDone': -1,
          'dailyDoneDate': dateStr,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [practiceId],
      );
    });

    DayAgendaService.instance.invalidateDate(dateStr);
    WorshipRepository.instance.invalidateCache();
    RitmoEventBus().fire(RitmoEvent(
      type: 'WorshipUpdated',
      timestamp: DateTime.now(),
      payload: {'date': dateStr, 'practiceId': practiceId},
    ));

    return recordId;
  }

  /// Undo a completion record and reset dailyDone state.
  Future<bool> undo(String recordId) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'worship_completions',
      where: 'id = ?',
      whereArgs: [recordId],
    );
    if (rows.isEmpty) return false;

    final row = rows.first;
    final practiceId = row['practiceId']! as String;
    final dateStr = row['dateStr']! as String;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'worship_completions',
        where: 'id = ?',
        whereArgs: [recordId],
      );

      await txn.update(
        'worship_practices',
        {
          'dailyDone': 0,
          'dailyDoneDate': dateStr,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [practiceId],
      );
    });

    DayAgendaService.instance.invalidateDate(dateStr);
    WorshipRepository.instance.invalidateCache();
    RitmoEventBus().fire(RitmoEvent(
      type: 'WorshipUpdated',
      timestamp: DateTime.now(),
      payload: {'date': dateStr, 'practiceId': practiceId},
    ));

    return true;
  }

  /// Calculate consecutive streak of DONE days up to [upToDateStr].
  Future<int> streakFor(String practiceId, {required String upToDateStr}) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'worship_completions',
      columns: ['dateStr', 'resultType'],
      where: 'practiceId = ? AND dateStr <= ?',
      whereArgs: [practiceId, upToDateStr],
      orderBy: 'dateStr DESC',
    );

    int streak = 0;
    DateTime? currentExpected;

    for (final row in rows) {
      final resType = row['resultType'] as String;
      if (resType != 'DONE') break;

      final dStr = row['dateStr'] as String;
      final date = DateTime.tryParse(dStr);
      if (date == null) break;

      if (currentExpected == null) {
        currentExpected = date;
        streak++;
      } else {
        final expectedPrev = currentExpected.subtract(const Duration(days: 1));
        if (date.year == expectedPrev.year &&
            date.month == expectedPrev.month &&
            date.day == expectedPrev.day) {
          streak++;
          currentExpected = date;
        } else {
          break;
        }
      }
    }

    return streak;
  }
}
