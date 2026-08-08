import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/models.dart' hide EnergyLevel;
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';
import 'package:sqflite/sqflite.dart';

class QuickLogSheet extends StatefulWidget {

  const QuickLogSheet({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  EnergyLevel? _selectedEnergy;
  Mood? _selectedMood;
  double _valence = 3;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  Future<void> _saveLogs() async {
    if (_selectedEnergy == null && _selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً حداقل یکی از موارد (انرژی یا حال روحی) را انتخاب کنید.', style: TextStyle(fontFamily: 'Vazirmatn')),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final noteText = _noteController.text.trim();

      await db.transaction((txn) async {
        // 1. Save Energy Log if selected
        if (_selectedEnergy != null) {
          final energyId = 'energy_manual_$nowMs';
          await txn.insert(
            'energy_logs',
            {
              'id': energyId,
              'energyLevel': _selectedEnergy!.name.toUpperCase(),
              'source': 'MANUAL',
              'note': noteText.isNotEmpty ? noteText : null,
              'loggedAt': nowMs,
            },
          );

          // Update default energy level setting
          await txn.insert(
            'app_settings',
            {
              'key': 'default_energy_level',
              'value': _selectedEnergy!.name.toUpperCase(),
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // 2. Save Mood Log if selected
        if (_selectedMood != null) {
          final moodId = 'mood_manual_$nowMs';
          await txn.insert(
            'mood_logs',
            {
              'id': moodId,
              'mood': _selectedMood!.name.toUpperCase(),
              'valence': _valence.toInt(),
              'note': noteText.isNotEmpty ? noteText : null,
              'loggedAt': nowMs,
            },
          );
        }
      });

      await HapticFeedback.mediumImpact();
      RitmoEvents.notifyRoutineChanged();
      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ارزیابی وضعیت شما با موفقیت ثبت شد 🌿', style: TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: Color(0xffEC4899),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving quick log: $e');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
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
                    'الان چطورم؟',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn'),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: isDark ? Colors.white60 : colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Energy Level
              Text(
                '⚡ سطح انرژی فیزیکی بدنی شما:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 8),
              Row(
                children: EnergyLevel.values.map((level) {
                  final isSelected = _selectedEnergy == level;
                  Color activeColor;
                  String emoji;
                  if (level == EnergyLevel.low) {
                    activeColor = Colors.redAccent;
                    emoji = '🥱';
                  } else if (level == EnergyLevel.medium) {
                    activeColor = Colors.blueAccent;
                    emoji = '🔋';
                  } else {
                    activeColor = Colors.greenAccent;
                    emoji = '⚡';
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (_selectedEnergy == level) {
                            _selectedEnergy = null;
                          } else {
                            _selectedEnergy = level;
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.08) : colors.border.withValues(alpha: 0.5)),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              level.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? (isDark ? Colors.white : activeColor) : (isDark ? Colors.white70 : colors.textSecondary),
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 2. Mood Grid
              Text(
                '🎭 احساس و حال روحی:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: Mood.values.length,
                itemBuilder: (context, index) {
                  final mood = Mood.values[index];
                  final isSelected = _selectedMood == mood;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_selectedMood == mood) {
                          _selectedMood = null;
                        } else {
                          _selectedMood = mood;
                          _valence = mood.defaultValence.toDouble();
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xffEC4899).withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xffEC4899) : (isDark ? Colors.white.withValues(alpha: 0.08) : colors.border.withValues(alpha: 0.5)),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? (isDark ? Colors.white : const Color(0xffEC4899)) : (isDark ? Colors.white70 : colors.textSecondary),
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Valence Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ' میزان خوشایی (میزان رضایت ذهنی):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                  Text(
                    _toPersianDigits('${_valence.toInt()} از ۵'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xffEC4899), fontFamily: 'Vazirmatn'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Slider(
                value: _valence,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: const Color(0xffEC4899),
                inactiveColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                onChanged: (v) {
                  setState(() {
                    _valence = v;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('خیلی ناخوشایند 😞', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : colors.textSecondary.withValues(alpha: 0.7), fontFamily: 'Vazirmatn')),
                  Text('خنثی 😐', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : colors.textSecondary.withValues(alpha: 0.7), fontFamily: 'Vazirmatn')),
                  Text('خیلی خوشایند 🥰', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : colors.textSecondary.withValues(alpha: 0.7), fontFamily: 'Vazirmatn')),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Note
              TextField(
                controller: _noteController,
                style: TextStyle(color: isDark ? Colors.white : colors.textPrimary, fontSize: 14, fontFamily: 'Vazirmatn'),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'توضیحات بیشتر یا علت این حس و حال (اختیاری)...',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'Vazirmatn'),
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : colors.border.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xffEC4899).withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _saveLogs,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'ثبت و ذخیره وضعیت کنونی',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
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
