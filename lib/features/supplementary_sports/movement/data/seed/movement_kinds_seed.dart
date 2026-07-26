import 'package:sqflite/sqflite.dart';

/// Seed data for the Movement Layer taxonomy (kinds).
class MovementKindsSeed {
  static Future<void> ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movement_kinds (
          code TEXT PRIMARY KEY,
          titleFa TEXT NOT NULL,
          emoji TEXT NOT NULL,
          family TEXT NOT NULL,
          baseMet REAL NOT NULL,
          metLow REAL NOT NULL,
          metHigh REAL NOT NULL,
          primaryMetric TEXT,
          secondaryMetric TEXT,
          isOutdoor INTEGER NOT NULL DEFAULT 0,
          isSocial INTEGER NOT NULL DEFAULT 0,
          needsVenue INTEGER NOT NULL DEFAULT 0,
          seasonMask TEXT,
          jointImpact INTEGER NOT NULL DEFAULT 1,
          aliasesFa TEXT,
          isCustom INTEGER NOT NULL DEFAULT 0,
          isEnabled INTEGER NOT NULL DEFAULT 1,
          usageCount INTEGER NOT NULL DEFAULT 0,
          lastUsedAt INTEGER,
          sortOrder INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_movement_kinds_family ON movement_kinds(family);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_movement_kinds_usage ON movement_kinds(usageCount DESC);');
  }

  static Future<void> seed(Database db) async {
    await ensureSchema(db);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Delete existing built-in kinds (keep user custom kinds with isCustom = 1)
    await db.delete('movement_kinds', where: 'isCustom = 0');

    final batch = db.batch();

    void addKind({
      required String code,
      required String titleFa,
      required String emoji,
      required String family,
      required double baseMet,
      required double metLow,
      required double metHigh,
      String? primaryMetric,
      String? secondaryMetric,
      bool isOutdoor = false,
      bool isSocial = false,
      bool needsVenue = false,
      String? seasonMask,
      int jointImpact = 1,
      String? aliasesFa,
      bool isEnabled = true,
      int sortOrder = 0,
    }) {
      batch.insert(
        'movement_kinds',
        {
          'code': code,
          'titleFa': titleFa,
          'emoji': emoji,
          'family': family,
          'baseMet': baseMet,
          'metLow': metLow,
          'metHigh': metHigh,
          'primaryMetric': primaryMetric ?? 'DURATION',
          'secondaryMetric': secondaryMetric,
          'isOutdoor': isOutdoor ? 1 : 0,
          'isSocial': isSocial ? 1 : 0,
          'needsVenue': needsVenue ? 1 : 0,
          'seasonMask': seasonMask,
          'jointImpact': jointImpact,
          'aliasesFa': aliasesFa,
          'isCustom': 0,
          'isEnabled': isEnabled ? 1 : 0,
          'usageCount': 0,
          'lastUsedAt': null,
          'sortOrder': sortOrder,
          'createdAt': now,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 🏃 ENDURANCE
    addKind(code: 'WALKING', titleFa: 'پیاده‌روی', emoji: '🚶', family: 'ENDURANCE', baseMet: 3.5, metLow: 2.5, metHigh: 4.5, primaryMetric: 'DISTANCE', jointImpact: 1, aliasesFa: 'قدم زدن,راه رفتن,پیاده');
    addKind(code: 'BRISK_WALKING', titleFa: 'پیاده‌روی تند', emoji: '🚶‍♂️', family: 'ENDURANCE', baseMet: 4.8, metLow: 4.0, metHigh: 5.5, primaryMetric: 'DISTANCE', jointImpact: 1, aliasesFa: 'پیاده روی سریع,قدم تند');
    addKind(code: 'RUNNING', titleFa: 'دویدن', emoji: '🏃', family: 'ENDURANCE', baseMet: 9.0, metLow: 7.0, metHigh: 12.0, primaryMetric: 'DISTANCE', jointImpact: 3, aliasesFa: 'دو,دویدن,جاگینگ');
    addKind(code: 'TRAIL_RUNNING', titleFa: 'دوی طبیعت', emoji: '🏃‍♂️', family: 'ENDURANCE', baseMet: 10.0, metLow: 8.0, metHigh: 13.0, primaryMetric: 'DISTANCE', isOutdoor: true, jointImpact: 3, aliasesFa: 'دوی کوهستان,دوی طبیعت');
    addKind(code: 'CYCLING', titleFa: 'دوچرخه‌سواری', emoji: '🚴', family: 'ENDURANCE', baseMet: 7.5, metLow: 4.0, metHigh: 12.0, primaryMetric: 'DISTANCE', isOutdoor: true, jointImpact: 0, aliasesFa: 'دوچرخه,پا زدن,رکاب زدن');
    addKind(code: 'STATIONARY_BIKE', titleFa: 'دوچرخهٔ ثابت', emoji: '🚴‍♂️', family: 'ENDURANCE', baseMet: 6.8, metLow: 4.0, metHigh: 10.0, primaryMetric: 'DURATION', jointImpact: 0, aliasesFa: 'دوچرخه ثابت,اسپینینگ');
    addKind(code: 'SWIMMING', titleFa: 'شنا', emoji: '🏊', family: 'ENDURANCE', baseMet: 7.0, metLow: 5.0, metHigh: 10.0, primaryMetric: 'LAPS', needsVenue: true, jointImpact: 0, aliasesFa: 'شنا,استخر,آب‌تنی');
    addKind(code: 'JUMP_ROPE', titleFa: 'طناب‌زدن', emoji: '🪢', family: 'ENDURANCE', baseMet: 11.0, metLow: 8.0, metHigh: 12.5, primaryMetric: 'DURATION', jointImpact: 3, aliasesFa: 'طناب زدن,طناب بازی');
    addKind(code: 'TREADMILL', titleFa: 'تردمیل', emoji: '🏃‍♀️', family: 'ENDURANCE', baseMet: 8.0, metLow: 5.0, metHigh: 11.0, primaryMetric: 'DISTANCE', jointImpact: 2, aliasesFa: 'تردمیل,دویدن روی تردمیل');
    addKind(code: 'ELLIPTICAL', titleFa: 'الپتیکال', emoji: '🚶‍♀️', family: 'ENDURANCE', baseMet: 5.0, metLow: 4.0, metHigh: 7.0, primaryMetric: 'DURATION', jointImpact: 0, aliasesFa: 'الپتیکال,اسکی فضایی');
    addKind(code: 'STAIR_CLIMBING', titleFa: 'پله‌نوردی', emoji: '🪜', family: 'ENDURANCE', baseMet: 8.0, metLow: 6.0, metHigh: 10.0, primaryMetric: 'DURATION', jointImpact: 2, aliasesFa: 'پله نوردی,پله بالا رفتن');
    addKind(code: 'ROWING', titleFa: 'قایق‌رانی / روئینگ', emoji: '🚣', family: 'ENDURANCE', baseMet: 7.0, metLow: 5.0, metHigh: 9.0, primaryMetric: 'DISTANCE', jointImpact: 0, aliasesFa: 'قایقرانی,روئینگ');

    // ⚽ SPORT
    addKind(code: 'FOOTBALL', titleFa: 'فوتبال', emoji: '⚽', family: 'SPORT', baseMet: 7.0, metLow: 5.0, metHigh: 9.0, isSocial: true, needsVenue: true, jointImpact: 2, aliasesFa: 'فوتبال,توپ بازی');
    addKind(code: 'FUTSAL', titleFa: 'فوتسال', emoji: '⚽', family: 'SPORT', baseMet: 8.0, metLow: 6.0, metHigh: 10.0, isSocial: true, needsVenue: true, jointImpact: 2, aliasesFa: 'فوتسال,سالن فوتسال');
    addKind(code: 'VOLLEYBALL', titleFa: 'والیبال', emoji: '🏐', family: 'SPORT', baseMet: 4.0, metLow: 3.0, metHigh: 6.0, isSocial: true, needsVenue: true, jointImpact: 1, aliasesFa: 'والیبال');
    addKind(code: 'BASKETBALL', titleFa: 'بسکتبال', emoji: '🏀', family: 'SPORT', baseMet: 6.5, metLow: 5.0, metHigh: 8.5, isSocial: true, needsVenue: true, jointImpact: 2, aliasesFa: 'بسکتبال');
    addKind(code: 'TENNIS', titleFa: 'تنیس', emoji: '🎾', family: 'SPORT', baseMet: 7.3, metLow: 5.0, metHigh: 9.5, isSocial: true, needsVenue: true, jointImpact: 1, aliasesFa: 'تنیس,راکت');
    addKind(code: 'TABLE_TENNIS', titleFa: 'پینگ‌پنگ', emoji: '🏓', family: 'SPORT', baseMet: 4.0, metLow: 3.0, metHigh: 5.5, isSocial: true, jointImpact: 0, aliasesFa: 'پینگ پنگ,تنیس روی میز');
    addKind(code: 'BADMINTON', titleFa: 'بدمینتون', emoji: '🏸', family: 'SPORT', baseMet: 5.5, metLow: 4.0, metHigh: 7.5, isSocial: true, jointImpact: 1, aliasesFa: 'بدمینتون');
    addKind(code: 'SQUASH', titleFa: 'اسکواش', emoji: '💥', family: 'SPORT', baseMet: 12.0, metLow: 9.0, metHigh: 14.0, isSocial: true, needsVenue: true, jointImpact: 2, aliasesFa: 'اسکواش');

    // 🧘 MIND_BODY
    addKind(code: 'YOGA', titleFa: 'یوگا', emoji: '🧘', family: 'MIND_BODY', baseMet: 3.0, metLow: 2.0, metHigh: 4.5, primaryMetric: 'DURATION', jointImpact: 0, aliasesFa: 'یوگا,تمرکز,مدیتیشن');
    addKind(code: 'PILATES', titleFa: 'پیلاتس', emoji: '🧘‍♂️', family: 'MIND_BODY', baseMet: 3.8, metLow: 2.5, metHigh: 5.0, primaryMetric: 'DURATION', jointImpact: 0, aliasesFa: 'پیلاتس,اصلاحی');
    addKind(code: 'STRETCHING', titleFa: 'کشش', emoji: '🤸', family: 'MIND_BODY', baseMet: 2.3, metLow: 1.8, metHigh: 3.0, primaryMetric: 'DURATION', jointImpact: 0, aliasesFa: 'کشش,انعطاف,گرم کردن');
    addKind(code: 'TAI_CHI', titleFa: 'تای‌چی', emoji: '☯️', family: 'MIND_BODY', baseMet: 3.0, metLow: 2.0, metHigh: 4.0, primaryMetric: 'DURATION', jointImpact: 0, aliasesFa: 'تای چی,حرکت آرام');
    addKind(code: 'BREATHWORK', titleFa: 'تمرین تنفس', emoji: '🫁', family: 'MIND_BODY', baseMet: 1.8, metLow: 1.2, metHigh: 2.5, primaryMetric: 'DURATION', jointImpact: 0, aliasesFa: 'تنفس,تمرین تنفسی');

    // 🏔 OUTDOOR
    addKind(code: 'HIKING', titleFa: 'کوه‌نوردی', emoji: '🏔', family: 'OUTDOOR', baseMet: 6.0, metLow: 4.5, metHigh: 8.5, primaryMetric: 'DISTANCE', isOutdoor: true, seasonMask: '1,2,3,7,8,9', jointImpact: 2, aliasesFa: 'کوهنوردی,کوه,پیاده روی کوه');
    addKind(code: 'NATURE_WALK', titleFa: 'طبیعت‌گردی', emoji: '🌲', family: 'OUTDOOR', baseMet: 4.0, metLow: 3.0, metHigh: 5.5, primaryMetric: 'DISTANCE', isOutdoor: true, jointImpact: 1, aliasesFa: 'طبیعت گردی,جنگل پیما');
    addKind(code: 'ROCK_CLIMBING', titleFa: 'صخره‌نوردی', emoji: '🧗', family: 'OUTDOOR', baseMet: 8.0, metLow: 6.0, metHigh: 11.0, primaryMetric: 'DURATION', isOutdoor: true, seasonMask: '1,2,3,7,8', jointImpact: 2, aliasesFa: 'صخره نوردی,سنگ نوردی');
    addKind(code: 'SKIING', titleFa: 'اسکی', emoji: '⛷', family: 'OUTDOOR', baseMet: 7.0, metLow: 5.0, metHigh: 9.5, primaryMetric: 'DURATION', isOutdoor: true, seasonMask: '10,11,12', jointImpact: 2, aliasesFa: 'اسکی,برف');
    addKind(code: 'SKATING', titleFa: 'اسکیت', emoji: '🛼', family: 'OUTDOOR', baseMet: 7.0, metLow: 5.0, metHigh: 9.0, primaryMetric: 'DURATION', isOutdoor: true, jointImpact: 2, aliasesFa: 'اسکیت,پاتیناژ');
    addKind(code: 'SURFING', titleFa: 'موج‌سواری', emoji: '🏄', family: 'OUTDOOR', baseMet: 5.0, metLow: 3.5, metHigh: 7.0, primaryMetric: 'DURATION', isOutdoor: true, seasonMask: '3,4,5,6', jointImpact: 1, aliasesFa: 'موج سواری,دریا');
    addKind(code: 'HORSE_RIDING', titleFa: 'اسب‌سواری', emoji: '🏇', family: 'OUTDOOR', baseMet: 5.5, metLow: 4.0, metHigh: 7.5, primaryMetric: 'DURATION', isOutdoor: true, jointImpact: 1, aliasesFa: 'اسب سواری,سوارکاری');

    // 🥋 MARTIAL_SKILL
    addKind(code: 'KARATE', titleFa: 'کاراته', emoji: '🥋', family: 'MARTIAL_SKILL', baseMet: 10.0, metLow: 7.0, metHigh: 12.0, primaryMetric: 'DURATION', jointImpact: 2, aliasesFa: 'کاراته,رزمی');
    addKind(code: 'TAEKWONDO', titleFa: 'تکواندو', emoji: '🥋', family: 'MARTIAL_SKILL', baseMet: 10.0, metLow: 7.0, metHigh: 12.0, primaryMetric: 'DURATION', jointImpact: 2, aliasesFa: 'تکواندو,رزمی');
    addKind(code: 'JUDO', titleFa: 'جودو', emoji: '🥋', family: 'MARTIAL_SKILL', baseMet: 10.0, metLow: 7.0, metHigh: 12.0, primaryMetric: 'DURATION', jointImpact: 2, aliasesFa: 'جودو,دفاع شخصی');
    addKind(code: 'BOXING', titleFa: 'بوکس', emoji: '🥊', family: 'MARTIAL_SKILL', baseMet: 9.0, metLow: 6.5, metHigh: 11.5, primaryMetric: 'DURATION', jointImpact: 2, aliasesFa: 'بوکس,کیسه بوکس');
    addKind(code: 'WRESTLING', titleFa: 'کشتی', emoji: '🤼', family: 'MARTIAL_SKILL', baseMet: 6.0, metLow: 4.5, metHigh: 8.5, primaryMetric: 'DURATION', jointImpact: 2, aliasesFa: 'کشتی,تشک');
    addKind(code: 'GYMNASTICS', titleFa: 'ژیمناستیک', emoji: '🤸‍♂️', family: 'MARTIAL_SKILL', baseMet: 3.8, metLow: 2.5, metHigh: 5.5, primaryMetric: 'DURATION', jointImpact: 1, aliasesFa: 'ژیمناستیک,آکروبات');
    addKind(code: 'DANCE', titleFa: 'رقص', emoji: '💃', family: 'MARTIAL_SKILL', baseMet: 5.0, metLow: 3.5, metHigh: 7.0, primaryMetric: 'DURATION', jointImpact: 1, aliasesFa: 'رقص,زومبا');

    // 🚶 DAILY
    addKind(code: 'COMMUTE_WALK', titleFa: 'پیاده تا محل کار', emoji: '🚶‍♂️', family: 'DAILY', baseMet: 3.5, metLow: 2.5, metHigh: 4.5, primaryMetric: 'DISTANCE', jointImpact: 1, aliasesFa: 'پیاده تا کار,رفت و آمد');
    addKind(code: 'STAIRS_INSTEAD', titleFa: 'پله به‌جای آسانسور', emoji: '🪜', family: 'DAILY', baseMet: 4.0, metLow: 3.0, metHigh: 5.5, primaryMetric: 'DURATION', jointImpact: 2, aliasesFa: 'پله جای آسانسور');
    addKind(code: 'GARDENING', titleFa: 'کار در باغچه', emoji: '🪴', family: 'DAILY', baseMet: 3.8, metLow: 2.5, metHigh: 5.0, primaryMetric: 'DURATION', jointImpact: 1, aliasesFa: 'باغبانی,گل کاری');
    addKind(code: 'PLAY_WITH_KIDS', titleFa: 'بازی با بچه', emoji: '👶', family: 'DAILY', baseMet: 4.0, metLow: 2.5, metHigh: 5.5, primaryMetric: 'DURATION', jointImpact: 1, aliasesFa: 'بازی با بچه,کودکان');
    addKind(code: 'HOUSEWORK', titleFa: 'خانه‌تکانی', emoji: '🧹', family: 'DAILY', baseMet: 3.3, metLow: 2.0, metHigh: 4.5, primaryMetric: 'DURATION', jointImpact: 1, aliasesFa: 'خانه تکانی,تمیزکاری');

    // 🏋️ STRENGTH
    addKind(code: 'STRENGTH_GYM', titleFa: 'تمرین قدرتی باشگاه', emoji: '🏋️', family: 'STRENGTH', baseMet: 5.0, metLow: 3.5, metHigh: 7.0, primaryMetric: 'DURATION', needsVenue: true, jointImpact: 2, aliasesFa: 'بدنسازی باشگاه,وزنه');
    addKind(code: 'STRENGTH_HOME', titleFa: 'تمرین قدرتی خانگی', emoji: '🏋️‍♂️', family: 'STRENGTH', baseMet: 4.5, metLow: 3.0, metHigh: 6.0, primaryMetric: 'DURATION', jointImpact: 1, aliasesFa: 'بدنسازی خانه,کالیستنیکس');
    addKind(code: 'SS_SESSION', titleFa: 'جلسهٔ برنامهٔ ریتمو', emoji: '⚡', family: 'STRENGTH', baseMet: 5.0, metLow: 3.5, metHigh: 7.0, isEnabled: false);
    addKind(code: 'CARDIO_GENERIC', titleFa: 'هوازی عمومی', emoji: '🫀', family: 'STRENGTH', baseMet: 6.0, metLow: 4.0, metHigh: 8.0, isEnabled: false);
    addKind(code: 'OTHER', titleFa: 'سایر ورزش‌ها', emoji: '🎯', family: 'STRENGTH', baseMet: 4.0, metLow: 2.5, metHigh: 6.0, isEnabled: false);

    await batch.commit(noResult: true);
  }
}
