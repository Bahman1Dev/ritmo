// lib/features/registry/presentation/all_plans_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/domain/registry_health_issue.dart';
import 'package:ritmo/features/registry/domain/registry_query.dart';
import 'package:ritmo/features/registry/logic/registry_health_audit.dart';
import 'package:ritmo/features/registry/logic/registry_index.dart';
import 'package:ritmo/features/registry/logic/registry_service.dart';
import 'package:ritmo/features/registry/presentation/widgets/registry_bulk_bar.dart';
import 'package:ritmo/features/registry/presentation/widgets/registry_health_card.dart';
import 'package:ritmo/features/registry/presentation/widgets/registry_row.dart';
import 'package:ritmo/features/registry/presentation/widgets/registry_skeleton.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';

enum PlanSortMode {
  displayOrder,
  closestDue,
  time,
  duration,
  alphabetical,
}

class AllPlansScreen extends StatefulWidget {
  const AllPlansScreen({super.key});

  @override
  State<AllPlansScreen> createState() => _AllPlansScreenState();
}

class _AllPlansScreenState extends State<AllPlansScreen> {
  final RegistryService _service = RegistryService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  RegistryQuery _query = const RegistryQuery();
  List<RegistryEntry> _entries = [];
  List<RegistryHealthIssue> _healthIssues = [];
  Map<String, String> _settingsMap = {};

  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  PlanSortMode _sortMode = PlanSortMode.displayOrder;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('app_settings');
      final map = <String, String>{};
      for (final r in rows) {
        map[r['key'] as String] = r['value'] as String? ?? '';
      }
      _settingsMap = map;
      await _refreshData();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getRemainingMinutes(RegistryEntry entry) {
    final timeStr = entry.agendaProxy.timeOfDay?.trim();
    if (timeStr == null || timeStr.isEmpty) return 99999;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeStr);
    if (match == null) return 99999;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, h, m);
    final diff = target.difference(now).inMinutes;
    return diff < -45 ? 99990 : diff;
  }

  void _applySort() {
    switch (_sortMode) {
      case PlanSortMode.closestDue:
        _entries.sort(
          (a, b) =>
              _getRemainingMinutes(a).compareTo(_getRemainingMinutes(b)),
        );
        break;
      case PlanSortMode.time:
        _entries.sort((a, b) {
          final timeA = a.agendaProxy.timeOfDay ?? '23:59';
          final timeB = b.agendaProxy.timeOfDay ?? '23:59';
          return timeA.compareTo(timeB);
        });
        break;
      case PlanSortMode.duration:
        _entries.sort(
          (a, b) => (b.agendaProxy.durationMinutes ?? 0)
              .compareTo(a.agendaProxy.durationMinutes ?? 0),
        );
        break;
      case PlanSortMode.alphabetical:
        _entries.sort((a, b) => a.title.compareTo(b.title));
        break;
      case PlanSortMode.displayOrder:
        break;
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      RegistryIndex.instance.invalidate();
      final items = await _service.query(_query, _settingsMap);
      List<RegistryHealthIssue> health = [];
      try {
        health = await RegistryHealthAudit().inspectAll(_settingsMap);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _entries = items;
          _healthIssues = health;
          _applySort();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _query = _query.copyWith(searchText: text);
      });
      _refreshData();
    });
  }

  Future<void> _archiveEntry(RegistryEntry entry) async {
    await RitmoExecutionKernel.instance.execute(
      ArchiveRoutineCommand(routineId: entry.sourceId),
    );

    RegistryIndex.instance.invalidate();
    await _refreshData();

    if (mounted) {
      RitmoToast.show(
        context,
        '«${entry.title}» بایگانی شد',
        onUndo: () async {
          await RitmoExecutionKernel.instance.execute(
            UnarchiveRoutineCommand(routineId: entry.sourceId),
          );
          RegistryIndex.instance.invalidate();
          await _refreshData();
        },
      );
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_query.domainFilter.isNotEmpty) count += _query.domainFilter.length;
    if (_sortMode != PlanSortMode.displayOrder) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Custom Header ───
              _buildHeader(theme),

              // ─── Search Bar (integrated filter) ───
              _buildSearchBar(theme, isDark),

              const SizedBox(height: 12),

              // ─── Level 1: Lens Switcher ───
              _buildLensSwitcher(theme, isDark),

              const SizedBox(height: 10),

              // ─── Level 2: Domain Chips (only for items lens) ───
              if (_query.lens == RegistryLens.items)
                _buildDomainFilterChips(theme, isDark),

              if (_query.lens == RegistryLens.items)
                const SizedBox(height: 8),

              // ─── Main Content ───
              Expanded(
                child: _isLoading
                    ? const RegistrySkeleton()
                    : _query.lens == RegistryLens.health
                        ? _buildHealthLensList()
                        : _buildItemsList(theme, isDark),
              ),

              // ─── Bulk Action Bar ───
              if (_isSelectionMode)
                RegistryBulkBar(
                  selectedCount: _selectedIds.length,
                  onCancel: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                  onArchiveSelected: () async {
                    for (final id in _selectedIds) {
                      final srcId = id.split(':').last;
                      await RitmoExecutionKernel.instance.execute(
                        ArchiveRoutineCommand(routineId: srcId),
                      );
                    }
                    if (mounted) {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      });
                    }
                    RegistryIndex.instance.invalidate();
                    await _refreshData();
                  },
                  onDeleteSelected: () async {
                    for (final id in _selectedIds) {
                      final srcId = id.split(':').last;
                      await RitmoExecutionKernel.instance.execute(
                        DeleteRoutineCommand(routineId: srcId),
                      );
                    }
                    if (mounted) {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      });
                    }
                    RegistryIndex.instance.invalidate();
                    await _refreshData();
                  },
                ),
            ],
          ),
        ),

        // ─── FAB ───
        floatingActionButton: _query.lens == RegistryLens.items
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => UniversalPlannerSheet(
                        onSaved: () => setState(() {}),
                      ),
                    );
                  },
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      CalendarTokens.fabRadius,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'افزودن برنامه',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ──────────── HEADER ──────────────────────
  // ═══════════════════════════════════════════

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CalendarTokens.spacingL,
        CalendarTokens.spacingM,
        CalendarTokens.spacingL,
        CalendarTokens.spacingS,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),

          // Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مخزن روتین‌ها',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (!_isLoading)
                  Text(
                    '${toPersianDigits(_entries.length.toString())} برنامه فعال',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),

          // Selection mode close
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ──────────── SEARCH BAR ──────────────────
  // ═══════════════════════════════════════════

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingL),
      child: SizedBox(
        height: CalendarTokens.searchBarHeight,
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'جست‌وجو در برنامه‌ها',
            hintStyle: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13.5,
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.4),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.4),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.4),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
                // Sort / Filter icon inside search bar
                Stack(
                  children: [
                    PopupMenuButton<PlanSortMode>(
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color:
                            _sortMode != PlanSortMode.displayOrder
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.4),
                      ),
                      tooltip: 'مرتب‌سازی',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (mode) {
                        setState(() {
                          _sortMode = mode;
                          _applySort();
                        });
                      },
                      itemBuilder: _buildSortMenuItems,
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            toPersianDigits(
                              _activeFilterCount.toString(),
                            ),
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
            filled: true,
            fillColor: isDark
                ? theme.colorScheme.surfaceContainerHigh
                    .withValues(alpha: 0.20)
                : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<PlanSortMode>> _buildSortMenuItems(
    BuildContext ctx,
  ) {
    final theme = Theme.of(ctx);
    PopupMenuEntry<PlanSortMode> item(PlanSortMode mode, IconData icon, String label) {
      final isActive = _sortMode == mode;
      return PopupMenuItem(
        value: mode,
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? theme.colorScheme.primary : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    return [
      item(PlanSortMode.displayOrder, Icons.dashboard_rounded,
          'ترتیب پیش‌فرض'),
      item(PlanSortMode.closestDue, Icons.hourglass_top_rounded,
          'نزدیک‌ترین موعد'),
      item(PlanSortMode.time, Icons.schedule_rounded,
          'زمان اجرا (صبح تا شب)'),
      item(PlanSortMode.duration, Icons.timer_rounded,
          'مدت زمان (بلند به کوتاه)'),
      item(PlanSortMode.alphabetical, Icons.sort_by_alpha_rounded,
          'حروف الفبا'),
    ];
  }

  // ═══════════════════════════════════════════
  // ──────────── LENS SWITCHER ───────────────
  // ═══════════════════════════════════════════

  Widget _buildLensSwitcher(ThemeData theme, bool isDark) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingL),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
                  .withValues(alpha: 0.20)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildLensTab(
                theme,
                isDark,
                RegistryLens.items,
                'برنامه‌ها',
                badgeText: _isLoading
                    ? null
                    : toPersianDigits(_entries.length.toString()),
              ),
            ),
            Expanded(
              child: _buildLensTab(
                theme,
                isDark,
                RegistryLens.reminders,
                'یادآورها',
              ),
            ),
            Expanded(
              child: _buildLensTab(
                theme,
                isDark,
                RegistryLens.health,
                'سلامت',
                showWarningDot: _healthIssues.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLensTab(
    ThemeData theme,
    bool isDark,
    RegistryLens lens,
    String label, {
    String? badgeText,
    bool showWarningDot = false,
  }) {
    final isActive = _query.lens == lens;

    return GestureDetector(
      onTap: () {
        setState(() {
          _query = _query.copyWith(lens: lens);
        });
        _refreshData();
      },
      child: AnimatedContainer(
        duration: CalendarTokens.durationStandard,
        curve: CalendarTokens.curveDefault,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? theme.colorScheme.surfaceContainerHigh
                      .withValues(alpha: 0.5)
                  : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? theme.textTheme.bodyLarge?.color
                    : theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.55),
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 5),
              Text(
                badgeText,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.4),
                ),
              ),
            ],
            if (showWarningDot) ...[
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ──────────── DOMAIN FILTER CHIPS ─────────
  // ═══════════════════════════════════════════

  Widget _buildDomainFilterChips(ThemeData theme, bool isDark) {
    return SizedBox(
      height: CalendarTokens.chipHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CalendarTokens.spacingL,
        ),
        children: [
          _buildFilterChip(
            theme,
            isDark,
            label: 'همه',
            isSelected: _query.domainFilter.isEmpty,
            onTap: () {
              setState(() {
                _query = _query.copyWith(domainFilter: {});
              });
              _refreshData();
            },
          ),
          const SizedBox(width: 8),
          for (final d in RegistryDomain.values)
            if (d.settingsKey.isEmpty ||
                _settingsMap[d.settingsKey] == 'true')
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildFilterChip(
                  theme,
                  isDark,
                  label: d.faLabel,
                  isSelected: _query.domainFilter.contains(d),
                  onTap: () {
                    final nextFilter =
                        Set<RegistryDomain>.from(_query.domainFilter);
                    if (_query.domainFilter.contains(d)) {
                      nextFilter.remove(d);
                    } else {
                      nextFilter.add(d);
                    }
                    setState(() {
                      _query =
                          _query.copyWith(domainFilter: nextFilter);
                    });
                    _refreshData();
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme,
    bool isDark, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const accentColor = Color(0xFF14B8A6); // Teal-500 muted

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CalendarTokens.durationStandard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.35)
                : theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? accentColor
                : theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ──────────── ITEMS LIST ──────────────────
  // ═══════════════════════════════════════════

  Widget _buildItemsList(ThemeData theme, bool isDark) {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              _query.searchText.isNotEmpty
                  ? 'نتیجه‌ای یافت نشد'
                  : 'هنوز برنامه‌ای ثبت نشده',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.4),
              ),
            ),
            if (_query.searchText.isEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'با دکمه «افزودن برنامه» شروع کنید.',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.3),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _entries.length,
      padding: const EdgeInsets.only(bottom: 88),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Dismissible(
          key: Key(entry.id),
          direction: _isSelectionMode
              ? DismissDirection.none
              : DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: const EdgeInsets.symmetric(
              horizontal: CalendarTokens.spacingL,
              vertical: CalendarTokens.registryCardGap / 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(
                CalendarTokens.radiusCardLg,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.archive_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'بایگانی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _archiveEntry(entry);
              return true;
            }
            return false;
          },
          child: RepaintBoundary(
            child: RegistryRow(
              entry: entry,
              isSelected: _selectedIds.contains(entry.id),
              isSelectionMode: _isSelectionMode,
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    if (_selectedIds.contains(entry.id)) {
                      _selectedIds.remove(entry.id);
                      if (_selectedIds.isEmpty) {
                        _isSelectionMode = false;
                      }
                    } else {
                      _selectedIds.add(entry.id);
                    }
                  });
                } else {
                  ActionRouter.open(
                    context,
                    item: entry.agendaProxy,
                  );
                }
              },
              onLongPress: () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.add(entry.id);
                });
              },
              onArchive: () => _archiveEntry(entry),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // ──────────── HEALTH LENS ─────────────────
  // ═══════════════════════════════════════════

  Widget _buildHealthLensList() {
    if (_healthIssues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: CalendarTokens.emerald,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'همه چیز مرتب است',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CalendarTokens.emerald,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'هیچ ناهنجاری یا مشکلی در دیتابیس برنامه‌ها یافت نشد.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _healthIssues.length,
      padding: const EdgeInsets.only(bottom: 40),
      itemBuilder: (context, index) {
        final issue = _healthIssues[index];
        return RegistryHealthCard(
          issue: issue,
          onFixed: () => _refreshData(),
        );
      },
    );
  }
}
