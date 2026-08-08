import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/study/data/study_repository.dart';
import 'package:ritmo/features/study/domain/study_models.dart';
import 'package:ritmo/features/study/domain/study_stats.dart';
import 'package:ritmo/features/study/presentation/widgets/bulk_topics_sheet.dart';
import 'package:ritmo/features/study/presentation/widgets/session_timer_sheet.dart';
import 'package:uuid/uuid.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({super.key, required this.subject});

  final StudySubject subject;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  List<StudyTopic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    final topics = await StudyRepository.instance.getTopics(subjectId: widget.subject.id);
    if (mounted) {
      setState(() {
        _topics = topics;
        _isLoading = false;
      });
    }
  }

  Future<void> _addTopicSingle() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن سرفصل جدید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'نام سرفصل'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.primary),
            child: const Text('افزودن', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final topic = StudyTopic(
        id: const Uuid().v4(),
        subjectId: widget.subject.id,
        name: name,
        orderIndex: _topics.length,
      );
      await StudyRepository.instance.saveTopic(topic);
      await _loadTopics();
    }
  }

  Future<void> _addBulkTopics() async {
    final bulkList = await BulkTopicsSheet.show(context, subjectId: widget.subject.id);
    if (bulkList != null && bulkList.isNotEmpty) {
      await StudyRepository.instance.saveTopicsBulk(bulkList);
      await _loadTopics();
    }
  }

  Future<void> _advanceMastery(StudyTopic topic) async {
    StudyMastery next;
    switch (topic.mastery) {
      case StudyMastery.notStarted:
        next = StudyMastery.learning;
        break;
      case StudyMastery.learning:
        next = StudyMastery.review;
        break;
      case StudyMastery.review:
        next = StudyMastery.mastered;
        break;
      case StudyMastery.mastered:
        next = StudyMastery.notStarted;
        break;
    }

    final updated = StudyTopic(
      id: topic.id,
      subjectId: topic.subjectId,
      parentTopicId: topic.parentTopicId,
      name: topic.name,
      mastery: next,
      studyCompletedMinutes: topic.studyCompletedMinutes,
      lastStudiedAtMs: topic.lastStudiedAtMs,
      nextReviewDateIso: topic.nextReviewDateIso,
      plannedDateIso: topic.plannedDateIso,
      orderIndex: topic.orderIndex,
      origin: topic.origin,
      chapter: topic.chapter,
    );

    await StudyRepository.instance.saveTopic(updated);
    await _loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.subject.name, style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.textPrimary)),
          backgroundColor: colors.surface,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addTopicSingle,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('افزودن سرفصل', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: colors.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addBulkTopics,
                          icon: Icon(Icons.playlist_add, color: colors.primary),
                          label: Text('افزودن دسته‌جمعی', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.primary)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_topics.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'هنوز هیچ سرفصلی برای این درس ثبت نشده است.',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topics.length,
                      itemBuilder: (context, index) {
                        final topic = _topics[index];
                        return _buildTopicTile(topic);
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopicTile(StudyTopic topic) {
    final colors = context.colors;
    String chipLabel;
    Color chipColor;

    switch (topic.mastery) {
      case StudyMastery.notStarted:
        chipLabel = '⚪ نخوانده';
        chipColor = colors.textSecondary;
        break;
      case StudyMastery.learning:
        chipLabel = '🔵 در حال یادگیری';
        chipColor = colors.primary;
        break;
      case StudyMastery.review:
        chipLabel = '🟡 نیاز به مرور';
        chipColor = colors.warning;
        break;
      case StudyMastery.mastered:
        chipLabel = '🟢 مسلط';
        chipColor = colors.success;
        break;
    }

    final lastStudiedText = topic.lastStudiedAtMs != null
        ? StudyDate.formatRelative(DateTime.fromMillisecondsSinceEpoch(topic.lastStudiedAtMs!).toIso8601String().substring(0, 10))
        : 'هرگز';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.name, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '${RitmoNumber.faInt(topic.studyCompletedMinutes)} دقیقه مطالعه · آخرین بار: $lastStudiedText',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _advanceMastery(topic),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(chipLabel, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, fontWeight: FontWeight.bold, color: chipColor)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_circle_fill, color: colors.primary, size: 28),
            onPressed: () => SessionTimerSheet.show(context, subject: widget.subject, topic: topic),
          ),
        ],
      ),
    );
  }
}
