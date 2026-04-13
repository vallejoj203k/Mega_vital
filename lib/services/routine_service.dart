// lib/services/routine_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/data/muscle_data.dart';

const _kRoutinesKey = 'mv_routines';

class RoutineService {
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

  Future<void> saveRoutine(SavedRoutine routine) async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await loadRoutines();
    existing.add(routine);
    await prefs.setString(_kRoutinesKey,
        jsonEncode(existing.map((r) => r.toMap()).toList()));
  }

  Future<void> deleteRoutine(String id) async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await loadRoutines();
    existing.removeWhere((r) => r.id == id);
    await prefs.setString(_kRoutinesKey,
        jsonEncode(existing.map((r) => r.toMap()).toList()));
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
}
