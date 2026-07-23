import 'dart:async';
import 'package:flutter/material.dart';

class RealmCountdownWidget extends StatefulWidget {

  const RealmCountdownWidget({
    super.key,
    required this.activeZone,
    required this.style,
  });
  final Map<String, dynamic> activeZone;
  final TextStyle style;

  @override
  State<RealmCountdownWidget> createState() => _RealmCountdownWidgetState();
}

class _RealmCountdownWidgetState extends State<RealmCountdownWidget> with WidgetsBindingObserver {
  Timer? _timer;
  late ValueNotifier<int> _remainingSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = ValueNotifier<int>(_calculateSecs());
    _startTimer();
  }

  int _calculateSecs() {
    final now = DateTime.now();
    if (widget.activeZone['isOverride'] == true) {
      final overrideUntilMs = widget.activeZone['overrideUntilMs'] as int? ?? 0;
      final diffMs = overrideUntilMs - now.millisecondsSinceEpoch;
      return diffMs > 0 ? (diffMs / 1000).ceil() : 0;
    }
    final endTimeStr = widget.activeZone['endTime'] as String?;
    if (endTimeStr == null) return 0;
    final parts = endTimeStr.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final min = int.tryParse(parts[1]) ?? 0;
    final endDateTime = DateTime(now.year, now.month, now.day, hour, min);
    final diff = endDateTime.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final secs = _calculateSecs();
      _remainingSeconds.value = secs;
      if (secs <= 0) {
        _timer?.cancel();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopTimer();
    } else if (state == AppLifecycleState.resumed) {
      _remainingSeconds.value = _calculateSecs();
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant RealmCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _remainingSeconds.value = _calculateSecs();
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _remainingSeconds.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '۰۰:۰۰:۰۰';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    
    return _toPersianDigits('$hStr:$mStr:$sStr');
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _remainingSeconds,
      builder: (context, seconds, child) {
        return Text(
          'باقی‌مانده: ${_formatDuration(seconds)}',
          style: widget.style,
        );
      },
    );
  }
}
