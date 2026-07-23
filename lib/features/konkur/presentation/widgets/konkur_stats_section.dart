import 'package:flutter/material.dart';
import 'package:ritmo/core/analytics/konkur_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_formatters.dart';

class KonkurStatsSection extends StatelessWidget {

  const KonkurStatsSection({
    super.key,
    required this.subjects,
    required this.data,
  });
  final List<KonkurSubject> subjects;
  final KonkurEngineOutput data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Resolve weakest subjects to models
    final resolvedWeakest = <KonkurSubject>[];
    for (final subId in data.weakestSubjects) {
      final sub = subjects.firstWhere((s) => s.id == subId, orElse: () => KonkurSubject(id: '', name: '', createdAt: 0, updatedAt: 0));
      if (sub.id.isNotEmpty) {
        resolvedWeakest.add(sub);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI GRID
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildKpiCard(
                title: 'کل ساعت مطالعه',
                value: formatDuration(data.studyMinutesTotal),
                icon: Icons.timer,
                iconColor: Colors.blue,
                colors: colors,
              ),
              _buildKpiCard(
                title: 'پوشش بودجه کنکور',
                value: '${toPersianDigits((data.budgetCoverage * 100).toInt())}٪',
                icon: Icons.pie_chart,
                iconColor: Colors.purple,
                colors: colors,
              ),
              _buildKpiCard(
                title: 'استمرار زنجیره',
                value: data.studyStreakDays > 0 ? '${toPersianDigits(data.studyStreakDays)} روز 🔥' : 'صفر روز',
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                colors: colors,
              ),
              _buildKpiCard(
                title: 'آمادگی کلی دروس',
                value: '${toPersianDigits((data.overallReadiness * 100).toInt())}٪',
                icon: Icons.speed,
                iconColor: Colors.green,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // WEAKEST SUBJECTS HINTS (SUPPORTIVE)
          if (resolvedWeakest.isNotEmpty) ...[
            Text(
              'پیشنهاد تمرکز و تقویت دروس:',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...resolvedWeakest.take(2).map((sub) {
              final readiness = data.perSubjectReadiness[sub.id] ?? 0.0;
              final percent = (readiness * 100).toInt();
              return Card(
                elevation: 0,
                color: colors.card,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch, color: Color(0xFF8B5CF6), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'میزان آمادگی فعلی: ${toPersianDigits(percent)}٪. به نظر می‌رسد این درس نیاز به تمرکز بیشتری دارد. بیایید با مطالعه مباحث پایه یا حل چند تست سبک، تسلط خود را ارتقا دهیم! 💪',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                color: colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required RitmoColors colors,
  }) {
    return Card(
      elevation: 0,
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                Icon(icon, size: 20, color: iconColor),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
