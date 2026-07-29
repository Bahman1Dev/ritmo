import 'package:ritmo/core/domain/completion/completion_outcome.dart';

/// Sealed hierarchy representing handoff intents from action sheets.
sealed class HandoffIntent {
  const HandoffIntent();
}

/// Intent to start focus timer with selected mode and target duration in minutes.
final class StartTimerHandoff extends HandoffIntent {
  final String mode;
  final int durationMinutes;

  const StartTimerHandoff({
    required this.mode,
    required this.durationMinutes,
  });
}

/// Intent to open the routine / item editor.
final class OpenEditorHandoff extends HandoffIntent {
  const OpenEditorHandoff();
}

/// Intent to open item details screen.
final class OpenDetailsHandoff extends HandoffIntent {
  const OpenDetailsHandoff();
}

/// Intent to open custom snooze picker sheet.
final class OpenSnoozePickerHandoff extends HandoffIntent {
  const OpenSnoozePickerHandoff();
}

/// Intent to open max snooze cap exceeded exit options.
final class OpenSnoozeCapExceededHandoff extends HandoffIntent {
  const OpenSnoozeCapExceededHandoff();
}

/// Sealed result returned when closing an ActionSheet.
sealed class ActionSheetResult {
  const ActionSheetResult();
}

/// Returned when writing was successfully executed inside the sheet.
final class ActionSheetSubmitted extends ActionSheetResult {
  final CompletionOutcome outcome;

  const ActionSheetSubmitted(this.outcome);
}

/// Returned when the user requested an action that must be handled outside.
final class ActionSheetHandoff extends ActionSheetResult {
  final HandoffIntent intent;

  const ActionSheetHandoff(this.intent);
}
