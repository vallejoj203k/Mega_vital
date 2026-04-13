// lib/services/food_log_service.dart
// ─────────────────────────────────────────────────────────────────
// Servicio completo de registro de alimentos.
//
// Modelos:
//   FoodEntry   → un alimento individual (nombre + macros)
//   FoodLog     → todos los alimentos de un día específico
//
// Almacenamiento:
//   SharedPreferences con clave 'mv_food_YYYY-MM-DD'
//   Cada día tiene su propio registro independiente.
//
// Acceso rápido:
//   FoodLogService.instance  (singleton)
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Prefijo de clave en SharedPreferences ─────────────────────────
const _kFoodPrefix = 'mv_food_';

// ─────────────────────────────────────────────────────────────────
// MODELO: Un alimento registrado
// ─────────────────────────────────────────────────────────────────
class FoodEntry {
  final String id;          // timestamp único
  final String name;        // "Pollo a la plancha"
  final String mealType;    // desayuno | almuerzo | merienda | cena | extra
  final int    calories;    // kcal
  final double protein;     // gramos
  final double carbs;       // gramos
  final double fat;         // gramos
  final double portions;    // factor de porción (1.0 = estándar)
  final DateTime loggedAt;  // cuándo fue registrado

  const FoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.portions = 1.0,
    required this.loggedAt,
  });

  // ── Macros ajustados por porciones ────────────────────────────
  int    get adjustedCalories => (calories * portions).round();
  double get adjustedProtein  => double.parse((protein * portions).toStringAsFixed(1));
  double get adjustedCarbs    => double.parse((carbs * portions).toStringAsFixed(1));
  double get adjustedFat      => double.parse((fat * portions).toStringAsFixed(1));

  // ── Ícono y color según tipo de comida ────────────────────────
  IconData get icon {
    switch (mealType) {
      case 'desayuno':  return Icons.wb_sunny_rounded;
      case 'almuerzo':  return Icons.lunch_dining_rounded;
      case 'merienda':  return Icons.apple_rounded;
      case 'cena':      return Icons.nightlight_round;
      default:          return Icons.restaurant_rounded;
    }
  }

  Color get color {
    switch (mealType) {
      case 'desayuno':  return const Color(0xFFFFB020);
      case 'almuerzo':  return const Color(0xFF4FC3F7);
      case 'merienda':  return const Color(0xFF00FF87);
      case 'cena':      return const Color(0xFFBB86FC);
      default:          return const Color(0xFFFF6B35);
    }
  }

  // ── Serialización ─────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id':        id,
    'name':      name,
    'mealType':  mealType,
    'calories':  calories,
    'protein':   protein,
    'carbs':     carbs,
    'fat':       fat,
    'portions':  portions,
    'loggedAt':  loggedAt.toIso8601String(),
  };

  factory FoodEntry.fromMap(Map<String, dynamic> m) => FoodEntry(
    id:        m['id']       ?? '',
    name:      m['name']     ?? '',
    mealType:  m['mealType'] ?? 'extra',
    calories:  (m['calories'] ?? 0) as int,
    protein:   (m['protein']  ?? 0.0).toDouble(),
    carbs:     (m['carbs']    ?? 0.0).toDouble(),
    fat:       (m['fat']      ?? 0.0).toDouble(),
    portions:  (m['portions'] ?? 1.0).toDouble(),
    loggedAt:  DateTime.tryParse(m['loggedAt'] ?? '') ?? DateTime.now(),
  );

  // ── Crear copia con porciones distintas ───────────────────────
  FoodEntry copyWithPortions(double p) => FoodEntry(
    id: id, name: name, mealType: mealType,
    calories: calories, protein: protein, carbs: carbs, fat: fat,
    portions: p, loggedAt: loggedAt,
  );
}

// ─────────────────────────────────────────────────────────────────
// MODELO: Registro del día completo
// ─────────────────────────────────────────────────────────────────
class FoodLog {
  final DateTime        date;
  final List<FoodEntry> entries;

  const FoodLog({required this.date, required this.entries});

  // ── Totales del día ───────────────────────────────────────────
  int    get totalCalories => entries.fold(0,    (s, e) => s + e.adjustedCalories);
  double get totalProtein  => entries.fold(0.0,  (s, e) => s + e.adjustedProtein);
  double get totalCarbs    => entries.fold(0.0,  (s, e) => s + e.adjustedCarbs);
  double get totalFat      => entries.fold(0.0,  (s, e) => s + e.adjustedFat);

  // ── Entradas agrupadas por tipo de comida ─────────────────────
  Map<String, List<FoodEntry>> get byMealType {
    final map = <String, List<FoodEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.mealType, () => []).add(e);
    }
    return map;
  }

  // ── Lista de tipos de comida en orden ─────────────────────────
  static const mealOrder = ['desayuno', 'almuerzo', 'merienda', 'cena', 'extra'];

  // ── Calorías de un tipo de comida ─────────────────────────────
  int caloriesFor(String mealType) =>
      (byMealType[mealType] ?? []).fold(0, (s, e) => s + e.adjustedCalories);

  // ── Serialización ─────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'date':    _dateKey(date),
    'entries': entries.map((e) => e.toMap()).toList(),
  };

  factory FoodLog.fromMap(Map<String, dynamic> m) => FoodLog(
    date:    DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
    entries: (m['entries'] as List? ?? [])
        .map((e) => FoodEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  // Registro vacío para un día dado
  factory FoodLog.empty(DateTime date) => FoodLog(date: date, entries: []);
}

// ─────────────────────────────────────────────────────────────────
// SERVICIO
// ─────────────────────────────────────────────────────────────────
class FoodLogService {
  // ── Singleton ─────────────────────────────────────────────────
  static final FoodLogService instance = FoodLogService._();
  FoodLogService._();

  // ── Clave de almacenamiento para una fecha ────────────────────
  static String _key(DateTime date) => '$_kFoodPrefix${_dateKey(date)}';

  // ── Cargar el log de un día ───────────────────────────────────
  Future<FoodLog> loadDay(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key(date));
      if (raw == null) return FoodLog.empty(date);
      return FoodLog.fromMap(jsonDecode(raw));
    } catch (_) {
      return FoodLog.empty(date);
    }
  }

  // ── Cargar el log de hoy ──────────────────────────────────────
  Future<FoodLog> loadToday() => loadDay(DateTime.now());

  // ── Guardar el log completo de un día ─────────────────────────
  Future<void> _saveLog(FoodLog log) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(log.date), jsonEncode(log.toMap()));
  }

  // ── Agregar un alimento al día ────────────────────────────────
  Future<FoodLog> addEntry(FoodEntry entry, {DateTime? date}) async {
    final day = date ?? DateTime.now();
    final log = await loadDay(day);
    final updated = FoodLog(
      date:    log.date,
      entries: [...log.entries, entry],
    );
    await _saveLog(updated);
    return updated;
  }

  // ── Editar un alimento existente ──────────────────────────────
  Future<FoodLog> updateEntry(FoodEntry updated, {DateTime? date}) async {
    final day = date ?? DateTime.now();
    final log = await loadDay(day);
    final newEntries = log.entries.map((e) => e.id == updated.id ? updated : e).toList();
    final newLog = FoodLog(date: log.date, entries: newEntries);
    await _saveLog(newLog);
    return newLog;
  }

  // ── Eliminar un alimento ──────────────────────────────────────
  Future<FoodLog> removeEntry(String entryId, {DateTime? date}) async {
    final day = date ?? DateTime.now();
    final log = await loadDay(day);
    final newLog = FoodLog(
      date:    log.date,
      entries: log.entries.where((e) => e.id != entryId).toList(),
    );
    await _saveLog(newLog);
    return newLog;
  }

  // ── Cargar varios días (para historial / progreso) ────────────
  Future<List<FoodLog>> loadRange(DateTime from, DateTime to) async {
    final logs = <FoodLog>[];
    var current = DateTime(from.year, from.month, from.day);
    final end    = DateTime(to.year,   to.month,   to.day);
    while (!current.isAfter(end)) {
      logs.add(await loadDay(current));
      current = current.add(const Duration(days: 1));
    }
    return logs;
  }

  // ── Borrar el registro de un día (por si el usuario lo necesita) ─
  Future<void> clearDay(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(date));
  }

  // ── Generar ID único ──────────────────────────────────────────
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}

// ── Helper: convierte DateTime a string de clave 'YYYY-MM-DD' ────
String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
