import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/medical_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/health/presentation/widgets/medication_form_sheet.dart';

class MedicationsSection extends StatefulWidget {
  const MedicationsSection({
    super.key,
  });

  @override
  State<MedicationsSection> createState() => _MedicationsSectionState();
}

class _MedicationsSectionState extends State<MedicationsSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;

  List<Map<String, dynamic>> _medicationRoutines = [];
  List<Map<String, dynamic>> _occurrencesToday = [];
  List<Map<String, dynamic>> _historyItems = [];
  List<Map<String, dynamic>> _archivedRoutines = [];
  Map<String, List<int>> _prnLogs24hMap = {};
  List<Map<String, dynamic>> _medicationLogsToday = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _tabController.addListener(() {
      if (_tabController.index == 2) {
        _loadHistory();
      }
    });

    // Refresh timers periodically to update PRN live countdowns
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _tabController.index == 0) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // Load all active medical routines
      final routines = await db.query(
        'routines',
        where: "category = 'medical' AND isArchived = 0",
      );

      // Load today's occurrences
      final occurrences = await db.query(
        'routine_occurrences',
        where: 'date = ?',
        whereArgs: [todayStr],
      );

      // Load today's medication logs
      final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;
      final medLogs = await db.query(
        'medication_logs',
        where: 'createdAt >= ?',
        whereArgs: [startOfDay],
      );

      // Load PRN logs in the last 24 hours for all medical routines
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneDayAgo = now - (24 * 60 * 60 * 1000);
      final prnLogs = await db.query(
        'prn_logs',
        where: 'takenAt >= ?',
        whereArgs: [oneDayAgo],
      );

      final prnMap = <String, List<int>>{};
      for (final log in prnLogs) {
        final rId = log['routineId']! as String;
        final takenAt = log['takenAt']! as int;
        prnMap.putIfAbsent(rId, () => []).add(takenAt);
      }

      if (mounted) {
        setState(() {
          _medicationRoutines = routines;
          _occurrencesToday = occurrences;
          _prnLogs24hMap = prnMap;
          _medicationLogsToday = medLogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final archived = await db.query(
        'routines',
        where: "category = 'medical' AND isArchived = 1",
      );

      final prnHistory = await db.rawQuery('''
        SELECT p.takenAt as timestamp, r.title, r.description as dosage, 'PRN' as type
        FROM prn_logs p
        JOIN routines r ON p.routineId = r.id
        ORDER BY p.takenAt DESC
        LIMIT 100
      ''');

      final scheduledHistory = await db.rawQuery('''
        SELECT c.completionTime as timestamp, r.title, r.description as dosage, 'SCHEDULED' as type
        FROM routine_completions c
        JOIN routines r ON c.routineId = r.id
        WHERE r.category = 'medical'
        ORDER BY c.completionTime DESC
        LIMIT 100
      ''');

      final merged = [...prnHistory, ...scheduledHistory];
      merged.sort((a, b) => (b['timestamp']! as int).compareTo(a['timestamp']! as int));

      if (mounted) {
        setState(() {
          _archivedRoutines = archived;
          _historyItems = merged.take(100).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }



  int getScheduledDateTime(String? timeStr) {
    final now = DateTime.now();
    if (timeStr == null || timeStr.isEmpty) {
      return DateTime(now.year, now.month, now.day, 8).millisecondsSinceEpoch;
    }
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(now.year, now.month, now.day, hour, minute).millisecondsSinceEpoch;
    } catch (e) {
      return DateTime(now.year, now.month, now.day, 8).millisecondsSinceEpoch;
    }
  }

  Future<void> _logScheduledMed(Map<String, dynamic> routine, String status) async {
    final colors = context.colors;
    final rId = routine['id'] as String;
    final title = routine['title'] as String;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Get timeLabel from occurrence to calculate scheduled time
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final occ = _occurrencesToday.firstWhere((o) => o['routine_id'] == rId, orElse: () => {});
    final timeStr = occ.isNotEmpty ? occ['scheduled_time'] as String? : null;
    final scheduledTime = getScheduledDateTime(timeStr);

    // Confirm dialog
    final actionText = status == 'TAKEN' ? 'مصرف' : 'رد کردن';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          title: Text('$actionText دارو', style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          content: Text('آیا $actionText دارو «$title» را تایید می‌کنید؟', style: const TextStyle(fontFamily: 'Vazirmatn')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: status == 'TAKEN' ? colors.primary : colors.textSecondary),
              child: const Text('تایید', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Insert to medication_logs
      await db.insert('medication_logs', {
        'id': 'medlog_${rId}_$now',
        'routineId': rId,
        'scheduledTime': scheduledTime,
        'takenTime': status == 'TAKEN' ? now : null,
        'status': status,
        'note': null,
        'createdAt': now,
      });

      // 2. Decrement stock count ONLY if status is TAKEN
      if (status == 'TAKEN') {
        final currentStock = routine['medStockCount'] as int? ?? 0;
        if (currentStock > 0) {
          await db.update(
            'routines',
            {'medStockCount': currentStock - 1},
            where: 'id = ?',
            whereArgs: [rId],
          );
        }
      }

      // 3. Complete/Skip occurrence
      await RitmoExecutionKernel.instance.execute(
        CompleteOccurrenceCommand(
          routineId: rId,
          dateStr: todayStr,
          resultType: status == 'TAKEN' ? 'FULL' : 'SKIPPED',
          durationMinutes: routine['targetDurationMinutes'] as int? ?? 5,
        ),
      );

      // Emit event
      RitmoEventBus().fire(RitmoEvent(
        type: status == 'TAKEN' ? 'medication_consumed' : 'medication_skipped',
        timestamp: DateTime.now(),
        payload: {'routineId': rId, 'takenAt': now},
      ));
      RitmoEvents.notifyRoutineChanged();

      await _loadData();
      if (_tabController.index == 2) {
        await _loadHistory();
      }
    } catch (e) {
      debugPrint('Error logging scheduled medication: $e');
    }
  }

  Future<void> _consumeMedication(Map<String, dynamic> routine) async {
    final colors = context.colors;
    final rId = routine['id'] as String;
    final title = routine['title'] as String;
    final dosage = routine['description'] as String? ?? '';
    final isPrn = routine['routineType'] == 'asNeeded';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Double check overdose if PRN
    if (isPrn) {
      final prnLogs = _prnLogs24hMap[rId] ?? [];
      final minInterval = routine['minIntervalHours'] as int? ?? 0;
      final maxDoses = routine['maxDosesPerDay'] as int? ?? 0;

      final check = MedicalEngine.checkOverdoseStatus(
        now: now,
        prnLogs24h: prnLogs,
        minIntervalHours: minInterval,
        maxDosesPerDay: maxDoses,
      );

      if (check != OverdoseResult.safe) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('امکان مصرف دارو به علت ریسک اوردوز وجود ندارد.', style: TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: colors.medicalRed,
          ),
        );
        return;
      }
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          title: const Text('ثبت مصرف دارو', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          content: Text('آیا مصرف دارو «$title» را تایید می‌کنید؟', style: const TextStyle(fontFamily: 'Vazirmatn')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: const Text('تایید', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final db = await DatabaseHelper.instance.database;

      if (isPrn) {
        // Insert into prn_logs
        await db.insert('prn_logs', {
          'id': 'prn_${rId}_$now',
          'routineId': rId,
          'takenAt': now,
          'dosage': dosage,
          'createdAt': now,
        });

        // Decrement stock count
        final currentStock = routine['medStockCount'] as int? ?? 0;
        if (currentStock > 0) {
          await db.update(
            'routines',
            {'medStockCount': currentStock - 1},
            where: 'id = ?',
            whereArgs: [rId],
          );
        }
      } else {
        // Scheduled: Complete via command
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        await RitmoExecutionKernel.instance.execute(
          CompleteOccurrenceCommand(
            routineId: rId,
            dateStr: todayStr,
            resultType: 'FULL',
            durationMinutes: routine['targetDurationMinutes'] as int? ?? 5,
          ),
        );
      }

      // Emit event
      RitmoEventBus().fire(RitmoEvent(
        type: 'medication_consumed',
        timestamp: DateTime.now(),
        payload: {'routineId': rId, 'takenAt': now},
      ));
      RitmoEvents.notifyRoutineChanged();

      await _loadData();
      if (_tabController.index == 2) {
        await _loadHistory();
      }
    } catch (e) {
      debugPrint('Error consuming medication: $e');
    }
  }

  Future<void> _archiveMedication(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'routines',
        {'isArchived': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      RitmoEvents.notifyRoutineChanged();
      await _loadData();
    } catch (e) {
      debugPrint('Error archiving: $e');
    }
  }

  Future<void> _restoreMedication(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.query('routines', columns: ['title'], where: 'id = ?', whereArgs: [id]);
      final title = res.isNotEmpty ? res.first['title']! as String : '';

      await db.update(
        'routines',
        {'isArchived': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      RitmoEvents.notifyRoutineChanged();
      await _loadData();
      await _loadHistory();

      if (mounted && title.isNotEmpty) {
        RitmoToast.show(
          context,
          'داروی "$title" مجدداً فعال شد.',
          icon: Icons.unarchive_rounded,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error restoring medication: $e');
    }
  }

  Future<void> _deleteMedication(String id) async {
    try {
      await RitmoExecutionKernel.instance.execute(
        DeleteRoutineCommand(routineId: id),
      );

      RitmoEventBus().fire(RitmoEvent(
        type: 'RoutineDeleted',
        timestamp: DateTime.now(),
        payload: {'routineId': id},
      ));

      RitmoEvents.notifyRoutineChanged();
      await _loadData();
      await _loadHistory();
    } catch (e) {
      RitmoLog.error('MedicationsSection', 'Error deleting medication routine', e);
    }
  }

  Future<void> _deleteHistoryItem(Map<String, dynamic> item) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final timestamp = item['timestamp'] as int;
      final type = item['type'] as String;

      if (type == 'PRN') {
        await db.delete(
          'prn_logs',
          where: 'takenAt = ?',
          whereArgs: [timestamp],
        );
      } else {
        await db.delete(
          'routine_completions',
          where: 'completionTime = ?',
          whereArgs: [timestamp],
        );
      }
      await _loadData();
      await _loadHistory();
    } catch (e) {
      debugPrint('Error deleting log: $e');
    }
  }

  void _showDeleteMedicationConfirmation(Map<String, dynamic> routine) {
    final colors = context.colors;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('حذف دارو', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'آیا از حذف داروی "${routine['title']}" مطمئن هستید؟ این عمل برنامه آلارم و تاریخچه مصرف آن را برای همیشه پاک می‌کند.',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _deleteMedication(routine['id'] as String);
                if (mounted) {
                  RitmoToast.show(
                    context,
                    'داروی "${routine['title']}" با موفقیت حذف شد.',
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.medicalRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حذف برای همیشه', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteLogConfirmation(Map<String, dynamic> logItem) {
    final colors = context.colors;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('حذف ثبت مصرف', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'آیا مطمئن هستید که می‌خواهید این ثبت مصرف از داروی "${logItem['title']}" را حذف کنید؟',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _deleteHistoryItem(logItem);
                if (mounted) {
                  RitmoToast.show(
                    context,
                    'ثبت مصرف دارو با موفقیت حذف شد.',
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.medicalRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حذف', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2235).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withValues(alpha: isDark ? 0.08 : 0.4)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: isDark ? Colors.white : colors.primary,
                  unselectedLabelColor: colors.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? const Color(0xFF2E334D) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.normal, fontSize: 14),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'امروز'),
                    Tab(text: 'همه داروها'),
                    Tab(text: 'تاریخچه'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayTab(),
                    _buildAllTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: _showAddEditMedicationSheet,
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('داروی جدید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final scheduledIds = _medicationRoutines
        .where((r) => r['routineType'] != 'asNeeded')
        .map((r) => r['id'] as String)
        .toSet();

    final todayScheduledOcc = _occurrencesToday
        .where((o) => scheduledIds.contains(o['routine_id']))
        .toList();

    final todayMeds = _medicationRoutines.where((r) {
      final rId = r['id'] as String;
      final isPrn = r['routineType'] == 'asNeeded';
      if (isPrn) return true;
      return todayScheduledOcc.any((o) => o['routine_id'] == rId);
    }).toList();

    final totalScheduled = todayScheduledOcc.length;
    final takenScheduledIds = _medicationLogsToday
        .where((l) => l['status'] == 'TAKEN')
        .map((l) => l['routineId'] as String)
        .toSet();
    final completedScheduled = todayScheduledOcc.where((o) => takenScheduledIds.contains(o['routine_id'])).length;

    final refillNeededList = _medicationRoutines.where((r) {
      final stock = r['medStockCount'] as int? ?? 0;
      final threshold = r['medRefillThreshold'] as int? ?? 0;
      return MedicalEngine.isRefillNeeded(stockCount: stock, warningThreshold: threshold);
    }).toList();

    return Column(
      children: [
        if (refillNeededList.isNotEmpty) _buildRefillWarningBanner(refillNeededList),
        if (totalScheduled > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'پیشرفت داروها امروز',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                    ),
                    Text(
                      '$completedScheduled از $totalScheduled دوز',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.primary, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: totalScheduled > 0 ? (completedScheduled / totalScheduled) : 0,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              colors.primary,
                              colors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: todayMeds.isEmpty
              ? Center(child: Text('بدون داروی فعال برای امروز', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary, fontSize: 14.5)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: todayMeds.length,
                  itemBuilder: (context, index) {
                    final med = todayMeds[index];
                    final isPrn = med['routineType'] == 'asNeeded';
                    final medId = med['id'] as String;

                    var isLogged = false;
                    var loggedStatus = '';
                    var timeLabel = '';
                    if (!isPrn) {
                      final log = _medicationLogsToday.firstWhere((l) => l['routineId'] == medId, orElse: () => {});
                      if (log.isNotEmpty) {
                        isLogged = true;
                        loggedStatus = log['status'] as String? ?? 'TAKEN';
                      }
                      final occ = todayScheduledOcc.firstWhere((o) => o['routine_id'] == medId, orElse: () => {});
                      if (occ.isNotEmpty) {
                        timeLabel = occ['scheduled_time'] as String? ?? '';
                      }
                    }

                    var checkResult = OverdoseResult.safe;
                    var countdownSecs = 0;
                    if (isPrn) {
                      final prnLogs = _prnLogs24hMap[medId] ?? [];
                      final minInterval = med['minIntervalHours'] as int? ?? 0;
                      final maxDoses = med['maxDosesPerDay'] as int? ?? 0;
                      final now = DateTime.now().millisecondsSinceEpoch;

                      checkResult = MedicalEngine.checkOverdoseStatus(
                        now: now,
                        prnLogs24h: prnLogs,
                        minIntervalHours: minInterval,
                        maxDosesPerDay: maxDoses,
                      );

                      if (checkResult == OverdoseResult.warningUnderInterval && prnLogs.isNotEmpty) {
                        final lastTaken = prnLogs.fold<int>(0, (m, v) => v > m ? v : m);
                        final nextAllowed = lastTaken + (minInterval * 60 * 60 * 1000);
                        countdownSecs = ((nextAllowed - now) / 1000).ceil();
                      }
                    }

                    final dose = med['description'] as String? ?? '';
                    final stock = med['medStockCount'] as int? ?? 0;
                    final threshold = med['medRefillThreshold'] as int? ?? 0;
                    final isRefill = MedicalEngine.isRefillNeeded(stockCount: stock, warningThreshold: threshold);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.6) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRefill 
                              ? colors.warning.withValues(alpha: 0.3)
                              : colors.border.withValues(alpha: isDark ? 0.12 : 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (isPrn ? colors.warning : colors.primary).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPrn ? Icons.medical_services_rounded : Icons.vaccines_rounded,
                                      color: isPrn ? colors.warning : colors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med['title'] as String,
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.bold,
                                            color: colors.textPrimary,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (isPrn ? colors.warning : colors.primary).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isPrn ? 'در صورت نیاز (PRN)' : 'ساعت $timeLabel',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPrn ? colors.warning : colors.primary,
                                                  fontFamily: 'Vazirmatn',
                                                ),
                                              ),
                                            ),
                                            if (dose.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '• $dose',
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  color: colors.textSecondary,
                                                  fontFamily: 'Vazirmatn',
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(height: 1, thickness: 1, color: colors.border.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildStockIndicator(med),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(med, isLogged, loggedStatus, checkResult, countdownSecs),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRefillWarningBanner(List<Map<String, dynamic>> meds) {
    final colors = context.colors;
    final names = meds.map((r) => r['title'] as String).join('، ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'نیاز به تهیه دارو: موجودی ($names) رو به اتمام است.',
              style: TextStyle(
                fontSize: 13, 
                color: colors.warning, 
                fontFamily: 'Vazirmatn', 
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator(Map<String, dynamic> routine) {
    final colors = context.colors;
    final stock = routine['medStockCount'] as int? ?? 0;
    final threshold = routine['medRefillThreshold'] as int? ?? 0;

    var barColor = colors.success;
    var label = 'موجودی کافی ($stock دوز)';

    if (stock == 0) {
      barColor = colors.medicalRed;
      label = 'بدون موجودی! خرید فوری';
    } else if (stock <= threshold) {
      barColor = colors.warning;
      label = 'موجودی کم ($stock دوز)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: barColor,
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: colors.border.withValues(alpha: 0.3),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: stock == 0 ? 0.0 : (stock > 50 ? 1.0 : stock / 50.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: barColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> routine, bool isLogged, String loggedStatus, OverdoseResult checkResult, int countdownSecs) {
    final colors = context.colors;
    final isPrn = routine['routineType'] == 'asNeeded';

    if (!isPrn) {
      if (isLogged) {
        final text = loggedStatus == 'TAKEN' ? 'مصرف شد' : 'رد شد';
        final color = loggedStatus == 'TAKEN' ? colors.success : colors.textSecondary;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                loggedStatus == 'TAKEN' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => _logScheduledMed(routine, 'TAKEN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text(
                'خوردم',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _logScheduledMed(routine, 'SKIPPED'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.4)),
                foregroundColor: colors.textSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text(
                'رد کردم',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      }
    }

    if (checkResult == OverdoseResult.warningUnderInterval) {
      final mins = (countdownSecs / 60).floor();
      final hrs = (mins / 60).floor();
      final remMins = mins % 60;
      final countdownStr = hrs > 0 ? '$hrs ساعت و $remMins دقیقه مانده' : '$remMins دقیقه مانده';

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.border.withValues(alpha: 0.5),
              disabledBackgroundColor: colors.border.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'غیرمجاز',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            countdownStr,
            style: TextStyle(fontSize: 10, color: colors.medicalRed, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else if (checkResult == OverdoseResult.warningMaxLimitExceeded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.border.withValues(alpha: 0.5),
              disabledBackgroundColor: colors.border.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'سقف پر شده',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary.withValues(alpha: 0.5)),
            ),
          ),
          Text(
            'حداکثر دوز مجاز امروز مصرف شده است.',
            style: TextStyle(fontSize: 10, color: colors.medicalRed, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    // Default button for PRN (taken)
    return ElevatedButton.icon(
      onPressed: () => _consumeMedication(routine),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.local_pharmacy_rounded, size: 16),
      label: const Text(
        'ثبت مصرف',
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAllTab() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _medicationRoutines.isEmpty
        ? Center(child: Text('بدون داروی ثبت شده', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary, fontSize: 14.5)))
        : Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '💡 با کشیدن دارو به راست می‌توانید آن را «ویرایش» و با کشیدن به چپ «خاتمه مصرف» (آرشیو) کنید.',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: _medicationRoutines.length,
                  itemBuilder: (context, index) {
                    final med = _medicationRoutines[index];
                    final medId = med['id'] as String;
                    final isPrn = med['routineType'] == 'asNeeded';

                    return Dismissible(
                      key: Key(medId),
                      background: Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.edit_rounded, color: colors.primary),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                        padding: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: colors.medicalRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.archive_rounded, color: colors.medicalRed),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _showAddEditMedicationSheet(medication: med);
                          return false;
                        } else {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                backgroundColor: colors.card,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('خاتمه مصرف دارو', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                                content: const Text('آیا مایلید مصرف این دارو را خاتمه دهید و آن را غیرفعال کنید؟ (این دارو به تاریخچه منتقل می‌شود)', style: TextStyle(fontFamily: 'Vazirmatn')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.medicalRed,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('خاتمه مصرف', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (confirm ?? false) {
                            await _archiveMedication(medId);
                            return true;
                          }
                          return false;
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.6) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.border.withValues(alpha: isDark ? 0.12 : 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isPrn ? colors.warning : colors.primary).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPrn ? Icons.medical_services_rounded : Icons.vaccines_rounded,
                                    color: isPrn ? colors.warning : colors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med['title'] as String,
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (isPrn ? colors.warning : colors.primary).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isPrn ? 'در صورت نیاز (PRN)' : 'برنامه منظم تکرارشونده',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isPrn ? colors.warning : colors.primary,
                                                fontFamily: 'Vazirmatn',
                                              ),
                                            ),
                                          ),
                                          if (med['description'] != null && (med['description'] as String).isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '• دوز: ${med['description']}',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                color: colors.textSecondary,
                                                fontFamily: 'Vazirmatn',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_rounded, color: colors.primary.withValues(alpha: 0.8), size: 20),
                                  onPressed: () => _showAddEditMedicationSheet(medication: med),
                                  tooltip: 'ویرایش دارو',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildHistoryTab() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_historyItems.isEmpty && _archivedRoutines.isEmpty) {
      return Center(child: Text('سوابق مصرف یا داروی خاتمه‌یافته‌ای ثبت نشده است', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary, fontSize: 14.5)));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        if (_archivedRoutines.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.assignment_turned_in_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'داروهای خاتمه‌یافته',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ..._archivedRoutines.map((med) {
            final medId = med['id'] as String;
            final isPrn = med['routineType'] == 'asNeeded';
            final dose = med['description'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.border.withValues(alpha: isDark ? 0.08 : 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPrn ? Icons.medical_services_rounded : Icons.vaccines_rounded,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${isPrn ? "PRN (در صورت نیاز)" : "منظم"} ${dose.isNotEmpty ? "• دوز: $dose" : ""}',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _restoreMedication(medId),
                        icon: Icon(Icons.unarchive_rounded, color: colors.primary, size: 22),
                        tooltip: 'فعال‌سازی مجدد',
                      ),
                      IconButton(
                        onPressed: () => _showDeleteMedicationConfirmation(med),
                        icon: Icon(Icons.delete_forever_rounded, color: colors.medicalRed, size: 22),
                        tooltip: 'حذف کامل دارو',
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: colors.border.withValues(alpha: 0.5)),
          ),
        ],

        if (_historyItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'سوابق مصرف روزانه',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ..._historyItems.map((item) {
            final time = DateTime.fromMillisecondsSinceEpoch(item['timestamp'] as int);
            final hourStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            final isPrn = item['type'] == 'PRN';

            final diff = DateTime.now().difference(time);
            var agoStr = '';
            if (diff.inMinutes < 60) {
              agoStr = '${diff.inMinutes} دقیقه پیش';
            } else if (diff.inHours < 24) {
              agoStr = '${diff.inHours} ساعت پیش';
            } else {
              agoStr = '${diff.inDays} روز پیش';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.6) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.border.withValues(alpha: isDark ? 0.12 : 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isPrn ? colors.warning : colors.primary).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPrn ? Icons.history_rounded : Icons.check_circle_outline_rounded,
                          color: isPrn ? colors.warning : colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'دوز: ${item['dosage'] ?? "نامشخص"} · ساعت $hourStr ($agoStr)',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showDeleteLogConfirmation(item),
                        icon: Icon(Icons.delete_outline_rounded, color: colors.textSecondary.withValues(alpha: 0.6), size: 22),
                        tooltip: 'حذف سابقه مصرف',
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showAddEditMedicationSheet({Map<String, dynamic>? medication, MedicationFormData? prefillData}) {
    MedicationFormSheet.show(
      context,
      medication: medication,
      prefillData: prefillData,
      onFormCompleted: (data) {
        // Form collected → show preview; only saves when user confirms in preview
        MedicationPreviewSheet.show(
          context,
          data: data,
          onSaved: _loadData,
          onEdit: () {
            // Re-open form with this collected data to allow editing
            _showAddEditMedicationSheet(medication: medication, prefillData: data);
          },
        );
      },
    );
  }
}

