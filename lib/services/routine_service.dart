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

    // Supabase sync
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('user_routines').upsert({
        'id':          routine.id,
        'user_id':     uid,
        'name':        routine.name,
        'muscle_id':   routine.muscleId,
        'muscle_name': routine.muscleName,
        'exercise_ids': routine.exercises.map((e) => e.id).toList(),
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
    final ids = List<String>.from(m['exerciseIds'] ?? []);
    final exercises = ids
        .map((id) => kAllExercises.cast<ExerciseItem?>()
            .firstWhere((e) => e?.id == id, orElse: () => null))
        .whereType<ExerciseItem>()
        .toList();
    return SavedRoutine(
      id: m['id'] ?? '', name: m['name'] ?? 'Rutina',
      muscleId: m['muscleId'] ?? '', muscleName: m['muscleName'] ?? '',
      exercises: exercises,
      createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  SavedRoutine _fromSupabaseRow(Map<String, dynamic> r) {
    final ids = List<String>.from((r['exercise_ids'] as List?) ?? []);
    final exercises = ids
        .map((id) => kAllExercises.cast<ExerciseItem?>()
            .firstWhere((e) => e?.id == id, orElse: () => null))
        .whereType<ExerciseItem>()
        .toList();
    return SavedRoutine(
      id:         r['id'] as String,
      name:       r['name'] as String,
      muscleId:   r['muscle_id'] as String,
      muscleName: r['muscle_name'] as String,
      exercises:  exercises,
      createdAt:  DateTime.parse(r['created_at'] as String),
    );
  }
}
