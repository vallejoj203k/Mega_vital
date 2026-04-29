import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String? content;
  final String? imageUrl;   // URL pública en Supabase Storage
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool viewedByMe;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.content,
    this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewedByMe = false,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  factory StoryModel.fromMap(Map<String, dynamic> m, {bool viewedByMe = false}) =>
      StoryModel(
        id:         m['id'] as String,
        userId:     m['user_id'] as String,
        userName:   m['user_name'] as String,
        content:    m['content'] as String?,
        imageUrl:   m['image_url'] as String?,
        createdAt:  DateTime.parse(m['created_at'] as String),
        expiresAt:  DateTime.parse(m['expires_at'] as String),
        viewedByMe: viewedByMe,
      );
}

class UserStoriesGroup {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final List<StoryModel> stories;

  const UserStoriesGroup({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.stories,
  });

  bool get hasUnviewed => stories.any((s) => !s.viewedByMe);

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  String get firstName {
    final name = userName.trim().split(' ').first;
    return name.length > 9 ? '${name.substring(0, 8)}.' : name;
  }
}

class StoryViewer {
  final String userId;
  final String name;
  final String? avatarUrl;

  const StoryViewer({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class StoriesService {
  static const _bucket = 'stories';

  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<List<UserStoriesGroup>> fetchActive() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final rows = await _db
          .from('user_stories')
          .select()
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      if ((rows as List).isEmpty) return [];

      final ids = rows.map((r) => r['id'] as String).toList();

      final views = await _db
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', uid)
          .inFilter('story_id', ids);

      final seen = {for (final v in (views as List)) v['story_id'] as String};

      final stories = rows.map((r) => StoryModel.fromMap(
            r as Map<String, dynamic>,
            viewedByMe: seen.contains(r['id'] as String),
          )).toList();

      final Map<String, List<StoryModel>> map = {};
      for (final s in stories) {
        map.putIfAbsent(s.userId, () => []).add(s);
      }

      final avatars = await _avatarMap(map.keys.toSet());

      return map.entries.map((e) => UserStoriesGroup(
            userId:    e.key,
            userName:  e.value.first.userName,
            avatarUrl: avatars[e.key],
            stories:   e.value,
          )).toList()
        ..sort((a, b) {
          if (a.userId == uid) return -1;
          if (b.userId == uid) return 1;
          if (a.hasUnviewed && !b.hasUnviewed) return -1;
          if (!a.hasUnviewed && b.hasUnviewed) return 1;
          return 0;
        });
    } catch (_) {
      return [];
    }
  }

  Future<bool> add({
    required String userId,
    required String userName,
    String? content,
    File? imageFile,
  }) async {
    try {
      // 1. Insertar el registro y obtener el ID generado por Supabase.
      final rows = await _db.from('user_stories').insert({
        'user_id':    userId,
        'user_name':  userName,
        if (content != null && content.isNotEmpty) 'content': content,
        'expires_at': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      }).select('id');

      if ((rows as List).isEmpty) return false;
      final storyId = rows.first['id'] as String;

      // 2. Subir imagen al Storage si se proporcionó.
      if (imageFile != null) {
        final imageUrl = await _uploadImage(
          file:    imageFile,
          userId:  userId,
          storyId: storyId,
        );
        if (imageUrl != null) {
          await _db
              .from('user_stories')
              .update({'image_url': imageUrl})
              .eq('id', storyId);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _uploadImage({
    required File file,
    required String userId,
    required String storyId,
  }) async {
    try {
      final path = '$userId/$storyId';
      await _db.storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '86400', upsert: true),
      );
      return _db.storage.from(_bucket).getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> markViewed(String storyId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.from('story_views').upsert({
        'story_id':  storyId,
        'viewer_id': uid,
      });
    } catch (_) {}
  }

  Future<Map<String, String?>> _avatarMap(Set<String> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final rows = await _db
          .from('user_profiles')
          .select('uid, avatar_url')
          .inFilter('uid', userIds.toList());
      return {
        for (final r in rows as List)
          r['uid'] as String: r['avatar_url'] as String?,
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<StoryViewer>> fetchViewers(String storyId) async {
    try {
      final views = await _db
          .from('story_views')
          .select('viewer_id')
          .eq('story_id', storyId);

      final ids = (views as List).map((v) => v['viewer_id'] as String).toList();
      if (ids.isEmpty) return [];

      final profiles = await _db
          .from('user_profiles')
          .select('uid, name, avatar_url')
          .inFilter('uid', ids);

      return (profiles as List).map((p) => StoryViewer(
        userId:    p['uid'] as String,
        name:      (p['name'] as String?) ?? 'Usuario',
        avatarUrl: p['avatar_url'] as String?,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> delete(String storyId) async {
    try {
      // Obtener datos antes de borrar para poder limpiar el Storage.
      final rows = await _db
          .from('user_stories')
          .select('user_id, image_url')
          .eq('id', storyId)
          .limit(1);

      await _db.from('user_stories').delete().eq('id', storyId);

      // Borrar imagen del Storage si existía.
      if ((rows as List).isNotEmpty) {
        final row = rows.first as Map<String, dynamic>;
        if (row['image_url'] != null) {
          final uid = row['user_id'] as String;
          await _db.storage.from(_bucket).remove(['$uid/$storyId']);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
