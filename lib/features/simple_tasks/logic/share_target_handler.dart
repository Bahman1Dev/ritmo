import 'package:flutter/services.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';

class SharedTextData {
  final String rawText;
  final String parsedTitle;
  final int? daysOffset;
  final String? timeStr;

  const SharedTextData({
    required this.rawText,
    required this.parsedTitle,
    this.daysOffset,
    this.timeStr,
  });
}

class ShareTargetHandler {
  static const MethodChannel _channel = MethodChannel('com.ritmo.app/share_target');

  static void init({required void Function(SharedTextData data) onSharedTextReceived}) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments as String?;
        if (text != null && text.trim().isNotEmpty) {
          final trimmed = text.trim();
          final parsed = QuickAddParser.parse(trimmed);

          String? timeStr;
          if (parsed.timeOfDay != null) {
            final hh = parsed.timeOfDay!.hour.toString().padLeft(2, '0');
            final mm = parsed.timeOfDay!.minute.toString().padLeft(2, '0');
            timeStr = '$hh:$mm';
          }

          final data = SharedTextData(
            rawText: trimmed,
            parsedTitle: parsed.title.isNotEmpty ? parsed.title : trimmed,
            daysOffset: parsed.daysOffset,
            timeStr: timeStr,
          );

          onSharedTextReceived(data);
        }
      }
    });
  }
}
