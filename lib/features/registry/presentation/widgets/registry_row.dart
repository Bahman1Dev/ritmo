// lib/features/registry/presentation/widgets/registry_row.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';

class RegistryRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final domainColor = entry.domain.color(context);
    final isArchived = entry.status == RegistryStatus.archived;

    Widget cardChild = InkWell(
      onTap: () {
        if (isSelectionMode) {
          onTap?.call();
        } else {
          ActionRouter.open(context, item: entry.agendaProxy);
        }
      },
      onLongPress: () {
        RitmoHaptics.confirm();
        onLongPress?.call();
      },
      borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isSelected
              ? domainColor.withValues(alpha: 0.15)
              : (isDark
                  ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.50)
                  : theme.cardColor),
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          border: Border.all(
            color: isSelected
                ? domainColor
                : theme.dividerColor.withValues(alpha: CalendarTokens.alphaCardBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          child: Row(
            children: [
              // Right Edge Domain Accent Bar (3px) in RTL
              Container(
                width: CalendarTokens.accentBarWidth,
                height: double.infinity,
                color: isArchived ? theme.disabledColor : domainColor,
              ),

              const SizedBox(width: 10),

              // Domain Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: domainColor.withValues(alpha: isDark ? 0.2 : 0.1),
                ),
                child: Icon(
                  entry.domain.icon,
                  size: 18,
                  color: domainColor,
                ),
              ),

              const SizedBox(width: 12),

              // Title & Details
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isArchived
                                  ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        if (isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: theme.disabledColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'بایگانی',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle ?? entry.scheduleSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Reminder Health Badge
              _buildReminderBadge(entry.reminderHealth),

              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );

    if (isArchived) {
      cardChild = Opacity(opacity: 0.55, child: cardChild);
    }

    if (!entry.caps.canArchive) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CalendarTokens.spacingL,
          vertical: 4.0,
        ),
        child: cardChild,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarTokens.spacingL,
        vertical: 4.0,
      ),
      child: Dismissible(
        key: ValueKey('entry_${entry.id}'),
        direction: DismissDirection.endToStart, // Swipe left in RTL
        confirmDismiss: (direction) async {
          if (!entry.caps.canArchive) {
            RitmoHaptics.warning();
            RitmoToast.show(context, 'این مورد سیستمی است و قابل بایگانی نیست.');
            return false;
          }
          return true;
        },
        onDismissed: (_) => onArchive?.call(),
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF64748B),
            borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
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

  Widget _buildReminderBadge(ReminderHealth health) {
    IconData icon;
    Color color;

    switch (health) {
      case ReminderHealth.off:
        icon = Icons.notifications_off_outlined;
        color = Colors.grey;
        break;
      case ReminderHealth.armed:
        icon = Icons.notifications_active_rounded;
        color = const Color(0xFF10B981); // Emerald
        break;
      case ReminderHealth.silent:
        icon = Icons.notifications_paused_rounded;
        color = const Color(0xFFF59E0B); // Amber
        break;
      case ReminderHealth.overdue:
        icon = Icons.notification_important_rounded;
        color = const Color(0xFFF43F5E); // Red
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
