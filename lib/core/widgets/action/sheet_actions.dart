import 'package:flutter/widgets.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';
import 'package:ritmo/core/widgets/action/action_sheet_result.dart';

/// An action executed inside the action sheet (e.g. submit completion, skip, undo).
///
/// NOTE: Submissions and cancellations MUST execute inside the sheet so that any database write
/// failure can be captured and displayed directly inside the sheet UI without closing prematurely.
class SubmitAction {
  final String id;
  final String label;
  final IconData? icon;
  final Future<CompletionOutcome> Function() onSubmit;
  final String? confirmationPrompt;
  final bool isDestructive;

  const SubmitAction({
    required this.id,
    required this.label,
    this.icon,
    required this.onSubmit,
    this.confirmationPrompt,
    this.isDestructive = false,
  });
}

/// An action that delegates navigation or full-screen features outside the sheet (e.g., timer, editor).
///
/// NOTE: Timer and full editor views must navigate outside because they control full screen overlays
/// and primary app navigation state.
class HandoffAction {
  final String id;
  final String label;
  final IconData? icon;
  final HandoffIntent intent;

  const HandoffAction({
    required this.id,
    required this.label,
    this.icon,
    required this.intent,
  });
}
