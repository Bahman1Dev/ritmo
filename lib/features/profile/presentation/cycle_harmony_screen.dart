import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';
import 'package:ritmo/core/domain/engines/hormonal_intelligence_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/module_management_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/features/profile/presentation/cycle_reminders_screen.dart';

class CycleHarmonyScreen extends StatefulWidget {
  const CycleHarmonyScreen({super.key});

  @override
  State<CycleHarmonyScreen> createState() => _CycleHarmonyScreenState();
}

class _CycleHarmonyScreenState extends State<CycleHarmonyScreen> {
  bool _isLoading = true;
  late HormonalEngineOutput _output;
  bool _cycleModuleEnabled = true;
  Map<String, String> _settings = {};
  List<Map<String, dynamic>> _cycleLogs = [];

  // Onboarding Setup State
  int _onboardingCycleLength = 28;
  int _onboardingPeriodDuration = 7;
  DateTime? _onboardingLastStartDate;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  String _formatJalaliDate(DateTime dt) {
    final jal = Jalali.fromDateTime(dt);
    return '${_toPersianDigits(jal.year.toString())}/${_toPersianDigits(jal.month.toString().padLeft(2, '0'))}/${_toPersianDigits(jal.day.toString().padLeft(2, '0'))}';
  }

  String _formatIsoToJalali(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return _formatJalaliDate(dt);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final settingsList = await db.query('app_settings');
    _settings = {for (final s in settingsList) s['key']! as String: s['value']! as String};
    _cycleModuleEnabled = _settings['module_cycle_enabled'] == 'true';
    
    _output = await HormonalIntelligenceEngine.evaluate(
      db: db,
      appSettings: _settings,
      now: DateTime.now(),
    );

    final logs = await db.query('cycle_logs', orderBy: 'cycleStartDate DESC');
    _cycleLogs = logs.map(Map<String, dynamic>.from).toList();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCycleModule(bool enabled) async {
    await ModuleManagementService.instance.setModuleEnabled('module_cycle_enabled', enabled);
    await _loadData();
  }

  Future<void> _togglePeriodToday() async {
    final db = await DatabaseHelper.instance.database;
    if (!mounted) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final hasRealActiveLog = _cycleLogs.any((log) {
      final startStr = log['cycleStartDate'] as String;
      final endStr = log['cycleEndDate'] as String?;
      return startStr.compareTo(todayStr) <= 0 && (endStr == null || endStr.compareTo(todayStr) >= 0);
    });

    if (!hasRealActiveLog) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xff1C1F2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('شروع دوره قاعدگی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              content: const Text('آیا می‌خواهید شروع دوره قاعدگی جدید را از امروز ثبت کنید؟', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70, fontSize: 13)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('خیر', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF43F5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('بله، ثبت شود', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      );
      if (confirm ?? false) {
        await db.insert('cycle_logs', {
          'id': 'cycle_$nowMs',
          'cycleStartDate': todayStr,
          'cycleEndDate': null,
          'isPredicted': 0,
          'suppressedPrayer': 1,
          'fastDebtCreated': 0,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        });
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xff1C1F2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('پایان دوره قاعدگی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              content: const Text('آیا می‌خواهید پایان دوره قاعدگی فعلی را در امروز ثبت کنید؟', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70, fontSize: 13)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('خیر', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF43F5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('بله، ثبت شود', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      );
      if (confirm ?? false) {
        final activeLogs = await db.query(
          'cycle_logs',
          where: 'cycleStartDate <= ? AND (cycleEndDate IS NULL OR cycleEndDate >= ?)',
          whereArgs: [todayStr, todayStr],
        );
        if (activeLogs.isNotEmpty) {
          final activeId = activeLogs.first['id']! as String;
          await db.update(
            'cycle_logs',
            {
              'cycleEndDate': todayStr,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [activeId],
          );
          await DatabaseHelper.instance.addFastingDebtIfNeeded(db, todayStr);
        }
      }
    }

    RitmoEvents.notifyRoutineChanged();
    await _loadData();
  }

  Future<void> _showLogPeriodDialog({Map<String, dynamic>? log}) async {
    var startDate = log != null
        ? (DateTime.tryParse(log['cycleStartDate'] as String) ?? DateTime.now())
        : DateTime.now();
        
    var endDate = log != null && log['cycleEndDate'] != null
        ? DateTime.tryParse(log['cycleEndDate'] as String)
        : null;

    final isEdit = log != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xff1C1F2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  isEdit ? 'ویرایش دوره قاعدگی' : 'ثبت دوره قاعدگی جدید',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تاریخ شروع دوره:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70)),
                      subtitle: Text(
                        _formatJalaliDate(startDate),
                        style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, color: Color(0xffF43F5E), fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(CupertinoIcons.calendar, color: Color(0xffF43F5E)),
                      onTap: () async {
                        final picked = await RitmoDatePicker.showJalali(
                          context: context,
                          initialDate: Jalali.fromDateTime(startDate),
                          firstDate: Jalali(1399),
                          lastDate: Jalali.fromDateTime(DateTime.now()),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked.toDateTime();
                          });
                        }
                      },
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تاریخ پایان دوره (اختیاری):', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70)),
                      subtitle: Text(
                        endDate != null ? _formatJalaliDate(endDate!) : 'در حال حاضر فعال',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 15,
                          color: endDate != null ? const Color(0xffF43F5E) : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (endDate != null)
                            IconButton(
                              icon: const Icon(CupertinoIcons.clear_circled, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setDialogState(() {
                                  endDate = null;
                                });
                              },
                            ),
                          const Icon(CupertinoIcons.calendar, color: Color(0xffF43F5E)),
                        ],
                      ),
                      onTap: () async {
                        final picked = await RitmoDatePicker.showJalali(
                          context: context,
                          initialDate: Jalali.fromDateTime(endDate ?? startDate),
                          firstDate: Jalali.fromDateTime(startDate),
                          lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 10))),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked.toDateTime();
                          });
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF43F5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final db = await DatabaseHelper.instance.database;
                      final startStr = startDate.toIso8601String().substring(0, 10);
                      final endStr = endDate?.toIso8601String().substring(0, 10);
                      final nowMs = DateTime.now().millisecondsSinceEpoch;

                      if (isEdit) {
                        await db.update(
                          'cycle_logs',
                          {
                            'cycleStartDate': startStr,
                            'cycleEndDate': endStr,
                            'updatedAt': nowMs,
                          },
                          where: 'id = ?',
                          whereArgs: [log['id']],
                        );
                      } else {
                        await db.insert('cycle_logs', {
                          'id': 'cycle_$nowMs',
                          'cycleStartDate': startStr,
                          'cycleEndDate': endStr,
                          'isPredicted': 0,
                          'suppressedPrayer': 1,
                          'fastDebtCreated': 0,
                          'createdAt': nowMs,
                          'updatedAt': nowMs,
                        });
                      }

                      if (endStr != null) {
                        await DatabaseHelper.instance.addFastingDebtIfNeeded(db, endStr);
                      }

                      RitmoEvents.notifyRoutineChanged();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      await _loadData();
                    },
                    child: const Text('ذخیره', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCycleSettingsDialog() async {
    final db = await DatabaseHelper.instance.database;
    if (!mounted) return;
    
    var cycleLength = int.tryParse(_settings['cycle_length_days'] ?? '28') ?? 28;
    var periodDuration = int.tryParse(_settings['period_duration_days'] ?? '7') ?? 7;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xff1C1F2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text(
                  'تنظیمات طول دوره و چرخه',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('میانگین طول چرخه (روز):', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70)),
                        Text('$cycleLength روز', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Color(0xffF43F5E), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: cycleLength.toDouble(),
                      min: 21,
                      max: 40,
                      divisions: 19,
                      activeColor: const Color(0xffF43F5E),
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        setDialogState(() {
                          cycleLength = val.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('میانگین طول قاعدگی (روز):', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white70)),
                        Text('$periodDuration روز', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: Color(0xffF43F5E), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: periodDuration.toDouble(),
                      min: 3,
                      max: 10,
                      divisions: 7,
                      activeColor: const Color(0xffF43F5E),
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        setDialogState(() {
                          periodDuration = val.toInt();
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF43F5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final nowMs = DateTime.now().millisecondsSinceEpoch;
                      
                      await db.rawInsert(
                        'INSERT OR REPLACE INTO app_settings (key, value, updatedAt) VALUES (?, ?, ?)',
                        ['cycle_length_days', cycleLength.toString(), nowMs],
                      );
                      await db.rawInsert(
                        'INSERT OR REPLACE INTO app_settings (key, value, updatedAt) VALUES (?, ?, ?)',
                        ['period_duration_days', periodDuration.toString(), nowMs],
                      );

                      RitmoEvents.notifyRoutineChanged();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      await _loadData();
                    },
                    child: const Text('ذخیره', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.bg,
        body: const Center(child: CircularProgressIndicator(color: Color(0xffF43F5E))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient (Theme-Aware)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xff0F0E17), const Color(0xff1A1625)]
                      : [const Color(0xffFDF8F7), const Color(0xffF3E8E6)],
                ),
              ),
            ),
          ),

          // Scrollable content
          Positioned.fill(
            child: SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: RitmoIcons.back(context, color: colors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'چرخه بدن و هماهنگی',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          IconButton(
                            icon: Icon(CupertinoIcons.shield_fill, color: colors.textPrimary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CycleRemindersScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '🔒 اطلاعات این بخش خصوصی و فقط برای شماست',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!_output.hasData)
                        _buildOnboardingUI(colors, isDark)
                      else ...[
                        // Status & circular ring
                        _buildCycleProgressCard(colors, isDark),
                        const SizedBox(height: 16),

                        // Daily status logger card
                        _buildDailyStatusCard(colors, isDark),
                        const SizedBox(height: 16),

                        // Cycle settings config card
                        _buildCycleSettingsCard(colors, isDark),
                        const SizedBox(height: 16),

                        // Grid details
                        _buildDetailsGrid(colors, isDark),
                        const SizedBox(height: 24),

                        // Today's Recommendations
                        _buildRecommendationsSection(colors, isDark),
                        const SizedBox(height: 24),

                        // History of Periods
                        _buildPeriodHistorySection(colors, isDark),
                        const SizedBox(height: 24),

                        // How Ritmo coordinates
                        _buildCoordinationSection(colors, isDark),
                        const SizedBox(height: 24),
                        _buildManagementCard(colors, isDark),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingUI(RitmoColors colors, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff141221).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffF43F5E).withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF43F5E).withValues(alpha: 0.04),
            blurRadius: 30,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsating Glow behind the heart icon
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffF43F5E).withValues(alpha: 0.25),
                              blurRadius: 25,
                              spreadRadius: 8,
                            )
                          ],
                        ),
                      ),
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xffFDA4AF), Color(0xffF43F5E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffF43F5E).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'تنظیم چرخه بیولوژیک بدن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Vazirmatn',
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ریتمو بر اساس تغییرات طبیعی هورمون‌های بدن شما، سطح انرژی، تمرکز و نیاز به استراحتتان را تحلیل می‌کند. لطفاً برای فعال‌سازی ویژگی‌ها، اطلاعات چرخه خود را مشخص کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary.withValues(alpha: 0.8),
                    fontFamily: 'Vazirmatn',
                    height: 1.6,
                  ),
                ),
                const Divider(height: 40, color: Colors.white10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'طول چرخه بدنی (فاصله بین دو شروع):',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xffF43F5E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_onboardingCycleLength روز',
                        style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Color(0xffFDA4AF), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: const Color(0xffF43F5E),
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xffF43F5E).withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _onboardingCycleLength.toDouble(),
                    min: 21,
                    max: 40,
                    divisions: 19,
                    onChanged: (val) {
                      setState(() {
                        _onboardingCycleLength = val.toInt();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'میانگین طول دوره خونریزی:',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xffF43F5E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_onboardingPeriodDuration روز',
                        style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Color(0xffFDA4AF), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: const Color(0xffF43F5E),
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xffF43F5E).withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _onboardingPeriodDuration.toDouble(),
                    min: 3,
                    max: 10,
                    divisions: 7,
                    onChanged: (val) {
                      setState(() {
                        _onboardingPeriodDuration = val.toInt();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Last start date picker ticket
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text('تاریخ شروع آخرین دوره شما:', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white60)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _onboardingLastStartDate != null
                            ? _formatJalaliDate(_onboardingLastStartDate!)
                            : 'هنوز انتخاب نشده (اختیاری)',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13.5,
                          color: _onboardingLastStartDate != null ? const Color(0xffFDA4AF) : Colors.white24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.calendar, color: Color(0xffF43F5E), size: 18),
                    ),
                    onTap: () async {
                      final picked = await RitmoDatePicker.showJalali(
                        context: context,
                        initialDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 7))),
                        firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 90))),
                        lastDate: Jalali.fromDateTime(DateTime.now()),
                      );
                      if (picked != null) {
                        setState(() {
                          _onboardingLastStartDate = picked.toDateTime();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 28),
                
                // Submit button with glowing gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffF43F5E).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (_onboardingLastStartDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'لطفاً تاریخ شروع آخرین دوره خود را مشخص کنید.',
                              style: TextStyle(fontFamily: 'Vazirmatn'),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final db = await DatabaseHelper.instance.database;
                      final nowMs = DateTime.now().millisecondsSinceEpoch;

                      await db.rawInsert(
                        'INSERT OR REPLACE INTO app_settings (key, value, updatedAt) VALUES (?, ?, ?)',
                        ['cycle_length_days', _onboardingCycleLength.toString(), nowMs],
                      );
                      await db.rawInsert(
                        'INSERT OR REPLACE INTO app_settings (key, value, updatedAt) VALUES (?, ?, ?)',
                        ['period_duration_days', _onboardingPeriodDuration.toString(), nowMs],
                      );

                      if (_onboardingLastStartDate != null) {
                        final startStr = _onboardingLastStartDate!.toIso8601String().substring(0, 10);
                        final daysAgo = DateTime.now().difference(_onboardingLastStartDate!).inDays;
                        
                        String? endStr;
                        if (daysAgo >= _onboardingPeriodDuration) {
                          endStr = _onboardingLastStartDate!.add(Duration(days: _onboardingPeriodDuration - 1)).toIso8601String().substring(0, 10);
                        }

                        await db.insert('cycle_logs', {
                          'id': 'cycle_$nowMs',
                          'cycleStartDate': startStr,
                          'cycleEndDate': endStr,
                          'isPredicted': 0,
                          'suppressedPrayer': 1,
                          'fastDebtCreated': 0,
                          'createdAt': nowMs,
                          'updatedAt': nowMs,
                        });

                        if (endStr != null) {
                          await DatabaseHelper.instance.addFastingDebtIfNeeded(db, endStr);
                        }
                      }

                      RitmoEvents.notifyRoutineChanged();
                      await _loadData();
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffFDA4AF), Color(0xffF43F5E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(minHeight: 50),
                        child: const Text(
                          'راه‌اندازی و شروع چرخه',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStatusCard(RitmoColors colors, bool isDark) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final hasRealActiveLog = _cycleLogs.any((log) {
      final startStr = log['cycleStartDate'] as String;
      final endStr = log['cycleEndDate'] as String?;
      return startStr.compareTo(todayStr) <= 0 && (endStr == null || endStr.compareTo(todayStr) >= 0);
    });

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff12111E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffF43F5E).withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xffF43F5E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.waveform_path, color: Color(0xffF43F5E), size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'ثبت وضعیت روزانه',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasRealActiveLog
                  ? 'دوره قاعدگی شما فعال ثبت شده است. اگر خونریزی شما به پایان رسیده، پایان دوره را امروز اعلام کنید.'
                  : 'شما می‌توانید زمان شروع قاعدگی خود را از امروز اعلام کنید تا پیش‌بینی و توصیه‌ها منطبق شوند.',
              style: TextStyle(
                fontSize: 10.5,
                color: colors.textSecondary.withValues(alpha: 0.8),
                fontFamily: 'Vazirmatn',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: hasRealActiveLog
                          ? [
                              BoxShadow(
                                color: const Color(0xffF43F5E).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasRealActiveLog ? const Color(0xffF43F5E) : Colors.white.withValues(alpha: 0.04),
                        foregroundColor: hasRealActiveLog ? Colors.white : const Color(0xffFDA4AF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: hasRealActiveLog ? Colors.transparent : const Color(0xffF43F5E).withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _togglePeriodToday,
                      icon: Icon(
                        hasRealActiveLog ? CupertinoIcons.square_fill : CupertinoIcons.play_fill,
                        size: 12,
                      ),
                      label: Text(
                        hasRealActiveLog ? 'اعلام پایان دوره قاعدگی (امروز)' : 'اعلام شروع قاعدگی از امروز',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(CupertinoIcons.calendar_badge_plus, color: Color(0xffFDA4AF), size: 18),
                  onPressed: _showLogPeriodDialog,
                  tooltip: 'ثبت تاریخ دلخواه',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleSettingsCard(RitmoColors colors, bool isDark) {
    final cycleLength = int.tryParse(_settings['cycle_length_days'] ?? '28') ?? 28;
    final periodDuration = int.tryParse(_settings['period_duration_days'] ?? '7') ?? 7;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff12111E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.settings, color: Colors.blueAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'مشخصات دوره و چرخه',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Color(0xffFDA4AF), size: 18),
                  onPressed: _showCycleSettingsDialog,
                  tooltip: 'تنظیم طول چرخه',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffFDA4AF).withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'طول چرخه بدنی',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$cycleLength روز',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffFDA4AF).withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'طول دوره قاعدگی',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$periodDuration روز',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodHistorySection(RitmoColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاریخچه دوره‌ها',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),
        if (_cycleLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: const Center(
              child: Text(
                'هیچ دوره‌ای ثبت نشده است. از دکمه‌های بالا برای شروع ثبت استفاده کنید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cycleLogs.length,
            itemBuilder: (context, index) {
              final log = _cycleLogs[index];
              final startStr = log['cycleStartDate'] as String;
              final endStr = log['cycleEndDate'] as String?;
              final duration = endStr != null
                  ? DateTime.tryParse(endStr)!.difference(DateTime.tryParse(startStr)!).inDays + 1
                  : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff12111E).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: duration != null && duration >= 8
                          ? const Color(0xffF43F5E).withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xffF43F5E),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'شروع: ${_formatIsoToJalali(startStr)}  ←  ${endStr != null ? "پایان: ${_formatIsoToJalali(endStr)}" : "درحال خونریزی"}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  duration != null ? 'مدت زمان خونریزی: $duration روز' : 'دوره در حال حاضر فعال است',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.textSecondary.withValues(alpha: 0.7),
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.pencil, color: Colors.blueAccent, size: 18),
                              onPressed: () => _showLogPeriodDialog(log: log),
                              tooltip: 'ویرایش زمان دوره',
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 18),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: AlertDialog(
                                        backgroundColor: const Color(0xff1C1F2E),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: const Text('حذف دوره', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        content: const Text('آیا مطمئن هستید که می‌خواهید این دوره را حذف کنید؟', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70, fontSize: 13)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('خیر', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('بله، حذف شود', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                );
                                if (confirm ?? false) {
                                  final db = await DatabaseHelper.instance.database;
                                  await db.delete('cycle_logs', where: 'id = ?', whereArgs: [log['id']]);
                                  RitmoEvents.notifyRoutineChanged();
                                  await _loadData();
                                }
                              },
                              tooltip: 'حذف دوره',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCycleProgressCard(RitmoColors colors, bool isDark) {
    final isActive = _output.state == HormonalPhase.menstrual;
    final dayLabel = isActive ? 'روز ${_output.dayOfMenstruation}' : 'روز ${_output.dayOfCycle}';
    final stateLabel = isActive ? 'در دوره قاعدگی' : 'دوره عادی بدنی';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff12111E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffF43F5E).withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF43F5E).withValues(alpha: 0.03),
            blurRadius: 20,
            spreadRadius: 1,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Row(
          children: [
            // Concentric Orbital Ring
            SizedBox(
              height: 110,
              width: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing ambient light
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffF43F5E).withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                  ),
                  // Progress ring track
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: isActive
                          ? (_output.dayOfMenstruation / 7).clamp(0.0, 1.0)
                          : (_output.dayOfCycle / 28).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: const Color(0xffF43F5E),
                      strokeWidth: 7,
                    ),
                  ),
                  // Thin outer orbit circle
                  Container(
                    height: 104,
                    width: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                    ),
                  ),
                  // Center Orb
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.01),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          Text(
                            'از چرخه',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: colors.textSecondary.withValues(alpha: 0.8),
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Info texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xffF43F5E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'توصیه ریتمو',
                          style: TextStyle(fontSize: 8.5, color: Color(0xffFDA4AF), fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(CupertinoIcons.sparkles, size: 11, color: colors.textSecondary.withValues(alpha: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stateLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffFDA4AF),
                      fontFamily: 'Vazirmatn',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActive
                        ? 'در این دوره بدن شما نیاز به بازیابی بالاتری دارد. کارهای سنگین روتین‌ها به آرامی فیلتر می‌شوند.'
                        : 'بدن شما در شرایط عادی خود قرار دارد. روتین‌ها با شدت و توان کاری کامل قابل پیگیری است.',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textSecondary.withValues(alpha: 0.8),
                      height: 1.5,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(RitmoColors colors, bool isDark) {
    final isActive = _output.state == HormonalPhase.menstrual;
    final isPre = _output.state == HormonalPhase.preCycle;

    var energy = 'متوسط';
    if (isActive) energy = 'پایین تا متوسط';
    if (isPre) energy = 'کمی خسته';

    var focus = 'متوسط';
    if (isActive) focus = 'متوسط';

    final rest = isActive ? 'بیشتر' : 'عادی';

    return Row(
      children: [
        Expanded(
          child: _buildGridItem(
            icon: CupertinoIcons.battery_charging,
            iconColor: Colors.greenAccent,
            title: 'سطح انرژی',
            value: energy,
            glowColor: Colors.green.withValues(alpha: 0.12),
            colors: colors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGridItem(
            icon: CupertinoIcons.brightness,
            iconColor: const Color(0xffC69FFF),
            title: 'تمرکز',
            value: focus,
            glowColor: Colors.deepPurple.withValues(alpha: 0.12),
            colors: colors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGridItem(
            icon: CupertinoIcons.heart_fill,
            iconColor: const Color(0xffFF9082),
            title: 'نیاز به استراحت',
            value: rest,
            glowColor: Colors.redAccent.withValues(alpha: 0.12),
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color glowColor,
    required RitmoColors colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff12111E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 9.5,
                color: colors.textSecondary.withValues(alpha: 0.8),
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(RitmoColors colors, bool isDark) {
    var adjustments = <String>[];
    if (_output.state == HormonalPhase.menstrual) {
      adjustments = [
        'فعالیت‌های سنگین را کاهش دهید',
        'بین کارها استراحت کوتاه اضافه کنید',
        'روی کارهای سبک و ضروری تمرکز کنید',
        'آب کافی بنوشید و استراحت کافی داشته باشید'
      ];
    } else if (_output.state == HormonalPhase.preCycle) {
      adjustments = [
        'ممکن است خستگی بدنی یا نوسانات انرژی خفیف را تجربه کنید 🔋',
        'اولویت‌دهی به کارهای مهم در ساعات اولیه روز ⏰',
        'پیشنهاد می‌شود زمان خواب شبانه را افزایش دهید 🌙'
      ];
    } else if (_output.state == HormonalPhase.postCycle) {
      adjustments = [
        'سطح انرژی و توانایی تمرکز در حال افزایش است 📈',
        'زمان عالی برای شروع برنامه‌ها یا یادگیری کارهای جدید 🎓'
      ];
    }

    if (adjustments.isEmpty) {
      adjustments = ['فعالیت‌های بدنی روزانه در حالت متعادل دنبال شود.', 'نوشیدن آب کافی در طول روز فراموش نشود.', 'مدیریت ساعت خواب برای حفظ شادابی توصیه می‌شود.'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'توصیه‌های امروز',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: adjustments.map((adj) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff12111E).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.greenAccent, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        adj,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCoordinationSection(RitmoColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'چطور ریتمو هماهنگ می‌شود؟',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildCoordinationItem(
              icon: CupertinoIcons.shield_fill,
              title: 'کنترل کامل در دست شماست',
              colors: colors,
            ),
            _buildCoordinationItem(
              icon: CupertinoIcons.sparkles,
              title: 'پیشنهادهای هوشمند شخصی‌سازی می‌شوند',
              colors: colors,
            ),
            _buildCoordinationItem(
              icon: CupertinoIcons.alarm,
              title: 'یادآوری‌ها با شرایط شما هماهنگ می‌شوند',
              colors: colors,
            ),
            _buildCoordinationItem(
              icon: CupertinoIcons.calendar_today,
              title: 'برنامه‌های سنگین سبک‌تر می‌شوند',
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordinationItem({
    required IconData icon,
    required String title,
    required RitmoColors colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff12111E).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xffF43F5E), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(RitmoColors colors, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff12111E).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مدیریت چرخه بدن',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cycleModuleEnabled ? 'ماژول فعال است' : 'ماژول غیرفعال است',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                CupertinoSwitch(
                  value: _cycleModuleEnabled,
                  activeTrackColor: const Color(0xffF43F5E),
                  onChanged: _toggleCycleModule,
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                foregroundColor: colors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CycleRemindersScreen(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.gear_solid, size: 16, color: Color(0xffFDA4AF)),
              label: const Text(
                'تنظیمات پیشرفته و یادآوری‌ها',
                style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
