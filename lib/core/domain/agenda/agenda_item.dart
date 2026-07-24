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
  sport,
  medicine,
}

/// Explicit classification of an agenda item's scheduling constraints.
enum AgendaItemType {
  fixed,
  flexible,
  floating,
  optional,
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

  AgendaItem({
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
    AgendaItemType? itemType,
  }) : itemType = itemType ??
            ((timeOfDay != null && timeOfDay.isNotEmpty) || isEssential
                ? AgendaItemType.fixed
                : AgendaItemType.flexible);

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

  final AgendaItemType itemType;

  bool get hasValidTimeOfDay {
    final value = timeOfDay?.trim();
    if (value == null || value.isEmpty) return false;

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) return false;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return false;

    return hour >= 0 && hour < 24 && minute >= 0 && minute < 60;
  }

  bool get isTimed => hasValidTimeOfDay;

  bool get isAllDay => !isTimed;

  bool get isFixed => itemType == AgendaItemType.fixed;

  bool get isFlexible => itemType == AgendaItemType.flexible;

  bool get isFloating => itemType == AgendaItemType.floating;

  bool get isOptional => itemType == AgendaItemType.optional;

  bool get isOvernight {
    if (!isTimed) return false;
    final parts = timeOfDay!.split(':');
    if (parts.length != 2) return false;
    final startH = int.tryParse(parts[0]) ?? 0;
    final startM = int.tryParse(parts[1]) ?? 0;
    final dur = durationMinutes ?? 0;
    final totalEndMinutes = (startH * 60) + startM + dur;
    if (totalEndMinutes >= 1440) return true;

    if (windowStart != null && windowEnd != null) {
      if (windowEnd!.day != windowStart!.day) return true;
    }
    return false;
  }

  bool get isCompleted =>
      completion == AgendaCompletion.done ||
      completion == AgendaCompletion.partial;
}

/// Options controlling how a day's agenda is assembled.
class AgendaQueryOptions {

  const AgendaQueryOptions({
    this.includeCompleted = true,
    this.domains = const {},
    this.includeWorshipDebt = false,
  });
  /// Whether to include items that are already completed (Calendar: true,
  /// Home pending-lists: false).
  final bool includeCompleted;

  /// If non-empty, restrict collection to these domains only.
  final Set<AgendaDomain> domains;

  /// Explicit policy flag: whether to include worship debt items (default: false).
  final bool includeWorshipDebt;

  bool wants(AgendaDomain domain) {
    if (domain == AgendaDomain.worshipDebt && !includeWorshipDebt) {
      return false;
    }
    return domains.isEmpty || domains.contains(domain);
  }
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
