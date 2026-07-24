import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_snapshot_builder.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';

class JourneyController extends ChangeNotifier {
  JourneyController({
    DayAgendaService? agendaService,
    DayAgendaSnapshotBuilder? snapshotBuilder,
    RitmoEventBus? eventBus,
  })  : _agendaService = agendaService ?? DayAgendaService.instance,
        _snapshotBuilder = snapshotBuilder ?? const DayAgendaSnapshotBuilder(),
        _eventBus = eventBus ?? RitmoEventBus() {
    _subscription = _eventBus.onEvents.listen(_handleEvent);
  }

  final DayAgendaService _agendaService;
  final DayAgendaSnapshotBuilder _snapshotBuilder;
  final RitmoEventBus _eventBus;
  StreamSubscription<RitmoEvent>? _subscription;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  DayAgendaSnapshot? _snapshot;
  String? _errorMessage;

  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  DayAgendaSnapshot? get snapshot => _snapshot;
  String? get errorMessage => _errorMessage;

  Future<void> loadDate(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dayAgenda = await _agendaService.agendaForDate(date);
      _snapshot = _snapshotBuilder.buildSnapshot(dayAgenda);
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      debugPrint('JourneyController loadDate error: $e\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDate(_selectedDate);
  }

  void _handleEvent(RitmoEvent event) {
    refresh();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
