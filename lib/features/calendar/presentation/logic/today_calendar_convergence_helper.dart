import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_action_handler.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_snapshot_builder.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';

/// Central helper for convergence and cross-feature workflows between Calendar and Today Dashboard.
class TodayCalendarConvergenceHelper {
  TodayCalendarConvergenceHelper({
    DayAgendaService? agendaService,
    DayAgendaSnapshotBuilder? snapshotBuilder,
    AgendaActionHandler? actionHandler,
    RitmoExecutionKernel? kernel,
    RitmoEventBus? eventBus,
  })  : _agendaService = agendaService ?? DayAgendaService.instance,
        _snapshotBuilder = snapshotBuilder ?? const DayAgendaSnapshotBuilder(),
        _actionHandler = actionHandler ?? AgendaActionHandler.instance,
        _kernel = kernel ?? RitmoExecutionKernel.instance,
        _eventBus = eventBus ?? RitmoEventBus();

  final DayAgendaService _agendaService;
  final DayAgendaSnapshotBuilder _snapshotBuilder;
  final AgendaActionHandler _actionHandler;
  final RitmoExecutionKernel _kernel;
  final RitmoEventBus _eventBus;

  /// Fetches a unified execution snapshot for today, shared between Today and Calendar.
  Future<DayAgendaSnapshot> fetchTodaySnapshot({DateTime? now}) async {
    final targetDate = now ?? DateTime.now();
    final todayAgenda = await _agendaService.agendaForDate(targetDate);
    return _snapshotBuilder.buildSnapshot(todayAgenda, now: targetDate);
  }

  /// Opens the Calendar screen tab focused on a specific date and optional item.
  void openCalendarInContext(
    BuildContext context, {
    DateTime? date,
    String? itemId,
  }) {
    final targetDate = date ?? DateTime.now();
    final payload = <String, dynamic>{
      'index': 4, // Calendar Tab Index
      'date': targetDate.toIso8601String(),
    };
    if (itemId != null) payload['itemId'] = itemId;

    _eventBus.fire(RitmoEvent(
      type: 'navigate_tab',
      timestamp: DateTime.now(),
      payload: payload,
    ));
  }

  /// Navigates to the main Today Dashboard screen tab.
  void openTodayDashboard(BuildContext context) {
    _eventBus.fire(RitmoEvent(
      type: 'navigate_tab',
      timestamp: DateTime.now(),
      payload: {'index': 2}, // Home Today Dashboard Tab Index
    ));
  }

  /// Executes item completion uniformly from any surface and refreshes both Today and Calendar.
  Future<void> completeItem(AgendaItem item) async {
    if (item.domain == AgendaDomain.routine) {
      await _kernel.execute(CompleteOccurrenceCommand(
        routineId: item.sourceId,
        dateStr: item.dateStr,
        resultType: 'COMPLETED',
        durationMinutes: item.durationMinutes ?? CalendarDefaults.fallbackDurationMinutes,
      ));
    } else {
      await _actionHandler.toggleAgendaItem(item: item, isDone: true);
    }

    _agendaService.invalidateDate(item.dateStr);
    _eventBus.fire(RitmoEvent(
      type: 'AgendaItemToggled',
      timestamp: DateTime.now(),
      payload: {'id': item.id, 'date': item.dateStr, 'isDone': true},
    ));
  }

  /// Executes item skip uniformly from any surface and refreshes both Today and Calendar.
  Future<void> skipItem(AgendaItem item) async {
    if (item.domain == AgendaDomain.routine) {
      await _kernel.execute(SkipOccurrenceCommand(
        routineId: item.sourceId,
        dateStr: item.dateStr,
        reason: 'Skipped via Quick Action',
      ));
    } else {
      await _actionHandler.toggleAgendaItem(item: item, isDone: false);
    }

    _agendaService.invalidateDate(item.dateStr);
    _eventBus.fire(RitmoEvent(
      type: 'AgendaItemToggled',
      timestamp: DateTime.now(),
      payload: {'id': item.id, 'date': item.dateStr, 'isDone': false},
    ));
  }
}
