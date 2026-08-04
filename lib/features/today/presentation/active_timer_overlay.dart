import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/ritmo_timer_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

// T6: Separate completed vs cancelled callbacks
// T4: dateStr required parameter — never use DateTime.now() for completionDate
// T7: Single timer ID pattern: 'routine_${routine.id}'
// T8: All DB reads via RitmoTimerService / ActiveTimerModel, no raw column access
// T9: _showCompletionDialog called outside setState via timer.cancel()
// B7: Single 'dart:async' import (duplicate removed)

class ActiveTimerOverlay extends StatefulWidget {
  const ActiveTimerOverlay({
    super.key,
    required this.routine,
    required this.completionMode,
    required this.dateStr,          // T4: required, from item.dateStr
    required this.onCompleted,      // T6: called only on confirmed completion
    required this.onCancelled,      // T6: called on cancel / "no thanks"
  });

  final Routine routine;
  final String completionMode; // FULL, LIGHT, MINIMAL
  final String dateStr;        // T4: the agenda item's date, not today's date
  final void Function(CompletionOutcome outcome) onCompleted; // T6
  final VoidCallback onCancelled;                             // T6

  @override
  State<ActiveTimerOverlay> createState() => _ActiveTimerOverlayState();
}

class _ActiveTimerOverlayState extends State<ActiveTimerOverlay>
    with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  Timer? _timer;
  late AnimationController _animController;

  // T7: single canonical timer ID
  String get _timerId => 'routine_${widget.routine.id}';

  int _resolveDur(int? v, int fallback) => (v != null && v > 0) ? v : fallback;

  @override
  void initState() {
    super.initState();
    _initTimerValues();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _initTimerValues() {
    var durationMinutes = 30;
    if (widget.completionMode == 'FULL') {
      durationMinutes = widget.routine.currentTargetMinutes > 0
          ? widget.routine.currentTargetMinutes
          : _resolveDur(widget.routine.targetDurationMinutes, 30);
    } else if (widget.completionMode == 'LIGHT') {
      durationMinutes = _resolveDur(widget.routine.lightDurationMinutes, 20);
    } else if (widget.completionMode == 'MINIMAL') {
      durationMinutes = _resolveDur(widget.routine.minimalDurationMinutes, 10);
    }
    _totalSeconds = durationMinutes * 60;

    if (_totalSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'مدتزمان نامعتبر است؛ تایمر قابل اجرا نیست.',
              style: TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        );
        Navigator.of(context).pop();
      });
      return;
    }
  }

  Future<void> _startTimer() async {
    if (_totalSeconds <= 0) return;

    // T7: Start timer with canonical ID — the same ID that router used
    // (router also calls startTimer with 'routine_${routine.id}'; the
    //  ConflictAlgorithm.replace in RitmoTimerService deduplicates automatically)
    await RitmoTimerService.instance.startTimer(
      id: _timerId,
      domain: 'routine',
      itemId: widget.routine.id,
      mode: widget.completionMode,
      durationMinutes: (_totalSeconds / 60).round(),
    );

    // Start Native Foreground Service
    await sl<NotificationPlatform>().startTimerMode(
      title: widget.routine.title,
      durationSeconds: _totalSeconds,
      elapsedSeconds: _elapsedSeconds,
    );

    // T9: Start local ticking — _showCompletionDialog called OUTSIDE setState
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_elapsedSeconds < _totalSeconds) {
        setState(() => _elapsedSeconds++);
        return;
      }
      timer.cancel();
      if (!mounted) return;
      unawaited(_showCompletionDialog());
    });
  }

  // T8: _togglePause reads/writes via RitmoTimerService model, no raw columns
  Future<void> _togglePause() async {
    RitmoHaptics.confirm();
    setState(() {
      _isPaused = !_isPaused;
    });

    // Reflect pause state in notification only — DB state is derived from
    // ActiveTimerModel.remainingSeconds which uses targetTimestamp (immutable).
    if (_isPaused) {
      await sl<NotificationPlatform>().startTimerMode(
        title: '${widget.routine.title} (متوقف‌شده)',
        durationSeconds: _totalSeconds,
        elapsedSeconds: _elapsedSeconds,
      );
    } else {
      await sl<NotificationPlatform>().startTimerMode(
        title: widget.routine.title,
        durationSeconds: _totalSeconds,
        elapsedSeconds: _elapsedSeconds,
      );
    }
  }

  // T6: Cancel path — calls onCancelled, no success message
  Future<void> _cancelTimer() async {
    RitmoHaptics.warning();
    _timer?.cancel();
    await RitmoTimerService.instance.cancelTimer(_timerId); // T7: same ID
    await sl<NotificationPlatform>().stopForegroundService();
    widget.onCancelled(); // T6: never fires success feedback
  }

  // T5+T6: Complete path — goes through CompletionGateway, returns outcome
  Future<void> _completeRoutine() async {
    RitmoHaptics.success();
    _timer?.cancel();

    // T5: Route through CompletionGateway (not direct AlarmSchedulerService)
    final outcome = await CompletionGateway.instance.submit(
      RoutineCompletion(
        routineId: widget.routine.id,
        dateStr: widget.dateStr,   // T4: from item, never DateTime.now()
        result: CompletionResult.fromDb(widget.completionMode),
        durationMinutes: DurationBounds.sanitize((_elapsedSeconds / 60).round()),
      ),
    );

    // Delete active timer — T7: same canonical ID
    await RitmoTimerService.instance.cancelTimer(_timerId);

    // Downgrade notification — only on success path (T6)
    if (outcome.didWrite) {
      final db = await DatabaseHelper.instance.database;
      final settingsList = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['persistent_status_notification_enabled'],
      );
      final isEnabled =
          settingsList.isEmpty || settingsList.first['value'] != 'false';
      if (isEnabled) {
        await sl<NotificationPlatform>().startStatusMode(
          zone: 'آزاد',
          energy: 'متوسط',
          proposedTask: 'استراحت 🌿',
        );
      } else {
        await sl<NotificationPlatform>().stopForegroundService();
      }
    } else {
      await sl<NotificationPlatform>().stopForegroundService();
    }

    widget.onCompleted(outcome); // T6: passes outcome to router for proper feedback
  }

  Future<void> _showCompletionDialog() async {
    RitmoHaptics.confirm();
    if (!mounted) return;
    final colors = context.colors;

    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'تایمر به پایان رسید 🎉',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            content: Text(
              'زمان تعیین شده برای روتین "${widget.routine.title}" تمام شد. آیا آن را انجام دادید؟',
              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(
                  'نه، بعداً انجام میدم',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: colors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text(
                  'آره، انجام دادم',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (done ?? false) {
      await _completeRoutine(); // T6: only this path fires success
    } else {
      await _cancelTimer(); // T6: fires onCancelled — no success message
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final remaining = _totalSeconds - _elapsedSeconds;
    final min = remaining / 60;
    final sec = remaining % 60;
    final timeStr =
        '${min.floor().toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
    final progress = _totalSeconds > 0 ? _elapsedSeconds / _totalSeconds : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xff121526),
                      const Color(0xff080912),
                    ]
                  : [
                      const Color(0xffF2F4F7),
                      const Color(0xffE4E7EC),
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // App Bar / Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _cancelTimer,
                        icon: Icon(Icons.close, color: colors.textSecondary),
                      ),
                      Text(
                        'تمرکز پویا',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(width: 48), // spacer balance
                    ],
                  ),
                  const Spacer(),

                  // Pulsing breathe animation
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final scale = 1.0 + (_animController.value * 0.08);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                )
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: CircularProgressIndicator(
                                    value: 1.0 - progress,
                                    strokeWidth: 6,
                                    color: colors.primary,
                                    backgroundColor: colors.border,
                                  ),
                                ),
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.card.withValues(
                                        alpha: isDark ? 0.03 : 0.65),
                                    border: Border.all(
                                      color: colors.border.withValues(
                                          alpha: isDark ? 0.1 : 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w300,
                                          fontFamily: 'Courier',
                                          color: colors.textPrimary,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.completionMode == 'FULL'
                                            ? 'حالت کامل 🎯'
                                            : widget.completionMode == 'LIGHT'
                                                ? 'حالت سبک ⚡'
                                                : 'حالت حداقلی 🌿',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textSecondary,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Routine Title
                  Text(
                    widget.routine.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.routine.description != null)
                    Text(
                      widget.routine.description!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),

                  const Spacer(),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Complete early
                      GestureDetector(
                        onTap: _completeRoutine,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.success.withValues(alpha: 0.15),
                            border: Border.all(color: colors.success, width: 2),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 28,
                            color: colors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Pause/Play Toggle
                      GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Cancel/Stop Timer
                      GestureDetector(
                        onTap: _cancelTimer,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.medicalRed.withValues(alpha: 0.15),
                            border:
                                Border.all(color: colors.medicalRed, width: 2),
                          ),
                          child: Icon(
                            Icons.stop,
                            size: 28,
                            color: colors.medicalRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
