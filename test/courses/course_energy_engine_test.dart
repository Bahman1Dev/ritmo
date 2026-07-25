import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/courses/logic/course_energy_engine.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

void main() {
  group('CourseEnergyEngine Unit Tests (C10)', () {
    final cNone = Course(
      id: 'c_none',
      title: 'Normal',
      totalSessions: 10,
      sessionDurationMinutes: 45,
      createdAt: 0,
      updatedAt: 0,
      energyRule: 'NONE',
      courseType: CourseType.custom,
      preferredDays: const [1, 3, 5],
    );

    final cSkip = Course(
      id: 'c_skip',
      title: 'Hard Math',
      totalSessions: 10,
      sessionDurationMinutes: 60,
      createdAt: 0,
      updatedAt: 0,
      energyRule: 'skip',
      courseType: CourseType.custom,
      preferredDays: const [1, 3, 5],
    );

    final cHighOnly = Course(
      id: 'c_high',
      title: 'Advanced Physics',
      totalSessions: 10,
      sessionDurationMinutes: 90,
      createdAt: 0,
      updatedAt: 0,
      energyRule: 'highEnergyOnly',
      courseType: CourseType.custom,
      preferredDays: const [1, 3, 5],
    );

    final sNone = CourseSession(
      id: 's1',
      courseId: 'c_none',
      sessionNumber: 1,
      createdAt: 0,
      updatedAt: 0,
    );

    final sSkip = CourseSession(
      id: 's2',
      courseId: 'c_skip',
      sessionNumber: 1,
      createdAt: 0,
      updatedAt: 0,
    );

    final sHigh = CourseSession(
      id: 's3',
      courseId: 'c_high',
      sessionNumber: 1,
      createdAt: 0,
      updatedAt: 0,
    );

    final coursesMap = {
      'c_none': cNone,
      'c_skip': cSkip,
      'c_high': cHighOnly,
    };

    test('Filters out skip and highEnergyOnly sessions when energy is LOW', () {
      final res = CourseEnergyEngine.filterAndRankForEnergy(
        candidateSessions: [sNone, sSkip, sHigh],
        coursesMap: coursesMap,
        currentEnergyLevel: 'LOW',
      );

      expect(res.length, 1);
      expect(res.first.id, 's1');
    });

    test('Filters out highEnergyOnly session when energy is MEDIUM', () {
      final res = CourseEnergyEngine.filterAndRankForEnergy(
        candidateSessions: [sNone, sSkip, sHigh],
        coursesMap: coursesMap,
        currentEnergyLevel: 'MEDIUM',
      );

      expect(res.length, 2);
      expect(res.map((s) => s.id), containsAll(['s1', 's2']));
    });

    test('Allows all sessions when energy is HIGH', () {
      final res = CourseEnergyEngine.filterAndRankForEnergy(
        candidateSessions: [sNone, sSkip, sHigh],
        coursesMap: coursesMap,
        currentEnergyLevel: 'HIGH',
      );

      expect(res.length, 3);
    });
  });
}
