import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/reflection/models/reflection_models.dart';
import 'package:ritmo/features/today/presentation/widgets/daily_reflection_sheet.dart';
import 'package:shamsi_date/shamsi_date.dart';

class JournalTimelineSection extends StatelessWidget {

  const JournalTimelineSection({
    super.key,
    required this.days,
    required this.onRefresh,
  });
  final List<JournalDay> days;
  final VoidCallback onRefresh;

  String _getJalaliMonthName(int month) {
    const months = [
      'فروردین', 'اردیبهشت', 'خرداد',
      'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر',
      'دی', 'بهمن', 'اسفند'
    ];
    return months[month - 1];
  }

  String _getDayOfWeekName(int weekday) {
    const days = [
      'دوشنبه', 'سه‌شنبه', 'چهارشنبه',
      'پنج‌شنبه', 'جمعه', 'شنبه', 'یک‌شنبه'
    ];
    return days[weekday - 1];
  }

  String _formatJalaliDate(String dateIso) {
    final dt = DateTime.tryParse(dateIso);
    if (dt == null) return dateIso;
    final jalali = Jalali.fromDateTime(dt);
    return '${_getDayOfWeekName(dt.weekday)}، ${jalali.day} ${_getJalaliMonthName(jalali.month)} ${jalali.year}';
  }

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'TIRED':
        return 'خسته و بی‌انرژی';
      case 'NORMAL':
        return 'عادی و آرام';
      case 'GOOD':
        return 'پرانرژی و خوب';
      case 'GREAT':
        return 'بسیار عالی و فوق‌العاده';
      default:
        return mood;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'TIRED':
        return '😫';
      case 'NORMAL':
        return '😐';
      case 'GOOD':
        return '🙂';
      case 'GREAT':
        return '🤩';
      default:
        return '😐';
    }
  }

  String _getMoodScoreEmoji(int score) {
    switch (score) {
      case 1:
        return '😫';
      case 2:
        return '🙁';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '🤩';
      default:
        return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '📚',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'هنوز هیچ یادداشتی ثبت نشده است.',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ثبت روزانه خودارزیابی به شما کمک می‌کند الگوهای ذهنی خود را بهتر بشناسید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final hasCheckin = day.checkin != null;
        final hasReflection = day.reflection != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => DailyReflectionSheet(
                  date: day.dateIso,
                  onSaved: onRefresh,
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: RitmoTheme.glassCardLight(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatJalaliDate(day.dateIso),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_left,
                          size: 14,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.5),

                    // Morning Checkin
                    if (hasCheckin) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.sun_max_fill,
                              size: 14,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'ارزیابی صبحگاهی: ',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${_getMoodEmoji(day.checkin!.mood)} ${_getMoodLabel(day.checkin!.mood)}',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (day.checkin!.note != null && day.checkin!.note!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    day.checkin!.note!,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hasReflection) const SizedBox(height: 12),
                    ],

                    // Evening Reflection
                    if (hasReflection) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.moon_stars_fill,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'بازتاب عصرگاهی: ',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'حالت روحی ${_getMoodScoreEmoji(day.reflection!.moodScore)}',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Structured elements
                                if (day.reflection!.wins != null && day.reflection!.wins!.isNotEmpty)
                                  _buildStructuredRow('🏆 دستاورد:', day.reflection!.wins!, colors),
                                if (day.reflection!.gratitude != null && day.reflection!.gratitude!.isNotEmpty)
                                  _buildStructuredRow('💖 شکرگزاری:', day.reflection!.gratitude!, colors),
                                if (day.reflection!.challenges != null && day.reflection!.challenges!.isNotEmpty)
                                  _buildStructuredRow('⚡ چالش:', day.reflection!.challenges!, colors),
                                if (day.reflection!.learnings != null && day.reflection!.learnings!.isNotEmpty)
                                  _buildStructuredRow('📚 یادگیری:', day.reflection!.learnings!, colors),
                                if (day.reflection!.tomorrowFocus != null && day.reflection!.tomorrowFocus!.isNotEmpty)
                                  _buildStructuredRow('🎯 تمرکز فردا:', day.reflection!.tomorrowFocus!, colors),
                                if (day.reflection!.reflectionText != null && day.reflection!.reflectionText!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    day.reflection!.reflectionText!,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else if (!hasReflection) ...[
                      // Reflection is missing, show a call-to-action
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle,
                              size: 14,
                              color: colors.warning.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تأمل عصرگاهی ثبت نشده است. برای ثبت ضربه بزنید.',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStructuredRow(String prefix, String text, RitmoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            color: colors.textSecondary,
          ),
          children: [
            TextSpan(
              text: '$prefix ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
