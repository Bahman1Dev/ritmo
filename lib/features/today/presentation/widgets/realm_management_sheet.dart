import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/realm/active_realm_resolver.dart';
import 'package:ritmo/core/repositories/realm_repository.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/today/presentation/widgets/realm_day_bar_widget.dart';
import 'package:ritmo/features/today/presentation/widgets/realm_edit_form_sheet.dart';

class RealmManagementSheet extends StatefulWidget {
  const RealmManagementSheet({
    super.key,
    required this.isDarkMode,
    this.onChanged,
  });

  final bool isDarkMode;
  final VoidCallback? onChanged;

  @override
  State<RealmManagementSheet> createState() => _RealmManagementSheetState();
}

class _RealmManagementSheetState extends State<RealmManagementSheet> {
  final RealmRepository _repository = RealmRepository();

  bool _isLoading = true;
  List<RealmData> _realms = [];
  List<RealmScheduleData> _schedules = [];
  Map<String, int> _routineCounts = {};
  ActiveRealmState _activeState = const FreeRealmState();

  int _selectedWeekday = DateTime.now().weekday; // Default to today's weekday
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startMinuteTimer();
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    super.dispose();
  }

  void _startMinuteTimer() {
    _minuteTimer?.cancel();
    // Update active state once per minute instead of once per second (Performance §6)
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _resolveActiveState();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final realms = await _repository.loadRealms();
      final schedules = await _repository.loadSchedules();
      final routineCounts = await _repository.loadRoutineCountsPerRealm();

      if (mounted) {
        setState(() {
          _realms = realms;
          _schedules = schedules;
          _routineCounts = routineCounts;
          _isLoading = false;
        });
        await _resolveActiveState();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveActiveState() async {
    final state = await _repository.getActiveRealmState();
    if (mounted) {
      setState(() {
        _activeState = state;
      });
      if (widget.onChanged != null) {
        widget.onChanged!();
      }
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RealmEditFormSheet(
        onSave: (realm, schedules) async {
          await _repository.saveRealm(realm, schedules);
          await _loadData();
        },
      ),
    );
  }

  void _openEditSheet(RealmData realm) {
    final realmSchedules = _schedules.where((s) => s.zoneId == realm.id).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RealmEditFormSheet(
        initialRealm: realm,
        initialSchedules: realmSchedules,
        onSave: (savedRealm, savedSchedules) async {
          await _repository.saveRealm(savedRealm, savedSchedules);
          await _loadData();
        },
      ),
    );
  }

  void _openManualActivationSheet(RealmData realm) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فعال‌سازی دستی قلمرو «${realm.name}»',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 4),
                Text(
                  'مدت زمان فعال ماندن قلمرو را انتخاب کنید:',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(CupertinoIcons.timer, color: Color(0xFF6366F1)),
                  title: const Text('۲۵ دقیقه (کار تمرکزی کوتاه)', style: TextStyle(fontSize: 14, fontFamily: 'Vazirmatn')),
                  onTap: () => _activateManualOverride(realm.id, 25),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.timer, color: Color(0xFF8B5CF6)),
                  title: const Text('۵۰ دقیقه (یک پومودورو کامل)', style: TextStyle(fontSize: 14, fontFamily: 'Vazirmatn')),
                  onTap: () => _activateManualOverride(realm.id, 50),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.timer, color: Color(0xFFEC4899)),
                  title: const Text('۹۰ دقیقه (جلسه عمیق)', style: TextStyle(fontSize: 14, fontFamily: 'Vazirmatn')),
                  onTap: () => _activateManualOverride(realm.id, 90),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.moon_stars_fill, color: Color(0xFFFFD700)),
                  title: const Text('تا پایان امروز', style: TextStyle(fontSize: 14, fontFamily: 'Vazirmatn')),
                  onTap: () {
                    final now = DateTime.now();
                    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    final diffMin = endOfDay.difference(now).inMinutes;
                    _activateManualOverride(realm.id, diffMin > 0 ? diffMin : 60);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _activateManualOverride(String realmId, int minutes) async {
    Navigator.pop(context);
    await _repository.setManualOverride(realmId: realmId, durationMinutes: minutes);
    await _resolveActiveState();
  }

  void _clearManualOverride() async {
    await _repository.clearManualOverride();
    await _resolveActiveState();
  }

  void _confirmDeleteRealm(RealmData realm) async {
    final connectedCount = _routineCounts[realm.id] ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('حذف قلمرو «${realm.name}»', style: const TextStyle(fontFamily: 'Vazirmatn')),
            content: Text(
              connectedCount > 0
                  ? 'با حذف این قلمرو، تعداد $connectedCount روتین متصل به آن آزاد خواهند شد. آیا مطمئن هستید؟'
                  : 'آیا از حذف این قلمرو اطمینان دارید؟',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف قلمرو', style: TextStyle(color: Colors.redAccent, fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      final snapshot = await _repository.deleteRealmTransactional(realm.id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('قلمرو «${realm.name}» حذف شد.', style: const TextStyle(fontFamily: 'Vazirmatn')),
            action: SnackBarAction(
              label: 'بازگردانی',
              textColor: const Color(0xFFFFD700),
              onPressed: () async {
                await _repository.restoreRealmFromSnapshot(snapshot);
                await _loadData();
              },
            ),
          ),
        );
      }
    }
  }

  void _showWhyThisRealmExplanation() {
    final colors = context.colors;
    String text = 'اطلاعاتی موجود نیست.';

    if (_activeState is ScheduledRealmState) {
      text = (_activeState as ScheduledRealmState).explanation;
    } else if (_activeState is ManualRealmState) {
      text = (_activeState as ManualRealmState).explanation;
    } else if (_activeState is FreeRealmState) {
      text = (_activeState as FreeRealmState).explanation;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF6366F1), size: 20),
                SizedBox(width: 8),
                Text('چرا این قلمرو؟', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16)),
              ],
            ),
            content: Text(text, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('متوجه شدم', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Sheet Header Drag Handle & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مدیریت قلمروها',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                        color: colors.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.textPrimary.withValues(alpha: 0.08)),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 1. ACTIVE REALM HERO BANNER
                        _buildActiveRealmBanner(colors),

                        const SizedBox(height: 16),

                        // 2. 24-HOUR VISUAL DAY BAR (§7.1)
                        RealmDayBarWidget(
                          selectedWeekday: _selectedWeekday,
                          realms: _realms,
                          schedules: _schedules,
                          activeRealmState: _activeState,
                          onWeekdayChanged: (w) => setState(() => _selectedWeekday = w),
                        ),

                        const SizedBox(height: 20),

                        // 3. REALMS LIST HEADER & CREATE BUTTON
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'لیست قلمروهای تعریف‌شده',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openCreateSheet,
                              icon: const Icon(CupertinoIcons.add, size: 16, color: Colors.white),
                              label: const Text('قلمرو جدید', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 4. REALMS LIST OR EMPTY STATE
                        if (_realms.isEmpty) ...[
                          _buildEmptyStateCard(colors),
                        ] else ...[
                          ..._realms.map((realm) => _buildRealmCard(colors, realm)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRealmBanner(RitmoColors colors) {
    final state = _activeState;

    if (state is ScheduledRealmState) {
      final realm = state.realm;
      final color = realm.parseColor();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Text(realm.icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        realm.name,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                        child: const Text('قلمرو فعلی', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'باقیمانده: ${state.remaining.inMinutes} دقیقه',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                ],
              ),
            ),

            // Why This Realm Button (F-1)
            IconButton(
              onPressed: _showWhyThisRealmExplanation,
              icon: const Icon(CupertinoIcons.info_circle, color: Color(0xFF6366F1), size: 20),
              tooltip: 'چرا این قلمرو؟',
            ),
          ],
        ),
      );
    }

    if (state is ManualRealmState) {
      final realm = state.realm;
      final color = realm.parseColor();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Text(realm.icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(realm.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFD4A843), borderRadius: BorderRadius.circular(6)),
                            child: const Text('فعال موقت', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تا ساعت ${_formatTime(state.expireAt)} (${state.remaining.inMinutes} دقیقه باقی مانده)',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _clearManualOverride,
                  child: const Text('لغو', style: TextStyle(color: Colors.redAccent, fontFamily: 'Vazirmatn')),
                ),
              ],
            ),
            if (state.nextRealmName != null) ...[
              const SizedBox(height: 8),
              Text(
                'بعد از این برمی‌گردد به: ${state.nextRealmName} (${state.nextRealmTimeStr})',
                style: TextStyle(fontSize: 11, color: colors.textTertiary, fontFamily: 'Vazirmatn'),
              ),
            ],
          ],
        ),
      );
    }

    // Free State
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.sun_max_fill, color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'الان در زمان آزاد هستید و هیچ قلمرویی فعال نیست.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
            ),
          ),
          IconButton(
            onPressed: _showWhyThisRealmExplanation,
            icon: const Icon(CupertinoIcons.info_circle, color: Colors.grey, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRealmCard(RitmoColors colors, RealmData realm) {
    final color = realm.parseColor();
    final routineCount = _routineCounts[realm.id] ?? 0;
    final realmSchedules = _schedules.where((s) => s.zoneId == realm.id).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(realm.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),

          // Name & Schedule Chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      realm.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$routineCount روتین',
                        style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Schedules Summary Chips
                if (realmSchedules.isEmpty)
                  Text('بدون زمان‌بندی فعال', style: TextStyle(fontSize: 11, color: colors.textTertiary, fontFamily: 'Vazirmatn'))
                else
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: realmSchedules.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${s.startTime} الی ${s.endTime}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, fontFamily: 'Vazirmatn'),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Action Overflow Menu (...)
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.ellipsis_vertical, color: colors.textTertiary, size: 18),
            onSelected: (action) {
              if (action == 'edit') {
                _openEditSheet(realm);
              } else if (action == 'manual') {
                _openManualActivationSheet(realm);
              } else if (action == 'delete') {
                _confirmDeleteRealm(realm);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manual',
                child: Row(children: [Icon(CupertinoIcons.play, size: 16), SizedBox(width: 8), Text('فعال‌سازی دستی', style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn'))]),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(CupertinoIcons.pencil, size: 16), SizedBox(width: 8), Text('ویرایش قلمرو', style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn'))]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16), SizedBox(width: 8), Text('حذف', style: TextStyle(fontSize: 13, color: Colors.redAccent, fontFamily: 'Vazirmatn'))]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(RitmoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.square_grid_2x2, size: 36, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'هیچ قلمرویی تعریف نشده است',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 4),
          Text(
            'با قلمروها می‌توانید برنامه‌ریزی روزانه خود را بخش‌بندی کرده و تمرکز عمیق را تجربه کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.4),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _openCreateSheet,
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            child: const Text('ساخت اولین قلمرو', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
