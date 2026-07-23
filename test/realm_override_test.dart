import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class RealmOverrideDatabase extends MockDatabase {
  final Map<String, List<Map<String, dynamic>>> tables = {
    'app_settings': [],
    'zones': [],
    'zone_schedules': [],
  };

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final list = tables[table] ?? [];
    if (where == null) return list;

    if (table == 'app_settings') {
      if (where.contains('key = ?')) {
        final keyVal = whereArgs!.first! as String;
        return list.where((row) => row['key'] == keyVal).toList();
      }
      return list;
    }

    if (table == 'zones') {
      if (where.contains('id = ?')) {
        final idVal = whereArgs!.first! as String;
        return list.where((row) => row['id'] == idVal).toList();
      }
      return list;
    }

    if (table == 'zone_schedules') {
      return list;
    }

    return [];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    if (table == 'app_settings') {
      final keyVal = values['key'];
      list.removeWhere((row) => row['key'] == keyVal);
      list.add(Map<String, dynamic>.from(values));
      return 1;
    }
    list.add(Map<String, dynamic>.from(values));
    return 1;
  }
}

Future<Map<String, dynamic>?> resolveActiveZoneForTest(Database db, DateTime now) async {
  // First, check override settings
  final overrideIdQuery = await db.query(
    'app_settings',
    where: 'key = ?',
    whereArgs: ['realm_override_id'],
  );
  final overrideUntilQuery = await db.query(
    'app_settings',
    where: 'key = ?',
    whereArgs: ['realm_override_until_ms'],
  );

  if (overrideIdQuery.isNotEmpty && overrideUntilQuery.isNotEmpty) {
    final overrideId = overrideIdQuery.first['value'] as String?;
    final overrideUntilStr = overrideUntilQuery.first['value'] as String?;
    if (overrideId != null && overrideId.isNotEmpty && overrideUntilStr != null) {
      final overrideUntilMs = int.tryParse(overrideUntilStr) ?? 0;
      if (now.millisecondsSinceEpoch < overrideUntilMs) {
        final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [overrideId]);
        if (zoneQuery.isNotEmpty) {
          final zone = Map<String, dynamic>.from(zoneQuery.first);
          zone['isOverride'] = true;
          zone['overrideUntilMs'] = overrideUntilMs;
          return zone;
        }
      }
    }
  }

  // Fallback to schedule
  final weekday = now.weekday;
  final currentMinutes = now.hour * 60 + now.minute;

  final schedulesRaw = await db.query('zone_schedules');
  final schedules = schedulesRaw.map(Map<String, dynamic>.from).toList();
  for (final sched in schedules) {
    final daysOfWeekStr = sched['daysOfWeek'] as String? ?? '';
    final days = daysOfWeekStr.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toSet();
    if (days.contains(weekday)) {
      final startTimeStr = sched['startTime'] as String? ?? '00:00';
      final endTimeStr = sched['endTime'] as String? ?? '23:59';

      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        final startMin = (int.tryParse(startParts[0]) ?? 0) * 60 + (int.tryParse(startParts[1]) ?? 0);
        final endMin = (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);

        if (currentMinutes >= startMin && currentMinutes <= endMin) {
          final zoneId = sched['zoneId'] as String;
          final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [zoneId]);
          if (zoneQuery.isNotEmpty) {
            final zone = Map<String, dynamic>.from(zoneQuery.first);
            zone['startTime'] = startTimeStr;
            zone['endTime'] = endTimeStr;
            return zone;
          }
        }
      }
    }
  }
  return null;
}

int calculateRemainingSecondsForTest(Map<String, dynamic> activeZone, DateTime now) {
  if (activeZone['isOverride'] == true) {
    final overrideUntilMs = activeZone['overrideUntilMs'] as int? ?? 0;
    final diffMs = overrideUntilMs - now.millisecondsSinceEpoch;
    return diffMs > 0 ? (diffMs / 1000).ceil() : 0;
  }
  final endTimeStr = activeZone['endTime'] as String?;
  if (endTimeStr == null) return 0;
  final parts = endTimeStr.split(':');
  if (parts.length != 2) return 0;
  final hour = int.tryParse(parts[0]) ?? 0;
  final min = int.tryParse(parts[1]) ?? 0;
  final endDateTime = DateTime(now.year, now.month, now.day, hour, min);
  final diff = endDateTime.difference(now).inSeconds;
  return diff > 0 ? diff : 0;
}

void main() {
  group('Time Realm (قلمرو زمانی) Override & Schedule Tests', () {
    late RealmOverrideDatabase db;
    late DateTime baseTime;

    setUp(() {
      db = RealmOverrideDatabase();
      baseTime = DateTime(2026, 6, 23, 10); // Tuesday, 10:00 AM

      // Seed 2 zones
      db.tables['zones'] = [
        {'id': 'work_zone', 'name': 'کار عمیق', 'color': '0xff3B82F6', 'icon': '💼', 'mode': 'FOCUS'},
        {'id': 'family_zone', 'name': 'خانواده', 'color': '0xff10B981', 'icon': '🏠', 'mode': 'NORMAL'},
      ];

      // Schedule Tuesday 08:00 - 12:00 for work_zone
      db.tables['zone_schedules'] = [
        {
          'id': 'sched_1',
          'zoneId': 'work_zone',
          'daysOfWeek': '2', // Tuesday is 2 in Dart weekday (Mon=1, Tue=2, ...)
          'startTime': '08:00',
          'endTime': '12:00',
        }
      ];
    });

    test('1. Schedule Resolution: returns work_zone at Tuesday 10:00 AM', () async {
      final active = await resolveActiveZoneForTest(db, baseTime);
      expect(active, isNotNull);
      expect(active!['id'], equals('work_zone'));
      expect(active['isOverride'], isNull);
    });

    test('2. Manual Override Priority: override active zone with family_zone', () async {
      final overrideUntilMs = baseTime.millisecondsSinceEpoch + 60 * 60 * 1000; // 60 mins from now
      await db.insert('app_settings', {'key': 'realm_override_id', 'value': 'family_zone'});
      await db.insert('app_settings', {'key': 'realm_override_until_ms', 'value': overrideUntilMs.toString()});

      final active = await resolveActiveZoneForTest(db, baseTime);
      expect(active, isNotNull);
      expect(active!['id'], equals('family_zone'));
      expect(active['isOverride'], isTrue);
      expect(active['overrideUntilMs'], equals(overrideUntilMs));
    });

    test('3. Override Expiration Fallback: returns scheduled work_zone after 60 mins', () async {
      final overrideUntilMs = baseTime.millisecondsSinceEpoch + 60 * 60 * 1000;
      await db.insert('app_settings', {'key': 'realm_override_id', 'value': 'family_zone'});
      await db.insert('app_settings', {'key': 'realm_override_until_ms', 'value': overrideUntilMs.toString()});

      // Advance time by 61 minutes
      final futureTime = baseTime.add(const Duration(minutes: 61));

      final active = await resolveActiveZoneForTest(db, futureTime);
      expect(active, isNotNull);
      // Fallback works! We get the scheduled work_zone again, NOT the overridden family_zone.
      expect(active!['id'], equals('work_zone'));
      expect(active['isOverride'], isNull);
    });

    test('4. Remaining Seconds Calculation: correct for scheduled and overridden realms', () async {
      // For scheduled zone ending at 12:00 (baseTime is 10:00, remaining should be 2 hours = 7200 seconds)
      final activeScheduled = await resolveActiveZoneForTest(db, baseTime);
      final remainingSecsSched = calculateRemainingSecondsForTest(activeScheduled!, baseTime);
      expect(remainingSecsSched, equals(2 * 60 * 60));

      // For overridden zone ending 60 mins from now (remaining should be 3600 seconds)
      final overrideUntilMs = baseTime.millisecondsSinceEpoch + 60 * 60 * 1000;
      await db.insert('app_settings', {'key': 'realm_override_id', 'value': 'family_zone'});
      await db.insert('app_settings', {'key': 'realm_override_until_ms', 'value': overrideUntilMs.toString()});

      final activeOverride = await resolveActiveZoneForTest(db, baseTime);
      final remainingSecsOverride = calculateRemainingSecondsForTest(activeOverride!, baseTime);
      expect(remainingSecsOverride, equals(3600));
    });
  });
}
