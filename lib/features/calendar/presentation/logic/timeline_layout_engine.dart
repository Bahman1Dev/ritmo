// lib/features/calendar/presentation/logic/timeline_layout_engine.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';

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

  double get leftFraction => totalLanes > 0 ? laneIndex / totalLanes : 0.0;
  double get widthFraction => totalLanes > 0 ? 1.0 / totalLanes : 1.0;
}

class TimelineLayoutEngine {
  const TimelineLayoutEngine({
    this.pxPerMinute = 1.2,
    this.minItemHeight = 28.0,
    this.defaultDurationMinutes = 30,
  });

  final double pxPerMinute;
  final double minItemHeight;
  final int defaultDurationMinutes;

  double get totalTimelineHeight => 1440 * pxPerMinute;

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

      final renderDurM = durM.clamp(DurationBounds.minMinutes, DurationBounds.maxRenderMinutes);
      final isTruncated = renderDurM < durM;

      rawEntries.add(_RawEntry(
        item: item,
        startMinutes: startM,
        durationMinutes: durM,
        renderDurationMinutes: renderDurM,
        isTruncated: isTruncated,
        endMinutes: startM + durM,
      ));
    }

    rawEntries.sort((a, b) {
      final cmp = a.startMinutes.compareTo(b.startMinutes);
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
            entry.startMinutes < other.endMinutes && entry.endMinutes > other.startMinutes);
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

    // Compute layout items
    final result = <TimelineLayoutItem>[];
    for (final entry in rawEntries) {
      final overlappingEntries = rawEntries.where((other) =>
          entry.startMinutes < other.endMinutes && entry.endMinutes > other.startMinutes).toList();

      final maxLaneInGroup = overlappingEntries.fold<int>(
        entry.laneIndex,
        (maxIdx, other) => max(maxIdx, other.laneIndex),
      );
      final totalLanes = maxLaneInGroup + 1;

      final top = entry.startMinutes * pxPerMinute;
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
      ));
    }

    // Global guard check
    for (var i = 0; i < lanes.length; i++) {
      final laneTotalHeight = lanes[i].fold<double>(0.0, (sum, e) => sum + (e.renderDurationMinutes * pxPerMinute));
      if (laneTotalHeight > totalTimelineHeight) {
        debugPrint('[TimelineLayoutEngine] WARNING: Lane $i total height (${laneTotalHeight}px) exceeds timeline height (${totalTimelineHeight}px)!');
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
    required this.isTruncated,
    required this.endMinutes,
  });

  final AgendaItem item;
  final int startMinutes;
  final int durationMinutes;
  final int renderDurationMinutes;
  final bool isTruncated;
  final int endMinutes;
  int laneIndex = 0;
}
