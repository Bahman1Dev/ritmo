import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_exercise_model.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_plan_generator.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/bottom_sheet_container.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/empty_state_view.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/secondary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/selectable_card.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/stepper_input.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';
import 'package:sqflite/sqflite.dart';

class SSPlanDayDetailScreen extends StatefulWidget {

  const SSPlanDayDetailScreen({
    super.key,
    required this.dayOfWeek,
    required this.dayName,
  });
  final int dayOfWeek;
  final String dayName;

  @override
  State<SSPlanDayDetailScreen> createState() => _SSPlanDayDetailScreenState();
}

class _SSPlanDayDetailScreenState extends State<SSPlanDayDetailScreen> {
  bool _isLoading = true;
  String? _planId;
  List<PlanExerciseDetail> _exercises = [];
  SSInlineAiSuggestion? _aiSuggestion;

  @override
  void initState() {
    super.initState();
    _loadDayDetails();
  }

  Future<void> _loadDayDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Load plan for this day
      final plans = await db.query(
        'ss_workout_plan',
        where: 'dayOfWeek = ?',
        whereArgs: [widget.dayOfWeek],
      );

      if (plans.isEmpty) {
        setState(() {
          _planId = null;
          _exercises = [];
          _isLoading = false;
        });
        return;
      }

      final plan = plans.first;
      _planId = plan['id'].toString();

      // 2. Load crossrefs joined with exercises
      final results = await db.rawQuery('''
        SELECT c.id as crossRefId, c.targetSets, c.targetReps, c.targetWeight,
               e.id as exId, e.name as exName, e.category as exCategory,
               e.equipment as exEquipment, e.instructions as exInstructions,
               e.changeSides as exChangeSides, e.repsDouble as exRepsDouble,
               e.repsHint as exRepsHint, e.impact as exImpact, e.noisy as exNoisy
        FROM ss_workout_exercise_crossref c
        JOIN ss_exercise e ON c.exerciseId = e.id
        WHERE c.planId = ?
        ORDER BY c.orderIndex ASC
      ''', [_planId]);

      final list = <PlanExerciseDetail>[];
      for (final row in results) {
        list.add(
          PlanExerciseDetail(
            crossRefId: row['crossRefId'].toString(),
            exercise: SsExerciseModel(
              id: row['exId'].toString(),
              name: row['exName'].toString(),
              category: row['exCategory'].toString(),
              equipment: row['exEquipment']?.toString(),
              instructions: row['exInstructions']?.toString(),
              changeSides: (row['exChangeSides'] as int? ?? 0) == 1,
              repsDouble: (row['exRepsDouble'] as int? ?? 0) == 1,
              repsHint: row['exRepsHint']?.toString(),
              impact: row['exImpact'] is num ? (row['exImpact']! as num).toInt() : 0,
              noisy: row['exNoisy'] is num ? (row['exNoisy']! as num).toInt() : 0,
            ),
            targetSets: row['targetSets'] as int? ?? 3,
            targetReps: row['targetReps'] as int? ?? 10,
            targetWeight: (row['targetWeight'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }

      // 3. Populate dynamic AI Overload Suggestion if we have exercises
      if (list.isNotEmpty && widget.dayOfWeek == 1) {
        final exName = list.first.exercise.name;
        _aiSuggestion = SSInlineAiSuggestion(
          id: 'sug_overload_${list.first.exercise.id}',
          message: 'مربی هوشمند 🤖: چون سه هفته متوالی حرکت «$exName» برایت راحت بوده، وزنه را ۵ کیلوگرم اضافه کنم؟',
          crossRefId: list.first.crossRefId,
          newWeight: list.first.targetWeight + 5.0,
        );
      } else {
        _aiSuggestion = null;
      }

      setState(() {
        _exercises = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading day details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save current plan snapshot to history (including plans and crossrefs)
  Future<void> _logVersionHistory(Database db, String reason) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentPlans = await db.query('ss_workout_plan');
    final currentCrossRefs = await db.query('ss_workout_exercise_crossref');
    final serializedData = {
      'plans': currentPlans,
      'crossrefs': currentCrossRefs,
    };
    await db.insert('ss_plan_version_history', {
      'id': 'snap_$now',
      'serializedPlan': jsonEncode(serializedData),
      'changeReason': reason,
      'createdAt': now,
    });
  }

  Future<void> _createDefaultPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Load user profile
      final profileMapList = await db.query('ss_user_profile', limit: 1);
      if (profileMapList.isEmpty) {
        throw Exception('User profile not found. Complete onboarding first.');
      }
      final profile = SsUserProfile.fromMap(profileMapList.first);

      // Determine active week from existing plans or default to 1
      var week = 1;
      final existingPlans = await db.query('ss_workout_plan');
      for (final p in existingPlans) {
        final pid = p['id'].toString();
        if (pid.startsWith('plan_w')) {
          final parts = pid.split('_');
          if (parts.length >= 2 && parts[1].startsWith('w')) {
            final wNum = int.tryParse(parts[1].substring(1));
            if (wNum != null) {
              week = wNum;
              break;
            }
          }
        }
      }

      // Generate the single day plan using SSPlanGenerator
      await SSPlanGenerator.generateSingleDayPlan(
        db,
        profile,
        week: week,
        dayOfWeek: widget.dayOfWeek,
      );

      await _logVersionHistory(db, 'ایجاد برنامه جدید روز ${widget.dayName}');
      await _loadDayDetails();
    } catch (e) {
      debugPrint('Error creating default plan: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyAiSuggestion() async {
    if (_aiSuggestion == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final action = AssistantAction(
        type: AssistantActionType.adjustWorkoutIntensity,
        title: 'اعمال پیشنهاد هوشمند سنگین‌تر کردن وزنه',
        payload: {
          'crossRefId': _aiSuggestion!.crossRefId,
          'newWeight': _aiSuggestion!.newWeight.toString(),
        },
      );

      await AssistantActionRegistry.executeAction(
        context,
        action,
        () async {
          _aiSuggestion = null;
          await _loadDayDetails();
        },
      );
    } catch (e) {
      debugPrint('Error applying AI suggestion: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateExerciseTargets(String crossRefId, int sets, int reps, double weight) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'ss_workout_exercise_crossref',
        {
          'targetSets': sets,
          'targetReps': reps,
          'targetWeight': weight,
        },
        where: 'id = ?',
        whereArgs: [crossRefId],
      );
      // Optional: log to version history if you want, but simple updates can bypass to avoid database size bloat
    } catch (e) {
      debugPrint('Error updating exercise targets: $e');
    }
  }

  Future<void> _deleteExercise(String crossRefId) async {
    if (_planId == null) return;

    if (_exercises.length == 1) {
      // Last exercise warning
      _showLastExerciseWarning(crossRefId);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'ss_workout_exercise_crossref',
        where: 'id = ?',
        whereArgs: [crossRefId],
      );

      await _logVersionHistory(db, 'حذف حرکت از روز ${widget.dayName}');
      await _loadDayDetails();
    } catch (e) {
      debugPrint('Error deleting exercise: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLastExerciseWarning(String crossRefId) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('این روز خالی می‌ماند!', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            content: const Text('حذف این حرکت باعث خالی شدن کل روز تمرینی می‌شود. آیا می‌خواهید کل روز تمرینی را حذف کنید یا حرکت دیگری جایگزین کنید؟', style: TextStyle(fontFamily: 'Vazirmatn')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddExerciseBottomSheet();
                },
                child: const Text('جایگزین کردن', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteEntirePlanDay();
                },
                child: const Text('حذف کل روز تمرینی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteEntirePlanDay() async {
    if (_planId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('ss_workout_plan', where: 'id = ?', whereArgs: [_planId]);
      await db.delete('ss_workout_exercise_crossref', where: 'planId = ?', whereArgs: [_planId]);

      await _logVersionHistory(db, 'حذف کل روز تمرینی ${widget.dayName}');
      await _loadDayDetails();
    } catch (e) {
      debugPrint('Error deleting plan day: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showSwapExerciseBottomSheet(PlanExerciseDetail currentDetail) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Load user profile
      final profileMapList = await db.query('ss_user_profile', limit: 1);
      if (profileMapList.isEmpty) return;
      final profile = SsUserProfile.fromMap(profileMapList.first);

      // Query similarity exercises using safety and equipment logic
      final results = await SSPlanGenerator.getSwapCandidates(
        db,
        currentDetail.exercise.id,
        profile,
      );

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حرکت مشابه عضلانی یافت نشد.', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
          );
        }
        return;
      }

      if (mounted) {
        unawaited(showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return BottomSheetContainer(
              title: 'جایگزین مشابه برای ${currentDetail.exercise.name}',
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final row = results[index];
                  final exId = row['id'].toString();
                  final exName = row['name'].toString();
                  final score = ((row['similarityScore'] as num? ?? 0.0) * 100).round();

                  return SelectableCard(
                    title: '$exName (شباهت: $score٪)',
                    selected: false,
                    onClick: () async {
                      Navigator.pop(context);
                      await _swapExercise(currentDetail.crossRefId, exId, exName);
                    },
                  );
                },
              ),
            );
          },
        ));
      }
    } catch (e) {
      debugPrint('Error swapping exercise: $e');
    }
  }

  Future<void> _swapExercise(String crossRefId, String newExerciseId, String newName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'ss_workout_exercise_crossref',
        {'exerciseId': newExerciseId},
        where: 'id = ?',
        whereArgs: [crossRefId],
      );

      await _logVersionHistory(db, 'جایگزینی حرکت با $newName');
      await _loadDayDetails();
    } catch (e) {
      debugPrint('Error swapping exercise: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddExerciseBottomSheet() async {
    if (_planId == null) return;

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Query all exercises not in this day
      final results = await db.query('ss_exercise');

      if (mounted) {
        unawaited(showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: BottomSheetContainer(
                title: 'افزودن حرکت جدید',
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final row = results[index];
                    final exId = row['id'].toString();
                    final exName = row['name'].toString();
                    final equip = row['equipment']?.toString() ?? 'وزن بدن';

                    // Check if already in plan
                    final alreadyAdded = _exercises.any((e) => e.exercise.id == exId);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SelectableCard(
                        title: '$exName ($equip)',
                        selected: alreadyAdded,
                        onClick: alreadyAdded ? () {} : () async {
                          Navigator.pop(context);
                          await _addExerciseToPlan(exId, exName);
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ));
      }
    } catch (e) {
      debugPrint('Error loading exercises: $e');
    }
  }

  Future<void> _addExerciseToPlan(String exerciseId, String exerciseName) async {
    if (_planId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final crossRefId = 'cross_${_planId}_${exerciseId}_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert('ss_workout_exercise_crossref', {
        'id': crossRefId,
        'planId': _planId,
        'exerciseId': exerciseId,
        'orderIndex': _exercises.length,
        'targetSets': 3,
        'targetReps': 10,
        'targetWeight': 10.0,
      });

      await _logVersionHistory(db, 'افزودن حرکت $exerciseName');
      await _loadDayDetails();
    } catch (e) {
      debugPrint('Error adding exercise: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
        body: Center(child: SSLottiePlayer.loading(size: 100)),
      );
    }

    if (_planId == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
        appBar: AppBar(
          title: Text(widget.dayName, style: const TextStyle(fontFamily: 'Vazirmatn')),
          centerTitle: true,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: EmptyStateView(
            message: 'برای روز ${widget.dayName} هیچ برنامه تمرینی فعال نشده است.',
            actionLabel: 'ایجاد برنامه برای امروز',
            onAction: _createDefaultPlan,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: Text('جزئیات تمرین ${widget.dayName}', style: const TextStyle(fontFamily: 'Vazirmatn')),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SupplementarySportsTheme.spacing24,
                    vertical: SupplementarySportsTheme.spacing16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Inline Suggestion Card
                      if (_aiSuggestion != null) ...[
                        _buildAiInlineCard(),
                        const SizedBox(height: SupplementarySportsTheme.spacing24),
                      ],

                      // Exercises List
                      Text(
                        'لیست حرکات امروز',
                        style: SupplementarySportsTheme.h2.copyWith(
                          color: SupplementarySportsTheme.getTextPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: SupplementarySportsTheme.spacing12),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final detail = _exercises[index];
                          return _buildExerciseEditableCard(detail);
                        },
                      ),
                      const SizedBox(height: SupplementarySportsTheme.spacing24),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(SupplementarySportsTheme.spacing24),
                child: PrimaryButton(
                  label: '+ افزودن حرکت',
                  onPressed: _showAddExerciseBottomSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiInlineCard() {
    return Container(
      padding: const EdgeInsets.all(SupplementarySportsTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _aiSuggestion!.message,
            textDirection: TextDirection.rtl,
            style: SupplementarySportsTheme.body.copyWith(
              color: SupplementarySportsTheme.getTextPrimary(context),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: SupplementarySportsTheme.spacing16),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              PrimaryButton(
                label: 'تایید و اعمال',
                width: 140,
                onPressed: _applyAiSuggestion,
              ),
              const SizedBox(width: SupplementarySportsTheme.spacing12),
              SecondaryButton(
                label: 'رد کردن',
                width: 100,
                onPressed: () {
                  setState(() {
                    _aiSuggestion = null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseEditableCard(PlanExerciseDetail detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: SupplementarySportsTheme.spacing8),
      padding: const EdgeInsets.all(SupplementarySportsTheme.spacing16),
      decoration: BoxDecoration(
        color: SupplementarySportsTheme.getSurfaceColor(context),
        borderRadius: SupplementarySportsTheme.borderRadiusCard,
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          // Header Row
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      detail.exercise.name,
                      style: SupplementarySportsTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: SupplementarySportsTheme.getTextPrimary(context),
                      ),
                    ),
                     const SizedBox(height: 4),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          detail.exercise.equipment ?? 'وزن بدن',
                          style: SupplementarySportsTheme.caption.copyWith(
                            color: SupplementarySportsTheme.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          detail.exercise.impact >= 2 
                              ? Icons.directions_run 
                              : (detail.exercise.impact == 1 ? Icons.directions_walk : Icons.spa),
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          detail.exercise.impact >= 2 ? 'پربرخورد' : (detail.exercise.impact == 1 ? 'متوسط' : 'آرام'),
                          style: SupplementarySportsTheme.caption.copyWith(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          detail.exercise.noisy >= 2 
                              ? Icons.volume_up 
                              : (detail.exercise.noisy == 1 ? Icons.volume_down : Icons.volume_mute),
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          detail.exercise.noisy >= 2 ? 'پرصدا' : (detail.exercise.noisy == 1 ? 'متوسط' : 'بی‌صدا'),
                          style: SupplementarySportsTheme.caption.copyWith(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sync_alt, size: 20, color: Colors.blueAccent),
                    tooltip: 'جایگزین مشابه',
                    onPressed: () => _showSwapExerciseBottomSheet(detail),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: 'حذف',
                    onPressed: () => _deleteExercise(detail.crossRefId),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: SupplementarySportsTheme.spacing8),

          // Parameter Editors
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sets
              _buildTargetEditor(
                label: 'ست',
                value: detail.targetSets,
                onChanged: (val) {
                  setState(() {
                    detail.targetSets = val;
                  });
                  _updateExerciseTargets(detail.crossRefId, detail.targetSets, detail.targetReps, detail.targetWeight);
                },
              ),
              // Reps
              _buildTargetEditor(
                label: 'تکرار',
                value: detail.targetReps,
                repsHint: detail.exercise.repsHint,
                onChanged: (val) {
                  setState(() {
                    detail.targetReps = val;
                  });
                  _updateExerciseTargets(detail.crossRefId, detail.targetSets, detail.targetReps, detail.targetWeight);
                },
              ),
              // Weight
              _buildWeightEditor(
                label: 'وزنه (kg)',
                value: detail.targetWeight,
                onChanged: (val) {
                  setState(() {
                    detail.targetWeight = val;
                  });
                  _updateExerciseTargets(detail.crossRefId, detail.targetSets, detail.targetReps, detail.targetWeight);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetEditor({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    String? repsHint,
  }) {
    var labelText = label;
    if (repsHint == 'reps_count_change_sides') {
      labelText = '$label (هر سمت)';
    }
    return Column(
      children: [
        Text(
          labelText,
          style: SupplementarySportsTheme.caption.copyWith(
            color: SupplementarySportsTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: SupplementarySportsTheme.spacing4),
        StepperInput(
          value: value,
          min: 1,
          max: 10,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildWeightEditor({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: SupplementarySportsTheme.caption.copyWith(
            color: SupplementarySportsTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: SupplementarySportsTheme.spacing4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 16),
              onPressed: value > 0 ? () => onChanged(value - 2.5) : null,
            ),
            Text(
              toPersianDigits(value.toStringAsFixed(1)),
              style: SupplementarySportsTheme.body.copyWith(
                fontWeight: FontWeight.bold,
                color: SupplementarySportsTheme.getTextPrimary(context),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => onChanged(value + 2.5),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Local View UI State Helper Models ---
class PlanExerciseDetail {

  PlanExerciseDetail({
    required this.crossRefId,
    required this.exercise,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
  });
  final String crossRefId;
  final SsExerciseModel exercise;
  int targetSets;
  int targetReps;
  double targetWeight;
}

class SSInlineAiSuggestion {

  SSInlineAiSuggestion({
    required this.id,
    required this.message,
    required this.crossRefId,
    required this.newWeight,
  });
  final String id;
  final String message;
  final String crossRefId;
  final double newWeight;
}
