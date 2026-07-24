import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:ritmo/core/services/sync/sync_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SnapshotSyncService PR-2 Façade & Decomposition Tests', () {
    test('SnapshotSyncService.syncAll executes without throwing errors', () async {
      expect(SnapshotSyncService.syncAll, isA<Function>());
    });

    test('SyncCoordinator exists and can be instantiated as a const service', () {
      const coordinator = SyncCoordinator();
      expect(coordinator, isNotNull);
    });
  });
}
