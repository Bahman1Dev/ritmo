import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV66 extends Migration {
  @override
  int get version => 66;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // 1. Obligatory & Mustahab Practices Seed
    final practices = [
      {
        'id': 'wp_fajr',
        'practiceType': 'PRAYER',
        'subType': 'FAJR',
        'title': 'نماز صبح',
        'dailyTarget': 1,
        'dailyDone': 0,
        'isActive': 1,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_dhuhr',
        'practiceType': 'PRAYER',
        'subType': 'DHUHR',
        'title': 'نماز ظهر و عصر',
        'dailyTarget': 1,
        'dailyDone': 0,
        'isActive': 1,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_maghrib',
        'practiceType': 'PRAYER',
        'subType': 'MAGHRIB',
        'title': 'نماز مغرب و عشا',
        'dailyTarget': 1,
        'dailyDone': 0,
        'isActive': 1,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_asr',
        'practiceType': 'PRAYER',
        'subType': 'ASR',
        'title': 'نماز عصر',
        'dailyTarget': 1,
        'dailyDone': 0,
        'isActive': 0,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_isha',
        'practiceType': 'PRAYER',
        'subType': 'ISHA',
        'title': 'نماز عشا',
        'dailyTarget': 1,
        'dailyDone': 0,
        'isActive': 0,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_quran',
        'practiceType': 'QURAN',
        'subType': 'QURAN_READING',
        'title': 'قرائت قرآن کریم',
        'dailyTarget': 5,
        'dailyDone': 0,
        'isActive': 1,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_dhikr_zahra',
        'practiceType': 'DHIKR',
        'subType': 'DHIKR_ZAHRA',
        'title': 'تسبیحات حضرت زهرا (س)',
        'dailyTarget': 1,
        'dailyDone': 0,
        'isActive': 1,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_dhikr_salawat',
        'practiceType': 'DHIKR',
        'subType': 'SALAWAT',
        'title': 'صلوات',
        'dailyTarget': 100,
        'dailyDone': 0,
        'isActive': 1,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
      {
        'id': 'wp_dhikr_esteghfar',
        'practiceType': 'DHIKR',
        'subType': 'ESTEGHFAR',
        'title': 'استغفار',
        'dailyTarget': 70,
        'dailyDone': 0,
        'isActive': 1,
        'dailyDoneDate': todayStr,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      },
    ];

    final batch = db.batch();
    for (final p in practices) {
      batch.insert(
        'worship_practices',
        p,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 2. Worship Seasons Seed
    final seasons = [
      {
        'id': 'ws_muharram',
        'seasonType': 'SPECIAL_PERIOD',
        'title': 'دهه اول محرم',
        'startDate': '01-01',
        'endDate': '01-10',
        'calendar': 'HIJRI',
        'isActive': 1,
        'createdAt': nowMs,
        'priority_weight': 2.0,
      },
      {
        'id': 'ws_dhul_hijjah',
        'seasonType': 'SPECIAL_PERIOD',
        'title': 'دهه اول ذی‌الحجه',
        'startDate': '12-01',
        'endDate': '12-10',
        'calendar': 'HIJRI',
        'isActive': 1,
        'createdAt': nowMs,
        'priority_weight': 2.0,
      },
      {
        'id': 'ws_ayyam_al_beed',
        'seasonType': 'AYYAM_AL_BEED',
        'title': 'ایام البیض',
        'startDate': '13',
        'endDate': '15',
        'calendar': 'HIJRI',
        'isActive': 1,
        'createdAt': nowMs,
        'priority_weight': 3.0,
      },
      {
        'id': 'ws_qadr',
        'seasonType': 'QADR_NIGHTS',
        'title': 'شب‌های قدر',
        'startDate': '09-19',
        'endDate': '09-23',
        'calendar': 'HIJRI',
        'isActive': 1,
        'createdAt': nowMs,
        'priority_weight': 5.0,
      },
    ];

    for (final s in seasons) {
      batch.insert(
        'worship_seasons',
        s,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> down(Database db) async {}
}
