import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/reflection/models/reflection_models.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:ritmo/features/today/presentation/widgets/morning_checkin_sheet.dart';

class ReflectionHero extends StatelessWidget {

  const ReflectionHero({
    super.key,
    required this.stats,
    required this.todayCheckinDone,
    required this.todayReflectionDone,
    required this.onRefresh,
  });
  final ReflectionStats stats;
  final bool todayCheckinDone;
  final bool todayReflectionDone;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final isMorning = now.hour < 12;

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Streak Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '🌱',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'زنجیره خودارزیابی',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '${stats.currentStreak} روز پیاپی',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'بیشترین: ${stats.longestStreak} روز',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // Today's Status
            Text(
              'وضعیت امروز شما',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    title: 'ارزیابی صبحگاهی',
                    isDone: todayCheckinDone,
                    icon: CupertinoIcons.sun_max_fill,
                    iconColor: Colors.orangeAccent,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    title: 'تأمل عصرگاهی',
                    isDone: todayReflectionDone,
                    icon: CupertinoIcons.moon_stars_fill,
                    iconColor: Colors.amber,
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            if (!todayCheckinDone && isMorning) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => MorningCheckinSheet(
                      onSaved: onRefresh,
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.sun_max_fill, size: 16),
                label: const Text(
                  'ثبت ارزیابی صبحگاهی امروز',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => DailyReflectionSheet(
                    onSaved: onRefresh,
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.pen, size: 16),
              label: Text(
                todayReflectionDone ? 'ویرایش تأمل امروز' : 'ثبت تأمل و بازتاب امروز',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required bool isDone,
    required IconData icon,
    required Color iconColor,
    required RitmoColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? colors.success.withValues(alpha: 0.1) : colors.card.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? colors.success.withValues(alpha: 0.4) : colors.border.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isDone ? CupertinoIcons.checkmark_alt_circle_fill : icon,
            color: isDone ? colors.success : iconColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isDone ? 'انجام شده' : 'در انتظار ثبت',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              color: isDone ? colors.success : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
