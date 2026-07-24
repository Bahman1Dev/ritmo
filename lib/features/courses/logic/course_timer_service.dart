import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ActiveCourseTimer {
  ActiveCourseTimer({
    required this.courseId,
    required this.sessionId,
    required this.startedAt,
    required this.elapsedSecondsBeforePause,
    required this.isPaused,
    required this.updatedAt,
  });

  final String courseId;
  final String sessionId;
  final int startedAt;
  final int elapsedSecondsBeforePause;
  final bool isPaused;
  final int updatedAt;

  int calculateCurrentElapsedSeconds(DateTime now) {
    if (isPaused) return elapsedSecondsBeforePause;
    final runningSeconds = (now.millisecondsSinceEpoch - startedAt) ~/ 1000;
    final total = elapsedSecondsBeforePause + (runningSeconds > 0 ? runningSeconds : 0);
    // 8-hour cap (28800 seconds)
    return total > 28800 ? 28800 : total;
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'sessionId': sessionId,
      'startedAt': startedAt,
      'elapsedSecondsBeforePause': elapsedSecondsBeforePause,
      'isPaused': isPaused ? 1 : 0,
      'updatedAt': updatedAt,
    };
  }

  factory ActiveCourseTimer.fromMap(Map<String, dynamic> map) {
    return ActiveCourseTimer(
      courseId: map['courseId'] as String,
      sessionId: map['sessionId'] as String,
      startedAt: map['startedAt'] as int,
      elapsedSecondsBeforePause: map['elapsedSecondsBeforePause'] as int,
      isPaused: (map['isPaused'] as int) == 1,
      updatedAt: map['updatedAt'] as int,
    );
  }
}

class CourseTimerService extends ChangeNotifier {
  CourseTimerService._init();
  static final CourseTimerService instance = CourseTimerService._init();

  ActiveCourseTimer? _activeTimer;
  Timer? _ticker;

  ActiveCourseTimer? get activeTimer => _activeTimer;
  bool get hasActiveTimer => _activeTimer != null;

  int get currentElapsedSeconds {
    if (_activeTimer == null) return 0;
    return _activeTimer!.calculateCurrentElapsedSeconds(DateTime.now());
  }

  Future<Database> get _database async => DatabaseHelper.instance.database;

  /// Restores active timer on app startup (C8)
  Future<void> initOnAppStart() async {
    try {
      final db = await _database;
      final maps = await db.query('course_active_timers', limit: 1);
      if (maps.isNotEmpty) {
        var timer = ActiveCourseTimer.fromMap(maps.first);
        final now = DateTime.now();
        final currentSec = timer.calculateCurrentElapsedSeconds(now);

        // Auto-pause if ran longer than 8 hours
        if (!timer.isPaused && currentSec >= 28800) {
          timer = ActiveCourseTimer(
            courseId: timer.courseId,
            sessionId: timer.sessionId,
            startedAt: now.millisecondsSinceEpoch,
            elapsedSecondsBeforePause: 28800,
            isPaused: true,
            updatedAt: now.millisecondsSinceEpoch,
          );
          await db.update(
            'course_active_timers',
            timer.toMap(),
            where: 'sessionId = ?',
            whereArgs: [timer.sessionId],
          );
        }

        _activeTimer = timer;
        _startTicker();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading active timer: $e');
    }
  }

  Future<void> startTimer(String courseId, String sessionId) async {
    final db = await _database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Clear any existing active timer
    await db.delete('course_active_timers');

    final timer = ActiveCourseTimer(
      courseId: courseId,
      sessionId: sessionId,
      startedAt: nowMs,
      elapsedSecondsBeforePause: 0,
      isPaused: false,
      updatedAt: nowMs,
    );

    await db.insert('course_active_timers', timer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    _activeTimer = timer;
    _startTicker();
    notifyListeners();
  }

  Future<void> pauseTimer(int currentElapsedSeconds) async {
    if (_activeTimer == null) return;
    final db = await _database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final updated = ActiveCourseTimer(
      courseId: _activeTimer!.courseId,
      sessionId: _activeTimer!.sessionId,
      startedAt: nowMs,
      elapsedSecondsBeforePause: currentElapsedSeconds,
      isPaused: true,
      updatedAt: nowMs,
    );

    await db.update(
      'course_active_timers',
      updated.toMap(),
      where: 'sessionId = ?',
      whereArgs: [updated.sessionId],
    );

    _activeTimer = updated;
    _stopTicker();
    notifyListeners();
  }

  Future<void> resumeTimer() async {
    if (_activeTimer == null) return;
    final db = await _database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final updated = ActiveCourseTimer(
      courseId: _activeTimer!.courseId,
      sessionId: _activeTimer!.sessionId,
      startedAt: nowMs,
      elapsedSecondsBeforePause: _activeTimer!.elapsedSecondsBeforePause,
      isPaused: false,
      updatedAt: nowMs,
    );

    await db.update(
      'course_active_timers',
      updated.toMap(),
      where: 'sessionId = ?',
      whereArgs: [updated.sessionId],
    );

    _activeTimer = updated;
    _startTicker();
    notifyListeners();
  }

  Future<void> stopTimer() async {
    if (_activeTimer == null) return;
    final db = await _database;
    await db.delete('course_active_timers');
    _activeTimer = null;
    _stopTicker();
    notifyListeners();
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeTimer != null && !_activeTimer!.isPaused) {
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
