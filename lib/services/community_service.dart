import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userInitials;
  final String content;
  final String? achievement;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.content,
    this.achievement,
    this.imageUrl,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> m, bool likedByMe) {
    final name = m['user_name'] as String? ?? 'Usuario';
    return CommunityPost(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      userName: name,
      userInitials: _initials(name),
      content: m['content'] as String,
      achievement: m['achievement'] as String?,
      imageUrl: m['image_url'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      likesCount: m['likes_count'] as int? ?? 0,
      commentsCount: m['comments_count'] as int? ?? 0,
      likedByMe: likedByMe,
    );
  }

  CommunityPost copyWith({int? likesCount, bool? likedByMe}) => CommunityPost(
    id: id,
    userId: userId,
    userName: userName,
    userInitials: userInitials,
    content: content,
    achievement: achievement,
    imageUrl: imageUrl,
    createdAt: createdAt,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount,
    likedByMe: likedByMe ?? this.likedByMe,
  );

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class CommunityComment {
  final String id;
  final String userId;
  final String userName;
  final String userInitials;
  final String content;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.content,
    required this.createdAt,
  });

  factory CommunityComment.fromMap(Map<String, dynamic> m) {
    final name = m['user_name'] as String? ?? 'Usuario';
    return CommunityComment(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      userName: name,
      userInitials: _initials(name),
      content: m['content'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class LeaderboardEntry {
  final String userId;
  final String name;
  final String initials;
  final int points;
  final int rank;
  final bool isMe;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.initials,
    required this.points,
    required this.rank,
    required this.isMe,
  });

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> m, String currentUid) {
    final name = m['name'] as String? ?? 'Usuario';
    return LeaderboardEntry(
      userId: m['uid'] as String,
      name: name,
      initials: _initials(name),
      points: (m['points'] as num?)?.toInt() ?? 0,
      rank: (m['rank'] as num?)?.toInt() ?? 0,
      isMe: m['uid'] == currentUid,
    );
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class CommunityService {
  final _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  Future<List<CommunityPost>> fetchPosts() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      // select() = SELECT * — resilient si image_url aún no existe en el schema
      final postsRaw = await _db
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final likesRaw = await _db
          .from('post_likes')
          .select('post_id')
          .eq('user_id', uid);

      final likedIds = <String>{
        for (final l in likesRaw as List) l['post_id'] as String,
      };

      return [
        for (final m in postsRaw as List)
          CommunityPost.fromMap(m as Map<String, dynamic>, likedIds.contains(m['id'])),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Retorna null en éxito, o el mensaje de error en fallo.
  Future<String?> createPost({
    required String userName,
    required String content,
    String? achievement,
    File? imageFile,
  }) async {
    final uid = _uid;
    if (uid == null) return 'No hay sesión activa.';
    try {
      final rows = await _db.from('community_posts').insert({
        'user_id': uid,
        'user_name': userName.isEmpty ? 'Usuario' : userName.trim(),
        'content': content.trim(),
        if (achievement != null && achievement.trim().isNotEmpty)
          'achievement': achievement.trim(),
      }).select('id');

      if (imageFile != null && (rows as List).isNotEmpty) {
        final postId = rows.first['id'] as String;
        final imageUrl = await _uploadPostImage(uid: uid, postId: postId, file: imageFile);
        if (imageUrl != null) {
          await _db.from('community_posts')
              .update({'image_url': imageUrl})
              .eq('id', postId);
        } else {
          // Post creado, pero la imagen no pudo subirse (bucket no configurado).
          return 'warn:image';
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _uploadPostImage({
    required String uid,
    required String postId,
    required File file,
  }) async {
    try {
      const bucket = 'post_images';
      final path = '$uid/$postId';
      await _db.storage.from(bucket).upload(
        path, file,
        fileOptions: const FileOptions(cacheControl: '86400', upsert: true),
      );
      return _db.storage.from(bucket).getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deletePost(String postId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db
          .from('community_posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleLike(String postId, {required bool currentlyLiked}) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      if (currentlyLiked) {
        await _db
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', uid);
      } else {
        await _db.from('post_likes').insert({'post_id': postId, 'user_id': uid});
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Posts de un usuario específico (para su perfil público).
  Future<List<CommunityPost>> fetchUserPosts(String userId) async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final postsRaw = await _db
          .from('community_posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      final likesRaw = await _db
          .from('post_likes')
          .select('post_id')
          .eq('user_id', uid);
      final likedIds = <String>{
        for (final l in likesRaw as List) l['post_id'] as String,
      };

      return [
        for (final m in postsRaw as List)
          CommunityPost.fromMap(m as Map<String, dynamic>, likedIds.contains(m['id'])),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<List<CommunityComment>> fetchComments(String postId) async {
    try {
      final data = await _db
          .from('post_comments')
          .select('id, post_id, user_id, user_name, content, created_at')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return [
        for (final m in data as List) CommunityComment.fromMap(m as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addComment({
    required String postId,
    required String userName,
    required String content,
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db.from('post_comments').insert({
        'post_id': postId,
        'user_id': uid,
        'user_name': userName.trim(),
        'content': content.trim(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<LeaderboardEntry>> _fetchLeaderboard(
      String rpcName, String currentUid) async {
    try {
      final data = await _db.rpc(rpcName);
      return [
        for (final m in data as List)
          LeaderboardEntry.fromMap(m as Map<String, dynamic>, currentUid),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<List<LeaderboardEntry>> fetchLeaderboardTotal() async {
    final uid = _uid;
    if (uid == null) return [];
    return _fetchLeaderboard('get_leaderboard_total', uid);
  }

  Future<List<LeaderboardEntry>> fetchLeaderboardWeekly() async {
    final uid = _uid;
    if (uid == null) return [];
    return _fetchLeaderboard('get_leaderboard_weekly', uid);
  }
}
