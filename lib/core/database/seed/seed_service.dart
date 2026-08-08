import 'dart:convert';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:ritmo/features/supplementary_sports/data/seed/ss_exercise_animation_map.dart';
import 'package:ritmo/features/supplementary_sports/data/seed/ss_exercise_farsi_names.dart';
import 'package:ritmo/features/supplementary_sports/movement/data/seed/movement_kinds_seed.dart';
import 'package:sqflite/sqflite.dart';

class SeedService {
  static Future<void> seedAll(Database db) async {
    await seedSettings(db);
    await seedWorshipPractices(db);
    await seedIranCities(db);
    await seedSupplementarySports(db);
    await MovementKindsSeed.seed(db);
  }

  static Future<void> seedSettings(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaultSettings = {
      'gentleness_level': 'NORMAL',
      'theme': 'DARK',
      'streak_threshold': '50',
      'energy_validity_minutes': '180',
      'default_energy_level': 'MEDIUM',
      'digest_mode': 'false',
      'coalescing_window_minutes': '10',
      'max_non_essential_per_hour': '3',
      'max_grace_per_week': '1',
      'max_grace_per_month': '3',
      'max_defer_count': '2',
      'daily_capacity_minutes': '360',
      'app_lock_mode': 'OFF',
      'app_lock_timeout_seconds': '300',
      'user_gender': 'UNSET',
      'prayer_calculation_method': 'TEHRAN_GEOPHYSICS',
      'ihtiyat_minutes': '0',
      'home_city_id': 'TEHRAN_TEHRAN',
      'current_streak': '0',
      'longest_streak': '0',
      'last_success_date': '',
      'assistant_cloud_consent': 'false',
      // Psychology layer settings (§3 T-A5)
      'motivation_diagnosis_enabled': 'true',
      'daily_budget_warning_enabled': 'true',
      'wip_limit_enabled': 'true',
      'wip_limit_count': '3',
      'cognitive_routing_enabled': 'false',
      'fresh_start_enabled': 'true',
      'capture_inbox_enabled': 'true',
      'mastery_pleasure_sampling_enabled': 'false',
      'mastery_decay_enabled': 'true',
      // Module flags (default false)
      'module_religion_enabled': 'true',
      'prayer_city_id': 'TEHRAN_TEHRAN',
      'module_medicine_enabled': 'false',
      'module_cycle_enabled': 'false',
      'module_study_enabled': 'false',
      'module_courses_enabled': 'false',
      'module_goals_enabled': 'false',
      'module_progressive_habits_enabled': 'false',
      'module_assistant_enabled': 'false',
      'module_health_enabled': 'true',
      'module_energy_enabled': 'false',
      'module_sports_enabled': 'false',
      'module_supplementary_sports_enabled': 'false',
      'patient_has_diabetes': 'false',
      'module_pregnancy_enabled': 'false',
      'patient_has_hypertension': 'false',
      'cycle_avg_length': '28',
      'cycle_avg_period': '6',
      'cycle_biometric_enabled': 'false',
      'cycle_setup_done': 'false',
      'cycle_consent_energy': 'false',
      'cycle_consent_reminders': 'false',
      'cycle_consent_worship': 'false',
      'cycle_consent_dashboard': 'false',
      'konkur_field': 'UNSET',
      'konkur_exam_date': '',
      'konkur_setup_done': 'false',
      'konkur_daily_target_minutes': '180',
      'konkur_show_in_dashboard': 'true',
      'module_sleep_enabled': 'false',
      'sleep_target_bedtime': '23:30',
      'sleep_target_wake': '07:00',
      'sleep_target_duration_minutes': '450',
      'sleep_winddown_reminder': 'false',
      'sleep_winddown_minutes': '30',
      'sleep_setup_done': 'false',
      'assistant_briefing_enabled': 'true',
      'assistant_proactive_enabled': 'true',
      'cycle_consent_sleep': 'false',
      'cycle_fertility_visible': 'false',
      'cycle_pms_window_days': '4',
      'cycle_length_days': '28',
      'period_duration_days': '6',
      'cycle_pregnancy_mode': 'false',
      'cycle_pregnancy_start_date': '',
      'cycle_pregnancy_due_date': '',
      'reflection_reminder_enabled': 'true',
      'reflection_prompt_style': 'structured',
      'health_adherence_enabled': 'true',
      'health_trend_window_days': '30',
      'show_cycle_in_calendar': 'false',
    };

    final batch = db.batch();
    defaultSettings.forEach((key, value) {
      batch.insert('app_settings', {
        'key': key,
        'value': value,
        'updatedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
    await batch.commit(noResult: true);
  }

  static Future<void> seedWorshipPractices(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final prayers = [
      {
        'id': 'wp_fajr',
        'practiceType': 'PRAYER',
        'subType': 'FAJR',
        'title': 'نماز صبح',
        'dailyTarget': 1,
        'dailyDone': 0,
        'reminderEnabled': 1,
        'reminderOffsetMinutes': 10,
        'sortOrder': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'wp_dhuhr',
        'practiceType': 'PRAYER',
        'subType': 'DHUHR',
        'title': 'نماز ظهر و عصر',
        'dailyTarget': 1,
        'dailyDone': 0,
        'reminderEnabled': 1,
        'reminderOffsetMinutes': 15,
        'sortOrder': 2,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'wp_maghrib',
        'practiceType': 'PRAYER',
        'subType': 'MAGHRIB',
        'title': 'نماز مغرب و عشا',
        'dailyTarget': 1,
        'dailyDone': 0,
        'reminderEnabled': 1,
        'reminderOffsetMinutes': 5,
        'sortOrder': 4,
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (final p in prayers) {
      await db.insert('worship_practices', p, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> seedIranCities(Database db) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/iran_cities.json');
      final rawList = jsonDecode(jsonStr) as List<dynamic>;
      final list = rawList.cast<Map<String, dynamic>>();
      final batch = db.batch();
      for (final city in list) {
        batch.insert('iran_cities', city.cast<String, Object?>(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // Safe fallback for tests
    }
  }

  static Future<void> seedSupplementarySports(Database db) async {
    try {
      var shouldForceReseed = false;
      try {
        final reseedQuery = await db.query(
          'app_settings',
          where: 'key = ?',
          whereArgs: ['ss_reseed_v38'],
        );
        if (reseedQuery.isNotEmpty && reseedQuery.first['value'].toString() == 'true') {
          shouldForceReseed = true;
        }
      } catch (_) {}

      if (shouldForceReseed) {
        await db.delete('ss_exercise', where: 'isCustom = 0');
        await db.delete('ss_workout_set');
        await db.delete('ss_exercise_set_suitability');
      }

      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM ss_exercise');
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count >= 250 && !shouldForceReseed) {
        return;
      }

      // 1. Seed workout sets
      final workoutSets = [
        {
          'id': 'insane_six_pack',
          'code': 'insane_six_pack',
          'title_fa': 'شکم شش‌تکه',
          'description_fa': 'تمرینات فشرده و هدفمند برای ساختن عضلات شکم شش‌تکه و قوی.',
          'icon': 'insane_six_pack',
          'focus': jsonEncode({'core': 10}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 1,
        },
        {
          'id': 'complex_core',
          'code': 'complex_core',
          'title_fa': 'تقویت هسته بدن',
          'description_fa': 'ثبات و استحکام بخش میانی بدن برای بهبود قامت و تعادل.',
          'icon': 'complex_core',
          'focus': jsonEncode({'core': 8, 'balance': 2}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 2,
        },
        {
          'id': 'light_cardio',
          'code': 'light_cardio',
          'title_fa': 'کاردیو سبک',
          'description_fa': 'تمرینی هوازی و ملایم برای بهبود سلامت قلب و چربی‌سوزی ملایم.',
          'icon': 'light_cardio',
          'focus': jsonEncode({'cardio': 10}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 3,
        },
        {
          'id': 'low_impact',
          'code': 'low_impact',
          'title_fa': 'کم‌فشار (حفاظت مفاصل)',
          'description_fa': 'تمرینات ملایم و ایمن، بدون فشار مضاعف بر روی مفاصل زانو و کمر.',
          'icon': 'low_impact',
          'focus': jsonEncode({'cardio': 6, 'stretching': 4}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 4,
        },
        {
          'id': 'balance',
          'code': 'balance',
          'title_fa': 'تمرین تعادل',
          'description_fa': 'افزایش تمرکز ذهنی‌عضلانی و بهبود تعادل و پایداری بدن.',
          'icon': 'balance',
          'focus': jsonEncode({'balance': 10}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 5,
        },
        {
          'id': 'a_upper_body',
          'code': 'a_upper_body',
          'title_fa': 'بالاتنه قدرتمند',
          'description_fa': 'تقویت و فرم‌دهی به عضلات سینه، بازوها، شانه و پشت.',
          'icon': 'a_upper_body',
          'focus': jsonEncode({'upper_body': 8, 'shoulder_and_back': 2}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 6,
        },
        {
          'id': 'b_lower_body',
          'code': 'b_lower_body',
          'title_fa': 'پایین‌تنه آهنین',
          'description_fa': 'تقویت عضلات پا، باسن و همسترینگ با تمرینات تخصصی پایین‌تنه.',
          'icon': 'b_lower_body',
          'focus': jsonEncode({'lower_body': 10}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 7,
        },
        {
          'id': 'healthy_posture',
          'code': 'healthy_posture',
          'title_fa': 'اصلاح قامت و ستون فقرات',
          'description_fa': 'بهبود راستای قامت و پیشگیری از قوز کمر و دردهای ناشی از پشت‌میزنشینی.',
          'icon': 'healthy_posture',
          'focus': jsonEncode({'shoulder_and_back': 6, 'stretching': 4}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 8,
        },
        {
          'id': 'healthy_posture_more_stretching',
          'code': 'healthy_posture_more_stretching',
          'title_fa': 'کشش و انعطاف قامت',
          'description_fa': 'تمرکز ویژه روی کشش عضلات سفت‌شده پشت و گردن برای آرامش بیشتر.',
          'icon': 'healthy_posture_more_stretching',
          'focus': jsonEncode({'stretching': 8, 'shoulder_and_back': 2}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 9,
        },
        {
          'id': 'lose_belly',
          'code': 'lose_belly',
          'title_fa': 'آب کردن شکم و پهلو',
          'description_fa': 'ترکیب حرکات هوازی و شکمی برای کاهش چربی‌های ناحیه میانی بدن.',
          'icon': 'lose_belly',
          'focus': jsonEncode({'core': 6, 'cardio': 4}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 10,
        },
        {
          'id': 'obliques',
          'code': 'obliques',
          'title_fa': 'عضلات مورب شکم',
          'description_fa': 'فرم‌دهی به بخش‌های جانبی شکم و ساختن خط کمر زیبا.',
          'icon': 'obliques',
          'focus': jsonEncode({'core': 10}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 11,
        },
        {
          'id': 'full_body',
          'code': 'full_body',
          'title_fa': 'تمام بدن (فول بادی)',
          'description_fa': 'تمرین همه‌جانبه برای درگیر کردن تمام عضلات اصلی بدن در یک جلسه.',
          'icon': 'full_body',
          'focus': jsonEncode({'lower_body': 3, 'upper_body': 3, 'core': 2, 'cardio': 2}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 12,
        },
        {
          'id': 'hiit',
          'code': 'hiit',
          'title_fa': 'تمرینات اینتروال (HIIT)',
          'description_fa': 'تمرینات شدید متناوب برای چربی‌سوزی حداکثری و افزایش استقامت در زمان کوتاه.',
          'icon': 'hiit',
          'focus': jsonEncode({'cardio': 6, 'plyometric': 4}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 13,
        },
        {
          'id': 'sprint_cardio',
          'code': 'sprint_cardio',
          'title_fa': 'کاردیو سرعتی',
          'description_fa': 'تمرینات سرعتی و چالشی برای انفجار کالری و افزایش قدرت هوازی.',
          'icon': 'sprint_cardio',
          'focus': jsonEncode({'cardio': 8, 'plyometric': 2}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 14,
        },
        {
          'id': 'tabata',
          'code': 'tabata',
          'title_fa': 'پروتکل تاباتا',
          'description_fa': 'سیستم چربی‌سوزی فوق‌العاده ۲۰ ثانیه کار شدید و ۱۰ ثانیه استراحت.',
          'icon': 'tabata',
          'focus': jsonEncode({'cardio': 5, 'plyometric': 5}),
          'difficulty_levels': 3,
          'is_female_oriented': 0,
          'sort_order': 15,
        },
        {
          'id': 'fem_rounds',
          'code': 'fem_rounds',
          'title_fa': 'تمرین فرم‌دهی بانوان',
          'description_fa': 'حرکات ویژه متمرکز بر خوش‌فرمی پایین‌تنه و شکم مناسب آناتومی بانوان.',
          'icon': 'fem_rounds',
          'focus': jsonEncode({'lower_body': 5, 'core': 5}),
          'difficulty_levels': 3,
          'is_female_oriented': 1,
          'sort_order': 16,
        },
        {
          'id': 'fem_hiit',
          'code': 'fem_hiit',
          'title_fa': 'کاردیو فشرده بانوان',
          'description_fa': 'چربی‌سوزی و تقویت سیستم ایمنی با متد HIIT متناسب با توانایی بانوان.',
          'icon': 'fem_hiit',
          'focus': jsonEncode({'cardio': 7, 'lower_body': 3}),
          'difficulty_levels': 3,
          'is_female_oriented': 1,
          'sort_order': 17,
        },
        {
          'id': 'fem_interval_training',
          'code': 'fem_interval_training',
          'title_fa': 'تمرینات دوره‌ای بانوان',
          'description_fa': 'بهبود تناسب اندام و سفت شدن عضلات بدون افزایش حجم غیرعادی.',
          'icon': 'fem_interval_training',
          'focus': jsonEncode({'lower_body': 4, 'upper_body': 3, 'core': 3}),
          'difficulty_levels': 3,
          'is_female_oriented': 1,
          'sort_order': 18,
        },
        {
          'id': 'fem_tabata',
          'code': 'fem_tabata',
          'title_fa': 'تاباتا اختصاصی بانوان',
          'description_fa': 'تمرین پرانرژی و چربی‌سوز تاباتا برای خوش‌فرمی اندام بانوان.',
          'icon': 'fem_tabata',
          'focus': jsonEncode({'cardio': 6, 'plyometric': 4}),
          'difficulty_levels': 3,
          'is_female_oriented': 1,
          'sort_order': 19,
        },
      ];

      final setBatch = db.batch();
      for (final ws in workoutSets) {
        setBatch.insert('ss_workout_set', ws, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await setBatch.commit(noResult: true);

      // 2. Seed exercises
      final exercisesJsonStr = await rootBundle.loadString('assets/data/fitify_exercises_bodyweight.json');
      final exercisesData = await compute(jsonDecode, exercisesJsonStr) as Map<String, dynamic>;
      final exercisesList = exercisesData['exercises'] as List<dynamic>;

      final batch = db.batch();
      final suitabilityBatch = db.batch();

      for (final item in exercisesList) {
        if (item is Map<String, dynamic>) {
          final id = item['code']?.toString() ?? '';
          final nameEn = item['title']?.toString() ?? '';
          
          final farsiInfo = SsExerciseFarsiNames.names[id];
          final name = farsiInfo?['title_fa'] ?? _translateToPersian(nameEn);
          final instructions = farsiInfo?['desc_fa'] ?? '';

          var category = 'Full Body';
          final catMap = item['category'] is Map<String, dynamic> ? item['category'] as Map<String, dynamic> : <String, dynamic>{};
          
          var maxVal = -1;
          catMap.forEach((key, val) {
            if (val is num && val > maxVal) {
              maxVal = val.toInt();
              category = key.toString();
            }
          });

          final catCardio = catMap['cardio'] as int? ?? 0;
          final catPlyometric = catMap['plyometric'] as int? ?? 0;
          final catLowerBody = catMap['lower_body'] as int? ?? 0;
          final catUpperBody = catMap['upper_body'] as int? ?? 0;
          final catShoulderAndBack = catMap['shoulder_and_back'] as int? ?? 0;
          final catCore = catMap['core'] as int? ?? 0;
          final catStretching = catMap['stretching'] as int? ?? 0;
          final catYoga = catMap['yoga'] as int? ?? 0;
          final catBalance = catMap['balance'] as int? ?? 0;
          final catWarmup = catMap['warmup'] as int? ?? 0;

          final equipment = item['tool']?.toString();
          final videoUrl = item['youtube']?.toString();

          final mappedAnim = ssExerciseAnimationMap[id];
          final animationAsset = mappedAnim != null ? 'assets/animations/custom/$mappedAnim.json' : null;

          final changeSides = item['change_sides'] == true ? 1 : 0;
          final noisy = item['noisy'] is num ? (item['noisy'] as num).toInt() : 0;
          final impact = item['impact'] is num ? (item['impact'] as num).toInt() : 0;
          final repsDouble = item['reps_double'] == true ? 1 : 0;
          
          final repDurationLow = item['rep_duration_low'] is num ? (item['rep_duration_low'] as num).toDouble() : 2.0;
          final repDurationMedium = item['rep_duration_medium'] is num ? (item['rep_duration_medium'] as num).toDouble() : 3.0;
          final repDurationHigh = item['rep_duration_high'] is num ? (item['rep_duration_high'] as num).toDouble() : 4.0;
          
          final sexynessMale = item['sexyness_m'] is num ? (item['sexyness_m'] as num).toDouble() : 5.0;
          final sexynessFemale = item['sexyness_f'] is num ? (item['sexyness_f'] as num).toDouble() : 5.0;
          final isolatedVsCompound = item['isolated_vs_compound'] is num ? (item['isolated_vs_compound'] as num).toDouble() : 0.0;
          final durationSeconds = item['duration'] is num ? (item['duration'] as num).toInt() : 30;
          final defaultReps = item['reps'] is num ? (item['reps'] as num).toInt() : 10;
          final repsHint = item['reps_hint']?.toString();
          
          final toolsRequired = jsonEncode(item['tools_required'] ?? []);
          final constraintNegative = item['constraint_negative']?.toString();
          final weightSupported = item['weight_supported'] == true ? 1 : 0;
          final weightPerHand = item['weight_per_hand'] == true ? 1 : 0;
          final muscleIntensity = jsonEncode(item['muscle_intensity'] ?? {});
          
          final skillRequired = item['skill_required'] is num ? (item['skill_required'] as num).toInt() : 0;
          final skillMax = item['skill_max'] is num ? (item['skill_max'] as num).toInt() : 10;
          
          final strengthVsCardio = item['strength_vs_cardio'] is num ? (item['strength_vs_cardio'] as num).toDouble() : 50.0;
          final machineVsFreeweight = item['machine_vs_freeweight'] is num ? (item['machine_vs_freeweight'] as num).toDouble() : 0.0;
          final looksCool = item['looks_cool'] is num ? (item['looks_cool'] as num).toInt() : 0;
          final stance = item['stance']?.toString();

          batch.insert('ss_exercise', {
            'id': id,
            'name': name,
            'nameEn': nameEn,
            'category': category,
            'equipment': equipment,
            'instructions': instructions,
            'videoUrl': videoUrl,
            'isCustom': 0,
            'changeSides': changeSides,
            'noisy': noisy,
            'impact': impact,
            'repsDouble': repsDouble,
            'repDurationLow': repDurationLow,
            'repDurationMedium': repDurationMedium,
            'repDurationHigh': repDurationHigh,
            'sexynessMale': sexynessMale,
            'sexynessFemale': sexynessFemale,
            'isolatedVsCompound': isolatedVsCompound,
            'durationSeconds': durationSeconds,
            'defaultReps': defaultReps,
            'repsHint': repsHint,
            'toolsRequired': toolsRequired,
            'constraintNegative': constraintNegative,
            'weightSupported': weightSupported,
            'weightPerHand': weightPerHand,
            'muscleIntensity': muscleIntensity,
            'skillRequired': skillRequired,
            'strengthVsCardio': strengthVsCardio,
            'machineVsFreeweight': machineVsFreeweight,
            'looksCool': looksCool,
            'stance': stance,
            
            // New columns
            'code': id,
            'cat_cardio': catCardio,
            'cat_plyometric': catPlyometric,
            'cat_lower_body': catLowerBody,
            'cat_upper_body': catUpperBody,
            'cat_shoulder_and_back': catShoulderAndBack,
            'cat_core': catCore,
            'cat_stretching': catStretching,
            'cat_yoga': catYoga,
            'cat_balance': catBalance,
            'cat_warmup': catWarmup,
            'skill_max': skillMax,
            'sexyness_m': item['sexyness_m'] as int? ?? 5,
            'sexyness_f': item['sexyness_f'] as int? ?? 5,
            'animation_asset': animationAsset,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // 3. Suitability seeding for this exercise
          final setsMap = item['sets'] is Map<String, dynamic> ? item['sets'] as Map<String, dynamic> : <String, dynamic>{};
          setsMap.forEach((setCode, setVal) {
            if (setVal is Map<String, dynamic>) {
              final suitability = setVal['suitability'] as int? ?? 0;
              final suitabilityLowerbody = setVal['suitability_lowerbody'] as int? ?? -1;
              final suitabilityAbscore = setVal['suitability_abscore'] as int? ?? -1;
              final suitabilityBack = setVal['suitability_back'] as int? ?? -1;
              final suitabilityUpperbody = setVal['suitability_upperbody'] as int? ?? -1;
              final difficulty = setVal['difficulty'] as int? ?? 0;
              final sortOrder = setVal['order'] as int? ?? 0;
              final skillRequired = setVal['skill_required'] as int? ?? -1;
              final skillMax = setVal['skill_max'] as int? ?? -1;

              suitabilityBatch.insert('ss_exercise_set_suitability', {
                'exercise_id': id,
                'set_code': setCode,
                'suitability': suitability,
                'suitability_lowerbody': suitabilityLowerbody,
                'suitability_abscore': suitabilityAbscore,
                'suitability_back': suitabilityBack,
                'suitability_upperbody': suitabilityUpperbody,
                'difficulty': difficulty,
                'sort_order': sortOrder,
                'skill_required': skillRequired,
                'skill_max': skillMax,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          });
        }
      }
      await batch.commit(noResult: true);
      await suitabilityBatch.commit(noResult: true);

      // 4. Seed similarities
      final similarityJsonStr = await rootBundle.loadString('assets/data/fitify_exercise_similarity_relations.json');
      final similarityData = await compute(jsonDecode, similarityJsonStr) as Map<String, dynamic>;

      final simBatch = db.batch();
      similarityData.forEach((sourceId, targets) {
        if (targets is Map<String, dynamic>) {
          targets.forEach((targetId, info) {
            if (info is Map<String, dynamic>) {
              final score = (info['similarity'] as num?)?.toDouble() ?? 0.0;
              simBatch.insert('ss_exercise_similarity', {
                'exerciseId': sourceId,
                'similarExerciseId': targetId,
                'similarityScore': score,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          });
        }
      });
      await simBatch.commit(noResult: true);
      await _translateExistingSeededExercises(db);

    } catch (e) {
      debugPrint('Error seeding supplementary sports: $e');
    }
  }

  static Future<void> _translateExistingSeededExercises(Database db) async {
    try {
      final List<Map<String, dynamic>> exercises = await db.query('ss_exercise', columns: ['id', 'name']);
      final batch = db.batch();
      var hasUpdates = false;
      for (final row in exercises) {
        final id = row['id'].toString();
        final currentName = row['name'].toString();
        final farsiName = _translateToPersian(currentName);
        if (farsiName != currentName) {
          batch.update(
            'ss_exercise',
            {'name': farsiName},
            where: 'id = ?',
            whereArgs: [id],
          );
          hasUpdates = true;
        }
      }
      if (hasUpdates) {
        await batch.commit(noResult: true);
      }
    } catch (_) {}
  }

  static String _translateToPersian(String title) {
    final cleanTitle = title.trim();
    final lower = cleanTitle.toLowerCase();

    final exactMap = <String, String>{
      'side leg lift': 'بلند کردن پا از پهلو',
      'mountain climbers': 'کوهنوردی',
      'back & forth squat': 'اسکوات رفت و برگشت',
      'frog jumps': 'پرش قورباغه‌ای',
      'front kicks': 'لگد به جلو',
      'lunges': 'لانژ',
      'toe balancing lunge': 'لانژ تعادلی روی پنجه',
      'pistol squats': 'اسکوات تک پا (پیستول)',
      'squats': 'اسکوات سوئدی',
      "prisoner's squat": 'اسکوات زندانی',
      'sumo squat': 'اسکوات سومو',
      'march & clap': 'مارچ و دست زدن',
      'jogging': 'دویدن نرم',
      'running in place': 'دویدن درجا',
      'running sprinter': 'دویدن استارت',
      'rear lunges': 'لانژ به عقب',
      'diagonal lunges': 'لانژ مورب',
      'single calf raises': 'ساق پا تک پا ایستاده',
      'calf raises': 'ساق پا ایستاده',
      'jumping lunges': 'لانژ پرشی',
      'jump squats': 'اسکوات پرشی',
      'high jump': 'پرش ارتفاع',
      'single leg jumps': 'پرش تک پا',
      'side-to-side jumps': 'پرش طرفین',
      'jump rope': 'طناب زنی',
      'one leg rope jump': 'طناب زنی تک پا',
      'high knees': 'زانو بلند',
      'butt kickers': 'ضربه به باسن',
      'plank-ins': 'پلانک جمع',
      'plank jacks': 'پلانک پروانه‌ای',
      'hurdler stretch': 'کشش موانع',
      'hundred pike': 'پایک صدتایی',
      'the hundred': 'پیلاتس صدتایی',
      'wide leg bend': 'خم شدن پا باز',
      'single leg circles': 'دایره با تک پا',
      'plank & rear kick': 'پلانک با لگد به عقب',
      'back plank & kick': 'پلانک معکوس با لگد',
      'outer thigh bicycle': 'دوچرخه ران خارجی',
      'outer thigh triangle': 'مثلث ران خارجی',
      'outer thigh raises': 'بالا آوردن ران خارجی',
      'plank': 'پلانک کلاسیک',
      'side plank': 'پلانک از پهلو',
      'pushups': 'شنا سوئدی',
      'push-up': 'شنا سوئدی',
      'incline pushups': 'شنا روی میز شیب‌دار',
      'decline pushups': 'شنا سوئدی شیب منفی',
      'diamond pushups': 'شنا سوئدی دست جمع',
      'crunches': 'کرانچ شکم',
      'bicycle crunches': 'کرانچ دوچرخه',
      'reverse crunches': 'کرانچ معکوس',
      'leg raises': 'بالا آوردن پاها خوابیده',
      'flutter kicks': 'پا دوچرخه خوابیده',
      'superman': 'سوپرمن خوابیده',
      'bird dog': 'سگ پرنده',
      'burpees': 'برپی',
      'jumping jacks': 'پروانه',
      'wall sit': 'نشستن کنار دیوار',
      'dips': 'دیپ پشت بازو روی صندلی',
      'pullups': 'بارفیکس دست باز',
      'pull-up': 'بارفیکس دست باز',
      'chin-ups': 'بارفیکس دست جمع معکوس',
    };

    if (exactMap.containsKey(lower)) {
      return exactMap[lower]!;
    }

    final words = lower.split(' ');
    final translated = <String>[];

    for (var word in words) {
      word = word.replaceAll('&', 'و').replaceAll('-', ' ');
      if (word == 'stretch') {
        translated.add('کشش');
      } else if (word == 'lunge' || word == 'lunges') {
        translated.add('لانژ');
      } else if (word == 'squat' || word == 'squats') {
        translated.add('اسکوات');
      } else if (word == 'pushup' || word == 'pushups' || word == 'push-up') {
        translated.add('شنا');
      } else if (word == 'plank' || word == 'planks') {
        translated.add('پلانک');
      } else if (word == 'jump' || word == 'jumps' || word == 'jumping') {
        translated.add('پرشی');
      } else if (word == 'pose') {
        translated.add('وضعیت');
      } else if (word == 'kick' || word == 'kicks' || word == 'kicker') {
        translated.add('لگد');
      } else if (word == 'wrist') {
        translated.add('مچ دست');
      } else if (word == 'neck') {
        translated.add('گردن');
      } else if (word == 'shoulder') {
        translated.add('شانه');
      } else if (word == 'arm' || word == 'arms') {
        translated.add('بازو');
      } else if (word == 'leg' || word == 'legs') {
        translated.add('پا');
      } else if (word == 'bridge') {
        translated.add('پل');
      } else if (word == 'circles' || word == 'circle') {
        translated.add('چرخش');
      } else if (word == 'single' || word == 'one') {
        translated.add('تک');
      } else if (word == 'double' || word == 'two') {
        translated.add('جفت');
      } else if (word == 'side') {
        translated.add('از پهلو');
      } else if (word == 'back') {
        translated.add('پشت');
      } else if (word == 'front') {
        translated.add('جلو');
      } else if (word == 'incline') {
        translated.add('سطح شیب‌دار مثبت');
      } else if (word == 'decline') {
        translated.add('سطح شیب‌دار منفی');
      } else {
        translated.add(word);
      }
    }

    if (translated.isNotEmpty) {
      if (translated.contains('کشش') && translated.indexOf('کشش') != 0) {
        translated.remove('کشش');
        translated.insert(0, 'کشش');
      }
      if (translated.contains('اسکوات') && translated.indexOf('اسکوات') != 0) {
        translated.remove('اسکوات');
        translated.insert(0, 'اسکوات');
      }
      if (translated.contains('لانژ') && translated.indexOf('لانژ') != 0) {
        translated.remove('لانژ');
        translated.insert(0, 'لانژ');
      }
      if (translated.contains('شنا') && translated.indexOf('شنا') != 0) {
        translated.remove('شنا');
        translated.insert(0, 'شنا');
      }
      if (translated.contains('پلانک') && translated.indexOf('پلانک') != 0) {
        translated.remove('پلانک');
        translated.insert(0, 'پلانک');
      }
      return translated.join(' ');
    }

    return cleanTitle;
  }
}
