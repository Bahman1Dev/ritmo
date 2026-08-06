import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

class FullscreenTasbihSheet extends StatefulWidget {
  const FullscreenTasbihSheet({
    super.key,
    this.initialDhikrTitle = 'تسبیحات حضرت زهرا (س)',
    this.targetCount = 100,
    this.isFatimaTasbih = true,
  });

  final String initialDhikrTitle;
  final int targetCount;
  final bool isFatimaTasbih;

  static Future<void> present(
    BuildContext context, {
    String initialDhikrTitle = 'تسبیحات حضرت زهرا (س)',
    int targetCount = 100,
    bool isFatimaTasbih = true,
  }) {
    return Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => FullscreenTasbihSheet(
          initialDhikrTitle: initialDhikrTitle,
          targetCount: targetCount,
          isFatimaTasbih: isFatimaTasbih,
        ),
      ),
    );
  }

  @override
  State<FullscreenTasbihSheet> createState() => _FullscreenTasbihSheetState();
}

class _FullscreenTasbihSheetState extends State<FullscreenTasbihSheet> {
  int _currentCount = 0;
  int _stageIndex = 0; // 0 = Allahu Akbar (34), 1 = Alhamdulillah (33), 2 = SubhanAllah (33)

  final List<_TasbihStage> _fatimaStages = const [
    _TasbihStage('اللهُ أَکْبَرُ', 'الله اکبر', 34, Color(0xFFFFD700)),
    _TasbihStage('الْحَمْدُ لِلَّهِ', 'الحمد لله', 33, Color(0xFF4CAF50)),
    _TasbihStage('سُبْحَانَ اللَّهِ', 'سبحان الله', 33, Color(0xFF2196F3)),
  ];

  void _onTap() {
    unawaited(HapticFeedback.lightImpact());

    if (widget.isFatimaTasbih) {
      final currentStage = _fatimaStages[_stageIndex];
      setState(() {
        _currentCount++;
      });

      if (_currentCount >= currentStage.target) {
        unawaited(HapticFeedback.heavyImpact());
        if (_stageIndex < _fatimaStages.length - 1) {
          setState(() {
            _stageIndex++;
            _currentCount = 0;
          });
        } else {
          // Completed full 100!
          _showCompletionDialog();
        }
      }
    } else {
      setState(() {
        _currentCount++;
      });
      if (_currentCount % 33 == 0) {
        unawaited(HapticFeedback.heavyImpact());
      }
      if (_currentCount >= widget.targetCount) {
        _showCompletionDialog();
      }
    }
  }

  void _reset() {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _currentCount = 0;
      _stageIndex = 0;
    });
  }

  void _showCompletionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('قبول باشد 🤲'),
        content: const Text('ذکر به پایان رسید. خدا از شما قبول بفرماید.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('تکرار مجدد'),
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('بستن'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stage = widget.isFatimaTasbih ? _fatimaStages[_stageIndex] : null;
    final activeColor = stage?.accentColor ?? const Color(0xffD4A843);
    final dhikrArabic = stage?.arabicText ?? widget.initialDhikrTitle;
    final dhikrTitle = stage?.titleFa ?? 'ذکر و تسبیح';
    final target = stage?.target ?? widget.targetCount;
    final progress = (target > 0) ? (_currentCount / target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: colors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SafeArea(
          child: Stack(
            children: [
              // ── Fullscreen Touch Surface ──
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stage indicator pill (for Fatima Tasbih)
                    if (widget.isFatimaTasbih) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_fatimaStages.length, (i) {
                          final st = _fatimaStages[i];
                          final isActive = i == _stageIndex;
                          final isDone = i < _stageIndex;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? st.accentColor.withValues(alpha: 0.2)
                                  : isDone
                                      ? colors.textSecondary.withValues(alpha: 0.1)
                                      : colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? st.accentColor : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              st.titleFa,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive
                                    ? st.accentColor
                                    : isDone
                                        ? colors.textSecondary
                                        : colors.textSecondary.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Arabic / Main Dhikr Phrase
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        dhikrArabic,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (widget.isFatimaTasbih)
                      Text(
                        dhikrTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    const SizedBox(height: 48),

                    // Counter Circle Progress Ring
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress Ring
                          SizedBox(
                            width: 190,
                            height: 190,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: colors.textPrimary.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),

                          // Count Number
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                toPersianDigits('$_currentCount'),
                                style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              Text(
                                toPersianDigits('از $target'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textSecondary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Touch Hint
                    Text(
                      'برای افزایش شمارش، هر جای صفحه را لمس کنید',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Top Bar: Close & Reset Buttons ──
              Positioned(
                top: 16,
                right: 16,
                left: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 28),
                      color: colors.textSecondary.withValues(alpha: 0.6),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise_circle_fill, size: 28),
                      color: colors.textSecondary.withValues(alpha: 0.6),
                      onPressed: _reset,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasbihStage {
  const _TasbihStage(this.arabicText, this.titleFa, this.target, this.accentColor);
  final String arabicText;
  final String titleFa;
  final int target;
  final Color accentColor;
}
