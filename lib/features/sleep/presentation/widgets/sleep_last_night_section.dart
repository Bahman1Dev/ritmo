import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:sqflite/sqflite.dart';

class SleepLastNightSection extends StatefulWidget {

  const SleepLastNightSection({
    super.key,
    this.lastNight,
    required this.target,
    required this.isWinddownEnabled,
    required this.onRefresh,
  });
  final SleepLog? lastNight;
  final SleepTarget target;
  final bool isWinddownEnabled;
  final VoidCallback onRefresh;

  @override
  State<SleepLastNightSection> createState() => _SleepLastNightSectionState();
}

class _SleepLastNightSectionState extends State<SleepLastNightSection> {
  bool _winddownEnabled = false;

  @override
  void initState() {
    super.initState();
    _winddownEnabled = widget.isWinddownEnabled;
  }

  @override
  void didUpdateWidget(covariant SleepLastNightSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWinddownEnabled != widget.isWinddownEnabled) {
      _winddownEnabled = widget.isWinddownEnabled;
    }
  }

  Future<void> _toggleWinddown(bool val) async {
    setState(() {
      _winddownEnabled = val;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'app_settings',
        {
          'key': 'sleep_winddown_reminder',
          'value': val.toString(),
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await HapticFeedback.selectionClick();
      widget.onRefresh();
    } catch (e) {
      debugPrint('Error saving winddown setting: $e');
    }
  }

  String _formatEpochTime(int? epochMs) {
    if (epochMs == null) return '--:--';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getBedtimeDeviationText(SleepLog log, SleepTarget target) {
    if (log.bedtimeAt == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(log.bedtimeAt!);
    final targetMin = target.bedtimeHour * 60 + target.bedtimeMinute;
    final actualMin = dt.hour * 60 + dt.minute;
    
    var diff = actualMin - targetMin;
    if (diff > 720) diff -= 1440;
    if (diff < -720) diff += 1440;
    
    if (diff.abs() <= 5) return 'دقیقاً سر وقت';
    if (diff > 0) return '${diff.abs()} دقیقه دیرتر از هدف';
    return '${diff.abs()} دقیقه زودتر از هدف';
  }

  String _getWakeDeviationText(SleepLog log, SleepTarget target) {
    if (log.wakeAt == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(log.wakeAt!);
    final targetMin = target.wakeHour * 60 + target.wakeMinute;
    final actualMin = dt.hour * 60 + dt.minute;
    
    var diff = actualMin - targetMin;
    if (diff > 720) diff -= 1440;
    if (diff < -720) diff += 1440;
    
    if (diff.abs() <= 5) return 'دقیقاً سر وقت';
    if (diff > 0) return '${diff.abs()} دقیقه دیرتر از هدف';
    return '${diff.abs()} دقیقه زودتر از هدف';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final log = widget.lastNight;

    if (log == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.moon_stars, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'هیچ داده‌ای برای دیشب ثبت نشده است.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sleep Details Card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جزئیات خواب دیشب',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    label: 'زمان خواب رفتن واقعی',
                    value: _formatEpochTime(log.bedtimeAt),
                    icon: CupertinoIcons.moon,
                  ),
                  _buildDetailRow(
                    label: 'زمان بیدار شدن واقعی',
                    value: _formatEpochTime(log.wakeAt),
                    icon: CupertinoIcons.sunrise,
                  ),
                  _buildDetailRow(
                    label: 'مدت کل خواب',
                    value: '${log.durationMinutes ~/ 60} ساعت و ${log.durationMinutes % 60} دقیقه',
                    icon: CupertinoIcons.time,
                  ),
                  _buildDetailRow(
                    label: 'کیفیت ثبت‌شده',
                    value: '${log.quality.emoji} ${log.quality.label}',
                    icon: CupertinoIcons.heart,
                  ),
                  _buildDetailRow(
                    label: 'دفعات بیدار شدن',
                    value: '${log.awakenings} بار',
                    icon: CupertinoIcons.bell,
                  ),
                  if (log.note != null && log.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Text(
                      'یادداشت شما:',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.note!,
                      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Program vs Reality Card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'برنامه در برابر واقعیت',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bedtime comparison
                  _buildComparisonRow(
                    title: 'خوابیدن:',
                    target: widget.target.bedtime,
                    actual: _formatEpochTime(log.bedtimeAt),
                    deviation: _getBedtimeDeviationText(log, widget.target),
                    colors: colors,
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Wake comparison
                  _buildComparisonRow(
                    title: 'بیدار شدن:',
                    target: widget.target.wake,
                    actual: _formatEpochTime(log.wakeAt),
                    deviation: _getWakeDeviationText(log, widget.target),
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Tonight settings card
          RitmoTheme.glassCardLight(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'برنامه خواب امشب شما',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'زمان خواب هدف امشب:',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                      ),
                      Text(
                        widget.target.bedtime,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'یادآور پیش‌خواب (Wind-down)',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white),
                    ),
                    subtitle: Text(
                      'ارسال اعلان ملایم برای آماده‌شدن جهت خواب',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary),
                    ),
                    value: _winddownEnabled,
                    activeThumbColor: const Color(0xff8B5CF6),
                    onChanged: _toggleWinddown,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff8B5CF6).withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white70),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required String title,
    required String target,
    required String actual,
    required String deviation,
    required RitmoColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: colors.cardSubtitle),
            ),
            const SizedBox(width: 8),
            Text(
              deviation,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xff8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'برنامه (هدف):',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary),
                ),
                Text(
                  target,
                  style: TextStyle(fontSize: 13, color: colors.cardTitle),
                ),
              ],
            ),
            Icon(CupertinoIcons.arrow_right_arrow_left, color: colors.glassBorder, size: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'واقعی:',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary),
                ),
                Text(
                  actual,
                  style: TextStyle(fontSize: 13, color: colors.cardTitle),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
