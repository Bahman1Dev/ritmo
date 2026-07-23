import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmo/core/services/notification_action_dispatcher.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ritmo/core/services/background_worker.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/database/seed/mock_data_seeder.dart';
import 'package:ritmo/core/services/device_service.dart';
import 'package:ritmo/core/security/app_lock_gate.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/restart_widget.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:ritmo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ritmo/features/onboarding/presentation/splash_screen.dart';
import 'package:ritmo/features/today/presentation/home_navigation_shell.dart';

// Engines & Service Locator Imports
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_orchestrator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/agenda/agenda_renderer_registry.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    final handle = PluginUtilities.getCallbackHandle(notificationActionDispatcher)!.toRawHandle();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_action_callback_handle', handle);
    await prefs.setInt('digest_notif_count', 0);

    Workmanager().initialize(ritmoCallbackDispatcher);
    Workmanager().registerPeriodicTask(
      'ritmo_periodic_reschedule',
      'ritmoRescheduleTask',
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.notRequired),
      backoffPolicy: BackoffPolicy.linear,
    );
  }

  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xff121212),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error details:',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              SelectableText(
                details.exception.toString(),
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stack Trace:',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SelectableText(
                details.stack.toString(),
                style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 1. Initialize service locator
  await AppBootstrapper.init();

  // Register Agenda Renderers
  AgendaRendererRegistry.register(AgendaDomain.prayer, const PrayerAgendaRenderer());
  
  // 2. Initialize database and repository before runApp to avoid dark/light flashing on startup
  final themeRepository = sl<ThemeRepository>();
  await themeRepository.init();
  
  final localeRepository = sl<LocaleRepository>();
  await localeRepository.init();
  
  runApp(RestartWidget(
    child: ProviderScope(
      child: RitmoApp(
        themeRepository: themeRepository,
        localeRepository: localeRepository,
        orchestrator: sl<RitmoIntelligenceOrchestrator>(),
      ),
    ),
  ));
}

class RitmoApp extends StatefulWidget {
  const RitmoApp({
    super.key,
    required this.themeRepository,
    required this.localeRepository,
    required this.orchestrator,
  });
  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;
  final RitmoIntelligenceOrchestrator orchestrator;

  @override
  State<RitmoApp> createState() => _RitmoAppState();
}

class _RitmoAppState extends State<RitmoApp> {
  bool _showSplash = true;
  bool _onboardingCompleted = false;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    // 1. Trigger database open and seed check
    final db = await DatabaseHelper.instance.database;

    // Purge legacy mock/test data once to ensure a clean user environment
    final mockCleared = await db.query('app_settings', where: "key = 'mock_data_purged_v1'");
    if (mockCleared.isEmpty) {
      try {
        debugPrint('[MockSeeder] 🧹 Purging all legacy mock data...');
        await MockDataSeeder.clearMockData(db);
        await db.insert('app_settings', {
          'key': 'mock_data_purged_v1',
          'value': 'true',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        debugPrint('[MockSeeder] ✨ Legacy test data purged successfully.');
      } catch (e, st) {
        debugPrint('[MockSeeder] ❌ Error purging mock data: $e\n$st');
      }
    }

    // Initialize Premium/Entitlement service
    await PremiumService.instance.init();

    // Register current device
    await DeviceService.instance.registerCurrentDevice();

    // 2. Reconcile external background updates and sync occurrences
    await RitmoExecutionKernel.instance.reconcileExternalState();

    // 3. Check if onboarding is completed by reading the home_city_id flag
    final settings = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['home_city_id'],
    );

    if (settings.isNotEmpty) {
      final routines = await db.query('routines');
      _onboardingCompleted = routines.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.themeRepository.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: widget.localeRepository.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Ritmo',
              theme: RitmoTheme.lightTheme,
              darkTheme: RitmoTheme.darkTheme,
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: const [
                PersianMaterialLocalizations.delegate,
                PersianCupertinoLocalizations.delegate,
                ...AppLocalizations.localizationsDelegates,
              ],
              supportedLocales: const [
                Locale('fa', 'IR'),
                Locale('en', 'US'),
              ],
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
                    statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
                    systemNavigationBarColor: isDarkMode ? const Color(0xff08090C) : const Color(0xffF2F5FA),
                    systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
                  ),
                );
                return AppLockGate(child: child!);
              },
              home: AnimatedSwitcher(
                duration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _showSplash
                    ? SplashScreen(
                        key: const ValueKey('splash'),
                        initializationFuture: _initializationFuture,
                        onInitializationComplete: () {
                          setState(() {
                            _showSplash = false;
                          });
                        },
                      )
                    : (_onboardingCompleted
                        ? HomeNavigationShell(
                            key: const ValueKey('home'),
                            themeRepository: widget.themeRepository,
                            localeRepository: widget.localeRepository,
                            onLogout: () async {
                              // For test/dev purposes, allow resetting the database
                              final db = await DatabaseHelper.instance.database;
                              await db.delete('routines');
                              await db.delete('routine_schedules');
                              await db.delete('routine_completions');
                              setState(() {
                                _onboardingCompleted = false;
                                _showSplash = true;
                                // Re-initialize after database reset
                                _initializationFuture = _initialize();
                              });
                            },
                          )
                        : OnboardingScreen(
                            key: const ValueKey('onboarding'),
                            onFinished: () {
                              setState(() {
                                _onboardingCompleted = true;
                              });
                            },
                          )),
              ),
            );
          },
        );
      },
    );
  }
}
