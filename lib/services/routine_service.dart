// lib/services/routine_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/data/muscle_data.dart';

const _kRoutinesKey = 'mv_routines';

class RoutineService {
  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ── Load own routines (from local cache) ─────────────────────────
  Future<List<SavedRoutine>> loadRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kRoutinesKey);
      if (raw == null) return [];
      final list  = List<Map<String, dynamic>>.from(jsonDecode(raw));
      return list.map(_fromMap).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  // ── Load routines for any user (from Supabase) ────────────────────
  Future<List<SavedRoutine>> loadRoutinesForUser(String userId) async {
    try {
      final rows = await _db
          .from('user_routines')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false) as List;
      return rows.map((r) => _fromSupabaseRow(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Save routine (local + Supabase) ───────────────────────────────
  Future<void> saveRoutine(SavedRoutine routine) async {
    // Local cache
    final prefs    = await SharedPreferences.getInstance();
    final existing = await loadRoutines();
    existing.removeWhere((r) => r.id == routine.id);
    existing.add(routine);
    await prefs.setString(_kRoutinesKey,
        jsonEncode(existing.map((r) => r.toMap()).toList()));

    // Supabase sync — exercise_ids stores [{id, weight?}] objects
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('user_routines').upsert({
        'id':          routine.id,
        'user_id':     uid,
        'name':        routine.name,
        'muscle_id':   routine.muscleId,
        'muscle_name': routine.muscleName,
        'muscle_ids':  routine.muscleIds,
        'exercise_ids': routine.exercises.map((e) {
          final w = routine.exerciseWeights[e.id];
          // Guardamos los datos completos para no depender de kAllExercises
          return {
            ...e.toMap(),
            if (w != null && w > 0) 'weight': w,
          };
        }).toList(),
        'created_at':  routine.createdAt.toIso8601String(),
      }, onConflict: 'id');
    } catch (_) {}
  }

  // ── Delete routine (local + Supabase) ─────────────────────────────
  Future<void> deleteRoutine(String id) async {
    // Local cache
    final prefs    = await SharedPreferences.getInstance();
    final existing = await loadRoutines();
    existing.removeWhere((r) => r.id == id);
    await prefs.setString(_kRoutinesKey,
        jsonEncode(existing.map((r) => r.toMap()).toList()));

    // Supabase sync
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('user_routines')
          .delete()
          .eq('id', id)
          .eq('user_id', uid);
    } catch (_) {}
  }

  SavedRoutine _fromMap(Map<String, dynamic> m) {
    List<ExerciseItem> exercises;
    // Formato nuevo: datos completos guardados en la rutina
    if (m['exercises'] is List && (m['exercises'] as List).isNotEmpty) {
      exercises = (m['exercises'] as List)
          .map((e) => ExerciseItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      // Formato antiguo: solo IDs → buscar en kAllExercises
      final ids = List<String>.from(m['exerciseIds'] ?? []);
      exercises = ids
          .map((id) => kAllExercises.cast<ExerciseItem?>()
              .firstWhere((e) => e?.id == id, orElse: () => null))
          .whereType<ExerciseItem>()
          .toList();
    }
    final weightsRaw = (m['exerciseWeights'] as Map?)?.cast<String, dynamic>() ?? {};
    final weights = weightsRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    // Support new muscleIds list or fall back to legacy single muscleId
    final muscleIds   = m['muscleIds']   != null
        ? List<String>.from(m['muscleIds'])
        : [m['muscleId'] as String? ?? ''];
    final muscleNames = m['muscleNames'] != null
        ? List<String>.from(m['muscleNames'])
        : [m['muscleName'] as String? ?? ''];
    return SavedRoutine(
      id: m['id'] ?? '', name: m['name'] ?? 'Rutina',
      muscleIds: muscleIds, muscleNames: muscleNames,
      exercises: exercises, exerciseWeights: weights,
      createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  SavedRoutine _fromSupabaseRow(Map<String, dynamic> r) {
    // exercise_ids acepta 3 formatos:
    //   legacy string:    ["id1"]
    //   solo id+peso:     [{"id":"id1","weight":80}]
    //   datos completos:  [{"id","name","muscle_id",...,"weight"}]
    final rawList  = (r['exercise_ids'] as List?) ?? [];
    final weights  = <String, double>{};
    final exercises = <ExerciseItem>[];
    for (final item in rawList) {
      if (item is String) {
        // Solo id → buscar en kAllExercises
        final ex = kAllExercises.cast<ExerciseItem?>()
            .firstWhere((e) => e?.id == item, orElse: () => null);
        if (ex != null) exercises.add(ex);
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final id  = map['id'] as String?;
        if (id == null) continue;
        final w = map['weight'];
        if (w != null) weights[id] = (w as num).toDouble();
        if (map.containsKey('name')) {
          // Datos completos guardados en la rutina
          exercises.add(ExerciseItem.fromMap(map));
        } else {
          // Solo id+peso → buscar en kAllExercises
          final ex = kAllExercises.cast<ExerciseItem?>()
              .firstWhere((e) => e?.id == id, orElse: () => null);
          if (ex != null) exercises.add(ex);
        }
      }
    }
    // Support new muscle_ids array or fall back to single muscle_id
    final muscleIds   = r['muscle_ids'] != null
        ? List<String>.from(r['muscle_ids'] as List)
        : [r['muscle_id'] as String? ?? ''];
    final muscleNames = muscleIds.map((id) {
      if (id.isEmpty) return r['muscle_name'] as String? ?? '';
      return kMuscleGroups.cast<MuscleGroup?>()
          .firstWhere((m) => m?.id == id, orElse: () => null)?.name
          ?? (r['muscle_name'] as String? ?? '');
    }).toList();
    return SavedRoutine(
      id:              r['id'] as String,
      name:            r['name'] as String,
      muscleIds:       muscleIds,
      muscleNames:     muscleNames,
      exercises:       exercises,
      exerciseWeights: weights,
      createdAt:       DateTime.parse(r['created_at'] as String),
    );
  }
}
