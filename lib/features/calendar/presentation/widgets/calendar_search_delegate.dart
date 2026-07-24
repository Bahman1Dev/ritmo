import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';

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
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
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
    final cleanQuery = query.trim().toLowerCase();
    final results = items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(cleanQuery);
      final subtitleMatch = item.subtitle?.toLowerCase().contains(cleanQuery) ?? false;
      return titleMatch || subtitleMatch;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'هیچ رویدادی یافت نشد.',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final timeStr = item.timeOfDay != null ? toPersianDigits(item.timeOfDay!) : 'تمام‌روز';

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note, color: Colors.blueAccent, size: 20),
          ),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$timeStr ${item.subtitle != null ? "• ${item.subtitle}" : ""}'),
          onTap: () => close(context, item),
        );
      },
    );
  }
}
