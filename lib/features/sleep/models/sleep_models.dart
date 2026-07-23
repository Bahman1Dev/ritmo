
enum SleepQuality {
  terrible,
  poor,
  fair,
  good,
  excellent;

  String get label {
    switch (this) {
      case SleepQuality.terrible: return 'خیلی بد';
      case SleepQuality.poor: return 'ضعیف';
      case SleepQuality.fair: return 'متوسط';
      case SleepQuality.good: return 'خوب';
      case SleepQuality.excellent: return 'عالی';
    }
  }

  String get emoji {
    switch (this) {
      case SleepQuality.terrible: return '😫';
      case SleepQuality.poor: return '🥱';
      case SleepQuality.fair: return '😐';
      case SleepQuality.good: return '🙂';
      case SleepQuality.excellent: return '😴';
    }
  }

  int get score {
    switch (this) {
      case SleepQuality.terrible: return 1;
      case SleepQuality.poor: return 2;
      case SleepQuality.fair: return 3;
      case SleepQuality.good: return 4;
      case SleepQuality.excellent: return 5;
    }
  }

  static SleepQuality fromInt(int val) {
    if (val <= 1) return SleepQuality.terrible;
    if (val == 2) return SleepQuality.poor;
    if (val == 3) return SleepQuality.fair;
    if (val == 4) return SleepQuality.good;
    return SleepQuality.excellent;
  }
}

class SleepTarget {

  SleepTarget({
    required this.bedtime,
    required this.wake,
    required this.durationMinutes,
  });

  factory SleepTarget.defaultTarget() {
    return SleepTarget(bedtime: '23:30', wake: '07:00', durationMinutes: 450);
  }
  final String bedtime; // "HH:mm"
  final String wake;    // "HH:mm"
  final int durationMinutes;

  int get bedtimeHour => int.parse(bedtime.split(':')[0]);
  int get bedtimeMinute => int.parse(bedtime.split(':')[1]);

  int get wakeHour => int.parse(wake.split(':')[0]);
  int get wakeMinute => int.parse(wake.split(':')[1]);
}

class SleepLog {

  SleepLog({
    required this.date,
    required this.reason,
    this.note,
    required this.createdAt,
    this.bedtimeAt,
    this.wakeAt,
    required this.durationMinutes,
    required this.quality,
    this.awakenings = 0,
  });

  factory SleepLog.fromMap(Map<String, dynamic> map) {
    return SleepLog(
      date: map['date'] as String,
      reason: map['reason'] as String? ?? '',
      note: map['note'] as String?,
      createdAt: map['createdAt'] as int? ?? 0,
      bedtimeAt: map['bedtimeAt'] as int?,
      wakeAt: map['wakeAt'] as int?,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      quality: SleepQuality.fromInt(map['quality'] as int? ?? 3),
      awakenings: map['awakenings'] as int? ?? 0,
    );
  }
  final String date; // YYYY-MM-DD
  final String reason;
  final String? note;
  final int createdAt;
  final int? bedtimeAt; // ms epoch
  final int? wakeAt;    // ms epoch
  final int durationMinutes;
  final SleepQuality quality;
  final int awakenings;

  int get durationFromTimes {
    if (bedtimeAt != null && wakeAt != null) {
      return (wakeAt! - bedtimeAt!) ~/ 60000;
    }
    return durationMinutes;
  }

  bool isOnTarget(SleepTarget target) {
    final dev = deviationMinutes(target);
    return dev <= 30 && durationMinutes >= target.durationMinutes;
  }

  int deviationMinutes(SleepTarget target) {
    if (bedtimeAt == null) return 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(bedtimeAt!);
    final targetMinutes = target.bedtimeHour * 60 + target.bedtimeMinute;
    final actualMinutes = dt.hour * 60 + dt.minute;
    
    var diff = (actualMinutes - targetMinutes).abs();
    if (diff > 720) {
      diff = 1440 - diff;
    }
    return diff;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'reason': reason,
      'note': note,
      'createdAt': createdAt,
      'bedtimeAt': bedtimeAt,
      'wakeAt': wakeAt,
      'durationMinutes': durationMinutes,
      'quality': quality.score,
      'awakenings': awakenings,
    };
  }
}
