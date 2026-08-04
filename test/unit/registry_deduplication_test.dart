import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/domain/registry_query.dart';
import 'package:ritmo/features/registry/logic/registry_index.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Registry Deduplication Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      RegistryIndex.instance.invalidate();
    });

    test('queryPhaseA returns unique items and filters out duplicates by title and sourceId', () async {
      final items = await RegistryIndex.instance.queryPhaseA(
        const RegistryQuery(),
        {},
      );

      final seenIds = <String>{};
      final seenSourceIds = <String>{};
      final seenTitles = <String>{};

      for (final item in items) {
        expect(seenIds.contains(item.id), isFalse, reason: 'Duplicate item ID: ${item.id}');
        if (item.sourceId.isNotEmpty) {
          expect(seenSourceIds.contains(item.sourceId), isFalse, reason: 'Duplicate sourceId: ${item.sourceId}');
          seenSourceIds.add(item.sourceId);
        }
        final normalizedTitle = item.title.trim().toLowerCase();
        if (normalizedTitle.isNotEmpty) {
          expect(seenTitles.contains(normalizedTitle), isFalse, reason: 'Duplicate title: ${item.title}');
          seenTitles.add(normalizedTitle);
        }
        seenIds.add(item.id);
      }
    });
  });
}
