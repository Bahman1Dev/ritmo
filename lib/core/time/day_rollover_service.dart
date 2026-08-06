import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

class DayRolloverService {
  Timer? _timer;
  String _lastDayKey = '';

  void start() {
    _lastDayKey = _todayKey();
    _schedule();
    WidgetsBinding.instance.addObserver(_LifecycleHook(onResume: _checkNow));
  }

  static String _todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  void _schedule() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _timer?.cancel();
    _timer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        _lastDayKey = _todayKey();
        RitmoEventBus().fire(
          RitmoEvent(
            type: RitmoEventType.dayRolledOver.code,
            timestamp: DateTime.now(),
            payload: {'date': _lastDayKey},
          ),
        );
        _schedule();
      },
    );
  }

  void _checkNow() {
    final currentKey = _todayKey();
    if (_lastDayKey.isNotEmpty && currentKey != _lastDayKey) {
      _lastDayKey = currentKey;
      RitmoEventBus().fire(
        RitmoEvent(
          type: RitmoEventType.dayRolledOver.code,
          timestamp: DateTime.now(),
          payload: {'date': currentKey},
        ),
      );
    }
  }

  void stop() {
    _timer?.cancel();
  }
}

class _LifecycleHook extends WidgetsBindingObserver {
  _LifecycleHook({required this.onResume});
  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
