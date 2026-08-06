// lib/features/supplementary_sports/presentation/ss_movement_tab_screen.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/supplementary_sports/movement/data/movement_repository.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_budget.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_suggester.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/movement_analytics_screen.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/movement_log_sheet.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/widgets/weekly_budget_card.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

class SSMovementTabScreen extends StatefulWidget {
  const SSMovementTabScreen({super.key, this.onNavigateToTab});
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<SSMovementTabScreen> createState() => _SSMovementTabScreenState();
}

class _SSMovementTabScreenState extends State<SSMovementTabScreen> {
  bool _isLoading = true;
  MovementBudgetSnapshot? _budgetSnapshot;
  MovementSuggestion? _suggestion;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    final snapshot = await MovementBudgetService.instance.getCurrentWeekSnapshot();
    final suggestion = await MovementSuggester.suggestToday();

    if (mounted) {
      setState(() {
        _budgetSnapshot = snapshot;
        _suggestion = suggestion;
        _isLoading = false;
      });
    }
  }

  void _openLogSheet({String? kindCode}) {
    RitmoHaptics.tap();
    showMovementLogSheet(
      context,
      presetKind: kindCode != null ? MovementKind.fromMap({'code': kindCode, 'titleFa': kindCode, 'emoji': '⚡'}) : null,
      onLogged: () {
        RitmoHaptics.success();
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const theme = SupplementarySportsTheme.dark;

    return Scaffold(
      backgroundColor: theme.surfaceBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Text(
                          'فعالیت‌های حرکتی و روزمره',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 1. Weekly Budget Card
                        if (_budgetSnapshot != null)
                          WeeklyBudgetCard(
                            snapshot: _budgetSnapshot!,
                            onTap: () => _openLogSheet(),
                          ),
                        const SizedBox(height: 16),

                        // 2. Suggestion Card
                        if (_suggestion != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.emeraldPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(_suggestion!.kind.emoji, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 10),
                                    Text(
                                      'پیشنهاد امروز: ${_suggestion!.kind.titleFa}',
                                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: theme.textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _suggestion!.reasonFa,
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: theme.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.emeraldPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _openLogSheet(kindCode: _suggestion!.kind.code),
                                    child: const Text('ثبت این پیشنهاد ⚡', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3. Big Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.emeraldPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => _openLogSheet(),
                            icon: const Icon(CupertinoIcons.plus_circle_fill, color: Colors.white),
                            label: const Text(
                              'ثبت فعالیت جدید ⚡',
                              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. Activity Timeline
                        Text(
                          'تایم‌لاین فعالیت‌های این هفته',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: theme.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        (_budgetSnapshot?.events.isEmpty ?? true)
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: theme.surfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
                                child: Center(
                                  child: Text(
                                    'در این هفته هنوز فعالیتی ثبت نشده است.',
                                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: theme.textSecondary),
                                  ),
                                ),
                              )
                            : Column(
                            children: _budgetSnapshot!.events.map((e) {
                              final duration = e.durationMinutes.toPersianDigits();
                              final met = e.metMinutes.round().toPersianDigits();
                              return Dismissible(
                                key: Key(e.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) async {
                                  await MovementRepository.instance.deleteEvent(e.id);
                                  unawaited(_loadData());
                                },
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  color: Colors.red.withValues(alpha: 0.8),
                                  child: const Icon(CupertinoIcons.trash, color: Colors.white),
                                ),
                                child: Card(
                                  color: theme.surfaceVariant,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    title: Text(e.kindCode, style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: theme.textPrimary)),
                                    subtitle: Text('$duration دقیقه · $met MET-min', style: TextStyle(fontFamily: 'Vazirmatn', color: theme.textSecondary)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),

                        // 5. Button to Full Analytics
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MovementAnalyticsScreen()),
                            );
                          },
                          icon: Icon(CupertinoIcons.chart_bar_alt_fill, color: theme.emeraldPrimary),
                          label: Text(
                            'تحلیل کامل و رکوردهای شخصی',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: theme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
