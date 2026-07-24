import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

class KonkurExamAction {
  const KonkurExamAction({
    required this.type,
    required this.subjectName,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String type; // 'RESCUE', 'UNSTABLE', 'STRENGTH', 'DECLINING'
  final String subjectName;
  final String description;
  final String icon;
  final Color color;
}

class KonkurExamActions {
  static List<KonkurExamAction> generateActions({
    required List<KonkurSubject> subjects,
    required List<KonkurMockResult> results,
    required Map<String, List<double>> perSubjectTrend,
  }) {
    if (results.isEmpty || subjects.isEmpty) return [];

    final actions = <KonkurExamAction>[];
    final subjectMap = {for (final s in subjects) s.id: s};

    // 1. RESCUE — weakest subject in current results
    results.sort((a, b) => a.percentage.compareTo(b.percentage));
    final weakestResult = results.first;
    final weakestSub = subjectMap[weakestResult.subjectId];
    if (weakestSub != null) {
      if (weakestResult.percentage < 30) {
        actions.add(KonkurExamAction(
          type: 'RESCUE',
          subjectName: weakestSub.name,
          description: 'یه جلسه مطالعه مفهومی فوری برای ${weakestSub.name} بذار — درصدت خیلی پایینه',
          icon: '🚨',
          color: Colors.red,
        ));
      } else if (weakestResult.percentage < 50) {
        actions.add(KonkurExamAction(
          type: 'RESCUE',
          subjectName: weakestSub.name,
          description: 'درس ${weakestSub.name} نیاز به تقویت داره — چند تست تمرینی بزن',
          icon: '⚠️',
          color: Colors.amber.shade800,
        ));
      }
    }

    // 2. UNSTABLE — most volatile subject
    String? mostVolatileSubjectId;
    double maxVariance = -1;

    for (final entry in perSubjectTrend.entries) {
      final trend = entry.value;
      if (trend.length < 2) continue;

      final mean = trend.reduce((a, b) => a + b) / trend.length;
      final variance = trend.fold<double>(0.0, (acc, val) => acc + pow(val - mean, 2)) / trend.length;

      if (variance > 100 && variance > maxVariance) {
        maxVariance = variance;
        mostVolatileSubjectId = entry.key;
      }
    }

    if (mostVolatileSubjectId != null) {
      final sub = subjectMap[mostVolatileSubjectId];
      if (sub != null) {
        actions.add(KonkurExamAction(
          type: 'UNSTABLE',
          subjectName: sub.name,
          description: 'درس ${sub.name} ناپایداره — مفهوم پایه رو مرور کن',
          icon: '📉',
          color: Colors.orange,
        ));
      }
    }

    // 3. STRENGTH — highest percentage subject
    results.sort((a, b) => b.percentage.compareTo(a.percentage));
    final strongestResult = results.first;
    final strongestSub = subjectMap[strongestResult.subjectId];
    if (strongestSub != null && strongestResult.percentage >= 70) {
      actions.add(KonkurExamAction(
        type: 'STRENGTH',
        subjectName: strongestSub.name,
        description: 'درس ${strongestSub.name} قوئه — سطح تسلط مباحثش رو به مسلط ارتقا بده',
        icon: '🏆',
        color: const Color(0xFF10B981),
      ));
    }

    // 4. DECLINING — subject with negative trend (last < prev - 10)
    for (final entry in perSubjectTrend.entries) {
      final trend = entry.value;
      if (trend.length >= 2) {
        final last = trend.last;
        final prev = trend[trend.length - 2];
        if (last < prev - 10) {
          final sub = subjectMap[entry.key];
          if (sub != null) {
            actions.add(KonkurExamAction(
              type: 'DECLINING',
              subjectName: sub.name,
              description: 'درس ${sub.name} افت داشته — قبل از آزمون بعدی یه مرور کوتاه بذار',
              icon: '📊',
              color: Colors.blue,
            ));
            break; // Include max 1 declining action
          }
        }
      }
    }

    return actions;
  }
}
