import 'package:flutter/material.dart';

class QuickAddResult {

  QuickAddResult({
    required this.title,
    required this.itemType,
    this.timeOfDay,
    required this.recurrenceType,
    this.intervalDays,
    this.intervalHours,
    this.weekdays,
    this.daysOffset,
    this.targetDurationMinutes,
  });
  final String title;
  final String itemType; // 'ROUTINE' | 'REMINDER' | 'TASK'
  final TimeOfDay? timeOfDay;
  final String recurrenceType; // 'EVERY_DAY' | 'WORKDAYS' | 'CUSTOM_DAYS' | 'INTERVAL_HOURS' | 'INTERVAL_DAYS' | 'MONTHLY'
  final int? intervalDays;
  final int? intervalHours;
  final Set<int>? weekdays;
  final int? daysOffset;
  final int? targetDurationMinutes;
}

class QuickAddParser {
  static String _normalizeDigits(String text) {
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    var result = text;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persianDigits[i], englishDigits[i]);
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result;
  }

  static QuickAddResult parse(String rawText) {
    final text = _normalizeDigits(rawText);
    var itemType = 'ROUTINE';
    TimeOfDay? timeOfDay;
    var recurrenceType = 'EVERY_DAY';
    int? intervalDays;
    int? intervalHours;
    Set<int>? weekdays;
    int? targetDurationMinutes;

    // Parse Duration
    if (RegExp(r'یک\s*ساعت\s*و\s*نیم').hasMatch(text) || RegExp(r'1\s*ساعت\s*و\s*نیم').hasMatch(text)) {
      targetDurationMinutes = 90;
    } else if (RegExp(r'یک\s*ساعت').hasMatch(text) || RegExp(r'1\s*ساعت').hasMatch(text)) {
      targetDurationMinutes = 60;
    } else if (RegExp(r'نیم\s*ساعت').hasMatch(text)) {
      targetDurationMinutes = 30;
    } else if (RegExp(r'یه\s*ربع').hasMatch(text)) {
      targetDurationMinutes = 15;
    } else {
      final hourHalfRegex = RegExp(r'(?<!هر\s*)(\d+)\s*ساعت\s*و\s*نیم');
      final hourHalfMatch = hourHalfRegex.firstMatch(text);
      if (hourHalfMatch != null) {
        final h = int.tryParse(hourHalfMatch.group(1)!);
        if (h != null) {
          targetDurationMinutes = h * 60 + 30;
        }
      } else {
        final hourRegex = RegExp(r'(?<!هر\s*)(\d+)\s*ساعت');
        final hourMatch = hourRegex.firstMatch(text);
        if (hourMatch != null) {
          final h = int.tryParse(hourMatch.group(1)!);
          if (h != null) {
            targetDurationMinutes = h * 60;
          }
        } else {
          final minRegex = RegExp(r'(\d+)\s*دقیقه');
          final minMatch = minRegex.firstMatch(text);
          if (minMatch != null) {
            final m = int.tryParse(minMatch.group(1)!);
            if (m != null) {
              targetDurationMinutes = m;
            }
          }
        }
      }
    }

    // 1. Parse Item Type & Days Offset
    int? daysOffset;
    if (text.contains('پس فردا') || text.contains('پس‌فردا')) {
      daysOffset = 2;
    } else if (text.contains('فردا')) {
      daysOffset = 1;
    } else if (text.contains('امروز') || text.contains('امشب')) {
      daysOffset = 0;
    }

    if (text.contains('فردا') || text.contains('امروز') || text.contains('امشب') || text.contains('یکبار') || text.contains('تسک') || text.contains('کار') || text.contains('وظیفه')) {
      itemType = 'TASK';
    } else if (text.contains('یادآور') || text.contains('اعلان') || text.contains('هشدار') || text.contains('زنگ')) {
      itemType = 'REMINDER';
    }

    // 2. Parse Time
    int? parsedHour;
    int? parsedMinute;

    // Try matching HH:MM or HH و MM
    final timeColonRegex = RegExp(r'(?:ساعت\s+)?(\d{1,2})[:و](\d{2})');
    final timeColonMatch = timeColonRegex.firstMatch(text);
    if (timeColonMatch != null) {
      parsedHour = int.tryParse(timeColonMatch.group(1)!);
      parsedMinute = int.tryParse(timeColonMatch.group(2)!);
    } else {
      // Try matching HH نیم (e.g., 9 و نیم, ساعت 9 نیم)
      final timeHalfRegex = RegExp(r'(?:ساعت\s+)?(\d{1,2})\s*(?:و\s*)?نیم');
      final timeHalfMatch = timeHalfRegex.firstMatch(text);
      if (timeHalfMatch != null) {
        parsedHour = int.tryParse(timeHalfMatch.group(1)!);
        parsedMinute = 30;
      } else {
        // Try matching standalone hour followed by period indicator or preceded by ساعت
        final timeWordRegex = RegExp(r'(?:ساعت\s+(\d{1,2}))|(\d{1,2})\s*(?:صبح|عصر|شب|ظهر|بعد\s*از\s*ظهر)');
        final timeWordMatch = timeWordRegex.firstMatch(text);
        if (timeWordMatch != null) {
          final hrStr = timeWordMatch.group(1) ?? timeWordMatch.group(2);
          parsedHour = int.tryParse(hrStr!);
          parsedMinute = 0;
        }
      }
    }

    if (parsedHour != null) {
      final pmRegex = RegExp(r'(عصر|شب|بعد\s*از\s*ظهر|بعدازظهر|غروب)');
      if (pmRegex.hasMatch(text) && parsedHour < 12) {
        parsedHour += 12;
      }
      final amRegex = RegExp('(صبح|بامداد)');
      if (amRegex.hasMatch(text) && parsedHour == 12) {
        parsedHour = 0;
      }
      timeOfDay = TimeOfDay(hour: parsedHour, minute: parsedMinute ?? 0);
    }

    // 3. Parse Recurrence
    if (text.contains('هر روز') || text.contains('روزانه')) {
      recurrenceType = 'EVERY_DAY';
    } else if (text.contains('روزهای کاری') || text.contains('شنبه تا چهارشنبه')) {
      recurrenceType = 'WORKDAYS';
    } else if (text.contains('آخر هفته') || text.contains('پنجشنبه و جمعه') || text.contains('پنج‌شنبه و جمعه')) {
      recurrenceType = 'CUSTOM_DAYS';
      weekdays = {4, 5};
    } else {
      // Match "هر X روز"
      final intervalDaysRegex = RegExp(r'هر\s+(\d+)\s+روز');
      final intervalDaysMatch = intervalDaysRegex.firstMatch(text);
      if (intervalDaysMatch != null) {
        recurrenceType = 'INTERVAL_DAYS';
        intervalDays = int.tryParse(intervalDaysMatch.group(1)!);
      } else {
        // Match "هر X ساعت"
        final intervalHoursRegex = RegExp(r'هر\s+(\d+)\s+ساعت');
        final intervalHoursMatch = intervalHoursRegex.firstMatch(text);
        if (intervalHoursMatch != null) {
          recurrenceType = 'INTERVAL_HOURS';
          intervalHours = int.tryParse(intervalHoursMatch.group(1)!);
        }
      }
    }

    // Match weekdays if not already custom/workdays
    if (recurrenceType == 'EVERY_DAY') {
      final detectedDays = <int>{};
      final dayMap = {
        'شنبه': 6,
        'یکشنبه': 7,
        'یک‌شنبه': 7,
        'دوشنبه': 1,
        'سه شنبه': 2,
        'سه‌شنبه': 2,
        'چهارشنبه': 3,
        'پنجشنبه': 4,
        'پنج‌شنبه': 4,
        'جمعه': 5,
      };
      dayMap.forEach((key, val) {
        if (text.contains(key)) {
          detectedDays.add(val);
        }
      });
      if (detectedDays.isNotEmpty) {
        recurrenceType = 'CUSTOM_DAYS';
        weekdays = detectedDays;
      }
    }

    final cleanT = cleanTitle(
      rawText,
      cleanTime: timeOfDay != null,
      cleanRecurrence: recurrenceType != 'EVERY_DAY' || (weekdays != null && weekdays.isNotEmpty),
      cleanDuration: targetDurationMinutes != null,
      cleanDate: daysOffset != null,
    );

    return QuickAddResult(
      title: cleanT,
      itemType: itemType,
      timeOfDay: timeOfDay,
      recurrenceType: recurrenceType,
      intervalDays: intervalDays,
      intervalHours: intervalHours,
      weekdays: weekdays,
      daysOffset: daysOffset,
      targetDurationMinutes: targetDurationMinutes,
    );
  }

  static String cleanTitle(
    String rawText, {
    required bool cleanTime,
    required bool cleanRecurrence,
    required bool cleanDuration,
    required bool cleanDate,
  }) {
    final text = _normalizeDigits(rawText);
    var clean = rawText;

    if (cleanTime) {
      final timeColonRegex = RegExp(r'(?:ساعت\s+)?(\d{1,2})[:و](\d{2})');
      final timeColonMatch = timeColonRegex.firstMatch(text);
      if (timeColonMatch != null) {
        clean = clean.replaceAll(timeColonMatch.group(0)!, '');
      }
      final timeHalfRegex = RegExp(r'(?:ساعت\s+)?([۰-۹\d]{1,2})\s*(?:و\s*)?نیم');
      clean = clean.replaceAll(timeHalfRegex, '');

      final hourRegex = RegExp(r'(?:ساعت\s+)?([۰-۹\d]{1,2})\s*(?:صبح|عصر|شب|ظهر|بعد\s*از\s*ظهر)?');
      clean = clean.replaceAll(hourRegex, '');
    }

    if (cleanDuration) {
      clean = clean.replaceAll(RegExp(r'یک\s*ساعت\s*و\s*نیم'), '');
      clean = clean.replaceAll(RegExp(r'یک\s*ساعت'), '');
      clean = clean.replaceAll(RegExp(r'نیم\s*ساعت'), '');
      clean = clean.replaceAll(RegExp(r'یه\s*ربع'), '');
      clean = clean.replaceAll(RegExp(r'(?<!هر\s*)([۰-۹٠-٩\d]+)\s*ساعت\s*و\s*نیم'), '');
      clean = clean.replaceAll(RegExp(r'(?<!هر\s*)([۰-۹٠-٩\d]+)\s*ساعت'), '');
      clean = clean.replaceAll(RegExp(r'([۰-۹٠-٩\d]+)\s*دقیقه'), '');
    }

    final wordsToRemove = <String>[];
    if (cleanDate) {
      wordsToRemove.addAll(['فردا', 'امروز', 'امشب', 'پس فردا', 'پس‌فردا']);
    }
    if (cleanRecurrence) {
      wordsToRemove.addAll([
        'هر روز', 'روزانه', 'هر', 'روزهای کاری', 'شنبه تا چهارشنبه', 'آخر هفته', 'پنجشنبه و جمعه', 'پنج‌شنبه و جمعه',
        'شنبه', 'یکشنبه', 'یک‌شنبه', 'دوشنبه', 'سه شنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'پنج‌شنبه', 'جمعه', 'روال'
      ]);
    }

    if (cleanTime || cleanDate || cleanRecurrence) {
      wordsToRemove.addAll(['ساعت', 'صبح', 'عصر', 'شب', 'ظهر', 'بامداد', 'یادآور', 'اعلان', 'کار', 'وظیفه', 'هشدار', 'ثبت', 'ایجاد', 'افزودن']);
    }

    for (final word in wordsToRemove) {
      clean = clean.replaceAll(RegExp('\\b$word\\b|\\s+$word\\s+|^$word\\s+|\\s+$word\$'), ' ');
      clean = clean.replaceAll(word, ' ');
    }

    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) {
      clean = rawText.trim();
    }
    return clean;
  }
}
