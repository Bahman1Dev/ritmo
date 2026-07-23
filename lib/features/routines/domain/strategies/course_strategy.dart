// lib/features/routines/domain/strategies/course_strategy.dart

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';

class CourseStrategy implements PlannerCategoryStrategy {
  const CourseStrategy();

  @override
  Category get category => Category.learning;

  @override
  bool matches(Category category, {String? itemType}) => category == Category.learning;

  @override
  bool isModuleEnabled(Object controller) => true;

  @override
  Future<void> save(Object ctx, BuildContext context) async {
    final c = ctx as PlannerSaveContext;
    final now = DateTime.now().millisecondsSinceEpoch;

    final course = Course(
      id: 'course_$now',
      title: c.title,
      totalSessions: c.courseTotalSessions,
      sessionDurationMinutes: c.courseSessionDuration,
      createdAt: now,
      updatedAt: now,
      courseType: CourseTypeExtension.fromString(c.courseType),
      weeklyTargetSessions: c.courseWeeklyTarget,
      preferredDays: c.coursePreferredDays,
      preferredTime: c.formatTime(c.coursePreferredTime),
      reminderEnabled: true,
    );

    await CoursesRepository.instance.createCourse(course);
    RitmoEventBus().fire(RitmoEvent(
      type: 'CourseChanged',
      timestamp: DateTime.now(),
      payload: const {},
    ));
  }
}
