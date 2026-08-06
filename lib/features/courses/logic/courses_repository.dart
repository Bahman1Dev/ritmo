import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/logic/course_validation.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:sqflite/sqflite.dart';

class CoursesRepository {
  CoursesRepository._init();
  static final CoursesRepository instance = CoursesRepository._init();

  Future<Database> get _database async => DatabaseHelper.instance.database;

  void _fireEvent(String reason, {String? courseId, String? sessionId, bool allSkipped = false}) {
    final now = DateTime.now();
    RitmoEventBus().fire(RitmoEvent(
      type: 'CoursesChanged',
      timestamp: now,
      payload: {
        ?courseId: courseId,
        ?sessionId: sessionId,
        'reason': reason,
        'allSkipped': allSkipped,
      },
    ));

    if (reason == 'COMPLETE') {
      RitmoEventBus().fire(RitmoEvent(
        type: 'CourseSessionCompleted',
        timestamp: now,
        payload: {
          ?sessionId: sessionId,
          ?courseId: courseId,
          'allSkipped': allSkipped,
        },
      ));
    }
  }

  /// Fetch all active and paused courses
  Future<List<Course>> getActiveCourses() async {
    final db = await _database;
    final maps = await db.query(
      'courses',
      where: 'isArchived = 0 AND status != ?',
      whereArgs: [CourseStatus.completed],
      orderBy: 'createdAt DESC',
    );
    return maps.map(Course.fromMap).toList();
  }

  /// Fetch all completed/archived courses
  Future<List<Course>> getCompletedAndArchivedCourses() async {
    final db = await _database;
    final maps = await db.query(
      'courses',
      where: 'isArchived = 1 OR status = ?',
      whereArgs: [CourseStatus.completed],
      orderBy: 'completedAt DESC, createdAt DESC',
    );
    return maps.map(Course.fromMap).toList();
  }

  /// Fetch a single course by ID
  Future<Course?> getCourseById(String courseId) async {
    final db = await _database;
    final maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [courseId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  /// Fetch all sessions of a specific course
  Future<List<CourseSession>> getSessionsForCourse(String courseId) async {
    final db = await _database;
    final maps = await db.query(
      'course_sessions',
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'displayOrder ASC, sessionNumber ASC',
    );
    return maps.map(CourseSession.fromMap).toList();
  }

  /// Batch fetch sessions for multiple courses (fixes N+1)
  Future<Map<String, List<CourseSession>>> getSessionsForCourses(Set<String> courseIds) async {
    if (courseIds.isEmpty) return {};
    final db = await _database;
    final placeholders = List.filled(courseIds.length, '?').join(',');
    final maps = await db.query(
      'course_sessions',
      where: 'courseId IN ($placeholders)',
      whereArgs: courseIds.toList(),
      orderBy: 'displayOrder ASC, sessionNumber ASC',
    );

    final result = <String, List<CourseSession>>{};
    for (final id in courseIds) {
      result[id] = [];
    }
    for (final map in maps) {
      final session = CourseSession.fromMap(map);
      result[session.courseId]?.add(session);
    }
    return result;
  }

  /// Fetch sessions for date range
  Future<List<CourseSession>> getSessionsForDateRange(String fromIso, String toIso) async {
    final db = await _database;
    final maps = await db.query(
      'course_sessions',
      where: 'plannedDate >= ? AND plannedDate <= ?',
      whereArgs: [fromIso, toIso],
      orderBy: 'plannedDate ASC, displayOrder ASC, sessionNumber ASC',
    );
    return maps.map(CourseSession.fromMap).toList();
  }

  /// Fetch sessions scheduled for a particular date
  Future<List<CourseSession>> getSessionsForDate(String dateStr) async {
    return getSessionsForDateRange(dateStr, dateStr);
  }

  /// Save course: routes to createCourse if isNew==true, or updateCourse if isNew==false
  Future<void> saveCourse(Course course, {required bool isNew}) async {
    if (isNew) {
      await createCourse(course);
    } else {
      await updateCourse(course);
    }
  }

  /// Create a new course and schedule its sessions
  Future<void> createCourse(Course course) async {
    CourseValidator.validateCourse(course);
    final db = await _database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.insert(
        'courses',
        course.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final sessionDates = CourseScheduler.distributeSessions(
        pendingCount: course.totalSessions,
        from: now,
        weeklyTarget: course.weeklyTargetSessions,
        preferredDays: course.preferredDays,
      );

      for (var i = 0; i < course.totalSessions; i++) {
        final sessionId = 'sess_${now.millisecondsSinceEpoch}_${course.id.hashCode}_$i';
        String? plannedDateStr;
        if (i < sessionDates.length) {
          plannedDateStr = _formatDate(sessionDates[i]);
        }

        final session = CourseSession(
          id: sessionId,
          courseId: course.id,
          sessionNumber: i + 1,
          displayOrder: i + 1,
          plannedDate: plannedDateStr,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
          sessionTitle: '${course.unitLabelResolved} ${i + 1}',
        );

        await txn.insert(
          'course_sessions',
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      await _rebuildRemindersForCourse(txn, course);
    });

    await syncCourseAlarms();
    _fireEvent('CREATE', courseId: course.id);
  }

  /// Create a course with pre-defined draft sessions (AI Syllabus import) - Fixes D-6 SOT totalSessions
  Future<void> createCourseWithSessions(Course course, List<CourseSession> draftSessions) async {
    final syncedCourse = course.copyWith(totalSessions: draftSessions.length);
    CourseValidator.validateCourse(syncedCourse);
    final db = await _database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.insert(
        'courses',
        syncedCourse.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final pendingCount = draftSessions.length;
      final sessionDates = CourseScheduler.distributeSessions(
        pendingCount: pendingCount,
        from: now,
        weeklyTarget: syncedCourse.weeklyTargetSessions,
        preferredDays: syncedCourse.preferredDays,
      );

      for (var i = 0; i < draftSessions.length; i++) {
        final draft = draftSessions[i];
        String? plannedDateStr;
        if (i < sessionDates.length) {
          plannedDateStr = _formatDate(sessionDates[i]);
        }

        final session = draft.copyWith(
          id: draft.id.isEmpty ? 'sess_${now.millisecondsSinceEpoch}_${syncedCourse.id.hashCode}_$i' : draft.id,
          courseId: syncedCourse.id,
          sessionNumber: i + 1,
          displayOrder: i + 1,
          plannedDate: plannedDateStr,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        );

        await txn.insert(
          'course_sessions',
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      await _rebuildRemindersForCourse(txn, syncedCourse);
    });

    await syncCourseAlarms();
    _fireEvent('CREATE', courseId: syncedCourse.id);
  }

  /// Update / edit course details with transactional session count adjustment and rescheduling (Fixes Root 1 & D-5)
  Future<void> updateCourse(Course updatedCourse) async {
    CourseValidator.validateCourse(updatedCourse);
    final db = await _database;
    final now = DateTime.now();

    final existingCourse = await getCourseById(updatedCourse.id);
    if (existingCourse == null) return;

    final existingSessions = await getSessionsForCourse(updatedCourse.id);
    final completedSessionsCount = existingSessions.where((s) => s.isCompleted).length;

    if (updatedCourse.totalSessions < completedSessionsCount) {
      throw CourseValidationException(
        'CANNOT_SHRINK_BELOW_COMPLETED',
        'تعداد جلسات نمی‌تواند کمتر از جلسات انجام‌شده ($completedSessionsCount) باشد.',
      );
    }

    final needsReschedule = existingCourse.weeklyTargetSessions != updatedCourse.weeklyTargetSessions ||
        !listEquals(existingCourse.preferredDays, updatedCourse.preferredDays) ||
        existingCourse.totalSessions != updatedCourse.totalSessions ||
        existingCourse.preferredTime != updatedCourse.preferredTime ||
        existingCourse.reminderEnabled != updatedCourse.reminderEnabled;

    final alarmsToCancel = <String>[];

    await db.transaction((txn) async {
      // 1. Adjust session count if totalSessions changed
      if (updatedCourse.totalSessions > existingCourse.totalSessions) {
        final countToAdd = updatedCourse.totalSessions - existingCourse.totalSessions;
        final startSessionNumber = existingSessions.length + 1;
        for (var i = 0; i < countToAdd; i++) {
          final sNum = startSessionNumber + i;
          final sessionId = 'sess_${now.millisecondsSinceEpoch}_${updatedCourse.id.hashCode}_$sNum';
          final newSession = CourseSession(
            id: sessionId,
            courseId: updatedCourse.id,
            sessionNumber: sNum,
            displayOrder: sNum,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            sessionTitle: '${updatedCourse.unitLabelResolved} $sNum',
          );
          await txn.insert(
            'course_sessions',
            newSession.toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      } else if (updatedCourse.totalSessions < existingCourse.totalSessions) {
        final countToRemove = existingCourse.totalSessions - updatedCourse.totalSessions;
        final pendingFromEnd = existingSessions.reversed.where((s) => !s.isCompleted && !s.isSkipped).take(countToRemove).toList();
        for (final s in pendingFromEnd) {
          final rems = await txn.query('pending_reminders', where: 'courseSessionId = ?', whereArgs: [s.id]);
          for (final r in rems) {
            if (r['id'] != null) alarmsToCancel.add(r['id']! as String);
          }
          await txn.delete('pending_reminders', where: 'courseSessionId = ?', whereArgs: [s.id]);
          await txn.delete('course_sessions', where: 'id = ?', whereArgs: [s.id]);
        }
      }

      // 2. Count actual remaining sessions in DB and sync totalSessions (SOT)
      final remainingCountRes = await txn.rawQuery(
        'SELECT COUNT(*) as cnt FROM course_sessions WHERE courseId = ?',
        [updatedCourse.id],
      );
      final actualTotal = remainingCountRes.isNotEmpty ? (remainingCountRes.first['cnt'] as int? ?? updatedCourse.totalSessions) : updatedCourse.totalSessions;
      final syncedCourse = updatedCourse.copyWith(totalSessions: actualTotal);

      await txn.update(
        'courses',
        syncedCourse.toMap(),
        where: 'id = ?',
        whereArgs: [syncedCourse.id],
      );

      // 3. Reschedule pending sessions if needed
      if (needsReschedule) {
        final currentSessionsMaps = await txn.query(
          'course_sessions',
          where: 'courseId = ?',
          whereArgs: [syncedCourse.id],
          orderBy: 'displayOrder ASC, sessionNumber ASC',
        );
        final currentSessions = currentSessionsMaps.map(CourseSession.fromMap).toList();

        final occupiedMap = CourseScheduler.weeklyOccupancy(
          sessions: currentSessions.where((s) => s.isCompleted || s.isSkipped || s.isUserScheduled).toList(),
        );

        final pendingToSchedule = currentSessions.where((s) => !s.isCompleted && !s.isSkipped && !s.isUserScheduled).toList();

        if (pendingToSchedule.isNotEmpty) {
          final newDates = CourseScheduler.distributeSessions(
            pendingCount: pendingToSchedule.length,
            from: now,
            weeklyTarget: syncedCourse.weeklyTargetSessions,
            preferredDays: syncedCourse.preferredDays,
            occupiedWeeklyCounts: occupiedMap,
          );

          for (var i = 0; i < pendingToSchedule.length; i++) {
            final session = pendingToSchedule[i];
            String? newDateStr;
            if (i < newDates.length) {
              newDateStr = _formatDate(newDates[i]);
            }
            await txn.update(
              'course_sessions',
              {
                'plannedDate': newDateStr,
                'updatedAt': now.millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [session.id],
            );
          }
        }
      }

      // 4. Rebuild reminders for course
      final rebuildAlarms = await _rebuildRemindersForCourse(txn, syncedCourse);
      alarmsToCancel.addAll(rebuildAlarms);
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    await syncCourseAlarms();
    _fireEvent('UPDATE', courseId: updatedCourse.id);
  }

  /// Complete a specific course session (Fixes D-1 Partial Update & D-2 Alarm Cleanup & D-25 Linked Goal)
  Future<void> completeSession({
    required String sessionId,
    required int actualDurationMinutes,
    String? note,
    int? understandingScore,
    bool needsReview = false,
    String? keyTakeaway,
    String? openQuestion,
  }) async {
    final db = await _database;
    final now = DateTime.now();
    String? courseId;
    final alarmsToCancel = <String>[];
    var allSkipped = false;

    await db.transaction((txn) async {
      final sessionMaps = await txn.query('course_sessions', where: 'id = ?', whereArgs: [sessionId]);
      if (sessionMaps.isEmpty) return;
      final session = CourseSession.fromMap(sessionMaps.first);
      courseId = session.courseId;

      // Partial update: preserve existing note if note parameter is null (Fixes D-1)
      final updates = <String, dynamic>{
        'completionStatus': SessionStatus.completed.dbValue,
        'actualDurationMinutes': actualDurationMinutes,
        'completedAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      };
      if (note != null) updates['note'] = note;
      if (understandingScore != null) updates['understandingScore'] = understandingScore;
      if (needsReview) updates['needsReview'] = 1;
      if (keyTakeaway != null) updates['keyTakeaway'] = keyTakeaway;
      if (openQuestion != null) updates['openQuestion'] = openQuestion;

      await txn.update(
        'course_sessions',
        updates,
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      final rems = await txn.query('pending_reminders', where: 'courseSessionId = ?', whereArgs: [sessionId]);
      for (final r in rems) {
        if (r['id'] != null) alarmsToCancel.add(r['id']! as String);
      }
      await txn.delete('pending_reminders', where: 'courseSessionId = ?', whereArgs: [sessionId]);

      // Check remaining pending sessions
      final remainingPending = await txn.query(
        'course_sessions',
        where: 'courseId = ? AND completionStatus = ?',
        whereArgs: [courseId, SessionStatus.pending.dbValue],
      );

      if (remainingPending.isEmpty) {
        final allSessions = await txn.query('course_sessions', where: 'courseId = ?', whereArgs: [courseId]);
        final completedCount = allSessions.where((s) => s['completionStatus'] == SessionStatus.completed.dbValue).length;
        allSkipped = completedCount == 0;

        await txn.update(
          'courses',
          {
            'status': CourseStatus.completed,
            'completedAt': now.millisecondsSinceEpoch,
            'updatedAt': now.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [courseId],
        );
      }

      // D-25: One-way linked goal progress update
      final courseMaps = await txn.query('courses', where: 'id = ?', whereArgs: [courseId]);
      if (courseMaps.isNotEmpty) {
        final course = Course.fromMap(courseMaps.first);
        if (course.linkedGoalId != null) {
          final totalSess = course.totalSessions;
          final allSess = await txn.query('course_sessions', where: 'courseId = ?', whereArgs: [courseId]);
          final doneSess = allSess.where((s) => s['completionStatus'] == SessionStatus.completed.dbValue).length;
          final ratio = totalSess > 0 ? (doneSess / totalSess) : 0.0;
          await txn.update(
            'goals',
            {'progressCache': ratio, 'updatedAt': now.millisecondsSinceEpoch},
            where: 'id = ?',
            whereArgs: [course.linkedGoalId],
          );
        }
        final rebuildAlarms = await _rebuildRemindersForCourse(txn, course);
        alarmsToCancel.addAll(rebuildAlarms);
      }
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    await syncCourseAlarms();
    _fireEvent('COMPLETE', courseId: courseId, sessionId: sessionId, allSkipped: allSkipped);
  }

  /// Uncomplete a session (Fixes D-12 State Resets)
  Future<void> uncompleteSession(String sessionId) async {
    final db = await _database;
    final now = DateTime.now();
    String? courseId;

    await db.transaction((txn) async {
      final sessionMaps = await txn.query('course_sessions', where: 'id = ?', whereArgs: [sessionId]);
      if (sessionMaps.isEmpty) return;
      final session = CourseSession.fromMap(sessionMaps.first);
      courseId = session.courseId;

      await txn.update(
        'course_sessions',
        {
          'completionStatus': SessionStatus.pending.dbValue,
          'completedAt': null,
          'updatedAt': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      final courseMaps = await txn.query('courses', where: 'id = ?', whereArgs: [courseId]);
      if (courseMaps.isNotEmpty) {
        final course = Course.fromMap(courseMaps.first);
        // Only set status back to ACTIVE if course was COMPLETED! (Fixes D-12)
        if (course.status == CourseStatus.completed && !course.isArchived) {
          await txn.update(
            'courses',
            {
              'status': CourseStatus.active,
              'completedAt': null,
              'updatedAt': now.millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [courseId],
          );
        }
        await _rebuildRemindersForCourse(txn, course);
      }
    });

    await syncCourseAlarms();
    _fireEvent('UNCOMPLETE', courseId: courseId, sessionId: sessionId);
  }

  /// Skip a session (Fixes D-1 Note Overwrite, D-27 completedAt for skipped sessions, D-13 honest completion)
  Future<void> skipSession(String sessionId, {String? reason}) async {
    final db = await _database;
    final now = DateTime.now();
    String? courseId;
    final alarmsToCancel = <String>[];
    var allSkipped = false;

    await db.transaction((txn) async {
      final sessionMaps = await txn.query('course_sessions', where: 'id = ?', whereArgs: [sessionId]);
      if (sessionMaps.isEmpty) return;
      final session = CourseSession.fromMap(sessionMaps.first);
      courseId = session.courseId;

      // Store skip reason in skipReason column without overwriting user note (Fixes D-1 & D-27)
      await txn.update(
        'course_sessions',
        {
          'completionStatus': SessionStatus.skipped.dbValue,
          'skipReason': reason,
          'completedAt': null, // Do NOT populate completedAt for skipped sessions! (Fixes D-27)
          'updatedAt': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      final rems = await txn.query('pending_reminders', where: 'courseSessionId = ?', whereArgs: [sessionId]);
      for (final r in rems) {
        if (r['id'] != null) alarmsToCancel.add(r['id']! as String);
      }
      await txn.delete('pending_reminders', where: 'courseSessionId = ?', whereArgs: [sessionId]);

      final remainingPending = await txn.query(
        'course_sessions',
        where: 'courseId = ? AND completionStatus = ?',
        whereArgs: [courseId, SessionStatus.pending.dbValue],
      );

      if (remainingPending.isEmpty) {
        final allSessions = await txn.query('course_sessions', where: 'courseId = ?', whereArgs: [courseId]);
        final completedCount = allSessions.where((s) => s['completionStatus'] == SessionStatus.completed.dbValue).length;
        allSkipped = completedCount == 0;

        await txn.update(
          'courses',
          {
            'status': CourseStatus.completed,
            'completedAt': now.millisecondsSinceEpoch,
            'updatedAt': now.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [courseId],
        );
      }

      final courseMaps = await txn.query('courses', where: 'id = ?', whereArgs: [courseId]);
      if (courseMaps.isNotEmpty) {
        final course = Course.fromMap(courseMaps.first);
        final rebuildAlarms = await _rebuildRemindersForCourse(txn, course);
        alarmsToCancel.addAll(rebuildAlarms);
      }
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    await syncCourseAlarms();
    _fireEvent('SKIP', courseId: courseId, sessionId: sessionId, allSkipped: allSkipped);
  }

  /// Reorder sessions within a course & keep titles synchronized (Fixes D-17)
  Future<void> reorderSessions(String courseId, List<String> orderedSessionIds) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final courseMaps = await txn.query('courses', where: 'id = ?', whereArgs: [courseId]);
      final unitLabel = courseMaps.isNotEmpty ? Course.fromMap(courseMaps.first).unitLabelResolved : 'جلسه';

      for (var i = 0; i < orderedSessionIds.length; i++) {
        final sId = orderedSessionIds[i];
        final newNum = i + 1;
        await txn.update(
          'course_sessions',
          {
            'displayOrder': newNum,
            'sessionNumber': newNum,
            'sessionTitle': '$unitLabel $newNum',
            'updatedAt': now,
          },
          where: 'id = ? AND courseId = ?',
          whereArgs: [sId, courseId],
        );
      }
    });

    _fireEvent('REORDER', courseId: courseId);
  }

  /// Manually reschedule a specific session to a new date
  Future<void> rescheduleSession(String sessionId, String? newDateStr) async {
    final db = await _database;
    final now = DateTime.now();
    String? courseId;
    final alarmsToCancel = <String>[];

    await db.transaction((txn) async {
      await txn.update(
        'course_sessions',
        {
          'plannedDate': newDateStr,
          'isUserScheduled': 1,
          'updatedAt': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      final sessionMaps = await txn.query('course_sessions', where: 'id = ?', whereArgs: [sessionId]);
      if (sessionMaps.isNotEmpty) {
        final session = CourseSession.fromMap(sessionMaps.first);
        courseId = session.courseId;
        final courseMaps = await txn.query('courses', where: 'id = ?', whereArgs: [courseId]);
        if (courseMaps.isNotEmpty) {
          final course = Course.fromMap(courseMaps.first);
          final rebuildAlarms = await _rebuildRemindersForCourse(txn, course);
          alarmsToCancel.addAll(rebuildAlarms);
        }
      }
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    await syncCourseAlarms();
    _fireEvent('RESCHEDULE', courseId: courseId, sessionId: sessionId);
  }

  /// Helper to delete a course (Fixes D-25 Linked Goal reference cleanup)
  Future<void> deleteCourse(String courseId) async {
    final db = await _database;
    final alarmsToCancel = <String>[];

    await db.transaction((txn) async {
      final maps = await txn.rawQuery('''
        SELECT id FROM pending_reminders 
        WHERE courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)
      ''', [courseId]);
      for (final row in maps) {
        if (row['id'] != null) {
          alarmsToCancel.add(row['id']! as String);
        }
      }

      await txn.delete('course_active_timers', where: 'courseId = ?', whereArgs: [courseId]);
      await txn.delete('pending_reminders', where: 'courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)', whereArgs: [courseId]);
      await txn.delete('course_sessions', where: 'courseId = ?', whereArgs: [courseId]);
      await txn.delete('courses', where: 'id = ?', whereArgs: [courseId]);
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    await SnapshotSyncService.syncAll();
    _fireEvent('DELETE', courseId: courseId);
  }

  /// Helper to pause, resume, or complete a course (Fixes D-15 auto-reschedule on resume)
  Future<void> updateCourseStatus(String courseId, String status) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final alarmsToCancel = <String>[];

    await db.transaction((txn) async {
      final courseMaps = await txn.query('courses', where: 'id = ?', whereArgs: [courseId]);
      if (courseMaps.isEmpty) return;
      final course = Course.fromMap(courseMaps.first);

      await txn.update(
        'courses',
        {
          'status': status,
          'updatedAt': now,
        },
        where: 'id = ?',
        whereArgs: [courseId],
      );

      // D-15: Auto-reschedule pending sessions starting from today when resuming a course!
      if (status == CourseStatus.active) {
        final pendingMaps = await txn.query(
          'course_sessions',
          where: 'courseId = ? AND completionStatus = ?',
          whereArgs: [courseId, SessionStatus.pending.dbValue],
          orderBy: 'displayOrder ASC, sessionNumber ASC',
        );
        final pendingSessions = pendingMaps.map(CourseSession.fromMap).toList();
        if (pendingSessions.isNotEmpty) {
          final newDates = CourseScheduler.distributeSessions(
            pendingCount: pendingSessions.length,
            from: DateTime.now(),
            weeklyTarget: course.weeklyTargetSessions,
            preferredDays: course.preferredDays,
          );
          for (var i = 0; i < pendingSessions.length; i++) {
            String? newDateStr;
            if (i < newDates.length) {
              newDateStr = _formatDate(newDates[i]);
            }
            await txn.update(
              'course_sessions',
              {'plannedDate': newDateStr, 'updatedAt': now},
              where: 'id = ?',
              whereArgs: [pendingSessions[i].id],
            );
          }
        }
      }

      final rebuildAlarms = await _rebuildRemindersForCourse(txn, course.copyWith(status: status));
      alarmsToCancel.addAll(rebuildAlarms);
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    await syncCourseAlarms();
    _fireEvent('STATUS', courseId: courseId);
  }

  /// Unified method to rebuild reminders for a course, gathering alarm IDs to cancel before delete (Fixes Root 2 & D-2)
  Future<List<String>> _rebuildRemindersForCourse(Transaction txn, Course course) async {
    final alarmsToCancel = <String>[];

    final existingRems = await txn.rawQuery('''
      SELECT id FROM pending_reminders 
      WHERE courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)
    ''', [course.id]);

    for (final row in existingRems) {
      if (row['id'] != null) {
        alarmsToCancel.add(row['id']! as String);
      }
    }

    await txn.rawDelete('''
      DELETE FROM pending_reminders 
      WHERE courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)
    ''', [course.id]);

    if (course.status == CourseStatus.paused ||
        course.status == CourseStatus.completed ||
        course.isArchived ||
        !course.reminderEnabled ||
        course.preferredTime == null) {
      return alarmsToCancel;
    }

    final sessionMaps = await txn.query(
      'course_sessions',
      where: 'courseId = ? AND completionStatus = ? AND plannedDate IS NOT NULL',
      whereArgs: [course.id, SessionStatus.pending.dbValue],
    );

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (final map in sessionMaps) {
      final session = CourseSession.fromMap(map);
      final dateStr = session.plannedDate!;

      final parts = course.preferredTime!.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) continue;
      final year = int.tryParse(dateParts[0]) ?? 0;
      final month = int.tryParse(dateParts[1]) ?? 0;
      final day = int.tryParse(dateParts[2]) ?? 0;

      final reminderDateTime = DateTime(year, month, day, hour, minute);
      final reminderTimeMs = reminderDateTime.millisecondsSinceEpoch;

      if (reminderTimeMs > nowMs) {
        final reminderId = 'rem_${nowMs}_${session.id.hashCode}';
        await txn.insert(
          'pending_reminders',
          {
            'id': reminderId,
            'routineId': null,
            'scheduleId': null,
            'courseSessionId': session.id,
            'originalTime': reminderTimeMs,
            'scheduledTime': reminderTimeMs,
            'state': 'SCHEDULED',
            'deferCount': 0,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    return alarmsToCancel;
  }

  /// Remove raw SQL from UI: fetch linked goal title safely
  Future<String?> getLinkedGoalTitle(String goalId) async {
    final db = await _database;
    final maps = await db.query('goals', columns: ['title'], where: 'id = ?', whereArgs: [goalId], limit: 1);
    if (maps.isNotEmpty) return maps.first['title'] as String?;
    return null;
  }

  /// Remove raw SQL from UI: fetch active goals list safely
  Future<List<Map<String, dynamic>>> getActiveGoalsList() async {
    final db = await _database;
    return await db.query('goals', columns: ['id', 'title'], where: "status = 'ACTIVE' AND isPrivate = 0");
  }

  /// Remove raw SQL from UI: fetch current energy level safely
  Future<String> getCurrentEnergyLevel() async {
    final db = await _database;
    final logs = await db.query('energy_logs', orderBy: 'loggedAt DESC', limit: 1);
    if (logs.isNotEmpty) {
      final lvl = logs.first['level'] as String?;
      if (lvl != null && lvl.isNotEmpty) {
        return lvl.toUpperCase();
      }
    }
    final settings = await db.query('app_settings', where: "key = 'default_energy_level'");
    if (settings.isNotEmpty) {
      return (settings.first['value'] as String? ?? 'MEDIUM').toUpperCase();
    }
    return 'MEDIUM';
  }

  /// Remove raw SQL from UI: fetch course settings safely
  Future<Map<String, String>> getCourseSettings() async {
    final db = await _database;
    final maps = await db.query('app_settings', where: "key LIKE 'module_courses_%' OR key = 'default_energy_level'");
    final result = <String, String>{};
    for (final row in maps) {
      final k = row['key'] as String?;
      final v = row['value'] as String?;
      if (k != null && v != null) {
        result[k] = v;
      }
    }
    return result;
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> syncCourseAlarms() async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final reminders = await db.rawQuery('''
      SELECT pr.id, pr.scheduledTime, c.title
      FROM pending_reminders pr
      JOIN course_sessions cs ON pr.courseSessionId = cs.id
      JOIN courses c ON cs.courseId = c.id
      WHERE pr.state = 'SCHEDULED' AND pr.scheduledTime > ? AND c.status = 'ACTIVE' AND c.isArchived = 0
    ''', [now]);

    for (final r in reminders) {
      final alarmId = r['id']! as String;
      final timeMs = r['scheduledTime']! as int;
      final courseTitle = r['title']! as String;

      await sl<AlarmPlatform>().scheduleExactAlarm(
        id: alarmId,
        timeMsUTC: timeMs,
        title: 'کلاس: $courseTitle',
        isEssential: false,
      );
    }

    await SnapshotSyncService.syncAll();
  }
}
