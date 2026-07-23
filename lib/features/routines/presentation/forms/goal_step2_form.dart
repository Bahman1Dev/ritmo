// lib/features/routines/presentation/forms/goal_step2_form.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class GoalStep2Form extends StatefulWidget {
  const GoalStep2Form({super.key, required this.controller});
  final PlannerController controller;

  @override
  State<GoalStep2Form> createState() => _GoalStep2FormState();
}

class _GoalStep2FormState extends State<GoalStep2Form> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'بازه زمانی هدف (SMART)',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('DAILY', 'روزانه'),
              const SizedBox(width: 8),
              _buildTypeChip('WEEKLY', 'هفتگی'),
              const SizedBox(width: 8),
              _buildTypeChip('LONG_TERM', 'بلندمدت'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تاریخ اتمام هدف',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton(
                onPressed: () async {
                  final date = await RitmoDatePicker.show(
                    context: context,
                    initialDate: controller.goalTargetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    controller.goalTargetDate = date;
                    controller.notifyListeners();
                  }
                },
                child: Text(
                  '${controller.goalTargetDate.year}/${controller.goalTargetDate.month}/${controller.goalTargetDate.day}',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تعریف مراحل (Steps)',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                onPressed: () {
                  controller.goalSteps.add('');
                  controller.notifyListeners();
                },
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.deepOrange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.goalSteps.length,
            itemBuilder: (context, idx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'گام ${idx + 1}',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        controller: TextEditingController(text: controller.goalSteps[idx])
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.goalSteps[idx].length),
                          ),
                        onChanged: (val) {
                          controller.goalSteps[idx] = val;
                        },
                      ),
                    ),
                    if (controller.goalSteps.length > 1)
                      IconButton(
                        onPressed: () {
                          controller.goalSteps.removeAt(idx);
                          controller.notifyListeners();
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final controller = widget.controller;
    final sel = controller.goalType == type;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      selected: sel,
      selectedColor: Colors.deepOrange,
      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
      onSelected: (val) {
        if (val) {
          controller.goalType = type;
          controller.notifyListeners();
        }
      },
    );
  }
}
