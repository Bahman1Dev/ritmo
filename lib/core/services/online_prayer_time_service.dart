import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OnlinePrayerTimeService {
  OnlinePrayerTimeService._init();
  static final OnlinePrayerTimeService instance = OnlinePrayerTimeService._init();

  /// Fetches prayer times from Aladhan API using Method 7 (Institute of Geophysics, University of Tehran).
  /// Returns a Map of time keys to 'HH:mm' strings, or null if network/API fails.
  Future<Map<String, String>?> fetchPrayerTimesFromApi({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    try {
      final timestamp = date.millisecondsSinceEpoch ~/ 1000;
      // Method 7 = Institute of Geophysics, University of Tehran (موسسه ژئوفیزیک دانشگاه تهران)
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$timestamp?latitude=$latitude&longitude=$longitude&method=7',
      );

      final response = await http.get(url).timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body) as Map<String, dynamic>;
        if (jsonMap['code'] == 200 && jsonMap['data'] != null) {
          final timings = jsonMap['data']['timings'] as Map<String, dynamic>?;
          if (timings != null) {
            final fajr = _cleanTime(timings['Fajr'] as String?);
            final sunrise = _cleanTime(timings['Sunrise'] as String?);
            final dhuhr = _cleanTime(timings['Dhuhr'] as String?);
            final asr = _cleanTime(timings['Asr'] as String?);
            final sunset = _cleanTime(timings['Sunset'] as String?);
            final maghrib = _cleanTime(timings['Maghrib'] as String?);
            final isha = _cleanTime(timings['Isha'] as String?);
            final midnight = _cleanTime(timings['Midnight'] as String?);

            if (fajr != null && dhuhr != null && maghrib != null) {
              return {
                'fajr': fajr,
                'sunrise': sunrise ?? fajr,
                'dhuhr': dhuhr,
                'asr': asr ?? dhuhr,
                'sunset': sunset ?? maghrib,
                'maghrib': maghrib,
                'isha': isha ?? maghrib,
                'midnightShari': midnight ?? '00:00',
              };
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OnlinePrayerTimeService error / offline: $e');
    }
    return null; // Return null so caller seamlessly falls back to offline calculation
  }

  String? _cleanTime(String? input) {
    if (input == null || input.isEmpty) return null;
    // API returns "HH:mm (EST)" -> extract "HH:mm"
    final clean = input.split(' ').first;
    final parts = clean.split(':');
    if (parts.length >= 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return '$h:$m';
    }
    return null;
  }
}
