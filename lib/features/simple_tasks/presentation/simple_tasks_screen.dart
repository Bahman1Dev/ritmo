import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/routines/presentation/quick_add_parser.dart';
import 'package:ritmo/features/search/presentation/global_search_screen.dart';
import 'package:ritmo/features/simple_tasks/data/simple_task_repository.dart';
import 'package:ritmo/features/simple_tasks/data/task_step_repository.dart';
import 'package:ritmo/features/simple_tasks/data/task_attachment_repository.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_bucket.dart';
import 'package:ritmo/features/simple_tasks/presentation/widgets/task_bucket_section.dart';
import 'package:ritmo/features/simple_tasks/presentation/widgets/task_detail_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleTasksScreen extends StatefulWidget {
  const SimpleTasksScreen({super.key, this.focusAddField = false});

  final bool focusAddField;

  @override
  State<SimpleTasksScreen> createState() => _SimpleTasksScreenState();
}

class _SimpleTasksScreenState extends State<SimpleTasksScreen> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();

  Map<TaskBucket, List<SimpleTask>> _buckets = {};
  Map<String, (int done, int total)> _stepCounts = {};
  Map<String, int> _attachmentCounts = {};
  final Map<TaskBucket, bool> _bucketExpandedState = {};

  bool _isLoading = true;

  String get _todayIso => DayKey.from(DateTime.now()).value;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndTasks();
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
    super.dispose();
  }

  Future<void> _loadPreferencesAndTasks() async {
    final prefs = await SharedPreferences.getInstance();
    for (final b in TaskBucket.values) {
      final key = 'tasks_bucket_expanded_${b.name}';
      final defaultExpanded = b != TaskBucket.doneToday;
      _bucketExpandedState[b] = prefs.getBool(key) ?? defaultExpanded;
    }
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final buckets = await SimpleTaskRepository.instance.buckets(_todayIso);

      final allTaskIds = <String>[];
      for (final list in buckets.values) {
        allTaskIds.addAll(list.map((t) => t.id));
      }
      final stepCounts = await TaskStepRepository.instance.countsFor(allTaskIds);
      final attachmentCounts = await TaskAttachmentRepository.instance.countsFor(allTaskIds);

      if (mounted) {
        setState(() {
          _buckets = buckets;
          _stepCounts = stepCounts;
          _attachmentCounts = attachmentCounts;
        });
      }
    } catch (e, st) {
      debugPrint('[SimpleTasksScreen] Error loading tasks: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleBucketExpanded(TaskBucket bucket) async {
    final currentState = _bucketExpandedState[bucket] ?? true;
    final newState = !currentState;
    setState(() {
      _bucketExpandedState[bucket] = newState;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tasks_bucket_expanded_${bucket.name}', newState);
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

  Future<void> _playSoundIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getString('tasks_completion_sound_enabled') == 'true';
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _toggleDone(SimpleTask task) async {
    RitmoHaptics.tap();
    final newDoneState = !task.isDone;
    if (newDoneState) {
      await _playSoundIfEnabled();
    }
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

  Future<void> _toggleStar(SimpleTask task) async {
    RitmoHaptics.tap();
    await SimpleTaskRepository.instance.setImportant(task.id, important: !task.isImportant);
    await _loadTasks();
  }

  void _openTaskDetails(SimpleTask task) {
    TaskDetailSheet.show(
      context,
      task: task,
      onTaskUpdated: _loadTasks,
      onTaskDeleted: _loadTasks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalTasks = _buckets.values.fold(0, (prev, list) => prev + list.length);

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

            const SizedBox(height: 10),

            // Main List View of Buckets
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colors.primary))
                  : totalTasks == 0
                      ? Center(
                          child: Text(
                            'هیچ کاری ثبت نشده است.\nیک کار جدید اضافه کنید!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: TaskBucket.values.map((bucket) {
                            final tasks = _buckets[bucket] ?? [];
                            final isExpanded = _bucketExpandedState[bucket] ?? true;

                            return TaskBucketSection(
                              bucket: bucket,
                              tasks: tasks,
                              stepCounts: _stepCounts,
                              attachmentCounts: _attachmentCounts,
                              isExpanded: isExpanded,
                              onToggleExpand: () => _toggleBucketExpanded(bucket),
                              onTaskTap: _openTaskDetails,
                              onToggleDone: _toggleDone,
                              onToggleStar: _toggleStar,
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
