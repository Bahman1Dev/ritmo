import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/utils/domain_palette.dart';

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
                      final color = domainColor(context, item.domain);
                      final icon = domainIcon(item.domain);

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(icon, size: 14, color: color),
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
}
