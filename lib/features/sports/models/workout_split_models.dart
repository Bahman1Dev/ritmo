import 'package:flutter/material.dart';

/// گروه‌های عضلانی + گزینه‌های ویژه
enum MuscleGroup {
  chest, back, shoulders, biceps, triceps, legs, abs, fullBody, cardio, rest;

  String get code => name.toUpperCase();

  String get label {
    switch (this) {
      case MuscleGroup.chest:    return 'سینه';
      case MuscleGroup.back:     return 'زیربغل';
      case MuscleGroup.shoulders:return 'سرشانه';
      case MuscleGroup.biceps:   return 'جلو بازو';
      case MuscleGroup.triceps:  return 'پشت بازو';
      case MuscleGroup.legs:     return 'پا';
      case MuscleGroup.abs:      return 'شکم';
      case MuscleGroup.fullBody: return 'تمام بدن';
      case MuscleGroup.cardio:   return 'هوازی';
      case MuscleGroup.rest:     return 'استراحت';
    }
  }

  String get emoji {
    switch (this) {
      case MuscleGroup.chest:    return '🫀';
      case MuscleGroup.back:     return '🔺';
      case MuscleGroup.shoulders:return '🤸';
      case MuscleGroup.biceps:   return '💪';
      case MuscleGroup.triceps:  return '🦾';
      case MuscleGroup.legs:     return '🦵';
      case MuscleGroup.abs:      return '🧱';
      case MuscleGroup.fullBody: return '🏋️';
      case MuscleGroup.cardio:   return '🏃';
      case MuscleGroup.rest:     return '😴';
    }
  }

  Color get color {
    switch (this) {
      case MuscleGroup.chest:    return const Color(0xffEF4444);
      case MuscleGroup.back:     return const Color(0xff3B82F6);
      case MuscleGroup.shoulders:return const Color(0xffF59E0B);
      case MuscleGroup.biceps:   return const Color(0xff8B5CF6);
      case MuscleGroup.triceps:  return const Color(0xffEC4899);
      case MuscleGroup.legs:     return const Color(0xff10B981);
      case MuscleGroup.abs:      return const Color(0xffFBBF24);
      case MuscleGroup.fullBody: return const Color(0xff14B8A6);
      case MuscleGroup.cardio:   return const Color(0xff22B8CF);
      case MuscleGroup.rest:     return const Color(0xff64748B);
    }
  }

  static MuscleGroup fromCode(String s) => MuscleGroup.values.firstWhere(
      (e) => e.code == s.toUpperCase(), orElse: () => MuscleGroup.rest);
}

/// سه نسخه‌ی تمرین — مثل تیرهای روتین‌های ریتمو
enum WorkoutTier {
  minimal, light, full;

  String get code => name.toUpperCase();

  String get label {
    switch (this) {
      case WorkoutTier.minimal: return 'حداقلی';
      case WorkoutTier.light:   return 'سبک';
      case WorkoutTier.full:    return 'کامل';
    }
  }

  String get description {
    switch (this) {
      case WorkoutTier.minimal: return '۱۰ دقیقه — فقط زنجیره رو حفظ کن';
      case WorkoutTier.light:   return '۲۵ دقیقه — تمرین سبک';
      case WorkoutTier.full:    return '۵۰ دقیقه — تمرین کامل';
    }
  }

  int get defaultMinutes {
    switch (this) {
      case WorkoutTier.minimal: return 10;
      case WorkoutTier.light:   return 25;
      case WorkoutTier.full:    return 50;
    }
  }

  Color get color {
    switch (this) {
      case WorkoutTier.minimal: return const Color(0xffFBBF24);
      case WorkoutTier.light:   return const Color(0xff00D9F6);
      case WorkoutTier.full:    return const Color(0xff00F5A0);
    }
  }

  static WorkoutTier fromCode(String s) => WorkoutTier.values.firstWhere(
      (e) => e.code == s.toUpperCase(), orElse: () => WorkoutTier.full);
}

/// محل تمرین
enum SportsLocation {
  home, gym;

  String get code  => name.toUpperCase();
  String get label => this == SportsLocation.home ? 'خانه' : 'باشگاه';
  String get emoji => this == SportsLocation.home ? '🏠' : '🏟️';

  static SportsLocation fromCode(String s) =>
      s.toUpperCase() == 'GYM' ? SportsLocation.gym : SportsLocation.home;
}

/// یک روزِ برنامه‌ی هفتگی
/// weekday طبق DateTime.weekday: 1=دوشنبه ... 7=یکشنبه
class SplitDay {

  SplitDay({required this.weekday, required this.groups, this.isRest = false});

  factory SplitDay.fromMap(Map<String, dynamic> map) {
    final raw = (map['muscleGroups'] as String? ?? '').trim();
    final groups = raw.isEmpty
        ? <MuscleGroup>[]
        : raw.split(',').where((e) => e.trim().isNotEmpty).map(MuscleGroup.fromCode).toList();
    return SplitDay(
      weekday: map['weekday'] as int,
      groups: groups,
      isRest: (map['isRest'] as int? ?? 0) == 1,
    );
  }
  final int weekday;
  final List<MuscleGroup> groups;
  final bool isRest;

  bool get isEmpty => isRest || groups.isEmpty;

  /// نام فارسی روز
  String get dayName {
    const names = {1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنج‌شنبه', 5: 'جمعه', 6: 'شنبه', 7: 'یکشنبه'};
    return names[weekday] ?? 'روز $weekday';
  }

  Map<String, dynamic> toMap() => {
        'weekday': weekday,
        'muscleGroups': groups.map((g) => g.code).join(','),
        'isRest': isRest ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
}

/// خروجی پیشنهاد امروز
class TodayWorkoutSuggestion {

  const TodayWorkoutSuggestion({
    required this.groups,
    required this.isRest,
    required this.hasNoPlan,
    required this.suggestedTier,
    required this.reason,
    required this.exercises,
  });
  final List<MuscleGroup> groups;
  final bool isRest;
  final bool hasNoPlan;
  final WorkoutTier suggestedTier;
  final String reason;
  final List<String> exercises;
}
