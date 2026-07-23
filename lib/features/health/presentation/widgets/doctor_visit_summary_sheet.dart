import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/analytics/health_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:shamsi_date/shamsi_date.dart';

class DoctorVisitSummarySheet extends StatefulWidget {
  const DoctorVisitSummarySheet({super.key});

  @override
  State<DoctorVisitSummarySheet> createState() => _DoctorVisitSummarySheetState();
}

class _DoctorVisitSummarySheetState extends State<DoctorVisitSummarySheet> {
  bool _isLoading = true;
  String _summaryText = '';

  @override
  void initState() {
    super.initState();
    _generateBriefing();
  }

  Future<void> _generateBriefing() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Fetch settings
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      final hasDiabetes = settingsMap['patient_has_diabetes'] == 'true';
      final hasHypertension = settingsMap['patient_has_hypertension'] == 'true';

      // 2. Fetch active routines
      final routines = await db.query('routines', where: "category = 'medical' AND isArchived = 0");
      final medsList = <String>[];
      for (final r in routines) {
        final title = r['title']! as String;
        final dosage = r['description'] as String? ?? '';
        final type = r['routineType']! as String;
        final stock = r['medStockCount'] as int? ?? 0;
        final typeStr = type == 'asNeeded' ? 'PRN (در صورت نیاز)' : 'روزانه/زمان‌بندی‌شده';
        medsList.add('• $title ${dosage.isNotEmpty ? "(دوز: $dosage)" : ""} - $typeStr [موجودی: $stock]');
      }

      // 3. Fetch logs for HealthEngine
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

      // 4. Calculate trends
      final engineInput = HealthEngineInput(
        bloodSugarLogs: sugarLogs,
        bloodPressureLogs: bpLogs,
        vitalSignLogs: vitalLogs,
        medicationLogs: medLogs,
        prnLogs: prnLogsRes,
        energyLogs: energyLogsRes,
        sleepLogs: sleepLogsRes,
        hasDiabetes: hasDiabetes,
        hasHypertension: hasHypertension,
        today: DateTime.now(),
      );

      final engineOutput = HealthEngine.calculateSync(engineInput);

      // Build Last Vitals
      final lastVitalsMap = <String, String>{};
      if (sugarLogs.isNotEmpty) {
        final last = sugarLogs.first;
        final date = _formatEpochShamsi(last.loggedAt);
        lastVitalsMap['قند خون'] = '${last.value} mg/dL (${last.categoryLabel}) در $date';
      }
      if (bpLogs.isNotEmpty) {
        final last = bpLogs.first;
        final date = _formatEpochShamsi(last.loggedAt);
        lastVitalsMap['فشار خون'] = '${last.systolic}/${last.diastolic} mmHg (${last.stageLabel}) در $date';
      }
      final weightLogs = vitalLogs.where((l) => l.vitalType == 'WEIGHT').toList();
      if (weightLogs.isNotEmpty) {
        final last = weightLogs.first;
        final date = _formatEpochShamsi(last.loggedAt);
        lastVitalsMap['وزن'] = '${last.value} kg در $date';
      }
      final spo2Logs = vitalLogs.where((l) => l.vitalType == 'SPO2').toList();
      if (spo2Logs.isNotEmpty) {
        final last = spo2Logs.first;
        final date = _formatEpochShamsi(last.loggedAt);
        lastVitalsMap['اکسیژن خون'] = '${last.value}٪ در $date';
      }

      // Build Trends
      final trendsList = <String>[];
      trendsList.add('• میزان پایبندی به مصرف داروها: ${_toPersianDigits((engineOutput.adherence.adherenceRate * 100).toStringAsFixed(0))}٪ (زنجیره فعلی: ${engineOutput.adherence.currentStreak} روز)');
      if (engineOutput.adherence.missedPattern != null) {
        trendsList.add('  - الگوی فراموشی: ${engineOutput.adherence.missedPattern}');
      }
      
      for (final trend in engineOutput.trends) {
        var label = '';
        var unit = '';
        if (trend.metric == 'blood_sugar') { label = 'قند خون ناشتا'; unit = 'mg/dL'; }
        else if (trend.metric == 'blood_pressure_systolic') { label = 'فشار خون سیستولیک'; unit = 'mmHg'; }
        else if (trend.metric == 'blood_pressure_diastolic') { label = 'فشار خون دیاستولیک'; unit = 'mmHg'; }
        else if (trend.metric == 'weight') { label = 'وزن بدن'; unit = 'kg'; }
        else if (trend.metric == 'spo2') { label = 'اکسیژن خون'; unit = '٪'; }
        else if (trend.metric == 'temperature') { label = 'دمای بدن'; unit = '°C'; }

        if (label.isNotEmpty) {
          final dirText = trend.direction == 'up' ? 'صعودی' : (trend.direction == 'down' ? 'نزولی' : 'پایدار');
          trendsList.add('• میانگین ۳۰ روزه $label: ${_toPersianDigits(trend.average.toStringAsFixed(1))} $unit (روند: $dirText)');
        }
      }

      // 5. Fetch Allergies
      final allergiesRes = await db.query('allergies');
      final allergiesList = <String>[];
      for (final a in allergiesRes) {
        allergiesList.add('• ${a['allergen']} (دسته: ${a['category']} - شدت: ${a['severity']})');
      }

      // 6. Build Text Summary
      final nowJalali = Jalali.now();
      final dateStr = _toPersianDigits('${nowJalali.year}/${nowJalali.month}/${nowJalali.day}');
      
      final buffer = StringBuffer();
      buffer.writeln('📋 گزارش خلاصه سلامت ریتمو (مخصوص پزشک معالج)');
      buffer.writeln('تاریخ تولید گزارش: $dateStr');
      buffer.writeln('=================================');
      buffer.writeln();
      buffer.writeln('💊 داروهای فعال:');
      if (medsList.isEmpty) {
        buffer.writeln('هیچ داروی فعالی ثبت نشده است.');
      } else {
        medsList.forEach(buffer.writeln);
      }
      buffer.writeln();
      buffer.writeln('📊 آخرین علائم حیاتی ثبت‌شده:');
      if (lastVitalsMap.isEmpty) {
        buffer.writeln('هیچ علامتی ثبت نشده است.');
      } else {
        lastVitalsMap.forEach((key, val) => buffer.writeln('• $key: $val'));
      }
      buffer.writeln();
      buffer.writeln('📈 روندها و آمارهای اخیر (۳۰ روزه):');
      if (trendsList.isEmpty) {
        buffer.writeln('داده‌های کافی وجود ندارد.');
      } else {
        trendsList.forEach(buffer.writeln);
      }
      buffer.writeln();
      buffer.writeln('⚠️ حساسیت‌ها و آلرژی‌ها:');
      if (allergiesList.isEmpty) {
        buffer.writeln('موردی ثبت نشده است.');
      } else {
        allergiesList.forEach(buffer.writeln);
      }
      buffer.writeln();
      buffer.writeln('---------------------------------');
      buffer.writeln('تهیه شده توسط برنامه خودمراقبتی و هوشمند ریتمو');

      if (mounted) {
        setState(() {
          _summaryText = buffer.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating briefing: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatEpochShamsi(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final jalali = Jalali.fromDateTime(dt);
    return _toPersianDigits('${jalali.year}/${jalali.month}/${jalali.day}');
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _summaryText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('متن گزارش با موفقیت در حافظه کپی شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
        backgroundColor: context.colors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RitmoTheme.glassCardLight(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'خلاصه آماده برای ارائه به پزشک',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      color: colors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.border)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _summaryText,
                          style: TextStyle(
                            fontFamily: 'Courier', // medical data layout
                            fontSize: 12,
                            color: colors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _copyToClipboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('کپی متن گزارش', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: const Text('بستن', style: TextStyle(fontFamily: 'Vazirmatn')),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
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
}
