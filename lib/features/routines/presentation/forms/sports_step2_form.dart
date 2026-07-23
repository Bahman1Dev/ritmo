// lib/features/routines/presentation/forms/sports_step2_form.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_day_of_week_selector.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_duration_picker.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_timeline_picker.dart';

class SportsStep2Form extends StatelessWidget {
  const SportsStep2Form({super.key, required this.controller});
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
            'نوع عملیات ورزشی',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOpChip('ROUTINE', 'برنامه‌ریزی روتین (تکرارشونده)', Icons.calendar_month_rounded),
              const SizedBox(width: 8),
              _buildOpChip('LOG', 'ثبت فوری فعالیت (لاگ تمرین)', Icons.history_rounded),
            ],
          ),
          const SizedBox(height: 20),

          if (controller.sportsOpType == 'LOG') ...[
            const Text(
              'نوع تمرین',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip('STRENGTH', '🏋️ بدنسازی/قدرتی'),
                _buildTypeChip('RUNNING', '🏃 دویدن'),
                _buildTypeChip('WALKING', '🚶 پیاده‌روی'),
                _buildTypeChip('YOGA', '🧘 یوگا'),
                _buildTypeChip('CYCLING', '🚴 دوچرخه‌سوار'),
                _buildTypeChip('SWIMMING', '🏊 شنا'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'مدت تمرین: ${controller.sportsDuration} دقیقه',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
            ),
            Slider(
              value: controller.sportsDuration.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              activeColor: colors.primary,
              onChanged: (val) {
                controller.sportsDuration = val.toInt();
                controller.notifyListeners();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'شدت تمرین',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildIntensityChip('LIGHT', 'سبک'),
                const SizedBox(width: 8),
                _buildIntensityChip('MEDIUM', 'متوسط'),
                const SizedBox(width: 8),
                _buildIntensityChip('HIGH', 'شدید'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'مکان تمرین',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLocationChip('GYM', '🏟️ باشگاه'),
                const SizedBox(width: 8),
                _buildLocationChip('HOME', '🏠 خانه'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'حس و حال شما',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFeelingChip('خوب', '😊 خوب'),
                const SizedBox(width: 8),
                _buildFeelingChip('عالی', '🤩 عالی'),
                const SizedBox(width: 8),
                _buildFeelingChip('خسته', '😫 خسته'),
              ],
            ),
          ] else ...[
            PlannerTimelinePicker(controller: controller),
            const SizedBox(height: 20),
            PlannerDurationPicker(controller: controller),
            const SizedBox(height: 16),
            const Text(
              'روزهای تمرین',
              style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            PlannerDayOfWeekSelector(
              selectedDays: controller.worshipSelectedDays,
              onChanged: (list) {
                controller.worshipSelectedDays = list;
                controller.notifyListeners();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpChip(String opType, String label, IconData icon) {
    final sel = controller.sportsOpType == opType;
    return ChoiceChip(
      avatar: Icon(icon, color: sel ? Colors.white : const Color(0xff10B981), size: 16),
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      selected: sel,
      selectedColor: const Color(0xff10B981),
      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
      onSelected: (val) {
        if (val) {
          controller.sportsOpType = opType;
          if (opType == 'LOG') {
            controller.title = 'فعالیت ورزشی';
          }
          controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final sel = controller.sportsType == type;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      selected: sel,
      selectedColor: const Color(0xff10B981),
      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
      onSelected: (val) {
        if (val) {
          controller.sportsType = type;
          controller.title = label.substring(2);
          controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildIntensityChip(String intensity, String label) {
    final sel = controller.sportsIntensity == intensity;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      selected: sel,
      selectedColor: const Color(0xff10B981),
      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
      onSelected: (val) {
        if (val) {
          controller.sportsIntensity = intensity;
          controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildLocationChip(String loc, String label) {
    final sel = controller.sportsLocation == loc;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      selected: sel,
      selectedColor: const Color(0xff10B981),
      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
      onSelected: (val) {
        if (val) {
          controller.sportsLocation = loc;
          controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildFeelingChip(String feel, String label) {
    final sel = controller.sportsFeeling == feel;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
      selected: sel,
      selectedColor: const Color(0xff10B981),
      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
      onSelected: (val) {
        if (val) {
          controller.sportsFeeling = feel;
          controller.notifyListeners();
        }
      },
    );
  }
}
