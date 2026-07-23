import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Settings Screen Parameter Logic Tests', () {
    test('Default rest duration mapping options', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ss_default_rest_seconds', 45);
      
      final val = prefs.getInt('ss_default_rest_seconds') ?? 90;
      expect(val, equals(45));

      final options = [30, 45, 60, 75, 90, 120];
      expect(options.contains(val), isTrue);
    });

    test('TTS coach sound states configurations', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ss_tts_enabled', false);
      await prefs.setBool('ss_tts_countdown_enabled', false);
      await prefs.setBool('ss_audio_cues_enabled', true);

      expect(prefs.getBool('ss_tts_enabled'), isFalse);
      expect(prefs.getBool('ss_tts_countdown_enabled'), isFalse);
      expect(prefs.getBool('ss_audio_cues_enabled'), isTrue);
    });

    test('Units metric toggle validation', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ss_units_metric', false);

      expect(prefs.getBool('ss_units_metric'), isFalse);
    });
  });
}
