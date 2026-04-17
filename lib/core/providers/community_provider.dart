import 'package:flutter/material.dart';
import '../../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final _service = CommunityService();

  List<CommunityPost> _posts = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _loadingPosts = false;
  bool _loadingLeaderboard = false;
  bool _initialized = false;

  List<CommunityPost> get posts => _posts;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get loadingPosts => _loadingPosts;
  bool get loadingLeaderboard => _loadingLeaderboard;
  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    await Future.wait([loadPosts(), loadLeaderboard()]);
    _initialized = true;
  }

  Future<void> loadPosts() async {
    _loadingPosts = true;
    notifyListeners();
    _posts = await _service.fetchPosts();
    _loadingPosts = false;
    notifyListeners();
  }

  Future<void> loadLeaderboard() async {
    _loadingLeaderboard = true;
    notifyListeners();
    _leaderboard = await _service.fetchLeaderboard();
    _loadingLeaderboard = false;
    notifyListeners();
  }

  /// Retorna null en éxito, o el mensaje de error en fallo.
  Future<String?> createPost(
    String userName,
    String content, {
    String? achievement,
  }) async {
    final error = await _service.createPost(
      userName: userName,
      content: content,
      achievement: achievement,
    );
    if (error == null) await loadPosts();
    return error;
  }

  Future<void> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    final newLiked = !post.likedByMe;
    // Optimistic update
    _posts[idx] = post.copyWith(
      likedByMe: newLiked,
      likesCount: post.likesCount + (newLiked ? 1 : -1),
    );
    notifyListeners();
    final ok = await _service.toggleLike(postId, currentlyLiked: post.likedByMe);
    if (!ok) {
      // Revert on failure
      _posts[idx] = post;
      notifyListeners();
    }
  }

  Future<bool> deletePost(String postId) async {
    final ok = await _service.deletePost(postId);
    if (ok) {
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    }
    return ok;
  }

  Future<List<CommunityComment>> fetchComments(String postId) =>
      _service.fetchComments(postId);

  Future<bool> addComment(
    String postId,
    String userName,
    String content,
  ) async {
    final ok = await _service.addComment(
      postId: postId,
      userName: userName,
      content: content,
    );
    if (ok) {
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final post = _posts[idx];
        _posts[idx] = CommunityPost(
          id: post.id,
          userId: post.userId,
          userName: post.userName,
          userInitials: post.userInitials,
          content: post.content,
          achievement: post.achievement,
          createdAt: post.createdAt,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount + 1,
          likedByMe: post.likedByMe,
        );
        notifyListeners();
      }
    }
    return ok;
  }
}
