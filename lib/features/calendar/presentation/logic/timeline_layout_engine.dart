import 'dart:math';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

class TimelineLayoutItem {
  const TimelineLayoutItem({
    required this.item,
    required this.top,
    required this.height,
    required this.laneIndex,
    required this.totalLanes,
    required this.startMinutes,
    required this.durationMinutes,
  });

  final AgendaItem item;
  final double top;
  final double height;
  final int laneIndex;
  final int totalLanes;
  final int startMinutes;
  final int durationMinutes;

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
      final startM = _parseStartMinutes(item.timeOfDay!);
      var durM = item.durationMinutes ?? defaultDurationMinutes;

      // Routines, habits, or items without explicit short duration constraints (>= 3 hours or <= 0)
      // visually render as a compact 30-minute card on the timeline grid.
      // Any large duration is capped at a maximum of 60 minutes (1 hour) to keep the timeline clean.
      if (durM <= 0 || durM >= 180) {
        durM = defaultDurationMinutes; // 30 mins
      } else if (durM > 60) {
        durM = 60; // Max 1 hour slot
      }

      rawEntries.add(_RawEntry(
        item: item,
        startMinutes: startM,
        durationMinutes: durM,
        endMinutes: startM + durM,
      ));
    }

    rawEntries.sort((a, b) {
      final cmp = a.startMinutes.compareTo(b.startMinutes);
      if (cmp != 0) return cmp;
      return b.durationMinutes.compareTo(a.durationMinutes);
    });

    final clusters = <List<_RawEntry>>[];
    for (final entry in rawEntries) {
      if (clusters.isEmpty) {
        clusters.add([entry]);
      } else {
        var added = false;
        for (final cluster in clusters) {
          final clusterMaxEnd = cluster.map((e) => e.endMinutes).reduce(max);
          if (entry.startMinutes < clusterMaxEnd) {
            cluster.add(entry);
            added = true;
            break;
          }
        }
        if (!added) {
          clusters.add([entry]);
        }
      }
    }

    final result = <TimelineLayoutItem>[];

    for (final cluster in clusters) {
      final lanes = <List<_RawEntry>>[];
      for (final entry in cluster) {
        var placed = false;
        for (var i = 0; i < lanes.length; i++) {
          final lane = lanes[i];
          final lastInLane = lane.last;
          if (entry.startMinutes >= lastInLane.endMinutes) {
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

      final totalLanes = lanes.length;

      for (final entry in cluster) {
        final top = entry.startMinutes * pxPerMinute;
        final rawHeight = entry.durationMinutes * pxPerMinute;
        final height = max(rawHeight, minItemHeight);

        result.add(TimelineLayoutItem(
          item: entry.item,
          top: top,
          height: height,
          laneIndex: entry.laneIndex,
          totalLanes: totalLanes,
          startMinutes: entry.startMinutes,
          durationMinutes: entry.durationMinutes,
        ));
      }
    }

    return result;
  }

  static int _parseStartMinutes(String timeOfDay) {
    final parts = timeOfDay.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60) + m;
  }
}

class _RawEntry {
  _RawEntry({
    required this.item,
    required this.startMinutes,
    required this.durationMinutes,
    required this.endMinutes,
  });

  final AgendaItem item;
  final int startMinutes;
  final int durationMinutes;
  final int endMinutes;
  int laneIndex = 0;
}
