// lib/features/registry/domain/delete_impact_report.dart

import 'package:ritmo/core/utils/persian_digits.dart';

class DeleteImpactReport {
  const DeleteImpactReport({
    required this.completionCount,
    required this.occurrenceCount,
    required this.activeReminderCount,
    required this.longestStreakDays,
    this.orphanedDependents = const [],
    this.isIrreversible = true,
  });

  final int completionCount;
  final int occurrenceCount;
  final int activeReminderCount;
  final int longestStreakDays;
  final List<String> orphanedDependents;
  final bool isIrreversible;

  String toFaSentence() {
    final parts = <String>[];
    if (completionCount > 0) {
      parts.add('${toPersianDigits(completionCount.toString())} ثبت انجام');
    }
    if (longestStreakDays > 0) {
      parts.add('زنجیرهٔ ${toPersianDigits(longestStreakDays.toString())} روزه');
    }
    if (activeReminderCount > 0) {
      parts.add('${toPersianDigits(activeReminderCount.toString())} یادآور فعال');
    }
    if (orphanedDependents.isNotEmpty) {
      parts.add('${toPersianDigits(orphanedDependents.length.toString())} مورد وابسته بی‌سرپرست می‌شود');
    }
    if (parts.isEmpty) {
      return 'هیچ سابقهٔ انجام یا یادآور فعالی ندارد.';
    }
    return parts.join(' · ');
  }
}
