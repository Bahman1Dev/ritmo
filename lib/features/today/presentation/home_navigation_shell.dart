import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/features/assistant/presentation/assistant_screen.dart';
import 'package:ritmo/features/calendar/presentation/calendar_screen.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
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
  int _currentIndex = 2; // Default starting tab: Home Dashboard (index 2)
  final List<Widget?> _screens = List.filled(5, null);
  StreamSubscription<RitmoEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _screens[_currentIndex] = _buildScreen(_currentIndex);

    _eventSubscription = RitmoEventBus().onEvents.listen((event) {
      if (event.type == 'navigate_tab') {
        final index = event.payload['index'] as int?;
        if (index != null && index >= 0 && index < 5) {
          setState(() {
            _currentIndex = index;
            _screens[index] ??= _buildScreen(index);
          });
        }
      }
    });

    _requestNotificationPermissionIfNeeded();
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

  Widget _buildScreen(int index) {
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
          onNavigateToTab: (index) {
            setState(() {
              _currentIndex = index;
              _screens[index] ??= _buildScreen(index);
            });
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

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _refreshCurrentScreen() {
    setState(() {});
  }

  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background Gradient (Theme-Aware)
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
                    final metrics = notification.metrics;
                    if (metrics.axis == Axis.vertical) {
                      final current = metrics.pixels;
                      final delta = current - _lastScrollOffset;

                      if (metrics.pixels <= 0) {
                        if (!_isNavBarVisible) {
                          setState(() => _isNavBarVisible = true);
                        }
                      } else if (delta > 8 && _isNavBarVisible) {
                        setState(() => _isNavBarVisible = false);
                      } else if (delta < -8 && !_isNavBarVisible) {
                        setState(() => _isNavBarVisible = true);
                      }
                      _lastScrollOffset = current;
                    }
                  }
                  return false;
                },
                child: IndexedStack(
                  index: _currentIndex,
                  children: List.generate(5, (index) => _screens[index] ?? const SizedBox.shrink()),
                ),
              ),
            ),
          ),

          // Redesigned Glassmorphic Premium Floating Dock (Centered & Compact)
          // Hide when the keyboard is open or when scrolling down
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
                        child: _buildCustomBottomBar(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return RitmoTheme.glassCardLight(
      blurSigma: 24,
      color: isDarkMode
          ? const Color(0xff12141C).withValues(alpha: 0.75)
          : Colors.white.withValues(alpha: 0.8),
      border: Border.all(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.6),
        width: 1.2,
      ),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Directionality(
          textDirection: TextDirection.rtl, // RTL tab layout
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Calendar (Rightmost)
              _buildNavItem(4, CupertinoIcons.calendar_circle_fill, CupertinoIcons.calendar, 'تقویم'),
              
              // 2. Assistant
              _buildNavItem(3, CupertinoIcons.sparkles, CupertinoIcons.sparkles, 'دستیار'),
              
              // 3. Dynamic Center Home/Plus Button
              _buildDynamicCenterButton(),
              
              // 4. Systems (Swapped)
              _buildNavItem(0, CupertinoIcons.square_grid_2x2_fill, CupertinoIcons.square_grid_2x2, 'سیستم‌ها'),
              
              // 5. Reports / Insights (Swapped to Leftmost)
              _buildNavItem(1, CupertinoIcons.lightbulb_fill, CupertinoIcons.lightbulb, 'بینش‌ها'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final activeColor = isDarkMode ? const Color(0xff5B8AF5) : const Color(0xff3B6FE0);
    final inactiveColor = isDarkMode ? const Color(0xff8E95A5) : const Color(0xff6C7281);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          _screens[index] ??= _buildScreen(index);
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
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCenterButton() {
    final isHomeActive = _currentIndex == 2;
    
    return GestureDetector(
      onTap: () {
        if (isHomeActive) {
          // Trigger quick add screen when already home
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
          // Navigate back to home dashboard when elsewhere
          setState(() {
            _currentIndex = 2;
            _screens[2] ??= _buildScreen(2);
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff5B8AF5),
              Color(0xff9B89FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff5B8AF5).withValues(alpha: 0.3),
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




