// lib/features/search/presentation/global_search_screen.dart
// S26 — جستجوی سراسری: کارها · روتین‌ها · اهداف · سایر آیتم‌های registry

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/domain/registry_query.dart';
import 'package:ritmo/features/registry/logic/registry_index.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';

/// نتیجه‌ی جستجو — می‌تواند کار ساده یا آیتم registry باشد
sealed class _SearchResult {}

class _TaskResult extends _SearchResult {
  _TaskResult(this.task);
  final SimpleTask task;
}

class _RegistryResult extends _SearchResult {
  _RegistryResult(this.entry);
  final RegistryEntry entry;
}

/// گروه نتایج جستجو
class _ResultGroup {
  const _ResultGroup({required this.label, required this.items, required this.icon});
  final String label;
  final List<_SearchResult> items;
  final IconData icon;
}

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<_ResultGroup> _groups = [];
  bool _isSearching = false;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    // فوکوس اتوماتیک
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim();
    if (query == _lastQuery) return;
    _lastQuery = query;
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _groups = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;

    // ۱. جستجو در کارهای ساده
    final taskRows = await _searchSimpleTasks(query);

    // ۲. جستجو در registry (روتین‌ها · اهداف · سایر)
    final registryEntries = await _searchRegistry(query);

    if (!mounted) return;

    final groups = <_ResultGroup>[];

    // --- کارها ---
    if (taskRows.isNotEmpty) {
      groups.add(_ResultGroup(
        label: 'کارها',
        icon: CupertinoIcons.check_mark_circled,
        items: taskRows.take(5).map((t) => _TaskResult(t) as _SearchResult).toList(),
      ));
    }

    // --- گروه‌بندی registry بر اساس domain ---
    final Map<RegistryDomain, List<RegistryEntry>> byDomain = {};
    for (final e in registryEntries) {
      byDomain.putIfAbsent(e.domain, () => []).add(e);
    }

    // ترتیب نمایش: روتین · هدف · سایر
    final domainOrder = [
      RegistryDomain.routine,
      RegistryDomain.goal,
      RegistryDomain.worship,
      RegistryDomain.medicine,
      RegistryDomain.course,
      RegistryDomain.konkur,
      RegistryDomain.movementKind,
      RegistryDomain.workoutPlan,
    ];

    for (final domain in domainOrder) {
      final entries = byDomain[domain];
      if (entries == null || entries.isEmpty) continue;
      groups.add(_ResultGroup(
        label: domain.faLabel,
        icon: domain.icon,
        items: entries.take(5).map((e) => _RegistryResult(e) as _SearchResult).toList(),
      ));
    }

    // سایر domainها که در ترتیب نیستند
    for (final kv in byDomain.entries) {
      if (domainOrder.contains(kv.key)) continue;
      groups.add(_ResultGroup(
        label: kv.key.faLabel,
        icon: kv.key.icon,
        items: kv.value.take(5).map((e) => _RegistryResult(e) as _SearchResult).toList(),
      ));
    }

    setState(() {
      _groups = groups;
      _isSearching = false;
    });
  }

  Future<List<SimpleTask>> _searchSimpleTasks(String query) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final q = '%${query.trim()}%';
      final rows = await db.query(
        'simple_tasks',
        where: 'title LIKE ? OR note LIKE ?',
        whereArgs: [q, q],
        orderBy: 'isDone ASC, updatedAt DESC',
        limit: 10,
      );
      return rows.map((m) => SimpleTask.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RegistryEntry>> _searchRegistry(String query) async {
    try {
      final results = await RegistryIndex.instance.queryPhaseA(
        RegistryQuery(
          searchText: query,
          statusFilter: const {RegistryStatus.active, RegistryStatus.paused, RegistryStatus.completed},
          showArchived: false,
        ),
        const {},
      );
      return results;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ──── نوار جستجو ────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(CupertinoIcons.search, color: colors.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'جستجو در همه‌چیز…',
                                  hintStyle: TextStyle(
                                    color: colors.textSecondary.withValues(alpha: 0.6),
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_controller.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _controller.clear();
                                  _focusNode.requestFocus();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    size: 16,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'انصراف',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 14,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ──── محتوا ────
              Expanded(
                child: _buildBody(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(RitmoColors colors) {
    if (_isSearching) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final query = _controller.text.trim();

    // حالت خالی — قبل از جستجو
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 52, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'چیزی بنویس تا جستجو شود.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      );
    }

    // هیچ نتیجه‌ای پیدا نشد
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 52, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'هیچ نتیجه‌ای برای «$query» پیدا نشد.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontFamily: 'Vazirmatn',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // نتایج
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      itemCount: _groups.length,
      itemBuilder: (context, gi) {
        final group = _groups[gi];
        return _buildGroup(group, colors);
      },
    );
  }

  Widget _buildGroup(_ResultGroup group, RitmoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ──── هدر گروه ────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Row(
            children: [
              Icon(group.icon, size: 15, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                group.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                  fontFamily: 'Vazirmatn',
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                toPersianDigits('(${group.items.length})'),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary.withValues(alpha: 0.6),
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
        // ──── ردیف‌های نتیجه ────
        ...group.items.map((item) => _buildResultTile(item, colors)),
        // جداکننده
        if (_groups.last != group)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 20,
            endIndent: 20,
            color: colors.border.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  Widget _buildResultTile(_SearchResult result, RitmoColors colors) {
    if (result is _TaskResult) {
      return _buildTaskTile(result.task, colors);
    } else if (result is _RegistryResult) {
      return _buildRegistryTile(result.entry, colors);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTaskTile(SimpleTask task, RitmoColors colors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context), // ردیف کار: در این نسخه فقط بازگشت
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Icon(
                task.isDone ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                size: 20,
                color: task.isDone ? colors.primary : colors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Vazirmatn',
                        color: task.isDone
                            ? colors.textSecondary.withValues(alpha: 0.6)
                            : colors.textPrimary,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        decorationColor: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.note != null && task.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.note!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Vazirmatn',
                          color: colors.textSecondary.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (task.dueDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDueDate(task.dueDate!),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.primary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistryTile(RegistryEntry entry, RitmoColors colors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Icon(
                entry.domain.icon,
                size: 20,
                color: colors.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Vazirmatn',
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.subtitle != null && entry.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Vazirmatn',
                          color: colors.textSecondary.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // نشان وضعیت
              _StatusDot(status: entry.status),
            ],
          ),
        ),
      ),
    );
  }

  /// نمایش تاریخ سررسید به صورت ساده
  String _formatDueDate(String iso) {
    try {
      final today = DateTime.now();
      final d = DateTime.parse(iso);
      final diff = d.difference(DateTime(today.year, today.month, today.day)).inDays;
      if (diff == 0) return 'امروز';
      if (diff == 1) return 'فردا';
      if (diff == -1) return 'دیروز';
      if (diff < 0) return toPersianDigits('${-diff} روز پیش');
      return toPersianDigits('$diff روز دیگر');
    } catch (_) {
      return iso;
    }
  }
}

/// نقطهٔ رنگی وضعیت entry
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final RegistryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RegistryStatus.active    => const Color(0xFF10B981),
      RegistryStatus.paused    => Colors.grey,
      RegistryStatus.archived  => const Color(0xFF64748B),
      RegistryStatus.completed => const Color(0xFF10B981),
      RegistryStatus.expired   => const Color(0xFFF59E0B),
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
