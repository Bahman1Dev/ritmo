import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/services/motivation_diagnosis_service.dart';
import 'package:ritmo/core/services/open_loop_capture_service.dart';

void main() {
  group('Prompt 059 Services Unit Tests', () {
    test('MotivationDiagnosisService: parses skip reasons correctly', () {
      final service = MotivationDiagnosisService.instance;
      expect(service.parseReason('TIRED'), equals(SkipReasonType.tired));
      expect(service.parseReason('NO_START_POINT'), equals(SkipReasonType.noStartPoint));
      expect(service.parseReason('TOO_BIG'), equals(SkipReasonType.tooBig));
      expect(service.parseReason('NOT_IN_MOOD'), equals(SkipReasonType.notInMood));
      expect(service.parseReason('FORGOT'), equals(SkipReasonType.forgot));
      expect(service.parseReason('EXTERNAL'), equals(SkipReasonType.external));
    });

    test('MotivationDiagnosisService: EXTERNAL reason returns non-failure action', () {
      final service = MotivationDiagnosisService.instance;
      final action = service.getActionForReason(SkipReasonType.external);
      expect(action['actionType'], equals('NONE_PRESERVE_STREAK'));
      expect(action['title'], contains('حفظ زنجیره'));
    });

    test('MotivationDiagnosisService: TOO_BIG reason returns breakdown wizard action', () {
      final service = MotivationDiagnosisService.instance;
      final action = service.getActionForReason(SkipReasonType.tooBig);
      expect(action['actionType'], equals('BREAK_DOWN_WIZARD'));
    });

    test('OpenLoopCaptureService: OpenLoopDecision mapping', () {
      expect(OpenLoopDecision.doNow.name, equals('doNow'));
      expect(OpenLoopDecision.schedule.name, equals('schedule'));
      expect(OpenLoopDecision.drop.name, equals('drop'));
    });
  });
}
