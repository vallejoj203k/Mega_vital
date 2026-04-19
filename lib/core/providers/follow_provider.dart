import 'package:flutter/material.dart';
import '../../services/follow_service.dart';

class FollowProvider extends ChangeNotifier {
  final _service = FollowService();

  Set<String> _followingIds = {};
  bool _loading = false;

  Set<String> get followingIds => _followingIds;
  bool get loading => _loading;

  bool isFollowing(String userId) => _followingIds.contains(userId);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _followingIds = await _service.fetchFollowingIds();
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleFollow(String targetId) async {
    final wasFollowing = _followingIds.contains(targetId);
    // Optimistic update
    if (wasFollowing) {
      _followingIds = {..._followingIds}..remove(targetId);
    } else {
      _followingIds = {..._followingIds, targetId};
    }
    notifyListeners();

    final ok = wasFollowing
        ? await _service.unfollowUser(targetId)
        : await _service.followUser(targetId);

    if (!ok) {
      // Revert on failure
      if (wasFollowing) {
        _followingIds = {..._followingIds, targetId};
      } else {
        _followingIds = {..._followingIds}..remove(targetId);
      }
      notifyListeners();
    }
  }
}
