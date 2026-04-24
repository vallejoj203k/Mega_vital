import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;
String? get _uid => _db.auth.currentUser?.id;

// ── Models ──────────────────────────────────────────────

class SpinInstructor {
  final String id;
  final String name;
  final String specialty;
  final String bio;
  final double rating;
  final int totalClasses;
  final String colorHex;

  const SpinInstructor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.rating,
    required this.totalClasses,
    required this.colorHex,
  });

  factory SpinInstructor.fromRow(Map<String, dynamic> r) => SpinInstructor(
        id: r['id'] as String,
        name: r['name'] as String,
        specialty: r['specialty'] as String,
        bio: r['bio'] as String? ?? '',
        rating: (r['rating'] as num).toDouble(),
        totalClasses: r['total_classes'] as int,
        colorHex: r['color_hex'] as String,
      );
}

enum SpinLevel { basico, intermedio, avanzado }

extension SpinLevelX on SpinLevel {
  String get label {
    switch (this) {
      case SpinLevel.basico:
        return 'Básico';
      case SpinLevel.intermedio:
        return 'Intermedio';
      case SpinLevel.avanzado:
        return 'Avanzado';
    }
  }

  static SpinLevel fromString(String s) {
    switch (s) {
      case 'intermedio':
        return SpinLevel.intermedio;
      case 'avanzado':
        return SpinLevel.avanzado;
      default:
        return SpinLevel.basico;
    }
  }
}

class SpinClass {
  final String id;
  final String name;
  final String description;
  final SpinInstructor instructor;
  final SpinLevel level;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final List<String> days;
  final int caloriesMin;
  final int caloriesMax;
  final int totalSpots;

  const SpinClass({
    required this.id,
    required this.name,
    required this.description,
    required this.instructor,
    required this.level,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.days,
    required this.caloriesMin,
    required this.caloriesMax,
    required this.totalSpots,
  });

  factory SpinClass.fromRow(
      Map<String, dynamic> r, SpinInstructor instructor) =>
      SpinClass(
        id: r['id'] as String,
        name: r['name'] as String,
        description: r['description'] as String? ?? '',
        instructor: instructor,
        level: SpinLevelX.fromString(r['level'] as String),
        startTime: (r['start_time'] as String).substring(0, 5),
        endTime: (r['end_time'] as String).substring(0, 5),
        durationMinutes: r['duration_minutes'] as int,
        days: List<String>.from(r['days'] as List),
        caloriesMin: r['calories_min'] as int,
        caloriesMax: r['calories_max'] as int,
        totalSpots: r['total_spots'] as int,
      );

  bool get isTodayActive {
    const map = {
      1: 'mon',
      2: 'tue',
      3: 'wed',
      4: 'thu',
      5: 'fri',
      6: 'sat',
      7: 'sun'
    };
    return days.contains(map[DateTime.now().weekday]);
  }

  /// Fecha de la próxima sesión disponible para reservar.
  /// Si la clase aún no ha terminado hoy → hoy.
  /// Si ya terminó → siguiente día hábil (Lun–Vie).
  DateTime get nextSessionDate {
    final now = DateTime.now();
    final parts = endTime.split(':');
    final endH = int.parse(parts[0]);
    final endM = int.parse(parts[1]);
    final classEndToday =
        DateTime(now.year, now.month, now.day, endH, endM);

    DateTime candidate = now.isBefore(classEndToday)
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day + 1);

    // Avanzar si cae en fin de semana o si la clase no ocurre ese día
    const dayMap = {1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat', 7: 'sun'};
    int safety = 0;
    while (!days.contains(dayMap[candidate.weekday]) && safety < 7) {
      candidate = candidate.add(const Duration(days: 1));
      safety++;
    }
    return candidate;
  }

  String get nextSessionLabel {
    final d = nextSessionDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (d == today) return 'Hoy';
    if (d == tomorrow) return 'Mañana';
    const names = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${names[d.weekday]} ${d.day}/${d.month}';
  }
}

class SpinSession {
  final String id;
  final String classId;
  final DateTime sessionDate;
  final bool isCancelled;

  const SpinSession({
    required this.id,
    required this.classId,
    required this.sessionDate,
    required this.isCancelled,
  });

  factory SpinSession.fromRow(Map<String, dynamic> r) => SpinSession(
        id: r['id'] as String,
        classId: r['class_id'] as String,
        sessionDate: DateTime.parse(r['session_date'] as String),
        isCancelled: r['is_cancelled'] as bool,
      );
}

class UserBooking {
  final String id;
  final String sessionId;
  final String userId;
  final int seatNumber;
  final bool isCancelled;
  final DateTime bookedAt;
  SpinClass? spinClass;
  DateTime? sessionDate;

  UserBooking({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.seatNumber,
    required this.isCancelled,
    required this.bookedAt,
    this.spinClass,
    this.sessionDate,
  });

  factory UserBooking.fromRow(Map<String, dynamic> r) => UserBooking(
        id: r['id'] as String,
        sessionId: r['session_id'] as String,
        userId: r['user_id'] as String,
        seatNumber: r['seat_number'] as int,
        isCancelled: r['is_cancelled'] as bool,
        bookedAt: DateTime.parse(r['booked_at'] as String),
      );

  String get seatLabel {
    final row = String.fromCharCode('A'.codeUnitAt(0) + seatNumber ~/ 6);
    final col = seatNumber % 6 + 1;
    return '$row$col';
  }
}

// ── Service ──────────────────────────────────────────────

class SpinningService {
  Future<List<SpinInstructor>> loadInstructors() async {
    try {
      final rows = await _db
          .from('spinning_instructors')
          .select()
          .eq('is_active', true)
          .order('name') as List;
      return rows
          .map((r) => SpinInstructor.fromRow(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SpinClass>> loadClasses() async {
    try {
      final instructorRows = await _db
          .from('spinning_instructors')
          .select()
          .eq('is_active', true) as List;
      final instructors = {
        for (final r in instructorRows)
          (r as Map<String, dynamic>)['id'] as String:
              SpinInstructor.fromRow(r)
      };

      final classRows = await _db
          .from('spinning_classes')
          .select()
          .eq('is_active', true)
          .order('start_time') as List;

      return classRows
          .map((r) {
            final row = r as Map<String, dynamic>;
            final inst = instructors[row['instructor_id'] as String];
            if (inst == null) return null;
            return SpinClass.fromRow(row, inst);
          })
          .whereType<SpinClass>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> getOrCreateSession(String classId, DateTime date) async {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final existing = await _db
          .from('spinning_sessions')
          .select('id')
          .eq('class_id', classId)
          .eq('session_date', dateKey)
          .maybeSingle();
      if (existing != null) return existing['id'] as String;

      final inserted = await _db
          .from('spinning_sessions')
          .insert({'class_id': classId, 'session_date': dateKey})
          .select('id')
          .single();
      return inserted['id'] as String;
    } catch (_) {
      rethrow;
    }
  }

  Future<Set<int>> getBookedSeats(String sessionId) async {
    try {
      final rows = await _db
          .from('spinning_bookings')
          .select('seat_number')
          .eq('session_id', sessionId)
          .eq('is_cancelled', false) as List;
      return rows
          .map((r) => (r as Map<String, dynamic>)['seat_number'] as int)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> hasUserBooked(String sessionId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final row = await _db
          .from('spinning_bookings')
          .select('id')
          .eq('session_id', sessionId)
          .eq('user_id', uid)
          .eq('is_cancelled', false)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> bookSeat(String sessionId, int seatNumber) async {
    final uid = _uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    await _db.from('spinning_bookings').insert({
      'session_id': sessionId,
      'user_id': uid,
      'seat_number': seatNumber,
    });
  }

  Future<List<UserBooking>> getUserBookings() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('spinning_bookings')
          .select('*, spinning_sessions(session_date, class_id)')
          .eq('user_id', uid)
          .eq('is_cancelled', false)
          .order('booked_at', ascending: false) as List;
      return rows
          .map((r) => UserBooking.fromRow(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await _db
        .from('spinning_bookings')
        .update({'is_cancelled': true}).eq('id', bookingId);
  }

  Future<List<SessionParticipant>> getParticipants(String sessionId) async {
    try {
      final rows = await _db
          .from('spinning_bookings')
          .select('seat_number, user_id')
          .eq('session_id', sessionId)
          .eq('is_cancelled', false) as List;

      final participants = <SessionParticipant>[];
      for (final r in rows) {
        final row = r as Map<String, dynamic>;
        final userId = row['user_id'] as String;
        String displayName = 'Usuario';
        String? avatarUrl;
        try {
          final profile = await _db
              .from('user_profiles')
              .select('display_name, avatar_url')
              .eq('uid', userId)
              .maybeSingle();
          if (profile != null) {
            displayName = profile['display_name'] as String? ?? 'Usuario';
            avatarUrl = profile['avatar_url'] as String?;
          }
        } catch (_) {}
        participants.add(SessionParticipant(
          userId: userId,
          seatNumber: row['seat_number'] as int,
          displayName: displayName,
          avatarUrl: avatarUrl,
        ));
      }
      return participants;
    } catch (_) {
      return [];
    }
  }
}

class SessionParticipant {
  final String userId;
  final int seatNumber;
  final String displayName;
  final String? avatarUrl;

  const SessionParticipant({
    required this.userId,
    required this.seatNumber,
    required this.displayName,
    this.avatarUrl,
  });

  String get seatLabel {
    final row = String.fromCharCode('A'.codeUnitAt(0) + seatNumber ~/ 6);
    final col = seatNumber % 6 + 1;
    return '$row$col';
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
