import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

enum AppMode { simple, full }

class AppModeService {
  AppModeService._();
  static final AppModeService instance = AppModeService._();

  final ValueNotifier<AppMode> notifier = ValueNotifier(AppMode.simple);

  AppMode _current = AppMode.simple;

  Future<void> load() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: "key = 'app_mode'",
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value'] as String?;
        if (val == 'FULL') {
          _current = AppMode.full;
        } else {
          _current = AppMode.simple;
        }
      } else {
        _current = AppMode.simple;
      }
      notifier.value = _current;
    } catch (e) {
      _current = AppMode.simple;
      notifier.value = _current;
    }
  }

  AppMode get current => _current;
  bool get isSimple => _current == AppMode.simple;

  Future<void> set(AppMode mode) async {
    _current = mode;
    notifier.value = mode;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final strVal = mode == AppMode.full ? 'FULL' : 'SIMPLE';
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        INSERT INTO app_settings (key, value, updatedAt)
        VALUES ('app_mode', '$strVal', $nowMs)
        ON CONFLICT(key) DO UPDATE SET
          value = excluded.value,
          updatedAt = excluded.updatedAt;
      ''');
    } catch (_) {}

    RitmoEventBus().fire(RitmoEvent(
      type: 'app_mode_changed',
      timestamp: DateTime.now(),
      payload: {'mode': strVal},
    ));
  }
}
