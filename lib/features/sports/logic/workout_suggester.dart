import 'package:ritmo/features/sports/data/exercise_suggestions.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';
import 'package:sqflite/sqflite.dart';

/// قلب «هوشمندی» ماژول ورزش:
/// نسخه‌ی پیشنهادی امروز را از خواب دیشب، ریکاوری خوداظهار، و فاز چرخه تعیین می‌کند.
class WorkoutSuggester {
  /// محل تمرین از app_settings
  static Future<SportsLocation> readLocation(Database db) async {
    final rows = await db.query('app_settings',
        where: 'key = ?', whereArgs: ['sports_location'], limit: 1);
    if (rows.isEmpty) return SportsLocation.home;
    return SportsLocation.fromCode(rows.first['value'] as String? ?? 'HOME');
  }

  /// آیا setup انجام شده؟
  static Future<bool> isSetupDone(Database db) async {
    final rows = await db.query('app_settings',
        where: 'key = ?', whereArgs: ['sports_setup_done'], limit: 1);
    return rows.isNotEmpty && (rows.first['value'] as String?) == 'true';
  }

  /// خواندن کل Split (۷ روز)
  static Future<Map<int, SplitDay>> readSplit(Database db) async {
    final rows = await db.query('workout_split_days');
    final map = <int, SplitDay>{};
    for (final r in rows) {
      final d = SplitDay.fromMap(r);
      map[d.weekday] = d;
    }
    return map;
  }

  /// ذخیره یک روز در split
  static Future<void> saveSplitDay(Database db, SplitDay day) async {
    await db.insert('workout_split_days', day.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ذخیره تنظیمات اولیه
  static Future<void> saveSetup(Database db, {
    required SportsLocation location,
    required int daysPerWeek,
    required String goalFocus,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    Future<void> put(String key, String val) => db.insert(
        'app_settings',
        {'key': key, 'value': val, 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace);

    await put('sports_location', location.code);
    await put('sports_days_per_week', daysPerWeek.toString());
    await put('sports_goal_focus', goalFocus);
    await put('sports_setup_done', 'true');
  }

  /// ریست کامل تنظیمات ورزش
  static Future<void> resetSetup(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('app_settings',
        {'key': 'sports_setup_done', 'value': 'false', 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.delete('workout_split_days');
  }

  /// آیا امروز تمرین ثبت شده؟
  static Future<bool> isTodayLogged(Database db) async {
    final today = DateTime.now();
    final rows = await db.rawQuery(
        'SELECT id FROM workout_logs WHERE loggedAt >= ? LIMIT 1',
        [DateTime(today.year, today.month, today.day).millisecondsSinceEpoch]);
    return rows.isNotEmpty;
  }

  /// مدت خواب دیشب به دقیقه
  static Future<int?> _lastNightSleepMinutes(Database db) async {
    try {
      final rows = await db.query('bedtime_diagnostics',
          orderBy: 'date DESC', limit: 1);
      if (rows.isEmpty) return null;
      return rows.first['durationMinutes'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// ریکاوریِ امروز — مجموع خستگی + کوفتگی (0..6)
  static Future<int> _todayRecoveryLoad(Database db) async {
    try {
      final today = DateTime.now();
      final key =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final rows = await db.query('workout_recovery_logs',
          where: 'date = ?', whereArgs: [key],
          orderBy: 'loggedAt DESC', limit: 1);
      if (rows.isEmpty) return 0;
      final soreness = rows.first['soreness'] as int? ?? 0;
      final fatigue  = rows.first['fatigue']  as int? ?? 0;
      return soreness + fatigue;
    } catch (_) {
      return 0;
    }
  }

  /// آیا ریکاوری امروز ثبت شده؟
  static Future<bool> isTodayRecoveryLogged(Database db) async {
    try {
      final today = DateTime.now();
      final key =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final rows = await db.query('workout_recovery_logs',
          where: 'date = ?', whereArgs: [key], limit: 1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// آیا کاربر در فاز قاعدگی است؟
  static Future<bool> _isMenstrualPhase(Database db) async {
    try {
      final flag = await db.query('app_settings',
          where: 'key = ?', whereArgs: ['module_cycle_enabled'], limit: 1);
      final on = flag.isNotEmpty && (flag.first['value'] as String?) == 'true';
      if (!on) return false;
      return false; // اگر منطق ساده‌ای در دسترس نبود false می‌ماند
    } catch (_) {
      return false;
    }
  }

  /// هدف ورزشی
  static Future<String> readGoalFocus(Database db) async {
    final rows = await db.query('app_settings',
        where: 'key = ?', whereArgs: ['sports_goal_focus'], limit: 1);
    return rows.isEmpty ? 'GENERAL' : (rows.first['value'] as String? ?? 'GENERAL');
  }

  /// پیشنهاد کامل امروز
  static Future<TodayWorkoutSuggestion> buildToday(Database db) async {
    final loc   = await readLocation(db);
    final split = await readSplit(db);
    final weekday = DateTime.now().weekday; // 1..7
    final today   = split[weekday];

    // هیچ برنامه‌ای؟
    final anyPlan = split.values.any((d) => !d.isEmpty);
    if (!anyPlan) {
      return const TodayWorkoutSuggestion(
        groups: [], isRest: false, hasNoPlan: true,
        suggestedTier: WorkoutTier.light,
        reason: 'هنوز برنامه‌ای نساخته‌ای',
        exercises: [],
      );
    }

    // روز استراحت؟
    if (today == null || today.isRest || today.groups.isEmpty) {
      return TodayWorkoutSuggestion(
        groups: const [], isRest: true, hasNoPlan: false,
        suggestedTier: WorkoutTier.minimal,
        reason: 'امروز روز استراحته — ریکاوری و کشش سبک',
        exercises: suggestionsFor(const [MuscleGroup.rest], loc),
      );
    }

    // تعیین نسخه‌ی پیشنهادی بر اساس خواب + ریکاوری + فاز
    final sleep     = await _lastNightSleepMinutes(db);
    final recovery  = await _todayRecoveryLoad(db);
    final menstrual = await _isMenstrualPhase(db);

    var tier = WorkoutTier.full;
    var reason = 'انرژی و ریکاوری خوبه — نسخه‌ی کامل 🔥';

    if (menstrual) {
      tier   = WorkoutTier.light;
      reason = 'فاز قاعدگی — نسخه‌ی سبک‌تر پیشنهاد می‌شه 💜';
    } else if (sleep != null && sleep < 300) {
      tier   = WorkoutTier.minimal;
      reason = 'دیشب خیلی کم خوابیدی (${(sleep / 60).toStringAsFixed(1)} ساعت) — نسخه‌ی حداقلی تا زنجیره نشکنه ⚡';
    } else if (sleep != null && sleep < 360) {
      tier   = WorkoutTier.light;
      reason = 'دیشب کم خوابیدی — نسخه‌ی سبک پیشنهاد می‌شه 🔋';
    } else if (recovery >= 4) {
      tier   = WorkoutTier.light;
      reason = 'بدنت هنوز خسته/کوفته‌ست — نسخه‌ی سبک 💤';
    } else if (recovery >= 2) {
      tier   = WorkoutTier.light;
      reason = 'کمی کوفتگی داری — ملایم تمرین کن 🟡';
    }

    return TodayWorkoutSuggestion(
      groups: today.groups, isRest: false, hasNoPlan: false,
      suggestedTier: tier, reason: reason,
      exercises: suggestionsFor(today.groups, loc),
    );
  }
}
