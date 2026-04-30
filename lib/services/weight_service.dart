// lib/services/weight_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class WeightEntry {
  final String   id;
  final double   weight;
  final DateTime recordedAt;

  const WeightEntry({
    required this.id,
    required this.weight,
    required this.recordedAt,
  });

  factory WeightEntry.fromMap(Map<String, dynamic> m) => WeightEntry(
    id:         m['id'] as String,
    weight:     (m['weight'] as num).toDouble(),
    recordedAt: DateTime.parse(m['recorded_at'] as String).toLocal(),
  );
}

class WeightService {
  final _db = Supabase.instance.client;

  // Últimas 12 entradas, de más reciente a más antigua
  Future<List<WeightEntry>> fetchHistory() async {
    try {
      final data = await _db
          .from('weight_history')
          .select()
          .order('recorded_at', ascending: false)
          .limit(12);
      return (data as List)
          .map((e) => WeightEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addEntry(double weight) async {
    try {
      await _db.from('weight_history').insert({
        'user_id': _db.auth.currentUser!.id,
        'weight':  weight,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
