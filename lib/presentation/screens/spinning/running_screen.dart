import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_colors.dart';
import '../../../services/class_schedule_service.dart';
import 'class_sessions_screen.dart';
import 'treadmill_selection_screen.dart';

// ── Models ─────────────────────────────────────────────

enum RunLevel { basico, intermedio, avanzado }

class RunInstructor {
  final String id;
  final String name;
  final String specialty;
  final String bio;
  final String photoAsset;
  final double rating;
  final int totalClasses;
  final Color color;

  const RunInstructor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.photoAsset,
    required this.rating,
    required this.totalClasses,
    required this.color,
  });
}

class RunClass {
  final String id;
  final String name;
  final String description;
  final List<String> features;
  final RunInstructor instructor;
  final RunLevel level;
  final String time;
  final String days;
  final int durationMinutes;
  final int caloriesMin;
  final int caloriesMax;
  final int totalSpots;
  int bookedSpots;
  Set<int> reservedSeats;

  RunClass({
    required this.id,
    required this.name,
    required this.description,
    required this.features,
    required this.instructor,
    required this.level,
    required this.time,
    required this.days,
    required this.durationMinutes,
    required this.caloriesMin,
    required this.caloriesMax,
    required this.totalSpots,
    required this.bookedSpots,
    Set<int>? reservedSeats,
  }) : reservedSeats = reservedSeats ?? {};

  int get availableSpots => totalSpots - bookedSpots;
}

// ── Static Data ────────────────────────────────────────

final _runInstructors = [
  const RunInstructor(
    id: 'ri1',
    name: 'Sofía',
    specialty: 'Cardio & Resistencia',
    bio: 'Entrenadora certificada con especialización en cardio progresivo y planes de resistencia. Más de 4 años guiando a atletas a mejorar su capacidad aeróbica con metodologías de interval training y carrera progresiva. Su enfoque combina técnica de carrera, postura y respiración para maximizar resultados.',
    photoAsset: 'assets/images/instructors/sofia.png',
    rating: 4.8,
    totalClasses: 210,
    color: Color(0xFF4FC3F7),
  ),
  const RunInstructor(
    id: 'ri2',
    name: 'Marcos',
    specialty: 'HIIT & Interval Running',
    bio: 'Especialista en entrenamiento de intervalos de alta intensidad aplicado a carrera. Combina sprints explosivos con recuperación activa para obtener el máximo rendimiento cardiovascular. Entrenador con certificación internacional y amplia experiencia en preparación física para atletas de todos los niveles.',
    photoAsset: 'assets/images/instructors/marcos.png',
    rating: 4.7,
    totalClasses: 175,
    color: Color(0xFF7C4DFF),
  ),
];

// Helpers para convertir ClassSchedule → RunClass
const _kRunDayNames = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

String _runFmtTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}

String _runFmtDays(ClassSchedule s) {
  if (s.scheduleType == 'daily') return 'Todos los días';
  if (s.scheduleType == 'monthly') return 'Día ${s.dayOfMonth} de cada mes';
  if (s.daysOfWeek.isEmpty) return '';
  return s.daysOfWeek.map((d) => _kRunDayNames[d]).join(' · ');
}

RunClass _scheduleToRunClass(ClassSchedule s) => RunClass(
  id: s.id,
  name: s.name,
  description: 'Sesión de ${s.durationMinutes} min · ${_runFmtDays(s)}',
  features: ['NordicTrack X32i', 'Monitor cardíaco'],
  instructor: _runInstructors[0],
  level: RunLevel.intermedio,
  time: _runFmtTime(s.timeOfDay),
  days: _runFmtDays(s),
  durationMinutes: s.durationMinutes,
  caloriesMin: 300,
  caloriesMax: 550,
  totalSpots: s.capacity,
  bookedSpots: 0,
);

// ── Main Screen ────────────────────────────────────────

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;

  late TabController _tabController;
  late List<RunClass> _classes;
  final Map<String, int> _myBookings = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _classes = [];
    _loadSchedules();
    _subscribeRealtime();
  }

  Future<void> _loadSchedules() async {
    try {
      final all = await ClassScheduleService().fetchSchedules();
      if (!mounted) return;
      setState(() {
        _classes = all
            .where((s) => s.activity == 'running')
            .map(_scheduleToRunClass)
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  RunClass? _classById(String id) {
    for (final c in _classes) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _loadBookings() async {
    // Reset to avoid accumulating stale state on re-loads
    for (final cls in _classes) {
      cls.bookedSpots = 0;
      cls.reservedSeats.clear();
    }
    _myBookings.clear();

    try {
      final rows = await _supabase
          .from('running_bookings')
          .select('class_id, treadmill_index, user_id');
      if (!mounted) return;
      final myId = _supabase.auth.currentUser?.id;
      setState(() {
        for (final row in rows) {
          final classId = row['class_id'] as String;
          final treadmillIndex = row['treadmill_index'] as int;
          final userId = row['user_id'] as String;
          final cls = _classById(classId);
          if (cls != null && cls.reservedSeats.add(treadmillIndex)) {
            cls.bookedSpots++;
          }
          if (myId != null && userId == myId) {
            _myBookings[classId] = treadmillIndex;
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _realtimeChannel = _supabase
        .channel('running_bookings_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'running_bookings',
          callback: (payload) {
            if (!mounted) return;
            final classId = payload.newRecord['class_id'] as String?;
            final treadmillIndex = payload.newRecord['treadmill_index'] as int?;
            final userId = payload.newRecord['user_id'] as String?;
            if (classId == null || treadmillIndex == null) return;
            setState(() {
              final cls = _classById(classId);
              if (cls != null && cls.reservedSeats.add(treadmillIndex)) {
                cls.bookedSpots++;
              }
              final myId = _supabase.auth.currentUser?.id;
              if (myId != null && userId == myId) {
                _myBookings[classId] = treadmillIndex;
              }
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'running_bookings',
          callback: (payload) {
            if (!mounted) return;
            final classId = payload.oldRecord['class_id'] as String?;
            final treadmillIndex = payload.oldRecord['treadmill_index'] as int?;
            final userId = payload.oldRecord['user_id'] as String?;
            if (classId == null || treadmillIndex == null) return;
            setState(() {
              final cls = _classById(classId);
              if (cls != null && cls.reservedSeats.remove(treadmillIndex)) {
                cls.bookedSpots--;
              }
              final myId = _supabase.auth.currentUser?.id;
              if (myId != null && userId == myId) {
                _myBookings.remove(classId);
              }
            });
          },
        )
        .subscribe();
  }

  Color _levelColor(RunLevel l) {
    switch (l) {
      case RunLevel.basico:      return AppColors.primary;
      case RunLevel.intermedio:  return AppColors.accentBlue;
      case RunLevel.avanzado:    return AppColors.accentPurple;
    }
  }

  String _levelLabel(RunLevel l) {
    switch (l) {
      case RunLevel.basico:      return 'Iniciación';
      case RunLevel.intermedio:  return 'Intermedio';
      case RunLevel.avanzado:    return 'Alto Rendimiento';
    }
  }

  String _treadmillLabel(int index) {
    const cols = 2;
    final row = index ~/ cols;
    final col = index % cols;
    return '${String.fromCharCode('A'.codeUnitAt(0) + row)}${col + 1}';
  }

  void _openTreadmillSelection(RunClass cls, {int? oldSpot}) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => TreadmillSelectionScreen(runClass: cls, currentSpot: oldSpot),
      ),
    );

    if (!mounted || result == null || result == oldSpot) return;

    setState(() {
      if (oldSpot != null && cls.reservedSeats.remove(oldSpot)) cls.bookedSpots--;
      if (cls.reservedSeats.add(result)) cls.bookedSpots++;
      _myBookings[cls.id] = result;
    });

    HapticFeedback.mediumImpact();
    final label = _treadmillLabel(result);
    final isChange = oldSpot != null;
    _showSnackBar(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primary,
      text: isChange
          ? 'Cambiaste a la trotadora $label en ${cls.name}'
          : 'Trotadora $label reservada en ${cls.name}',
    );

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      if (oldSpot != null) {
        await _supabase.from('running_bookings').delete()
            .eq('user_id', userId).eq('class_id', cls.id);
      }
      await _supabase.from('running_bookings').insert({
        'user_id': userId,
        'class_id': cls.id,
        'treadmill_index': result,
      });
      await _loadBookings();
    } catch (e) {
      debugPrint('running_bookings insert error: $e');
      if (!mounted) return;
      setState(() {
        if (cls.reservedSeats.remove(result)) cls.bookedSpots--;
        if (oldSpot != null && cls.reservedSeats.add(oldSpot)) {
          cls.bookedSpots++;
          _myBookings[cls.id] = oldSpot;
        } else {
          _myBookings.remove(cls.id);
        }
      });
      _showSnackBar(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        text: 'Error: $e',
      );
    }
  }

  void _cancelBooking(RunClass cls) async {
    final tc = AppThemeColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Cancelar reserva',
            style: TextStyle(color: tc.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          '¿Seguro que quieres cancelar tu trotadora en ${cls.name}?',
          style: TextStyle(color: tc.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: TextStyle(color: tc.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final spot = _myBookings[cls.id];
    setState(() {
      if (spot != null && cls.reservedSeats.remove(spot)) cls.bookedSpots--;
      _myBookings.remove(cls.id);
    });

    HapticFeedback.mediumImpact();
    _showSnackBar(
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.textSecondary,
      text: 'Reserva cancelada en ${cls.name}',
    );

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('running_bookings').delete()
          .eq('user_id', userId).eq('class_id', cls.id);
      await _loadBookings();
    } catch (_) {
      if (!mounted || spot == null) return;
      setState(() {
        if (cls.reservedSeats.add(spot)) cls.bookedSpots++;
        _myBookings[cls.id] = spot;
      });
      _showSnackBar(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        text: 'Error al cancelar la reserva. Inténtalo de nuevo.',
      );
    }
  }

  void _showSnackBar(
      {required IconData icon, required Color iconColor, required String text}) {
    if (!mounted) return;
    final tc = AppThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: tc.textPrimary))),
        ]),
        backgroundColor: tc.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tc = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(tc),
            _buildTabBar(tc),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentBlue, strokeWidth: 2.5))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _RunScheduleTab(
                          classes: _classes,
                          myBookings: _myBookings,
                          levelColor: _levelColor,
                          levelLabel: _levelLabel,
                          onBook: _openTreadmillSelection,
                          onChangeSeat: (cls, oldSpot) =>
                              _openTreadmillSelection(cls, oldSpot: oldSpot),
                          onCancel: _cancelBooking,
                        ),
                        _RunMyBookingsTab(
                          classes: _classes,
                          myBookings: _myBookings,
                          levelColor: _levelColor,
                          levelLabel: _levelLabel,
                          spotLabel: _treadmillLabel,
                          onChangeSeat: (cls, oldSpot) =>
                              _openTreadmillSelection(cls, oldSpot: oldSpot),
                          onCancel: _cancelBooking,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors tc) {
    final availableClasses = _classes.where((c) => c.availableSpots > 0).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentBlue.withOpacity(0.18), tc.background],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: tc.textPrimary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(Icons.directions_run_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Running',
                          style: AppTextStyles.displayMedium
                              .copyWith(color: tc.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accentBlue, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('PRO',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text('Trotadoras profesionales con instructores certificados',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: tc.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentBlue.withOpacity(0.2), width: 0.5),
            ),
            child: Row(children: [
              _CredBadge(
                  icon: Icons.verified_rounded,
                  label: 'Instructores Certificados',
                  color: AppColors.accentBlue),
              const SizedBox(width: 10),
              _CredBadge(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Monitor Cardíaco',
                  color: AppColors.error),
              const SizedBox(width: 10),
              _CredBadge(
                  icon: Icons.directions_run_rounded,
                  label: 'NordicTrack X32i',
                  color: AppColors.accentPurple),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _StatChip(
                icon: Icons.calendar_today_rounded,
                label: '$availableClasses clases disponibles',
                color: AppColors.accentBlue),
            const SizedBox(width: 10),
            _StatChip(
                icon: Icons.local_fire_department_rounded,
                label: '300–650 kcal',
                color: AppColors.accentPurple),
            const SizedBox(width: 10),
            _StatChip(
                icon: Icons.timer_rounded,
                label: '45–60 min',
                color: AppColors.primary),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClassSessionsScreen(
                  activity: 'running',
                  accentColor: Color(0xFF4FC3F7),
                )),
              ),
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: const Text('Ver horarios y reservar cupo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppThemeColors tc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.border, width: 0.5),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentBlue, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: AppColors.accentBlue.withOpacity(0.4), blurRadius: 8)
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: tc.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Horarios'),
          Tab(text: 'Mis Reservas'),
        ],
      ),
    );
  }
}

// ── Cred Badge ─────────────────────────────────────────

class _CredBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CredBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: color),
                  overflow: TextOverflow.ellipsis)),
        ]),
      );
}

// ── Stat Chip ──────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Schedule Tab ───────────────────────────────────────

class _RunScheduleTab extends StatelessWidget {
  final List<RunClass> classes;
  final Map<String, int> myBookings;
  final Color Function(RunLevel) levelColor;
  final String Function(RunLevel) levelLabel;
  final void Function(RunClass) onBook;
  final void Function(RunClass, int) onChangeSeat;
  final void Function(RunClass) onCancel;

  const _RunScheduleTab({
    required this.classes,
    required this.myBookings,
    required this.levelColor,
    required this.levelLabel,
    required this.onBook,
    required this.onChangeSeat,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: classes.length,
      itemBuilder: (context, i) {
        final cls = classes[i];
        final bookedSpot = myBookings[cls.id];
        return _RunClassCard(
          cls: cls,
          isBooked: bookedSpot != null,
          bookedSpot: bookedSpot,
          levelColor: levelColor,
          levelLabel: levelLabel,
          onBook: () => onBook(cls),
          onChangeSeat: bookedSpot != null ? () => onChangeSeat(cls, bookedSpot) : null,
          onCancel: bookedSpot != null ? () => onCancel(cls) : null,
        );
      },
    );
  }
}

// ── Run Class Card ─────────────────────────────────────

class _RunClassCard extends StatelessWidget {
  final RunClass cls;
  final bool isBooked;
  final int? bookedSpot;
  final Color Function(RunLevel) levelColor;
  final String Function(RunLevel) levelLabel;
  final VoidCallback onBook;
  final VoidCallback? onChangeSeat;
  final VoidCallback? onCancel;

  const _RunClassCard({
    required this.cls,
    required this.isBooked,
    this.bookedSpot,
    required this.levelColor,
    required this.levelLabel,
    required this.onBook,
    this.onChangeSeat,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final color = levelColor(cls.level);
    final isFull = cls.availableSpots == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBooked ? color.withOpacity(0.5) : tc.border,
          width: isBooked ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
          if (isBooked)
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 16),
        ],
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Stack(children: [
            _RunHeroImage(level: cls.level, color: color, surface: tc.surface),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, tc.surface.withOpacity(0.95)],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.6), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_levelIcon(cls.level), size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(levelLabel(cls.level),
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                ]),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: isBooked
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: color.withOpacity(0.6), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.directions_run_rounded, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          bookedSpot != null
                              ? 'Trot. ${_spotFromIndex(bookedSpot!)}'
                              : 'Reservado',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                      ]),
                    )
                  : Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.accentBlue.withOpacity(0.5),
                            width: 0.5),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_rounded,
                            size: 11, color: AppColors.accentBlue),
                        SizedBox(width: 4),
                        Text('CERTIFICADA',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentBlue,
                                letterSpacing: 0.8)),
                      ]),
                    ),
            ),
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Text(cls.name,
                  style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cls.description,
                style: TextStyle(
                    fontSize: 13, color: tc.textSecondary, height: 1.45)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cls.features
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accentBlue.withOpacity(0.25),
                              width: 0.5),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 10, color: AppColors.accentBlue),
                          const SizedBox(width: 4),
                          Text(f,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentBlue)),
                        ]),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            Container(height: 0.5, color: tc.border),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _InfoPill(
                  icon: Icons.access_time_rounded,
                  label: cls.time,
                  color: AppColors.accentBlue),
              _InfoPill(
                  icon: Icons.local_fire_department_rounded,
                  label: '${cls.caloriesMin}–${cls.caloriesMax} kcal',
                  color: AppColors.accentOrange),
              _InfoPill(
                  icon: Icons.timer_rounded,
                  label: '${cls.durationMinutes} min',
                  color: AppColors.accentPurple),
              _InfoPill(
                icon: Icons.people_rounded,
                label: isFull
                    ? 'Sin cupos'
                    : '${cls.availableSpots}/${cls.totalSpots} cupos',
                color: isFull
                    ? AppColors.error
                    : cls.availableSpots <= 2
                        ? AppColors.warning
                        : AppColors.primary,
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 15, color: tc.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(cls.days,
                      style: TextStyle(fontSize: 13, color: tc.textSecondary))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  isFull ? 'Lleno' : '${cls.availableSpots} lugares',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isFull ? AppColors.error : AppColors.primary),
                ),
                _SpotsBar(
                    total: cls.totalSpots,
                    booked: cls.bookedSpots,
                    border: tc.border),
              ]),
            ]),
            const SizedBox(height: 12),
            if (isBooked && bookedSpot != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: color.withOpacity(0.2), width: 0.5),
                ),
                child: Row(children: [
                  Icon(Icons.directions_run_rounded, size: 14, color: color),
                  const SizedBox(width: 8),
                  Text('Tu trotadora reservada:',
                      style: TextStyle(fontSize: 13, color: tc.textSecondary)),
                  const Spacer(),
                  Text('Trot. ${_spotFromIndex(bookedSpot!)}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ]),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 46,
              child: isBooked
                  ? _BookedActions(
                      color: color,
                      onChangeSeat: onChangeSeat ?? () {},
                      onCancel: onCancel ?? () {},
                    )
                  : isFull
                      ? _FullButton()
                      : _BookButton(color: color, onTap: onBook),
            ),
          ]),
        ),
      ]),
    );
  }

  IconData _levelIcon(RunLevel l) {
    switch (l) {
      case RunLevel.basico:      return Icons.signal_cellular_alt_1_bar_rounded;
      case RunLevel.intermedio:  return Icons.signal_cellular_alt_2_bar_rounded;
      case RunLevel.avanzado:    return Icons.signal_cellular_alt_rounded;
    }
  }

  static String _spotFromIndex(int index) {
    const cols = 2;
    final row = index ~/ cols;
    final col = index % cols;
    return '${String.fromCharCode('A'.codeUnitAt(0) + row)}${col + 1}';
  }
}

class _RunHeroImage extends StatelessWidget {
  final RunLevel level;
  final Color color;
  final Color surface;
  const _RunHeroImage(
      {required this.level, required this.color, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.3), surface],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -20,
          top: -20,
          child: Icon(Icons.directions_run_rounded,
              size: 160, color: color.withOpacity(0.08)),
        ),
        Center(
          child: Icon(Icons.directions_run_rounded,
              size: 64, color: color.withOpacity(0.5)),
        ),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _SpotsBar extends StatelessWidget {
  final int total, booked;
  final Color border;
  const _SpotsBar(
      {required this.total, required this.booked, required this.border});

  @override
  Widget build(BuildContext context) {
    final ratio = booked / total;
    final color = ratio >= 0.9
        ? AppColors.error
        : ratio >= 0.7
            ? AppColors.warning
            : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 80,
      height: 4,
      decoration:
          BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
      child: FractionallySizedBox(
        widthFactor: ratio.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _BookButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_run_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text('Elegir Trotadora',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ]),
        ),
      );
}

class _BookedActions extends StatelessWidget {
  final Color color;
  final VoidCallback onChangeSeat;
  final VoidCallback onCancel;
  const _BookedActions(
      {required this.color,
      required this.onChangeSeat,
      required this.onCancel});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: GestureDetector(
          onTap: onChangeSeat,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.swap_horiz_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text('Cambiar trotadora',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
            ]),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(
            child: GestureDetector(
          onTap: onCancel,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
            ),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                  SizedBox(width: 6),
                  Text('Cancelar',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ]),
          ),
        )),
      ]);
}

class _FullButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.block_rounded, size: 18, color: AppColors.error),
          SizedBox(width: 8),
          Text('Clase llena',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
        ]),
      );
}

// ── Instructors Tab ────────────────────────────────────

class _RunInstructorsTab extends StatelessWidget {
  final List<RunInstructor> instructors;
  const _RunInstructorsTab({required this.instructors});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: instructors.length,
        itemBuilder: (_, i) => _RunInstructorCard(inst: instructors[i]),
      );
}

class _RunInstructorCard extends StatelessWidget {
  final RunInstructor inst;
  const _RunInstructorCard({required this.inst});

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: inst.color.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
              color: inst.color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6)),
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Stack(children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: Image.asset(
                inst.photoAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [inst.color.withOpacity(0.35), tc.surface],
                    ),
                  ),
                  child: Center(
                      child: Icon(Icons.person_rounded,
                          size: 96, color: inst.color.withOpacity(0.4))),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75)
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(inst.name,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3)),
                          const SizedBox(height: 3),
                          Text(inst.specialty,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: inst.color)),
                        ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: inst.color.withOpacity(0.6), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_rounded,
                            size: 13, color: inst.color),
                        const SizedBox(width: 4),
                        Text('Certificado/a',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: inst.color)),
                      ]),
                    ),
                  ]),
            ),
          ]),
        ),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: inst.color.withOpacity(0.07),
            border: Border(
              top: BorderSide(color: inst.color.withOpacity(0.2), width: 0.5),
              bottom:
                  BorderSide(color: inst.color.withOpacity(0.2), width: 0.5),
            ),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                    icon: Icons.star_rounded,
                    value: inst.rating.toStringAsFixed(1),
                    label: 'Calificación',
                    color: AppColors.warning),
                Container(
                    width: 0.5,
                    height: 36,
                    color: inst.color.withOpacity(0.3)),
                _StatColumn(
                    icon: Icons.directions_run_rounded,
                    value: '${inst.totalClasses}',
                    label: 'Clases impartidas',
                    color: inst.color),
                Container(
                    width: 0.5,
                    height: 36,
                    color: inst.color.withOpacity(0.3)),
                _StatColumn(
                    icon: Icons.workspace_premium_rounded,
                    value: '4+',
                    label: 'Años de exp.',
                    color: AppColors.primary),
              ]),
        ),

        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                      color: inst.color,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('Perfil profesional',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tc.textPrimary,
                      letterSpacing: 0.3)),
            ]),
            const SizedBox(height: 10),
            Text(inst.bio,
                style: TextStyle(
                    fontSize: 14, color: tc.textSecondary, height: 1.6)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _SpecChip(label: 'Cardio Progresivo', color: inst.color),
              _SpecChip(label: 'Interval Training', color: inst.color),
              _SpecChip(label: 'Resistencia Aeróbica', color: inst.color),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatColumn(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 13, color: tc.textMuted)),
    ]);
  }
}

class _SpecChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SpecChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      );
}

// ── My Bookings Tab ────────────────────────────────────

class _RunMyBookingsTab extends StatelessWidget {
  final List<RunClass> classes;
  final Map<String, int> myBookings;
  final Color Function(RunLevel) levelColor;
  final String Function(RunLevel) levelLabel;
  final String Function(int) spotLabel;
  final void Function(RunClass, int) onChangeSeat;
  final void Function(RunClass) onCancel;

  const _RunMyBookingsTab({
    required this.classes,
    required this.myBookings,
    required this.levelColor,
    required this.levelLabel,
    required this.spotLabel,
    required this.onChangeSeat,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final booked =
        classes.where((c) => myBookings.containsKey(c.id)).toList();

    if (booked.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.directions_run_rounded, size: 64, color: tc.textMuted),
        const SizedBox(height: 16),
        Text('Sin reservas aún',
            style: AppTextStyles.headingMedium.copyWith(color: tc.textSecondary)),
        const SizedBox(height: 8),
        Text('Ve a Horarios y reserva tu trotadora',
            style: AppTextStyles.bodyMedium.copyWith(color: tc.textMuted)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: booked.length,
      itemBuilder: (context, i) {
        final cls = booked[i];
        final color = levelColor(cls.level);
        final spot = myBookings[cls.id]!;
        final label = spotLabel(spot);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.directions_run_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(cls.name,
                        style: AppTextStyles.headingSmall
                            .copyWith(color: tc.textPrimary)),
                    const SizedBox(height: 2),
                    Text(cls.time,
                        style: TextStyle(fontSize: 13, color: tc.textSecondary)),
                    Text(cls.days,
                        style: TextStyle(fontSize: 13, color: tc.textMuted)),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(levelLabel(cls.level),
                      style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 4),
                Text('Trot. $label',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text('${cls.caloriesMin}–${cls.caloriesMax} kcal',
                    style: TextStyle(fontSize: 13, color: tc.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(height: 0.5, color: tc.border),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: GestureDetector(
                onTap: () => onChangeSeat(cls, spot),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: color.withOpacity(0.35), width: 1),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 15, color: color),
                        const SizedBox(width: 5),
                        Text('Cambiar trotadora',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                      ]),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: GestureDetector(
                onTap: () => onCancel(cls),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.25), width: 1),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_outlined,
                            size: 15, color: AppColors.error),
                        SizedBox(width: 5),
                        Text('Cancelar',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                      ]),
                ),
              )),
            ]),
          ]),
        );
      },
    );
  }
}
