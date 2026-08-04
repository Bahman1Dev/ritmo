import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

enum TimerDirection { down, up }

class ActiveTimerModel {
  final String id;
  final String domain;
  final String itemId;
  final String mode; // 'FULL' | 'LIGHT' | 'MINIMAL' | 'CUSTOM'
  final TimerDirection direction;
  final int targetTimestamp; // Epoch MS
  final int durationSeconds;
  final int createdAt;

  const ActiveTimerModel({
    required this.id,
    required this.domain,
    required this.itemId,
    required this.mode,
    required this.direction,
    required this.targetTimestamp,
    required this.durationSeconds,
    required this.createdAt,
  });

  /// Calculates remaining seconds for countdown timer (down to 0).
  int get remainingSeconds {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diff = ((targetTimestamp - nowMs) / 1000).round();
    return diff.clamp(0, durationSeconds);
  }

  /// Calculates elapsed seconds.
  int get elapsedSeconds {
    return (durationSeconds - remainingSeconds).clamp(0, durationSeconds);
  }

  bool get isExpired => remainingSeconds <= 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'domain': domain,
        'itemId': itemId,
        'mode': mode,
        'direction': direction.name.toUpperCase(),
        'targetTimestamp': targetTimestamp,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt,
        // Compatibility fields for legacy NOT NULL table schemas
        'routineId': itemId.isNotEmpty ? itemId : id,
        'startedAt': createdAt,
        'plannedDurationMinutes': (durationSeconds / 60).round(),
      };

  factory ActiveTimerModel.fromMap(Map<String, dynamic> map) {
    final rawItemId = (map['itemId'] as String?) ?? (map['routineId'] as String?) ?? '';
    final rawCreatedAt = (map['createdAt'] as int?) ?? (map['startedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
    final rawDuration = (map['durationSeconds'] as int?) ?? ((map['plannedDurationMinutes'] as int? ?? 0) * 60);

    return ActiveTimerModel(
      id: map['id']! as String,
      domain: map['domain'] as String? ?? 'routine',
      itemId: rawItemId,
      mode: map['mode'] as String? ?? 'FULL',
      direction: map['direction'] == 'UP' ? TimerDirection.up : TimerDirection.down,
      targetTimestamp: map['targetTimestamp'] as int? ?? (rawCreatedAt + (rawDuration * 1000)),
      durationSeconds: rawDuration,
      createdAt: rawCreatedAt,
    );
  }
}

/// Unified Doze-safe timer service using Target Timestamp in SQLite.
class RitmoTimerService extends ChangeNotifier {
  RitmoTimerService._();
  static final instance = RitmoTimerService._();

  Timer? _ticker;
  final List<ActiveTimerModel> _activeTimers = [];

  List<ActiveTimerModel> get activeTimers => List.unmodifiable(_activeTimers);

  Future<void> init() async {
    await loadTimers();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  Future<void> loadTimers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('active_timers');
      _activeTimers.clear();
      for (final r in rows) {
        _activeTimers.add(ActiveTimerModel.fromMap(r));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[RitmoTimerService] loadTimers error: $e');
    }
  }

  Future<void> startTimer({
    required String id,
    required String domain,
    required String itemId,
    required String mode,
    required int durationMinutes,
    TimerDirection direction = TimerDirection.down,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final targetMs = nowMs + (durationMinutes * 60 * 1000);
    final model = ActiveTimerModel(
      id: id,
      domain: domain,
      itemId: itemId,
      mode: mode,
      direction: direction,
      targetTimestamp: targetMs,
      durationSeconds: durationMinutes * 60,
      createdAt: nowMs,
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'active_timers',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await loadTimers();
  }

  Future<void> cancelTimer(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('active_timers', where: 'id = ?', whereArgs: [id]);
    await loadTimers();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
