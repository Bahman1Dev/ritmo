import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/logic/konkur_review_policy.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_formatters.dart';

class KonkurStudySheet extends StatefulWidget {
  const KonkurStudySheet({
    super.key,
    this.initialTopic,
    this.initialMode,
    required this.subjects,
    required this.topics,
    required this.onSaved,
    this.preSelectedTopicId,
  });

  final KonkurTopic? initialTopic;
  final String? initialMode;
  final List<KonkurSubject> subjects;
  final List<KonkurTopic> topics;
  final VoidCallback onSaved;
  final String? preSelectedTopicId;

  @override
  State<KonkurStudySheet> createState() => _KonkurStudySheetState();
}

class _KonkurStudySheetState extends State<KonkurStudySheet> {
  // Mode selection
  late String _currentMode; // STUDY, TEST, REVIEW

  // Topic Selection
  KonkurSubject? _selectedSubject;
  KonkurTopic? _selectedTopic;

  // Timer Variables
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;

  // Test Mode Inputs
  final _correctController = TextEditingController(text: '0');
  final _wrongController = TextEditingController(text: '0');
  final _blankController = TextEditingController(text: '0');
  double _netPercent = 0;

  // Mastery promotion on save
  MasteryLevel? _promotedMastery;
  String? _selectedOutcome; // UNDERSTOOD, PARTIAL, NEEDS_REVIEW, NEEDS_PRACTICE

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode ?? 'STUDY';

    // Preset initial or preSelected topic if provided
    final preSelected = widget.initialTopic ??
        (widget.preSelectedTopicId != null
            ? widget.topics.where((t) => t.id == widget.preSelectedTopicId).firstOrNull
            : null);

    if (preSelected != null) {
      _selectedTopic = preSelected;
      _selectedSubject = widget.subjects.firstWhere(
        (s) => s.id == _selectedTopic!.subjectId,
        orElse: () => widget.subjects.first,
      );
      _promotedMastery = _selectedTopic!.masteryLevel;
    } else if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
      final subTopics = widget.topics.where((t) => t.subjectId == _selectedSubject!.id).toList();
      if (subTopics.isNotEmpty) {
        _selectedTopic = subTopics.first;
        _promotedMastery = _selectedTopic!.masteryLevel;
      }
    }

    _correctController.addListener(_calculateLivePercent);
    _wrongController.addListener(_calculateLivePercent);
    _blankController.addListener(_calculateLivePercent);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _correctController.dispose();
    _wrongController.dispose();
    _blankController.dispose();
    super.dispose();
  }

  void _calculateLivePercent() {
    final correct = int.tryParse(_correctController.text) ?? 0;
    final wrong = int.tryParse(_wrongController.text) ?? 0;
    final blank = int.tryParse(_blankController.text) ?? 0;
    final total = correct + wrong + blank;

    setState(() {
      _netPercent = KonkurMockResult.computeNetPercent(correct, wrong, total);
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsElapsed = 0;
      _isRunning = false;
    });
  }

  Future<void> _saveSession() async {
    final colors = context.colors;
    if (_selectedTopic == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً مبحث مورد نظر را انتخاب کنید.',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
        ),
      );
      return;
    }

    final minutes = _secondsElapsed ~/ 60;
    if (minutes < 1) {
      // Allow saving even short trials for demo/debug, but show warning
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ثبت جلسه کوتاه؟', style: TextStyle(fontFamily: 'Vazirmatn')),
          content: const Text(
            'زمان ثبت شده کمتر از یک دقیقه است. آیا می‌خواهید این زمان را گرد کرده و ثبت کنید؟',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('ثبت', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final duration = minutes < 1 ? 1 : minutes;

    final correct = int.tryParse(_correctController.text) ?? 0;
    final wrong = int.tryParse(_wrongController.text) ?? 0;
    final blank = int.tryParse(_blankController.text) ?? 0;
    final total = correct + wrong + blank;

    final session = KonkurStudySession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      topicId: _selectedTopic!.id,
      subjectId: _selectedSubject!.id,
      dateIso: DateTime.now().toIso8601String().substring(0, 10),
      durationMinutes: duration,
      mode: _currentMode,
      testsTotal: _currentMode == 'TEST' ? total : 0,
      testsCorrect: _currentMode == 'TEST' ? correct : 0,
      testsWrong: _currentMode == 'TEST' ? wrong : 0,
      testsBlank: _currentMode == 'TEST' ? blank : 0,
      note: 'ثبت خودکار از تایمر کنکور ritmo',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      sessionOutcome: _selectedOutcome,
    );

    try {
      final repo = KonkurRepository.instance;
      
      // Save study session
      await repo.insertStudySession(session);

      // Increment phase-specific completed minutes and update topic mastery / lastStudiedAt
      final conceptAdd = _currentMode == 'STUDY' ? duration : 0;
      final practiceAdd = _currentMode == 'TEST' ? duration : 0;
      final reviewAdd = _currentMode == 'REVIEW' ? duration : 0;

      final targetMastery = _promotedMastery ?? _selectedTopic!.masteryLevel;
      final calculatedNextRevDate = const KonkurReviewPolicy().computeNextReviewDate(
        outcome: _selectedOutcome,
        currentMastery: targetMastery,
        from: DateTime.now(),
      );
      final nextRev = calculatedNextRevDate != null
          ? calculatedNextRevDate.toIso8601String().substring(0, 10)
          : _selectedTopic!.nextReviewDate;

      final updatedTopic = KonkurTopic(
        id: _selectedTopic!.id,
        subjectId: _selectedTopic!.subjectId,
        parentTopicId: _selectedTopic!.parentTopicId,
        name: _selectedTopic!.name,
        progressPercentage: targetMastery == MasteryLevel.mastered ? 100.0 : 50.0,
        studyTargetMinutes: _selectedTopic!.studyTargetMinutes,
        studyCompletedMinutes: _selectedTopic!.studyCompletedMinutes,
        createdAt: _selectedTopic!.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        examQuestionCount: _selectedTopic!.examQuestionCount,
        masteryLevel: targetMastery,
        lastStudiedAt: DateTime.now().millisecondsSinceEpoch,
        nextReviewDate: nextRev,
        plannedDate: _selectedTopic!.plannedDate,
        orderIndex: _selectedTopic!.orderIndex,
        prerequisiteTopicIds: _selectedTopic!.prerequisiteTopicIds,
        conceptCompletedMinutes: _selectedTopic!.conceptCompletedMinutes + conceptAdd,
        conceptTargetMinutes: _selectedTopic!.conceptTargetMinutes,
        practiceCompletedMinutes: _selectedTopic!.practiceCompletedMinutes + practiceAdd,
        practiceTargetMinutes: _selectedTopic!.practiceTargetMinutes,
        reviewCompletedMinutes: _selectedTopic!.reviewCompletedMinutes + reviewAdd,
        reviewTargetMinutes: _selectedTopic!.reviewTargetMinutes,
      );
      await repo.updateTopic(updatedTopic);

      // Mark matching plan item for today as DONE
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final planItems = await repo.getPlanItems();
      final matchingItem = planItems.firstWhere(
        (item) => item.topicId == _selectedTopic!.id && item.dateIso == todayStr && item.status == 'PENDING',
        orElse: () => KonkurPlanItem(id: '', dateIso: '', createdAt: 0),
      );
      if (matchingItem.id.isNotEmpty) {
        await repo.updatePlanItemStatus(matchingItem.id, 'DONE');
      }

      widget.onSaved();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        String outcomeNote = '';
        if (_selectedOutcome == 'NEEDS_REVIEW') {
          outcomeNote = '\nمرور این مبحث در برنامه فردا ثبت خواهد شد 🔁';
        } else if (_selectedOutcome == 'NEEDS_PRACTICE') {
          outcomeNote = '\nپیشنهاد: آزمونک تمرینی برای این مبحث بزن 📝';
        }

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colors.success,
            content: Text(
              'جلسه با موفقیت ثبت شد. خدا قوت! 💪$outcomeNote',
              style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ثبت جلسه: $e',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        );
      }
    }
  }

  String _formatTimerText() {
    final hours = _secondsElapsed ~/ 3600;
    final mins = (_secondsElapsed % 3600) ~/ 60;
    final secs = _secondsElapsed % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final subTopics = widget.topics.where((t) => t.subjectId == _selectedSubject?.id).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⏱ ثبت فعالیت و تایمر مطالعه',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mode Toggle
          Row(
            children: [
              _buildModeTab('STUDY', 'مطالعه 📚', colors),
              _buildModeTab('TEST', 'تست‌زنی 📝', colors),
              _buildModeTab('REVIEW', 'مرور 🔁', colors),
            ],
          ),
          const SizedBox(height: 20),
          // Subject & Topic Selector (if not preset)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<KonkurSubject>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'درس',
                    labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.subjects.map((sub) {
                    return DropdownMenuItem(
                      value: sub,
                      child: Text(sub.name, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (sub) {
                    setState(() {
                      _selectedSubject = sub;
                      final list = widget.topics.where((t) => t.subjectId == sub?.id).toList();
                      _selectedTopic = list.isNotEmpty ? list.first : null;
                      _promotedMastery = _selectedTopic?.masteryLevel;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<KonkurTopic>(
                  value: _selectedTopic,
                  decoration: const InputDecoration(
                    labelText: 'مبحث',
                    labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: subTopics.map((topic) {
                    return DropdownMenuItem(
                      value: topic,
                      child: Text(topic.name, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (topic) {
                    setState(() {
                      _selectedTopic = topic;
                      _promotedMastery = topic?.masteryLevel;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Timer Widget
          Card(
            elevation: 0,
            color: colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    toPersianDigits(_formatTimerText()),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        label: Text(
                          _isRunning ? 'توقف موقت' : 'شروع تایمر',
                          style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRunning ? colors.warning : const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh, color: Colors.grey),
                        label: const Text('ریست', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Test Mode Inputs
          if (_currentMode == 'TEST') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildNumberInput('صحیح', _correctController, colors)),
                const SizedBox(width: 8),
                Expanded(child: _buildNumberInput('غلط', _wrongController, colors)),
                const SizedBox(width: 8),
                Expanded(child: _buildNumberInput('نزده', _blankController, colors)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _netPercent >= 50.0
                    ? colors.success.withValues(alpha: 0.15)
                    : _netPercent >= 0.0
                        ? colors.warning.withValues(alpha: 0.15)
                        : colors.medicalRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'درصد خالص کنکور (نمره منفی):',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${toPersianDigits(_netPercent.toStringAsFixed(1))}٪',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _netPercent >= 50.0
                          ? colors.success
                          : _netPercent >= 0.0
                              ? colors.warning
                              : colors.medicalRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Outcome Picker on Complete
          Text(
            'نتیجه جلسه:',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('✅ کاملاً فهمیدم', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10)),
                selected: _selectedOutcome == 'UNDERSTOOD',
                selectedColor: Colors.green.withValues(alpha: 0.2),
                onSelected: (sel) => setState(() => _selectedOutcome = sel ? 'UNDERSTOOD' : null),
              ),
              ChoiceChip(
                label: const Text('🔵 تا حدی فهمیدم', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10)),
                selected: _selectedOutcome == 'PARTIAL',
                selectedColor: Colors.blue.withValues(alpha: 0.2),
                onSelected: (sel) => setState(() => _selectedOutcome = sel ? 'PARTIAL' : null),
              ),
              ChoiceChip(
                label: const Text('🔁 باید مرور بشه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10)),
                selected: _selectedOutcome == 'NEEDS_REVIEW',
                selectedColor: Colors.orange.withValues(alpha: 0.2),
                onSelected: (sel) => setState(() => _selectedOutcome = sel ? 'NEEDS_REVIEW' : null),
              ),
              ChoiceChip(
                label: const Text('📝 تمرین بیشتر لازمه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10)),
                selected: _selectedOutcome == 'NEEDS_PRACTICE',
                selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                onSelected: (sel) => setState(() => _selectedOutcome = sel ? 'NEEDS_PRACTICE' : null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mastery Level Picker on Complete
          if (_selectedTopic != null) ...[
            Text(
              'سطح تسلط جدید مبحث:',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: MasteryLevel.values.map((lvl) {
                final isSelected = _promotedMastery == lvl;
                return ChoiceChip(
                  avatar: Text(lvl.emoji),
                  label: Text(
                    lvl.label,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _promotedMastery = lvl;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 28),
          // Save Button
          ElevatedButton(
            onPressed: _secondsElapsed > 0 ? _saveSession : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.border,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              '✓ ثبت و اتمام جلسه مطالعه',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildModeTab(String mode, String label, RitmoColors colors) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF8B5CF6) : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller, RitmoColors colors) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, color: colors.textPrimary),
    );
  }
}
