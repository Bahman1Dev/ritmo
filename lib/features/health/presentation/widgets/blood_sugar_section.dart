import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

class BloodSugarSection extends StatefulWidget {
  const BloodSugarSection({
    super.key,
  });

  @override
  State<BloodSugarSection> createState() => _BloodSugarSectionState();
}

class _BloodSugarSectionState extends State<BloodSugarSection> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();

  List<BloodSugarLog> _logs = [];
  bool _isDiabetic = false;
  bool _isLoading = true;
  String _measurementType = 'FASTING';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
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

  String _normalizeDigits(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '٧', '۸', '۹'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], english[i]).replaceAll(arabic[i], english[i]);
    }
    return result;
  }

  Map<String, int> _getTargetRange(String type) {
    if (_isDiabetic) {
      switch (type) {
        case 'FASTING':
        case 'BEFORE_MEAL':
          return {'min': 80, 'max': 130};
        case 'AFTER_MEAL':
          return {'min': 80, 'max': 180};
        case 'BEDTIME':
          return {'min': 100, 'max': 150};
        case 'RANDOM':
        default:
          return {'min': 80, 'max': 180};
      }
    } else {
      switch (type) {
        case 'FASTING':
          return {'min': 70, 'max': 100};
        case 'BEFORE_MEAL':
          return {'min': 70, 'max': 110};
        case 'AFTER_MEAL':
          return {'min': 70, 'max': 140};
        case 'BEDTIME':
          return {'min': 100, 'max': 140};
        case 'RANDOM':
        default:
          return {'min': 70, 'max': 140};
      }
    }
  }

  String _checkStatus(int value, String type) {
    final range = _getTargetRange(type);
    if (value < 70) return 'LOW';
    if (value > range['max']!) return 'HIGH';
    if (value < range['min']!) return 'LOW';
    return 'NORMAL';
  }

  String _getMeasurementLabel(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'FASTING':
        return l10n.bloodSugarFasting;
      case 'BEFORE_MEAL':
        return l10n.bloodSugarBeforeMeal;
      case 'AFTER_MEAL':
        return l10n.bloodSugarAfterMeal;
      case 'BEDTIME':
        return l10n.bloodSugarBedtime;
      case 'RANDOM':
      default:
        return l10n.bloodSugarRandom;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Load diabetes flag
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      final hasDiabetes = settingsMap['patient_has_diabetes'] == 'true';

      // Load blood sugar logs
      final results = await db.query('blood_sugar_logs', orderBy: 'loggedAt DESC', limit: 100);
      final logsList = results.map(BloodSugarLog.fromMap).toList();

      if (mounted) {
        setState(() {
          _isDiabetic = hasDiabetes;
          _logs = logsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading blood sugar: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _toggleDiabetic(bool val) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {
          'key': 'patient_has_diabetes',
          'value': val.toString(),
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      setState(() {
        _isDiabetic = val;
      });
    } catch (e) {
      debugPrint('Error updating diabetes setting: $e');
    }
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final normValStr = _normalizeDigits(_valueController.text.trim());
    final value = int.tryParse(normValStr);
    if (value == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final log = BloodSugarLog(
      id: 'bs_$now',
      value: value,
      measurementType: _measurementType,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      loggedAt: now,
    );

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('blood_sugar_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      _valueController.clear();
      _noteController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      
      await _loadData();
    } catch (e) {
      debugPrint('Error saving blood sugar log: $e');
    }
  }

  Future<void> _deleteLog(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('blood_sugar_logs', where: 'id = ?', whereArgs: [id]);
      await _loadData();
    } catch (e) {
      debugPrint('Error deleting blood sugar log: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;



    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.bloodSugarTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      l10n.bloodSugarDiabeticFlag,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    Switch(
                      value: _isDiabetic,
                      activeThumbColor: colors.primary,
                      onChanged: _toggleDiabetic,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Line Chart
            if (_logs.isNotEmpty) ...[
              Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: CustomPaint(
                  painter: _BloodSugarChartPainter(
                    logs: _logs.take(7).toList().reversed.toList(),
                    isDiabetic: _isDiabetic,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Fast Add Log Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _valueController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: l10n.bloodSugarValue,
                              icon: Icons.speed,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return l10n.bloodSugarEnterValue;
                              }
                              if (int.tryParse(_normalizeDigits(val.trim())) == null) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _measurementType,
                            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: l10n.bloodSugarTitle,
                              icon: Icons.category,
                            ),
                            dropdownColor: colors.card,
                            items: [
                              DropdownMenuItem(value: 'FASTING', child: Text(l10n.bloodSugarFasting)),
                              DropdownMenuItem(value: 'BEFORE_MEAL', child: Text(l10n.bloodSugarBeforeMeal)),
                              DropdownMenuItem(value: 'AFTER_MEAL', child: Text(l10n.bloodSugarAfterMeal)),
                              DropdownMenuItem(value: 'BEDTIME', child: Text(l10n.bloodSugarBedtime)),
                              DropdownMenuItem(value: 'RANDOM', child: Text(l10n.bloodSugarRandom)),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _measurementType = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      decoration: RitmoTheme.inputDecoration(
                        context,
                        label: 'یادداشت (اختیاری)',
                        icon: Icons.note_alt_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        l10n.bloodSugarSave,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.bloodSugarHistory,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // History list
            if (_isLoading) Center(child: CircularProgressIndicator(color: colors.primary)) else _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (_logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'سابقه سنجشی وجود ندارد.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final typeLabel = _getMeasurementLabel(log.measurementType);
        final status = _checkStatus(log.value, log.measurementType);

        Color badgeColor;
        String statusText;
        switch (status) {
          case 'LOW':
            badgeColor = colors.medicalRed;
            statusText = l10n.bloodSugarLow;
          case 'HIGH':
            badgeColor = colors.warning;
            statusText = l10n.bloodSugarHigh;
          case 'NORMAL':
          default:
            badgeColor = colors.success;
            statusText = l10n.bloodSugarInRange;
        }

        final jalali = Jalali.fromDateTime(DateTime.fromMillisecondsSinceEpoch(log.loggedAt));
        final dateStr = _toPersianDigits('${jalali.year}/${jalali.month}/${jalali.day}');
        final timeStr = _toPersianDigits('${DateTime.fromMillisecondsSinceEpoch(log.loggedAt).hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(log.loggedAt).minute.toString().padLeft(2, '0')}');

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: badgeColor.withValues(alpha: 0.1),
              child: Text(
                _toPersianDigits(log.value.toString()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                  fontSize: 15,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateStr ساعت $timeStr',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                if (log.note != null && log.note!.isNotEmpty)
                  Text(
                    log.note!,
                    style: TextStyle(fontSize: 11, color: colors.textPrimary, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: colors.medicalRed),
              onPressed: () => _confirmDelete(log.id),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          title: const Text('حذف سنجش', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          content: const Text('آیا مطمئن هستید که می‌خواهید این سنجش قند خون را حذف کنید؟', style: TextStyle(fontFamily: 'Vazirmatn')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteLog(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.medicalRed),
              child: const Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodSugarChartPainter extends CustomPainter {

  _BloodSugarChartPainter({
    required this.logs,
    required this.isDiabetic,
    required this.colors,
  });
  final List<BloodSugarLog> logs;
  final bool isDiabetic;
  final RitmoColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final linePaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );

    // Grid details
    const paddingLeft = 35.0;
    const paddingRight = 15.0;
    const paddingTop = 20.0;
    const paddingBottom = 25.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // We can assume min sugar = 40, max sugar = 250 for graphing boundaries
    const minVal = 40;
    const maxVal = 240;

    double getY(double val) {
      var pct = (val - minVal) / (maxVal - minVal);
      pct = pct.clamp(0.0, 1.0);
      return size.height - paddingBottom - (pct * chartHeight);
    }

    double getX(int index, int total) {
      if (total <= 1) return paddingLeft + chartWidth / 2;
      return paddingLeft + (index * (chartWidth / (total - 1)));
    }

    // 1. Draw target range shaded area (using standard fasting range 70-130 as general indicator)
    final targetMin = isDiabetic ? 80.0 : 70.0;
    final targetMax = isDiabetic ? 130.0 : 110.0;
    final targetTop = getY(targetMax);
    final targetBottom = getY(targetMin);

    final rangePaint = Paint()
      ..color = colors.success.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(paddingLeft, targetTop, size.width - paddingRight, targetBottom),
      rangePaint,
    );

    // Draw reference line for target limits
    final refLinePaint = Paint()
      ..color = colors.success.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(paddingLeft, targetTop), Offset(size.width - paddingRight, targetTop), refLinePaint);
    canvas.drawLine(Offset(paddingLeft, targetBottom), Offset(size.width - paddingRight, targetBottom), refLinePaint);

    // Label the target lines
    textPainter.text = TextSpan(
      text: _toPersianDigits(targetMax.toInt().toString()),
      style: TextStyle(color: colors.success.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 4, targetTop - textPainter.height / 2));

    textPainter.text = TextSpan(
      text: _toPersianDigits(targetMin.toInt().toString()),
      style: TextStyle(color: colors.success.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 4, targetBottom - textPainter.height / 2));

    // 2. Draw horizontal grid lines (e.g. at 50, 100, 150, 200)
    final gridPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final val in [50, 100, 150, 200]) {
      if (val.toDouble() == targetMin || val.toDouble() == targetMax) continue;
      final y = getY(val.toDouble());
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      textPainter.text = TextSpan(
        text: _toPersianDigits(val.toString()),
        style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 4, y - textPainter.height / 2));
    }

    // 3. Plot the data line
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < logs.length; i++) {
      final x = getX(i, logs.length);
      final y = getY(logs[i].value.toDouble());
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // 4. Draw points and X-axis labels
    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      final pt = points[i];

      // Point color based on range
      var pColor = colors.success;
      final range = _getTargetRange(log.measurementType);
      if (log.value < 70) {
        pColor = colors.medicalRed;
      } else if (log.value > range['max']! || log.value < range['min']!) {
        pColor = colors.warning;
      }

      // Draw shadow circle
      canvas.drawCircle(pt, 5, Paint()..color = colors.card);
      // Draw outer circle
      canvas.drawCircle(pt, 4, Paint()..color = pColor);

      // Draw value text above dot
      textPainter.text = TextSpan(
        text: _toPersianDigits(log.value.toString()),
        style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx - textPainter.width / 2, pt.dy - 16));

      // Draw X-axis label (Time/Type)
      final dt = DateTime.fromMillisecondsSinceEpoch(log.loggedAt);
      final jalali = Jalali.fromDateTime(dt);
      final label = _toPersianDigits('${jalali.month}/${jalali.day}');
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: colors.textSecondary, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx - textPainter.width / 2, size.height - paddingBottom + 4));
    }
  }

  Map<String, int> _getTargetRange(String type) {
    if (isDiabetic) {
      switch (type) {
        case 'FASTING':
        case 'BEFORE_MEAL':
          return {'min': 80, 'max': 130};
        case 'AFTER_MEAL':
          return {'min': 80, 'max': 180};
        case 'BEDTIME':
          return {'min': 100, 'max': 150};
        case 'RANDOM':
        default:
          return {'min': 80, 'max': 180};
      }
    } else {
      switch (type) {
        case 'FASTING':
          return {'min': 70, 'max': 100};
        case 'BEFORE_MEAL':
          return {'min': 70, 'max': 110};
        case 'AFTER_MEAL':
          return {'min': 70, 'max': 140};
        case 'BEDTIME':
          return {'min': 100, 'max': 140};
        case 'RANDOM':
        default:
          return {'min': 70, 'max': 140};
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

  @override
  bool shouldRepaint(covariant _BloodSugarChartPainter oldDelegate) {
    return oldDelegate.logs != logs || oldDelegate.isDiabetic != isDiabetic || oldDelegate.colors != colors;
  }
}
