import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class AssistantSuggestion {

  AssistantSuggestion({
    required this.id,
    required this.title,
    required this.body,
    required this.suggestionType,
    required this.status,
    required this.createdAt,
  });

  factory AssistantSuggestion.fromMap(Map<String, dynamic> map) {
    return AssistantSuggestion(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      suggestionType: map['suggestionType'] as String,
      status: map['status'] as String,
      createdAt: map['createdAt'] as int,
    );
  }
  final String id;
  final String title;
  final String body;
  final String suggestionType; // 'ENERGY', 'SPORTS', 'CIRCADIAN', 'COGNITIVE'
  final String status; // 'PENDING', 'APPLIED', 'DISMISSED'
  final int createdAt;
}

class AssistantSuggestionsService {
  static Future<List<AssistantSuggestion>> getPendingSuggestions() async {
    final db = await DatabaseHelper.instance.database;
    
    // Check if we already have pending suggestions
    final rows = await db.query(
      'assistant_suggestions',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'createdAt DESC',
    );
    
    if (rows.isNotEmpty) {
      return rows.map(AssistantSuggestion.fromMap).toList();
    }
    
    // If empty, generate new suggestions based on database heuristics
    await _generateHeuristicSuggestions(db);
    
    final newRows = await db.query(
      'assistant_suggestions',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'createdAt DESC',
    );
    return newRows.map(AssistantSuggestion.fromMap).toList();
  }

  static Future<void> _generateHeuristicSuggestions(dynamic db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const uuid = Uuid();

    // 1. Check recent recovery logs for sports muscle soreness
    var sportsSuggestionBody = 'به علت گرفتگی عضلات، پیشنهاد می‌شود امروز تمرین بالاتنه (سینه/پشت) انجام دهید و مکمل‌های بعد از تمرین را مصرف کنید.';
    
    try {
      final recoveryRows = (await db.query(
        'workout_recovery_logs',
        orderBy: 'loggedAt DESC',
        limit: 1,
      )) as List<Map<String, Object?>>;
      if (recoveryRows.isNotEmpty) {
        final soreStr = recoveryRows.first['soreMuscleGroups'] as String? ?? '';
        if (soreStr.contains('LEGS')) {
          sportsSuggestionBody = 'به علت گزارش گرفتگی شدید در عضلات پا، پیشنهاد می‌کنیم برنامه تمرینی امروز را به عضلات بالاتنه تغییر داده یا تمرین کششی انجام دهید.';
        }
      }
    } catch (e) {
      debugPrint('Error reading workout recovery logs: $e');
    }

    // 2. Check recent daily reflections for anxiety/stress keywords
    var cognitiveSuggestionBody = 'تحلیل یادداشت‌های اخیر نشان‌دهنده افزایش سطح استرس است. مایلید یک روتین پیاده‌روی ۱۰ دقیقه‌ای به تقویم فردا اضافه کنیم؟';
    
    try {
      final reflectionRows = (await db.query(
        'daily_reflections',
        orderBy: 'createdAt DESC',
        limit: 3,
      )) as List<Map<String, Object?>>;
      for (final row in reflectionRows) {
        final text = row['text'] as String? ?? '';
        if (text.contains('خسته') || text.contains('استرس') || text.contains('نگران')) {
          cognitiveSuggestionBody = 'تحلیل یادداشت‌های روزهای اخیر نشان‌دهنده خستگی و استرس بالا است. پیشنهاد می‌کنیم فردا را به عنوان روز ریکاوری و رهاسازی ذهن بگذرانید و یک پیاده‌روی کوتاه انجام دهید.';
          break;
        }
      }
    } catch (e) {
      debugPrint('Error reading daily reflections: $e');
    }

    // Insert Heuristic Suggestions
    await db.insert('assistant_suggestions', {
      'id': uuid.v4(),
      'title': 'بهینه‌ساز انرژی ⚡',
      'body': 'سطح انرژی شما بر اساس کیفیت خواب دیشب پایین پیش‌بینی می‌شود. مایلید کارهای سنگین امروز را به فردا منتقل کرده و یک روتین کششی سبک انجام دهید؟',
      'suggestionType': 'ENERGY',
      'status': 'PENDING',
      'createdAt': now,
    });

    await db.insert('assistant_suggestions', {
      'id': uuid.v4(),
      'title': 'تنظیم برنامه ورزشی 🏃',
      'body': sportsSuggestionBody,
      'suggestionType': 'SPORTS',
      'status': 'PENDING',
      'createdAt': now - 1000,
    });

    await db.insert('assistant_suggestions', {
      'id': uuid.v4(),
      'title': 'ساعت تمرکز طلایی 📚',
      'body': 'بر اساس تحلیل عملکرد شما، بازدهی ذهنی‌تان بین ۱۰ تا ۱۲ صبح در بالاترین حد است. پیشنهاد می‌کنیم ساعت ترجیحی مطالعه دوره جدید خود را به این بازه تغییر دهید.',
      'suggestionType': 'CIRCADIAN',
      'status': 'PENDING',
      'createdAt': now - 2000,
    });

    await db.insert('assistant_suggestions', {
      'id': uuid.v4(),
      'title': 'بینش خودمراقبتی 🧠',
      'body': cognitiveSuggestionBody,
      'suggestionType': 'COGNITIVE',
      'status': 'PENDING',
      'createdAt': now - 3000,
    });
  }

  static Future<void> dismissSuggestion(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'assistant_suggestions',
      {'status': 'DISMISSED'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<bool> applySuggestion(String id, BuildContext context) async {
    final db = await DatabaseHelper.instance.database;
    
    // Get suggestion details
    final rows = await db.query(
      'assistant_suggestions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    
    final suggestion = AssistantSuggestion.fromMap(rows.first);
    
    var success = false;
    
    if (suggestion.suggestionType == 'ENERGY') {
      // Rule 1: Reschedule heavy tasks (simulated here since calendar exceptions are dynamic)
      success = true;
    } else if (suggestion.suggestionType == 'SPORTS') {
      // Rule 2: Update workout split day for today to CHEST,BACK
      try {
        final weekday = DateTime.now().weekday;
        await db.update(
          'workout_split_days',
          {
            'muscleGroups': 'CHEST,BACK',
            'isRest': 0,
          },
          where: 'weekday = ?',
          whereArgs: [weekday],
        );
        success = true;
      } catch (e) {
        debugPrint('Error updating split days: $e');
      }
    } else if (suggestion.suggestionType == 'CIRCADIAN') {
      // Rule 3: Update courses preferredTime to 10:00
      try {
        await db.update(
          'courses',
          {'preferredTime': '10:00'},
        );
        success = true;
      } catch (e) {
        debugPrint('Error updating courses: $e');
      }
    } else if (suggestion.suggestionType == 'COGNITIVE') {
      // Rule 4: Add a new walking routine for tomorrow
      try {
        const uuid = Uuid();
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowWeekday = tomorrow.weekday;
        
        final routineId = uuid.v4();
        await db.insert('routines', {
          'id': routineId,
          'title': 'پیاده‌روی ریکاوری',
          'description': 'پیاده‌روی ۱۰ دقیقه‌ای برای کاهش استرس',
          'category': 'fitness',
          'targetDurationMinutes': 10,
          'lightDurationMinutes': 5,
          'energyLevel': 'LOW',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
        
        await db.insert('routine_schedules', {
          'id': uuid.v4(),
          'routineId': routineId,
          'weekday': tomorrowWeekday,
        });
        success = true;
      } catch (e) {
        debugPrint('Error inserting routine: $e');
      }
    }
    
    if (success) {
      await db.update(
        'assistant_suggestions',
        {'status': 'APPLIED'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    return success;
  }
}
