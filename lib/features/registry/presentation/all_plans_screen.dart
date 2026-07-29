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
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';

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

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _service.query(_query, _settingsMap);
      List<RegistryHealthIssue> health = [];
      try {
        health = await RegistryHealthAudit().inspectAll(_settingsMap);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _entries = items;
          _healthIssues = health;
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
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'routines',
      {'isArchived': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [entry.sourceId],
    );

    RegistryIndex.instance.invalidate();
    await _refreshData();

    if (mounted) {
      RitmoToast.show(
        context,
        '«${entry.title}» بایگانی شد',
        onUndo: () async {
          await db.update(
            'routines',
            {'isArchived': 0, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
            where: 'id = ?',
            whereArgs: [entry.sourceId],
          );
          RegistryIndex.instance.invalidate();
          await _refreshData();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'همه برنامه‌ها',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
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
        body: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(CalendarTokens.spacingL),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'جست‌وجو در همه برنامه‌ها...',
                  hintStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
                      : theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
                    ),
                  ),
                ),
              ),
            ),

            // Lens Switcher
            _buildLensSwitcher(theme),

            const SizedBox(height: 8),

            // Domain Filter Chips (only for items lens)
            if (_query.lens == RegistryLens.items) _buildDomainFilterChips(theme),

            const SizedBox(height: 8),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _query.lens == RegistryLens.health
                      ? _buildHealthLensList()
                      : _buildItemsList(),
            ),

            // Bulk Action Bar
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
        floatingActionButton: _query.lens == RegistryLens.items
            ? FloatingActionButton.extended(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => UniversalPlannerSheet(onSaved: () => setState(() {})),
                  );
                },
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'برنامه جدید',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLensSwitcher(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingL),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildLensOption(
                RegistryLens.items,
                '📚 آیتم‌ها (${toPersianDigits(_entries.length.toString())})',
              ),
            ),
            Expanded(
              child: _buildLensOption(
                RegistryLens.reminders,
                '🔔 یادآورها',
              ),
            ),
            Expanded(
              child: _buildLensOption(
                RegistryLens.health,
                '🩺 سلامت',
                badgeCount: _healthIssues.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLensOption(RegistryLens lens, String label, {int badgeCount = 0}) {
    final active = _query.lens == lens;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _query = _query.copyWith(lens: lens);
        });
        _refreshData();
      },
      borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(CalendarTokens.radiusPill),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12.5,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.white : theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFF43F5E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDomainFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingL),
      child: Row(
        children: [
          FilterChip(
            label: const Text('همه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
            selected: _query.domainFilter.isEmpty,
            onSelected: (_) {
              setState(() {
                _query = _query.copyWith(domainFilter: {});
              });
              _refreshData();
            },
          ),
          const SizedBox(width: 6),
          for (final d in RegistryDomain.values)
            if (d.settingsKey.isEmpty || _settingsMap[d.settingsKey] == 'true')
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: FilterChip(
                  label: Text(d.faLabel, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                  selected: _query.domainFilter.contains(d),
                  onSelected: (sel) {
                    final nextFilter = Set<RegistryDomain>.from(_query.domainFilter);
                    if (sel) {
                      nextFilter.add(d);
                    } else {
                      nextFilter.remove(d);
                    }
                    setState(() {
                      _query = _query.copyWith(domainFilter: nextFilter);
                    });
                    _refreshData();
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'هیچ برنامه‌ای یافت نشد',
          style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemExtent: 80,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return RepaintBoundary(
          child: RegistryRow(
            entry: entry,
            isSelected: _selectedIds.contains(entry.id),
            isSelectionMode: _isSelectionMode,
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (_selectedIds.contains(entry.id)) {
                    _selectedIds.remove(entry.id);
                    if (_selectedIds.isEmpty) _isSelectionMode = false;
                  } else {
                    _selectedIds.add(entry.id);
                  }
                });
              } else {
                ActionRouter.open(context, item: entry.agendaProxy);
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
        );
      },
    );
  }

  Widget _buildHealthLensList() {
    if (_healthIssues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: CalendarTokens.emerald, size: 48),
            const SizedBox(height: 12),
            Text(
              'همه چیز مرتب است 🎉',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CalendarTokens.emerald,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'هیچ ناهنجاری یا مشکلی در دیتابیس برنامه‌ها یافت نشد.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.grey),
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
