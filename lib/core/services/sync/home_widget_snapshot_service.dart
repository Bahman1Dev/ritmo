import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/core/services/sync/models/today_snapshot_state.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/snapshot_helper.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:sqflite/sqflite.dart';

const Map<String, String> kWidgetModuleEmoji = {
  'sleep': '🌙', 'sports': '🏋️', 'energy': '⚡', 'medicine': '💊',
  'worship': '🕌', 'cycle': '🌸', 'goals': '🚩', 'courses': '📚', 'konkur': '📝',
};

const Map<String, String> kWidgetModuleColor = {
  'sleep': '#8B5CF6', 'sports': '#10B981', 'energy': '#EC4899', 'medicine': '#EF4444',
  'worship': '#FBBF24', 'cycle': '#EC4899', 'goals': '#F59E0B', 'courses': '#3B82F6', 'konkur': '#8B5CF6',
};

class HomeWidgetSnapshotService {
  const HomeWidgetSnapshotService();

  Future<void> sync({
    required Database db,
    required TodaySnapshotState state,
  }) async {
    // 1. Compact widget snapshot
    await SnapshotHelper.updateWidgetSnapshot(
      nextActionTitle: state.nextTask?.routine.title ?? 'استراحت 🌿',
      rhythmScore: state.rhythmScore,
      currentEnergyLevel: state.resolvedEnergy.name,
    );

    // 2. Full home-screen widget snapshot
    try {
      final en = state.resolvedEnergy.name.toLowerCase();
      final modules = await _buildWidgetModules(
        db: db,
        s: state.settingsMap,
        now: state.now,
        resolvedEnergy: state.resolvedEnergy,
        routinesResult: state.routinesResult,
        completions: state.completions,
      );
      await SnapshotHelper.updateFullWidgetSnapshot(
        rhythmScore: state.rhythmScore,
        nextActionTitle: state.nextTask?.routine.title ?? 'استراحت 🌿',
        energyLabel: en == 'low' ? 'کم' : en == 'high' ? 'زیاد' : 'متوسط',
        energyPercent: en == 'low' ? 30 : en == 'high' ? 90 : 65,
        modules: modules,
      );
      await sl<NotificationPlatform>().refreshWidgets();
    } catch (e) {
      debugPrint('HomeWidgetSnapshotService: full widget snapshot failed: $e');
    }
  }

  Future<List<Map<String, String>>> _buildWidgetModules({
    required Database db,
    required Map<String, String> s,
    required DateTime now,
    required EnergyLevel resolvedEnergy,
    required List<Map<String, Object?>> routinesResult,
    required List<Map<String, Object?>> completions,
  }) async {
    final out = <Map<String, String>>[];
    String fa(Object v) => toPersianDigits(v.toString());
    Map<String, String> row(String id, String title, String primary, String secondary) => {
          'id': id,
          'title': title,
          'primary': primary,
          'secondary': secondary,
          'emoji': kWidgetModuleEmoji[id] ?? '•',
          'color': kWidgetModuleColor[id] ?? '#10B981',
        };

    // خواب
    if (s['module_sleep_enabled'] == 'true') {
      try {
        final rows = await db.query('bedtime_diagnostics', orderBy: 'date DESC', limit: 1);
        if (rows.isNotEmpty) {
          final log = SleepLog.fromMap(rows.first);
          final h = log.durationMinutes ~/ 60;
          final m = log.durationMinutes % 60;
          out.add(row('sleep', 'خواب', '${fa(h)}:${fa(m.toString().padLeft(2, '0'))} ساعت',
              'کیفیت دیشب: ${log.quality.emoji} ${log.quality.label}'));
        } else {
          out.add(row('sleep', 'خواب', '—', 'هنوز خوابی ثبت نشده'));
        }
      } catch (e, st) {
        debugPrint('Error in HomeWidgetSnapshotService module loader: $e\n$st');
      }
    }

    // ورزش
    if (s['module_sports_enabled'] == 'true') {
      try {
        final weekAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
        final rows = await db.query('workout_logs', where: 'loggedAt >= ?', whereArgs: [weekAgo]);
        final sessions = rows.length;
        final minutes = rows.fold<int>(0, (a, r) => a + ((r['durationMinutes'] as int?) ?? 0));
        out.add(row('sports', 'ورزش', '${fa(sessions)} جلسه', 'این هفته: ${fa(minutes)} دقیقه'));
      } catch (e, st) {
        debugPrint('Error in HomeWidgetSnapshotService module loader: $e\n$st');
      }
    }

    // انرژی و مود — از سطح انرژیِ resolved
    if (s['module_energy_enabled'] == 'true') {
      final en = resolvedEnergy.name.toLowerCase();
      final label = en == 'low' ? 'کم' : en == 'high' ? 'زیاد' : 'متوسط';
      final pct = en == 'low' ? 30 : en == 'high' ? 90 : 65;
      out.add(row('energy', 'انرژی و مود', '${fa(pct)}٪', 'سطح: $label'));
    }

    // دارو — پایبندی امروز
    if (s['module_medicine_enabled'] == 'true') {
      try {
        final medRoutines = routinesResult
            .where((r) => (r['category'] as String?)?.toLowerCase() == 'medical')
            .toList();
        final totalDoses = medRoutines.fold<int>(0, (a, r) {
          final mx = (r['maxDosesPerDay'] as int?) ?? 1;
          return a + (mx <= 0 ? 1 : mx);
        });
        var taken = 0;
        for (final r in medRoutines) {
          final rId = r['id']! as String;
          taken += completions.where((c) => c['routineId'] == rId).length;
        }
        final pct = totalDoses > 0 ? ((taken / totalDoses) * 100).round().clamp(0, 100) : 0;
        final remaining = (totalDoses - taken) < 0 ? 0 : (totalDoses - taken);
        out.add(row('medicine', 'دارو', '${fa(pct)}٪', 'پایبندی امروز · ${fa(remaining)} باقی‌مانده'));
      } catch (e, st) {
        debugPrint('Error in HomeWidgetSnapshotService module loader: $e\n$st');
      }
    }

    // عبادت — قضاها + نماز بعدی (best-effort)
    if (s['module_religion_enabled'] == 'true') {
      try {
        final debtsRows = await db.query('worship_debts', where: 'isArchived = 0');
        final debts = debtsRows.length;
        var secondaryText = 'برنامه‌ی عبادی';
        try {
          final homeCityId = s['home_city_id'] ?? 'TEHRAN_TEHRAN';
          final prayerTimes = await PrayerTimeProvider.instance
              .getPrayerTimesForDate(cityId: homeCityId, date: now);
          secondaryText = _nextPrayerText(prayerTimes, now) ?? secondaryText;
        } catch (e, st) {
          debugPrint('Error in HomeWidgetSnapshotService module loader: $e\n$st');
        }
        out.add(row('worship', 'عبادت', debts > 0 ? '${fa(debts)} قضا' : 'به‌روز ✓', secondaryText));
      } catch (e, st) {
        debugPrint('Error in HomeWidgetSnapshotService module loader: $e\n$st');
      }
    }

    // چرخه — فاز فعلی (هم‌شرط با داشبورد)
    if (s['module_cycle_enabled'] == 'true' &&
        s['cycle_consent_dashboard'] == 'true' &&
        s['cycle_setup_done'] == 'true') {
      try {
        final output = await CycleEngine()
            .calculate(CycleEngineInput(db: db, appSettings: s, now: now));
        final p = output.currentPhase;
        final label = p == CyclePhase.menstrual
            ? 'قاعدگی'
            : p == CyclePhase.follicular
                ? 'فولیکولار'
                : p == CyclePhase.ovulation
                    ? 'تخمک‌گذاری'
                    : 'لوتئال';
        out.add(row('cycle', 'چرخه بدن', label, 'فاز کنونی بدن'));
      } catch (e, st) {
        debugPrint('Error in HomeWidgetSnapshotService module loader: $e\n$st');
      }
    }

    // اهداف / دوره‌ها / کنکور — از اجندای مشترکِ امروز
    final goalsEnabled = s['module_goals_enabled'] == 'true';
    final coursesEnabled = s['module_courses_enabled'] == 'true';
    final konkurEnabled = s['module_konkur_enabled'] == 'true';
    if (goalsEnabled || coursesEnabled || konkurEnabled) {
      try {
        final dayAgenda = await DayAgendaService.instance.agendaForDate(
          now,
          options: const AgendaQueryOptions(),
        );
        final items = dayAgenda.items;
        if (goalsEnabled) {
          final steps = items.where((i) => i.domain == AgendaDomain.goalStep).toList();
          final total = steps.length;
          final done = steps.where((i) => i.isCompleted).length;
          out.add(row('goals', 'اهداف', total > 0 ? '${fa(done)}/${fa(total)}' : '—', 'گام‌های امروز'));
        }
        if (coursesEnabled) {
          final sessions =
              items.where((i) => i.domain == AgendaDomain.course && !i.isCompleted).length;
          out.add(row('courses', 'دوره‌ها', '${fa(sessions)} جلسه', 'مطالعه‌ی امروز'));
        }
        if (konkurEnabled) {
          final konkur = items
              .where((i) => i.domain == AgendaDomain.konkur && i.completion == AgendaCompletion.pending)
              .length;
          out.add(row('konkur', 'کنکور', '${fa(konkur)} مبحث', 'برنامه‌ی امروز'));
        }
      } catch (e, st) {
        debugPrint('Error in HomeWidgetSnapshotService module loader: $e\n$st');
      }
    }

    return out;
  }

  String? _nextPrayerText(Map<String, String> prayerTimes, DateTime now) {
    int? toMin(String? t) {
      if (t == null || !t.contains(':')) return null;
      final p = t.split(':');
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h == null || m == null) return null;
      return h * 60 + m;
    }

    final cur = now.hour * 60 + now.minute;
    final fajr = toMin(prayerTimes['fajr']);
    final dhuhr = toMin(prayerTimes['dhuhr']);
    final maghrib = toMin(prayerTimes['maghrib']);
    final isha = toMin(prayerTimes['isha']);

    String? name;
    String? time;
    if (fajr != null && cur < fajr) {
      name = 'اذان صبح';
      time = prayerTimes['fajr'];
    } else if (dhuhr != null && cur < dhuhr) {
      name = 'اذان ظهر';
      time = prayerTimes['dhuhr'];
    } else if (maghrib != null && cur < maghrib) {
      name = 'اذان مغرب';
      time = prayerTimes['maghrib'];
    } else if (isha != null && cur < isha) {
      name = 'نماز عشا';
      time = prayerTimes['isha'];
    } else if (fajr != null) {
      name = 'اذان صبح فردا';
      time = prayerTimes['fajr'];
    }
    if (name != null && time != null) return '$name: ${toPersianDigits(time)}';
    return null;
  }
}
