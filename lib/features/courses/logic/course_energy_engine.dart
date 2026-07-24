import 'package:ritmo/features/courses/models/course_models.dart';

class CourseEnergyEngine {
  /// Filters and ranks candidate sessions based on current energy level (HIGH, MEDIUM, LOW)
  static List<CourseSession> filterAndRankForEnergy({
    required List<CourseSession> candidateSessions,
    required Map<String, Course> coursesMap,
    required String currentEnergyLevel,
  }) {
    final energy = currentEnergyLevel.toUpperCase();
    final filtered = <CourseSession>[];

    for (final session in candidateSessions) {
      final course = coursesMap[session.courseId];
      final energyRule = course?.energyRule ?? 'NONE';

      if (energy == 'LOW') {
        if (energyRule == 'skip' || energyRule == 'highEnergyOnly') {
          continue; // Filter out
        }
        filtered.add(session);
      } else if (energy == 'MEDIUM') {
        if (energyRule == 'highEnergyOnly') {
          continue; // Filter out
        }
        filtered.add(session);
      } else {
        // HIGH energy: allow all
        filtered.add(session);
      }
    }

    // Sort/rank candidates
    filtered.sort((a, b) {
      final courseA = coursesMap[a.courseId];
      final courseB = coursesMap[b.courseId];

      final ruleA = courseA?.energyRule ?? 'NONE';
      final ruleB = courseB?.energyRule ?? 'NONE';

      final diffA = a.difficulty ?? 3;
      final diffB = b.difficulty ?? 3;

      if (energy == 'HIGH') {
        // High energy prefers highEnergyOnly rules and higher difficulty
        final scoreA = (ruleA == 'highEnergyOnly' ? 10 : 0) + diffA;
        final scoreB = (ruleB == 'highEnergyOnly' ? 10 : 0) + diffB;
        return scoreB.compareTo(scoreA);
      } else if (energy == 'LOW') {
        // Low energy prefers lower difficulty and shorter duration
        final durA = a.estimatedDurationMinutes ?? courseA?.sessionDurationMinutes ?? 45;
        final durB = b.estimatedDurationMinutes ?? courseB?.sessionDurationMinutes ?? 45;
        final scoreA = diffA * 10 + durA;
        final scoreB = diffB * 10 + durB;
        return scoreA.compareTo(scoreB);
      } else {
        // Medium energy: default display order or session number
        return a.displayOrder.compareTo(b.displayOrder);
      }
    });

    return filtered;
  }
}
