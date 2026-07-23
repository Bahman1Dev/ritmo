import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_continuity_bar.dart';

class ProgressScreen extends StatelessWidget {

  const ProgressScreen({
    super.key,
    required this.currentStreak,
    required this.last7DaysLogged,
    required this.recentFeelingsEmojis,
    required this.readyToProgressExercises,
  });
  final int currentStreak;
  final List<bool> last7DaysLogged;
  final List<String> recentFeelingsEmojis; // e.g. ['🙂', '😌', '😓', '🙂']
  final List<String> readyToProgressExercises;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A110E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.right_chevron, color: Colors.white),
          onPressed: () { RitmoHaptics.tap(); Navigator.pop(context); },
        ),
        title: const Text('پیشرفت شما 📊',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16,
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // استریک
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xff00F5A0).withValues(alpha: 0.2), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xff00F5A0).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('$currentStreak روز پیاپی!',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                            color: Colors.white, fontFamily: 'Vazirmatn')),
                    const SizedBox(height: 4),
                    const Text('تداوم کلید موفقیته، ادامه بده!',
                        style: TextStyle(fontSize: 13, color: Colors.white60, fontFamily: 'Vazirmatn')),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('تداوم هفتگی', style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              SportsContinuityBar(last7DaysLogged: last7DaysLogged),

              const SizedBox(height: 24),
              const Text('روند احساسات اخیر', style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (recentFeelingsEmojis.isEmpty)
                const Text('هنوز دیتای کافی برای نمایش نداریم.', style: TextStyle(fontSize: 13, color: Colors.white38, fontFamily: 'Vazirmatn'))
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: recentFeelingsEmojis.map((e) => Text(e, style: const TextStyle(fontSize: 28))).toList(),
                  ),
                ),

              const SizedBox(height: 32),
              const Text('💪 آماده برای پیشرفت (افزایش وزنه)', style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (readyToProgressExercises.isEmpty)
                const Text('فعلاً با همین برنامه ادامه بده، بدنت داره سازگار میشه.', style: TextStyle(fontSize: 13, color: Colors.white38, fontFamily: 'Vazirmatn'))
              else
                ...readyToProgressExercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xff3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, color: Color(0xff60A5FA), size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(ex, style: const TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'))),
                      ],
                    ),
                  ),
                )),
                
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
