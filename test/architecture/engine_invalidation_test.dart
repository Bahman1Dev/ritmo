import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/engine_invalidation_policy.dart';
import 'package:ritmo/core/domain/engines/engine_invalidation_tag.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

void main() {
  test('A. every event type has exactly one policy entry', () {
    expect(
      EngineInvalidationPolicy.eventTags.keys.toSet(),
      equals(RitmoEventType.values.toSet()),
    );
  });

  test('B. every tag has at least one producing event', () {
    final produced = EngineInvalidationPolicy.eventTags.values
        .expand((s) => s)
        .toSet();
    final orphans = EngineInvalidationTag.values.toSet().difference(produced);
    expect(orphans, isEmpty, reason: 'Tags nobody fires: $orphans');
  });

  test('C. every tag has at least one consuming engine', () {
    final consumed = EngineInvalidationPolicy.engineTags.values
        .expand((s) => s)
        .toSet();
    final unused = EngineInvalidationTag.values.toSet().difference(consumed);
    expect(unused, isEmpty, reason: 'Tags no engine listens to: $unused');
  });
}
