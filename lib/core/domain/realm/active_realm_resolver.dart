import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/engines/zone_engine.dart';

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

enum RealmMode {
  normal,    // عادی: همه روتین‌ها عبور می‌کنند
  focus,     // تمرکز عمیق: فقط روتین‌های ضروری (isEssential) عبور می‌کنند
  silent,    // بی‌صدا: روتین‌های دارویی (medical) همیشه عبور می‌کنند، غیرضروری مسدود می‌شوند
}

RealmMode parseRealmMode(String? raw) {
  if (raw == null) return RealmMode.normal;
  switch (raw.toUpperCase()) {
    case 'FOCUS':
      return RealmMode.focus;
    case 'SILENT':
    case 'MUTE':
      return RealmMode.silent;
    case 'NORMAL':
    default:
      return RealmMode.normal;
  }
}

String realmModeToRaw(RealmMode mode) {
  switch (mode) {
    case RealmMode.focus:
      return 'FOCUS';
    case RealmMode.silent:
      return 'SILENT';
    case RealmMode.normal:
      return 'NORMAL';
  }
}

class RealmData {
  const RealmData({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.icon,
    required this.mode,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String colorHex;
  final String icon;
  final RealmMode mode;
  final bool isDefault;
  final int? createdAt;

  factory RealmData.fromMap(Map<String, dynamic> map) {
    return RealmData(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'قلمرو',
      colorHex: map['color'] as String? ?? '#6366F1',
      icon: map['icon'] as String? ?? '🎯',
      mode: parseRealmMode(map['mode'] as String?),
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': colorHex,
      'icon': icon,
      'mode': realmModeToRaw(mode),
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Color parseColor({Color fallback = const Color(0xFF6366F1)}) {
    try {
      var hex = colorHex.replaceAll('#', '').trim();
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }
}

class RealmScheduleData {
  const RealmScheduleData({
    required this.id,
    required this.zoneId,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    this.createdAt,
  });

  final String id;
  final String zoneId;
  final Set<int> daysOfWeek; // 1: Mon ... 7: Sun
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final int? createdAt;

  factory RealmScheduleData.fromMap(Map<String, dynamic> map) {
    final daysStr = map['daysOfWeek'] as String? ?? '';
    final days = daysStr
        .split(',')
        .map((d) => int.tryParse(d.trim()) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toSet();

    return RealmScheduleData(
      id: map['id'] as String,
      zoneId: map['zoneId'] as String,
      daysOfWeek: days,
      startTime: map['startTime'] as String? ?? '00:00',
      endTime: map['endTime'] as String? ?? '23:59',
      createdAt: map['createdAt'] as int?,
    );
  }
}

sealed class ActiveRealmState {
  const ActiveRealmState();

  bool get isActive => this is ScheduledRealmState || this is ManualRealmState;
  bool get isFree => this is FreeRealmState;
}

final class ScheduledRealmState extends ActiveRealmState {
  const ScheduledRealmState({
    required this.realm,
    required this.schedule,
    required this.remaining,
    required this.progress,
    required this.explanation,
  });

  final RealmData realm;
  final RealmScheduleData schedule;
  final Duration remaining;
  final double progress; // 0.0 to 1.0
  final String explanation;
}

final class ManualRealmState extends ActiveRealmState {
  const ManualRealmState({
    required this.realm,
    required this.expireAt,
    required this.remaining,
    required this.progress,
    required this.explanation,
    this.nextRealmName,
    this.nextRealmTimeStr,
  });

  final RealmData realm;
  final DateTime expireAt;
  final Duration remaining;
  final double progress; // 0.0 to 1.0
  final String explanation;
  final String? nextRealmName;
  final String? nextRealmTimeStr;
}

final class FreeRealmState extends ActiveRealmState {
  const FreeRealmState({this.explanation = 'الان در زمان آزاد هستی و هیچ قلمرویی فعال نیست.'});
  final String explanation;
}

final class RealmErrorState extends ActiveRealmState {
  const RealmErrorState(this.error);
  final Object error;
}

class ActiveRealmResolver {
  const ActiveRealmResolver({this.clock = const SystemClock()});

  final Clock clock;

  /// Resolves the currently active realm state given loaded realms, schedules, and manual override.
  ActiveRealmState resolve({
    required List<RealmData> realms,
    required List<RealmScheduleData> schedules,
    String? overrideRealmId,
    int? overrideUntilMs,
  }) {
    final now = clock.now();
    final nowMs = now.millisecondsSinceEpoch;

    // 1. Check manual override state
    if (overrideRealmId != null &&
        overrideRealmId.isNotEmpty &&
        overrideUntilMs != null &&
        nowMs < overrideUntilMs) {
      final overrideRealm = realms.firstWhere(
        (r) => r.id == overrideRealmId,
        orElse: () => RealmData(
          id: overrideRealmId,
          name: 'قلمرو دستی',
          colorHex: '#6366F1',
          icon: '🎯',
          mode: RealmMode.normal,
        ),
      );

      final expireAt = DateTime.fromMillisecondsSinceEpoch(overrideUntilMs);
      final remaining = expireAt.difference(now);

      // Find next scheduled realm to build honest explanation
      final nextSchedule = _findNextSchedule(now, realms, schedules);

      final explanation = 'چون خودت تا ساعت ${_formatTime(expireAt)} این قلمرو را به صورت دستی فعال کردی.';

      return ManualRealmState(
        realm: overrideRealm,
        expireAt: expireAt,
        remaining: remaining.isNegative ? Duration.zero : remaining,
        progress: 1.0,
        explanation: explanation,
        nextRealmName: nextSchedule?.realm.name,
        nextRealmTimeStr: nextSchedule != null ? _formatTime(nextSchedule.scheduleStartDt) : null,
      );
    }

    // 2. Check scheduled realms
    final activeMatchingSchedules = <({RealmData realm, RealmScheduleData schedule, int durationMin, DateTime startDt, DateTime endDt})>[];

    final currentWeekday = now.weekday;

    for (final schedule in schedules) {
      if (!schedule.daysOfWeek.contains(currentWeekday)) {
        continue;
      }

      final isWithin = ZoneEngine.isTimeWithinRange(
        time: now,
        startTimeStr: schedule.startTime,
        endTimeStr: schedule.endTime,
      );

      if (isWithin) {
        final realm = realms.firstWhere(
          (r) => r.id == schedule.zoneId,
          orElse: () => RealmData(
            id: schedule.zoneId,
            name: 'قلمرو زمان‌بندی‌شده',
            colorHex: '#6366F1',
            icon: '🎯',
            mode: RealmMode.normal,
          ),
        );

        final times = _calculateScheduleBounds(now, schedule.startTime, schedule.endTime);
        final durMin = times.endDt.difference(times.startDt).inMinutes;

        activeMatchingSchedules.add((
          realm: realm,
          schedule: schedule,
          durationMin: durMin > 0 ? durMin : 1,
          startDt: times.startDt,
          endDt: times.endDt,
        ));
      }
    }

    if (activeMatchingSchedules.isEmpty) {
      return const FreeRealmState();
    }

    // Priority Rule (ق-۹):
    // 1. Shorter duration schedule wins (more specific window)
    // 2. Tie-breaker: Newer created date
    activeMatchingSchedules.sort((a, b) {
      final durComp = a.durationMin.compareTo(b.durationMin);
      if (durComp != 0) return durComp;
      final aCreated = a.realm.createdAt ?? 0;
      final bCreated = b.realm.createdAt ?? 0;
      return bCreated.compareTo(aCreated);
    });

    final winner = activeMatchingSchedules.first;
    final totalDuration = winner.endDt.difference(winner.startDt);
    final elapsed = now.difference(winner.startDt);
    final remaining = winner.endDt.difference(now);

    final progress = totalDuration.inSeconds > 0
        ? (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0)
        : 1.0;

    final explanation =
        'چون امروز ${_weekdayFa(now.weekday)} است و ساعت ${_formatTime(now)} در بازه ${_formatTime(winner.startDt)} الی ${_formatTime(winner.endDt)} قلمرو «${winner.realm.name}» قرار دارد.';

    return ScheduledRealmState(
      realm: winner.realm,
      schedule: winner.schedule,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      progress: progress,
      explanation: explanation,
    );
  }

  static ({DateTime startDt, DateTime endDt}) _calculateScheduleBounds(
      DateTime now, String startTimeStr, String endTimeStr) {
    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');
    final startH = int.tryParse(startParts[0]) ?? 0;
    final startM = int.tryParse(startParts[1]) ?? 0;
    final endH = int.tryParse(endParts[0]) ?? 0;
    final endM = int.tryParse(endParts[1]) ?? 0;

    var startDt = DateTime(now.year, now.month, now.day, startH, startM);
    var endDt = DateTime(now.year, now.month, now.day, endH, endM);

    if (startDt.isAfter(endDt)) {
      // Cross-midnight range e.g. 23:00 to 05:00
      if (now.hour < endH || (now.hour == endH && now.minute < endM)) {
        // We are in the early morning part (after midnight)
        startDt = startDt.subtract(const Duration(days: 1));
      } else {
        // We are in the late night part (before midnight)
        endDt = endDt.add(const Duration(days: 1));
      }
    }

    return (startDt: startDt, endDt: endDt);
  }

  static ({RealmData realm, DateTime scheduleStartDt})? _findNextSchedule(
      DateTime now, List<RealmData> realms, List<RealmScheduleData> schedules) {
    // Check upcoming schedules for today and tomorrow
    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final checkDate = now.add(Duration(days: dayOffset));
      final checkWeekday = checkDate.weekday;

      for (final s in schedules) {
        if (!s.daysOfWeek.contains(checkWeekday)) continue;
        final bounds = _calculateScheduleBounds(checkDate, s.startTime, s.endTime);
        if (bounds.startDt.isAfter(now)) {
          final realm = realms.firstWhere((r) => r.id == s.zoneId,
              orElse: () => RealmData(id: s.zoneId, name: 'قلمرو', colorHex: '#6366F1', icon: '🎯', mode: RealmMode.normal));
          return (realm: realm, scheduleStartDt: bounds.startDt);
        }
      }
    }
    return null;
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _weekdayFa(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'شنبه';
      case DateTime.sunday:
        return 'یکشنبه';
      case DateTime.monday:
        return 'دوشنبه';
      case DateTime.tuesday:
        return 'سه‌شنبه';
      case DateTime.wednesday:
        return 'چهارشنبه';
      case DateTime.thursday:
        return 'پنج‌شنبه';
      case DateTime.friday:
        return 'جمعه';
      default:
        return '';
    }
  }
}
