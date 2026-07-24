import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_formatters.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_study_sheet.dart';

class KonkurBudgetSection extends StatefulWidget {

  const KonkurBudgetSection({
    super.key,
    required this.subjects,
    required this.topics,
    required this.budgetCoverage,
    required this.perSubjectReadiness,
    required this.onRefresh,
  });
  final List<KonkurSubject> subjects;
  final List<KonkurTopic> topics;
  final double budgetCoverage;
  final Map<String, double> perSubjectReadiness;
  final VoidCallback onRefresh;

  @override
  State<KonkurBudgetSection> createState() => _KonkurBudgetSectionState();
}

class _KonkurBudgetSectionState extends State<KonkurBudgetSection> {
  MasteryLevel? _selectedMasteryFilter;
  final _subjectNameController = TextEditingController();
  final _subjectFactorController = TextEditingController(text: '1.0');
  final _subjectQuestionsController = TextEditingController(text: '0');

  final _topicNameController = TextEditingController();
  final _topicQuestionsController = TextEditingController(text: '0');
  final _topicTargetMinutesController = TextEditingController(text: '120');
  final _topicConceptTargetController = TextEditingController(text: '0');
  final _topicPracticeTargetController = TextEditingController(text: '0');
  final _topicReviewTargetController = TextEditingController(text: '0');

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectFactorController.dispose();
    _subjectQuestionsController.dispose();
    _topicNameController.dispose();
    _topicQuestionsController.dispose();
    _topicTargetMinutesController.dispose();
    _topicConceptTargetController.dispose();
    _topicPracticeTargetController.dispose();
    _topicReviewTargetController.dispose();
    super.dispose();
  }

  // CYCLE MASTERY LEVEL INLINE
  Future<void> _cycleMastery(KonkurTopic topic) async {
    final nextIndex = (MasteryLevel.values.indexOf(topic.masteryLevel) + 1) % MasteryLevel.values.length;
    final nextLevel = MasteryLevel.values[nextIndex];

    final updatedTopic = KonkurTopic(
      id: topic.id,
      subjectId: topic.subjectId,
      parentTopicId: topic.parentTopicId,
      name: topic.name,
      progressPercentage: nextLevel == MasteryLevel.mastered ? 100.0 : 50.0,
      studyTargetMinutes: topic.studyTargetMinutes,
      studyCompletedMinutes: topic.studyCompletedMinutes,
      createdAt: topic.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      examQuestionCount: topic.examQuestionCount,
      masteryLevel: nextLevel,
      lastStudiedAt: topic.lastStudiedAt,
      nextReviewDate: nextLevel == MasteryLevel.mastered
          ? DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10)
          : null,
      plannedDate: topic.plannedDate,
      orderIndex: topic.orderIndex,
    );

    try {
      await KonkurRepository.instance.updateTopic(updatedTopic);
      widget.onRefresh();
    } catch (_) {}
  }

  // ADD SUBJECT
  void _showAddSubjectDialog() {
    _subjectNameController.clear();
    _subjectFactorController.text = '1.0';
    _subjectQuestionsController.text = '0';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('افزودن درس جدید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectNameController,
                decoration: const InputDecoration(labelText: 'نام درس', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectFactorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'ضریب درس در کنکور', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectQuestionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'تعداد کل سؤالات در کنکور', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              onPressed: () async {
                if (_subjectNameController.text.isEmpty) return;
                final factor = double.tryParse(_subjectFactorController.text) ?? 1.0;
                final qCount = int.tryParse(_subjectQuestionsController.text) ?? 0;

                final sub = KonkurSubject(
                  id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                  name: _subjectNameController.text,
                  importanceFactor: factor,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                  examQuestionCount: qCount,
                  orderIndex: widget.subjects.length,
                );

                await KonkurRepository.instance.insertSubject(sub);
                widget.onRefresh();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('✓ ذخیره', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // EDIT SUBJECT
  void _showEditSubjectDialog(KonkurSubject sub) {
    _subjectNameController.text = sub.name;
    _subjectFactorController.text = sub.importanceFactor.toString();
    _subjectQuestionsController.text = sub.examQuestionCount.toString();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ویرایش درس', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectNameController,
                decoration: const InputDecoration(labelText: 'نام درس', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectFactorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'ضریب درس در کنکور', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectQuestionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'تعداد کل سؤالات در کنکور', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('حذف درس؟', style: TextStyle(fontFamily: 'Vazirmatn')),
                    content: Text('آیا مطمئن هستید که می‌خواهید درس "${sub.name}" و تمام مباحث زیرمجموعه آن را حذف کنید؟ این عمل غیرقابل بازگشت است.', style: const TextStyle(fontFamily: 'Vazirmatn')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn'))),
                      TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('حذف کاملا', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red))),
                    ],
                  ),
                );
                if (confirm ?? false) {
                  await KonkurRepository.instance.deleteSubject(sub.id);
                  widget.onRefresh();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                }
              },
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              onPressed: () async {
                if (_subjectNameController.text.isEmpty) return;
                final factor = double.tryParse(_subjectFactorController.text) ?? 1.0;
                final qCount = int.tryParse(_subjectQuestionsController.text) ?? 0;

                final updated = KonkurSubject(
                  id: sub.id,
                  name: _subjectNameController.text,
                  importanceFactor: factor,
                  progressPercentage: sub.progressPercentage,
                  createdAt: sub.createdAt,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                  examQuestionCount: qCount,
                  subjectGroup: sub.subjectGroup,
                  colorHex: sub.colorHex,
                  orderIndex: sub.orderIndex,
                  isPreset: sub.isPreset,
                );

                await KonkurRepository.instance.updateSubject(updated);
                widget.onRefresh();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('✓ بروزرسانی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ADD TOPIC
  void _showAddTopicDialog(KonkurSubject sub) {
    _topicNameController.clear();
    _topicQuestionsController.text = '0';
    _topicTargetMinutesController.text = '120';
    _topicConceptTargetController.text = '0';
    _topicPracticeTargetController.text = '0';
    _topicReviewTargetController.text = '0';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('افزودن مبحث جدید به ${sub.name}', style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _topicNameController,
                  decoration: const InputDecoration(labelText: 'نام مبحث', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _topicQuestionsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'تعداد تست احتمالی در کنکور', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _topicTargetMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'زمان هدف مطالعه (دقیقه)', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('تنظیم هدف فازبندی (اختیاری)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    TextField(
                      controller: _topicConceptTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان هدف مطالعه مفهومی (دقیقه — اختیاری)', hintText: '0 = بدون هدف مشخص', labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topicPracticeTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان هدف تمرین/تست (دقیقه — اختیاری)', labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topicReviewTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان هدف مرور (دقیقه — اختیاری)', labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              onPressed: () async {
                if (_topicNameController.text.isEmpty) return;
                final qCount = int.tryParse(_topicQuestionsController.text) ?? 0;
                final targetMins = int.tryParse(_topicTargetMinutesController.text) ?? 120;
                final conceptTarget = int.tryParse(_topicConceptTargetController.text) ?? 0;
                final practiceTarget = int.tryParse(_topicPracticeTargetController.text) ?? 0;
                final reviewTarget = int.tryParse(_topicReviewTargetController.text) ?? 0;

                final topic = KonkurTopic(
                  id: 'topic_${DateTime.now().millisecondsSinceEpoch}',
                  subjectId: sub.id,
                  name: _topicNameController.text,
                  studyTargetMinutes: targetMins,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                  examQuestionCount: qCount,
                  conceptTargetMinutes: conceptTarget,
                  practiceTargetMinutes: practiceTarget,
                  reviewTargetMinutes: reviewTarget,
                );

                await KonkurRepository.instance.insertTopic(topic);
                widget.onRefresh();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('✓ ذخیره', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // EDIT TOPIC
  void _showEditTopicDialog(KonkurTopic topic, String subjectName) {
    _topicNameController.text = topic.name;
    _topicQuestionsController.text = topic.examQuestionCount.toString();
    _topicTargetMinutesController.text = topic.studyTargetMinutes.toString();
    _topicConceptTargetController.text = topic.conceptTargetMinutes.toString();
    _topicPracticeTargetController.text = topic.practiceTargetMinutes.toString();
    _topicReviewTargetController.text = topic.reviewTargetMinutes.toString();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('ویرایش مبحث (${topic.name})', style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 14)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _topicNameController,
                  decoration: const InputDecoration(labelText: 'نام مبحث', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _topicQuestionsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'تعداد تست احتمالی در کنکور', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _topicTargetMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'زمان هدف مطالعه (دقیقه)', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('تنظیم هدف فازبندی (اختیاری)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    TextField(
                      controller: _topicConceptTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان هدف مطالعه مفهومی (دقیقه — اختیاری)', hintText: '0 = بدون هدف مشخص', labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topicPracticeTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان هدف تمرین/تست (دقیقه — اختیاری)', labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topicReviewTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان هدف مرور (دقیقه — اختیاری)', labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('حذف مبحث؟', style: TextStyle(fontFamily: 'Vazirmatn')),
                    content: Text('آیا مطمئن هستید که می‌خواهید مبحث "${topic.name}" را حذف کنید؟', style: const TextStyle(fontFamily: 'Vazirmatn')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn'))),
                      TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('حذف مبحث', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red))),
                    ],
                  ),
                );
                if (confirm ?? false) {
                  await KonkurRepository.instance.deleteTopic(topic.id);
                  widget.onRefresh();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              onPressed: () async {
                if (_topicNameController.text.isEmpty) return;
                final qCount = int.tryParse(_topicQuestionsController.text) ?? 0;
                final targetMins = int.tryParse(_topicTargetMinutesController.text) ?? 120;
                final conceptTarget = int.tryParse(_topicConceptTargetController.text) ?? 0;
                final practiceTarget = int.tryParse(_topicPracticeTargetController.text) ?? 0;
                final reviewTarget = int.tryParse(_topicReviewTargetController.text) ?? 0;

                final updated = KonkurTopic(
                  id: topic.id,
                  subjectId: topic.subjectId,
                  parentTopicId: topic.parentTopicId,
                  name: _topicNameController.text,
                  progressPercentage: topic.progressPercentage,
                  studyTargetMinutes: targetMins,
                  studyCompletedMinutes: topic.studyCompletedMinutes,
                  createdAt: topic.createdAt,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                  examQuestionCount: qCount,
                  masteryLevel: topic.masteryLevel,
                  lastStudiedAt: topic.lastStudiedAt,
                  nextReviewDate: topic.nextReviewDate,
                  plannedDate: topic.plannedDate,
                  orderIndex: topic.orderIndex,
                  prerequisiteTopicIds: topic.prerequisiteTopicIds,
                  conceptCompletedMinutes: topic.conceptCompletedMinutes,
                  conceptTargetMinutes: conceptTarget,
                  practiceCompletedMinutes: topic.practiceCompletedMinutes,
                  practiceTargetMinutes: practiceTarget,
                  reviewCompletedMinutes: topic.reviewCompletedMinutes,
                  reviewTargetMinutes: reviewTarget,
                );

                await KonkurRepository.instance.updateTopic(updated);
                widget.onRefresh();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('✓ بروزرسانی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openStudySheet(KonkurTopic topic, String mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return KonkurStudySheet(
          initialTopic: topic,
          subjects: widget.subjects,
          topics: widget.topics,
          onSaved: widget.onRefresh,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final budgetPercent = (widget.budgetCoverage * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Budget Coverage Bar
          _buildBudgetProgressHeader(budgetPercent, colors),
          const SizedBox(height: 12),

          // Mastery Filter Bar
          _buildMasteryFilterBar(colors),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سرفصل‌ها و مباحث درس‌ها:',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF8B5CF6)),
                label: const Text(
                  'افزودن درس',
                  style: TextStyle(fontFamily: 'Vazirmatn', color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subject List with Expandable Tiles
          if (widget.subjects.isEmpty)
            _buildEmptyState(colors)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.subjects.length,
              itemBuilder: (context, index) {
                final subject = widget.subjects[index];
                final readiness = widget.perSubjectReadiness[subject.id] ?? 0.0;
                final subTopics = widget.topics
                    .where((t) => t.subjectId == subject.id)
                    .where((t) => _selectedMasteryFilter == null || t.masteryLevel == _selectedMasteryFilter)
                    .toList();
                return _buildSubjectExpansionTile(subject, readiness, subTopics, colors);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMasteryFilterBar(RitmoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('همه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
            selected: _selectedMasteryFilter == null,
            onSelected: (_) => setState(() => _selectedMasteryFilter = null),
          ),
          const SizedBox(width: 6),
          ...MasteryLevel.values.map((lvl) {
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: FilterChip(
                avatar: Text(lvl.emoji),
                label: Text(lvl.label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                selected: _selectedMasteryFilter == lvl,
                onSelected: (sel) => setState(() => _selectedMasteryFilter = sel ? lvl : null),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBudgetProgressHeader(int percent, RitmoColors colors) {
    final totalTargetMins = widget.topics.fold(0, (acc, t) => acc + t.studyTargetMinutes);
    final totalCompletedMins = widget.topics.fold(0, (acc, t) => acc + t.studyCompletedMinutes);
    final masteredCount = widget.topics.where((t) => t.masteryLevel == MasteryLevel.mastered).length;

    final completedHours = (totalCompletedMins / 60).toStringAsFixed(1);
    final targetHours = (totalTargetMins / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'پوشش بودجه‌بندی کنکور',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '${toPersianDigits(percent)}٪ مباحث خوانده شده',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.budgetCoverage,
              backgroundColor: colors.border,
              color: const Color(0xFF8B5CF6),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'زمان مطالعه: ${toPersianDigits(completedHours)} از ${toPersianDigits(targetHours)} ساعت',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.bold),
              ),
              Text(
                'مسلط: ${toPersianDigits(masteredCount)} از ${toPersianDigits(widget.topics.length)} مبحث',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectExpansionTile(
    KonkurSubject subject,
    double readiness,
    List<KonkurTopic> subTopics,
    RitmoColors colors,
  ) {
    final percent = (readiness * 100).toInt();
    final circleColor = subject.colorHex != null
        ? Color(int.parse(subject.colorHex!.replaceFirst('#', '0xFF')))
        : const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subject.name,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(right: 22, top: 4),
          child: Row(
            children: [
              Text(
                'ضریب: ${toPersianDigits(subject.importanceFactor)}',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                'آمادگی درس: ${toPersianDigits(percent)}٪',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: percent >= 70
                      ? colors.success
                      : percent >= 40
                          ? colors.warning
                          : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditSubjectDialog(subject),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (subTopics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'مبحثی برای این درس ثبت نشده است.',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
              ),
            )
          else ...[
            Builder(
              builder: (context) {
                final Map<String, List<KonkurTopic>> topicsByChapter = {};
                for (final topic in subTopics) {
                  final chapterName = topic.chapter ?? 'سرفصل‌های عمومی';
                  topicsByChapter.putIfAbsent(chapterName, () => []).add(topic);
                }

                final List<Widget> chapterWidgets = [];
                for (final entry in topicsByChapter.entries) {
                  chapterWidgets.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4, right: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                          Divider(
                            thickness: 0.5,
                            height: 8,
                            color: colors.border.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                  for (final topic in entry.value) {
                    chapterWidgets.add(_buildTopicRow(topic, subject.name, colors));
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: chapterWidgets,
                );
              },
            ),
          ],
          const Divider(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showAddTopicDialog(subject),
              icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF8B5CF6)),
              label: const Text(
                'افزودن مبحث',
                style: TextStyle(fontFamily: 'Vazirmatn', color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicRow(KonkurTopic topic, String subjectName, RitmoColors colors) {
    final progress = topic.studyTargetMinutes > 0
        ? (topic.studyCompletedMinutes / topic.studyTargetMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.name,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (topic.examQuestionCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '≈ ${toPersianDigits(topic.examQuestionCount)} تست',
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: colors.border,
                          color: Colors.lightBlue,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${toPersianDigits(topic.studyCompletedMinutes)} / ${toPersianDigits(topic.studyTargetMinutes)} د.',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary),
                    ),
                  ],
                ),
                _buildTopicPhaseBar(topic, colors),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Mastery Chip cycling level on tap
          GestureDetector(
            onTap: () => _cycleMastery(topic),
            child: Chip(
              avatar: Text(topic.masteryLevel.emoji),
              label: Text(
                topic.masteryLevel.label,
                style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 10),
              ),
              backgroundColor: colors.bg,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          const SizedBox(width: 6),
          // Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              if (val == 'edit') {
                _showEditTopicDialog(topic, subjectName);
              } else if (val == 'study') {
                _openStudySheet(topic, 'STUDY');
              } else if (val == 'test') {
                _openStudySheet(topic, 'TEST');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'study',
                child: Row(
                  children: [
                    Icon(Icons.menu_book, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('شروع مطالعه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تست‌زنی و کارنامه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_note, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('ویرایش مبحث', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicPhaseBar(KonkurTopic topic, RitmoColors colors) {
    if (topic.conceptTargetMinutes == 0 &&
        topic.practiceTargetMinutes == 0 &&
        topic.reviewTargetMinutes == 0) {
      return const SizedBox.shrink();
    }

    final conceptFill = topic.conceptTargetMinutes > 0
        ? (topic.conceptCompletedMinutes / topic.conceptTargetMinutes).clamp(0.0, 1.0)
        : 0.0;
    final practiceFill = topic.practiceTargetMinutes > 0
        ? (topic.practiceCompletedMinutes / topic.practiceTargetMinutes).clamp(0.0, 1.0)
        : 0.0;
    final reviewFill = topic.reviewTargetMinutes > 0
        ? (topic.reviewCompletedMinutes / topic.reviewTargetMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: conceptFill,
                    minHeight: 4,
                    backgroundColor: colors.border,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('مفهومی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: practiceFill,
                    minHeight: 4,
                    backgroundColor: colors.border,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 2),
                const Text('تمرین', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: reviewFill,
                    minHeight: 4,
                    backgroundColor: colors.border,
                    color: colors.success,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('مرور', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        ],
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
            Icon(Icons.book, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'هیچ درسی ثبت نشده است. دکمه «افزودن درس» را لمس کنید.',
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
