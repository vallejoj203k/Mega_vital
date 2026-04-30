// lib/core/providers/weight_provider.dart
import 'package:flutter/material.dart';
import '../../services/weight_service.dart';

export '../../services/weight_service.dart' show WeightEntry;

class WeightProvider extends ChangeNotifier {
  final WeightService _service;

  List<WeightEntry> _history = [];
  bool _isLoading = false;

  WeightProvider({WeightService? service})
      : _service = service ?? WeightService();

  List<WeightEntry> get history    => _history;
  bool              get isLoading  => _isLoading;

  // Último registro (más reciente primero)
  WeightEntry? get latest => _history.isEmpty ? null : _history.first;

  // Diferencia entre el último y el anterior (+ sube, - baja)
  double? get trend {
    if (_history.length < 2) return null;
    return _history[0].weight - _history[1].weight;
  }

  // true si no hay entradas o la última tiene más de 30 días
  bool get needsMonthlyUpdate {
    if (_history.isEmpty) return true;
    return DateTime.now().difference(_history.first.recordedAt).inDays >= 30;
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    _history   = await _service.fetchHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addEntry(double weight) async {
    final ok = await _service.addEntry(weight);
    if (ok) await load();
    return ok;
  }

  void clear() {
    _history   = [];
    _isLoading = false;
    notifyListeners();
  }
}
