import 'package:ritmo/core/domain/commands/commands_registry.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/ritmo_command_bus.dart';
import 'package:ritmo/core/domain/personas/assistant_persona.dart';

class PersonaRegistry {
  PersonaRegistry._();
  static final PersonaRegistry instance = PersonaRegistry._();

  final Map<String, AssistantPersona> _personas = {};

  void register(AssistantPersona persona) {
    // Privacy Enforcer: Only cycle & health personas read cycle/medical domains
    if (persona.reads.contains(DataDomain.cycle) && persona.id != 'cycle') {
      throw SecurityError('فقط پرسونای سیکل مجاز به خواندن DataDomain.cycle است.');
    }
    if (persona.reads.contains(DataDomain.medical) && persona.id != 'health') {
      throw SecurityError('فقط پرسونای سلامت مجاز به خواندن DataDomain.medical است.');
    }
    _personas[persona.id] = persona;
  }

  AssistantPersona? getPersona(String id) => _personas[id];

  List<AssistantPersona> get allPersonas => _personas.values.toList();

  void initStandardPersonas() {
    final allCmdIds = RitmoCommandBus.instance.registeredCommandIds;

    register(AssistantPersona(
      id: 'global',
      displayName: 'دستیار سراسری ریتمو',
      systemPromptKey: 'system_prompt_global',
      reads: {
        DataDomain.routines,
        DataDomain.goals,
        DataDomain.worship,
        DataDomain.konkur,
        DataDomain.sleep,
        DataDomain.energy,
        DataDomain.reflection,
        DataDomain.sports,
        DataDomain.courses,
      },
      commandIds: allCmdIds,
    ));

    register(AssistantPersona(
      id: 'worship',
      displayName: 'دستیار معنوی و عبادات',
      systemPromptKey: 'system_prompt_worship',
      reads: {DataDomain.worship, DataDomain.routines},
      commandIds: {'createWorshipItem', 'deleteWorshipItem', 'openPage', 'updateSetting'},
      handoffHint: 'جهت تنظیم خواب یا اهداف می‌توانید به دستیار خواب یا اهداف منتقل شوید.',
    ));

    register(AssistantPersona(
      id: 'konkur',
      displayName: 'دستیار برنامه‌ریزی کنکور',
      systemPromptKey: 'system_prompt_konkur',
      reads: {DataDomain.konkur, DataDomain.routines},
      commandIds: {'addKonkurItem', 'openPage'},
    ));

    register(AssistantPersona(
      id: 'courses',
      displayName: 'دستیار دوره‌ها و دروس',
      systemPromptKey: 'system_prompt_courses',
      reads: {DataDomain.courses, DataDomain.routines},
      commandIds: {'createCourse', 'openPage'},
    ));

    register(AssistantPersona(
      id: 'sports',
      displayName: 'مربی هوشمند ورزشی',
      systemPromptKey: 'system_prompt_sports',
      reads: {DataDomain.sports, DataDomain.energy, DataDomain.routines},
      commandIds: {'swapExercise', 'adjustWorkoutIntensity', 'changeSetProgram', 'rescheduleDay', 'openPage'},
    ));

    register(AssistantPersona(
      id: 'wellbeing',
      displayName: 'دستیار حال و تعادل',
      systemPromptKey: 'system_prompt_wellbeing',
      reads: {DataDomain.energy, DataDomain.sleep, DataDomain.reflection, DataDomain.routines},
      commandIds: {'logEnergyMood', 'logSleep', 'logReflection', 'openPage'},
    ));

    register(AssistantPersona(
      id: 'goals',
      displayName: 'دستیار اهداف و برنامه‌ها',
      systemPromptKey: 'system_prompt_goals',
      reads: {DataDomain.goals, DataDomain.routines},
      commandIds: {'createGoal', 'editGoal', 'completeGoalStep', 'openPage'},
    ));

    register(AssistantPersona(
      id: 'sleep',
      displayName: 'دستیار تنظیم خواب',
      systemPromptKey: 'system_prompt_sleep',
      reads: {DataDomain.sleep, DataDomain.energy},
      commandIds: {'logSleep', 'openPage'},
    ));

    register(AssistantPersona(
      id: 'reflection',
      displayName: 'دستیار خودارزیابی و بازتاب',
      systemPromptKey: 'system_prompt_reflection',
      reads: {DataDomain.reflection, DataDomain.energy},
      commandIds: {'logReflection', 'openPage'},
    ));

    register(AssistantPersona(
      id: 'cycle',
      displayName: 'دستیار بهداشت چرخه بدنی',
      systemPromptKey: 'system_prompt_cycle',
      reads: {DataDomain.cycle, DataDomain.energy, DataDomain.routines},
      commandIds: {'openPage', 'logEnergyMood'},
    ));

    register(AssistantPersona(
      id: 'health',
      displayName: 'دستیار هوشمند سلامت',
      systemPromptKey: 'system_prompt_health',
      reads: {DataDomain.medical, DataDomain.energy, DataDomain.routines},
      commandIds: {'openPage', 'updateSetting'},
    ));
  }
}

class SecurityError extends Error {
  SecurityError(this.message);
  final String message;

  @override
  String toString() => 'SecurityError: $message';
}
