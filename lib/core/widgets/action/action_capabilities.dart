/// Meaning of snooze capability for a domain.
enum SnoozeMeaning {
  none,
  normal,
  qada,
}

/// Declarative capabilities supported by a specific domain ActionBody.
class ActionCapabilities {
  final List<String> variants;
  final bool canTimer;
  final bool canSnooze;
  final bool canSkip;
  final bool canCancel;
  final bool canEdit;
  final bool canDetails;
  final bool canIncrementalCount;
  final SnoozeMeaning snoozeMeaning;

  const ActionCapabilities({
    this.variants = const [],
    this.canTimer = false,
    this.canSnooze = false,
    this.canSkip = false,
    this.canCancel = false,
    this.canEdit = false,
    this.canDetails = false,
    this.canIncrementalCount = false,
    this.snoozeMeaning = SnoozeMeaning.none,
  });

  static const ActionCapabilities empty = ActionCapabilities();

  /// Indicates if this action is simple (no variants, timer, or count selection).
  bool get isSimple => variants.isEmpty && !canTimer && !canIncrementalCount;
}
