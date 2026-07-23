import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_formatters.dart';

class KonkurExamsSection extends StatefulWidget {

  const KonkurExamsSection({
    super.key,
    required this.subjects,
    required this.mockExams,
    required this.mockResults,
    required this.perSubjectTrend,
    required this.onRefresh,
  });
  final List<KonkurSubject> subjects;
  final List<KonkurMockExam> mockExams;
  final List<KonkurMockResult> mockResults;
  final Map<String, List<double>> perSubjectTrend;
  final VoidCallback onRefresh;

  @override
  State<KonkurExamsSection> createState() => _KonkurExamsSectionState();
}

class _KonkurExamsSectionState extends State<KonkurExamsSection> {
  KonkurSubject? _selectedTrendSubject;

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedTrendSubject = widget.subjects.first;
    }
  }

  @override
  void didUpdateWidget(covariant KonkurExamsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subjects.isNotEmpty &&
        (_selectedTrendSubject == null || !widget.subjects.any((s) => s.id == _selectedTrendSubject!.id))) {
      setState(() {
        _selectedTrendSubject = widget.subjects.first;
      });
    }
  }

  void _showAddExamSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _AddMockExamSheet(
          subjects: widget.subjects,
          onSaved: widget.onRefresh,
        );
      },
    );
  }

  Future<void> _deleteExam(String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کارنامه؟', style: TextStyle(fontFamily: 'Vazirmatn')),
        content: const Text('آیا مطمئن هستید که می‌خواهید این کارنامه و تمام نتایج ثبت شده برای آن را حذف کنید؟', style: TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف کارنامه', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red))),
        ],
      ),
    );
    if (confirm ?? false) {
      await KonkurRepository.instance.deleteMockExam(examId);
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Fetch trend data for selected subject
    final trendScores = _selectedTrendSubject != null
        ? (widget.perSubjectTrend[_selectedTrendSubject!.id] ?? [])
        : <double>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trend Chart Card
          if (widget.subjects.isNotEmpty && trendScores.isNotEmpty) ...[
            _buildTrendChartCard(trendScores, colors),
            const SizedBox(height: 20),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'کارنامه‌های ثبت شده آزمون‌ها:',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddExamSheet,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'ثبت آزمون جدید',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.mockExams.isEmpty)
            _buildEmptyState(colors)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.mockExams.length,
              itemBuilder: (context, index) {
                final exam = widget.mockExams[index];
                final results = widget.mockResults.where((r) => r.mockExamId == exam.id).toList();
                return _buildExamResultCard(exam, results, colors);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard(List<double> trendScores, RitmoColors colors) {
    return Card(
      elevation: 0,
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'روند درصدهای دروس در آزمون‌ها 📈',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
                ),
                DropdownButton<KonkurSubject>(
                  value: _selectedTrendSubject,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5CF6)),
                  items: widget.subjects.map((sub) {
                    return DropdownMenuItem(
                      value: sub,
                      child: Text(sub.name, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (sub) {
                    setState(() {
                      _selectedTrendSubject = sub;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: CustomPaint(
                painter: TrendChartPainter(
                  scores: trendScores,
                  lineColor: const Color(0xFF8B5CF6),
                  gridColor: colors.border,
                  textColor: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'نمودار پیشرفت درصدهای خالص درس انتخاب شده از اولین تا آخرین آزمون',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamResultCard(
    KonkurMockExam exam,
    List<KonkurMockResult> results,
    RitmoColors colors,
  ) {
    // Calculate average percentage
    var totalPercent = 0.0;
    for (final r in results) {
      totalPercent += r.percentage;
    }
    final avgPercent = results.isNotEmpty ? totalPercent / results.length : 0.0;

    var dateStr = '';
    try {
      final dt = DateTime.parse(exam.examDate);
      final jalali = Jalali.fromDateTime(dt);
      dateStr = '${toPersianDigits(jalali.day)} ${jalali.formatter.mN} ${toPersianDigits(jalali.year)}';
    } catch (_) {}

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'برگزارکننده: ${exam.provider ?? "سایر"} · تاریخ: $dateStr',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: avgPercent >= 50.0
                    ? colors.success.withValues(alpha: 0.1)
                    : colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'میانگین: ${toPersianDigits(avgPercent.toStringAsFixed(1))}٪',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: avgPercent >= 50.0 ? colors.success : colors.warning,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
          onPressed: () => _deleteExam(exam.id),
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'هیچ نتیجه درسی برای این آزمون ثبت نشده است.',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
                4: FlexColumnWidth(1.2),
              },
              border: TableBorder.symmetric(inside: BorderSide(color: colors.border.withValues(alpha: 0.5))),
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('درس', colors),
                    _buildTableHeader('صحیح', colors),
                    _buildTableHeader('غلط', colors),
                    _buildTableHeader('نزده', colors),
                    _buildTableHeader('درصد خالص', colors),
                  ],
                ),
                ...results.map((res) {
                  final subject = widget.subjects.firstWhere(
                    (s) => s.id == res.subjectId,
                    orElse: () => KonkurSubject(id: '', name: 'نامشخص', createdAt: 0, updatedAt: 0),
                  );
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(subject.name, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(toPersianDigits(res.correctAnswers), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(toPersianDigits(res.wrongAnswers), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(toPersianDigits(res.emptyAnswers), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${toPersianDigits(res.percentage.toStringAsFixed(1))}٪',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: res.percentage >= 50.0
                                ? colors.success
                                : res.percentage >= 0.0
                                    ? colors.warning
                                    : colors.medicalRed,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String label, RitmoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        textAlign: label == 'درس' ? Alignment.centerRight.hashCode == 0 ? TextAlign.left : TextAlign.right : TextAlign.center,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(RitmoColors colors) {
    return Card(
      elevation: 0,
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'هنوز کارنامه‌ای ثبت نکرده‌اید. با دکمه بالا اولین آزمون را ثبت کنید.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MOCK EXAM ADD SHEET
class _AddMockExamSheet extends StatefulWidget {

  const _AddMockExamSheet({
    required this.subjects,
    required this.onSaved,
  });
  final List<KonkurSubject> subjects;
  final VoidCallback onSaved;

  @override
  State<_AddMockExamSheet> createState() => _AddMockExamSheetState();
}

class _AddMockExamSheetState extends State<_AddMockExamSheet> {
  final _titleController = TextEditingController();
  final _providerController = TextEditingController(text: 'سنجش');
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  // Map of subjectId -> controllers
  final Map<String, TextEditingController> _correctControllers = {};
  final Map<String, TextEditingController> _wrongControllers = {};
  final Map<String, TextEditingController> _blankControllers = {};

  @override
  void initState() {
    super.initState();
    for (final sub in widget.subjects) {
      _correctControllers[sub.id] = TextEditingController(text: '0');
      _wrongControllers[sub.id] = TextEditingController(text: '0');
      _blankControllers[sub.id] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _providerController.dispose();
    _noteController.dispose();
    for (final c in _correctControllers.values) {
      c.dispose();
    }
    for (final c in _wrongControllers.values) {
      c.dispose();
    }
    for (final c in _blankControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(_selectedDate),
      firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365))),
      lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 30))),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked.toDateTime();
      });
    }
  }

  Future<void> _saveExam() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً عنوان آزمون را وارد کنید.', style: TextStyle(fontFamily: 'Vazirmatn'))),
      );
      return;
    }

    final examId = 'exam_${DateTime.now().millisecondsSinceEpoch}';
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);

    final exam = KonkurMockExam(
      id: examId,
      title: _titleController.text,
      examDate: dateStr,
      provider: _providerController.text,
      note: _noteController.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final repo = KonkurRepository.instance;
      // 1. Insert exam
      await repo.insertMockExam(exam);

      // 2. Insert subject results
      for (final sub in widget.subjects) {
        final correct = int.tryParse(_correctControllers[sub.id]!.text) ?? 0;
        final wrong = int.tryParse(_wrongControllers[sub.id]!.text) ?? 0;
        final blank = int.tryParse(_blankControllers[sub.id]!.text) ?? 0;
        final total = correct + wrong + blank;

        final percentage = KonkurMockResult.computeNetPercent(correct, wrong, total);

        final result = KonkurMockResult(
          id: 'res_${DateTime.now().millisecondsSinceEpoch}_${sub.id}',
          mockExamId: examId,
          subjectId: sub.id,
          percentage: percentage,
          correctAnswers: correct,
          wrongAnswers: wrong,
          emptyAnswers: blank,
          totalQuestions: total,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await repo.insertMockResult(result);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final jalali = Jalali.fromDateTime(_selectedDate);
    final dateDisplay = '${toPersianDigits(jalali.day)} ${jalali.formatter.mN} ${toPersianDigits(jalali.year)}';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📝 ثبت کارنامه آزمون سراسری/آزمایشی',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'عنوان آزمون (مثلا: قلم‌چی مرحله ۳)', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _providerController,
                          decoration: const InputDecoration(labelText: 'برگزارکننده', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8B5CF6)),
                          label: Text(dateDisplay, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'عملکرد شما در هر درس:',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...widget.subjects.map((sub) => _buildSubjectInputRow(sub, colors)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'یادداشت یا تحلیل کلی آزمون', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('✓ ثبت و محاسبه خودکار کارنامه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectInputRow(KonkurSubject sub, RitmoColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub.name, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildCellInput('صحیح', _correctControllers[sub.id]!)),
              const SizedBox(width: 8),
              Expanded(child: _buildCellInput('غلط', _wrongControllers[sub.id]!)),
              const SizedBox(width: 8),
              Expanded(child: _buildCellInput('نزده', _blankControllers[sub.id]!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCellInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 10),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
    );
  }
}

// CUSTOM PAINTER FOR TREND CHART
class TrendChartPainter extends CustomPainter {

  TrendChartPainter({
    required this.scores,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });
  final List<double> scores;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintPoints = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    // Draw horizontal grid lines for 0%, 25%, 50%, 75%, 100%
    const gridLines = [0.0, 0.25, 0.5, 0.75, 1.0];
    for (final ratio in gridLines) {
      final y = size.height * (1.0 - ratio);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);

      // Draw label text
      final textSpan = TextSpan(
        text: toPersianDigits('${(ratio * 100).toInt()}%'),
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 8, color: textColor),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 24, y - 10));
    }

    if (scores.isEmpty) return;

    // Calculate chart points coordinates
    final numPoints = scores.length;
    final stepX = numPoints > 1 ? size.width / (numPoints - 1) : size.width;

    final points = <Offset>[];
    for (var i = 0; i < numPoints; i++) {
      // Map percentage to Y height (clamped to 0-100)
      final scoreVal = scores[i].clamp(0.0, 100.0);
      final ratioY = scoreVal / 100.0;
      final y = size.height * (1.0 - ratioY);
      
      final x = numPoints > 1 ? i * stepX : size.width / 2;
      points.add(Offset(x, y));
    }

    // Draw lines between points
    if (numPoints > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paintLine);
    }

    // Draw dot points
    for (final point in points) {
      canvas.drawCircle(point, 5, paintPoints);
      // Draw inner white dot for aesthetics
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter oldDelegate) {
    return oldDelegate.scores != scores;
  }
}
