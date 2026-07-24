import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class AgendaItemDetailSheet extends StatelessWidget {
  const AgendaItemDetailSheet({
    super.key,
    required this.item,
    this.onComplete,
    this.onSkip,
    this.onFocus,
  });

  final AgendaItem item;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onFocus;

  static const Set<AgendaDomain> _actionableDomains = {
    AgendaDomain.routine,
    AgendaDomain.course,
    AgendaDomain.goalStep,
    AgendaDomain.medicine,
    AgendaDomain.sport,
    AgendaDomain.prayer,
    AgendaDomain.mustahab,
    AgendaDomain.worshipDebt,
    AgendaDomain.cycle,
    AgendaDomain.konkur,
  };

  static Future<void> show(
    BuildContext context, {
    required AgendaItem item,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
    VoidCallback? onFocus,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AgendaItemDetailSheet(
        item: item,
        onComplete: onComplete,
        onSkip: onSkip,
        onFocus: onFocus,
      ),
    );
  }

  String _completionLabel(AgendaCompletion completion) {
    switch (completion) {
      case AgendaCompletion.none:
        return 'نامشخص';
      case AgendaCompletion.pending:
        return 'در انتظار';
      case AgendaCompletion.done:
        return 'انجام‌شده';
      case AgendaCompletion.partial:
        return 'ناقص';
      case AgendaCompletion.skipped:
        return 'رد شده';
      case AgendaCompletion.overdue:
        return 'عقب‌افتاده';
      case AgendaCompletion.missed:
        return 'از دست رفته';
    }
  }

  String _domainLabel(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine:
        return 'روتین';
      case AgendaDomain.prayer:
        return 'نماز';
      case AgendaDomain.mustahab:
        return 'مستحبات';
      case AgendaDomain.course:
        return 'درس';
      case AgendaDomain.goalStep:
        return 'گام هدف';
      case AgendaDomain.konkur:
        return 'کنکور';
      case AgendaDomain.cycle:
        return 'دوره';
      case AgendaDomain.worshipDebt:
        return 'قضا';
      case AgendaDomain.sport:
        return 'ورزش';
      case AgendaDomain.medicine:
        return 'دارو';
    }
  }

  IconData _domainIcon(AgendaDomain domain) {
    switch (domain) {
      case AgendaDomain.routine:
        return Icons.sync_rounded;
      case AgendaDomain.prayer:
        return Icons.mosque_rounded;
      case AgendaDomain.mustahab:
        return Icons.menu_book_rounded;
      case AgendaDomain.course:
        return Icons.school_rounded;
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
    }
  }

  Color _domainColor(AgendaDomain domain) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isDone = item.isCompleted;
    final isActionable = _actionableDomains.contains(item.domain);
    final color = _domainColor(item.domain);

    String? endTimeStr;
    if (item.isTimed && item.durationMinutes != null) {
      final parts = item.timeOfDay!.split(':');
      if (parts.length == 2) {
        final startH = int.tryParse(parts[0]) ?? 0;
        final startM = int.tryParse(parts[1]) ?? 0;
        final endTotal = (startH * 60) + startM + item.durationMinutes!;
        final endH = (endTotal ~/ 60) % 24;
        final endM = endTotal % 60;
        endTimeStr =
            '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerLow : theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(CalendarTokens.radiusSheet)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Domain Hero Banner Top (64px)
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: CalendarTokens.spacing2xl),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(CalendarTokens.radiusSheet)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_domainIcon(item.domain), size: 20, color: color),
                    ),
                    const SizedBox(width: CalendarTokens.spacingM),
                    Text(
                      _domainLabel(item.domain),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.maybePop(context),
                      tooltip: 'بستن',
                    ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CalendarTokens.spacing2xl,
                  CalendarTokens.spacingXl,
                  CalendarTokens.spacing2xl,
                  CalendarTokens.spacingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Status Badge Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDone
                                ? CalendarTokens.emerald.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                          ),
                          child: Text(
                            _completionLabel(item.completion),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDone ? CalendarTokens.emerald : Colors.amber.shade800,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: CalendarTokens.spacingXs),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Vazirmatn',
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                        ),
                      ),
                    ],

                    const SizedBox(height: CalendarTokens.spacingM),
                    Divider(color: theme.dividerColor.withValues(alpha: 0.12)),
                    const SizedBox(height: CalendarTokens.spacingS),

                    // Time Row
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: CalendarTokens.spacingM),
                        Text(
                          item.isTimed
                              ? _buildTimeLabel(item, endTimeStr)
                              : 'تمام‌روز / بدون زمان',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CalendarTokens.spacing2xl),

                    // Action Buttons Row (50px height)
                    Row(
                      children: [
                        if (onFocus != null) ...[
                          Semantics(
                            label: 'نمایش روی تایم‌لاین',
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.maybePop(context);
                                  onFocus!();
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(CalendarTokens.radiusSegment),
                                  ),
                                ),
                                icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                                label: const Text(
                                  'تایم‌لاین',
                                  style: TextStyle(fontFamily: 'Vazirmatn'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: CalendarTokens.spacingS),
                        ],
                        if (isActionable && !isDone && onSkip != null) ...[
                          Semantics(
                            label: 'رد کردن این آیتم',
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.maybePop(context);
                                  onSkip!();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amber.shade800,
                                  side: BorderSide(color: Colors.amber.shade800),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(CalendarTokens.radiusSegment),
                                  ),
                                ),
                                icon: const Icon(Icons.block_rounded, size: 18),
                                label: const Text(
                                  'رد کردن',
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: CalendarTokens.spacingS),
                        ],
                        if (isActionable && !isDone && onComplete != null)
                          Expanded(
                            child: Semantics(
                              label: 'تکمیل این آیتم',
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    onComplete!();
                                  },
                                  icon: const Icon(Icons.check_rounded, size: 20),
                                  label: const Text(
                                    'تکمیل',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CalendarTokens.emerald,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(CalendarTokens.radiusSegment),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!isActionable)
                          Expanded(
                            child: Text(
                              'عملیات مستقیم برای این نوع در دسترس نیست',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTimeLabel(AgendaItem item, String? endTimeStr) {
    final start = toPersianDigits(item.timeOfDay ?? '');
    if (item.durationMinutes != null && item.durationMinutes! > 0) {
      final dur = toPersianDigits('${item.durationMinutes}');
      if (endTimeStr != null) {
        return 'از $start تا ${toPersianDigits(endTimeStr)} ($dur دقیقه)';
      }
      return 'ساعت $start ($dur دقیقه)';
    }
    return 'ساعت $start';
  }
}
