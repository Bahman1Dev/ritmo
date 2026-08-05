// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:ritmo/core/analytics/assistant_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/core/analytics/health_engine.dart';
import 'package:ritmo/core/analytics/insight_generation_engine.dart';
import 'package:ritmo/core/analytics/konkur_engine.dart';
// Analytical engines
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/analytics/milestone_engine.dart';
import 'package:ritmo/core/analytics/mood_engine.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';
import 'package:ritmo/core/analytics/sleep_engine.dart';
import 'package:ritmo/core/behavior/behavioral_intelligence_orchestrator.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/commands/commands_registry.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/medical_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_orchestrator.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
// Platform Interfaces
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/platform/backup_platform.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/device_service.dart';
import 'package:ritmo/core/services/google_drive_backup_service.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
// Feature Repositories
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_session_repository.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_session_repository_impl.dart';

final sl = GetIt.instance;

class AppBootstrapper {
  AppBootstrapper._();

  /// Standalone initializer that registers all core singletons.
  /// Decoupled from WidgetsFlutterBinding and runApp for isolate compatibility.
  static Future<void> init() async {
    if (sl.isRegistered<RitmoEventBus>()) {
      return; // Already initialized (e.g. by another isolate or double call)
    }

    // 1. Initialize Event Bus and Engine Bus
    registerAllRitmoCommands();
    final eventBus = RitmoEventBus();
    sl.registerSingleton<RitmoEventBus>(eventBus);

    final registry = EngineRegistry()
      ..register(LifeBalanceEngine())
      ..register(EnergyAnalyticsEngine())
      ..register(MilestoneEngine())
      ..register(InsightGenerationEngine())
      ..register(MedicineEngine())
      ..register(CycleEngine())
      ..register(KonkurEngine())
      ..register(GoalsEngine())
      ..register(SleepEngine())
      ..register(MoodEngine())
      ..register(AssistantEngine())
      ..register(ReflectionEngine())
      ..register(HealthEngine())
      ..register(BehavioralIntelligenceOrchestrator());

    sl.registerSingleton<EngineRegistry>(registry);

    RitmoEngineBus.init(registry);
    sl.registerSingleton<RitmoEngineBus>(RitmoEngineBus.instance);

    // 2. Keep orchestrator instance alive to listen to events
    final orchestrator = RitmoIntelligenceOrchestrator(
      engineBus: RitmoEngineBus.instance,
      eventBus: eventBus,
    );
    sl.registerSingleton<RitmoIntelligenceOrchestrator>(orchestrator);

    // 3. Register Core Services and Singletons
    sl.registerSingleton<DayAgendaService>(DayAgendaService.instance);
    sl.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);
    sl.registerSingleton<PremiumService>(PremiumService.instance);
    sl.registerSingleton<DeviceService>(DeviceService.instance);
    // 4. Register Feature Repositories
    sl.registerSingleton<CoursesRepository>(CoursesRepository.instance);
    sl.registerSingleton<GoalsRepository>(GoalsRepository.instance);
    sl.registerSingleton<KonkurRepository>(KonkurRepository.instance);
    sl.registerSingleton<SSSessionRepository>(SSSessionRepositoryImpl());

    // 5. Register Repositories requiring async initialization
    final themeRepository = ThemeRepository();
    sl.registerSingleton<ThemeRepository>(themeRepository);

    final localeRepository = LocaleRepository();
    sl.registerSingleton<LocaleRepository>(localeRepository);

    // 6. Register Platform Implementations
    sl.registerSingleton<AlarmPlatform>(const MethodChannelAlarmPlatform());
    sl.registerSingleton<NotificationPlatform>(const MethodChannelNotificationPlatform());
    sl.registerSingleton<BackupPlatform>(GoogleDriveBackupService.instance);
  }
}
