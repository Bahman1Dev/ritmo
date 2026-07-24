import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';

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

class GoalsManagementSheet extends StatefulWidget {

  const GoalsManagementSheet({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<GoalsManagementSheet> createState() => _GoalsManagementSheetState();
}

class _GoalsManagementSheetState extends State<GoalsManagementSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _goalsList = [];
  final Map<String, List<Map<String, dynamic>>> _goalStepsMap = {};

  // Form states for creating a goal
  bool _isCreatingGoal = false;
  final _goalTitleController = TextEditingController();
  final _goalDescController = TextEditingController();
  
  // F5 goal progression and scheduling states
  String _selectedGoalType = 'ANNUAL';
  String? _selectedParentGoalId;
  final List<GoalStepInput> _stepInputs = [];
  List<Map<String, dynamic>> _routinesList = [];

  // F8 AI goal breakdown fields
  bool _isBreakingDown = false;
  List<AiSubGoalInput> _aiSubGoals = [];
  List<GoalStepInput> _aiDirectSteps = [];

  @override
  void initState() {
    super.initState();
    _loadGoalsData();
  }

  @override
  void dispose() {
    _goalTitleController.dispose();
    _goalDescController.dispose();
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

  Future<void> _loadGoalsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final goals = await db.query('goals', orderBy: 'createdAt DESC');

      _goalsList = goals;
      _goalStepsMap.clear();

      for (final goal in goals) {
        final goalId = goal['id']! as String;
        final steps = await db.query(
          'goal_steps',
          where: 'goalId = ?',
          whereArgs: [goalId],
          orderBy: 'displayOrder ASC',
        );
        _goalStepsMap[goalId] = steps;
      }

      final routines = await db.query('routines', where: 'isArchived = 0', orderBy: 'title ASC');
      _routinesList = routines;
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStep(String stepId, bool currentVal, String goalId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final newVal = currentVal ? 0 : 1;

      await db.update(
        'goal_steps',
        {'isCompleted': newVal},
        where: 'id = ?',
        whereArgs: [stepId],
      );

      // Check if all steps are completed to auto-complete goal
      final steps = await db.query('goal_steps', where: 'goalId = ?', whereArgs: [goalId]);
      final allCompleted = steps.every((s) => s['isCompleted'] == 1);
      
      await db.update(
        'goals',
        {
          'status': allCompleted ? 'COMPLETED' : 'ACTIVE',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [goalId],
      );

      HapticFeedback.lightImpact();
      _loadGoalsData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error toggling goal step: $e');
    }
  }

  Future<void> _triggerAiBreakdown() async {
    final title = _goalTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا عنوان هدف را وارد کنید.')),
      );
      return;
    }

    setState(() {
      _isBreakingDown = true;
    });

    try {
      final breakdown = await AIGateway.instance.breakDownGoal(
        goalTitle: title,
        goalDescription: _goalDescController.text.trim(),
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
                final match = _routinesList.firstWhere(
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
            final match = _routinesList.firstWhere(
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
        for (final sg in _aiSubGoals) {
          sg.dispose();
        }
        for (final st in _aiDirectSteps) {
          st.dispose();
        }

        _aiSubGoals = parsedSubGoals;
        _aiDirectSteps = parsedDirectSteps;
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
    if (_goalTitleController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final mainGoalId = 'goal_${DateTime.now().millisecondsSinceEpoch}';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert Main Goal
      await db.insert('goals', {
        'id': mainGoalId,
        'parentGoalId': _selectedParentGoalId,
        'title': _goalTitleController.text.trim(),
        'description': _goalDescController.text.trim().isNotEmpty ? _goalDescController.text.trim() : null,
        'goalType': _selectedGoalType,
        'status': 'ACTIVE',
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      if (_aiSubGoals.isNotEmpty || _aiDirectSteps.isNotEmpty) {
        // 2. Save Direct Steps
        for (var i = 0; i < _aiDirectSteps.length; i++) {
          final input = _aiDirectSteps[i];
          final title = input.titleController.text.trim();
          if (title.isNotEmpty) {
            final dateStr = input.scheduledDate?.toIso8601String().substring(0, 10);
            await db.insert('goal_steps', {
              'id': RitmoIdFactory.goalStep(),
              'goalId': mainGoalId,
              'title': title,
              'isCompleted': 0,
              'displayOrder': i,
              'createdAt': nowMs,
              'scheduledDate': dateStr,
              'linkedRoutineId': input.linkedRoutineId,
            });
          }
        }

        // 3. Save Sub-Goals & Sub-Goal Steps
        for (var i = 0; i < _aiSubGoals.length; i++) {
          final sg = _aiSubGoals[i];
          final sgTitle = sg.titleController.text.trim();
          if (sgTitle.isNotEmpty) {
            final subGoalId = RitmoIdFactory.goal();
            
            await db.insert('goals', {
              'id': subGoalId,
              'parentGoalId': mainGoalId,
              'title': sgTitle,
              'description': sg.descController.text.trim().isNotEmpty ? sg.descController.text.trim() : null,
              'goalType': sg.goalType,
              'status': 'ACTIVE',
              'createdAt': nowMs + i,
              'updatedAt': nowMs + i,
            });

            for (var j = 0; j < sg.stepInputs.length; j++) {
              final stepInput = sg.stepInputs[j];
              final stepTitle = stepInput.titleController.text.trim();
              if (stepTitle.isNotEmpty) {
                final dateStr = stepInput.scheduledDate?.toIso8601String().substring(0, 10);
                await db.insert('goal_steps', {
                  'id': RitmoIdFactory.goalStep(),
                  'goalId': subGoalId,
                  'title': stepTitle,
                  'isCompleted': 0,
                  'displayOrder': j,
                  'createdAt': nowMs,
                  'scheduledDate': dateStr,
                  'linkedRoutineId': stepInput.linkedRoutineId,
                });
              }
            }
          }
        }
      } else {
        // Save Manual Steps
        for (var i = 0; i < _stepInputs.length; i++) {
          final input = _stepInputs[i];
          final title = input.titleController.text.trim();
          if (title.isNotEmpty) {
            final dateStr = input.scheduledDate?.toIso8601String().substring(0, 10);
            await db.insert('goal_steps', {
              'id': RitmoIdFactory.goalStep(),
              'goalId': mainGoalId,
              'title': title,
              'isCompleted': 0,
              'displayOrder': i,
              'createdAt': nowMs,
              'scheduledDate': dateStr,
              'linkedRoutineId': input.linkedRoutineId,
            });
          }
        }
      }

      _goalTitleController.clear();
      _goalDescController.clear();
      for (final input in _stepInputs) {
        input.dispose();
      }
      _stepInputs.clear();

      for (final sg in _aiSubGoals) {
        sg.dispose();
      }
      _aiSubGoals.clear();

      for (final st in _aiDirectSteps) {
        st.dispose();
      }
      _aiDirectSteps.clear();

      _selectedParentGoalId = null;
      _selectedGoalType = 'ANNUAL';

      setState(() {
        _isCreatingGoal = false;
      });

      HapticFeedback.mediumImpact();
      await _loadGoalsData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error saving goal: $e');
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      // Cascade delete handles step deletion due to foreign key constraint
      await db.delete('goals', where: 'id = ?', whereArgs: [goalId]);

      HapticFeedback.mediumImpact();
      _loadGoalsData();
      widget.onSaved();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isCreatingGoal ? 'ایجاد هدف جدید' : 'اهداف و برنامه‌های زندگی',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                    if (!_isCreatingGoal)
                      IconButton(
                        icon: const Icon(CupertinoIcons.add_circled, color: Color(0xff5B8AF5), size: 24),
                        onPressed: () {
                          setState(() {
                            _isCreatingGoal = true;
                            _selectedGoalType = 'ANNUAL';
                            _selectedParentGoalId = null;
                            _stepInputs.clear();
                            _stepInputs.add(GoalStepInput(titleController: TextEditingController()));
                          });
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(CupertinoIcons.back, color: Colors.white60, size: 20),
                        onPressed: () {
                          setState(() {
                            for (final input in _stepInputs) {
                              input.dispose();
                            }
                            _stepInputs.clear();
                            _isCreatingGoal = false;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!_isCreatingGoal)
                  Text(
                    'اهداف بلندمدت و گام‌های عملی ریتم زندگی خود را مدیریت کنید.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                const Divider(color: Colors.white10, height: 20),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xff5B8AF5)))
                      : _isCreatingGoal
                          ? _buildCreateGoalForm(colors)
                          : _buildGoalsList(colors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(String type, String label, RitmoColors colors) {
    final isSelected = _selectedGoalType == type;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontFamily: 'Vazirmatn')),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedGoalType = type;
            _selectedParentGoalId = null;
          });
        }
      },
    );
  }

  Widget _buildCreateGoalForm(RitmoColors colors) {
    final activeGoals = _goalsList.where((g) => g['status'] == 'ACTIVE').toList();

    return ListView(
      children: [
        TextField(
          controller: _goalTitleController,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
          decoration: InputDecoration(
            hintText: 'عنوان هدف (مثلاً: قبولی در آزمون رانندگی)',
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
            fillColor: Colors.white.withValues(alpha: 0.02),
            filled: true,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _goalDescController,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'توضیحات هدف (اختیاری)',
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
            fillColor: Colors.white.withValues(alpha: 0.02),
            filled: true,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'سطح هدف',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLevelChip('ANNUAL', 'سالانه', colors),
            _buildLevelChip('MONTHLY', 'ماهانه', colors),
            _buildLevelChip('WEEKLY', 'هفتگی', colors),
            _buildLevelChip('DAILY', 'روزانه', colors),
          ],
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String?>(
          initialValue: _selectedParentGoalId,
          dropdownColor: colors.card,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
          decoration: InputDecoration(
            labelText: 'هدف مادر (اختیاری)',
            labelStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
            fillColor: Colors.white.withValues(alpha: 0.02),
            filled: true,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
          ),
          items: [
            const DropdownMenuItem<String?>(
              child: Text('بدون هدف مادر', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ...activeGoals.map((g) {
              final typeFarsi = {
                'ANNUAL': 'سالانه',
                'MONTHLY': 'ماهانه',
                'WEEKLY': 'هفتگی',
                'DAILY': 'روزانه',
              }[g['goalType']] ?? 'هدف';
              return DropdownMenuItem<String?>(
                value: g['id'] as String,
                child: Text('${g['title']} ($typeFarsi)', style: const TextStyle(fontFamily: 'Vazirmatn')),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              _selectedParentGoalId = val;
            });
          },
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('گام‌های عملی هدف (تسک‌ها)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(CupertinoIcons.wand_stars, size: 14, color: Color(0xff5B8AF5)),
                  label: const Text('تجزیه با هوش مصنوعی', style: TextStyle(fontSize: 11, color: Color(0xff5B8AF5), fontFamily: 'Vazirmatn')),
                  onPressed: _triggerAiBreakdown,
                ),
                TextButton.icon(
                  icon: const Icon(CupertinoIcons.add, size: 14, color: Color(0xff5B8AF5)),
                  label: const Text('افزودن گام', style: TextStyle(fontSize: 11, color: Color(0xff5B8AF5), fontFamily: 'Vazirmatn')),
                  onPressed: () {
                    setState(() {
                      _stepInputs.add(GoalStepInput(titleController: TextEditingController()));
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_isBreakingDown)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xff5B8AF5)),
                  SizedBox(height: 12),
                  Text(
                    'در حال خرد کردن هدف با هوش مصنوعی...',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Vazirmatn'),
                  ),
                ],
              ),
            ),
          ),

        if (_aiSubGoals.isNotEmpty || _aiDirectSteps.isNotEmpty) ...[
          const Divider(color: Colors.white24, height: 20),
          const Text(
            'پیش‌نمایش خرد کردن هدف (قابل ویرایش)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff5B8AF5), fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 12),

          if (_aiDirectSteps.isNotEmpty) ...[
            const Text('گام‌های مستقیم هدف', style: TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Vazirmatn')),
            const SizedBox(height: 8),
            ..._buildStepListFields(_aiDirectSteps, colors),
          ],

          ...List.generate(_aiSubGoals.length, (sgIndex) {
            final sg = _aiSubGoals[sgIndex];
            final farsiType = {
              'ANNUAL': 'سالانه',
              'MONTHLY': 'ماهانه',
              'WEEKLY': 'هفتگی',
              'DAILY': 'روزانه',
            }[sg.goalType] ?? 'هدف';

            return Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.01),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('هدف فرعی ${sgIndex + 1} ($farsiType)', style: const TextStyle(fontSize: 11, color: Color(0xff5B8AF5), fontFamily: 'Vazirmatn')),
                      IconButton(
                        icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            sg.dispose();
                            _aiSubGoals.removeAt(sgIndex);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sg.titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                    decoration: InputDecoration(
                      hintText: 'عنوان هدف فرعی',
                      hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 11),
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.3))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sg.descController,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Vazirmatn'),
                    decoration: InputDecoration(
                      hintText: 'توضیحات هدف فرعی',
                      hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 11),
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.3))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('گام‌های عملی هدف فرعی', style: TextStyle(fontSize: 10, color: Colors.white60, fontFamily: 'Vazirmatn')),
                      TextButton.icon(
                        icon: const Icon(CupertinoIcons.add, size: 10, color: Color(0xff5B8AF5)),
                        label: const Text('افزودن گام', style: TextStyle(fontSize: 10, color: Color(0xff5B8AF5), fontFamily: 'Vazirmatn')),
                        onPressed: () {
                          setState(() {
                            sg.stepInputs.add(GoalStepInput(titleController: TextEditingController()));
                          });
                        },
                      ),
                    ],
                  ),
                  ..._buildStepListFields(sg.stepInputs, colors),
                ],
              ),
            );
          }),
        ] else ...[
          ...List.generate(_stepInputs.length, (index) {
            final stepInput = _stepInputs[index];
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.01),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stepInput.titleController,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn'),
                          decoration: InputDecoration(
                            hintText: 'عنوان گام ${index + 1}',
                            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
                            fillColor: Colors.white.withValues(alpha: 0.02),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4))),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 18),
                        onPressed: () {
                          setState(() {
                            stepInput.dispose();
                            _stepInputs.removeAt(index);
                          });
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(CupertinoIcons.calendar, size: 14),
                          label: Text(
                            stepInput.scheduledDate == null
                                ? 'تاریخ برنامه‌ریزی'
                                : formatShamsiDate(stepInput.scheduledDate!.toIso8601String().substring(0, 10)),
                            style: const TextStyle(fontSize: 11, fontFamily: 'Vazirmatn'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final selected = await RitmoDatePicker.showJalali(
                              context: context,
                              initialDate: Jalali.fromDateTime(stepInput.scheduledDate ?? DateTime.now()),
                              firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365))),
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
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: stepInput.linkedRoutineId,
                              isExpanded: true,
                              hint: const Text('اتصال به روتین', style: TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'Vazirmatn')),
                              dropdownColor: colors.card,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Vazirmatn'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  child: Text('بدون روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                                ),
                                ..._routinesList.map((r) {
                                  return DropdownMenuItem<String?>(
                                    value: r['id'] as String,
                                    child: Text(r['title'] as String, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11), overflow: TextOverflow.ellipsis),
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
          }),
        ],

        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _saveGoal,
          child: const Text('ذخیره هدف زندگی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
        ),
      ],
    );
  }

  List<Widget> _buildStepListFields(List<GoalStepInput> inputs, RitmoColors colors) {
    return List.generate(inputs.length, (index) {
      final stepInput = inputs[index];
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: stepInput.titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Vazirmatn'),
                    decoration: InputDecoration(
                      hintText: 'عنوان گام ${index + 1}',
                      hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 11),
                      fillColor: Colors.white.withValues(alpha: 0.01),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.3))),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
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
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(CupertinoIcons.calendar, size: 12),
                    label: Text(
                      stepInput.scheduledDate == null
                          ? 'تاریخ برنامه‌ریزی'
                          : formatShamsiDate(stepInput.scheduledDate!.toIso8601String().substring(0, 10)),
                      style: const TextStyle(fontSize: 10, fontFamily: 'Vazirmatn'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () async {
                      final selected = await RitmoDatePicker.showJalali(
                        context: context,
                        initialDate: Jalali.fromDateTime(stepInput.scheduledDate ?? DateTime.now()),
                        firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365))),
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
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: stepInput.linkedRoutineId,
                        isExpanded: true,
                        hint: const Text('اتصال به روتین', style: TextStyle(fontSize: 10, color: Colors.white38, fontFamily: 'Vazirmatn')),
                        dropdownColor: colors.card,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Vazirmatn'),
                        items: [
                          const DropdownMenuItem<String?>(
                            child: Text('بدون روتین', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10)),
                          ),
                          ..._routinesList.map((r) {
                            return DropdownMenuItem<String?>(
                              value: r['id'] as String,
                              child: Text(r['title'] as String, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 10), overflow: TextOverflow.ellipsis),
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
    });
  }

  final Map<String, bool> _expandedGoals = {};

  Widget _buildGoalNode(Map<String, dynamic> goal, RitmoColors colors, double depth) {
    final goalId = goal['id'] as String;
    final title = goal['title'] as String;
    final desc = goal['description'] as String?;
    final isCompleted = goal['status'] == 'COMPLETED';
    final steps = _goalStepsMap[goalId] ?? [];
    final childGoals = _goalsList.where((g) => g['parentGoalId'] == goalId).toList();
    final isExpanded = _expandedGoals[goalId] ?? true;

    final completedSteps = steps.where((s) => s['isCompleted'] == 1).length;
    final totalSteps = steps.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : (isCompleted ? 1.0 : 0.0);

    final goalTypeFarsi = {
      'ANNUAL': 'سالانه',
      'MONTHLY': 'ماهانه',
      'WEEKLY': 'هفتگی',
      'DAILY': 'روزانه',
    }[goal['goalType']] ?? 'هدف';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.only(right: 12.0 * depth),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: depth == 0 ? 0.02 : 0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: depth == 0 ? 0.06 : 0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (childGoals.isNotEmpty || steps.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedGoals[goalId] = !isExpanded;
                      });
                    },
                    child: Icon(
                      isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_left,
                      color: colors.textSecondary,
                      size: 16,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              goalTypeFarsi,
                              style: TextStyle(fontSize: 9, color: colors.primary, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? colors.success : Colors.white,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                fontFamily: 'Vazirmatn',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteGoal(goalId),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 4,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(color: isCompleted ? colors.success : colors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  totalSteps > 0 ? '$completedSteps/$totalSteps گام' : (isCompleted ? '۱/۱' : '۰/۱'),
                  style: TextStyle(fontSize: 9, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
              ],
            ),
            if (isExpanded) ...[
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(color: Colors.white10, height: 10),
                ...steps.map((step) {
                  final stepId = step['id'] as String;
                  final stepTitle = step['title'] as String;
                  final stepDone = step['isCompleted'] == 1;

                  return GestureDetector(
                    onTap: () => _toggleStep(stepId, stepDone, goalId),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            stepDone ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                            color: stepDone ? colors.success : colors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stepTitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: stepDone ? colors.textSecondary : colors.textPrimary,
                                decoration: stepDone ? TextDecoration.lineThrough : null,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (childGoals.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...childGoals.map((child) => _buildGoalNode(child, colors, depth + 1)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList(RitmoColors colors) {
    if (_goalsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.flag_fill, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              'هنوز هیچ هدفی ثبت نکرده‌اید.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 6),
            Text(
              'با زدن دکمه + در بالا اولین هدف خود را بسازید.',
              style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 11, fontFamily: 'Vazirmatn'),
            ),
          ],
        ),
      );
    }

    final rootGoals = _goalsList.where((g) {
      final parentId = g['parentGoalId'];
      if (parentId == null || parentId.toString().isEmpty) return true;
      return !_goalsList.any((parent) => parent['id'] == parentId);
    }).toList();

    return ListView.builder(
      itemCount: rootGoals.length,
      itemBuilder: (context, index) {
        return _buildGoalNode(rootGoals[index], colors, 0);
      },
    );
  }
}
