// lib/features/routines/presentation/planner_controller.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/assistant/logic/duration_estimator.dart';
import 'package:ritmo/features/health/presentation/widgets/medication_form_sheet.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_strategy_registry.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class OccupiedRange {
  OccupiedRange({required this.start, required this.end, required this.title, required this.timeStr});
  final int start; // in minutes (0..1439)
  final int end;
  final String title;
  final String timeStr;
}

// --- STATE CONTROLLER ---
class PlannerController extends ChangeNotifier {

  PlannerController({
    this.routineToEdit,
    required this.onSaved,
    required this.onPageChanged,
    this.prefilledTime,
  });
  final Map<String, dynamic>? routineToEdit;
  final VoidCallback onSaved;
  final void Function(int) onPageChanged;
  final TimeOfDay? prefilledTime;

  bool moduleReligionEnabled = true;
  bool moduleMedicineEnabled = false;
  bool moduleCycleEnabled = false;
  bool moduleCoursesEnabled = false;
  bool moduleKonkurEnabled = false;
  bool moduleGoalsEnabled = false;
  bool moduleSportsEnabled = false;
  bool moduleEnergyEnabled = false;
  bool moduleSleepEnabled = false;

  int currentPage = 0;
  bool isEditing = false;
  bool isSaving = false;

  // NLP Text Input
  final TextEditingController inputController = TextEditingController();
  bool isParsing = false;
  bool isListening = false; // Voice input pulsing simulation

  // Core Fields
  String title = '';
  String description = '';
  Category selectedCategory = Category.personal;
  String itemType = 'ROUTINE'; // 'ROUTINE' | 'REMINDER' | 'TASK' | 'REFLECT' | 'EVENT'
  double priority = 1; // 0.5=Low, 1.0=Medium, 1.5=High, 2.0=Critical
  
  // Temporal data for medical category
  MedicationFormData? tempMedicationData;
  
  // Date & Time Configurations
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int targetDuration = 60; // 60 minutes
  String recurrenceType = 'EVERY_DAY'; // 'EVERY_DAY', 'WEEKLY', 'CUSTOM_DAYS'
  int reminderOffsetMinutes = 15; // 15 mins before

  // Worship specific fields
  String worshipType = 'MUSTAHAB'; // 'MUSTAHAB' | 'DHIKR' | 'QURAN' | 'DEBT'
  String worshipDebtType = 'PRAYER'; // 'PRAYER' | 'FAST'
  int worshipTotalCount = 10;
  int worshipDailyTarget = 1;
  String worshipReminderAnchor = 'NONE'; // NONE, FAJR, SUNRISE, DHUHR, ASR, MAGHRIB, ISHA, MIDNIGHT_SHARI, WAKEUP, BEDTIME
  int worshipOffsetMinutes = 0;
  List<int> worshipSelectedDays = [6, 7, 1, 2, 3, 4, 5]; // Sat..Fri (matches 6,7,1,2,3,4,5)
  String worshipRepeatType = 'RECURRING'; // 'RECURRING' | 'ONCE'
  
  // Sports specific fields
  String sportsOpType = 'ROUTINE'; // 'ROUTINE' | 'LOG'
  String sportsType = 'STRENGTH'; // RUNNING, WALKING, STRENGTH, YOGA, CYCLING, SWIMMING, OTHER
  int sportsDuration = 45;
  String sportsIntensity = 'MEDIUM'; // LIGHT, MEDIUM, HIGH
  String sportsLocation = 'GYM'; // HOME, GYM
  String sportsFeeling = 'خوب';
  
  // Medical specific fields
  String medicalMode = 'FIXED'; // 'FIXED' | 'PRN'
  List<TimeOfDay> medicalTimes = [const TimeOfDay(hour: 8, minute: 0)];
  int medicalStockCount = 30;
  int medicalRefillWarning = 5;
  int medicalMinIntervalHours = 4;
  int medicalMaxDosesPerDay = 4;

  // Learning/Course specific fields
  String courseType = 'VIDEO'; // VIDEO, BOOK, SKILL, CUSTOM
  int courseTotalSessions = 10;
  int courseWeeklyTarget = 3;
  int courseSessionDuration = 45;
  List<int> coursePreferredDays = [6, 1, 3]; // Sat, Mon, Wed
  TimeOfDay coursePreferredTime = const TimeOfDay(hour: 18, minute: 0);

  // Goals specific fields
  String goalType = 'DAILY'; // DAILY, WEEKLY, LONG_TERM
  DateTime goalTargetDate = DateTime.now().add(const Duration(days: 30));
  List<String> goalSteps = [''];

  // Reflection specific fields
  int reflectionMood = 3;
  String reflectionWins = '';
  String reflectionGratitude = '';
  String reflectionLearnings = '';
  bool reflectionIsPrivate = false;

  // Event specific fields
  DateTime eventDate = DateTime.now();
  TimeOfDay eventStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay eventEndTime = const TimeOfDay(hour: 10, minute: 0);
  String eventLocation = '';

  // Advanced accordion properties
  bool isAdvancedExpanded = false;
  String notes = '';
  String? dependsOnRoutineId;
  String? selectedZoneId;
  List<Map<String, dynamic>> availableZones = [];
  String energyRule = 'NONE';

  // Visual/UI effects
  bool showSuccessAnim = false;
  List<Map<String, dynamic>> todayOtherRoutines = [];

  // Sunrise/Sunset calculations (standard fallback or loaded)
  TimeOfDay sunriseTime = const TimeOfDay(hour: 5, minute: 45);
  TimeOfDay sunsetTime = const TimeOfDay(hour: 19, minute: 15);

  // NLP state
  String rawInputText = '';
  bool isTimeParsed = false;
  bool isRecurrenceParsed = false;
  bool isDurationParsed = false;
  bool isDateParsed = false;
  Timer? _nlpDebounceTimer;
  
  // Parsed backups to un-apply
  TimeOfDay? parsedTime;
  String? parsedRecurrence;
  Set<int>? parsedWeekdays;
  int? parsedDuration;
  int? parsedDaysOffset;
  
  final Set<String> rejectedEntities = {};
  
  // AI estimated duration
  int? aiEstimatedDuration;
  bool isAiParsing = false;
  bool showAiParseAction = false;
  
  // Occupancy details
  List<OccupiedRange> occupiedRanges = [];
  List<String> suggestedTimeSlots = [];
  String sleepBedtime = '23:30';
  String sleepWake = '07:00';
  bool isOccupancyLoading = false;
  
  // Quick save hint
  bool quickSaveHintDismissed = false;
  bool hasManuallySelectedCategory = false;
  
  // Frequent stations
  List<Map<String, dynamic>> frequentStations = [];

  void init() {
    isEditing = routineToEdit != null;
    if (isEditing) {
      _loadEditData();
    } else if (prefilledTime != null) {
      selectedTime = prefilledTime!;
    }
    _loadOtherRoutinesForDate();
    _loadModuleSettings();
    _loadZones();
    _loadQuickSaveHintStatus();
    loadOccupancyForDate(selectedDate);
    loadFrequentStations();
  }

  Future<void> _loadZones() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final list = await db.query('zones');
      availableZones = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading zones in planner: $e');
    }
  }

  Future<void> _loadModuleSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      
      moduleReligionEnabled = settingsMap['module_religion_enabled'] == 'true';
      moduleMedicineEnabled = settingsMap['module_medicine_enabled'] == 'true';
      moduleCycleEnabled = settingsMap['module_cycle_enabled'] == 'true';
      moduleCoursesEnabled = settingsMap['module_courses_enabled'] == 'true';
      moduleKonkurEnabled = settingsMap['module_konkur_enabled'] == 'true';
      moduleGoalsEnabled = settingsMap['module_goals_enabled'] == 'true';
      moduleSportsEnabled = settingsMap['module_sports_enabled'] == 'true';
      moduleEnergyEnabled = settingsMap['module_energy_enabled'] == 'true';
      moduleSleepEnabled = settingsMap['module_sleep_enabled'] == 'true';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading module settings in planner: $e');
    }
  }

  void _loadEditData() {
    final data = routineToEdit!;
    title = data['title'] as String? ?? '';
    description = data['description'] as String? ?? '';
    selectedCategory = Category.values.firstWhere((e) => e.name == data['category'], orElse: () => Category.personal);
    priority = data['priority'] as double? ?? 1.0;
    targetDuration = data['targetDurationMinutes'] as int? ?? 60;
    itemType = data['itemType'] as String? ?? 'ROUTINE';
    dependsOnRoutineId = data['dependsOnRoutineId'] as String?;
    selectedZoneId = data['zoneId'] as String?;
    energyRule = data['energyRule'] as String? ?? 'NONE';
    
    // Load Time and Recurrence
    final timeStr = data['timeOfDay'] as String? ?? '08:00';
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    notifyListeners();
  }

  Future<void> _loadOtherRoutinesForDate() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final list = await db.query(
        'routines',
        where: 'isArchived = 0',
        orderBy: 'title ASC',
      );
      
      // Load schedules and merge
      final resolvedList = <Map<String, dynamic>>[];
      for (final r in list) {
        final schedules = await db.query(
          'routine_schedules',
          where: 'routineId = ?',
          whereArgs: [r['id']],
        );
        if (schedules.isNotEmpty) {
          final sched = schedules.first;
          final rMap = Map<String, dynamic>.from(r);
          rMap['timeOfDay'] = sched['timeOfDay'] ?? '08:00';
          resolvedList.add(rMap);
        }
      }

      // Sort chronologically
      resolvedList.sort((a, b) {
        final timeA = a['timeOfDay'] as String? ?? '08:00';
        final timeB = b['timeOfDay'] as String? ?? '08:00';
        return timeA.compareTo(timeB);
      });

      todayOtherRoutines = resolvedList;
      notifyListeners();
    } catch (e) {
      debugPrint('Load other routines error: $e');
    }
  }

  void updatePage(int page) {
    currentPage = page;
    onPageChanged(page);
    notifyListeners();
  }

  void selectCategory(Category cat, BuildContext context, {String? type}) {
    var isSystemEnabled = true;
    String? settingKey;
    String? systemName;
    String? systemDescription;
    IconData? systemIcon;
    Color? systemColor;

    if (cat == Category.fitness) {
      isSystemEnabled = moduleSportsEnabled;
      settingKey = 'module_sports_enabled';
      systemName = 'ورزش';
      systemDescription = 'با فعالسازی این سیستم، میتوانید تمرینهای ورزشی، مدت و شدت آنها را ثبت کرده و روند فعالیت بدنی خود را پیگیری کنید.';
      systemIcon = Icons.fitness_center;
      systemColor = const Color(0xff10B981);
    } else if (cat == Category.religious) {
      isSystemEnabled = moduleReligionEnabled;
      settingKey = 'module_religion_enabled';
      systemName = 'عبادت';
      systemDescription = 'با فعال‌سازی این سیستم، می‌توانید برنامه‌ی نمازهای واجب، مستحبات، اذکار و قرآن خود را زمان‌بندی و پیگیری کنید.';
      systemIcon = Icons.mosque_rounded;
      systemColor = const Color(0xffFBBF24);
    } else if (cat == Category.medical) {
      isSystemEnabled = moduleMedicineEnabled;
      settingKey = 'module_medicine_enabled';
      systemName = 'دارو و سلامت';
      systemDescription = 'با فعال‌سازی این سیستم، می‌توانید برنامه‌ی داروها، نوبت‌های پزشک و سایر موارد پزشکی خود را مدیریت کنید.';
      systemIcon = Icons.vaccines_rounded;
      systemColor = const Color(0xff06B6D4);
    } else if (cat == Category.learning || cat == Category.free) {
      isSystemEnabled = moduleCoursesEnabled;
      settingKey = 'module_courses_enabled';
      systemName = 'دوره‌های آموزشی';
      systemDescription = 'با فعال‌سازی این سیستم، می‌توانید دوره‌های آموزشی، کتاب‌ها و دوره‌های دلخواه خود را زمان‌بندی و پیگیری کنید.';
      systemIcon = Icons.school_rounded;
      systemColor = const Color(0xff6366F1);
    } else if (cat == Category.custom) {
      isSystemEnabled = moduleGoalsEnabled;
      settingKey = 'module_goals_enabled';
      systemName = 'اهداف و برنامه‌ها';
      systemDescription = 'با فعال‌سازی این سیستم، می‌توانید اهداف زندگی خود را در قالب پروژه‌ها و گام‌های مشخص زمان‌بندی و مدیریت کنید.';
      systemIcon = Icons.track_changes_rounded;
      systemColor = const Color(0xffF97316);
    }

    if (!isSystemEnabled && settingKey != null) {
      _showActivationDialog(
        context: context,
        settingKey: settingKey,
        name: systemName!,
        description: systemDescription!,
        icon: systemIcon!,
        color: systemColor!,
        onActivated: () {
          selectedCategory = cat;
          if (type != null) {
            itemType = type;
          } else {
            itemType = cat == Category.medical ? 'REMINDER' : 'ROUTINE';
          }
          if (cat == Category.medical && openMedicalSheet != null) {
            openMedicalSheet!(MedicationFormData(
              name: title,
              dose: '',
              type: 'FIXED',
              scheduledTimes: [selectedTime],
              repeatType: 'WEEKDAYS',
              selectedWeekdays: const [6, 7, 1, 2, 3, 4, 5],
              intervalDays: 1,
              startDate: DateTime.now(),
              stockCount: 30,
              warningThreshold: 5,
              minInterval: 4,
              maxDoses: 4,
            ));
          } else if (cat == Category.religious && openWorshipSheet != null) {
            openWorshipSheet!();
          } else if (cat == Category.learning && openCourseSheet != null) {
            openCourseSheet!(initialValues: {'title': title});
          } else if (cat == Category.free && openCourseSheet != null) {
            openCourseSheet!(initialValues: {'courseType': 'BOOK', 'title': title});
          } else if (cat == Category.custom && openGoalSheet != null) {
            openGoalSheet!({'title': title});
          } else if (cat == Category.fitness && openSportsScreen != null) {
            openSportsScreen!();
          } else {
            updatePage(1);
          }
        },
      );
      return;
    }

    selectedCategory = cat;
    if (type != null) {
      itemType = type;
    } else {
      if (cat == Category.medical) {
        itemType = 'REMINDER';
      } else {
        itemType = 'ROUTINE';
      }
    }

    // Medical: open the unified MedicationFormSheet directly, then jump to preview (page 2)
    if (cat == Category.medical && openMedicalSheet != null) {
      openMedicalSheet!(MedicationFormData(
        name: title,
        dose: '',
        type: 'FIXED',
        scheduledTimes: [selectedTime],
        repeatType: 'WEEKDAYS',
        selectedWeekdays: const [6, 7, 1, 2, 3, 4, 5],
        intervalDays: 1,
        startDate: DateTime.now(),
        stockCount: 30,
        warningThreshold: 5,
        minInterval: 4,
        maxDoses: 4,
      ));
      return;
    }

    // Religious: open the AddCustomMustahabSheet directly
    if (cat == Category.religious && openWorshipSheet != null) {
      openWorshipSheet!();
      return;
    }

    // Course: open the CreateCourseSheet directly
    if (cat == Category.learning && openCourseSheet != null) {
      openCourseSheet!(initialValues: {'title': title});
      return;
    }

    // Study: open the CreateCourseSheet directly with BOOK prefilled
    if (cat == Category.free && openCourseSheet != null) {
      openCourseSheet!(initialValues: {'courseType': 'BOOK', 'title': title});
      return;
    }

    // Goal: open the CreateGoalSheet directly
    if (cat == Category.custom && openGoalSheet != null) {
      openGoalSheet!({'title': title});
      return;
    }

    // Sports: open the SportsScreen directly
    if (cat == Category.fitness && openSportsScreen != null) {
      openSportsScreen!();
      return;
    }

    updatePage(1);
  }

  /// Callback set by the widget to open MedicationFormSheet in the right context
  void Function([MedicationFormData?])? openMedicalSheet;

  /// Callback set by the widget to open AddCustomMustahabSheet in the right context
  VoidCallback? openWorshipSheet;

  /// Callback set by the widget to open CreateCourseSheet in the right context
  void Function({Map<String, dynamic>? initialValues})? openCourseSheet;

  /// Callback set by the widget to open CreateGoalSheet in the right context
  void Function([Map<String, dynamic>?])? openGoalSheet;

  /// Callback set by the widget to open SportsScreen in the right context
  VoidCallback? openSportsScreen;

  // Let the sheet wire these up
  void setMedicalSheetOpener(void Function([MedicationFormData?]) opener) {
    openMedicalSheet = opener;
  }

  void setWorshipSheetOpener(VoidCallback opener) {
    openWorshipSheet = opener;
  }

  void setCourseSheetOpener(void Function({Map<String, dynamic>? initialValues}) opener) {
    openCourseSheet = opener;
  }

  void setGoalSheetOpener(void Function([Map<String, dynamic>?]) opener) {
    openGoalSheet = opener;
  }

  void setSportsScreenOpener(VoidCallback opener) {
    openSportsScreen = opener;
  }

  void _showActivationDialog({
    required BuildContext context,
    required String settingKey,
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onActivated,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xff12141C).withValues(alpha: 0.9) 
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(icon, color: color, size: 38),
                ),
                const SizedBox(height: 20),
                Text(
                  'فعال‌سازی سیستم $name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        child: Text(
                          'انصراف',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            final db = await DatabaseHelper.instance.database;
                            await db.insert(
                              'app_settings',
                              {
                                'key': settingKey,
                                'value': 'true',
                                'updatedAt': DateTime.now().millisecondsSinceEpoch,
                              },
                              conflictAlgorithm: ConflictAlgorithm.replace,
                            );
                            await _loadModuleSettings();
                            onActivated();
                          } catch (e) {
                            debugPrint('Error enabling module: $e');
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'فعال‌سازی سیستم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadQuickSaveHintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    quickSaveHintDismissed = prefs.getBool('planner_quick_save_hint_dismissed') ?? false;
    notifyListeners();
  }

  Future<void> dismissQuickSaveHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('planner_quick_save_hint_dismissed', true);
    quickSaveHintDismissed = true;
    notifyListeners();
  }

  void onInputTextChanged(String text, {bool immediate = false}) {
    rawInputText = text;
    
    // Estimate word count to show AI action
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    showAiParseAction = !isTimeParsed && wordCount >= 5;
    
    if (immediate) {
      _nlpDebounceTimer?.cancel();
      _executeNLPParse(text);
    } else {
      _nlpDebounceTimer?.cancel();
      _nlpDebounceTimer = Timer(const Duration(milliseconds: 350), () {
        _executeNLPParse(text);
      });
    }
  }

  void _executeNLPParse(String text) {
    if (text.isEmpty) return;
    
    final parsed = QuickAddParser.parse(text);
    // 1. Time
    if (parsed.timeOfDay != null && !rejectedEntities.contains('time')) {
      parsedTime = parsed.timeOfDay;
      selectedTime = parsed.timeOfDay!;
      isTimeParsed = true;
    } else {
      isTimeParsed = false;
    }
    
    // 2. Recurrence
    if ((parsed.recurrenceType != 'EVERY_DAY' || (parsed.weekdays != null && parsed.weekdays!.isNotEmpty)) && !rejectedEntities.contains('recurrence')) {
      parsedRecurrence = parsed.recurrenceType;
      parsedWeekdays = parsed.weekdays;
      recurrenceType = parsed.recurrenceType;
      if (parsed.weekdays != null) {
        worshipSelectedDays = parsed.weekdays!.toList();
      }
      isRecurrenceParsed = true;
    } else {
      isRecurrenceParsed = false;
    }
    
    // 3. Duration
    if (parsed.targetDurationMinutes != null && !rejectedEntities.contains('duration')) {
      parsedDuration = parsed.targetDurationMinutes;
      targetDuration = parsed.targetDurationMinutes!;
      isDurationParsed = true;
    } else {
      isDurationParsed = false;
    }
    
    // 4. Date
    if (parsed.daysOffset != null && !rejectedEntities.contains('date')) {
      parsedDaysOffset = parsed.daysOffset;
      selectedDate = DateTime.now().add(Duration(days: parsed.daysOffset!));
      isDateParsed = true;
    } else {
      isDateParsed = false;
    }
    
    // Auto-suggest category if not manually overridden
    if (!hasManuallySelectedCategory) {
      final suggCat = _detectCategory(text);
      if (suggCat != null) {
        selectedCategory = suggCat;
      }
    }
    
    // Clean up title
    title = QuickAddParser.cleanTitle(
      text,
      cleanTime: isTimeParsed,
      cleanRecurrence: isRecurrenceParsed,
      cleanDuration: isDurationParsed,
      cleanDate: isDateParsed,
    );
    
    // Recheck word count for AI suggestion
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    showAiParseAction = !isTimeParsed && wordCount >= 5;

    estimateDurationIfNeeded();
    loadOccupancyForDate(selectedDate);
    notifyListeners();
  }

  void removeParsedEntity(String entityKey) {
    rejectedEntities.add(entityKey);
    
    if (entityKey == 'time') {
      isTimeParsed = false;
      selectedTime = const TimeOfDay(hour: 8, minute: 0);
    } else if (entityKey == 'recurrence') {
      isRecurrenceParsed = false;
      recurrenceType = 'EVERY_DAY';
    } else if (entityKey == 'duration') {
      isDurationParsed = false;
      targetDuration = 60;
    } else if (entityKey == 'date') {
      isDateParsed = false;
      selectedDate = DateTime.now();
    }
    
    // Recompute title
    title = QuickAddParser.cleanTitle(
      rawInputText,
      cleanTime: isTimeParsed,
      cleanRecurrence: isRecurrenceParsed,
      cleanDuration: isDurationParsed,
      cleanDate: isDateParsed,
    );
    
    // Recheck word count for AI suggestion
    final wordCount = rawInputText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    showAiParseAction = !isTimeParsed && wordCount >= 5;

    HapticFeedback.selectionClick();
    estimateDurationIfNeeded();
    loadOccupancyForDate(selectedDate);
    notifyListeners();
  }

  Category? _detectCategory(String text) {
    final t = text.toLowerCase();
    if (t.contains('قرص') || t.contains('دارو') || t.contains('پزشک') || t.contains('دکتر') || t.contains('ویتامین')) {
      return Category.medical;
    }
    if (t.contains('نماز') || t.contains('قرآن') || t.contains('دعا') || t.contains('اذان') || t.contains('مسجد') || t.contains('ذکر')) {
      return Category.religious;
    }
    if (t.contains('باشگاه') || t.contains('دویدن') || t.contains('ورزش') || t.contains('تمرین') || t.contains('فوتبال') || t.contains('شنا') || t.contains('بدنسازی')) {
      return Category.fitness;
    }
    if (t.contains('درس') || t.contains('مطالعه') || t.contains('کلاس') || t.contains('آموزش') || t.contains('دوره') || t.contains('یادگیری')) {
      return Category.learning;
    }
    if (t.contains('کتاب') || t.contains('خواندن')) {
      return Category.free;
    }
    if (t.contains('هدف') || t.contains('پروژه') || t.contains('برنامه') || t.contains('کار بزرگ')) {
      return Category.custom;
    }
    return null;
  }

  Future<void> estimateDurationIfNeeded() async {
    if (title.trim().isEmpty || isEditing) {
      aiEstimatedDuration = null;
      notifyListeners();
      return;
    }
    try {
      final result = await DurationEstimator.estimate(
        title: title,
        category: selectedCategory.name,
        userQuery: rawInputText.isNotEmpty ? rawInputText : title,
      );
      aiEstimatedDuration = result.duration;
      notifyListeners();
    } catch (e) {
      debugPrint('Error estimating duration: $e');
    }
  }

  Future<void> parseWithAI(BuildContext context) async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    isAiParsing = true;
    notifyListeners();

    try {
      final parsed = await AIGateway.instance.parseQuickAdd(text);
      if (parsed != null) {
        final parsedTitle = parsed['title'] as String? ?? text;
        
        TimeOfDay? timeOfDay;
        if (parsed['time'] != null) {
          final tStr = parsed['time'] as String;
          final parts = tStr.split(':');
          if (parts.length >= 2) {
            timeOfDay = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }

        final parsedRecurrenceType = parsed['recurrenceType'] as String? ?? 'EVERY_DAY';
        final parsedDuration = parsed['durationMinutes'] as int?;
        final parsedDaysOffset = parsed['daysOffset'] as int?;
        
        final wDays = parsed['weekdays'] as List<dynamic>?;
        final parsedWeekdays = wDays?.cast<int>().toSet();

        title = parsedTitle;
        
        if (timeOfDay != null && !rejectedEntities.contains('time')) {
          selectedTime = timeOfDay;
          isTimeParsed = true;
        } else {
          isTimeParsed = false;
        }

        if ((parsedRecurrenceType != 'EVERY_DAY' || (parsedWeekdays != null && parsedWeekdays.isNotEmpty)) && !rejectedEntities.contains('recurrence')) {
          recurrenceType = parsedRecurrenceType;
          if (parsedWeekdays != null) {
            worshipSelectedDays = parsedWeekdays.toList();
          }
          isRecurrenceParsed = true;
        } else {
          isRecurrenceParsed = false;
        }

        if (parsedDuration != null && !rejectedEntities.contains('duration')) {
          targetDuration = parsedDuration;
          isDurationParsed = true;
        } else {
          isDurationParsed = false;
        }

        if (parsedDaysOffset != null && !rejectedEntities.contains('date')) {
          selectedDate = DateTime.now().add(Duration(days: parsedDaysOffset));
          isDateParsed = true;
        } else {
          isDateParsed = false;
        }

        title = QuickAddParser.cleanTitle(
          text,
          cleanTime: isTimeParsed,
          cleanRecurrence: isRecurrenceParsed,
          cleanDuration: isDurationParsed,
          cleanDate: isDateParsed,
        );

        estimateDurationIfNeeded();
        loadOccupancyForDate(selectedDate);
      } else {
        RitmoToast.show(context, 'چیزی پیدا نشد', icon: Icons.info_outline, iconColor: Colors.amber);
      }
    } catch (e) {
      debugPrint('AI parse error: $e');
      RitmoToast.show(context, 'خطا در ارتباط با هوش مصنوعی', icon: Icons.error_outline, iconColor: Colors.red);
    } finally {
      isAiParsing = false;
      notifyListeners();
    }
  }

  Future<void> loadOccupancyForDate(DateTime date) async {
    isOccupancyLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      
      sleepBedtime = settingsMap['sleep_target_bedtime'] ?? '23:30';
      sleepWake = settingsMap['sleep_target_wake'] ?? '07:00';
      
      final dayAgenda = await DayAgendaService.instance.agendaForDate(date);
      
      var bedtime = 1410; // 23:30
      var wake = 420; // 07:00
      try {
        final bp = sleepBedtime.split(':');
        bedtime = int.parse(bp[0]) * 60 + int.parse(bp[1]);
      } catch (_) {}
      try {
        final wp = sleepWake.split(':');
        wake = int.parse(wp[0]) * 60 + int.parse(wp[1]);
      } catch (_) {}

      final isSleepCrossMidnight = bedtime > wake;
      
      final ranges = <OccupiedRange>[];
      if (isSleepCrossMidnight) {
        ranges.add(OccupiedRange(start: bedtime, end: 1440, title: 'خواب', timeStr: sleepBedtime));
        ranges.add(OccupiedRange(start: 0, end: wake, title: 'خواب', timeStr: '۰۰:۰۰'));
      } else {
        ranges.add(OccupiedRange(start: bedtime, end: wake, title: 'خواب', timeStr: sleepBedtime));
      }

      for (final item in dayAgenda.items) {
        if (item.timeOfDay != null && item.timeOfDay!.isNotEmpty) {
          final parts = item.timeOfDay!.split(':');
          if (parts.length >= 2) {
            final h = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[1]) ?? 0;
            final start = h * 60 + m;
            
            var dur = item.durationMinutes ?? 15;
            if (item.durationMinutes == null && item.domain == AgendaDomain.prayer) {
              if (item.windowStart != null && item.windowEnd != null) {
                final diff = item.windowEnd!.difference(item.windowStart!).inMinutes;
                if (diff > 0) dur = diff;
              } else {
                dur = 20;
              }
            }
            ranges.add(OccupiedRange(
              start: start,
              end: start + dur,
              title: item.title,
              timeStr: item.timeOfDay!,
            ));
          }
        }
      }
      
      occupiedRanges = ranges;
      suggestedTimeSlots = _calculateSuggestions(bedtime, wake, isSleepCrossMidnight);
    } catch (e) {
      debugPrint('Error loading occupancy: $e');
    } finally {
      isOccupancyLoading = false;
      notifyListeners();
    }
  }

  List<String> _calculateSuggestions(int bedtime, int wake, bool isSleepCrossMidnight) {
    final suggestions = <String>[];
    final duration = targetDuration;
    
    final startLimit = wake;
    final endLimit = isSleepCrossMidnight ? bedtime : 1440;
    
    for (var t = startLimit; t + duration <= endLimit; t += 15) {
      final start = t;
      final end = t + duration;
      
      var overlaps = false;
      for (final occ in occupiedRanges) {
        if (start < occ.end && occ.start < end) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        final h = start ~/ 60;
        final m = start % 60;
        final timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        suggestions.add(timeStr);
        if (suggestions.length >= 3) break;
      }
    }
    
    return suggestions;
  }

  Future<List<Map<String, dynamic>>> getFrequentStations() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT r.title, r.category, rs.timeOfDay, COUNT(c.id) as completionCount
        FROM routine_completions c
        JOIN routines r ON c.routineId = r.id
        JOIN routine_schedules rs ON rs.routineId = r.id
        WHERE c.createdAt >= ? AND r.isArchived = 0
        GROUP BY r.title, r.category, rs.timeOfDay
        ORDER BY completionCount DESC
        LIMIT 3
      ''', [thirtyDaysAgo]);
      
      if (results.isEmpty) {
        final List<Map<String, dynamic>> fallback = await db.rawQuery('''
          SELECT r.title, r.category, rs.timeOfDay
          FROM routines r
          JOIN routine_schedules rs ON rs.routineId = r.id
          WHERE r.isArchived = 0
          ORDER BY r.updatedAt DESC
          LIMIT 3
        ''');
        return fallback;
      }
      return results;
    } catch (e) {
      debugPrint('Error getting frequent stations: $e');
      return [];
    }
  }

  Future<void> loadFrequentStations() async {
    frequentStations = await getFrequentStations();
    notifyListeners();
  }

  void applyFrequentStation(Map<String, dynamic> station) {
    final stationTitle = station['title'] as String? ?? '';
    title = stationTitle;
    inputController.text = stationTitle;
    
    final catStr = station['category'] as String? ?? 'personal';
    selectedCategory = Category.values.firstWhere((e) => e.name == catStr, orElse: () => Category.personal);
    
    final timeStr = station['timeOfDay'] as String? ?? '08:00';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    
    rawInputText = '';
    isTimeParsed = true;
    isRecurrenceParsed = false;
    isDurationParsed = false;
    isDateParsed = false;
    rejectedEntities.clear();
    
    notifyListeners();
  }

  void triggerVoiceSimulate() {
    isListening = true;
    notifyListeners();

    Timer(const Duration(seconds: 3), () {
      isListening = false;
      inputController.text = 'فردا ساعت ۸ باشگاه ورزشی بروم';
      parseNLPText();
    });
  }

  void parseNLPText() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    onInputTextChanged(text, immediate: true);
    updatePage(1);
  }

  void adjustDuration(int delta) {
    targetDuration = (targetDuration + delta).clamp(15, 180);
    
    var bedtime = 1410; // 23:30
    var wake = 420; // 07:00
    try {
      final bp = sleepBedtime.split(':');
      bedtime = int.parse(bp[0]) * 60 + int.parse(bp[1]);
    } catch (_) {}
    try {
      final wp = sleepWake.split(':');
      wake = int.parse(wp[0]) * 60 + int.parse(wp[1]);
    } catch (_) {}
    final isSleepCrossMidnight = bedtime > wake;
    suggestedTimeSlots = _calculateSuggestions(bedtime, wake, isSleepCrossMidnight);
    
    notifyListeners();
  }

  void setTime(TimeOfDay time) {
    selectedTime = time;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    loadOccupancyForDate(date);
    notifyListeners();
  }

  /// Builds an immutable snapshot of the controller's current state.
  /// This is passed to the strategy so strategies never import PlannerController.
  PlannerSaveContext _buildSaveContext() {
    return PlannerSaveContext(
      title: title,
      description: description,
      notes: notes,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      isEditing: isEditing,
      routineToEdit: routineToEdit,
      selectedCategory: selectedCategory,
      itemType: itemType,
      // Generic
      recurrenceType: recurrenceType,
      targetDuration: targetDuration,
      reminderOffsetMinutes: reminderOffsetMinutes,
      priority: priority,
      energyRule: energyRule,
      dependsOnRoutineId: dependsOnRoutineId,
      selectedZoneId: selectedZoneId,
      // Worship
      worshipType: worshipType,
      worshipDebtType: worshipDebtType,
      worshipTotalCount: worshipTotalCount,
      worshipDailyTarget: worshipDailyTarget,
      worshipReminderAnchor: worshipReminderAnchor,
      worshipOffsetMinutes: worshipOffsetMinutes,
      worshipSelectedDays: worshipSelectedDays,
      worshipRepeatType: worshipRepeatType,
      // Sports
      sportsOpType: sportsOpType,
      sportsType: sportsType,
      sportsDuration: sportsDuration,
      sportsIntensity: sportsIntensity,
      sportsLocation: sportsLocation,
      sportsFeeling: sportsFeeling,
      // Medical
      medicalMode: medicalMode,
      medicalTimes: medicalTimes,
      medicalStockCount: medicalStockCount,
      medicalRefillWarning: medicalRefillWarning,
      medicalMinIntervalHours: medicalMinIntervalHours,
      medicalMaxDosesPerDay: medicalMaxDosesPerDay,
      // Course
      courseType: courseType,
      courseTotalSessions: courseTotalSessions,
      courseWeeklyTarget: courseWeeklyTarget,
      courseSessionDuration: courseSessionDuration,
      coursePreferredDays: coursePreferredDays,
      coursePreferredTime: coursePreferredTime,
      // Goal
      goalType: goalType,
      goalTargetDate: goalTargetDate,
      goalSteps: goalSteps,
      // Reflection
      reflectionMood: reflectionMood,
      reflectionWins: reflectionWins,
      reflectionGratitude: reflectionGratitude,
      reflectionLearnings: reflectionLearnings,
      reflectionIsPrivate: reflectionIsPrivate,
    );
  }

  Future<void> save(BuildContext context) async {
    // Medical: medication is saved now since the user confirmed on Step 3
    if (selectedCategory == Category.medical) {
      if (tempMedicationData != null) {
        try {
          await MedicationSaveHelper.save(tempMedicationData!);
        } catch (e) {
          debugPrint('Save medical error: $e');
          RitmoToast.show(context, 'خطا در ثبت دارو: $e', icon: Icons.error_outline, iconColor: Colors.red);
          return;
        }
      }
      showSuccessAnim = true;
      notifyListeners();
      Timer(const Duration(milliseconds: 1400), () {
        onSaved();
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
      return;
    }

    if (title.trim().isEmpty) {
      RitmoToast.show(context, 'لطفاً عنوان فعالیت را وارد کنید.', icon: Icons.warning_rounded, iconColor: Colors.amber);
      updatePage(0);
      return;
    }

    try {
      final saveCtx = _buildSaveContext();
      final strategy = PlannerStrategyRegistry.resolve(
        selectedCategory,
        itemType: itemType,
      );
      await strategy.save(saveCtx, context);

      showSuccessAnim = true;
      notifyListeners();

      Timer(const Duration(milliseconds: 1400), () {
        onSaved();
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      debugPrint('Save error: $e');
      RitmoToast.show(context, 'خطا در ثبت اطلاعات: $e', icon: Icons.error_outline, iconColor: Colors.red);
    }
  }
}
