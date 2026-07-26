import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/services/premium_service.dart';

import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/core/utils/snapshot_helper.dart';
import 'package:ritmo/features/onboarding/logic/day_arc_inferencer.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_draft.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_gate.dart';
import 'package:ritmo/features/onboarding/logic/onboarding_module_map.dart';
import 'package:ritmo/features/onboarding/logic/starter_pack_catalog.dart';
import 'package:ritmo/features/onboarding/models/focus_area.dart';
import 'package:sqflite/sqflite.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController() {
    _initDefaults();
  }

  int currentIndex = 0;
  String userName = '';
  String gender = 'OTHER';
  int age = 25;
  String wakeTime = '07:00';
  String sleepTime = '23:00';
  bool isDayArcInferred = false;
  String dayArcReason = '';
  Set<FocusArea> focusAreas = {};
  List<StarterRoutineTemplate> selectedStarterRoutines = [];
  Set<String> skippedStepCodes = {};
  String energyProfile = 'MEDIUM';
  bool enableCycle = false;
  bool notifAsked = false;
  bool notifGranted = false;
  bool isSaving = false;
  String? errorMessage;

  static const List<String> stepCodes = [
    'WELCOME',
    'IDENTITY',
    'DAY_ARC',
    'FOCUS',
    'STARTER_PACK',
    'NOTIFICATIONS',
    'CELEBRATION',
  ];

  Future<void> _initDefaults() async {
    final suggestion = await DayArcInferencer.suggest();
    wakeTime = suggestion.wakeTime;
    sleepTime = suggestion.sleepTime;
    isDayArcInferred = suggestion.isInferred;
    dayArcReason = suggestion.reasonFa;

    selectedStarterRoutines = StarterPackCatalog.suggestFor(focusAreas);
    notifyListeners();
  }

  Future<void> checkAndLoadDraft() async {
    final draft = await OnboardingDraftStore.load();
    if (draft != null) {
      currentIndex = draft.stepIndex;
      final st = draft.state;
      userName = st['userName'] as String? ?? userName;
      gender = st['gender'] as String? ?? gender;
      age = st['age'] as int? ?? age;
      wakeTime = st['wakeTime'] as String? ?? wakeTime;
      sleepTime = st['sleepTime'] as String? ?? sleepTime;
      energyProfile = st['energyProfile'] as String? ?? energyProfile;
      enableCycle = st['enableCycle'] as bool? ?? enableCycle;

      final areaCodes = List<String>.from(st['focusAreas'] as List? ?? []);
      focusAreas = areaCodes.map((c) => FocusArea.parse(c)).whereType<FocusArea>().toSet();

      skippedStepCodes = Set<String>.from(st['skippedStepCodes'] as List? ?? []);
      selectedStarterRoutines = StarterPackCatalog.suggestFor(focusAreas);
      notifyListeners();
    }
  }

  void _saveDraftDebounced() {
    final draft = OnboardingDraft(
      stepIndex: currentIndex,
      state: {
        'userName': userName,
        'gender': gender,
        'age': age,
        'wakeTime': wakeTime,
        'sleepTime': sleepTime,
        'energyProfile': energyProfile,
        'enableCycle': enableCycle,
        'focusAreas': focusAreas.map((a) => a.code).toList(),
        'skippedStepCodes': skippedStepCodes.toList(),
      },
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
    OnboardingDraftStore.save(draft);
  }

  void next() {
    if (currentIndex < stepCodes.length - 1) {
      currentIndex++;
      _saveDraftDebounced();
      notifyListeners();
    }
  }

  void prev() {
    if (currentIndex > 0) {
      currentIndex--;
      _saveDraftDebounced();
      notifyListeners();
    }
  }

  Future<void> skipCurrentStep() async {
    final code = stepCodes[currentIndex];
    skippedStepCodes.add(code);

    switch (code) {
      case 'IDENTITY':
        await CentralInboxService.push(
          category: InboxCategory.SUGGESTION,
          sourceSystem: 'onboarding_skip',
          entityId: 'skip_identity',
          eventType: 'setup_profile',
          title: 'تکمیل پروفایل کاربری',
          body: 'نام و مشخصات خود را در تنظیمات تکمیل کنید.',
          priority: 1,
        );
      case 'DAY_ARC':
        await CentralInboxService.push(
          category: InboxCategory.SUGGESTION,
          sourceSystem: 'onboarding_skip',
          entityId: 'skip_day_arc',
          eventType: 'setup_day_arc',
          title: 'تنظیم قوس روز',
          body: 'ساعات خواب و بیداری خود را تنظیم کنید.',
          priority: 1,
        );
      case 'FOCUS':
        await CentralInboxService.push(
          category: InboxCategory.SUGGESTION,
          sourceSystem: 'onboarding_skip',
          entityId: 'skip_focus',
          eventType: 'setup_focus',
          title: 'انتخاب حوزه‌های تمرکز',
          body: 'حوزه‌های اصلی تمرکز زندگی خود را مشخص کنید.',
          priority: 1,
        );
      case 'STARTER_PACK':
        await CentralInboxService.push(
          category: InboxCategory.SUGGESTION,
          sourceSystem: 'onboarding_skip',
          entityId: 'skip_starter_pack',
          eventType: 'create_first_routine',
          title: 'ساخت اولین روتین',
          body: 'اولین عادت/روتین خود را ایجاد کنید.',
          priority: 1,
        );
    }

    next();
  }

  void toggleFocusArea(FocusArea area) {
    if (focusAreas.contains(area)) {
      focusAreas.remove(area);
    } else {
      focusAreas.add(area);
    }
    selectedStarterRoutines = StarterPackCatalog.suggestFor(focusAreas);
    notifyListeners();
  }

  void toggleStarterRoutine(StarterRoutineTemplate template) {
    if (selectedStarterRoutines.any((t) => t.id == template.id)) {
      selectedStarterRoutines.removeWhere((t) => t.id == template.id);
    } else {
      selectedStarterRoutines.add(template);
    }
    notifyListeners();
  }

  Future<void> save({required VoidCallback onFinished}) async {
    if (isSaving) return;
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    try {
      // 1. Create starter routines using CreateRoutineCommand via Kernel
      for (final t in selectedStarterRoutines) {
        final rId = RitmoIdFactory.routine();
        final duration = DurationBounds.sanitize(t.durationMinutes);

        final routineData = {
          'id': rId,
          'title': t.titleFa,
          'category': t.category.name,
          'routineType': 'timeBased',
          'notificationLevel': 'normal',
          'isEssential': 0,
          'energyRule': 'none',
          'priority': 1.0,
          'targetDurationMinutes': duration,
          'displayOrder': 1,
          'description': 'اولین روتین ثبت‌شده در آنبوردینگ',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        };

        final scheduleData = {
          'id': RitmoIdFactory.schedule(rId),
          'routineId': rId,
          'scheduleType': 'DAILY',
          'timeOfDay': t.defaultTime,
          'daysOfWeek': '1,2,3,4,5,6,7',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        };

        final command = CreateRoutineCommand(
          routineData: routineData,
          scheduleData: scheduleData,
        );

        await RitmoExecutionKernel.instance.execute(command);
      }

      // 2. Perform main onboarding completion transaction
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        final canCourses = PremiumService.instance.can(PremiumFeature.coursesModule);
        final canKonkur = PremiumService.instance.can(PremiumFeature.konkurModule);

        final moduleStates = OnboardingModuleMap.resolveModuleStates(
          chosenAreas: focusAreas,
          isFemale: gender == 'FEMALE',
          enableCycle: enableCycle,
          canUseCourses: canCourses,
          canUseKonkur: canKonkur,
        );

        for (final entry in moduleStates.entries) {
          await txn.insert(
            'app_settings',
            {
              'key': entry.key,
              'value': entry.value,
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        final focusCodes = focusAreas.map((a) => a.code).toList();
        final settingsToSave = {
          if (userName.isNotEmpty) 'user_name': userName,
          'user_gender': gender,
          'user_age': age.toString(),
          'wake_time': wakeTime,
          'sleep_time': sleepTime,
          'primary_focus_areas': jsonEncode(focusCodes),
          'energy_profile': energyProfile,
          'default_energy_level': energyProfile,
          'notif_permission_asked': 'true',
          'notif_permission_granted': notifGranted ? 'true' : 'false',
          'onboarding_skipped_steps': jsonEncode(skippedStepCodes.toList()),
        };

        for (final entry in settingsToSave.entries) {
          await txn.insert(
            'app_settings',
            {
              'key': entry.key,
              'value': entry.value,
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await OnboardingGate.markCompleted(txn, version: OnboardingGate.currentVersion);
      });

      // Post transaction actions
      final firstRoutineTitle = selectedStarterRoutines.isNotEmpty
          ? selectedStarterRoutines.first.titleFa
          : 'ریتمو';

      SnapshotHelper.updateWidgetSnapshot(
        nextActionTitle: firstRoutineTitle,
        rhythmScore: 100,
        currentEnergyLevel: energyProfile,
      );
      await AlarmSchedulerService.scheduleNextAlarms();

      RitmoEventBus().fire(RitmoEvent(
        type: 'DataImported',
        timestamp: DateTime.now(),
        payload: {},
      ));

      await OnboardingDraftStore.clear();

      isSaving = false;
      notifyListeners();
      onFinished();
    } catch (e, st) {
      debugPrint('[OnboardingController] Error during save: $e\n$st');
      isSaving = false;
      errorMessage = 'ذخیرهٔ اطلاعات ناموفق بود. لطفاً دوباره تلاش کنید.';
      notifyListeners();
    }
  }
}
