import 'package:supabase_flutter/supabase_flutter.dart';

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String? content;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool viewedByMe;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.content,
    required this.createdAt,
    required this.expiresAt,
    this.viewedByMe = false,
  });

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  factory StoryModel.fromMap(Map<String, dynamic> m, {bool viewedByMe = false}) =>
      StoryModel(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        userName: m['user_name'] as String,
        content: m['content'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        expiresAt: DateTime.parse(m['expires_at'] as String),
        viewedByMe: viewedByMe,
      );
}

class UserStoriesGroup {
  final String userId;
  final String userName;
  final List<StoryModel> stories;

  const UserStoriesGroup({
    required this.userId,
    required this.userName,
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

class StoriesService {
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

      final stories = rows
          .map((r) => StoryModel.fromMap(
                r as Map<String, dynamic>,
                viewedByMe: seen.contains(r['id'] as String),
              ))
          .toList();

      final Map<String, List<StoryModel>> map = {};
      for (final s in stories) {
        map.putIfAbsent(s.userId, () => []).add(s);
      }

      return map.entries
          .map((e) => UserStoriesGroup(
                userId: e.key,
                userName: e.value.first.userName,
                stories: e.value,
              ))
          .toList()
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
    required String content,
  }) async {
    try {
      await _db.from('user_stories').insert({
        'user_id':    userId,
        'user_name':  userName,
        'content':    content,
        'expires_at': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
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

  Future<bool> delete(String storyId) async {
    try {
      await _db.from('user_stories').delete().eq('id', storyId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
