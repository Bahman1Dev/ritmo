import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class SportsAiBanner extends StatelessWidget {

  const SportsAiBanner({super.key, required this.onOpenChat});
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RitmoHaptics.tap();
        onOpenChat();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xff3B82F6).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مربی هوشمند',
                      style: TextStyle(fontSize: 12, color: Color(0xff3B82F6), fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('نیاز به تغییر برنامه داری؟ بپرس',
                      style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Vazirmatn')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff3B82F6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('چت',
                  style: TextStyle(fontSize: 12, color: Color(0xff60A5FA), fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
