import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class ActionFeedback {
  ActionFeedback._();

  /// Unified feedback for all agenda item actions: haptics + toast + agenda invalidation
  static void success(
    BuildContext context, {
    required String message,
    required String dateStr,
    String? undoToken,
    VoidCallback? onUndo,
  }) {
    RitmoHaptics.success();
    DayAgendaService.instance.invalidateDate(dateStr);
    if (!context.mounted) return;

    final VoidCallback? undoCallback = onUndo ??
        (undoToken != null
            ? () async {
                final outcome = await CompletionGateway.instance.undo(undoToken);
                if (!context.mounted) return;
                if (outcome.didWrite) {
                  ActionFeedback.success(
                    context,
                    message: 'ثبت با موفقیت بازگردانده شد',
                    dateStr: dateStr,
                  );
                } else {
                  ActionFeedback.failure(
                    context,
                    message: outcome.errorMessage ?? 'بازگردانی انجام نشد',
                  );
                }
              }
            : null);

    RitmoToast.show(
      context,
      message,
      onUndo: undoCallback,
    );
  }

  static void failure(BuildContext context, {required String message}) {
    RitmoHaptics.warning();
    if (!context.mounted) return;

    RitmoToast.show(
      context,
      message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xffEF4444),
    );
  }
}
