import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';

/// کارت «امروز چی کار کنم؟» — مهم‌ترین کارت صفحه ورزش
class SportsTodayWorkoutCard extends StatefulWidget {

  const SportsTodayWorkoutCard({
    super.key,
    required this.suggestion,
    required this.isTodayLogged,
    required this.onLog,
    required this.onEditSplit,
    required this.onCantToday,
  });
  final TodayWorkoutSuggestion suggestion;
  final bool isTodayLogged;
  final VoidCallback onLog;
  final VoidCallback onEditSplit;
  final VoidCallback onCantToday;

  @override
  State<SportsTodayWorkoutCard> createState() => _SportsTodayWorkoutCardState();
}

class _SportsTodayWorkoutCardState extends State<SportsTodayWorkoutCard> {
  late WorkoutTier _selectedTier;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.suggestion.suggestedTier;
  }

  @override
  void didUpdateWidget(SportsTodayWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestion.suggestedTier != widget.suggestion.suggestedTier) {
      _selectedTier = widget.suggestion.suggestedTier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;

    // حالت هیچ برنامه‌ای
    if (s.hasNoPlan) {
      return _buildNoPlanCard();
    }

    // حالت روز استراحت
    if (s.isRest) {
      return _buildRestCard(s);
    }

    // حالت روز تمرین
    return _buildWorkoutCard(s);
  }

  Widget _buildNoPlanCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Text('🗓️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('هنوز برنامه هفتگی نداری',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                  color: Colors.white, fontFamily: 'Vazirmatn'),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('از بخش «برنامه» روزهای هر گروه عضله رو تنظیم کن',
              style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn'),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.onEditSplit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff00F5A0),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('ساختن برنامه هفتگی',
                style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRestCard(TodayWorkoutSuggestion s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff64748B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xff64748B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Text('😴', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const Text('امروز: استراحت',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: Colors.white, fontFamily: 'Vazirmatn')),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xff64748B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('ریکاوری',
                  style: TextStyle(fontSize: 11, color: Color(0xff94A3B8),
                      fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 14),
          const Text('کشش‌های پیشنهادی:',
              style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: s.exercises.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(e, style: const TextStyle(fontSize: 11.5,
                  color: Colors.white60, fontFamily: 'Vazirmatn')),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(TodayWorkoutSuggestion s) {
    final accentColor = s.groups.isNotEmpty ? s.groups.first.color : const Color(0xff00F5A0);
    final isLogged = widget.isTodayLogged;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عنوان + badge
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('امروز:',
                    style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 4),
                Text(
                  s.groups.map((g) => '${g.emoji} ${g.label}').join('  '),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: Colors.white, fontFamily: 'Vazirmatn'),
                ),
              ]),
            ),
            if (isLogged)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xff00F5A0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('✓ ثبت شد',
                    style: TextStyle(fontSize: 11, color: Color(0xff00F5A0),
                        fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 14),

          // دلیل نسخه پیشنهادی
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(s.reason,
                style: const TextStyle(fontSize: 12, color: Colors.white60,
                    fontFamily: 'Vazirmatn')),
          ),
          const SizedBox(height: 14),

          // سه تیر نسخه
          const Text('نسخه تمرین امروز:',
              style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 8),
          Row(children: WorkoutTier.values.map((t) {
            final isSelected = _selectedTier == t;
            final isSuggested = t == s.suggestedTier;
            return Expanded(
              child: GestureDetector(
                onTap: () { RitmoHaptics.tap(); setState(() => _selectedTier = t); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? t.color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? t.color : Colors.white.withValues(alpha: 0.07),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Text(t.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontFamily: 'Vazirmatn',
                            color: isSelected ? t.color : Colors.white38,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    if (isSuggested)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('پیشنهاد',
                            style: TextStyle(fontSize: 9, color: t.color,
                                fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                      ),
                  ]),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 6),
          Text(_selectedTier.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: _selectedTier.color.withValues(alpha: 0.7),
                  fontFamily: 'Vazirmatn')),
          const SizedBox(height: 14),

          // حرکات پیشنهادی
          const Text('حرکات پیشنهادی:',
              style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: s.exercises.take(8).map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.15)),
              ),
              child: Text(e, style: TextStyle(fontSize: 11.5,
                  color: accentColor.withValues(alpha: 0.85), fontFamily: 'Vazirmatn')),
            )).toList(),
          ),
          const SizedBox(height: 18),

          // دکمه ثبت
          ElevatedButton(
            onPressed: widget.onLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLogged ? Colors.white12 : accentColor,
              foregroundColor: isLogged ? Colors.white60 : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              isLogged ? '✓ تمرین ثبت شد — ثبت مجدد' : 'ثبت تمرین امروز ⚡',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          
          if (!isLogged) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onCantToday,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('امروز نمی‌تونم 😓', 
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
