import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String type;      // 'new_post' | 'new_follower'
  final String title;
  final String body;
  final String? actorId;
  final String? actorName;
  final String? postId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.actorId,
    this.actorName,
    this.postId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id:        m['id'] as String,
    type:      m['type'] as String,
    title:     m['title'] as String,
    body:      m['body'] as String,
    actorId:   m['actor_id'] as String?,
    actorName: m['actor_name'] as String?,
    postId:    m['post_id'] as String?,
    isRead:    m['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, type: type, title: title, body: body,
    actorId: actorId, actorName: actorName, postId: postId,
    isRead: isRead ?? this.isRead, createdAt: createdAt,
  );
}

class NotificationService {
  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<List<AppNotification>> fetchNotifications() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      return [
        for (final r in rows as List)
          AppNotification.fromMap(r as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<int> unreadCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final rows = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String notifId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notifId);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (_) {}
  }
}
