// lib/features/routines/presentation/forms/course_step2_form.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_day_of_week_selector.dart';

class CourseStep2Form extends StatelessWidget {
  const CourseStep2Form({super.key, required this.controller});
  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'نوع منبع آموزشی',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip('VIDEO', '🎥 ویدیو / کلاس'),
              _buildTypeChip('BOOK', '📖 کتاب / متن'),
              _buildTypeChip('SKILL', '🎯 تمرین عملی'),
              _buildTypeChip('CUSTOM', '📚 سایر منابع'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'تعداد کل جلسات / فصول: ${controller.courseTotalSessions}',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          Slider(
            value: controller.courseTotalSessions.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: colors.primary,
            onChanged: (val) {
              controller.courseTotalSessions = val.toInt();
              controller.notifyListeners();
            },
          ),
          const SizedBox(height: 8),
          Text(
            'هدف هفتگی (تعداد جلسات در هفته): ${controller.courseWeeklyTarget}',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          Slider(
            value: controller.courseWeeklyTarget.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            activeColor: colors.primary,
            onChanged: (val) {
              controller.courseWeeklyTarget = val.toInt();
              controller.notifyListeners();
            },
          ),
          const SizedBox(height: 8),
          Text(
            'مدت زمان تقریبی هر جلسه: ${controller.courseSessionDuration} دقیقه',
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          Slider(
            value: controller.courseSessionDuration.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            activeColor: colors.primary,
            onChanged: (val) {
              controller.courseSessionDuration = val.toInt();
              controller.notifyListeners();
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'زمان ترجیحی مطالعه',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: controller.coursePreferredTime,
                  );
                  if (time != null) {
                    controller.coursePreferredTime = time;
                    controller.notifyListeners();
                  }
                },
                child: Text(
                  '${controller.coursePreferredTime.hour.toString().padLeft(2, '0')}:${controller.coursePreferredTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'روزهای ترجیحی برای مطالعه',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          PlannerDayOfWeekSelector(
            selectedDays: controller.coursePreferredDays,
            onChanged: (list) {
              controller.coursePreferredDays = list;
              controller.notifyListeners();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final sel = controller.courseType == type;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      selected: sel,
      selectedColor: const Color(0xff6366F1),
      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
      onSelected: (val) {
        if (val) {
          controller.courseType = type;
          controller.notifyListeners();
        }
      },
    );
  }
}
