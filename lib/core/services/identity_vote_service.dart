import 'package:ritmo/core/database/database_helper.dart';

class IdentityVoteSummary {
  const IdentityVoteSummary({
    required this.goalId,
    required this.goalTitle,
    required this.identityStatement,
    required this.votesThisWeek,
    required this.totalVotes,
  });

  final String goalId;
  final String goalTitle;
  final String identityStatement;
  final int votesThisWeek;
  final int totalVotes;
}

class IdentityVoteService {
  IdentityVoteService._();
  static final IdentityVoteService instance = IdentityVoteService._();

  /// Calculates votes cast for identity-based goals in the past week (§3, م-۱۰).
  Future<List<IdentityVoteSummary>> getWeeklyIdentityVotes({DateTime? now}) async {
    final db = await DatabaseHelper.instance.database;
    final currentTime = now ?? DateTime.now();
    final weekStartMs = currentTime.subtract(const Duration(days: 7)).millisecondsSinceEpoch;

    final goals = await db.query(
      'goals',
      where: "identityStatement IS NOT NULL AND identityStatement != '' AND isPrivate = 0",
    );

    final summaries = <IdentityVoteSummary>[];

    for (final g in goals) {
      final goalId = g['id'] as String;
      final title = g['title'] as String? ?? '';
      final statement = g['identityStatement'] as String;

      // Count completions linked to this goal or its steps
      final completions = await db.rawQuery('''
        SELECT completionTime FROM routine_completions rc
        JOIN routines r ON rc.routineId = r.id
        JOIN goal_steps gs ON gs.linkedRoutineId = r.id
        WHERE gs.goalId = ? AND rc.resultType IN ('COMPLETED', 'DONE', 'PARTIAL')
      ''', [goalId]);

      int weekVotes = 0;
      final totalVotes = completions.length;

      for (final c in completions) {
        final timeMs = c['completionTime'] as int? ?? 0;
        if (timeMs >= weekStartMs) {
          weekVotes++;
        }
      }

      summaries.add(IdentityVoteSummary(
        goalId: goalId,
        goalTitle: title,
        identityStatement: statement,
        votesThisWeek: weekVotes,
        totalVotes: totalVotes,
      ));
    }

    return summaries;
  }
}
