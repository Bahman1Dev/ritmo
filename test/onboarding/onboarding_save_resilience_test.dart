import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/utils/utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_controller.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_gate.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Onboarding Controller Save Resilience Tests', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
        await db.execute('CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT, updatedAt INTEGER);');
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            routineType TEXT NOT NULL DEFAULT 'timeBased',
            notificationLevel TEXT NOT NULL DEFAULT 'normal',
            isEssential INTEGER NOT NULL DEFAULT 0,
            energyRule TEXT NOT NULL DEFAULT 'none',
            priority REAL NOT NULL DEFAULT 1.0,
            targetDurationMinutes INTEGER NOT NULL DEFAULT 30,
            lightDurationMinutes INTEGER NOT NULL DEFAULT 20,
            minimalDurationMinutes INTEGER NOT NULL DEFAULT 10,
            displayOrder INTEGER NOT NULL DEFAULT 1,
            description TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE routine_schedules (
            id TEXT PRIMARY KEY,
            routineId TEXT NOT NULL,
            scheduleType TEXT NOT NULL DEFAULT 'DAILY',
            timeOfDay TEXT NOT NULL DEFAULT '08:00',
            daysOfWeek TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
            intervalDays INTEGER,
            dayOfMonth INTEGER,
            recurrenceRule TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE routine_occurrences (
            id TEXT PRIMARY KEY,
            routine_id TEXT NOT NULL,
            date TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            scheduled_time TEXT NOT NULL DEFAULT '08:00',
            target_duration INTEGER NOT NULL DEFAULT 30,
            completed_duration INTEGER,
            completed_at INTEGER,
            skip_reason TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
      });
      DatabaseHelper.databaseInstance = db;
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.databaseInstance = null;
    });

    test('onboarding completes and invokes onFinished even when post-save side effects fail', () async {
      final controller = OnboardingController();
      bool finishedCalled = false;

      await controller.save(onFinished: () {
        finishedCalled = true;
      });

      expect(finishedCalled, isTrue);
      expect(controller.errorMessage, isNull);

      final isCompleted = await OnboardingGate.isCompleted(db);
      expect(isCompleted, isTrue);
    });

    test('onboarding save is idempotent and does not create duplicate routines on retry', () async {
      final controller = OnboardingController();

      await controller.save(onFinished: () {});
      await controller.save(onFinished: () {});

      final count = firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM routines')) ?? 0;
      expect(count, equals(controller.selectedStarterRoutines.length));
    });
  });
}
