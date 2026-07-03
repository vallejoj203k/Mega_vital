import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Models ────────────────────────────────────────────────────────

class ClassSchedule {
  final String id;
  final String activity; // 'spinning' | 'running'
  final String name;
  final String scheduleType; // 'daily' | 'weekly' | 'monthly' | 'custom'
  final List<int> daysOfWeek; // 1=Mon..7=Sun (Dart weekday convention)
  final int? dayOfMonth;
  final TimeOfDay timeOfDay;
  final int durationMinutes;
  final int capacity;
  final bool active;

  const ClassSchedule({
    required this.id,
    required this.activity,
    required this.name,
    required this.scheduleType,
    required this.daysOfWeek,
    this.dayOfMonth,
    required this.timeOfDay,
    required this.durationMinutes,
    required this.capacity,
    required this.active,
  });

  factory ClassSchedule.fromMap(Map<String, dynamic> m) {
    final timeParts = (m['time_of_day'] as String).split(':');
    return ClassSchedule(
      id:              m['id'] as String,
      activity:        m['activity'] as String,
      name:            m['name'] as String,
      scheduleType:    m['schedule_type'] as String,
      daysOfWeek:      (m['days_of_week'] as List<dynamic>?)
                           ?.map((e) => e as int).toList() ?? [],
      dayOfMonth:      m['day_of_month'] as int?,
      timeOfDay:       TimeOfDay(
                         hour:   int.parse(timeParts[0]),
                         minute: int.parse(timeParts[1]),
                       ),
      durationMinutes: m['duration_minutes'] as int? ?? 60,
      capacity:        m['capacity'] as int? ?? 18,
      active:          m['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'activity':         activity,
    'name':             name,
    'schedule_type':    scheduleType,
    'days_of_week':     daysOfWeek,
    if (dayOfMonth != null) 'day_of_month': dayOfMonth,
    'time_of_day':      '${timeOfDay.hour.toString().padLeft(2,'0')}:${timeOfDay.minute.toString().padLeft(2,'0')}:00',
    'duration_minutes': durationMinutes,
    'capacity':         capacity,
    'active':           active,
  };

  // Returns upcoming dates (up to [lookAheadDays] from today) when this schedule fires
  List<DateTime> upcomingDates({int lookAheadDays = 14}) {
    final result = <DateTime>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (scheduleType) {
      case 'daily':
        for (int i = 0; i < lookAheadDays; i++) {
          result.add(today.add(Duration(days: i)));
        }
        break;
      case 'weekly':
      case 'custom':
        for (int i = 0; i < lookAheadDays; i++) {
          final date = today.add(Duration(days: i));
          if (daysOfWeek.contains(date.weekday)) result.add(date);
        }
        break;
      case 'monthly':
        final dom = dayOfMonth ?? 1;
        var cur = DateTime(today.year, today.month, 1);
        while (result.length < 3) {
          final candidate = DateTime(cur.year, cur.month, dom);
          if (!candidate.isBefore(today)) result.add(candidate);
          cur = DateTime(cur.year, cur.month + 1, 1);
        }
        break;
    }
    return result;
  }
}

class ClassSession {
  final String id;
  final String scheduleId;
  final String scheduleName;
  final String activity;
  final DateTime sessionDate;
  final DateTime startsAt;
  final int capacity;
  final int bookedCount;
  final String status;
  final bool isBookedByMe;

  const ClassSession({
    required this.id,
    required this.scheduleId,
    required this.scheduleName,
    required this.activity,
    required this.sessionDate,
    required this.startsAt,
    required this.capacity,
    required this.bookedCount,
    required this.status,
    required this.isBookedByMe,
  });

  int get availableSpots => capacity - bookedCount;
  bool get isFull => status == 'full' || bookedCount >= capacity;
  bool get isCompleted => status == 'completed';
  bool get isOpen => status == 'open';

  factory ClassSession.fromMap(Map<String, dynamic> m, String myUserId) {
    final bookings = (m['class_bookings'] as List<dynamic>?) ?? [];
    return ClassSession(
      id:           m['id'] as String,
      scheduleId:   m['schedule_id'] as String,
      scheduleName: (m['class_schedules'] as Map?)?['name'] as String? ?? '',
      activity:     (m['class_schedules'] as Map?)?['activity'] as String? ?? '',
      sessionDate:  DateTime.parse(m['session_date'] as String),
      startsAt:     DateTime.parse(m['starts_at'] as String).toLocal(),
      capacity:     m['capacity'] as int,
      bookedCount:  m['booked_count'] as int,
      status:       m['status'] as String,
      isBookedByMe: bookings.any((b) => (b as Map)['user_id'] == myUserId),
    );
  }
}

// ── Service ───────────────────────────────────────────────────────

class ClassScheduleService {
  final _db = Supabase.instance.client;

  String get _uid => _db.auth.currentUser?.id ?? '';

  // ── Schedules (admin) ─────────────────────────────────────────

  Future<List<ClassSchedule>> fetchSchedules() async {
    try {
      final data = await _db
          .from('class_schedules')
          .select()
          .eq('active', true)
          .order('activity')
          .order('time_of_day');
      return (data as List).map((m) => ClassSchedule.fromMap(m)).toList();
    } catch (_) { return []; }
  }

  Future<bool> createSchedule(ClassSchedule s) async {
    try {
      await _db.from('class_schedules').insert(s.toInsertMap());
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateSchedule(ClassSchedule s) async {
    try {
      await _db.from('class_schedules')
          .update(s.toInsertMap()).eq('id', s.id);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      await _db.from('class_schedules').update({'active': false}).eq('id', id);
      return true;
    } catch (_) { return false; }
  }

  // ── Sessions ──────────────────────────────────────────────────

  Future<void> ensureSessions(String scheduleId, List<DateTime> dates) async {
    if (dates.isEmpty) return;
    try {
      final isoDateList = dates
          .map((d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}')
          .toList();
      await _db.rpc('ensure_class_sessions', params: {
        'p_schedule_id': scheduleId,
        'p_dates': isoDateList,
      });
    } catch (_) {}
  }

  Future<void> completeExpiredSessions() async {
    try {
      await _db.rpc('complete_expired_sessions');
    } catch (_) {}
  }

  Future<List<ClassSession>> fetchSessions({
    required String activity,
    int lookAheadDays = 14,
  }) async {
    try {
      final now   = DateTime.now();
      final from  = DateTime(now.year, now.month, now.day);
      final until = from.add(Duration(days: lookAheadDays));
      final fromStr  = '${from.year}-${from.month.toString().padLeft(2,'0')}-${from.day.toString().padLeft(2,'0')}';
      final untilStr = '${until.year}-${until.month.toString().padLeft(2,'0')}-${until.day.toString().padLeft(2,'0')}';

      final data = await _db
          .from('class_sessions')
          .select('''
            *,
            class_schedules!inner(name, activity),
            class_bookings(user_id)
          ''')
          .eq('class_schedules.activity', activity)
          .neq('status', 'completed')
          .neq('status', 'cancelled')
          .gte('session_date', fromStr)
          .lte('session_date', untilStr)
          .order('starts_at');

      return (data as List)
          .map((m) => ClassSession.fromMap(m, _uid))
          .toList();
    } catch (_) { return []; }
  }

  // ── Bookings ──────────────────────────────────────────────────

  Future<String> bookSession(String sessionId, String userName) async {
    try {
      final result = await _db.rpc('book_class_session', params: {
        'p_session_id': sessionId,
        'p_user_name':  userName,
      });
      return result as String? ?? 'error';
    } catch (_) { return 'error'; }
  }

  Future<bool> cancelBooking(String sessionId) async {
    try {
      final result = await _db.rpc('cancel_class_booking', params: {
        'p_session_id': sessionId,
      });
      return result as bool? ?? false;
    } catch (_) { return false; }
  }

  // ── Créditos de clases (pago en recepción) ────────────────────

  Future<int> fetchMyCredits() async {
    try {
      final row = await _db
          .from('user_profiles')
          .select('class_credits')
          .eq('uid', _uid)
          .maybeSingle();
      return (row?['class_credits'] as int?) ?? 0;
    } catch (_) { return 0; }
  }

  // delta puede ser positivo (cargar) o negativo (quitar). delta=0 solo consulta.
  Future<int?> adminAdjustCredits(String uid, int delta) async {
    try {
      final result = await _db.rpc('admin_adjust_class_credits', params: {
        'p_uid':   uid,
        'p_delta': delta,
      });
      return result as int?;
    } catch (_) { return null; }
  }
}
