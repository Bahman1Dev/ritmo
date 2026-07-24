import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class CalendarSearchDelegate extends SearchDelegate<AgendaItem?> {
  CalendarSearchDelegate({required this.items});

  final List<AgendaItem> items;

  @override
  String get searchFieldLabel => 'جستجوی رویدادها...';

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
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final cleanQuery = query.trim().toLowerCase();
    final results = items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(cleanQuery);
      final subtitleMatch = item.subtitle?.toLowerCase().contains(cleanQuery) ?? false;
      return titleMatch || subtitleMatch;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: results.isEmpty
          ? Center(
              child: Text(
                'هیچ رویدادی یافت نشد.',
                style: TextStyle(
                  color: theme.hintColor,
                  fontSize: CalendarTokens.textBody,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];
                final timeStr = item.timeOfDay != null ? toPersianDigits(item.timeOfDay!) : 'تمام‌روز';

                return ListTile(
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
                    '$timeStr ${item.subtitle != null && item.subtitle!.isNotEmpty ? "• ${item.subtitle}" : ""}',
                    style: const TextStyle(fontFamily: 'Vazirmatn'),
                  ),
                  onTap: () => close(context, item),
                );
              },
            ),
    );
  }
}
