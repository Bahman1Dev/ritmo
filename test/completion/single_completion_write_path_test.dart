import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Single Completion Write Path Guard Test (K-10)', () {
    final allowedWritingFiles = <String>{
      'complete_occurrence_handler.dart',
      'skip_occurrence_handler.dart',
      'reschedule_occurrence_handler.dart',
      'delete_routine_handler.dart',
      'archive_routine_handler.dart',
      'edit_routine_handler.dart',
      'snooze_reminder_handler.dart',
      'routine_occurrence_generator.dart',
      'migrations_registry.dart',
      'routine_tables.dart',
      'mock_data_seeder.dart',
      'alarm_scheduler_service.dart',
      'day_agenda_service.dart',
      'routine_agenda_source.dart',
      'insight_generation_engine.dart',
      'behavioral_intelligence_orchestrator.dart',
      'rhythm_snapshot_service.dart',
      'today_snapshot_context_builder.dart',
      'conversation_rag.dart',
      'context_resolver.dart',
      'module_management_service.dart',
      'end_of_day_sweep.dart',
      'daily_digest_builder.dart',
    };

    final writePattern = RegExp(r'''(insert|update|delete|rawInsert|rawUpdate|rawDelete)\s*\(\s*['"](routine_completions|routine_occurrences)['"]''');

    test('no UI layer file performs direct SQL writes on completion tables', () {
      final uiFiles = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final violations = <String>[];

      for (final file in uiFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (writePattern.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      expect(
        violations.isEmpty,
        isTrue,
        reason: 'Single Write Path Violation! UI files must NEVER perform direct SQL writes to routine_completions or routine_occurrences.\nViolations:\n${violations.join('\n')}',
      );
    });
  });
}
