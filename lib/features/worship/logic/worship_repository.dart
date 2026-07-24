import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';

/// Central repository for the Worship domain.
///
/// Single source of truth for prayer times calculation, active worship
/// practices, and worship settings. All other domains (Home, Calendar, AI)
/// read from this repository rather than querying `iran_cities` or computing
/// prayer times independently.
class WorshipRepository {
  WorshipRepository._();
  static final WorshipRepository instance = WorshipRepository._();

  final Map<String, Map<String, String>> _prayerTimesCache = {};
  List<Map<String, dynamic>>? _cachedPrayerPractices;
  List<Map<String, dynamic>>? _cachedMustahabPractices;

  /// Invalidate in-memory cached practices when settings/practices change.
  void invalidateCache() {
    _prayerTimesCache.clear();
    _cachedPrayerPractices = null;
    _cachedMustahabPractices = null;
  }

  /// Get calculated prayer times for a specific date using settings and city configuration.
  Future<Map<String, String>> getPrayerTimesForDate(DateTime date, {Map<String, String>? settingsMap}) async {
    final db = await DatabaseHelper.instance.database;

    final settings = settingsMap ??
        {
          for (final row in await db.query('app_settings'))
            row['key']! as String: row['value']! as String
        };

    final cityId = settings['prayer_city_id'] ?? settings['home_city_id'] ?? 'TEHRAN_TEHRAN';
    final dateStr = date.toIso8601String().substring(0, 10);
    final cacheKey = '$cityId|$dateStr';

    if (_prayerTimesCache.containsKey(cacheKey)) {
      return _prayerTimesCache[cacheKey]!;
    }

    try {
      final times = await PrayerTimeProvider.instance.getPrayerTimesForDate(
        cityId: cityId,
        date: date,
      );
      _prayerTimesCache[cacheKey] = times;
      return times;
    } catch (e) {
      debugPrint('[WorshipRepository] Failed to calculate prayer times: $e');
      return const {};
    }
  }

  /// Fetch active prayer and mustahab practices.
  Future<({List<Map<String, dynamic>> prayers, List<Map<String, dynamic>> mustahab})> getActivePractices() async {
    if (_cachedPrayerPractices != null && _cachedMustahabPractices != null) {
      return (prayers: _cachedPrayerPractices!, mustahab: _cachedMustahabPractices!);
    }

    final db = await DatabaseHelper.instance.database;
    final practices = await db.query(
      'worship_practices',
      where: 'isActive = 1',
    );

    final prayers = <Map<String, dynamic>>[];
    final mustahab = <Map<String, dynamic>>[];

    for (final p in practices) {
      final type = p['practiceType'] as String? ?? '';
      if (type == 'PRAYER') {
        prayers.add(Map<String, dynamic>.from(p));
      } else if (type == 'MUSTAHAB' || type == 'QURAN' || type == 'DHIKR') {
        if (p['reminderEnabled'] == 1) {
          mustahab.add(Map<String, dynamic>.from(p));
        }
      }
    }

    _cachedPrayerPractices = prayers;
    _cachedMustahabPractices = mustahab;

    return (prayers: prayers, mustahab: mustahab);
  }
}
