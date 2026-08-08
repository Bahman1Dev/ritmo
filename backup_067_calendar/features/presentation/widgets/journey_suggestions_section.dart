import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class JourneySuggestionsSection extends StatelessWidget {
  const JourneySuggestionsSection({
    super.key,
    required this.snapshot,
    this.onSelectConflict,
  });

  final DayAgendaSnapshot snapshot;
  final ValueChanged<AgendaConflict>? onSelectConflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final conflicts = snapshot.conflicts;
    final suggestions = snapshot.suggestions;

    if (conflicts.isEmpty && suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: CalendarTokens.spacing3xl),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CalendarTokens.emerald.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, size: 28, color: CalendarTokens.emerald),
            ),
            const SizedBox(height: CalendarTokens.spacingM),
            const Text(
              'برنامه‌ات ایده‌آله 🎯',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: CalendarTokens.textTitle,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: CalendarTokens.spacingXs),
            Text(
              'هیچ تداخل یا هشداری در این روز وجود ندارد.',
              style: TextStyle(
                fontSize: CalendarTokens.textMeta,
                fontFamily: 'Vazirmatn',
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conflicts.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                const SizedBox(width: CalendarTokens.spacingS),
                Text(
                  'تداخل‌ها (${toPersianDigits(conflicts.length.toString())})',
                  style: TextStyle(
                    fontSize: CalendarTokens.textTitle,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: CalendarTokens.spacingS),
            for (final conflict in conflicts)
              InkWell(
                onTap: () => onSelectConflict?.call(conflict),
                borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                child: Container(
                  margin: const EdgeInsets.only(bottom: CalendarTokens.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                    child: Row(
                      children: [
                        Container(
                          width: CalendarTokens.accentBarWidth,
                          height: 54,
                          color: Colors.amber.shade700,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conflict.description,
                                    style: const TextStyle(
                                      fontSize: CalendarTokens.textBody,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade800,
                                    borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                                  ),
                                  child: const Text(
                                    'رفع تداخل',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: CalendarTokens.spacingM),
          ],
          if (suggestions.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: CalendarTokens.spacingS),
                Text(
                  'پیشنهادها (${toPersianDigits(suggestions.length.toString())})',
                  style: TextStyle(
                    fontSize: CalendarTokens.textTitle,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: CalendarTokens.spacingS),
            for (final suggestion in suggestions)
              Container(
                margin: const EdgeInsets.only(bottom: CalendarTokens.spacingS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CalendarTokens.radiusCard),
                  child: Row(
                    children: [
                      Container(
                        width: CalendarTokens.accentBarWidth,
                        height: 54,
                        color: theme.colorScheme.primary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  suggestion.message,
                                  style: const TextStyle(
                                    fontSize: CalendarTokens.textBody,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ),
                              if (suggestion.suggestedTimeOfDay != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(CalendarTokens.radiusBadge),
                                  ),
                                  child: Text(
                                    toPersianDigits(suggestion.suggestedTimeOfDay!),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
