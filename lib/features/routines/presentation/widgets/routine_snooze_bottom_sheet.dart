import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RoutineSnoozeBottomSheet extends StatefulWidget {

  const RoutineSnoozeBottomSheet({
    super.key,
    required this.routine,
    required this.onSnoozeSelected,
  });
  final Routine routine;
  final Function(int minutes) onSnoozeSelected;

  static void show({
    required BuildContext context,
    required Routine routine,
    required Function(int minutes) onSnoozeSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RoutineSnoozeBottomSheet(
        routine: routine,
        onSnoozeSelected: onSnoozeSelected,
      ),
    );
  }

  @override
  State<RoutineSnoozeBottomSheet> createState() => _RoutineSnoozeBottomSheetState();
}

class _RoutineSnoozeBottomSheetState extends State<RoutineSnoozeBottomSheet> {
  int _customMinutes = 15;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget buildOptionCard({
      required String label,
      required String subtitle,
      required IconData icon,
      required Color color,
      required int minutes,
      bool isFullWidth = false,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: RitmoTheme.glassCardLight(
          borderRadius: 16,
          color: colors.card.withValues(alpha: 0.55),
          border: Border.all(color: colors.border.withValues(alpha: 0.35), width: 1.2),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              widget.onSnoozeSelected(minutes);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_left, color: colors.textSecondary.withValues(alpha: 0.5), size: 12),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: RitmoTheme.glassCardLight(
          blurSigma: 20,
          color: colors.card.withValues(alpha: isDarkMode ? 0.85 : 0.9),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 12),
                Text(
                  '⏳ تعویق روتین: ${widget.routine.title}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'زمان یادآوری مجدد این روتین را مشخص کنید:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 16),

                // Presets Grid Layout (2 columns)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    buildOptionCard(
                      label: '۵ دقیقه دیگر',
                      subtitle: 'زمان کوتاه و فوری',
                      icon: CupertinoIcons.timer,
                      color: colors.success,
                      minutes: 5,
                    ),
                    buildOptionCard(
                      label: '۱۵ دقیقه دیگر',
                      subtitle: 'تغییر وضعیت سریع',
                      icon: CupertinoIcons.clock,
                      color: colors.primary,
                      minutes: 15,
                    ),
                    buildOptionCard(
                      label: '۳۰ دقیقه دیگر',
                      subtitle: 'تعویق نیم ساعته',
                      icon: CupertinoIcons.alarm,
                      color: colors.warning,
                      minutes: 30,
                    ),
                    buildOptionCard(
                      label: '۱ ساعت دیگر',
                      subtitle: 'فاصله یک ساعته',
                      icon: CupertinoIcons.hourglass,
                      color: const Color(0xff8B5CF6),
                      minutes: 60,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                buildOptionCard(
                  label: 'فردا (۲۴ ساعت دیگر)',
                  subtitle: 'انتقال یادآوری به روز بعد',
                  icon: CupertinoIcons.sunrise,
                  color: colors.medicalRed,
                  minutes: 1440,
                  isFullWidth: true,
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Custom offset selection card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'زمان دلخواه:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              _toPersianDigits('$_customMinutes دقیقه'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(CupertinoIcons.minus, color: colors.textSecondary, size: 14),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: colors.primary,
                                inactiveTrackColor: colors.border.withValues(alpha: 0.3),
                                thumbColor: colors.primary,
                                overlayColor: colors.primary.withValues(alpha: 0.12),
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              ),
                              child: Slider(
                                value: _customMinutes.toDouble(),
                                min: 5,
                                max: 120,
                                divisions: 23, // 5 min increments from 5 to 120
                                label: _toPersianDigits('$_customMinutes دقیقه'),
                                onChanged: (val) {
                                  final intVal = val.toInt();
                                  if (intVal != _customMinutes) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _customMinutes = intVal;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          Icon(CupertinoIcons.plus, color: colors.textSecondary, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    widget.onSnoozeSelected(_customMinutes);
                  },
                  child: const Text(
                    'تایید زمان دلخواه',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'انصراف',
                    style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (var i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], persian[i]);
    }
    return input;
  }
}
