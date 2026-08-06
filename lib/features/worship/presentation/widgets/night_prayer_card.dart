// lib/features/worship/presentation/widgets/night_prayer_card.dart
// Night Prayer Ritual ("نماز شب به عنوان آیین شبانه") — Section 5 New Feature #3 (F-3)
// Dynamic card that appears after Shari Midnight (W-5) with 11-rak'ah stepper
// (8 Rak'ah Nafilat al-Layl + 2 Rak'ah Shaf' + 1 Rak'ah Witr).

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';

class NightPrayerCard extends StatefulWidget {
  const NightPrayerCard({
    super.key,
    required this.day,
    required this.onComplete,
  });

  final WorshipDay day;
  final VoidCallback onComplete;

  @override
  State<NightPrayerCard> createState() => _NightPrayerCardState();
}

class _NightPrayerCardState extends State<NightPrayerCard> {
  int _currentRakah = 0; // 0 to 11

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final midnight = widget.day.times.midnightShari;
    final fajr = widget.day.times.fajr;

    // Is it night time (after midnight or before fajr)?
    final isNightTime = now.isAfter(midnight) || now.isBefore(fajr);

    if (!isNightTime) {
      return const SizedBox.shrink(); // Hide during day
    }

    final isCompleted = _currentRakah >= 11;
    final progress = (_currentRakah / 11).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF1E1E38), // Night sky theme
            const Color(0xFF121224),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.moon_stars_fill,
                    size: 20,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'آیین نماز شب (نافله شب)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '۱۱ رکعت',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'وَمِنَ اللَّيْلِ فَتَهَجَّدْ بِهِ نَافِلَةً لَكَ عَسَىٰ أَنْ يَبْعَثَكَ رَبُّكَ مَقَامًا مَحْمُودًا',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Stepper Counter Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rakahStageText(_currentRakah),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_currentRakah از ۱۱ رکعت خوانده شده',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Row(
                children: [
                  if (_currentRakah > 0)
                    IconButton(
                      icon: const Icon(CupertinoIcons.minus_circle, color: Colors.white70),
                      onPressed: () {
                        unawaited(HapticFeedback.lightImpact());
                        setState(() {
                          _currentRakah--;
                        });
                      },
                    ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      unawaited(HapticFeedback.mediumImpact());
                      if (_currentRakah < 11) {
                        setState(() {
                          _currentRakah += 2; // Step 2 rak'ahs
                          if (_currentRakah > 11) _currentRakah = 11;
                        });
                        if (_currentRakah >= 11) {
                          widget.onComplete();
                        }
                      }
                    },
                    child: Text(
                      isCompleted ? 'تکمیل شد 🎉' : '+ ۲ رکعت',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  String _rakahStageText(int count) {
    if (count < 8) return '۸ رکعت نافله شب (۴ نماز ۲ رکعتی)';
    if (count < 10) return '۲ رکعت نماز شفع';
    if (count == 10) return '۱ رکعت نماز وتر';
    return 'پایان نماز شب — قبول باشد 🤲';
  }
}
