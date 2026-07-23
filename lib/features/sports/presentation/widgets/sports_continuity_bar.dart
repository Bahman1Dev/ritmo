import 'package:flutter/material.dart';

class SportsContinuityBar extends StatelessWidget { // true = logged, false = missed

  const SportsContinuityBar({super.key, required this.last7DaysLogged});
  final List<bool> last7DaysLogged;

  @override
  Widget build(BuildContext context) {
    // اگر لیست کمتر از ۷ روز بود، با false پر می‌کنیم
    final days = List<bool>.from(last7DaysLogged);
    while (days.length < 7) {
      days.insert(0, false);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تداوم ۷ روز گذشته:',
              style: TextStyle(fontSize: 12, color: Colors.white60, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isLogged = days[index];
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLogged ? const Color(0xff00F5A0) : Colors.white.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Icon(
                    isLogged ? Icons.check : Icons.circle,
                    size: 14,
                    color: isLogged ? Colors.black : Colors.transparent,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
