class DayPlanItem {
  DayPlanItem({
    required this.id,
    required this.title,
    required this.domain,
    required this.durationMinutes,
    required this.priority,
    this.isFixedTime = false,
  });

  final String id;
  final String title;
  final String domain;
  final int durationMinutes;
  final int priority; // 1 = Highest
  final bool isFixedTime;
}

class DayPlan {
  DayPlan({required this.items});

  final List<DayPlanItem> items;

  /// Reshuffle non-fixed items according to priority while maintaining fixed items
  DayPlan reshuffle() {
    final fixed = items.where((i) => i.isFixedTime).toList();
    final flex = items.where((i) => !i.isFixedTime).toList();
    flex.sort((a, b) => a.priority.compareTo(b.priority));
    return DayPlan(items: [...fixed, ...flex]);
  }
}
