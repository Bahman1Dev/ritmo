import 'dart:async';
import 'package:ritmo/features/study/data/study_active_session_dao.dart';
import 'package:ritmo/features/study/data/study_repository.dart';
import 'package:ritmo/features/study/domain/study_models.dart';

class StudyTimerService {
  StudyTimerService({StudyActiveSessionDao? dao, StudyRepository? repo})
      : _dao = dao ?? StudyActiveSessionDao.instance,
        _repo = repo ?? StudyRepository.instance;

  static final StudyTimerService instance = StudyTimerService();

  final StudyActiveSessionDao _dao;
  final StudyRepository _repo;

  ActiveStudySessionState? _currentSession;
  Timer? _ticker;

  ActiveStudySessionState? get currentSession => _currentSession;
  bool get isRunning => _currentSession != null && !_currentSession!.isPaused;
  bool get hasActiveSession => _currentSession != null;

  final _controller = StreamController<ActiveStudySessionState?>.broadcast();
  Stream<ActiveStudySessionState?> get stream => _controller.stream;

  Future<void> init() async {
    _currentSession = await _dao.getActiveSession();
    if (_currentSession != null) {
      _startTicker();
    }
    _controller.add(_currentSession);
  }

  Future<void> startSession({
    required String subjectId,
    String? topicId,
    StudyMode mode = StudyMode.learn,
    int? plannedMinutes,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final state = ActiveStudySessionState(
      id: 'singleton',
      subjectId: subjectId,
      topicId: topicId,
      mode: mode,
      startedAtMs: nowMs,
      accumulatedSeconds: 0,
      isPaused: false,
      plannedMinutes: plannedMinutes,
      createdAtMs: nowMs,
    );

    await _dao.saveActiveSession(state);
    _currentSession = state;
    _startTicker();
    _controller.add(_currentSession);
  }

  Future<void> pauseSession() async {
    if (_currentSession == null || _currentSession!.isPaused) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = _currentSession!.elapsedSeconds(nowMs);

    final updated = ActiveStudySessionState(
      id: 'singleton',
      subjectId: _currentSession!.subjectId,
      topicId: _currentSession!.topicId,
      mode: _currentSession!.mode,
      startedAtMs: nowMs,
      accumulatedSeconds: elapsedSec,
      isPaused: true,
      plannedMinutes: _currentSession!.plannedMinutes,
      createdAtMs: _currentSession!.createdAtMs,
    );

    await _dao.saveActiveSession(updated);
    _currentSession = updated;
    _ticker?.cancel();
    _controller.add(_currentSession);
  }

  Future<void> resumeSession() async {
    if (_currentSession == null || !_currentSession!.isPaused) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final updated = ActiveStudySessionState(
      id: 'singleton',
      subjectId: _currentSession!.subjectId,
      topicId: _currentSession!.topicId,
      mode: _currentSession!.mode,
      startedAtMs: nowMs,
      accumulatedSeconds: _currentSession!.accumulatedSeconds,
      isPaused: false,
      plannedMinutes: _currentSession!.plannedMinutes,
      createdAtMs: _currentSession!.createdAtMs,
    );

    await _dao.saveActiveSession(updated);
    _currentSession = updated;
    _startTicker();
    _controller.add(_currentSession);
  }

  Future<void> stopAndSaveSession({
    int? overrideDurationMinutes,
    int? quality,
    String? note,
    StudyMastery? newMastery,
    String? nextReviewDateIso,
  }) async {
    if (_currentSession == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final totalSec = _currentSession!.elapsedSeconds(nowMs);
    final durationMinutes = overrideDurationMinutes ?? (totalSec / 60).round();

    if (durationMinutes > 0) {
      final now = DateTime.now();
      final dateIso = now.toIso8601String().substring(0, 10);
      final id = 'sess_${now.millisecondsSinceEpoch}';

      final session = StudySession(
        id: id,
        subjectId: _currentSession!.subjectId ?? '',
        topicId: _currentSession!.topicId,
        durationMinutes: durationMinutes,
        dateIso: dateIso,
        mode: _currentSession!.mode,
        source: 'TIMER',
        startedAtMs: _currentSession!.createdAtMs,
        endedAtMs: nowMs,
        quality: quality,
        note: note,
        createdAtMs: nowMs,
      );

      await _repo.recordSession(
        session,
        newMastery: newMastery,
        nextReviewDateIso: nextReviewDateIso,
      );
    }

    await cancelSession();
  }

  Future<void> cancelSession() async {
    await _dao.clearActiveSession();
    _currentSession = null;
    _ticker?.cancel();
    _controller.add(null);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(_currentSession);
    });
  }

  void dispose() {
    _ticker?.cancel();
    _controller.close();
  }
}
