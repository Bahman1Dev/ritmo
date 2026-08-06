import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class TimelineOverflowCard extends StatelessWidget {
  const TimelineOverflowCard({
    super.key,
    required this.overflowCount,
    required this.overflowItems,
  });

  final int overflowCount;
  final List<AgendaItem> overflowItems;

  void _showOverflowSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CalendarTokens.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(CalendarTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'رویدادهای هم‌زمان (${toPersianDigits(overflowCount)})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: overflowItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = overflowItems[index];
                      final domainColor = _getDomainColor(item.domain);
                      final domainIcon = _getDomainIcon(item.domain);

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: domainColor.withValues(alpha: 0.15),
                          child: Icon(domainIcon, size: 14, color: domainColor),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w600,
                            fontSize: CalendarTokens.textBody,
                          ),
                        ),
                        subtitle: item.timeOfDay != null
                            ? Text(
                                toPersianDigits(item.timeOfDay!),
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: CalendarTokens.textMeta,
                                ),
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ActionRouter.open(context, item: item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => _showOverflowSheet(context),
      borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant.withValues(alpha: CalendarTokens.alphaDomainFill),
          borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: CalendarTokens.alphaCardBorder),
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacingS),
        child: Text(
          '+${toPersianDigits(overflowCount.toString())} مورد دیگر',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: CalendarTokens.textMetaSplit,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }

  static IconData _getDomainIcon(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine:
        return Icons.task_alt_rounded;
      case AgendaDomain.prayer:
        return Icons.access_time_filled_rounded;
      case AgendaDomain.mustahab:
        return Icons.auto_awesome_rounded;
      case AgendaDomain.course:
        return Icons.menu_book_rounded;
      case AgendaDomain.goalStep:
        return Icons.track_changes_rounded;
      case AgendaDomain.konkur:
        return Icons.assignment_rounded;
      case AgendaDomain.cycle:
        return Icons.favorite_rounded;
      case AgendaDomain.worshipDebt:
        return Icons.restore_rounded;
      case AgendaDomain.sport:
        return Icons.fitness_center_rounded;
      case AgendaDomain.medicine:
        return Icons.medication_rounded;
      case AgendaDomain.event:
        return Icons.event_rounded;
    }
  }

  static Color _getDomainColor(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine:
        return Colors.teal;
      case AgendaDomain.prayer:
        return Colors.indigo;
      case AgendaDomain.mustahab:
        return Colors.blueGrey;
      case AgendaDomain.course:
        return Colors.amber.shade800;
      case AgendaDomain.goalStep:
        return Colors.deepPurple;
      case AgendaDomain.konkur:
        return Colors.red;
      case AgendaDomain.cycle:
        return Colors.pink;
      case AgendaDomain.worshipDebt:
        return Colors.brown;
      case AgendaDomain.sport:
        return Colors.green;
      case AgendaDomain.medicine:
        return Colors.orange.shade800;
      case AgendaDomain.event:
        return Colors.blue;
    }
  }
}
