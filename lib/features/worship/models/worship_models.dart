import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

// Helper to convert English digits to Persian digits
String toPersianDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  
  var output = input;
  for (var i = 0; i < english.length; i++) {
    output = output.replaceAll(english[i], persian[i]);
  }
  return output;
}

const hijriMonthsFa = {
  1: 'محرم',
  2: 'صفر',
  3: 'ربیع‌الاول',
  4: 'ربیع‌الثانی',
  5: 'جمادی‌الاول',
  6: 'جمادی‌الثانی',
  7: 'رجب',
  8: 'شعبان',
  9: 'رمضان',
  10: 'شوال',
  11: 'ذوالقعده',
  12: 'ذوالحجه',
};

class HijriDate {

  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
    required this.formatted,
  });

  factory HijriDate.fromMap(Map<String, dynamic> map) {
    return HijriDate(
      day: map['day'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
      monthName: map['monthName'] as String,
      formatted: map['formatted'] as String,
    );
  }
  final int day;
  final int month;
  final int year;
  final String monthName;
  final String formatted;

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'monthName': monthName,
      'formatted': formatted,
    };
  }

  static String _dateKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'hijri_date_${y}_${m}_$d';
  }

  static Future<HijriDate?> getOrFetch(DateTime date, Database db) async {
    // 0. Load offset from db settings
    var offset = 0;
    try {
      final offsetSetting = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['hijri_offset'],
        limit: 1,
      );
      if (offsetSetting.isNotEmpty) {
        offset = int.tryParse(offsetSetting.first['value']! as String) ?? 0;
      }
    } catch (_) {}

    final adjustedDate = offset != 0 ? date.add(Duration(days: offset)) : date;
    final key = _dateKey(adjustedDate);

    // 1. Check local cache
    final settings = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (settings.isNotEmpty) {
      try {
        final val = settings.first['value']! as String;
        final decoded = json.decode(val) as Map<String, dynamic>;
        return HijriDate.fromMap(decoded);
      } catch (e) {
        debugPrint('Error decoding cached Hijri date: $e');
      }
    }

    // 2. Check failure cooldown to prevent network spamming on timeouts
    final failKey = 'hijri_fail_$key';
    final failSettings = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [failKey],
      limit: 1,
    );
    if (failSettings.isNotEmpty) {
      try {
        final lastAttempt = int.parse(failSettings.first['value']! as String);
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (nowMs - lastAttempt < 60 * 60 * 1000) { // 1 hour cooldown
          return null;
        }
      } catch (_) {}
    }

    // 3. Try Iranian/Shia Calendar API (PNLdev) first
    try {
      final shamsi = Jalali.fromDateTime(adjustedDate);
      final url = Uri.parse('https://pnldev.com/api/calender?year=${shamsi.year}&month=${shamsi.month}&day=${shamsi.day}');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['status'] == true && decoded['result'] != null) {
          final moonData = decoded['result']['moon'] as Map<String, dynamic>;
          final hDay = moonData['day'] as int;
          final hMonthNumber = moonData['month'] as int;
          final hYear = moonData['year'] as int;
          final hMonthName = hijriMonthsFa[hMonthNumber] ?? '';

          final faDay = toPersianDigits(hDay.toString());
          final faMonth = hMonthName;
          final faYear = toPersianDigits(hYear.toString());
          final formatted = '$faDay $faMonth $faYear';

          final hijriObj = HijriDate(
            day: hDay,
            month: hMonthNumber,
            year: hYear,
            monthName: hMonthName,
            formatted: formatted,
          );

          final nowMs = DateTime.now().millisecondsSinceEpoch;
          await db.insert(
            'app_settings',
            {
              'key': key,
              'value': json.encode(hijriObj.toMap()),
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await db.delete('app_settings', where: 'key = ?', whereArgs: [failKey]);
          return hijriObj;
        }
      }
    } catch (e) {
      debugPrint('Error fetching Hijri date from PNLdev API: $e. Trying fallback...');
    }

    // 4. Fallback to Aladhan API
    try {
      final dayStr = adjustedDate.day.toString().padLeft(2, '0');
      final monthStr = adjustedDate.month.toString().padLeft(2, '0');
      final yearStr = adjustedDate.year.toString();
      final url = Uri.parse('https://api.aladhan.com/v1/gToH?date=$dayStr-$monthStr-$yearStr');
      
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['code'] == 200 && decoded['data'] != null) {
          final hijriData = decoded['data']['hijri'] as Map<String, dynamic>;
          final hDay = int.parse(hijriData['day'] as String);
          final hMonthNumber = hijriData['month']['number'] as int;
          final hYear = int.parse(hijriData['year'] as String);
          final hMonthName = hijriMonthsFa[hMonthNumber] ?? (hijriData['month']['en'] as String);

          final faDay = toPersianDigits(hDay.toString());
          final faMonth = hijriMonthsFa[hMonthNumber] ?? '';
          final faYear = toPersianDigits(hYear.toString());
          final formatted = '$faDay $faMonth $faYear';

          final hijriObj = HijriDate(
            day: hDay,
            month: hMonthNumber,
            year: hYear,
            monthName: hMonthName,
            formatted: formatted,
          );

          final nowMs = DateTime.now().millisecondsSinceEpoch;
          await db.insert(
            'app_settings',
            {
              'key': key,
              'value': json.encode(hijriObj.toMap()),
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await db.delete('app_settings', where: 'key = ?', whereArgs: [failKey]);
          return hijriObj;
        }
      }
    } catch (e) {
      debugPrint('Error fetching Hijri date from fallback network: $e. Using offline fallback...');
    }

    // 5. Offline Tabular Islamic Calendar Fallback (Kuwaiti Algorithm)
    try {
      final localHijri = _gregorianToHijri(adjustedDate);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {
          'key': key,
          'value': json.encode(localHijri.toMap()),
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.delete('app_settings', where: 'key = ?', whereArgs: [failKey]);
      return localHijri;
    } catch (e) {
      debugPrint('Error calculating offline Hijri date: $e');
    }
    return null;
  }

  static HijriDate _gregorianToHijri(DateTime date) {
    final day = date.day;
    final month = date.month;
    final year = date.year;
    
    var m = month;
    var y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    
    final a = y ~/ 100;
    var b = 2 - a + (a ~/ 4);
    if (y < 1583) b = 0;
    if (y == 1582) {
      if (m > 10) b = -10;
      if (m == 10) {
        b = 0;
        if (day > 4) b = -10;
      }
    }
    
    final jd = (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524;
    
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    
    final hMonth = (24 * l) ~/ 709;
    final hDay = l - (709 * hMonth) ~/ 24;
    final hYear = 30 * n + j - 30;
    
    final hMonthName = hijriMonthsFa[hMonth] ?? '';
    final faDay = toPersianDigits(hDay.toString());
    final faMonth = hMonthName;
    final faYear = toPersianDigits(hYear.toString());
    final formatted = '$faDay $faMonth $faYear';
    
    return HijriDate(
      day: hDay,
      month: hMonth,
      year: hYear,
      monthName: hMonthName,
      formatted: formatted,
    );
  }
}

class WorshipPractice {

  const WorshipPractice({
    required this.id,
    required this.practiceType,
    this.subType,
    required this.title,
    this.dailyTarget = 1,
    this.dailyDone = 0,
    this.totalTarget,
    this.totalDone = 0,
    this.reminderEnabled = false,
    this.reminderTime,
    this.reminderOffsetMinutes,
    this.reminderAnchor = 'NONE',
    this.reminderDaysOfWeek,
    this.reminderTimes,
    this.deferCount = 0,
    this.lastDeferredUntil,
    this.sortOrder = 0,
    this.isActive = true,
    this.allowQada = false,
    this.reminderFrequency = 'DAILY',
    this.notes,
    this.dailyDoneDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorshipPractice.fromMap(Map<String, dynamic> map) {
    return WorshipPractice(
      id: map['id'] as String,
      practiceType: map['practiceType'] as String,
      subType: map['subType'] as String?,
      title: map['title'] as String,
      dailyTarget: map['dailyTarget'] as int? ?? 1,
      dailyDone: map['dailyDone'] as int? ?? 0,
      totalTarget: map['totalTarget'] as int?,
      totalDone: map['totalDone'] as int? ?? 0,
      reminderEnabled: (map['reminderEnabled'] as int? ?? 0) == 1,
      reminderTime: map['reminderTime'] as String?,
      reminderOffsetMinutes: map['reminderOffsetMinutes'] as int?,
      reminderAnchor: map['reminderAnchor'] as String? ?? 'NONE',
      reminderDaysOfWeek: map['reminderDaysOfWeek'] as String?,
      reminderTimes: map['reminderTimes'] as String?,
      deferCount: map['deferCount'] as int? ?? 0,
      lastDeferredUntil: map['lastDeferredUntil'] as int?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      allowQada: (map['allowQada'] as int? ?? 0) == 1,
      reminderFrequency: map['reminderFrequency'] as String? ?? 'DAILY',
      notes: map['notes'] as String?,
      dailyDoneDate: map['dailyDoneDate'] as String?,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }
  final String id;
  final String practiceType; // 'PRAYER' / 'MUSTAHAB' / 'QURAN' / 'DHIKR'
  final String? subType;
  final String title;
  final int dailyTarget;
  final int dailyDone;
  final int? totalTarget;
  final int totalDone;
  final bool reminderEnabled;
  final String? reminderTime;
  final int? reminderOffsetMinutes;
  final String reminderAnchor;
  final String? reminderDaysOfWeek;
  final String? reminderTimes;
  final int deferCount;
  final int? lastDeferredUntil;
  final int sortOrder;
  final bool isActive;
  final bool allowQada;
  final String reminderFrequency; // 'DAILY' / 'WEEKLY' / 'MONTHLY'
  final String? notes;
  final String? dailyDoneDate;
  final int createdAt;
  final int updatedAt;

  bool get isDeferExhausted => deferCount >= 3;

  bool needsReset(String todayStr) {
    return dailyDoneDate != todayStr;
  }

  WorshipPractice copyWith({
    String? id,
    String? practiceType,
    String? subType,
    String? title,
    int? dailyTarget,
    int? dailyDone,
    int? totalTarget,
    int? totalDone,
    bool? reminderEnabled,
    String? reminderTime,
    int? reminderOffsetMinutes,
    String? reminderAnchor,
    String? reminderDaysOfWeek,
    String? reminderTimes,
    int? deferCount,
    int? lastDeferredUntil,
    int? sortOrder,
    bool? isActive,
    bool? allowQada,
    String? reminderFrequency,
    String? notes,
    String? dailyDoneDate,
    int? createdAt,
    int? updatedAt,
  }) {
    return WorshipPractice(
      id: id ?? this.id,
      practiceType: practiceType ?? this.practiceType,
      subType: subType ?? this.subType,
      title: title ?? this.title,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      dailyDone: dailyDone ?? this.dailyDone,
      totalTarget: totalTarget ?? this.totalTarget,
      totalDone: totalDone ?? this.totalDone,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      reminderAnchor: reminderAnchor ?? this.reminderAnchor,
      reminderDaysOfWeek: reminderDaysOfWeek ?? this.reminderDaysOfWeek,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      deferCount: deferCount ?? this.deferCount,
      lastDeferredUntil: lastDeferredUntil ?? this.lastDeferredUntil,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      allowQada: allowQada ?? this.allowQada,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      notes: notes ?? this.notes,
      dailyDoneDate: dailyDoneDate ?? this.dailyDoneDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'practiceType': practiceType,
      'subType': subType,
      'title': title,
      'dailyTarget': dailyTarget,
      'dailyDone': dailyDone,
      'totalTarget': totalTarget,
      'totalDone': totalDone,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderTime': reminderTime,
      'reminderOffsetMinutes': reminderOffsetMinutes,
      'reminderAnchor': reminderAnchor,
      'reminderDaysOfWeek': reminderDaysOfWeek,
      'reminderTimes': reminderTimes,
      'deferCount': deferCount,
      'lastDeferredUntil': lastDeferredUntil,
      'sortOrder': sortOrder,
      'isActive': isActive ? 1 : 0,
      'allowQada': allowQada ? 1 : 0,
      'reminderFrequency': reminderFrequency,
      'notes': notes,
      'dailyDoneDate': dailyDoneDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class PrayerTime {

  const PrayerTime({
    required this.date,
    required this.cityId,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.midnightShari,
    this.sunset = '',
    required this.calculationMethod,
    required this.ihtiyatMinutes,
  });

  factory PrayerTime.fromMap(Map<String, dynamic> map) {
    return PrayerTime(
      date: map['date'] as String,
      cityId: map['cityId'] as String,
      fajr: map['fajr'] as String,
      sunrise: map['sunrise'] as String,
      dhuhr: map['dhuhr'] as String,
      asr: map['asr'] as String,
      maghrib: map['maghrib'] as String,
      isha: map['isha'] as String,
      midnightShari: map['midnightShari'] as String,
      sunset: map['sunset'] as String? ?? '',
      calculationMethod: map['calculationMethod'] as String? ?? 'TEHRAN_GEOPHYSICS',
      ihtiyatMinutes: map['ihtiyatMinutes'] as int? ?? 10,
    );
  }
  final String date;
  final String cityId;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String midnightShari;
  final String sunset;
  final String calculationMethod;
  final int ihtiyatMinutes;

  MapEntry<String, DateTime> nextPrayer(DateTime now) {
    final times = {
      'FAJR': _parseTime(fajr, now),
      'SUNRISE': _parseTime(sunrise, now),
      'DHUHR': _parseTime(dhuhr, now),
      'ASR': _parseTime(asr, now),
      'MAGHRIB': _parseTime(maghrib, now),
      'ISHA': _parseTime(isha, now),
    };

    for (final entry in times.entries) {
      if (entry.value.isAfter(now)) {
        return entry;
      }
    }

    final tomorrow = now.add(const Duration(days: 1));
    return MapEntry('FAJR', _parseTime(fajr, tomorrow));
  }

  Duration countdown(MapEntry<String, DateTime> next) {
    return next.value.difference(DateTime.now());
  }

  DateTime _parseTime(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }
}

class WorshipDebt {

  WorshipDebt({
    required this.id,
    required this.debtType,
    required this.title,
    required this.totalCount,
    required this.remainingCount,
    required this.dailyTarget,
    required this.autoCreated,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorshipDebt.fromMap(Map<String, dynamic> map) {
    return WorshipDebt(
      id: map['id'] as String,
      debtType: map['debtType'] as String,
      title: map['title'] as String,
      totalCount: map['totalCount'] as int,
      remainingCount: map['remainingCount'] as int,
      dailyTarget: map['dailyTarget'] as int? ?? 0,
      autoCreated: (map['autoCreated'] as int? ?? 0) == 1,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }
  final String id;
  final String debtType; // 'PRAYER', 'FAST', 'ATONEMENT'
  final String title;
  final int totalCount;
  final int remainingCount;
  final int dailyTarget;
  final bool autoCreated;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;

  double get progressPercent {
    if (totalCount == 0) return 100;
    final done = totalCount - remainingCount;
    return (done / totalCount * 100).clamp(0.0, 100.0);
  }

  int get daysToFinish {
    if (remainingCount <= 0) return 0;
    if (dailyTarget <= 0) return 99999;
    return (remainingCount / dailyTarget).ceil();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtType': debtType,
      'title': title,
      'totalCount': totalCount,
      'remainingCount': remainingCount,
      'dailyTarget': dailyTarget,
      'autoCreated': autoCreated ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class WorshipSeason {

  WorshipSeason({
    required this.id,
    required this.seasonType,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.calendar,
    this.behaviorJson,
    required this.isActive,
    required this.priorityWeight,
    required this.createdAt,
  });

  factory WorshipSeason.fromMap(Map<String, dynamic> map) {
    return WorshipSeason(
      id: map['id'] as String,
      seasonType: (map['seasonType'] ?? map['type']) as String,
      title: map['title'] as String,
      startDate: (map['startDate'] ?? map['start_date']) as String,
      endDate: (map['endDate'] ?? map['end_date']) as String,
      calendar: map['calendar'] as String? ?? 'HIJRI',
      behaviorJson: map['behaviorJson'] as String?,
      isActive: ((map['isActive'] ?? map['is_active']) as int? ?? 1) == 1,
      priorityWeight: ((map['priority_weight'] ?? map['priorityWeight'] ?? 1.0) as num).toDouble(),
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
  final String id;
  final String seasonType;
  final String title;
  final String startDate;
  final String endDate;
  final String calendar;
  final String? behaviorJson;
  final bool isActive;
  final double priorityWeight;
  final int createdAt;

  bool isActiveNow([HijriDate? todayHijri]) {
    if (!isActive) return false;

    if (calendar.toUpperCase() == 'HIJRI') {
      if (todayHijri == null) return false;
      try {
        final startParts = startDate.split('-');
        final endParts = endDate.split('-');
        final startM = int.parse(startParts[startParts.length - 2]);
        final startD = int.parse(startParts.last);
        final endM = int.parse(endParts[endParts.length - 2]);
        final endD = int.parse(endParts.last);

        final currentM = todayHijri.month;
        final currentD = todayHijri.day;

        if (endM > startM || (endM == startM && endD >= startD)) {
          if (currentM > startM && currentM < endM) return true;
          if (currentM == startM && currentM == endM) {
            return currentD >= startD && currentD <= endD;
          }
          if (currentM == startM) return currentD >= startD;
          if (currentM == endM) return currentD <= endD;
          return false;
        } else {
          // Overlaps Hijri new year
          if (currentM > startM || currentM < endM) return true;
          if (currentM == startM) return currentD >= startD;
          if (currentM == endM) return currentD <= endD;
          return false;
        }
      } catch (e) {
        debugPrint('Error evaluating Hijri WorshipSeason active status ($startDate / $endDate): $e');
        return false;
      }
    }

    final now = DateTime.now();
    try {
      final todayStr = now.toIso8601String().substring(0, 10);
      if (startDate.length == 10 && endDate.length == 10) {
        return todayStr.compareTo(startDate) >= 0 && todayStr.compareTo(endDate) <= 0;
      }
      
      final currentYear = now.year;
      final start = DateTime.parse('$currentYear-$startDate');
      final end = DateTime.parse('$currentYear-$endDate');
      
      if (end.isBefore(start)) {
        final nextYearEnd = DateTime.parse('${currentYear + 1}-$endDate');
        final prevYearStart = DateTime.parse('${currentYear - 1}-$startDate');
        return (now.isAfter(start) && now.isBefore(nextYearEnd)) || 
               (now.isAfter(prevYearStart) && now.isBefore(end));
      }
      
      return now.isAfter(start.subtract(const Duration(days: 1))) && 
             now.isBefore(end.add(const Duration(days: 1)));
    } catch (e) {
      debugPrint('Error evaluating WorshipSeason active status: $e');
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seasonType': seasonType,
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'calendar': calendar,
      'behaviorJson': behaviorJson,
      'isActive': isActive ? 1 : 0,
      'priority_weight': priorityWeight,
      'createdAt': createdAt,
    };
  }
}
