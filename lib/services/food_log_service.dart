// lib/services/food_log_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────
// MODELO: Un alimento registrado
// ─────────────────────────────────────────────────────────────────
class FoodEntry {
  final String id;
  final String name;
  final String mealType;
  final int    calories;
  final double protein;
  final double carbs;
  final double fat;
  final double portions;
  final DateTime loggedAt;

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

  int    get adjustedCalories => (calories * portions).round();
  double get adjustedProtein  => double.parse((protein * portions).toStringAsFixed(1));
  double get adjustedCarbs    => double.parse((carbs * portions).toStringAsFixed(1));
  double get adjustedFat      => double.parse((fat * portions).toStringAsFixed(1));

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

  factory FoodEntry.fromRow(Map<String, dynamic> r) => FoodEntry(
    id:       r['id'] as String,
    name:     r['name'] as String,
    mealType: r['meal_type'] as String,
    calories: (r['calories'] as num).toInt(),
    protein:  (r['protein']  as num).toDouble(),
    carbs:    (r['carbs']    as num).toDouble(),
    fat:      (r['fat']      as num).toDouble(),
    portions: (r['portions'] as num).toDouble(),
    loggedAt: DateTime.parse(r['logged_at'] as String),
  );

  Map<String, dynamic> toRow(String userId, DateTime date) => {
    'id':        id,
    'user_id':   userId,
    'date':      _dateKey(date),
    'meal_type': mealType,
    'name':      name,
    'calories':  calories,
    'protein':   protein,
    'carbs':     carbs,
    'fat':       fat,
    'portions':  portions,
    'logged_at': loggedAt.toIso8601String(),
  };

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

  int    get totalCalories => entries.fold(0,    (s, e) => s + e.adjustedCalories);
  double get totalProtein  => entries.fold(0.0,  (s, e) => s + e.adjustedProtein);
  double get totalCarbs    => entries.fold(0.0,  (s, e) => s + e.adjustedCarbs);
  double get totalFat      => entries.fold(0.0,  (s, e) => s + e.adjustedFat);

  Map<String, List<FoodEntry>> get byMealType {
    final map = <String, List<FoodEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.mealType, () => []).add(e);
    }
    return map;
  }

  static const mealOrder = ['desayuno', 'almuerzo', 'merienda', 'cena', 'extra'];

  int caloriesFor(String mealType) =>
      (byMealType[mealType] ?? []).fold(0, (s, e) => s + e.adjustedCalories);

  factory FoodLog.empty(DateTime date) => FoodLog(date: date, entries: []);
}

// ─────────────────────────────────────────────────────────────────
// SERVICIO
// ─────────────────────────────────────────────────────────────────
class FoodLogService {
  static final FoodLogService instance = FoodLogService._();
  FoodLogService._();

  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<FoodLog> loadDay(DateTime date) async {
    final uid = _uid;
    if (uid == null) return FoodLog.empty(date);
    try {
      final rows = await _db
          .from('nutrition_logs')
          .select()
          .eq('user_id', uid)
          .eq('date', _dateKey(date)) as List;
      return FoodLog(
        date:    date,
        entries: rows
            .map((r) => FoodEntry.fromRow(r as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return FoodLog.empty(date);
    }
  }

  Future<FoodLog> loadToday() => loadDay(DateTime.now());

  Future<FoodLog> addEntry(FoodEntry entry, {DateTime? date}) async {
    final uid = _uid;
    final day = date ?? DateTime.now();
    if (uid == null) return FoodLog.empty(day);
    try {
      await _db.from('nutrition_logs').insert(entry.toRow(uid, day));
    } catch (_) {}
    return loadDay(day);
  }

  Future<FoodLog> updateEntry(FoodEntry updated, {DateTime? date}) async {
    final uid = _uid;
    final day = date ?? DateTime.now();
    if (uid == null) return FoodLog.empty(day);
    try {
      await _db.from('nutrition_logs').update({
        'name':      updated.name,
        'meal_type': updated.mealType,
        'calories':  updated.calories,
        'protein':   updated.protein,
        'carbs':     updated.carbs,
        'fat':       updated.fat,
        'portions':  updated.portions,
      }).eq('id', updated.id).eq('user_id', uid);
    } catch (_) {}
    return loadDay(day);
  }

  Future<FoodLog> removeEntry(String entryId, {DateTime? date}) async {
    final uid = _uid;
    final day = date ?? DateTime.now();
    if (uid == null) return FoodLog.empty(day);
    try {
      await _db.from('nutrition_logs')
          .delete()
          .eq('id', entryId)
          .eq('user_id', uid);
    } catch (_) {}
    return loadDay(day);
  }

  Future<List<FoodLog>> loadRange(DateTime from, DateTime to) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('nutrition_logs')
          .select()
          .eq('user_id', uid)
          .gte('date', _dateKey(from))
          .lte('date', _dateKey(to)) as List;

      final grouped = <String, List<FoodEntry>>{};
      for (final r in rows) {
        final key = r['date'] as String;
        grouped.putIfAbsent(key, () => [])
            .add(FoodEntry.fromRow(r as Map<String, dynamic>));
      }

      final logs    = <FoodLog>[];
      var   current = DateTime(from.year, from.month, from.day);
      final end     = DateTime(to.year, to.month, to.day);
      while (!current.isAfter(end)) {
        logs.add(FoodLog(date: current, entries: grouped[_dateKey(current)] ?? []));
        current = current.add(const Duration(days: 1));
      }
      return logs;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearDay(DateTime date) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('nutrition_logs')
          .delete()
          .eq('user_id', uid)
          .eq('date', _dateKey(date));
    } catch (_) {}
  }

  static String generateId() {
    final rng   = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
