// lib/features/worship/logic/prayer_timeline.dart
// Updated for Prompt 048 W-5: PrayerTimeline now works with PrayerTimes
// (full DateTime fields). Legacy PrayerTime (HH:mm) API preserved for
// backward compatibility during migration.

import 'package:ritmo/features/worship/logic/prayer_times.dart';
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

  // ── New API: works with PrayerTimes (DateTime-based) ────────────────────

  /// Returns all slots for [times] as a time-ordered list (W-5).
  static List<PrayerSlot> slotsForTimes(
    PrayerTimes times, {
    bool includeAsrIsha = true,
  }) {
    var midnightShari = times.midnightShari;
    if (midnightShari.isBefore(times.maghrib)) {
      midnightShari = midnightShari.add(const Duration(days: 1));
    }

    final slots = <PrayerSlot>[
      PrayerSlot(key: 'FAJR', titleFa: 'اذان صبح', at: times.fajr, isPrayer: true),
      PrayerSlot(key: 'SUNRISE', titleFa: 'طلوع آفتاب', at: times.sunrise, isPrayer: false),
      PrayerSlot(key: 'DHUHR', titleFa: 'اذان ظهر', at: times.dhuhr, isPrayer: true),
      if (includeAsrIsha)
        PrayerSlot(key: 'ASR', titleFa: 'اذان عصر', at: times.asr, isPrayer: true),
      PrayerSlot(key: 'MAGHRIB', titleFa: 'اذان مغرب', at: times.maghrib, isPrayer: true),
      if (includeAsrIsha)
        PrayerSlot(key: 'ISHA', titleFa: 'اذان عشا', at: times.isha, isPrayer: true),
      PrayerSlot(key: 'MIDNIGHT_SHARI', titleFa: 'نیمه‌شب شرعی', at: midnightShari, isPrayer: false),
    ];
    slots.sort((a, b) => a.at.compareTo(b.at));
    return slots;
  }

  /// Returns the PrayerSlot for a given prayer subType key (e.g. 'FAJR', 'ASR').
  static PrayerSlot? getSlotFor(String subType, PrayerTimes times) {
    final slots = slotsForTimes(times, includeAsrIsha: true);
    final key = subType.toUpperCase();
    try {
      return slots.firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Deadline DateTime for a given prayer key (W-5).
  /// FAJR → SUNRISE, DHUHR/ASR → MAGHRIB, MAGHRIB/ISHA → MIDNIGHT_SHARI.
  static DateTime? deadlineForSlot(String prayerKey, PrayerTimes times) {
    final slots = slotsForTimes(times, includeAsrIsha: true);
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
    try {
      return slots.firstWhere((s) => s.key == deadlineKey).at;
    } catch (_) {
      return null;
    }
  }

  /// Next prayer slot after [now] using new PrayerTimes.
  static PrayerSlot? nextFromTimes(PrayerTimes times, DateTime now, {bool includeAsrIsha = true}) {
    for (final slot in slotsForTimes(times, includeAsrIsha: includeAsrIsha)) {
      if (slot.at.isAfter(now)) return slot;
    }
    return null;
  }

  /// Current active prayer window using new PrayerTimes.
  static PrayerSlot? currentWindowFromTimes(PrayerTimes times, DateTime now) {
    final slots = slotsForTimes(times, includeAsrIsha: true);
    for (var i = 0; i < slots.length; i++) {
      final cur = slots[i];
      final nextAt = (i + 1 < slots.length)
          ? slots[i + 1].at
          : slots[0].at.add(const Duration(days: 1));
      if ((now.isAfter(cur.at) || now.isAtSameMomentAs(cur.at)) && now.isBefore(nextAt)) {
        return cur;
      }
    }
    return null;
  }

  // ── Legacy API: works with old PrayerTime (HH:mm strings) ───────────────
  // Preserved for backward compatibility during migration.

  static List<PrayerSlot> slotsFor(
    PrayerTime times,
    DateTime date, {
    bool includeAsrIsha = true,
  }) {
    final slots = <PrayerSlot>[];

    final maghribParts = times.maghrib.split(':');
    final maghribH = int.tryParse(maghribParts.isNotEmpty ? maghribParts[0] : '') ?? 19;

    void addSlot(String key, String titleFa, String? timeStr, bool isPrayer) {
      if (timeStr == null || timeStr.isEmpty) return;
      final parts = timeStr.split(':');
      final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
      var dt = DateTime(date.year, date.month, date.day, h, m);
      if (key == 'MIDNIGHT_SHARI' && h < maghribH) {
        dt = dt.add(const Duration(days: 1));
      }
      slots.add(PrayerSlot(
        key: key,
        titleFa: titleFa,
        at: dt,
        isPrayer: isPrayer,
      ));
    }

    addSlot('FAJR', 'اذان صبح', times.fajr, true);
    addSlot('SUNRISE', 'طلوع آفتاب', times.sunrise, false);
    addSlot('DHUHR', 'اذان ظهر', times.dhuhr, true);
    if (includeAsrIsha) addSlot('ASR', 'اذان عصر', times.asr, true);
    addSlot('MAGHRIB', 'اذان مغرب', times.maghrib, true);
    if (includeAsrIsha) addSlot('ISHA', 'اذان عشا', times.isha, true);
    addSlot('MIDNIGHT_SHARI', 'نیمه‌شب شرعی', times.midnightShari, false);

    slots.sort((a, b) => a.at.compareTo(b.at));
    return slots;
  }

  static PrayerSlot? next(PrayerTime times, DateTime now, {bool includeAsrIsha = true}) {
    for (final slot in slotsFor(times, now, includeAsrIsha: includeAsrIsha)) {
      if (slot.at.isAfter(now)) return slot;
    }
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowSlots = slotsFor(times, tomorrow, includeAsrIsha: includeAsrIsha);
    if (tomorrowSlots.isNotEmpty) {
      return tomorrowSlots.firstWhere((s) => s.isPrayer, orElse: () => tomorrowSlots.first);
    }
    return null;
  }

  static PrayerSlot? currentWindow(PrayerTime times, DateTime now) {
    final slots = slotsFor(times, now, includeAsrIsha: true);
    for (var i = 0; i < slots.length; i++) {
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
    try {
      return slots.firstWhere((s) => s.key == deadlineKey).at;
    } catch (_) {
      return null;
    }
  }
}
