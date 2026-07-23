// lib/features/routines/domain/strategies/reflection_strategy.dart

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';
import 'package:sqflite/sqflite.dart';

class ReflectionStrategy implements PlannerCategoryStrategy {
  const ReflectionStrategy();

  @override
  Category get category => Category.personal;

  @override
  bool matches(Category category, {String? itemType}) =>
      category == Category.personal && itemType == 'REFLECT';

  @override
  bool isModuleEnabled(Object controller) => true;

  @override
  Future<void> save(Object ctx, BuildContext context) async {
    final c = ctx as PlannerSaveContext;
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final todayStr = c.formatDate(c.selectedDate);

    await db.insert(
      'daily_reflections',
      {
        'id': 'reflection_$todayStr',
        'date': todayStr,
        'mood_score': c.reflectionMood,
        'reflection_text': c.title,
        'reflectionNote': c.title,
        'learnings': c.reflectionLearnings.isNotEmpty ? c.reflectionLearnings : null,
        'gratitude': c.reflectionGratitude.isNotEmpty ? c.reflectionGratitude : null,
        'wins': c.reflectionWins.isNotEmpty ? c.reflectionWins : null,
        'goodThing': c.reflectionWins.isNotEmpty ? c.reflectionWins : null,
        'challenges': null,
        'tomorrowFocus': null,
        'timestamp': now,
        'isPrivate': c.reflectionIsPrivate ? 1 : 0,
        'createdAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    RitmoEventBus().fire(RitmoEvent(
      type: 'ReflectionChanged',
      timestamp: DateTime.now(),
      payload: const {},
    ));
  }
}
