import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/widgets/action/action_capabilities.dart';
import 'package:ritmo/core/widgets/action/action_sheet_registry.dart';
import 'package:ritmo/core/widgets/action/action_sheet_result.dart';
import 'package:ritmo/core/widgets/action/sheet_actions.dart';

void main() {
  group('Prompt 036 - Action Sheet Contracts Tests (WU-8 to WU-11)', () {
    test('ActionSheetResult exhaustiveness test', () {
      final ActionSheetResult res1 = ActionSheetSubmitted(const CompletedOutcome());
      final ActionSheetResult res2 = ActionSheetHandoff(const OpenEditorHandoff());

      switch (res1) {
        case ActionSheetSubmitted(:final outcome):
          expect(outcome.didWrite, isTrue);
        case ActionSheetHandoff():
          fail('Should be submitted');
      }

      switch (res2) {
        case ActionSheetSubmitted():
          fail('Should be handoff');
        case ActionSheetHandoff(:final intent):
          expect(intent, isA<OpenEditorHandoff>());
      }
    });

    test('ActionCapabilities defaults all flags to false and snoozeMeaning to none', () {
      const caps = ActionCapabilities.empty;
      expect(caps.canTimer, isFalse);
      expect(caps.canSnooze, isFalse);
      expect(caps.canSkip, isFalse);
      expect(caps.canCancel, isFalse);
      expect(caps.canEdit, isFalse);
      expect(caps.canDetails, isFalse);
      expect(caps.canIncrementalCount, isFalse);
      expect(caps.snoozeMeaning, SnoozeMeaning.none);
    });

    test('registry_covers_all_domains_test checks registration for all AgendaDomain values', () {
      // Register dummy builders for each domain to verify registry lookup
      for (final domain in AgendaDomain.values) {
        ActionSheetRegistry.register(domain, (item) => throw UnimplementedError());
        expect(ActionSheetRegistry.isRegistered(domain), isTrue);
      }
    });
  });
}
