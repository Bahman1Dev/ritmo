import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/zone_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:sqflite/sqflite.dart';

/// Bottom sheet widget for managing user realms (focus zones) and schedules.
class RealmManagementSheet extends StatefulWidget {

  /// Constructs a [RealmManagementSheet].
  const RealmManagementSheet({
    required this.isDarkMode,
    this.onChanged,
    super.key,
  });
  /// Whether dark mode is currently active.
  final bool isDarkMode;

  /// Optional callback invoked when realm configuration changes.
  final VoidCallback? onChanged;

  @override
  State<RealmManagementSheet> createState() => _RealmManagementSheetState();
}

class _RealmManagementSheetState extends State<RealmManagementSheet> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _zones = [];
  Map<String, dynamic>? _activeZone;
  Map<String, List<Map<String, dynamic>>> _zoneRoutines = {};
  Map<String, List<Map<String, dynamic>>> _mapSchedules = {};
  bool _isLoading = true;
  Timer? _tickerTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadData());
    _startTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopTicker();
    } else if (state == AppLifecycleState.resumed) {
      _currentTime = DateTime.now();
      _loadData();
      _startTicker();
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _stopTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // 1. Fetch zones
      final zonesRaw = await db.query('zones');
      final zones = zonesRaw.map(Map<String, dynamic>.from).toList();
      
      // 2. Fetch schedules
      final schedulesRaw = await db.query('zone_schedules');
      final schedules = schedulesRaw.map(Map<String, dynamic>.from).toList();
      
      // Map schedules by zoneId
      final mapSchedules = <String, List<Map<String, dynamic>>>{};
      for (final s in schedules) {
        final zId = s['zoneId'] as String;
        mapSchedules.putIfAbsent(zId, () => []).add(s);
      }

      // 3. Resolve active zone
      final activeZone = await _resolveActiveZone(db, _currentTime);
      
      // 4. Fetch routines for zones
      final routinesRaw = await db.query('routines', where: 'isArchived = 0');
      final zoneRoutines = <String, List<Map<String, dynamic>>>{};
      for (final r in routinesRaw) {
        final zId = r['zoneId'] as String?;
        if (zId != null) {
          zoneRoutines.putIfAbsent(zId, () => []).add(r);
        }
      }

      if (mounted) {
        setState(() {
          _zones = zones;
          _activeZone = activeZone;
          _zoneRoutines = zoneRoutines;
          _mapSchedules = mapSchedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading realm sheet data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _resolveActiveZone(Database db, DateTime now) async {
    // Check override settings
    final overrideIdQuery = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['realm_override_id'],
    );
    final overrideUntilQuery = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['realm_override_until_ms'],
    );

    if (overrideIdQuery.isNotEmpty && overrideUntilQuery.isNotEmpty) {
      final overrideId = overrideIdQuery.first['value'] as String?;
      final overrideUntilStr = overrideUntilQuery.first['value'] as String?;
      if (overrideId != null && overrideId.isNotEmpty && overrideUntilStr != null) {
        final overrideUntilMs = int.tryParse(overrideUntilStr) ?? 0;
        if (now.millisecondsSinceEpoch < overrideUntilMs) {
          final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [overrideId]);
          if (zoneQuery.isNotEmpty) {
            final zone = Map<String, dynamic>.from(zoneQuery.first);
            zone['isOverride'] = true;
            zone['overrideUntilMs'] = overrideUntilMs;
            return zone;
          }
        }
      }
    }

    // Schedule-based active zone
    final weekday = now.weekday;
    final currentMinutes = now.hour * 60 + now.minute;

    final schedulesRaw = await db.query('zone_schedules');
    final schedules = schedulesRaw.map(Map<String, dynamic>.from).toList();
    for (final sched in schedules) {
      final daysOfWeekStr = sched['daysOfWeek'] as String? ?? '';
      final days = daysOfWeekStr.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toSet();
      if (days.contains(weekday)) {
        final startTimeStr = sched['startTime'] as String? ?? '00:00';
        final endTimeStr = sched['endTime'] as String? ?? '23:59';

        final startParts = startTimeStr.split(':');
        final endParts = endTimeStr.split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final startMin = (int.tryParse(startParts[0]) ?? 0) * 60 + (int.tryParse(startParts[1]) ?? 0);
          final endMin = (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);

          if (currentMinutes >= startMin && currentMinutes <= endMin) {
            final zoneId = sched['zoneId'] as String;
            final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [zoneId]);
            if (zoneQuery.isNotEmpty) {
              final zone = Map<String, dynamic>.from(zoneQuery.first);
              zone['startTime'] = startTimeStr;
              zone['endTime'] = endTimeStr;
              return zone;
            }
          }
        }
      }
    }
    return null;
  }

  Future<void> _applyOverride(String zoneId) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final untilMs = nowMs + 60 * 60 * 1000; // 60 minutes

    await db.insert(
      'app_settings',
      {'key': 'realm_override_id', 'value': zoneId, 'updatedAt': nowMs},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'app_settings',
      {'key': 'realm_override_until_ms', 'value': untilMs.toString(), 'updatedAt': nowMs},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    RitmoEvents.notifyRoutineChanged();
    widget.onChanged?.call();
    unawaited(_loadData());
  }

  Future<void> _cancelOverride() async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'app_settings',
      {'key': 'realm_override_id', 'value': '', 'updatedAt': nowMs},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'app_settings',
      {'key': 'realm_override_until_ms', 'value': '0', 'updatedAt': nowMs},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    RitmoEvents.notifyRoutineChanged();
    widget.onChanged?.call();
    unawaited(_loadData());
  }

  int _calculateRemainingSeconds(Map<String, dynamic> activeZone) {
    final now = _currentTime;
    if (activeZone['isOverride'] == true) {
      final overrideUntilMs = activeZone['overrideUntilMs'] as int? ?? 0;
      final diffMs = overrideUntilMs - now.millisecondsSinceEpoch;
      return diffMs > 0 ? (diffMs / 1000).ceil() : 0;
    }
    final endTimeStr = activeZone['endTime'] as String?;
    if (endTimeStr == null) return 0;
    final parts = endTimeStr.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final min = int.tryParse(parts[1]) ?? 0;
    final endDateTime = DateTime(now.year, now.month, now.day, hour, min);
    final diff = endDateTime.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  double _calculateProgress(Map<String, dynamic> activeZone) {
    if (activeZone['isOverride'] == true) {
      final remaining = _calculateRemainingSeconds(activeZone);
      final elapsed = 3600 - remaining;
      return (elapsed / 3600).clamp(0.0, 1.0);
    }
    final startTimeStr = activeZone['startTime'] as String?;
    final endTimeStr = activeZone['endTime'] as String?;
    if (startTimeStr == null || endTimeStr == null) return 0;

    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');
    if (startParts.length != 2 || endParts.length != 2) return 0;

    final startMin = (int.tryParse(startParts[0]) ?? 0) * 60 + (int.tryParse(startParts[1]) ?? 0);
    final endMin = (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);
    final currentMin = _currentTime.hour * 60 + _currentTime.minute;

    final total = endMin - startMin;
    if (total <= 0) return 1;
    final elapsed = currentMin - startMin;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '۰۰:۰۰:۰۰';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    return _toPersianDigits('$hStr:$mStr:$sStr');
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

  String _formatTimeRange(String startTime, String endTime) {
    return _toPersianDigits('$startTime الی $endTime');
  }

  Widget _buildExplanationBanner(RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.info_circle_fill,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قلمرو زمانی چیست؟',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'قلمروهای زمانی به شما کمک می‌کنند روز خود را به بخش‌های متمرکز (مانند کار، استراحت، خانواده یا عبادت) تقسیم کنید. روتین‌های متصل به هر قلمرو، فقط در زمان آن قلمرو برجسته می‌شوند تا تمرکز شما حفظ شود.',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    height: 1.6,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 30,
        child: Container(
          padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'قلمروهای زمانی شما',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _buildExplanationBanner(colors),
                  
                  if (_zones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'هیچ قلمرو زمانی تعریف نشده است.\nبرای مدیریت زمان‌بندی‌های خود قلمرو جدید بسازید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: colors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    )
                  else
                    ..._zones.map((z) {
                      final zoneId = z['id'] as String;
                      final zoneColorHex = z['color'] as String? ?? '0xff3B82F6';
                      final zoneColor = Color(int.tryParse(zoneColorHex) ?? 0xff3B82F6);
                      final zoneIcon = z['icon'] as String? ?? '💼';
                      final zoneName = z['name'] as String? ?? '';
                      final zoneMode = z['mode'] as String? ?? 'NORMAL';

                      final zoneScheds = _mapSchedules[zoneId] ?? [];
                      var timeInfo = 'بدون زمان‌بندی';
                      var daysInfo = '';

                      if (zoneScheds.isNotEmpty) {
                        final first = zoneScheds.first;
                        final startTime = first['startTime'] as String? ?? '';
                        final endTime = first['endTime'] as String? ?? '';
                        timeInfo = _formatTimeRange(startTime, endTime);

                        final daysStr = first['daysOfWeek'] as String? ?? '';
                        final days = daysStr.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toSet();
                        
                        final dayNames = <String>[];
                        final order = [6, 7, 1, 2, 3, 4, 5];
                        final names = {6: 'ش', 7: 'ی', 1: 'د', 2: 'س', 3: 'چ', 4: 'پ', 5: 'ج'};
                        for (final d in order) {
                          if (days.contains(d)) {
                            dayNames.add(names[d]!);
                          }
                        }
                        daysInfo = ' | روزهای: ${dayNames.join('، ')}';
                      }

                      final isActive = _activeZone != null && _activeZone!['id'] == zoneId;
                      final isOverride = isActive && _activeZone!['isOverride'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? zoneColor.withValues(alpha: 0.08)
                              : colors.card.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? zoneColor : colors.border.withValues(alpha: 0.5),
                            width: isActive ? 2.0 : 1.0,
                          ),
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: zoneColor.withValues(alpha: 0.15),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ] : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: zoneColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(zoneIcon, style: const TextStyle(fontSize: 20)),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    zoneName,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOverride ? colors.warning.withValues(alpha: 0.2) : colors.success.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isOverride ? 'فعال موقت ⚡' : 'قلمرو فعلی 🌟',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isOverride ? colors.warning : colors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                '$timeInfo$daysInfo (${zoneMode == 'FOCUS' ? 'تمرکز عمیق' : zoneMode == 'SILENT' ? 'بی‌صدا' : 'عادی'})',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isActive)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: zoneColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        backgroundColor: zoneColor.withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => _applyOverride(zoneId),
                                      child: const Text(
                                        'فعال‌سازی',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (isOverride)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: _cancelOverride,
                                      child: const Text(
                                        'لغو',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 18),
                                    onPressed: () => _deleteZone(zoneId, zoneName),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (isActive) ...[
                              // Progress bar and countdown timer
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'پیشرفت زمانی',
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 10,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(_calculateRemainingSeconds(_activeZone!)),
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: zoneColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _calculateProgress(_activeZone!),
                                        backgroundColor: zoneColor.withValues(alpha: 0.15),
                                        valueColor: AlwaysStoppedAnimation<Color>(zoneColor),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Connected routines
                                    Text(
                                      'روتین‌های متصل به این قلمرو:',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildConnectedRoutines(zoneId, colors),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _showAddZoneDialog,
                    icon: const Icon(CupertinoIcons.add, size: 18),
                    label: const Text(
                      'افزودن قلمرو جدید',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'بستن',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildConnectedRoutines(String zoneId, RitmoColors colors) {
    final routines = _zoneRoutines[zoneId] ?? [];
    if (routines.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'هیچ روتینی به این قلمرو متصل نشده است.',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: routines.map((r) {
        final title = r['title'] as String? ?? '';
        final category = r['category'] as String? ?? '';
        final isEssential = (r['isEssential'] as int? ?? 0) == 1;
        final duration = r['targetDurationMinutes'] as int?;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    category == 'HEALTH'
                        ? '💊'
                        : category == 'STUDY'
                            ? '📚'
                            : category == 'WORK'
                                ? '💼'
                                : category == 'RELIGION'
                                    ? '🕌'
                                    : '🌱',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (isEssential) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ضروری',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 8,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (duration != null)
                Text(
                  _toPersianDigits('$duration دقیقه'),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _deleteZone(String zoneId, String zoneName) async {
    final colors = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xff1A1D29) : Colors.white,
          title: const Text(
            'حذف قلمرو زمانی',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'آیا مطمئن هستید که می‌خواهید قلمرو «$zoneName» را حذف کنید؟',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'لغو',
                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm ?? false) {
      final db = await DatabaseHelper.instance.database;
      
      // Clear override if deleting the currently overridden zone
      final overrideIdQuery = await db.query('app_settings', where: 'key = ?', whereArgs: ['realm_override_id']);
      if (overrideIdQuery.isNotEmpty && overrideIdQuery.first['value'] == zoneId) {
        await _cancelOverride();
      }

      await db.delete('zones', where: 'id = ?', whereArgs: [zoneId]);
      await db.delete('zone_schedules', where: 'zoneId = ?', whereArgs: [zoneId]);

      // Remove zone reference from routines
      await db.update(
        'routines',
        {'zoneId': null},
        where: 'zoneId = ?',
        whereArgs: [zoneId],
      );

      RitmoEvents.notifyRoutineChanged();
      widget.onChanged?.call();
      unawaited(_loadData());
    }
  }

  void _showAddZoneDialog() {
    final nameController = TextEditingController();
    var startTime = const TimeOfDay(hour: 8, minute: 0);
    var endTime = const TimeOfDay(hour: 17, minute: 0);
    final selectedDays = <int>{6, 7, 1, 2, 3};
    var selectedMode = 'FOCUS';
    var selectedColor = '0xff3B82F6';
    var selectedIcon = '💼';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = context.colors;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            void applyTemplate(String name, String start, String end, Set<int> days, String mode, String color, String icon) {
              nameController.text = name;
              final startParts = start.split(':');
              final endParts = end.split(':');
              startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
              endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
              selectedDays
                ..clear()
                ..addAll(days);
              selectedMode = mode;
              selectedColor = color;
              selectedIcon = icon;
            }

            final templates = [
              {'name': 'کار', 'start': '08:00', 'end': '17:00', 'days': {6, 7, 1, 2, 3}, 'mode': 'FOCUS', 'color': '0xff3B82F6', 'icon': '💼'},
              {'name': 'خانواده', 'start': '21:00', 'end': '23:00', 'days': {6, 7, 1, 2, 3, 4, 5}, 'mode': 'NORMAL', 'color': '0xff10B981', 'icon': '🏠'},
              {'name': 'مطالعه', 'start': '18:00', 'end': '20:00', 'days': {6, 7, 1, 2, 3, 4}, 'mode': 'FOCUS', 'color': '0xff8B5CF6', 'icon': '📚'},
              {'name': 'ورزش', 'start': '17:00', 'end': '19:00', 'days': {6, 1, 3}, 'mode': 'NORMAL', 'color': '0xffF59E0B', 'icon': '🏃'},
              {'name': 'استراحت', 'start': '23:00', 'end': '07:00', 'days': {6, 7, 1, 2, 3, 4, 5}, 'mode': 'SILENT', 'color': '0xffEC4899', 'icon': '🧘'},
              {'name': 'عبادت', 'start': '19:00', 'end': '20:00', 'days': {6, 7, 1, 2, 3, 4, 5}, 'mode': 'NORMAL', 'color': '0xff06B6D4', 'icon': '🕌'},
            ];

            return Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ساخت قلمرو جدید',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'پیشنهادها و الگوها:',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: templates.map((t) {
                              final isSelectedTemplate = nameController.text == t['name'];
                              final tColor = Color(int.parse(t['color']! as String));
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    applyTemplate(
                                      t['name']! as String,
                                      t['start']! as String,
                                      t['end']! as String,
                                      t['days']! as Set<int>,
                                      t['mode']! as String,
                                      t['color']! as String,
                                      t['icon']! as String,
                                    );
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelectedTemplate ? tColor.withValues(alpha: 0.2) : colors.card.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelectedTemplate ? tColor : colors.border.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(t['icon']! as String, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        t['name']! as String,
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
                          decoration: InputDecoration(
                            labelText: 'نام قلمرو',
                            labelStyle: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 12),
                            hintText: 'مثال: کار عمیق، کلاس درس، خانواده...',
                            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontFamily: 'Vazirmatn', fontSize: 11),
                            prefixIcon: TextButton(
                              onPressed: () {
                                final emojis = ['💼', '🏠', '📚', '🏃', '🧘', '🕌', '🎯', '🎨', '💻'];
                                final nextIdx = (emojis.indexOf(selectedIcon) + 1) % emojis.length;
                                setDialogState(() {
                                  selectedIcon = emojis[nextIdx];
                                });
                              },
                              child: Text(selectedIcon, style: const TextStyle(fontSize: 18)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تکرار در روزهای هفته:',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [6, 7, 1, 2, 3, 4, 5].map((d) {
                            final names = {6: 'ش', 7: 'ی', 1: 'د', 2: 'س', 3: 'چ', 4: 'پ', 5: 'ج'};
                            final isSelected = selectedDays.contains(d);
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  if (isSelected) {
                                    selectedDays.remove(d);
                                  } else {
                                    selectedDays.add(d);
                                  }
                                });
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(int.parse(selectedColor)).withValues(alpha: 0.2) : colors.card.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Color(int.parse(selectedColor)) : colors.border.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    names[d]!,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: startTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      startTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: colors.card.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('شروع قلمرو', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimeOfDay(startTime),
                                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: endTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      endTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: colors.card.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colors.border.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'پایان قلمرو',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 10,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimeOfDay(endTime),
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedMode,
                          dropdownColor: isDark ? const Color(0xff1A1D29) : Colors.white,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
                          decoration: InputDecoration(
                            labelText: 'حالت قلمرو (سکوت / تمرکز)',
                            labelStyle: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn', fontSize: 11),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'NORMAL', child: Text('عادی (اعلان‌های معمولی)', style: TextStyle(fontFamily: 'Vazirmatn'))),
                            DropdownMenuItem(value: 'SILENT', child: Text('بی‌صدا (فقط اعلان‌های دارویی)', style: TextStyle(fontFamily: 'Vazirmatn'))),
                            DropdownMenuItem(value: 'FOCUS', child: Text('تمرکز عمیق (جلوگیری از مزاحمت)', style: TextStyle(fontFamily: 'Vazirmatn'))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedMode = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('لطفاً نام قلمرو را وارد کنید.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                              );
                              return;
                            }
                            if (selectedDays.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('لطفاً حداقل یک روز را انتخاب کنید.', style: TextStyle(fontFamily: 'Vazirmatn'))),
                              );
                              return;
                            }

                            final startStr = _formatTimeOfDay(startTime);
                            final endStr = _formatTimeOfDay(endTime);

                            final db = await DatabaseHelper.instance.database;
                            final existingSchedulesRaw = await db.rawQuery('''
                              SELECT zs.*, z.name as zoneName 
                              FROM zone_schedules zs 
                              JOIN zones z ON zs.zoneId = z.id
                            ''');

                            final check = ZoneEngine.checkOverlap(
                              proposedDays: selectedDays,
                              proposedStart: startStr,
                              proposedEnd: endStr,
                              existingSchedules: existingSchedulesRaw,
                            );

                            if (check['hasOverlap'] == true) {
                              final conflictName = check['message'];
                              final suggStart = check['suggestedStart'] as String;

                              if (!context.mounted) return;
                              final fix = await showDialog<bool>(
                                context: context,
                                builder: (context) => Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: AlertDialog(
                                    backgroundColor: isDark ? const Color(0xff1A1D29) : Colors.white,
                                    title: const Text('⚠️ تداخل در زمان‌بندی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold)),
                                    content: Text(
                                      '$conflictName\n\nآیا می‌خواهید زمان شروع این قلمرو به ساعت $suggStart (پایان قلمرو متداخل) تغییر یابد؟',
                                      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, height: 1.6),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('خیر، لغو ثبت', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('بله، تغییر بده', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (fix ?? false) {
                                final parts = suggStart.split(':');
                                setDialogState(() {
                                  startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                                });
                              }
                              return;
                            }

                            final now = DateTime.now().millisecondsSinceEpoch;
                            final zoneId = 'zone_$now';

                            await db.insert('zones', {
                              'id': zoneId,
                              'name': name,
                              'color': selectedColor,
                              'icon': selectedIcon,
                              'mode': selectedMode,
                              'isDefault': 0,
                              'createdAt': now,
                              'updatedAt': now,
                            });

                            await db.insert('zone_schedules', {
                              'id': 'sched_$now',
                              'zoneId': zoneId,
                              'daysOfWeek': selectedDays.join(','),
                              'startTime': startStr,
                              'endTime': endStr,
                              'createdAt': now,
                              'updatedAt': now,
                            });

                            RitmoEvents.notifyRoutineChanged();
                            widget.onChanged?.call();
                            
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            unawaited(_loadData());
                          },
                          child: const Text(
                            'ذخیره و ثبت قلمرو',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'انصراف',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
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
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
