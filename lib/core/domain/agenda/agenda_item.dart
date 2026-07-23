import 'package:ritmo/core/domain/models.dart';

/// The domain a single agenda item belongs to.
///
/// Every cross-section "thing that happens on a day" is normalized into an
/// [AgendaItem] tagged with one of these domains, so Home and Calendar can
/// both render from the same source.
enum AgendaDomain {
  routine,
  prayer,
  mustahab,
  course,
  goalStep,
  konkur,
  cycle,
  worshipDebt,
}

/// Completion / lifecycle state of an agenda item for its date.
///
/// Historical prayer/worship completion in the past is treated as
/// [AgendaCompletion.none] (unknown) — only today carries a real status.
enum AgendaCompletion {
  none,
  pending,
  done,
  partial,
  skipped,
  overdue,
  missed,
}

/// A lightweight pointer that lets the UI deep-link into the owning section
/// for a given agenda item.
class AgendaDeepLink {

  const AgendaDeepLink({
    required this.domain,
    required this.targetId,
  });
  final AgendaDomain domain;
  final String targetId;
}

/// The single normalized unit of "something on a day".
///
/// Produced by `DayAgendaService` from each domain's own repo/engine and
/// consumed by both the Home dashboard and the Calendar. For routines, the
/// raw routine/schedule maps are preserved in [meta] under `'routine'` /
/// `'schedule'` so the existing `RoutineCard` and conflict logic keep working
/// without a rewrite.
class AgendaItem {

  const AgendaItem({
    required this.id,
    required this.domain,
    required this.sourceId,
    required this.title,
    this.subtitle,
    required this.dateStr,
    this.timeOfDay,
    this.durationMinutes,
    required this.category,
    this.completion = AgendaCompletion.none,
    this.priority = 1.0,
    this.isEssential = false,
    required this.deepLink,
    this.windowStart,
    this.windowEnd,
    this.meta = const {},
  });
  /// Domain-prefixed unique id, e.g. `"course:<sessionId>"`.
  final String id;

  final AgendaDomain domain;

  /// Id of the underlying source row (sessionId, stepId, practiceId, ...).
  final String sourceId;

  final String title;
  final String? subtitle;

  /// Date string in `YYYY-MM-DD`.
  final String dateStr;

  /// Time of day in `HH:mm` (includes resolved prayer anchor time). Null = untimed.
  final String? timeOfDay;

  final int? durationMinutes;

  /// Reused `Category` for color/icon parity with the rest of the app.
  final Category category;

  final AgendaCompletion completion;

  /// Sort/importance weight (timed items sort by time, untimed by priority).
  final double priority;

  final bool isEssential;

  final AgendaDeepLink deepLink;

  /// Window boundaries for time-boxed items (e.g. prayers: fajr to sunrise).
  final DateTime? windowStart;
  final DateTime? windowEnd;

  /// Domain-specific extras. For routines: `meta['routine']` = raw routine map,
  /// `meta['schedule']` = raw schedule map.
  final Map<String, dynamic> meta;

  bool get isTimed => timeOfDay != null && timeOfDay!.isNotEmpty;

  bool get isCompleted =>
      completion == AgendaCompletion.done ||
      completion == AgendaCompletion.partial;
}

/// Options controlling how a day's agenda is assembled.
class AgendaQueryOptions {

  const AgendaQueryOptions({
    this.includeCompleted = true,
    this.domains = const {},
  });
  /// Whether to include items that are already completed (Calendar: true,
  /// Home pending-lists: false).
  final bool includeCompleted;

  /// If non-empty, restrict collection to these domains only.
  final Set<AgendaDomain> domains;

  bool wants(AgendaDomain domain) => domains.isEmpty || domains.contains(domain);
}

/// The assembled agenda for a single day.
class DayAgenda {

  const DayAgenda({
    required this.dateStr,
    required this.items,
    this.rhythmScore = 0,
    this.enabledDomains = const {},
  });
  final String dateStr;
  final List<AgendaItem> items;
  final int rhythmScore;

  /// Which domains were actually enabled (module-gated / consented) for this day.
  final Map<AgendaDomain, bool> enabledDomains;

  List<AgendaItem> itemsForDomain(AgendaDomain domain) =>
      items.where((i) => i.domain == domain).toList();

  static DayAgenda empty(String dateStr) =>
      DayAgenda(dateStr: dateStr, items: const []);
}
