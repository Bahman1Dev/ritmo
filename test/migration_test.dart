import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final List<String> executedStatements = [];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #execute) {
      return execute(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List<Object?>?
            : null,
      );
    }
    if (invocation.memberName == #rawQuery) {
      return rawQuery(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List<Object?>?
            : null,
      );
    }
    if (invocation.memberName == #insert) {
      return Future.value(0);
    }
    if (invocation.memberName == #query) {
      return Future.value(<Map<String, Object?>>[]);
    }
    return null;
  }
}

void main() {
  group('Database Migration Tests (v1 -> v5)', () {
    test('onUpgrade from v1 to v2 creates all version 2 tables', () async {
      final mockDb = MockDatabase();

      // Call migration logic on the public onUpgrade method
      await DatabaseHelper.instance.onUpgrade(mockDb, 1, 2);

      // Verify that version 2 tables were created
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();
      
      expect(allExecutedSql, contains('worship_debts'));
      expect(allExecutedSql, contains('worship_seasons'));
      expect(allExecutedSql, contains('prn_logs'));
      expect(allExecutedSql, contains('cycle_logs'));
      expect(allExecutedSql, contains('konkur_subjects'));
      expect(allExecutedSql, contains('konkur_topics'));
      expect(allExecutedSql, contains('konkur_mock_exams'));
      expect(allExecutedSql, contains('konkur_mock_exam_results'));
      expect(allExecutedSql, contains('goals'));
      expect(allExecutedSql, contains('goal_steps'));
      expect(allExecutedSql, contains('bedtime_diagnostics'));
      expect(allExecutedSql, contains('daily_checkins'));
      expect(allExecutedSql, contains('daily_reflections'));
      expect(allExecutedSql, contains('assistant_chats'));
      expect(allExecutedSql, contains('notification_history'));
      expect(allExecutedSql, contains('assistant_suggestions'));
    });

    test('onUpgrade from v1 to v5 executes successfully and creates all tables up to v5', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 1, 5);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('worship_debts'));
      expect(allExecutedSql, contains('custom_categories'));
      expect(allExecutedSql, contains('milestones_unlocked'));
    });

    test('onUpgrade from v8 to v9 adds new columns to routines and goal_steps', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 8, 9);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('alter table routines add column progressionmode'));
      expect(allExecutedSql, contains('alter table routines add column progressionstart'));
      expect(allExecutedSql, contains('alter table routines add column progressiontarget'));
      expect(allExecutedSql, contains('alter table routines add column progressionstep'));
      expect(allExecutedSql, contains('alter table routines add column progressioneveryn'));
      expect(allExecutedSql, contains('alter table routines add column progressioncurrent'));
      expect(allExecutedSql, contains('alter table routines add column progressiondonesinceadvance'));
      expect(allExecutedSql, contains('alter table goal_steps add column scheduleddate'));
      expect(allExecutedSql, contains('alter table goal_steps add column linkedroutineid'));
    });

    test('onUpgrade from v9 to v10 adds new columns to routines', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 9, 10);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('alter table routines add column itemtype'));
    });

    test('onUpgrade from v10 to v11 creates all version 11 health tables', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 10, 11);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('doctor_visits'));
      expect(allExecutedSql, contains('blood_sugar_logs'));
      expect(allExecutedSql, contains('blood_pressure_logs'));
      expect(allExecutedSql, contains('vital_signs_logs'));
      expect(allExecutedSql, contains('medical_documents'));
      expect(allExecutedSql, contains('medical_document_images'));
      expect(allExecutedSql, contains('vaccinations'));
      expect(allExecutedSql, contains('allergies'));
      expect(allExecutedSql, contains('medical_profile'));
      expect(allExecutedSql, contains('pregnancy_tracker'));
      expect(allExecutedSql, contains('pregnancy_checkups'));
      expect(allExecutedSql, contains('pregnancy_symptoms'));
      expect(allExecutedSql, contains('kick_counts'));
      expect(allExecutedSql, contains('contraction_timer'));
    });

    test('onUpgrade from v12 to v13 alters tables and recreates pending_reminders', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 12, 13);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('alter table courses add column coursetype'));
      expect(allExecutedSql, contains('alter table courses add column weeklytargetsessions'));
      expect(allExecutedSql, contains('alter table courses add column isadaptive'));
      expect(allExecutedSql, contains('alter table course_sessions add column sessiontitle'));
      expect(allExecutedSql, contains('create table pending_reminders'));
    });

    test('onUpgrade from v13 to v14 creates cycle_periods and cycle_day_logs', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 13, 14);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('create table cycle_periods'));
      expect(allExecutedSql, contains('create table cycle_day_logs'));
    });

    test('onUpgrade from v14 to v15 creates konkur_study_sessions and konkur_plan_items and alters existing konkur tables', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 14, 15);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('create table if not exists konkur_study_sessions'));
      expect(allExecutedSql, contains('create table if not exists konkur_plan_items'));
      expect(allExecutedSql, contains('alter table konkur_subjects add column subjectgroup'));
      expect(allExecutedSql, contains('alter table konkur_subjects add column examquestioncount'));
      expect(allExecutedSql, contains('alter table konkur_topics add column masterylevel'));
      expect(allExecutedSql, contains('alter table konkur_mock_exams add column provider'));
      expect(allExecutedSql, contains('alter table konkur_mock_exam_results add column totalquestions'));
    });

    test('onUpgrade from v15 to v16 adds progressCache column to goals table', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 15, 16);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('alter table goals add column progresscache'));
    });

    test('onUpgrade from v16 to v17 adds columns to bedtime_diagnostics and creates mood_logs', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 16, 17);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('alter table bedtime_diagnostics add column bedtimeat'));
      expect(allExecutedSql, contains('alter table bedtime_diagnostics add column wakeat'));
      expect(allExecutedSql, contains('alter table bedtime_diagnostics add column durationminutes'));
      expect(allExecutedSql, contains('alter table bedtime_diagnostics add column quality'));
      expect(allExecutedSql, contains('alter table bedtime_diagnostics add column awakenings'));
      expect(allExecutedSql, contains('create table if not exists mood_logs'));
    });

    test('onUpgrade from v17 to v18 adds actionsJson and meta to assistant_chats', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 17, 18);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('alter table assistant_chats add column actionsjson'));
      expect(allExecutedSql, contains('alter table assistant_chats add column meta'));
    });

    test('onUpgrade from v18 to v19 creates fasting_debt and seeds cycle settings', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 18, 19);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('create table if not exists fasting_debt'));
    });

    test('onUpgrade from v19 to v20 adds reflection fields and seeds reflection settings', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 19, 20);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('alter table daily_reflections add column gratitude'));
      expect(allExecutedSql, contains('alter table daily_reflections add column wins'));
      expect(allExecutedSql, contains('alter table daily_reflections add column challenges'));
      expect(allExecutedSql, contains('alter table daily_reflections add column tomorrowfocus'));
    });

    test('onUpgrade from v20 to v21 creates medication_logs and seeds settings', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 20, 21);
      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();

      expect(allExecutedSql, contains('create table if not exists medication_logs'));
      expect(allExecutedSql, contains('idx_medlog_routine'));
      expect(allExecutedSql, contains('idx_medlog_time'));
    });
  });
}
