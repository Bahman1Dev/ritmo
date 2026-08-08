import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/simple_tasks/data/task_step_repository.dart';
import 'package:ritmo/features/simple_tasks/domain/task_step.dart';

class TaskStepList extends StatefulWidget {
  const TaskStepList({
    super.key,
    required this.taskId,
    required this.steps,
    required this.onStepsChanged,
  });

  final String taskId;
  final List<TaskStep> steps;
  final VoidCallback onStepsChanged;

  @override
  State<TaskStepList> createState() => _TaskStepListState();
}

class _TaskStepListState extends State<TaskStepList> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addStep() async {
    final title = _addController.text.trim();
    if (title.isEmpty) return;

    await TaskStepRepository.instance.add(
      taskId: widget.taskId,
      title: title,
    );
    _addController.clear();
    widget.onStepsChanged();

    // Retain focus so user can type multiple sub-steps sequentially
    _addFocusNode.requestFocus();
  }

  Future<void> _toggleStep(TaskStep step) async {
    RitmoHaptics.tap();
    await TaskStepRepository.instance.setCompleted(
      step.id,
      completed: !step.isCompleted,
    );
    widget.onStepsChanged();
  }

  Future<void> _deleteStep(String stepId) async {
    await TaskStepRepository.instance.delete(stepId);
    widget.onStepsChanged();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final list = List<TaskStep>.from(widget.steps);
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);

    final orderedIds = list.map((e) => e.id).toList();
    await TaskStepRepository.instance.reorder(widget.taskId, orderedIds);
    widget.onStepsChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.steps.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.steps.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final step = widget.steps[index];
              return Container(
                key: ValueKey(step.id),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: IconButton(
                    icon: Icon(
                      step.isCompleted
                          ? CupertinoIcons.checkmark_square_fill
                          : CupertinoIcons.square,
                      color: step.isCompleted ? colors.success : colors.textTertiary,
                      size: 20,
                    ),
                    onPressed: () => _toggleStep(step),
                  ),
                  title: Text(
                    step.title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      color: step.isCompleted ? colors.textTertiary : colors.textPrimary,
                      decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textTertiary, size: 16),
                    onPressed: () => _deleteStep(step.id),
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 6),

        // Add sub-step field
        TextField(
          controller: _addController,
          focusNode: _addFocusNode,
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12.5, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: '+ افزودن زیرگام تازه...',
            hintStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textTertiary),
            filled: true,
            fillColor: colors.surfaceSunken,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _addStep(),
        ),
      ],
    );
  }
}
