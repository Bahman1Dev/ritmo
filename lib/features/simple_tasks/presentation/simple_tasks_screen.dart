import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';
import 'package:ritmo/features/routines/presentation/universal_planner_sheet.dart';
import 'package:ritmo/features/search/presentation/global_search_screen.dart';
import 'package:ritmo/features/simple_tasks/data/simple_task_repository.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';

class SimpleTasksScreen extends StatefulWidget {
  const SimpleTasksScreen({super.key, this.focusAddField = false});

  final bool focusAddField;

  @override
  State<SimpleTasksScreen> createState() => _SimpleTasksScreenState();
}

class _SimpleTasksScreenState extends State<SimpleTasksScreen> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();

  List<SimpleTask> _todayTasks = [];
  List<SimpleTask> _upcomingTasks = [];
  List<SimpleTask> _somedayTasks = [];
  List<SimpleTask> _doneTodayTasks = [];

  bool _isLoading = true;
  bool _upcomingExpanded = true;
  bool _somedayExpanded = true;
  bool _doneTodayExpanded = false;

  String? _editingTaskId;
  final TextEditingController _inlineEditController = TextEditingController();

  String get _todayIso => DayKey.from(DateTime.now()).value;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    if (widget.focusAddField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    _inlineEditController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final repository = SimpleTaskRepository.instance;
    final today = await repository.today(_todayIso);
    final upcoming = await repository.upcoming(_todayIso);
    final someday = await repository.someday();
    final done = await repository.doneToday(_todayIso);

    if (mounted) {
      setState(() {
        _todayTasks = today;
        _upcomingTasks = upcoming;
        _somedayTasks = someday;
        _doneTodayTasks = done;
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    final result = QuickAddParser.parse(text);

    String? dueDate;
    String? dueTime;

    if (result.daysOffset != null) {
      final targetDate = DateTime.now().add(Duration(days: result.daysOffset!));
      dueDate = DayKey.from(targetDate).value;
    }

    if (result.timeOfDay != null) {
      final hh = result.timeOfDay!.hour.toString().padLeft(2, '0');
      final mm = result.timeOfDay!.minute.toString().padLeft(2, '0');
      dueTime = '$hh:$mm';
    }

    // Use clean title if parsed, otherwise original text
    final titleToSave = result.title.isNotEmpty ? result.title : text;

    final created = await SimpleTaskRepository.instance.create(
      title: titleToSave,
      dueDate: dueDate,
      dueTime: dueTime,
    );

    _addController.clear();
    _addFocusNode.requestFocus();
    await _loadTasks();

    if (mounted && dueDate != null) {
      final dateLabel = result.daysOffset == 1
          ? 'فردا'
          : (result.daysOffset == 0 ? 'امروز' : dueDate);
      RitmoToast.show(
        context,
        'برای $dateLabel ثبت شد',
        actionLabel: 'بدون تاریخ',
        onAction: () async {
          await SimpleTaskRepository.instance.updateTask(created.copyWith(dueDate: null, dueTime: null));
          unawaited(_loadTasks());
        },
      );
    }
  }

  Future<void> _toggleDone(SimpleTask task) async {
    RitmoHaptics.tap();
    final newDoneState = !task.isDone;
    await SimpleTaskRepository.instance.setDone(task.id, done: newDoneState);
    await _loadTasks();

    if (mounted) {
      RitmoToast.show(
        context,
        newDoneState ? 'انجام شد' : 'بازگردانی شد',
        actionLabel: 'برگردان',
        onAction: () async {
          await SimpleTaskRepository.instance.setDone(task.id, done: !newDoneState);
          unawaited(_loadTasks());
        },
      );
    }
  }

  Future<void> _deleteTask(SimpleTask task) async {
    RitmoHaptics.tap();
    await SimpleTaskRepository.instance.delete(task.id);
    await _loadTasks();

    if (mounted) {
      RitmoToast.show(
        context,
        'حذف شد',
        actionLabel: 'برگردان',
        onAction: () async {
          await SimpleTaskRepository.instance.restoreTask(task);
          unawaited(_loadTasks());
        },
      );
    }
  }

  void _startInlineEdit(SimpleTask task) {
    setState(() {
      _editingTaskId = task.id;
      _inlineEditController.text = task.title;
    });
  }

  Future<void> _saveInlineEdit(SimpleTask task) async {
    final newTitle = _inlineEditController.text.trim();
    if (newTitle.isNotEmpty && newTitle != task.title) {
      await SimpleTaskRepository.instance.updateTask(task.copyWith(title: newTitle));
      await _loadTasks();
    }
    setState(() {
      _editingTaskId = null;
    });
  }

  Future<void> _pickDateForTask(SimpleTask task) async {
    final now = DateTime.now();
    final initialDate = task.dueDate != null ? DateTime.tryParse(task.dueDate!) ?? now : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      final iso = DayKey.from(picked).value;
      await SimpleTaskRepository.instance.updateTask(task.copyWith(dueDate: iso));
      await _loadTasks();
    }
  }

  void _openTaskDetailsSheet(SimpleTask task) {
    RitmoHaptics.tap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskDetailsSheet(
        task: task,
        onUpdated: _loadTasks,
        onDeleted: () => _deleteTask(task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final totalActiveCount = _todayTasks.length + _upcomingTasks.length + _somedayTasks.length;
    final isEverythingEmpty = totalActiveCount == 0 && _doneTodayTasks.isEmpty;
    final isTodayDone = _todayTasks.isEmpty && _doneTodayTasks.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Title & Search Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'کارها',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.search, color: colors.textSecondary, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GlobalSearchScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Sticky Inline Add Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addController,
                        focusNode: _addFocusNode,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addTask(),
                        decoration: InputDecoration(
                          hintText: 'یک کار بنویس…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary.withValues(alpha: 0.6),
                            fontFamily: 'Vazirmatn',
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.add_circled_solid, color: colors.primary, size: 28),
                      onPressed: _addTask,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isEverythingEmpty
                      ? _buildEmptyState(
                          message: 'چیزی برای امروز نداری.',
                          colors: colors,
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            // Today's Empty state (if all done today)
                            if (isTodayDone)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF10B981), size: 44),
                                    const SizedBox(height: 8),
                                    Text(
                                      'همهٔ کارهای امروز انجام شد.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textSecondary,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Today Bucket
                            if (_todayTasks.isNotEmpty) ...[
                              ..._todayTasks.map((t) => _buildTaskRow(t)),
                              const SizedBox(height: 16),
                            ],

                            // Upcoming Bucket (بعداً)
                            if (_upcomingTasks.isNotEmpty) ...[
                              _buildBucketHeader(
                                title: 'بعداً (${toPersianDigits(_upcomingTasks.length)})',
                                isExpanded: _upcomingExpanded,
                                onToggle: () => setState(() => _upcomingExpanded = !_upcomingExpanded),
                                colors: colors,
                              ),
                              if (_upcomingExpanded)
                                ..._upcomingTasks.map((t) => _buildTaskRow(t)),
                              const SizedBox(height: 16),
                            ],

                            // Someday Bucket (هر وقت شد) - with Reorder support
                            if (_somedayTasks.isNotEmpty) ...[
                              _buildBucketHeader(
                                title: 'هر وقت شد (${toPersianDigits(_somedayTasks.length)})',
                                isExpanded: _somedayExpanded,
                                onToggle: () => setState(() => _somedayExpanded = !_somedayExpanded),
                                colors: colors,
                              ),
                              if (_somedayExpanded)
                                ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _somedayTasks.length,
                                  onReorder: (oldIndex, newIndex) async {
                                    if (newIndex > oldIndex) newIndex -= 1;
                                    final items = List<SimpleTask>.from(_somedayTasks);
                                    final moved = items.removeAt(oldIndex);
                                    items.insert(newIndex, moved);
                                    setState(() => _somedayTasks = items);
                                    await SimpleTaskRepository.instance.reorder(items.map((e) => e.id).toList());
                                  },
                                  itemBuilder: (context, index) {
                                    final t = _somedayTasks[index];
                                    return KeyedSubtree(
                                      key: ValueKey(t.id),
                                      child: _buildTaskRow(t, isSomeday: true),
                                    );
                                  },
                                ),
                              const SizedBox(height: 16),
                            ],

                            // Done Today Bucket (انجام‌شده امروز)
                            if (_doneTodayTasks.isNotEmpty) ...[
                              _buildBucketHeader(
                                title: 'انجام‌شده امروز (${toPersianDigits(_doneTodayTasks.length)})',
                                isExpanded: _doneTodayExpanded,
                                onToggle: () => setState(() => _doneTodayExpanded = !_doneTodayExpanded),
                                colors: colors,
                              ),
                              if (_doneTodayExpanded)
                                ..._doneTodayTasks.map((t) => _buildTaskRow(t)),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required dynamic colors,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_left,
              size: 14,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String message, required dynamic colors}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.checkmark_circle_fill, size: 56, color: colors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _addFocusNode.requestFocus(),
            icon: Icon(CupertinoIcons.add, size: 16, color: colors.primary),
            label: Text('افزودن کار', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(SimpleTask task, {bool isSomeday = false}) {
    final colors = context.colors;
    final isEditing = _editingTaskId == task.id;

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _toggleDone(task);
          return false;
        } else {
          await _deleteTask(task);
          return true;
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isEditing) _startInlineEdit(task);
          },
          onLongPress: () => _openTaskDetailsSheet(task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Touch Target Minimum 44x44 Checkmark Circle
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      task.isDone ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: task.isDone ? const Color(0xFF10B981) : colors.textSecondary.withValues(alpha: 0.5),
                      size: 24,
                    ),
                    onPressed: () => _toggleDone(task),
                  ),
                ),
                const SizedBox(width: 4),

                // Task Title / Inline Text Field
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: _inlineEditController,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                          onSubmitted: (_) => _saveInlineEdit(task),
                          decoration: const InputDecoration(border: InputBorder.none),
                        )
                      : Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: task.isDone ? colors.textSecondary : colors.textPrimary,
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                ),

                // Date Chip (if present)
                if (task.dueDate != null && !task.isDone) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _pickDateForTask(task),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.dueDate == _todayIso ? 'امروز' : task.dueDate!,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.primary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ),
                ],

                // Drag Handle if someday task
                if (isSomeday)
                  ReorderableDragStartListener(
                    index: _somedayTasks.indexOf(task),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.bars, color: colors.textSecondary.withValues(alpha: 0.4), size: 18),
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

class _TaskDetailsSheet extends StatefulWidget {
  const _TaskDetailsSheet({
    required this.task,
    required this.onUpdated,
    required this.onDeleted,
  });

  final SimpleTask task;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;

  @override
  State<_TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<_TaskDetailsSheet> {
  late SimpleTask _task;
  late TextEditingController _noteController;
  bool _hasReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _noteController = TextEditingController(text: _task.note);
    _hasReminder = _task.reminderId != null && _task.reminderId!.isNotEmpty;
    if (_task.dueTime != null) {
      final parts = _task.dueTime!.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateDate(String? isoDate) async {
    if (_task.reminderId != null && _task.reminderId!.isNotEmpty) {
      try {
        await sl<AlarmPlatform>().cancelAlarm(_task.reminderId!);
      } catch (_) {}
    }
    final updated = _task.copyWith(dueDate: isoDate);
    await SimpleTaskRepository.instance.updateTask(updated);
    setState(() => _task = updated);
    widget.onUpdated();
  }

  Future<void> _toggleReminder(bool enable) async {
    if (!enable) {
      if (_task.reminderId != null && _task.reminderId!.isNotEmpty) {
        try {
          await sl<AlarmPlatform>().cancelAlarm(_task.reminderId!);
        } catch (_) {}
      }
      final updated = _task.copyWith(reminderId: null, reminderAtMs: null, dueTime: null);
      await SimpleTaskRepository.instance.updateTask(updated);
      setState(() {
        _hasReminder = false;
        _task = updated;
      });
      widget.onUpdated();
    } else {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _reminderTime,
      );
      if (pickedTime != null) {
        final hh = pickedTime.hour.toString().padLeft(2, '0');
        final mm = pickedTime.minute.toString().padLeft(2, '0');
        final dueTimeStr = '$hh:$mm';

        final remId = 'rem_task_${_task.id}';
        final now = DateTime.now();
        final targetDate = _task.dueDate != null ? DateTime.parse(_task.dueDate!) : now;
        final remDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, pickedTime.hour, pickedTime.minute);

        await SimpleTaskRepository.instance.addPendingReminder(
          reminderId: remId,
          title: _task.title,
          body: 'یادآور کار: ${_task.title}',
          scheduledTimeMs: remDateTime.millisecondsSinceEpoch,
          taskId: _task.id,
        );

        await AlarmSchedulerService.scheduleNextAlarms();

        final updated = _task.copyWith(
          reminderId: remId,
          reminderAtMs: remDateTime.millisecondsSinceEpoch,
          dueTime: dueTimeStr,
        );
        await SimpleTaskRepository.instance.updateTask(updated);
        setState(() {
          _hasReminder = true;
          _reminderTime = pickedTime;
          _task = updated;
        });
        widget.onUpdated();
      }
    }
  }

  Future<void> _promoteToRoutine() async {
    if (_task.reminderId != null && _task.reminderId!.isNotEmpty) {
      try {
        await sl<AlarmPlatform>().cancelAlarm(_task.reminderId!);
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
      final routineId = 'routine_promoted_${DateTime.now().millisecondsSinceEpoch}';
      await SimpleTaskRepository.instance.promoteToRoutine(_task.id, routineId);
      widget.onUpdated();

      if (mounted) {
        await UniversalPlannerSheet.show(
          context: context,
          routineToEdit: {
            'title': _task.title,
            'note': _task.note,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final todayIso = DayKey.from(DateTime.now()).value;
    final tomorrowIso = DayKey.from(DateTime.now().add(const Duration(days: 1))).value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        blurSigma: 20,
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_task.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 16),

              // 1. Date options
              const Text('تاریخ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('امروز', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                    selected: _task.dueDate == todayIso,
                    onSelected: (_) => _updateDate(todayIso),
                  ),
                  ChoiceChip(
                    label: const Text('فردا', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                    selected: _task.dueDate == tomorrowIso,
                    onSelected: (_) => _updateDate(tomorrowIso),
                  ),
                  ChoiceChip(
                    label: const Text('انتخاب تاریخ', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                    selected: _task.dueDate != null && _task.dueDate != todayIso && _task.dueDate != tomorrowIso,
                    onSelected: (_) async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) unawaited(_updateDate(DayKey.from(picked).value));
                    },
                  ),
                  ChoiceChip(
                    label: const Text('بدون تاریخ', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                    selected: _task.dueDate == null,
                    onSelected: (_) => _updateDate(null),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 2. Reminder option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('یادآور', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                  Switch(
                    value: _hasReminder,
                    onChanged: _toggleReminder,
                  ),
                ],
              ),
              const Divider(height: 24),

              // 3. Multiline Note
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: const InputDecoration(
                  hintText: 'یادداشت…',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Vazirmatn'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) async {
                  await SimpleTaskRepository.instance.updateTask(_task.copyWith(note: val));
                  widget.onUpdated();
                },
              ),
              const SizedBox(height: 16),

              // 4. Promote to routine
              ListTile(
                leading: const Icon(CupertinoIcons.repeat, color: Colors.blueAccent),
                title: const Text('تبدیل به روتین تکرارشونده', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                onTap: _promoteToRoutine,
              ),

              // 5. Delete option
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                title: const Text('حذف کار', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDeleted();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
