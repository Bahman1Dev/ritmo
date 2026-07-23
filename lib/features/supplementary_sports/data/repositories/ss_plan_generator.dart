import 'dart:convert';
import 'dart:math';

import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:sqflite/sqflite.dart';

enum ProgressionSignal {
  increase, // ready to increase (EASY)
  decrease, // mostly HARD
  maintain, // GOOD
}

class SSPlanGenerator {
  SSPlanGenerator._();

  /// Generates a fully personalized workout plan for a specific week (1 to 4)
  /// and saves it to the SQLite database.
  static Future<void> generateWeeklyAndMonthlyPlan(
    Database db,
    SsUserProfile profile, {
    required int week,
    Map<String, ProgressionSignal>? progressionSignals,
  }) async {
    // 1. Determine schedule split (days of the week)
    final workoutDays = <int>[];
    if (profile.daysPerWeek == 1) {
      workoutDays.addAll([1]); // Sat
    } else if (profile.daysPerWeek == 2) {
      workoutDays.addAll([1, 4]); // Sat, Tue
    } else if (profile.daysPerWeek == 3) {
      workoutDays.addAll([1, 3, 5]); // Sat, Mon, Wed
    } else if (profile.daysPerWeek == 4) {
      workoutDays.addAll([1, 3, 5, 6]); // Sat, Mon, Wed, Thu
    } else if (profile.daysPerWeek == 5) {
      workoutDays.addAll([1, 2, 3, 5, 6]); // Sat, Sun, Mon, Wed, Thu
    } else if (profile.daysPerWeek == 6) {
      workoutDays.addAll([1, 2, 3, 4, 5, 6]); // Sat-Thu
    } else {
      workoutDays.addAll([1, 2, 3, 4, 5, 6, 7]); // Sat-Fri
    }

    // 2. Clear existing plans for this week to avoid duplicates
    final weekIdPrefix = 'plan_w${week}_';
    await db.delete(
      'ss_workout_exercise_crossref',
      where: 'planId LIKE ?',
      whereArgs: ['$weekIdPrefix%'],
    );
    await db.delete(
      'ss_workout_plan',
      where: 'id LIKE ?',
      whereArgs: ['$weekIdPrefix%'],
    );

    // 3. Generate each day using generateSingleDayPlan
    for (final day in workoutDays) {
      await generateSingleDayPlan(
        db,
        profile,
        week: week,
        dayOfWeek: day,
        progressionSignals: progressionSignals,
      );
    }
  }

  /// Selects the best Fitify Set Code based on user profile and goal
  static String _selectSetCode(SsUserProfile profile) {
    final isFemale = (profile.gender ?? '').toUpperCase() == 'FEMALE';
    final hasCore = profile.focusAreas.contains(BodyArea.core);
    final hasLegs = profile.focusAreas.contains(BodyArea.legs);
    final hasChestOrUpper = profile.focusAreas.contains(BodyArea.chest) || 
                            profile.focusAreas.contains(BodyArea.arms) || 
                            profile.focusAreas.contains(BodyArea.shoulders);

    if (profile.neighborFriendly) {
      if (profile.goal == FitnessGoal.fatLoss) {
        return 'low_impact';
      }
      if (hasCore) {
        return 'complex_core';
      }
      return 'balance';
    }

    if (isFemale) {
      if (hasCore) {
        return 'fem_rounds';
      }
      if (profile.goal == FitnessGoal.fatLoss) {
        return 'fem_hiit';
      }
      if (hasLegs) {
        return 'fem_rounds';
      }
      return 'fem_tabata';
    }

    // Male/General
    if (profile.goal == FitnessGoal.fatLoss) {
      if (hasCore) {
        return 'lose_belly';
      }
      if (profile.focusAreas.contains(BodyArea.fullBody)) {
        return 'hiit';
      }
      return 'sprint_cardio';
    }

    if (profile.goal == FitnessGoal.muscleGain || profile.goal == FitnessGoal.strength) {
      if (hasCore) {
        return 'insane_six_pack';
      }
      if (hasLegs && !hasChestOrUpper) {
        return 'b_lower_body';
      }
      if (hasChestOrUpper && !hasLegs) {
        return 'a_upper_body';
      }
      return 'full_body';
    }

    // Default
    if (hasCore) {
      return 'complex_core';
    }
    return 'full_body';
  }

  /// Generates a plan for a single specific day using all personalization & progression logic
  static Future<void> generateSingleDayPlan(
    Database db,
    SsUserProfile profile, {
    required int week,
    required int dayOfWeek,
    Map<String, ProgressionSignal>? progressionSignals,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    final setCode = _selectSetCode(profile);

    // 1. Fetch exercises from SQLite that belong to the chosen set and have suitability > 0
    final List<Map<String, dynamic>> rawDbResult = await db.rawQuery('''
      SELECT e.*, 
             s.suitability, 
             s.suitability_lowerbody, 
             s.suitability_abscore, 
             s.suitability_back, 
             s.suitability_upperbody, 
             s.difficulty as set_difficulty,
             s.sort_order as set_sort_order,
             s.skill_required as set_skill_required,
             s.skill_max as set_skill_max
      FROM ss_exercise e
      JOIN ss_exercise_set_suitability s ON e.id = s.exercise_id
      WHERE s.set_code = ? AND s.suitability > 0
    ''', [setCode]);

    var allExercises = rawDbResult;
    if (allExercises.isEmpty) {
      final fallbackQuery = await db.query('ss_exercise');
      allExercises = fallbackQuery.map((ex) {
        final m = Map<String, dynamic>.from(ex);
        m['suitability'] = 5;
        m['suitability_lowerbody'] = -1;
        m['suitability_abscore'] = -1;
        m['suitability_back'] = -1;
        m['suitability_upperbody'] = -1;
        m['set_difficulty'] = 2;
        m['set_sort_order'] = 0;
        m['set_skill_required'] = -1;
        m['set_skill_max'] = -1;
        return m;
      }).toList();
    }

    // 2. Filter exercises by equipment, limitations, and skill level suitability
    final allowedExercises = allExercises.where((ex) {
      if (profile.neighborFriendly) {
        final noisyVal = int.tryParse(ex['noisy']?.toString() ?? '0') ?? 0;
        final impactVal = int.tryParse(ex['impact']?.toString() ?? '0') ?? 0;
        if (noisyVal >= 2 || impactVal >= 2) return false;
      }
      return _isExerciseAllowed(ex, profile.availableEquipment) &&
             _satisfiesLimitations(ex, profile.physicalLimitations) &&
             _satisfiesSkill(ex, profile.experienceLevel);
    }).toList();

    // Fallback conflict resolution
    var finalExercises = allowedExercises;
    if (finalExercises.isEmpty) {
      finalExercises = allExercises.where((ex) {
        final tools = _decodeTools(ex['toolsRequired']);
        final isBodyweight = tools.isEmpty || ex['equipment']?.toString() == 'bodyweightOnly';
        final isSafeCategory = ex['category']?.toString() == 'warmup' ||
                               ex['category']?.toString() == 'stretching' ||
                               ex['category']?.toString() == 'yoga';
        return isBodyweight && isSafeCategory;
      }).toList();
      
      if (finalExercises.isEmpty) {
        finalExercises = allExercises;
      }
    }

    // 3. Clear existing plan and crossrefs for this specific day
    final planId = 'plan_w${week}_$dayOfWeek';
    await db.delete(
      'ss_workout_exercise_crossref',
      where: 'planId = ?',
      whereArgs: [planId],
    );
    await db.delete(
      'ss_workout_plan',
      where: 'id = ?',
      whereArgs: [planId],
    );

    // 4. Determine schedule split (days of the week)
    final workoutDays = <int>[];
    if (profile.daysPerWeek == 1) {
      workoutDays.addAll([1]);
    } else if (profile.daysPerWeek == 2) {
      workoutDays.addAll([1, 4]);
    } else if (profile.daysPerWeek == 3) {
      workoutDays.addAll([1, 3, 5]);
    } else if (profile.daysPerWeek == 4) {
      workoutDays.addAll([1, 3, 5, 6]);
    } else if (profile.daysPerWeek == 5) {
      workoutDays.addAll([1, 2, 3, 5, 6]);
    } else if (profile.daysPerWeek == 6) {
      workoutDays.addAll([1, 2, 3, 4, 5, 6]);
    } else {
      workoutDays.addAll([1, 2, 3, 4, 5, 6, 7]);
    }

    final dayIndex = workoutDays.indexOf(dayOfWeek);
    final splitLength = workoutDays.isNotEmpty ? workoutDays.length : 3;
    final finalDayIndex = dayIndex >= 0 ? dayIndex : 0;

    // Define target focus categories and muscle groups depending on split length and current day
    var targetCategories = <String>[];
    var farsiMuscleNames = <String>[];

    if (splitLength == 1) {
      // Full Body
      targetCategories = ['upper_body', 'lower_body', 'shoulder_and_back', 'core'];
      farsiMuscleNames = ['کل بدن'];
    } else if (splitLength == 2) {
      if (finalDayIndex == 0) {
        targetCategories = ['upper_body', 'shoulder_and_back', 'core'];
        farsiMuscleNames = ['بالاتنه', 'شکم'];
      } else {
        targetCategories = ['lower_body', 'cardio', 'core'];
        farsiMuscleNames = ['پایین‌تنه', 'هوازی'];
      }
    } else {
      // 3+ Days Split
      final part = finalDayIndex % 3;
      if (part == 0) {
        targetCategories = ['upper_body', 'core'];
        farsiMuscleNames = ['سینه', 'سرشانه', 'پشت‌بازو'];
      } else if (part == 1) {
        targetCategories = ['shoulder_and_back'];
        farsiMuscleNames = ['زیربغل', 'پشت', 'جلوبازو'];
      } else {
        targetCategories = ['lower_body', 'core'];
        farsiMuscleNames = ['ران و باسن', 'ساق پا', 'شکم'];
      }
    }

    // Determine session duration and exercise count based on duration
    final defaults = getSessionDefaults(profile.sessionDuration);
    final estimatedMinutes = defaults.$1;
    final targetCount = defaults.$2;

    // Build session flow
    final sessionExercises = <Map<String, dynamic>>[];

    // Helper for sorting groups: sort by set_sort_order first, then by score DESC
    void sortGroup(List<Map<String, dynamic>> list) {
      list.sort((a, b) {
        final orderA = int.tryParse(a['set_sort_order']?.toString() ?? '0') ?? 0;
        final orderB = int.tryParse(b['set_sort_order']?.toString() ?? '0') ?? 0;
        if (orderA != 0 || orderB != 0) {
          if (orderA == 0) return 1;
          if (orderB == 0) return -1;
          return orderA.compareTo(orderB);
        }
        final scoreA = _calculateExerciseScore(a, profile);
        final scoreB = _calculateExerciseScore(b, profile);
        return scoreB.compareTo(scoreA);
      });
    }

    // 5.1. Warmup (1 exercise)
    final warmups = finalExercises
        .where((ex) => ex['category']?.toString() == 'warmup' || ex['category']?.toString() == 'stretching')
        .toList();
    sortGroup(warmups);
    if (warmups.isNotEmpty) {
      sessionExercises.add(warmups[random.nextInt(min(5, warmups.length))]);
    }

    // 5.2. Primary Work (Compound & high-suitability: targetCount - 3 exercises)
    final primaryOptions = finalExercises
        .where((ex) => targetCategories.contains(ex['category']?.toString()))
        .toList();
    sortGroup(primaryOptions);
    
    if (primaryOptions.isNotEmpty) {
      final selectCount = max(2, targetCount - 3);
      final topOptions = primaryOptions.take(min(12, primaryOptions.length)).toList();
      topOptions.shuffle(random);
      sessionExercises.addAll(topOptions.take(min(selectCount, topOptions.length)));
    }

    // 5.3. Finishers/Cardio (1-2 exercises)
    final finishers = finalExercises
        .where((ex) => ex['category']?.toString() == 'core' || ex['category']?.toString() == 'cardio' || ex['category']?.toString() == 'plyometric')
        .toList();
    sortGroup(finishers);
    if (finishers.isNotEmpty) {
      final topFinishers = finishers.take(min(8, finishers.length)).toList();
      topFinishers.shuffle(random);
      sessionExercises.addAll(topFinishers.take(min(1, topFinishers.length)));
    }

    // 5.4. Cooldown (1 exercise)
    final cooldowns = finalExercises
        .where((ex) => ex['category']?.toString() == 'stretching' || ex['category']?.toString() == 'yoga')
        .toList();
    sortGroup(cooldowns);
    if (cooldowns.isNotEmpty) {
      sessionExercises.add(cooldowns[random.nextInt(min(5, cooldowns.length))]);
    }

    // Deduplicate selected exercises
    final seenIds = <String>{};
    final uniqueSessionExercises = <Map<String, dynamic>>[];
    for (final ex in sessionExercises) {
      final id = ex['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        uniqueSessionExercises.add(ex);
      }
    }

    // 6. Define target configuration sets, reps, and rest based on goal
    var baseSets = 3;
    var baseReps = 10;
    switch (profile.goal) {
      case FitnessGoal.strength:
        baseSets = 5;
        baseReps = 5;
      case FitnessGoal.muscleGain:
        baseSets = 4;
        baseReps = 10;
      case FitnessGoal.fatLoss:
        baseSets = 3;
        baseReps = 15;
      case FitnessGoal.bodyRecomposition:
        baseSets = 3;
        baseReps = 12;
    }

    // Adjust sets based on experience level
    if (profile.experienceLevel == ExperienceLevel.beginner) {
      baseSets = max(1, baseSets - 1);
    } else if (profile.experienceLevel == ExperienceLevel.advanced) {
      baseSets = baseSets + 1;
    }

    double? baseWeight;
    final hasWeights = profile.availableEquipment.contains(Equipment.dumbbell) ||
                            profile.availableEquipment.contains(Equipment.barbell);
    if (hasWeights) {
      baseWeight = profile.experienceLevel == ExperienceLevel.beginner
          ? 5.0
          : profile.experienceLevel == ExperienceLevel.intermediate
              ? 12.0
              : 20.0;
    }

    // Apply Progressive Overload week adjustments
    if (week == 1) {
      // baseline
    } else if (week == 2) {
      baseReps = baseReps + 2;
    } else if (week == 3) {
      baseSets = baseSets + 1;
      baseReps = max(3, baseReps - 2);
      if (baseWeight != null) {
        baseWeight = (baseWeight * 1.15).roundToDouble(); // +15% weight
      }
    } else if (week == 4) {
      baseSets = max(1, baseSets - 1);
      if (baseWeight != null) {
        baseWeight = (baseWeight * 0.7).roundToDouble(); // -30% weight
      }
    }

    // Insert Plan Row
    await db.insert('ss_workout_plan', {
      'id': planId,
      'dayOfWeek': dayOfWeek,
      'muscleGroups': jsonEncode(farsiMuscleNames),
      'estimatedMinutes': estimatedMinutes,
      'createdAt': now,
      'updatedAt': now,
    });

    // Insert Crossref Rows
    for (var order = 0; order < uniqueSessionExercises.length; order++) {
      final ex = uniqueSessionExercises[order];
      final crossId = 'cross_${planId}_${ex['id']}_$order';
      final isWarmupOrCool = ex['category']?.toString() == 'warmup' ||
                             ex['category']?.toString() == 'stretching' ||
                             ex['category']?.toString() == 'yoga';

      final isWeightSupported = (ex['weightSupported'] as int? ?? 0) == 1;
      
      var exerciseSets = isWarmupOrCool ? 1 : baseSets;
      var exerciseReps = isWarmupOrCool ? 12 : baseReps;
      var exerciseWeight = (isWarmupOrCool || !isWeightSupported || !hasWeights) ? null : baseWeight;

      // Apply Progressive Overload signals
      if (!isWarmupOrCool && progressionSignals != null && progressionSignals.containsKey(ex['id'])) {
        final signal = progressionSignals[ex['id']];
        if (signal == ProgressionSignal.increase) {
          if (isWeightSupported && exerciseWeight != null) {
            exerciseWeight = (exerciseWeight * 1.1).roundToDouble();
          } else {
            if (exerciseReps < 15) {
              exerciseReps += 2;
            } else {
              exerciseSets += 1;
            }
          }
        } else if (signal == ProgressionSignal.decrease) {
          if (isWeightSupported && exerciseWeight != null) {
            exerciseWeight = max(1, (exerciseWeight * 0.9).roundToDouble());
          } else {
            if (exerciseReps > 5) {
              exerciseReps = max(5, exerciseReps - 2);
            } else {
              exerciseSets = max(1, exerciseSets - 1);
            }
          }
        }
      }

      await db.insert('ss_workout_exercise_crossref', {
        'id': crossId,
        'planId': planId,
        'exerciseId': ex['id'],
        'orderIndex': order,
        'difficultyOffset': 0.0,
        'targetSets': exerciseSets,
        'targetReps': exerciseReps,
        'targetWeight': exerciseWeight,
      });
    }
  }

  // --- Matching helpers ---

  static List<dynamic> _decodeTools(dynamic rawTools) {
    if (rawTools == null || rawTools.toString().isEmpty) {
      return [];
    }
    try {
      return jsonDecode(rawTools.toString()) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  static bool _isExerciseAllowed(Map<String, dynamic> ex, List<Equipment> availableEquipment) {
    final tools = _decodeTools(ex['toolsRequired']);

    final isBodyweightOnly = availableEquipment.contains(Equipment.bodyweightOnly);
    if (isBodyweightOnly) {
      return tools.isEmpty;
    }

    final toolMapping = <String, Equipment>{
      'regular_chair': Equipment.bodyweightOnly,
      'adjustable_bench': Equipment.dumbbell,
      'non_adjustable_bench': Equipment.barbell,
      'adjustable_bench,non_adjustable_bench': Equipment.dumbbell,
      'plyometric_box': Equipment.machine,
      'plyosoftbox': Equipment.machine,
      'jumprope': Equipment.resistanceBand,
    };

    if (tools.isEmpty) {
      return true;
    }

    for (final option in tools) {
      if (option is List) {
        var optionSatisfied = true;
        for (final tool in option) {
          final toolStr = tool.toString();
          final requiredEquip = toolMapping[toolStr];
          
          if (requiredEquip != null) {
            if (!availableEquipment.contains(requiredEquip)) {
              optionSatisfied = false;
              break;
            }
          } else {
            if (toolStr.contains(',')) {
              final parts = toolStr.split(',');
              var partSatisfied = false;
              for (final part in parts) {
                final partEquip = toolMapping[part.trim()];
                if (partEquip == null || availableEquipment.contains(partEquip)) {
                  partSatisfied = true;
                  break;
                }
              }
              if (!partSatisfied) {
                optionSatisfied = false;
                break;
              }
            }
          }
        }
        if (optionSatisfied) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _satisfiesLimitations(Map<String, dynamic> ex, List<Limitation> limitations) {
    if (limitations.contains(Limitation.none)) return true;

    final name = (ex['name'] ?? '').toString().toLowerCase();
    final nameEn = (ex['nameEn'] ?? '').toString().toLowerCase();
    final constraint = ex['constraintNegative']?.toString();

    final hasKneeProblems = limitations.contains(Limitation.kneeProblems);
    final hasNoJumping = limitations.contains(Limitation.noJumping);
    if (hasKneeProblems || hasNoJumping) {
      final impact = ex['impact'] is num ? (ex['impact'] as num).toInt() : 0;
      if (impact >= 2) {
        return false;
      }
    }

    for (final lim in limitations) {
      if (lim == Limitation.kneeProblems) {
        final hasKneeLoad = name.contains('squat') || name.contains('lunge') || name.contains('jump') || name.contains('jumping') ||
                            name.contains('اسکوات') || name.contains('لانژ') || name.contains('پرش') || name.contains('هاپ') ||
                            nameEn.contains('squat') || nameEn.contains('lunge') || nameEn.contains('jump') || nameEn.contains('jumping');
        if (hasKneeLoad) return false;
        
        if (constraint != null && const ['4', '5', '6', '7', '11', '18', '33', '38'].contains(constraint)) {
          return false;
        }
      }
      if (lim == Limitation.backProblems) {
        final hasBackLoad = name.contains('deadlift') || name.contains('superman') || name.contains('good morning') ||
                            name.contains('ددلیفت') || name.contains('فیله کمر') ||
                            nameEn.contains('deadlift') || nameEn.contains('superman') || nameEn.contains('good morning');
        if (hasBackLoad) return false;
      }
      if (lim == Limitation.shoulderProblems) {
        final hasShoulderLoad = name.contains('shoulder press') || name.contains('overhead') || name.contains('handstand') ||
                                name.contains('سرشانه') || name.contains('هنداستند') || name.contains('پرس شانه') ||
                                nameEn.contains('shoulder press') || nameEn.contains('overhead') || nameEn.contains('handstand');
        if (hasShoulderLoad) return false;

        if (constraint != null && const ['1', '28', '34'].contains(constraint)) {
          return false;
        }
      }
      if (lim == Limitation.wristProblems) {
        final hasWristLoad = name.contains('pushup') || name.contains('plank') || name.contains('handstand') ||
                             name.contains('شنا روی زمین') || name.contains('پلانک') ||
                             nameEn.contains('pushup') || nameEn.contains('plank') || nameEn.contains('handstand');
        if (hasWristLoad) return false;

        if (constraint != null && const ['1', '9', '30', '39'].contains(constraint)) {
          return false;
        }
      }
      if (lim == Limitation.noPullUps) {
        final hasPullup = name.contains('pullup') || name.contains('pull-up') || name.contains('بارفیکس') ||
                          nameEn.contains('pullup') || nameEn.contains('pull-up');
        if (hasPullup) return false;
      }
      if (lim == Limitation.noJumping) {
        final hasJumping = name.contains('jump') || name.contains('jumping') || name.contains('burpee') || name.contains('پرش') || name.contains('بورپی') ||
                           nameEn.contains('jump') || nameEn.contains('jumping') || nameEn.contains('burpee');
        if (hasJumping) return false;

        if (constraint != null && const ['4', '5', '9', '11', '12', '33'].contains(constraint)) {
          return false;
        }
      }
    }

    return true;
  }

  static bool _satisfiesSkill(Map<String, dynamic> ex, ExperienceLevel experience) {
    final skillRequired = int.tryParse(ex['set_skill_required']?.toString() ?? '-1') ?? -1;
    final skillMax = int.tryParse(ex['set_skill_max']?.toString() ?? '-1') ?? -1;

    final skillReq = skillRequired != -1 ? skillRequired : (int.tryParse(ex['skillRequired']?.toString() ?? '0') ?? 0);
    final skillMx = skillMax != -1 ? skillMax : (int.tryParse(ex['skill_max']?.toString() ?? '10') ?? 10);

    var userLevel = 3;
    if (experience == ExperienceLevel.intermediate) {
      userLevel = 6;
    } else if (experience == ExperienceLevel.advanced) {
      userLevel = 10;
    }

    return skillReq <= userLevel && userLevel <= (skillMx == 0 ? 10 : skillMx);
  }

  // --- Sorting & Scoring helpers ---

  static double _calculateExerciseScore(Map<String, dynamic> ex, SsUserProfile profile) {
    final suitabilityVal = int.tryParse(ex['suitability']?.toString() ?? '0') ?? 0;
    final suitabilityLower = int.tryParse(ex['suitability_lowerbody']?.toString() ?? '-1') ?? -1;
    final suitabilityAb = int.tryParse(ex['suitability_abscore']?.toString() ?? '-1') ?? -1;
    final suitabilityBack = int.tryParse(ex['suitability_back']?.toString() ?? '-1') ?? -1;
    final suitabilityUpper = int.tryParse(ex['suitability_upperbody']?.toString() ?? '-1') ?? -1;

    var suitability = suitabilityVal.toDouble();

    if (suitabilityLower != -1 && suitabilityAb != -1 && suitabilityBack != -1 && suitabilityUpper != -1) {
      var sum = 0.0;
      var count = 0.0;
      for (final area in profile.focusAreas) {
        if (area == BodyArea.core) {
          sum += suitabilityAb;
          count += 1.0;
        } else if (area == BodyArea.legs || area == BodyArea.glutes) {
          sum += suitabilityLower;
          count += 1.0;
        } else if (area == BodyArea.back || area == BodyArea.shoulders) {
          sum += suitabilityBack;
          count += 1.0;
        } else if (area == BodyArea.chest || area == BodyArea.arms) {
          sum += suitabilityUpper;
          count += 1.0;
        }
      }
      if (count > 0.0) {
        suitability = sum / count;
      } else {
        suitability = (suitabilityLower + suitabilityAb + suitabilityBack + suitabilityUpper) / 4.0;
      }
    }

    final sexynessM = int.tryParse(ex['sexyness_m']?.toString() ?? '5') ?? 5;
    final sexynessF = int.tryParse(ex['sexyness_f']?.toString() ?? '5') ?? 5;
    final sexyness = ((profile.gender ?? '').toUpperCase() == 'FEMALE' ? sexynessF : sexynessM).toDouble();

    final looksCool = int.tryParse(ex['looksCool']?.toString() ?? '0') ?? 0;

    final difficulty = (ex['set_difficulty'] as num?)?.toDouble() ?? 2.0;
    var userLevelDiff = 1.5;
    if (profile.experienceLevel == ExperienceLevel.intermediate) {
      userLevelDiff = 3.0;
    } else if (profile.experienceLevel == ExperienceLevel.advanced) {
      userLevelDiff = 4.5;
    }
    final diffPenalty = (difficulty - userLevelDiff).abs();

    const w1 = 0.5; // suitability
    const w2 = 0.2; // sexyness
    const w3 = 0.1; // looksCool
    const w4 = 0.2; // difficulty match

    return (suitability * w1) + (sexyness * w2) + (looksCool * w3) - (diffPenalty * w4);
  }

  /// Finds and filters suitable replacement candidates for a given exercise
  static Future<List<Map<String, dynamic>>> getSwapCandidates(
    Database db,
    String exerciseId,
    SsUserProfile profile, {
    int limit = 5,
  }) async {
    var results = await db.rawQuery('''
      SELECT e.*, s.similarityScore 
      FROM ss_exercise_similarity s
      JOIN ss_exercise e ON s.similarExerciseId = e.id
      WHERE s.exerciseId = ?
      ORDER BY s.similarityScore DESC
    ''', [exerciseId]);

    if (results.isEmpty) {
      final categoryResult = await db.query('ss_exercise', where: 'id = ?', whereArgs: [exerciseId], limit: 1);
      if (categoryResult.isNotEmpty) {
        final category = categoryResult.first['category']?.toString() ?? 'Full Body';
        results = await db.rawQuery('''
          SELECT *, 0.5 as similarityScore
          FROM ss_exercise
          WHERE category = ? AND id != ?
          ORDER BY RANDOM()
          LIMIT 20
        ''', [category, exerciseId]);
      }
    }

    final filtered = results.where((ex) {
      return _isExerciseAllowed(ex, profile.availableEquipment) &&
             _satisfiesLimitations(ex, profile.physicalLimitations) &&
             _satisfiesSkill(ex, profile.experienceLevel);
    }).toList();

    return filtered.take(limit).toList();
  }

  static (int estimatedMinutes, int targetCount) getSessionDefaults(SessionDuration duration) {
    switch (duration) {
      case SessionDuration.short30:
        return (30, 4);
      case SessionDuration.long60:
        return (60, 8);
      case SessionDuration.medium45:
      default:
        return (45, 6);
    }
  }
}
