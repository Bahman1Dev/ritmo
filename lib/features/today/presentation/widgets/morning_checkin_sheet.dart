import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:sqflite/sqflite.dart';

/// Modal bottom sheet for morning mood & energy check-in.
class MorningCheckinSheet extends StatefulWidget {

  /// Constructs a [MorningCheckinSheet].
  const MorningCheckinSheet({required this.onSaved, super.key});
  /// Callback triggered when the check-in is saved.
  final VoidCallback onSaved;

  @override
  State<MorningCheckinSheet> createState() => _MorningCheckinSheetState();
}

class _MorningCheckinSheetState extends State<MorningCheckinSheet> {
  String _selectedMood = 'NORMAL';
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _moods = [
    {
      'key': 'TIRED',
      'label': 'خسته و بی‌انرژی',
      'icon': CupertinoIcons.clear_circled_solid,
      'color': Colors.redAccent,
      'energy': 'LOW',
    },
    {
      'key': 'NORMAL',
      'label': 'عادی و آرام',
      'icon': CupertinoIcons.checkmark_circle,
      'color': Colors.blueAccent,
      'energy': 'MEDIUM',
    },
    {
      'key': 'GOOD',
      'label': 'پرانرژی و خوب',
      'icon': CupertinoIcons.checkmark_circle_fill,
      'color': Colors.greenAccent,
      'energy': 'HIGH',
    },
    {
      'key': 'GREAT',
      'label': 'بسیار عالی و فوق‌العاده',
      'icon': CupertinoIcons.star_circle_fill,
      'color': Colors.amber,
      'energy': 'HIGH',
    },
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveCheckin() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Perform Upsert on daily_checkins (Using INSERT OR REPLACE)
      await db.insert(
        'daily_checkins',
        {
          'id': 'checkin_$todayStr',
          'date': todayStr,
          'mood': _selectedMood,
          'note':
              _noteController.text.isNotEmpty ? _noteController.text : null,
          'createdAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Map mood to energy level and log it in energy_logs
      final moodItem = _moods.firstWhere((m) => m['key'] == _selectedMood);
      final energyLevel = moodItem['energy'] as String;

      await db.insert(
        'energy_logs',
        {
          'id': 'energy_$nowMs',
          'energyLevel': energyLevel,
          'note': 'ثبت شده از ارزیابی صبحگاهی: ${moodItem['label']}',
          'loggedAt': nowMs,
        },
      );

      // 3. Update app settings current default energy level
      await db.insert(
        'app_settings',
        {
          'key': 'default_energy_level',
          'value': energyLevel,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await HapticFeedback.mediumImpact();
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ارزیابی صبحگاهی شما با موفقیت ثبت شد 🌿',
              style: TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: Color(0xff10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving morning check-in: $e');
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ارزیابی و چک‌این صبحگاهی',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.cardTitle,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.xmark,
                        color: colors.iconSecondary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ریتم و وضعیت امروز خود را ثبت کنید تا سطح انرژی شما کالیبره شود.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 20),

                // Mood Selection List
                ..._moods.map((mood) {
                  final isSelected = _selectedMood == mood['key'];
                  final mColor = mood['color'] as Color;

                  return GestureDetector(
                    onTap: () async {
                      await HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMood = mood['key'] as String;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? mColor.withValues(alpha: 0.08)
                                : colors.cardFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? mColor.withValues(alpha: 0.4)
                                  : colors.glassBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mood['icon'] as IconData,
                            color: isSelected ? mColor : colors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              mood['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? colors.cardTitle
                                        : colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: mColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Optional note text field
                TextField(
                  controller: _noteController,
                  style: TextStyle(
                    color: colors.cardTitle,
                    fontSize: 13,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'یادداشت کوتاه از احساس امروز (اختیاری)',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    fillColor: colors.inputBackground,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveCheckin,
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'تایید و ثبت وضعیت',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
