import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/completion/completion_gateway.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:ritmo/features/konkur/presentation/widgets/konkur_study_sheet.dart';
import 'package:ritmo/features/routines/shared/widgets/routine_niyyah_sheet.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_quick_log_sheet.dart';

/// Central action router for opening the appropriate action sheet for any AgendaItem.
class ActionRouter {
  ActionRouter._();

  static Future<void> open(BuildContext context, {required AgendaItem item}) async {
    switch (item.domain) {
      case AgendaDomain.routine:
        final routineMap = item.meta['routine'] as Map<String, dynamic>?;
        if (routineMap != null) {
          final routine = Routine.fromMap(routineMap);
          RoutineNiyyahSheet.show(
            context: context,
            routine: routine,
            onStartTimer: (selectedMode) async {},
            onCompleteInstantly: (modeStr, duration) async {
              await CompletionGateway.instance.submit(
                RoutineCompletion(
                  routineId: routine.id,
                  dateStr: item.dateStr,
                  result: CompletionResult.fromDb(modeStr),
                  durationMinutes: duration,
                ),
              );
            },
            onSnooze: () {},
            onEdit: () {},
            onViewDetails: () {},
          );
        }
        break;

      case AgendaDomain.course:
        await CompletionGateway.instance.submit(
          CourseSessionCompletion(
            sessionId: item.sourceId,
            courseId: item.meta['courseId'] as String? ?? '',
            dateStr: item.dateStr,
          ),
        );
        break;

      case AgendaDomain.konkur:
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => KonkurStudySheet(
            subjects: const [],
            topics: const [],
            onSaved: () {},
          ),
        );
        break;

      case AgendaDomain.prayer:
      case AgendaDomain.mustahab:
      case AgendaDomain.worshipDebt:
        await CompletionGateway.instance.submit(
          WorshipCompletion(
            worshipId: item.sourceId,
            dateStr: item.dateStr,
          ),
        );
        break;

      case AgendaDomain.sport:
        showSportsQuickLogSheet(context, onLogged: () {});
        break;

      case AgendaDomain.goalStep:
        await CompletionGateway.instance.submit(
          GoalStepCompletion(
            goalId: item.meta['goalId'] as String? ?? '',
            stepId: item.sourceId,
            dateStr: item.dateStr,
          ),
        );
        break;

      case AgendaDomain.medicine:
        await CompletionGateway.instance.submit(
          MedicationTake(
            medicationId: item.sourceId,
            dateStr: item.dateStr,
          ),
        );
        break;

      case AgendaDomain.cycle:
        break;
    }
  }
}
