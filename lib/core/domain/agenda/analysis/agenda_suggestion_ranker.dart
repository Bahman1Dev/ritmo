import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_overload_detector.dart';
import 'package:ritmo/core/domain/agenda/sleep_window_resolver.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';

class AgendaSuggestion {
  const AgendaSuggestion({
    required this.id,
    required this.message,
    required this.priorityScore,
    this.suggestedTimeOfDay,
    this.targetItemId,
    this.categoryTag = 'general',
    this.explanationReason = '',
    this.isActionable = true,
  });

  final String id;
  final String message;
  final double priorityScore;
  final String? suggestedTimeOfDay;
  final String? targetItemId;
  final String categoryTag;
  final String explanationReason;
  final bool isActionable;
}

class AgendaSuggestionRanker {
  const AgendaSuggestionRanker({
    this.overloadDetector = const AgendaOverloadDetector(),
  });

  final AgendaOverloadDetector overloadDetector;

  List<AgendaSuggestion> generateSuggestions({
    required List<AgendaItem> items,
    required List<AgendaConflict> conflicts,
    required List<TimeGap> freeGaps,
    required double overloadScore,
    DateTime? now,
    SleepWindowBlock? sleepWindow,
  }) {
    final rawSuggestions = <AgendaSuggestion>[];

    // 1. Overload Warning Signal
    if (overloadScore >= 0.85) {
      final percent = (overloadScore * 100).round();
      rawSuggestions.add(AgendaSuggestion(
        id: 'overload_warning',
        message: 'برنامه امروز پر شده است ($percent٪ ظرفیت). پیشنهاد می‌شود موارد اختیاری به روز بعد منتقل شوند.',
        priorityScore: 0.82,
        categoryTag: 'overloadWarning',
        explanationReason: 'تکمیل ظرفیت زمانی روز',
        isActionable: false,
      ));
    }

    // 2. Conflict Resolution Signals
    for (final conflict in conflicts) {
      // Find candidate movable item
      final movableA = DirectManipulationEligibility.isDraggable(conflict.itemA);
      final movableB = DirectManipulationEligibility.isDraggable(conflict.itemB);

      if (!movableA && !movableB) {
        // Hard fixed conflict -> Warning only, do not propose invalid move
        rawSuggestions.add(AgendaSuggestion(
          id: 'hard_conflict_${conflict.itemA.id}_${conflict.itemB.id}',
          message: 'تداخل دو برنامه ثابت "${conflict.itemA.title}" و "${conflict.itemB.title}" در ساعت ${conflict.itemA.timeOfDay}.',
          priorityScore: 0.75,
          categoryTag: 'conflictWarning',
          explanationReason: 'برنامه‌های ثابت امکان جابه‌جایی مستقیم ندارند',
          isActionable: false,
        ));
        continue;
      }

      final movableItem = movableA ? conflict.itemA : conflict.itemB;
      final itemDuration = movableItem.durationMinutes ?? 30;

      // Find best quality free gap that fits duration and is not in sleep window
      TimeGap? bestGap;
      for (final gap in freeGaps) {
        if (!gap.isUsable || gap.durationMinutes < itemDuration) continue;
        if (sleepWindow != null && gap.startMinutes >= sleepWindow.startMinutes && gap.startMinutes < sleepWindow.endMinutes) {
          continue; // Avoid sleep window
        }
        if (overloadDetector.isSlotOverloaded(gap.startMinutes, itemDuration, items)) {
          continue; // Avoid overloaded hours
        }
        if (bestGap == null || gap.qualityScore > bestGap.qualityScore) {
          bestGap = gap;
        }
      }

      if (bestGap != null) {
        final score = 0.88 + (bestGap.qualityScore * 0.10);
        rawSuggestions.add(AgendaSuggestion(
          id: 'resolve_conflict_${conflict.itemA.id}_${conflict.itemB.id}',
          message: 'انتقال "${movableItem.title}" به زمان خالی در ساعت ${bestGap.startTimeStr}.',
          priorityScore: score.clamp(0.0, 1.0),
          suggestedTimeOfDay: bestGap.startTimeStr,
          targetItemId: movableItem.id,
          categoryTag: 'conflictResolution',
          explanationReason: 'رفع تداخل با انتقال به بازه مناسب',
          isActionable: true,
        ));
      }
    }

    // 3. Untimed Task Scheduling Signals
    final untimedPending = items
        .where((i) => !i.isTimed && !i.isCompleted && DirectManipulationEligibility.isDraggable(i))
        .toList();

    if (untimedPending.isNotEmpty) {
      for (final item in untimedPending) {
        final itemDuration = item.durationMinutes ?? 30;
        final targetGap = freeGaps.firstWhere(
          (g) => g.isUsable && g.durationMinutes >= itemDuration && g.qualityScore >= 0.45,
          orElse: () => const TimeGap(startMinutes: -1, endMinutes: -1),
        );

        if (targetGap.startMinutes >= 0) {
          rawSuggestions.add(AgendaSuggestion(
            id: 'schedule_untimed_${item.id}',
            message: 'زمان‌بندی "${item.title}" در بازه خالی ساعت ${targetGap.startTimeStr}.',
            priorityScore: 0.62 + (targetGap.qualityScore * 0.10),
            suggestedTimeOfDay: targetGap.startTimeStr,
            targetItemId: item.id,
            categoryTag: 'untimedSchedule',
            explanationReason: 'استفاده بهینه از زمان‌های خالی روز',
            isActionable: true,
          ));
        }
      }
    }

    // 4. Noise Reduction & Deduplication Thresholding
    final filtered = <AgendaSuggestion>[];
    final seenTargetIds = <String>{};

    // Sort by priority score descending
    rawSuggestions.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    for (final sug in rawSuggestions) {
      if (sug.priorityScore < 0.45) continue; // Suppress weak low-confidence suggestions
      if (sug.targetItemId != null && seenTargetIds.contains(sug.targetItemId)) {
        continue; // Deduplicate multiple suggestions for same item
      }
      if (sug.targetItemId != null) {
        seenTargetIds.add(sug.targetItemId!);
      }
      filtered.add(sug);
      if (filtered.length >= 3) break; // Limit top 3 actionable suggestions max
    }

    return filtered;
  }
}
