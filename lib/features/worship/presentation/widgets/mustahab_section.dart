import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_snackbar.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/worship_reminder_settings_sheet.dart';
import 'package:sqflite/sqflite.dart';

class MustahabSection extends StatefulWidget {

  const MustahabSection({
    super.key,
    required this.onChanged,
  });
  final VoidCallback onChanged;

  @override
  State<MustahabSection> createState() => _MustahabSectionState();
}

class _MustahabSectionState extends State<MustahabSection> {
  bool _isLoading = true;
  List<WorshipPractice> _activeMustahabs = [];
  String _todayStr = '';

  @override
  void initState() {
    super.initState();
    _todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _loadMustahabs();
  }

  @override
  void didUpdateWidget(MustahabSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMustahabs();
  }

  Future<void> _loadMustahabs() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Fetch active mustahab practices
      final results = await db.query(
        'worship_practices',
        where: "practiceType = 'MUSTAHAB' AND isActive = 1",
        orderBy: 'sortOrder ASC, createdAt DESC',
      );

      final list = results.map(WorshipPractice.fromMap).toList();

      // Daily reset is handled centrally in EndOfDaySweep

      if (mounted) {
        setState(() {
          _activeMustahabs = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mustahab practices: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleDone(WorshipPractice practice, bool isDone) async {
    unawaited(HapticFeedback.selectionClick());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final updated = practice.copyWith(
        dailyDone: isDone ? 1 : 0,
        dailyDoneDate: _todayStr,
        updatedAt: nowMs,
      );

      await db.update(
        'worship_practices',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [practice.id],
      );

      await _loadMustahabs();
      widget.onChanged();

      // Notify the reactive layer (invalidates DayAgenda cache + refreshes UI).
      RitmoEventBus().fire(RitmoEvent(
        type: 'WorshipUpdated',
        timestamp: DateTime.now(),
        payload: {
          'practiceId': practice.id,
          'done': isDone,
          'date': _todayStr,
        },
      ));
    } catch (e) {
      debugPrint('Error updating mustahab: $e');
    }
  }

  Future<void> _skipPracticeAndPromptQada(WorshipPractice practice) async {
    final colors = context.colors;
    unawaited(HapticFeedback.vibrate());
    
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
              'ثبت قضای ${practice.title}',
              style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'آیا مایلید ${practice.title} امروز را به بدهی‌های عبادی خود (بخش قضا) اضافه کنید؟',
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

    if (addToQada ?? false) {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final debtId = 'debt_${practice.subType ?? "mustahab"}_$nowMs';

      // Add or increment debt
      final existingDebt = await db.query(
        'worship_debts',
        where: 'debtType = ? AND title = ? AND isArchived = 0',
        whereArgs: ['PRAYER', practice.title],
        limit: 1,
      );

      if (existingDebt.isNotEmpty) {
        final id = existingDebt.first['id']! as String;
        final currentTotal = existingDebt.first['totalCount']! as int;
        final currentRemaining = existingDebt.first['remainingCount']! as int;

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
            'title': practice.title,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('قضای ${practice.title} به بدهی‌های شما اضافه شد.', style: const TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: const Color(0xffD4A843),
          ),
        );
      }
    }

    // Mark as completed/skipped for today (set dailyDone to 1) so it doesn't show as undone and hides the controls.
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'worship_practices',
      {
        'dailyDone': 1,
        'dailyDoneDate': _todayStr,
        'updatedAt': nowMs,
      },
      where: 'id = ?',
      whereArgs: [practice.id],
    );

    await _loadMustahabs();
    widget.onChanged();
  }

  void _showManageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ManageMustahabSheet(
          onSaved: () {
            _loadMustahabs();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مستحبات و ادعیه',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              GestureDetector(
                onTap: _showManageSheet,
                child: Text(
                  '➕ مدیریت',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_activeMustahabs.isEmpty)
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
                    Icon(CupertinoIcons.heart, color: colors.textSecondary.withValues(alpha: 0.4), size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'هیچ برنامه‌ی مستحبی فعال نیست.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.textSecondary.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showManageSheet,
                      child: const Text(
                        'فعال‌سازی مستحبات',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeMustahabs.length,
                separatorBuilder: (context, index) => Divider(color: colors.border, height: 16),
                itemBuilder: (context, index) {
                  final practice = _activeMustahabs[index];
                  final isDone = practice.dailyDone >= 1;

                  return Row(
                    children: [
                      // Checkbox
                      Transform.scale(
                        scale: 1.05,
                        child: Checkbox(
                          value: isDone,
                          onChanged: (val) {
                            if (val != null) {
                              _toggleDone(practice, val);
                            }
                          },
                          activeColor: const Color(0xffD4A843),
                          checkColor: Colors.white,
                          side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              practice.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDone ? colors.cardSubtitle : colors.cardTitle,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            if (practice.notes != null && practice.notes!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                toPersianDigits(practice.notes!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Skip Button
                      if (practice.allowQada && !isDone)
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.clear_circled,
                            color: colors.textSecondary.withValues(alpha: 0.6),
                            size: 18,
                          ),
                          tooltip: 'رد کردن و ثبت قضا',
                          onPressed: () => _skipPracticeAndPromptQada(practice),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ManageMustahabSheet extends StatefulWidget {

  const _ManageMustahabSheet({
    required this.onSaved,
  });
  final VoidCallback onSaved;

  @override
  State<_ManageMustahabSheet> createState() => _ManageMustahabSheetState();
}

class _ManageMustahabSheetState extends State<_ManageMustahabSheet> {
  List<Map<String, dynamic>> _presets = [];
  List<WorshipPractice> _customPractices = [];
  bool _isLoadingPresets = true;

  final List<Map<String, dynamic>> _defaultPresets = [
    {'id': 'preset_night_prayer', 'subType': 'NIGHT_PRAYER', 'title': 'نماز شب', 'notes': 'هر شب قبل از خواب یا نیمه‌شب'},
    {'id': 'preset_nafilah_fajr', 'subType': 'NAFILAH', 'title': 'نافله صبح', 'notes': 'قبل از نماز صبح'},
    {'id': 'preset_nafilah_dhuhr', 'subType': 'NAFILAH', 'title': 'نافله ظهر', 'notes': 'قبل از نماز ظهر'},
    {'id': 'preset_nafilah_asr', 'subType': 'NAFILAH', 'title': 'نافله عصر', 'notes': 'قبل از نماز عصر'},
    {'id': 'preset_nafilah_maghrib', 'subType': 'NAFILAH', 'title': 'نافله مغرب', 'notes': 'بعد از نماز مغرب'},
    {'id': 'preset_nafilah_isha', 'subType': 'NAFILAH', 'title': 'نافله عشا', 'notes': 'بعد از نماز عشا'},
    {'id': 'preset_ziarat_ashura', 'subType': 'ZIARAT', 'title': 'زیارت عاشورا', 'notes': 'زیارت امام حسین (ع)'},
    {'id': 'preset_dua_ahd', 'subType': 'DUA', 'title': 'دعای عهد', 'notes': 'تجدید عهد با امام زمان (عج)'},
    {'id': 'preset_dua_kumayl', 'subType': 'DUA', 'title': 'دعای کمیل', 'notes': 'پنجشنبه شب‌ها'},
    {'id': 'preset_dua_nudbah', 'subType': 'DUA', 'title': 'دعای ندبه', 'notes': 'صبح‌های جمعه'},
    {'id': 'preset_jafar_tayyar', 'subType': 'PRAYER', 'title': 'نماز جعفر طیار', 'notes': 'توصیه شده در روز جمعه'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Read active status for all presets
      final finalPresets = <Map<String, dynamic>>[];
      for (final def in _defaultPresets) {
        final existing = await db.query(
          'worship_practices',
          where: 'id = ?',
          whereArgs: [def['id']],
          limit: 1,
        );

        var isActive = false;
        if (existing.isNotEmpty) {
          isActive = (existing.first['isActive'] as int? ?? 0) == 1;
        }

        finalPresets.add({
          ...def,
          'isActive': isActive,
        });
      }

      // Read all custom mustahabs
      final customResults = await db.query(
        'worship_practices',
        where: "practiceType = 'MUSTAHAB' AND subType = 'CUSTOM'",
        orderBy: 'createdAt DESC',
      );
      final customs = customResults.map(WorshipPractice.fromMap).toList();

      if (mounted) {
        setState(() {
          _presets = finalPresets;
          _customPractices = customs;
          _isLoadingPresets = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading presets: $e');
    }
  }

  Future<void> _toggleCustomActive(WorshipPractice practice, bool enable) async {
    unawaited(HapticFeedback.lightImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'worship_practices',
        {
          'isActive': enable ? 1 : 0,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [practice.id],
      );
      await _loadPresets();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error toggling custom active: $e');
    }
  }

  Future<void> _deleteCustom(WorshipPractice practice) async {
    unawaited(HapticFeedback.vibrate());

    // 1. Temporarily remove from local list and update UI
    setState(() {
      _customPractices.removeWhere((p) => p.id == practice.id);
    });

    var undoClicked = false;

    // 2. Show SnackBar with Undo action
    final colors = context.colors;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border.withValues(alpha: 0.1), width: 0.8),
        ),
        backgroundColor: colors.card.withValues(alpha: 0.95),
        duration: const Duration(seconds: 5),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'مستحب سفارشی حذف شد',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13.5,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  undoClicked = true;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  // Re-add and reload
                  _loadPresets();
                },
                child: const Text(
                  'بازگرداندن (Undo)',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xffD4A843),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 3. Wait for 5 seconds, then check if we should delete from DB
    await Future.delayed(const Duration(seconds: 5));
    if (!undoClicked) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete(
          'worship_practices',
          where: 'id = ?',
          whereArgs: [practice.id],
        );
        widget.onSaved();
      } catch (e) {
        debugPrint('Error deleting custom practice: $e');
      }
    }
  }

  Map<String, dynamic> _getDefaultReminder(String id) {
    final defaults = <String, Map<String, dynamic>>{
      'preset_night_prayer': {'time': '22:30', 'freq': 'DAILY', 'day': ''},
      'preset_nafilah_fajr': {'time': '05:00', 'freq': 'DAILY', 'day': ''},
      'preset_nafilah_dhuhr': {'time': '12:00', 'freq': 'DAILY', 'day': ''},
      'preset_nafilah_asr': {'time': '15:30', 'freq': 'DAILY', 'day': ''},
      'preset_nafilah_maghrib': {'time': '19:30', 'freq': 'DAILY', 'day': ''},
      'preset_nafilah_isha': {'time': '20:30', 'freq': 'DAILY', 'day': ''},
      'preset_ziarat_ashura': {'time': '08:00', 'freq': 'DAILY', 'day': ''},
      'preset_dua_ahd': {'time': '07:00', 'freq': 'DAILY', 'day': ''},
      'preset_dua_kumayl': {'time': '20:00', 'freq': 'WEEKLY', 'day': 'Thursday'},
      'preset_dua_nudbah': {'time': '07:30', 'freq': 'WEEKLY', 'day': 'Friday'},
      'preset_jafar_tayyar': {'time': '10:00', 'freq': 'WEEKLY', 'day': 'Friday'},
    };
    return defaults[id] ?? {'time': '21:00', 'freq': 'DAILY', 'day': ''};
  }

  String _describeReminder(Map<String, dynamic> reminder) {
    final freq = reminder['freq'] == 'DAILY' ? 'هر روز' : 'هفتگی';
    final time = toPersianDigits(reminder['time'] as String);
    final day = reminder['day'] == 'Thursday' ? 'پنجشنبه‌ها' : (reminder['day'] == 'Friday' ? 'جمعه‌ها' : '');
    if (day.isNotEmpty) {
      return '$freq ($day) ساعت $time';
    }
    return '$freq ساعت $time';
  }

  void _showPresetReminderDialog(Map<String, dynamic> preset) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reminder = _getDefaultReminder(preset['id'] as String);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: RitmoTheme.glassCardLight(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.alarm_fill, color: Color(0xffD4A843), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'تنظیم یادآور مستحب',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'یادآور پیش‌فرض برای «${preset['title']}» به صورت زیر تنظیم شده است:',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textPrimary.withValues(alpha: 0.9),
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffD4A843).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _describeReminder(reminder),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffD4A843),
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffD4A843),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _togglePresetWithReminder(preset, true, true);
                      },
                      child: const Text(
                        'تایید و ثبت با یادآور پیش‌فرض',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                        final tempPractice = WorshipPractice(
                          id: preset['id'] as String,
                          practiceType: 'MUSTAHAB',
                          subType: preset['subType'] as String,
                          title: preset['title'] as String,
                          reminderEnabled: true,
                          reminderTime: reminder['time'] as String,
                          reminderFrequency: reminder['freq'] as String,
                          reminderDaysOfWeek: reminder['day'] as String,
                          notes: preset['notes'] as String?,
                          dailyDoneDate: todayStr,
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (sheetCtx) {
                            return WorshipReminderSettingsSheet(
                              practice: tempPractice,
                              onSaved: (updated) async {
                                await _togglePresetWithReminder(
                                  preset,
                                  true,
                                  updated.reminderEnabled == true,
                                  customTime: updated.reminderTime,
                                  customFreq: updated.reminderFrequency,
                                  customDay: updated.reminderDaysOfWeek,
                                );
                              },
                            );
                          },
                        );
                      },
                      child: const Text(
                        'ویرایش یادآور',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _togglePresetWithReminder(preset, true, false);
                      },
                      child: const Text(
                        'ثبت بدون یادآور',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text(
                        'انصراف',
                        style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePreset(Map<String, dynamic> preset, bool enable) async {
    await _togglePresetWithReminder(preset, enable, false);
  }

  Future<void> _togglePresetWithReminder(
    Map<String, dynamic> preset,
    bool enable,
    bool enableReminder, {
    String? customTime,
    String? customFreq,
    String? customDay,
  }) async {
    unawaited(HapticFeedback.lightImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final rDefaults = _getDefaultReminder(preset['id'] as String);

      if (enable) {
        // Upsert preset in DB
        await db.insert(
          'worship_practices',
          {
            'id': preset['id'],
            'practiceType': 'MUSTAHAB',
            'subType': preset['subType'],
            'title': preset['title'],
            'dailyTarget': 1,
            'dailyDone': 0,
            'reminderEnabled': enableReminder ? 1 : 0,
            'reminderTime': customTime ?? rDefaults['time'],
            'reminderFrequency': customFreq ?? rDefaults['freq'],
            'reminderDaysOfWeek': customDay ?? rDefaults['day'],
            'isActive': 1,
            'notes': preset['notes'],
            'dailyDoneDate': todayStr,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Mark inactive
        await db.update(
          'worship_practices',
          {
            'isActive': 0,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [preset['id']],
        );
      }

      await _loadPresets();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error toggling preset: $e');
    }
  }

  Future<void> _editPractice({WorshipPractice? practice, Map<String, dynamic>? preset}) async {
    WorshipPractice practiceToEdit;
    if (practice != null) {
      practiceToEdit = practice;
    } else {
      final db = await DatabaseHelper.instance.database;
      final existing = await db.query(
        'worship_practices',
        where: 'id = ?',
        whereArgs: [preset!['id']],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        practiceToEdit = WorshipPractice.fromMap(existing.first);
      } else {
        final reminder = preset['reminder'] as Map<String, dynamic>;
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        practiceToEdit = WorshipPractice(
          id: preset['id'] as String,
          practiceType: 'MUSTAHAB',
          subType: preset['subType'] as String,
          title: preset['title'] as String,
          reminderTime: reminder['time'] as String,
          reminderFrequency: reminder['freq'] as String,
          reminderDaysOfWeek: reminder['day'] as String,
          isActive: false,
          notes: preset['notes'] as String?,
          dailyDoneDate: todayStr,
          createdAt: nowMs,
          updatedAt: nowMs,
        );
      }
    }

    if (!mounted) return;

    unawaited(showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return AddCustomMustahabSheet(
          practice: practiceToEdit,
          onDelete: practice != null ? () => _deleteCustom(practice) : null,
          onSaved: () {
            _loadPresets();
            widget.onSaved();
          },
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مدیریت مستحبات و ادعیه',
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _buildPresetsTab(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsTab(RitmoColors colors) {
    if (_isLoadingPresets) {
      return Center(child: CircularProgressIndicator(color: colors.textPrimary));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (_customPractices.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'مستحبات سفارشی شما',
              style: TextStyle(
                color: isDark ? const Color(0xffD4A843) : colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          ..._customPractices.map((practice) {
            final isActive = practice.isActive == true;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff0b0b0e) : colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.border,
                ),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  practice.title,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
                subtitle: practice.notes != null && practice.notes!.isNotEmpty
                    ? Text(
                        practice.notes!,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12.5, fontFamily: 'Vazirmatn'),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(CupertinoIcons.settings, color: colors.textSecondary, size: 18),
                      onPressed: () => _editPractice(practice: practice),
                    ),
                    const SizedBox(width: 4),
                    CupertinoSwitch(
                      value: isActive,
                      activeTrackColor: const Color(0xffD4A843),
                      onChanged: (val) => _toggleCustomActive(practice, val),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(color: colors.border.withValues(alpha: 0.5)),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            'مستحبات پیش‌فرض',
            style: TextStyle(
              color: isDark ? const Color(0xffD4A843) : colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
        ..._presets.map((preset) {
          final isActive = preset['isActive'] as bool;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0b0b0e) : colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.border,
              ),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                preset['title'] as String,
                style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
              ),
              subtitle: Text(
                preset['notes'] as String,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5, fontFamily: 'Vazirmatn'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(CupertinoIcons.settings, color: colors.textSecondary, size: 18),
                    onPressed: () => _editPractice(preset: preset),
                  ),
                  const SizedBox(width: 4),
                  CupertinoSwitch(
                    value: isActive,
                    activeTrackColor: const Color(0xffD4A843),
                    onChanged: (val) {
                      if (val) {
                        _showPresetReminderDialog(preset);
                      } else {
                        _togglePreset(preset, false);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) {
                return AddCustomMustahabSheet(
                  onSaved: () {
                    _loadPresets();
                    widget.onSaved();
                  },
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0b0b0e) : colors.textSecondary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 18,
                  color: isDark ? const Color(0xffD4A843) : colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'اضافه کردن مستحبات سفارشی',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xffD4A843) : colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class AddCustomMustahabSheet extends StatefulWidget {

  const AddCustomMustahabSheet({super.key, 
    required this.onSaved,
    this.practice,
    this.onDelete,
  });
  final VoidCallback onSaved;
  final WorshipPractice? practice;
  final VoidCallback? onDelete;

  @override
  State<AddCustomMustahabSheet> createState() => _AddCustomMustahabSheetState();
}

class _AddCustomMustahabSheetState extends State<AddCustomMustahabSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  WorshipPractice? _tempPractice;

  @override
  void initState() {
    super.initState();
    if (widget.practice != null) {
      _titleController.text = widget.practice!.title;
      _notesController.text = widget.practice!.notes ?? '';
      _tempPractice = widget.practice;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustom() async {
    unawaited(HapticFeedback.mediumImpact());
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      RitmoSnackbar.warning(context, 'لطفاً عنوان مستحب را وارد کنید');
      return;
    }

    final isEdit = widget.practice != null;
    final notes = _notesController.text.trim().isEmpty 
        ? (isEdit && widget.practice!.subType == 'PRESET' ? '' : 'مستحب سفارشی') 
        : _notesController.text.trim();

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final id = isEdit ? widget.practice!.id : 'wp_custom_${nowMs}_${DateTime.now().microsecondsSinceEpoch}';

      final practice = _tempPractice ?? widget.practice ?? WorshipPractice(
        id: id,
        practiceType: 'MUSTAHAB',
        subType: 'CUSTOM',
        title: title,
        reminderTime: '21:00',
        dailyDoneDate: todayStr,
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      final p = practice.copyWith(
        id: id,
        title: title,
        notes: notes,
        dailyTarget: 1,
        updatedAt: nowMs,
        isActive: !isEdit || (widget.practice!.isActive),
      );

      if (isEdit) {
        await db.insert(
          'worship_practices',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await db.insert(
          'worship_practices',
          p.toMap(),
        );
      }

      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        RitmoSnackbar.success(
          context,
          isEdit ? 'تغییرات با موفقیت ذخیره شد ✨' : 'مستحب سفارشی با موفقیت اضافه شد ✨',
        );
      }
    } catch (e) {
      debugPrint('Error saving mustahab: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.practice != null ? 'ویرایش مستحب سفارشی' : 'افزودن مستحب سفارشی',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title field
              Text(
                'عنوان مستحب یا دعا:',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontFamily: 'Vazirmatn'),
                decoration: InputDecoration(
                  hintText: 'مثلا: دعای توسل، نماز باران...',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.4), fontSize: 13),
                  fillColor: isDark ? const Color(0xff0b0b0e) : colors.textSecondary.withValues(alpha: 0.02),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.textSecondary.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xffD4A843), width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description/Notes field
              Text(
                'توضیحات کوتاه:',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontFamily: 'Vazirmatn'),
                decoration: InputDecoration(
                  hintText: 'مثلا: سه شنبه شب ها، هدیه به اموات...',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.4), fontSize: 13),
                  fillColor: isDark ? const Color(0xff0b0b0e) : colors.textSecondary.withValues(alpha: 0.02),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.textSecondary.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xffD4A843), width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add / Edit Reminder Area
              if (_tempPractice?.reminderEnabled ?? false) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffD4A843).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffD4A843).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.alarm_fill, color: Color(0xffD4A843), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'یادآوری فعال است ⏰',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffD4A843),
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'تناوب: ${_tempPractice!.reminderFrequency == "DAILY" ? "روزانه" : _tempPractice!.reminderFrequency == "WEEKLY" ? "هفتگی" : _tempPractice!.reminderFrequency}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textPrimary.withValues(alpha: 0.7),
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: colors.medicalRed,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: colors.medicalRed.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              unawaited(HapticFeedback.vibrate());
                              setState(() {
                                if (_tempPractice != null) {
                                  _tempPractice = _tempPractice!.copyWith(reminderEnabled: false);
                                }
                              });
                              RitmoSnackbar.success(context, 'یادآور با موفقیت حذف شد 🗑️');
                            },
                            icon: const Icon(CupertinoIcons.trash, size: 14),
                            label: const Text(
                              'حذف',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xffD4A843),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: colors.textSecondary.withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) {
                                  return WorshipReminderSettingsSheet(
                                    practice: _tempPractice!,
                                    onSaved: (updated) {
                                      setState(() {
                                        _tempPractice = updated;
                                      });
                                    },
                                  );
                                },
                              );
                            },
                            icon: const Icon(CupertinoIcons.pencil, size: 14),
                            label: const Text(
                              'ویرایش',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final p = _tempPractice ?? WorshipPractice(
                      id: '',
                      practiceType: 'MUSTAHAB',
                      subType: 'CUSTOM',
                      title: _titleController.text.isEmpty ? 'مستحب' : _titleController.text,
                      reminderTime: '21:00',
                      dailyDoneDate: '',
                      createdAt: 0,
                      updatedAt: 0,
                    );
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) {
                        return WorshipReminderSettingsSheet(
                          practice: p,
                          onSaved: (updated) {
                            setState(() {
                              _tempPractice = updated;
                            });
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff0b0b0e) : colors.textSecondary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xffD4A843).withValues(alpha: 0.15) : colors.textSecondary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.bell_fill,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'افزودن یادآور',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              if (widget.onDelete != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.medicalRed,
                          side: BorderSide(color: colors.medicalRed.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDelete!();
                        },
                        child: const Text(
                          'حذف مستحب',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffD4A843),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saveCustom,
                        child: const Text(
                          'ثبت تغییرات',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffD4A843),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveCustom,
                  child: Text(
                    widget.practice != null ? 'ثبت تغییرات' : 'ثبت و افزودن مستحب',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



