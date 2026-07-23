import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/memory/memory_models.dart';
import 'package:ritmo/core/database/database_helper.dart';

class AiMemoryService {
  AiMemoryService._privateConstructor();
  static final AiMemoryService instance = AiMemoryService._privateConstructor();

  static const double _lambda = 0.0041258; // Exp decay for 7-day half-life (hours)

  // Stop words for Persian tokenization
  static const Set<String> _stopWords = {
    'و', 'در', 'به', 'از', 'که', 'با', 'تا', 'این', 'آن',
    'را', 'برای', 'هم', 'چون', 'اگر', 'اما', 'ولی', 'یا',
    'من', 'تو', 'او', 'ما', 'شما', 'آنها', 'همین', 'همان'
  };

  static final RegExp explicitRememberRegex = RegExp(
    '(یادت باشه|یادت بمونه|فراموش نکن|به خاطر بسپار|remember)',
    caseSensitive: false,
  );

  static String memoryInstruction() {
    return '\n---'
        '\n[قانون حافظه صریح]'
        '\nاگر کاربر صریحاً خواست چیزی به خاطر سپرده شود (مثلاً با عباراتی مثل «یادت باشه...» یا «فراموش نکن...»)، شما باید فکت مربوطه را استخراج کرده و در انتهای پاسخ خود خارج از متن اصلی، دقیقاً با فرمت تگ زیر بفرستید. در متن اصلی پاسخ نیز خیلی کوتاه و صمیمانه ذخیره شدن آن را تأیید کنید:'
        '\n<memory_ops>[{"op":"ADD","content":"فکت استخراج‌شده به صورت جمله سوم‌شخص کوتاه فارسی","type":"preference","importance":10,"sensitive":false}]</memory_ops>'
        '\n---';
  }

  Future<void> processExplicitSafetyNet({
    required String userText,
    required String assistantResponse,
    required String domain,
    String? sessionId,
  }) async {
    try {
      if (!await isMemoryEnabled()) return;

      // Check if user text has explicit remember keywords and response does not contain <memory_ops>
      if (explicitRememberRegex.hasMatch(userText) && !assistantResponse.contains('<memory_ops>')) {
        // Clean user text of keywords to extract the core memory statement
        var content = userText
            .replaceAll(explicitRememberRegex, '')
            .replaceAll(RegExp('[،,.:!؟?()]+'), ' ')
            .trim();
        
        if (content.length > 300) {
          content = content.substring(0, 300);
        }

        if (content.isNotEmpty) {
          final op = MemoryOp(
            op: 'ADD',
            content: content,
            type: MemoryType.preference,
            domain: domain,
            importance: 10,
            sensitive: domain == 'cycle' || domain == 'health',
          );
          await applyOperations([op]);
        }
      }
    } catch (e) {
      debugPrint('[MEMORY] Error in explicit safety net: $e');
    }
  }

  /// Check if memory system is enabled globally
  Future<bool> isMemoryEnabled() async {
    return _getSetting('ai_memory_enabled', true);
  }

  /// Check if implicit memory learning is enabled
  Future<bool> isImplicitEnabled() async {
    return _getSetting('ai_memory_implicit_enabled', true);
  }

  /// Helper to get boolean setting
  Future<bool> _getSetting(String key, bool defaultValue) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
      if (res.isEmpty) return defaultValue;
      return res.first['value'].toString() == 'true';
    } catch (_) {
      return defaultValue;
    }
  }

  /// Retrieve relevant memories for the conversation
  Future<List<MemoryEntry>> retrieve({
    required String domain,
    required String query,
  }) async {
    if (!await isMemoryEnabled()) return [];

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Fetch all active, non-expired memories from database
      final List<Map<String, dynamic>> rows = await db.query(
        'ai_memory',
        where: "status = 'active' AND (expiresAt IS NULL OR expiresAt > ?)",
        whereArgs: [now],
      );

      final allMemories = rows.map(MemoryEntry.fromMap).toList();

      // 2. Filter based on Privacy check: sensitive memories only returned if domain matches or domain is 'core'
      final allowedMemories = allMemories.where((m) {
        if (m.sensitive) {
          return m.domain == domain || domain == 'core';
        }
        return true;
      }).toList();

      // 3. Separate pinned and unpinned memories
      final pinned = allowedMemories.where((m) => m.pinned).take(20).toList();
      final unpinnedCandidates = allowedMemories.where((m) => !m.pinned).toList();

      // 4. Score unpinned candidates
      final scoredUnpinned = <_ScoredMemory>[];
      for (final memory in unpinnedCandidates) {
        final score = _calculateScore(memory, domain, query);
        scoredUnpinned.add(_ScoredMemory(memory, score));
      }

      // Sort in descending order of score
      scoredUnpinned.sort((a, b) => b.score.compareTo(a.score));

      final retrievedUnpinned = scoredUnpinned
          .take(10)
          .map((sm) => sm.entry)
          .toList();

      final result = [...pinned, ...retrievedUnpinned];

      // 5. Update lastAccessedAt and accessCount for retrieved memories
      if (result.isNotEmpty) {
        final batch = db.batch();
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        for (final m in result) {
          batch.update(
            'ai_memory',
            {
              'lastAccessedAt': nowMs,
              'accessCount': m.accessCount + 1,
            },
            where: 'id = ?',
            whereArgs: [m.id],
          );
        }
        await batch.commit(noResult: true);
      }

      return result;
    } catch (e) {
      debugPrint('[MEMORY] Error retrieving memories: $e');
      return [];
    }
  }

  /// Calculate importance/recency/relevance score
  double _calculateScore(MemoryEntry m, String currentDomain, String query) {
    // 1. Recency score: decay over hours since last accessed
    final hoursSinceAccess = DateTime.now().difference(m.lastAccessedAt).inSeconds / 3600.0;
    final recency = math.exp(-_lambda * hoursSinceAccess);

    // 2. Importance ratio (0.0 to 1.0)
    final importanceRatio = m.importance / 10.0;

    // 3. Token relevance (Jaccard similarity)
    var relevance = _calculateTokenOverlap(query, m.content);

    // Fixed domain match bonus
    if (m.domain == currentDomain && currentDomain != 'core') {
      relevance += 0.3; // Give a boost for same-domain memories
    }

    // Weight formulas: 0.5 * recency + 2.0 * importanceRatio + 3.0 * relevance
    return (0.5 * recency) + (2.0 * importanceRatio) + (3.0 * relevance);
  }

  /// Jaccard token overlap calculation
  double _calculateTokenOverlap(String s1, String s2) {
    final t1 = _tokenize(s1);
    final t2 = _tokenize(s2);
    if (t1.isEmpty || t2.isEmpty) return 0;

    final intersection = t1.intersection(t2);
    final union = t1.union(t2);
    return intersection.length / union.length;
  }

  /// Tokenize Persian text (splits space/half-space, removes stop words)
  Set<String> _tokenize(String text) {
    final clean = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF‌]'), ' ') // Keep Persian chars, numbers, letters and ZWNJ
        .replaceAll('‌', ' '); // Replace ZWNJ with space to split half-space tokens
    return clean
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !_stopWords.contains(t))
        .toSet();
  }

  /// Format retrieved memories to Persian prompt block
  String buildPromptBlock(List<MemoryEntry> entries) {
    if (entries.isEmpty) return '';

    final lines = <String>[];
    for (final entry in entries) {
      final ageStr = _formatAge(entry.lastAccessedAt);
      lines.add('- ${entry.content} ($ageStr)');
    }

    return '\n---'
        '\n[اطلاعات پس‌زمینه کاربر]'
        '\nآنچه از قبل درباره کاربر می‌دانی:'
        '\n${lines.join('\n')}'
        '\nاین موارد پس‌زمینه‌اند؛ اگر حرف فعلی کاربر با آن‌ها تناقض داشت، حرف فعلی او مقدم است.'
        '\n---';
  }

  /// Helper to format age of memory entry
  String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return 'کمتر از یک ساعت پیش';
    } else if (diff.inHours < 24) {
      return '~${diff.inHours} ساعت پیش';
    } else if (diff.inDays < 30) {
      return '~${diff.inDays} روز پیش';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30.0).round();
      return '~$months ماه پیش';
    } else {
      final years = (diff.inDays / 365.0).round();
      return '~$years سال پیش';
    }
  }

  /// Apply database operations: ADD, UPDATE, DELETE, NOOP
  Future<void> applyOperations(List<MemoryOp> ops) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        for (final op in ops) {
          // Clean content before applying operations (strip HTML tags, limit 300 chars)
          final cleanedContent = op.content
              .replaceAll(RegExp('<[^>]*>'), '')
              .trim();
          final finalContent = cleanedContent.length > 300
              ? cleanedContent.substring(0, 300)
              : cleanedContent;

          if (finalContent.isEmpty && op.op != 'DELETE') continue;

          switch (op.op) {
            case 'ADD':
              // Generate unique ID
              final id = 'mem_${now}_${math.Random().nextInt(99999)}';
              final isExplicit = op.importance == 10;
              await txn.insert('ai_memory', {
                'id': id,
                'content': finalContent,
                'type': op.type.name,
                'domain': op.domain,
                'source': isExplicit ? MemorySource.explicit.name : MemorySource.implicit.name,
                'importance': op.importance,
                'pinned': isExplicit ? 1 : 0,
                'sensitive': op.sensitive ? 1 : 0,
                'status': MemoryStatus.active.name,
                'createdAt': now,
                'updatedAt': now,
                'lastAccessedAt': now,
                'accessCount': 0,
                'expiresAt': op.expiresAt?.millisecondsSinceEpoch,
              });

            case 'UPDATE':
              if (op.id == null) continue;
              await txn.update(
                'ai_memory',
                {
                  'content': finalContent,
                  'type': op.type.name,
                  'domain': op.domain,
                  'importance': op.importance,
                  'sensitive': op.sensitive ? 1 : 0,
                  'updatedAt': now,
                  'expiresAt': op.expiresAt?.millisecondsSinceEpoch,
                },
                where: 'id = ?',
                whereArgs: [op.id],
              );

            case 'DELETE':
              if (op.id == null) continue;
              // Set status to archived
              await txn.update(
                'ai_memory',
                {
                  'status': MemoryStatus.archived.name,
                  'updatedAt': now,
                },
                where: 'id = ?',
                whereArgs: [op.id],
              );

            case 'NOOP':
            default:
              break;
          }
        }
      });

      // Run automatic pruning/forgetfulness check
      await pruneMemories();
    } catch (e) {
      debugPrint('[MEMORY] Error applying memory operations: $e');
    }
  }

  /// Forgetfulness and capacity management logic
  Future<void> pruneMemories() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Forget memories with importance <= 4 that haven't been accessed in 60 days (5184000 seconds)
      final sixtyDaysAgoMs = now - (60 * 24 * 3600 * 1000);
      await db.update(
        'ai_memory',
        {'status': MemoryStatus.archived.name, 'updatedAt': now},
        where: "pinned = 0 AND status = 'active' AND importance <= 4 AND lastAccessedAt < ?",
        whereArgs: [sixtyDaysAgoMs],
      );

      // 2. Enforce limits: max 30 active unpinned memories for 'core', max 15 for any other domain
      final domains = ['core', 'health', 'cycle', 'worship', 'wellbeing', 'goals', 'konkur', 'courses', 'sports'];
      for (final d in domains) {
        final limit = d == 'core' ? 30 : 15;
        
        final List<Map<String, dynamic>> activeUnpinned = await db.query(
          'ai_memory',
          where: "status = 'active' AND pinned = 0 AND domain = ?",
          whereArgs: [d],
          orderBy: 'importance ASC, lastAccessedAt ASC', // Prune least important and oldest first
        );

        if (activeUnpinned.length > limit) {
          final toArchiveCount = activeUnpinned.length - limit;
          final batch = db.batch();
          for (var i = 0; i < toArchiveCount; i++) {
            final id = activeUnpinned[i]['id'] as String;
            batch.update(
              'ai_memory',
              {'status': MemoryStatus.archived.name, 'updatedAt': now},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
          await batch.commit(noResult: true);
        }
      }
    } catch (e) {
      debugPrint('[MEMORY] Error pruning memories: $e');
    }
  }
}

class _ScoredMemory {
  _ScoredMemory(this.entry, this.score);
  final MemoryEntry entry;
  final double score;
}
