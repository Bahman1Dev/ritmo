import 'dart:async';

import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';

class PregnancySection extends StatefulWidget {
  const PregnancySection({
    super.key,
  });

  @override
  State<PregnancySection> createState() => _PregnancySectionState();
}

class _PregnancySectionState extends State<PregnancySection> with TickerProviderStateMixin {
  late TabController _tabController;

  // Configuration flags
  bool _isVisible = false;
  bool _isLoading = true;

  // Active tracker details
  Map<String, dynamic>? _activeTracker;
  List<Map<String, dynamic>> _checkups = [];
  List<Map<String, dynamic>> _kickLogs = [];
  List<Map<String, dynamic>> _contractionLogs = [];

  // Form selections
  DateTime _selectedLmp = DateTime.now().subtract(const Duration(days: 30));

  // Kick Counter State
  bool _isCountingKicks = false;
  int _currentKickCount = 0;
  int? _kickSessionStart;
  Timer? _kickTimer;
  int _kickElapsedSeconds = 0;

  // Contraction State
  bool _isTimingContraction = false;
  int? _contractionStart;
  int _currentContractionDuration = 0;
  Timer? _contractionTimer;

  // Symptoms Selection
  final Map<String, bool> _selectedSymptoms = {
    'NAUSEA': false,
    'HEADACHE': false,
    'SWELLING': false,
    'HEARTBURN': false,
    'BACKACHE': false,
    'FATIGUE': false,
  };
  String _symptomSeverity = 'MILD';
  final Map<String, bool> _selectedSupplements = {
    'IRON': false,
    'FOLIC_ACID': false,
    'VITAMIN_D': false,
    'CALCIUM': false,
    'MULTIVITAMIN': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkVisibilityAndLoad();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kickTimer?.cancel();
    _contractionTimer?.cancel();
    super.dispose();
  }



  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  String _formatJalaliDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final j = Jalali.fromDateTime(dt);
    return _toPersianDigits('${j.year}/${j.month}/${j.day}');
  }

  Future<void> _checkVisibilityAndLoad() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Query settings to check eligibility
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      
      final pregnancyEnabled = settingsMap['module_pregnancy_enabled'] == 'true';
      final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
      final shouldShow = isFemale && pregnancyEnabled;

      if (!mounted) return;
      
      if (!shouldShow) {
        setState(() {
          _isVisible = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isVisible = true;
      });

      // Load active pregnancy tracker
      final trackers = await db.query('pregnancy_tracker', where: 'isActive = 1', limit: 1);
      
      if (trackers.isNotEmpty) {
        final tracker = trackers.first;
        final trackerId = tracker['id']! as String;

        // Recalculate weeks dynamically based on current date and lmp
        final lmpStr = tracker['lmpDate']! as String;
        final lmpDate = DateTime.parse(lmpStr);
        final diffDays = DateTime.now().difference(lmpDate).inDays;
        final currentWeek = (diffDays / 7).floor() + 1;
        
        var trimester = 1;
        if (currentWeek >= 27) {
          trimester = 3;
        } else if (currentWeek >= 13) {
          trimester = 2;
        }

        // Update current week/trimester in DB
        await db.update(
          'pregnancy_tracker',
          {
            'currentWeek': currentWeek,
            'currentTrimester': trimester,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [trackerId],
        );

        // Fetch checkups, kick counts, and contraction logs
        final checkupsRes = await db.query('pregnancy_checkups', where: 'pregnancyId = ?', whereArgs: [trackerId]);
        final kickRes = await db.query('kick_counts', where: 'pregnancyId = ?', whereArgs: [trackerId], orderBy: 'loggedAt DESC');
        final contractionRes = await db.query('contraction_timer', where: 'pregnancyId = ?', whereArgs: [trackerId], orderBy: 'loggedAt DESC');

        if (mounted) {
          setState(() {
            _activeTracker = {
              ...tracker,
              'currentWeek': currentWeek,
              'currentTrimester': trimester,
            };
            _checkups = checkupsRes;
            _kickLogs = kickRes;
            _contractionLogs = contractionRes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeTracker = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading pregnancy tracker: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _startTracker() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final trackerId = 'preg_${DateTime.now().millisecondsSinceEpoch}';
      
      final lmpStr = _selectedLmp.toIso8601String().substring(0, 10);
      final eddDate = _selectedLmp.add(const Duration(days: 280));
      final eddStr = eddDate.toIso8601String().substring(0, 10);
      
      final diffDays = DateTime.now().difference(_selectedLmp).inDays;
      final currentWeek = (diffDays / 7).floor() + 1;
      
      var trimester = 1;
      if (currentWeek >= 27) {
        trimester = 3;
      } else if (currentWeek >= 13) {
        trimester = 2;
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert active pregnancy tracker
      await db.insert('pregnancy_tracker', {
        'id': trackerId,
        'lmpDate': lmpStr,
        'estimatedDueDate': eddStr,
        'currentWeek': currentWeek,
        'currentTrimester': trimester,
        'isActive': 1,
        'notes': '',
        'createdAt': now,
        'updatedAt': now,
      });

      // 2. Seed national screening checkups (standard checks in Iran)
      final checkupTemplates = [
        {'title': 'مراقبت اول: هفته ۶ تا ۱۰ (تایید بارداری، آزمایشات اولیه و سونوی قلب)', 'type': 'SCREENING', 'week': 6},
        {'title': 'مراقبت دوم: هفته ۱۱ تا ۱۳ (غربالگری مرحله اول - NT و آزمایش خون)', 'type': 'SCREENING', 'week': 11},
        {'title': 'مراقبت سوم: هفته ۱۵ تا ۲۰ (غربالگری مرحله دوم - آنومالی اسکن)', 'type': 'SCREENING', 'week': 15},
        {'title': 'مراقبت چهارم: هفته ۲۴ تا ۲۸ (تست گلوکز GTT و تزریق روگام در صورت نیاز)', 'type': 'SCREENING', 'week': 24},
        {'title': 'مراقبت پنجم: هفته ۲۸ تا ۳۲ (سونوگرافی کنترل رشد و وزن جنین)', 'type': 'SCREENING', 'week': 28},
        {'title': 'مراقبت ششم: هفته ۳۵ تا ۳۷ (تست استرپتوکوک گروه B)', 'type': 'SCREENING', 'week': 35},
        {'title': 'مراقبت هفتم: هفته ۳۸ مراقبت هفتگی تا زایمان (NST و بررسی فشار خون)', 'type': 'SCREENING', 'week': 38},
      ];

      for (final temp in checkupTemplates) {
        final checkupDate = _selectedLmp.add(Duration(days: (temp['week']! as int) * 7)).millisecondsSinceEpoch;
        await db.insert('pregnancy_checkups', {
          'id': 'chk_${trackerId}_${temp['week']}',
          'pregnancyId': trackerId,
          'title': temp['title']! as String,
          'scheduledDate': checkupDate,
          'type': temp['type']! as String,
          'isCompleted': 0,
          'createdAt': now,
        });
      }

      await _checkVisibilityAndLoad();
    } catch (e) {
      debugPrint('Error starting pregnancy tracker: $e');
    }
  }

  Future<void> _endTracker() async {
    if (_activeTracker == null) return;
    final trackerId = _activeTracker!['id'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: context.colors.card,
          title: const Text('پایان دوره بارداری', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          content: const Text('آیا مطمئن هستید که می‌خواهید پایش دوره بارداری فعلی را پایان دهید؟ اطلاعات آرشیو خواهند شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.medicalRed),
              child: const Text('تایید و پایان', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'pregnancy_tracker',
        {
          'isActive': 0,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [trackerId],
      );
      await _checkVisibilityAndLoad();
    } catch (e) {
      debugPrint('Error ending pregnancy tracker: $e');
    }
  }

  Future<void> _toggleCheckup(String id, bool completed) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'pregnancy_checkups',
        {
          'isCompleted': completed ? 1 : 0,
          'actualDate': completed ? DateTime.now().millisecondsSinceEpoch : null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await _checkVisibilityAndLoad();
    } catch (e) {
      debugPrint('Error toggling checkup: $e');
    }
  }

  // Kick Counter functions
  void _startKickSession() {
    setState(() {
      _isCountingKicks = true;
      _currentKickCount = 0;
      _kickSessionStart = DateTime.now().millisecondsSinceEpoch;
      _kickElapsedSeconds = 0;
    });

    _kickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _kickElapsedSeconds = (DateTime.now().millisecondsSinceEpoch - _kickSessionStart!) ~/ 1000;
        });
      }
    });
  }

  void _recordKick() {
    if (!_isCountingKicks) return;
    setState(() {
      _currentKickCount++;
    });
  }

  Future<void> _saveKickSession() async {
    _kickTimer?.cancel();
    if (_activeTracker == null || _kickSessionStart == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('kick_counts', {
        'id': 'kick_$now',
        'pregnancyId': _activeTracker!['id'] as String,
        'startTime': _kickSessionStart,
        'endTime': now,
        'kickCount': _currentKickCount,
        'loggedAt': now,
      });

      setState(() {
        _isCountingKicks = false;
        _kickSessionStart = null;
      });
      await _checkVisibilityAndLoad();
    } catch (e) {
      debugPrint('Error saving kick session: $e');
    }
  }

  // Contraction Timer functions
  void _toggleContractionTimer() {
    if (!_isTimingContraction) {
      // Start Timing
      setState(() {
        _isTimingContraction = true;
        _contractionStart = DateTime.now().millisecondsSinceEpoch;
        _currentContractionDuration = 0;
      });

      _contractionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _currentContractionDuration = (DateTime.now().millisecondsSinceEpoch - _contractionStart!) ~/ 1000;
          });
        }
      });
    } else {
      // Stop Timing
      _contractionTimer?.cancel();
      _saveContraction();
    }
  }

  Future<void> _saveContraction() async {
    if (_activeTracker == null || _contractionStart == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final durationSecs = (now - _contractionStart!) ~/ 1000;

    // Calculate interval from the start of the previous contraction
    var intervalSecs = 0;
    if (_contractionLogs.isNotEmpty) {
      final prevStart = _contractionLogs.first['startTime'] as int;
      intervalSecs = (_contractionStart! - prevStart) ~/ 1000;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('contraction_timer', {
        'id': 'contract_$now',
        'pregnancyId': _activeTracker!['id'] as String,
        'startTime': _contractionStart,
        'endTime': now,
        'durationSeconds': durationSecs,
        'intervalFromPrevious': intervalSecs,
        'loggedAt': now,
      });

      setState(() {
        _isTimingContraction = false;
        _contractionStart = null;
      });
      await _checkVisibilityAndLoad();
    } catch (e) {
      debugPrint('Error saving contraction: $e');
    }
  }

  bool _check511LaborAlert() {
    // 5-1-1 Rule: Contractions are:
    // - Every 5 minutes or less (intervalFromPrevious <= 300 seconds)
    // - Lasting at least 1 minute (durationSeconds >= 60 seconds)
    // - Repeating consistently for 1 hour (loggedAt >= 1 hour ago)
    if (_contractionLogs.length < 3) return false;

    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
    final recent = _contractionLogs.where((c) => c['loggedAt'] as int >= oneHourAgo).toList();

    if (recent.length < 3) return false;

    // Verify if all recent contractions in the last hour match the duration and frequency criteria
    var matches511 = true;
    for (var i = 0; i < recent.length; i++) {
      final duration = recent[i]['durationSeconds'] as int;
      final interval = recent[i]['intervalFromPrevious'] as int;

      if (duration < 60) matches511 = false;
      // Skip the last item since it might not have a valid previous interval
      if (i < recent.length - 1 && (interval > 300 || interval == 0)) matches511 = false;
    }

    return matches511;
  }

  // Daily Symptoms and Supplements Logging
  Future<void> _saveSymptomsAndSupplements() async {
    if (_activeTracker == null) return;
    final trackerId = _activeTracker!['id'] as String;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now().millisecondsSinceEpoch;

    final activeSymptoms = <String>[];
    _selectedSymptoms.forEach((k, v) {
      if (v) activeSymptoms.add(k);
    });

    final activeSupps = <String>[];
    _selectedSupplements.forEach((k, v) {
      if (v) activeSupps.add(k);
    });

    try {
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // Log symptoms
        for (final sym in activeSymptoms) {
          final symId = 'sym_${trackerId}_${sym}_$now';
          await txn.insert('pregnancy_symptoms', {
            'id': symId,
            'pregnancyId': trackerId,
            'date': todayStr,
            'symptom': sym,
            'severity': _symptomSeverity,
            'note': 'مکمل‌ها: ${activeSupps.join(", ")}',
          });
        }
      });

      // Reset form selections
      setState(() {
        _selectedSymptoms.updateAll((k, v) => false);
        _selectedSupplements.updateAll((k, v) => false);
        _symptomSeverity = 'MILD';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('علائم و مکمل‌های روز با موفقیت ثبت شدند.', style: TextStyle(fontFamily: 'Vazirmatn'))),
      );

      await _checkVisibilityAndLoad();
    } catch (e) {
      debugPrint('Error saving symptoms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }



    final colors = context.colors;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'مراقبت بارداری',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_activeTracker != null)
                TextButton.icon(
                  onPressed: _endTracker,
                  icon: Icon(Icons.power_settings_new, color: colors.medicalRed, size: 16),
                  label: Text('پایان بارداری', style: TextStyle(color: colors.medicalRed, fontSize: 12, fontFamily: 'Vazirmatn')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activeTracker == null)
            _buildSetupView()
          else ...[
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: colors.primary,
              labelColor: colors.textPrimary,
              unselectedLabelColor: colors.textSecondary,
              tabs: const [
                Tab(text: 'هفته‌شمار'),
                Tab(text: 'معاینات کشوری'),
                Tab(text: 'حرکات جنین'),
                Tab(text: 'انقباضات'),
                Tab(text: 'علائم روزانه'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWeekTrackerTab(),
                  _buildCheckupsTab(),
                  _buildKickCounterTab(),
                  _buildContractionTimerTab(),
                  _buildSymptomsTab(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    final colors = context.colors;
    final jalaliLmp = Jalali.fromDateTime(_selectedLmp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'پایش و مدیریت بارداری فعال نیست. برای شروع، لطفاً تاریخ اولین روز آخرین قاعدگی خود (LMP) را انتخاب کنید:',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await RitmoDatePicker.showJalali(
                  context: context,
                  initialDate: Jalali.fromDateTime(_selectedLmp),
                  firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 280))),
                  lastDate: Jalali.fromDateTime(DateTime.now()),
                );
                if (picked != null) {
                  setState(() {
                    _selectedLmp = picked.toDateTime();
                  });
                }
              },
              icon: Icon(Icons.calendar_month, color: colors.primary),
              label: Text(
                _toPersianDigits('LMP: ${jalaliLmp.year}/${jalaliLmp.month}/${jalaliLmp.day}'),
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startTracker,
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: const Text('شروع پایش بارداری', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );
  }

  // Sub-tab 1: Week Tracker
  Widget _buildWeekTrackerTab() {
    final colors = context.colors;
    final week = _activeTracker!['currentWeek'] as int;
    final eddStr = _activeTracker!['estimatedDueDate'] as String;
    final eddDate = DateTime.parse(eddStr);
    final lmpStr = _activeTracker!['lmpDate'] as String;
    final lmpDate = DateTime.parse(lmpStr);
    final totalDays = DateTime.now().difference(lmpDate).inDays;
    final day = totalDays % 7;
    
    final progress = (totalDays / 280.0).clamp(0.0, 1.0);
    final eddJalali = Jalali.fromDateTime(eddDate);
    final eddStrJalali = _toPersianDigits('${eddJalali.year}/${eddJalali.month}/${eddJalali.day}');

    var trimesterText = 'سه ماهه اول';
    final tri = _activeTracker!['currentTrimester'] as int;
    if (tri == 2) trimesterText = 'سه ماهه دوم';
    if (tri == 3) trimesterText = 'سه ماهه سوم';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _toPersianDigits('هفته $week بارداری (روز $day)'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trimesterText,
                    style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              color: colors.primary,
              backgroundColor: colors.border,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('پیشرفت بارداری:', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                Text(_toPersianDigits('${(progress * 100).toStringAsFixed(0)}٪'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.event, color: colors.primary),
                const SizedBox(width: 10),
                Text('تاریخ تخمینی زایمان (EDD):', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                const SizedBox(width: 8),
                Text(eddStrJalali, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, color: colors.textSecondary),
                const SizedBox(width: 10),
                Text('تاریخ آخرین قاعدگی (LMP):', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                const SizedBox(width: 8),
                Text(_formatJalaliDate(lmpDate.millisecondsSinceEpoch), style: TextStyle(fontSize: 14, color: colors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sub-tab 2: Checkups
  Widget _buildCheckupsTab() {
    final colors = context.colors;

    if (_checkups.isEmpty) {
      return Center(
        child: Text('هیچ مراقبتی تعریف نشده است.', style: TextStyle(color: colors.textSecondary)),
      );
    }

    return ListView.builder(
      itemCount: _checkups.length,
      itemBuilder: (context, index) {
        final chk = _checkups[index];
        final completed = chk['isCompleted'] == 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            title: Text(
              chk['title'] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: completed ? FontWeight.normal : FontWeight.bold,
                color: completed ? colors.textSecondary : colors.textPrimary,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: chk['actualDate'] != null
                ? Text('انجام شده در: ${_formatJalaliDate(chk['actualDate'] as int)}', style: const TextStyle(fontSize: 11))
                : Text('تاریخ تقریبی سررسید: ${_formatJalaliDate(chk['scheduledDate'] as int)}', style: const TextStyle(fontSize: 11)),
            value: completed,
            activeColor: colors.success,
            onChanged: (val) {
              if (val != null) {
                _toggleCheckup(chk['id'] as String, val);
              }
            },
          ),
        );
      },
    );
  }

  // Sub-tab 3: Kick Counter
  Widget _buildKickCounterTab() {
    final colors = context.colors;
    final mins = _kickElapsedSeconds ~/ 60;
    final secs = _kickElapsedSeconds % 60;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Active counter card
          Card(
            color: _isCountingKicks ? colors.primary.withValues(alpha: 0.08) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_isCountingKicks) ...[
                    const Text('پایش حرکات جنین به مدت ۱ ساعت به ارزیابی سلامت جنین کمک می‌کند.', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _startKickSession,
                      style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
                      child: const Text('شروع شمارش حرکات جنین', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
                    ),
                  ] else ...[
                    Text(
                      _toPersianDigits('${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _toPersianDigits('حرکات شمرده شده: $_currentKickCount'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _recordKick,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('ثبت حرکت / لگد', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
                          style: ElevatedButton.styleFrom(backgroundColor: colors.success),
                        ),
                        OutlinedButton(
                          onPressed: _saveKickSession,
                          child: const Text('پایان و ذخیره', style: TextStyle(fontFamily: 'Vazirmatn')),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // History
          const Align(
            alignment: Alignment.centerRight,
            child: Text('سوابق شمارش حرکات جنین:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          if (_kickLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('سابقه‌ای ثبت نشده است.', style: TextStyle(color: colors.textSecondary)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _kickLogs.length.clamp(0, 3),
              itemBuilder: (context, index) {
                final log = _kickLogs[index];
                final count = log['kickCount'] as int;
                final date = _formatJalaliDate(log['loggedAt'] as int);
                final durationSecs = ((log['endTime'] as int) - (log['startTime'] as int)) ~/ 1000;
                final durationMins = durationSecs ~/ 60;

                // Standard warning: if kicks are less than 10, highlight
                final isLow = count < 10;

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: isLow ? colors.warning : colors.success,
                    ),
                    title: Text(
                      _toPersianDigits('$count حرکت در $durationMins دقیقه'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text('تاریخ ثبت: $date', style: const TextStyle(fontSize: 11)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Sub-tab 4: Contraction Timer
  Widget _buildContractionTimerTab() {
    final colors = context.colors;
    final is511Labor = _check511LaborAlert();

    return SingleChildScrollView(
      child: Column(
        children: [
          // 5-1-1 Emergency Banner
          if (is511Labor) ...[
            Card(
              color: colors.medicalRed.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.medicalRed, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: colors.medicalRed, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ هشدار ۵-۱-۱: انقباضات شما منظم شده و هر ۵ دقیقه یا کمتر تکرار می‌شوند. فاز زایمان فعال است! لطفاً سریعاً با پزشک خود یا بیمارستان تماس بگیرید.',
                        style: TextStyle(
                          color: colors.medicalRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Active contraction timer
          Card(
            color: _isTimingContraction ? colors.medicalRed.withValues(alpha: 0.08) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isTimingContraction) ...[
                    Text(
                      _toPersianDigits('مدت انقباض: $_currentContractionDuration ثانیه'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.medicalRed),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _toggleContractionTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTimingContraction ? colors.medicalRed : colors.primary,
                    ),
                    child: Text(
                      _isTimingContraction ? 'پایان انقباض' : 'شروع انقباض',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // History
          const Align(
            alignment: Alignment.centerRight,
            child: Text('آخرین انقباضات ثبت شده:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          if (_contractionLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('انقباضی ثبت نشده است.', style: TextStyle(color: colors.textSecondary)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _contractionLogs.length.clamp(0, 3),
              itemBuilder: (context, index) {
                final log = _contractionLogs[index];
                final duration = log['durationSeconds'] as int;
                final interval = log['intervalFromPrevious'] as int;
                final date = _formatJalaliDate(log['loggedAt'] as int);

                final intervalStr = interval > 0 ? 'فاصله از قبلی: ${interval ~/ 60} دقیقه' : 'اولین انقباض';

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Icon(Icons.timer_outlined, color: colors.medicalRed),
                    title: Text(
                      _toPersianDigits('مدت: $duration ثانیه · $intervalStr'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text('ثبت: $date', style: const TextStyle(fontSize: 11)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Sub-tab 5: Symptoms and Supplements Log
  Widget _buildSymptomsTab() {
    final colors = context.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Symptoms Selector
          const Text('علائم امروز:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildSymptomChip('NAUSEA', 'تهوع'),
              _buildSymptomChip('HEADACHE', 'سردرد'),
              _buildSymptomChip('SWELLING', 'تورم بدن'),
              _buildSymptomChip('HEARTBURN', 'سوزش معده'),
              _buildSymptomChip('BACKACHE', 'کمردرد'),
              _buildSymptomChip('FATIGUE', 'خستگی شدید'),
            ],
          ),
          const SizedBox(height: 12),
          // Severity
          Row(
            children: [
              const Text('شدت علائم: ', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _symptomSeverity,
                dropdownColor: colors.card,
                items: const [
                  DropdownMenuItem(value: 'MILD', child: Text('خفیف', style: TextStyle(fontFamily: 'Vazirmatn'))),
                  DropdownMenuItem(value: 'MODERATE', child: Text('متوسط', style: TextStyle(fontFamily: 'Vazirmatn'))),
                  DropdownMenuItem(value: 'SEVERE', child: Text('شدید', style: TextStyle(fontFamily: 'Vazirmatn'))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _symptomSeverity = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Supplements
          const Text('مکمل‌های مصرفی امروز:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildSupplementChip('IRON', 'آهن'),
              _buildSupplementChip('FOLIC_ACID', 'اسید فولیک'),
              _buildSupplementChip('VITAMIN_D', 'ویتامین D'),
              _buildSupplementChip('CALCIUM', 'کلسیم'),
              _buildSupplementChip('MULTIVITAMIN', 'مولتی‌ویتامین'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveSymptomsAndSupplements,
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            child: const Text('ثبت علائم و مکمل‌های امروز', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomChip(String key, String label) {
    final colors = context.colors;
    final isSelected = _selectedSymptoms[key] ?? false;

    return FilterChip(
      label: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: isSelected ? Colors.white : colors.textPrimary)),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.card,
      onSelected: (val) {
        setState(() {
          _selectedSymptoms[key] = val;
        });
      },
    );
  }

  Widget _buildSupplementChip(String key, String label) {
    final colors = context.colors;
    final isSelected = _selectedSupplements[key] ?? false;

    return FilterChip(
      label: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: isSelected ? Colors.white : colors.textPrimary)),
      selected: isSelected,
      selectedColor: colors.success,
      backgroundColor: colors.card,
      onSelected: (val) {
        setState(() {
          _selectedSupplements[key] = val;
        });
      },
    );
  }
}
