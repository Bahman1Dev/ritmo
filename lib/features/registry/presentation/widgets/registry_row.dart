// lib/features/registry/presentation/widgets/registry_row.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/presentation/widgets/registry_countdown_badge.dart';
import 'package:ritmo/features/registry/presentation/widgets/registry_status_badge.dart';

class RegistryRow extends StatefulWidget {
  const RegistryRow({
    super.key,
    required this.entry,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onArchive,
    this.onTogglePause,
  });

  final RegistryEntry entry;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onArchive;
  final VoidCallback? onTogglePause;

  @override
  State<RegistryRow> createState() => _RegistryRowState();
}

class _RegistryRowState extends State<RegistryRow> {
  bool _isPressed = false;

  RegistryEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final domainColor = entry.domain.color(context);
    final isArchived = entry.status == RegistryStatus.archived;

    // Determine if countdown is urgent (< 15 min remaining)
    final isUrgent = _checkUrgency();

    Widget cardChild = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (widget.isSelectionMode) {
          widget.onTap?.call();
        } else {
          ActionRouter.open(context, item: entry.agendaProxy);
        }
      },
      onLongPress: () {
        RitmoHaptics.confirm();
        widget.onLongPress?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: CalendarTokens.durationMicro,
        curve: CalendarTokens.curveDefault,
        child: AnimatedContainer(
          duration: CalendarTokens.durationStandard,
          height: CalendarTokens.registryCardHeight,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? domainColor.withValues(alpha: 0.10)
                : (isDark
                    ? theme.colorScheme.surfaceContainerHigh
                        .withValues(alpha: 0.25)
                    : theme.cardColor),
            borderRadius:
                BorderRadius.circular(CalendarTokens.radiusCardLg),
            border: Border.all(
              color: widget.isSelected
                  ? domainColor.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.06),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              // Domain icon container (40×40, rounded rect)
              Container(
                width: CalendarTokens.iconContainerSize,
                height: CalendarTokens.iconContainerSize,
                decoration: BoxDecoration(
                  color: domainColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(
                    CalendarTokens.iconContainerRadius,
                  ),
                ),
                child: Icon(
                  entry.domain.icon,
                  size: 20,
                  color: domainColor,
                ),
              ),

              const SizedBox(width: 12),

              // Title + Schedule + Status row
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _stripEmoji(entry.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isArchived
                            ? theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.45)
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Schedule summary
                    Text(
                      entry.scheduleSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Status badge + Countdown
                    Row(
                      children: [
                        RegistryStatusBadge(
                          status: entry.status,
                          reminderHealth: entry.reminderHealth,
                          isUrgent: isUrgent,
                        ),
                        const SizedBox(width: 6),
                        RegistryCountdownBadge(
                          agendaItem: entry.agendaProxy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Three-dot menu
              _buildOverflowMenu(context, theme),
            ],
          ),
        ),
      ),
    );

    if (isArchived) {
      cardChild = Opacity(opacity: 0.50, child: cardChild);
    }

    // Wrap with dismissible if archivable
    if (!entry.caps.canArchive) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CalendarTokens.spacingL,
          vertical: CalendarTokens.registryCardGap / 2,
        ),
        child: cardChild,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarTokens.spacingL,
        vertical: CalendarTokens.registryCardGap / 2,
      ),
      child: Dismissible(
        key: ValueKey('entry_${entry.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          if (!entry.caps.canArchive) {
            RitmoHaptics.warning();
            RitmoToast.show(
              context,
              'این مورد سیستمی است و قابل بایگانی نیست.',
            );
            return false;
          }
          return true;
        },
        onDismissed: (_) => widget.onArchive?.call(),
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF64748B),
            borderRadius:
                BorderRadius.circular(CalendarTokens.radiusCardLg),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'بایگانی',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.archive_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
        child: cardChild,
      ),
    );
  }

  Widget _buildOverflowMenu(BuildContext context, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (action) {
        switch (action) {
          case 'edit':
            ActionRouter.open(context, item: entry.agendaProxy);
            break;
          case 'archive':
            widget.onArchive?.call();
            break;
        }
      },
      itemBuilder: (_) => [
        if (entry.caps.canEdit)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'ویرایش',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
              ],
            ),
          ),
        if (entry.caps.canArchive)
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'بایگانی',
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _checkUrgency() {
    final timeStr = entry.agendaProxy.timeOfDay?.trim();
    if (timeStr == null || timeStr.isEmpty) return false;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeStr);
    if (match == null) return false;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, h, m);
    final diff = target.difference(now).inMinutes;
    return diff >= 0 && diff <= 15;
  }

  /// Strips emoji characters from title for cleaner display.
  /// The domain icon serves as the visual identifier instead.
  static String _stripEmoji(String text) {
    return text
        .replaceAll(
          RegExp(
            r'[\u{1F600}-\u{1F64F}' // Emoticons
            r'\u{1F300}-\u{1F5FF}' // Misc Symbols & Pictographs
            r'\u{1F680}-\u{1F6FF}' // Transport & Map
            r'\u{1F1E0}-\u{1F1FF}' // Flags
            r'\u{2600}-\u{26FF}' // Misc symbols
            r'\u{2700}-\u{27BF}' // Dingbats
            r'\u{FE00}-\u{FE0F}' // Variation Selectors
            r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols
            r'\u{1FA70}-\u{1FAFF}' // Extended-A
            r'\u{200D}' // ZWJ
            r'\u{20E3}' // Combining Enclosing Keycap
            r'\u{FE0F}]', // Variation Selector
            unicode: true,
          ),
          '',
        )
        .trim();
  }
}
