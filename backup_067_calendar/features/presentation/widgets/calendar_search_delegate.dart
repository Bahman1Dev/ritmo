// lib/features/calendar/presentation/widgets/calendar_search_delegate.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';

import 'package:ritmo/core/utils/persian_text.dart';

class CalendarSearchDelegate extends SearchDelegate<AgendaItem?> {
  CalendarSearchDelegate({
    required this.items,
    this.registryEntries = const [],
    this.onItemSelected,
  });

  final List<AgendaItem> items;
  final List<RegistryEntry> registryEntries;
  final ValueChanged<AgendaItem>? onItemSelected;

  @override
  String get searchFieldLabel => 'جستجوی رویدادها و برنامه‌ها...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final q = normalizeFa(query);

    final todayResults = q.isEmpty
        ? items
        : items
            .where((i) =>
                normalizeFa(i.title).contains(q) ||
                (i.subtitle != null && normalizeFa(i.subtitle!).contains(q)))
            .toList();

    final allRegistryResults = q.isEmpty
        ? registryEntries
        : registryEntries
            .where((r) =>
                normalizeFa(r.title).contains(q) ||
                (r.subtitle != null && normalizeFa(r.subtitle!).contains(q)))
            .toList();

    if (todayResults.isEmpty && allRegistryResults.isEmpty) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Text(
            'رویداد یا برنامه‌ای یافت نشد',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(CalendarTokens.spacingM),
        children: [
          if (todayResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                'در این روز (${toPersianDigits(todayResults.length.toString())})',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            for (final item in todayResults)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event_note_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
                subtitle: Text(
                  '${item.timeOfDay != null ? toPersianDigits(item.timeOfDay!) : "تمام‌روز"} ${item.subtitle != null && item.subtitle!.isNotEmpty ? "• ${item.subtitle}" : ""}',
                  style: const TextStyle(fontFamily: 'Vazirmatn'),
                ),
                onTap: () {
                  close(context, item);
                  onItemSelected?.call(item);
                },
              ),
          ],

          if (allRegistryResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                'همهٔ برنامه‌ها (${toPersianDigits(allRegistryResults.length.toString())})',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            for (final entry in allRegistryResults)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: entry.domain.color(context).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.domain.icon, color: entry.domain.color(context), size: 20),
                ),
                title: Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
                subtitle: Text(
                  '${entry.domain.faLabel} · ${entry.scheduleSummary}',
                  style: const TextStyle(fontFamily: 'Vazirmatn'),
                ),
                onTap: () {
                  close(context, null);
                  ActionRouter.open(context, item: entry.agendaProxy);
                },
              ),
          ],
        ],
      ),
    );
  }
}
