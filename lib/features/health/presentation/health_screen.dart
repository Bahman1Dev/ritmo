import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/analytics/health_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/features/health/presentation/pages/health_insights_page.dart';
// Import new subpages
import 'package:ritmo/features/health/presentation/pages/medications_page.dart';
import 'package:ritmo/features/health/presentation/pages/monitoring_page.dart';
import 'package:ritmo/features/health/presentation/pages/records_page.dart';
import 'package:ritmo/features/health/presentation/pages/visits_page.dart';
// Import sheets
import 'package:ritmo/features/health/presentation/widgets/ai_health_assistant_sheet.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _isLoading = true;

  // Live summaries
  String _medicationsSummary = 'در حال بارگذاری...';
  String _monitoringSummary = 'در حال بارگذاری...';
  String _visitsSummary = 'در حال بارگذاری...';
  String _recordsSummary = 'در حال بارگذاری...';

  // Next upcoming dose
  String? _nextDoseName;
  String? _nextDoseTimeStr;
  String _countdownText = 'بارگذاری نوبت بعدی...';

  // Subsystem alerts
  List<String> _criticalAlerts = [];

  HealthEngineOutput? _engineOutput;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Start live countdown timer to update every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _calculateNextDoseCountdown();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

  String _jalaliMonthName(int month) {
    const months = [
      'فروردین', 'اردیبهشت', 'خرداد',
      'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر',
      'دی', 'بهمن', 'اسفند'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  Future<void> _loadDashboardData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;

      // 1. Fetch medications count & next dose
      final routines = await db.query(
        'routines',
        where: "category = 'medical' AND isArchived = 0",
      );
      final occurrences = await db.query(
        'routine_occurrences',
        where: 'date = ?',
        whereArgs: [todayStr],
      );
      final medLogs = await db.query(
        'medication_logs',
        where: 'createdAt >= ?',
        whereArgs: [startOfDay],
      );

      final scheduledIds = routines
          .where((r) => r['routineType'] != 'asNeeded')
          .map((r) => r['id']! as String)
          .toSet();

      final todayScheduledOcc = occurrences
          .where((o) => scheduledIds.contains(o['routine_id']))
          .toList();

      final totalScheduled = todayScheduledOcc.length;
      final takenScheduledIds = medLogs
          .where((l) => l['status'] == 'TAKEN')
          .map((l) => l['routineId']! as String)
          .toSet();

      final completedScheduled = todayScheduledOcc
          .where((o) => takenScheduledIds.contains(o['routine_id']))
          .length;

      // Find next upcoming scheduled medication
      String? nextMedName;
      String? nextMedTimeStr;
      
      final pendingScheduled = todayScheduledOcc
          .where((o) => o['status'] == 'pending')
          .toList();

      if (pendingScheduled.isNotEmpty) {
        pendingScheduled.sort((a, b) {
          final tA = a['scheduled_time'] as String? ?? '00:00';
          final tB = b['scheduled_time'] as String? ?? '00:00';
          return tA.compareTo(tB);
        });

        final nextOcc = pendingScheduled.first;
        final nextRoutine = routines.firstWhere((r) => r['id'] == nextOcc['routine_id']);
        nextMedName = nextRoutine['title'] as String?;
        nextMedTimeStr = nextOcc['scheduled_time'] as String?;
      }

      final medsSummary = '$completedScheduled از $totalScheduled دارو مصرف شده';

      // 2. Fetch last blood sugar & blood pressure
      final sugarLogs = await db.query('blood_sugar_logs', orderBy: 'loggedAt DESC', limit: 1);
      final bpLogs = await db.query('blood_pressure_logs', orderBy: 'loggedAt DESC', limit: 1);

      var sugarPart = '';
      if (sugarLogs.isNotEmpty) {
        sugarPart = 'قند ${sugarLogs.first['value']}';
      }

      var bpPart = '';
      if (bpLogs.isNotEmpty) {
        final sys = bpLogs.first['systolic']! as int;
        final dia = bpLogs.first['diastolic']! as int;
        
        final sysStr = (sys / 10.0).toStringAsFixed(sys % 10 == 0 ? 0 : 1);
        final diaStr = (dia / 10.0).toStringAsFixed(dia % 10 == 0 ? 0 : 1);
        bpPart = 'فشار $sysStr/$diaStr';
      }

      var monitoringSummary = 'سنجشی ثبت نشده است';
      if (sugarPart.isNotEmpty && bpPart.isNotEmpty) {
        monitoringSummary = '$sugarPart · $bpPart';
      } else if (sugarPart.isNotEmpty) {
        monitoringSummary = sugarPart;
      } else if (bpPart.isNotEmpty) {
        monitoringSummary = bpPart;
      }

      // 3. Fetch doctor visits
      final visitResults = await db.query(
        'doctor_visits', 
        where: "visitDateTime > ? AND status = 'UPCOMING'",
        whereArgs: [nowMs],
        orderBy: 'visitDateTime ASC', 
        limit: 1,
      );
      var visitsSummary = 'نوبت فعالی ثبت نشده است';
      if (visitResults.isNotEmpty) {
        final doctor = visitResults.first['doctorName'] as String? ?? 'پزشک';
        final dt = DateTime.fromMillisecondsSinceEpoch(visitResults.first['visitDateTime']! as int);
        final j = Jalali.fromDateTime(dt);
        visitsSummary = 'نوبت بعدی: ${j.day} ${_jalaliMonthName(j.month)}، $doctor';
      }

      // 4. Fetch records summary
      final docsRes = await db.query('medical_documents');
      final allergyRes = await db.query('allergies');
      final recordsSummary = '${docsRes.length} مدرک · ${allergyRes.length} آلرژی ثبت‌شده';

      // 5. Load alerts
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      final pregnancyEnabled = settingsMap['module_pregnancy_enabled'] == 'true';
      final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
      final showPreg = isFemale && pregnancyEnabled;

      final alerts = <String>[];

      // A. Medications alerts (low stock)
      final lowStockMeds = await db.query(
        'routines',
        where: "category = 'medical' AND isArchived = 0 AND medStockCount <= medRefillThreshold AND medStockCount > 0",
      );
      for (final med in lowStockMeds) {
        alerts.add('موجودی داروی «${med['title']}» رو به اتمام است (${med['medStockCount']} عدد باقی‌مانده).');
      }

      // B. Blood sugar alerts (hypo/hyperglycemia)
      if (sugarLogs.isNotEmpty) {
        final val = sugarLogs.first['value']! as int;
        final type = sugarLogs.first['measurementType']! as String;
        final isDiabetic = settingsMap['patient_has_diabetes'] == 'true';
        
        var maxVal = isDiabetic ? 130 : 100;
        if (type == 'AFTER_MEAL' || type == 'RANDOM') maxVal = isDiabetic ? 180 : 140;

        if (val < 70) {
          alerts.add('⚠️ هشدار افت شدید قند خون (کمتر از ۷۰): مقدار $val ثبت شده است!');
        } else if (val > maxVal + 50) {
          alerts.add('⚠️ هشدار افزایش شدید قند خون: مقدار $val ثبت شده است!');
        }
      }

      // C. Blood pressure alerts (crisis)
      if (bpLogs.isNotEmpty) {
        final sys = bpLogs.first['systolic']! as int;
        final dia = bpLogs.first['diastolic']! as int;
        if (sys > 180 || dia > 120) {
          alerts.add('🚨 بحران فشار خون ($sys/$dia): نیاز به بررسی فوری پزشکی!');
        }
      }

      // D. Labor contraction alert (5-1-1)
      if (showPreg) {
        final activePreg = await db.query('pregnancy_tracker', where: 'isActive = 1', limit: 1);
        if (activePreg.isNotEmpty) {
          final trackerId = activePreg.first['id']! as String;
          final contractionRes = await db.query(
            'contraction_timer',
            where: 'pregnancyId = ?',
            whereArgs: [trackerId],
            orderBy: 'loggedAt DESC',
          );
          
          if (contractionRes.length >= 3) {
            final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
            final recent = contractionRes.where((c) => (c['loggedAt']! as int) >= oneHourAgo).toList();

            if (recent.length >= 3) {
              var matches511 = true;
              for (var i = 0; i < recent.length; i++) {
                final duration = recent[i]['durationSeconds']! as int;
                final interval = recent[i]['intervalFromPrevious']! as int;
                if (duration < 60) matches511 = false;
                if (i < recent.length - 1 && (interval > 300 || interval == 0)) matches511 = false;
              }
              if (matches511) {
                alerts.add('🤰 هشدار زایمان فعال (انقباضات ۵-۱-۱): لطفاً فوراً با اورژانس یا بخش زایمان تماس بگیرید!');
              }
            }
          }
        }
      }

      // E. Calculate Health Engine data
      final allSugars = await db.query('blood_sugar_logs', orderBy: 'loggedAt DESC');
      final sugarLogsList = allSugars.map(BloodSugarLog.fromMap).toList();

      final allBps = await db.query('blood_pressure_logs', orderBy: 'loggedAt DESC');
      final bpLogsList = allBps.map(BloodPressureLog.fromMap).toList();

      final allVitals = await db.query('vital_signs_logs', orderBy: 'loggedAt DESC');
      final vitalLogsList = allVitals.map(VitalSignLog.fromMap).toList();

      final allMedicationLogs = await db.query('medication_logs', orderBy: 'createdAt DESC');
      final medLogsList = allMedicationLogs.map(MedicationLog.fromMap).toList();

      final prnLogsRes = await db.query('prn_logs', orderBy: 'takenAt DESC');
      final energyLogsRes = await db.query('energy_logs', orderBy: 'loggedAt DESC');
      final sleepLogsRes = await db.query('bedtime_diagnostics', orderBy: 'createdAt DESC');

      final engineInput = HealthEngineInput(
        bloodSugarLogs: sugarLogsList,
        bloodPressureLogs: bpLogsList,
        vitalSignLogs: vitalLogsList,
        medicationLogs: medLogsList,
        prnLogs: prnLogsRes,
        energyLogs: energyLogsRes,
        sleepLogs: sleepLogsRes,
        hasDiabetes: settingsMap['patient_has_diabetes'] == 'true',
        hasHypertension: settingsMap['patient_has_hypertension'] == 'true',
        today: DateTime.now(),
      );

      final engineOutput = HealthEngine.calculateSync(engineInput);

      if (mounted) {
        setState(() {
          _medicationsSummary = medsSummary;
          _monitoringSummary = monitoringSummary;
          _visitsSummary = visitsSummary;
          _recordsSummary = recordsSummary;
          
          _nextDoseName = nextMedName;
          _nextDoseTimeStr = nextMedTimeStr;
          
          _criticalAlerts = alerts;
          _engineOutput = engineOutput;
          _isLoading = false;
        });

        _calculateNextDoseCountdown();
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateNextDoseCountdown() {
    if (!mounted) return;
    if (_nextDoseTimeStr == null || _nextDoseName == null) {
      setState(() {
        _countdownText = 'برنامه دارویی فعال برای امروز تعریف نشده است 💊';
      });
      return;
    }

    final now = DateTime.now();
    final parts = _nextDoseTimeStr!.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    
    final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
    final diff = scheduledDateTime.difference(now);
    
    setState(() {
      if (diff.isNegative) {
        final overdueMins = diff.inMinutes.abs();
        _countdownText = 'نوبت داروی «$_nextDoseName» با تأخیر ($overdueMins دقیقه قبل)';
      } else {
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        final timeRemainingStr = hours > 0 
            ? '$hours ساعت و $minutes دقیقه مانده' 
            : '$minutes دقیقه مانده';
        _countdownText = 'دوز بعدی: «$_nextDoseName» ($timeRemainingStr)';
      }
    });
  }

  void _openAiAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: AiHealthAssistantSheet(),
      ),
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSkeletonLoading(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SlideFadeTransition(
                        delay: Duration.zero,
                        child: _buildHeader(),
                      ),
                      if (_criticalAlerts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SlideFadeTransition(
                          delay: const Duration(milliseconds: 100),
                          child: _buildAlertsBanner(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SlideFadeTransition(
                        delay: const Duration(milliseconds: 150),
                        child: _buildStatusHero(),
                      ),
                      const SizedBox(height: 20),
                      SlideFadeTransition(
                        delay: const Duration(milliseconds: 200),
                        child: _buildGridMenu(),
                      ),
                      const SizedBox(height: 20),
                      SlideFadeTransition(
                        delay: const Duration(milliseconds: 250),
                        child: _buildTrendsCard(
                          onTap: () => _navigateToPage(const HealthInsightsPage()),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                  onPressed: () => Navigator.maybePop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Text(
                  'سلامت',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'پایش داروها، سنجش‌های حیاتی و پرونده پزشکی',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _openAiAssistant,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
            ),
            child: Icon(CupertinoIcons.sparkles, color: colors.primary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsBanner() {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.medicalRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          right: BorderSide(color: colors.medicalRed, width: 4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _criticalAlerts.map((alert) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.medicalRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _toPersianDigits(alert),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.medicalRed,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusHero() {
    final colors = context.colors;
    final stats = _engineOutput?.adherence;
    final rate = stats?.adherenceRate ?? 0.0;
    final streak = stats?.currentStreak ?? 0;
    final hasMeds = _nextDoseName != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'پایبندی دارویی',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      streak > 0
                          ? '🔥 ${_toPersianDigits(streak.toString())} روز پایبندی متوالی! فوق‌العاده است.'
                          : 'با ثبت به‌موقع مصرف داروها، وضعیت خود را بهبود دهید.',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: rate / 100.0,
                      strokeWidth: 6,
                      backgroundColor: colors.border.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                    Text(
                      '%${_toPersianDigits(rate.toStringAsFixed(0))}',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  hasMeds ? CupertinoIcons.time : CupertinoIcons.info_circle,
                  color: hasMeds ? colors.primary : colors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _toPersianDigits(_countdownText),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: hasMeds ? FontWeight.bold : FontWeight.normal,
                      color: hasMeds ? colors.textPrimary : colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildHubCard(
          title: 'داروها',
          subtitle: _medicationsSummary,
          icon: CupertinoIcons.capsule_fill,
          color: const Color(0xff3B82F6),
          onTap: () => _navigateToPage(const MedicationsPage()),
        ),
        _buildHubCard(
          title: 'پایش سلامت',
          subtitle: _monitoringSummary,
          icon: CupertinoIcons.waveform_path,
          color: const Color(0xffF59E0B),
          onTap: () => _navigateToPage(const MonitoringPage()),
        ),
        _buildHubCard(
          title: 'نوبت‌های پزشک',
          subtitle: _visitsSummary,
          icon: CupertinoIcons.calendar_badge_plus,
          color: const Color(0xff10B981),
          onTap: () => _navigateToPage(const VisitsPage()),
        ),
        _buildHubCard(
          title: 'پرونده پزشکی',
          subtitle: _recordsSummary,
          icon: CupertinoIcons.folder_fill,
          color: const Color(0xff8B5CF6),
          onTap: () => _navigateToPage(const RecordsPage()),
        ),
      ],
    );
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(CupertinoIcons.arrow_up_left, color: colors.textSecondary.withValues(alpha: 0.4), size: 14),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _toPersianDigits(subtitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsCard({required VoidCallback onTap}) {
    const identityColor = Color(0xff8B5CF6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [identityColor, identityColor.withValues(alpha: 0.85)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: identityColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.chart_bar_square, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'روندها و تحلیل سلامت',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'بررسی پایبندی دارویی و همبستگی شاخص‌های حیاتی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_left, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: List.generate(4, (_) => Container(
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
            ),
          )),
        ),
      ],
    );
  }
}

class SlideFadeTransition extends StatelessWidget {

  const SlideFadeTransition({
    super.key,
    required this.child,
    required this.delay,
  });
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 20.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
