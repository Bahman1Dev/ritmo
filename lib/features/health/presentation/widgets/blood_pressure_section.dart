import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

class BloodPressureSection extends StatefulWidget {
  const BloodPressureSection({
    super.key,
  });

  @override
  State<BloodPressureSection> createState() => _BloodPressureSectionState();
}

class _BloodPressureSectionState extends State<BloodPressureSection> {
  final _formKey = GlobalKey<FormState>();
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _pulseController = TextEditingController();
  final _noteController = TextEditingController();

  List<BloodPressureLog> _logs = [];
  bool _isLoading = true;

  String _arm = 'LEFT';
  String _position = 'SITTING';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _pulseController.dispose();
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

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query('blood_pressure_logs', orderBy: 'loggedAt DESC', limit: 100);
      final logsList = results.map(BloodPressureLog.fromMap).toList();

      if (mounted) {
        setState(() {
          _logs = logsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading blood pressure: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final sysVal = int.tryParse(_normalizeDigits(_sysController.text.trim()));
    final diaVal = int.tryParse(_normalizeDigits(_diaController.text.trim()));
    final pulseVal = _pulseController.text.trim().isNotEmpty
        ? int.tryParse(_normalizeDigits(_pulseController.text.trim()))
        : null;

    if (sysVal == null || diaVal == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final log = BloodPressureLog(
      id: 'bp_$now',
      systolic: sysVal,
      diastolic: diaVal,
      pulse: pulseVal,
      arm: _arm,
      position: _position,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      loggedAt: now,
    );

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('blood_pressure_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      _sysController.clear();
      _diaController.clear();
      _pulseController.clear();
      _noteController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      
      _loadData();
    } catch (e) {
      debugPrint('Error saving blood pressure log: $e');
    }
  }

  Future<void> _deleteLog(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('blood_pressure_logs', where: 'id = ?', whereArgs: [id]);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting blood pressure log: $e');
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
            Text(
              l10n.bloodPressureTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  painter: _BloodPressureChartPainter(
                    logs: _logs.take(7).toList().reversed.toList(),
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
                          child: TextFormField(
                            controller: _sysController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: 'سیستول (SYS)',
                              icon: Icons.heart_broken_outlined,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'اجباری';
                              if (int.tryParse(_normalizeDigits(val.trim())) == null) return 'نامعتبر';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _diaController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: 'دیاستول (DIA)',
                              icon: Icons.heart_broken_sharp,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'اجباری';
                              if (int.tryParse(_normalizeDigits(val.trim())) == null) return 'نامعتبر';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pulseController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: 'ضربان (Pulse)',
                              icon: Icons.monitor_heart_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _arm,
                            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
                            decoration: RitmoTheme.inputDecoration(
                              context,
                              label: l10n.bloodPressureArm,
                              icon: Icons.accessibility_new,
                            ),
                            dropdownColor: colors.card,
                            items: [
                              DropdownMenuItem(value: 'LEFT', child: Text(l10n.bloodPressureArmLeft)),
                              DropdownMenuItem(value: 'RIGHT', child: Text(l10n.bloodPressureArmRight)),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _arm = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _position,
                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Vazirmatn'),
                      decoration: RitmoTheme.inputDecoration(
                        context,
                        label: l10n.bloodPressurePosition,
                        icon: Icons.airline_seat_recline_normal,
                      ),
                      dropdownColor: colors.card,
                      items: [
                        DropdownMenuItem(value: 'SITTING', child: Text(l10n.bloodPressurePositionSitting)),
                        DropdownMenuItem(value: 'STANDING', child: Text(l10n.bloodPressurePositionStanding)),
                        DropdownMenuItem(value: 'LYING', child: Text(l10n.bloodPressurePositionLying)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _position = val;
                          });
                        }
                      },
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
                        l10n.bloodPressureSave,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.bloodPressureHistory,
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
        final stageText = log.stageLabel;

        Color badgeColor;
        if (log.systolic > 180 || log.diastolic > 120) {
          badgeColor = colors.medicalRed; // Hypertensive crisis
        } else if (log.systolic >= 140 || log.diastolic >= 90) {
          badgeColor = colors.medicalRed; // Stage 2
        } else if (log.systolic >= 130 || log.diastolic >= 80) {
          badgeColor = colors.warning; // Stage 1
        } else if (log.systolic >= 120 && log.diastolic < 80) {
          badgeColor = colors.warning; // Elevated/Pre-hypertension
        } else {
          badgeColor = colors.success; // Normal
        }

        final jalali = Jalali.fromDateTime(DateTime.fromMillisecondsSinceEpoch(log.loggedAt));
        final dateStr = _toPersianDigits('${jalali.year}/${jalali.month}/${jalali.day}');
        final timeStr = _toPersianDigits('${DateTime.fromMillisecondsSinceEpoch(log.loggedAt).hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(log.loggedAt).minute.toString().padLeft(2, '0')}');

        var posText = '';
        switch (log.position) {
          case 'LYING':
            posText = l10n.bloodPressurePositionLying;
          case 'STANDING':
            posText = l10n.bloodPressurePositionStanding;
          case 'SITTING':
          default:
            posText = l10n.bloodPressurePositionSitting;
        }

        final armText = log.arm == 'LEFT' ? l10n.bloodPressureArmLeft : l10n.bloodPressureArmRight;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: badgeColor.withValues(alpha: 0.1),
              child: Icon(Icons.favorite, color: badgeColor, size: 20),
            ),
            title: Row(
              children: [
                Text(
                  _toPersianDigits('${log.systolic}/${log.diastolic}'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stageText,
                    style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateStr ساعت $timeStr · $armText ($posText)',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                if (log.pulse != null)
                  Text(
                    'ضربان قلب: ${_toPersianDigits(log.pulse.toString())} بار در دقیقه',
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
          content: const Text('آیا مطمئن هستید که می‌خواهید این سنجش فشار خون را حذف کنید؟', style: TextStyle(fontFamily: 'Vazirmatn')),
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

class _BloodPressureChartPainter extends CustomPainter {

  _BloodPressureChartPainter({
    required this.logs,
    required this.colors,
  });
  final List<BloodPressureLog> logs;
  final RitmoColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final sysLinePaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final diaLinePaint = Paint()
      ..color = colors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );

    // Padding
    const paddingLeft = 35.0;
    const paddingRight = 15.0;
    const paddingTop = 20.0;
    const paddingBottom = 25.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Boundary for Blood Pressure Graph: Min 40, Max 200
    const minVal = 40;
    const maxVal = 200;

    double getY(double val) {
      var pct = (val - minVal) / (maxVal - minVal);
      pct = pct.clamp(0.0, 1.0);
      return size.height - paddingBottom - (pct * chartHeight);
    }

    double getX(int index, int total) {
      if (total <= 1) return paddingLeft + chartWidth / 2;
      return paddingLeft + (index * (chartWidth / (total - 1)));
    }

    // Grid lines (horizontal) at 60, 90, 120, 150, 180
    final gridPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final val in [60, 90, 120, 150, 180]) {
      final y = getY(val.toDouble());
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      textPainter.text = TextSpan(
        text: _toPersianDigits(val.toString()),
        style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Reference limit markings (diastolic normal limit <80 and systolic normal limit <120)
    final refPaint = Paint()
      ..color = colors.warning.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Systolic threshold line (120)
    canvas.drawLine(Offset(paddingLeft, getY(120)), Offset(size.width - paddingRight, getY(120)), refPaint);
    // Diastolic threshold line (80)
    canvas.drawLine(Offset(paddingLeft, getY(80)), Offset(size.width - paddingRight, getY(80)), refPaint);

    final sysPath = Path();
    final diaPath = Path();

    for (var i = 0; i < logs.length; i++) {
      final x = getX(i, logs.length);
      final sysY = getY(logs[i].systolic.toDouble());
      final diaY = getY(logs[i].diastolic.toDouble());

      if (i == 0) {
        sysPath.moveTo(x, sysY);
        diaPath.moveTo(x, diaY);
      } else {
        sysPath.lineTo(x, sysY);
        diaPath.lineTo(x, diaY);
      }
    }

    // Draw lines
    canvas.drawPath(sysPath, sysLinePaint);
    canvas.drawPath(diaPath, diaLinePaint);

    // Draw dots and value labels
    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      final x = getX(i, logs.length);
      final sysY = getY(log.systolic.toDouble());
      final diaY = getY(log.diastolic.toDouble());

      // Systolic Dot
      canvas.drawCircle(Offset(x, sysY), 4.5, Paint()..color = colors.card);
      canvas.drawCircle(Offset(x, sysY), 3.5, Paint()..color = colors.primary);

      textPainter.text = TextSpan(
        text: _toPersianDigits(log.systolic.toString()),
        style: TextStyle(color: colors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, sysY - 14));

      // Diastolic Dot
      canvas.drawCircle(Offset(x, diaY), 4.5, Paint()..color = colors.card);
      canvas.drawCircle(Offset(x, diaY), 3.5, Paint()..color = colors.success);

      textPainter.text = TextSpan(
        text: _toPersianDigits(log.diastolic.toString()),
        style: TextStyle(color: colors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, diaY + 4));

      // X-Axis Date label
      final dt = DateTime.fromMillisecondsSinceEpoch(log.loggedAt);
      final jalali = Jalali.fromDateTime(dt);
      final dateLabel = _toPersianDigits('${jalali.month}/${jalali.day}');
      textPainter.text = TextSpan(
        text: dateLabel,
        style: TextStyle(color: colors.textSecondary, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - paddingBottom + 4));
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
  bool shouldRepaint(covariant _BloodPressureChartPainter oldDelegate) {
    return oldDelegate.logs != logs || oldDelegate.colors != colors;
  }
}
