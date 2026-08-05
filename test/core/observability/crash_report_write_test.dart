import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ritmo/core/observability/privacy_error_sink.dart';
import 'package:ritmo/core/observability/ritmo_logger.dart';

class FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  late Directory tempDir;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePathProvider fakePathProvider;
  late Directory testDocsDir;

  setUp(() async {
    testDocsDir = await Directory.systemTemp.createTemp('crash_test_docs_');
    fakePathProvider = FakePathProvider()..tempDir = testDocsDir;
    PathProviderPlatform.instance = fakePathProvider;
  });

  tearDown(() async {
    if (await testDocsDir.exists()) {
      await testDocsDir.delete(recursive: true);
    }
  });

  group('PrivacyErrorSink Integration Tests', () {
    test('writing error via RitmoLogger creates crash log file on disk', () async {
      RitmoLogger.addSink(PrivacyErrorSink.instance);

      RitmoLogger.error(
        'Test error message for crash report verification',
        error: FormatException('Invalid data format'),
        stack: StackTrace.current,
        context: {'scope': 'TestScope'},
      );

      // Wait briefly for async I/O
      await Future.delayed(const Duration(milliseconds: 300));

      final crashDir = Directory(p.join(testDocsDir.path, 'crash_reports'));
      expect(await crashDir.exists(), true);

      final reports = await PrivacyErrorSink.getCrashReports();
      expect(reports.isNotEmpty, true);

      final logContent = await reports.first.readAsString();
      expect(logContent.contains('Scope: TestScope'), true);
      expect(logContent.contains('FormatException'), true);
    });
  });
}
