import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/study/data/study_repository.dart';
import 'package:ritmo/features/study/data/study_settings_repository.dart';
import 'package:ritmo/core/database/schema/schema_manager.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('debug database load and study repository', () async {
    // Open a temporary database in memory
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 81,
      onCreate: (db, version) async {
        await SchemaManager.createAll(db);
      },
      onUpgrade: (db, from, to) async {
        await DatabaseHelper.instance.onUpgrade(db, from, to);
      },
    );

    // Set the singleton database instance to our temporary one
    DatabaseHelper.databaseInstance = db;

    try {
      print('Loading Study Settings...');
      final settings = await StudySettingsRepository.instance.load();
      print('Study Settings Loaded: konkurMode=${settings.konkurMode}');

      print('Loading subjects...');
      final subjects = await StudyRepository.instance.getSubjects(isKonkurMode: settings.konkurMode);
      print('Subjects loaded: ${subjects.length}');

      print('Loading topics...');
      final topics = await StudyRepository.instance.getTopics(isKonkurMode: settings.konkurMode);
      print('Topics loaded: ${topics.length}');

      print('Loading sessions...');
      final todayIso = DateTime.now().toIso8601String().substring(0, 10);
      final todaySessions = await StudyRepository.instance.getSessions(dateIso: todayIso);
      print('Today sessions: ${todaySessions.length}');

      final allSessions = await StudyRepository.instance.getSessions(limit: 500);
      print('All sessions: ${allSessions.length}');

      print('Loading aggregated stats...');
      final stats = await StudyRepository.instance.getAggregatedSubjectStats();
      print('Stats loaded: ${stats.keys.length}');

    } catch (e, st) {
      print('EXCEPTION THROWN: $e\n$st');
      rethrow;
    }
  });
}
