// lib/features/sports/movement/data/movement_repository.dart

import 'package:ritmo/core/analytics/movement_load_calculator.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/core/utils/text_similarity.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_event.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';
import 'package:sqflite/sqflite.dart';

class PRCheckResult {
  const PRCheckResult({
    required this.isNewPr,
    this.prType,
    this.value,
    this.previousValue,
  });

  final bool isNewPr;
  final String? prType;
  final double? value;
  final double? previousValue;
}

class MovementRepository {
  MovementRepository._();
  static final instance = MovementRepository._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Fetch kinds filtered by optional family and enabled status.
  Future<List<MovementKind>> getKinds({MovementFamily? family, bool enabledOnly = true}) async {
    final db = await _db;
    var whereClause = enabledOnly ? 'isEnabled = 1' : '1=1';
    final whereArgs = <dynamic>[];

    if (family != null) {
      whereClause += ' AND family = ?';
      whereArgs.add(family.code);
    }

    final rows = await db.query(
      'movement_kinds',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'usageCount DESC, sortOrder ASC, titleFa ASC',
    );

    return rows.map((r) => MovementKind.fromMap(r)).toList();
  }

  /// Search kinds by Persian query, matching titleFa, code, or aliasesFa.
  Future<List<MovementKind>> searchKinds(String query) async {
    final q = TextSimilarity.normalize(query).trim().toLowerCase();
    if (q.isEmpty) return getKinds();

    final db = await _db;
    final all = await db.query('movement_kinds', where: 'isEnabled = 1');
    final kinds = all.map((r) => MovementKind.fromMap(r)).toList();

    return kinds.where((k) {
      final titleNorm = TextSimilarity.normalize(k.titleFa).toLowerCase();
      final aliasesNorm = TextSimilarity.normalize(k.aliasesFa ?? '').toLowerCase();
      final codeNorm = k.code.toLowerCase();

      return titleNorm.contains(q) || aliasesNorm.contains(q) || codeNorm.contains(q);
    }).toList();
  }

  /// Fetch recently or most used kinds for quick pickers.
  Future<List<MovementKind>> recentKinds({int limit = 6}) async {
    final db = await _db;
    final rows = await db.query(
      'movement_kinds',
      where: 'isEnabled = 1 AND usageCount > 0',
      orderBy: 'lastUsedAt DESC, usageCount DESC',
      limit: limit,
    );

    if (rows.length < limit) {
      final fallbackRows = await db.query(
        'movement_kinds',
        where: 'isEnabled = 1',
        orderBy: 'usageCount DESC, sortOrder ASC',
        limit: limit,
      );
      final combined = <String, Map<String, dynamic>>{};
      for (final r in [...rows, ...fallbackRows]) {
        combined[r['code'] as String] = r;
      }
      return combined.values.take(limit).map((r) => MovementKind.fromMap(r)).toList();
    }

    return rows.map((r) => MovementKind.fromMap(r)).toList();
  }

  /// Get single kind by code.
  Future<MovementKind?> getKind(String code) async {
    final db = await _db;
    final rows = await db.query('movement_kinds', where: 'code = ?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) return null;
    return MovementKind.fromMap(rows.first);
  }

  /// Create user custom movement kind.
  Future<MovementKind> createCustomKind(MovementKind kind) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final customMap = Map<String, dynamic>.from(kind.toMap())
      ..['isCustom'] = 1
      ..['isEnabled'] = 1
      ..['createdAt'] = now
      ..['updatedAt'] = now;

    await db.insert('movement_kinds', customMap, conflictAlgorithm: ConflictAlgorithm.replace);
    return MovementKind.fromMap(customMap);
  }

  /// Main method to log a MovementEvent. Handles MET/calories calculations,
  /// kind usage counter, PR checks, and event bus notification inside a transaction.
  Future<Map<String, dynamic>> logEvent(MovementEvent event) async {
    final db = await _db;
    PRCheckResult? prResult;

    await db.transaction((txn) async {
      final kind = await getKind(event.kindCode);
      final baseMet = kind?.baseMet ?? 4.0;
      final metLow = kind?.metLow ?? 3.0;
      final metHigh = kind?.metHigh ?? 6.0;

      final met = MovementLoadCalculator.metFor(
        baseMet: baseMet,
        metLow: metLow,
        metHigh: metHigh,
        intensity: event.intensity,
      );

      final weightKg = await MovementLoadCalculator.getUserWeightKg(txn);
      final metMins = MovementLoadCalculator.metMinutes(met: met, durationMinutes: event.durationMinutes);
      final kcal = MovementLoadCalculator.calories(met: met, weightKg: weightKg, durationMinutes: event.durationMinutes);

      final fullEvent = event.copyWith(
        metMinutes: metMins,
        caloriesKcal: kcal,
      );

      await txn.insert('workout_logs', fullEvent.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      // Increment kind usage count
      await txn.rawUpdate('''
        UPDATE movement_kinds
        SET usageCount = usageCount + 1, lastUsedAt = ?
        WHERE code = ?
      ''', [fullEvent.loggedAt, fullEvent.kindCode]);

      // Check PR
      prResult = await _checkAndRecordPrs(txn, fullEvent, kind);
    });

    // Fire event bus
    RitmoEventBus().fire(RitmoEvent(
      type: RitmoEventType.workoutLogChanged.code,
      timestamp: DateTime.now(),
      payload: {
        'source': 'movement',
        'id': event.id,
        'kind': event.kindCode,
        'loggedAt': event.loggedAt,
        'isPr': prResult?.isNewPr ?? false,
      },
    ));

    return {
      'id': event.id,
      'isPr': prResult?.isNewPr ?? false,
      'prResult': prResult,
    };
  }

  /// Update existing movement event.
  Future<void> updateEvent(MovementEvent event) async {
    final db = await _db;
    final kind = await getKind(event.kindCode);

    final met = MovementLoadCalculator.metFor(
      baseMet: kind?.baseMet ?? 4.0,
      metLow: kind?.metLow ?? 3.0,
      metHigh: kind?.metHigh ?? 6.0,
      intensity: event.intensity,
    );

    final weightKg = await MovementLoadCalculator.getUserWeightKg(db);
    final metMins = MovementLoadCalculator.metMinutes(met: met, durationMinutes: event.durationMinutes);
    final kcal = MovementLoadCalculator.calories(met: met, weightKg: weightKg, durationMinutes: event.durationMinutes);

    final updated = event.copyWith(metMinutes: metMins, caloriesKcal: kcal);

    await db.update(
      'workout_logs',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );

    RitmoEventBus().fire(RitmoEvent(
      type: RitmoEventType.workoutLogChanged.code,
      timestamp: DateTime.now(),
      payload: {'source': 'movement', 'id': event.id, 'kind': event.kindCode},
    ));
  }

  /// Delete movement event.
  Future<void> deleteEvent(String id) async {
    final db = await _db;
    await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);

    RitmoEventBus().fire(RitmoEvent(
      type: RitmoEventType.workoutLogChanged.code,
      timestamp: DateTime.now(),
      payload: {'source': 'movement', 'id': id, 'action': 'deleted'},
    ));
  }

  /// Fetch events logged between two dates (inclusive).
  Future<List<MovementEvent>> eventsBetween(DateTime from, DateTime to) async {
    final db = await _db;
    final startMs = DateTime(from.year, from.month, from.day).millisecondsSinceEpoch;
    final endMs = DateTime(to.year, to.month, to.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final rows = await db.query(
      'workout_logs',
      where: 'loggedAt >= ? AND loggedAt <= ?',
      whereArgs: [startMs, endMs],
      orderBy: 'loggedAt DESC',
    );

    return rows.map((r) => MovementEvent.fromMap(r)).toList();
  }

  /// Fetch events of a specific kind.
  Future<List<MovementEvent>> eventsOfKind(String kindCode, {int limit = 30}) async {
    final db = await _db;
    final rows = await db.query(
      'workout_logs',
      where: 'kind = ? OR type = ?',
      whereArgs: [kindCode, kindCode],
      orderBy: 'loggedAt DESC',
      limit: limit,
    );

    return rows.map((r) => MovementEvent.fromMap(r)).toList();
  }

  /// Check for new Personal Records (PR) and insert/update movement_pr table.
  Future<PRCheckResult> _checkAndRecordPrs(
    DatabaseExecutor txn,
    MovementEvent event,
    MovementKind? kind,
  ) async {
    if (kind == null) return const PRCheckResult(isNewPr: false);

    bool isPr = false;
    String? topPrType;
    double? prValue;
    double? prevValue;

    Future<void> evaluatePr(String prType, double newValue) async {
      if (newValue <= 0) return;

      final existing = await txn.query(
        'movement_pr',
        where: 'kind = ? AND prType = ?',
        whereArgs: [event.kindCode, prType],
        limit: 1,
      );

      if (existing.isEmpty) {
        isPr = true;
        topPrType = prType;
        prValue = newValue;
        prevValue = 0.0;

        await txn.insert('movement_pr', {
          'id': RitmoIdFactory.movementPr(),
          'kind': event.kindCode,
          'prType': prType,
          'value': newValue,
          'logId': event.id,
          'achievedAt': event.loggedAt,
        });
      } else {
        final currentMax = (existing.first['value'] as num).toDouble();
        if (newValue > currentMax) {
          isPr = true;
          topPrType = prType;
          prValue = newValue;
          prevValue = currentMax;

          await txn.update(
            'movement_pr',
            {
              'value': newValue,
              'logId': event.id,
              'achievedAt': event.loggedAt,
            },
            where: 'kind = ? AND prType = ?',
            whereArgs: [event.kindCode, prType],
          );
        }
      }
    }

    if (event.distanceMeters != null && event.distanceMeters! > 0) {
      await evaluatePr('MAX_DISTANCE', event.distanceMeters! / 1000.0);
    }
    if (event.durationMinutes > 0) {
      await evaluatePr('MAX_DURATION', event.durationMinutes.toDouble());
    }
    if (event.elevationMeters != null && event.elevationMeters! > 0) {
      await evaluatePr('MAX_ELEVATION', event.elevationMeters!);
    }
    if (event.laps != null && event.laps! > 0) {
      await evaluatePr('MAX_LAPS', event.laps!.toDouble());
    }

    return PRCheckResult(
      isNewPr: isPr,
      prType: topPrType,
      value: prValue,
      previousValue: prevValue,
    );
  }
}
