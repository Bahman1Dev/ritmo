import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/courses_engine.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

void main() {
  group('Prompt 056 Bug Verification Tests', () {
    test('D-1 & D-27: CourseSession skipReason & completedAt for skipped sessions', () {
      final session = CourseSession(
        id: 's1',
        courseId: 'c1',
        sessionNumber: 1,
        createdAt: 1000,
        updatedAt: 1000,
        note: 'Study Note 1',
        skipReason: 'Lack of energy',
        completionStatus: SessionStatus.skipped,
        completedAt: null,
      );

      expect(session.note, equals('Study Note 1'));
      expect(session.skipReason, equals('Lack of energy'));
      expect(session.completedAt, isNull);
      expect(session.isSkipped, isTrue);
      expect(session.isCompleted, isFalse);
    });

    test('D-4: Engine Fingerprint includes completion state & updated timestamp', () {
      final engine = CoursesEngine();
      final today = DateTime(2026, 8, 6);
      final course = Course(
        id: 'c1',
        title: 'Flutter Advanced',
        totalSessions: 10,
        sessionDurationMinutes: 45,
        courseType: CourseType.skill,
        preferredDays: [6, 1, 3],
        createdAt: 1000,
        updatedAt: 1000,
      );

      final s1Pending = CourseSession(
        id: 's1',
        courseId: 'c1',
        sessionNumber: 1,
        createdAt: 1000,
        updatedAt: 1000,
        completionStatus: SessionStatus.pending,
      );

      final fp1 = engine.fingerprint(CoursesEngineInput(
        courses: [course],
        sessions: [s1Pending],
        currentEnergyLevel: 'MEDIUM',
        today: today,
      ));

      final s1Completed = s1Pending.copyWith(
        completionStatus: SessionStatus.completed,
        updatedAt: 2000,
      );

      final fp2 = engine.fingerprint(CoursesEngineInput(
        courses: [course],
        sessions: [s1Completed],
        currentEnergyLevel: 'MEDIUM',
        today: today,
      ));

      expect(fp1, isNot(equals(fp2)));
    });

    test('D-7 & SafeCourseColor: Handles null, hex prefixes and invalid hex gracefully', () {
      final c1 = Course(
        id: 'c1',
        title: 'Safe Color Test',
        totalSessions: 5,
        sessionDurationMinutes: 30,
        courseType: CourseType.custom,
        preferredDays: [6, 1, 3],
        colorHex: '#FF5733',
        createdAt: 1000,
        updatedAt: 1000,
      );

      final c2 = Course(
        id: 'c2',
        title: 'Invalid Color Test',
        totalSessions: 5,
        sessionDurationMinutes: 30,
        courseType: CourseType.custom,
        preferredDays: [6, 1, 3],
        colorHex: 'INVALID_HEX',
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(c1.resolvedColor(const Color(0xff000000)).value, equals(const Color(0xffff5733).value));
      expect(c2.resolvedColor(const Color(0xff000000)).value, equals(const Color(0xff000000).value));
    });

    test('D-19 & D-20: RitmoNumber Persian Digits Normalization', () {
      const faStr = '۱۲';
      final enStr = RitmoNumber.toEn(faStr);
      final parsed = int.tryParse(enStr);

      expect(enStr, equals('12'));
      expect(parsed, equals(12));
      expect(parsed! >= 1, isTrue);
    });
  });
}
