import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/konkur/data/konkur_curriculum.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class KonkurRepository {
  KonkurRepository._init();
  static final KonkurRepository instance = KonkurRepository._init();

  Future<Database> get _database async => DatabaseHelper.instance.database;

  /// Seeds the database with the complete Konkur curriculum for a given field.
  /// Only inserts if no subjects exist yet for this field (idempotent).
  Future<void> seedCurriculum(KonkurField field) async {
    final existing = await getSubjects();
    final curriculum = KonkurCurriculum.byField[field] ?? [];
    if (curriculum.isEmpty) return;

    final existingNames = existing.map((s) => s.name).toSet();
    final newSubjects = curriculum.where((sData) => !existingNames.contains(sData.name));
    if (newSubjects.isEmpty && existing.isNotEmpty) return; // already seeded

    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;
    int orderIdx = existing.length;

    for (final subjectData in curriculum) {
      if (existingNames.contains(subjectData.name)) continue;

      final subjectId = uuid.v4();
      final subject = KonkurSubject(
        id: subjectId,
        name: subjectData.name,
        importanceFactor: subjectData.defaultCoefficient,
        createdAt: now,
        updatedAt: now,
        examQuestionCount: subjectData.defaultExamQuestions,
        orderIndex: orderIdx++,
        colorHex: _defaultColorForField(field),
        isPreset: true,
      );
      await insertSubject(subject);

      int topicOrderIdx = 0;
      for (final topicData in subjectData.topics) {
        final totalEst = topicData.estimatedMinutes;
        final conceptTarget = (totalEst * 0.5).round();
        final practiceTarget = (totalEst * 0.3).round();
        final reviewTarget = (totalEst * 0.2).round();

        final topic = KonkurTopic(
          id: uuid.v4(),
          subjectId: subjectId,
          name: topicData.name,
          chapter: topicData.chapter,
          studyTargetMinutes: totalEst,
          examQuestionCount: topicData.examQuestions,
          masteryLevel: topicData.defaultMastery,
          createdAt: now,
          updatedAt: now,
          orderIndex: topicOrderIdx++,
          conceptTargetMinutes: conceptTarget,
          practiceTargetMinutes: practiceTarget,
          reviewTargetMinutes: reviewTarget,
        );
        await insertTopic(topic);
      }
    }

    await updateAppSetting('konkur_field', field.code);
    await updateAppSetting('konkur_setup_done', 'true');
  }

  String _defaultColorForField(KonkurField field) {
    return switch (field) {
      KonkurField.riyazi  => '#3B82F6',  // blue
      KonkurField.tajrobi => '#10B981',  // emerald
      KonkurField.ensani  => '#F59E0B',  // amber
      KonkurField.honar   => '#EC4899',  // pink
      KonkurField.zaban   => '#8B5CF6',  // purple
    };
  }


  // READ METHODS
  Future<List<KonkurSubject>> getSubjects() async {
    final db = await _database;
    final maps = await db.query('konkur_subjects', where: 'isArchived = 0', orderBy: 'orderIndex ASC');
    return maps.map(KonkurSubject.fromMap).toList();
  }

  Future<List<KonkurTopic>> getTopics() async {
    final db = await _database;
    final maps = await db.query('konkur_topics', orderBy: 'orderIndex ASC');
    return maps.map(KonkurTopic.fromMap).toList();
  }

  Future<List<KonkurStudySession>> getStudySessions() async {
    final db = await _database;
    final maps = await db.query('konkur_study_sessions', orderBy: 'dateIso DESC, createdAt DESC');
    return maps.map(KonkurStudySession.fromMap).toList();
  }

  Future<List<KonkurMockExam>> getMockExams() async {
    final db = await _database;
    final maps = await db.query('konkur_mock_exams', orderBy: 'examDate DESC, createdAt DESC');
    return maps.map(KonkurMockExam.fromMap).toList();
  }

  Future<List<KonkurMockResult>> getMockResults() async {
    final db = await _database;
    final maps = await db.query('konkur_mock_exam_results', orderBy: 'createdAt DESC');
    return maps.map(KonkurMockResult.fromMap).toList();
  }

  Future<List<KonkurPlanItem>> getPlanItems() async {
    final db = await _database;
    final maps = await db.query('konkur_plan_items', orderBy: 'dateIso ASC, createdAt DESC');
    return maps.map(KonkurPlanItem.fromMap).toList();
  }

  Future<List<KonkurPlanItem>> getPendingCarryOverItems() async {
    final db = await _database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final results = await db.query(
      'konkur_plan_items',
      where: "status = 'PENDING' AND dateIso < ?",
      whereArgs: [todayStr],
      orderBy: 'dateIso ASC',
    );
    return results.map(KonkurPlanItem.fromMap).toList();
  }

  Future<Map<String, String>> getAppSettings() async {
    final db = await _database;
    final maps = await db.query('app_settings');
    return {for (final item in maps) if (item['key'] != null) item['key'].toString(): item['value']?.toString() ?? ''};
  }

  // WRITE/UPDATE METHODS
  Future<void> insertSubject(KonkurSubject subject) async {
    final db = await _database;
    await db.insert('konkur_subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSubject(KonkurSubject subject) async {
    final db = await _database;
    await db.update('konkur_subjects', subject.toMap(), where: 'id = ?', whereArgs: [subject.id]);
  }

  Future<void> deleteSubject(String subjectId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_subjects', where: 'id = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_topics', where: 'subjectId = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_plan_items', where: 'subjectId = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_study_sessions', where: 'subjectId = ?', whereArgs: [subjectId]);
      await txn.delete('konkur_mock_exam_results', where: 'subjectId = ?', whereArgs: [subjectId]);
    });
  }

  Future<void> insertTopic(KonkurTopic topic) async {
    final db = await _database;
    await db.insert('konkur_topics', topic.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTopic(KonkurTopic topic) async {
    final db = await _database;
    await db.update('konkur_topics', topic.toMap(), where: 'id = ?', whereArgs: [topic.id]);
  }

  Future<void> deleteTopic(String topicId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_topics', where: 'id = ?', whereArgs: [topicId]);
      await txn.delete('konkur_plan_items', where: 'topicId = ?', whereArgs: [topicId]);
      await txn.delete('konkur_study_sessions', where: 'topicId = ?', whereArgs: [topicId]);
    });
  }

  Future<void> insertStudySession(KonkurStudySession session) async {
    final db = await _database;
    await db.transaction((txn) async {
      // 1. Insert session
      await txn.insert('konkur_study_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      // 2. Update subject and topic completion minutes if topicId is specified
      if (session.topicId != null) {
        final topicMapList = await txn.query('konkur_topics', where: 'id = ?', whereArgs: [session.topicId], limit: 1);
        if (topicMapList.isNotEmpty) {
          final topic = KonkurTopic.fromMap(topicMapList.first);
          final updatedCompleted = topic.studyCompletedMinutes + session.durationMinutes;
          
          await txn.update(
            'konkur_topics',
            {
              'studyCompletedMinutes': updatedCompleted,
              'lastStudiedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [topic.id],
          );
        }
      }
    });
  }

  Future<void> deleteStudySession(String sessionId) async {
    final db = await _database;
    await db.delete('konkur_study_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> insertMockExam(KonkurMockExam exam) async {
    final db = await _database;
    await db.insert('konkur_mock_exams', exam.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    RitmoEventBus().fire(RitmoEvent(
      type: RitmoEventType.completionRecorded.code,
      timestamp: DateTime.now(),
      payload: {'domain': 'konkur_mock_exam', 'examId': exam.id, 'dateStr': exam.examDate},
    ));
  }

  Future<void> deleteMockExam(String examId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_mock_exams', where: 'id = ?', whereArgs: [examId]);
      await txn.delete('konkur_mock_exam_results', where: 'mockExamId = ?', whereArgs: [examId]);
    });
    RitmoEventBus().fire(RitmoEvent(
      type: RitmoEventType.completionRecorded.code,
      timestamp: DateTime.now(),
      payload: {'domain': 'konkur_mock_exam_deleted', 'examId': examId},
    ));
  }

  Future<void> insertMockResult(KonkurMockResult result) async {
    final db = await _database;
    await db.insert('konkur_mock_exam_results', result.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    RitmoEventBus().fire(RitmoEvent(
      type: RitmoEventType.completionRecorded.code,
      timestamp: DateTime.now(),
      payload: {'domain': 'konkur_mock_result', 'resultId': result.id, 'mockExamId': result.mockExamId},
    ));
  }

  Future<void> deleteMockResult(String resultId) async {
    final db = await _database;
    await db.delete('konkur_mock_exam_results', where: 'id = ?', whereArgs: [resultId]);
    RitmoEventBus().fire(RitmoEvent(
      type: RitmoEventType.completionRecorded.code,
      timestamp: DateTime.now(),
      payload: {'domain': 'konkur_mock_result_deleted', 'resultId': resultId},
    ));
  }

  Future<void> insertPlanItem(KonkurPlanItem item) async {
    final db = await _database;
    await db.insert('konkur_plan_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePlanItemStatus(String itemId, String status) async {
    final db = await _database;
    await db.update('konkur_plan_items', {'status': status}, where: 'id = ?', whereArgs: [itemId]);
  }

  Future<List<KonkurStudySession>> getRecentStudySessions({int days = 14}) async {
    final db = await _database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = _formatDate(cutoffDate);
    final maps = await db.query(
      'konkur_study_sessions',
      where: 'dateIso >= ?',
      whereArgs: [cutoffStr],
      orderBy: 'dateIso DESC, createdAt DESC',
    );
    return maps.map(KonkurStudySession.fromMap).toList();
  }

  Future<void> savePlanItems(List<KonkurPlanItem> items, {bool keepToday = true}) async {
    await savePlanItemsSmart(items, preserveToday: keepToday);
  }

  Future<void> savePlanItemsSmart(
    List<KonkurPlanItem> items, {
    bool preserveToday = true,
    bool preserveLocked = true,
    bool preserveUserEdited = true,
  }) async {
    final db = await _database;
    final todayStr = _formatDate(DateTime.now());

    await db.transaction((txn) async {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (preserveToday) {
        whereClauses.add('dateIso > ?');
        whereArgs.add(todayStr);
      } else {
        whereClauses.add('dateIso >= ?');
        whereArgs.add(todayStr);
      }

      whereClauses.add("status = 'PENDING'");

      if (preserveLocked) {
        whereClauses.add('(isLocked IS NULL OR isLocked = 0)');
      }

      if (preserveUserEdited) {
        whereClauses.add('(isUserEdited IS NULL OR isUserEdited = 0)');
      }

      final whereSql = whereClauses.join(' AND ');
      await txn.delete('konkur_plan_items', where: whereSql, whereArgs: whereArgs);

      final batch = txn.batch();
      for (final item in items) {
        batch.insert('konkur_plan_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, int>> getPendingCarryOverCountByTopic() async {
    final db = await _database;
    final todayStr = _formatDate(DateTime.now());
    final result = await db.rawQuery(
      "SELECT topicId, COUNT(*) as carryCount FROM konkur_plan_items WHERE dateIso < ? AND status = 'PENDING' AND topicId IS NOT NULL GROUP BY topicId",
      [todayStr],
    );
    final map = <String, int>{};
    for (final row in result) {
      final tid = row['topicId'] as String?;
      final count = row['carryCount'] as int? ?? 0;
      if (tid != null) map[tid] = count;
    }
    return map;
  }

  Future<Map<String, int>> getLastStudiedAtByTopic() async {
    final topics = await getTopics();
    final map = <String, int>{};
    for (final t in topics) {
      if (t.lastStudiedAt != null) {
        map[t.id] = t.lastStudiedAt!;
      }
    }
    return map;
  }

  Future<Map<String, double>> getRecentSubjectPerformance() async {
    final results = await getMockResults();
    final map = <String, double>{};
    for (final res in results) {
      map[res.subjectId] = res.percentage;
    }
    return map;
  }

  Future<List<KonkurTopic>> getUpcomingReviewDueTopics({required DateTime today}) async {
    final topics = await getTopics();
    final todayStr = _formatDate(today);
    return topics.where((t) {
      if (t.nextReviewDate == null || t.nextReviewDate!.isEmpty) return false;
      return t.nextReviewDate!.compareTo(todayStr) <= 0;
    }).toList();
  }

  Future<void> updateAppSetting(String key, String value) async {
    final db = await _database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> resetKonkurModule() async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('konkur_subjects');
      await txn.delete('konkur_topics');
      await txn.delete('konkur_study_sessions');
      await txn.delete('konkur_mock_exams');
      await txn.delete('konkur_mock_exam_results');
      await txn.delete('konkur_plan_items');

      final now = DateTime.now().millisecondsSinceEpoch;
      final settingsToReset = {
        'konkur_field': 'UNSET',
        'konkur_exam_date': '',
        'konkur_setup_done': 'false',
        'konkur_daily_target_minutes': '180',
        'konkur_show_in_dashboard': 'true',
      };

      for (final entry in settingsToReset.entries) {
        await txn.insert(
          'app_settings',
          {
            'key': entry.key,
            'value': entry.value,
            'updatedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<int> getTodayPlannedMinutes() async {
    final db = await _database;
    final todayStr = _formatDate(DateTime.now());
    final result = await db.rawQuery(
      'SELECT SUM(plannedMinutes) as total FROM konkur_plan_items WHERE dateIso = ?',
      [todayStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTodayActualMinutes() async {
    final db = await _database;
    final todayStr = _formatDate(DateTime.now());
    final result = await db.rawQuery(
      'SELECT SUM(durationMinutes) as total FROM konkur_study_sessions WHERE dateIso = ?',
      [todayStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTodayCompletedItemCount() async {
    final db = await _database;
    final todayStr = _formatDate(DateTime.now());
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM konkur_plan_items WHERE dateIso = ? AND status = 'DONE'",
      [todayStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTodayTotalItemCount() async {
    final db = await _database;
    final todayStr = _formatDate(DateTime.now());
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM konkur_plan_items WHERE dateIso = ?',
      [todayStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
