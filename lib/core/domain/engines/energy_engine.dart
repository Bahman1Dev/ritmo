import 'package:ritmo/core/domain/models.dart';

class EnergyLog {

  EnergyLog({
    required this.id,
    required this.energyLevel,
    required this.source,
    this.note,
    required this.loggedAt,
  });
  final String id;
  final EnergyLevel energyLevel;
  final String source; // MANUAL, CHECK_IN, INFERRED
  final String? note;
  final DateTime loggedAt;
}

class EnergyEngine {
  /// Resolves the current energy level based on the list of logs and the current timestamp.
  /// If the latest log is older than [validityMinutes], it is considered stale, and the [defaultEnergy] (usually MEDIUM) is returned.
  static EnergyLevel resolve({
    required List<EnergyLog> logs,
    required int validityMinutes,
    required EnergyLevel defaultEnergy,
    required DateTime now,
  }) {
    if (logs.isEmpty) {
      return defaultEnergy;
    }

    // Sort logs descending by loggedAt to get the latest one
    final sortedLogs = List<EnergyLog>.from(logs)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    final latestLog = sortedLogs.first;

    // Check if the log is within the validity window
    final difference = now.difference(latestLog.loggedAt).inMinutes;

    if (difference >= 0 && difference <= validityMinutes) {
      return latestLog.energyLevel;
    }

    // Stale or future log (invalid)
    return defaultEnergy;
  }
}
