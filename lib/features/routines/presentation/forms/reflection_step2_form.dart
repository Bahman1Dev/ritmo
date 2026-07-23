// lib/features/routines/presentation/forms/reflection_step2_form.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class ReflectionStep2Form extends StatelessWidget {
  const ReflectionStep2Form({super.key, required this.controller});
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
            'حس و حال امروز شما',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final score = index + 1;
              final isSelected = controller.reflectionMood == score;
              final emojis = ['😫', '☹️', '😐', '🙂', '🤩'];
              return GestureDetector(
                onTap: () {
                  controller.reflectionMood = score;
                  controller.notifyListeners();
                },
                child: Text(
                  emojis[index],
                  style: TextStyle(
                    fontSize: isSelected ? 40 : 28,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text(
            'موفقیت‌های امروز',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'امروز چه موفقیت‌هایی داشتید؟',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              controller.reflectionWins = val;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'شکرگزاری امروز',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'امروز بابت چه چیزی شکرگزار هستید؟',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              controller.reflectionGratitude = val;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'آموخته‌های امروز',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'امروز چه چیز جدیدی یاد گرفتید؟',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              controller.reflectionLearnings = val;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'یادداشت محرمانه باشد؟',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Switch(
                value: controller.reflectionIsPrivate,
                activeThumbColor: colors.primary,
                onChanged: (val) {
                  controller.reflectionIsPrivate = val;
                  controller.notifyListeners();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
