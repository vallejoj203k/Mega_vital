// lib/services/workout_log_service.dart
// ─────────────────────────────────────────────────────────────────
// Servicio de registro de entrenamientos.
// - Guarda sesiones completas en SharedPreferences (offline-first)
// - Sincroniza sesiones completadas con Supabase (best-effort)
// - Persiste la sesión activa en SharedPreferences para sobrevivir
//   cierres/muertes de la app y restaurar el estado al relanzar
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kSessionsKey      = 'mv_workout_sessions';
const _kLastWeightsKey   = 'mv_last_weights';
const _kActiveSessionKey = 'mv_active_session';
const _kSessionStartKey  = 'mv_session_start';

// ── Modelos ───────────────────────────────────────────────────────

/// Una serie dentro de un ejercicio registrado.
class ExerciseSetLog {
  final int    setNumber;
  double       weight;   // kg (0 = peso corporal / sin peso)
  int          reps;
  bool         isDone;

  ExerciseSetLog({
    required this.setNumber,
    this.weight  = 0,
    required this.reps,
    this.isDone  = false,
  });

  Map<String, dynamic> toMap() => {
    'set'   : setNumber,
    'weight': weight,
    'reps'  : reps,
    'done'  : isDone,
  };

  factory ExerciseSetLog.fromMap(Map<String, dynamic> m) => ExerciseSetLog(
    setNumber: (m['set']    as num?)?.toInt()    ?? 1,
    weight   : (m['weight'] as num?)?.toDouble() ?? 0.0,
    reps     : (m['reps']   as num?)?.toInt()    ?? 10,
    isDone   : m['done']    as bool?             ?? false,
  );

  ExerciseSetLog copyWith({double? weight, int? reps, bool? isDone}) =>
    ExerciseSetLog(
      setNumber: setNumber,
      weight   : weight   ?? this.weight,
      reps     : reps     ?? this.reps,
      isDone   : isDone   ?? this.isDone,
    );
}

/// Un ejercicio dentro de una sesión registrada.
class LoggedExercise {
  final String              exerciseId;
  final String              exerciseName;
  final String              muscleId;
  List<ExerciseSetLog>      sets;

  LoggedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleId,
    required this.sets,
  });

  /// Volumen total: suma de (peso × reps) en series completadas.
  double get totalVolume => sets
      .where((s) => s.isDone)
      .fold(0.0, (sum, s) => sum + s.weight * s.reps);

  /// Peso máximo utilizado en cualquier serie.
  double get maxWeight => sets.isEmpty
      ? 0.0
      : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  /// Número de series completadas.
  int get doneSets => sets.where((s) => s.isDone).length;

  Map<String, dynamic> toMap() => {
    'id'    : exerciseId,
    'name'  : exerciseName,
    'muscle': muscleId,
    'sets'  : sets.map((s) => s.toMap()).toList(),
  };

  factory LoggedExercise.fromMap(Map<String, dynamic> m) => LoggedExercise(
    exerciseId  : m['id']     as String? ?? '',
    exerciseName: m['name']   as String? ?? '',
    muscleId    : m['muscle'] as String? ?? '',
    sets        : (m['sets'] as List? ?? [])
        .map((s) => ExerciseSetLog.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList(),
  );
}

/// Una sesión de entrenamiento completa.
class WorkoutSession {
  final String              id;
  String                    name;
  final DateTime            date;
  int                       durationMinutes;
  List<LoggedExercise>      exercises;
  bool                      isCompleted;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    this.durationMinutes = 0,
    required this.exercises,
    this.isCompleted     = false,
  });

  /// Volumen total de la sesión (kg × reps acumulado).
  double get totalVolume =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolume);

  /// Ejercicios con al menos 1 serie completada.
  int get completedExercises =>
      exercises.where((e) => e.doneSets > 0).length;

  /// Total de series completadas en la sesión.
  int get totalDoneSets =>
      exercises.fold(0, (sum, e) => sum + e.doneSets);

  Map<String, dynamic> toMap() => {
    'id'       : id,
    'name'     : name,
    'date'     : date.toIso8601String(),
    'duration' : durationMinutes,
    'exercises': exercises.map((e) => e.toMap()).toList(),
    'completed': isCompleted,
  };

  factory WorkoutSession.fromMap(Map<String, dynamic> m) => WorkoutSession(
    id             : m['id']        as String? ?? '',
    name           : m['name']      as String? ?? 'Entrenamiento',
    date           : DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
    durationMinutes: (m['duration'] as num?)?.toInt() ?? 0,
    exercises      : (m['exercises'] as List? ?? [])
        .map((e) => LoggedExercise.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    isCompleted    : m['completed'] as bool? ?? false,
  );
}

// ── Servicio singleton ────────────────────────────────────────────

class WorkoutLogService {
  WorkoutLogService._();
  static final WorkoutLogService instance = WorkoutLogService._();

  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ─── Sesiones completadas ─────────────────────────────────────

  Future<List<WorkoutSession>> loadSessions() async {
    return _loadLocalSessions();
  }

  Future<List<WorkoutSession>> _loadLocalSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kSessionsKey);
      if (raw == null) return [];
      final list  = List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)));
      return list.map(WorkoutSession.fromMap).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(WorkoutSession session) async {
    // Siempre guarda localmente primero
    final prefs    = await SharedPreferences.getInstance();
    final sessions = await _loadLocalSessions();
    final idx      = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }
    await prefs.setString(
        _kSessionsKey, jsonEncode(sessions.map((s) => s.toMap()).toList()));

    // Sincroniza con Supabase en segundo plano (no bloqueante)
    final uid = _uid;
    if (uid != null) {
      unawaited(_syncToSupabase(session, uid));
    }
  }

  Future<void> _syncToSupabase(WorkoutSession session, String uid) async {
    try {
      await _db.from('workout_sessions').upsert({
        ...session.toMap(),
        'user_id'     : uid,
        'total_volume': session.totalVolume,
        'total_sets'  : session.totalDoneSets,
      });
    } catch (_) {}
  }

  Future<void> deleteSession(String id) async {
    final prefs    = await SharedPreferences.getInstance();
    final sessions = await _loadLocalSessions();
    sessions.removeWhere((s) => s.id == id);
    await prefs.setString(
        _kSessionsKey, jsonEncode(sessions.map((s) => s.toMap()).toList()));

    final uid = _uid;
    if (uid != null) {
      unawaited(_deleteFromSupabase(id, uid));
    }
  }

  Future<void> _deleteFromSupabase(String id, String uid) async {
    try {
      await _db.from('workout_sessions').delete()
          .eq('id', id).eq('user_id', uid);
    } catch (_) {}
  }

  // ─── Sesión activa (sobrevive cierres/muertes de la app) ────────

  Future<void> saveActiveSession(WorkoutSession session, DateTime startTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_kActiveSessionKey, jsonEncode(session.toMap())),
        prefs.setString(_kSessionStartKey,  startTime.toIso8601String()),
      ]);
    } catch (_) {}
  }

  /// Devuelve la sesión activa persistida junto con su hora de inicio, o null.
  Future<({WorkoutSession session, DateTime startTime})?> loadActiveSession() async {
    try {
      final prefs      = await SharedPreferences.getInstance();
      final sessionRaw = prefs.getString(_kActiveSessionKey);
      final startRaw   = prefs.getString(_kSessionStartKey);
      if (sessionRaw == null || startRaw == null) return null;
      final session   = WorkoutSession.fromMap(
          Map<String, dynamic>.from(jsonDecode(sessionRaw) as Map));
      final startTime = DateTime.parse(startRaw);
      return (session: session, startTime: startTime);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_kActiveSessionKey),
        prefs.remove(_kSessionStartKey),
      ]);
    } catch (_) {}
  }

  // ─── Pesos guardados ─────────────────────────────────────────────

  Future<Map<String, double>> loadLastWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kLastWeightsKey);
      if (raw == null) return {};
      final map   = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveLastWeight(String exerciseId, double weight) async {
    final prefs   = await SharedPreferences.getInstance();
    final weights = await loadLastWeights();
    weights[exerciseId] = weight;
    await prefs.setString(_kLastWeightsKey, jsonEncode(weights));
  }

  Future<double?> getLastWeight(String exerciseId) async {
    final weights = await loadLastWeights();
    return weights[exerciseId];
  }

  /// Guarda el último peso registrado para cada ejercicio de la sesión.
  Future<void> saveSessionWeights(WorkoutSession session) async {
    for (final ex in session.exercises) {
      final done = ex.sets.where((s) => s.isDone && s.weight > 0);
      if (done.isNotEmpty) {
        await saveLastWeight(ex.exerciseId, done.last.weight);
      }
    }
  }
}
