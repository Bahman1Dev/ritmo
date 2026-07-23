import 'package:flutter/foundation.dart';

enum Category {
  medical,
  religious,
  fitness,
  work,
  personal,
  free,
  learning,
  konkur,
  custom,
}

enum RoutineType {
  timeBased,
  intervalBased,
  countBased,
  progressive,
  dependent,
  asNeeded,
}

enum NotificationLevel {
  none,
  silent,
  normal,
  important,
}

enum EnergyRule {
  none,
  skip,
  offerLight,
  offerMinimal,
  highEnergyOnly,
}

enum DependencyType {
  afterCompletion,
  relativeTime,
  chained,
}

enum ZoneMode {
  normal,
  focus,
  silent,
}

enum EnergyLevel {
  low,
  medium,
  high,
}

enum DecisionOutcome {
  ignore,
  sendStandard,
  offerLight,
  offerMinimal,
  deferOrCancel,
}

class Routine {

  Routine({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.customCategoryId,
    this.zoneId,
    required this.routineType,
    required this.notificationLevel,
    required this.isEssential,
    this.isEssentialLocked = false,
    required this.energyRule,
    this.priority = 1.0,
    this.targetDurationMinutes,
    this.lightDurationMinutes,
    this.minimalDurationMinutes,
    this.energyImpact = 0,
    this.dependsOnRoutineId,
    this.dependencyType,
    this.dependencyOffsetMinutes,
    this.dependencyWindowMinutes,
    this.isArchived = false,
    this.isPrivate = false,
    this.medStockCount = 0,
    this.medRefillThreshold = 0,
    this.minIntervalHours = 0,
    this.maxDosesPerDay = 0,
    this.progressionMode = 'NONE',
    this.progressionStart = 0,
    this.progressionTarget = 0,
    this.progressionStep = 0,
    this.progressionEveryN = 1,
    this.progressionCurrent = 0,
    this.progressionDoneSinceAdvance = 0,
    this.itemType = 'ROUTINE',
    this.timeOfDay,
  });

  factory Routine.fromMap(Map<String, dynamic> map) {
    final catStr = map['category'] as String;
    final catEnum = Category.values.firstWhere(
      (e) => e.name == catStr,
      orElse: () => Category.custom,
    );

    final routineTypeStr = map['routineType'] as String;
    final routineTypeEnum = RoutineType.values.firstWhere(
      (e) => e.name == routineTypeStr,
      orElse: () => RoutineType.asNeeded,
    );

    final notifLevelStr = map['notificationLevel'] as String;
    final notifLevelEnum = NotificationLevel.values.firstWhere(
      (e) => e.name == notifLevelStr,
      orElse: () => NotificationLevel.normal,
    );

    final energyRuleStr = map['energyRule'] as String;
    final energyRuleEnum = EnergyRule.values.firstWhere(
      (e) => e.name == energyRuleStr,
      orElse: () => EnergyRule.none,
    );

    final depTypeStr = map['dependencyType'] as String?;
    final depTypeEnum = depTypeStr != null
        ? DependencyType.values.firstWhere(
            (e) => e.name == depTypeStr,
            orElse: () => DependencyType.afterCompletion,
          )
        : null;

    return Routine(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: catEnum,
      customCategoryId: map['customCategoryId'] as String?,
      zoneId: map['zoneId'] as String?,
      routineType: routineTypeEnum,
      notificationLevel: notifLevelEnum,
      isEssential: map['isEssential'] == 1,
      isEssentialLocked: (map['isEssentialLocked'] as int? ?? 0) == 1,
      energyRule: energyRuleEnum,
      priority: (map['priority'] as num?)?.toDouble() ?? 1.0,
      targetDurationMinutes: map['targetDurationMinutes'] as int?,
      lightDurationMinutes: map['lightDurationMinutes'] as int?,
      minimalDurationMinutes: map['minimalDurationMinutes'] as int?,
      energyImpact: map['energyImpact'] as int? ?? 0,
      dependsOnRoutineId: map['dependsOnRoutineId'] as String?,
      dependencyType: depTypeEnum,
      dependencyOffsetMinutes: map['dependencyOffsetMinutes'] as int?,
      dependencyWindowMinutes: map['dependencyWindowMinutes'] as int?,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      isPrivate: (map['isPrivate'] as int? ?? 0) == 1,
      medStockCount: map['medStockCount'] as int? ?? 0,
      medRefillThreshold: map['medRefillThreshold'] as int? ?? 0,
      minIntervalHours: map['minIntervalHours'] as int? ?? 0,
      maxDosesPerDay: map['maxDosesPerDay'] as int? ?? 0,
      progressionMode: map['progressionMode'] as String? ?? 'NONE',
      progressionStart: map['progressionStart'] as int? ?? 0,
      progressionTarget: map['progressionTarget'] as int? ?? 0,
      progressionStep: map['progressionStep'] as int? ?? 0,
      progressionEveryN: map['progressionEveryN'] as int? ?? 1,
      progressionCurrent: map['progressionCurrent'] as int? ?? 0,
      progressionDoneSinceAdvance: map['progressionDoneSinceAdvance'] as int? ?? 0,
      itemType: map['itemType'] as String? ?? 'ROUTINE',
      timeOfDay: map['timeOfDay'] as String?,
    );
  }
  final String id;
  final String title;
  final String? description;
  final Category category;
  final String? customCategoryId;
  final String? zoneId;
  final RoutineType routineType;
  final NotificationLevel notificationLevel;
  final bool isEssential;
  final bool isEssentialLocked;
  final EnergyRule energyRule;
  final double priority;
  final int? targetDurationMinutes;
  final int? lightDurationMinutes;
  final int? minimalDurationMinutes;
  final int energyImpact;
  final String? dependsOnRoutineId;
  final DependencyType? dependencyType;
  final int? dependencyOffsetMinutes;
  final int? dependencyWindowMinutes;
  final bool isArchived;
  final bool isPrivate;
  final int medStockCount;
  final int medRefillThreshold;
  final int minIntervalHours;
  final int maxDosesPerDay;
  final String progressionMode;
  final int progressionStart;
  final int progressionTarget;
  final int progressionStep;
  final int progressionEveryN;
  final int progressionCurrent;
  final int progressionDoneSinceAdvance;
  final String itemType;
  final String? timeOfDay;

  int get currentTargetMinutes {
    if (progressionMode == 'NONE') {
      return targetDurationMinutes ?? 0;
    }
    return progressionCurrent;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'customCategoryId': customCategoryId,
      'zoneId': zoneId,
      'routineType': routineType.name,
      'notificationLevel': notificationLevel.name,
      'isEssential': isEssential ? 1 : 0,
      'isEssentialLocked': isEssentialLocked ? 1 : 0,
      'energyRule': energyRule.name,
      'priority': priority,
      'targetDurationMinutes': targetDurationMinutes,
      'lightDurationMinutes': lightDurationMinutes,
      'minimalDurationMinutes': minimalDurationMinutes,
      'energyImpact': energyImpact,
      'dependsOnRoutineId': dependsOnRoutineId,
      'dependencyType': dependencyType?.name,
      'dependencyOffsetMinutes': dependencyOffsetMinutes,
      'dependencyWindowMinutes': dependencyWindowMinutes,
      'isArchived': isArchived ? 1 : 0,
      'isPrivate': isPrivate ? 1 : 0,
      'medStockCount': medStockCount,
      'medRefillThreshold': medRefillThreshold,
      'minIntervalHours': minIntervalHours,
      'maxDosesPerDay': maxDosesPerDay,
      'progressionMode': progressionMode,
      'progressionStart': progressionStart,
      'progressionTarget': progressionTarget,
      'progressionStep': progressionStep,
      'progressionEveryN': progressionEveryN,
      'progressionCurrent': progressionCurrent,
      'progressionDoneSinceAdvance': progressionDoneSinceAdvance,
      'itemType': itemType,
      'timeOfDay': timeOfDay,
    };
  }
}

class CustomCategory {

  CustomCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
    this.isArchived = false,
  });

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id'] as String,
      title: map['title'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      sortOrder: map['sortOrder'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
    );
  }
  final String id;
  final String title;
  final String icon;
  final String color;
  final int sortOrder;
  final DateTime createdAt;
  final bool isArchived;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isArchived': isArchived ? 1 : 0,
    };
  }
}

class RitmoEvents {
  static final ValueNotifier<int> routineChanges = ValueNotifier<int>(0);

  static void notifyRoutineChanged() {
    routineChanges.value++;
  }
}

class RecurrenceRule {

  RecurrenceRule({
    required this.weekdays,
    this.intervalDays,
    this.monthDay,
    this.startDate,
    this.endDate,
    this.excludedDates,
    required this.reminderTimes,
    this.intervalHours,
  });

  factory RecurrenceRule.fromMap(Map<String, dynamic> map) {
    return RecurrenceRule(
      weekdays: List<int>.from(map['weekdays'] ?? []),
      intervalDays: map['intervalDays'] as int?,
      monthDay: map['monthDay'] as int?,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate'] as String) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      excludedDates: map['excludedDates'] != null
          ? (map['excludedDates'] as List).map((d) => DateTime.parse(d as String)).toList()
          : null,
      reminderTimes: List<String>.from(map['reminderTimes'] ?? []),
      intervalHours: map['intervalHours'] as int?,
    );
  }
  final List<int> weekdays; // 1: Mon ... 7: Sun
  final int? intervalDays;
  final int? monthDay;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime>? excludedDates;
  final List<String> reminderTimes; // e.g. ["08:00", "20:00"]
  final int? intervalHours;

  Map<String, dynamic> toMap() {
    return {
      'weekdays': weekdays,
      'intervalDays': intervalDays,
      'monthDay': monthDay,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'excludedDates': excludedDates?.map((d) => d.toIso8601String()).toList(),
      'reminderTimes': reminderTimes,
      'intervalHours': intervalHours,
    };
  }
}

