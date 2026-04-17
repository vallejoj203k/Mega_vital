import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sistema de puntos de la comunidad Mega Vital:
//   +100  Completar un entrenamiento           (Flutter → awardWorkout)
//   + 50  Cumplir meta calórica del día        (Flutter → awardNutritionGoal, 1×/día)
//   + 20  Publicar en el feed                  (SQL trigger automático)
//   +  5  Dejar un comentario                  (SQL trigger automático)
//   +  3  Recibir un like en tu publicación    (SQL trigger automático)
// Los puntos de comunidad se otorgan automáticamente mediante triggers SQL.
// Esta clase gestiona los puntos generados desde Flutter.

class PointsService {
  PointsService._();
  static final PointsService instance = PointsService._();

  final _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  Future<void> award({
    required int amount,
    required String reason,
    required String userName,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('point_events').insert({
        'user_id': uid,
        'user_name': userName.isEmpty ? 'Usuario' : userName,
        'amount': amount,
        'reason': reason,
      });
    } catch (_) {
      // No bloqueante — los puntos son un plus, no funcionalidad crítica
    }
  }

  Future<void> awardWorkout(String userName) =>
      award(amount: 100, reason: 'workout', userName: userName);

  Future<void> awardStreak(String userName) =>
      award(amount: 15, reason: 'streak', userName: userName);

  Future<void> awardAchievement(String userName, {int points = 50}) =>
      award(amount: points, reason: 'achievement', userName: userName);

  // +50 pts al cumplir la meta calórica diaria.
  // SharedPreferences garantiza que solo se otorgue una vez al día.
  Future<void> awardNutritionGoal(String userName) async {
    final today = _todayKey();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kNutritionKey) == today) return;
    await award(amount: 50, reason: 'nutrition_goal', userName: userName);
    await prefs.setString(_kNutritionKey, today);
  }

  static const _kNutritionKey = 'mv_pts_nutrition_date';

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
