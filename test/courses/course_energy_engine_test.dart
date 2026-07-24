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
    );

    final cSkip = Course(
      id: 'c_skip',
      title: 'Hard Math',
      totalSessions: 10,
      sessionDurationMinutes: 60,
      createdAt: 0,
      updatedAt: 0,
      energyRule: 'skip',
    );

    final cHighOnly = Course(
      id: 'c_high',
      title: 'Advanced Physics',
      totalSessions: 10,
      sessionDurationMinutes: 90,
      createdAt: 0,
      updatedAt: 0,
      energyRule: 'highEnergyOnly',
    );

    final sNone = CourseSession(
      id: 's1',
      courseId: 'c_none',
      sessionNumber: 1,
      difficulty: 2,
      createdAt: 0,
      updatedAt: 0,
    );

    final sSkip = CourseSession(
      id: 's2',
      courseId: 'c_skip',
      sessionNumber: 1,
      difficulty: 5,
      createdAt: 0,
      updatedAt: 0,
    );

    final sHighOnly = CourseSession(
      id: 's3',
      courseId: 'c_high',
      sessionNumber: 1,
      difficulty: 5,
      createdAt: 0,
      updatedAt: 0,
    );

    final coursesMap = {
      'c_none': cNone,
      'c_skip': cSkip,
      'c_high': cHighOnly,
    };

    test('LOW energy filters out skip and highEnergyOnly courses', () {
      final result = CourseEnergyEngine.filterAndRankForEnergy(
        candidateSessions: [sNone, sSkip, sHighOnly],
        coursesMap: coursesMap,
        currentEnergyLevel: 'LOW',
      );

      expect(result.length, equals(1));
      expect(result.first.id, equals('s1'));
    });

    test('HIGH energy prioritizes highEnergyOnly and high difficulty', () {
      final result = CourseEnergyEngine.filterAndRankForEnergy(
        candidateSessions: [sNone, sSkip, sHighOnly],
        coursesMap: coursesMap,
        currentEnergyLevel: 'HIGH',
      );

      expect(result.length, equals(3));
      expect(result.first.id, equals('s3')); // c_high has highest score
    });
  });
}
