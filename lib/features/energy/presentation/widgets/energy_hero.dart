import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';

class EnergyHero extends StatelessWidget {

  const EnergyHero({
    super.key,
    required this.currentEnergy,
    required this.explanations,
    this.latestMoodLog,
    required this.onQuickLogTap,
  });
  final double currentEnergy;
  final List<String> explanations;
  final MoodLog? latestMoodLog;
  final VoidCallback onQuickLogTap;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine current mood text
    final moodText = latestMoodLog != null
        ? '${latestMoodLog!.mood.emoji} ${latestMoodLog!.mood.label}'
        : 'ثبت نشده';

    // Color theme pink identity
    const pinkColor = Color(0xffEC4899);

    return RitmoTheme.glassCardLight(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Symmetrical orb representing dynamic energy
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 130,
                  width: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        pinkColor.withValues(alpha: 0.25),
                        pinkColor.withValues(alpha: 0.02),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pinkColor.withValues(alpha: 0.12),
                        blurRadius: 25,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                ),
                Container(
                  height: 105,
                  width: 105,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff141221).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: pinkColor.withValues(alpha: 0.4), width: 2.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'انرژی پویا',
                          style: TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            Text(
                              _toPersianDigits(currentEnergy.toInt().toString()),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const Text(
                              '٪',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: pinkColor,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Latest Mood
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'احوال روحی اخیر: ',
                    style: TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Vazirmatn'),
                  ),
                  Text(
                    moodText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Log Button
            SizedBox(
              width: 160,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pinkColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onQuickLogTap,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'الان چطورم؟',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
              ),
            ),

            // Why this number explanations
            if (explanations.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '💡 چرا این عدد؟ (عوامل سازنده انرژی پویا)',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white70, fontFamily: 'Vazirmatn'),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: explanations.map((exp) {
                  // Style based on positive/negative/base
                  var chipBg = Colors.white.withValues(alpha: 0.02);
                  var chipText = Colors.white70;
                  var borderCol = Colors.white.withValues(alpha: 0.05);

                  if (exp.contains('+')) {
                    chipBg = Colors.green.withValues(alpha: 0.05);
                    chipText = Colors.greenAccent;
                    borderCol = Colors.green.withValues(alpha: 0.15);
                  } else if (exp.contains('-')) {
                    chipBg = Colors.red.withValues(alpha: 0.05);
                    chipText = const Color(0xffF43F5E);
                    borderCol = Colors.red.withValues(alpha: 0.15);
                  } else if (exp.contains('ثبت دستی')) {
                    chipBg = pinkColor.withValues(alpha: 0.06);
                    chipText = const Color(0xffFDA4AF);
                    borderCol = pinkColor.withValues(alpha: 0.15);
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderCol),
                    ),
                    child: Text(
                      _toPersianDigits(exp),
                      style: TextStyle(fontSize: 9.5, color: chipText, fontFamily: 'Vazirmatn'),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
