import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/conflict_checker.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/goals/presentation/widgets/goals_formatters.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';

class RoutineCreateFlow extends StatefulWidget {

  const RoutineCreateFlow({required this.onSaved, super.key, this.routineToEdit});
  final Map<String, dynamic>? routineToEdit;
  final VoidCallback onSaved;

  @override
  State<RoutineCreateFlow> createState() => _RoutineCreateFlowState();
}

class _RoutineCreateFlowState extends State<RoutineCreateFlow> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _originalRoutineData;
  Map<String, dynamic>? _originalScheduleData;
  String _lastSavedEditScope = 'future';

  // AI Quick Add Controller
  final TextEditingController _quickAddController = TextEditingController();
  bool _isAnalyzing = false;
  String _quickAddStatusMessage = '';
  Color _quickAddStatusColor = Colors.green;

  // Core Form Fields
  String _itemType = 'ROUTINE'; // 'ROUTINE' | 'REMINDER' | 'TASK'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Category _selectedCategory = Category.personal;
  CustomCategory? _selectedCustomCategory;
  List<CustomCategory> _customCategories = [];

  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime _taskDate = DateTime.now(); // For TASK type, date is stored in RecurrenceRule's startDate/endDate

  // Recurrence configuration (only for ROUTINE)
  String _recurrenceType = 'EVERY_DAY'; // 'EVERY_DAY', 'INTERVAL_DAYS', 'INTERVAL_HOURS', 'CUSTOM_DAYS', 'MONTHLY'
  int _intervalDays = 2;
  int _intervalHours = 8;
  Set<int> _customWeekdays = {6, 7, 1, 2, 3, 4, 5}; // 6=Sat, 7=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri
  final int _monthDay = 15;

  // Collapsible panel state
  bool _isMoreOptionsExpanded = false;

  // More Options Fields
  double _priority = 1; // 0.5=Low, 1.0=Medium, 1.5=High, 2.0=Critical
  bool _isEssential = false;
  String? _selectedZoneId;
  String? _dependsOnRoutineId;
  int _targetDuration = 30;
  bool _conflictWarningBypassed = false;

  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _activeRoutines = [];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    _loadZones();
    _loadActiveRoutines();
    if (widget.routineToEdit != null) {
      _loadRoutineData(widget.routineToEdit!);
    }
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomCategories() async {
    final list = await DatabaseHelper.instance.getCustomCategories();
    setState(() {
      _customCategories = list.map(CustomCategory.fromMap).toList();
      if (widget.routineToEdit != null) {
        final customCatId = widget.routineToEdit!['customCategoryId'] as String?;
        if (customCatId != null) {
          _selectedCustomCategory = _customCategories.firstWhere(
            (c) => c.id == customCatId,
            orElse: () => _customCategories.first,
          );
        }
      }
    });
  }

  Future<void> _loadZones() async {
    final db = await DatabaseHelper.instance.database;
    final list = await db.query('zones');
    setState(() {
      _zones = list;
    });
  }

  Future<void> _loadActiveRoutines() async {
    final db = await DatabaseHelper.instance.database;
    final list = await db.query('routines', where: 'isArchived = 0', orderBy: 'title ASC');
    setState(() {
      _activeRoutines = list;
    });
  }

  Future<void> _loadRoutineData(Map<String, dynamic> data) async {
    _originalRoutineData = Map<String, dynamic>.from(data);
    _titleController.text = data['title'] as String? ?? '';
    _descriptionController.text = data['description'] as String? ?? '';
    _selectedCategory = Category.values.firstWhere((e) => e.name == data['category'], orElse: () => Category.personal);
    _isEssential = data['isEssential'] == 1;
    _selectedZoneId = data['zoneId'] as String?;
    _priority = data['priority'] as double? ?? 1.0;
    final dbDuration = data['targetDurationMinutes'] as int? ?? 30;
    _targetDuration = dbDuration < 5 ? 30 : dbDuration;
    _itemType = data['itemType'] as String? ?? 'ROUTINE';
    _dependsOnRoutineId = data['dependsOnRoutineId'] as String?;

    try {
      final db = await DatabaseHelper.instance.database;
      final schedules = await db.query(
        'routine_schedules',
        where: 'routineId = ?',
        whereArgs: [data['id']],
      );
      if (schedules.isNotEmpty) {
        final sched = schedules.first;
        _originalScheduleData = Map<String, dynamic>.from(sched);
        final timeStr = sched['timeOfDay'] as String? ?? '08:00';
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          _reminderTimes = [
            TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts[1]) ?? 0,
            )
          ];
        }

        if (sched['recurrenceRule'] != null) {
          final rule = RecurrenceRule.fromMap(jsonDecode(sched['recurrenceRule']! as String) as Map<String, dynamic>);
          if (rule.weekdays.isNotEmpty) {
            if (rule.weekdays.length == 7) {
              _recurrenceType = 'EVERY_DAY';
            } else {
              _recurrenceType = 'CUSTOM_DAYS';
              _customWeekdays = rule.weekdays.toSet();
            }
          } else if (rule.intervalDays != null) {
            _recurrenceType = 'INTERVAL_DAYS';
            _intervalDays = rule.intervalDays!;
          } else if (rule.intervalHours != null) {
            _recurrenceType = 'INTERVAL_HOURS';
            _intervalHours = rule.intervalHours!;
          } else if (rule.monthDay != null) {
            _recurrenceType = 'MONTHLY';
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading routine schedule: $e');
    }

    setState(() {});
  }

  Future<String?> _showEditSafetyDialog() {
    return showGeneralDialog<String>(
      context: context,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final colors = context.colors;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: RitmoTheme.glassCardLight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'اعمال تغییرات روتین',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'شما زمان‌بندی یا تعریف این روتین را تغییر دادید. این تغییرات روی کدام بخش اعمال شود؟',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: () => Navigator.pop(context, 'future'),
                      child: const Text('فقط از امروز به بعد (رخدادهای گذشته دست‌نخورده)', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: () => Navigator.pop(context, 'all'),
                      child: const Text('همه رخدادها (شامل گذشته)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('انصراف', style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  // AI & Local Quick Add Processing
  Future<void> _processQuickAdd() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _quickAddStatusMessage = '';
    });

    try {
      final parsed = await AIGateway.instance.parseQuickAdd(text);
      if (parsed == null) {
        _applyLocalFallback(text, 'پردازش توسط پارسر محلی انجام شد (خطا در ارتباط با هوش مصنوعی).');
      } else {
        _applyParsedResult(parsed);
        setState(() {
          _quickAddStatusMessage = 'پردازش با موفقیت توسط هوش مصنوعی انجام شد.';
          _quickAddStatusColor = context.colors.success;
        });
      }
    } catch (e) {
      if (e.toString().contains('Daily free AI quota')) {
        _applyLocalFallback(text, 'سهمیه رایگان روزانه هوش مصنوعی به پایان رسیده است (پردازش محلی).');
      } else {
        _applyLocalFallback(text, 'پردازش توسط پارسر محلی انجام شد (خطای سیستمی).');
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _applyLocalFallback(String text, String warningMessage) {
    final localParsed = QuickAddParser.parse(text);
    setState(() {
      _titleController.text = localParsed.title;
      _itemType = localParsed.itemType;
      if (localParsed.timeOfDay != null) {
        _reminderTimes = [localParsed.timeOfDay!];
      }
      _recurrenceType = localParsed.recurrenceType;
      if (localParsed.intervalDays != null) {
        _intervalDays = localParsed.intervalDays!;
      }
      if (localParsed.intervalHours != null) {
        _intervalHours = localParsed.intervalHours!;
      }
      if (localParsed.weekdays != null) {
        _customWeekdays = localParsed.weekdays!;
      }
      if (localParsed.daysOffset != null) {
        _taskDate = DateTime.now().add(Duration(days: localParsed.daysOffset!));
      } else {
        _taskDate = DateTime.now();
      }
      if (localParsed.targetDurationMinutes != null) {
        _targetDuration = localParsed.targetDurationMinutes!;
      }
      _quickAddStatusMessage = warningMessage;
      _quickAddStatusColor = context.colors.warning;
    });
  }

  void _applyParsedResult(Map<String, dynamic> parsed) {
    setState(() {
      _titleController.text = parsed['title'] as String? ?? '';
      _itemType = parsed['itemType'] as String? ?? 'ROUTINE';
      final timeStr = parsed['time'] as String?;
      if (timeStr != null && timeStr.contains(':')) {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final min = int.tryParse(parts[1]) ?? 0;
        _reminderTimes = [TimeOfDay(hour: hour, minute: min)];
      }
      _recurrenceType = parsed['recurrenceType'] as String? ?? 'EVERY_DAY';
      if (parsed['intervalDays'] != null) {
        _intervalDays = (parsed['intervalDays'] as num).toInt();
      }
      if (parsed['intervalHours'] != null) {
        _intervalHours = (parsed['intervalHours'] as num).toInt();
      }
      if (parsed['weekdays'] != null) {
        _customWeekdays = List<int>.from(parsed['weekdays'] as Iterable).toSet();
      }
      if (parsed['daysOffset'] != null) {
        _taskDate = DateTime.now().add(Duration(days: (parsed['daysOffset'] as num).toInt()));
      } else {
        _taskDate = DateTime.now();
      }
      if (parsed['durationMinutes'] != null) {
        _targetDuration = (parsed['durationMinutes'] as num).toInt();
      }
    });
  }

  RecurrenceRule _buildRecurrenceRule() {
    var weekdays = <int>[];
    int? intervalDays;
    int? intervalHours;
    int? monthDay;
    DateTime? startDate = DateTime.now();
    DateTime? endDate;

    if (_itemType == 'TASK') {
      // One-time task: set start/end date to the task date, and make it everyday so it occurs exactly on that day
      startDate = DateTime(_taskDate.year, _taskDate.month, _taskDate.day);
      endDate = DateTime(_taskDate.year, _taskDate.month, _taskDate.day, 23, 59, 59);
      weekdays = [1, 2, 3, 4, 5, 6, 7];
    } else if (_itemType == 'ROUTINE' || _itemType == 'REMINDER') {
      if (_recurrenceType == 'EVERY_DAY') {
        weekdays = [6, 7, 1, 2, 3, 4, 5];
      } else if (_recurrenceType == 'CUSTOM_DAYS') {
        weekdays = _customWeekdays.toList();
      } else if (_recurrenceType == 'INTERVAL_DAYS') {
        intervalDays = _intervalDays;
      } else if (_recurrenceType == 'INTERVAL_HOURS') {
        intervalHours = _intervalHours;
      } else if (_recurrenceType == 'MONTHLY') {
        monthDay = _monthDay;
      }
    }

    return RecurrenceRule(
      weekdays: weekdays,
      intervalDays: intervalDays,
      intervalHours: intervalHours,
      monthDay: monthDay,
      startDate: startDate,
      endDate: endDate,
      reminderTimes: _reminderTimes.map((t) {
        final hr = t.hour.toString().padLeft(2, '0');
        final mn = t.minute.toString().padLeft(2, '0');
        return '$hr:$mn';
      }).toList(),
    );
  }

  bool _hasCycle(String childId, String parentId, Map<String, String?> dependencyMap) {
    String? current = parentId;
    while (current != null) {
      if (current == childId) return true;
      current = dependencyMap[current];
    }
    return false;
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    final colors = context.colors;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Check premium limits for new items
    if (widget.routineToEdit == null && !PremiumService.instance.can(PremiumFeature.unlimitedRoutines)) {
      final db = await DatabaseHelper.instance.database;
      final activeCountQuery = await db.rawQuery(
        'SELECT COUNT(*) as count FROM routines WHERE isArchived = 0'
      );
      final activeCount = (activeCountQuery.first['count'] as num?)?.toInt() ?? 0;
      final limit = PremiumService.instance.limitFor(PremiumFeature.unlimitedRoutines);

      if (activeCount >= limit && mounted) {
        PremiumUpgradeSheet.show(context);
        return;
      }
    }

    // Check conflicts before saving
    if (!_conflictWarningBypassed && _reminderTimes.isNotEmpty) {
      final timeStr = '${_reminderTimes.first.hour.toString().padLeft(2, '0')}:${_reminderTimes.first.minute.toString().padLeft(2, '0')}';
      final dateStr = _itemType == 'TASK'
          ? '${_taskDate.year}-${_taskDate.month.toString().padLeft(2, '0')}-${_taskDate.day.toString().padLeft(2, '0')}'
          : '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

      final conflicts = await ConflictChecker.checkConflicts(
        timeStr: timeStr,
        durationMinutes: _targetDuration,
        dateStr: dateStr,
        ignoreSourceId: widget.routineToEdit != null ? widget.routineToEdit!['id'] as String? : null,
      );

      if (conflicts.isNotEmpty && mounted) {
        final conflictTitles = conflicts.map((c) => '"${c.title}" (ساعت ${c.timeOfDay})').join(' و ');
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.card,
            title: Text(
              'هشدار تداخل زمانی',
              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            content: Text(
              'زمان انتخابی با $conflictTitles تداخل دارد.\nآیا می‌خواهید روتین در همین ساعت ذخیره شود؟',
              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('تغییر زمان', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.primary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
                child: const Text('همین‌جا ذخیره کن', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
              ),
            ],
          ),
        );

        if (proceed != true) {
          return;
        }
        _conflictWarningBypassed = true;
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = widget.routineToEdit != null
        ? widget.routineToEdit!['id'] as String
        : 'routine_$now';

    var editScope = 'future';
    if (widget.routineToEdit != null) {
      final scope = await _showEditSafetyDialog();
      if (scope == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تغییرات ذخیره نشد.', style: TextStyle(fontFamily: 'Vazirmatn')),
              backgroundColor: colors.warning,
            ),
          );
        }
        return;
      }
      editScope = scope;
      _lastSavedEditScope = editScope;
    }

    final customCatId = _selectedCategory == Category.custom ? _selectedCustomCategory?.id : null;

    // Validate cycle for stack routine dependency
    if (_dependsOnRoutineId != null) {
      final depMap = <String, String?>{
        for (final r in _activeRoutines) r['id'] as String: r['dependsOnRoutineId'] as String?
      };
      if (_hasCycle(id, _dependsOnRoutineId!, depMap)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('چرخه وابستگی شناسایی شد! این وابستگی غیر مجاز است.', style: TextStyle(fontFamily: 'Vazirmatn')),
              backgroundColor: colors.medicalRed,
            ),
          );
        }
        return;
      }
    }

    final routineData = {
      'id': id,
      'title': title,
      'description': _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      'category': _selectedCategory.name,
      'customCategoryId': customCatId,
      'zoneId': _selectedZoneId,
      'routineType': _itemType == 'ROUTINE' ? RoutineType.timeBased.name : RoutineType.asNeeded.name,
      'notificationLevel': NotificationLevel.normal.name,
      'isEssential': (_itemType == 'ROUTINE' && _isEssential) ? 1 : 0,
      'isEssentialLocked': widget.routineToEdit != null ? widget.routineToEdit!['isEssentialLocked'] ?? 0 : 0,
      'energyRule': EnergyRule.none.name,
      'priority': _priority,
      'targetDurationMinutes': _targetDuration,
      'lightDurationMinutes': widget.routineToEdit != null ? widget.routineToEdit!['lightDurationMinutes'] ?? 0 : 0,
      'minimalDurationMinutes': widget.routineToEdit != null ? widget.routineToEdit!['minimalDurationMinutes'] ?? 0 : 0,
      'isArchived': 0,
      'isPrivate': widget.routineToEdit != null ? widget.routineToEdit!['isPrivate'] ?? 0 : 0,
      'displayOrder': widget.routineToEdit != null ? widget.routineToEdit!['displayOrder'] ?? 1 : 1,
      'createdAt': widget.routineToEdit != null ? widget.routineToEdit!['createdAt'] ?? now : now,
      'updatedAt': now,
      'dependsOnRoutineId': _itemType == 'ROUTINE' ? _dependsOnRoutineId : null,
      'itemType': _itemType,
    };

    final rule = _buildRecurrenceRule();
    final firstTime = rule.reminderTimes.isNotEmpty ? rule.reminderTimes.first : '08:00';
    final daysStr = rule.weekdays.join(',');

    final scheduleData = {
      'id': 'sched_$id',
      'routineId': id,
      'scheduleType': _itemType == 'TASK' ? 'DAILY' : (_recurrenceType == 'CUSTOM_DAYS' ? 'SPECIFIC_DAYS' : 'RECURRENCE'),
      'timeOfDay': firstTime,
      'daysOfWeek': daysStr.isNotEmpty ? daysStr : '6,7,1,2,3,4,5',
      'recurrenceRule': jsonEncode(rule.toMap()),
      'createdAt': widget.routineToEdit != null ? widget.routineToEdit!['createdAt'] ?? now : now,
      'updatedAt': now,
    };

    // Execute save transaction
    try {
      if (widget.routineToEdit != null) {
        await RitmoExecutionKernel.instance.execute(
          EditRoutineCommand(
            routineId: id,
            routineData: routineData,
            scheduleData: scheduleData,
            applyToAll: editScope == 'all',
          ),
        );
      } else {
        await RitmoExecutionKernel.instance.execute(
          CreateRoutineCommand(
            routineData: routineData,
            scheduleData: scheduleData,
          ),
        );
      }

      widget.onSaved();
      if (mounted) {
        final parentCtx = Navigator.of(context).context;
        Navigator.pop(context);

        final itemTypeName = _itemType == 'TASK'
            ? 'کار'
            : (_itemType == 'REMINDER' ? 'یادآور' : 'روتین');
        final message = widget.routineToEdit != null
            ? 'تغییرات $itemTypeName با موفقیت ذخیره شد.'
            : '$itemTypeName با موفقیت ثبت شد.';

        RitmoToast.show(
          parentCtx,
          message,
          iconColor: const Color(0xff10B981),
          onUndo: () async {
            try {
              if (widget.routineToEdit != null) {
                if (_originalRoutineData != null && _originalScheduleData != null) {
                  await RitmoExecutionKernel.instance.execute(
                    EditRoutineCommand(
                      routineId: id,
                      routineData: _originalRoutineData!,
                      scheduleData: _originalScheduleData!,
                      applyToAll: _lastSavedEditScope == 'all',
                    ),
                  );
                  widget.onSaved();
                  RitmoToast.show(
                    parentCtx,
                    'تغییرات لغو شد.',
                    icon: Icons.info_outline,
                    iconColor: Colors.blue,
                  );
                }
              } else {
                await RitmoExecutionKernel.instance.execute(
                  DeleteRoutineCommand(routineId: id),
                );
                widget.onSaved();
                RitmoToast.show(
                  parentCtx,
                  'ثبت $itemTypeName لغو شد.',
                  icon: Icons.info_outline,
                  iconColor: Colors.blue,
                );
              }
            } catch (undoErr) {
              debugPrint('Undo operation error: $undoErr');
            }
          },
        );
      }
    } catch (e, stack) {
      debugPrint('Save routine error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره: $e', style: const TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: colors.medicalRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.6 : 0.4),
                ),
              ),
            ),
          ),

          // Main form card
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.92,
              child: RitmoTheme.glassCardLight(
                borderRadius: 32,
                child: Column(
                  children: [
                    // Pull indicator
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48), // spacer to center
                          Text(
                            widget.routineToEdit != null ? 'ویرایش روتین' : 'ثبت جدید',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: colors.textPrimary, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Scrollable form body
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                          children: [
                            if (widget.routineToEdit == null) ...[
                              // Quick Add text field
                              _buildQuickAddWidget(),
                              const SizedBox(height: 16),
                            ],

                            // Segmented Item Type selector
                            _buildSegmentedTypeSelector(),
                            const SizedBox(height: 20),

                            // Layer 1 inputs: Title
                            _buildTextFormField(
                              controller: _titleController,
                              label: 'عنوان',
                              hint: _itemType == 'ROUTINE'
                                  ? 'مثال: مطالعه روزانه کتاب'
                                  : _itemType == 'REMINDER'
                                      ? 'مثال: خوردن قرص کلسیم'
                                      : 'مثال: فرستادن گزارش پروژه',
                              validator: (val) => val == null || val.trim().isEmpty ? 'وارد کردن عنوان الزامی است' : null,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _buildTextFormField(
                              controller: _descriptionController,
                              label: 'توضیحات (اختیاری)',
                              hint: 'توضیحات بیشتر...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            // Category Selector (Layer 1)
                            _buildCategorySelector(),
                            const SizedBox(height: 20),

                            // Dynamic Fields Container (Animated size morphing)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Time Selector (Layer 1)
                                  _buildTimeSelector(),
                                  const SizedBox(height: 20),

                                  // Recurrence Selector (Layer 1 - only for ROUTINE)
                                  if (_itemType == 'ROUTINE') ...[
                                    _buildRecurrenceSelector(),
                                    const SizedBox(height: 20),
                                  ],
                                ],
                              ),
                            ),

                            // Collapsible "گزینه‌های بیشتر" (Progressive Disclosure)
                            _buildCollapsibleMoreOptions(),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Save Button Area (Ergonomic thumb zone)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: colors.primary.withValues(alpha: 0.3),
                          ),
                          onPressed: _saveRoutine,
                          child: Text(
                            widget.routineToEdit != null ? 'ذخیره تغییرات' : 'ثبت و ذخیره جدید',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Quick Add Widget ---
  Widget _buildQuickAddWidget() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colors.primary.withValues(alpha: 0.1),
                  colors.primary.withValues(alpha: 0.04),
                ]
              : [
                  colors.primary.withValues(alpha: 0.06),
                  colors.primary.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_isAnalyzing) const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffD4A843)),
                    ) else GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _processQuickAdd();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bolt_rounded, color: colors.primary, size: 18),
                      ),
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quickAddController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                  decoration: InputDecoration(
                    hintText: 'افزودن سریع (مثال: کار جلسه کاری فردا ساعت ۱۵)',
                    hintStyle: TextStyle(fontSize: 12, color: colors.textSecondary.withValues(alpha: 0.6), fontFamily: 'Vazirmatn'),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          if (_quickAddStatusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _quickAddStatusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _quickAddStatusMessage,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _quickAddStatusColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Segmented Type Selector ---
  // --- Segmented Type Selector ---
  Widget _buildSegmentedTypeSelector() {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final buttonWidth = (totalWidth - 8) / 3;

        var selectedIndex = 0;
        if (_itemType == 'REMINDER') selectedIndex = 1;
        if (_itemType == 'ROUTINE') selectedIndex = 2;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.all(4),
          child: Stack(
            children: [
              // Slide background indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                right: selectedIndex * buttonWidth,
                left: (2 - selectedIndex) * buttonWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary,
                        colors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              // Buttons
              Row(
                children: [
                  _buildSegmentButton('TASK', '✅ کار', _itemType == 'TASK'),
                  _buildSegmentButton('REMINDER', '🔔 یادآور', _itemType == 'REMINDER'),
                  _buildSegmentButton('ROUTINE', '🔁 روال', _itemType == 'ROUTINE'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentButton(String type, String label, bool isSelected) {
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _itemType = type;
            if (type == 'TASK') {
              _reminderTimes = [const TimeOfDay(hour: 12, minute: 0)];
            }
          });
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : colors.textPrimary.withValues(alpha: 0.7),
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ),
    );
  }

  // --- TextField Helper ---
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontSize: 14, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13.5, color: colors.textSecondary.withValues(alpha: 0.8), fontFamily: 'Vazirmatn'),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: colors.textSecondary.withValues(alpha: 0.48), fontFamily: 'Vazirmatn'),
          filled: true,
          fillColor: colors.card.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.border.withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.border.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.8), width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // --- Category Selector ---
  Widget _buildCategorySelector() {
    final colors = context.colors;

    final defaultCats = [
      {'cat': Category.personal, 'title': 'شخصی 👤'},
      {'cat': Category.work, 'title': 'کار 💼'},
      {'cat': Category.free, 'title': 'فراغت 🌿'},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('دسته‌بندی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...defaultCats.map((item) {
                  final cat = item['cat']! as Category;
                  final title = item['title']! as String;
                  final isSelected = _selectedCategory == cat;
                  return _buildCategoryChip(cat, title, isSelected);
                }),
                ..._customCategories.map((cc) {
                  final isSelected = _selectedCategory == Category.custom && _selectedCustomCategory?.id == cc.id;
                  return _buildCategoryChip(Category.custom, '${cc.icon} ${cc.title}', isSelected, customCat: cc);
                }),
                // Add custom category button
                GestureDetector(
                  onTap: _showAddCustomCategoryDialog,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, size: 18, color: colors.primary),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Category cat, String title, bool isSelected, {CustomCategory? customCat}) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = cat;
          _selectedCustomCategory = customCat;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? colors.primary.withValues(alpha: 0.16) 
              : colors.card.withValues(alpha: 0.15),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colors.primary : colors.textPrimary.withValues(alpha: 0.8),
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }

  // --- Time Selector ---
  Widget _buildTimeSelector() {
    final colors = context.colors;

    if (_itemType == 'TASK') {
      // Single date and time picker for task
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تاریخ انجام کار', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final selected = await RitmoDatePicker.showJalali(
                        context: context,
                        initialDate: Jalali.fromDateTime(_taskDate),
                        firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 30))),
                        lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 365))),
                      );
                      if (selected != null) {
                        setState(() {
                          _taskDate = selected.toDateTime();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.card.withValues(alpha: 0.15),
                        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: colors.primary),
                          Text(
                            formatShamsiDate(_taskDate.toIso8601String().substring(0, 10)),
                            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ساعت یادآوری', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: _reminderTimes.first,
                      );
                      if (selected != null) {
                        setState(() {
                          _reminderTimes = [selected];
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.card.withValues(alpha: 0.15),
                        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.access_time_rounded, size: 18, color: colors.primary),
                          Text(
                            _reminderTimes.first.format(context),
                            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    // List of reminder times for ROUTINE and REMINDER
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ساعت‌های یادآوری / انجام', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              IconButton(
                icon: Icon(Icons.add_circle_rounded, color: colors.primary, size: 22),
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (selected != null) {
                    setState(() {
                      _reminderTimes.add(selected);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reminderTimes.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time.format(context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary, fontFamily: 'Vazirmatn')),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (_reminderTimes.length > 1) {
                          setState(() {
                            _reminderTimes.removeAt(index);
                          });
                        }
                      },
                      child: Icon(Icons.close_rounded, size: 14, color: colors.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Recurrence Selector ---
  Widget _buildRecurrenceSelector() {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تکرار', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _recurrenceType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'EVERY_DAY', child: Text('هر روز', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13))),
              DropdownMenuItem(value: 'INTERVAL_DAYS', child: Text('هر N روز', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13))),
              DropdownMenuItem(value: 'INTERVAL_HOURS', child: Text('هر N ساعت', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13))),
              DropdownMenuItem(value: 'CUSTOM_DAYS', child: Text('روزهای دلخواه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _recurrenceType = val;
                });
              }
            },
          ),
          if (_recurrenceType == 'INTERVAL_DAYS') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('هر چند روز یک‌بار؟', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                Text('هر $_intervalDays روز', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary, fontFamily: 'Vazirmatn')),
              ],
            ),
            Slider(
              value: _intervalDays.toDouble(),
              min: 2,
              max: 30,
              divisions: 28,
              onChanged: (val) {
                setState(() {
                  _intervalDays = val.round();
                });
              },
            ),
          ] else if (_recurrenceType == 'INTERVAL_HOURS') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('هر چند ساعت یک‌بار؟', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                Text('هر $_intervalHours ساعت', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary, fontFamily: 'Vazirmatn')),
              ],
            ),
            Slider(
              value: _intervalHours.toDouble(),
              min: 1,
              max: 48,
              divisions: 47,
              onChanged: (val) {
                setState(() {
                  _intervalHours = val.round();
                });
              },
            ),
          ] else if (_recurrenceType == 'CUSTOM_DAYS') ...[
            const SizedBox(height: 12),
            _buildCustomWeekdaysSelector(),
          ]
        ],
      ),
    );
  }

  Widget _buildCustomWeekdaysSelector() {
    final colors = context.colors;
    final weekdaysNames = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    final dartDays = [6, 7, 1, 2, 3, 4, 5];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = dartDays[index];
        final isSelected = _customWeekdays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                if (_customWeekdays.length > 1) {
                  _customWeekdays.remove(day);
                }
              } else {
                _customWeekdays.add(day);
              }
            });
          },
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : colors.card.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? colors.primary : colors.border),
            ),
            child: Text(
              weekdaysNames[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colors.textPrimary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        );
      }),
    );
  }





  // --- Collapsible "گزینه‌های بیشتر" ---
  Widget _buildCollapsibleMoreOptions() {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          const Divider(height: 30),
          GestureDetector(
            onTap: () {
              setState(() {
                _isMoreOptionsExpanded = !_isMoreOptionsExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('گزینه‌های بیشتر', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                Icon(_isMoreOptionsExpanded ? Icons.expand_less : Icons.expand_more, color: colors.textSecondary),
              ],
            ),
          ),
          if (_isMoreOptionsExpanded) ...[
            const SizedBox(height: 16),

             // Target Duration slider (for all types)
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(_itemType == 'ROUTINE' ? 'مدت زمان هدف' : 'مدت زمان', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                 Text('$_targetDuration دقیقه', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary, fontFamily: 'Vazirmatn')),
               ],
             ),
             Slider(
               value: _targetDuration.clamp(5, 180).toDouble(),
               min: 5,
               max: 180,
               divisions: 35,
               onChanged: (val) {
                 setState(() {
                   _targetDuration = val.round();
                 });
               },
             ),
             const SizedBox(height: 12),

              // Essential Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('آیا این روال حیاتی (Essential) است؟', style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                  Switch(
                    value: _isEssential,
                    activeThumbColor: colors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isEssential = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            // Priority (Chips)
            Text('اولویت', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityChip(0.5, 'کم'),
                _buildPriorityChip(1, 'متوسط'),
                _buildPriorityChip(1.5, 'زیاد'),
                _buildPriorityChip(2, 'حیاتی'),
              ],
            ),
            const SizedBox(height: 16),

            // Zone Selector
            Text('محدودیت قلمرو زمانی (Zone)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _selectedZoneId,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(child: Text('بدون محدودیت', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13))),
                ..._zones.map((z) => DropdownMenuItem(
                      value: z['id'] as String,
                      child: Text(z['name'] as String? ?? '', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                    )),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedZoneId = val;
                });
              },
            ),
            const SizedBox(height: 16),

            // Habit Stacking Dependency Selector (only for ROUTINE)
            if (_itemType == 'ROUTINE') ...[
              Text('وابستگی به روال دیگر (Habit Stacking)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _dependsOnRoutineId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(child: Text('بدون وابستگی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13))),
                  ..._activeRoutines.map((r) => DropdownMenuItem(
                        value: r['id'] as String,
                        child: Text(r['title'] as String? ?? '', style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                      )),
                ],
                onChanged: (val) {
                  if (val != null && !_validateDependency(val)) {
                    return;
                  }
                  setState(() {
                    _dependsOnRoutineId = val;
                  });
                },
              ),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildPriorityChip(double priority, String label) {
    final colors = context.colors;
    final isSelected = _priority == priority;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _priority = priority;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.card.withValues(alpha: 0.3),
            border: Border.all(color: isSelected ? colors.primary : colors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.primary : colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ),
    );
  }

  bool _validateDependency(String parentId) {
    final colors = context.colors;
    final depMap = <String, String?>{
      for (final r in _activeRoutines) r['id'] as String: r['dependsOnRoutineId'] as String?
    };
    // To prevent immediate trivial self dependency or self stack dependency loops
    if (_hasCycle('new_routine', parentId, depMap)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('انتخاب این وابستگی باعث ایجاد چرخه و بن‌بست می‌شود!', style: TextStyle(fontFamily: 'Vazirmatn')),
          backgroundColor: colors.medicalRed,
        ),
      );
      return false;
    }
    return true;
  }

  // --- Add Custom Category Dialog ---
  void _showAddCustomCategoryDialog() {
    final titleController = TextEditingController();
    var selectedEmoji = '🏷️';
    const selectedColor = Color(0xff3B6FE0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = context.colors;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: colors.card,
                title: const Text('ایجاد دسته‌بندی سفارشی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'عنوان دسته‌بندی',
                        labelStyle: TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('آیکون / اموجی', style: TextStyle(fontFamily: 'Vazirmatn')),
                        DropdownButton<String>(
                          value: selectedEmoji,
                          items: ['🏷️', '💼', '🏃', '📚', '🎨', '🍳', '🛒', '🛠️', '💻']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedEmoji = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('لغو', style: TextStyle(fontFamily: 'Vazirmatn')),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      final hexColor = '#${selectedColor.toARGB32().toRadixString(16).substring(2)}';
                      final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';

                      final newCat = CustomCategory(
                        id: customId,
                        title: title,
                        icon: selectedEmoji,
                        color: hexColor,
                        sortOrder: _customCategories.length,
                        createdAt: DateTime.now(),
                      );

                      await DatabaseHelper.instance.insertCustomCategory(newCat.toMap());
                      await _loadCustomCategories();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('ایجاد', style: TextStyle(fontFamily: 'Vazirmatn')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
