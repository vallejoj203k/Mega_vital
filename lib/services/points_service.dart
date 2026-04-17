import 'package:supabase_flutter/supabase_flutter.dart';

// Sistema de puntos de la comunidad Mega Vital:
//   +100  Completar un entrenamiento
//   + 20  Publicar en el feed
//   +  5  Dejar un comentario
//   +  3  Recibir un like en tu publicación
// Los puntos de comunidad (post/like/comment) se otorgan automáticamente
// mediante triggers SQL con SECURITY DEFINER.
// Esta clase gestiona los puntos generados desde Flutter (entrenamientos).

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
}
