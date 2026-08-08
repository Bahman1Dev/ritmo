import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No direct raw settings reads in core features outside whitelist', () {
    final featuresDir = Directory('lib/features');
    if (!featuresDir.existsSync()) return;

    final whitelistedFiles = [
      'psych_layer_settings_sheet.dart',
      'ai_memory_management_screen.dart',
      'cycle_lock_gate.dart',
      'cycle_harmony_screen.dart',
      'cycle_reminders_screen.dart',
      'ss_settings_screen.dart',
      'step_notifications.dart',
      'ai_chat_screen.dart',
      'day_plan_validator.dart',
      'assistant_action_registry.dart',
      'goals_controller.dart',
      'health_screen.dart',
      'health_insights_page.dart',
      'records_page.dart',
      'ai_health_assistant_sheet.dart',
      'blood_sugar_section.dart',
      'doctor_visit_summary_sheet.dart',
      'pregnancy_section.dart',
      'konkur_repository.dart',
      'day_arc_inferencer.dart',
      'all_plans_screen.dart',
      'planner_controller.dart',
      'dashboard_controller.dart',
      'insights_screen.dart',
      'systems_hub_screen.dart',
      'reshuffle_preview_sheet.dart',
      'worship_repository.dart',
      'ai_worship_assistant_sheet.dart',
      'prayer_city_picker.dart',
      'prayer_times_hero.dart',
      'cycle_screen.dart',
      'cycle_onboarding_controller.dart',
    ];

    final violations = <String>[];
    for (final file in featuresDir.listSync(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        final baseName = file.uri.pathSegments.last;
        if (whitelistedFiles.contains(baseName)) continue;

        final content = file.readAsStringSync();
        if (content.contains("db.query('app_settings'") || content.contains("db.insert('app_settings'")) {
          violations.add(file.path);
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'فایل‌های زیر نباید مستقیماً به دیتابیس app_settings متصل شوند: ${violations.join(", ")}',
    );
  });
}
