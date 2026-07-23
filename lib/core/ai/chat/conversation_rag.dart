import 'package:ritmo/core/ai/ai_context_builder.dart';
import 'package:ritmo/core/database/database_helper.dart';

class RagResult {   // فقط aggregate
  const RagResult({this.blocked = false, this.blockReason, this.blockMessage, this.data = const {}});
  final bool blocked;
  final String? blockReason;   // 'cycle_no_consent' | 'medical'
  final String? blockMessage;  // متن فارسی ثابت برای نمایش بدون LLM
  final Map<String, dynamic> data;
}

class ConversationRAG {
  Future<RagResult> retrieve({required String query, required ConsentProfile consent}) async {
    // 1) Privacy Guard
    final normalized = query.toLowerCase().replaceAll('\u200c', ' ');

    final cycleKeywords = [
      'چرخه', 'قاعدگی', 'پریود', 'پریودی', 'هورمون', 'سیکل', 'عادت ماهیانه',
      'cycle', 'menstrual', 'period', 'hormone', 'hormonal', 'pregnancy'
    ];
    final medicalKeywords = [
      'دارو', 'داروها', 'دوز', 'قرص', 'آمپول', 'نسخه', 'بیماری', 'درمان', 'پزشک', 'پزشکی',
      'medicine', 'medication', 'medical', 'dose', 'dosage', 'prescription'
    ];

    final hasCycleKeyword = cycleKeywords.any(normalized.contains);
    final hasMedicalKeyword = medicalKeywords.any(normalized.contains);

    if (hasCycleKeyword && consent.cycleConsentChat != true) {
      return const RagResult(
        blocked: true,
        blockReason: 'cycle_no_consent',
        blockMessage: 'برای حفظ حریم خصوصی، اطلاعات چرخه و سلامت بانوان در چت عمومی مدیریت نمی‌شوند. لطفاً از دستیار اختصاصی بخش چرخه استفاده کنید.',
      );
    }

    if (hasMedicalKeyword) {
      return const RagResult(
        blocked: true,
        blockReason: 'medical',
        blockMessage: 'برای حفظ ایمنی، اطلاعات پزشکی و یادآورهای دارویی از طریق دستیار مدیریت نمی‌شوند؛ لطفاً این موارد را مستقیماً در بخش سلامت مدیریت کنید.',
      );
    }

    // 2) Pattern matching & aggregate fetches (30-day window)
    final dateLimit = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
    final timestampLimit = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    final retrievedData = <String, dynamic>{};

    final hasFitness = ['ورزش', 'تمرین', 'دویدن', 'فیتنس', 'running'].any(normalized.contains);
    final hasStudy = ['مطالعه', 'درس', 'کتاب', 'کنکور', 'آزمون', 'تست'].any(normalized.contains);
    final hasPrayer = ['نماز', 'واجب', 'عبادت', 'دعا', 'ذکر', 'قضا'].any(normalized.contains);
    final hasSleep = ['خواب', 'بیدار', 'bedtime'].any(normalized.contains);
    final hasEnergy = ['انرژی', 'خلق', 'روحیه', 'خستگی', 'mood'].any(normalized.contains);
    final hasGoals = ['هدف', 'اهداف', 'پیشرفت', 'گام'].any(normalized.contains);
    final hasReflection = ['تأمل', 'بازتاب', 'خودارزیاب', 'روزنگار'].any(normalized.contains);

    if (hasFitness) {
      retrievedData['fitness'] = await _fetchRoutineStats('fitness', dateLimit);
    }
    if (hasStudy) {
      retrievedData['study'] = await _fetchStudyStats(dateLimit);
    }
    if (hasPrayer) {
      retrievedData['worship'] = await _fetchWorshipStats();
    }
    if (hasSleep) {
      retrievedData['sleep'] = await _fetchSleepStats(timestampLimit);
    }
    if (hasEnergy) {
      retrievedData['energy'] = await _fetchEnergyStats(timestampLimit);
    }
    if (hasGoals) {
      retrievedData['goals'] = await _fetchGoalStats();
    }
    if (hasReflection) {
      retrievedData['reflection'] = await _fetchReflectionStats(timestampLimit);
    }

    return RagResult(data: retrievedData);
  }

  Future<Map<String, dynamic>> _fetchRoutineStats(String category, String dateLimit) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN rc.resultType = 'COMPLETE' THEN 1 ELSE 0 END) as completed,
          SUM(CASE WHEN rc.resultType = 'SNOOZE' THEN 1 ELSE 0 END) as skipped,
          COUNT(*) as total
        FROM routine_completions rc
        JOIN routines r ON rc.routineId = r.id
        WHERE r.category = ? AND rc.completionDate >= ?
      ''', [category, dateLimit]);
      if (result.isEmpty) return {'completed': 0, 'skipped': 0, 'total': 0};
      return {
        'completed': result.first['completed'] ?? 0,
        'skipped': result.first['skipped'] ?? 0,
        'total': result.first['total'] ?? 0,
      };
    } catch (_) {
      return {'completed': 0, 'skipped': 0, 'total': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchStudyStats(String dateLimit) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final konkurResult = await db.rawQuery('''
        SELECT SUM(durationMinutes) as minutes, COUNT(*) as count 
        FROM konkur_study_sessions 
        WHERE dateIso >= ?
      ''', [dateLimit]);
      final konkurMins = (konkurResult.first['minutes'] as num?)?.toInt() ?? 0;
      final konkurCount = (konkurResult.first['count'] as num?)?.toInt() ?? 0;

      final courseResult = await db.rawQuery('''
        SELECT SUM(actualDurationMinutes) as minutes, COUNT(*) as count 
        FROM course_sessions 
        WHERE plannedDate >= ? AND completionStatus = 'COMPLETED'
      ''', [dateLimit]);
      final courseMins = (courseResult.first['minutes'] as num?)?.toInt() ?? 0;
      final courseCount = (courseResult.first['count'] as num?)?.toInt() ?? 0;

      return {
        'total_minutes': konkurMins + courseMins,
        'sessions': konkurCount + courseCount,
      };
    } catch (_) {
      return {'total_minutes': 0, 'sessions': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchWorshipStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final practicesResult = await db.rawQuery('SELECT COUNT(*) as count FROM worship_practices WHERE isActive = 1');
      final practicesCount = (practicesResult.first['count'] as num?)?.toInt() ?? 0;

      final debtsResult = await db.rawQuery('SELECT SUM(debtCount) as count FROM worship_debts');
      final debtsCount = (debtsResult.first['count'] as num?)?.toInt() ?? 0;

      return {
        'practices_count': practicesCount,
        'debts_count': debtsCount,
      };
    } catch (_) {
      return {'practices_count': 0, 'debts_count': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchSleepStats(int timestampLimit) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT AVG(quality) as avg_quality, COUNT(*) as count 
        FROM bedtime_diagnostics 
        WHERE createdAt >= ?
      ''', [timestampLimit]);
      if (result.isEmpty) return {'avg_quality': 0.0, 'entries': 0};
      return {
        'avg_quality': (result.first['avg_quality'] as num?)?.toDouble() ?? 0.0,
        'entries': (result.first['count'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {'avg_quality': 0.0, 'entries': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchEnergyStats(int timestampLimit) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as entries,
          SUM(CASE WHEN energyLevel = 'LOW' THEN 1 ELSE 0 END) as low_count,
          SUM(CASE WHEN energyLevel = 'HIGH' THEN 1 ELSE 0 END) as high_count
        FROM energy_logs 
        WHERE loggedAt >= ?
      ''', [timestampLimit]);
      if (result.isEmpty) return {'entries': 0, 'low_count': 0, 'high_count': 0};
      return {
        'entries': (result.first['entries'] as num?)?.toInt() ?? 0,
        'low_count': (result.first['low_count'] as num?)?.toInt() ?? 0,
        'high_count': (result.first['high_count'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {'entries': 0, 'low_count': 0, 'high_count': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchGoalStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final activeGoalsResult = await db.rawQuery("SELECT COUNT(*) as count FROM goals WHERE status = 'ACTIVE'");
      final activeCount = (activeGoalsResult.first['count'] as num?)?.toInt() ?? 0;

      final stepsResult = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN gs.isCompleted = 1 THEN 1 ELSE 0 END) as completed_steps,
          COUNT(*) as total_steps
        FROM goal_steps gs
        JOIN goals g ON gs.goalId = g.id
        WHERE g.status = 'ACTIVE'
      ''');
      
      return {
        'active': activeCount,
        'completed_steps': (stepsResult.first['completed_steps'] as num?)?.toInt() ?? 0,
        'total_steps': (stepsResult.first['total_steps'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {'active': 0, 'completed_steps': 0, 'total_steps': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchReflectionStats(int timestampLimit) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT AVG(mood_score) as avg_mood, COUNT(*) as count 
        FROM daily_reflections 
        WHERE createdAt >= ? AND isPrivate = 0
      ''', [timestampLimit]);
      if (result.isEmpty) return {'count': 0, 'avg_mood': 0.0};
      return {
        'count': (result.first['count'] as num?)?.toInt() ?? 0,
        'avg_mood': (result.first['avg_mood'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (_) {
      return {'count': 0, 'avg_mood': 0.0};
    }
  }
}
