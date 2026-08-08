import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/action_router.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/persian_text.dart';
import 'package:ritmo/features/calendar/data/calendar_search_repository.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/calendar/utils/domain_palette.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

/// K36 + K37 — Global Calendar Search Delegate
/// Grouped into: "امروز", "این هفته", "سایر تاریخ‌ها"
/// Searches across current day items + global database via CalendarSearchRepository.
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
  String get searchFieldLabel => 'جستجوی سراسری رویدادها و کاره…';

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
    return _buildAsyncSearchList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildAsyncSearchList(context);
  }

  Widget _buildAsyncSearchList(BuildContext context) {
    final q = normalizeFa(query.trim());

    if (q.isEmpty) {
      return _buildTodayList(context, q);
    }

    return FutureBuilder<List<CalendarSearchHit>>(
      future: CalendarSearchRepository.instance.search(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final hits = snapshot.data ?? [];
        if (hits.isEmpty) {
          return const Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: Text(
                'هیچ نتیجه‌ای یافت نشد.',
                style: TextStyle(fontFamily: 'Vazirmatn'),
              ),
            ),
          );
        }

        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final todayHits = hits.where((h) => h.dateStr == todayStr).toList();
        final otherHits = hits.where((h) => h.dateStr != todayStr).toList();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: const EdgeInsets.all(CalendarTokens.spacingM),
            children: [
              if (todayHits.isNotEmpty) ...[
                _SearchSectionHeader(
                  title: 'امروز (${toPersianDigits(todayHits.length)})',
                ),
                ...todayHits.map((h) => _HitTile(hit: h, onSelected: close)),
                const SizedBox(height: 12),
              ],
              if (otherHits.isNotEmpty) ...[
                _SearchSectionHeader(
                  title: 'سایر تاریخ‌ها (${toPersianDigits(otherHits.length)})',
                ),
                ...otherHits.map((h) => _HitTile(hit: h, onSelected: close)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayList(BuildContext context, String q) {
    final theme = Theme.of(context);
    final todayResults = q.isEmpty
        ? items
        : items
            .where((i) =>
                normalizeFa(i.title).contains(q) ||
                (i.subtitle != null && normalizeFa(i.subtitle!).contains(q)))
            .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(CalendarTokens.spacingM),
        children: [
          _SearchSectionHeader(
            title: 'برنامه‌های امروز (${toPersianDigits(todayResults.length)})',
          ),
          ...todayResults.map((item) {
            final color = domainColor(context, item.domain);
            final icon = domainIcon(item.domain);
            return ListTile(
              leading: Icon(icon, color: color),
              title: Text(item.title, style: const TextStyle(fontFamily: 'Vazirmatn')),
              subtitle: item.subtitle != null
                  ? Text(item.subtitle!, style: const TextStyle(fontFamily: 'Vazirmatn'))
                  : null,
              onTap: () {
                onItemSelected?.call(item);
                close(context, item);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: CalendarTokens.textSection,
          fontWeight: FontWeight.bold,
          fontFamily: 'Vazirmatn',
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.onSelected});
  final CalendarSearchHit hit;
  final void Function(BuildContext, AgendaItem?) onSelected;

  @override
  Widget build(BuildContext context) {
    final color = domainColor(context, hit.domain);
    final icon = domainIcon(hit.domain);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        hit.title,
        style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${hit.dateStr}${hit.subtitle != null ? ' · ${hit.subtitle}' : ''}',
        style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
      ),
      onTap: () {
        // Construct target item for router
        final item = AgendaItem(
          id: hit.id,
          domain: hit.domain,
          sourceId: hit.sourceId,
          title: hit.title,
          dateStr: hit.dateStr,
          category: Category.personal,
          deepLink: AgendaDeepLink(domain: hit.domain, targetId: hit.sourceId),
        );
        ActionRouter.open(context, item: item);
        onSelected(context, item);
      },
    );
  }
}
