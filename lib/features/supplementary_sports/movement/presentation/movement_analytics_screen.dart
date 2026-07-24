// lib/features/sports/movement/presentation/movement_analytics_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';

class MovementAnalyticsScreen extends StatefulWidget {
  const MovementAnalyticsScreen({super.key});

  @override
  State<MovementAnalyticsScreen> createState() => _MovementAnalyticsScreenState();
}

class _MovementAnalyticsScreenState extends State<MovementAnalyticsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _prs = [];
  Map<MovementFamily, int> _familyCounts = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final prRows = await db.query('movement_pr', orderBy: 'achievedAt DESC');
      final logRows = await db.query('workout_logs', columns: ['kind', 'type']);

      final familyCounts = <MovementFamily, int>{};
      for (final r in logRows) {
        final kCode = (r['kind'] ?? r['type'] ?? '').toString();
        final kRows = await db.query('movement_kinds', where: 'code = ?', whereArgs: [kCode], limit: 1);
        if (kRows.isNotEmpty) {
          final f = MovementFamily.fromCode(kRows.first['family']?.toString() ?? 'ENDURANCE');
          familyCounts[f] = (familyCounts[f] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _prs = prRows;
          _familyCounts = familyCounts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('تحلیل حرکت و رکوردهای شخصی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Diversity Map
                    Text(
                      '🎨 نقشهٔ تنوع خانواده‌های حرکت',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16, color: colors.onBackground),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: MovementFamily.values.map((f) {
                        final count = _familyCounts[f] ?? 0;
                        final isUsed = count > 0;
                        return Container(
                          width: (MediaQuery.of(context).size.width - 44) / 2,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUsed ? colors.surfaceVariant : colors.surfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUsed ? colors.primary.withValues(alpha: 0.5) : colors.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(f.emoji, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      f.titleFa,
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontWeight: FontWeight.bold,
                                        color: isUsed ? colors.onSurface : colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isUsed ? '${count.toPersianDigits()} فعالیت ثبت‌شده' : 'این خانواده رو هنوز امتحان نکردی 💡',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: isUsed ? colors.primary : colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Personal Records (PR)
                    Text(
                      '🏆 رکوردهای شخصی من (PR)',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16, color: colors.onBackground),
                    ),
                    const SizedBox(height: 12),
                    _prs.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'هنوز رکوردی ثبت نشده. با ثبت فعالیت‌های بیشتر رکوردهای جدیدت اینجا قرار می‌گیرند ✨',
                                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            children: _prs.map((pr) {
                              final kindCode = pr['kind']?.toString() ?? '';
                              final prType = pr['prType']?.toString() ?? '';
                              final val = (pr['value'] as num? ?? 0).toDouble();

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFF59E0B),
                                    child: Text('🏆', style: TextStyle(fontSize: 18)),
                                  ),
                                  title: Text(
                                    '$kindCode — $prType',
                                    style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'مقدار رکورد: ${val.toStringAsFixed(1).toPersianDigits()}',
                                    style: TextStyle(fontFamily: 'Vazirmatn', color: colors.primary),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
