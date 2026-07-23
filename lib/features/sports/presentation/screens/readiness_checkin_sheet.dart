// lib/features/sports/presentation/screens/readiness_checkin_sheet.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

/// شیت چک‌این صبحگاهی
class ReadinessCheckinSheet extends StatefulWidget {
  const ReadinessCheckinSheet({super.key});

  @override
  State<ReadinessCheckinSheet> createState() => _ReadinessCheckinSheetState();
}

class _ReadinessCheckinSheetState extends State<ReadinessCheckinSheet> {
  int sleepHours = 7;
  int sleepMin = 30;
  int sleepQuality = 4;
  int? hrv;
  int? restingHr;
  int soreness = 2;
  int fatigue = 1;
  int mood = 4;
  bool menstrual = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'چک‌این صبحگاهی 🌅',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'چند دقیقه وقت بذار تا برنامه‌ات به‌روز بشه',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 20),
          _buildSlider(
            'خواب 😴',
            '$sleepHoursس $sleepMinد',
            0,
            12 * 60,
            sleepHours * 60 + sleepMin,
            (v) {
              setState(() {
                sleepHours = v ~/ 60;
                sleepMin = v % 60;
              });
            },
            divisions: 12 * 2,
          ),
          _buildStepper(
            'کیفیت خواب ★',
            sleepQuality,
            1,
            5,
            (v) => setState(() => sleepQuality = v),
          ),
          _buildOptionalInt(
            'HRV (ms)',
            hrv,
            (v) => setState(() => hrv = v),
          ),
          _buildOptionalInt(
            'نبض صبح (bpm)',
            restingHr,
            (v) => setState(() => restingHr = v),
          ),
          _buildStepper(
            'کوفتی عضله 😣',
            soreness,
            0,
            10,
            (v) => setState(() => soreness = v),
          ),
          _buildStepper(
            'خستگی 😴',
            fatigue,
            0,
            10,
            (v) => setState(() => fatigue = v),
          ),
          _buildStepper(
            'حال و هوا 😊',
            mood,
            1,
            5,
            (v) => setState(() => mood = v),
          ),
          SwitchListTile(
            value: menstrual,
            onChanged: (v) => setState(() => menstrual = v),
            activeThumbColor: RitmoTheme.accent,
            title: const Text(
              'فاز قاعدگی 💜',
              style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'),
            ),
            subtitle: const Text(
              'اگر در فاز قاعدگی هستی، نسخه سبک‌تر پیشنهاد میشه',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: RitmoTheme.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'تایید و محاسبه آمادگی ⚡',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    String value,
    int min,
    int max,
    int current,
    ValueChanged<int> onChanged, {
    int divisions = 10,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: RitmoTheme.accent,
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Slider(
            value: current.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            activeColor: RitmoTheme.accent,
            inactiveColor: Colors.white12,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Vazirmatn',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed:
                    value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white54,
                  size: 24,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: RitmoTheme.accent,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalInt(
    String label,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    final ctrl = TextEditingController(text: value?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white54,
            fontFamily: 'Vazirmatn',
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: RitmoTheme.accent),
          ),
        ),
        onChanged: (v) => onChanged(int.tryParse(v)),
      ),
    );
  }
}
