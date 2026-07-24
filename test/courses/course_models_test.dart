import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

void main() {
  group('Course & CourseSession Model Round-Trip Tests (C2)', () {
    test('Course toMap -> fromMap preserves all fields including nulls', () {
      final course = Course(
        id: 'c_test_1',
        title: 'دوره تست فلاتر',
        totalSessions: 12,
        sessionDurationMinutes: 45,
        activityType: 'STUDY',
        zoneId: null,
        isArchived: false,
        energyRule: 'offerLight',
        createdAt: 1700000000000,
        updatedAt: 1700000005000,
        courseType: CourseType.video,
        unitLabel: null,
        emoji: '📱',
        colorHex: '#FF0055',
        provider: 'یوتیوب',
        weeklyTargetSessions: 4,
        isAdaptive: true,
        preferredDays: [6, 1, 3],
        preferredTime: '18:00',
        reminderEnabled: true,
        linkedGoalId: null,
        status: CourseStatus.active,
        completedAt: null,
        targetEndDate: '2026-10-15',
        adaptiveLastAppliedAt: 1700001000000,
        masteryScore: 85.5,
        reviewEnabled: true,
      );

      final map = course.toMap();
      final restored = Course.fromMap(map);

      expect(restored.id, equals(course.id));
      expect(restored.title, equals(course.title));
      expect(restored.totalSessions, equals(course.totalSessions));
      expect(restored.sessionDurationMinutes, equals(course.sessionDurationMinutes));
      expect(restored.zoneId, isNull);
      expect(restored.isArchived, isFalse);
      expect(restored.energyRule, equals('offerLight'));
      expect(restored.courseType, equals(CourseType.video));
      expect(restored.unitLabel, isNull);
      expect(restored.emoji, equals('📱'));
      expect(restored.colorHex, equals('#FF0055'));
      expect(restored.provider, equals('یوتیوب'));
      expect(restored.weeklyTargetSessions, equals(4));
      expect(restored.isAdaptive, isTrue);
      expect(restored.preferredDays, equals([6, 1, 3]));
      expect(restored.preferredTime, equals('18:00'));
      expect(restored.reminderEnabled, isTrue);
      expect(restored.linkedGoalId, isNull);
      expect(restored.status, equals(CourseStatus.active));
      expect(restored.completedAt, isNull);
      expect(restored.targetEndDate, equals('2026-10-15'));
      expect(restored.adaptiveLastAppliedAt, equals(1700001000000));
      expect(restored.masteryScore, equals(85.5));
      expect(restored.reviewEnabled, isTrue);
    });

    test('CourseSession toMap -> fromMap preserves all fields including nulls & enums', () {
      final session = CourseSession(
        id: 'sess_test_1',
        courseId: 'c_test_1',
        sessionNumber: 3,
        plannedDate: '2026-08-01',
        completionStatus: SessionStatus.completed,
        actualDurationMinutes: 50,
        note: 'تمرین خوب انجام شد',
        createdAt: 1700000000000,
        updatedAt: 1700000500000,
        sessionTitle: 'جلسه سوم - ویجت‌های سفارشی',
        completedAt: 1700000500000,
        isUserScheduled: true,
        plannedStartTime: '18:30',
        estimatedDurationMinutes: 45,
        sectionTitle: 'فصل دو: ویجت‌ها',
        learningObjective: 'آشنایی با RenderObject',
        difficulty: 4,
        activityKind: CourseActivityKind.practice,
        understandingScore: 5,
        needsReview: true,
        keyTakeaway: 'کلید مسئله ساخت CustomPainter بود',
        openQuestion: null,
        sourceSessionId: null,
        displayOrder: 3,
      );

      final map = session.toMap();
      final restored = CourseSession.fromMap(map);

      expect(restored.id, equals(session.id));
      expect(restored.courseId, equals(session.courseId));
      expect(restored.sessionNumber, equals(3));
      expect(restored.plannedDate, equals('2026-08-01'));
      expect(restored.completionStatus, equals(SessionStatus.completed));
      expect(restored.isCompleted, isTrue);
      expect(restored.isSkipped, isFalse);
      expect(restored.actualDurationMinutes, equals(50));
      expect(restored.note, equals('تمرین خوب انجام شد'));
      expect(restored.sessionTitle, equals('جلسه سوم - ویجت‌های سفارشی'));
      expect(restored.completedAt, equals(1700000500000));
      expect(restored.isUserScheduled, isTrue);
      expect(restored.plannedStartTime, equals('18:30'));
      expect(restored.estimatedDurationMinutes, equals(45));
      expect(restored.sectionTitle, equals('فصل دو: ویجت‌ها'));
      expect(restored.learningObjective, equals('آشنایی با RenderObject'));
      expect(restored.difficulty, equals(4));
      expect(restored.activityKind, equals(CourseActivityKind.practice));
      expect(restored.understandingScore, equals(5));
      expect(restored.needsReview, isTrue);
      expect(restored.keyTakeaway, equals('کلید مسئله ساخت CustomPainter بود'));
      expect(restored.openQuestion, isNull);
      expect(restored.sourceSessionId, isNull);
      expect(restored.displayOrder, equals(3));
    });

    test('CourseSession copyWith clearCompletedAt resets completedAt and status', () {
      final session = CourseSession(
        id: 'sess_1',
        courseId: 'c_1',
        sessionNumber: 1,
        completionStatus: SessionStatus.completed,
        completedAt: 1700000000000,
        createdAt: 1700000000000,
        updatedAt: 1700000000000,
      );

      final cleared = session.clearCompletedAt();
      expect(cleared.completedAt, isNull);
      expect(cleared.completionStatus, equals(SessionStatus.pending));
      expect(cleared.isCompleted, isFalse);
    });
  });
}
