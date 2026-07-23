import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:sqflite/sqflite.dart';

class CoursesRepository {
  CoursesRepository._init();
  static final CoursesRepository instance = CoursesRepository._init();

  Future<Database> get _database async => DatabaseHelper.instance.database;

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
      orderBy: 'sessionNumber ASC',
    );
    return maps.map(CourseSession.fromMap).toList();
  }

  /// Fetch all sessions scheduled for a particular date (plannedDate = 'YYYY-MM-DD')
  Future<List<CourseSession>> getSessionsForDate(String dateStr) async {
    final db = await _database;
    final maps = await db.query(
      'course_sessions',
      where: 'plannedDate = ?',
      whereArgs: [dateStr],
    );
    return maps.map(CourseSession.fromMap).toList();
  }

  /// Create a new course and schedule its sessions
  Future<void> createCourse(Course course) async {
    final db = await _database;
    await db.transaction((txn) async {
      // 1. Insert course
      await txn.insert(
        'courses',
        course.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Generate and insert sessions using CourseScheduler
      final now = DateTime.now();
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
          plannedDate: plannedDateStr,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
          sessionTitle: '${course.unitLabelResolved} ${i + 1}',
        );

        await txn.insert(
          'course_sessions',
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 3. Schedule reminder if enabled
        if (course.reminderEnabled && plannedDateStr != null && course.preferredTime != null) {
          await _scheduleReminderForSession(txn, session, plannedDateStr, course.preferredTime!);
        }
      }
    });

    await syncCourseAlarms();
  }

  /// Complete a specific course session
  Future<void> completeSession({
    required String sessionId,
    required int actualDurationMinutes,
    String? note,
  }) async {
    final db = await _database;
    final now = DateTime.now();
    String? completedDate;
    String? completedCourseId;

    await db.transaction((txn) async {
      // 1. Fetch session to get course details
      final sessionMaps = await txn.query('course_sessions', where: 'id = ?', whereArgs: [sessionId]);
      if (sessionMaps.isEmpty) return;
      final session = CourseSession.fromMap(sessionMaps.first);
      completedDate = session.plannedDate;
      completedCourseId = session.courseId;

      // 2. Update session status
      await txn.update(
        'course_sessions',
        {
          'completionStatus': 'COMPLETED',
          'actualDurationMinutes': actualDurationMinutes,
          'note': note,
          'updatedAt': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      // 3. Delete any scheduled reminder for this session
      await txn.delete(
        'pending_reminders',
        where: 'courseSessionId = ?',
        whereArgs: [sessionId],
      );

      // 4. Check if all sessions for this course are completed
      final courseId = session.courseId;
      final remainingMaps = await txn.query(
        'course_sessions',
        where: 'courseId = ? AND completionStatus = ?',
        whereArgs: [courseId, 'PENDING'],
      );

      if (remainingMaps.isEmpty) {
        // Complete the course itself
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
    });

    // Notify the reactive layer (invalidates DayAgenda cache + refreshes UI).
    RitmoEventBus().fire(RitmoEvent(
      type: 'CourseSessionCompleted',
      timestamp: now,
      payload: {
        'sessionId': sessionId,
        'courseId': ?completedCourseId,
        'date': ?completedDate,
      },
    ));
  }

  /// Update / edit course details and reschedule future sessions if scheduling properties changed
  Future<void> updateCourse(Course updatedCourse, {bool reschedulePending = false}) async {
    final db = await _database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      // 1. Update course columns
      await txn.update(
        'courses',
        updatedCourse.toMap(),
        where: 'id = ?',
        whereArgs: [updatedCourse.id],
      );

      if (reschedulePending) {
        // 2. Fetch remaining pending sessions
        final pendingMaps = await txn.query(
          'course_sessions',
          where: 'courseId = ? AND completionStatus = ?',
          whereArgs: [updatedCourse.id, 'PENDING'],
          orderBy: 'sessionNumber ASC',
        );

        if (pendingMaps.isNotEmpty) {
          final pendingSessions = pendingMaps.map(CourseSession.fromMap).toList();

          // 3. Distribute new dates for pending sessions starting from today/tomorrow
          final sessionDates = CourseScheduler.distributeSessions(
            pendingCount: pendingSessions.length,
            from: now,
            weeklyTarget: updatedCourse.weeklyTargetSessions,
            preferredDays: updatedCourse.preferredDays,
          );

          for (var i = 0; i < pendingSessions.length; i++) {
            final session = pendingSessions[i];
            String? newPlannedDate;
            if (i < sessionDates.length) {
              newPlannedDate = _formatDate(sessionDates[i]);
            }

            // Update session date
            await txn.update(
              'course_sessions',
              {
                'plannedDate': newPlannedDate,
                'updatedAt': now.millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [session.id],
            );

            // 4. Update reminder
            await txn.delete(
              'pending_reminders',
              where: 'courseSessionId = ?',
              whereArgs: [session.id],
            );

            if (updatedCourse.reminderEnabled && newPlannedDate != null && updatedCourse.preferredTime != null) {
              await _scheduleReminderForSession(txn, session, newPlannedDate, updatedCourse.preferredTime!);
            }
          }
        }
      }
    });

    await syncCourseAlarms();
  }

  /// Manually reschedule a specific session to a new date
  Future<void> rescheduleSession(String sessionId, String? newDateStr) async {
    final db = await _database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      // 1. Update planned date
      await txn.update(
        'course_sessions',
        {
          'plannedDate': newDateStr,
          'updatedAt': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      // 2. Update reminder
      await txn.delete(
        'pending_reminders',
        where: 'courseSessionId = ?',
        whereArgs: [sessionId],
      );

      if (newDateStr != null) {
        final sessionMaps = await txn.query('course_sessions', where: 'id = ?', whereArgs: [sessionId]);
        if (sessionMaps.isNotEmpty) {
          final session = CourseSession.fromMap(sessionMaps.first);
          final courseMaps = await txn.query('courses', where: 'id = ?', whereArgs: [session.courseId]);
          if (courseMaps.isNotEmpty) {
            final course = Course.fromMap(courseMaps.first);
            if (course.reminderEnabled && course.preferredTime != null) {
              await _scheduleReminderForSession(txn, session, newDateStr, course.preferredTime!);
            }
          }
        }
      }
    });

    await syncCourseAlarms();
  }

  /// Helper to delete a course
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

      await txn.delete('pending_reminders', where: 'courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)', whereArgs: [courseId]);
      await txn.delete('course_sessions', where: 'courseId = ?', whereArgs: [courseId]);
      await txn.delete('courses', where: 'id = ?', whereArgs: [courseId]);
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }
    await SnapshotSyncService.syncAll();
  }

  /// Helper to pause or resume a course
  Future<void> updateCourseStatus(String courseId, String status) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final alarmsToCancel = <String>[];

    await db.transaction((txn) async {
      await txn.update(
        'courses',
        {
          'status': status,
          'updatedAt': now,
        },
        where: 'id = ?',
        whereArgs: [courseId],
      );

      if (status == 'PAUSED') {
        final maps = await txn.rawQuery('''
          SELECT id FROM pending_reminders 
          WHERE courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)
        ''', [courseId]);
        for (final row in maps) {
          if (row['id'] != null) {
            alarmsToCancel.add(row['id']! as String);
          }
        }

        await txn.update(
          'pending_reminders',
          {'state': 'CANCELLED', 'updatedAt': now},
          where: 'courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)',
          whereArgs: [courseId],
        );
      } else if (status == 'ACTIVE') {
        await txn.update(
          'pending_reminders',
          {'state': 'SCHEDULED', 'updatedAt': now},
          where: 'courseSessionId IN (SELECT id FROM course_sessions WHERE courseId = ?)',
          whereArgs: [courseId],
        );
      }
    });

    for (final id in alarmsToCancel) {
      await sl<AlarmPlatform>().cancelAlarm(id);
    }

    await syncCourseAlarms();
  }

  /// Helper to schedule a reminder in `pending_reminders`
  Future<void> _scheduleReminderForSession(
    Transaction txn,
    CourseSession session,
    String dateStr,
    String timeStr,
  ) async {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return;
      final year = int.tryParse(dateParts[0]) ?? 0;
      final month = int.tryParse(dateParts[1]) ?? 0;
      final day = int.tryParse(dateParts[2]) ?? 0;

      final reminderDateTime = DateTime(year, month, day, hour, minute);
      final reminderTimeMs = reminderDateTime.millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;

      final reminderId = 'rem_${now}_${session.id.hashCode}';

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
          'createdAt': now,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error scheduling reminder for session: $e');
    }
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

    // 1. Query all course reminders that are scheduled in the future
    final reminders = await db.rawQuery('''
      SELECT pr.id, pr.scheduledTime, c.title
      FROM pending_reminders pr
      JOIN course_sessions cs ON pr.courseSessionId = cs.id
      JOIN courses c ON cs.courseId = c.id
      WHERE pr.state = 'SCHEDULED' AND pr.scheduledTime > ? AND c.status = 'ACTIVE' AND c.isArchived = 0
    ''', [now]);

    // 2. Schedule physical alarms for each
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

    // 3. Sync full snapshot for widgets/BootReceiver
    await SnapshotSyncService.syncAll();
  }
}

