import 'dart:async';
import 'package:flutter/material.dart';

class NowTicker extends StatefulWidget {
  const NowTicker({
    super.key,
    required this.builder,
    this.isToday = true,
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final bool isToday;

  @override
  State<NowTicker> createState() => _NowTickerState();
}

class _NowTickerState extends State<NowTicker> with WidgetsBindingObserver {
  late final ValueNotifier<DateTime> _nowNotifier;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nowNotifier = ValueNotifier(DateTime.now());
    if (widget.isToday) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(NowTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isToday != oldWidget.isToday) {
      if (widget.isToday) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _nowNotifier.value = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _nowNotifier.value = DateTime.now();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isToday) {
      _startTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _nowNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _nowNotifier,
      builder: (ctx, now, _) => widget.builder(ctx, now),
    );
  }
}
