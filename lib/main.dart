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
import 'package:ritmo/core/services/account_reset_service.dart';
import 'package:ritmo/core/services/device_service.dart';
import 'package:ritmo/core/security/app_lock_gate.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/restart_widget.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_gate.dart';
import 'package:ritmo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ritmo/features/onboarding/presentation/splash_screen.dart';
import 'package:ritmo/features/today/presentation/home_navigation_shell.dart';

// Engines & Service Locator Imports
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_orchestrator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/agenda/agenda_renderer_registry.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    RitmoLog.error('FlutterError', details.exceptionAsString(), details.exception, details.stack);
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    RitmoLog.error('PlatformError', error.toString(), error, stack);
    return true;
  };

  if (!kIsWeb) {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final handle = PluginUtilities.getCallbackHandle(notificationActionDispatcher)?.toRawHandle();
        if (handle != null) {
          await prefs.setInt('notification_action_callback_handle', handle);
        }

        final todayStr = DayKey.from(DateTime.now()).value;
        final lastResetDate = prefs.getString('digest_notif_reset_date');
        if (lastResetDate != todayStr) {
          await prefs.setInt('digest_notif_count', 0);
          await prefs.setString('digest_notif_reset_date', todayStr);
        }

        final wmRegistered = prefs.getBool('wm_registered_v2') ?? false;
        if (!wmRegistered) {
          Workmanager().initialize(ritmoCallbackDispatcher);
          await Workmanager().registerPeriodicTask(
            'ritmo_periodic_reschedule',
            'ritmoRescheduleTask',
            frequency: const Duration(hours: 6),
            existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
            constraints: Constraints(networkType: NetworkType.notRequired),
            backoffPolicy: BackoffPolicy.linear,
          );
          await prefs.setBool('wm_registered_v2', true);
        }
      } catch (e, st) {
        RitmoLog.error('BackgroundInit', 'Workmanager init error', e, st);
      }
    });
  }

  ErrorWidget.builder = (details) {
    if (kDebugMode) {
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
    }

    return Material(
      color: const Color(0xff12111E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xffF43F5E), size: 48),
              const SizedBox(height: 16),
              const Text(
                'مشکلی در پردازش این بخش پیش آمد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'اطلاعات شما کاملاً محفوظ است. لطفاً برنامه را مجدداً بارگذاری کنید.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
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
  Object? _initError;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    try {
      _initError = null;
      // 1. Trigger database open
      final db = await DatabaseHelper.instance.database;

      // 2. Initialize Premium/Entitlement service
      try {
        await PremiumService.instance.init();
      } catch (e, st) {
        RitmoLog.error('Init', 'PremiumService init failed', e, st);
      }

      // 3. Register current device
      try {
        await DeviceService.instance.registerCurrentDevice();
      } catch (e, st) {
        RitmoLog.error('Init', 'Device registration failed', e, st);
      }

      // 4. Reconcile external background updates and sync occurrences
      try {
        await RitmoExecutionKernel.instance.reconcileExternalState();
      } catch (e, st) {
        RitmoLog.error('Init', 'Reconcile external state failed', e, st);
      }

      // 5. Check if onboarding is completed via OnboardingGate
      _onboardingCompleted = await OnboardingGate.isCompleted(db);
    } catch (e, st) {
      RitmoLog.error('Init', 'Critical startup error in _initialize', e, st);
      _initError = e;
      rethrow;
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
                duration: kDebugMode ? const Duration(milliseconds: 100) : const Duration(milliseconds: 650),
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
                              await AccountResetService.wipeUserData();
                              setState(() {
                                _onboardingCompleted = false;
                                _showSplash = true;
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
