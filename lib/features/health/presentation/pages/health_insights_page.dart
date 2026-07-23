import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/analytics/health_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/features/health/presentation/widgets/adherence_card.dart';
import 'package:ritmo/features/health/presentation/widgets/doctor_visit_summary_sheet.dart';
import 'package:ritmo/features/health/presentation/widgets/health_correlation_section.dart';
import 'package:ritmo/features/health/presentation/widgets/health_trends_section.dart';

class HealthInsightsPage extends StatefulWidget {
  const HealthInsightsPage({super.key});

  @override
  State<HealthInsightsPage> createState() => _HealthInsightsPageState();
}

class _HealthInsightsPageState extends State<HealthInsightsPage> {
  bool _isLoading = true;
  HealthEngineOutput? _engineOutput;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final sugarRes = await db.query('blood_sugar_logs', orderBy: 'loggedAt DESC');
      final sugarLogs = sugarRes.map(BloodSugarLog.fromMap).toList();

      final bpRes = await db.query('blood_pressure_logs', orderBy: 'loggedAt DESC');
      final bpLogs = bpRes.map(BloodPressureLog.fromMap).toList();

      final vitalRes = await db.query('vital_signs_logs', orderBy: 'loggedAt DESC');
      final vitalLogs = vitalRes.map(VitalSignLog.fromMap).toList();

      final medicationLogsRes = await db.query('medication_logs', orderBy: 'createdAt DESC');
      final medLogs = medicationLogsRes.map(MedicationLog.fromMap).toList();

      final prnLogsRes = await db.query('prn_logs', orderBy: 'takenAt DESC');
      final energyLogsRes = await db.query('energy_logs', orderBy: 'loggedAt DESC');
      final sleepLogsRes = await db.query('bedtime_diagnostics', orderBy: 'createdAt DESC');

      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};

      final engineInput = HealthEngineInput(
        bloodSugarLogs: sugarLogs,
        bloodPressureLogs: bpLogs,
        vitalSignLogs: vitalLogs,
        medicationLogs: medLogs,
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
          _engineOutput = engineOutput;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading health insights: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDoctorVisitSummarySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: DoctorVisitSummarySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const identityColor = Color(0xff8B5CF6); // Insights Purple-Blue

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: identityColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.chart_bar_square_fill, color: identityColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'روندها و تحلیل سلامت',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: _engineOutput == null
            ? const Center(child: Text('داده‌ای برای تحلیل وجود ندارد.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AdherenceCard(stats: _engineOutput!.adherence),
                  const SizedBox(height: 16),
                  HealthTrendsSection(trends: _engineOutput!.trends),
                  const SizedBox(height: 16),
                  HealthCorrelationSection(correlations: _engineOutput!.correlations),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openDoctorVisitSummarySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text(
                      'تولید خلاصه برای پزشک',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }
}
