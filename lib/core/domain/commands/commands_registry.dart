import 'package:ritmo/core/domain/commands/ritmo_command_bus.dart';
import 'package:ritmo/core/domain/commands/catalog/app_commands.dart';
import 'package:ritmo/core/domain/commands/catalog/routine_commands.dart';
import 'package:ritmo/core/domain/commands/catalog/goal_commands.dart';
import 'package:ritmo/core/domain/commands/catalog/study_commands.dart';
import 'package:ritmo/core/domain/commands/catalog/worship_commands.dart';
import 'package:ritmo/core/domain/commands/catalog/wellbeing_commands.dart';
import 'package:ritmo/core/domain/commands/catalog/sports_commands.dart';

void registerAllRitmoCommands() {
  RitmoCommandBus.instance.registerAll([
    // App & System commands
    const AppOpenPageCommand(),
    const AssistantHandoffCommand(),
    const AssistantUndoLastCommand(),

    // Routine commands
    const RoutineCreateCommand(),
    const RoutineCreateFromPhraseCommand(),
    const RoutineEditCommand(),
    const RoutineArchiveCommand(),
    const RoutineDeleteCommand(),
    const RoutineCompleteCommand(),
    const RoutineSkipCommand(),
    const RoutineSnoozeCommand(),
    const RoutineRescheduleCommand(),
    const RoutineSetReminderOffsetCommand(),
    const RoutineSetEssentialCommand(),
    const RoutineSetPrivateCommand(),
    const RoutineBulkRescheduleCommand(),

    // Goal commands
    const GoalCreateCommand(),
    const GoalEditCommand(),
    const GoalCompleteStepCommand(),

    // Study commands
    const CourseCreateCommand(),
    const KonkurCreateTopicCommand(),

    // Worship commands
    const WorshipCreateCommand(),
    const WorshipDeleteCommand(),

    // Wellbeing commands
    const SleepLogCommand(),
    const EnergyLogCommand(),
    const ReflectionLogCommand(),
    const SettingUpdateCommand(),

    // Sports & Movement commands
    const SportsMarkDoneCommand(),
    const SportsSkipSessionCommand(),
    const SportsMoveSessionCommand(),
  ]);
}
