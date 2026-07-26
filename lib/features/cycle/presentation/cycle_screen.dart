import 'dart:math' as math;
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/ux/ritmo_empty_state.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_lock_gate.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_trends_section.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_correlation_section.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_sos_section.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_pregnancy_mode.dart';
import 'package:ritmo/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart';
import 'package:ritmo/features/cycle/models/cycle_models.dart';
import 'package:ritmo/features/cycle/logic/cycle_correlation.dart';
import 'package:ritmo/core/utils/cycle_consent_bridge.dart';
import 'package:ritmo/core/services/cycle_notification_service.dart';
import 'package:lottie/lottie.dart';
import 'package:ritmo/features/cycle/models/cycle_intelligence_models.dart';
import 'package:ritmo/features/cycle/logic/cycle_data_quality_engine.dart';
import 'package:ritmo/features/cycle/logic/cycle_personal_pattern_engine.dart';
import 'package:ritmo/features/cycle/logic/cycle_burden_engine.dart';
import 'package:ritmo/features/cycle/logic/cycle_load_balancer.dart';
import 'package:ritmo/features/cycle/logic/cycle_checkin_orchestrator.dart';
import 'package:ritmo/features/cycle/logic/cycle_anomaly_detector.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_prediction_confidence_card.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_burden_card.dart';
import 'package:ritmo/features/cycle/presentation/widgets/cycle_personal_forecast_card.dart';

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  @override
  Widget build(BuildContext context) {
    return const CycleLockGate(
      child: _CycleScreenContent(),
    );
  }
}

class _CycleScreenContent extends StatefulWidget {
  const _CycleScreenContent();

  @override
  State<_CycleScreenContent> createState() => _CycleScreenContentState();
}

class _CycleScreenContentState extends State<_CycleScreenContent> {
  bool _isLoading = true;
  Map<String, String> _settings = {};
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _dayLogs = [];
  CycleEngineOutput? _engineOutput;
  int _activeTab = 0;
  List<FastingDebt> _fastingDebts = [];
  Map<String, dynamic>? _forgottenPeriod;
  bool _startSetup = false;
  List<SymptomStat> _symptomStats = [];
  PredictionConfidence? _predictionConfidence;
  DataQualityReport? _dataQualityReport;
  List<SymptomForecast> _personalForecasts = [];
  BodyBurdenScore? _burdenScore;
  CycleAdaptiveAdvice? _adaptiveAdvice;
  // ignore: unused_field
  String? _checkinPromptFa;
  // ignore: unused_field
  List<CycleAnomaly> _anomalies = [];

  bool _isPeriodForgotten(Map<String, dynamic> p) {
    if (p['endDate'] != null) return false;
    final startStr = p['startDate'] as String;
    final start = DateTime.tryParse(startStr);
    if (start == null) return false;
    final cleanStart = DateTime(start.year, start.month, start.day);
    final now = DateTime.now();
    final cleanToday = DateTime(now.year, now.month, now.day);
    return cleanToday.difference(cleanStart).inDays >= 12;
  }

  void _openAiAssistant() {
    showCycleAiConsentSheet(
      context,
      engineOutput: _engineOutput,
      dayLogs: _dayLogs,
      settings: _settings,
      onConsentGranted: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiCycleAssistantSheet(
            engineOutput: _engineOutput,
            dayLogs: _dayLogs,
            settings: _settings,
          ),
        );
      },
    );
  }

  // Onboarding Wizard State
  int _onboardingStep = 1;
  int _setupCycleLength = 28;
  int _setupPeriodDuration = 6;
  DateTime _setupLastStartDate = DateTime.now().subtract(const Duration(days: 5));
  bool _setupWorship = false;
  bool _setupEnergy = false;
  bool _setupReminders = false;
  bool _setupDashboard = false;

  // Selected calendar month
  Jalali _calendarMonth = Jalali.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Load settings
      final settingsList = await db.query('app_settings');
      _settings = {for (final s in settingsList) if (s['key'] != null) s['key'].toString(): s['value']?.toString() ?? ''};

      // Seed cycle consent settings if they do not exist
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      var consentSeedChanged = false;
      if (!_settings.containsKey('cycle_consent_ai')) {
        await db.insert('app_settings', {
          'key': 'cycle_consent_ai',
          'value': 'false',
          'updatedAt': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        consentSeedChanged = true;
      }
      if (!_settings.containsKey('cycle_ai_share_data')) {
        await db.insert('app_settings', {
          'key': 'cycle_ai_share_data',
          'value': 'false',
          'updatedAt': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        consentSeedChanged = true;
      }
      if (!_settings.containsKey('cycle_ai_share_fertility_data')) {
        await db.insert('app_settings', {
          'key': 'cycle_ai_share_fertility_data',
          'value': 'false',
          'updatedAt': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        consentSeedChanged = true;
      }
      if (consentSeedChanged) {
        final updatedSettingsList = await db.query('app_settings');
        _settings = {for (final s in updatedSettingsList) if (s['key'] != null) s['key'].toString(): s['value']?.toString() ?? ''};
      }

      // Migrate settings if legacy settings exist but new ones do not
      var settingsChanged = false;
      if (!_settings.containsKey('cycle_avg_length') && _settings.containsKey('cycle_length_days')) {
        await db.insert('app_settings', {
          'key': 'cycle_avg_length',
          'value': _settings['cycle_length_days'],
          'updatedAt': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        settingsChanged = true;
      }
      if (!_settings.containsKey('cycle_avg_period') && _settings.containsKey('period_duration_days')) {
        await db.insert('app_settings', {
          'key': 'cycle_avg_period',
          'value': _settings['period_duration_days'],
          'updatedAt': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        settingsChanged = true;
      }
      if (settingsChanged) {
        final updatedSettingsList = await db.query('app_settings');
        _settings = {for (final s in updatedSettingsList) if (s['key'] != null) s['key'].toString(): s['value']?.toString() ?? ''};
      }

      // Load cycle periods
      _periods = await db.query('cycle_periods', orderBy: 'startDate DESC');

      // Migrate periods if legacy logs exist but new periods are empty
      if (_periods.isEmpty) {
        final legacyLogs = await db.query('cycle_logs', orderBy: 'cycleStartDate DESC');
        if (legacyLogs.isNotEmpty) {
          final batch = db.batch();
          for (final log in legacyLogs) {
            batch.insert('cycle_periods', {
              'id': log['id'],
              'startDate': log['cycleStartDate'],
              'endDate': log['cycleEndDate'],
              'flowIntensity': log['flowLevel'] ?? 'MEDIUM',
              'isPredicted': log['isPredicted'] ?? 0,
              'note': log['note'] ?? 'انتقال یافته از تاریخچه قدیمی',
              'createdAt': log['createdAt'],
              'updatedAt': log['updatedAt'],
            });
          }
          await batch.commit(noResult: true);
          _periods = await db.query('cycle_periods', orderBy: 'startDate DESC');
        }
      }

      // Find if there is any forgotten period
      _forgottenPeriod = null;
      for (final p in _periods) {
        if (_isPeriodForgotten(p)) {
          _forgottenPeriod = p;
          break;
        }
      }

      // Load daily logs
      _dayLogs = await db.query('cycle_day_logs', orderBy: 'logDate DESC');

      // Load fasting debts
      _fastingDebts = await CycleConsentBridge.getFastingDebts();

      // Calculate engine output
      final engine = CycleEngine();
      _engineOutput = await engine.calculate(CycleEngineInput(
        db: db,
        appSettings: _settings,
        now: DateTime.now(),
      ));

      if (_engineOutput != null) {
        final consentReminders = _settings['cycle_consent_reminders'] == 'true';
        final pregnancyMode = _settings['cycle_pregnancy_mode'] == 'true';
        await CycleNotificationService.scheduleReminders(
          nextPeriodWindowStart: _engineOutput!.nextPeriodWindowStart,
          consentReminders: consentReminders,
          pregnancyMode: pregnancyMode,
        );

        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        _dataQualityReport = await CycleDataQualityEngine.evaluateDataQuality(
          db: db,
          periodRows: _periods,
          todayIso: todayStr,
        );

        final confLevel = _periods.length >= 5 && !_dataQualityReport!.hasForgottenOpenPeriod
            ? PredictionConfidenceLevel.high
            : (_periods.length >= 2 ? PredictionConfidenceLevel.medium : PredictionConfidenceLevel.low);
        final confScore = _periods.length >= 5 ? 0.90 : (_periods.length >= 2 ? 0.65 : 0.35);
        _predictionConfidence = PredictionConfidence(
          level: confLevel,
          score: confScore,
          reasonsFa: _dataQualityReport!.warningsFa.isNotEmpty
              ? _dataQualityReport!.warningsFa
              : ['${_periods.length} چرخه ثبت‌شده و الگوی نسبتاً پایدار'],
        );

        _personalForecasts = await CyclePersonalPatternEngine.computePersonalForecasts(
          db: db,
          periodRows: _periods,
          avgCycleLength: _engineOutput!.stats.avgCycleLength,
        );

        final latestLog = _dayLogs.isNotEmpty ? _dayLogs.first : null;
        final symptomsStr = latestLog?['symptoms'] as String? ?? '';
        final loggedSymptoms = symptomsStr.isNotEmpty ? symptomsStr.split(',') : <String>[];

        _burdenScore = CycleBurdenEngine.calculateBurden(
          phase: _engineOutput!.currentPhase,
          dayOfPeriod: _engineOutput!.dayOfPeriod,
          flowIntensity: latestLog?['flowLevel'] as String?,
          loggedSymptoms: loggedSymptoms,
          energyTag: null,
          sleepHours: null,
        );

        _adaptiveAdvice = CycleLoadBalancer.generateAdvice(_burdenScore!);

        _checkinPromptFa = CycleCheckinOrchestrator.checkinPromptFa(
          phase: _engineOutput!.currentPhase,
          dataQuality: _dataQualityReport!,
          pmsWindowStart: _engineOutput!.pmsWindowStart,
          now: DateTime.now(),
        );

        _anomalies = CycleAnomalyDetector.detectAnomalies(
          periodRows: _periods,
          avgCycleLength: _engineOutput!.stats.avgCycleLength,
        );
      }

      final stats = await CycleCorrelationAnalyzer.analyzeSymptomStats(db);

      if (mounted) {
        setState(() {
          _symptomStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cycle data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  String _formatJalaliDate(DateTime dt) {
    final jal = Jalali.fromDateTime(dt);
    return '${_toPersianDigits(jal.year.toString())}/${_toPersianDigits(jal.month.toString().padLeft(2, '0'))}/${_toPersianDigits(jal.day.toString().padLeft(2, '0'))}';
  }

  String _formatIsoToJalali(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return _formatJalaliDate(dt);
  }

  Future<void> _saveOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final batch = db.batch();

      // Write settings
      final settingsToSave = {
        'cycle_avg_length': _setupCycleLength.toString(),
        'cycle_avg_period': _setupPeriodDuration.toString(),
        'cycle_consent_worship': _setupWorship.toString(),
        'cycle_consent_energy': _setupEnergy.toString(),
        'cycle_consent_reminders': _setupReminders.toString(),
        'cycle_consent_dashboard': _setupDashboard.toString(),
        'cycle_setup_done': 'true',
      };

      for (final entry in settingsToSave.entries) {
        batch.insert(
          'app_settings',
          {'key': entry.key, 'value': entry.value, 'updatedAt': nowMs},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert first period starting on last start date
      final firstPeriodId = 'period_$nowMs';
      batch.insert('cycle_periods', {
        'id': firstPeriodId,
        'startDate': _setupLastStartDate.toIso8601String().substring(0, 10),
        'endDate': null,
        'flowIntensity': 'MEDIUM',
        'isPredicted': 0,
        'note': 'ثبت اولیه در راه‌اندازی',
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      await batch.commit(noResult: true);
      RitmoEvents.notifyRoutineChanged();
      await _loadData();
    } catch (e) {
      debugPrint('Error saving onboarding: $e');
    }
  }

  Future<void> _togglePeriodToday() async {
    if (_engineOutput == null) return;
    final db = await DatabaseHelper.instance.database;
    if (!mounted) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final hasActivePeriod = _periods.any((p) => p['endDate'] == null && !_isPeriodForgotten(p));

    if (!hasActivePeriod) {
      if (_forgottenPeriod != null) {
        showDialog(
          context: context,
          builder: (context) => _buildConfirmDialog(
            title: 'خطا در ثبت دوره جدید',
            content: 'شما یک دورهٔ باز قدیمی (فراموش‌شده) دارید. لطفاً ابتدا از بخش هشدار بالای صفحه تکلیف آن را مشخص کنید تا بتوانید دورهٔ جدید ثبت کنید.',
            confirmText: 'فهمیدم',
          ),
        );
        return;
      }
      // Start Period dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => _buildConfirmDialog(
          title: 'شروع دوره جدید',
          content: 'آیا می‌خواهید شروع دوره قاعدگی خود را از امروز ثبت کنید؟',
          confirmText: 'بله، ثبت شود',
        ),
      );

      if (confirm ?? false) {
        await db.insert('cycle_periods', {
          'id': 'period_$nowMs',
          'startDate': todayStr,
          'endDate': null,
          'flowIntensity': 'MEDIUM',
          'isPredicted': 0,
          'note': 'ثبت دستی',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        });
        RitmoEvents.notifyRoutineChanged();
        await _loadData();
      }
    } else {
      // End Period dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => _buildConfirmDialog(
          title: 'پایان دوره',
          content: 'آیا می‌خواهید پایان دوره قاعدگی فعلی را در امروز ثبت کنید؟',
          confirmText: 'بله، ثبت شود',
        ),
      );

      if (confirm ?? false) {
        // Find current ongoing period
        final activePeriods = await db.query(
          'cycle_periods',
          where: 'startDate <= ? AND endDate IS NULL',
          whereArgs: [todayStr],
          orderBy: 'startDate DESC',
          limit: 1,
        );

        if (activePeriods.isNotEmpty) {
          final activeId = activePeriods.first['id']! as String;
          await db.update(
            'cycle_periods',
            {
              'endDate': todayStr,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [activeId],
          );

          // Add qada fasting debt if worship consent enabled
          if (_settings['cycle_consent_worship'] == 'true') {
            await DatabaseHelper.instance.addFastingDebtIfNeeded(db, todayStr);
          }

          RitmoEvents.notifyRoutineChanged();
          await _loadData();
        }
      }
    }
  }

  Future<void> _editBaselineParameter(
    String key,
    String name,
    int minVal,
    int maxVal,
    int defaultVal,
  ) async {
    final currentVal = int.tryParse(_settings[key] ?? '') ?? defaultVal;
    var selectedVal = currentVal;

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: RitmoSheetGlassCard(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    top: 24,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تغییر متوسط $name',
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.xmark, color: Colors.white54, size: 20),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'یک عدد بین ${_toPersianDigits(minVal.toString())} تا ${_toPersianDigits(maxVal.toString())} روز انتخاب کنید:',
                        style: const TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.minus_circle, color: Color(0xffF43F5E), size: 28),
                            onPressed: () {
                              if (selectedVal > minVal) {
                                setSheetState(() => selectedVal--);
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${_toPersianDigits(selectedVal.toString())} روز',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(CupertinoIcons.plus_circle, color: Color(0xffF43F5E), size: 28),
                            onPressed: () {
                              if (selectedVal < maxVal) {
                                setSheetState(() => selectedVal++);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffF43F5E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('ذخیره تغییرات', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirm ?? false) {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'app_settings',
        {
          'key': key,
          'value': selectedVal.toString(),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      RitmoEvents.notifyRoutineChanged();
      await _loadData();
    }
  }

  Widget _buildConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
  }) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xff1C1F2E) : colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Vazirmatn', 
            color: isDark ? Colors.white : colors.textPrimary, 
            fontSize: 14, 
            fontWeight: FontWeight.bold
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            fontFamily: 'Vazirmatn', 
            color: isDark ? Colors.white70 : colors.textSecondary, 
            fontSize: 14, 
            height: 1.5
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'خیر', 
              style: TextStyle(
                fontFamily: 'Vazirmatn', 
                color: isDark ? Colors.white54 : colors.textSecondary.withValues(alpha: 0.6)
              )
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActivePhaseColor(),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePeriod(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'حذف دوره',
        content: 'آیا از حذف اطلاعات این دوره اطمینان دارید؟ این عمل غیرقابل بازگشت است.',
        confirmText: 'حذف شود',
      ),
    );

    if (confirm ?? false) {
      final db = await DatabaseHelper.instance.database;
      final batch = db.batch();
      batch.delete('cycle_periods', where: 'id = ?', whereArgs: [id]);
      batch.delete('fasting_debt', where: 'id = ?', whereArgs: ['fd_$id']);
      batch.delete('worship_debts', where: 'id = ?', whereArgs: ['debt_cycle_fast_fd_$id']);
      await batch.commit(noResult: true);
      RitmoEvents.notifyRoutineChanged();
      await _loadData();
    }
  }

  Future<void> _closeForgottenPeriod(Map<String, dynamic> period) async {
    final db = await DatabaseHelper.instance.database;
    final startStr = period['startDate'] as String;
    final start = DateTime.parse(startStr);
    final avgPeriod = int.tryParse(_settings['cycle_avg_period'] ?? '6') ?? 6;
    final end = start.add(Duration(days: avgPeriod - 1));
    final endStr = end.toIso8601String().substring(0, 10);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'cycle_periods',
      {
        'endDate': endStr,
        'updatedAt': nowMs,
      },
      where: 'id = ?',
      whereArgs: [period['id']],
    );

    // Re-sync fasting debt if worship consent enabled
    if (_settings['cycle_consent_worship'] == 'true') {
      await DatabaseHelper.instance.addFastingDebtIfNeeded(db, endStr);
    }

    RitmoEvents.notifyRoutineChanged();
    await _loadData();
  }

  bool rangesOverlap(DateTime s1, DateTime? e1, DateTime s2, DateTime? e2) {
    final dateS1 = DateTime(s1.year, s1.month, s1.day);
    final dateE1 = e1 != null ? DateTime(e1.year, e1.month, e1.day) : null;
    final dateS2 = DateTime(s2.year, s2.month, s2.day);
    final dateE2 = e2 != null ? DateTime(e2.year, e2.month, e2.day) : null;

    final cond1 = dateE2 == null || !dateS1.isAfter(dateE2); // dateS1 <= dateE2
    final cond2 = dateE1 == null || !dateS2.isAfter(dateE1); // dateS2 <= dateE1
    return cond1 && cond2;
  }

  String? _validatePeriodDates(DateTime startDate, DateTime? endDate, {String? excludeId}) {
    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
    final cleanEnd = endDate != null ? DateTime(endDate.year, endDate.month, endDate.day) : null;

    if (cleanEnd != null && cleanEnd.isBefore(cleanStart)) {
      return 'تاریخ پایان دوره نمی‌تواند قبل از تاریخ شروع باشد.';
    }

    final cleanToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (cleanStart.isAfter(cleanToday)) {
      return 'تاریخ شروع دوره نمی‌تواند در آینده باشد.';
    }
    if (cleanEnd != null && cleanEnd.isAfter(cleanToday)) {
      return 'تاریخ پایان دوره نمی‌تواند در آینده باشد.';
    }

    // Check overlap with other periods
    for (final p in _periods) {
      if (excludeId != null && p['id'] == excludeId) continue;
      final otherStart = DateTime.parse(p['startDate'] as String);
      final otherEnd = p['endDate'] != null ? DateTime.parse(p['endDate'] as String) : null;

      if (rangesOverlap(startDate, endDate, otherStart, otherEnd)) {
        final formattedOtherStart = _formatIsoToJalali(p['startDate'] as String);
        return 'تداخل با دوره ثبت شده دیگر (شروع از $formattedOtherStart)';
      }
    }

    return null;
  }

  Future<void> _editPeriod(Map<String, dynamic> p) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddEditPeriodSheet(
          period: p,
          onValidate: (startDate, endDate) {
            return _validatePeriodDates(startDate, endDate, excludeId: p['id'] as String);
          },
          onSave: (startDate, endDate) async {
            await _savePeriod(p['id'] as String, startDate, endDate);
          },
        );
      },
    );
  }

  Future<void> _addNewPeriodSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddEditPeriodSheet(
          onValidate: _validatePeriodDates,
          onSave: (startDate, endDate) async {
            await _savePeriod(null, startDate, endDate);
          },
        );
      },
    );
  }

  Future<void> _savePeriod(String? id, DateTime startDate, DateTime? endDate) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final startIso = startDate.toIso8601String().substring(0, 10);
    final endIso = endDate?.toIso8601String().substring(0, 10);

    final batch = db.batch();
    final isNew = id == null;
    final periodId = id ?? 'period_$nowMs';

    if (isNew) {
      batch.insert('cycle_periods', {
        'id': periodId,
        'startDate': startIso,
        'endDate': endIso,
        'flowIntensity': 'MEDIUM',
        'isPredicted': 0,
        'note': 'ثبت دستی',
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });
    } else {
      batch.update(
        'cycle_periods',
        {
          'startDate': startIso,
          'endDate': endIso,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [periodId],
      );
    }

    final worshipConsent = _settings['cycle_consent_worship'] == 'true';
    final sendToWorship = _settings['cycle_send_fasting_debt_to_worship'] == 'true';
    final debtId = 'fd_$periodId';
    final worshipDebtId = 'debt_cycle_fast_$debtId';

    var overlapDays = 0;
    if (endIso != null && worshipConsent) {
      // Find ws_ramadan dates
      final seasons = await db.query(
        'worship_seasons',
        where: "id = 'ws_ramadan'",
        limit: 1,
      );
      if (seasons.isNotEmpty) {
        final rStartStr = seasons.first['startDate']! as String;
        final rEndStr = seasons.first['endDate']! as String;
        try {
          final rStart = DateTime.parse(rStartStr);
          final rEnd = DateTime.parse(rEndStr);
          
          final start = DateTime.parse(startIso);
          final end = DateTime.parse(endIso);
          
          // Calculate overlap
          final latestStart = start.isAfter(rStart) ? start : rStart;
          final earliestEnd = end.isBefore(rEnd) ? end : rEnd;
          
          if (!latestStart.isAfter(earliestEnd)) {
            overlapDays = earliestEnd.difference(latestStart).inDays + 1;
          }
        } catch (e) {
          debugPrint('Error parsing Ramadan dates in cycle screen: $e');
        }
      }
    }

    if (overlapDays > 0) {
      // Check if debt exists to preserve isResolved status
      var isResolved = 0;
      if (!isNew) {
        final existingDebts = await db.query('fasting_debt', where: 'id = ?', whereArgs: [debtId]);
        if (existingDebts.isNotEmpty) {
          isResolved = existingDebts.first['isResolved']! as int;
        }
      }

      batch.insert(
        'fasting_debt',
        {
          'id': debtId,
          'dateIso': startIso,
          'daysOwed': overlapDays,
          'reason': 'عذر شرعی (دوره بدنی)',
          'isResolved': isResolved,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If sendToWorship is true, sync to worship_debts
      if (sendToWorship) {
        batch.insert(
          'worship_debts',
          {
            'id': worshipDebtId,
            'sourceKind': 'CYCLE_FAST',
            'debtType': 'FAST',
            'title': 'روزه قضا (عذر شرعی)',
            'totalCount': overlapDays,
            'remainingCount': isResolved == 1 ? 0 : overlapDays,
            'dailyTarget': 1,
            'autoCreated': 1,
            'isArchived': isResolved,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        batch.delete('worship_debts', where: 'id = ?', whereArgs: [worshipDebtId]);
      }
    } else {
      batch.delete('fasting_debt', where: 'id = ?', whereArgs: [debtId]);
      batch.delete('worship_debts', where: 'id = ?', whereArgs: [worshipDebtId]);
    }

    await batch.commit(noResult: true);
    RitmoEvents.notifyRoutineChanged();
    await _loadData();
  }

  Future<void> _toggleFastingDebtSync(bool val) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_settings',
      {
        'key': 'cycle_send_fasting_debt_to_worship',
        'value': val ? 'true' : 'false',
        'updatedAt': nowMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncFastingDebtsToWorship(val);
    await _loadData();
  }

  Future<void> _syncFastingDebtsToWorship(bool enabled) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (enabled) {
      final unresolvedCycleDebts = await db.query(
        'fasting_debt',
        where: 'isResolved = 0',
      );
      
      final batch = db.batch();
      for (final row in unresolvedCycleDebts) {
        final cycleDebtId = row['id']! as String;
        final daysOwed = row['daysOwed'] as int? ?? 1;
        final worshipDebtId = 'debt_cycle_fast_$cycleDebtId';
        
        batch.insert(
          'worship_debts',
          {
            'id': worshipDebtId,
            'sourceKind': 'CYCLE_FAST',
            'debtType': 'FAST',
            'title': 'روزه قضا (عذر شرعی)',
            'totalCount': daysOwed,
            'remainingCount': daysOwed,
            'dailyTarget': 1,
            'autoCreated': 1,
            'isArchived': 0,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } else {
      await db.delete(
        'worship_debts',
        where: "id LIKE 'debt_cycle_fast_%'",
      );
    }
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

    final isSetupDone = _settings['cycle_setup_done'] == 'true';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Theme gradient and animated cycle-aware background
          Positioned.fill(
            child: CycleAnimatedBackground(
              phase: _getCurrentDayPhase(),
              isDark: isDark,
              isPregnancy: _settings['cycle_pregnancy_mode'] == 'true',
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    // Header Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: RitmoIcons.back(context, color: colors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'چرخه بدن و سلامتی',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(CupertinoIcons.sparkles, color: _getActivePhaseColor()),
                                onPressed: _openAiAssistant,
                              ),
                              IconButton(
                                icon: Icon(CupertinoIcons.settings, color: _getActivePhaseColor()),
                                onPressed: _openSettingsSheet,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: isSetupDone
                          ? (_settings['cycle_pregnancy_mode'] == 'true'
                              ? CyclePregnancyModeView(
                                  pregnancyStartDate: _settings['cycle_pregnancy_start_date'] ?? '',
                                  pregnancyDueDate: _settings['cycle_pregnancy_due_date'] ?? '',
                                  onDeactivated: _loadData,
                                  settings: _settings,
                                  dayLogs: _dayLogs,
                                  engineOutput: _engineOutput,
                                )
                              : _buildMainDashboard(colors, isDark))
                          : (_startSetup
                              ? _buildOnboardingWizard(colors, isDark)
                              : RitmoEmptyState(
                                  icon: CupertinoIcons.heart_circle_fill,
                                  title: 'چرخه بدن فعال نشده است',
                                  description: 'برای استفاده از پیش‌بینی‌های هوشمند، مدیریت زمان عبادات، تحلیل انرژی و یادآوری‌ها، ابتدا مشخصات چرخه بدن خود را تنظیم کنید.',
                                  ctaLabel: 'تنظیم چرخه بدن',
                                  onCta: () => setState(() => _startSetup = true),
                                )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingWizard(RitmoColors colors, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _onboardingStep == 1
                ? _buildSetupStep1(colors)
                : _onboardingStep == 2
                    ? _buildSetupStep2(colors)
                    : _buildSetupStep3(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupStep1(RitmoColors colors) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: const Color(0xffF43F5E).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.heart_fill, color: Color(0xffF43F5E), size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'به بخش چرخه بدن خوش آمدید',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'در این بخش خصوصی، اطلاعات بیولوژیک بدن شما بررسی شده و ریتم زندگی و روتین‌های روزانه‌تان به صورت هوشمند و کاملاً محرمانه با آن هماهنگ می‌شود.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.6),
        ),
        Divider(height: 32, color: colors.border),
        Text(
          'طول چرخه بدنی شما معمولاً چند روز است؟',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('میانگین فاصله شروع دو پریود:', style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
            Text(_toPersianDigits('$_setupCycleLength روز'), style: const TextStyle(fontSize: 18, color: Color(0xffF43F5E), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          ],
        ),
        Slider(
          value: _setupCycleLength.toDouble(),
          min: 21,
          max: 45,
          divisions: 24,
          activeColor: const Color(0xffF43F5E),
          inactiveColor: colors.border,
          onChanged: (v) => setState(() => _setupCycleLength = v.toInt()),
        ),
        const SizedBox(height: 16),
        Text(
          'طول مدت خونریزی چند روز است؟',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('طول خونریزی:', style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
            Text(_toPersianDigits('$_setupPeriodDuration روز'), style: const TextStyle(fontSize: 18, color: Color(0xffF43F5E), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          ],
        ),
        Slider(
          value: _setupPeriodDuration.toDouble(),
          min: 3,
          max: 10,
          divisions: 7,
          activeColor: const Color(0xffF43F5E),
          inactiveColor: colors.border,
          onChanged: (v) => setState(() => _setupPeriodDuration = v.toInt()),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => setState(() => _onboardingStep = 2),
            child: const Text('مرحله بعد', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupStep2(RitmoColors colors) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاریخ شروع آخرین دوره شما',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 8),
        Text(
          'مشخص کردن تاریخ تقریبی یا دقیق آخرین قاعدگی، به موتور پردازشی ریتمو کمک می‌کند تا فاز کنونی بدن شما را محاسبه کند.',
          style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.5),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: colors.textSecondary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: ListTile(
            title: Text('آخرین شروع:', style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
            subtitle: Text(
              _formatJalaliDate(_setupLastStartDate),
              style: const TextStyle(fontSize: 16, color: Color(0xffF43F5E), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
            ),
            trailing: const Icon(CupertinoIcons.calendar, color: Color(0xffF43F5E)),
            onTap: () async {
              final picked = await RitmoDatePicker.showJalali(
                context: context,
                initialDate: Jalali.fromDateTime(_setupLastStartDate),
                firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 45))),
                lastDate: Jalali.fromDateTime(DateTime.now()),
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).brightness == Brightness.dark
                              ? const ColorScheme.dark(
                                  primary: Color(0xffF43F5E),
                                  onPrimary: Colors.white,
                                  surface: Colors.transparent,
                                )
                              : ColorScheme.light(
                                  primary: const Color(0xffF43F5E),
                                  onSurface: context.colors.textPrimary,
                                ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1A1625) : Colors.white),
                        ),
                        child: child!,
                      ),
                    ),
                  );
                },
              );
              if (picked != null) {
                setState(() => _setupLastStartDate = picked.toDateTime());
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => setState(() => _onboardingStep = 1),
                child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF43F5E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => setState(() => _onboardingStep = 3),
                child: const Text('مرحله بعد', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSetupStep3(RitmoColors colors) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اتصال‌های حریم خصوصی و رضایت',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 6),
        Text(
          'با رعایت کامل حریم خصوصی، هیچ استفاده بدون رضایتی از داده‌ها صورت نمی‌گیرد. اتصالات مورد نظر خود را برای هماهنگی ریتم فعال کنید (همه پیش‌فرض خاموش هستند).',
          style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.5),
        ),
        Divider(height: 24, color: colors.border),
        _buildConsentSwitch(
          title: 'هماهنگی با بخش عبادات',
          subtitle: 'تعلیق هوشمند فرایض دینی در روزهای عادت ماهیانه و محاسبه بدهی‌های قضا.',
          value: _setupWorship,
          onChanged: (v) => setState(() => _setupWorship = v),
        ),
        const SizedBox(height: 12),
        _buildConsentSwitch(
          title: 'هماهنگی با انرژی و روتین‌ها',
          subtitle: 'تعدیل خودکار زمان و سطح فشار روتین‌های روزانه شما بر اساس نوسانات انرژی بدنی.',
          value: _setupEnergy,
          onChanged: (v) => setState(() => _setupEnergy = v),
        ),
        const SizedBox(height: 12),
        _buildConsentSwitch(
          title: 'یادآوری‌های حریم خصوصی',
          subtitle: 'ارسال اعلان‌های غیرمستقیم و لطیف برای پیگیری چرخه بدون درج کلمات افشاکننده.',
          value: _setupReminders,
          onChanged: (v) => setState(() => _setupReminders = v),
        ),
        const SizedBox(height: 12),
        _buildConsentSwitch(
          title: 'خلاصه وضعیت روی داشبورد اصلی',
          subtitle: 'نمایش یک کارت وضعیت محرمانه روی داشبورد امروز در صورت ورود به حساب کاربری مجاز.',
          value: _setupDashboard,
          onChanged: (v) => setState(() => _setupDashboard = v),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => setState(() => _onboardingStep = 2),
                child: const Text('بازگشت', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF43F5E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _saveOnboarding,
                child: const Text('تکمیل راه‌اندازی', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsentSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xffF43F5E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(RitmoColors colors, bool isDark) {
    if (_engineOutput == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Navigation Tabs
          _buildSegmentedTabs(colors),
          const SizedBox(height: 16),

          if (_forgottenPeriod != null) ...[
            _buildForgottenPeriodWarning(colors, isDark),
            const SizedBox(height: 16),
          ],

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _activeTab == 0
                ? Column(
                    key: const ValueKey(0),
                    children: [
                      _buildOrbCard(colors, isDark),
                      const SizedBox(height: 16),
                      _buildNextPeriodPredictionCard(colors, isDark),
                      if (_predictionConfidence != null && _dataQualityReport != null)
                        CyclePredictionConfidenceCard(
                          confidence: _predictionConfidence!,
                          dataQuality: _dataQualityReport!,
                        ),
                      const SizedBox(height: 16),
                      _buildQuickActionButtons(colors, isDark),
                      if (_burdenScore != null && _adaptiveAdvice != null)
                        CycleBurdenCard(
                          burden: _burdenScore!,
                          advice: _adaptiveAdvice!,
                        ),
                      const SizedBox(height: 16),
                      _buildCycleSyncingWorkoutCard(colors, isDark),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final card = _buildSymptomPredictionCard(colors, isDark);
                          return card != null
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: card,
                                )
                              : const SizedBox();
                        },
                      ),
                      if (_personalForecasts.isNotEmpty)
                        CyclePersonalForecastCard(forecasts: _personalForecasts),
                      if (_engineOutput != null) ...[
                        CycleSosSection(
                          engineOutput: _engineOutput,
                          dayLogs: _dayLogs,
                          settings: _settings,
                          phase: _getCurrentDayPhase(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildCalendarView(colors, isDark),
                      const SizedBox(height: 16),
                      _buildIrregularityStatsCard(colors, isDark),
                      const SizedBox(height: 16),

                      _buildHistoryList(colors, isDark),
                    ],
                  )
                : _activeTab == 1
                    ? CycleTrendsSection(
                        key: const ValueKey(1),
                        engineOutput: _engineOutput!,
                      )
                    : _activeTab == 2
                        ? const CycleCorrelationSection(
                            key: ValueKey(2),
                          )
                        : _buildFastingDebtView(colors, isDark),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(RitmoColors colors) {
    final showWorship = _settings['module_religion_enabled'] == 'true';
    final activeThemeColor = _getActivePhaseColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildTabButton(int index, String label, IconData icon) {
      final isActive = _activeTab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _activeTab = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeThemeColor.withValues(alpha: 0.12) : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? activeThemeColor : (isDark ? Colors.white.withValues(alpha: 0.05) : colors.border.withValues(alpha: 0.5)),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: isActive ? activeThemeColor : (isDark ? Colors.white54 : colors.textSecondary)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? activeThemeColor : (isDark ? Colors.white70 : colors.textSecondary),
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildTabButton(0, 'داشبورد', CupertinoIcons.today),
        buildTabButton(1, 'روندها', CupertinoIcons.chart_bar_alt_fill),
        buildTabButton(2, 'همبستگی‌ها', CupertinoIcons.sparkles),
        if (showWorship) buildTabButton(3, 'روزه قضا', CupertinoIcons.bookmark_fill),
      ],
    );
  }

  Widget _buildFastingDebtView(RitmoColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.bookmark_solid, color: Color(0xffEC4899), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'دفترچه قضای روزه‌های واجب',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'بر اساس فقه اسلامی و رضایت عبادی شما، روزهای روزه واجب که به علت عذر شرعی بدنی از دست رفته‌اند در این دفترچه ثبت می‌شوند تا بتوانید به مرور زمان قضای آن‌ها را به جا آورید.',
                  style: TextStyle(fontSize: 15.5, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.5),
                ),
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white10 : colors.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ارسال بدهی‌ها به بخش عبادت',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                    CupertinoSwitch(
                      value: _settings['cycle_send_fasting_debt_to_worship'] == 'true',
                      activeTrackColor: const Color(0xffEC4899),
                      onChanged: (val) async {
                        HapticFeedback.selectionClick();
                        await _toggleFastingDebtSync(val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_fastingDebts.isEmpty) RitmoTheme.glassCardLight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'هیچ بدهی قضای روزه‌ای ثبت نشده است 🌸',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                ),
              ) else ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fastingDebts.length,
                itemBuilder: (context, index) {
                  final debt = _fastingDebts[index];
                  var dateStr = debt.dateIso;
                  try {
                    final dt = DateTime.parse(debt.dateIso);
                    final jal = Jalali.fromDateTime(dt);
                    dateStr = '${_toPersianDigits(jal.year.toString())}/${_toPersianDigits(jal.month.toString())}/${_toPersianDigits(jal.day.toString())}';
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RitmoTheme.glassCardLight(
                      child: ListTile(
                        title: Text(
                          _toPersianDigits('بدهی روزه: ${debt.daysOwed} روز'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
                        ),
                        subtitle: Text(
                          'شروع دوره: $dateStr • ${debt.reason ?? "عذر شرعی"}',
                          style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                        ),
                        trailing: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: debt.isResolved ? Colors.white10 : const Color(0xffEC4899),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await CycleConsentBridge.resolveFastingDebt(debt.id, !debt.isResolved);
                            await _loadData();
                          },
                          child: Text(
                            debt.isResolved ? 'تسویه شده' : 'ثبت تسویه',
                            style: TextStyle(
                              fontSize: 14,
                              color: debt.isResolved ? Colors.white38 : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildForgottenPeriodWarning(RitmoColors colors, bool isDark) {
    if (_forgottenPeriod == null) return const SizedBox();
    final startStr = _forgottenPeriod!['startDate'] as String;
    final jalaliDateStr = _formatIsoToJalali(startStr);

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'دوره قاعدگی باز (احتمالاً فراموش‌شده)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'دوره‌ای که در تاریخ $jalaliDateStr شروع شده، هنوز پایانی برای آن ثبت نشده است (بیش از ۱۲ روز). برای دقت محاسبات چرخه، لطفاً پایان آن را ثبت کنید یا تاریخ‌ها را ویرایش کنید.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF43F5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _closeForgottenPeriod(_forgottenPeriod!),
                    child: Text(
                      'ثبت پایان (${_toPersianDigits(_settings['cycle_avg_period'] ?? '6')} روزه)',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _editPeriod(_forgottenPeriod!),
                    child: const Text(
                      'ویرایش تاریخ‌ها',
                      style: TextStyle(fontSize: 14.5, fontFamily: 'Vazirmatn'),
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

  Widget _buildNextPeriodPredictionCard(RitmoColors colors, bool isDark) {
    if (_engineOutput == null) return const SizedBox();

    final hasEnoughData = _engineOutput!.stats.totalRecordedCycles >= 2;
    final predictedDateStr = _formatJalaliDate(_engineOutput!.nextPeriodPrediction);

    var windowText = '';
    if (hasEnoughData) {
      final startStr = _formatJalaliDate(_engineOutput!.nextPeriodWindowStart);
      final endStr = _formatJalaliDate(_engineOutput!.nextPeriodWindowEnd);
      windowText = 'بازهٔ تخمینی شروع: از $startStr تا $endStr';
    } else {
      windowText = 'بازهٔ تخمینی: دادهٔ ناکافی جهت محاسبه بازه';
    }

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.calendar_circle, color: Color(0xffF43F5E), size: 20),
                const SizedBox(width: 8),
                Text(
                  'پیش‌بینی شروع دوره بعدی',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'تاریخ تخمینی شروع: $predictedDateStr',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xffF43F5E),
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              windowText,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'وضعیت ریتم چرخه: ',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasEnoughData && _engineOutput!.regularityLabel == 'نسبتاً منظم'
                        ? Colors.green.withValues(alpha: 0.15)
                        : hasEnoughData
                            ? Colors.orange.withValues(alpha: 0.15)
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _engineOutput!.regularityLabel,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: hasEnoughData && _engineOutput!.regularityLabel == 'نسبتاً منظم'
                          ? (isDark ? const Color(0xff34D399) : const Color(0xff059669))
                          : hasEnoughData
                              ? (isDark ? const Color(0xffF5B95B) : const Color(0xffD97706))
                              : colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12, height: 20),
            Text(
              _engineOutput!.predictionDisclaimer,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary.withValues(alpha: 0.8),
                fontFamily: 'Vazirmatn',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  CyclePhase _getCurrentDayPhase() {
    if (_engineOutput == null) return CyclePhase.noData;
    final today = DateTime.now();
    if (_checkIsPeriodDay(today)) return CyclePhase.menstrual;
    if (_checkIsOvulationDay(today) || _checkIsFertileDay(today)) return CyclePhase.ovulation;
    if (_checkIsPmsDay(today)) return CyclePhase.luteal;
    return CyclePhase.follicular;
  }

  Color _getActivePhaseColor() {
    final phase = _getCurrentDayPhase();
    switch (phase) {
      case CyclePhase.menstrual:
        return const Color(0xffF43F5E);
      case CyclePhase.ovulation:
        return const Color(0xff06B6D4);
      case CyclePhase.luteal:
        return const Color(0xffEC4899);
      case CyclePhase.follicular:
      default:
        return const Color(0xff8B5CF6);
    }
  }

  Widget _buildOrbCard(RitmoColors colors, bool isDark) {
    final phase = _getCurrentDayPhase();
    final today = DateTime.now();
    final isTodayPeriod = _checkIsPeriodDay(today);
    final isTodayOvulation = _checkIsOvulationDay(today);
    final isTodayFertile = _checkIsFertileDay(today);
    final isTodayPms = _checkIsPmsDay(today);
    final activePeriodDay = _calculateActivePeriodDay(today);

    var phaseText = '';
    var remainingText = '';
    var emoji = '✨';
    var statusTip = '';
    var phaseColor = const Color(0xff8B5CF6);

    if (isTodayPeriod) {
      phaseText = 'دوران قاعدگی (پریود)';
      remainingText = 'روز ${_toPersianDigits(activePeriodDay.toString())} دوره خونریزی';
      phaseColor = const Color(0xffF43F5E);
      emoji = '🩸';
      statusTip = 'بدن شما در حال پاکسازی طبیعی است. استراحت کافی، نوشیدن آب ولرم و دمنوش‌های ملایم به کاهش انقباضات کمک می‌کند.';
    } else if (isTodayOvulation) {
      phaseText = 'روز تخمک‌گذاری';
      remainingText = 'اوج هورمون‌های زنانه و باروری';
      phaseColor = const Color(0xff06B6D4);
      emoji = '🥚';
      statusTip = 'تخمک‌گذاری رخ داده است. هورمون‌ها در بالاترین سطح خود هستند و آمادگی فیزیکی و سطح نشاط بدنی شما عالی است.';
    } else if (isTodayFertile) {
      phaseText = 'پنجره باروری (Fertile)';
      remainingText = 'روز ${_toPersianDigits(_engineOutput?.dayOfCycle.toString() ?? '12')} چرخه بدنی';
      phaseColor = const Color(0xff06B6D4);
      emoji = '🧬';
      statusTip = 'پنجره باروری شما فعال است. زمان مناسبی برای ورزش‌های پرانرژی و تعاملات اجتماعی بالا است.';
    } else if (isTodayPms) {
      phaseText = 'روزهای پیش از عادت (PMS)';
      remainingText = 'روز ${_toPersianDigits(_engineOutput?.dayOfCycle.toString() ?? '24')} چرخه بدنی';
      phaseColor = const Color(0xffEC4899);
      emoji = '🌸';
      statusTip = 'روزهای قبل از پریود؛ نوسان هورمونی طبیعی است. یوگای آرام، کاهش مصرف نمک و خواب منظم بسیار موثر است.';
    } else {
      phaseText = 'فاز فولیکولار (رشد)';
      remainingText = 'روز ${_toPersianDigits(_engineOutput?.dayOfCycle.toString() ?? '7')} چرخه بدنی';
      phaseColor = const Color(0xff8B5CF6);
      emoji = '✨';
      statusTip = 'فاز فولیکولار با رشد فولیکول‌ها شروع شده است. سطح هورمون استروژن افزایش یافته و انرژی و تمرکز شما رو به رشد است.';
    }

    final totalCycleLength = _engineOutput?.stats.avgCycleLength ?? 28.0;
    final avgPeriodDuration = _engineOutput?.stats.avgPeriodDuration ?? 7.0;
    final currentDay = isTodayPeriod ? activePeriodDay : (_engineOutput?.dayOfCycle ?? 1);
    final totalDays = isTodayPeriod ? avgPeriodDuration : totalCycleLength;
    final progress = totalDays > 0 ? (currentDay / totalDays).clamp(0.05, 1.0) : 0.1;

    return RitmoTheme.glassCardLight(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            // Premium Progress Orb representing cycle day
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow container
                Container(
                  height: 146,
                  width: 146,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withValues(alpha: 0.12),
                        blurRadius: 35,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                ),
                // Ring CustomPaint
                SizedBox(
                  height: 136,
                  width: 136,
                  child: CustomPaint(
                    painter: _CycleProgressRingPainter(
                      percentage: progress,
                      activeColor: phaseColor,
                      isDark: isDark,
                    ),
                  ),
                ),
                // Center card
                Container(
                  height: 104,
                  width: 104,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff12101F).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          phase == CyclePhase.menstrual ? 'روز پریود' : 'روز چرخه',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _toPersianDigits(
                            phase == CyclePhase.menstrual
                                ? activePeriodDay.toString()
                                : (_engineOutput?.dayOfCycle.toString() ?? '12'),
                          ),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: phaseColor,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Phase Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: phaseColor.withValues(alpha: isDark ? 0.3 : 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    phaseText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : phaseColor,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Remaining Text
            Text(
              remainingText,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            
            // Daily Status Tip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                statusTip,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : colors.textSecondary.withValues(alpha: 0.95),
                  fontFamily: 'Vazirmatn',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(RitmoColors colors, bool isDark) {
    if (_engineOutput == null) return const SizedBox();
    final hasActivePeriod = _periods.any((p) => p['endDate'] == null && !_isPeriodForgotten(p));

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _togglePeriodToday,
            child: RitmoTheme.glassCardLight(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasActivePeriod ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.add_circled_solid,
                      color: _getActivePhaseColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasActivePeriod ? 'ثبت پایان قاعدگی' : 'ثبت شروع قاعدگی',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
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
        Expanded(
          child: GestureDetector(
            onTap: _showDailyLoggingBottomSheet,
            child: RitmoTheme.glassCardLight(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.pencil_outline,
                      color: _getActivePhaseColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ثبت علائم روزانه',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDailyLoggingBottomSheet() async {
    final db = await DatabaseHelper.instance.database;
    if (!mounted) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Try to load today's log if it exists
    final existingLogs = await db.query('cycle_day_logs', where: 'logDate = ?', whereArgs: [todayStr]);
    if (!mounted) return;
    final Map<String, dynamic>? todayLog = existingLogs.isNotEmpty ? existingLogs.first : null;

    var flowLevel = todayLog != null ? todayLog['flowLevel'] as String? : 'NONE';
    var mood = todayLog != null ? todayLog['mood'] as String? : 'NEUTRAL';
    var energyTag = todayLog != null ? todayLog['energyTag'] as String? : 'MEDIUM';
    final note = todayLog != null ? (todayLog['note'] as String? ?? '') : '';

    var symptoms = <String>[];
    if (todayLog != null && todayLog['symptomsJson'] != null) {
      try {
        final parsed = jsonDecode(todayLog['symptomsJson'] as String) as List<dynamic>;
        symptoms = parsed.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    final noteController = TextEditingController(text: note);

    final symptomsList = [
      {'key': 'cramps', 'label': 'دل‌درد و انقباض'},
      {'key': 'headache', 'label': 'سردرد'},
      {'key': 'bloating', 'label': 'نفخ شکم'},
      {'key': 'fatigue', 'label': 'خستگی بدنی'},
      {'key': 'backache', 'label': 'کمردرد'},
      {'key': 'mood_swings', 'label': 'نوسانات خُلق'},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var showSuccessLottie = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = context.colors;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            if (showSuccessLottie) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: RitmoSheetGlassCard(
                  child: Container(
                    height: 350,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Lottie.asset(
                            'assets/animations/workout_success.json',
                            repeat: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'احوال امروز با موفقیت ثبت شد 🌸',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: RitmoSheetGlassCard(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    top: 24,
                    left: 20,
                    right: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ثبت علائم و احوال امروز',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: isDark ? Colors.white : colors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(CupertinoIcons.xmark, color: isDark ? Colors.white54 : colors.textSecondary, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 1: Flow
                      _buildSectionHeader(CupertinoIcons.drop, 'میزان خونریزی یا ترشح بدنی', colors, isDark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          {'key': 'NONE', 'label': 'هیچ'},
                          {'key': 'LIGHT', 'label': 'خفیف'},
                          {'key': 'MEDIUM', 'label': 'متوسط'},
                          {'key': 'HEAVY', 'label': 'شدید'},
                        ].map((item) {
                          final f = item['key']!;
                          final label = item['label']!;
                          final active = flowLevel == f;
                          return ChoiceChip(
                            label: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: active ? Colors.white : (isDark ? Colors.white70 : colors.textSecondary))),
                            selected: active,
                            selectedColor: _getActivePhaseColor(),
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            checkmarkColor: Colors.white,
                            side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => flowLevel = f);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Mood
                      _buildSectionHeader(CupertinoIcons.smiley, 'حس و خُلق‌وخو', colors, isDark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          {'key': 'HAPPY', 'label': 'عالی'},
                          {'key': 'NEUTRAL', 'label': 'معمولی'},
                          {'key': 'SAD', 'label': 'بی‌حوصله'},
                          {'key': 'ANXIOUS', 'label': 'مضطرب'},
                          {'key': 'IRRITABLE', 'label': 'کلافه'},
                        ].map((item) {
                          final m = item['key']!;
                          final label = item['label']!;
                          final active = mood == m;
                          return ChoiceChip(
                            label: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: active ? Colors.white : (isDark ? Colors.white70 : colors.textSecondary))),
                            selected: active,
                            selectedColor: _getActivePhaseColor(),
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            checkmarkColor: Colors.white,
                            side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => mood = m);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Energy
                      _buildSectionHeader(CupertinoIcons.bolt, 'سطح انرژی بدنی', colors, isDark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          {'key': 'HIGH', 'label': 'پرانرژی'},
                          {'key': 'MEDIUM', 'label': 'معمولی'},
                          {'key': 'LOW', 'label': 'نیاز به استراحت'},
                        ].map((item) {
                          final e = item['key']!;
                          final label = item['label']!;
                          final active = energyTag == e;
                          return ChoiceChip(
                            label: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: active ? Colors.white : (isDark ? Colors.white70 : colors.textSecondary))),
                            selected: active,
                            selectedColor: _getActivePhaseColor(),
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            checkmarkColor: Colors.white,
                            side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => energyTag = e);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Section 4: Symptoms
                      _buildSectionHeader(CupertinoIcons.doc_plaintext, 'علائم جسمی شایع (انتخاب چندگانه)', colors, isDark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: symptomsList.map((s) {
                          final key = s['key']!;
                          final label = s['label']!;
                          final active = symptoms.contains(key);

                          var activeColor = const Color(0xffEC4899);
                          var symIcon = CupertinoIcons.tag;
                          if (key == 'cramps') {
                            activeColor = const Color(0xffF43F5E);
                            symIcon = CupertinoIcons.bolt_horizontal_fill;
                          } else if (key == 'headache') {
                            activeColor = const Color(0xff3B82F6);
                            symIcon = CupertinoIcons.sparkles;
                          } else if (key == 'bloating') {
                            activeColor = const Color(0xff10B981);
                            symIcon = CupertinoIcons.wind;
                          } else if (key == 'fatigue') {
                            activeColor = const Color(0xff8B5CF6);
                            symIcon = CupertinoIcons.battery_25;
                          } else if (key == 'backache') {
                            activeColor = const Color(0xffF59E0B);
                            symIcon = CupertinoIcons.arrow_down_right_arrow_up_left;
                          } else if (key == 'mood_swings') {
                            activeColor = const Color(0xffEC4899);
                            symIcon = CupertinoIcons.heart_slash_fill;
                          }

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setDialogState(() {
                                if (active) {
                                  symptoms.remove(key);
                                } else {
                                  symptoms.add(key);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? activeColor.withValues(alpha: 0.12) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active ? activeColor : (isDark ? Colors.white10 : Colors.grey.shade300),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    symIcon,
                                    color: active ? activeColor : (isDark ? Colors.white54 : colors.textSecondary),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 13,
                                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                      color: active ? activeColor : (isDark ? Colors.white70 : colors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Section 5: Notes
                      _buildSectionHeader(CupertinoIcons.pencil, 'یادداشت شخصی', colors, isDark),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        style: TextStyle(color: isDark ? Colors.white : colors.textPrimary, fontSize: 14, fontFamily: 'Vazirmatn'),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'جزئیات یا مشاهدات خود را بنویسید...',
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : colors.textSecondary.withValues(alpha: 0.3), fontSize: 14, fontFamily: 'Vazirmatn'),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getActivePhaseColor(),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final logId = todayLog != null ? todayLog['id'] as String : 'daylog_$nowMs';
                            final symptomsJson = jsonEncode(symptoms);

                            await db.insert(
                              'cycle_day_logs',
                              {
                                'id': logId,
                                'logDate': todayStr,
                                'flowLevel': flowLevel,
                                'symptomsJson': symptomsJson,
                                'mood': mood,
                                'energyTag': energyTag,
                                'note': noteController.text.trim(),
                                'createdAt': nowMs,
                                'updatedAt': nowMs,
                              },
                              conflictAlgorithm: ConflictAlgorithm.replace,
                            );

                            RitmoEvents.notifyRoutineChanged();

                            setDialogState(() {
                              showSuccessLottie = true;
                            });

                            await Future.delayed(const Duration(milliseconds: 1400));

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            await _loadData();
                          },
                          child: const Text('ذخیره احوال امروز', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildSectionHeader(IconData icon, String title, RitmoColors colors, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: _getActivePhaseColor(), size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Vazirmatn', 
            fontSize: 15.5, 
            color: isDark ? Colors.white70 : colors.textSecondary, 
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  String _translateSymptom(String key) {
    final lowerKey = key.toLowerCase();
    switch (lowerKey) {
      case 'cramps':
        return 'دل‌درد و انقباض';
      case 'headache':
        return 'سردرد';
      case 'bloating':
        return 'نفخ شکم';
      case 'fatigue':
        return 'خستگی بدنی';
      case 'backache':
        return 'کمردرد';
      case 'mood_swings':
        return 'نوسانات خُلق';
      default:
        if (key.length > 1) {
          return key[0].toUpperCase() + key.substring(1).toLowerCase();
        }
        return key;
    }
  }

  Widget _buildCycleSyncingWorkoutCard(RitmoColors colors, bool isDark) {
    final phase = _getCurrentDayPhase();
    var title = '';
    var description = '';
    var icon = CupertinoIcons.sparkles;
    var phaseColor = const Color(0xffEC4899);

    switch (phase) {
      case CyclePhase.menstrual:
        title = 'ورزش مناسب: کشش و یوگا 🌸';
        description = 'با توجه به فاز قاعدگی، امروز تمرینات سبک مانند یوگا، حرکات کششی و پیاده‌روی ملایم را انتخاب کنید تا بدن بازسازی شود.';
        icon = CupertinoIcons.heart_fill;
        phaseColor = const Color(0xffF43F5E);
      case CyclePhase.ovulation:
        title = 'ورزش مناسب: قدرت و استقامت 🔥';
        description = 'شما در فاز تخمک‌گذاری و اوج انرژی هستید. بهترین زمان برای تمرینات قدرتی پرفشار، پلایومتریک و چالش عضلات است.';
        icon = CupertinoIcons.flame_fill;
        phaseColor = const Color(0xffD946EF);
      case CyclePhase.luteal:
        title = 'ورزش مناسب: تمرینات تعادلی 🧘‍♀️';
        description = 'در فاز لوتئال انرژی به مرور کاهش می‌یابد. تمرینات با شدت متوسط، ورزش‌های تعادلی و روتین‌های کششی آرام‌بخش توصیه می‌شوند.';
        icon = CupertinoIcons.waveform_path_ecg;
        phaseColor = const Color(0xffF59E0B);
      case CyclePhase.follicular:
        title = 'ورزش مناسب: کاردیو و هوازی ⚡';
        description = 'در فاز فولیکولار سطح انرژی رو به افزایش است. زمان عالی برای ورزش‌های هوازی، دویدن و بالا بردن ضربان قلب است.';
        icon = CupertinoIcons.bolt_fill;
        phaseColor = const Color(0xff10B981);
      case CyclePhase.noData:
        title = 'ورزش متناسب با ریتم بدنی 🌸';
        description = 'با ثبت اطلاعات دوره، برنامه و حرکات پیشنهادی ورزشی شما به طور خودکار متناسب با فاز چرخه بدنتان همگام می‌شود.';
        icon = CupertinoIcons.sparkles;
        phaseColor = const Color(0xffEC4899);
    }

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: phaseColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                      height: 1.45,
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

  Widget? _buildSymptomPredictionCard(RitmoColors colors, bool isDark) {
    if (_engineOutput == null || !_engineOutput!.hasData || _symptomStats.isEmpty) return null;

    final currentDay = _engineOutput!.dayOfCycle;
    if (currentDay <= 0) return null;

    // Look for any symptom whose typicalCycleDay is within currentDay + 1 to currentDay + 3
    final upcomingSymptoms = <SymptomStat>[];
    for (final stat in _symptomStats) {
      final diff = stat.typicalCycleDay - currentDay;
      if (diff >= 1 && diff <= 3) {
        upcomingSymptoms.add(stat);
      }
    }

    if (upcomingSymptoms.isEmpty) return null;

    // Build the warning message
    final symptomsText = upcomingSymptoms.map((s) {
      final translated = _translateSymptom(s.key);
      final diff = s.typicalCycleDay - currentDay;
      return '$translated (${diff == 1 ? 'فردا' : 'در $diff روز آینده'})';
    }).join(' و ');

    const tip = 'توصیه خودمراقبتی: آب بیشتری بنوشید، از غذاهای شور بپرهیزید و روتین خواب و پیاده‌روی سبک را منظم نگه‌دارید. 🌸';

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(CupertinoIcons.bell_fill, color: Color(0xffF59E0B), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'احتمال بروز علائم در روزهای آینده ⚠️',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'بر اساس الگوهای قبلی، احتمالاً $symptomsText را تجربه کنید.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffF59E0B),
                      fontFamily: 'Vazirmatn',
                      height: 1.4,
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


  Widget _buildCalendarView(RitmoColors colors, bool isDark) {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final monthName = _calendarMonth.formatter.mN;
    final monthLength = _calendarMonth.monthLength;

    // Day week of first day (1: Saturday, 7: Friday)
    final firstDay = Jalali(year, month);
    final emptyCells = firstDay.weekDay - 1; // standard Jalali week index starts at Sat (1)

    final weekdaysHeaders = <String>['شنبه', 'یکشنبه', 'دوشنبه', 'سه شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          children: [
            // Calendar month selector header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(CupertinoIcons.right_chevron, color: _getActivePhaseColor(), size: 16),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = _calendarMonth.addMonths(-1);
                    });
                  },
                ),
                Column(
                  children: [
                    Text(
                      monthName,
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : colors.textPrimary, 
                        fontFamily: 'Vazirmatn'
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _toPersianDigits(year.toString()),
                      style: TextStyle(
                        fontSize: 10, 
                        color: colors.textSecondary.withValues(alpha: 0.7), 
                        fontFamily: 'Vazirmatn'
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.left_chevron, color: _getActivePhaseColor(), size: 16),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = _calendarMonth.addMonths(1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Weekday Headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekdaysHeaders.map((header) {
                return Expanded(
                  child: Center(
                    child: Text(
                      header,
                      style: TextStyle(fontSize: 9.5, color: colors.textSecondary.withValues(alpha: 0.8), fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Days grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: emptyCells + monthLength,
              itemBuilder: (context, index) {
                if (index < emptyCells) {
                  return const SizedBox();
                }

                final dayNum = index - emptyCells + 1;
                final dayJalali = Jalali(year, month, dayNum);
                final dayGregorian = dayJalali.toDateTime();

                final dateStr = dayGregorian.toIso8601String().substring(0, 10);

                // Check biological flags
                final isPeriodDay = _checkIsPeriodDay(dayGregorian);
                final isPredictedDay = _checkIsPredictedDay(dayGregorian);
                final isOvulationDay = _checkIsOvulationDay(dayGregorian);
                final isFertileDay = _checkIsFertileDay(dayGregorian);
                final hasLog = _checkHasLog(dateStr);

                final todayJalali = Jalali.now();
                final isToday = dayJalali.year == todayJalali.year &&
                    dayJalali.month == todayJalali.month &&
                    dayJalali.day == todayJalali.day;

                Color? cellBg;
                Border? cellBorder;
                var textColor = colors.textPrimary;
                final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
                final isSpecialDay = isPeriodDay || isPredictedDay || isOvulationDay || isFertileDay;

                final isPmsDay = _checkIsPmsDay(dayGregorian);

                if (isPeriodDay) {
                  cellBg = const Color(0xffF43F5E).withValues(alpha: 0.35);
                  textColor = isDarkTheme ? Colors.white : colors.textPrimary;
                } else if (isPredictedDay) {
                  cellBorder = Border.all(color: const Color(0xffF43F5E).withValues(alpha: 0.6), width: 1.5);
                } else if (isOvulationDay) {
                  cellBg = const Color(0xff06B6D4).withValues(alpha: 0.4);
                  cellBorder = Border.all(color: const Color(0xff06B6D4), width: 1.5);
                  textColor = isDarkTheme ? Colors.white : colors.textPrimary;
                } else if (isFertileDay) {
                  cellBg = const Color(0xff06B6D4).withValues(alpha: 0.15);
                } else if (isPmsDay) {
                  cellBg = const Color(0xffEC4899).withValues(alpha: 0.15);
                }

                if (isToday) {
                  cellBorder = Border.all(
                    color: isSpecialDay 
                        ? (isDarkTheme ? Colors.white : colors.textPrimary) 
                        : _getActivePhaseColor(), 
                    width: 2
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: cellBg,
                        border: cellBorder,
                        borderRadius: BorderRadius.circular(10), // Squircle design
                      ),
                      child: Center(
                        child: Text(
                          _toPersianDigits(dayNum.toString()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ),
                    if (hasLog)
                      Positioned(
                        bottom: 3,
                        child: Container(
                          height: 4,
                          width: 4,
                          decoration: BoxDecoration(
                            color: _getActivePhaseColor(), // Dynamic symptom dot matching active phase
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            _buildCalendarLegend(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarLegend(RitmoColors colors) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: isDarkTheme ? Colors.white10 : colors.border, height: 24),
        Text(
          'راهنمای تقویم چرخه بدنی:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkTheme ? Colors.white70 : colors.textPrimary, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildLegendItem(const Color(0xffF43F5E).withValues(alpha: 0.35), 'قاعدگی (پریود)', colors.textPrimary),
            _buildLegendItem(Colors.transparent, 'پیش‌بینی دوره بعدی', colors.textPrimary, borderColor: const Color(0xffF43F5E).withValues(alpha: 0.6)),
            _buildLegendItem(const Color(0xffEC4899).withValues(alpha: 0.15), 'روزهای پیش از عادت (PMS)', colors.textPrimary),
            _buildLegendItem(const Color(0xff06B6D4).withValues(alpha: 0.4), 'روز تخمک‌گذاری', colors.textPrimary, borderColor: const Color(0xff06B6D4)),
            _buildLegendItem(const Color(0xff06B6D4).withValues(alpha: 0.15), 'پنجره باروری (Fertile)', colors.textPrimary),
            _buildLegendItem(Colors.transparent, 'امروز', colors.textPrimary, borderColor: isDarkTheme ? Colors.white : colors.textPrimary),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: _getActivePhaseColor(), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('علائم ثبت شده', style: TextStyle(fontSize: 12, color: isDarkTheme ? Colors.white70 : colors.textSecondary, fontFamily: 'Vazirmatn')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color bg, String text, Color textColor, {Color? borderColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bg,
            border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
            borderRadius: BorderRadius.circular(4), // Squircle legend markers
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, color: textColor, fontFamily: 'Vazirmatn')),
      ],
    );
  }

  bool _checkIsPeriodDay(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    for (final p in _periods) {
      final pStart = DateTime.parse(p['startDate'] as String);
      final start = DateTime(pStart.year, pStart.month, pStart.day);
      final endStr = p['endDate'] as String?;
      final end = endStr != null ? DateTime.parse(endStr) : null;
      final cleanEnd = end != null ? DateTime(end.year, end.month, end.day) : null;

      if (!cleanDate.isBefore(start)) {
        if (cleanEnd != null) {
          if (!cleanDate.isAfter(cleanEnd)) return true;
        } else {
          // If ongoing, assume duration is setup period duration
          final pDur = int.tryParse(_settings['cycle_avg_period'] ?? '6') ?? 6;
          if (cleanDate.difference(start).inDays < pDur) return true;
        }
      }
    }
    return false;
  }

  int _calculateActivePeriodDay(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    for (final p in _periods) {
      final pStart = DateTime.parse(p['startDate'] as String);
      final start = DateTime(pStart.year, pStart.month, pStart.day);
      final endStr = p['endDate'] as String?;
      final end = endStr != null ? DateTime.parse(endStr) : null;
      final cleanEnd = end != null ? DateTime(end.year, end.month, end.day) : null;

      if (!cleanDate.isBefore(start)) {
        if (cleanEnd != null) {
          if (!cleanDate.isAfter(cleanEnd)) {
            return cleanDate.difference(start).inDays + 1;
          }
        } else {
          final pDur = int.tryParse(_settings['cycle_avg_period'] ?? '6') ?? 6;
          if (cleanDate.difference(start).inDays < pDur) {
            return cleanDate.difference(start).inDays + 1;
          }
        }
      }
    }
    return (_engineOutput?.dayOfPeriod ?? 0) > 0 ? _engineOutput!.dayOfPeriod : 1;
  }

  bool _checkIsPredictedDay(DateTime date) {
    if (_engineOutput == null) return false;
    final nextPeriod = _engineOutput!.nextPeriodPrediction;
    final cleanNextPeriod = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day);
    final cleanDate = DateTime(date.year, date.month, date.day);
    final pDur = int.tryParse(_settings['cycle_avg_period'] ?? '6') ?? 6;
    final diff = cleanDate.difference(cleanNextPeriod).inDays;
    return diff >= 0 && diff < pDur;
  }

  bool _checkIsOvulationDay(DateTime date) {
    if (_engineOutput == null || !_engineOutput!.hasData) return false;
    final cleanDate = DateTime(date.year, date.month, date.day);
    final ovulation = DateTime(_engineOutput!.ovulationDay.year, _engineOutput!.ovulationDay.month, _engineOutput!.ovulationDay.day);
    return cleanDate.isAtSameMomentAs(ovulation);
  }

  bool _checkIsFertileDay(DateTime date) {
    if (_engineOutput == null || !_engineOutput!.hasData) return false;
    final cleanDate = DateTime(date.year, date.month, date.day);
    final start = DateTime(_engineOutput!.fertileWindowStart.year, _engineOutput!.fertileWindowStart.month, _engineOutput!.fertileWindowStart.day);
    final end = DateTime(_engineOutput!.fertileWindowEnd.year, _engineOutput!.fertileWindowEnd.month, _engineOutput!.fertileWindowEnd.day);
    return !cleanDate.isBefore(start) && !cleanDate.isAfter(end);
  }

  bool _checkIsPmsDay(DateTime date) {
    if (_engineOutput == null || !_engineOutput!.hasData) return false;
    final cleanDate = DateTime(date.year, date.month, date.day);
    final start = DateTime(_engineOutput!.pmsWindowStart.year, _engineOutput!.pmsWindowStart.month, _engineOutput!.pmsWindowStart.day);
    final end = DateTime(_engineOutput!.pmsWindowEnd.year, _engineOutput!.pmsWindowEnd.month, _engineOutput!.pmsWindowEnd.day);
    return !cleanDate.isBefore(start) && !cleanDate.isAfter(end);
  }

  bool _checkHasLog(String dateStr) {
    for (final l in _dayLogs) {
      if (l['logDate'] == dateStr) return true;
    }
    return false;
  }

  Widget _buildIrregularityStatsCard(RitmoColors colors, bool isDark) {
    if (_engineOutput == null) return const SizedBox();

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.graph_square, color: Color(0xffF43F5E), size: 18),
                const SizedBox(width: 8),
                Text(
                  'آمار و ریتم بیولوژیک',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatPill('طول چرخه بدنی', '${_toPersianDigits(_engineOutput!.stats.avgCycleLength.toStringAsFixed(1))} روز'),
                _buildStatPill('طول قاعدگی', '${_toPersianDigits(_engineOutput!.stats.avgPeriodDuration.toStringAsFixed(1))} روز'),
                _buildStatPill('کل دوره‌ها', _toPersianDigits(_engineOutput!.stats.totalRecordedCycles.toString())),
              ],
            ),
            if (_engineOutput!.isIrregular) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'نوسان در طول چرخه‌ها مشاهده شد. این موضوع غالباً طبیعی است؛ در صورت تداوم می‌توانید آن را با پزشک متخصص مطرح کنید.',
                        style: TextStyle(fontSize: 14, color: Colors.amber, fontFamily: 'Vazirmatn', height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String val) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : context.colors.textSecondary, fontFamily: 'Vazirmatn')),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffF43F5E), fontFamily: 'Vazirmatn')),
      ],
    );
  }

  void _openSettingsSheet() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: RitmoSheetGlassCard(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsPanel(colors, isDark, setSheetState),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildSettingsPanel(RitmoColors colors, bool isDark, [StateSetter? setSheetState]) {
    final hasBiometrics = _settings['cycle_biometric_enabled'] == 'true';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.settings_solid, color: Color(0xffF43F5E), size: 18),
              const SizedBox(width: 8),
              Text(
                'تنظیمات و اتصالات حریم خصوصی',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleRow(
            title: 'قفل اثر انگشت / تشخیص چهره',
            value: hasBiometrics,
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'cycle_biometric_enabled',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildToggleRow(
            title: 'رمز عبور حریم خصوصی چرخه',
            value: _settings['cycle_lock_enabled'] != 'false',
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'cycle_lock_enabled',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          InkWell(
            onTap: () {
              Navigator.pop(context); // Close settings sheet
              _openChangePasscodeSheet();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🔑',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _settings['app_lock_password'] != null && _settings['app_lock_password']!.isNotEmpty
                            ? 'تغییر رمز عبور چرخه'
                            : 'تنظیم رمز عبور چرخه',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  Icon(CupertinoIcons.chevron_left, color: colors.textSecondary, size: 14),
                ],
              ),
            ),
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildToggleRow(
            title: 'تعلیق نماز و روزه در عبادات',
            value: _settings['cycle_consent_worship'] == 'true',
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'cycle_consent_worship',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildToggleRow(
            title: 'تعدیل فشار در روتین‌ها و انرژی',
            value: _settings['cycle_consent_energy'] == 'true',
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'cycle_consent_energy',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildToggleRow(
            title: 'تعدیل فشار در کیفیت خواب',
            value: _settings['cycle_consent_sleep'] == 'true',
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'cycle_consent_sleep',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildToggleRow(
            title: 'یادآوری‌های حریم خصوصی',
            value: _settings['cycle_consent_reminders'] == 'true',
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'cycle_consent_reminders',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildToggleRow(
            title: 'کارت داشبورد صفحه اصلی',
            value: _settings['cycle_consent_dashboard'] == 'true',
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'cycle_consent_dashboard',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildToggleRow(
            title: 'نمایش چرخه در تقویم و ریتم‌های روزانه',
            value: _settings['show_cycle_in_calendar'] == 'true',
            onChanged: (v) async {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {
                  'key': 'show_cycle_in_calendar',
                  'value': v.toString(),
                  'updatedAt': DateTime.now().millisecondsSinceEpoch
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _loadData();
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          InkWell(
            onTap: () async {
              final isPregnancyActive = _settings['cycle_pregnancy_mode'] == 'true';
              Navigator.pop(context);
              if (isPregnancyActive) {
                await _deactivatePregnancyFromSettings();
              } else {
                await _activatePregnancyFlow();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _settings['cycle_pregnancy_mode'] == 'true' ? '🔄' : '🤰',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _settings['cycle_pregnancy_mode'] == 'true'
                            ? 'بازگشت به حالت عادی چرخه قاعدگی'
                            : 'فعالسازی حالت بارداری',
                        style: TextStyle(
                          fontSize: 14,
                          color: _settings['cycle_pregnancy_mode'] == 'true'
                              ? const Color(0xffEC4899)
                              : colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  Icon(CupertinoIcons.chevron_left, color: colors.textSecondary, size: 14),
                ],
              ),
            ),
          ),
          Divider(height: 24, color: isDark ? Colors.white10 : colors.border),
          Text(
            'تنظیمات طول چرخه بدنی',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : colors.textPrimary, fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 12),
          _buildParameterRow(
            title: 'متوسط طول چرخه (فاصله شروع دو پریود)',
            value: '${_toPersianDigits(_settings['cycle_avg_length'] ?? '28')} روز',
            onTap: () async {
              await _editBaselineParameter('cycle_avg_length', 'طول کل چرخه بدنی', 21, 45, 28);
              if (setSheetState != null) setSheetState(() {});
            },
          ),
          Divider(height: 16, color: isDark ? Colors.white10 : colors.border),
          _buildParameterRow(
            title: 'متوسط طول دوره قاعدگی (خونریزی)',
            value: '${_toPersianDigits(_settings['cycle_avg_period'] ?? '6')} روز',
            onTap: () async {
              await _editBaselineParameter('cycle_avg_period', 'طول دوره قاعدگی', 3, 10, 6);
              if (setSheetState != null) setSheetState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : context.colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffF43F5E), fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.pencil, color: Color(0xffF43F5E), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : context.colors.textPrimary, fontFamily: 'Vazirmatn')),
        CupertinoSwitch(
          value: value,
          activeTrackColor: const Color(0xffF43F5E),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHistoryList(RitmoColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاریخچه دوره‌های قبلی',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
              TextButton.icon(
                onPressed: _addNewPeriodSheet,
                icon: const Icon(CupertinoIcons.plus, size: 16, color: Color(0xffF43F5E)),
                label: const Text(
                  'افزودن دوره قبلی',
                  style: TextStyle(fontSize: 14, color: Color(0xffF43F5E), fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_periods.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'هیچ دوره‌ای ثبت نشده است.',
                style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _periods.length,
            itemBuilder: (context, index) {
              final p = _periods[index];
              final startStr = p['startDate'] as String;
              final endStr = p['endDate'] as String?;

              var subtitle = 'شروع: ${_formatIsoToJalali(startStr)}';
              if (endStr != null) {
                subtitle += ' | پایان: ${_formatIsoToJalali(endStr)}';
              } else {
                subtitle += ' (در حال جریان)';
              }

              return Card(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    endStr != null ? 'دوره تکمیل‌شده' : 'دوره فعال بدنی',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.pencil, color: Color(0xffF43F5E), size: 18),
                        onPressed: () => _editPeriod(p),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.trash_fill, color: isDark ? Colors.white30 : colors.textSecondary.withValues(alpha: 0.3), size: 18),
                        onPressed: () => _deletePeriod(p['id'] as String),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _activatePregnancyFlow() async {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'فعالسازی حالت بارداری',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'آیا باردار هستید؟ با فعالسازی این حالت، پیگیری چرخه قاعدگی متوقف می‌شود و اطلاعات دوران بارداری نمایش داده می‌شود.',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: isDark ? Colors.white70 : colors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: isDark ? Colors.white60 : colors.textSecondary.withValues(alpha: 0.7))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getActivePhaseColor(),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('بله، فعالسازی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed ?? false) {
      if (!mounted) return;
      final picked = await RitmoDatePicker.showJalali(
        context: context,
        initialDate: Jalali.now(),
        firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 300))),
        lastDate: Jalali.now(),
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).brightness == Brightness.dark
                              ? const ColorScheme.dark(
                                  primary: Color(0xffEC4899),
                                  onPrimary: Colors.white,
                                  surface: Colors.transparent,
                                )
                              : ColorScheme.light(
                                  primary: const Color(0xffEC4899),
                                  onSurface: context.colors.textPrimary,
                                ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1A1625) : Colors.white),
                ),
                child: child!,
              ),
            ),
          );
        },
      );

      if (picked != null) {
        final lmp = picked.toDateTime();
        final edd = lmp.add(const Duration(days: 280));
        
        final lmpStr = lmp.toIso8601String().substring(0, 10);
        final eddStr = edd.toIso8601String().substring(0, 10);

        final db = await DatabaseHelper.instance.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert(
          'app_settings',
          {'key': 'cycle_pregnancy_mode', 'value': 'true', 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await db.insert(
          'app_settings',
          {'key': 'cycle_pregnancy_start_date', 'value': lmpStr, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await db.insert(
          'app_settings',
          {'key': 'cycle_pregnancy_due_date', 'value': eddStr, 'updatedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await _loadData();
      }
    }
  }

  Future<void> _deactivatePregnancyFromSettings() async {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'غیرفعالسازی حالت بارداری',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'آیا مایل به خروج از حالت بارداری و بازگشت به پیگیری چرخه قاعدگی معمولی هستید؟ داده‌های چرخه قبلی شما حفظ خواهند شد.',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, color: isDark ? Colors.white70 : colors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: isDark ? Colors.white60 : colors.textSecondary.withValues(alpha: 0.7))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEC4899),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('بله، بازگشت', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed ?? false) {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {'key': 'cycle_pregnancy_mode', 'value': 'false', 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _loadData();
    }
  }

  void _openChangePasscodeSheet() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPassword = _settings['app_lock_password'] ?? '';
    final hasPassword = currentPassword.isNotEmpty;

    var step = hasPassword ? 0 : 1;
    var enteredPin = '';
    String? firstNewPin;
    var errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          
          var titleText = 'تغییر رمز عبور چرخه';
          var subtitleText = '';
          if (step == 0) {
            titleText = 'تایید رمز عبور فعلی';
            subtitleText = 'لطفاً رمز عبور ۴ رقمی فعلی خود را وارد کنید.';
          } else if (step == 1) {
            titleText = 'تعیین رمز عبور جدید';
            subtitleText = 'یک رمز عبور ۴ رقمی جدید برای این بخش وارد کنید.';
          } else if (step == 2) {
            titleText = 'تایید رمز عبور جدید';
            subtitleText = 'لطفاً رمز عبور جدید خود را مجدداً وارد کنید.';
          }

          void onPinKeyTapped(String key) {
            if (enteredPin.length >= 4) return;
            HapticFeedback.lightImpact();
            setSheetState(() {
              errorMessage = '';
              enteredPin += key;
            });

            if (enteredPin.length == 4) {
              Future.delayed(const Duration(milliseconds: 250), () async {
                if (step == 0) {
                  if (enteredPin == currentPassword) {
                    HapticFeedback.mediumImpact();
                    setSheetState(() {
                      step = 1;
                      enteredPin = '';
                      errorMessage = '';
                    });
                  } else {
                    HapticFeedback.heavyImpact();
                    setSheetState(() {
                      enteredPin = '';
                      errorMessage = 'رمز عبور فعلی نادرست است.';
                    });
                  }
                } else if (step == 1) {
                  HapticFeedback.mediumImpact();
                  setSheetState(() {
                    firstNewPin = enteredPin;
                    enteredPin = '';
                    step = 2;
                    errorMessage = '';
                  });
                } else if (step == 2) {
                  if (enteredPin == firstNewPin) {
                    final db = await DatabaseHelper.instance.database;
                    final nowMs = DateTime.now().millisecondsSinceEpoch;
                    await db.insert(
                      'app_settings',
                      {
                        'key': 'app_lock_password',
                        'value': enteredPin,
                        'updatedAt': nowMs,
                      },
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    );
                    HapticFeedback.mediumImpact();
                    await _loadData();
                    if (context.mounted) {
                      Navigator.pop(context); // Close sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('رمز عبور چرخه با موفقیت ذخیره شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
                        ),
                      );
                    }
                  } else {
                    HapticFeedback.heavyImpact();
                    setSheetState(() {
                      enteredPin = '';
                      firstNewPin = null;
                      step = 1;
                      errorMessage = 'رمز عبور با تاییدیه مطابقت ندارد. دوباره تعریف کنید.';
                    });
                  }
                }
              });
            }
          }

          void onBackspaceTapped() {
            if (enteredPin.isEmpty) return;
            HapticFeedback.lightImpact();
            setSheetState(() {
              errorMessage = '';
              enteredPin = enteredPin.substring(0, enteredPin.length - 1);
            });
          }

          Widget buildKeyBtn(String key) {
            return GestureDetector(
              onTap: () => onPinKeyTapped(key),
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _toPersianDigits(key),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
            );
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: RitmoSheetGlassCard(
              child: Padding(
                padding: EdgeInsets.only(bottom: viewInsets.bottom + 16, left: 24, right: 24, top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xffF43F5E), size: 22),
                        Text(
                          titleText,
                          style: TextStyle(
                            fontSize: 16,
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
                    const Divider(height: 16, color: Colors.white10),
                    const SizedBox(height: 12),
                    Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isActive = enteredPin.length > index;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          height: 12,
                          width: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xffF43F5E)
                                : (isDark ? Colors.white24 : Colors.black12),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['1', '2', '3'].map(buildKeyBtn).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['4', '5', '6'].map(buildKeyBtn).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['7', '8', '9'].map(buildKeyBtn).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 48, height: 48),
                              buildKeyBtn('0'),
                              GestureDetector(
                                onTap: onBackspaceTapped,
                                child: Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: colors.textPrimary.withValues(alpha: 0.04),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(CupertinoIcons.delete_left, color: colors.textPrimary, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddEditPeriodSheet extends StatefulWidget {

  const _AddEditPeriodSheet({
    this.period,
    required this.onValidate,
    required this.onSave,
  });
  final Map<String, dynamic>? period;
  final String? Function(DateTime startDate, DateTime? endDate) onValidate;
  final Function(DateTime startDate, DateTime? endDate) onSave;

  @override
  State<_AddEditPeriodSheet> createState() => _AddEditPeriodSheetState();
}

class _AddEditPeriodSheetState extends State<_AddEditPeriodSheet> {
  late DateTime _startDate;
  DateTime? _endDate;
  bool _hasEndDate = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.period != null) {
      _startDate = DateTime.parse(widget.period!['startDate'] as String);
      final endStr = widget.period!['endDate'] as String?;
      if (endStr != null) {
        _endDate = DateTime.parse(endStr);
        _hasEndDate = true;
      }
    } else {
      _startDate = DateTime.now();
      _endDate = null;
      _hasEndDate = false;
    }
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

  String _formatJalaliDate(DateTime dt) {
    final jal = Jalali.fromDateTime(dt);
    return '${_toPersianDigits(jal.year.toString())}/${_toPersianDigits(jal.month.toString().padLeft(2, '0'))}/${_toPersianDigits(jal.day.toString().padLeft(2, '0'))}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoSheetGlassCard(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.period != null ? 'ویرایش تاریخ‌های دوره قاعدگی' : 'افزودن دوره قاعدگی جدید',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      color: isDark ? Colors.white : colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: isDark ? Colors.white54 : colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorText != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('تاریخ شروع دوره:', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : colors.textSecondary, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await RitmoDatePicker.showJalali(
                    context: context,
                    initialDate: Jalali.fromDateTime(_startDate),
                    firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365))),
                    lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 30))),
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).brightness == Brightness.dark
                                  ? const ColorScheme.dark(
                                      primary: Color(0xffF43F5E),
                                      onPrimary: Colors.white,
                                      surface: Colors.transparent,
                                    )
                                  : ColorScheme.light(
                                      primary: const Color(0xffF43F5E),
                                      onSurface: context.colors.textPrimary,
                                    ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1A1625) : Colors.white),
                            ),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.toDateTime();
                      _errorText = null;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatJalaliDate(_startDate),
                        style: TextStyle(color: isDark ? Colors.white : colors.textPrimary, fontSize: 14, fontFamily: 'Vazirmatn'),
                      ),
                      const Icon(CupertinoIcons.calendar, color: Color(0xffF43F5E), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('این دوره پایان یافته است', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : colors.textSecondary, fontFamily: 'Vazirmatn')),
                  CupertinoSwitch(
                    value: _hasEndDate,
                    activeTrackColor: const Color(0xffF43F5E),
                    onChanged: (v) {
                      setState(() {
                        _hasEndDate = v;
                        if (v && _endDate == null) {
                          _endDate = _startDate.add(const Duration(days: 5));
                        }
                        _errorText = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_hasEndDate) ...[
                Text('تاریخ پایان دوره:', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : colors.textSecondary, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await RitmoDatePicker.showJalali(
                      context: context,
                      initialDate: Jalali.fromDateTime((_endDate == null || _endDate!.isBefore(_startDate)) ? _startDate : _endDate!),
                      firstDate: Jalali.fromDateTime(_startDate),
                      lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 30))),
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).brightness == Brightness.dark
                                    ? const ColorScheme.dark(
                                        primary: Color(0xffF43F5E),
                                        onPrimary: Colors.white,
                                        surface: Colors.transparent,
                                      )
                                    : ColorScheme.light(
                                        primary: const Color(0xffF43F5E),
                                        onSurface: context.colors.textPrimary,
                                      ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1A1625) : Colors.white),
                              ),
                              child: child!,
                            ),
                          ),
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked.toDateTime();
                        _errorText = null;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _endDate != null ? _formatJalaliDate(_endDate!) : 'انتخاب تاریخ',
                          style: TextStyle(color: isDark ? Colors.white : colors.textPrimary, fontSize: 14, fontFamily: 'Vazirmatn'),
                        ),
                        const Icon(CupertinoIcons.calendar, color: Color(0xffF43F5E), size: 20),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF43F5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final error = widget.onValidate(_startDate, _hasEndDate ? _endDate : null);
                    if (error != null) {
                      setState(() {
                        _errorText = error;
                      });
                      return;
                    }
                    widget.onSave(_startDate, _hasEndDate ? _endDate : null);
                    Navigator.pop(context);
                  },
                  child: Text(
                    widget.period != null ? 'ذخیره تغییرات' : 'افزودن دوره',
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class CycleAnimatedBackground extends StatefulWidget {
  
  const CycleAnimatedBackground({
    super.key,
    required this.phase,
    required this.isDark,
    this.isPregnancy = false,
  });
  final CyclePhase phase;
  final bool isDark;
  final bool isPregnancy;

  @override
  State<CycleAnimatedBackground> createState() => _CycleAnimatedBackgroundState();
}

class _CycleAnimatedBackgroundState extends State<CycleAnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    Color secondaryColor;
    Color tertiaryColor;
    Color baseBgColor;

    if (widget.isPregnancy) {
      primaryColor = const Color(0xffEC4899).withValues(alpha: 0.85);
      secondaryColor = const Color(0xff8B5CF6).withValues(alpha: 0.80);
      tertiaryColor = const Color(0xffF59E0B).withValues(alpha: 0.75);
    } else {
      // Determine bubble colors based on phase (matching calendar markers)
      switch (widget.phase) {
        case CyclePhase.menstrual: // Period (Coral/Pink)
          primaryColor = const Color(0xffF43F5E).withValues(alpha: 0.85);
          secondaryColor = const Color(0xffEC4899).withValues(alpha: 0.80);
          tertiaryColor = const Color(0xffFB7185).withValues(alpha: 0.75);
        case CyclePhase.ovulation: // Fertile Window (Teal/Cyan)
          primaryColor = const Color(0xff06B6D4).withValues(alpha: 0.85);
          secondaryColor = const Color(0xff22D3EE).withValues(alpha: 0.80);
          tertiaryColor = const Color(0xff0EA5E9).withValues(alpha: 0.75);
        case CyclePhase.luteal: // Pre-period / PMS (Magenta/Amber)
          primaryColor = const Color(0xffEC4899).withValues(alpha: 0.85);
          secondaryColor = const Color(0xffFB7185).withValues(alpha: 0.80);
          tertiaryColor = const Color(0xffF59E0B).withValues(alpha: 0.75);
        case CyclePhase.follicular: // Clean days (Lavender/Violet)
        default:
          primaryColor = const Color(0xff8B5CF6).withValues(alpha: 0.85);
          secondaryColor = const Color(0xffC084FC).withValues(alpha: 0.80);
          tertiaryColor = const Color(0xffA78BFA).withValues(alpha: 0.75);
      }
    }

    if (widget.isDark) {
      baseBgColor = const Color(0xff0A0B10); // Very dark slate
    } else {
      baseBgColor = const Color(0xffF9FAFB); // Very light grey/white
    }

    return Stack(
      children: [
        // 1. Solid base background
        Positioned.fill(
          child: Container(
            color: baseBgColor,
          ),
        ),

        // 2. Glowing Colored Floating Blobs underneath glass
        // Blob 1 (Top-Left)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * 2 * math.pi;
            final dx = math.sin(angle) * 70;
            final dy = math.cos(angle) * 90;
            return Positioned(
              top: 80 + dy,
              left: -40 + dx,
              child: child!,
            );
          },
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Blob 2 (Bottom-Right)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * 2 * math.pi + math.pi;
            final dx = math.sin(angle) * 80;
            final dy = math.cos(angle) * 70;
            return Positioned(
              bottom: 120 + dy,
              right: -50 + dx,
              child: child!,
            );
          },
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Blob 3 (Top-Right)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * 2 * math.pi;
            final dx = math.cos(angle * 1.2) * 60;
            final dy = math.sin(angle * 1.2) * 50;
            return Positioned(
              top: 220 + dy,
              right: -40 + dx,
              child: child!,
            );
          },
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: tertiaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Blob 4 (Bottom-Left)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * 2 * math.pi + math.pi / 2;
            final dx = math.cos(angle * 0.8) * 50;
            final dy = math.sin(angle * 0.8) * 80;
            return Positioned(
              bottom: 220 + dy,
              left: -50 + dx,
              child: child!,
            );
          },
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.65),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 3. Full-screen Blur & Glass Pane Overlay
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xff12141C).withValues(alpha: 0.50) // Smoky glass (iOS style)
                      : Colors.white.withValues(alpha: 0.35), // White glass (iOS style)
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RitmoSheetGlassCard extends StatelessWidget {
  const RitmoSheetGlassCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.65),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                left: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                right: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}



class _CycleProgressRingPainter extends CustomPainter {

  _CycleProgressRingPainter({
    required this.percentage,
    required this.activeColor,
    required this.isDark,
  });
  final double percentage;
  final Color activeColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 8.0;

    // Background track
    final paintBg = Paint()
      ..color = activeColor.withValues(alpha: isDark ? 0.20 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBg);

    if (percentage <= 0) return;

    // Active sweep arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paintActive = Paint()
      ..shader = SweepGradient(
        colors: [
          activeColor.withValues(alpha: 0.35),
          activeColor,
          activeColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      paintActive,
    );

    // Glow indicator at the thumb
    final thumbAngle = -math.pi / 2 + sweepAngle;
    final thumbX = center.dx + radius * math.cos(thumbAngle);
    final thumbY = center.dy + radius * math.sin(thumbAngle);

    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final thumbShadowPaint = Paint()
      ..color = activeColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(thumbX, thumbY), 9, thumbShadowPaint);
    canvas.drawCircle(Offset(thumbX, thumbY), 4.5, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _CycleProgressRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDark != isDark;
  }
}
