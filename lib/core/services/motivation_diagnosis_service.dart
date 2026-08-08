import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

enum SkipReasonType {
  tired,        // خسته بودم
  noStartPoint, // نمی‌دانستم از کجا شروع کنم
  tooBig,       // خیلی بزرگ بود
  notInMood,    // حوصله نداشتم
  forgot,       // یادم رفت
  external,     // بیرونی بود (مهمان، سفر، کار)
}

class MotivationDiagnosisService {
  MotivationDiagnosisService._();
  static final MotivationDiagnosisService instance = MotivationDiagnosisService._();

  /// Maps human-readable Persian skip reason selection to enum.
  SkipReasonType parseReason(String reasonKey) {
    switch (reasonKey) {
      case 'TIRED':
        return SkipReasonType.tired;
      case 'NO_START_POINT':
        return SkipReasonType.noStartPoint;
      case 'TOO_BIG':
        return SkipReasonType.tooBig;
      case 'NOT_IN_MOOD':
        return SkipReasonType.notInMood;
      case 'FORGOT':
        return SkipReasonType.forgot;
      case 'EXTERNAL':
      default:
        return SkipReasonType.external;
    }
  }

  /// Records skip reason for a routine completion in DB.
  /// If reason is EXTERNAL (§5), preserves streak and excludes from failure stats.
  Future<void> recordSkipReason({
    required String completionId,
    required String routineId,
    required SkipReasonType reason,
    String? dateStr,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'routine_completions',
        {'skipReason': reason.name.toUpperCase()},
        where: 'id = ?',
        whereArgs: [completionId],
      );

      if (dateStr != null && dateStr.isNotEmpty) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await txn.insert(
          'skip_reasons',
          {
            'id': 'sr_${routineId}_$dateStr',
            'itemId': routineId,
            'domain': 'routine',
            'dateStr': dateStr,
            'reason': reason.name.toUpperCase(),
            'note': null,
            'createdAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Returns recommended corrective action for a given skip reason (§5 نگاشت علت به اقدام).
  Map<String, dynamic> getActionForReason(SkipReasonType reason) {
    switch (reason) {
      case SkipReasonType.tired:
        return {
          'actionType': 'SHRINK_OR_MOVE_PEAK',
          'title': 'پیشنهاد نسخهٔ حداقلی یا انتقال به اوج انرژی',
          'description': 'برای دفعهٔ بعد نسخهٔ کوتاه‌تر اجرا شود یا زمان به پنجرهٔ اوج انرژی منتقل شود.',
        };
      case SkipReasonType.noStartPoint:
        return {
          'actionType': 'ADD_FIRST_PHYSICAL_STEP',
          'title': 'تعیین اولین قدم فیزیکی',
          'description': 'یک اقدام کوچک فیزیکی (مثلاً: باز کردن کتاب صفحهٔ ۱۲) ثبت کنید.',
        };
      case SkipReasonType.tooBig:
        return {
          'actionType': 'BREAK_DOWN_WIZARD',
          'title': 'شکستن کار به ۲ تا ۳ زیرگام',
          'description': 'تقسیم فعالیت بزرگ به گام‌های کوچک و مستقل.',
        };
      case SkipReasonType.notInMood:
        return {
          'actionType': 'TEMPTATION_BUNDLE',
          'title': 'بسته‌بندی وسوسه یا تغییر ساعت',
          'description': 'اتصال این کار به یک فعالیت لذت‌بخش یا انتقال به بازهٔ خلق بالا.',
        };
      case SkipReasonType.forgot:
        return {
          'actionType': 'HABIT_STACKING',
          'title': 'تغییر نشانه و زنجیره‌سازی',
          'description': 'اتصال این کار به یک روتین تثبیت‌شده یا مکان مشخص.',
        };
      case SkipReasonType.external:
        return {
          'actionType': 'NONE_PRESERVE_STREAK',
          'title': 'ثبت دلیل بیرونی (حفظ زنجیره)',
          'description': 'دلیل بیرونی ثبت شد. این نوبت در آمار شکست حساب نمی‌شود.',
        };
    }
  }
}
