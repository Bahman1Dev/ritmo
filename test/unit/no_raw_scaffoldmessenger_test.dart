import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Guard Test: Target Phase 1 files must not contain raw ScaffoldMessenger or _TopToastWidget', () {
    final targetFiles = [
      'lib/features/routines/shared/routine_actions.dart',
      'lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart',
      'lib/features/chat/presentation/ai_chat_screen.dart',
      'lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart',
      'lib/features/goals/presentation/widgets/ai_goals_assistant_sheet.dart',
      'lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart',
      'lib/features/supplementary_sports/presentation/widgets/ss_ai_coach_sheet.dart',
      'lib/features/wellbeing/presentation/widgets/ai_wellbeing_assistant_sheet.dart',
      'lib/features/today/presentation/now_dashboard_screen.dart',
      'lib/features/profile/presentation/backup_screen.dart',
      'lib/features/profile/presentation/profile_screen.dart',
      'lib/features/inbox/logic/inbox_navigator.dart',
      'lib/features/profile/presentation/crash_reports_screen.dart',
    ];

    final violations = <String>[];

    for (final relPath in targetFiles) {
      final file = File(relPath);
      if (!file.existsSync()) {
        violations.add('File not found: $relPath');
        continue;
      }

      final content = file.readAsStringSync();
      if (content.contains('ScaffoldMessenger.of(') || content.contains('ScaffoldMessenger.maybeOf(')) {
        violations.add('$relPath contains raw ScaffoldMessenger');
      }
      if (content.contains('class _TopToastWidget')) {
        violations.add('$relPath contains legacy _TopToastWidget');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Raw ScaffoldMessenger or legacy _TopToastWidget found in Phase 1 targets:\n${violations.join('\n')}',
    );
  });
}
