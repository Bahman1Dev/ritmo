import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/memory/assistant_memory_binding.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/konkur/logic/konkur_ai_helper.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_study_sheet.dart';

class AiKonkurAssistantSheet extends StatefulWidget {
  const AiKonkurAssistantSheet({
    super.key,
    required this.subjects,
    required this.topics,
    required this.perSubjectTrend,
    required this.onRefresh,
  });

  final List<KonkurSubject> subjects;
  final List<KonkurTopic> topics;
  final Map<String, List<double>> perSubjectTrend;
  final VoidCallback onRefresh;

  @override
  State<AiKonkurAssistantSheet> createState() => _AiKonkurAssistantSheetState();
}

class _AiKonkurAssistantSheetState extends State<AiKonkurAssistantSheet> {
  late final String _sessionId;
  String? _activeAction; // 'DECONSTRUCT', 'RECOMMEND_TOPIC', 'PLAN_DIST', 'ANALYZE_EXAMS'
  bool _isLoading = false;
  String _aiTextResponse = '';

  // Recommended Topic State
  KonkurTopic? _recommendedTopic;
  KonkurSubject? _recommendedSubject;

  // 1. Deconstruct Subject State
  KonkurSubject? _selectedDeconstructSub;
  List<Map<String, dynamic>> _suggestedTopics = []; // List of { "name": String, "questions": int, "selected": bool }

  void _triggerMemoryConsolidation() {
    unawaited(AssistantMemoryBinding.triggerConsolidation(
      sessionId: _sessionId,
      domain: 'konkur',
    ));
  }

  void _closeSheet() {
    _triggerMemoryConsolidation();
    Navigator.pop(context);
  }

  KonkurTopic? _extractRecommendedTopic(String aiResponse) {
    for (final topic in widget.topics) {
      if (aiResponse.contains(topic.name)) {
        return topic;
      }
    }
    return null;
  }

  void _openStudySheet() {
    if (_recommendedTopic == null) return;
    final topicId = _recommendedTopic!.id;
    final parentContext = Navigator.of(context).context;
    _triggerMemoryConsolidation();
    Navigator.pop(context); // close assistant sheet
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => KonkurStudySheet(
        subjects: widget.subjects,
        topics: widget.topics,
        preSelectedTopicId: topicId,
        onSaved: widget.onRefresh,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sessionId = 'konkur_${DateTime.now().millisecondsSinceEpoch}';
    if (widget.subjects.isNotEmpty) {
      _selectedDeconstructSub = widget.subjects.first;
    }
  }

  Future<void> _runDeconstruct() async {
    if (_selectedDeconstructSub == null) return;
    setState(() {
      _isLoading = true;
      _suggestedTopics = [];
    });

    const sysPrompt = 'You are the Ritmo Konkur AI Assistant. Split the requested subject into 4-8 logical sub-topics for exam prep.';
    final userPrompt = '''
Subject Name: "${_selectedDeconstructSub!.name}"
Please return ONLY a valid JSON array of objects representing subtopics. Do not include markdown code fences or any other explanations.

JSON Schema:
[
  {"name": "نام مبحث به فارسی", "questions": 3},
  {"name": "نام مبحث دوم به فارسی", "questions": 2}
]
''';

    try {
      final res = await KonkurAiHelper.askAssistant(
        sysPrompt,
        userPrompt,
        sessionId: _sessionId,
      );
      if (res != null) {
        var cleanJson = res.trim();
        if (cleanJson.startsWith('```')) {
          final lines = cleanJson.split('\n');
          if (lines.first.startsWith('```')) lines.removeAt(0);
          if (lines.isNotEmpty && lines.last.startsWith('```')) lines.removeLast();
          cleanJson = lines.join('\n').trim();
        }

        final List<dynamic> parsed = jsonDecode(cleanJson);
        setState(() {
          _suggestedTopics = parsed.map((item) {
            return {
              'name': item['name'] as String,
              'questions': (item['questions'] as num?)?.toInt() ?? 0,
              'selected': true,
            };
          }).toList();
        });
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveDeconstructedTopics() async {
    if (_selectedDeconstructSub == null || _suggestedTopics.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = KonkurRepository.instance;
      final now = DateTime.now().millisecondsSinceEpoch;
      var index = 0;
      
      for (final item in _suggestedTopics) {
        if (item['selected'] == true) {
          final topic = KonkurTopic(
            id: 'topic_${DateTime.now().millisecondsSinceEpoch}_$index',
            subjectId: _selectedDeconstructSub!.id,
            name: item['name'] as String,
            studyTargetMinutes: (item['questions'] as int) * 60, // 1 hr study target per exam question
            createdAt: now,
            updatedAt: now,
            examQuestionCount: item['questions'] as int,
            orderIndex: index++,
          );
          await repo.insertTopic(topic);
        }
      }

      widget.onRefresh();
      if (mounted) {
        _closeSheet();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مباحث پیشنهادی هوش مصنوعی با موفقیت ثبت شدند! 🚀', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        );
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _buildEnhancedContextPrompt() async {
    try {
      final repo = KonkurRepository.instance;
      final planned = await repo.getTodayPlannedMinutes();
      final actual = await repo.getTodayActualMinutes();

      final needsReviewTopics = widget.topics.where((t) =>
        t.masteryLevel == MasteryLevel.needsReview ||
        (t.nextReviewDate != null && t.nextReviewDate!.compareTo(DateTime.now().toIso8601String().substring(0, 10)) <= 0)
      ).map((t) => t.name).take(3).join(', ');

      return '''

Student Live Progress & Context:
- Today planned study: $planned minutes, completed study: $actual minutes.
- Topics needing immediate review: ${needsReviewTopics.isEmpty ? 'None' : needsReviewTopics}
''';
    } catch (_) {
      return '';
    }
  }

  // 2. Recommend Topic Right Now
  Future<void> _runRecommendTopic() async {
    setState(() {
      _isLoading = true;
      _aiTextResponse = '';
      _recommendedTopic = null;
      _recommendedSubject = null;
    });

    const sysPrompt = '''You are the Ritmo Konkur AI Assistant.
Help the student choose the best topic to study right now.
If you learn important facts about the student's strengths or weaknesses,
mark them as memory operations using <memory_ops>...</memory_ops> tags.
Example: <memory_ops>[{"op":"upsert","key":"weakness_subject","value":"chemistry","domain":"konkur"}]</memory_ops>
''';
    
    final topicsSummary = widget.topics.map((t) {
      final sub = widget.subjects.firstWhere((s) => s.id == t.subjectId, orElse: () => KonkurSubject(id: '', name: 'درس', createdAt: 0, updatedAt: 0));
      return '- ${sub.name}: ${t.name} (${t.examQuestionCount} questions in Konkur, target ${t.studyTargetMinutes} min)';
    }).join('\n');

    final extraContext = await _buildEnhancedContextPrompt();
    final userPrompt = '''
Topics: $topicsSummary
$extraContext
Please recommend one high-priority topic to study right now, explain why based on importance coefficient or question budget, and give a brief supportive tip. Write in Farsi.
''';

    try {
      final res = await KonkurAiHelper.askAssistant(
        sysPrompt,
        userPrompt,
        sessionId: _sessionId,
      );
      if (res != null) {
        final topic = _extractRecommendedTopic(res);
        final sub = topic != null
            ? widget.subjects.where((s) => s.id == topic.subjectId).firstOrNull
            : null;
        setState(() {
          _aiTextResponse = res;
          _recommendedTopic = topic;
          _recommendedSubject = sub;
        });
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  // 3. Analyze Trend & Results
  Future<void> _runAnalyzeTrend() async {
    setState(() {
      _isLoading = true;
      _aiTextResponse = '';
    });

    const sysPrompt = '''You are the Ritmo Konkur AI Assistant.
Analyze the student's mock exam scores trend. Provide supportive coaching and highlight weakest areas to focus on. NEVER estimate country rank/grade.
If you learn important facts about the student's strengths or weaknesses,
mark them as memory operations using <memory_ops>...</memory_ops> tags.
Example: <memory_ops>[{"op":"upsert","key":"weakness_subject","value":"chemistry","domain":"konkur"}]</memory_ops>
''';

    final trendsSummary = widget.perSubjectTrend.entries.map((e) {
      final sub = widget.subjects.firstWhere((s) => s.id == e.key, orElse: () => KonkurSubject(id: '', name: 'درس نامشخص', createdAt: 0, updatedAt: 0));
      return '${sub.name}: scores history ${e.value}';
    }).join('\n');

    final extraContext = await _buildEnhancedContextPrompt();
    final userPrompt = '''
Student Mock Exam Score Trends:
$trendsSummary
$extraContext
Please write a short analysis in Farsi. Point out progress, highlight which subject needs more focus, and write a motivational closing. Remember, never estimate rank.
''';

    try {
      final res = await KonkurAiHelper.askAssistant(
        sysPrompt,
        userPrompt,
        sessionId: _sessionId,
      );
      if (res != null) {
        setState(() {
          _aiTextResponse = res;
        });
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  // 4. Propose Plan Distribution
  Future<void> _runPlanDistribution() async {
    setState(() {
      _isLoading = true;
      _aiTextResponse = '';
    });

    const sysPrompt = 'You are the Ritmo Konkur AI Assistant. Help the student allocate and plan their study topics across weekdays.';

    final subjectsSummary = widget.subjects.map((s) => s.name).join(', ');
    final extraContext = await _buildEnhancedContextPrompt();
    final userPrompt = '''
Subjects list: $subjectsSummary
$extraContext
Please suggest a healthy weekly study schedule (e.g. which days to focus on math, chemistry, etc.) to keep balanced preparation. Write a friendly, motivating recommendation in Farsi.
''';

    try {
      final res = await KonkurAiHelper.askAssistant(
        sysPrompt,
        userPrompt,
        sessionId: _sessionId,
      );
      if (res != null) {
        setState(() {
          _aiTextResponse = res;
        });
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title
            Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF8B5CF6), size: 28),
                const SizedBox(width: 12),
                Text(
                  _activeAction == null ? '🤖 دستیار هوشمند کنکور ritmo' : _getActionTitle(),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_activeAction != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _activeAction = null;
                        _aiTextResponse = '';
                        _suggestedTopics = [];
                      });
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeSheet,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                          SizedBox(height: 16),
                          Text(
                            'در حال ارتباط با مغز هوش مصنوعی... 🧠',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _activeAction == null
                      ? _buildActionList(colors)
                      : _buildActiveActionView(colors),
            ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionTitle() {
    switch (_activeAction) {
      case 'DECONSTRUCT':
        return 'تقسیم درس به مباحث پیشنهادی';
      case 'RECOMMEND_TOPIC':
        return 'الان چی بخونم؟';
      case 'PLAN_DIST':
        return 'پیشنهاد توزیع برنامه در هفته';
      case 'ANALYZE_EXAMS':
        return 'تحلیل کارنامه‌ها و نمودار روند';
      default:
        return 'دستیار کنکور';
    }
  }

  Widget _buildActionList(RitmoColors colors) {
    return ListView(
      children: [
        _buildActionTile(
          icon: Icons.list_alt,
          title: 'این درس رو به مبحث تقسیم کن 📝',
          subtitle: 'نام درس را انتخاب کنید تا هوش مصنوعی آن را به سرفصل‌های تستی و بودجه‌بندی شده تقسیم کند.',
          onTap: () {
            setState(() {
              _activeAction = 'DECONSTRUCT';
            });
          },
          colors: colors,
        ),
        _buildActionTile(
          icon: Icons.rocket_launch,
          title: 'الان کدوم مبحث رو بخونم؟ 🚀',
          subtitle: 'با سنجش بودجه سؤالات کنکور، میزان تسلط فعلی و انرژی شما، بهترین مبحث پیشنهادی برای همین حالا.',
          onTap: () {
            setState(() {
              _activeAction = 'RECOMMEND_TOPIC';
            });
            _runRecommendTopic();
          },
          colors: colors,
        ),
        _buildActionTile(
          icon: Icons.calendar_view_week,
          title: 'چیدمان و پیشنهاد توزیع زمان 📅',
          subtitle: 'پیشنهاد توزیع مباحث در طول روزهای هفته جهت حفظ تعادل مطالعاتی دروس.',
          onTap: () {
            setState(() {
              _activeAction = 'PLAN_DIST';
            });
            _runPlanDistribution();
          },
          colors: colors,
        ),
        _buildActionTile(
          icon: Icons.insights,
          title: 'کارنامه‌ام رو تحلیل کن 📈',
          subtitle: 'تحلیل صمیمانه و تشویقی روند نمرات کارنامه‌ها و هدایت برای تقویت نقاط ضعف.',
          onTap: () {
            setState(() {
              _activeAction = 'ANALYZE_EXAMS';
            });
            _runAnalyzeTrend();
          },
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required RitmoColors colors,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveActionView(RitmoColors colors) {
    if (_activeAction == 'DECONSTRUCT') {
      return _buildDeconstructView(colors);
    }

    // Default text response viewer for other actions
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              _aiTextResponse.isEmpty ? 'متأسفانه پاسخی دریافت نشد.' : _aiTextResponse,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                height: 1.6,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (_activeAction == 'RECOMMEND_TOPIC' && _recommendedTopic != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'موضوع پیشنهادی: ${_recommendedSubject != null ? "${_recommendedSubject!.name} • " : ""}${_recommendedTopic!.name}',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _openStudySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('شروع جلسه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _activeAction = null;
                _aiTextResponse = '';
                _recommendedTopic = null;
                _recommendedSubject = null;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'بازگشت به لیست خدمات',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeconstructView(RitmoColors colors) {
    if (_suggestedTopics.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'درس مورد نظر را برای تقسیم به مباحث انتخاب کنید:',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<KonkurSubject>(
            value: _selectedDeconstructSub,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: widget.subjects.map((sub) {
              return DropdownMenuItem(
                value: sub,
                child: Text(sub.name, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
              );
            }).toList(),
            onChanged: (sub) {
              setState(() {
                _selectedDeconstructSub = sub;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _runDeconstruct,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              '✓ تحلیل و تقسیم با هوش مصنوعی',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'مباحث پیشنهادی هوش مصنوعی برای "${_selectedDeconstructSub!.name}":',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'شما می‌توانید سرفصل‌های نامناسب را غیرفعال کرده یا تعداد تست آن‌ها را ویرایش کنید.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _suggestedTopics.length,
            itemBuilder: (context, index) {
              final item = _suggestedTopics[index];
              return Card(
                elevation: 0,
                color: colors.card,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: item['selected'] as bool,
                        activeColor: const Color(0xFF8B5CF6),
                        onChanged: (val) {
                          setState(() {
                            _suggestedTopics[index]['selected'] = val;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          item['name'] as String,
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Editable Question Budget Count
                      SizedBox(
                        width: 50,
                        height: 36,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                          controller: TextEditingController(text: item['questions'].toString())
                            ..addListener(() {
                              // Avoid infinite updates
                            }),
                          onChanged: (text) {
                            final val = int.tryParse(text) ?? 0;
                            _suggestedTopics[index]['questions'] = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('تست', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textSecondary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveDeconstructedTopics,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            '✓ افزودن مباحث انتخاب شده به درس',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
