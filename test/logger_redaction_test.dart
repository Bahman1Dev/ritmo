import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' hide equals;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/observability/privacy_error_sink.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  MockPathProviderPlatform(this.testDir);
  final Directory testDir;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return testDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('privacy_sink_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PrivacyErrorSink Unit Tests', () {
    test('sanitize scrubs all Persian characters from strings and stacktraces', () {
      const rawError = 'DatabaseException(اطلاعات شخصی کاربر در ثبت رکورد عبادتی)';
      final clean = PrivacyErrorSink.sanitize(rawError);
      expect(clean.contains('اطلاعات'), isFalse);
      expect(clean.contains('کاربر'), isFalse);
      expect(clean.contains('[REDACTED_TEXT]'), isTrue);
    });

    test('writes sanitized crash report file to disk', () async {
      await PrivacyErrorSink.instance.logError(
        'TestScope',
        'پیام تست شخصی که نباید لیکی داشته باشد',
        ArgumentError('خطای ورودی'),
        StackTrace.current,
      );

      final reports = await PrivacyErrorSink.getCrashReports();
      expect(reports.length, equals(1));

      final content = await reports.first.readAsString();
      expect(content.contains('TestScope'), isTrue);
      expect(content.contains('ArgumentError'), isTrue);
      expect(content.contains('پیام تست'), isFalse);
      expect(content.contains('خطای ورودی'), isFalse);
    });

    test('rotates and prunes files when exceeding max limit of 20', () async {
      final crashDir = Directory(join(tempDir.path, 'crash_reports'));
      await crashDir.create(recursive: true);

      for (var i = 0; i < 22; i++) {
        final f = File(join(crashDir.path, 'crash_100$i.log'));
        await f.writeAsString('Log entry $i');
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final initialFiles = await PrivacyErrorSink.getCrashReports();
      expect(initialFiles.length, equals(22));

      await PrivacyErrorSink.instance.logError('Scope', 'Msg', FormatException('Err'));

      final rotatedFiles = await PrivacyErrorSink.getCrashReports();
      expect(rotatedFiles.length, lessThanOrEqualTo(20));
    });

    test('verifies RitmoLog.error pipeline correctly forwards to PrivacyErrorSink and creates log file', () async {
      RitmoLog.addSink(PrivacyErrorSink.instance);

      RitmoLog.error(
        'PipelineScope',
        'پیام ثبت ریتمو لاگ',
        StateError('حالت نامعتبر'),
        StackTrace.current,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final reports = await PrivacyErrorSink.getCrashReports();
      expect(reports.isNotEmpty, isTrue);

      final content = await reports.first.readAsString();
      expect(content.contains('PipelineScope'), isTrue);
      expect(content.contains('StateError'), isTrue);
      expect(content.contains('پیام ثبت ریتمو لاگ'), isFalse);
      expect(content.contains('[REDACTED_TEXT]'), isTrue);
    });
  });
}
