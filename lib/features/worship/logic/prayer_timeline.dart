import 'package:ritmo/features/worship/models/worship_models.dart';

class PrayerSlot {
  const PrayerSlot({
    required this.key,
    required this.titleFa,
    required this.at,
    required this.isPrayer,
  });

  final String key; // FAJR|SUNRISE|DHUHR|ASR|MAGHRIB|ISHA|MIDNIGHT_SHARI
  final String titleFa;
  final DateTime at;
  final bool isPrayer;
}

class PrayerTimeline {
  const PrayerTimeline._();

  static List<PrayerSlot> slotsFor(
    PrayerTime times,
    DateTime date, {
    bool includeAsrIsha = true,
  }) {
    final slots = <PrayerSlot>[];

    void addSlot(String key, String titleFa, String? timeStr, bool isPrayer) {
      if (timeStr == null || timeStr.isEmpty) return;
      final parts = timeStr.split(':');
      final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
      final at = DateTime(date.year, date.month, date.day, h, m);
      slots.add(PrayerSlot(key: key, titleFa: titleFa, at: at, isPrayer: isPrayer));
    }

    addSlot('FAJR', 'اذان صبح', times.fajr, true);
    addSlot('SUNRISE', 'طلوع آفتاب', times.sunrise, false);
    addSlot('DHUHR', 'اذان ظهر', times.dhuhr, true);
    if (includeAsrIsha) {
      addSlot('ASR', 'اذان عصر', times.asr, true);
    }
    addSlot('MAGHRIB', 'اذان مغرب', times.maghrib, true);
    if (includeAsrIsha) {
      addSlot('ISHA', 'اذان عشا', times.isha, true);
    }
    addSlot('MIDNIGHT_SHARI', 'نیمه‌شب شرعی', times.midnightShari, false);

    slots.sort((a, b) => a.at.compareTo(b.at));
    return slots;
  }

  static PrayerSlot? next(
    PrayerTime times,
    DateTime now, {
    bool includeAsrIsha = true,
  }) {
    final todaySlots = slotsFor(times, now, includeAsrIsha: includeAsrIsha);

    for (final slot in todaySlots) {
      if (slot.at.isAfter(now)) {
        return slot;
      }
    }

    // All slots today passed -> Tomorrow Fajr
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowSlots = slotsFor(times, tomorrow, includeAsrIsha: includeAsrIsha);
    if (tomorrowSlots.isNotEmpty) {
      return tomorrowSlots.firstWhere(
        (s) => s.isPrayer,
        orElse: () => tomorrowSlots.first,
      );
    }

    return null;
  }

  static PrayerSlot? currentWindow(PrayerTime times, DateTime now) {
    final slots = slotsFor(times, now, includeAsrIsha: true);
    for (int i = 0; i < slots.length; i++) {
      final cur = slots[i];
      final nextAt = (i + 1 < slots.length) ? slots[i + 1].at : slots[0].at.add(const Duration(days: 1));
      if ((now.isAfter(cur.at) || now.isAtSameMomentAs(cur.at)) && now.isBefore(nextAt)) {
        return cur;
      }
    }
    return null;
  }

  static DateTime? deadlineFor(String prayerKey, PrayerTime times, DateTime date) {
    final slots = slotsFor(times, date, includeAsrIsha: true);

    String? deadlineKey;
    switch (prayerKey.toUpperCase()) {
      case 'FAJR':
        deadlineKey = 'SUNRISE';
      case 'DHUHR':
      case 'ASR':
        deadlineKey = 'MAGHRIB';
      case 'MAGHRIB':
      case 'ISHA':
        deadlineKey = 'MIDNIGHT_SHARI';
    }

    if (deadlineKey == null) return null;

    final match = slots.firstWhere(
      (s) => s.key == deadlineKey,
      orElse: () => PrayerSlot(key: '', titleFa: '', at: date.add(const Duration(hours: 23, minutes: 59)), isPrayer: false),
    );

    return match.key.isNotEmpty ? match.at : null;
  }
}
