import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class SessionSummaryScreen extends StatelessWidget {

  const SessionSummaryScreen({
    super.key,
    required this.minutesElapsed,
    required this.exercisesCompleted,
    required this.overallFeelingEmoji,
    required this.newStreak,
  });
  final int minutesElapsed;
  final int exercisesCompleted;
  final String overallFeelingEmoji;
  final int newStreak;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A110E),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // آیکون و عنوان
                const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'خسته نباشی دلاور!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'یه قدم دیگه به هدفت نزدیک‌تر شدی.',
                  style: TextStyle(fontSize: 14, color: Colors.white54, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),

                // آمار
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('⏱️ زمان تمرین:', '$minutesElapsed دقیقه'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildStatRow('🏋️ حرکات انجام شده:', '$exercisesCompleted حرکت'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildStatRow('📊 احساس کلی:', overallFeelingEmoji),
                      const Divider(color: Colors.white12, height: 24),
                      _buildStatRow('🔥 تداوم (استریک):', '$newStreak روز پیاپی', highlight: true),
                    ],
                  ),
                ),

                const Spacer(),
                const Spacer(),

                // دکمه بازگشت
                ElevatedButton(
                  onPressed: () {
                    RitmoHaptics.success();
                    // حذف تمام صفحات قبلی و برگشت به خانه
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00F5A0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('بازگشت به خانه',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 14, fontFamily: 'Vazirmatn')),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xff00F5A0) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }
}
