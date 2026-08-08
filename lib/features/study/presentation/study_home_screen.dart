import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/study/data/study_repository.dart';
import 'package:ritmo/features/study/data/study_settings_repository.dart';
import 'package:ritmo/features/study/domain/study_models.dart';
import 'package:ritmo/features/study/domain/study_planner.dart';
import 'package:ritmo/features/study/domain/study_stats.dart';
import 'package:ritmo/features/study/presentation/study_settings_sheet.dart';
import 'package:ritmo/features/study/presentation/subject_detail_screen.dart';
import 'package:ritmo/features/study/presentation/widgets/manual_session_sheet.dart';
import 'package:ritmo/features/study/presentation/widgets/session_timer_sheet.dart';
import 'package:ritmo/features/study/presentation/widgets/study_week_heatmap.dart';
import 'package:uuid/uuid.dart';

class StudyHomeScreen extends StatefulWidget {
  const StudyHomeScreen({super.key});

  @override
  State<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends State<StudyHomeScreen> {
  StudySettings? _settings;
  List<StudySubject> _subjects = [];
  List<StudySession> _todaySessions = [];
  Map<String, SubjectStats> _subjectStats = {};
  Map<String, int> _weeklyHeatmapData = {};
  StudyRecommendation? _topRecommendation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await StudySettingsRepository.instance.load();
      final isKonkur = settings.konkurMode;
      final subjects = await StudyRepository.instance.getSubjects(isKonkurMode: isKonkur);
      final topics = await StudyRepository.instance.getTopics(isKonkurMode: isKonkur);

      final todayIso = DateTime.now().toIso8601String().substring(0, 10);
      final todaySessions = await StudyRepository.instance.getSessions(dateIso: todayIso);
      final allSessions = await StudyRepository.instance.getSessions(limit: 500);

      final stats = await StudyRepository.instance.getAggregatedSubjectStats();

      final recs = StudyPlanner.evaluate(
        subjects: subjects,
        topics: topics,
        todaySessions: todaySessions,
        today: DateTime.now(),
        dailyCapacityMinutes: settings.dailyTargetMinutes,
      );

      final heatmapData = <String, int>{};
      for (final s in allSessions) {
        heatmapData[s.dateIso] = (heatmapData[s.dateIso] ?? 0) + s.durationMinutes;
      }

      if (mounted) {
        setState(() {
          _settings = settings;
          _subjects = subjects;
          _todaySessions = todaySessions;
          _subjectStats = stats;
          _weeklyHeatmapData = heatmapData;
          _topRecommendation = recs.isNotEmpty ? recs.first : null;
        });
      }
    } catch (e, st) {
      debugPrint('[StudyHomeScreen] Error loading study data: $e\n$st');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addSubject() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن درس جدید', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'نام درس (مثلاً: زبان انگلیسی)'),
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
      final subject = StudySubject(
        id: const Uuid().v4(),
        name: name,
        orderIndex: _subjects.length,
      );
      await StudyRepository.instance.saveSubject(subject);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final todayMinutes = _todaySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final targetMinutes = _settings?.dailyTargetMinutes ?? 90;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('درس و مطالعه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.textPrimary)),
          backgroundColor: colors.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                if (_settings != null) {
                  await StudySettingsSheet.show(context, settings: _settings!);
                  await _loadData();
                }
              },
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_topRecommendation != null) _buildNextUpCard(_topRecommendation!),
                            const SizedBox(height: 16),
                            _buildTodayProgressCard(todayMinutes, targetMinutes),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('دروس من', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                TextButton.icon(
                                  onPressed: _addSubject,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('درس جدید', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_subjects.isEmpty)
                              _buildEmptyState()
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _subjects.length,
                                itemBuilder: (context, index) {
                                  final subject = _subjects[index];
                                  final stats = _subjectStats[subject.id];
                                  return _buildSubjectCard(subject, stats);
                                },
                              ),
                            const SizedBox(height: 24),
                            StudyWeekHeatmap(sessionsByDate: _weeklyHeatmapData),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            if (_subjects.isNotEmpty) {
              await SessionTimerSheet.show(context, subject: _subjects.first);
            } else {
              await _addSubject();
            }
          },
          backgroundColor: colors.primary,
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: const Text('شروع مطالعه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildNextUpCard(StudyRecommendation rec) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text('الان چی بخونم؟', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${rec.subject.name} — ${rec.topic.name}', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 4),
          Text('دلیل: ${rec.reason}', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => SessionTimerSheet.show(context, subject: rec.subject, topic: rec.topic),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text('شروع جلسه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgressCard(int todayMinutes, int targetMinutes) {
    final colors = context.colors;
    final progress = targetMinutes > 0 ? (todayMinutes / targetMinutes).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('مطالعه امروز', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              TextButton.icon(
                onPressed: () async {
                  await ManualSessionSheet.show(context, subjects: _subjects);
                  await _loadData();
                },
                icon: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('ثبت دستی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${RitmoNumber.faInt(todayMinutes)} از ${RitmoNumber.faInt(targetMinutes)} دقیقه',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.surfaceElevated,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(StudySubject subject, SubjectStats? stats) {
    final colors = context.colors;
    final totalHours = (stats?.totalMinutes ?? 0) / 60.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: colors.surfaceSunken,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubjectDetailScreen(subject: subject)),
          );
          await _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(subject.emoji ?? '📚', style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      '${RitmoNumber.fa(totalHours.toStringAsFixed(1))} ساعت مطالعه · ${StudyDate.formatRelative(stats?.lastStudiedDateIso)}',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined, size: 48, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text('اولین درس خود را اضافه کنید', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 4),
          Text('با افزودن درس و سرفصل‌ها، پیشنهاد مطالعه روزانه فعال می‌شود.', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addSubject,
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('افزودن اولین درس', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
