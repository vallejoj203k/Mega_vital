import 'package:flutter/material.dart';
import '../../services/class_schedule_service.dart';

class ClassProvider extends ChangeNotifier {
  final _service = ClassScheduleService();

  List<ClassSchedule> _schedules = [];
  List<ClassSession>  _spinningSessions = [];
  List<ClassSession>  _runningSessions  = [];
  bool _loading = false;
  int  _myCredits = 0;

  List<ClassSchedule> get schedules        => _schedules;
  List<ClassSession>  get spinningSessions => _spinningSessions;
  List<ClassSession>  get runningSessions  => _runningSessions;
  bool                get loading          => _loading;
  int                 get myCredits        => _myCredits;

  Future<void> init() async {
    await _service.completeExpiredSessions();
    await loadSchedules();
  }

  Future<void> loadSchedules() async {
    _schedules = await _service.fetchSchedules();
    notifyListeners();
  }

  Future<void> loadSessions(String activity) async {
    _loading = true;
    notifyListeners();

    // Always reload schedules first to ensure they're fresh
    _schedules = await _service.fetchSchedules();

    // Genera las sesiones del próximo mes (se renueva conforme avanza el tiempo)
    final relevant = _schedules.where((s) => s.activity == activity && s.active);
    for (final sched in relevant) {
      final dates = sched.upcomingDates(lookAheadDays: 31);
      if (dates.isNotEmpty) await _service.ensureSessions(sched.id, dates);
    }

    final sessions =
        await _service.fetchSessions(activity: activity, lookAheadDays: 31);
    if (activity == 'spinning') {
      _spinningSessions = sessions;
    } else {
      _runningSessions = sessions;
    }
    _myCredits = await _service.fetchMyCredits();
    _loading = false;
    notifyListeners();
  }

  Future<String> bookSession(String sessionId, String userName,
      {int? seatIndex}) async {
    final result =
        await _service.bookSession(sessionId, userName, seatIndex: seatIndex);
    if (result == 'ok') {
      await _refreshBoth();
    }
    return result;
  }

  Future<bool> cancelBooking(String sessionId) async {
    final ok = await _service.cancelBooking(sessionId);
    if (ok) await _refreshBoth();
    return ok;
  }

  Future<void> _refreshBoth() async {
    final sp = await _service.fetchSessions(activity: 'spinning');
    final ru = await _service.fetchSessions(activity: 'running');
    _spinningSessions = sp;
    _runningSessions  = ru;
    _myCredits = await _service.fetchMyCredits();
    notifyListeners();
  }

  // Admin: ajustar créditos de un usuario (retorna nuevo saldo o null si falla)
  Future<int?> adminAdjustCredits(String uid, int delta) =>
      _service.adminAdjustCredits(uid, delta);

  // Admin
  Future<bool> createSchedule(ClassSchedule s) async {
    final ok = await _service.createSchedule(s);
    if (ok) await loadSchedules();
    return ok;
  }

  Future<bool> updateSchedule(ClassSchedule s) async {
    final ok = await _service.updateSchedule(s);
    if (ok) await loadSchedules();
    return ok;
  }

  Future<bool> deleteSchedule(String id) async {
    final ok = await _service.deleteSchedule(id);
    if (ok) await loadSchedules();
    return ok;
  }
}
