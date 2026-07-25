import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';

void main() {
  group('RegistryEntry ID Format & Reversibility Tests', () {
    test('RegistryEntry ID has domain:sourceId format', () {
      final entry = RegistryEntry(
        id: 'routine:rt_123',
        domain: RegistryDomain.routine,
        sourceId: 'rt_123',
        title: 'مطالعه شبانه',
        scheduleSummary: 'هر روز',
        agendaProxy: AgendaItem(
          id: 'routine:rt_123',
          domain: AgendaDomain.routine,
          sourceId: 'rt_123',
          title: 'مطالعه شبانه',
          dateStr: '2026-07-25',
          category: Category.personal,
        ),
      );

      expect(entry.id, 'routine:rt_123');
      expect(entry.domain, RegistryDomain.routine);
      expect(entry.sourceId, 'rt_123');
    });

    test('System generated worship entries have canArchive == false', () {
      const caps = RegistryCapabilities.systemGenerated();
      expect(caps.canArchive, isFalse);
      expect(caps.canDelete, isFalse);
      expect(caps.canEdit, isFalse);
      expect(caps.canToggleReminder, isTrue);
    });
  });
}
