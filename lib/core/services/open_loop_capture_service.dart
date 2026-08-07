import 'package:ritmo/core/database/database_helper.dart';

enum OpenLoopDecision {
  doNow,    // الان انجامش می‌دهم
  schedule, // برایش زمان می‌گذارم
  drop,     // رهایش می‌کنم
}

class OpenLoopCaptureService {
  OpenLoopCaptureService._();
  static final OpenLoopCaptureService instance = OpenLoopCaptureService._();

  /// Captures a quick thought / open loop into inbox.
  Future<String> captureThought({
    required String text,
    String? source,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'open_loop_$now';

    await db.insert('inbox_items', {
      'id': id,
      'category': 'CHECKIN',
      'sourceSystem': source ?? 'QUICK_CAPTURE',
      'title': text,
      'body': 'حلقهٔ باز — منتظر تصمیم‌گیری',
      'priority': 0,
      'status': 'UNREAD',
      'createdAt': now,
      'dedupeKey': 'open_loop_$now',
      'payloadJson': '{"isOpenLoop": true, "loopState": "OPEN"}',
    });

    return id;
  }

  /// Resolves an open loop with one of the 3 decisions (م-۷).
  Future<void> resolveOpenLoop({
    required String itemId,
    required OpenLoopDecision decision,
    String? scheduledDate,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String status = 'ACTIONED';
    String loopState = 'DONE';

    if (decision == OpenLoopDecision.drop) {
      status = 'ARCHIVED';
      loopState = 'DROPPED'; // Does not count in failure stats (§10 سناریو ۱۰)
    } else if (decision == OpenLoopDecision.schedule) {
      loopState = 'SCHEDULED';
    }

    final payloadJson = '{"isOpenLoop": true, "loopState": "$loopState", "scheduledDate": "${scheduledDate ?? ""}"}';

    await db.update(
      'inbox_items',
      {
        'status': status,
        'readAt': now,
        'payloadJson': payloadJson,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
}
