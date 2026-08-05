import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/features/worship/logic/hijri_calendar.dart';
import 'package:ritmo/features/worship/logic/prayer_timeline.dart';
import 'package:ritmo/features/worship/logic/prayer_times.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:sqflite/sqflite.dart';

export 'package:ritmo/features/worship/logic/prayer_times.dart';

// ─── Engine-local models ─────────────────────────────────────────────────────

/// All data needed to render a single worship day, fetched in one batch.
class WorshipDay {
  const WorshipDay({
    required this.date,
    required this.hijri,
    required this.times,
    required this.practices,
    required this.seasons,
    required this.context,
    required this.occasions,
  });

  final DateTime date;
  final HijriDate hijri;
  final PrayerTimes times;
  final List<WorshipPracticeState> practices;
  final List<WorshipSeason> seasons;
  final WorshipDayContext context;
  final List<OccasionItem> occasions;
}

/// The state of a single worship practice on a specific day.
class WorshipPracticeState {
  const WorshipPracticeState({
    required this.practice,
    required this.countDone,
    required this.countTarget,
    this.resultType,
    this.qualityWindow,
    this.windowStart,
    this.windowEnd,
  });

  final WorshipPractice practice;
  final int countDone;
  final int countTarget;

  /// DONE | SKIPPED | PARTIAL | QADA_ADDED | MISSED | null
  final String? resultType;

  /// EARLY | NORMAL | LATE | null
  final String? qualityWindow;

  /// Prayer window start (prayers only)
  final DateTime? windowStart;

  /// Prayer window end (prayers only)
  final DateTime? windowEnd;

  bool get isDone => resultType == 'DONE';
  bool get isSkipped => resultType == 'SKIPPED';
  bool get isMissed => resultType == 'MISSED';
  bool get isPending => resultType == null;
}

/// Result of a worship log operation — never throws for business paths.
sealed class WorshipLogResult {}

class WorshipLogOk extends WorshipLogResult {
  WorshipLogOk(this.undoToken);
  final String undoToken;
}

class WorshipLogBlocked extends WorshipLogResult {
  WorshipLogBlocked(this.reasonCode, this.userMessage);

  /// SUSPENDED_BY_CYCLE | QUOTA_EXHAUSTED | NOT_YET_DUE
  final String reasonCode;

  /// Friendly Persian message for display
  final String userMessage;
}

class WorshipLogFailed extends WorshipLogResult {
  WorshipLogFailed(this.error);
  final Object error;
}

/// Soft streak — ratio-based, not hard consecutive-days.
class SoftStreak {
  const SoftStreak({
    required this.daysDone,
    required this.windowDays,
    required this.currentRun,
  });

  final int daysDone;
  final int windowDays;
  final int currentRun;

  double get ratio => windowDays == 0 ? 0 : daysDone / windowDays;
}

/// Traveller / exemption context for a calendar day.
class WorshipDayContext {
  const WorshipDayContext({
    required this.date,
    this.isTraveller = false,
    this.fastingExempt = false,
    this.prayerExempt = false,
    this.reason,
  });

  factory WorshipDayContext.fromMap(Map<String, dynamic> m) {
    return WorshipDayContext(
      date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
      isTraveller: (m['isTraveller'] as int? ?? 0) == 1,
      fastingExempt: (m['fastingExempt'] as int? ?? 0) == 1,
      prayerExempt: (m['prayerExempt'] as int? ?? 0) == 1,
      reason: m['reason'] as String?,
    );
  }

  final DateTime date;
  final bool isTraveller;
  final bool fastingExempt;
  final bool prayerExempt;

  /// TRAVEL | MENSTRUATION | ILLNESS | MANUAL
  final String? reason;

  String get _isoDate => date.toIso8601String().substring(0, 10);

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'date': _isoDate,
      'isTraveller': isTraveller ? 1 : 0,
      'fastingExempt': fastingExempt ? 1 : 0,
      'prayerExempt': prayerExempt ? 1 : 0,
      'reason': reason,
      'createdAt': now,
      'updatedAt': now,
    };
  }
}

/// Debt augmented with estimated finish date and on-track ratio.
class WorshipDebtView {
  const WorshipDebtView({
    required this.debt,
    this.estimatedFinishDate,
    required this.onTrackRatio,
  });

  final WorshipDebt debt;
  final DateTime? estimatedFinishDate;
  final double onTrackRatio;
}

/// Occasion from the worship_occasions asset JSON.
class OccasionItem {
  const OccasionItem({
    required this.titleFa,
    required this.kind,
    required this.calendarType,
  });

  final String titleFa;

  /// NATIONAL | CELEBRATION | MOURNING | RELIGIOUS
  final String kind;

  /// 'solar' | 'hijri'
  final String calendarType;
}

// ─── WorshipEngine ──────────────────────────────────────────────────────────

/// Central engine for the Worship module (Prompt 048, Phase 1.4).
/// Every DB read/write in the worship module MUST go through here.
/// No widget may call [DatabaseHelper.instance.database] directly.
class WorshipEngine {
  WorshipEngine._();
  static final WorshipEngine instance = WorshipEngine._();

  // ── Cache ────────────────────────────────────────────────────────────────
  final Map<String, WorshipDay> _dayCache = {};
  Map<String, dynamic>? _settingsCache;
  List<OccasionItem>? _occasionsCache;

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _loadSettings(DatabaseExecutor db) async {
    if (_settingsCache != null) return _settingsCache!;
    const keys = [
      'prayer_city_id',
      'prayer_calculation_method',
      'ihtiyat_minutes',
      'show_asr_isha_prayers',
      'hijri_offset',
      'last_worship_sweep_date',
      'module_religion_enabled',
    ];
    final rows = await db.query(
      'app_settings',
      columns: ['key', 'value'],
      where: 'key IN (${List.filled(keys.length, '?').join(',')})',
      whereArgs: keys,
    );
    final map = <String, dynamic>{};
    for (final r in rows) {
      map[r['key'] as String] = r['value'];
    }
    _settingsCache = map;
    return map;
  }

  // ── Hijri (instant, offline — W-6) ───────────────────────────────────────

  /// Returns Hijri date for [date] — always instant, always offline (W-6).
  HijriDate hijriFor(DateTime date, {int offsetDays = 0}) =>
      HijriCalendarCalculator.hijriFromGregorian(date, offsetDays: offsetDays);

  // ── Prayer times (W-5) ───────────────────────────────────────────────────

  /// Returns full-DateTime prayer times for [date].
  /// Reads from cache; self-heals if missing (W-12).
  Future<PrayerTimes> prayerTimes(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    return _prayerTimesFromDb(db, date);
  }

  Future<PrayerTimes> _prayerTimesFromDb(DatabaseExecutor db, DateTime date) async {
    final dateStr = _ds(date);
    final settings = await _loadSettings(db);
    final cityId = settings['prayer_city_id'] as String? ?? '';
    final method = settings['prayer_calculation_method'] as String? ?? 'TEHRAN_GEOPHYSICS';
    final ihtiyat = int.tryParse(settings['ihtiyat_minutes']?.toString() ?? '') ?? 10;
    final hijriOffset = int.tryParse(settings['hijri_offset']?.toString() ?? '') ?? 0;

    // Try ISO columns first (W-5), fall back to HH:mm
    final cacheRows = await db.query(
      'prayer_times_cache',
      where: 'date = ? AND cityId = ?',
      whereArgs: [dateStr, cityId],
      limit: 1,
    );

    if (cacheRows.isNotEmpty) {
      final row = cacheRows.first;
      final fajr = _isoOrTime(row['fajrIso'] as String?, row['fajr'] as String?, date);
      final sunrise = _isoOrTime(row['sunriseIso'] as String?, row['sunrise'] as String?, date);
      final dhuhr = _isoOrTime(row['dhuhrIso'] as String?, row['dhuhr'] as String?, date);
      final asr = _isoOrTime(row['asrIso'] as String?, row['asr'] as String?, date);
      final maghrib = _isoOrTime(row['maghribIso'] as String?, row['maghrib'] as String?, date);
      final sunset = _isoOrTime(row['sunsetIso'] as String?, row['sunset'] as String?, date);
      final isha = _isoOrTime(row['ishaIso'] as String?, row['isha'] as String?, date);
      final midnight = _isoOrTime(row['midnightShariIso'] as String?, row['midnightShari'] as String?, date);

      if (fajr != null && maghrib != null && isha != null && midnight != null) {
        return PrayerTimes(
          date: dateStr,
          cityId: cityId,
          fajr: fajr,
          sunrise: sunrise ?? date,
          dhuhr: dhuhr ?? date,
          asr: asr ?? date,
          maghrib: maghrib,
          sunset: sunset ?? maghrib,
          isha: isha,
          midnightShari: midnight,
          calculationMethod: method,
          ihtiyatMinutes: ihtiyat,
        );
      }
    }

    // Self-heal: compute and cache (W-12)
    return _computeAndCache(db, date, cityId, method, ihtiyat, hijriOffset);
  }

  Future<PrayerTimes> _computeAndCache(
    DatabaseExecutor db,
    DateTime date,
    String cityId,
    String method,
    int ihtiyat,
    int hijriOffset,
  ) async {
    double lat = 35.6892, lon = 51.3890;
    var isFallback = cityId.isEmpty;

    if (cityId.isNotEmpty) {
      try {
        final rows = await db.query(
          'iran_cities',
          columns: ['lat', 'lng'],
          where: 'id = ?',
          whereArgs: [cityId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          lat = (rows.first['lat'] as num).toDouble();
          lon = (rows.first['lng'] as num).toDouble();
        } else {
          isFallback = true;
          RitmoLogger.warning('WorshipEngine: city "$cityId" not found — using Tehran fallback (W-14)');
        }
      } catch (e) {
        isFallback = true;
        RitmoLogger.warning('WorshipEngine: city lookup failed: $e');
      }
    }

    final times = _calcTimes(date, lat, lon, method, ihtiyat);
    final fallback = isFallback;

    try {
      await db.insert(
        'prayer_times_cache',
        {
          'date': _ds(date),
          'cityId': cityId,
          'calculationMethod': method,
          'ihtiyatMinutes': ihtiyat,
          'fajr': times.fajrText,
          'sunrise': times.sunriseText,
          'dhuhr': times.dhuhrText,
          'asr': times.asrText,
          'maghrib': times.maghribText,
          'sunset': times.sunsetText,
          'isha': times.ishaText,
          'midnightShari': times.midnightShariText,
          'fajrIso': times.fajr.toIso8601String(),
          'sunriseIso': times.sunrise.toIso8601String(),
          'dhuhrIso': times.dhuhr.toIso8601String(),
          'asrIso': times.asr.toIso8601String(),
          'maghribIso': times.maghrib.toIso8601String(),
          'sunsetIso': times.sunset.toIso8601String(),
          'ishaIso': times.isha.toIso8601String(),
          'midnightShariIso': times.midnightShari.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      RitmoLogger.warning('WorshipEngine: cache write failed: $e');
    }

    return PrayerTimes(
      date: _ds(date),
      cityId: cityId,
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      sunset: times.sunset,
      isha: times.isha,
      midnightShari: times.midnightShari,
      calculationMethod: method,
      ihtiyatMinutes: ihtiyat,
      isFallbackLocation: fallback,
    );
  }

  /// Builds yearly prayer cache in a single batch transaction (W-12).
  Future<void> cacheRange({int days = 365}) async {
    final db = await DatabaseHelper.instance.database;
    final settings = await _loadSettings(db);
    final cityId = settings['prayer_city_id'] as String? ?? '';
    final method = settings['prayer_calculation_method'] as String? ?? 'TEHRAN_GEOPHYSICS';
    final ihtiyat = int.tryParse(settings['ihtiyat_minutes']?.toString() ?? '') ?? 10;


    double lat = 35.6892, lon = 51.3890;
    if (cityId.isNotEmpty) {
      try {
        final rows = await db.query('iran_cities', columns: ['lat', 'lng'], where: 'id = ?', whereArgs: [cityId], limit: 1);
        if (rows.isNotEmpty) {
          lat = (rows.first['lat'] as num).toDouble();
          lon = (rows.first['lng'] as num).toDouble();
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    final lLat = lat, lLon = lon; // capture for closure
    await db.transaction((txn) async {
      for (var i = 0; i < days; i++) {
        final d = now.add(Duration(days: i));
        final times = _calcTimes(d, lLat, lLon, method, ihtiyat);
        await txn.insert(
          'prayer_times_cache',
          {
            'date': _ds(d),
            'cityId': cityId,
            'calculationMethod': method,
            'ihtiyatMinutes': ihtiyat,
            'fajr': times.fajrText,
            'sunrise': times.sunriseText,
            'dhuhr': times.dhuhrText,
            'asr': times.asrText,
            'maghrib': times.maghribText,
            'sunset': times.sunsetText,
            'isha': times.ishaText,
            'midnightShari': times.midnightShariText,
            'fajrIso': times.fajr.toIso8601String(),
            'sunriseIso': times.sunrise.toIso8601String(),
            'dhuhrIso': times.dhuhr.toIso8601String(),
            'asrIso': times.asr.toIso8601String(),
            'maghribIso': times.maghrib.toIso8601String(),
            'sunsetIso': times.sunset.toIso8601String(),
            'ishaIso': times.isha.toIso8601String(),
            'midnightShariIso': times.midnightShari.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ── loadDay (max 3 queries per spec) ─────────────────────────────────────

  /// Loads all data needed for one worship day in at most 3 DB queries.
  Future<WorshipDay> loadDay(DateTime date) async {
    final cacheKey = _ds(date);
    if (_dayCache.containsKey(cacheKey)) return _dayCache[cacheKey]!;

    final db = await DatabaseHelper.instance.database;
    final settings = await _loadSettings(db);
    final hijriOffset = int.tryParse(settings['hijri_offset']?.toString() ?? '') ?? 0;

    // ─ Query 1: practices (active, not user-disabled) ─
    final practiceRows = await db.query(
      'worship_practices',
      where: 'isActive = 1 AND (userDisabledAt IS NULL)',
      orderBy: 'sortOrder ASC',
    );

    // ─ Query 2: completions for this date ─
    final completionRows = await db.query(
      'worship_completions',
      where: 'dateStr = ?',
      whereArgs: [cacheKey],
    );

    // ─ Query 3: prayer times (self-healing) ─
    final times = await _prayerTimesFromDb(db, date);

    // Build completion lookup
    final completionMap = <String, Map<String, dynamic>>{};
    for (final row in completionRows) {
      completionMap[row['practiceId'] as String] = row;
    }

    // Build practice states
    final states = practiceRows.map((row) {
      final practice = WorshipPractice.fromMap(row);
      final comp = completionMap[practice.id];

      // Compute prayer window start/end
      DateTime? winStart, winEnd;
      String? qualityWindow;
      if (practice.practiceType == 'PRAYER') {
        final slot = PrayerTimeline.getSlotFor(practice.subType ?? '', times);
        winStart = slot?.at;
        winEnd = slot != null ? PrayerTimeline.deadlineForSlot(slot.key, times) : null;
        if (comp != null) {
          qualityWindow = comp['qualityWindow'] as String?;
        }
      }

      return WorshipPracticeState(
        practice: practice,
        countDone: comp != null ? (comp['countDone'] as int? ?? 0) : 0,
        countTarget: practice.dailyTarget,
        resultType: comp != null ? comp['resultType'] as String? : null,
        qualityWindow: qualityWindow,
        windowStart: winStart,
        windowEnd: winEnd,
      );
    }).toList();

    // Day context
    final ctx = await _loadDayContext(db, date);

    // Active seasons
    final hijri = hijriFor(date, offsetDays: hijriOffset);
    final seasons = await _loadActiveSeasons(db, date, hijri);

    // Occasions (W-16 asset)
    final occasions = await _loadOccasions(date, hijri);

    final day = WorshipDay(
      date: date,
      hijri: hijri,
      times: times,
      practices: states,
      seasons: seasons,
      context: ctx,
      occasions: occasions,
    );

    _dayCache[cacheKey] = day;
    return day;
  }

  /// Loads multiple consecutive days in batch (for weekly/monthly views).
  Future<List<WorshipDay>> loadRange(DateTime from, DateTime to) async {
    final result = <WorshipDay>[];
    var cur = from;
    while (!cur.isAfter(to)) {
      result.add(await loadDay(cur));
      cur = cur.add(const Duration(days: 1));
    }
    return result;
  }

  // ── logDone ───────────────────────────────────────────────────────────────

  /// Logs completion of a worship practice.
  /// Computes [qualityWindow] from PrayerTimeline automatically.
  /// Always uses [CompletionGateway] semantics — returns [WorshipLogOk] with undoToken.
  Future<WorshipLogResult> logDone({
    required String practiceId,
    required DateTime date,
    int amount = 1,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final dateStr = _ds(date);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final recordId = 'wc_${practiceId}_$dateStr';

      // Load practice for metadata
      final practiceRows = await db.query(
        'worship_practices',
        where: 'id = ?',
        whereArgs: [practiceId],
        limit: 1,
      );
      final practice = practiceRows.isNotEmpty ? WorshipPractice.fromMap(practiceRows.first) : null;
      final dailyTarget = practice?.dailyTarget ?? 1;
      final practiceType = practice?.practiceType ?? 'PRAYER';

      // Quality window for prayers
      String? qualityWindow;
      if (practiceType == 'PRAYER' && practice != null) {
        final times = await _prayerTimesFromDb(db, date);
        qualityWindow = _qualityWindow(practice.subType ?? '', times, date);
      }

      await db.transaction((txn) async {
        await txn.insert(
          'worship_completions',
          {
            'id': recordId,
            'practiceId': practiceId,
            'dateStr': dateStr,
            'practiceType': practiceType,
            'resultType': amount >= dailyTarget ? 'DONE' : 'PARTIAL',
            'countDone': amount,
            'countTarget': dailyTarget,
            'qualityWindow': qualityWindow,
            'loggedAt': nowMs,
            'createdAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Write dailyDone as a write-only cache (never read in business logic)
        await txn.update(
          'worship_practices',
          {'dailyDone': amount, 'dailyDoneDate': dateStr, 'updatedAt': nowMs},
          where: 'id = ?',
          whereArgs: [practiceId],
        );
      });

      invalidate(date: date);
      DayAgendaService.instance.invalidateDate(dateStr);
      RitmoEventBus().fire(RitmoEvent(
        type: 'WorshipUpdated',
        timestamp: DateTime.now(),
        payload: {'date': dateStr, 'practiceId': practiceId},
      ));

      return WorshipLogOk(recordId);
    } catch (e) {
      RitmoLogger.error('WorshipEngine.logDone error: $e');
      return WorshipLogFailed(e);
    }
  }

  // ── logSkip ───────────────────────────────────────────────────────────────

  /// Logs skipping a practice with an optional reason.
  /// [addToQada] creates a deterministic debt record (W-10).
  Future<WorshipLogResult> logSkip({
    required String practiceId,
    required DateTime date,
    String? reason,
    bool addToQada = false,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final dateStr = _ds(date);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final recordId = 'wc_${practiceId}_$dateStr';

      await db.transaction((txn) async {
        await txn.insert(
          'worship_completions',
          {
            'id': recordId,
            'practiceId': practiceId,
            'dateStr': dateStr,
            'practiceType': 'PRAYER',
            'resultType': addToQada ? 'QADA_ADDED' : 'SKIPPED',
            'countDone': 0,
            'reason': reason,
            'loggedAt': nowMs,
            'createdAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (addToQada) {
          // Deterministic debt ID — no timestamp, no duplicates (W-10)
          final debtId = 'debt_PRAYER_$practiceId';
          await txn.rawInsert('''
            INSERT INTO worship_debts
              (id, debtType, sourcePracticeId, title,
               totalCount, remainingCount, dailyTarget,
               autoCreated, isArchived, createdAt, updatedAt)
            SELECT ?, 'PRAYER', ?, title, 1, 1, 1, 1, 0, ?, ?
            FROM worship_practices WHERE id = ?
            ON CONFLICT(id) DO UPDATE SET
              totalCount = totalCount + 1,
              remainingCount = remainingCount + 1,
              updatedAt = excluded.updatedAt
          ''', [debtId, practiceId, nowMs, nowMs, practiceId]);
        }

        await txn.update(
          'worship_practices',
          {'dailyDone': -1, 'dailyDoneDate': dateStr, 'updatedAt': nowMs},
          where: 'id = ?',
          whereArgs: [practiceId],
        );
      });

      invalidate(date: date);
      DayAgendaService.instance.invalidateDate(dateStr);
      RitmoEventBus().fire(RitmoEvent(
        type: 'WorshipUpdated',
        timestamp: DateTime.now(),
        payload: {'date': dateStr, 'practiceId': practiceId},
      ));

      return WorshipLogOk(recordId);
    } catch (e) {
      RitmoLogger.error('WorshipEngine.logSkip error: $e');
      return WorshipLogFailed(e);
    }
  }

  // ── setPracticeEnabled (W-3) ──────────────────────────────────────────────

  /// Enables or disables a practice — persists across restarts (W-3).
  /// [userDisabledAt] ensures auto-seed never re-enables it.
  Future<void> setPracticeEnabled(String practiceId, bool enabled) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'worship_practices',
      {
        'isActive': enabled ? 1 : 0,
        'userDisabledAt': enabled ? null : DateTime.now().toIso8601String(),
        'updatedAt': nowMs,
      },
      where: 'id = ?',
      whereArgs: [practiceId],
    );
    invalidate();
    RitmoEventBus().fire(RitmoEvent(
      type: 'WorshipUpdated',
      timestamp: DateTime.now(),
      payload: {'practiceId': practiceId, 'enabled': enabled},
    ));
  }

  // ── debts ─────────────────────────────────────────────────────────────────

  /// Active worship debts with estimated finish date and on-track ratio.
  Future<List<WorshipDebtView>> debts() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'worship_debts',
      where: 'isArchived = 0 AND remainingCount > 0',
      orderBy: 'createdAt ASC',
    );

    return rows.map((row) {
      final debt = WorshipDebt.fromMap(row);
      DateTime? estimatedFinish;
      if (debt.dailyTarget > 0 && debt.remainingCount > 0) {
        final daysLeft = (debt.remainingCount / debt.dailyTarget).ceil();
        estimatedFinish = DateTime.now().add(Duration(days: daysLeft));
      }
      final done = debt.totalCount - debt.remainingCount;
      final onTrack = debt.totalCount > 0 ? done / debt.totalCount : 1.0;
      return WorshipDebtView(
        debt: debt,
        estimatedFinishDate: estimatedFinish,
        onTrackRatio: onTrack.clamp(0.0, 1.0),
      );
    }).toList();
  }

  // ── softStreak ────────────────────────────────────────────────────────────

  /// Ratio-based streak: counts DONE days in the past [window] days.
  Future<SoftStreak> softStreak(String practiceId, {int window = 30}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final fromStr = _ds(now.subtract(Duration(days: window - 1)));
    final toStr = _ds(now);

    final rows = await db.query(
      'worship_completions',
      columns: ['dateStr', 'resultType'],
      where: 'practiceId = ? AND dateStr >= ? AND dateStr <= ?',
      whereArgs: [practiceId, fromStr, toStr],
      orderBy: 'dateStr DESC',
    );

    var daysDone = 0;
    var currentRun = 0;
    var inRun = true;

    for (final row in rows) {
      final rt = row['resultType'] as String?;
      if (rt == 'DONE') {
        daysDone++;
        if (inRun) currentRun++;
      } else {
        inRun = false;
      }
    }

    return SoftStreak(daysDone: daysDone, windowDays: window, currentRun: currentRun);
  }

  // ── dayContext (F-1) ──────────────────────────────────────────────────────

  /// Loads traveller/exemption context for [date].
  Future<WorshipDayContext> dayContext(DateTime date) async {
    return _loadDayContext(await DatabaseHelper.instance.database, date);
  }

  Future<WorshipDayContext> _loadDayContext(DatabaseExecutor db, DateTime date) async {
    try {
      final rows = await db.query(
        'worship_day_context',
        where: 'date = ?',
        whereArgs: [_ds(date)],
        limit: 1,
      );
      if (rows.isNotEmpty) return WorshipDayContext.fromMap(rows.first);
    } catch (_) {}
    return WorshipDayContext(date: date);
  }

  /// Persists traveller/exemption context for a day.
  Future<void> setDayContext(WorshipDayContext ctx) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'worship_day_context',
      ctx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    invalidate(date: ctx.date);
  }

  // ── activeSeasons ─────────────────────────────────────────────────────────

  /// Returns worship seasons active on [date] (W-7 recurrence logic).
  Future<List<WorshipSeason>> activeSeasons(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    final hijriOffset = int.tryParse(
          (_settingsCache ?? {})['hijri_offset']?.toString() ?? '',
        ) ??
        0;
    return _loadActiveSeasons(db, date, hijriFor(date, offsetDays: hijriOffset));
  }

  Future<List<WorshipSeason>> _loadActiveSeasons(
    DatabaseExecutor db,
    DateTime date,
    HijriDate hijri,
  ) async {
    final rows = await db.query('worship_seasons', where: 'isActive = 1');
    return rows
        .map((r) => WorshipSeason.fromMap(r))
        .where((s) => _isSeasonActive(s, date, hijri))
        .toList();
  }

  /// Recurrence-aware season check (W-7). No fragile string parsing.
  bool _isSeasonActive(WorshipSeason s, DateTime date, HijriDate hijri) {
    final rec = s.recurrence ?? s.calendar.toUpperCase();

    switch (rec) {
      case 'RANGE_HIJRI':
        return _hijriInRange(hijri, s.startDate, s.endDate);

      case 'RANGE_SOLAR':
        try {
          final sp = s.startDate.split('-');
          final ep = s.endDate.split('-');
          final sm = int.parse(sp[sp.length - 2]), sd = int.parse(sp.last);
          final em = int.parse(ep[ep.length - 2]), ed = int.parse(ep.last);
          final cm = date.month, cd = date.day;
          final afterStart = cm > sm || (cm == sm && cd >= sd);
          final beforeEnd = cm < em || (cm == em && cd <= ed);
          if (em > sm || (em == sm && ed >= sd)) return afterStart && beforeEnd;
          return afterStart || beforeEnd; // wraps year
        } catch (_) {
          return false;
        }

      case 'DAYS_OF_EVERY_HIJRI_MONTH':
        return _parseDayList(s.dayList).contains(hijri.day);

      case 'DAYS_OF_HIJRI_MONTH':
        final dayList = _parseDayList(s.dayList);
        return (s.hijriMonth == null || s.hijriMonth == hijri.month) &&
            dayList.contains(hijri.day);

      case 'NIGHTS_OF_HIJRI_MONTH':
        // After maghrib → the night belongs to the NEXT Hijri day (W-7)
        final isAfterMaghrib = date.hour >= 19; // rough heuristic for non-live check
        final effectiveDate = isAfterMaghrib ? date.add(const Duration(days: 1)) : date;
        final effectiveHijri = hijriFor(effectiveDate);
        final dayList = _parseDayList(s.dayList);
        return (s.hijriMonth == null || s.hijriMonth == effectiveHijri.month) &&
            dayList.contains(effectiveHijri.day);

      default:
        return _hijriInRange(hijri, s.startDate, s.endDate);
    }
  }

  bool _hijriInRange(HijriDate h, String startDate, String endDate) {
    try {
      final sp = startDate.split('-');
      final ep = endDate.split('-');
      final sm = int.parse(sp[sp.length - 2]), sd = int.parse(sp.last);
      final em = int.parse(ep[ep.length - 2]), ed = int.parse(ep.last);
      final cm = h.month, cd = h.day;

      final afterStart = cm > sm || (cm == sm && cd >= sd);
      final beforeEnd = cm < em || (cm == em && cd <= ed);
      if (em > sm || (em == sm && ed >= sd)) return afterStart && beforeEnd;
      return afterStart || beforeEnd; // wraps Hijri new year
    } catch (_) {
      return false;
    }
  }

  List<int> _parseDayList(String? json) {
    if (json == null) return [];
    try {
      return (jsonDecode(json) as List<dynamic>).cast<int>();
    } catch (_) {
      return [];
    }
  }

  // ── resolveMissResult (W-4) ───────────────────────────────────────────────

  /// Shared logic for determining miss result type (W-4).
  /// Used by sweep AND debt section — single source of truth.
  static String resolveMissResult({
    required WorshipPractice practice,
    required WorshipDayContext ctx,
    required bool suspended,
  }) {
    if (suspended || (ctx.prayerExempt && practice.practiceType == 'PRAYER')) {
      return 'SKIPPED'; // EXEMPT — no qada for prayers
    }
    return 'MISSED';
  }

  /// Whether qada should be added for this miss (W-4 fiqh table).
  static bool shouldAddQada({
    required WorshipPractice practice,
    required WorshipDayContext ctx,
    required bool suspended,
  }) {
    // Fasting must be made up even during menstruation
    if (practice.practiceType == 'FASTING' && suspended) return true;
    // Prayers during suspension/exemption: no qada
    if (suspended || (ctx.prayerExempt && practice.practiceType == 'PRAYER')) return false;
    return practice.allowQada;
  }

  // ── Occasions (W-16) ─────────────────────────────────────────────────────

  Future<List<OccasionItem>> _loadOccasions(DateTime date, HijriDate hijri) async {
    // W-16: asset loading implemented when occasions data moves to JSON
    if (_occasionsCache != null) {
      return _occasionsCache!.where((o) => _isOccasionToday(o, date, hijri)).toList();
    }
    _occasionsCache = []; // empty until W-16
    return [];
  }

  /// Checks if an occasion falls on [date]. Implemented in W-16.
  bool _isOccasionToday(OccasionItem o, DateTime date, HijriDate hijri) {
    return false; // stub — will be populated in W-16
  }

  // ── invalidate ────────────────────────────────────────────────────────────

  /// Invalidates cached data. Must be called after every write.
  void invalidate({DateTime? date}) {
    if (date != null) {
      _dayCache.remove(_ds(date));
    } else {
      _dayCache.clear();
    }
    _settingsCache = null;
    _occasionsCache = null;
  }

  // ── Prayer time computation (offline trig — W-5) ─────────────────────────

  PrayerTimes _calcTimes(DateTime date, double lat, double lon, String method, int ihtiyat) {
    // Fajr/Isha angles by calculation method
    double fa, ia;
    switch (method) {
      case 'ISNA':
        fa = 15.0; ia = 15.0;
      case 'MWL':
        fa = 18.0; ia = 17.0;
      case 'EGYPT':
        fa = 19.5; ia = 17.5;
      case 'TEHRAN_GEOPHYSICS':
      default:
        fa = 17.7; ia = 14.0;
    }

    final jd = _jd(date);
    final sol = _solar(jd);
    final decl = sol.$1;
    final eot = sol.$2;
    final transit = 12.0 - eot / 60.0 - lon / 15.0;

    double? angTime(double angle, bool morning) {
      final cosH = (_sind(-angle) - _sind(decl) * _sind(lat)) /
          (_cosd(decl) * _cosd(lat));
      if (cosH.abs() > 1) return null;
      final h = math.acos(cosH) * _r2d / 15.0;
      return transit + (morning ? -h : h);
    }

    double asrTime(int shadow) {
      final x = shadow + math.tan((lat - decl).abs() * _d2r);
      final cosH = (math.cos(math.atan(1 / x)) - _sind(decl) * _sind(lat)) /
          (_cosd(decl) * _cosd(lat));
      if (cosH.abs() > 1) return transit;
      return transit + math.acos(cosH) * _r2d / 15.0;
    }

    final fajrH = angTime(fa, true) ?? (transit - 1.5);
    final sunriseH = angTime(0.833, true) ?? (transit - 1.0);
    final dhuhrH = transit;
    final asrH = asrTime(1);
    final sunsetH = angTime(0.833, false) ?? (transit + 1.0);
    final maghribH = sunsetH;
    final ishaH = angTime(ia, false) ?? (sunsetH + 1.0);

    // Next-day fajr for correct shari midnight (W-5)
    final nextDay = date.add(const Duration(days: 1));
    final jd2 = _jd(nextDay);
    final sol2 = _solar(jd2);
    final decl2 = sol2.$1, eot2 = sol2.$2;
    final transit2 = 12.0 - eot2 / 60.0 - lon / 15.0;
    final cosHNext = (_sind(-fa) - _sind(decl2) * _sind(lat)) /
        (_cosd(decl2) * _cosd(lat));
    final nextFajrH = cosHNext.abs() <= 1
        ? transit2 - math.acos(cosHNext) * _r2d / 15.0
        : transit2 - 1.5;

    // Shari midnight = midpoint between maghrib and next-day fajr (W-5 fix)
    final nightLen = (nextFajrH + 24.0) - maghribH;
    final midH = maghribH + nightLen / 2.0;

    final ihtMin = ihtiyat / 60.0;
    return PrayerTimes(
      date: _ds(date),
      cityId: '',
      fajr: _hrs(fajrH + ihtMin, date),
      sunrise: _hrs(sunriseH - ihtMin, date),
      dhuhr: _hrs(dhuhrH + ihtMin, date),
      asr: _hrs(asrH + ihtMin, date),
      maghrib: _hrs(maghribH + ihtMin, date),
      sunset: _hrs(sunsetH, date),
      isha: _hrs(ishaH + ihtMin, date),
      midnightShari: _hrsCross(midH, date),
      calculationMethod: method,
      ihtiyatMinutes: ihtiyat,
    );
  }

  // ── Trig helpers ──────────────────────────────────────────────────────────

  static const double _d2r = math.pi / 180.0;
  static const double _r2d = 180.0 / math.pi;

  static double _sind(double d) => math.sin(d * _d2r);
  static double _cosd(double d) => math.cos(d * _d2r);

  /// Julian Day Number (noon)
  double _jd(DateTime d) {
    var y = d.year, m = d.month;
    final day = d.day + 0.5;
    if (m <= 2) { y--; m += 12; }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day + b - 1524.5;
  }

  /// Returns (declination, equation-of-time) in degrees / minutes
  (double, double) _solar(double jd) {
    final d = jd - 2451545.0;
    final g = (357.529 + 0.98560028 * d) % 360;
    final q = (280.459 + 0.98564736 * d) % 360;
    final L = (q + 1.915 * _sind(g) + 0.020 * _sind(2 * g)) % 360;
    final e = 23.439 - 0.00000036 * d;
    final sinL = math.sin(L * _d2r);
    final decl = math.asin(math.sin(e * _d2r) * sinL) * _r2d;
    final ra = math.atan2(math.cos(e * _d2r) * sinL, math.cos(L * _d2r)) * _r2d / 15.0;
    final eot = q / 15.0 - (ra % 24);
    return (decl, eot);
  }

  DateTime _hrs(double hrs, DateTime base) {
    final totalMin = (hrs * 60).round();
    final h = totalMin ~/ 60, m = totalMin % 60;
    if (h >= 24) return DateTime(base.year, base.month, base.day + 1, h - 24, m);
    if (h < 0) return DateTime(base.year, base.month, base.day, 0, 0);
    return DateTime(base.year, base.month, base.day, h, m);
  }

  DateTime _hrsCross(double hrs, DateTime base) {
    final totalMin = (hrs * 60).round();
    final h = totalMin ~/ 60, m = totalMin % 60;
    if (h >= 24) {
      final next = base.add(const Duration(days: 1));
      return DateTime(next.year, next.month, next.day, h - 24, m);
    }
    return DateTime(base.year, base.month, base.day, h < 0 ? 0 : h, m < 0 ? 0 : m);
  }

  DateTime? _isoOrTime(String? iso, String? hhMm, DateTime base) {
    if (iso != null && iso.isNotEmpty) return DateTime.tryParse(iso);
    if (hhMm != null && hhMm.isNotEmpty) {
      final p = hhMm.split(':');
      if (p.length >= 2) {
        final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
        if (h != null && m != null) return DateTime(base.year, base.month, base.day, h, m);
      }
    }
    return null;
  }

  String _qualityWindow(String subType, PrayerTimes times, DateTime at) {
    final slot = PrayerTimeline.getSlotFor(subType, times);
    if (slot == null) return 'NORMAL';
    final deadline = PrayerTimeline.deadlineForSlot(slot.key, times);
    if (deadline == null) return 'NORMAL';
    final len = deadline.difference(slot.at).inMinutes;
    final elapsed = at.difference(slot.at).inMinutes;
    if (elapsed < 0) return 'EARLY';
    if (len <= 0) return 'NORMAL';
    final ratio = elapsed / len;
    if (ratio < 0.33) return 'EARLY';
    if (ratio < 0.66) return 'NORMAL';
    return 'LATE';
  }

  static String _ds(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
