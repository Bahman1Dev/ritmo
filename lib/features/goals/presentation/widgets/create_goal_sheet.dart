import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/courses/presentation/courses_screen.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';
import 'package:ritmo/features/konkur/presentation/konkur_screen.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart';
import 'package:ritmo/features/worship/presentation/worship_screen.dart';

class GoalStepInput {

  GoalStepInput({
    required this.titleController,
    this.scheduledDate,
    this.linkedRoutineId,
  });
  final TextEditingController titleController;
  DateTime? scheduledDate;
  String? linkedRoutineId;

  void dispose() {
    titleController.dispose();
  }
}

class AiSubGoalInput {

  AiSubGoalInput({
    required String title,
    required String desc,
    required this.goalType,
    required this.stepInputs,
  })  : titleController = TextEditingController(text: title),
        descController = TextEditingController(text: desc);
  final TextEditingController titleController;
  final TextEditingController descController;
  final String goalType;
  final List<GoalStepInput> stepInputs;

  void dispose() {
    titleController.dispose();
    descController.dispose();
    for (final s in stepInputs) {
      s.dispose();
    }
  }
}

class CreateGoalSheet extends StatefulWidget { // For pre-filling templates

  const CreateGoalSheet({
    super.key,
    required this.activeGoals,
    required this.routines,
    required this.onSaved,
    this.goalToEdit,
    this.templateData,
  });
  final List<Goal> activeGoals;
  final List<Map<String, dynamic>> routines;
  final VoidCallback onSaved;
  final Goal? goalToEdit; // If editing an existing goal
  final Map<String, dynamic>? templateData;

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedGoalType = 'MONTHLY';
  String? _selectedParentGoalId;
  DateTime? _targetDate;

  final List<GoalStepInput> _stepInputs = [];
  List<AiSubGoalInput> _aiSubGoals = [];
  List<GoalStepInput> _aiDirectSteps = [];

  bool _isBreakingDown = false;
  bool _isLoading = false;
  bool _isPrivate = false;

  // Wizard state
  int _currentStep = 0; // 0: چی؟ (What), 1: کی؟ (When), 2: چطور؟ (How)

  @override
  void initState() {
    super.initState();
    
    // Add default step
    _stepInputs.add(GoalStepInput(titleController: TextEditingController()));

    if (widget.templateData != null) {
      final t = widget.templateData!;
      _titleController.text = t['title'] ?? '';
      _descController.text = t['description'] ?? '';
      _selectedGoalType = t['goalType'] ?? 'MONTHLY';
      
      final initialSteps = t['steps'] as List<String>?;
      if (initialSteps != null && initialSteps.isNotEmpty) {
        _stepInputs.clear();
        for (final title in initialSteps) {
          _stepInputs.add(GoalStepInput(
            titleController: TextEditingController(text: title),
          ));
        }
      }
    }

    if (widget.goalToEdit != null) {
      final g = widget.goalToEdit!;
      _titleController.text = g.title;
      _descController.text = g.description ?? '';
      _selectedGoalType = g.goalType.toJson();
      _selectedParentGoalId = g.parentGoalId;
      _isPrivate = g.isPrivate == 1;
      if (g.targetDate != null && g.targetDate!.isNotEmpty) {
        _targetDate = DateTime.tryParse(g.targetDate!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final input in _stepInputs) {
      input.dispose();
    }
    for (final sg in _aiSubGoals) {
      sg.dispose();
    }
    for (final st in _aiDirectSteps) {
      st.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _triggerAiBreakdown() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً ابتدا عنوان هدف را وارد کنید.', style: TextStyle(fontFamily: 'Vazirmatn')),
        ),
      );
      return;
    }

    setState(() {
      _isBreakingDown = true;
    });

    try {
      final breakdown = await AIGateway.instance.breakDownGoal(
        goalTitle: title,
        goalDescription: _descController.text.trim(),
        goalType: _selectedGoalType,
      );

      final parsedSubGoals = <AiSubGoalInput>[];
      if (breakdown['subGoals'] != null && breakdown['subGoals'] is List) {
        for (final sg in breakdown['subGoals']) {
          final steps = <GoalStepInput>[];
          if (sg['steps'] != null && sg['steps'] is List) {
            for (final st in sg['steps']) {
              final offsetDays = st['offsetDays'] as int? ?? 0;
              final scheduledDate = DateTime.now().add(Duration(days: offsetDays));
              
              String? linkedRoutineId;
              final routineType = st['suggestedRoutineType']?.toString().toLowerCase();
              if (routineType != null && routineType != 'null') {
                final match = widget.routines.firstWhere(
                  (r) => (r['category'] as String? ?? '').toLowerCase() == routineType,
                  orElse: () => <String, dynamic>{},
                );
                if (match.isNotEmpty) {
                  linkedRoutineId = match['id'] as String;
                }
              }

              steps.add(GoalStepInput(
                titleController: TextEditingController(text: st['title'] as String? ?? ''),
                scheduledDate: scheduledDate,
                linkedRoutineId: linkedRoutineId,
              ));
            }
          }

          parsedSubGoals.add(AiSubGoalInput(
            title: sg['title'] as String? ?? '',
            desc: sg['description'] as String? ?? '',
            goalType: sg['goalType'] as String? ?? 'DAILY',
            stepInputs: steps,
          ));
        }
      }

      final parsedDirectSteps = <GoalStepInput>[];
      if (breakdown['steps'] != null && breakdown['steps'] is List) {
        for (final st in breakdown['steps']) {
          final offsetDays = st['offsetDays'] as int? ?? 0;
          final scheduledDate = DateTime.now().add(Duration(days: offsetDays));

          String? linkedRoutineId;
          final routineType = st['suggestedRoutineType']?.toString().toLowerCase();
          if (routineType != null && routineType != 'null') {
            final match = widget.routines.firstWhere(
              (r) => (r['category'] as String? ?? '').toLowerCase() == routineType,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              linkedRoutineId = match['id'] as String;
            }
          }

          parsedDirectSteps.add(GoalStepInput(
            titleController: TextEditingController(text: st['title'] as String? ?? ''),
            scheduledDate: scheduledDate,
            linkedRoutineId: linkedRoutineId,
          ));
        }
      }

      setState(() {
        _aiSubGoals = parsedSubGoals;
        _aiDirectSteps = parsedDirectSteps;
        // Swap manual steps with AI steps for easy edit
        if (_aiDirectSteps.isNotEmpty) {
          _stepInputs.clear();
          _stepInputs.addAll(_aiDirectSteps);
        }
      });
    } catch (e) {
      debugPrint('Error breaking down goal: $e');
    } finally {
      setState(() {
        _isBreakingDown = false;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (_titleController.text.trim().isEmpty) return;

    if (widget.goalToEdit == null && !PremiumService.instance.can(PremiumFeature.unlimitedGoals)) {
      final db = await DatabaseHelper.instance.database;
      final activeCountQuery = await db.rawQuery(
        "SELECT COUNT(*) as count FROM goals WHERE status != 'COMPLETED' AND parentGoalId IS NULL"
      );
      final activeCount = (activeCountQuery.first['count'] as num?)?.toInt() ?? 0;
      final limit = PremiumService.instance.limitFor(PremiumFeature.unlimitedGoals);

      if (activeCount >= limit && mounted) {
        PremiumUpgradeSheet.show(context);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final targetDateStr = _targetDate?.toIso8601String().substring(0, 10);

      final steps = <Map<String, dynamic>>[];
      final subGoals = <Map<String, dynamic>>[];

      if (_aiSubGoals.isNotEmpty && _aiDirectSteps.isEmpty) {
        // Direct steps from AI (if any)
        for (final ds in _aiDirectSteps) {
          steps.add({
            'title': ds.titleController.text.trim(),
            'scheduledDate': ds.scheduledDate?.toIso8601String().substring(0, 10),
            'linkedRoutineId': ds.linkedRoutineId,
          });
        }

        // Sub goals from AI
        for (final sg in _aiSubGoals) {
          final sgSteps = <Map<String, dynamic>>[];
          for (final s in sg.stepInputs) {
            sgSteps.add({
              'title': s.titleController.text.trim(),
              'scheduledDate': s.scheduledDate?.toIso8601String().substring(0, 10),
              'linkedRoutineId': s.linkedRoutineId,
            });
          }
          subGoals.add({
            'title': sg.titleController.text.trim(),
            'description': sg.descController.text.trim(),
            'goalType': sg.goalType,
            'steps': sgSteps,
          });
        }
      } else {
        // Manual steps (or AI steps copied to manual list)
        for (final s in _stepInputs) {
          steps.add({
            'title': s.titleController.text.trim(),
            'scheduledDate': s.scheduledDate?.toIso8601String().substring(0, 10),
            'linkedRoutineId': s.linkedRoutineId,
          });
        }
      }

      final database = await DatabaseHelper.instance.database;
      if (widget.goalToEdit != null) {
        // Editing: update title, description, parentGoalId, goalType, targetDate
        await database.update(
          'goals',
          {
            'title': _titleController.text.trim(),
            'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
            'parentGoalId': _selectedParentGoalId,
            'goalType': _selectedGoalType,
            'targetDate': targetDateStr,
            'isPrivate': _isPrivate ? 1 : 0,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [widget.goalToEdit!.id],
        );
      } else {
        // Saving new goal
        await GoalsRepository.instance.saveGoal(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
          goalType: _selectedGoalType,
          parentGoalId: _selectedParentGoalId,
          targetDate: targetDateStr,
          steps: steps,
          subGoals: subGoals,
        );
        // Update privacy field for newly created goal
        await database.rawUpdate(
          'UPDATE goals SET isPrivate = ? WHERE id = (SELECT id FROM goals ORDER BY createdAt DESC LIMIT 1)',
          [if (_isPrivate) 1 else 0],
        );
      }

      HapticFeedback.mediumImpact();
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving goal: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Contextual Banners Detection ---
  Widget? _detectContextualBanner(String text, RitmoColors colors) {
    if (text.isEmpty) return null;
    final clean = text.toLowerCase();
    
    if (clean.contains('کنکور') || clean.contains('آزمون') || clean.contains('تست')) {
      return _buildBanner('کنکور', colors, const KonkurScreen());
    }
    if (clean.contains('ورزش') || clean.contains('باشگاه') || clean.contains('تمرین') || clean.contains('بدنسازی')) {
      return _buildBanner('ورزش تکمیلی', colors, const SSHomeDashboardScreen());
    }
    if (clean.contains('نماز') || clean.contains('قرآن') || clean.contains('عبادت') || clean.contains('دعا') || clean.contains('روزه')) {
      return _buildBanner('عبادت', colors, const WorshipScreen());
    }
    if (clean.contains('درس') || clean.contains('دوره') || clean.contains('کلاس') || clean.contains('آموزش')) {
      return _buildBanner('دوره‌های آموزشی', colors, const CoursesScreen());
    }
    return null;
  }

  Widget _buildBanner(String moduleName, RitmoColors colors, Widget targetScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.info, color: colors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'برای برنامه‌ریزی $moduleName بخش اختصاصی وجود دارد.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5, color: colors.textPrimary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.pop(context); // Close sheet
              Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
            },
            child: Text(
              'ورود به بخش',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      expand: false,
      snap: true,
      snapSizes: const [0.85, 1.0],
      builder: (context, scrollController) {
        return RitmoTheme.glassCardLight(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Wizard Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _buildStepIndicator(0, 'چی؟', colors),
                      _buildStepConnector(colors),
                      _buildStepIndicator(1, 'کی؟', colors),
                      _buildStepConnector(colors),
                      _buildStepIndicator(2, 'چطور؟', colors),
                    ],
                  ),
                ),

                // Live Preview Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildLivePreviewCard(colors),
                ),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: bottomInset + 20,
                    ),
                    children: [
                      IndexedStack(
                        index: _currentStep,
                        children: [
                          _buildStep1What(colors),
                          _buildStep2When(colors),
                          _buildStep3How(colors),
                        ],
                      ),
                    ],
                  ),
                ),

                // Wizard Bottom Navigation Actions
                _buildWizardFooter(colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, RitmoColors colors) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : Colors.white10,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: Colors.white, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            toPersianDigits(stepIndex + 1),
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontFamily: 'Vazirmatn',
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(RitmoColors colors) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 1.5,
        color: Colors.white10,
      ),
    );
  }

  Widget _buildLivePreviewCard(RitmoColors colors) {
    final title = _titleController.text.trim().isEmpty ? 'عنوان هدف شما' : _titleController.text.trim();
    final typeLabel = GoalLevel.fromString(_selectedGoalType).label;
    final dateStr = _targetDate != null ? formatShamsiDate(_targetDate!.toIso8601String().substring(0, 10)) : 'بدون مهلت';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'پیش‌نمایش هدف',
                style: TextStyle(fontSize: 10, fontFamily: 'Vazirmatn', color: colors.primary, fontWeight: FontWeight.bold),
              ),
              Icon(CupertinoIcons.eye, size: 12, color: colors.primary),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, fontFamily: 'Vazirmatn', color: colors.textPrimary, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(fontSize: 10, fontFamily: 'Vazirmatn', color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 11, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'مهلت: $dateStr',
                style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 1: WHAT? ---
  Widget _buildStep1What(RitmoColors colors) {
    final banner = _detectContextualBanner(_titleController.text, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'چه چیزی می‌خواهید بسازید؟',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 12),

        // Title field
        TextField(
          controller: _titleController,
          style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
          decoration: InputDecoration(
            hintText: 'مثال: تسلط بر مکالمه انگلیسی',
            labelText: 'عنوان هدف',
            labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
            prefixIcon: Icon(CupertinoIcons.flag, color: colors.primary, size: 18),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primary)),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),

        // Context Banner
        banner ?? const SizedBox.shrink(),

        const SizedBox(height: 20),

        // Description field
        TextField(
          controller: _descController,
          style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'مثال: تمرین مکالمه روزانه به مدت ۳ ماه متوالی',
            labelText: 'توضیحات هدف (اختیاری)',
            labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
            prefixIcon: Icon(CupertinoIcons.text_alignleft, color: colors.textSecondary, size: 18),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primary)),
          ),
        ),

        const SizedBox(height: 24),

        // Level chips selection
        Text(
          'بازه برنامه‌ریزی هدف (سطح)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLevelChipButton('DAILY', 'روزانه', colors),
            _buildLevelChipButton('WEEKLY', 'هفتگی', colors),
            _buildLevelChipButton('MONTHLY', 'ماهانه', colors),
            _buildLevelChipButton('ANNUAL', 'سالانه', colors),
          ],
        ),

        const SizedBox(height: 24),

        // Parent goal selector
        if (widget.activeGoals.isNotEmpty) ...[
          Text(
            'هدف والد (اختیاری)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedParentGoalId,
                isExpanded: true,
                dropdownColor: colors.card,
                hint: const Text('انتخاب هدف والد', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white30)),
                items: [
                  const DropdownMenuItem<String?>(
                    child: Text('بدون والد', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                  ),
                  ...widget.activeGoals
                      .where((g) => g.id != widget.goalToEdit?.id)
                      .map((g) {
                    return DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(g.title, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedParentGoalId = val;
                  });
                },
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Private toggle
        CheckboxListTile(
          title: const Text('تنظیم به عنوان هدف خصوصی', style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn')),
          subtitle: const Text('در چت دستیار و گزارشات پنهان می‌ماند.', style: TextStyle(fontSize: 10.5, fontFamily: 'Vazirmatn')),
          value: _isPrivate,
          activeColor: colors.primary,
          checkColor: Colors.white,
          onChanged: (val) {
            setState(() {
              _isPrivate = val ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildLevelChipButton(String typeKey, String label, RitmoColors colors) {
    final isSelected = _selectedGoalType == typeKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedGoalType = typeKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // --- STEP 2: WHEN? ---
  Widget _buildStep2When(RitmoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'چه زمانی مهلت پایان هدف است؟',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 16),

        // Main Date Picker trigger
        InkWell(
          onTap: () async {
            final selected = await RitmoDatePicker.showJalali(
              context: context,
              initialDate: Jalali.fromDateTime(_targetDate ?? DateTime.now().add(const Duration(days: 30))),
              firstDate: Jalali.fromDateTime(DateTime.now()),
              lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 365 * 3))),
            );
            if (selected != null) {
              setState(() {
                _targetDate = selected.toDateTime();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.calendar_badge_plus, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _targetDate == null ? 'انتخاب تاریخ پایان' : 'تاریخ پایان تنظیم شده',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _targetDate == null
                            ? 'بدون تاریخ (مهلت نامحدود)'
                            : formatShamsiDate(_targetDate!.toIso8601String().substring(0, 10)),
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, color: colors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_left, size: 16, color: colors.textSecondary),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Quick Shortcuts
        Text(
          'میان‌برهای سریع تاریخ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        
        Row(
          children: [
            Expanded(
              child: _buildDateShortcutButton('تا آخر ماه', () {
                final nowJ = Jalali.now();
                final targetJ = Jalali(nowJ.year, nowJ.month, nowJ.monthLength);
                setState(() {
                  _targetDate = targetJ.toDateTime();
                });
              }, colors),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDateShortcutButton('۳ ماه آینده', () {
                final nowJ = Jalali.now();
                var newMonth = nowJ.month + 3;
                var newYear = nowJ.year;
                if (newMonth > 12) {
                  newMonth -= 12;
                  newYear += 1;
                }
                final targetJ = Jalali(newYear, newMonth, nowJ.day);
                setState(() {
                  _targetDate = targetJ.toDateTime();
                });
              }, colors),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildDateShortcutButton('تا کنکور (۱۲ تیر)', () {
          // Hardcode typical Konkur date or fallback
          final konkurJ = Jalali(1406, 4, 12);
          setState(() {
            _targetDate = konkurJ.toDateTime();
          });
        }, colors, isFullWidth: true),
      ],
    );
  }

  Widget _buildDateShortcutButton(String label, VoidCallback onTap, RitmoColors colors, {bool isFullWidth = false}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn', color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // --- STEP 3: HOW? ---
  Widget _buildStep3How(RitmoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'گام‌های اجرایی و اتصال روتین‌ها',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
            ),
            
            // AI breakdown assistant trigger
            if (widget.goalToEdit == null)
              _isBreakingDown
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B))),
                    )
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                      icon: const Icon(CupertinoIcons.wand_stars, size: 14, color: Color(0xFFF59E0B)),
                      label: const Text('شکستن با هوش مصنوعی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      onPressed: _triggerAiBreakdown,
                    ),
          ],
        ),
        const SizedBox(height: 12),

        // Steps Builder
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _stepInputs.length,
          itemBuilder: (context, index) {
            return _buildStepInputRow(_stepInputs[index], index, _stepInputs, colors);
          },
        ),

        const SizedBox(height: 16),

        // Add Step Button
        OutlinedButton.icon(
          icon: Icon(CupertinoIcons.add, size: 14, color: colors.primary),
          label: const Text('افزودن گام دستی جدید', style: TextStyle(fontFamily: 'Vazirmatn')),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 44),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _stepInputs.add(GoalStepInput(titleController: TextEditingController()));
            });
          },
        ),
      ],
    );
  }

  Widget _buildStepInputRow(GoalStepInput stepInput, int index, List<GoalStepInput> inputs, RitmoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: stepInput.titleController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontFamily: 'Vazirmatn'),
                  decoration: InputDecoration(
                    hintText: 'مثال: مطالعه فصل اول کتاب',
                    labelText: 'گام ${index + 1}',
                    labelStyle: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 14),
                onPressed: () {
                  setState(() {
                    stepInput.dispose();
                    inputs.removeAt(index);
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Scheduled Date Shamsi picker button
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(CupertinoIcons.calendar, size: 11, color: colors.primary),
                  label: Text(
                    stepInput.scheduledDate == null
                        ? 'تاریخ برنامه‌ریزی'
                        : formatShamsiDate(stepInput.scheduledDate!.toIso8601String().substring(0, 10)),
                    style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', color: colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
                  ),
                  onPressed: () async {
                    final selected = await RitmoDatePicker.showJalali(
                      context: context,
                      initialDate: Jalali.fromDateTime(stepInput.scheduledDate ?? DateTime.now()),
                      firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 30))),
                      lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 365 * 2))),
                    );
                    if (selected != null) {
                      setState(() {
                        stepInput.scheduledDate = selected.toDateTime();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Connected Routine dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border.withValues(alpha: 0.4)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: stepInput.linkedRoutineId,
                      isExpanded: true,
                      hint: const Text('اتصال به روتین', style: TextStyle(fontSize: 11.5, color: Colors.white38, fontFamily: 'Vazirmatn')),
                      dropdownColor: colors.card,
                      style: TextStyle(color: colors.textPrimary, fontSize: 11.5, fontFamily: 'Vazirmatn'),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('بدون روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5)),
                        ),
                        ...widget.routines.map((r) {
                          return DropdownMenuItem<String?>(
                            value: r['id'] as String,
                            child: Text(r['title'] as String, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5), overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          stepInput.linkedRoutineId = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FOOTER CONTROLS ---
  Widget _buildWizardFooter(RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black12,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back / Cancel button
          if (_currentStep > 0)
            ElevatedButton(
              onPressed: _prevStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                foregroundColor: colors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('مرحله قبل', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
            ),

          // Next / Save button
          ElevatedButton(
            onPressed: _currentStep == 2 ? _saveGoal : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(
                    _currentStep == 2 ? (widget.goalToEdit != null ? 'ذخیره تغییرات' : 'ایجاد هدف') : 'مرحله بعد',
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
