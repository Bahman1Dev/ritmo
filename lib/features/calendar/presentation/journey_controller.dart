import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/agenda/agenda_action_handler.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_snapshot_builder.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/commands/command_stack.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/features/courses/logic/course_scheduler.dart';
import 'package:ritmo/core/domain/agenda/occurrence_override_repository.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/calendar/utils/calendar_defaults.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Calendar view scale. `agenda` is the primary view ("what's next?").
/// `week` and `year` are overflow-menu-only — shown in the ⋯ button.
enum JourneyScale { agenda, day, week, month, year }

class JourneyController extends ChangeNotifier {
  JourneyController({
    DayAgendaService? agendaService,
    DayAgendaSnapshotBuilder? snapshotBuilder,
    RitmoEventBus? eventBus,
    AgendaActionHandler? actionHandler,
    RitmoExecutionKernel? kernel,
  })  : _agendaService = agendaService ?? DayAgendaService.instance,
        _snapshotBuilder = snapshotBuilder ?? const DayAgendaSnapshotBuilder(),
        _eventBus = eventBus ?? RitmoEventBus(),
        _actionHandler = actionHandler ?? AgendaActionHandler.instance,
        _kernel = kernel ?? RitmoExecutionKernel.instance {
    _subscription = _eventBus.onEvents.listen(_handleEvent);
  }

  final DayAgendaService _agendaService;
  final DayAgendaSnapshotBuilder _snapshotBuilder;
  final RitmoEventBus _eventBus;
  final AgendaActionHandler _actionHandler;
  final RitmoExecutionKernel _kernel;
  StreamSubscription<RitmoEvent>? _subscription;

  bool _isDisposed = false;
  DateTime _selectedDate = DateTime.now();
  JourneyScale _activeScale = JourneyScale.agenda; // overridden by loadDefaultScale()
  bool _isLoading = false;
  bool _isExecutingAction = false;
  DayAgendaSnapshot? _snapshot;
  Map<String, DayAgendaSnapshot> _rangeSnapshots = {};
  String? _errorMessage;
  String? _highlightedItemId;
  int? _focusedMinutes;
  String? _manipulatingItemId;
  bool _isDragging = false;
  bool _isResizing = false;
  String? _previewTimeOfDay;
  int? _previewDurationMinutes;

  DateTime get selectedDate => _selectedDate;
  JourneyScale get activeScale => _activeScale;
  bool get isLoading => _isLoading;
  bool get isExecutingAction => _isExecutingAction;
  DayAgendaSnapshot? get snapshot => _snapshot;
  Map<String, DayAgendaSnapshot> get rangeSnapshots => _rangeSnapshots;
  String? get errorMessage => _errorMessage;
  String? get highlightedItemId => _highlightedItemId;
  int? get focusedMinutes => _focusedMinutes;
  String? get manipulatingItemId => _manipulatingItemId;
  bool get isDragging => _isDragging;
  bool get isResizing => _isResizing;
  String? get previewTimeOfDay => _previewTimeOfDay;
  int? get previewDurationMinutes => _previewDurationMinutes;
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  void highlightItem(String? itemId) {
    if (_isDisposed) return;
    _highlightedItemId = itemId;
    notifyListeners();
  }

  void focusMinutes(int? minutes) {
    if (_isDisposed) return;
    _focusedMinutes = minutes;
    notifyListeners();
  }

  void clearFocusAndHighlight() {
    if (_isDisposed) return;
    _highlightedItemId = null;
    _focusedMinutes = null;
    notifyListeners();
  }

  void setScale(JourneyScale scale) {
    if (_isDisposed || _activeScale == scale) return;
    _activeScale = scale;
    loadForActiveScale();
  }

  void selectDate(DateTime date, {JourneyScale? scaleToSet}) {
    if (_isDisposed) return;
    _selectedDate = date;
    if (scaleToSet != null) {
      _activeScale = scaleToSet;
    }
    loadForActiveScale();
  }

  void navigatePeriod(int offset) {
    if (_isDisposed) return;
    switch (_activeScale) {
      case JourneyScale.agenda:
        // Agenda navigates in 7-day blocks (same as week)
        _selectedDate = _selectedDate.add(Duration(days: 7 * offset));
        break;
      case JourneyScale.day:
        _selectedDate = _selectedDate.add(Duration(days: offset));
        break;
      case JourneyScale.week:
        _selectedDate = _selectedDate.add(Duration(days: 7 * offset));
        break;
      case JourneyScale.month:
        final j = Jalali.fromDateTime(_selectedDate);
        final nextJ = j.addMonths(offset);
        _selectedDate = nextJ.toDateTime();
        break;
      case JourneyScale.year:
        final j = Jalali.fromDateTime(_selectedDate);
        final nextJ = Jalali(j.year + offset, j.month, j.day.clamp(1, 29));
        _selectedDate = nextJ.toDateTime();
        break;
    }
    loadForActiveScale();
  }

  Future<void> loadForActiveScale({bool isBackgroundRefresh = false}) async {
    if (_isDisposed) return;

    // K21: Agenda scale uses its own dedicated range loader
    if (_activeScale == JourneyScale.agenda) {
      await loadAgendaRange();
      return;
    }

    if (!isBackgroundRefresh && _snapshot == null) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final range = _calculateDateRangeForScale(_activeScale, _selectedDate);
      final daysMap = await _agendaService.agendaForRange(range.start, range.end);
      if (_isDisposed) return;

      final newSnapshots = <String, DayAgendaSnapshot>{};
      for (final entry in daysMap.entries) {
        newSnapshots[entry.key] = _snapshotBuilder.buildSnapshot(entry.value);
      }

      _rangeSnapshots = newSnapshots;
      final selectedKey = _formatDateKey(_selectedDate);
      _snapshot = _rangeSnapshots[selectedKey];

      // Cleanup stale highlights or manipulation state if item no longer exists
      if (_snapshot != null) {
        final currentItemIds = _snapshot!.items.map((i) => i.id).toSet();
        if (_highlightedItemId != null && !currentItemIds.contains(_highlightedItemId)) {
          _highlightedItemId = null;
        }
        if (_manipulatingItemId != null && !currentItemIds.contains(_manipulatingItemId)) {
          _manipulatingItemId = null;
          _isDragging = false;
          _isResizing = false;
          _previewTimeOfDay = null;
          _previewDurationMinutes = null;
        }
      }
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to load schedule: $e';
      debugPrint('loadForActiveScale error: $e\n$stackTrace');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> completeItem(AgendaItem item) async {
    if (_isDisposed || _isExecutingAction) return;
    _isExecutingAction = true;
    notifyListeners();

    try {
      if (item.domain == AgendaDomain.routine) {
        await _kernel.execute(CompleteOccurrenceCommand(
          routineId: item.sourceId,
          dateStr: item.dateStr,
          resultType: 'COMPLETED',
          durationMinutes: item.durationMinutes ?? 30,
        ));
      } else {
        await _actionHandler.toggleAgendaItem(item: item, isDone: true);
      }
      await refresh();
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to complete task: $e';
      debugPrint('completeItem error: $e\n$stackTrace');
    } finally {
      if (!_isDisposed) {
        _isExecutingAction = false;
        notifyListeners();
      }
    }
  }

  Future<void> skipItem(AgendaItem item) async {
    if (_isDisposed || _isExecutingAction) return;
    _isExecutingAction = true;
    notifyListeners();

    try {
      if (item.domain == AgendaDomain.routine) {
        await _kernel.execute(SkipOccurrenceCommand(
          routineId: item.sourceId,
          dateStr: item.dateStr,
          reason: 'Skipped via Calendar',
        ));
      } else {
        await _actionHandler.toggleAgendaItem(item: item, isDone: false);
      }
      await refresh();
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to skip task: $e';
      debugPrint('skipItem error: $e\n$stackTrace');
    } finally {
      if (!_isDisposed) {
        _isExecutingAction = false;
        notifyListeners();
      }
    }
  }

  void startItemDrag(AgendaItem item) {
    if (_isDisposed) return;
    _manipulatingItemId = item.id;
    _isDragging = true;
    _isResizing = false;
    _previewTimeOfDay = item.timeOfDay;
    _previewDurationMinutes = item.durationMinutes;
    notifyListeners();
  }

  void updateDragPreview(String timeOfDay) {
    if (_isDisposed || _previewTimeOfDay == timeOfDay) return;
    _previewTimeOfDay = timeOfDay;
    notifyListeners();
  }

  Future<void> commitItemDrag(
    AgendaItem item,
    String newTimeOfDay, {
    CalendarEditScope scope = CalendarEditScope.thisDayOnly,
  }) async {
    if (_isDisposed || _isExecutingAction) return;
    _isExecutingAction = true;
    notifyListeners();

    final oldTimeOfDay = item.timeOfDay ?? '08:00';
    try {
      final command = _MoveItemCommand(
        actionHandler: _actionHandler,
        item: item,
        oldTimeOfDay: oldTimeOfDay,
        newTimeOfDay: newTimeOfDay,
        onRefresh: refresh,
        scope: scope,
      );
      await command.execute();
      CommandStack.instance.push(command);
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to move task: $e';
      debugPrint('commitItemDrag error: $e\n$stackTrace');
    } finally {
      if (!_isDisposed) {
        _isExecutingAction = false;
        cancelManipulation();
      }
    }
  }

  Future<void> commitItemResize(
    AgendaItem item,
    int newDurationMinutes, {
    CalendarEditScope scope = CalendarEditScope.thisDayOnly,
  }) async {
    if (_isDisposed || _isExecutingAction) return;
    _isExecutingAction = true;
    notifyListeners();

    final oldDuration = item.durationMinutes ?? CalendarDefaults.fallbackDurationMinutes;
    try {
      final command = _ResizeItemCommand(
        actionHandler: _actionHandler,
        item: item,
        oldDuration: oldDuration,
        newDuration: newDurationMinutes,
        onRefresh: refresh,
        scope: scope,
      );
      await command.execute();
      CommandStack.instance.push(command);
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to resize task: $e';
      debugPrint('commitItemResize error: $e\n$stackTrace');
    } finally {
      if (!_isDisposed) {
        _isExecutingAction = false;
        cancelManipulation();
      }
    }
  }

  Future<bool> undoLastAction() async {
    if (_isDisposed) return false;
    final success = await CommandStack.instance.undoLast();
    if (success) {
      await refresh();
    }
    return success;
  }

  void cancelManipulation() {
    if (_isDisposed) return;
    _manipulatingItemId = null;
    _isDragging = false;
    _isResizing = false;
    _previewTimeOfDay = null;
    _previewDurationMinutes = null;
    notifyListeners();
  }

  Future<void> loadDate(DateTime date) async {
    selectDate(date);
  }

  /// K22 — Reads `calendar_default_scale` from app_settings and applies it.
  /// EXCEPTION: if the caller sets scaleToSet on selectDate (e.g. via initialItemId
  /// or a push notification), that takes priority and this method must NOT override it.
  /// This comment is intentional — do not remove without reading 067.md §K22.
  Future<void> loadDefaultScale() async {
    if (_isDisposed) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['calendar_default_scale'],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value']?.toString() ?? 'agenda';
        final scale = _scaleFromString(val);
        if (!_isDisposed) {
          _activeScale = scale;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[JourneyController] loadDefaultScale error: $e');
    }
  }

  static JourneyScale _scaleFromString(String val) {
    switch (val) {
      case 'agenda': return JourneyScale.agenda;
      case 'day':    return JourneyScale.day;
      case 'week':   return JourneyScale.week;
      case 'month':  return JourneyScale.month;
      case 'year':   return JourneyScale.year;
      default:       return JourneyScale.agenda;
    }
  }

  /// K21 — Loads a date range for the Agenda scale.
  ///
  /// Performance target: < 250ms for the initial load.
  /// Uses a single agendaForRange call — NOT one query per day.
  /// Must start with if (_isDisposed) return; — guaranteed by spec (067.md §K21).
  Future<void> loadAgendaRange({int daysBack = 14, int daysForward = 45}) async {
    if (_isDisposed) return;
    if (_snapshot == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final sw = Stopwatch()..start();
      final today = DateTime.now();
      final start = today.subtract(Duration(days: daysBack));
      final end = today.add(Duration(days: daysForward));

      // Single range call — never N-per-day calls
      final daysMap = await _agendaService.agendaForRange(start, end);
      if (_isDisposed) return;

      final newSnapshots = <String, DayAgendaSnapshot>{};
      for (final entry in daysMap.entries) {
        newSnapshots[entry.key] = _snapshotBuilder.buildSnapshot(entry.value);
      }
      _rangeSnapshots = newSnapshots;
      sw.stop();
      debugPrint('[JourneyController] loadAgendaRange: ${sw.elapsedMilliseconds}ms');
    } catch (e, st) {
      if (_isDisposed) return;
      debugPrint('[JourneyController] loadAgendaRange error: $e\n$st');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    await loadForActiveScale(isBackgroundRefresh: true);
  }

  void _handleEvent(RitmoEvent event) {
    if (_isDisposed) return;
    if (event.type == 'RoutineCompleted' ||
        event.type == 'RoutineSkipped' ||
        event.type == 'RoutineUpdated' ||
        event.type == 'RoutineCreated' ||
        event.type == 'RoutineDeleted' ||
        event.type == 'PrayerCompleted' ||
        event.type == 'WorshipUpdated' ||
        event.type == 'CourseSessionCompleted' ||
        event.type == 'AgendaItemToggled' ||
        event.type == 'ReshuffleApplied') {
      refresh();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  static ({DateTime start, DateTime end}) _calculateDateRangeForScale(JourneyScale scale, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final j = Jalali.fromDateTime(dateOnly);
    switch (scale) {
      case JourneyScale.agenda:
        // Agenda loads a 60-day forward window from selected date
        return (start: dateOnly, end: dateOnly.add(const Duration(days: 59)));
      case JourneyScale.day:
        return (start: dateOnly, end: dateOnly);
      case JourneyScale.week:
        final sat = CourseScheduler.getSaturdayOfWeek(dateOnly);
        final fri = sat.add(const Duration(days: 6));
        return (start: sat, end: fri);
      case JourneyScale.month:
        final startJ = Jalali(j.year, j.month, 1);
        final endJ = Jalali(j.year, j.month, startJ.monthLength);
        return (start: startJ.toDateTime(), end: endJ.toDateTime());
      case JourneyScale.year:
        final startJ = Jalali(j.year, 1, 1);
        final endJ = Jalali(j.year, 12, Jalali(j.year, 12, 1).monthLength);
        return (start: startJ.toDateTime(), end: endJ.toDateTime());
    }
  }

  Future<void> scheduleItem(AgendaItem item, int startMinutes, int durationMinutes) async {
    if (_isDisposed || _isExecutingAction) return;
    _isExecutingAction = true;
    notifyListeners();

    final newTimeStr = TimelineSnappingHelper.minutesToTimeString(startMinutes);
    try {
      final command = _ScheduleItemCommand(
        actionHandler: _actionHandler,
        item: item,
        newTimeOfDay: newTimeStr,
        newDurationMinutes: durationMinutes,
        onRefresh: refresh,
      );
      await command.execute();
      CommandStack.instance.push(command);
      RitmoHaptics.success();
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to schedule task: $e';
      debugPrint('scheduleItem error: $e\n$stackTrace');
    } finally {
      if (!_isDisposed) {
        _isExecutingAction = false;
        cancelManipulation();
      }
    }
  }

  Future<void> unscheduleItem(AgendaItem item) async {
    if (_isDisposed || _isExecutingAction) return;
    _isExecutingAction = true;
    notifyListeners();

    try {
      final command = _UnscheduleItemCommand(
        actionHandler: _actionHandler,
        item: item,
        oldTimeOfDay: item.timeOfDay,
        oldDurationMinutes: item.durationMinutes,
        onRefresh: refresh,
      );
      await command.execute();
      CommandStack.instance.push(command);
      RitmoHaptics.success();
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to unschedule task: $e';
      debugPrint('unscheduleItem error: $e\n$stackTrace');
    } finally {
      if (!_isDisposed) {
        _isExecutingAction = false;
        cancelManipulation();
      }
    }
  }

  void startItemResize(AgendaItem item) {
    if (_isDisposed) return;
    _manipulatingItemId = item.id;
    _isDragging = false;
    _isResizing = true;
    _previewTimeOfDay = item.timeOfDay;
    _previewDurationMinutes = item.durationMinutes ?? 30;
    notifyListeners();
  }

  void updateResizePreview(int durationMinutes) {
    if (_isDisposed || _previewDurationMinutes == durationMinutes) return;
    _previewDurationMinutes = durationMinutes;
    notifyListeners();
  }

  static String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

enum CalendarEditScope { thisDayOnly, allFutureDays }

class _MoveItemCommand implements UndoableCommand {
  _MoveItemCommand({
    required this.actionHandler,
    required this.item,
    required this.oldTimeOfDay,
    required this.newTimeOfDay,
    required this.onRefresh,
    this.scope = CalendarEditScope.thisDayOnly,
    OccurrenceOverrideRepository? overrideRepo,
  }) : _overrideRepo = overrideRepo ?? const SqliteOccurrenceOverrideRepository();

  final AgendaActionHandler actionHandler;
  final AgendaItem item;
  final String oldTimeOfDay;
  final String newTimeOfDay;
  final Future<void> Function() onRefresh;
  final CalendarEditScope scope;
  final OccurrenceOverrideRepository _overrideRepo;

  @override
  String get description => 'جابه‌جایی رویداد';

  @override
  Future<void> execute() async {
    final nowIso = DateTime.now().toIso8601String();
    if (scope == CalendarEditScope.thisDayOnly) {
      final override = OccurrenceOverride(
        sourceType: item.domain.name,
        sourceId: item.sourceId,
        dateStr: item.dateStr,
        timeOfDay: newTimeOfDay,
        status: 'MOVED',
        createdAt: nowIso,
        updatedAt: nowIso,
      );
      await _overrideRepo.upsert(override);
    } else {
      await _overrideRepo.removeAllFuture(item.domain.name, item.sourceId, item.dateStr);
      await actionHandler.updateAgendaItemTimeAndDuration(
        item: item,
        newTimeOfDay: newTimeOfDay,
      );
    }
    DayAgendaService.instance.invalidateDate(item.dateStr);
    await onRefresh();
  }

  @override
  Future<void> undo() async {
    if (scope == CalendarEditScope.thisDayOnly) {
      await _overrideRepo.remove(item.domain.name, item.sourceId, item.dateStr);
    } else {
      await actionHandler.updateAgendaItemTimeAndDuration(
        item: item,
        newTimeOfDay: oldTimeOfDay,
      );
    }
    DayAgendaService.instance.invalidateDate(item.dateStr);
    await onRefresh();
  }
}

class _ResizeItemCommand implements UndoableCommand {
  _ResizeItemCommand({
    required this.actionHandler,
    required this.item,
    required this.oldDuration,
    required this.newDuration,
    required this.onRefresh,
    this.scope = CalendarEditScope.thisDayOnly,
    OccurrenceOverrideRepository? overrideRepo,
  }) : _overrideRepo = overrideRepo ?? const SqliteOccurrenceOverrideRepository();

  final AgendaActionHandler actionHandler;
  final AgendaItem item;
  final int oldDuration;
  final int newDuration;
  final Future<void> Function() onRefresh;
  final CalendarEditScope scope;
  final OccurrenceOverrideRepository _overrideRepo;

  @override
  String get description => 'تغییر مدت زمان رویداد';

  @override
  Future<void> execute() async {
    final nowIso = DateTime.now().toIso8601String();
    if (scope == CalendarEditScope.thisDayOnly) {
      final override = OccurrenceOverride(
        sourceType: item.domain.name,
        sourceId: item.sourceId,
        dateStr: item.dateStr,
        durationMinutes: newDuration,
        status: 'RESIZED',
        createdAt: nowIso,
        updatedAt: nowIso,
      );
      await _overrideRepo.upsert(override);
    } else {
      await _overrideRepo.removeAllFuture(item.domain.name, item.sourceId, item.dateStr);
      await actionHandler.updateAgendaItemTimeAndDuration(
        item: item,
        newDurationMinutes: newDuration,
      );
    }
    DayAgendaService.instance.invalidateDate(item.dateStr);
    await onRefresh();
  }

  @override
  Future<void> undo() async {
    if (scope == CalendarEditScope.thisDayOnly) {
      await _overrideRepo.remove(item.domain.name, item.sourceId, item.dateStr);
    } else {
      await actionHandler.updateAgendaItemTimeAndDuration(
        item: item,
        newDurationMinutes: oldDuration,
      );
    }
    DayAgendaService.instance.invalidateDate(item.dateStr);
    await onRefresh();
  }
}

class _ScheduleItemCommand implements UndoableCommand {
  _ScheduleItemCommand({
    required this.actionHandler,
    required this.item,
    required this.newTimeOfDay,
    required this.newDurationMinutes,
    required this.onRefresh,
  });

  final AgendaActionHandler actionHandler;
  final AgendaItem item;
  final String newTimeOfDay;
  final int newDurationMinutes;
  final Future<void> Function() onRefresh;

  @override
  String get description => 'زمان‌بندی رویداد';

  @override
  Future<void> execute() async {
    await actionHandler.updateAgendaItemTimeAndDuration(
      item: item,
      newTimeOfDay: newTimeOfDay,
      newDurationMinutes: newDurationMinutes,
    );
    await onRefresh();
  }

  @override
  Future<void> undo() async {
    await actionHandler.clearAgendaItemTime(item: item);
    await onRefresh();
  }
}

class _UnscheduleItemCommand implements UndoableCommand {
  _UnscheduleItemCommand({
    required this.actionHandler,
    required this.item,
    required this.oldTimeOfDay,
    required this.oldDurationMinutes,
    required this.onRefresh,
  });

  final AgendaActionHandler actionHandler;
  final AgendaItem item;
  final String? oldTimeOfDay;
  final int? oldDurationMinutes;
  final Future<void> Function() onRefresh;

  @override
  String get description => 'لغو زمان‌بندی رویداد';

  @override
  Future<void> execute() async {
    await actionHandler.clearAgendaItemTime(item: item);
    await onRefresh();
  }

  @override
  Future<void> undo() async {
    if (oldTimeOfDay != null) {
      await actionHandler.updateAgendaItemTimeAndDuration(
        item: item,
        newTimeOfDay: oldTimeOfDay,
        newDurationMinutes: oldDurationMinutes,
      );
      await onRefresh();
    }
  }
}
