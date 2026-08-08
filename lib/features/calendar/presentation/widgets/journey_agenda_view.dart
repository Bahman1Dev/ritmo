import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/calendar/logic/agenda_bucketing.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/utils/domain_palette.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

/// K20 — Agenda scale view: scrollable list bucketed by time proximity.
///
/// Layout rules (from 067.md §K20):
/// - CustomScrollView with SliverPersistentHeader for sticky bucket headers.
/// - Empty buckets are NOT rendered (no header, no empty space).
/// - Fixed row height from CalendarTokens.agendaRowHeight to prevent scroll jitter.
/// - thisWeek/nextWeek/later group items under a Jalali day sub-heading.
/// - Completed items go to the bottom of their group with lineThrough style.
/// - K23: right→left swipe = postpone (task/goalStep only); left→right swipe = done.
class JourneyAgendaView extends StatefulWidget {
  const JourneyAgendaView({
    super.key,
    required this.rangeSnapshots,
    required this.now,
    required this.onItemTap,
    required this.onAddTap,
    this.isLoading = false,
    this.onPostponeItem,
    this.onDoneItem,
  });

  final Map<String, DayAgendaSnapshot> rangeSnapshots;
  final DateTime now;
  final void Function(AgendaItem item) onItemTap;
  final VoidCallback onAddTap;
  final bool isLoading;
  final Future<void> Function(AgendaItem item)? onPostponeItem;
  final Future<void> Function(AgendaItem item)? onDoneItem;

  @override
  State<JourneyAgendaView> createState() => _JourneyAgendaViewState();
}

class _JourneyAgendaViewState extends State<JourneyAgendaView> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(CalendarTokens.spacingM),
        child: RitmoSkeletonList(itemCount: 6, itemHeight: CalendarTokens.agendaRowHeight),
      );
    }

    final bucketed = bucketRange(widget.rangeSnapshots, now: widget.now);

    // Filter to non-empty buckets only
    final activeBuckets = AgendaBucket.values
        .where((b) => bucketed[b]?.isNotEmpty ?? false)
        .toList();

    if (activeBuckets.isEmpty) {
      return _EmptyAgendaState(onAddTap: widget.onAddTap);
    }

    // Build sliver list
    final slivers = <Widget>[];
    for (final bucket in activeBuckets) {
      final items = bucketed[bucket]!;
      slivers.add(_BucketHeaderSliver(
        bucket: bucket,
        count: items.length,
        isOverdue: bucket == AgendaBucket.overdue,
      ));

      final needsSubGroups = bucket == AgendaBucket.thisWeek ||
          bucket == AgendaBucket.nextWeek ||
          bucket == AgendaBucket.later;

      if (needsSubGroups) {
        final grouped = groupByDate(items);
        final sortedDates = grouped.keys.toList()..sort();
        for (final dateStr in sortedDates) {
          final dayItems = _sortItems(grouped[dateStr]!);
          slivers.add(_DaySubGroupHeader(dateStr: dateStr));
          slivers.add(_ItemsSliver(
            items: dayItems,
            onItemTap: widget.onItemTap,
            onPostponeItem: widget.onPostponeItem,
            onDoneItem: widget.onDoneItem,
          ));
        }
      } else {
        final sorted = _sortItems(items);
        slivers.add(_ItemsSliver(
          items: sorted,
          onItemTap: widget.onItemTap,
          onPostponeItem: widget.onPostponeItem,
          onDoneItem: widget.onDoneItem,
        ));
      }
    }

    // K32-point-3: "مرور روز" row at end of today bucket is handled by onAddTap
    // (day review button is in header — K32 path 1)

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: slivers,
    );
  }

  /// Sort: timed items by time, then untimed by priority descending.
  /// Done/skipped always last within their group.
  List<AgendaItem> _sortItems(List<AgendaItem> items) {
    final undone = items
        .where((i) =>
            i.completion != AgendaCompletion.done &&
            i.completion != AgendaCompletion.skipped)
        .toList();
    final done = items
        .where((i) =>
            i.completion == AgendaCompletion.done ||
            i.completion == AgendaCompletion.skipped)
        .toList();

    int compareUndone(AgendaItem a, AgendaItem b) {
      final aHasTime = a.isTimed;
      final bHasTime = b.isTimed;
      if (aHasTime && bHasTime) {
        return (a.timeOfDay ?? '').compareTo(b.timeOfDay ?? '');
      } else if (aHasTime) {
        return -1;
      } else if (bHasTime) {
        return 1;
      }
      return b.priority.compareTo(a.priority);
    }

    undone.sort(compareUndone);
    return [...undone, ...done];
  }
}

// ────────────────────────────────────────────────────────────
// Bucket Header Sliver (sticky)
// ────────────────────────────────────────────────────────────

class _BucketHeaderSliver extends StatelessWidget {
  const _BucketHeaderSliver({
    required this.bucket,
    required this.count,
    required this.isOverdue,
  });

  final AgendaBucket bucket;
  final int count;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        bucket: bucket,
        count: count,
        isOverdue: isOverdue,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate({
    required this.bucket,
    required this.count,
    required this.isOverdue,
  });

  final AgendaBucket bucket;
  final int count;
  final bool isOverdue;

  @override
  double get minExtent => CalendarTokens.agendaBucketHeaderHeight;
  @override
  double get maxExtent => CalendarTokens.agendaBucketHeaderHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final labelColor = isOverdue
        ? context.colors.warning
        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75);

    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarTokens.spacingXl,
        vertical: CalendarTokens.spacingXs,
      ),
      child: Row(
        children: [
          Text(
            bucketLabelFa(bucket),
            style: TextStyle(
              fontSize: CalendarTokens.textSection,
              fontWeight: FontWeight.w700,
              color: labelColor,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: (isOverdue ? context.colors.warning : theme.colorScheme.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
            ),
            child: Text(
              toPersianDigits(count),
              style: TextStyle(
                fontSize: CalendarTokens.textLabel,
                fontWeight: FontWeight.w600,
                color: isOverdue ? context.colors.warning : theme.colorScheme.primary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.bucket != bucket ||
      oldDelegate.count != count ||
      oldDelegate.isOverdue != isOverdue;
}

// ────────────────────────────────────────────────────────────
// Day Sub-Group Header (non-sticky)
// ────────────────────────────────────────────────────────────

class _DaySubGroupHeader extends StatelessWidget {
  const _DaySubGroupHeader({required this.dateStr});
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            CalendarTokens.spacingXl, CalendarTokens.spacingS, CalendarTokens.spacingXl, 2),
        child: Text(
          daySubGroupLabel(dateStr),
          style: TextStyle(
            fontSize: CalendarTokens.textMeta,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Items Sliver — K23 swipe gestures embedded
// ────────────────────────────────────────────────────────────

class _ItemsSliver extends StatelessWidget {
  const _ItemsSliver({
    required this.items,
    required this.onItemTap,
    this.onPostponeItem,
    this.onDoneItem,
  });

  final List<AgendaItem> items;
  final void Function(AgendaItem) onItemTap;
  final Future<void> Function(AgendaItem)? onPostponeItem;
  final Future<void> Function(AgendaItem)? onDoneItem;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _AgendaRow(
          item: items[i],
          onTap: () => onItemTap(items[i]),
          onPostpone: onPostponeItem != null ? () => onPostponeItem!(items[i]) : null,
          onDone: onDoneItem != null ? () => onDoneItem!(items[i]) : null,
        ),
        childCount: items.length,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Single Agenda Row — K23 Dismissible swipe
// ────────────────────────────────────────────────────────────

class _AgendaRow extends StatefulWidget {
  const _AgendaRow({
    required this.item,
    required this.onTap,
    this.onPostpone,
    this.onDone,
  });

  final AgendaItem item;
  final VoidCallback onTap;
  final Future<void> Function()? onPostpone;
  final Future<void> Function()? onDone;

  @override
  State<_AgendaRow> createState() => _AgendaRowState();
}

class _AgendaRowState extends State<_AgendaRow> {
  /// K23: Only task and goalStep support right→left postpone.
  bool get _canPostpone =>
      widget.item.domain == AgendaDomain.task ||
      widget.item.domain == AgendaDomain.goalStep;

  bool get _isDone =>
      widget.item.completion == AgendaCompletion.done ||
      widget.item.completion == AgendaCompletion.skipped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final color = domainColor(context, item.domain);
    final icon = domainIcon(item.domain);
    final isDone = _isDone;

    Widget row = SizedBox(
      height: CalendarTokens.agendaRowHeight,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CalendarTokens.spacingXl,
            vertical: CalendarTokens.spacingXs,
          ),
          child: Row(
            children: [
              // Domain icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDone ? 0.06 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    size: 16,
                    color: color.withValues(alpha: isDone ? 0.4 : 1.0)),
              ),
              const SizedBox(width: CalendarTokens.spacingS),

              // Title + subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: CalendarTokens.textBody,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Vazirmatn',
                        color: isDone
                            ? theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.35)
                            : theme.textTheme.bodyMedium?.color,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty)
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: CalendarTokens.textMeta,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: isDone ? 0.25 : 0.5),
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                  ],
                ),
              ),

              // Time label if timed
              if (item.isTimed && item.timeOfDay != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    toPersianDigits(item.timeOfDay!),
                    style: TextStyle(
                      fontSize: CalendarTokens.textMeta,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: isDone ? 0.25 : 0.55),
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),

              // Importance star — task domain only
              if (item.domain == AgendaDomain.task &&
                  item.meta['isImportant'] == 1)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.star_rounded,
                      size: 16,
                      color: theme.colorScheme.primary.withValues(
                          alpha: isDone ? 0.25 : 0.75)),
                ),
            ],
          ),
        ),
      ),
    );

    // K23 — wrap in Dismissible for swipe gestures
    return Dismissible(
      key: ValueKey(item.id),
      // Left→right: mark done (all domains)
      background: _SwipeBackground(
        color: Colors.green.shade600,
        icon: Icons.check_rounded,
        alignment: AlignmentDirectional.centerStart,
        label: 'انجام شد',
      ),
      // Right→left: postpone (task/goalStep only); snap back for others
      secondaryBackground: _SwipeBackground(
        color: _canPostpone ? Colors.orange.shade700 : Colors.transparent,
        icon: _canPostpone ? Icons.schedule_rounded : null,
        alignment: AlignmentDirectional.centerEnd,
        label: _canPostpone ? 'فردا' : '',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Done swipe
          RitmoHaptics.tap();
          if (widget.onDone != null) await widget.onDone!();
          return false; // parent refreshes via event; don't remove from list directly
        } else {
          // Postpone swipe
          if (!_canPostpone) {
            // Snap back — routines cannot be postponed
            return false;
          }
          RitmoHaptics.tap();
          if (widget.onPostpone != null) await widget.onPostpone!();
          return false;
        }
      },
      child: row,
    );
  }
}

// ────────────────────────────────────────────────────────────
// Swipe Background
// ────────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    this.icon,
    required this.alignment,
    required this.label,
  });

  final Color color;
  final IconData? icon;
  final AlignmentGeometry alignment;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const SizedBox.shrink();
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingXl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: CalendarTokens.textMeta,
              fontWeight: FontWeight.w600,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Empty Agenda State — K20 rule + K25 rule (3 action buttons)
// ────────────────────────────────────────────────────────────

class _EmptyAgendaState extends StatelessWidget {
  const _EmptyAgendaState({required this.onAddTap});
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'برنامه‌ای در بازه پیش‌رو ثبت نشده.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: CalendarTokens.textBody,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 24),
            _ActionButton(
              label: 'افزودن برنامه',
              icon: Icons.add_rounded,
              onTap: onAddTap,
              isPrimary: true,
            ),
            const SizedBox(height: 10),
            _ActionButton(
              label: 'رفتن به نمای روز',
              icon: Icons.today_rounded,
              onTap: () {}, // Caller handles via onItemTap flow
            ),
            const SizedBox(height: 10),
            _ActionButton(
              label: 'نمای ماه',
              icon: Icons.calendar_month_rounded,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isPrimary
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          side: BorderSide(
            color: isPrimary
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          ),
        ),
      ),
    );
  }
}
