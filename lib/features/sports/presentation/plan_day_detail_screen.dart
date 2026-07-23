import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/models/sports_models.dart';
import 'package:ritmo/features/sports/models/workout_split_models.dart';

class PlanDayDetailScreen extends StatefulWidget {

  const PlanDayDetailScreen({
    super.key,
    required this.weekday,
    required this.dayPlan,
  });
  final int weekday; // 1 = دوشنبه
  final SplitDay dayPlan;

  @override
  State<PlanDayDetailScreen> createState() => _PlanDayDetailScreenState();
}

class _PlanDayDetailScreenState extends State<PlanDayDetailScreen> {
  late List<ExerciseChecklistEntry> _exercises; // استفاده از همون مدل برای ویرایش
  bool _hasChanges = false;

  final Map<int, String> _dayNames = {
    1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنج‌شنبه',
    5: 'جمعه', 6: 'شنبه', 7: 'یکشنبه'
  };

  @override
  void initState() {
    super.initState();
    // در واقعیت این لیست باید از دیتابیس (plan_exercise) خونده بشه
    // اینجا به صورت mock چند تا میذاریم اگر خالی بود
    _exercises = [];
    if (_exercises.isEmpty && widget.dayPlan.groups.isNotEmpty) {
      _exercises = [
        ExerciseChecklistEntry(
          exerciseId: 'ex_mock_1',
          name: 'پرس سینه دمبل',
          referenceSets: 3,
          referenceReps: 12,
          referenceWeight: 15,
          status: 'UPCOMING',
        ),
      ];
    }
  }

  void _addExercise() {
    RitmoHaptics.tap();
    // TODO: Open Exercise Library to select one
    setState(() {
      _exercises.add(
        ExerciseChecklistEntry(
          exerciseId: 'ex_mock_new',
          name: 'حرکت جدید',
          referenceSets: 3,
          referenceReps: 10,
          status: 'UPCOMING',
        )
      );
      _hasChanges = true;
    });
  }

  void _removeExercise(int index) {
    RitmoHaptics.warning();
    setState(() {
      _exercises.removeAt(index);
      _hasChanges = true;
    });
  }

  void _saveChanges() {
    RitmoHaptics.success();
    // TODO: Save to DB
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_dayNames[widget.weekday]} - ${widget.dayPlan.groups.isEmpty ? 'استراحت' : widget.dayPlan.groups.map((g) => g.label).join(' و ')}';

    return Scaffold(
      backgroundColor: const Color(0xff0A110E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.right_chevron, color: Colors.white),
          onPressed: () { RitmoHaptics.tap(); Navigator.pop(context); },
        ),
        title: const Text('ویرایش برنامه روزانه',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16,
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${index + 1}. ${ex.name}',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _removeExercise(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildCompactInput('ست', ex.referenceSets.toString()),
                            const SizedBox(width: 12),
                            const Text('×', style: TextStyle(color: Colors.white54)),
                            const SizedBox(width: 12),
                            _buildCompactInput('تکرار', ex.referenceReps.toString()),
                            const SizedBox(width: 12),
                            const Text('—', style: TextStyle(color: Colors.white54)),
                            const SizedBox(width: 12),
                            _buildCompactInput('وزنه (kg)', ex.referenceWeight?.toString() ?? '-'),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add, color: Color(0xff00F5A0), size: 20),
                label: const Text('افزودن حرکت جدید', style: TextStyle(color: Color(0xff00F5A0), fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xff00F5A0).withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ElevatedButton(
                onPressed: _hasChanges ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00F5A0),
                  disabledBackgroundColor: Colors.white12,
                  foregroundColor: Colors.black,
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('ذخیره تغییرات',
                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInput(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'Vazirmatn')),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
