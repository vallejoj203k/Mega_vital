import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<bool> followUser(String targetId) async {
    final uid = _uid;
    if (uid == null || uid == targetId) return false;
    try {
      await _db.from('user_follows').insert({
        'follower_id': uid,
        'following_id': targetId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unfollowUser(String targetId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db
          .from('user_follows')
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', targetId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Devuelve los IDs de usuarios que sigue el usuario actual.
  Future<Set<String>> fetchFollowingIds() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final rows = await _db
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', uid);
      return {for (final r in rows as List) r['following_id'] as String};
    } catch (_) {
      return {};
    }
  }

  Future<int> followersCount(String userId) async {
    try {
      final rows = await _db
          .from('user_follows')
          .select('id')
          .eq('following_id', userId);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }
}
