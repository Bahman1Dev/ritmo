import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/realm/active_realm_resolver.dart';
import 'package:sqflite/sqflite.dart';

class RealmRepository {
  RealmRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  /// Loads all realms from the `zones` table.
  Future<List<RealmData>> loadRealms() async {
    final db = await _dbHelper.database;
    final rows = await db.query('zones', orderBy: 'createdAt ASC');
    return rows.map(RealmData.fromMap).toList();
  }

  /// Loads all realm schedules from `zone_schedules`.
  Future<List<RealmScheduleData>> loadSchedules() async {
    final db = await _dbHelper.database;
    final rows = await db.query('zone_schedules');
    return rows.map(RealmScheduleData.fromMap).toList();
  }

  /// Counts connected routines for every realm in a single batch query (avoiding N+1).
  Future<Map<String, int>> loadRoutineCountsPerRealm() async {
    final db = await _dbHelper.database;
    final counts = <String, int>{};

    // Query 1: Direct zoneId on routines table
    final directRows = await db.rawQuery('''
      SELECT zoneId, COUNT(*) as count 
      FROM routines 
      WHERE isArchived = 0 AND zoneId IS NOT NULL AND zoneId != '' 
      GROUP BY zoneId
    ''');
    for (final row in directRows) {
      final zId = row['zoneId'] as String?;
      final cnt = row['count'] as int? ?? 0;
      if (zId != null) {
        counts[zId] = cnt;
      }
    }

    // Query 2: routine_zone_rules join
    final ruleRows = await db.rawQuery('''
      SELECT rzr.zoneId, COUNT(DISTINCT rzr.routineId) as count
      FROM routine_zone_rules rzr
      JOIN routines r ON r.id = rzr.routineId
      WHERE r.isArchived = 0
      GROUP BY rzr.zoneId
    ''');
    for (final row in ruleRows) {
      final zId = row['zoneId'] as String?;
      final cnt = row['count'] as int? ?? 0;
      if (zId != null) {
        counts[zId] = (counts[zId] ?? 0) + cnt;
      }
    }

    return counts;
  }

  /// Resolves the active realm state through the unified resolver.
  Future<ActiveRealmState> getActiveRealmState({Clock clock = const SystemClock()}) async {
    try {
      final db = await _dbHelper.database;

      final realms = await loadRealms();
      final schedules = await loadSchedules();

      // Read manual override settings
      final overrideIdRows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['realm_override_id'],
      );
      final overrideUntilRows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['realm_override_until_ms'],
      );

      String? overrideRealmId;
      int? overrideUntilMs;

      if (overrideIdRows.isNotEmpty && overrideUntilRows.isNotEmpty) {
        overrideRealmId = overrideIdRows.first['value'] as String?;
        final untilStr = overrideUntilRows.first['value'] as String?;
        if (untilStr != null) {
          overrideUntilMs = int.tryParse(untilStr);
        }
      }

      final resolver = ActiveRealmResolver(clock: clock);
      return resolver.resolve(
        realms: realms,
        schedules: schedules,
        overrideRealmId: overrideRealmId,
        overrideUntilMs: overrideUntilMs,
      );
    } catch (e) {
      return RealmErrorState(e);
    }
  }

  /// Atomically sets manual override for a realm (ق-۷).
  Future<void> setManualOverride({
    required String realmId,
    required int durationMinutes,
  }) async {
    final db = await _dbHelper.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final untilMs = nowMs + (durationMinutes * 60 * 1000);

    await db.transaction((txn) async {
      await txn.insert(
        'app_settings',
        {'key': 'realm_override_id', 'value': realmId, 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'app_settings',
        {'key': 'realm_override_until_ms', 'value': untilMs.toString(), 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Atomically clears manual override.
  Future<void> clearManualOverride() async {
    final db = await _dbHelper.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert(
        'app_settings',
        {'key': 'realm_override_id', 'value': '', 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'app_settings',
        {'key': 'realm_override_until_ms', 'value': '0', 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Atomically saves or updates a realm and its schedules (ق-۱۰).
  Future<void> saveRealm(RealmData realm, List<RealmScheduleData> schedules) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'zones',
        realm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Replace schedules for this zone
      await txn.delete('zone_schedules', where: 'zoneId = ?', whereArgs: [realm.id]);
      for (final s in schedules) {
        await txn.insert(
          'zone_schedules',
          {
            'id': s.id,
            'zoneId': realm.id,
            'daysOfWeek': s.daysOfWeek.join(','),
            'startTime': s.startTime,
            'endTime': s.endTime,
            'createdAt': s.createdAt ?? DateTime.now().millisecondsSinceEpoch,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Atomically deletes a realm and returns a snapshot for Undo capability (ق-۴, §7.7).
  Future<Map<String, dynamic>> deleteRealmTransactional(String realmId) async {
    final db = await _dbHelper.database;
    late Map<String, dynamic> snapshot;

    await db.transaction((txn) async {
      // 1. Fetch realm
      final zoneRows = await txn.query('zones', where: 'id = ?', whereArgs: [realmId]);
      if (zoneRows.isEmpty) {
        throw Exception('قلمرو پیدا نشد');
      }
      final zoneMap = Map<String, dynamic>.from(zoneRows.first);

      // 2. Fetch schedules
      final scheduleRows = await txn.query('zone_schedules', where: 'zoneId = ?', whereArgs: [realmId]);
      final schedules = scheduleRows.map(Map<String, dynamic>.from).toList();

      // 3. Fetch routine rules
      final ruleRows = await txn.query('routine_zone_rules', where: 'zoneId = ?', whereArgs: [realmId]);
      final rules = ruleRows.map(Map<String, dynamic>.from).toList();

      // 4. Fetch unlinked routines
      final routineRows = await txn.query('routines', where: 'zoneId = ?', whereArgs: [realmId]);
      final routineIds = routineRows.map((r) => r['id'] as String).toList();

      snapshot = {
        'realm': zoneMap,
        'schedules': schedules,
        'rules': rules,
        'unlinkedRoutineIds': routineIds,
      };

      // Perform atomic cascade cleanups
      await txn.delete('zone_schedules', where: 'zoneId = ?', whereArgs: [realmId]);
      await txn.delete('routine_zone_rules', where: 'zoneId = ?', whereArgs: [realmId]);
      await txn.update('routines', {'zoneId': null}, where: 'zoneId = ?', whereArgs: [realmId]);

      // Clear override if this realm was manually override
      final overrideQuery = await txn.query('app_settings', where: 'key = ? AND value = ?', whereArgs: ['realm_override_id', realmId]);
      if (overrideQuery.isNotEmpty) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('app_settings', {'key': 'realm_override_id', 'value': '', 'updatedAt': nowMs}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('app_settings', {'key': 'realm_override_until_ms', 'value': '0', 'updatedAt': nowMs}, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Delete realm record
      await txn.delete('zones', where: 'id = ?', whereArgs: [realmId]);
    });

    return snapshot;
  }

  /// Restores a deleted realm from a snapshot (Undo delete - §7.7).
  Future<void> restoreRealmFromSnapshot(Map<String, dynamic> snapshot) async {
    final db = await _dbHelper.database;

    final realmMap = snapshot['realm'] as Map<String, dynamic>;
    final schedules = snapshot['schedules'] as List<Map<String, dynamic>>;
    final rules = snapshot['rules'] as List<Map<String, dynamic>>;
    final unlinkedRoutineIds = snapshot['unlinkedRoutineIds'] as List<String>;

    await db.transaction((txn) async {
      await txn.insert('zones', realmMap, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final s in schedules) {
        await txn.insert('zone_schedules', s, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final r in rules) {
        await txn.insert('routine_zone_rules', r, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final zoneId = realmMap['id'] as String;
      for (final rId in unlinkedRoutineIds) {
        await txn.update('routines', {'zoneId': zoneId}, where: 'id = ?', whereArgs: [rId]);
      }
    });
  }
}
