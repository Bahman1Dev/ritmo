import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_consent_bridge.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:sqflite/sqflite.dart';

class WorshipDebtsSection extends StatefulWidget {

  const WorshipDebtsSection({
    super.key,
    required this.onChanged,
  });
  final VoidCallback onChanged;

  @override
  State<WorshipDebtsSection> createState() => _WorshipDebtsSectionState();
}

class _WorshipDebtsSectionState extends State<WorshipDebtsSection> {
  bool _isLoading = true;
  List<WorshipDebt> _activeDebts = [];
  List<WorshipDebt> _archivedDebts = [];
  bool _showArchived = false;

  // End of day prompt condition
  bool _showEndDayPrompt = false;
  List<String> _undonePrayerTitles = [];

  @override
  void initState() {
    super.initState();
    _loadDebtsAndCheckPrompt();
  }

  @override
  void didUpdateWidget(WorshipDebtsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadDebtsAndCheckPrompt();
  }

  Future<void> _loadDebtsAndCheckPrompt() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // 1. Load Debts
      final results = await db.query('worship_debts');
      final list = results.map(WorshipDebt.fromMap).toList();

      final active = <WorshipDebt>[];
      final archived = <WorshipDebt>[];

      for (final d in list) {
        if (d.remainingCount <= 0 || d.isArchived) {
          archived.add(d);
        } else {
          active.add(d);
        }
      }

      // 2. Check if we should show the undone prayer prompt
      // We only show it if the user is NOT menstruating, has undone prayers today,
      // and hasn't acted on this prompt today.
      var showPrompt = false;
      final undone = <String>[];

      final isMenstruating = await CycleConsentBridge.isWorshipSuspended();
      if (!isMenstruating) {
        // Check if prompt already acted upon today
        final promptSettings = await db.query(
          'app_settings',
          where: "key = 'worship_debt_prompt_date'",
          limit: 1,
        );
        final lastPromptDate = promptSettings.isNotEmpty ? promptSettings.first['value']! as String : '';

        if (lastPromptDate != todayStr) {
          // Check for daily prayers or mustahab practices with allowQada = 1 that are active but not completed
          final dailyPrayers = await db.query(
            'worship_practices',
            where: "(practiceType = 'PRAYER' OR (practiceType = 'MUSTAHAB' AND allowQada = 1)) AND isActive = 1 AND dailyDone = 0",
          );

          if (dailyPrayers.isNotEmpty) {
            for (final p in dailyPrayers) {
              undone.add(p['title']! as String);
            }
            showPrompt = true;
          }
        }
      }

      if (mounted) {
        setState(() {
          _activeDebts = active;
          _archivedDebts = archived;
          _showEndDayPrompt = showPrompt;
          _undonePrayerTitles = undone;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading worship debts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logCompletion(WorshipDebt debt) async {
    HapticFeedback.mediumImpact();
    if (debt.remainingCount <= 0) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final newRemaining = debt.remainingCount - 1;
      final isNowArchived = newRemaining == 0;

      await db.update(
        'worship_debts',
        {
          'remainingCount': newRemaining,
          'isArchived': isNowArchived ? 1 : 0,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [debt.id],
      );

      // Handle cycle fasting debt synchronization
      if (debt.id.startsWith('debt_cycle_fast_')) {
        final cycleDebtId = debt.id.replaceFirst('debt_cycle_fast_', '');
        await db.update(
          'fasting_debt',
          {
            'isResolved': isNowArchived ? 1 : 0,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [cycleDebtId],
        );
      }

      await _loadDebtsAndCheckPrompt();
      widget.onChanged();

      if (isNowArchived && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تبریک! بدهی عبادی "${debt.title}" را با موفقیت تمام کردید. 🎉', style: const TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: const Color(0xffD4A843),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error logging debt completion: $e');
    }
  }

  Future<void> _changeDailyTarget(WorshipDebt debt, int delta) async {
    HapticFeedback.selectionClick();
    final newTarget = (debt.dailyTarget + delta).clamp(1, 100);

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        'worship_debts',
        {
          'dailyTarget': newTarget,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [debt.id],
      );

      await _loadDebtsAndCheckPrompt();
    } catch (e) {
      debugPrint('Error updating debt target: $e');
    }
  }

  Future<void> _dismissPrompt(bool accept) async {
    HapticFeedback.mediumImpact();
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Mark prompt as completed for today in settings
      await db.insert(
        'app_settings',
        {
          'key': 'worship_debt_prompt_date',
          'value': todayStr,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. If accepted, add all undone prayers to debts
      if (accept) {
        for (final title in _undonePrayerTitles) {
          final debtId = 'debt_auto_${title.hashCode}_$nowMs';
          
          final existing = await db.query(
            'worship_debts',
            where: 'debtType = ? AND title = ? AND isArchived = 0',
            whereArgs: ['PRAYER', title],
            limit: 1,
          );

          if (existing.isNotEmpty) {
            final id = existing.first['id']! as String;
            final currentTotal = existing.first['totalCount']! as int;
            final currentRemaining = existing.first['remainingCount']! as int;

            await db.update(
              'worship_debts',
              {
                'totalCount': currentTotal + 1,
                'remainingCount': currentRemaining + 1,
                'updatedAt': nowMs,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          } else {
            await db.insert(
              'worship_debts',
              {
                'id': debtId,
                'debtType': 'PRAYER',
                'title': title,
                'totalCount': 1,
                'remainingCount': 1,
                'dailyTarget': 1,
                'autoCreated': 1,
                'isArchived': 0,
                'createdAt': nowMs,
                'updatedAt': nowMs,
              },
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('نمازهای خوانده‌نشده امروز به لیست قضای شما اضافه شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
              backgroundColor: Color(0xffD4A843),
            ),
          );
        }
      }

      setState(() {
        _showEndDayPrompt = false;
      });
      await _loadDebtsAndCheckPrompt();
      widget.onChanged();
    } catch (e) {
      debugPrint('Error dismissing prompt: $e');
    }
  }

  void _showAddDebtSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _AddDebtSheet(
          onSaved: () {
            _loadDebtsAndCheckPrompt();
            widget.onChanged();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: colors.textPrimary)),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. END OF DAY PROMPT
          if (_showEndDayPrompt && _undonePrayerTitles.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff0b0b0e) : colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : const Color(0xffD4A843).withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.bell_fill, color: Color(0xffD4A843), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ثبت نماز قضا',
                        style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary.withValues(alpha: 0.5), size: 16),
                        onPressed: () => _dismissPrompt(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'امروز موفق به خواندن ${toPersianDigits(_undonePrayerTitles.length.toString())} نماز (${_undonePrayerTitles.join(' و ')}) نشدید. مایلید این موارد به قضا اضافه شود؟',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13.5, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _dismissPrompt(false),
                        child: Text('خیر، لازم نیست', style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 13.5, fontFamily: 'Vazirmatn')),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffD4A843),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => _dismissPrompt(true),
                        child: Text(
                          'بله، اضافه کن',
                          style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // 2. ACTIVE DEBTS SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'بدهی‌های عبادی (قضا)',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              GestureDetector(
                onTap: _showAddDebtSheet,
                child: Text(
                  '➕ ثبت بدهی جدید',
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
          const SizedBox(height: 10),

          if (_activeDebts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff0b0b0e) : Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.68), width: 1.5),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.checkmark_seal, color: colors.textSecondary.withValues(alpha: 0.4), size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'هیچ بدهی عبادی ثبت نشده است.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff0b0b0e) : Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.68), width: 1.5),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activeDebts.length,
                    separatorBuilder: (context, index) => Divider(color: colors.border, height: 24),
                    itemBuilder: (context, index) {
                      final debt = _activeDebts[index];
                      final remaining = debt.remainingCount;
                      final total = debt.totalCount;
                      final completed = total - remaining;
                      final progress = debt.progressPercent / 100.0;
                      final daysLeft = debt.daysToFinish;

                      // Display type icon
                      var typeIcon = CupertinoIcons.check_mark;
                      if (debt.debtType == 'FAST') typeIcon = CupertinoIcons.drop;
                      if (debt.debtType == 'PRAYER') typeIcon = CupertinoIcons.circle_grid_hex;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(typeIcon, color: const Color(0xffD4A843), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                debt.title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const Spacer(),
                              Text(
                                toPersianDigits('$completed از $total انجام شده'),
                                style: TextStyle(color: colors.textSecondary, fontSize: 12.5, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Timeline Prediction Note
                          if (debt.dailyTarget > 0)
                            Text(
                              toPersianDigits('اگه روزی ${debt.dailyTarget} تا انجام بدی، $daysLeft روزه تموم میشه ✨'),
                              style: const TextStyle(color: Color(0xffD4A843), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                          const SizedBox(height: 8),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colors.inputBackground,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xffD4A843)),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Actions Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Change target
                              Row(
                                children: [
                                  Text(
                                    'هدف روزانه: ',
                                    style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 12.5, fontFamily: 'Vazirmatn'),
                                  ),
                                  GestureDetector(
                                    onTap: () => _changeDailyTarget(debt, -1),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(6)),
                                      child: Icon(CupertinoIcons.minus, size: 10, color: colors.iconSecondary),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      toPersianDigits('${debt.dailyTarget}'),
                                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _changeDailyTarget(debt, 1),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(6)),
                                      child: Icon(CupertinoIcons.plus, size: 10, color: colors.iconSecondary),
                                    ),
                                  ),
                                ],
                              ),

                              // Increment button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.textSecondary.withValues(alpha: 0.05),
                                  foregroundColor: colors.textPrimary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _logCompletion(debt),
                                icon: const Icon(CupertinoIcons.checkmark, size: 12, color: Color(0xffD4A843)),
                                label: const Text('ثبت انجام قضا', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  // Archived Section Toggle
                  if (_archivedDebts.isNotEmpty) ...[
                    Divider(color: colors.border, height: 24),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showArchived = !_showArchived;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showArchived ? '🔻 پنهان کردن آرشیو' : '🔺 نمایش بدهی‌های پایان‌یافته',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                          ),
                        ],
                      ),
                    ),
                    if (_showArchived) ...[
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _archivedDebts.length,
                        itemBuilder: (context, index) {
                          final debt = _archivedDebts[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xff10B981), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  debt.title,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'شما توانستید تمام کنید ✅',
                                  style: TextStyle(color: Color(0xff10B981), fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AddDebtSheet extends StatefulWidget {

  const _AddDebtSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _targetController = TextEditingController(text: '1');
  String _debtType = 'PRAYER'; // PRAYER, FAST, ATONEMENT

  @override
  void dispose() {
    _titleController.dispose();
    _countController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final count = int.tryParse(_countController.text) ?? 0;
    final target = int.tryParse(_targetController.text) ?? 1;

    if (title.isEmpty || count <= 0) return;

    HapticFeedback.mediumImpact();
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final id = 'debt_custom_$nowMs';

      await db.insert(
        'worship_debts',
        {
          'id': id,
          'debtType': _debtType,
          'title': title,
          'totalCount': count,
          'remainingCount': count,
          'dailyTarget': target,
          'autoCreated': 0,
          'isArchived': 0,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        },
      );

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving custom debt: $e');
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
                    'ثبت بدهی (قضای) جدید',
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
                  hintText: 'عنوان بدهی (مثلا: نماز قضای صبح)',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5),
                  fillColor: colors.textSecondary.withValues(alpha: 0.02),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xffD4A843)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Debt Type Picker
              Row(
                children: [
                  _buildTypeOption('PRAYER', 'نماز قضا'),
                  const SizedBox(width: 8),
                  _buildTypeOption('FAST', 'روزه قضا'),
                  const SizedBox(width: 8),
                  _buildTypeOption('ATONEMENT', 'کفاره / سایر'),
                ],
              ),
              const SizedBox(height: 12),

              // Total count & Target Count Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
                      decoration: InputDecoration(
                        hintText: 'تعداد کل قضاها',
                        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5),
                        fillColor: colors.textSecondary.withValues(alpha: 0.02),
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.06)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xffD4A843)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
                      decoration: InputDecoration(
                        hintText: 'هدف انجام در روز',
                        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5),
                        fillColor: colors.textSecondary.withValues(alpha: 0.02),
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.06)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xffD4A843)),
                        ),
                      ),
                    ),
                  ),
                ],
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
                child: const Text('ثبت بدهی جدید', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String label) {
    final colors = context.colors;
    final isSelected = _debtType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _debtType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.textSecondary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xffD4A843).withValues(alpha: 0.5) : colors.textSecondary.withValues(alpha: 0.06),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xffC4953B) : colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
