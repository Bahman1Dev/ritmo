import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/behavior/behavioral_intelligence_orchestrator.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final Map<String, List<Map<String, dynamic>>> tables = {};

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
    return tables[table] ?? [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    // Light queries helper for count checks
    if (sql.contains('routine_completions')) {
      final list = tables['routine_completions'] ?? [];
      return [{'count': list.length}];
    }
    if (sql.contains('energy_logs')) {
      final list = tables['energy_logs'] ?? [];
      return [{'count': list.length}];
    }
    if (sql.contains('bedtime_diagnostics')) {
      final list = tables['sleep_logs'] ?? [];
      return [{'count': list.length}];
    }
    if (sql.contains('daily_reflections')) {
      final list = tables['daily_reflections'] ?? [];
      return [{'count': list.length}];
    }
    if (sql.contains('routine_occurrences')) {
      final list = tables['routine_occurrences'] ?? [];
      return [{'count': list.length}];
    }
    if (sql.contains('goals')) {
      final list = tables['goals'] ?? [];
      return [{'count': list.length}];
    }
    return [{'count': 0}];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('BehavioralIntelligenceOrchestrator Unit Tests', () {
    late MockDatabase mockDb;
    late EngineRegistry registry;

    setUp(() {
      mockDb = MockDatabase();
      DatabaseHelper.databaseInstance = mockDb;

      registry = EngineRegistry()
        ..register(BehavioralIntelligenceOrchestrator());
      RitmoEngineBus.init(registry);

      // Seed baseline tables
      mockDb.tables['routines'] = [
        {'id': 'r1', 'title': 'ورزش صبحگاهی', 'category': 'health', 'isEssential': 1, 'isArchived': 0},
        {'id': 'r2', 'title': 'مطالعه ریاضی', 'category': 'learning', 'isEssential': 0, 'isArchived': 0},
      ];

      mockDb.tables['routine_occurrences'] = [
        {'routine_id': 'r1', 'date': '2026-06-28', 'status': 'completed'},
        {'routine_id': 'r2', 'date': '2026-06-28', 'status': 'pending'},
      ];

      mockDb.tables['routine_completions'] = [
        {'routineId': 'r1', 'completionDate': '2026-06-28', 'resultType': 'COMPLETED', 'completionTime': 1782637200000},
      ];

      mockDb.tables['energy_logs'] = [
        {'loggedAt': 1782637200000, 'energyLevel': 'HIGH', 'valence': 4, 'fatigueLevel': 1},
      ];

      mockDb.tables['daily_rhythm'] = [
        {'date': '2026-06-28', 'rhythmScore': 85},
        {'date': '2026-06-27', 'rhythmScore': 80},
      ];

      mockDb.tables['sleep_logs'] = [
        {'date': '2026-06-28', 'durationMinutes': 480, 'qualityScore': 90, 'wasNap': 0},
      ];

      mockDb.tables['worship_debts'] = [];
      mockDb.tables['daily_checkins'] = [];
      mockDb.tables['daily_reflections'] = [
        {'date': '2026-06-28', 'reflection_text': 'امروز حس خوبی داشتم و مطالعه عالی بود.', 'mood_score': 5},
        {'date': '2026-06-27', 'reflection_text': 'کمی خسته بودم ولی به روتین‌ها رسیدم.', 'mood_score': 3},
        // Sensitive reflection to verify filter
        {'date': '2026-06-26', 'reflection_text': 'درد شدیدی در دوران پریود داشتم و استراحت کردم.', 'mood_score': 2},
      ];

      mockDb.tables['courses'] = [];
      mockDb.tables['course_sessions'] = [];
      mockDb.tables['konkur_plan_items'] = [];
      mockDb.tables['konkur_subjects'] = [];
    });

    tearDown(() {
      DatabaseHelper.databaseInstance = null;
    });

    test('Orchestrator calculates BehavioralSnapshot correctly', () async {
      final snapshot = await BehavioralIntelligenceOrchestrator.buildSnapshot(today: DateTime(2026, 6, 28));

      // Verify metadata versions
      expect(snapshot.engineVersion, equals(BehavioralIntelligenceOrchestrator.engineVersionInt));
      expect(snapshot.snapshotVersion, equals(BehavioralIntelligenceOrchestrator.snapshotVersionStr));
      expect(snapshot.fingerprint.fingerprintVersion, equals('v1'));

      // Verify historical stats calculation
      expect(snapshot.historical.routineCompletion30d, closeTo(50.0, 0.01)); // 1 completion / 2 occurrences

      // Verify data coverage is computed (occurrences count is 2, which is < 14, so it should be false)
      expect(snapshot.sparseData.enoughRoutine, isFalse);

      // Verify reflections are parsed but Cycle/Menstrual/Sensitive items are filtered
      expect(snapshot.reflections.recurringTopics, isNotEmpty);
      for (final recurring in snapshot.reflections.recurringTopics) {
        expect(recurring.topic.contains('پریود'), isFalse);
        expect(recurring.topic.contains('دوران'), isFalse);
      }

      // Verify suggestions and preferences exist
      expect(snapshot.adaptiveSuggestions.style, isNotNull);
    });

    test('Fingerprint and behaviorHash is stable for identical data inputs', () async {
      final snapshot1 = await BehavioralIntelligenceOrchestrator.buildSnapshot(today: DateTime(2026, 6, 28));
      final hash1 = snapshot1.behaviorHash;

      // Invalidate cache to force recalculation and see if hash is identical
      RitmoEngineBus.instance.cacheStore.invalidate(BehavioralIntelligenceOrchestrator);

      final snapshot2 = await BehavioralIntelligenceOrchestrator.buildSnapshot(today: DateTime(2026, 6, 28));
      final hash2 = snapshot2.behaviorHash;

      expect(hash1, equals(hash2));
    });
  });
}
