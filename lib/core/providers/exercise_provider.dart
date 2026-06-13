import 'package:flutter/material.dart';
import '../data/muscle_data.dart';
import '../../services/exercise_service.dart';

class ExerciseProvider extends ChangeNotifier {
  final _service = ExerciseService();

  List<ExerciseItem> _exercises = List.of(kAllExercises);
  bool _loading = false;

  List<ExerciseItem> get exercises => _exercises;
  bool get loading => _loading;

  List<ExerciseItem> forMuscle(String muscleId) =>
      _exercises.where((e) => e.muscleId == muscleId).toList();

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    var exs = await _service.fetchAll();
    if (exs.isEmpty) {
      await _service.seedAll(kAllExercises);
      exs = await _service.fetchAll();
      if (exs.isEmpty) exs = List.of(kAllExercises);
    }
    _exercises = exs;
    _loading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    final exs = await _service.fetchAll();
    if (exs.isNotEmpty) {
      _exercises = exs;
      notifyListeners();
    }
  }
}
