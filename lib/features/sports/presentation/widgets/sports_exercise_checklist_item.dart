import 'package:flutter/material.dart';
import 'package:ritmo/features/sports/models/sports_models.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';

class SportsExerciseChecklistItem extends StatelessWidget {

  const SportsExerciseChecklistItem({
    super.key,
    required this.entry,
    required this.onMarkDone,
    required this.onSwap,
  });
  final ExerciseChecklistEntry entry;
  final VoidCallback onMarkDone;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final isDone = entry.status == 'DONE';
    final isCurrent = entry.status == 'CURRENT';

    // رنگ‌ها و استایل‌ها بر اساس وضعیت
    final bgColor = isDone
        ? Colors.white.withValues(alpha: 0.02)
        : isCurrent
            ? const Color(0xff00F5A0).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05);

    final borderColor = isDone
        ? Colors.transparent
        : isCurrent
            ? const Color(0xff00F5A0).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08);

    final titleColor = isDone
        ? Colors.white38
        : isCurrent
            ? const Color(0xff00F5A0)
            : Colors.white;

    final subColor = isDone ? Colors.white24 : Colors.white54;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // آیکون وضعیت
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? Colors.white12
                      : isCurrent
                          ? const Color(0xff00F5A0)
                          : Colors.white.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(
                    isDone ? Icons.check : Icons.circle,
                    size: isDone ? 14 : 8,
                    color: isDone
                        ? Colors.white38
                        : isCurrent
                            ? Colors.black
                            : Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 15,
                    color: titleColor,
                    fontFamily: 'Vazirmatn',
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isDone && entry.feeling != null)
                Text(
                  _getFeelingEmoji(entry.feeling!),
                  style: const TextStyle(fontSize: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 36), // هم‌راستا با متن
            child: Text(
              _buildReferenceText(),
              style: TextStyle(
                fontSize: 12,
                color: subColor,
                fontFamily: 'Vazirmatn',
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          
          // دکمه‌ها فقط در حالت CURRENT نمایش داده می‌شوند
          if (isCurrent) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      RitmoHaptics.success();
                      onMarkDone();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00F5A0),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('انجام شد ✓',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    RitmoHaptics.tap();
                    onSwap();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('جایگزین کن',
                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _buildReferenceText() {
    var text = '${entry.referenceSets} ست × ${entry.referenceReps} تکرار';
    if (entry.referenceWeight != null && entry.referenceWeight! > 0) {
      // حذف صفرهای اضافی اعشار
      final w = entry.referenceWeight!.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');
      text += ' × $w کیلو';
    }
    return text;
  }

  String _getFeelingEmoji(Feeling feeling) {
    switch (feeling) {
      case Feeling.easy: return '😌';
      case Feeling.good: return '🙂';
      case Feeling.hard: return '😓';
    }
  }
}
