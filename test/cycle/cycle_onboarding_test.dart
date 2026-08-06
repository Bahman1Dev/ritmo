import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/cycle/logic/cycle_onboarding_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('CycleOnboardingController Tests', () {
    late Database db;

    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT,
            updatedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE cycle_periods (
            id TEXT PRIMARY KEY,
            startDate TEXT NOT NULL,
            endDate TEXT,
            flowIntensity TEXT,
            isPredicted INTEGER DEFAULT 0,
            note TEXT,
            createdAt INTEGER,
            updatedAt INTEGER
          )
        ''');
      });
      DatabaseHelper.instance.overrideDatabaseForTesting(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saveOnboarding with endedWithKnownStart calculates correct closed endDate', () async {
      final startDate = DateTime(2026, 8, 1);
      final data = CycleOnboardingData(
        periodStatus: CyclePeriodStatusChoice.endedWithKnownStart,
        cycleLength: 28,
        periodDuration: 6,
        startDate: startDate,
        worshipConsent: true,
      );

      await CycleOnboardingController.instance.saveOnboarding(data);

      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key'] as String: s['value'] as String};

      expect(settingsMap['module_cycle_enabled'], equals('true'));
      expect(settingsMap['cycle_setup_done'], equals('true'));
      expect(settingsMap['cycle_avg_length'], equals('28'));
      expect(settingsMap['user_cycle_length'], equals('28'));
      expect(settingsMap['cycle_avg_period'], equals('6'));
      expect(settingsMap['user_period_length'], equals('6'));
      expect(settingsMap['cycle_consent_worship'], equals('true'));

      final periods = await db.query('cycle_periods');
      expect(periods.length, equals(1));
      expect(periods.first['startDate'], equals('2026-08-01'));
      expect(periods.first['endDate'], equals('2026-08-06'));
    });

    test('saveOnboarding with dontKnow inserts ZERO period rows', () async {
      final data = CycleOnboardingData(
        periodStatus: CyclePeriodStatusChoice.dontKnow,
        cycleLength: 30,
        periodDuration: 5,
      );

      await CycleOnboardingController.instance.saveOnboarding(data);

      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key'] as String: s['value'] as String};

      expect(settingsMap['module_cycle_enabled'], equals('true'));
      expect(settingsMap['cycle_setup_done'], equals('true'));

      final periods = await db.query('cycle_periods');
      expect(periods.isEmpty, isTrue);
    });

    test('saveOnboarding with currentlyPregnant enables pregnancy mode and creates ZERO period rows', () async {
      final data = CycleOnboardingData(
        periodStatus: CyclePeriodStatusChoice.currentlyPregnant,
      );

      await CycleOnboardingController.instance.saveOnboarding(data);

      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key'] as String: s['value'] as String};

      expect(settingsMap['cycle_is_pregnant'], equals('true'));

      final periods = await db.query('cycle_periods');
      expect(periods.isEmpty, isTrue);
    });
  });
}
