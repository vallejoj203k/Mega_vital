// lib/core/providers/nutrition_provider.dart
// ─────────────────────────────────────────────────────────────────
// Provider que gestiona el estado de nutrición del día.
// Se encarga de cargar, agregar, editar y eliminar alimentos,
// y notificar a todos los widgets que lo escuchan.
//
// Uso:
//   context.watch<NutritionProvider>()   → escucha cambios
//   context.read<NutritionProvider>()    → acción sin rebuild
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/food_log_service.dart';
import '../../services/points_service.dart';

class NutritionProvider extends ChangeNotifier {
  final FoodLogService _service = FoodLogService.instance;

  // ── Estado ────────────────────────────────────────────────────
  FoodLog  _log       = FoodLog.empty(DateTime.now());
  bool     _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  // ── Getters ───────────────────────────────────────────────────
  FoodLog  get log          => _log;
  bool     get isLoading    => _isLoading;
  DateTime get selectedDate => _selectedDate;
  bool     get isToday      =>
      _selectedDate.year  == DateTime.now().year &&
      _selectedDate.month == DateTime.now().month &&
      _selectedDate.day   == DateTime.now().day;

  // Totales del día
  int    get totalCalories => _log.totalCalories;
  double get totalProtein  => _log.totalProtein;
  double get totalCarbs    => _log.totalCarbs;
  double get totalFat      => _log.totalFat;

  // Entradas de hoy agrupadas por tipo de comida
  Map<String, List<FoodEntry>> get byMealType => _log.byMealType;

  // ── Inicializar (llamar en initState o en el Provider) ────────
  Future<void> init() async {
    await loadDay(DateTime.now());
  }

  // ── Cargar un día específico ──────────────────────────────────
  Future<void> loadDay(DateTime date) async {
    _isLoading = true;
    _selectedDate = date;
    notifyListeners();

    _log = await _service.loadDay(date);

    _isLoading = false;
    notifyListeners();
  }

  // ── Cargar hoy ────────────────────────────────────────────────
  Future<void> loadToday() => loadDay(DateTime.now());

  // ── Navegar al día anterior / siguiente ───────────────────────
  Future<void> previousDay() =>
      loadDay(_selectedDate.subtract(const Duration(days: 1)));

  Future<void> nextDay() {
    final next = _selectedDate.add(const Duration(days: 1));
    // No permitir navegar al futuro
    if (next.isAfter(DateTime.now())) return Future.value();
    return loadDay(next);
  }

  // ── Agregar alimento ──────────────────────────────────────────
  Future<void> addEntry({
    required String name,
    required String mealType,
    required int    calories,
    required double protein,
    required double carbs,
    required double fat,
    double portions = 1.0,
  }) async {
    final entry = FoodEntry(
      id:        FoodLogService.generateId(),
      name:      name.trim(),
      mealType:  mealType,
      calories:  calories,
      protein:   protein,
      carbs:     carbs,
      fat:       fat,
      portions:  portions,
      loggedAt:  DateTime.now(),
    );

    _log = await _service.addEntry(entry, date: _selectedDate);
    notifyListeners();
  }

  // ── Actualizar porciones de un alimento ───────────────────────
  Future<void> updatePortions(String entryId, double portions) async {
    final entry = _log.entries.cast<FoodEntry?>()
        .firstWhere((e) => e?.id == entryId, orElse: () => null);
    if (entry == null) return;

    _log = await _service.updateEntry(
      entry.copyWithPortions(portions),
      date: _selectedDate,
    );
    notifyListeners();
  }

  // ── Eliminar alimento ─────────────────────────────────────────
  Future<void> removeEntry(String entryId) async {
    _log = await _service.removeEntry(entryId, date: _selectedDate);
    notifyListeners();
  }

  // ── Limpiar el día ────────────────────────────────────────────
  Future<void> clearDay() async {
    await _service.clearDay(_selectedDate);
    _log = FoodLog.empty(_selectedDate);
    notifyListeners();
  }

  // ── Meta nutricional diaria ───────────────────────────────────
  // Llama esto después de addEntry cuando sea el día de hoy.
  // goalCalories: meta calculada por FitnessCalculator del perfil.
  // Solo otorga puntos si la meta se cumple y no se han otorgado hoy.
  Future<void> checkAndAwardNutritionGoal({
    required int goalCalories,
    required String userName,
  }) async {
    if (!isToday) return;
    if (totalCalories < goalCalories) return;
    await PointsService.instance.awardNutritionGoal(userName);
  }
}
