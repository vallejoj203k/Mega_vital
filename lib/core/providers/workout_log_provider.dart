// lib/core/providers/workout_log_provider.dart
// ─────────────────────────────────────────────────────────────────
// Provider que gestiona el estado del registro de entrenamientos.
// - Sesión activa (en curso), persisted across app restarts
// - Historial de sesiones completadas
// - Memoria de pesos usados por ejercicio
// - WidgetsBindingObserver para auto-guardar al ir a background
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/workout_log_service.dart';
import '../../services/points_service.dart';
import '../data/muscle_data.dart';

// Helpers para parsear los strings de series/reps del modelo ExerciseItem
int _parseSetsCount(String setsStr) =>
    int.tryParse(setsStr.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 3;

int _parseDefaultReps(String repsStr) {
  final first = repsStr.trim().split(RegExp(r'[\s\-]')).first;
  return int.tryParse(first.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;
}

class WorkoutLogProvider extends ChangeNotifier with WidgetsBindingObserver {
  final WorkoutLogService _service = WorkoutLogService.instance;

  WorkoutSession?       _activeSession;
  List<WorkoutSession>  _history       = [];
  bool                  _isLoading     = false;
  Map<String, double>   _lastWeights   = {};
  DateTime?             _sessionStart;

  // ── Getters ───────────────────────────────────────────────────

  WorkoutSession?      get activeSession  => _activeSession;
  List<WorkoutSession> get history        => _history;
  bool                 get isLoading      => _isLoading;
  bool                 get hasActiveSession => _activeSession != null;
  Map<String, double>  get lastWeights    => Map.unmodifiable(_lastWeights);

  /// Minutos transcurridos desde que inició la sesión activa.
  int get currentDurationMinutes {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inMinutes;
  }

  /// Segundos transcurridos (para mostrar el cronómetro).
  int get currentDurationSeconds {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inSeconds;
  }

  /// Sesiones completadas hoy.
  List<WorkoutSession> get todaySessions {
    final now = DateTime.now();
    return _history.where((s) =>
        s.date.year  == now.year  &&
        s.date.month == now.month &&
        s.date.day   == now.day   &&
        s.isCompleted).toList();
  }

  // ── Inicialización ────────────────────────────────────────────

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    WidgetsBinding.instance.addObserver(this);
    await Future.wait([
      _loadHistory(),
      _loadWeights(),
      _restoreActiveSession(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-guarda la sesión activa cuando la app pasa a segundo plano o se cierra.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistActiveSession();
    }
  }

  Future<void> _loadHistory() async {
    _history = await _service.loadSessions();
  }

  Future<void> _loadWeights() async {
    _lastWeights = await _service.loadLastWeights();
  }

  Future<void> _restoreActiveSession() async {
    final saved = await _service.loadActiveSession();
    if (saved != null) {
      _activeSession = saved.session;
      _sessionStart  = saved.startTime;
    }
  }

  Future<void> reloadHistory() async {
    await _loadHistory();
    notifyListeners();
  }

  // ── Persistencia de sesión activa ─────────────────────────────

  void _persistActiveSession() {
    if (_activeSession != null && _sessionStart != null) {
      unawaited(_service.saveActiveSession(_activeSession!, _sessionStart!));
    }
  }

  // ── Consulta de último peso ───────────────────────────────────

  double getLastWeight(String exerciseId) =>
      _lastWeights[exerciseId] ?? 0.0;

  // ── Iniciar sesión ────────────────────────────────────────────

  Future<void> startSession(
      String name, List<ExerciseItem> exercises) async {
    _sessionStart = DateTime.now();

    final loggedExercises = <LoggedExercise>[];
    for (final ex in exercises) {
      final lastWeight  = _lastWeights[ex.id] ?? 0.0;
      final setsCount   = _parseSetsCount(ex.sets);
      final defaultReps = _parseDefaultReps(ex.reps);

      loggedExercises.add(LoggedExercise(
        exerciseId  : ex.id,
        exerciseName: ex.name,
        muscleId    : ex.muscleId,
        sets        : List.generate(
          setsCount,
          (i) => ExerciseSetLog(
            setNumber: i + 1,
            weight   : lastWeight,
            reps     : defaultReps,
          ),
        ),
      ));
    }

    _activeSession = WorkoutSession(
      id       : DateTime.now().millisecondsSinceEpoch.toString(),
      name     : name,
      date     : DateTime.now(),
      exercises: loggedExercises,
    );

    // Persiste inmediatamente para sobrevivir cierres inesperados
    await _service.saveActiveSession(_activeSession!, _sessionStart!);
    notifyListeners();
  }

  // ── Modificar series ──────────────────────────────────────────

  void updateSetWeight(int exIdx, int setIdx, double weight) {
    if (_activeSession == null) return;
    _activeSession!.exercises[exIdx].sets[setIdx].weight = weight;
    _persistActiveSession();
    notifyListeners();
  }

  void updateSetReps(int exIdx, int setIdx, int reps) {
    if (_activeSession == null) return;
    _activeSession!.exercises[exIdx].sets[setIdx].reps = reps;
    _persistActiveSession();
    notifyListeners();
  }

  void toggleSetDone(int exIdx, int setIdx) {
    if (_activeSession == null) return;
    final set = _activeSession!.exercises[exIdx].sets[setIdx];
    set.isDone = !set.isDone;
    _persistActiveSession();
    notifyListeners();
  }

  void addSet(int exIdx) {
    if (_activeSession == null) return;
    final ex      = _activeSession!.exercises[exIdx];
    final lastSet = ex.sets.isNotEmpty ? ex.sets.last : null;
    ex.sets.add(ExerciseSetLog(
      setNumber: ex.sets.length + 1,
      weight   : lastSet?.weight ?? 0,
      reps     : lastSet?.reps   ?? 10,
    ));
    _persistActiveSession();
    notifyListeners();
  }

  void removeLastSet(int exIdx) {
    if (_activeSession == null) return;
    final sets = _activeSession!.exercises[exIdx].sets;
    if (sets.length > 1) {
      sets.removeLast();
      _persistActiveSession();
      notifyListeners();
    }
  }

  // ── Finalizar sesión ──────────────────────────────────────────

  Future<void> finishSession({String userName = 'Usuario'}) async {
    if (_activeSession == null) return;
    _activeSession!.durationMinutes = currentDurationMinutes;
    _activeSession!.isCompleted     = true;
    await _service.saveSessionWeights(_activeSession!);
    await _service.saveSession(_activeSession!);
    await _service.clearActiveSession();
    unawaited(PointsService.instance.awardWorkout(userName));
    _activeSession = null;
    _sessionStart  = null;
    await Future.wait([_loadHistory(), _loadWeights()]);
    notifyListeners();
  }

  /// Descarta la sesión activa sin guardar.
  Future<void> cancelSession() async {
    await _service.clearActiveSession();
    _activeSession = null;
    _sessionStart  = null;
    notifyListeners();
  }

  // ── Historial ─────────────────────────────────────────────────

  Future<void> deleteSession(String id) async {
    await _service.deleteSession(id);
    await _loadHistory();
    notifyListeners();
  }
}
