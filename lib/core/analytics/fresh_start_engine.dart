import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:shamsi_date/shamsi_date.dart';

enum FreshStartLandmarkType {
  saturday,        // شنبه (شروع هفته)
  shamsiMonthStart,// اول ماه شمسی
  nowruz,          // اول فروردین
  seasonStart,     // اول فصل
  lunarMonthStart, // اول ماه قمری (رمضان و...)
  birthday,        // روز تولد
  none,
}

@immutable
class FreshStartInput {
  const FreshStartInput({
    required this.now,
    required this.stagnantGoals,
    required this.deadRoutines,
    this.birthdayJalali,
    this.hijriDay,
  });

  final DateTime now;
  final List<Map<String, dynamic>> stagnantGoals;
  final List<Map<String, dynamic>> deadRoutines;
  final String? birthdayJalali; // format 'MM-DD'
  final int? hijriDay; // 1 for first day of lunar month

  @override
  String toString() {
    return 'FreshStartInput(now: $now, goals: ${stagnantGoals.length}, routines: ${deadRoutines.length}, bday: $birthdayJalali, hijri: $hijriDay)';
  }
}

@immutable
class FreshStartOutput {
  const FreshStartOutput({
    required this.isLandmarkDay,
    required this.landmarkType,
    required this.landmarkTitle,
    required this.stagnantGoalProposals,
    required this.deadRoutineProposals,
  });

  final bool isLandmarkDay;
  final FreshStartLandmarkType landmarkType;
  final String landmarkTitle;
  final List<Map<String, dynamic>> stagnantGoalProposals;
  final List<Map<String, dynamic>> deadRoutineProposals;

  factory FreshStartOutput.none() {
    return const FreshStartOutput(
      isLandmarkDay: false,
      landmarkType: FreshStartLandmarkType.none,
      landmarkTitle: '',
      stagnantGoalProposals: [],
      deadRoutineProposals: [],
    );
  }
}

/// Fresh Start Effect Engine (Dai, Milkman & Riis — م-۶)
class FreshStartEngine implements CachedEngine<FreshStartInput, FreshStartOutput> {
  @override
  bool canRun(FreshStartInput input) => true;

  @override
  List<Type> dependencies() => [];

  @override
  Duration get ttl => const Duration(hours: 4);

  @override
  void invalidate() {}

  @override
  String fingerprint(FreshStartInput input) => input.toString();

  @override
  Future<FreshStartOutput> calculate(FreshStartInput input) async {
    final jalali = Jalali.fromDateTime(input.now);
    
    FreshStartLandmarkType landmark = FreshStartLandmarkType.none;
    String landmarkTitle = '';

    // Check Shamsi Landmarks
    if (jalali.month == 1 && jalali.day == 1) {
      landmark = FreshStartLandmarkType.nowruz;
      landmarkTitle = 'نوروز و آغاز سال نو';
    } else if (jalali.day == 1 && (jalali.month == 4 || jalali.month == 7 || jalali.month == 10)) {
      landmark = FreshStartLandmarkType.seasonStart;
      landmarkTitle = 'آغاز فصل جدید';
    } else if (jalali.day == 1) {
      landmark = FreshStartLandmarkType.shamsiMonthStart;
      landmarkTitle = 'اول ماه ${jalali.formatter.mN}';
    } else if (input.now.weekday == DateTime.saturday) {
      landmark = FreshStartLandmarkType.saturday;
      landmarkTitle = 'شنبه و شروع هفته جدید';
    } else if (input.hijriDay == 1) {
      landmark = FreshStartLandmarkType.lunarMonthStart;
      landmarkTitle = 'اول ماه قمری';
    } else if (input.birthdayJalali != null) {
      final monthDay = '${jalali.month.toString().padLeft(2, '0')}-${jalali.day.toString().padLeft(2, '0')}';
      if (monthDay == input.birthdayJalali) {
        landmark = FreshStartLandmarkType.birthday;
        landmarkTitle = 'روز تولد شما';
      }
    }

    if (landmark == FreshStartLandmarkType.none) {
      return FreshStartOutput.none();
    }

    // Prepare fresh restart proposals for stagnant items
    final goalProposals = input.stagnantGoals.map((g) => {
      'id': g['id'],
      'title': g['title'],
      'type': 'goal',
      'actionOptions': ['REVIVE', 'DOWNSIZE', 'HONORABLE_ARCHIVE'],
      'message': 'به مناسبت $landmarkTitle، فرصت تازه‌ای برای بازتعریف یا احیای هدف «${g['title']}» داری.',
    }).toList();

    final routineProposals = input.deadRoutines.map((r) => {
      'id': r['id'],
      'title': r['title'],
      'type': 'routine',
      'actionOptions': ['RESTART_MINIMAL', 'RESCHEDULE', 'ARCHIVE'],
      'message': 'به مناسبت $landmarkTitle، می‌توانی روتین «${r['title']}» را با نسخهٔ حداقل از نو شروع کنی.',
    }).toList();

    return FreshStartOutput(
      isLandmarkDay: true,
      landmarkType: landmark,
      landmarkTitle: landmarkTitle,
      stagnantGoalProposals: goalProposals,
      deadRoutineProposals: routineProposals,
    );
  }
}
