import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/stories_service.dart';

export '../../services/stories_service.dart' show StoryModel, UserStoriesGroup, StoryViewer;

class StoriesProvider extends ChangeNotifier {
  final StoriesService _svc;

  List<UserStoriesGroup> _groups = [];
  bool _loading = false;

  StoriesProvider({StoriesService? service})
      : _svc = service ?? StoriesService();

  List<UserStoriesGroup> get groups  => _groups;
  bool                   get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _groups = await _svc.fetchActive();
    _loading = false;
    notifyListeners();
  }

  Future<bool> addStory({
    required String userId,
    required String userName,
    String? content,
    File? imageFile,
  }) async {
    final ok = await _svc.add(
      userId:    userId,
      userName:  userName,
      content:   content,
      imageFile: imageFile,
    );
    if (ok) await load();
    return ok;
  }

  Future<void> markViewed(String storyId) async {
    await _svc.markViewed(storyId);
    _groups = _groups.map((g) => UserStoriesGroup(
      userId: g.userId,
      userName: g.userName,
      stories: g.stories.map((s) => s.id == storyId
          ? StoryModel(
              id: s.id, userId: s.userId, userName: s.userName,
              content: s.content, imageUrl: s.imageUrl,
              createdAt: s.createdAt, expiresAt: s.expiresAt,
              viewedByMe: true,
            )
          : s).toList(),
    )).toList();
    notifyListeners();
  }

  Future<bool> deleteStory(String storyId) async {
    final ok = await _svc.delete(storyId);
    if (ok) await load();
    return ok;
  }

  Future<List<StoryViewer>> fetchStoryViewers(String storyId) =>
      _svc.fetchViewers(storyId);
}
