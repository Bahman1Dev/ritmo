import 'dart:async';
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
import 'package:ritmo/core/database/seed/seed_service.dart';
import 'package:ritmo/core/services/account_reset_service.dart';
import 'package:ritmo/core/security/app_lock_gate.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_preferences.dart';
import 'package:ritmo/core/widgets/restart_widget.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_gate.dart';
import 'package:ritmo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ritmo/features/onboarding/presentation/splash_screen.dart';
import 'package:ritmo/features/today/presentation/home_navigation_shell.dart';

// Engines & Service Locator Imports
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_orchestrator.dart';
import 'package:ritmo/core/domain/agenda/agenda_renderer_registry.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';

import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';

import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/app_mode/app_mode_service.dart';
import 'package:ritmo/core/observability/privacy_error_sink.dart';
import 'package:ritmo/core/observability/ritmo_friendly_error_pane.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RitmoLog.addSink(PrivacyErrorSink.instance);
  await PrivacyErrorSink.instance.init();

  FlutterError.onError = (details) {
    RitmoLog.error('FlutterError', details.exceptionAsString(), details.exception, details.stack);
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    RitmoLog.error('PlatformError', error.toString(), error, stack);
    return kReleaseMode;
  };

  if (!kIsWeb) {
    unawaited(Future.microtask(() async {
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
          unawaited(Workmanager().initialize(ritmoCallbackDispatcher));
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
    }));
  }

  ErrorWidget.builder = (details) {
    return RitmoFriendlyErrorPane(details: details);
  };

  // 1. Initialize service locator & settings cache
  await AppBootstrapper.init();
  await SettingsService.instance.init();

  // Register Agenda Renderers
  AgendaRendererRegistry.register(AgendaDomain.prayer, const PrayerAgendaRenderer());

  // 2. Initialize database and repository before runApp to avoid dark/light flashing on startup
  final themeRepository = sl<ThemeRepository>();
  await themeRepository.init();

  final localeRepository = sl<LocaleRepository>();
  await localeRepository.init();

  await AppModeService.instance.load();

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
    try {
      final db = await DatabaseHelper.instance.database;
      
      // 1. Seed initial data
      await SeedService.seedAll(db);

      // 2. Check if onboarding is completed via OnboardingGate
      _onboardingCompleted = await OnboardingGate.isCompleted(db);
    } catch (e, st) {
      RitmoLog.error('Init', 'Critical startup error in _initialize', e, st);
      rethrow;
    }
  }

  void _applySystemOverlay(RitmoColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: brightness,
        systemNavigationBarColor: colors.systemNavBar,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemePreferences>(
      valueListenable: widget.themeRepository.preferencesNotifier,
      builder: (context, prefs, _) {
        final palette = RitmoPalette.byId(prefs.paletteId);
        return ValueListenableBuilder<Locale>(
          valueListenable: widget.localeRepository.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Ritmo',
              themeMode: prefs.mode,
              theme: RitmoTheme.build(
                palette: palette,
                brightness: Brightness.light,
                reduceTransparency: prefs.reduceTransparency,
              ),
              darkTheme: RitmoTheme.build(
                palette: palette,
                brightness: Brightness.dark,
                reduceTransparency: prefs.reduceTransparency,
                trueBlack: prefs.trueBlack,
              ),
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
                final brightness = Theme.of(context).brightness;
                final colors = Theme.of(context).extension<RitmoColors>() ?? palette.forBrightness(brightness);
                _applySystemOverlay(colors, brightness);
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
