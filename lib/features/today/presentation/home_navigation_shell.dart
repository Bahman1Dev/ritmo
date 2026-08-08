import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ritmo/core/app_mode/app_mode_service.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_glass_surface.dart';
import 'package:ritmo/features/assistant/presentation/assistant_screen.dart';
import 'package:ritmo/features/calendar/presentation/calendar_screen.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/simple_tasks/presentation/simple_tasks_screen.dart';
import 'package:ritmo/features/today/presentation/insights_screen.dart';
import 'package:ritmo/features/today/presentation/now_dashboard_screen.dart';
import 'package:ritmo/features/today/presentation/systems_hub_screen.dart';

class HomeNavigationShell extends StatefulWidget {
  const HomeNavigationShell({
    super.key,
    required this.onLogout,
    required this.themeRepository,
    required this.localeRepository,
  });
  final VoidCallback onLogout;
  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;

  @override
  State<HomeNavigationShell> createState() => _HomeNavigationShellState();
}

class _HomeNavigationShellState extends State<HomeNavigationShell> {
  late AppMode _activeMode;
  late int _currentIndex;
  late List<Widget?> _screens;
  StreamSubscription<RitmoEvent>? _eventSubscription;
  DateTime? _lastBackPressTime;
  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0;
  bool _focusTasksAddField = false;

  @override
  void initState() {
    super.initState();
    _activeMode = AppModeService.instance.current;
    _currentIndex = _activeMode == AppMode.simple ? 0 : 2;
    _screens = List.filled(_activeMode == AppMode.simple ? 3 : 5, null);
    _screens[_currentIndex] = _buildScreen(_currentIndex, _activeMode);

    _eventSubscription = RitmoEventBus().onEvents.listen((event) {
      if (event.type == 'navigate_tab') {
        final index = event.payload['index'] as int?;
        final maxTabs = _activeMode == AppMode.simple ? 3 : 5;
        if (index != null && index >= 0 && index < maxTabs) {
          setState(() {
            _currentIndex = index;
            _screens[index] ??= _buildScreen(index, _activeMode);
          });
        }
      } else if (event.type == 'app_mode_changed') {
        _handleModeChange(AppModeService.instance.current);
      }
    });

    _requestNotificationPermissionIfNeeded();
  }

  void _handleModeChange(AppMode newMode) {
    if (_activeMode == newMode) return;
    setState(() {
      _activeMode = newMode;
      _currentIndex = newMode == AppMode.simple ? 0 : 2;
      _screens = List.filled(newMode == AppMode.simple ? 3 : 5, null);
      _screens[_currentIndex] = _buildScreen(_currentIndex, newMode);
    });
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: "key = 'notif_permission_asked'",
        limit: 1,
      );

      if (rows.isNotEmpty && rows.first['value'] == 'true') {
        return;
      }

      final plugin = FlutterLocalNotificationsPlugin();
      final androidImplementation = plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        if (granted == false) {
          await androidImplementation.requestNotificationsPermission();
        }
      }
    } catch (e) {
      debugPrint('Error requesting notifications permission at shell startup: $e');
    }
  }

  Widget _buildScreen(int index, AppMode mode) {
    if (mode == AppMode.simple) {
      switch (index) {
        case 0:
          return SimpleTasksScreen(focusAddField: _focusTasksAddField);
        case 1:
          return const CalendarScreen();
        case 2:
          return SystemsHubScreen(
            onLogout: widget.onLogout,
            themeRepository: widget.themeRepository,
            localeRepository: widget.localeRepository,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (index) {
        case 0:
          return SystemsHubScreen(
            onLogout: widget.onLogout,
            themeRepository: widget.themeRepository,
            localeRepository: widget.localeRepository,
          );
        case 1:
          return const InsightsScreen();
        case 2:
          return NowDashboardScreen(
            onLogout: widget.onLogout,
            themeRepository: widget.themeRepository,
            localeRepository: widget.localeRepository,
            onNavigateToTab: (idx) {
              final maxTabs = _screens.length;
              if (idx >= 0 && idx < maxTabs) {
                setState(() {
                  _currentIndex = idx;
                  _screens[idx] ??= _buildScreen(idx, mode);
                });
              }
            },
          );
        case 3:
          return const AssistantScreen(isTab: true);
        case 4:
          return const CalendarScreen();
        default:
          return const SizedBox.shrink();
      }
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _refreshCurrentScreen() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppMode>(
      valueListenable: AppModeService.instance.notifier,
      builder: (context, currentMode, _) {
        if (_activeMode != currentMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleModeChange(currentMode);
          });
        }

        final defaultTab = currentMode == AppMode.simple ? 0 : 2;
        final maxTabs = currentMode == AppMode.simple ? 3 : 5;

        // Prevent out-of-bounds index
        if (_currentIndex >= maxTabs) {
          _currentIndex = defaultTab;
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (_currentIndex != defaultTab) {
              setState(() {
                _currentIndex = defaultTab;
                _screens[defaultTab] ??= _buildScreen(defaultTab, currentMode);
              });
              return;
            }

            final now = DateTime.now();
            if (_lastBackPressTime == null ||
                now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
              _lastBackPressTime = now;
              RitmoToast.show(
                context,
                'برای خروج، دوباره دکمه برگشت را بزنید',
                icon: Icons.exit_to_app_rounded,
                iconColor: const Color(0xffF59E0B),
              );
            } else {
              await SystemNavigator.pop();
            }
          },
          child: Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                // Background Gradient
                Positioned.fill(
                  child: RitmoTheme.buildBackgroundContainer(
                    context: context,
                    child: const SizedBox.expand(),
                  ),
                ),

                // Current Screen View
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          final currentOffset = notification.metrics.pixels;
                          final delta = currentOffset - _lastScrollOffset;

                          if (delta > 10 && _isNavBarVisible && currentOffset > 50) {
                            setState(() {
                              _isNavBarVisible = false;
                            });
                          } else if (delta < -10 && !_isNavBarVisible) {
                            setState(() {
                              _isNavBarVisible = true;
                            });
                          }

                          _lastScrollOffset = currentOffset;
                        }
                        return false;
                      },
                      child: IndexedStack(
                        index: _currentIndex < maxTabs ? _currentIndex : defaultTab,
                        children: List.generate(maxTabs, (index) {
                          return _screens[index] ?? const SizedBox.shrink();
                        }),
                      ),
                    ),
                  ),
                ),

                // Bottom Navigation Bar
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                    child: AnimatedSlide(
                      offset: _isNavBarVisible ? Offset.zero : const Offset(0, 2),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: _isNavBarVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: currentMode == AppMode.simple
                                  ? _buildSimpleBottomBar()
                                  : _buildFullBottomBar(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 3-Tab Bottom Bar for Simple Mode
  Widget _buildSimpleBottomBar() {
    return RitmoGlassSurface(
      blurSigma: 24,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      borderRadius: BorderRadius.circular(RitmoRadius.sheet),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Tasks
            _buildNavItem(0, CupertinoIcons.check_mark_circled_solid, CupertinoIcons.check_mark_circled, 'کارها'),

            // Dynamic Center Button: Plus/Focus
            _buildSimpleCenterButton(),

            // Tab 1: Calendar
            _buildNavItem(1, CupertinoIcons.calendar_circle_fill, CupertinoIcons.calendar, 'تقویم'),

            // Tab 2: More / Systems
            _buildNavItem(2, CupertinoIcons.square_grid_2x2_fill, CupertinoIcons.square_grid_2x2, 'بیشتر'),
          ],
        ),
      ),
    );
  }

  /// 5-Tab Bottom Bar for Full Mode
  Widget _buildFullBottomBar() {
    return RitmoGlassSurface(
      blurSigma: 24,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      borderRadius: BorderRadius.circular(RitmoRadius.sheet),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(4, CupertinoIcons.calendar_circle_fill, CupertinoIcons.calendar, 'تقویم'),
            _buildNavItem(3, CupertinoIcons.sparkles, CupertinoIcons.sparkles, 'دستیار'),
            _buildFullCenterButton(),
            _buildNavItem(0, CupertinoIcons.square_grid_2x2_fill, CupertinoIcons.square_grid_2x2, 'سیستم‌ها'),
            _buildNavItem(1, CupertinoIcons.lightbulb_fill, CupertinoIcons.lightbulb, 'بینش‌ها'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final colors = context.colors;

    final activeColor = colors.primary;
    final inactiveColor = colors.textSecondary;

    return GestureDetector(
      onTap: () {
        RitmoHapticsPolicy.selection();
        setState(() {
          _currentIndex = index;
          _screens[index] ??= _buildScreen(index, _activeMode);
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCenterButton() {
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        RitmoHapticsPolicy.tap();
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _focusTasksAddField = true;
            _screens[0] = _buildScreen(0, AppMode.simple);
          });
        } else {
          // Re-trigger focus on Tasks add field
          setState(() {
            _focusTasksAddField = true;
            _screens[0] = _buildScreen(0, AppMode.simple);
          });
        }
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.brandGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildFullCenterButton() {
    final isHomeActive = _currentIndex == 2;
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        RitmoHapticsPolicy.tap();
        if (isHomeActive) {
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierDismissible: true,
              pageBuilder: (context, _, _) => UniversalPlannerSheet(
                onSaved: _refreshCurrentScreen,
              ),
            ),
          );
        } else {
          setState(() {
            _currentIndex = 2;
            _screens[2] ??= _buildScreen(2, AppMode.full);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.brandGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: isHomeActive
              ? const Icon(
                  CupertinoIcons.add,
                  key: ValueKey('plus_icon'),
                  color: Colors.white,
                  size: 24,
                )
              : const Icon(
                  CupertinoIcons.house_fill,
                  key: ValueKey('home_icon'),
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }
}
