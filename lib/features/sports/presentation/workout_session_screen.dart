import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/sports/models/sports_models.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_exercise_checklist_item.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_quick_feeling_sheet.dart';
import 'package:ritmo/features/sports/presentation/widgets/sports_rest_timer_banner.dart';

class WorkoutSessionScreen extends StatefulWidget {

  const WorkoutSessionScreen({
    super.key,
    required this.dayId,
    required this.title,
    required this.initialExercises,
  });
  final String dayId;
  final String title;
  final List<ExerciseChecklistEntry> initialExercises;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late List<ExerciseChecklistEntry> _exercises;
  late int _currentIndex;
  bool _showRest = false;

  @override
  void initState() {
    super.initState();
    // کپی عمیق (Deep copy) برای جلوگیری از تغییر حالت اولیه در صورت نیاز به انصراف
    _exercises = widget.initialExercises.map((e) => ExerciseChecklistEntry(
      exerciseId: e.exerciseId,
      name: e.name,
      referenceSets: e.referenceSets,
      referenceReps: e.referenceReps,
      referenceWeight: e.referenceWeight,
      status: e.status,
      feeling: e.feeling,
    )).toList();
    
    // پیدا کردن اولین حرکت انجام نشده
    _currentIndex = _exercises.indexWhere((e) => e.status != 'DONE');
    if (_currentIndex == -1) {
      _currentIndex = 0; // همه انجام شدن؟
    } else {
      // مارک کردن اولین حرکت به عنوان CURRENT و بقیه UPCOMING
      for (var i = 0; i < _exercises.length; i++) {
        if (_exercises[i].status != 'DONE') {
          _exercises[i] = _copyWithStatus(_exercises[i], i == _currentIndex ? 'CURRENT' : 'UPCOMING');
        }
      }
    }
  }

  ExerciseChecklistEntry _copyWithStatus(ExerciseChecklistEntry old, String newStatus, [Feeling? newFeeling]) {
    return ExerciseChecklistEntry(
      exerciseId: old.exerciseId,
      name: old.name,
      referenceSets: old.referenceSets,
      referenceReps: old.referenceReps,
      referenceWeight: old.referenceWeight,
      status: newStatus,
      feeling: newFeeling ?? old.feeling,
    );
  }

  void _markCurrentDone() {
    if (_currentIndex >= _exercises.length) return;
    
    final doneIndex = _currentIndex;
    final doneExercise = _exercises[doneIndex];

    // ۱. نمایش شیت احساسات
    showSportsQuickFeelingSheet(
      context,
      exerciseName: doneExercise.name,
      onFeelingSelected: (feeling) {
        setState(() {
          _exercises[doneIndex] = _copyWithStatus(doneExercise, 'DONE', feeling);
        });
      },
    );

    // ۲. آپدیت وضعیت بدون منتظر موندن برای انتخاب احساس
    setState(() {
      _exercises[doneIndex] = _copyWithStatus(doneExercise, 'DONE');
      _showRest = true;
    });
  }

  void _onRestFinished() {
    setState(() {
      _showRest = false;
      _advanceToNext();
    });
  }

  void _advanceToNext() {
    var nextIndex = _exercises.indexWhere((e) => e.status != 'DONE', _currentIndex);
    if (nextIndex == -1) {
      // اگر همه انجام شده باشن، بگرد از اول شاید یکی جا مونده باشه
      nextIndex = _exercises.indexWhere((e) => e.status != 'DONE');
    }

    if (nextIndex != -1) {
      setState(() {
        _currentIndex = nextIndex;
        _exercises[_currentIndex] = _copyWithStatus(_exercises[_currentIndex], 'CURRENT');
      });
    } else {
      // همه حرکات تمام شده!
      RitmoHaptics.success();
      // TODO: Navigate to SessionSummaryScreen
    }
  }

  void _finishWorkoutEarly() {
    RitmoHaptics.warning();
    // TODO: Confirm and save what's done, then go to Summary
  }

  @override
  Widget build(BuildContext context) {
    // آیا همه حرکات انجام شده؟
    final allDone = _exercises.every((e) => e.status == 'DONE');

    return Scaffold(
      backgroundColor: const Color(0xff0A110E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.right_chevron, color: Colors.white),
          onPressed: () { RitmoHaptics.tap(); Navigator.pop(context); },
        ),
        title: Text(widget.title,
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 16,
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // هدر پیشرفت
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text('پیشرفت جلسه:', style: TextStyle(color: Colors.white60, fontSize: 13, fontFamily: 'Vazirmatn')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 6, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3))),
                        FractionallySizedBox(
                          widthFactor: _exercises.where((e) => e.status == 'DONE').length / (_exercises.isEmpty ? 1 : _exercises.length),
                          child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xff00F5A0), borderRadius: BorderRadius.circular(3))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // بنر استراحت
            if (_showRest && !allDone)
              SportsRestTimerBanner(
                onSkip: _onRestFinished,
                onFinished: _onRestFinished,
              ),

            // لیست حرکات
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  return SportsExerciseChecklistItem(
                    entry: _exercises[index],
                    onMarkDone: () {
                      if (index == _currentIndex) {
                        _markCurrentDone();
                      } else {
                        // کاربر حرکت دیگری را به عنوان CURRENT انتخاب می‌کند
                        setState(() {
                          _exercises[_currentIndex] = _copyWithStatus(_exercises[_currentIndex], 'UPCOMING');
                          _currentIndex = index;
                          _exercises[_currentIndex] = _copyWithStatus(_exercises[_currentIndex], 'CURRENT');
                        });
                      }
                    },
                    onSwap: () {
                      // TODO: Open swap exercise sheet
                    },
                  );
                },
              ),
            ),

            // دکمه پایان
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: allDone ? RitmoHaptics.success : _finishWorkoutEarly,
                style: ElevatedButton.styleFrom(
                  backgroundColor: allDone ? const Color(0xff00F5A0) : Colors.white12,
                  foregroundColor: allDone ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(allDone ? 'پایان موفقیت‌آمیز تمرین 🎉' : 'پایان زودهنگام تمرین',
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
