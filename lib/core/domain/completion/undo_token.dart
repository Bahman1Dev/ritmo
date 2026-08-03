import 'package:flutter/foundation.dart';

@immutable
sealed class UndoToken {
  const UndoToken();

  String serialize();

  static UndoToken parse(String raw) {
    if (raw.startsWith('routine:')) {
      final payload = raw.substring('routine:'.length);
      final parts = payload.split('|');
      if (parts.length >= 5) {
        return RoutineCompletionUndoToken(
          routineId: parts[0],
          dateStr: parts[1],
          completionId: parts[2],
          previousProgressionCurrent: int.tryParse(parts[3]) ?? 0,
          previousProgressionDoneSinceAdvance: int.tryParse(parts[4]) ?? 0,
        );
      } else if (parts.length >= 2) {
        return RoutineCompletionUndoToken(
          routineId: parts[0],
          dateStr: parts[1],
          completionId: 'comp_${parts[0]}_${parts[1]}',
          previousProgressionCurrent: 0,
          previousProgressionDoneSinceAdvance: 0,
        );
      }
    } else if (raw.startsWith('reschedule:')) {
      final payload = raw.substring('reschedule:'.length);
      final parts = payload.split('|');
      if (parts.length >= 3) {
        return RescheduleUndoToken(
          routineId: parts[0],
          fromDateStr: parts[1],
          toDateStr: parts[2],
        );
      }
    } else if (raw.startsWith('skip:')) {
      final payload = raw.substring('skip:'.length);
      final parts = payload.split('|');
      if (parts.length >= 3) {
        return SkipUndoToken(
          routineId: parts[0],
          dateStr: parts[1],
          completionId: parts[2],
        );
      }
    }

    throw FormatException('Invalid UndoToken format: "$raw"');
  }
}

class RoutineCompletionUndoToken extends UndoToken {
  const RoutineCompletionUndoToken({
    required this.routineId,
    required this.dateStr,
    required this.completionId,
    required this.previousProgressionCurrent,
    required this.previousProgressionDoneSinceAdvance,
  });

  final String routineId;
  final String dateStr;
  final String completionId;
  final int previousProgressionCurrent;
  final int previousProgressionDoneSinceAdvance;

  @override
  String serialize() =>
      'routine:$routineId|$dateStr|$completionId|$previousProgressionCurrent|$previousProgressionDoneSinceAdvance';
}

class RescheduleUndoToken extends UndoToken {
  const RescheduleUndoToken({
    required this.routineId,
    required this.fromDateStr,
    required this.toDateStr,
  });

  final String routineId;
  final String fromDateStr;
  final String toDateStr;

  @override
  String serialize() => 'reschedule:$routineId|$fromDateStr|$toDateStr';
}

class SkipUndoToken extends UndoToken {
  const SkipUndoToken({
    required this.routineId,
    required this.dateStr,
    required this.completionId,
  });

  final String routineId;
  final String dateStr;
  final String completionId;

  @override
  String serialize() => 'skip:$routineId|$dateStr|$completionId';
}
