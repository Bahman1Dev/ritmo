import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_action_handler.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_consent_bridge.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_agenda_card.dart';

class ObligatoryPrayersSection extends StatefulWidget {

  const ObligatoryPrayersSection({
    super.key,
    required this.onChanged,
    this.prayerTime,
  });
  final VoidCallback onChanged;
  final PrayerTime? prayerTime;

  @override
  State<ObligatoryPrayersSection> createState() => _ObligatoryPrayersSectionState();
}

class _ObligatoryPrayersSectionState extends State<ObligatoryPrayersSection> {
  bool _isMenstruating = false;
  bool _isLoading = true;
  List<WorshipPractice> _practices = [];
  String _todayStr = '';

  @override
  void initState() {
    super.initState();
    _todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _loadPracticesAndStatus();
  }

  @override
  void didUpdateWidget(ObligatoryPrayersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadPracticesAndStatus();
  }

  Future<void> _loadPracticesAndStatus() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Check menstruation and consent
      final menstruating = await CycleConsentBridge.isWorshipSuspended();

      // Find ws_ramadan season and check if active
      var isRamadan = false;
      final seasons = await db.query(
        'worship_seasons',
        where: "id = 'ws_ramadan'",
        limit: 1,
      );
      if (seasons.isNotEmpty) {
        final rStartStr = seasons.first['startDate']! as String;
        final rEndStr = seasons.first['endDate']! as String;
        final isActive = (seasons.first['isActive'] as int? ?? 1) == 1;
        if (isActive) {
          try {
            final todayStr = DateTime.now().toIso8601String().substring(0, 10);
            if (todayStr.compareTo(rStartStr) >= 0 && todayStr.compareTo(rEndStr) <= 0) {
              isRamadan = true;
            }
          } catch (_) {}
        }
      }

      // Upsert wp_fasting_ramadan if needed
      final ramadanPQuery = await db.query(
        'worship_practices',
        where: "id = 'wp_fasting_ramadan'",
        limit: 1,
      );
      if (isRamadan) {
        if (ramadanPQuery.isEmpty) {
          await db.insert('worship_practices', {
            'id': 'wp_fasting_ramadan',
            'practiceType': 'FASTING',
            'subType': 'RAMADAN_FAST',
            'title': 'روزه ماه مبارک رمضان',
            'dailyTarget': 1,
            'dailyDone': 0,
            'isActive': 1,
            'dailyDoneDate': _todayStr,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          });
        } else {
          final p = WorshipPractice.fromMap(ramadanPQuery.first);
          if (!p.isActive) {
            await db.update(
              'worship_practices',
              {'isActive': 1, 'updatedAt': nowMs},
              where: "id = 'wp_fasting_ramadan'",
            );
          }
        }
      } else {
        if (ramadanPQuery.isNotEmpty) {
          final p = WorshipPractice.fromMap(ramadanPQuery.first);
          if (p.isActive) {
            await db.update(
              'worship_practices',
              {'isActive': 0, 'updatedAt': nowMs},
              where: "id = 'wp_fasting_ramadan'",
            );
          }
        }
      }

      // 2. Ensure default obligatory prayers exist and are active
      final defaultPrayers = [
        {'id': 'wp_fajr', 'subType': 'FAJR', 'title': 'نماز صبح', 'sortOrder': 1},
        {'id': 'wp_dhuhr', 'subType': 'DHUHR', 'title': 'نماز ظهر و عصر', 'sortOrder': 2},
        {'id': 'wp_maghrib', 'subType': 'MAGHRIB', 'title': 'نماز مغرب و عشا', 'sortOrder': 4},
      ];

      for (final dp in defaultPrayers) {
        final existing = await db.query(
          'worship_practices',
          where: 'id = ?',
          whereArgs: [dp['id']],
          limit: 1,
        );
        if (existing.isEmpty) {
          await db.insert('worship_practices', {
            'id': dp['id'],
            'practiceType': 'PRAYER',
            'subType': dp['subType'],
            'title': dp['title'],
            'dailyTarget': 1,
            'dailyDone': 0,
            'isActive': 1,
            'dailyDoneDate': _todayStr,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          });
        } else {
          final p = WorshipPractice.fromMap(existing.first);
          if (!p.isActive) {
            await db.update(
              'worship_practices',
              {'isActive': 1, 'updatedAt': nowMs},
              where: 'id = ?',
              whereArgs: [dp['id']],
            );
          }
        }
      }

      // Fetch prayer and fasting practices
      final results = await db.query(
        'worship_practices',
        where: "(practiceType = 'PRAYER' OR practiceType = 'FASTING') AND isActive = 1",
        orderBy: 'sortOrder ASC',
      );

      final list = results.map(WorshipPractice.fromMap).toList();

      // Daily reset is handled central in EndOfDaySweep

      if (mounted) {
        setState(() {
          _isMenstruating = menstruating;
          _practices = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading obligatory prayers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  WorshipPractice? _getPracticeBySubType(String subType) {
    try {
      return _practices.firstWhere((p) => p.subType == subType);
    } catch (_) {
      return null;
    }
  }

  DateTime _parseTime(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  Future<Map<String, dynamic>> _captureSnapshot(List<String> practiceIds, {String? debtType, String? debtTitle}) async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Fetch practice states
    final practices = <Map<String, dynamic>>[];
    for (final id in practiceIds) {
      final rows = await db.query('worship_practices', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        practices.add(rows.first);
      }
    }
    
    // 2. Fetch debt states
    final debts = <Map<String, dynamic>>[];
    if (debtType != null && debtTitle != null) {
      final rows = await db.query(
        'worship_debts',
        where: 'debtType = ? AND title = ? AND isArchived = 0',
        whereArgs: [debtType, debtTitle],
      );
      if (rows.isNotEmpty) {
        debts.add(rows.first);
      }
    }
    
    return {
      'practices': practices,
      'debts': debts,
      'hadDebtBefore': debts.isNotEmpty,
    };
  }

  Future<void> _restoreSnapshot(Map<String, dynamic> snapshot, List<String> practiceIds, {String? debtType, String? debtTitle}) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Restore practices
      final practices = List<Map<String, dynamic>>.from(snapshot['practices']);
      for (final p in practices) {
        await txn.update(
          'worship_practices',
          {
            'dailyDone': p['dailyDone'],
            'dailyDoneDate': p['dailyDoneDate'],
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [p['id']],
        );
      }
      
      // 2. Restore debts
      final bool hadDebtBefore = snapshot['hadDebtBefore'];
      final debts = List<Map<String, dynamic>>.from(snapshot['debts']);
      if (hadDebtBefore && debts.isNotEmpty) {
        // Restore previous counts
        final oldDebt = debts.first;
        await txn.update(
          'worship_debts',
          {
            'totalCount': oldDebt['totalCount'],
            'remainingCount': oldDebt['remainingCount'],
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [oldDebt['id']],
        );
      } else if (!hadDebtBefore && debtType != null && debtTitle != null) {
        // A new debt was inserted, so we should delete it!
        await txn.delete(
          'worship_debts',
          where: 'debtType = ? AND title = ? AND isArchived = 0',
          whereArgs: [debtType, debtTitle],
        );
      }
    });
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    AgendaActionHandler.instance.notifyWorshipUpdated(todayStr);
    await _loadPracticesAndStatus();
    widget.onChanged();
  }

  void _showUndoSnackBar({
    required String message,
    required Map<String, dynamic> snapshot,
    required List<String> practiceIds,
    String? debtType,
    String? debtTitle,
  }) {
    RitmoToast.show(
      context,
      message,
      onUndo: () async {
        await _restoreSnapshot(snapshot, practiceIds, debtType: debtType, debtTitle: debtTitle);
        if (mounted) {
          RitmoToast.show(
            context,
            'عملیات با موفقیت بازگردانی شد.',
          );
        }
      },
    );
  }

  Future<void> _toggleGroupDone(String group, bool isDone) async {
    unawaited(HapticFeedback.mediumImpact());
    
    final practiceIds = <String>[];
    if (group == 'FAJR') {
      practiceIds.add('wp_fajr');
    } else if (group == 'DHUHR_ASR') {
      practiceIds.add('wp_dhuhr');
      final asr = _getPracticeBySubType('ASR');
      if (asr != null) practiceIds.add(asr.id);
    } else if (group == 'MAGHRIB_ISHA') {
      practiceIds.add('wp_maghrib');
      final isha = _getPracticeBySubType('ISHA');
      if (isha != null) practiceIds.add(isha.id);
    } else if (group == 'RAMADAN_FAST') {
      practiceIds.add('wp_fasting_ramadan');
    }

    final snapshot = await _captureSnapshot(practiceIds);

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await AgendaActionHandler.instance.togglePrayer(
      group: group,
      isDone: isDone,
      dateStr: todayStr,
    );
    await _loadPracticesAndStatus();
    widget.onChanged();

    _showUndoSnackBar(
      message: isDone ? 'نماز با موفقیت ثبت شد.' : 'ثبت نماز لغو شد.',
      snapshot: snapshot,
      practiceIds: practiceIds,
    );
  }

  Future<void> _skipGroupWithQadaDirect(
      String groupTitle, List<WorshipPractice> groupPractices, bool addToQada) async {
    unawaited(HapticFeedback.mediumImpact());
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final practicesList = groupPractices.map((p) => {
      'id': p.id,
      'subType': p.subType,
      'title': p.title,
      'practiceType': p.practiceType,
    }).toList();

    final practiceIds = groupPractices.map((p) => p.id).toList();
    String? debtType;
    String? debtTitle;
    if (addToQada && groupPractices.isNotEmpty) {
      final p = groupPractices.first;
      debtType = p.practiceType == 'FASTING' ? 'FAST' : 'PRAYER';
      debtTitle = p.practiceType == 'FASTING' ? 'روزه قضا' : p.title;
    }
    final snapshot = await _captureSnapshot(practiceIds, debtType: debtType, debtTitle: debtTitle);

    await AgendaActionHandler.instance.skipPrayer(
      practices: practicesList,
      addToQada: addToQada,
      dateStr: todayStr,
    );

    await _loadPracticesAndStatus();
    widget.onChanged();

    _showUndoSnackBar(
      message: addToQada ? 'نماز به عنوان قضا ثبت شد.' : 'نماز رد شد.',
      snapshot: snapshot,
      practiceIds: practiceIds,
      debtType: debtType,
      debtTitle: debtTitle,
    );
  }

  Widget _buildPassedUnactedRow({
    required String title,
    required String timeStr,
    required List<WorshipPractice> practices,
    required String group,
    required RitmoColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.medicalRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.medicalRed.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 13, color: colors.medicalRed),
                    const SizedBox(width: 4),
                    Text(
                      'وقت این نماز گذشته است',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.medicalRed,
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xffD4A843),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _toggleGroupDone(group, true),
                child: const Text(
                  'خواندم',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colors.medicalRed,
                  backgroundColor: colors.medicalRed.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _skipGroupWithQadaDirect(title, practices, true),
                child: const Text(
                  'افزودن به قضا',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllRemindersSettings({
    required List<WorshipPractice> fajrGroup,
    required List<WorshipPractice> dhuhrAsrGroup,
    required List<WorshipPractice> maghribIshaGroup,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _AllPrayersReminderSettingsSheet(
          fajrPractices: fajrGroup,
          dhuhrAsrPractices: dhuhrAsrGroup,
          maghribIshaPractices: maghribIshaGroup,
          onSaved: () {
            _loadPracticesAndStatus();
            widget.onChanged();
          },
        );
      },
    );
  }

  void _showSnoozeDialog(String groupTitle, List<WorshipPractice> groupPractices) {
    showDialog(
      context: context,
      builder: (context) {
        return _SnoozeSelectionDialog(
          groupTitle: groupTitle,
          practices: groupPractices,
          prayerTime: widget.prayerTime,
          onSnoozed: () {
            _loadPracticesAndStatus();
            widget.onChanged();
          },
        );
      },
    );
  }

  Future<void> _skipGroupAndPromptQada(String groupTitle, List<WorshipPractice> groupPractices) async {
    final colors = context.colors;
    HapticFeedback.vibrate();
    
    // Show confirmation dialog to add to Qada debts
    final addToQada = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              groupTitle == 'روزه ماه رمضان' ? 'ثبت روزه قضای ماه رمضان' : 'ثبت نماز قضای $groupTitle',
              style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            content: Text(
              groupTitle == 'روزه ماه رمضان'
                  ? 'آیا مایلید روزه امروز را به بدهی‌های عبادی (روزه قضا) اضافه کنید؟'
                  : 'آیا مایلید نماز امروز ($groupTitle) را به بدهی‌های عبادی (نماز قضا) اضافه کنید؟',
              style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 14.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('خیر', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('بله، اضافه کن', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );

    if (addToQada == null) return;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final practicesList = groupPractices.map((p) => {
      'id': p.id,
      'subType': p.subType,
      'title': p.title,
      'practiceType': p.practiceType,
    }).toList();

    final practiceIds = groupPractices.map((p) => p.id).toList();
    String? debtType;
    String? debtTitle;
    if (addToQada == true && groupPractices.isNotEmpty) {
      final p = groupPractices.first;
      debtType = p.practiceType == 'FASTING' ? 'FAST' : 'PRAYER';
      debtTitle = p.practiceType == 'FASTING' ? 'روزه قضا' : p.title;
    }
    final snapshot = await _captureSnapshot(practiceIds, debtType: debtType, debtTitle: debtTitle);

    await AgendaActionHandler.instance.skipPrayer(
      practices: practicesList,
      addToQada: addToQada == true,
      dateStr: todayStr,
    );

    await _loadPracticesAndStatus();
    widget.onChanged();

    _showUndoSnackBar(
      message: addToQada == true ? 'نماز به عنوان قضا ثبت شد.' : 'نماز رد شد.',
      snapshot: snapshot,
      practiceIds: practiceIds,
      debtType: debtType,
      debtTitle: debtTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: colors.textPrimary)),
      );
    }

    // Grouping elements
    final fajrP = _getPracticeBySubType('FAJR');
    final dhuhrP = _getPracticeBySubType('DHUHR');
    final asrP = _getPracticeBySubType('ASR');
    final maghribP = _getPracticeBySubType('MAGHRIB');
    final ishaP = _getPracticeBySubType('ISHA');
    final ramadanFastP = _getPracticeBySubType('RAMADAN_FAST');

    final fajrGroup = <WorshipPractice>[?fajrP];
    final dhuhrAsrGroup = <WorshipPractice>[?dhuhrP];
    final maghribIshaGroup = <WorshipPractice>[?maghribP];

    // Status Count
    final pTime = widget.prayerTime;
    
    var isFajrPassed = false;
    var isDhuhrAsrPassed = false;
    var isMaghribIshaPassed = false;
    
    if (pTime != null) {
      final now = DateTime.now();
      
      final sunriseDt = _parseTime(pTime.sunrise, now);
      final sunsetDt = _parseTime(pTime.sunset, now);
      var midnightDt = _parseTime(pTime.midnightShari, now);
      if (midnightDt.hour < 4 && now.hour >= 4) {
        midnightDt = midnightDt.add(const Duration(days: 1));
      }
      
      isFajrPassed = now.isAfter(sunriseDt);
      isDhuhrAsrPassed = now.isAfter(sunsetDt);
      isMaghribIshaPassed = now.isAfter(midnightDt);
    }

    final visibleRows = <Widget>[];
    var doneCount = 0;
    var totalCount = 0;

    // Fajr Row
    if (fajrP != null) {
      totalCount++;
      final isDone = fajrP.dailyDone >= 1;
      final isSkipped = fajrP.dailyDone == -1;
      if (isDone) doneCount++;

      final timeStr = widget.prayerTime != null ? toPersianDigits(widget.prayerTime!.fajr) : '--:--';
      if (isDone || isSkipped) {
        visibleRows.add(_buildGroupRow(
          title: 'نماز صبح',
          timeStr: timeStr,
          practices: fajrGroup,
          isDone: isDone,
          onToggle: (val) => _toggleGroupDone('FAJR', val),
          colors: colors,
        ));
      } else if (isFajrPassed) {
        visibleRows.add(_buildPassedUnactedRow(
          title: 'نماز صبح',
          timeStr: timeStr,
          practices: fajrGroup,
          group: 'FAJR',
          colors: colors,
        ));
      } else {
        visibleRows.add(_buildGroupRow(
          title: 'نماز صبح',
          timeStr: timeStr,
          practices: fajrGroup,
          isDone: false,
          onToggle: (val) => _toggleGroupDone('FAJR', val),
          colors: colors,
        ));
      }
    }

    // Dhuhr / Asr Row
    if (dhuhrP != null) {
      totalCount++;
      final isDone = dhuhrP.dailyDone >= 1 && (asrP == null || asrP.dailyDone >= 1);
      final isSkipped = dhuhrP.dailyDone == -1 || (asrP != null && asrP.dailyDone == -1);
      if (isDone) doneCount++;

      final timeStr = widget.prayerTime != null
          ? toPersianDigits(
              asrP != null 
                ? '${widget.prayerTime!.dhuhr} / ${widget.prayerTime!.asr}'
                : widget.prayerTime!.dhuhr
            )
          : '--:--';

      if (isDone || isSkipped) {
        visibleRows.add(_buildGroupRow(
          title: 'نماز ظهر و عصر',
          timeStr: timeStr,
          practices: dhuhrAsrGroup,
          isDone: isDone,
          onToggle: (val) => _toggleGroupDone('DHUHR_ASR', val),
          colors: colors,
        ));
      } else if (isDhuhrAsrPassed) {
        visibleRows.add(_buildPassedUnactedRow(
          title: 'نماز ظهر و عصر',
          timeStr: timeStr,
          practices: dhuhrAsrGroup,
          group: 'DHUHR_ASR',
          colors: colors,
        ));
      } else {
        visibleRows.add(_buildGroupRow(
          title: 'نماز ظهر و عصر',
          timeStr: timeStr,
          practices: dhuhrAsrGroup,
          isDone: false,
          onToggle: (val) => _toggleGroupDone('DHUHR_ASR', val),
          colors: colors,
        ));
      }
    }

    // Maghrib / Isha Row
    if (maghribP != null) {
      totalCount++;
      final isDone = maghribP.dailyDone >= 1 && (ishaP == null || ishaP.dailyDone >= 1);
      final isSkipped = maghribP.dailyDone == -1 || (ishaP != null && ishaP.dailyDone == -1);
      if (isDone) doneCount++;

      final timeStr = widget.prayerTime != null
          ? toPersianDigits(
              ishaP != null 
                ? '${widget.prayerTime!.maghrib} / ${widget.prayerTime!.isha}'
                : widget.prayerTime!.maghrib
            )
          : '--:--';

      if (isDone || isSkipped) {
        visibleRows.add(_buildGroupRow(
          title: 'نماز مغرب و عشا',
          timeStr: timeStr,
          practices: maghribIshaGroup,
          isDone: isDone,
          onToggle: (val) => _toggleGroupDone('MAGHRIB_ISHA', val),
          colors: colors,
        ));
      } else if (isMaghribIshaPassed) {
        visibleRows.add(_buildPassedUnactedRow(
          title: 'نماز مغرب و عشا',
          timeStr: timeStr,
          practices: maghribIshaGroup,
          group: 'MAGHRIB_ISHA',
          colors: colors,
        ));
      } else {
        visibleRows.add(_buildGroupRow(
          title: 'نماز مغرب و عشا',
          timeStr: timeStr,
          practices: maghribIshaGroup,
          isDone: false,
          onToggle: (val) => _toggleGroupDone('MAGHRIB_ISHA', val),
          colors: colors,
        ));
      }
    }

    // Fasting Row
    if (ramadanFastP != null) {
      final isDone = ramadanFastP.dailyDone >= 1;

      visibleRows.add(_buildGroupRow(
        title: 'روزه ماه رمضان',
        timeStr: 'امروز',
        practices: [ramadanFastP],
        isDone: isDone,
        onToggle: (val) => _toggleGroupDone('RAMADAN_FAST', val),
        colors: colors,
      ));
    }

    final allDone = totalCount > 0 && doneCount == totalCount;

    // Status Count
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نمازهای واجب',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.bell_fill, color: Color(0xffD4A843), size: 20),
                onPressed: () => _showAllRemindersSettings(
                  fajrGroup: fajrGroup,
                  dhuhrAsrGroup: dhuhrAsrGroup,
                  maghribIshaGroup: maghribIshaGroup,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0b0b0e) : Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.68),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Column(
              children: [
                ...List.generate(visibleRows.length, (index) {
                  return Column(
                    children: [
                      visibleRows[index],
                      if (index < visibleRows.length - 1)
                        Divider(color: colors.border, height: 16),
                    ],
                  );
                }),

                if (allDone) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffD4A843).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffD4A843).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xffD4A843), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'تمامی نمازهای واجب امروز انجام شده‌اند 🌟',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Menstruation Banner
                if (_isMenstruating) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xff8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xff8B5CF6).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.heart_fill, color: Color(0xffA78BFA), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'امروز نماز به دلیل عادت ماهانه واجب نیست 💜',
                          style: TextStyle(
                            color: Color(0xffC084FC),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupRow({
    required String title,
    required String timeStr,
    required List<WorshipPractice> practices,
    required bool isDone,
    required ValueChanged<bool> onToggle,
    required RitmoColors colors,
  }) {
    final hasReminder = practices.any((p) => p.reminderEnabled);
    final maxDeferCount = practices.map((p) => p.deferCount).fold(0, max);
    final isSnoozed = practices.any((p) => p.lastDeferredUntil != null);
    final isSkipped = practices.any((p) => p.dailyDone == -1);
    
    String? snoozeText;
    if (isSnoozed) {
      final latestSnooze = practices.map((p) => p.lastDeferredUntil ?? 0).fold(0, max);
      if (latestSnooze > 0) {
        final time = DateTime.fromMillisecondsSinceEpoch(latestSnooze);
        final hour = time.hour.toString().padLeft(2, '0');
        final min = time.minute.toString().padLeft(2, '0');
        snoozeText = 'تعویق تا ${toPersianDigits("$hour:$min")}';
      }
    }

    return PrayerAgendaCard(
      title: title,
      timeStr: timeStr,
      isDone: isDone,
      isSkipped: isSkipped,
      isSnoozed: isSnoozed,
      snoozeText: snoozeText,
      deferCount: maxDeferCount,
      hasReminder: hasReminder,
      disableControls: _isMenstruating,
      onToggle: onToggle,
      onSnooze: () => _showSnoozeDialog(title, practices),
      onSkip: () => _skipGroupAndPromptQada(title, practices),
    );
  }
}

class _AllPrayersReminderSettingsSheet extends StatefulWidget {

  const _AllPrayersReminderSettingsSheet({
    required this.fajrPractices,
    required this.dhuhrAsrPractices,
    required this.maghribIshaPractices,
    required this.onSaved,
  });
  final List<WorshipPractice> fajrPractices;
  final List<WorshipPractice> dhuhrAsrPractices;
  final List<WorshipPractice> maghribIshaPractices;
  final VoidCallback onSaved;

  @override
  State<_AllPrayersReminderSettingsSheet> createState() => _AllPrayersReminderSettingsSheetState();
}

class _AllPrayersReminderSettingsSheetState extends State<_AllPrayersReminderSettingsSheet> {
  bool _fajrEnabled = true;
  int _fajrOffset = 10;

  bool _dhuhrAsrEnabled = true;
  int _dhuhrAsrOffset = 10;

  bool _maghribIshaEnabled = true;
  int _maghribIshaOffset = 10;

  @override
  void initState() {
    super.initState();
    _fajrEnabled = widget.fajrPractices.any((p) => p.reminderEnabled);
    if (widget.fajrPractices.isNotEmpty) {
      _fajrOffset = widget.fajrPractices.first.reminderOffsetMinutes ?? 10;
    }

    _dhuhrAsrEnabled = widget.dhuhrAsrPractices.any((p) => p.reminderEnabled);
    if (widget.dhuhrAsrPractices.isNotEmpty) {
      _dhuhrAsrOffset = widget.dhuhrAsrPractices.first.reminderOffsetMinutes ?? 10;
    }

    _maghribIshaEnabled = widget.maghribIshaPractices.any((p) => p.reminderEnabled);
    if (widget.maghribIshaPractices.isNotEmpty) {
      _maghribIshaOffset = widget.maghribIshaPractices.first.reminderOffsetMinutes ?? 10;
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        for (final p in widget.fajrPractices) {
          await txn.update(
            'worship_practices',
            {
              'reminderEnabled': _fajrEnabled ? 1 : 0,
              'reminderOffsetMinutes': _fajrOffset,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [p.id],
          );
        }
        for (final p in widget.dhuhrAsrPractices) {
          await txn.update(
            'worship_practices',
            {
              'reminderEnabled': _dhuhrAsrEnabled ? 1 : 0,
              'reminderOffsetMinutes': _dhuhrAsrOffset,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [p.id],
          );
        }
        for (final p in widget.maghribIshaPractices) {
          await txn.update(
            'worship_practices',
            {
              'reminderEnabled': _maghribIshaEnabled ? 1 : 0,
              'reminderOffsetMinutes': _maghribIshaOffset,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [p.id],
          );
        }
      });

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving all reminder settings: $e');
    }
  }

  Widget _buildPrayerReminderSection({
    required String title,
    required bool enabled,
    required int offsetMinutes,
    required ValueChanged<bool> onEnabledChanged,
    required ValueChanged<double> onOffsetChanged,
    required RitmoColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
            ),
            CupertinoSwitch(
              value: enabled,
              activeTrackColor: const Color(0xffD4A843),
              onChanged: onEnabledChanged,
            ),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'زمان یادآوری:',
                style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
              Text(
                offsetMinutes == 0
                    ? 'دقیقاً زمان اذان'
                    : offsetMinutes < 0
                        ? toPersianDigits('${offsetMinutes.abs()} دقیقه قبل از اذان')
                        : toPersianDigits('$offsetMinutes دقیقه بعد از اذان'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xffD4A843), fontFamily: 'Vazirmatn'),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xffD4A843),
              inactiveTrackColor: colors.glassBorder,
              thumbColor: const Color(0xffD4A843),
              overlayColor: const Color(0xffD4A843).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: offsetMinutes.toDouble(),
              min: -60,
              max: 60,
              divisions: 24,
              onChanged: onOffsetChanged,
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تنظیم یادآوری نمازهای واجب',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildPrayerReminderSection(
                title: 'نماز صبح',
                enabled: _fajrEnabled,
                offsetMinutes: _fajrOffset,
                onEnabledChanged: (val) => setState(() => _fajrEnabled = val),
                onOffsetChanged: (val) => setState(() => _fajrOffset = val.toInt()),
                colors: colors,
              ),
              Divider(color: colors.border),
              _buildPrayerReminderSection(
                title: 'نماز ظهر و عصر',
                enabled: _dhuhrAsrEnabled,
                offsetMinutes: _dhuhrAsrOffset,
                onEnabledChanged: (val) => setState(() => _dhuhrAsrEnabled = val),
                onOffsetChanged: (val) => setState(() => _dhuhrAsrOffset = val.toInt()),
                colors: colors,
              ),
              Divider(color: colors.border),
              _buildPrayerReminderSection(
                title: 'نماز مغرب و عشا',
                enabled: _maghribIshaEnabled,
                offsetMinutes: _maghribIshaOffset,
                onEnabledChanged: (val) => setState(() => _maghribIshaEnabled = val),
                onOffsetChanged: (val) => setState(() => _maghribIshaOffset = val.toInt()),
                colors: colors,
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _save,
                child: const Text('ثبت تنظیمات یادآوری', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderSettingsSheet extends StatefulWidget {

  const _ReminderSettingsSheet({
    required this.groupTitle,
    required this.practices,
    required this.onSaved,
  });
  final String groupTitle;
  final List<WorshipPractice> practices;
  final VoidCallback onSaved;

  @override
  State<_ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<_ReminderSettingsSheet> {
  bool _reminderEnabled = true;
  int _offsetMinutes = 10;

  @override
  void initState() {
    super.initState();
    _reminderEnabled = widget.practices.any((p) => p.reminderEnabled);
    _offsetMinutes = widget.practices.first.reminderOffsetMinutes ?? 10;
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        for (final p in widget.practices) {
          await txn.update(
            'worship_practices',
            {
              'reminderEnabled': _reminderEnabled ? 1 : 0,
              'reminderOffsetMinutes': _offsetMinutes,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [p.id],
          );
        }
      });

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving reminder settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تنظیم یادآوری ${widget.groupTitle}',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Switch row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'فعال‌سازی یادآوری روزانه',
                    style: TextStyle(fontSize: 14.5, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  CupertinoSwitch(
                    value: _reminderEnabled,
                    activeTrackColor: const Color(0xffD4A843),
                    onChanged: (val) {
                      setState(() {
                        _reminderEnabled = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_reminderEnabled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'زمان اعلام یادآوری',
                      style: TextStyle(fontSize: 14.5, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                    Text(
                      _offsetMinutes == 0
                          ? 'دقیقاً زمان اذان'
                          : _offsetMinutes < 0
                              ? toPersianDigits('${_offsetMinutes.abs()} دقیقه قبل از اذان')
                              : toPersianDigits('$_offsetMinutes دقیقه بعد از اذان'),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xffD4A843), fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xffD4A843),
                    inactiveTrackColor: colors.glassBorder,
                    thumbColor: const Color(0xffD4A843),
                    overlayColor: const Color(0xffD4A843).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _offsetMinutes.toDouble(),
                    min: -60,
                    max: 60,
                    divisions: 24, // multiples of 5 mins (-60 to 60)
                    onChanged: (val) {
                      setState(() {
                        _offsetMinutes = val.toInt();
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _save,
                child: const Text('ثبت تنظیمات یادآوری', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnoozeSelectionDialog extends StatefulWidget {

  const _SnoozeSelectionDialog({
    required this.groupTitle,
    required this.practices,
    required this.prayerTime,
    required this.onSnoozed,
  });
  final String groupTitle;
  final List<WorshipPractice> practices;
  final PrayerTime? prayerTime;
  final VoidCallback onSnoozed;

  @override
  State<_SnoozeSelectionDialog> createState() => _SnoozeSelectionDialogState();
}

class _SnoozeSelectionDialogState extends State<_SnoozeSelectionDialog> {
  int _selectedMinutes = 15;
  final TextEditingController _customController = TextEditingController();
  bool _isCustom = false;
  String? _warningMessage;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _checkWarning(int mins) {
    if (widget.prayerTime == null) return;
    
    // We want to check if snooze duration exceeds the NEXT actual prayer time.
    final now = DateTime.now();
    final snoozeTime = now.add(Duration(minutes: mins));

    // Resolve next prayer time
    final nextPrEntry = widget.prayerTime!.nextPrayer(now);
    
    if (snoozeTime.isAfter(nextPrEntry.value)) {
      var nextPrFa = '';
      switch (nextPrEntry.key) {
        case 'FAJR': nextPrFa = 'صبح';
        case 'DHUHR': nextPrFa = 'ظهر';
        case 'ASR': nextPrFa = 'عصر';
        case 'MAGHRIB': nextPrFa = 'مغرب';
        case 'ISHA': nextPrFa = 'عشا';
        default: nextPrFa = 'بعدی';
      }
      setState(() {
        _warningMessage = '⚠️ هشدار: زمان تعویق از وقت نماز $nextPrFa نزدیک است!';
      });
    } else {
      setState(() {
        _warningMessage = null;
      });
    }
  }

  Future<void> _applySnooze() async {
    HapticFeedback.mediumImpact();
    var mins = _selectedMinutes;
    if (_isCustom) {
      mins = int.tryParse(_customController.text) ?? 15;
    }

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    try {
      await AgendaActionHandler.instance.snoozePrayer(
        practiceIds: widget.practices.map((p) => p.id).toList(),
        minutes: mins,
        dateStr: todayStr,
      );
      widget.onSnoozed();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: colors.medicalRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'تعویق یادآوری ${widget.groupTitle}',
          style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'می‌خواهید یادآوری مجدد این نماز تا چند دقیقه دیگر به تاخیر بیفتد؟',
              style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Standard Options
            if (!_isCustom) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [15, 30, 60].map((mins) {
                  final isSelected = _selectedMinutes == mins;
                  return ChoiceChip(
                    label: Text(toPersianDigits('$mins دقیقه'), style: const TextStyle(fontFamily: 'Vazirmatn')),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMinutes = mins;
                        });
                        _checkWarning(mins);
                      }
                    },
                    selectedColor: const Color(0xffD4A843),
                    backgroundColor: colors.inputBackground,
                    labelStyle: TextStyle(color: isSelected ? Colors.black : colors.textPrimary, fontSize: 13.5),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Toggle Custom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'زمان سفارشی',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13.5, fontFamily: 'Vazirmatn'),
                ),
                CupertinoSwitch(
                  value: _isCustom,
                  activeTrackColor: const Color(0xffD4A843),
                  onChanged: (val) {
                    setState(() {
                      _isCustom = val;
                      _warningMessage = null;
                    });
                    if (!val) {
                      _checkWarning(_selectedMinutes);
                    }
                  },
                ),
              ],
            ),

            if (_isCustom) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
                onChanged: (val) {
                  final mins = int.tryParse(val) ?? 0;
                  _checkWarning(mins);
                },
                decoration: InputDecoration(
                  hintText: 'مدت زمان به دقیقه...',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.4), fontSize: 13.5),
                  fillColor: colors.textSecondary.withValues(alpha: 0.02),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffD4A843)),
                  ),
                ),
              ),
            ],

            if (_warningMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _warningMessage!,
                style: const TextStyle(color: Color(0xffF87171), fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('انصراف', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffD4A843),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _applySnooze,
            child: Text('تایید تعویق', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
          ),
        ],
      ),
    );
  }
}
