// lib/services/exercise_progress_service.dart
// Sincroniza el progreso de ejercicios con Supabase.
// Fallback silencioso a datos locales cuando no hay conexión.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'workout_log_service.dart';

class ExerciseProgressEntry {
  final String exerciseName;
  final String muscleId;
  final DateTime date;
  final double maxWeight;
  final double volume;
  final int sets;

  const ExerciseProgressEntry({
    required this.exerciseName,
    required this.muscleId,
    required this.date,
    required this.maxWeight,
    required this.volume,
    required this.sets,
  });

  factory ExerciseProgressEntry.fromMap(Map<String, dynamic> m) =>
      ExerciseProgressEntry(
        exerciseName: m['exercise_name'] as String? ?? '',
        muscleId: m['muscle_id'] as String? ?? '',
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        maxWeight: (m['max_weight'] as num?)?.toDouble() ?? 0.0,
        volume: (m['volume'] as num?)?.toDouble() ?? 0.0,
        sets: (m['sets'] as num?)?.toInt() ?? 0,
      );
}

class ExerciseProgressService {
  ExerciseProgressService._();
  static final ExerciseProgressService instance = ExerciseProgressService._();

  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── Sync ─────────────────────────────────────────────────────────

  /// Guarda el progreso de todos los ejercicios de una sesión en Supabase.
  /// Silencioso en caso de error — los datos siguen en local.
  Future<void> syncSession(WorkoutSession session) async {
    final uid = _uid;
    if (uid == null || !session.isCompleted) return;

    final rows = <Map<String, dynamic>>[];
    for (final ex in session.exercises) {
      final done = ex.sets.where((s) => s.isDone).toList();
      if (done.isEmpty) continue;
      rows.add({
        'user_id': uid,
        'exercise_name': ex.exerciseName,
        'muscle_id': ex.muscleId,
        'date': _dateStr(session.date),
        'max_weight': ex.maxWeight,
        'volume': ex.totalVolume,
        'sets': ex.doneSets,
      });
    }
    if (rows.isEmpty) return;

    try {
      await _db
          .from('exercise_progress')
          .upsert(rows, onConflict: 'user_id,exercise_name,date');
    } catch (_) {
      // No bloquear al usuario — la sesión ya está guardada localmente
    }
  }

  /// Sincroniza todo el historial local a Supabase (migración inicial).
  Future<void> syncAllSessions(List<WorkoutSession> sessions) async {
    for (final s in sessions) {
      await syncSession(s);
    }
  }

  // ── Fetch ─────────────────────────────────────────────────────────

  /// Retorna el progreso agrupado por ejercicio desde Supabase.
  /// Vacío si no hay sesión o falla la red.
  Future<Map<String, List<ExerciseProgressEntry>>> fetchAllProgress() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final data = await _db
          .from('exercise_progress')
          .select()
          .eq('user_id', uid)
          .order('date', ascending: true);

      final Map<String, List<ExerciseProgressEntry>> result = {};
      for (final row in data as List) {
        final entry =
            ExerciseProgressEntry.fromMap(row as Map<String, dynamic>);
        result.putIfAbsent(entry.exerciseName, () => []).add(entry);
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
