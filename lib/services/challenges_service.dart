import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class Challenge {
  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String? description;
  final String exercise;
  final String unit;       // 'kg' | 'reps' | 'seg' | 'km' | 'kg×reps'
  final bool higherIsBetter;
  final DateTime deadline;
  final DateTime createdAt;
  final int participantsCount;
  final double? myRecord;
  final int? myReps;

  const Challenge({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    this.description,
    required this.exercise,
    required this.unit,
    required this.higherIsBetter,
    required this.deadline,
    required this.createdAt,
    this.participantsCount = 0,
    this.myRecord,
    this.myReps,
  });

  bool get isActive => deadline.isAfter(DateTime.now());
  int  get daysLeft => deadline.difference(DateTime.now()).inDays;
  bool get isWeightReps => unit == 'kg×reps';

  factory Challenge.fromMap(
    Map<String, dynamic> m, {
    double? myRecord,
    int? myReps,
    int participantsCount = 0,
  }) =>
      Challenge(
        id:               m['id'] as String,
        creatorId:        m['creator_id'] as String,
        creatorName:      m['creator_name'] as String,
        title:            m['title'] as String,
        description:      m['description'] as String?,
        exercise:         m['exercise'] as String,
        unit:             m['unit'] as String,
        higherIsBetter:   m['higher_is_better'] as bool? ?? true,
        deadline:         DateTime.parse(m['deadline'] as String),
        createdAt:        DateTime.parse(m['created_at'] as String),
        participantsCount: participantsCount,
        myRecord:         myRecord,
        myReps:           myReps,
      );

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get creatorInitials => _initials(creatorName);
}

class ChallengeRecord {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final double value;
  final int? reps;
  final DateTime createdAt;
  int rank;

  ChallengeRecord({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.value,
    this.reps,
    required this.createdAt,
    this.rank = 0,
  });

  double get volume => value * (reps ?? 1);

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  factory ChallengeRecord.fromMap(Map<String, dynamic> m, {String? avatarUrl}) =>
      ChallengeRecord(
        id:          m['id'] as String,
        challengeId: m['challenge_id'] as String,
        userId:      m['user_id'] as String,
        userName:    m['user_name'] as String,
        avatarUrl:   avatarUrl,
        value:       (m['value'] as num).toDouble(),
        reps:        m['reps'] as int?,
        createdAt:   DateTime.parse(m['created_at'] as String),
      );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class ChallengesService {
  final _db = Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<List<Challenge>> fetchChallenges() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('challenges')
          .select()
          .order('created_at', ascending: false)
          .limit(30);

      if ((rows as List).isEmpty) return [];

      final ids = rows.map((r) => r['id'] as String).toList();

      final allRecords = await _db
          .from('challenge_records')
          .select('challenge_id, user_id, value, reps')
          .inFilter('challenge_id', ids) as List;

      final countMap   = <String, int>{};
      final myMap      = <String, double>{};
      final myRepsMap  = <String, int>{};
      for (final r in allRecords) {
        final cid = r['challenge_id'] as String;
        countMap[cid] = (countMap[cid] ?? 0) + 1;
        if (r['user_id'] == uid) {
          myMap[cid]     = (r['value'] as num).toDouble();
          myRepsMap[cid] = r['reps'] as int? ?? 0;
        }
      }

      return [
        for (final m in rows)
          Challenge.fromMap(
            m as Map<String, dynamic>,
            participantsCount: countMap[m['id']] ?? 0,
            myRecord: myMap[m['id'] as String],
            myReps:  myRepsMap[m['id'] as String],
          ),
      ];
    } catch (_) {
      return [];
    }
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
    final uid = _uid;
    if (uid == null) return 'No hay sesión activa.';
    try {
      await _db.from('challenges').insert({
        'creator_id':       uid,
        'creator_name':     creatorName.trim(),
        'title':            title.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description':    description.trim(),
        'exercise':         exercise.trim(),
        'unit':             unit,
        'higher_is_better': unit == 'kg×reps' ? true : higherIsBetter,
        'deadline':         deadline.toIso8601String().substring(0, 10),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertRecord({
    required String challengeId,
    required String userName,
    required double value,
    int? reps,
  }) async {
    final uid = _uid;
    if (uid == null) return 'No hay sesión activa.';
    try {
      await _db.from('challenge_records').upsert({
        'challenge_id': challengeId,
        'user_id':      uid,
        'user_name':    userName.trim(),
        'value':        value,
        if (reps != null) 'reps': reps,
      }, onConflict: 'challenge_id,user_id');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<ChallengeRecord>> fetchLeaderboard(
    String challengeId, {
    required bool higherIsBetter,
    required String unit,
  }) async {
    try {
      final rows = await _db
          .from('challenge_records')
          .select()
          .eq('challenge_id', challengeId) as List;

      if (rows.isEmpty) return [];

      // Sort client-side so kg×reps can use volume (kg × reps).
      rows.sort((a, b) {
        if (unit == 'kg×reps') {
          final va = (a['value'] as num).toDouble() * ((a['reps'] as int?) ?? 1);
          final vb = (b['value'] as num).toDouble() * ((b['reps'] as int?) ?? 1);
          return vb.compareTo(va);
        }
        final va = (a['value'] as num).toDouble();
        final vb = (b['value'] as num).toDouble();
        return higherIsBetter ? vb.compareTo(va) : va.compareTo(vb);
      });

      final userIds = rows.map((r) => r['user_id'] as String).toSet();
      final avatars = await _avatarMap(userIds);

      return rows.asMap().entries.map((e) {
        final rec = ChallengeRecord.fromMap(
          e.value as Map<String, dynamic>,
          avatarUrl: avatars[e.value['user_id'] as String],
        );
        rec.rank = e.key + 1;
        return rec;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteChallenge(String challengeId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db.from('challenges').delete()
          .eq('id', challengeId)
          .eq('creator_id', uid);
      return true;
    } catch (_) {
      return false;
    }
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
}
