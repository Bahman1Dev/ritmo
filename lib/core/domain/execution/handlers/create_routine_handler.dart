import 'dart:convert';

import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models/duration_variants.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/execution/command_context.dart';
import 'package:ritmo/core/domain/execution/command_handler.dart';
import 'package:ritmo/core/domain/execution/events/kernel_event_factory.dart';
import 'package:ritmo/core/domain/execution/kernel_mutation_result.dart';
import 'package:ritmo/core/domain/models.dart';

class CreateRoutineHandler
    implements KernelCommandHandler<CreateRoutineCommand> {
  const CreateRoutineHandler();

  @override
  Future<KernelMutationResult> handle(
    CommandContext context,
    CreateRoutineCommand command,
  ) async {
    final routineMap = Map<String, dynamic>.from(command.routineData);
    final mode = routineMap['progressionMode'] as String? ?? 'NONE';
    final start = routineMap['progressionStart'] as int? ?? 0;

    if (mode != 'NONE' &&
        (routineMap['progressionCurrent'] == null ||
            routineMap['progressionCurrent'] == 0)) {
      routineMap['progressionCurrent'] = start;
    }

    final target = routineMap['targetDurationMinutes'] as int? ?? 0;
    final category = routineMap['category'] as String?;
    if (DurationVariants.supportsVariants(target) && category != 'medical') {
      final light = routineMap['lightDurationMinutes'] as int? ?? 0;
      final minimal = routineMap['minimalDurationMinutes'] as int? ?? 0;
      if (light <= 0) {
        routineMap['lightDurationMinutes'] = DurationVariants.light(target);
      }
      if (minimal <= 0) {
        routineMap['minimalDurationMinutes'] = DurationVariants.minimal(target);
      }
    }

    await context.txn.insert('routines', routineMap);
    if (command.scheduleData != null) {
      await context.txn.insert('routine_schedules', command.scheduleData!);

      final ruleMap =
          jsonDecode(command.scheduleData!['recurrenceRule'] as String? ?? '{}');
      final rule = RecurrenceRule.fromMap(ruleMap);

      await RoutineOccurrenceGenerator.generateFutureOccurrences(
        context.txn,
        routineMap['id'] as String,
        rule,
      );
    }

    return KernelMutationResult(
      domainEvents: [
        KernelEventFactory.routineCreated(
          now: context.now,
          routineId: routineMap['id'] as String?,
        ),
      ],
    );
  }
}
