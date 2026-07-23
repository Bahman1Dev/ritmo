import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/ai/ai_response_processor.dart';
import 'package:ritmo/core/analytics/assistant_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final List<String> executedStatements = [];
  final Map<String, List<Map<String, dynamic>>> tables = {
    'assistant_chats': [],
    'app_settings': [],
  };

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    tables[table] ??= [];
    tables[table]!.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    return [];
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
    return tables[table] ?? [];
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
      return insert(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as Map<String, Object?>,
      );
    }
    if (invocation.memberName == #query) {
      return query(
        invocation.positionalArguments[0] as String,
      );
    }
    return null;
  }
}

void main() {
  group('Assistant Synthesis Engine Tests', () {
    final today = DateTime(2026, 6, 24);

    test('Rank actions and calculate briefing correctly in normal conditions', () async {
      final engine = AssistantEngine();
      final input = AssistantEngineInput(
        routines: [
          {'id': 'r1', 'title': 'Morning Meditation', 'category': 'personal', 'isArchived': 0},
          {'id': 'r2', 'title': 'Exercise', 'category': 'fitness', 'isArchived': 0},
        ],
        routineCompletions: [
          {'completionDate': '2026-06-24', 'routineId': 'r1'},
        ],
        sleepLogs: [], // Sleep not recorded for yesterday
        energyLogs: [
          {'energyLevel': 'LOW', 'loggedAt': today.millisecondsSinceEpoch},
        ],
        moodLogs: [],
        goals: [],
        goalSteps: [
          {'id': 'gs1', 'title': 'Overdue step', 'scheduledDate': '2026-06-23', 'isCompleted': 0},
        ],
        konkurStudySessions: [],
        today: today,
      );

      final output = await engine.calculate(input);

      expect(output.dailyBriefing.text, contains('ابتدا خواب دیشب خود را ثبت کنید'));
      expect(output.dailyBriefing.text, contains('گام هدف عقب‌افتاده دارید'));
      
      // Actions: Sleep should be Rank 1, Overdue Goals Rank 2, Low energy Rank 3
      expect(output.nextActions.length, greaterThanOrEqualTo(3));
      expect(output.nextActions[0].action?.type, AssistantActionType.logSleep);
      expect(output.nextActions[0].rank, 1);
      expect(output.nextActions[1].action?.type, AssistantActionType.openPage);
      expect(output.nextActions[1].rank, 2);
      expect(output.nextActions[2].action?.type, AssistantActionType.logEnergyMood);
      expect(output.nextActions[2].rank, 3);
    });

    test('Highlights respect privacy and zero-leak rules indirectly', () async {
      final engine = AssistantEngine();
      final input = AssistantEngineInput(
        routines: [],
        routineCompletions: [],
        sleepLogs: [],
        energyLogs: [],
        moodLogs: [],
        goals: [],
        goalSteps: [],
        konkurStudySessions: [],
        today: today,
        isUserFemale: true,
        cycleConsent: true,
        isEnergyTuned: true,
      );

      final output = await engine.calculate(input);
      final hasIndirectBodyRhythm = output.systemHighlights.any((h) => h.headline.contains('وضعیت بدنی: نیاز به استراحت'));
      expect(hasIndirectBodyRhythm, isTrue);

      // Verify no direct leakage
      for (final h in output.systemHighlights) {
        expect(h.headline.contains('قاعدگی'), isFalse);
        expect(h.headline.contains('پریود'), isFalse);
        expect(h.headline.contains('سیکل'), isFalse);
      }
    });

    test('Respects proactive and briefing toggle config', () async {
      final engine = AssistantEngine();
      final input = AssistantEngineInput(
        routines: [],
        routineCompletions: [],
        sleepLogs: [],
        energyLogs: [],
        moodLogs: [],
        goals: [],
        goalSteps: [],
        konkurStudySessions: [],
        today: today,
        isProactiveEnabled: false,
        isBriefingEnabled: false,
      );

      final output = await engine.calculate(input);
      expect(output.dailyBriefing.text, isEmpty);
      expect(output.dailyBriefing.highlights, isEmpty);
      expect(output.nextActions, isEmpty);
    });
  });

  group('Assistant Response Parsing and Action Verification', () {
    test('processCopilot parses reply and extracts actions successfully', () {
      const jsonResponse = '''
      {
        "reply": "روتین جدید ایجاد شد.",
        "actions": [
          {
            "type": "createRoutine",
            "title": "ثبت روتین مطالعه",
            "payload": {
              "title": "مطالعه ریاضی",
              "category": "study"
            }
          }
        ]
      }
      ''';

      final processed = AIResponseProcessor.processCopilot(jsonResponse);
      expect(processed['reply'], 'روتین جدید ایجاد شد.');
      expect(processed['actions'].length, 1);
      expect(processed['actions'][0]['type'], 'createRoutine');
      expect(processed['actions'][0]['title'], 'ثبت روتین مطالعه');
      expect(processed['actions'][0]['payload']['title'], 'مطالعه ریاضی');
    });

    test('processCopilot discards unknown action types', () {
      const jsonResponse = '''
      {
        "reply": "اقدام غیرمجاز.",
        "actions": [
          {
            "type": "hackDatabaseDirectly",
            "title": "هک دیتابیس",
            "payload": {}
          }
        ]
      }
      ''';

      final processed = AIResponseProcessor.processCopilot(jsonResponse);
      expect(processed['reply'], 'اقدام غیرمجاز.');
      expect(processed['actions'], isEmpty);
    });

    test('processCopilot zero-leak filter discards cycle references', () {
      const jsonResponse = '''
      {
        "reply": "همبستگی با عادت ماهیانه شما",
        "actions": []
      }
      ''';

      final processed = AIResponseProcessor.processCopilot(jsonResponse);
      expect(processed['reply'], contains('محدوده اختیارات دستیار نیست'));
      expect(processed['actions'], isEmpty);
    });
  });

  group('Database Migration v18 Tests', () {
    test('onUpgrade from v17 to v18 alters assistant_chats and seeds settings', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 17, 18);

      final allSql = mockDb.executedStatements.join('\n').toLowerCase();
      expect(allSql, contains('alter table assistant_chats add column actionsjson'));
      expect(allSql, contains('alter table assistant_chats add column meta'));

      final settings = mockDb.tables['app_settings']!;
      expect(settings.any((s) => s['key'] == 'assistant_briefing_enabled' && s['value'] == 'true'), isTrue);
      expect(settings.any((s) => s['key'] == 'assistant_proactive_enabled' && s['value'] == 'true'), isTrue);
    });
  });
}
