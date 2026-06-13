import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/data/muscle_data.dart';

class ExerciseService {
  final _db = Supabase.instance.client;

  Future<List<ExerciseItem>> fetchAll() async {
    try {
      final data = await _db
          .from('exercises')
          .select()
          .order('muscle_id')
          .order('display_order');
      return (data as List)
          .map((m) => ExerciseItem.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> create(ExerciseItem ex, {int displayOrder = 0}) async {
    try {
      await _db.from('exercises').insert({
        'id':            ex.id,
        'name':          ex.name,
        'muscle_id':     ex.muscleId,
        'sets':          ex.sets,
        'reps':          ex.reps,
        'rest_seconds':  ex.restSeconds,
        if (ex.tip != null && ex.tip!.isNotEmpty) 'tip': ex.tip,
        'difficulty':    ex.difficulty.name,
        'display_order': displayOrder,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(ExerciseItem ex) async {
    try {
      await _db.from('exercises').update({
        'name':         ex.name,
        'muscle_id':    ex.muscleId,
        'sets':         ex.sets,
        'reps':         ex.reps,
        'rest_seconds': ex.restSeconds,
        'tip':          (ex.tip?.isNotEmpty == true) ? ex.tip : null,
        'difficulty':   ex.difficulty.name,
      }).eq('id', ex.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _db.from('exercises').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
