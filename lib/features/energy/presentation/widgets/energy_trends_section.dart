import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';

class EnergyTrendsSection extends StatelessWidget {

  const EnergyTrendsSection({
    super.key,
    required this.energyLogs,
    required this.moodLogs,
    this.dominantMood,
    required this.correlationInsight,
  });
  final List<EnergyLog> energyLogs;
  final List<MoodLog> moodLogs;
  final Mood? dominantMood;
  final String correlationInsight;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();

    // Group last 28 days into 4 weekly averages
    final weeklyAverages = <Map<String, double>>[];
    for (var w = 3; w >= 0; w--) {
      final start = now.subtract(Duration(days: (w + 1) * 7)).millisecondsSinceEpoch;
      final end = now.subtract(Duration(days: w * 7)).millisecondsSinceEpoch;

      final wEnergy = energyLogs.where((l) => l.loggedAt >= start && l.loggedAt < end).toList();
      final wMood = moodLogs.where((l) => l.loggedAt >= start && l.loggedAt < end).toList();

      var avgEnergy = 0.0;
      if (wEnergy.isNotEmpty) {
        avgEnergy = wEnergy.map((l) => l.energyLevel.score.toDouble()).reduce((a, b) => a + b) / wEnergy.length;
      } else {
        avgEnergy = 65.0; // fallback default
      }

      var avgValence = 0.0;
      if (wMood.isNotEmpty) {
        avgValence = wMood.map((l) => l.valence.toDouble()).reduce((a, b) => a + b) / wMood.length;
      } else {
        avgValence = 3.0; // fallback default
      }

      // scale valence 1..5 to 0..100
      var moodPct = ((avgValence - 1.0) / 4.0) * 100.0;
      if (moodPct < 0.0) moodPct = 0.0;

      weeklyAverages.add({
        'energy': avgEnergy,
        'mood': moodPct,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Weekly Averages Simple Bar Chart
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.chart_bar_alt_fill, color: Color(0xffEC4899), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'روند میانگین هفتگی (۴ هفته اخیر)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Bars Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (index) {
                    final data = weeklyAverages[index];
                    final energyHeight = (data['energy']! / 100.0) * 80.0;
                    final moodHeight = (data['mood']! / 100.0) * 80.0;

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Energy Bar (Pink)
                            Container(
                              width: 14,
                              height: energyHeight < 10 ? 10 : energyHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xffEC4899),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Mood Bar (Blue/Teal)
                            Container(
                              width: 14,
                              height: moodHeight < 10 ? 10 : moodHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xff60A5FA),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _toPersianDigits('هفته ${4 - index}'),
                          style: const TextStyle(fontSize: 9, color: Colors.white30, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    );
                  }),
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                
                // Chart Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendDot(const Color(0xffEC4899), 'انرژی فیزیکی'),
                    const SizedBox(width: 24),
                    _buildLegendDot(const Color(0xff60A5FA), 'رضایت ذهنی (خوشایی)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Correlation Analytics Insight Card
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.sparkles, color: Color(0xffEC4899), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'تحلیل همبستگی و بینش زیستی',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Dominant mood row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'حس و حال غالب دورانی:',
                      style: TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Vazirmatn'),
                    ),
                    Text(
                      dominantMood != null ? '${dominantMood!.emoji} ${dominantMood!.label}' : 'ثبت نشده',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 20),
                
                // Correlation text
                Text(
                  _toPersianDigits(correlationInsight),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 9.5, color: Colors.white54, fontFamily: 'Vazirmatn')),
      ],
    );
  }
}
