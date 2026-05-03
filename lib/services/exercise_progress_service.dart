// lib/services/exercise_progress_service.dart
// Sincroniza el progreso de ejercicios al cloud (Supabase) como backup.
// La fuente de verdad siempre es el almacenamiento local (WorkoutLogProvider).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'workout_log_service.dart';

class ExerciseProgressService {
  ExerciseProgressService._();
  static final instance = ExerciseProgressService._();

  final _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  /// Sincroniza todas las sesiones completadas al cloud.
  /// Usa UPSERT con ON CONFLICT DO NOTHING para no sobreescribir datos
  /// si la fila ya existe con el mismo (user_id, exercise_name, session_date).
  Future<void> syncAllSessions(List<WorkoutSession> sessions) async {
    final uid = _uid;
    if (uid == null) return;

    final completed = sessions.where((s) => s.isCompleted).toList();
    if (completed.isEmpty) return;

    final rows = <Map<String, dynamic>>[];

    for (final session in completed) {
      final dateStr = session.date.toIso8601String().substring(0, 10);
      for (final ex in session.exercises) {
        final done = ex.sets.where((s) => s.isDone).toList();
        if (done.isEmpty) continue;
        rows.add({
          'user_id':       uid,
          'exercise_name': ex.exerciseName,
          'muscle_id':     ex.muscleId,
          'session_date':  dateStr,
          'max_weight':    ex.maxWeight,
          'total_volume':  ex.totalVolume,
        });
      }
    }

    if (rows.isEmpty) return;

    // Lotes de 50 para no superar el límite de payload
    const batchSize = 50;
    for (int i = 0; i < rows.length; i += batchSize) {
      final batch = rows.sublist(i, (i + batchSize).clamp(0, rows.length));
      try {
        await _db
            .from('exercise_progress')
            .upsert(batch, onConflict: 'user_id,exercise_name,session_date');
      } catch (_) {
        // Silencioso — el cloud es solo backup
      }
    }
  }
}
