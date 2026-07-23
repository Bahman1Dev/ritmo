import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class SportsRestTimerBanner extends StatefulWidget {

  const SportsRestTimerBanner({
    super.key,
    this.initialSeconds = 60,
    required this.onSkip,
    required this.onFinished,
  });
  final int initialSeconds;
  final VoidCallback onSkip;
  final VoidCallback onFinished;

  @override
  State<SportsRestTimerBanner> createState() => _SportsRestTimerBannerState();
}

class _SportsRestTimerBannerState extends State<SportsRestTimerBanner> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        RitmoHaptics.warning(); // Vibrate to notify finish
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // تبدیل اعداد به فارسی (اختیاری ولی برای زیبایی بهتر است)
    final timeText = _formatTime(_remainingSeconds)
        .replaceAll('0', '۰').replaceAll('1', '۱').replaceAll('2', '۲')
        .replaceAll('3', '۳').replaceAll('4', '۴').replaceAll('5', '۵')
        .replaceAll('6', '۶').replaceAll('7', '۷').replaceAll('8', '۸')
        .replaceAll('9', '۹');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffC9822A).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffC9822A).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Text('⏱', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('استراحت: $timeText',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: Color(0xffE0A75E), fontFamily: 'Vazirmatn')),
          ),
          TextButton(
            onPressed: () {
              RitmoHaptics.tap();
              _timer?.cancel();
              widget.onSkip();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('رد کن', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
