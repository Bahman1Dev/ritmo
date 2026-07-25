import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class RoutineNiyyahSheet extends StatefulWidget {

  const RoutineNiyyahSheet({
    super.key,
    required this.routine,
    this.initialMode = 'FULL',
    required this.onStartTimer,
    required this.onCompleteInstantly,
    required this.onSnooze,
    required this.onEdit,
    required this.onViewDetails,
  });
  final Routine routine;
  final String initialMode;
  final Function(String selectedMode) onStartTimer;
  final Function(String selectedMode, int duration) onCompleteInstantly;
  final VoidCallback onSnooze;
  final VoidCallback onEdit;
  final VoidCallback onViewDetails;

  static Future<void> show({
    required BuildContext context,
    required Routine routine,
    String initialMode = 'FULL',
    required Function(String selectedMode) onStartTimer,
    required Function(String selectedMode, int duration) onCompleteInstantly,
    required VoidCallback onSnooze,
    required VoidCallback onEdit,
    required VoidCallback onViewDetails,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RoutineNiyyahSheet(
        routine: routine,
        initialMode: initialMode,
        onStartTimer: onStartTimer,
        onCompleteInstantly: onCompleteInstantly,
        onSnooze: onSnooze,
        onEdit: onEdit,
        onViewDetails: onViewDetails,
      ),
    );
  }

  @override
  State<RoutineNiyyahSheet> createState() => _RoutineNiyyahSheetState();
}

class _RoutineNiyyahSheetState extends State<RoutineNiyyahSheet> {
  late String selectedMode;

  @override
  void initState() {
    super.initState();
    selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final fullMinutes = widget.routine.currentTargetMinutes > 0 ? widget.routine.currentTargetMinutes : (widget.routine.targetDurationMinutes ?? 30);
    final lightMinutes = widget.routine.lightDurationMinutes ?? 20;
    final minimalMinutes = widget.routine.minimalDurationMinutes ?? 10;

    final canStartTimer = fullMinutes > 0 || lightMinutes > 0 || minimalMinutes > 0;

    final hasTiers = (widget.routine.lightDurationMinutes != null && widget.routine.lightDurationMinutes! > 0) ||
                     (widget.routine.minimalDurationMinutes != null && widget.routine.minimalDurationMinutes! > 0);

    return Container(
      margin: const EdgeInsets.all(16),
      child: RitmoTheme.glassCardLight(
        blurSigma: 20,
        color: colors.card.withValues(alpha: isDarkMode ? 0.85 : 0.9),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'نیت انجام: ${widget.routine.title}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              if (widget.routine.description != null && widget.routine.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.routine.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
              if (hasTiers) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Full Mode
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          RitmoHaptics.tap();
                          setState(() => selectedMode = 'FULL');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: selectedMode == 'FULL'
                                ? LinearGradient(
                                    colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: selectedMode == 'FULL' ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedMode == 'FULL' ? colors.primary : colors.border.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: selectedMode == 'FULL'
                                ? [
                                    BoxShadow(
                                      color: colors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'کامل 🎯',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: selectedMode == 'FULL' ? Colors.white : colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${PersianDigits.convert(fullMinutes.toString())} دقیقه',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selectedMode == 'FULL' ? Colors.white70 : colors.textSecondary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Light Mode
                    if (widget.routine.lightDurationMinutes != null && widget.routine.lightDurationMinutes! > 0)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            RitmoHaptics.tap();
                            setState(() => selectedMode = 'LIGHT');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selectedMode == 'LIGHT'
                                  ? LinearGradient(
                                      colors: [colors.success, colors.success.withValues(alpha: 0.8)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: selectedMode == 'LIGHT' ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedMode == 'LIGHT' ? colors.success : colors.border.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: selectedMode == 'LIGHT'
                                  ? [
                                      BoxShadow(
                                        color: colors.success.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                  ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'سبک ⚡',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: selectedMode == 'LIGHT' ? Colors.white : colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${PersianDigits.convert(lightMinutes.toString())} دقیقه',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: selectedMode == 'LIGHT' ? Colors.white70 : colors.textSecondary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (widget.routine.lightDurationMinutes != null && widget.routine.lightDurationMinutes! > 0)
                      const SizedBox(width: 8),

                    // Minimal Mode
                    if (widget.routine.minimalDurationMinutes != null && widget.routine.minimalDurationMinutes! > 0)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            RitmoHaptics.tap();
                            setState(() => selectedMode = 'MINIMAL');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selectedMode == 'MINIMAL'
                                  ? const LinearGradient(
                                      colors: [Colors.orange, Colors.orangeAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: selectedMode == 'MINIMAL' ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedMode == 'MINIMAL' ? Colors.orange : colors.border.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: selectedMode == 'MINIMAL'
                                  ? [
                                      BoxShadow(
                                        color: Colors.orange.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'حداقلی 🌿',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: selectedMode == 'MINIMAL' ? Colors.white : colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${PersianDigits.convert(minimalMinutes.toString())} دقیقه',
                                  style: TextStyle(
                                    color: selectedMode == 'MINIMAL' ? Colors.white70 : colors.textSecondary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.clock, color: colors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'مدت زمان هدف: ${PersianDigits.convert(fullMinutes.toString())} دقیقه',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (canStartTimer)
                Row(
                  children: [
                    // Start Timer
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          RitmoHaptics.confirm();
                          Navigator.pop(context);
                          widget.onStartTimer(selectedMode);
                        },
                        icon: const Icon(CupertinoIcons.timer, size: 18),
                        label: const Text('شروع تایمر تمرکز', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Log Instantly
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.success,
                          side: BorderSide(color: colors.success, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          RitmoHaptics.confirm();
                          Navigator.pop(context);
                          final duration = selectedMode == 'FULL'
                              ? fullMinutes
                              : (selectedMode == 'LIGHT' ? lightMinutes : minimalMinutes);
                          widget.onCompleteInstantly(selectedMode, duration);
                        },
                        child: const Text('ثبت فوری بدون تایمر', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.success,
                    side: BorderSide(color: colors.success, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    RitmoHaptics.confirm();
                    Navigator.pop(context);
                    final duration = selectedMode == 'FULL'
                        ? fullMinutes
                        : (selectedMode == 'LIGHT' ? lightMinutes : minimalMinutes);
                    widget.onCompleteInstantly(selectedMode, duration);
                  },
                  child: const Text('ثبت فوری بدون تایمر', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Snooze Option
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        RitmoHaptics.tap();
                        Navigator.pop(context);
                        widget.onSnooze();
                      },
                      icon: const Icon(CupertinoIcons.time, size: 16),
                      label: const Text('تعویق روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit Option
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        RitmoHaptics.tap();
                        Navigator.pop(context);
                        widget.onEdit();
                      },
                      icon: const Icon(CupertinoIcons.pencil, size: 16),
                      label: const Text('ویرایش روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Details Option
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xffA78BFA),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        RitmoHaptics.tap();
                        Navigator.pop(context);
                        widget.onViewDetails();
                      },
                      icon: const Icon(CupertinoIcons.chart_bar_fill, size: 16),
                      label: const Text('مشاهده جزئیات', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
