// lib/features/calendar/presentation/logic/timeline_layout_engine.dart

import 'dart:math';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class TimelineLayoutItem {
  const TimelineLayoutItem({
    required this.item,
    required this.top,
    required this.height,
    required this.laneIndex,
    required this.totalLanes,
    required this.startMinutes,
    required this.durationMinutes,
    required this.renderDurationMinutes,
    required this.isTruncated,
    this.isClippedAtStart = false,
    this.isClippedAtEnd = false,
    this.continuesToNextDay = false,
    this.continuedFromPreviousDay = false,
    this.overflowCount = 0,
    this.overflowItems = const [],
  });

  final AgendaItem item;
  final double top;
  final double height;
  final int laneIndex;
  final int totalLanes;
  final int startMinutes;
  final int durationMinutes;
  final int renderDurationMinutes;
  final bool isTruncated;
  final bool isClippedAtStart;
  final bool isClippedAtEnd;
  final bool continuesToNextDay;
  final bool continuedFromPreviousDay;
  final int overflowCount;
  final List<AgendaItem> overflowItems;

  double get leftFraction => totalLanes > 0 ? laneIndex / totalLanes : 0.0;
  double get widthFraction => totalLanes > 0 ? 1.0 / totalLanes : 1.0;
}

class TimelineLayoutEngine {
  const TimelineLayoutEngine({
    this.pxPerMinute = CalendarTokens.pxPerMinute,
    this.minItemHeight = 28.0,
    this.defaultDurationMinutes = DurationBounds.defaultMinutes,
    this.rangeStartMinutes = 0,
    this.rangeEndMinutes = 1440,
    this.maxLanes,
  });

  final double pxPerMinute;
  final double minItemHeight;
  final int defaultDurationMinutes;
  final int rangeStartMinutes;
  final int rangeEndMinutes;
  final int? maxLanes;

  int get rangeDurationMinutes => rangeEndMinutes - rangeStartMinutes;
  double get totalTimelineHeight => rangeDurationMinutes * pxPerMinute;

  List<TimelineLayoutItem> calculateLayout(List<AgendaItem> items) {
    final timed = items.where((i) => i.isTimed).toList();
    if (timed.isEmpty) return [];

    final rawEntries = <_RawEntry>[];
    for (final item in timed) {
      final startM = _tryParseStartMinutes(item.timeOfDay);
      if (startM == null) continue;

      var durM = DurationBounds.sanitize(item.durationMinutes);
      final maxDurationForDay = (1440 - startM).clamp(1, 1440);
      durM = durM.clamp(DurationBounds.minMinutes, maxDurationForDay);
      final endM = startM + durM;

      // Filter: item must overlap range [rangeStartMinutes, rangeEndMinutes)
      if (startM >= rangeEndMinutes || endM <= rangeStartMinutes) {
        continue;
      }

      final visibleStart = max(startM, rangeStartMinutes);
      final visibleEnd = min(endM, rangeEndMinutes);
      final isClippedAtStart = startM < rangeStartMinutes;
      final isClippedAtEnd = endM > rangeEndMinutes;

      final renderDurM = (visibleEnd - visibleStart).clamp(DurationBounds.minMinutes, DurationBounds.maxRenderMinutes);
      final isTruncated = renderDurM < (visibleEnd - visibleStart);

      rawEntries.add(_RawEntry(
        item: item,
        startMinutes: startM,
        durationMinutes: durM,
        renderDurationMinutes: renderDurM,
        visibleStart: visibleStart,
        visibleEnd: visibleEnd,
        isClippedAtStart: isClippedAtStart,
        isClippedAtEnd: isClippedAtEnd,
        isTruncated: isTruncated,
        endMinutes: endM,
      ));
    }

    if (rawEntries.isEmpty) return [];

    rawEntries.sort((a, b) {
      final cmp = a.visibleStart.compareTo(b.visibleStart);
      if (cmp != 0) return cmp;
      return b.durationMinutes.compareTo(a.durationMinutes);
    });

    // Assign lanes
    final lanes = <List<_RawEntry>>[];
    for (final entry in rawEntries) {
      var placed = false;
      for (var i = 0; i < lanes.length; i++) {
        final lane = lanes[i];
        final hasOverlap = lane.any((other) =>
            entry.visibleStart < other.visibleEnd && entry.visibleEnd > other.visibleStart);
        if (!hasOverlap) {
          lane.add(entry);
          entry.laneIndex = i;
          placed = true;
          break;
        }
      }
      if (!placed) {
        lanes.add([entry]);
        entry.laneIndex = lanes.length - 1;
      }
    }

    final result = <TimelineLayoutItem>[];
    final processedOverflowEntries = <_RawEntry>{};

    for (final entry in rawEntries) {
      if (processedOverflowEntries.contains(entry)) continue;

      final overlappingEntries = rawEntries.where((other) =>
          entry.visibleStart < other.visibleEnd && entry.visibleEnd > other.visibleStart).toList();

      final maxLaneInGroup = overlappingEntries.fold<int>(
        entry.laneIndex,
        (maxIdx, other) => max(maxIdx, other.laneIndex),
      );
      var totalLanes = maxLaneInGroup + 1;

      // Handle maxLanes capping if set
      if (maxLanes != null && totalLanes > maxLanes!) {
        totalLanes = maxLanes!;

        // Sort overlapping entries by essential/priority
        overlappingEntries.sort((a, b) {
          if (a.item.isEssential != b.item.isEssential) {
            return a.item.isEssential ? -1 : 1;
          }
          if (a.item.priority != b.item.priority) {
            return b.item.priority.compareTo(a.item.priority);
          }
          return a.visibleStart.compareTo(b.visibleStart);
        });

        final primaryCount = maxLanes! - 1;
        final primaryEntries = overlappingEntries.take(primaryCount).toList();
        final overflowEntries = overlappingEntries.skip(primaryCount).toList();

        if (primaryEntries.contains(entry)) {
          final laneIdx = primaryEntries.indexOf(entry);
          final top = (entry.visibleStart - rangeStartMinutes) * pxPerMinute;
          final rawHeight = entry.renderDurationMinutes * pxPerMinute;
          final maxHeight = totalTimelineHeight - top;
          final height = max(rawHeight, minItemHeight).clamp(minItemHeight, maxHeight);

          result.add(TimelineLayoutItem(
            item: entry.item,
            top: top,
            height: height,
            laneIndex: laneIdx,
            totalLanes: totalLanes,
            startMinutes: entry.startMinutes,
            durationMinutes: entry.durationMinutes,
            renderDurationMinutes: entry.renderDurationMinutes,
            isTruncated: entry.isTruncated,
            isClippedAtStart: entry.isClippedAtStart,
            isClippedAtEnd: entry.isClippedAtEnd,
          ));
        } else {
          // Entry is in the overflow group. Create overflow item once for the group.
          if (!overflowEntries.every((e) => processedOverflowEntries.contains(e))) {
            for (final overflowEntry in overflowEntries) {
              processedOverflowEntries.add(overflowEntry);
            }

            final overflowItemsList = overflowEntries.map((e) => e.item).toList();
            final minStart = overflowEntries.map((e) => e.visibleStart).reduce(min);
            final maxEnd = overflowEntries.map((e) => e.visibleEnd).reduce(max);

            final top = (minStart - rangeStartMinutes) * pxPerMinute;
            final rawHeight = (maxEnd - minStart) * pxPerMinute;
            final maxHeight = totalTimelineHeight - top;
            final height = max(rawHeight, minItemHeight).clamp(minItemHeight, maxHeight);

            result.add(TimelineLayoutItem(
              item: overflowEntries.first.item,
              top: top,
              height: height,
              laneIndex: maxLanes! - 1,
              totalLanes: totalLanes,
              startMinutes: minStart,
              durationMinutes: maxEnd - minStart,
              renderDurationMinutes: maxEnd - minStart,
              isTruncated: false,
              overflowCount: overflowEntries.length,
              overflowItems: overflowItemsList,
            ));
          }
        }
      } else {
        // Normal rendering when totalLanes <= maxLanes (or maxLanes == null)
        final top = (entry.visibleStart - rangeStartMinutes) * pxPerMinute;
        final rawHeight = entry.renderDurationMinutes * pxPerMinute;
        final maxHeight = totalTimelineHeight - top;
        final height = max(rawHeight, minItemHeight).clamp(minItemHeight, maxHeight);

        result.add(TimelineLayoutItem(
          item: entry.item,
          top: top,
          height: height,
          laneIndex: entry.laneIndex,
          totalLanes: totalLanes,
          startMinutes: entry.startMinutes,
          durationMinutes: entry.durationMinutes,
          renderDurationMinutes: entry.renderDurationMinutes,
          isTruncated: entry.isTruncated,
          isClippedAtStart: entry.isClippedAtStart,
          isClippedAtEnd: entry.isClippedAtEnd,
        ));
      }
    }

    return result;
  }

  static int? _tryParseStartMinutes(String? timeOfDay) {
    if (timeOfDay == null) return null;

    final value = timeOfDay.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;

    final h = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (h == null || m == null) return null;
    if (h < 0 || h >= 24 || m < 0 || m >= 60) return null;

    return (h * 60) + m;
  }
}

class _RawEntry {
  _RawEntry({
    required this.item,
    required this.startMinutes,
    required this.durationMinutes,
    required this.renderDurationMinutes,
    required this.visibleStart,
    required this.visibleEnd,
    required this.isClippedAtStart,
    required this.isClippedAtEnd,
    required this.isTruncated,
    required this.endMinutes,
  });

  final AgendaItem item;
  final int startMinutes;
  final int durationMinutes;
  final int renderDurationMinutes;
  final int visibleStart;
  final int visibleEnd;
  final bool isClippedAtStart;
  final bool isClippedAtEnd;
  final bool isTruncated;
  final int endMinutes;
  int laneIndex = 0;
}
