import 'dart:math';
import 'package:ritmo/core/database/seed/seed_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Utilities for dev seeding and mock data purging.
class MockDataSeeder {
  static Future<void> clearMockData(Database db) async {
    const tablesToClear = [
      'routines', 'routine_schedules', 'routine_occurrences',
      'routine_completions', 'workout_split_days', 'exercises_library',
      'workout_logs', 'workout_set_logs', 'workout_recovery_logs',
      'courses', 'course_sessions',
      'goals', 'goal_steps',
      'konkur_subjects', 'konkur_topics', 'konkur_mock_exams',
      'konkur_mock_exam_results', 'konkur_study_sessions', 'konkur_plan_items',
      'cycle_periods', 'cycle_logs', 'cycle_day_logs',
      'mood_logs', 'daily_checkins', 'daily_reflections', 'energy_logs',
      'worship_practices', 'worship_debts', 'fasting_debt',
      'doctor_visits', 'vaccinations', 'medical_profile',
      'blood_pressure_logs', 'blood_sugar_logs', 'vital_signs_logs',
      'medication_logs',
      'ss_workout_plan', 'ss_workout_exercise_crossref',
      'ss_workout_session_log', 'ss_workout_set_log', 'ss_exercise_feeling_log',
      'ss_user_profile', 'ss_plan_version_history',
    ];
    for (final t in tablesToClear) {
      try {
        await db.delete(t);
      } catch (_) {}
    }
    try {
      await db.delete('app_settings');
    } catch (_) {}
    await SeedService.seedAll(db);
  }

  static Future<void> seed6MonthsData(Database db) async {
    final now = DateTime.now();
    const uuid = Uuid();
    final random = Random(42); // fixed seed for reproducibility

    // ── 0. CLEAN UP existing mock data ─────────────────────────────────────
    const tablesToClear = [
      'routines', 'routine_schedules', 'routine_occurrences',
      'routine_completions', 'workout_split_days', 'exercises_library',
      'workout_logs', 'workout_set_logs', 'workout_recovery_logs',
      'courses', 'course_sessions',
      'goals', 'goal_steps',
      'konkur_subjects', 'konkur_topics', 'konkur_mock_exams',
      'konkur_mock_exam_results', 'konkur_study_sessions',
      'cycle_periods', 'cycle_logs', 'cycle_day_logs',
      'mood_logs', 'daily_checkins', 'daily_reflections', 'energy_logs',
      'worship_practices', 'worship_debts', 'fasting_debt',
      'doctor_visits', 'vaccinations', 'medical_profile',
      'blood_pressure_logs', 'blood_sugar_logs', 'vital_signs_logs',
      'medication_logs',
    ];
    for (final t in tablesToClear) {
      await db.delete(t);
    }

    // ── 1. APP SETTINGS — Elham's profile + all modules active ─────────────
    final profileSettings = {
      'user_name': 'الهام',
      'user_age': '26',
      'user_gender': 'FEMALE',
      'home_city_id': 'TEHRAN_TEHRAN',
      'prayer_city_id': 'TEHRAN_TEHRAN',
      'module_religion_enabled': 'true',
      'module_medicine_enabled': 'true',
      'module_cycle_enabled': 'true',
      'module_konkur_enabled': 'true',
      'module_courses_enabled': 'true',
      'module_goals_enabled': 'true',
      'module_sports_enabled': 'true',
      'module_assistant_enabled': 'true',
      'module_energy_enabled': 'true',
      'module_progressive_habits_enabled': 'true',
      'module_sleep_enabled': 'true',
      'cycle_setup_done': 'true',
      'konkur_setup_done': 'true',
      'sleep_setup_done': 'true',
      'onboarding_complete': 'true',
    };
    for (final e in profileSettings.entries) {
      await db.insert('app_settings', {
        'key': e.key,
        'value': e.value,
        'updatedAt': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── 2. WORSHIP PRACTICES ────────────────────────────────────────────────
    final worshipPractices = [
      {
        'id': 'wp_quran',
        'practiceType': 'QURAN',
        'title': 'تلاوت قرآن',
        'dailyTarget': 2,
        'dailyDone': 2,
        'reminderEnabled': 1,
        'reminderTime': '07:00',
        'reminderFrequency': 'DAILY',
        'reminderAnchor': 'NONE',
        'sortOrder': 0,
        'isActive': 1,
        'allowQada': 0,
        'totalDone': 340,
        'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
      {
        'id': 'wp_dhikr',
        'practiceType': 'DHIKR',
        'title': 'ذکر صبحگاهی',
        'dailyTarget': 100,
        'dailyDone': 100,
        'reminderEnabled': 1,
        'reminderTime': '06:30',
        'reminderFrequency': 'DAILY',
        'reminderAnchor': 'NONE',
        'sortOrder': 1,
        'isActive': 1,
        'allowQada': 0,
        'totalDone': 15800,
        'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
      {
        'id': 'wp_salat_nafila',
        'practiceType': 'MUSTAHAB',
        'subType': 'NAFILA',
        'title': 'نماز نافله ظهر',
        'dailyTarget': 1,
        'dailyDone': 1,
        'reminderEnabled': 1,
        'reminderTime': '12:30',
        'reminderFrequency': 'DAILY',
        'reminderAnchor': 'NONE',
        'sortOrder': 2,
        'isActive': 1,
        'allowQada': 1,
        'totalDone': 120,
        'createdAt': now.subtract(const Duration(days: 150)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
    ];
    for (final wp in worshipPractices) {
      await db.insert('worship_practices', wp,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── 3. WORSHIP DEBTS (قضاء) ─────────────────────────────────────────────
    final worshipDebts = [
      {
        'id': 'debt_fast_ramadan',
        'debtType': 'FAST',
        'title': 'روزه قضاء ماه رمضان',
        'totalCount': 5,
        'remainingCount': 3,
        'dailyTarget': 1,
        'autoCreated': 1,
        'isArchived': 0,
        'createdAt': now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
    ];
    for (final d in worshipDebts) {
      await db.insert('worship_debts', d,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── 4. FASTING DEBT (auto-created from cycle) ───────────────────────────
    await db.insert('fasting_debt', {
      'id': uuid.v4(),
      'dateIso': now.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10),
      'daysOwed': 6,
      'reason': 'قاعدگی',
      'isResolved': 0,
      'createdAt': now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
      'updatedAt': now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // ── 5. ROUTINES (daily/regular) ─────────────────────────────────────────
    final mockRoutines = <Map<String, dynamic>>[
      {
        'id': 'routine_meditation',
        'title': 'مدیتیشن آرامش',
        'description': '۱۰ دقیقه مدیتیشن تنفسی برای تمرکز ذهن',
        'category': 'wellbeing',
        'routineType': 'ROUTINE',
        'notificationLevel': 'NORMAL',
        'isEssential': 0,
        'energyRule': 'NONE',
        'targetDurationMinutes': 10,
        'lightDurationMinutes': 5,
        'minimalDurationMinutes': 3,
        'energyImpact': 1,
        'displayOrder': 0,
        'updatedAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
      },
      {
        'id': 'routine_workout',
        'title': 'تمرین قدرتی بدنسازی',
        'description': 'تمرین برنامه بدنسازی روزانه بر اساس اسپلیت',
        'category': 'fitness',
        'routineType': 'ROUTINE',
        'notificationLevel': 'HIGH',
        'isEssential': 1,
        'energyRule': 'NONE',
        'targetDurationMinutes': 45,
        'lightDurationMinutes': 20,
        'minimalDurationMinutes': 15,
        'energyImpact': -2,
        'displayOrder': 1,
        'updatedAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
      },
      {
        'id': 'routine_reading',
        'title': 'مطالعه کتاب',
        'description': 'مطالعه روزانه برای رشد شخصی',
        'category': 'learning',
        'routineType': 'ROUTINE',
        'notificationLevel': 'NORMAL',
        'isEssential': 0,
        'energyRule': 'NONE',
        'targetDurationMinutes': 30,
        'lightDurationMinutes': 15,
        'minimalDurationMinutes': 10,
        'energyImpact': 1,
        'displayOrder': 2,
        'updatedAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
      },
    ];

    for (final r in mockRoutines) {
      final routineId = r['id'] as String;
      final createdAt = now.subtract(const Duration(days: 180)).millisecondsSinceEpoch;
      await db.insert('routines', {
        ...r,
        'isArchived': 0,
        'isPrivate': 0,
        'itemType': 'ROUTINE',
        'priority': 1.0,
        'createdAt': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await db.insert('routine_schedules', {
        'id': 'sched_$routineId',
        'routineId': routineId,
        'scheduleType': 'DAILY',
        'timeOfDay': '08:00',
        'escalationPolicy': 'NONE',
        'createdAt': createdAt,
        'updatedAt': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── 6. WORKOUT SPLIT DAYS ───────────────────────────────────────────────
    final splitDays = [
      (1, 'CHEST,TRICEPS', 0),
      (2, 'BACK,BICEPS', 0),
      (3, 'SHOULDERS,ABS', 0),
      (4, '', 1),
      (5, 'LEGS', 0),
      (6, 'ABS,CARDIO', 0),
      (7, '', 1),
    ];
    for (final s in splitDays) {
      await db.insert('workout_split_days', {
        'weekday': s.$1,
        'muscleGroups': s.$2,
        'isRest': s.$3,
        'updatedAt': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── 7. EXERCISES LIBRARY ────────────────────────────────────────────────
    final exercises = [
      ('ex_bench', 'پرس سینه', 'CHEST', 'BARBELL'),
      ('ex_squat', 'اسکوات', 'LEGS', 'BARBELL'),
      ('ex_deadlift', 'ددلیفت', 'BACK', 'BARBELL'),
      ('ex_ohp', 'پرس سرشانه', 'SHOULDERS', 'BARBELL'),
      ('ex_row', 'زیربغل هالتر', 'BACK', 'BARBELL'),
      ('ex_curl', 'جلو بازو', 'BICEPS', 'DUMBBELL'),
      ('ex_plank', 'پلانک', 'ABS', 'BODYWEIGHT'),
    ];
    for (final ex in exercises) {
      await db.insert('exercises_library', {
        'id': ex.$1,
        'name': ex.$2,
        'category': ex.$3,
        'equipment': ex.$4,
        'instructions': '۳ ست ۱۰ تایی',
        'isCustom': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── 8. COURSES ──────────────────────────────────────────────────────────
    const courseId = 'course_flutter';
    await db.insert('courses', {
      'id': courseId,
      'title': 'دوره پیشرفته توسعه فلاتر',
      'totalSessions': 60,
      'sessionDurationMinutes': 45,
      'activityType': 'LEARNING',
      'energyRule': 'NONE',
      'courseType': 'VIDEO',
      'weeklyTargetSessions': 3,
      'isAdaptive': 1,
      'preferredDays': '6,1,3',
      'preferredTime': '10:00',
      'reminderEnabled': 1,
      'status': 'ACTIVE',
      'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
      'updatedAt': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    const course2Id = 'course_english';
    await db.insert('courses', {
      'id': course2Id,
      'title': 'زبان انگلیسی پیشرفته',
      'totalSessions': 40,
      'sessionDurationMinutes': 30,
      'activityType': 'LEARNING',
      'energyRule': 'NONE',
      'courseType': 'AUDIO',
      'weeklyTargetSessions': 2,
      'isAdaptive': 0,
      'preferredDays': '2,4',
      'preferredTime': '19:00',
      'reminderEnabled': 1,
      'status': 'ACTIVE',
      'createdAt': now.subtract(const Duration(days: 120)).millisecondsSinceEpoch,
      'updatedAt': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // ── 9. GOALS ────────────────────────────────────────────────────────────
    final goals = [
      {
        'id': 'goal_fitness',
        'title': 'کاهش ۵ کیلوگرم وزن',
        'description': 'رسیدن به وزن ایده‌آل از طریق برنامه ورزشی و تغذیه',
        'goalType': 'HEALTH',
        'status': 'ACTIVE',
        'targetDate': now.add(const Duration(days: 60)).toIso8601String().substring(0, 10),
        'progressCache': 0.6,
        'isPrivate': 0,
        'createdAt': now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
      {
        'id': 'goal_flutter',
        'title': 'تسلط بر Flutter و Dart',
        'description': 'یادگیری کامل فلاتر و ساخت یک اپلیکیشن کامل',
        'goalType': 'SKILL',
        'status': 'ACTIVE',
        'targetDate': now.add(const Duration(days: 90)).toIso8601String().substring(0, 10),
        'progressCache': 0.45,
        'isPrivate': 0,
        'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
      {
        'id': 'goal_reading',
        'title': 'خواندن ۱۲ کتاب در سال',
        'description': 'یک کتاب در ماه برای رشد شخصی و حرفه‌ای',
        'goalType': 'HABIT',
        'status': 'ACTIVE',
        'targetDate': now.add(const Duration(days: 180)).toIso8601String().substring(0, 10),
        'progressCache': 0.5,
        'isPrivate': 0,
        'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
    ];
    for (final g in goals) {
      await db.insert('goals', g, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Goal Steps
    final goalStepsData = [
      ('goal_fitness', [
        ('step_f1', 'ثبت وزن اولیه و تنظیم رژیم', 1, 1),
        ('step_f2', 'انجام تمرین ۳ روز در هفته', 1, 2),
        ('step_f3', 'کاهش مصرف شکر', 1, 3),
        ('step_f4', 'رسیدن به هدف وزنی', 0, 4),
      ]),
      ('goal_flutter', [
        ('step_fl1', 'یادگیری مفاهیم Dart', 1, 1),
        ('step_fl2', 'ساخت اولین Widget', 1, 2),
        ('step_fl3', 'کار با State Management', 1, 3),
        ('step_fl4', 'اتصال به API', 0, 4),
        ('step_fl5', 'انتشار اپ', 0, 5),
      ]),
      ('goal_reading', [
        ('step_r1', 'کتاب اول: اتمیک هبیت', 1, 1),
        ('step_r2', 'کتاب دوم: قانون ۵ ثانیه', 1, 2),
        ('step_r3', 'کتاب سوم: تفکر سریع و آهسته', 1, 3),
        ('step_r4', 'کتاب چهارم: ذهنیت رشد', 1, 4),
        ('step_r5', 'کتاب پنجم: قدرت عادت', 1, 5),
        ('step_r6', 'کتاب ششم: هنر ظریف', 0, 6),
        ('step_r7', 'کتاب هفتم', 0, 7),
      ]),
    ];
    for (final (goalId, steps) in goalStepsData) {
      for (final (id, title, isCompleted, order) in steps) {
        await db.insert('goal_steps', {
          'id': id,
          'goalId': goalId,
          'title': title,
          'isCompleted': isCompleted,
          'displayOrder': order,
          'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // ── 10. KONKUR ──────────────────────────────────────────────────────────
    final konkurSubjects = [
      ('subj_math', 'ریاضی', '#2196F3', 0),
      ('subj_physics', 'فیزیک', '#FF5722', 1),
      ('subj_chemistry', 'شیمی', '#9C27B0', 2),
      ('subj_literature', 'ادبیات فارسی', '#4CAF50', 3),
    ];
    for (final s in konkurSubjects) {
      await db.insert('konkur_subjects', {
        'id': s.$1,
        'name': s.$2,
        'colorHex': s.$3,
        'orderIndex': s.$4,
        'importanceFactor': 1.2,
        'progressPercentage': 55.0 + random.nextDouble() * 30,
        'isArchived': 0,
        'subjectGroup': 'SPECIALIZED',
        'examQuestionCount': 30,
        'isPreset': 1,
        'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final konkurTopics = [
      ('topic_algebra', 'subj_math', 'جبر و معادلات', 'MASTERED'),
      ('topic_calculus', 'subj_math', 'حساب دیفرانسیل', 'LEARNING'),
      ('topic_mechanics', 'subj_physics', 'مکانیک', 'LEARNING'),
      ('topic_electricity', 'subj_physics', 'الکتریسیته', 'STARTED'),
      ('topic_organic', 'subj_chemistry', 'شیمی آلی', 'STARTED'),
      ('topic_poetry', 'subj_literature', 'شعر فارسی', 'MASTERED'),
    ];
    for (final (idx, t) in konkurTopics.indexed) {
      await db.insert('konkur_topics', {
        'id': t.$1,
        'subjectId': t.$2,
        'name': t.$3,
        'masteryLevel': t.$4,
        'progressPercentage': t.$4 == 'MASTERED' ? 90.0 : (t.$4 == 'LEARNING' ? 55.0 : 20.0),
        'studyTargetMinutes': 600,
        'studyCompletedMinutes': t.$4 == 'MASTERED' ? 580 : (t.$4 == 'LEARNING' ? 330 : 120),
        'orderIndex': idx,
        'examQuestionCount': 10,
        'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final konkurExams = [
      ('mock_1', 'آزمون آزمایشی جامع سنجش ۱', 'سنجش', 120),
      ('mock_2', 'آزمون آزمایشی گزینه دو ۲', 'گزینه دو', 60),
      ('mock_3', 'آزمون آزمایشی قلم‌چی ۳', 'قلم‌چی', 15),
    ];
    for (final exam in konkurExams) {
      final examTs = now.subtract(Duration(days: exam.$4));
      await db.insert('konkur_mock_exams', {
        'id': exam.$1,
        'title': exam.$2,
        'provider': exam.$3,
        'examDate': examTs.toIso8601String().substring(0, 10),
        'createdAt': examTs.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await db.insert('konkur_mock_exam_results', {
        'id': uuid.v4(),
        'mockExamId': exam.$1,
        'subjectId': 'subj_math',
        'percentage': 70.0 + random.nextDouble() * 20,
        'correctAnswers': 22 + random.nextInt(6),
        'wrongAnswers': 3 + random.nextInt(4),
        'emptyAnswers': random.nextInt(3),
        'totalQuestions': 30,
        'createdAt': examTs.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── 11. MEDICAL — Medication routine ────────────────────────────────────
    const medicationRoutineId = 'routine_medication_omega3';
    await db.insert('routines', {
      'id': medicationRoutineId,
      'title': 'قرص امگا ۳',
      'description': 'مکمل امگا ۳ برای سلامت قلب',
      'category': 'medical',
      'routineType': 'ROUTINE',
      'notificationLevel': 'HIGH',
      'isEssential': 1,
      'energyRule': 'NONE',
      'priority': 1.0,
      'targetDurationMinutes': 1,
      'lightDurationMinutes': 1,
      'minimalDurationMinutes': 1,
      'energyImpact': 0,
      'displayOrder': 10,
      'isArchived': 0,
      'isPrivate': 0,
      'itemType': 'ROUTINE',
      'medStockCount': 60,
      'medRefillThreshold': 10,
      'createdAt': now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
      'updatedAt': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('routine_schedules', {
      'id': 'sched_$medicationRoutineId',
      'routineId': medicationRoutineId,
      'scheduleType': 'DAILY',
      'timeOfDay': '08:00',
      'escalationPolicy': 'NONE',
      'createdAt': now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
      'updatedAt': now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Medical profile
    final medProfile = {
      'blood_type': 'A+',
      'height_cm': '165',
      'weight_kg': '58',
      'allergies': 'پنی‌سیلین',
      'chronic_conditions': 'ندارد',
      'emergency_contact': '09121234567',
    };
    for (final e in medProfile.entries) {
      await db.insert('medical_profile', {
        'id': uuid.v4(),
        'profileKey': e.key,
        'profileValue': e.value,
        'updatedAt': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Doctor visits
    final doctorVisits = [
      {
        'id': uuid.v4(),
        'doctorName': 'دکتر سعیدی',
        'specialty': 'متخصص زنان',
        'clinicName': 'کلینیک شفا',
        'visitDateTime': now.subtract(const Duration(days: 45)).millisecondsSinceEpoch,
        'visitType': 'IN_PERSON',
        'status': 'COMPLETED',
        'reason': 'معاینه دوره‌ای',
        'doctorNotes': 'سالم است. ادامه مصرف امگا ۳ توصیه شد.',
        'reminderBefore': 60,
        'createdAt': now.subtract(const Duration(days: 50)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
      {
        'id': uuid.v4(),
        'doctorName': 'دکتر محمدی',
        'specialty': 'عمومی',
        'clinicName': 'درمانگاه نور',
        'visitDateTime': now.add(const Duration(days: 15)).millisecondsSinceEpoch,
        'visitType': 'IN_PERSON',
        'status': 'UPCOMING',
        'reason': 'آزمایش خون دوره‌ای',
        'reminderBefore': 60,
        'createdAt': now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
    ];
    for (final v in doctorVisits) {
      await db.insert('doctor_visits', v,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Vaccinations
    await db.insert('vaccinations', {
      'id': uuid.v4(),
      'vaccineName': 'فلو (آنفلوانزا)',
      'diseaseTarget': 'آنفلوانزا',
      'doseNumber': 1,
      'totalDoses': 1,
      'dateAdministered': now.subtract(const Duration(days: 120)).millisecondsSinceEpoch,
      'nextDoseDue': now.add(const Duration(days: 245)).millisecondsSinceEpoch,
      'clinicName': 'داروخانه مرکزی',
      'notes': 'واکسن سالانه',
      'createdAt': now.subtract(const Duration(days: 120)).millisecondsSinceEpoch,
      'updatedAt': now.subtract(const Duration(days: 120)).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // ── 12. DAILY LOOP — 180 days of historical data ─────────────────────────
    var sessionIdx = 1;

    // Prepare irregular cycle schedule
    final cycleStartDays = <int>[];
    var currentOffset = 0;
    while (currentOffset < 180) {
      cycleStartDays.add(currentOffset);
      currentOffset += 26 + random.nextInt(5); // 26–30 day cycles
    }

    final dailyBatch = db.batch();
    for (var i = 180; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final timestamp = date.millisecondsSinceEpoch;
      final weekday = date.weekday;
      final moodVal = 3 + random.nextInt(3); // 3–5

      // A. Mood logs
      dailyBatch.insert('mood_logs', {
        'id': uuid.v4(),
        'mood': ['GOOD', 'GREAT', 'NEUTRAL', 'GOOD', 'GREAT'][random.nextInt(5)],
        'valence': moodVal,
        'note': 'ثبت روزانه',
        'loggedAt': timestamp,
      });

      // B. Daily checkins
      dailyBatch.insert('daily_checkins', {
        'id': uuid.v4(),
        'date': dateStr,
        'mood': 'GOOD',
        'createdAt': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // C. Energy logs (every other day)
      if (i % 2 == 0) {
        dailyBatch.insert('energy_logs', {
          'id': uuid.v4(),
          'energyLevel': ['LOW', 'MEDIUM', 'HIGH', 'HIGH', 'MEDIUM'][random.nextInt(5)],
          'source': 'MANUAL',
          'loggedAt': timestamp,
        });
      }

      // D. Daily reflections (every 3 days)
      if (i % 3 == 0) {
        dailyBatch.insert('daily_reflections', {
          'id': uuid.v4(),
          'date': dateStr,
          'reflection_text': 'امروز تمرکز خوبی داشتم و روتین‌ها را کامل کردم.',
          'reflectionNote': 'کمی خستگی احساس کردم ولی انگیزه بالا بود.',
          'mood_score': moodVal,
          'wins': 'تمام روتین‌ها انجام شد.',
          'isPrivate': 0,
          'timestamp': timestamp,
          'createdAt': timestamp,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // E. Routine completions (80% rate)
      for (final r in mockRoutines) {
        final completed = random.nextDouble() < 0.8;
        dailyBatch.insert('routine_occurrences', {
          'routine_id': r['id'],
          'date': dateStr,
          'scheduled_time': '08:00',
          'status': completed ? 'completed' : 'pending',
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        if (completed) {
          dailyBatch.insert('routine_completions', {
            'id': uuid.v4(),
            'routineId': r['id'],
            'completionDate': dateStr,
            'completionTime': timestamp,
            'resultType': 'COMPLETED',
            'resultSource': 'USER',
            'durationMinutes': r['targetDurationMinutes'],
            'delayMinutes': random.nextInt(10),
            'createdAt': timestamp,
          });
        }
      }

      // F. Workout logs (Mon/Wed/Fri = weekday 1, 3, 5)
      if (weekday == 1 || weekday == 3 || weekday == 5) {
        final workoutId = uuid.v4();
        final muscle = weekday == 1
            ? 'CHEST,TRICEPS'
            : (weekday == 3 ? 'BACK,BICEPS' : 'LEGS');
        dailyBatch.insert('workout_logs', {
          'id': workoutId,
          'type': 'STRENGTH',
          'durationMinutes': 40 + random.nextInt(20),
          'intensity': 'HIGH',
          'note': 'تمرین قدرتی',
          'loggedAt': timestamp,
          'muscleGroups': muscle,
          'feeling': ['GREAT', 'GOOD', 'OKAY'][random.nextInt(3)],
        });

        final exId = weekday == 5 ? 'ex_squat' : 'ex_bench';
        for (var s = 1; s <= 3; s++) {
          dailyBatch.insert('workout_set_logs', {
            'id': uuid.v4(),
            'workoutLogId': workoutId,
            'exerciseId': exId,
            'setIndex': s,
            'weight': 55.0 + (s * 5.0),
            'reps': 8 + random.nextInt(4),
            'isCompleted': 1,
          });
        }

        dailyBatch.insert('workout_recovery_logs', {
          'id': uuid.v4(),
          'date': dateStr,
          'soreness': random.nextInt(3) + 1,
          'fatigue': random.nextInt(3) + 1,
          'hydration': 2,
          'soreMuscleGroups': muscle,
          'loggedAt': timestamp,
        });
      }

      // G. Course sessions (Sat/Mon/Wed = weekday 6, 1, 3)
      if (weekday == 6 || weekday == 1 || weekday == 3) {
        dailyBatch.insert('course_sessions', {
          'id': uuid.v4(),
          'courseId': sessionIdx % 3 == 0 ? course2Id : courseId,
          'sessionNumber': sessionIdx++,
          'plannedDate': dateStr,
          'completionStatus': 'COMPLETED',
          'actualDurationMinutes': 40 + random.nextInt(15),
          'sessionTitle': 'جلسه $sessionIdx',
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
      }

      // H. Konkur study sessions (every other day)
      if (i % 2 == 0) {
        dailyBatch.insert('konkur_study_sessions', {
          'id': uuid.v4(),
          'topicId': konkurTopics[random.nextInt(konkurTopics.length)].$1,
          'subjectId': konkurSubjects[random.nextInt(konkurSubjects.length)].$1,
          'dateIso': dateStr,
          'durationMinutes': 60 + random.nextInt(60),
          'mode': 'STUDY',
          'testsTotal': 20 + random.nextInt(20),
          'testsCorrect': 14 + random.nextInt(8),
          'testsWrong': random.nextInt(4),
          'testsBlank': random.nextInt(3),
          'createdAt': timestamp,
        });
      }

      // I. Medication logs
      dailyBatch.insert('medication_logs', {
        'id': uuid.v4(),
        'routineId': medicationRoutineId,
        'scheduledTime': timestamp,
        'takenTime': timestamp + 300000,
        'status': random.nextDouble() < 0.9 ? 'TAKEN' : 'SKIPPED',
        'createdAt': timestamp,
      });

      // J. Blood pressure logs (weekly)
      if (i % 7 == 0) {
        dailyBatch.insert('blood_pressure_logs', {
          'id': uuid.v4(),
          'systolic': 110 + random.nextInt(15),
          'diastolic': 70 + random.nextInt(10),
          'pulse': 68 + random.nextInt(12),
          'arm': 'LEFT',
          'position': 'SITTING',
          'loggedAt': timestamp,
        });
      }

      // K. Vital signs (weight, weekly)
      if (i % 7 == 0) {
        dailyBatch.insert('vital_signs_logs', {
          'id': uuid.v4(),
          'vitalType': 'WEIGHT',
          'value': 58.5 - (i / 180.0) * 3.0, // gradual weight loss
          'unit': 'kg',
          'loggedAt': timestamp,
        });
      }
    }
    await dailyBatch.commit(noResult: true);

    // ── 13. CYCLE DATA (irregular but realistic full cycle logs) ─────────────
    final cycleBatch = db.batch();
    for (var i = 0; i < cycleStartDays.length; i++) {
      final startDay = cycleStartDays[i];
      final cycleDays = i > 0 ? (startDay - cycleStartDays[i - 1]) : 28;

      final startDate = now.subtract(Duration(days: startDay));
      final startDateStr = startDate.toIso8601String().substring(0, 10);
      final bleedingDays = 5 + random.nextInt(3); // 5–7 days
      final endDate = startDate.add(Duration(days: bleedingDays));
      final endDateStr = endDate.toIso8601String().substring(0, 10);
      final ts = startDate.millisecondsSinceEpoch;

      cycleBatch.insert('cycle_periods', {
        'id': uuid.v4(),
        'startDate': startDateStr,
        'endDate': startDay == 0 ? null : endDateStr,
        'flowIntensity': 'MEDIUM',
        'isPredicted': 0,
        'note': 'چرخه طبیعی',
        'createdAt': ts,
        'updatedAt': ts,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      cycleBatch.insert('cycle_logs', {
        'id': uuid.v4(),
        'cycleStartDate': startDateStr,
        'cycleEndDate': startDay == 0 ? null : endDateStr,
        'phase': 'MENSTRUATION',
        'flowLevel': 'MEDIUM',
        'symptomsJson': '["cramps","fatigue"]',
        'isPredicted': 0,
        'suppressedPrayer': 1,
        'fastDebtCreated': 1,
        'createdAt': ts,
        'updatedAt': ts,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (var d = 0; d < cycleDays; d++) {
        final logDate = startDate.add(Duration(days: d));
        // Don't seed future dates
        if (logDate.isAfter(now)) continue;

        var flowLevel = 'NONE';
        var symptomsJson = '[]';
        var mood = 'NEUTRAL';
        var energyTag = 'MEDIUM';
        var note = 'روزهای عادی چرخه';

        if (d < bleedingDays) {
          flowLevel = d < 2 ? 'HEAVY' : (d < 5 ? 'MEDIUM' : 'LIGHT');
          symptomsJson = d % 3 == 0 ? '["cramps"]' : '[]';
          mood = d < 3 ? 'IRRITABLE' : 'SAD';
          energyTag = 'LOW';
          note = 'روزهای خونریزی';
        } else if (d >= 12 && d <= 15) {
          // Ovulation
          symptomsJson = d == 13 ? '["bloating"]' : '[]';
          mood = 'HAPPY';
          energyTag = 'HIGH';
          note = 'دوره باروری و تخمک‌گذاری';
        } else if (d >= 24 && d <= 27) {
          // PMS/Luteal
          symptomsJson = d == 25 ? '["headache"]' : (d == 27 ? '["fatigue"]' : '[]');
          mood = 'ANXIOUS';
          energyTag = 'LOW';
          note = 'سندروم پیش از قاعدگی';
        }

        cycleBatch.insert('cycle_day_logs', {
          'id': uuid.v4(),
          'logDate': logDate.toIso8601String().substring(0, 10),
          'flowLevel': flowLevel,
          'symptomsJson': symptomsJson,
          'mood': mood,
          'energyTag': energyTag,
          'note': note,
          'createdAt': logDate.millisecondsSinceEpoch,
          'updatedAt': logDate.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await cycleBatch.commit(noResult: true);
  }

  static Future<void> clearAllData(Database db) async {
    const tablesToClear = [
      'routines', 'routine_schedules', 'routine_occurrences',
      'routine_completions', 'workout_split_days', 'exercises_library',
      'workout_logs', 'workout_set_logs', 'workout_recovery_logs',
      'courses', 'course_sessions',
      'goals', 'goal_steps',
      'konkur_subjects', 'konkur_topics', 'konkur_mock_exams',
      'konkur_mock_exam_results', 'konkur_study_sessions',
      'cycle_periods', 'cycle_logs', 'cycle_day_logs',
      'mood_logs', 'daily_checkins', 'daily_reflections', 'energy_logs',
      'worship_practices', 'worship_debts', 'fasting_debt',
      'doctor_visits', 'vaccinations', 'medical_profile',
      'blood_pressure_logs', 'blood_sugar_logs', 'vital_signs_logs',
      'medication_logs', 'app_settings',
    ];
    for (final t in tablesToClear) {
      try {
        await db.delete(t);
      } catch (_) {}
    }
  }
}
