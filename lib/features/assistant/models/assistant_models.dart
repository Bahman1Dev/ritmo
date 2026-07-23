import 'package:flutter/cupertino.dart';

enum AssistantActionType {
  createRoutine,
  createGoal,
  logSleep,
  logEnergyMood,
  addKonkurItem,
  createCourse,
  openPage,
  updateSetting,
  completeRoutine,
  skipRoutine,
  editRoutine,
  deleteRoutine,
  editGoal,
  completeGoalStep,
  createWorshipItem,
  deleteWorshipItem,
  logReflection,
  rescheduleReminder,
  swapExercise,
  adjustWorkoutIntensity,
  setQuietMode,
  changeSetProgram,
  rescheduleDay,
  applyDayPlan;

  String get label {
    switch (this) {
      case AssistantActionType.createRoutine: return 'ایجاد روتین جدید';
      case AssistantActionType.createGoal: return 'تعریف هدف جدید';
      case AssistantActionType.logSleep: return 'ثبت وضعیت خواب';
      case AssistantActionType.logEnergyMood: return 'ثبت وضعیت روزانه';
      case AssistantActionType.addKonkurItem: return 'افزودن برنامه مطالعه';
      case AssistantActionType.createCourse: return 'ثبت دوره جدید';
      case AssistantActionType.openPage: return 'مشاهده صفحه';
      case AssistantActionType.updateSetting: return 'تغییر تنظیمات';
      case AssistantActionType.completeRoutine: return 'تیک زدن روتین';
      case AssistantActionType.skipRoutine: return 'رد کردن روتین';
      case AssistantActionType.editRoutine: return 'ویرایش روتین';
      case AssistantActionType.deleteRoutine: return 'حذف روتین';
      case AssistantActionType.editGoal: return 'ویرایش هدف';
      case AssistantActionType.completeGoalStep: return 'تکمیل گامِ هدف';
      case AssistantActionType.createWorshipItem: return 'افزودن عبادت';
      case AssistantActionType.deleteWorshipItem: return 'حذف عبادت';
      case AssistantActionType.logReflection: return 'ثبت بازتاب';
      case AssistantActionType.rescheduleReminder: return 'جابجاییِ یادآوری';
      case AssistantActionType.swapExercise: return 'تعویض حرکت ورزشی';
      case AssistantActionType.adjustWorkoutIntensity: return 'تنظیم شدت تمرین';
      case AssistantActionType.setQuietMode: return 'تنظیم حالت بی‌صدا';
      case AssistantActionType.changeSetProgram: return 'تغییر برنامه تمرین';
      case AssistantActionType.rescheduleDay: return 'تغییر روز تمرین';
      case AssistantActionType.applyDayPlan: return 'چیدن برنامه روز';
    }
  }

  IconData get icon {
    switch (this) {
      case AssistantActionType.createRoutine: return CupertinoIcons.add_circled;
      case AssistantActionType.createGoal: return CupertinoIcons.flag;
      case AssistantActionType.logSleep: return CupertinoIcons.moon;
      case AssistantActionType.logEnergyMood: return CupertinoIcons.heart;
      case AssistantActionType.addKonkurItem: return CupertinoIcons.book;
      case AssistantActionType.createCourse: return CupertinoIcons.play_rectangle;
      case AssistantActionType.openPage: return CupertinoIcons.arrow_right_circle;
      case AssistantActionType.updateSetting: return CupertinoIcons.slider_horizontal_3;
      case AssistantActionType.completeRoutine: return CupertinoIcons.checkmark_circle;
      case AssistantActionType.skipRoutine: return CupertinoIcons.xmark_circle;
      case AssistantActionType.editRoutine: return CupertinoIcons.pencil;
      case AssistantActionType.deleteRoutine: return CupertinoIcons.trash;
      case AssistantActionType.editGoal: return CupertinoIcons.pencil;
      case AssistantActionType.completeGoalStep: return CupertinoIcons.checkmark_seal;
      case AssistantActionType.createWorshipItem: return CupertinoIcons.moon_stars;
      case AssistantActionType.deleteWorshipItem: return CupertinoIcons.trash;
      case AssistantActionType.logReflection: return CupertinoIcons.text_quote;
      case AssistantActionType.rescheduleReminder: return CupertinoIcons.clock;
      case AssistantActionType.swapExercise: return CupertinoIcons.arrow_2_circlepath;
      case AssistantActionType.adjustWorkoutIntensity: return CupertinoIcons.gauge;
      case AssistantActionType.setQuietMode: return CupertinoIcons.volume_off;
      case AssistantActionType.changeSetProgram: return CupertinoIcons.arrow_right_arrow_left;
      case AssistantActionType.rescheduleDay: return CupertinoIcons.calendar_today;
      case AssistantActionType.applyDayPlan: return CupertinoIcons.calendar;
    }
  }

  static AssistantActionType fromString(String val) {
    return AssistantActionType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AssistantActionType.openPage,
    );
  }
}

class AssistantAction {

  AssistantAction({
    required this.type,
    required this.title,
    required this.payload,
    this.targetRoute,
  });

  factory AssistantAction.fromJson(Map<String, dynamic> json) {
    return AssistantAction(
      type: AssistantActionType.fromString(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      targetRoute: json['targetRoute'] as String?,
    );
  }
  final AssistantActionType type;
  final String title;
  final Map<String, dynamic> payload;
  final String? targetRoute;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'payload': payload,
      'targetRoute': targetRoute,
    };
  }
}

class NextAction {

  NextAction({
    required this.title,
    required this.reason,
    this.action,
    this.deepLinkRoute,
    required this.rank,
  });
  final String title;
  final String reason;
  final AssistantAction? action;
  final String? deepLinkRoute;
  final int rank;
}

class BriefingItem {

  BriefingItem({
    required this.system,
    required this.headline,
  });
  factory BriefingItem.fromJson(Map<String, dynamic> json) => BriefingItem(
        system: json['system'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
      );
  final String system;
  final String headline;

  Map<String, dynamic> toJson() => {'system': system, 'headline': headline};
}

class DailyBriefing {

  DailyBriefing({
    required this.text,
    required this.highlights,
    required this.stats,
  });
  final String text;
  final List<BriefingItem> highlights;
  final Map<String, dynamic> stats;
}
