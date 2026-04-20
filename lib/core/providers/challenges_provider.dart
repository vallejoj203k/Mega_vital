import 'package:flutter/material.dart';
import '../../services/challenges_service.dart';

class ChallengesProvider extends ChangeNotifier {
  final _service = ChallengesService();

  List<Challenge> _challenges = [];
  bool _loading = false;
  bool _initialized = false;

  List<Challenge> get challenges => _challenges;
  bool get loading => _loading;
  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    await load();
    _initialized = true;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _challenges = await _service.fetchChallenges();
    _loading = false;
    notifyListeners();
  }

  Future<String?> createChallenge({
    required String creatorName,
    required String title,
    String? description,
    required String exercise,
    required String unit,
    required bool higherIsBetter,
    required DateTime deadline,
  }) async {
    final err = await _service.createChallenge(
      creatorName:    creatorName,
      title:          title,
      description:    description,
      exercise:       exercise,
      unit:           unit,
      higherIsBetter: higherIsBetter,
      deadline:       deadline,
    );
    if (err == null) await load();
    return err;
  }

  Future<String?> upsertRecord({
    required String challengeId,
    required String userName,
    required double value,
    int? reps,
  }) async {
    final err = await _service.upsertRecord(
      challengeId: challengeId,
      userName:    userName,
      value:       value,
      reps:        reps,
    );
    if (err == null) await load();
    return err;
  }

  Future<List<ChallengeRecord>> fetchLeaderboard(
    String challengeId, {
    required bool higherIsBetter,
    required String unit,
  }) =>
      _service.fetchLeaderboard(
        challengeId,
        higherIsBetter: higherIsBetter,
        unit:           unit,
      );

  Future<bool> deleteChallenge(String challengeId) async {
    final ok = await _service.deleteChallenge(challengeId);
    if (ok) {
      _challenges.removeWhere((c) => c.id == challengeId);
      notifyListeners();
    }
    return ok;
  }
}
