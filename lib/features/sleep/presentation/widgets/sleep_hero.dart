import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:ritmo/features/sleep/presentation/widgets/sleep_log_sheet.dart';

class SleepHero extends StatefulWidget {

  const SleepHero({
    super.key,
    this.lastNight,
    required this.target,
    required this.onRefresh,
  });
  final SleepLog? lastNight;
  final SleepTarget target;
  final VoidCallback onRefresh;

  @override
  State<SleepHero> createState() => _SleepHeroState();
}

class _SleepHeroState extends State<SleepHero> {
  late Timer _timer;
  String _countdownText = '';
  bool _isWinddownActive = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;
    
    final now = DateTime.now();
    var bedtime = DateTime(now.year, now.month, now.day, widget.target.bedtimeHour, widget.target.bedtimeMinute);
    
    if (now.isAfter(bedtime)) {
      bedtime = bedtime.add(const Duration(days: 1));
    }

    final diff = bedtime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    // Standard wind-down trigger is 30 minutes before bedtime
    final totalDiffMin = diff.inMinutes;
    final isWinddown = totalDiffMin <= 30;

    setState(() {
      _isWinddownActive = isWinddown;
      if (isWinddown) {
        _countdownText = '🌙 وقتشه آروم آروم آماده‌ی خواب بشی (حدود ${totalDiffMin.abs()} د دیگه)';
      } else {
        _countdownText = '$hours ساعت و $minutes دقیقه تا زمان خواب هدف شما 😴';
      }
    });
  }

  void _showLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepLogSheet(
        target: widget.target,
        onSaved: widget.onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lastLog = widget.lastNight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: RitmoTheme.glassCardLight(
        border: Border.all(
          color: _isWinddownActive
              ? const Color(0xff8B5CF6).withValues(alpha: 0.5)
              : colors.glassBorder,
          width: _isWinddownActive ? 2.0 : 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title / Top Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'وضعیت خواب اخیر شما',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.cardSubtitle,
                    ),
                  ),
                  if (lastLog != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.cardFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(lastLog.quality.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            lastLog.quality.label,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              color: colors.cardTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Main content - Duration
              if (lastLog != null) ...[
                // Sleep registered
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${lastLog.durationMinutes ~/ 60}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: colors.cardTitle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ساعت',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: colors.cardSubtitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${lastLog.durationMinutes % 60}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: colors.cardTitle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'دقیقه',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: colors.cardSubtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTargetStatusChip(lastLog),
                  ],
                ),
              ] else ...[
                // Sleep not registered
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خواب دیشب ثبت نشده 🌙',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.cardTitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'برای سنجش بدهی خواب و تأثیر آن روی انرژی، وضعیت خواب خود را ثبت کنید.',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              Divider(color: colors.glassBorder),
              const SizedBox(height: 12),

              // Bedtime Countdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isWinddownActive
                      ? const Color(0xff8B5CF6).withValues(alpha: 0.1)
                      : colors.cardFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isWinddownActive
                        ? const Color(0xff8B5CF6).withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isWinddownActive ? CupertinoIcons.bell : CupertinoIcons.time,
                      color: _isWinddownActive ? const Color(0xff8B5CF6) : colors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _countdownText,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: _isWinddownActive ? FontWeight.bold : FontWeight.normal,
                          color: _isWinddownActive ? colors.cardTitle : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _showLogSheet,
                child: Text(
                  lastLog != null ? 'ثبت مجدد خواب دیشب' : 'ثبت خواب دیشب',
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
      ),
    );
  }

  Widget _buildTargetStatusChip(SleepLog log) {
    final colors = context.colors;
    final diff = log.durationMinutes - widget.target.durationMinutes;
    final isOk = diff >= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOk ? colors.success.withValues(alpha: 0.1) : colors.medicalRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOk ? colors.success.withValues(alpha: 0.2) : colors.medicalRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.exclamationmark_circle_fill,
            color: isOk ? colors.success : colors.medicalRed,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isOk ? 'به هدف خواب رسیدی' : '${diff.abs()} دقیقه کمتر از هدف',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOk ? colors.success : colors.medicalRed,
            ),
          ),
        ],
      ),
    );
  }
}
