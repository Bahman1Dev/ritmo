import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class RitmoToast {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Color iconColor = const Color(0xffD4A843),
    VoidCallback? onUndo,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final effectiveUndo = onUndo ?? onAction;
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _RitmoTopToastWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        onDismiss: () {
          overlayEntry.remove();
        },
        onUndo: effectiveUndo,
      ),
    );
    overlayState.insert(overlayEntry);
  }
}

class _RitmoTopToastWidget extends StatefulWidget {

  const _RitmoTopToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
    this.onUndo,
  });
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;
  final VoidCallback? onUndo;

  @override
  State<_RitmoTopToastWidget> createState() => _RitmoTopToastWidgetState();
}

class _RitmoTopToastWidgetState extends State<_RitmoTopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;
  int _secondsLeft = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    final autoDismissMs = widget.onUndo != null ? 5200 : 2200;
    _dismissTimer = Timer(Duration(milliseconds: autoDismissMs), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });

    if (widget.onUndo != null) {
      _secondsLeft = 5;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
          if (_secondsLeft <= 0) t.cancel();
        } else {
          t.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleUndo() {
    _dismissTimer?.cancel();
    _countdownTimer?.cancel();
    if (widget.onUndo != null) widget.onUndo!();
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 64,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff1E2235).withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: widget.iconColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (widget.onUndo != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 16,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.25),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _handleUndo,
                            child: Text(
                              'لغو ($_secondsLeft)',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff60A5FA),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
