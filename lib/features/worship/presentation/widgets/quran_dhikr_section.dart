import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/fullscreen_tasbih_sheet.dart';

class QuranDhikrSection extends StatefulWidget {

  const QuranDhikrSection({
    super.key,
    required this.onChanged,
  });
  final VoidCallback onChanged;

  @override
  State<QuranDhikrSection> createState() => _QuranDhikrSectionState();
}

class _QuranDhikrSectionState extends State<QuranDhikrSection> {
  bool _isLoading = true;
  String _todayStr = '';

  // Quran practice
  WorshipPractice? _quranPractice;

  // Dhikrs list & selected Dhikr
  List<WorshipPractice> _dhikrs = [];
  String? _selectedDhikrId;

  // Hazrat Zahra Tasbih Active State (Local)
  // Step: 0 = Allahu Akbar (34), 1 = Al-Hamdulillah (33), 2 = Subhan Allah (33)
  int _zahraStep = 0;
  int _zahraCount = 0;

  final List<String> _zahraPhrases = ['الله اکبر', 'الحمدلله', 'سبحان الله'];
  final List<int> _zahraTargets = [34, 33, 33];

  @override
  void initState() {
    super.initState();
    _todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _loadData();
  }

  @override
  void didUpdateWidget(QuranDhikrSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Check & Initialize Defaults if missing
      await db.transaction((txn) async {
        // Quran
        final quranCheck = await txn.query('worship_practices', where: "id = 'wp_quran'", limit: 1);
        if (quranCheck.isEmpty) {
          await txn.insert('worship_practices', {
            'id': 'wp_quran',
            'practiceType': 'QURAN',
            'subType': 'PAGE',
            'title': 'قرائت قرآن کریم',
            'dailyTarget': 4,
            'dailyDone': 0,
            'isActive': 1,
            'dailyDoneDate': _todayStr,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          });
        }

        // Hazrat Zahra
        final zahraCheck = await txn.query('worship_practices', where: "id = 'wp_dhikr_zahra'", limit: 1);
        if (zahraCheck.isEmpty) {
          await txn.insert('worship_practices', {
            'id': 'wp_dhikr_zahra',
            'practiceType': 'DHIKR',
            'subType': 'TASBIH',
            'title': 'تسبیحات حضرت زهرا',
            'dailyTarget': 1,
            'dailyDone': 0,
            'isActive': 1,
            'dailyDoneDate': _todayStr,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          });
        }

        // Salawat
        final salawatCheck = await txn.query('worship_practices', where: "id = 'wp_dhikr_salawat'", limit: 1);
        if (salawatCheck.isEmpty) {
          await txn.insert('worship_practices', {
            'id': 'wp_dhikr_salawat',
            'practiceType': 'DHIKR',
            'subType': 'SALAWAT',
            'title': 'صلوات',
            'dailyTarget': 100,
            'dailyDone': 0,
            'isActive': 1,
            'dailyDoneDate': _todayStr,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          });
        }

        // Esteghfar
        final esteghfarCheck = await txn.query('worship_practices', where: "id = 'wp_dhikr_esteghfar'", limit: 1);
        if (esteghfarCheck.isEmpty) {
          await txn.insert('worship_practices', {
            'id': 'wp_dhikr_esteghfar',
            'practiceType': 'DHIKR',
            'subType': 'ESTEGHFAR',
            'title': 'استغفار',
            'dailyTarget': 100,
            'dailyDone': 0,
            'isActive': 1,
            'dailyDoneDate': _todayStr,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          });
        }
      });

      // 2. Fetch Practices (Load QURAN regardless of isActive, but DHIKR only if isActive = 1)
      final allWorship = await db.query(
        'worship_practices',
        where: "practiceType = 'QURAN' OR (practiceType = 'DHIKR' AND isActive = 1)",
        orderBy: 'createdAt ASC',
      );

      final list = allWorship.map(WorshipPractice.fromMap).toList();

      // Daily reset is handled centrally in EndOfDaySweep

      // Extract Quran and Dhikrs list
      WorshipPractice? quranP;
      final dhikrsList = <WorshipPractice>[];

      for (final p in list) {
        if (p.practiceType == 'QURAN') {
          quranP = p;
        } else if (p.practiceType == 'DHIKR') {
          dhikrsList.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _quranPractice = quranP;
          _dhikrs = dhikrsList;
          if (_selectedDhikrId == null || !dhikrsList.any((d) => d.id == _selectedDhikrId)) {
            if (dhikrsList.any((d) => d.id == 'wp_dhikr_zahra')) {
              _selectedDhikrId = 'wp_dhikr_zahra';
            } else if (dhikrsList.isNotEmpty) {
              _selectedDhikrId = dhikrsList.first.id;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Quran/Dhikr data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- QURAN ACTIONS ---
  Future<void> _updateQuranPages(int delta) async {
    if (_quranPractice == null) return;
    unawaited(HapticFeedback.lightImpact());

    final currentDone = _quranPractice!.dailyDone;
    final newDone = (currentDone + delta).clamp(0, 999);

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final updated = _quranPractice!.copyWith(
        dailyDone: newDone,
        updatedAt: nowMs,
      );

      await db.update(
        'worship_practices',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );

      setState(() {
        _quranPractice = updated;
      });
      widget.onChanged();
    } catch (e) {
      debugPrint('Error updating Quran pages: $e');
    }
  }

  Future<void> _toggleQuranActive(bool isActive) async {
    if (_quranPractice == null) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final updated = _quranPractice!.copyWith(
        isActive: isActive,
        updatedAt: nowMs,
      );

      await db.update(
        'worship_practices',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );

      setState(() {
        _quranPractice = updated;
      });
      widget.onChanged();
    } catch (e) {
      debugPrint('Error toggling Quran active: $e');
    }
  }

  void _showQuranSettingsSheet() {
    if (_quranPractice == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _QuranSettingsSheet(
          practice: _quranPractice!,
          onSaved: () {
            _loadData();
            widget.onChanged();
          },
        );
      },
    );
  }

  // --- HAZRAT ZAHRA TASBIH ACTIONS ---
  Future<void> _tapZahraCounter() async {
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _zahraCount++;
    });

    final target = _zahraTargets[_zahraStep];
    if (_zahraCount >= target) {
      unawaited(HapticFeedback.mediumImpact());
      if (_zahraStep < 2) {
        // Next Phrase
        setState(() {
          _zahraStep++;
          _zahraCount = 0;
        });
      } else {
        // Finished a full round!
        _zahraStep = 0;
        _zahraCount = 0;

        final activePractice = _dhikrs.firstWhere((p) => p.id == 'wp_dhikr_zahra');
        final db = await DatabaseHelper.instance.database;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final updated = activePractice.copyWith(
          dailyDone: activePractice.dailyDone + 1,
          updatedAt: nowMs,
        );

        await db.update(
          'worship_practices',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [updated.id],
        );

        await _loadData();
        widget.onChanged();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تسبیحات حضرت زهرا (س) به پایان رسید. قبول باشد ✨', style: TextStyle(fontFamily: 'Vazirmatn')),
              backgroundColor: Color(0xffD4A843),
            ),
          );
        }
      }
    }
  }

  void _resetZahraCounter() {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _zahraStep = 0;
      _zahraCount = 0;
    });
  }

  void _openFullscreenTasbih({String? title, int target = 100, bool isFatima = false}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => FullscreenTasbihSheet(
          initialDhikrTitle: title ?? 'تسبیحات حضرت زهرا (س)',
          targetCount: target,
          isFatimaTasbih: isFatima,
        ),
      ),
    ).then((_) {
      _loadData();
      widget.onChanged();
    });
  }

  // --- OTHER DHIKRS ACTIONS ---
  Future<void> _incrementDhikr(WorshipPractice practice, int amount) async {
    unawaited(HapticFeedback.lightImpact());
    final newDone = (practice.dailyDone + amount).clamp(0, 99999);

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final updated = practice.copyWith(
        dailyDone: newDone,
        updatedAt: nowMs,
      );

      await db.update(
        'worship_practices',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [practice.id],
      );

      await _loadData();
      widget.onChanged();
    } catch (e) {
      debugPrint('Error incrementing dhikr: $e');
    }
  }

  Future<void> _resetDhikr(WorshipPractice practice) async {
    unawaited(HapticFeedback.mediumImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final updated = practice.copyWith(
        dailyDone: 0,
        updatedAt: nowMs,
      );

      await db.update(
        'worship_practices',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [practice.id],
      );

      await _loadData();
      widget.onChanged();
    } catch (e) {
      debugPrint('Error resetting dhikr: $e');
    }
  }

  Future<void> _deleteCustomDhikr(WorshipPractice practice) async {
    unawaited(HapticFeedback.vibrate());
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'worship_practices',
        where: 'id = ?',
        whereArgs: [practice.id],
      );
      if (_selectedDhikrId == practice.id) {
        _selectedDhikrId = 'wp_dhikr_zahra';
      }
      await _loadData();
      widget.onChanged();
    } catch (e) {
      debugPrint('Error deleting custom dhikr: $e');
    }
  }

  Future<void> _manuallySetDhikrCount(WorshipPractice practice) async {
    final colors = context.colors;
    final controller = TextEditingController(text: practice.dailyDone.toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'ثبت دستی تعداد ${practice.title}',
              style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 15.5, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تعداد انجام شده امروز را وارد کنید:',
                  style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 13.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  decoration: InputDecoration(
                    fillColor: colors.inputBackground,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffD4A843)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('انصراف', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('ذخیره', style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );

    if (result ?? false) {
      final value = int.tryParse(controller.text) ?? 0;
      unawaited(HapticFeedback.mediumImpact());
      try {
        final db = await DatabaseHelper.instance.database;
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        await db.update(
          'worship_practices',
          {
            'dailyDone': value,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [practice.id],
        );

        if (practice.id == 'wp_dhikr_zahra') {
          setState(() {
            _zahraStep = 0;
            _zahraCount = 0;
          });
        }

        await _loadData();
        widget.onChanged();
      } catch (e) {
        debugPrint('Error manually setting dhikr count: $e');
      }
    }
  }

  void _showAddDhikrSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _AddDhikrSheet(
          onSaved: () {
            _loadData();
            widget.onChanged();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: colors.textPrimary)),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قرآن و اذکار',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.fullscreen, color: Color(0xffD4A843), size: 20),
                    tooltip: 'تسبیح تمام‌صفحه',
                    onPressed: () => _openFullscreenTasbih(isFatima: true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(CupertinoIcons.settings, color: colors.textSecondary, size: 20),
                    onPressed: _showQuranSettingsSheet,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. QURAN CARD
          if (_quranPractice != null) _buildQuranCard(colors),
          const SizedBox(height: 16),

          // 2. MERGED DHIKRS & TASBIHAT CARD
          _buildDhikrCard(colors),
        ],
      ),
    );
  }

  Widget _buildQuranCard(RitmoColors colors) {
    final done = _quranPractice!.dailyDone;
    final target = _quranPractice!.dailyTarget;
    final isActive = _quranPractice!.isActive;
    final progress = target > 0 ? (done / target).clamp(0.0, 1.0) : 0.0;
    final isCompleted = done >= target;

    // Mock weekly pages chart data (last 7 days)
    final mockPages = <int>[2, 4, 6, 3, 0, 4, done];
    final mockDays = <String>['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.book, color: Color(0xffD4A843), size: 18),
              const SizedBox(width: 8),
              Text(
                'قرائت قرآن کریم',
                style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
              ),
              const Spacer(),
              if (isActive && isCompleted) ...[
                const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xffD4A843), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '🎉 تکمیل هدف امروز',
                      style: TextStyle(color: Color(0xffD4A843), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: isActive,
                  activeTrackColor: const Color(0xffD4A843),
                  onChanged: _toggleQuranActive,
                ),
              ),
            ],
          ),

          if (!isActive) ...[
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'برنامه قرائت قرآن خاموش است 📖',
                  style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5, fontFamily: 'Vazirmatn'),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),

            // Progress Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  toPersianDigits('$done از $target صفحه خوانده شده'),
                  style: TextStyle(color: colors.textSecondary, fontSize: 13.5, fontFamily: 'Vazirmatn'),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _updateQuranPages(-1),
                      icon: Icon(CupertinoIcons.minus_circle, color: colors.textSecondary, size: 22),
                    ),
                    IconButton(
                      onPressed: () => _updateQuranPages(1),
                      icon: const Icon(CupertinoIcons.plus_circle, color: Color(0xffD4A843), size: 22),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Linear progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.inputBackground,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xffD4A843)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),

            // Weekly bar trend
            Text(
              'روند قرائت ۷ روز گذشته:',
              style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (idx) {
                  final val = mockPages[idx];
                  final maxVal = mockPages.fold(1, max);
                  final ratio = (val / maxVal).clamp(0.05, 1.0);

                  return Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 10,
                              height: 35 * ratio,
                              decoration: BoxDecoration(
                                color: idx == 6
                                    ? const Color(0xffD4A843)
                                    : const Color(0xffD4A843).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mockDays[idx],
                          style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 10.5, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDhikrCard(RitmoColors colors) {
    if (_dhikrs.isEmpty) return const SizedBox();

    final activePractice = _dhikrs.firstWhere(
      (p) => p.id == _selectedDhikrId,
      orElse: () => _dhikrs.first,
    );

    final done = activePractice.dailyDone;
    final target = activePractice.dailyTarget;
    final isCustom = activePractice.subType == 'CUSTOM';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.circle_grid_hex, color: Color(0xffD4A843), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activePractice.id,
                    dropdownColor: colors.card,
                    icon: Icon(CupertinoIcons.chevron_down, color: colors.textSecondary, size: 14),
                    style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    items: _dhikrs.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(d.title),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDhikrId = val;
                          if (val == 'wp_dhikr_zahra') {
                            _zahraStep = 0;
                            _zahraCount = 0;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              // No reminder icon
              GestureDetector(
                onTap: _showAddDhikrSheet,
                child: Text(
                  '➕ ذکر جدید',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (activePractice.id == 'wp_dhikr_zahra') ...[
            // Tasbih Hazrat Zahra view
            Row(
              children: [
                Expanded(
                  child: ScaleOnTap(
                    onTap: _tapZahraCounter,
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff16161a) : colors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _zahraPhrases[_zahraStep],
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xffD4A843),
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              toPersianDigits('$_zahraCount / ${_zahraTargets[_zahraStep]}'),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    // Reset Button
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: colors.textSecondary.withValues(alpha: 0.04)),
                      icon: Icon(CupertinoIcons.refresh, color: colors.textSecondary, size: 20),
                      onPressed: _resetZahraCounter,
                    ),
                    const SizedBox(height: 4),
                    // Manual Edit
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: colors.textSecondary.withValues(alpha: 0.04)),
                      icon: Icon(CupertinoIcons.pencil, color: colors.textSecondary, size: 20),
                      onPressed: () => _manuallySetDhikrCount(activePractice),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (idx) {
                final isPassed = _zahraStep > idx;
                final isActive = _zahraStep == idx;
                var indicatorColor = colors.inputBackground;
                if (isPassed) indicatorColor = const Color(0xffD4A843);
                if (isActive) indicatorColor = const Color(0xffD4A843).withValues(alpha: 0.5);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 32,
                  height: 6,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            if (done > 0) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  toPersianDigits('امروز: $done دور انجام شده'),
                  style: const TextStyle(color: Color(0xffD4A843), fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
              ),
            ]
          ] else ...[
            // Other Dhikrs view
            Row(
              children: [
                Expanded(
                  child: ScaleOnTap(
                    onTap: () => _incrementDhikr(activePractice, 1),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff16161a) : colors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              toPersianDigits('$done / $target'),
                              style: const TextStyle(
                                fontSize: 21.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffD4A843),
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        // Reset Button
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: colors.textSecondary.withValues(alpha: 0.04)),
                          icon: Icon(CupertinoIcons.refresh, color: colors.textSecondary, size: 18),
                          onPressed: () => _resetDhikr(activePractice),
                        ),
                        const SizedBox(width: 4),
                        // Fast Increment +10
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xffD4A843).withValues(alpha: 0.1)),
                          icon: const Text('۱۰+', style: TextStyle(color: Color(0xffD4A843), fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                          onPressed: () => _incrementDhikr(activePractice, 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Manual Edit
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: colors.textSecondary.withValues(alpha: 0.04)),
                          icon: Icon(CupertinoIcons.pencil, color: colors.textSecondary, size: 18),
                          onPressed: () => _manuallySetDhikrCount(activePractice),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.1)),
                            icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 18),
                            onPressed: () => _deleteCustomDhikr(activePractice),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuranSettingsSheet extends StatefulWidget {

  const _QuranSettingsSheet({
    required this.practice,
    required this.onSaved,
  });
  final WorshipPractice practice;
  final VoidCallback onSaved;

  @override
  State<_QuranSettingsSheet> createState() => _QuranSettingsSheetState();
}

class _QuranSettingsSheetState extends State<_QuranSettingsSheet> {
  late int _targetPages;

  @override
  void initState() {
    super.initState();
    _targetPages = widget.practice.dailyTarget;
  }

  Future<void> _save() async {
    unawaited(HapticFeedback.mediumImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        'worship_practices',
        {
          'dailyTarget': _targetPages,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [widget.practice.id],
      );

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving Quran target: $e');
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
                    'تنظیمات قرائت قرآن',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'هدف روزانه (تعداد صفحه در روز):',
                    style: TextStyle(fontSize: 14.5, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  Text(
                    toPersianDigits('$_targetPages صفحه'),
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xffD4A843), fontFamily: 'Vazirmatn'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_targetPages > 1) {
                        setState(() {
                          _targetPages--;
                        });
                      }
                    },
                    icon: Icon(CupertinoIcons.minus_circle, color: colors.textSecondary, size: 24),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      if (_targetPages < 604) {
                        setState(() {
                          _targetPages++;
                        });
                      }
                    },
                    icon: const Icon(CupertinoIcons.plus_circle, color: Color(0xffD4A843), size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // No reminder details area
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _save,
                child: const Text('ثبت تنظیمات قرائت', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDhikrSheet extends StatefulWidget {

  const _AddDhikrSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<_AddDhikrSheet> createState() => _AddDhikrSheetState();
}

class _AddDhikrSheetState extends State<_AddDhikrSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController(text: '100');

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final target = int.tryParse(_targetController.text) ?? 100;
    if (title.isEmpty) return;

    unawaited(HapticFeedback.mediumImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final id = 'wp_dhikr_custom_$nowMs';

      await db.insert(
        'worship_practices',
        {
          'id': id,
          'practiceType': 'DHIKR',
          'subType': 'CUSTOM',
          'title': title,
          'dailyTarget': target,
          'dailyDone': 0,
          'reminderEnabled': 0,
          'isActive': 1,
          'dailyDoneDate': todayStr,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        },
      );

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving custom dhikr: $e');
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
                    'افزودن ذکر سفارشی جدید',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: _titleController,
                style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
                decoration: InputDecoration(
                  hintText: 'نام ذکر (مثلا: لا اله الا الله)',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5),
                  fillColor: colors.inputBackground,
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xffD4A843)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Target count
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
                decoration: InputDecoration(
                  hintText: 'هدف روزانه (تعداد مرتبه)',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5),
                  fillColor: colors.inputBackground,
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xffD4A843)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4A843),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _save,
                child: const Text('ثبت و افزودن ذکر', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScaleOnTap extends StatefulWidget {

  const ScaleOnTap({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );
    _scale = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) async {
        await _controller.forward();
        unawaited(_controller.reverse());
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
