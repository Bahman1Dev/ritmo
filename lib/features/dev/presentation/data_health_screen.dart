import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class DataHealthScreen extends StatefulWidget {
  const DataHealthScreen({super.key});

  @override
  State<DataHealthScreen> createState() => _DataHealthScreenState();
}

class _DataHealthScreenState extends State<DataHealthScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _queryResults = [];

  @override
  void initState() {
    super.initState();
    _runHealthAuditQueries();
  }

  Future<void> _runHealthAuditQueries() async {
    if (!kDebugMode) return;

    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    final results = <Map<String, dynamic>>[];

    // Query 1: Duplicate routine completions
    final q1 = await db.rawQuery('''
      SELECT routineId, completionDate, COUNT(*) AS c
      FROM routine_completions
      GROUP BY routineId, completionDate
      HAVING c > 1;
    ''');
    results.add({'title': '۱. رکوردهای تکراری ثبت انجام', 'rows': q1, 'count': q1.length});

    // Query 2: Completion without done occurrence
    final q2 = await db.rawQuery('''
      SELECT c.id, c.routineId, c.completionDate
      FROM routine_completions c
      LEFT JOIN routine_occurrences o
        ON o.routine_id = c.routineId AND o.date = c.completionDate
      WHERE c.resultType NOT IN ('SKIPPED', 'RESCHEDULED')
        AND (o.status IS NULL OR o.status != 'done');
    ''');
    results.add({'title': '۲. ثبت انجام بدون رخداد done', 'rows': q2, 'count': q2.length});

    // Query 3: done occurrence without completion record
    final q3 = await db.rawQuery('''
      SELECT o.routine_id, o.date
      FROM routine_occurrences o
      LEFT JOIN routine_completions c
        ON c.routineId = o.routine_id AND c.completionDate = o.date
      WHERE o.status = 'done' AND c.id IS NULL;
    ''');
    results.add({'title': '۳. رخداد done بدون رکورد انجام', 'rows': q3, 'count': q3.length});

    // Query 4: Open reminders for completed items
    final q4 = await db.rawQuery('''
      SELECT pr.id, pr.routineId
      FROM pending_reminders pr
      JOIN routine_occurrences o ON o.routine_id = pr.routineId
      WHERE o.status = 'done' AND pr.state IN ('unknown', 'delayed');
    ''');
    results.add({'title': '۴. یادآورهای باز برای کارهای انجام‌شده', 'rows': q4, 'count': q4.length});

    // Query 5: Result source breakdown
    final q5 = await db.rawQuery('''
      SELECT resultSource, COUNT(*) AS c
      FROM routine_completions
      GROUP BY resultSource;
    ''');
    results.add({'title': '۵. سهم مسیرهای ثبت انجام', 'rows': q5, 'count': q5.length});

    // Query 6: Duplicate occurrences on same date
    final q6 = await db.rawQuery('''
      SELECT routine_id, date, COUNT(*) AS c
      FROM routine_occurrences
      GROUP BY routine_id, date
      HAVING c > 1;
    ''');
    results.add({'title': '۶. رخداد تکراری در یک روز', 'rows': q6, 'count': q6.length});

    setState(() {
      _queryResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('پایش سلامت داده‌ها (توسعه‌دهنده)', style: TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _runHealthAuditQueries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _queryResults.length,
              itemBuilder: (context, index) {
                final item = _queryResults[index];
                final title = item['title'] as String;
                final count = item['count'] as int;
                final rows = item['rows'] as List<Map<String, dynamic>>;

                final hasIssue = count > 0 && index != 4; // Query 5 is breakdown

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: hasIssue
                                    ? colors.error.withValues(alpha: 0.15)
                                    : colors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count مورد',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hasIssue ? colors.error : colors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (rows.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            rows.take(3).toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
