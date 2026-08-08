enum SplitPatternType {
  fullBody,
  upperLower,
  pushPullLegs,
  custom;

  String get code => switch (this) {
    SplitPatternType.fullBody => 'FULL_BODY',
    SplitPatternType.upperLower => 'UPPER_LOWER',
    SplitPatternType.pushPullLegs => 'PUSH_PULL_LEGS',
    SplitPatternType.custom => 'CUSTOM',
  };

  static SplitPatternType fromCode(String code) => switch (code.toUpperCase()) {
    'UPPER_LOWER' => SplitPatternType.upperLower,
    'PUSH_PULL_LEGS' => SplitPatternType.pushPullLegs,
    'CUSTOM' => SplitPatternType.custom,
    _ => SplitPatternType.fullBody,
  };

  String get labelFa => switch (this) {
    SplitPatternType.fullBody => 'کل بدن',
    SplitPatternType.upperLower => 'بالاتنه و پایین‌تنه',
    SplitPatternType.pushPullLegs => 'هل، کشش، پا (Push/Pull/Legs)',
    SplitPatternType.custom => 'دلخواه (سفارشی)',
  };
}

class SplitPattern {
  static List<String> focusFor(String patternCode, int sessionIndexInWeek, List<String> userFocusAreas) {
    final code = patternCode.toUpperCase();
    if (code == 'FULL_BODY') {
      return ['FULL_BODY'];
    }
    
    if (code == 'UPPER_LOWER') {
      final isUpper = sessionIndexInWeek % 2 == 0;
      if (isUpper) {
        final upper = ['CHEST', 'SHOULDER', 'BACK'];
        final userUpper = userFocusAreas.where((f) => ['CHEST', 'SHOULDER', 'BACK', 'BICEPS', 'TRICEPS'].contains(f.toUpperCase())).toList();
        if (userUpper.isNotEmpty) {
          return [userUpper.first, ...upper.where((u) => u != userUpper.first)].take(3).toList();
        }
        return upper;
      } else {
        final lower = ['QUADS_GLUTES', 'HAMSTRINGS', 'CALVES'];
        final userLower = userFocusAreas.where((f) => ['QUADS_GLUTES', 'HAMSTRINGS', 'CALVES'].contains(f.toUpperCase())).toList();
        if (userLower.isNotEmpty) {
          return [userLower.first, ...lower.where((l) => l != userLower.first)].take(3).toList();
        }
        return lower;
      }
    }
    
    if (code == 'PUSH_PULL_LEGS') {
      final step = sessionIndexInWeek % 3;
      if (step == 0) {
        final push = ['CHEST', 'SHOULDER', 'TRICEPS'];
        final userPush = userFocusAreas.where((f) => push.contains(f.toUpperCase())).toList();
        if (userPush.isNotEmpty) {
          return [userPush.first, ...push.where((p) => p != userPush.first)].take(3).toList();
        }
        return push;
      } else if (step == 1) {
        final pull = ['BACK', 'BICEPS'];
        final userPull = userFocusAreas.where((f) => pull.contains(f.toUpperCase())).toList();
        if (userPull.isNotEmpty) {
          return [...userPull, ...pull.where((p) => !userPull.contains(p))].take(3).toList();
        }
        return pull;
      } else {
        final legs = ['QUADS_GLUTES', 'HAMSTRINGS', 'CORE'];
        final userLegs = userFocusAreas.where((f) => legs.contains(f.toUpperCase())).toList();
        if (userLegs.isNotEmpty) {
          return [userLegs.first, ...legs.where((l) => l != userLegs.first)].take(3).toList();
        }
        return legs;
      }
    }
    
    if (userFocusAreas.isNotEmpty) {
      return userFocusAreas.take(3).toList();
    }
    return ['FULL_BODY'];
  }
}
