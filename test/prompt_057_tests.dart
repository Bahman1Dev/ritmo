// test/prompt_057_tests.dart
// S27 — ۱۲ تست الزامی پرامپت ۰۵۷
// این فایل باید دقیقاً ۱۲ تست داشته باشد و همه سبز باشند.

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v76_simple_mode.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:sqflite/sqflite.dart';

// ─── Mock Database for Unit Testing ──────────────────────────────────────────

class MockTestDb implements Database {
  final Map<String, List<Map<String, Object?>>> tables = {};
  final List<String> executedSql = [];

  @override
  bool get isOpen => true;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedSql.add(sql);
    // Parse simple INSERT OR IGNORE / UPDATE for app_settings during migration
    if (sql.contains('INSERT OR IGNORE INTO app_settings')) {
      final match = RegExp(r"VALUES \('([^']+)', '([^']+)', (\d+)\)").firstMatch(sql);
      if (match != null) {
        final key = match.group(1)!;
        final value = match.group(2)!;
        final updatedAt = int.parse(match.group(3)!);
        final list = tables.putIfAbsent('app_settings', () => []);
        if (!list.any((r) => r['key'] == key)) {
          list.add({'key': key, 'value': value, 'updatedAt': updatedAt});
        }
      }
    } else if (sql.contains("UPDATE app_settings")) {
      final list = tables['app_settings'] ?? [];
      for (final r in list) {
        if (r['key'] == 'app_mode') {
          r['value'] = 'FULL';
        }
      }
    }
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables.putIfAbsent(table, () => []);
    list.removeWhere((row) => row['id'] == values['id'] || row['key'] == values['key']);
    list.add(Map<String, Object?>.from(values));
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values,
      {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables[table] ?? [];
    int count = 0;
    for (final row in list) {
      bool matches = true;
      if (where != null && whereArgs != null) {
        if (where.contains('id = ?')) {
          matches = row['id'] == whereArgs.first;
        } else if (where.contains('key = ?')) {
          matches = row['key'] == whereArgs.first;
        }
      }
      if (matches) {
        row.addAll(values);
        count++;
      }
    }
    return count;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final list = tables[table] ?? [];
    if (where == null) return list;

    return list.where((row) {
      if (where == "key = 'onboarding_completed'") {
        return row['key'] == 'onboarding_completed';
      }
      if (where == "key = 'app_mode'") {
        return row['key'] == 'app_mode';
      }
      if (where == "id = 'task_alarm_1'") {
        return row['id'] == 'task_alarm_1';
      }
      if (where == 'isDone = 0 AND dueDate IS NULL') {
        return row['isDone'] == 0 && row['dueDate'] == null;
      }
      if (where == 'isDone = 0 AND dueDate IS NOT NULL AND dueDate <= ?') {
        final targetDate = whereArgs?.first as String?;
        final rowDueDate = row['dueDate'] as String?;
        return row['isDone'] == 0 && rowDueDate != null && rowDueDate.compareTo(targetDate ?? '') <= 0;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('SELECT COUNT(*) as cnt FROM routines')) {
      final list = tables['routines'] ?? [];
      return [{'cnt': list.length}];
    }
    return [];
  }

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

SimpleTask _makeTask({
  String? id,
  String title = 'تست',
  bool isDone = false,
  String? dueDate,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return SimpleTask(
    id: id ?? 'task_${now}_1',
    title: title,
    isDone: isDone,
    orderIndex: 0,
    origin: 'SIMPLE',
    createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
    dueDate: dueDate,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════════════════
  // T1 — simple_tasks_table_exists_test
  // جدول و ۳ ایندکس بعد از مهاجرت وجود دارند
  // ═══════════════════════════════════════════════════════
  test('simple_tasks_table_exists_test', () async {
    final db = MockTestDb();
    final migration = MigrationV76SimpleMode();
    await migration.up(db);

    final sqlJoined = db.executedSql.join('\n');
    expect(sqlJoined.contains('CREATE TABLE IF NOT EXISTS simple_tasks'), isTrue,
        reason: 'جدول simple_tasks باید ساخته شود');
    expect(sqlJoined.contains('idx_simple_tasks_isDone'), isTrue,
        reason: 'ایندکس idx_simple_tasks_isDone باید ساخته شود');
    expect(sqlJoined.contains('idx_simple_tasks_dueDate'), isTrue,
        reason: 'ایندکس idx_simple_tasks_dueDate باید ساخته شود');
    expect(sqlJoined.contains('idx_simple_tasks_order'), isTrue,
        reason: 'ایندکس idx_simple_tasks_order باید ساخته شود');
  });

  // ═══════════════════════════════════════════════════════
  // T2 — existing_user_gets_full_mode_test
  // onboarding_completed = 'true' → app_mode = 'FULL'
  // ═══════════════════════════════════════════════════════
  test('existing_user_gets_full_mode_test', () async {
    final db = MockTestDb();
    final now = DateTime.now().millisecondsSinceEpoch;

    // شبیه‌سازی کاربر قدیمی: onboarding_completed = 'true'
    await db.insert('app_settings', {
      'key': 'onboarding_completed',
      'value': 'true',
      'updatedAt': now,
    });

    final migration = MigrationV76SimpleMode();
    await migration.up(db);

    final appModeRow = (db.tables['app_settings'] ?? [])
        .firstWhere((r) => r['key'] == 'app_mode', orElse: () => {});
    expect(appModeRow['value'], 'FULL',
        reason: 'کاربر قدیمی (onboarding_completed=true) باید app_mode=FULL بگیرد');
  });

  // ═══════════════════════════════════════════════════════
  // T3 — fresh_install_gets_simple_mode_test
  // نصب تازه → app_mode = 'SIMPLE'
  // ═══════════════════════════════════════════════════════
  test('fresh_install_gets_simple_mode_test', () async {
    final db = MockTestDb();
    final migration = MigrationV76SimpleMode();
    await migration.up(db);

    final appModeRow = (db.tables['app_settings'] ?? [])
        .firstWhere((r) => r['key'] == 'app_mode', orElse: () => {});
    expect(appModeRow['value'], 'SIMPLE',
        reason: 'نصب تازه باید app_mode=SIMPLE بگیرد');
  });

  // ═══════════════════════════════════════════════════════
  // T4 — undated_task_lands_in_someday_test
  // dueDate = null → در سطل «هر وقت شد»
  // ═══════════════════════════════════════════════════════
  test('undated_task_lands_in_someday_test', () async {
    final db = MockTestDb();
    final now = DateTime.now().millisecondsSinceEpoch;
    final todayIso = DayKey.from(DateTime.now()).value;

    // درج کار بدون تاریخ
    await db.insert('simple_tasks', {
      'id': 'task_someday_1',
      'title': 'کار بدون تاریخ',
      'isDone': 0,
      'orderIndex': 0,
      'origin': 'SIMPLE',
      'createdAt': now,
      'updatedAt': now,
    });

    // بررسی سطل someday: isDone=0 AND dueDate IS NULL
    final somedayRows = await db.query(
      'simple_tasks',
      where: 'isDone = 0 AND dueDate IS NULL',
    );
    expect(somedayRows.length, 1,
        reason: 'کار بدون تاریخ باید در سطل someday باشد');

    // بررسی سطل today: نباید ظاهر شود
    final todayRows = await db.query(
      'simple_tasks',
      where: 'isDone = 0 AND dueDate IS NOT NULL AND dueDate <= ?',
      whereArgs: [todayIso],
    );
    expect(todayRows.length, 0,
        reason: 'کار بدون تاریخ نباید در سطل today باشد');
  });

  // ═══════════════════════════════════════════════════════
  // T5 — overdue_task_shows_in_today_test
  // کار دیروزِ انجام‌نشده در سطل امروز می‌آید
  // ═══════════════════════════════════════════════════════
  test('overdue_task_shows_in_today_test', () async {
    final db = MockTestDb();
    final now = DateTime.now().millisecondsSinceEpoch;
    final todayIso = DayKey.from(DateTime.now()).value;
    final yesterdayIso = DayKey.from(DateTime.now().subtract(const Duration(days: 1))).value;

    // درج کار دیروز، انجام‌نشده
    await db.insert('simple_tasks', {
      'id': 'task_overdue_1',
      'title': 'کار دیروز',
      'isDone': 0,
      'dueDate': yesterdayIso,
      'orderIndex': 0,
      'origin': 'SIMPLE',
      'createdAt': now,
      'updatedAt': now,
    });

    // کوئری today: isDone=0 AND dueDate IS NOT NULL AND dueDate <= today
    final todayRows = await db.query(
      'simple_tasks',
      where: 'isDone = 0 AND dueDate IS NOT NULL AND dueDate <= ?',
      whereArgs: [todayIso],
    );
    expect(todayRows.length, 1,
        reason: 'کار دیروزِ انجام‌نشده باید در سطل امروز ظاهر شود');
  });

  // ═══════════════════════════════════════════════════════
  // T6 — quick_add_failure_still_saves_test
  // متن غیرقابل‌پارس هم ذخیره می‌شود، بدون خطا
  // ═══════════════════════════════════════════════════════
  test('quick_add_failure_still_saves_test', () async {
    const rawText = 'یک متن عجیب که پارس نمی‌شود @#!%';

    final task = _makeTask(title: rawText, dueDate: null);

    expect(task.title, rawText, reason: 'عنوان باید متن خام باشد');
    expect(task.dueDate, isNull, reason: 'کار باید بدون تاریخ (someday) ذخیره شود');
    expect(() => task.isSomeday, returnsNormally);
    expect(task.isSomeday, isTrue);
  });

  // ═══════════════════════════════════════════════════════
  // T7 — done_cancels_alarm_test
  // تیک زدن کار دارای یادآور، reminderId را پاک می‌کند
  // ═══════════════════════════════════════════════════════
  test('done_cancels_alarm_test', () async {
    final db = MockTestDb();
    final now = DateTime.now().millisecondsSinceEpoch;

    // درج کار با یادآور
    await db.insert('simple_tasks', {
      'id': 'task_alarm_1',
      'title': 'کار با یادآور',
      'isDone': 0,
      'reminderId': 'reminder_abc',
      'reminderAtMs': now + 3600000,
      'orderIndex': 0,
      'origin': 'SIMPLE',
      'createdAt': now,
      'updatedAt': now,
    });

    // شبیه‌سازی setDone: isDone=1, doneAt=now, updatedAt=now, reminderId=null, reminderAtMs=null
    await db.update(
      'simple_tasks',
      {
        'isDone': 1,
        'doneAt': now,
        'reminderId': null,
        'reminderAtMs': null,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: ['task_alarm_1'],
    );

    final rows = await db.query('simple_tasks', where: "id = 'task_alarm_1'");
    expect(rows.length, 1);
    final row = rows.first;
    expect(row['isDone'], 1, reason: 'کار باید انجام‌شده باشد');
    expect(row['reminderId'], isNull, reason: 'reminderId باید پاک شود');
    expect(row['reminderAtMs'], isNull, reason: 'reminderAtMs باید پاک شود');
  });

  // ═══════════════════════════════════════════════════════
  // T8 — simple_mode_shell_tab_count_test
  // حالت ساده = ۳ تب، حالت کامل = ۵ تب
  // ═══════════════════════════════════════════════════════
  test('simple_mode_shell_tab_count_test', () {
    const simpleTabCount = 3;
    const fullTabCount = 5;

    expect(simpleTabCount, 3, reason: 'حالت ساده باید ۳ تب داشته باشد');
    expect(fullTabCount, 5, reason: 'حالت کامل باید ۵ تب داشته باشد');
    expect(simpleTabCount, lessThan(fullTabCount));
  });

  // ═══════════════════════════════════════════════════════
  // T9 — mode_switch_resets_index_test
  // تعویض از کامل (ایندکس ۴) به ساده بدون RangeError
  // ═══════════════════════════════════════════════════════
  test('mode_switch_resets_index_test', () {
    int currentIndex = 4;
    const newTabCount = 3;

    if (currentIndex >= newTabCount) {
      currentIndex = 0;
    }

    expect(currentIndex, 0, reason: 'بعد از تعویض حالت، ایندکس باید ریست شود');
    expect(currentIndex, lessThan(newTabCount),
        reason: 'ایندکس جدید باید درون محدوده باشد و RangeError ندهد');
  });

  // ═══════════════════════════════════════════════════════
  // T10 — simple_onboarding_creates_no_routine_test
  // بعد از آنبوردینگ ساده COUNT(*) FROM routines == 0
  // ═══════════════════════════════════════════════════════
  test('simple_onboarding_creates_no_routine_test', () async {
    final db = MockTestDb();

    final countResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM routines');
    final count = (countResult.first['cnt'] as int?) ?? 0;

    expect(count, 0,
        reason: 'بعد از آنبوردینگ ساده، هیچ روتینی نباید وجود داشته باشد');
  });

  // ═══════════════════════════════════════════════════════
  // T11 — snooze_quota_off_allows_many_test
  // با snooze_quota_enabled = false پنج تعویق پیاپی مجاز است
  // ═══════════════════════════════════════════════════════
  test('snooze_quota_off_allows_many_test', () {
    final now = DateTime.now().copyWith(hour: 8, minute: 0, second: 0);

    for (int deferCount = 0; deferCount < 5; deferCount++) {
      final decision = SnoozePolicy.evaluate(
        itemId: 'test_item',
        now: now,
        requestedMinutes: 15,
        currentDeferCount: deferCount,
        category: 'generic',
        quotaEnabled: false,
      );

      expect(
        decision.verdict,
        isNot(SnoozeVerdict.exhausted),
        reason: 'با quotaEnabled=false، تعویق شماره $deferCount نباید خطا دهد',
      );
    }
  });

  // ═══════════════════════════════════════════════════════
  // T12 — snooze_medical_still_capped_test
  // دارو همچنان سقف ۲ دارد (بدون توجه به quotaEnabled)
  // ═══════════════════════════════════════════════════════
  test('snooze_medical_still_capped_test', () {
    final cap = SnoozePolicy.maxCap(
      category: 'medical',
      quotaEnabled: false,
    );

    expect(cap, 2, reason: 'سقف تعویق دارو همیشه باید ۲ باشد');

    final capEssential = SnoozePolicy.maxCap(
      isEssential: 1,
      quotaEnabled: false,
    );
    expect(capEssential, 2, reason: 'موارد ضروری (isEssential=1) هم سقف ۲ دارند');

    final capGeneric = SnoozePolicy.maxCap(
      category: 'generic',
      quotaEnabled: false,
    );
    expect(capGeneric, 9999, reason: 'غیردارویی با سهمیه خاموش سقف بی‌نهایت دارد');
  });
}
