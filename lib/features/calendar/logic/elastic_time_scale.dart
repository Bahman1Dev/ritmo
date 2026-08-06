import 'dart:math';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class ElasticBand {
  const ElasticBand({
    required this.startMinutes,
    required this.endMinutes,
    required this.isFolded,
    required this.pixelHeight,
    required this.startPixel,
  });

  final int startMinutes;
  final int endMinutes;
  final bool isFolded;
  final double pixelHeight;
  final double startPixel;

  int get durationMinutes => endMinutes - startMinutes;
  double get endPixel => startPixel + pixelHeight;
}

class ElasticTimeScale {
  ElasticTimeScale({
    required this.bands,
    required this.totalHeight,
    required this.isElastic,
  });

  final List<ElasticBand> bands;
  final double totalHeight;
  final bool isElastic;

  static ElasticTimeScale build({
    required List<AgendaItem> items,
    int? sleepStartMinutes,
    int? sleepEndMinutes,
    Set<int> expandedBandIndices = const {},
  }) {
    final timedItems = items.where((i) => i.isTimed).toList();

    if (timedItems.isEmpty && sleepStartMinutes == null) {
      const defaultPxPerMin = CalendarTokens.pxPerMinute;
      const totalH = 1440 * defaultPxPerMin;
      return ElasticTimeScale(
        bands: const [
          ElasticBand(
            startMinutes: 0,
            endMinutes: 1440,
            isFolded: false,
            pixelHeight: totalH,
            startPixel: 0,
          ),
        ],
        totalHeight: totalH,
        isElastic: false,
      );
    }

    final occupied = <({int start, int end})>[];
    for (final item in timedItems) {
      final parts = item.timeOfDay!.split(':');
      final s = (int.parse(parts[0]) * 60) + int.parse(parts[1]);
      final dur = item.durationMinutes ?? 30;
      occupied.add((start: s, end: min(s + dur, 1440)));
    }

    occupied.sort((a, b) => a.start.compareTo(b.start));
    final mergedOccupied = <({int start, int end})>[];

    for (final b in occupied) {
      if (mergedOccupied.isEmpty) {
        mergedOccupied.add(b);
      } else {
        final last = mergedOccupied.last;
        if (b.start <= last.end) {
          mergedOccupied[mergedOccupied.length - 1] = (
            start: last.start,
            end: max(last.end, b.end),
          );
        } else {
          mergedOccupied.add(b);
        }
      }
    }

    final expandedOccupied = <({int start, int end})>[];
    for (final b in mergedOccupied) {
      final s = max(0, b.start - 20);
      final e = min(1440, b.end + 20);
      if (expandedOccupied.isEmpty) {
        expandedOccupied.add((start: s, end: e));
      } else {
        final last = expandedOccupied.last;
        if (s <= last.end) {
          expandedOccupied[expandedOccupied.length - 1] = (
            start: last.start,
            end: max(last.end, e),
          );
        } else {
          expandedOccupied.add((start: s, end: e));
        }
      }
    }

    final rawBands = <({int start, int end, bool isFolded})>[];
    var currentCursor = 0;

    for (final occ in expandedOccupied) {
      if (occ.start > currentCursor) {
        final gapMins = occ.start - currentCursor;
        if (gapMins >= 45) {
          rawBands.add((start: currentCursor, end: occ.start, isFolded: true));
        } else {
          rawBands.add((start: currentCursor, end: occ.start, isFolded: false));
        }
      }
      rawBands.add((start: occ.start, end: occ.end, isFolded: false));
      currentCursor = occ.end;
    }

    if (currentCursor < 1440) {
      final gapMins = 1440 - currentCursor;
      if (gapMins >= 45) {
        rawBands.add((start: currentCursor, end: 1440, isFolded: true));
      } else {
        rawBands.add((start: currentCursor, end: 1440, isFolded: false));
      }
    }

    final finalBands = <ElasticBand>[];
    var currentY = 0.0;
    const pxPerMinExpanded = 2.2;
    const pxPerMinNormal = CalendarTokens.pxPerMinute;
    const foldedHeight = 28.0;

    for (var i = 0; i < rawBands.length; i++) {
      final raw = rawBands[i];
      final isManuallyExpanded = expandedBandIndices.contains(i);
      final isFolded = raw.isFolded && !isManuallyExpanded;

      double height;
      if (isFolded) {
        height = foldedHeight;
      } else if (raw.isFolded && isManuallyExpanded) {
        height = (raw.end - raw.start) * pxPerMinNormal;
      } else {
        height = (raw.end - raw.start) * pxPerMinExpanded;
      }

      finalBand.add(ElasticBand(
        startMinutes: raw.start,
        endMinutes: raw.end,
        isFolded: isFolded,
        pixelHeight: height,
        startPixel: currentY,
      ));

      currentY += height;
    }

    return ElasticTimeScale(
      bands: finalBands,
      totalHeight: currentY,
      isElastic: true,
    );
  }

  double minutesToPixels(int minutes) {
    final clampedM = minutes.clamp(0, 1440);
    for (final band in bands) {
      if (clampedM >= band.startMinutes && clampedM <= band.endMinutes) {
        if (band.isFolded || band.durationMinutes == 0) {
          final frac = band.durationMinutes > 0
              ? (clampedM - band.startMinutes) / band.durationMinutes
              : 0.0;
          return band.startPixel + (frac * band.pixelHeight);
        } else {
          final rate = band.pixelHeight / band.durationMinutes;
          return band.startPixel + ((clampedM - band.startMinutes) * rate);
        }
      }
    }
    return totalHeight;
  }

  int pixelsToMinutes(double pixels) {
    final clampedY = pixels.clamp(0.0, totalHeight);
    for (final band in bands) {
      if (clampedY >= band.startPixel && clampedY <= band.endPixel) {
        if (band.pixelHeight == 0) return band.startMinutes;
        final frac = (clampedY - band.startPixel) / band.pixelHeight;
        final mins = band.startMinutes + (frac * band.durationMinutes).round();
        return mins.clamp(0, 1440);
      }
    }
    return 1440;
  }
}
