import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'running_spot_selection_screen.dart';

// ── Models ─────────────────────────────────────────────

enum RunLevel { principiante, intermedio, avanzado }

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
  Set<int> reservedSpots;

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
    Set<int>? reservedSpots,
  }) : reservedSpots = reservedSpots ?? {};

  int get availableSpots => totalSpots - bookedSpots;
}

// ── Static Data ────────────────────────────────────────

final _runInstructors = [
  const RunInstructor(
    id: 'r1',
    name: 'Camila',
    specialty: 'Resistencia & Atletismo',
    bio: 'Atleta certificada con más de 6 años de experiencia en entrenamiento de resistencia y running técnico. Especialista en planes de progresión para corredores de todos los niveles, desde principiantes hasta atletas de competición. Su método combina técnica de carrera, trabajo de fuerza y fisiología del ejercicio para maximizar el rendimiento en cada sesión.',
    photoAsset: 'assets/images/instructors/camila.png',
    rating: 4.9,
    totalClasses: 310,
    color: Color(0xFF00FF87),
  ),
  const RunInstructor(
    id: 'r2',
    name: 'Rodrigo',
    specialty: 'HIIT Running & Intervalos',
    bio: 'Entrenador personal certificado especializado en running de alta intensidad e intervalos. Con formación en biomecánica de la carrera y más de 4 años de experiencia, lleva a cada atleta a superar sus marcas personales. Su metodología enfocada en intervalos y trabajo de umbral anaeróbico garantiza mejoras medibles sesión a sesión.',
    photoAsset: 'assets/images/instructors/rodrigo.png',
    rating: 4.8,
    totalClasses: 220,
    color: Color(0xFF4FC3F7),
  ),
];

List<RunClass> _buildRunClasses() => [
  RunClass(
    id: 'r_c1',
    name: 'Morning Sprint',
    description: 'Activa el cuerpo desde temprano con una sesión de intervalos cortos y sprint progresivos. La mejor forma de comenzar el día con energía máxima y quemar desde la primera hora.',
    features: ['Cinta profesional', 'Monitor de ritmo', 'Protocolo de intervalos'],
    instructor: _runInstructors[0],
    level: RunLevel.avanzado,
    time: '06:00 AM',
    days: 'Lun · Mié · Vie',
    durationMinutes: 45,
    caloriesMin: 400,
    caloriesMax: 550,
    totalSpots: 6,
    bookedSpots: 0,
  ),
  RunClass(
    id: 'r_c2',
    name: 'Endurance Base',
    description: 'Sesión de carrera continua a ritmo moderado para construir base aeróbica. Ideal para quienes buscan mejorar resistencia sin sacrificar técnica. Guiada con control de frecuencia cardíaca.',
    features: ['Cinta profesional', 'Control cardíaco', 'Ritmo progresivo'],
    instructor: _runInstructors[0],
    level: RunLevel.principiante,
    time: '08:00 AM',
    days: 'Lun · Mar · Mié · Jue · Vie',
    durationMinutes: 45,
    caloriesMin: 300,
    caloriesMax: 420,
    totalSpots: 6,
    bookedSpots: 0,
  ),
  RunClass(
    id: 'r_c3',
    name: 'Interval Blast',
    description: 'Alta intensidad con intervalos de 30-60 segundos al máximo esfuerzo. El protocolo más efectivo para mejorar potencia aeróbica y quemar grasa en tiempo récord.',
    features: ['Cinta profesional', 'Métricas en tiempo real', 'Protocolo HIIT'],
    instructor: _runInstructors[1],
    level: RunLevel.avanzado,
    time: '06:30 PM',
    days: 'Mar · Jue',
    durationMinutes: 40,
    caloriesMin: 450,
    caloriesMax: 600,
    totalSpots: 6,
    bookedSpots: 0,
  ),
  RunClass(
    id: 'r_c4',
    name: 'Weekend Long Run',
    description: 'La sesión de fondo del fin de semana. Carrera continua a ritmo conversacional para consolidar la base aeróbica acumulada durante la semana. Para todos los niveles.',
    features: ['Cinta profesional', 'Monitor cardíaco', 'Todos los niveles'],
    instructor: _runInstructors[1],
    level: RunLevel.intermedio,
    time: '09:00 AM',
    days: 'Sáb · Dom',
    durationMinutes: 60,
    caloriesMin: 380,
    caloriesMax: 500,
    totalSpots: 6,
    bookedSpots: 0,
  ),
];

// ── Main Screen ────────────────────────────────────────

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;

  late TabController _tabController;
  late List<RunClass> _classes;
  final Map<String, int> _myBookings = {}; // classId → spotIndex
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _classes = _buildRunClasses();
    _loadBookings();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ── Supabase helpers ────────────────────────────────────

  RunClass? _classById(String id) {
    for (final c in _classes) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _loadBookings() async {
    try {
      final rows = await _supabase
          .from('running_bookings')
          .select('class_id, spot_index, user_id');
      if (!mounted) return;
      final myId = _supabase.auth.currentUser?.id;
      setState(() {
        for (final row in rows) {
          final classId = row['class_id'] as String;
          final spotIndex = row['spot_index'] as int;
          final userId = row['user_id'] as String;
          final cls = _classById(classId);
          if (cls != null && cls.reservedSpots.add(spotIndex)) {
            cls.bookedSpots++;
          }
          if (myId != null && userId == myId) {
            _myBookings[classId] = spotIndex;
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
            final spotIndex = payload.newRecord['spot_index'] as int?;
            final userId = payload.newRecord['user_id'] as String?;
            if (classId == null || spotIndex == null) return;
            setState(() {
              final cls = _classById(classId);
              if (cls != null && cls.reservedSpots.add(spotIndex)) {
                cls.bookedSpots++;
              }
              final myId = _supabase.auth.currentUser?.id;
              if (myId != null && userId == myId) {
                _myBookings[classId] = spotIndex;
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
            final spotIndex = payload.oldRecord['spot_index'] as int?;
            final userId = payload.oldRecord['user_id'] as String?;
            if (classId == null || spotIndex == null) return;
            setState(() {
              final cls = _classById(classId);
              if (cls != null && cls.reservedSpots.remove(spotIndex)) {
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
      case RunLevel.principiante:
        return AppColors.primary;
      case RunLevel.intermedio:
        return AppColors.accentBlue;
      case RunLevel.avanzado:
        return AppColors.accentPurple;
    }
  }

  String _levelLabel(RunLevel l) {
    switch (l) {
      case RunLevel.principiante:
        return 'Principiante';
      case RunLevel.intermedio:
        return 'Intermedio';
      case RunLevel.avanzado:
        return 'Alto Rendimiento';
    }
  }

  String _spotLabel(int index) {
    const cols = 2;
    final row = index ~/ cols;
    final col = index % cols;
    return '${String.fromCharCode('A'.codeUnitAt(0) + row)}${col + 1}';
  }

  void _openSpotSelection(RunClass cls, {int? oldSpot}) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => RunningSpotSelectionScreen(
          runClass: cls,
          currentSpot: oldSpot,
        ),
      ),
    );

    if (!mounted || result == null || result == oldSpot) return;

    setState(() {
      if (oldSpot != null && cls.reservedSpots.remove(oldSpot)) cls.bookedSpots--;
      if (cls.reservedSpots.add(result)) cls.bookedSpots++;
      _myBookings[cls.id] = result;
    });

    HapticFeedback.mediumImpact();
    final label = _spotLabel(result);
    final isChange = oldSpot != null;
    _showSnackBar(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primary,
      text: isChange
          ? 'Cambiaste a la cinta $label en ${cls.name}'
          : 'Cinta $label reservada en ${cls.name}',
    );

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      if (oldSpot != null) {
        await _supabase
            .from('running_bookings')
            .delete()
            .eq('user_id', userId)
            .eq('class_id', cls.id);
      }
      await _supabase.from('running_bookings').insert({
        'user_id': userId,
        'class_id': cls.id,
        'spot_index': result,
      });
    } catch (e) {
      debugPrint('running_bookings insert error: $e');
      if (!mounted) return;
      setState(() {
        if (cls.reservedSpots.remove(result)) cls.bookedSpots--;
        if (oldSpot != null && cls.reservedSpots.add(oldSpot)) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cancelar reserva',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Seguro que quieres cancelar tu cinta en ${cls.name}?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final spot = _myBookings[cls.id];

    setState(() {
      if (spot != null && cls.reservedSpots.remove(spot)) cls.bookedSpots--;
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
      await _supabase
          .from('running_bookings')
          .delete()
          .eq('user_id', userId)
          .eq('class_id', cls.id);
    } catch (_) {
      if (!mounted || spot == null) return;
      setState(() {
        if (cls.reservedSpots.add(spot)) cls.bookedSpots++;
        _myBookings[cls.id] = spot;
      });
      _showSnackBar(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        text: 'Error al cancelar la reserva. Inténtalo de nuevo.',
      );
    }
  }

  void _showSnackBar({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _RunScheduleTab(
                          classes: _classes,
                          myBookings: _myBookings,
                          levelColor: _levelColor,
                          levelLabel: _levelLabel,
                          onBook: _openSpotSelection,
                          onChangeSpot: (cls, oldSpot) =>
                              _openSpotSelection(cls, oldSpot: oldSpot),
                          onCancel: _cancelBooking,
                        ),
                        _RunInstructorsTab(instructors: _runInstructors),
                        _RunMyBookingsTab(
                          classes: _classes,
                          myBookings: _myBookings,
                          levelColor: _levelColor,
                          levelLabel: _levelLabel,
                          spotLabel: _spotLabel,
                          onChangeSpot: (cls, oldSpot) =>
                              _openSpotSelection(cls, oldSpot: oldSpot),
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

  Widget _buildHeader(BuildContext context) {
    final availableClasses = _classes.where((c) => c.availableSpots > 0).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
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
                    Row(
                      children: [
                        Text('Running', style: AppTextStyles.displayMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sesiones en cinta con entrenadores certificados',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              children: [
                _RunCredBadge(
                    icon: Icons.verified_rounded,
                    label: 'Entrenadores Certificados',
                    color: AppColors.primary),
                const SizedBox(width: 10),
                _RunCredBadge(
                    icon: Icons.monitor_heart_rounded,
                    label: 'Monitor Cardíaco',
                    color: AppColors.error),
                const SizedBox(width: 10),
                _RunCredBadge(
                    icon: Icons.speed_rounded,
                    label: 'Cinta Profesional',
                    color: AppColors.accentBlue),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RunStatChip(
                icon: Icons.calendar_today_rounded,
                label: '$availableClasses clases disponibles',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _RunStatChip(
                icon: Icons.local_fire_department_rounded,
                label: '300–600 kcal',
                color: AppColors.accentPurple,
              ),
              const SizedBox(width: 10),
              _RunStatChip(
                icon: Icons.timer_rounded,
                label: '40-60 min',
                color: AppColors.accentBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 8,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Horarios'),
          Tab(text: 'Entrenadores'),
          Tab(text: 'Mis Reservas'),
        ],
      ),
    );
  }
}

// ── Cred Badge ─────────────────────────────────────────

class _RunCredBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RunCredBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ──────────────────────────────────────────

class _RunStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RunStatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Schedule Tab ───────────────────────────────────────

class _RunScheduleTab extends StatelessWidget {
  final List<RunClass> classes;
  final Map<String, int> myBookings;
  final Color Function(RunLevel) levelColor;
  final String Function(RunLevel) levelLabel;
  final void Function(RunClass) onBook;
  final void Function(RunClass, int) onChangeSpot;
  final void Function(RunClass) onCancel;

  const _RunScheduleTab({
    required this.classes,
    required this.myBookings,
    required this.levelColor,
    required this.levelLabel,
    required this.onBook,
    required this.onChangeSpot,
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
          onChangeSpot:
              bookedSpot != null ? () => onChangeSpot(cls, bookedSpot) : null,
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
  final VoidCallback? onChangeSpot;
  final VoidCallback? onCancel;

  const _RunClassCard({
    required this.cls,
    required this.isBooked,
    this.bookedSpot,
    required this.levelColor,
    required this.levelLabel,
    required this.onBook,
    this.onChangeSpot,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final color = levelColor(cls.level);
    final isFull = cls.availableSpots == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBooked ? color.withOpacity(0.5) : AppColors.border,
          width: isBooked ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (isBooked)
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 16),
        ],
      ),
      child: Column(
        children: [
          // ── Hero area ──
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                _RunHeroImage(level: cls.level, color: color),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.surface.withOpacity(0.95),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withOpacity(0.6), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_levelIcon(cls.level), size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          levelLabel(cls.level),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                      ],
                    ),
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
                            border: Border.all(
                                color: color.withOpacity(0.6), width: 1),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_run_rounded,
                                    size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  bookedSpot != null
                                      ? 'Cinta ${_spotFromIndex(bookedSpot!)}'
                                      : 'Reservado',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color),
                                ),
                              ]),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.5),
                                width: 0.5),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    size: 11, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('CERTIFICADA',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 0.8)),
                              ]),
                        ),
                ),
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Text(cls.name, style: AppTextStyles.headingLarge),
                ),
              ],
            ),
          ),

          // ── Info section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.description,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.45),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cls.features
                      .map((f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.25),
                                  width: 0.5),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 10, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(f,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                            ]),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Container(height: 0.5, color: AppColors.border),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _RunInfoPill(
                        icon: Icons.access_time_rounded,
                        label: cls.time,
                        color: AppColors.accentBlue),
                    _RunInfoPill(
                        icon: Icons.local_fire_department_rounded,
                        label: '${cls.caloriesMin}–${cls.caloriesMax} kcal',
                        color: AppColors.accentOrange),
                    _RunInfoPill(
                        icon: Icons.timer_rounded,
                        label: '${cls.durationMinutes} min',
                        color: AppColors.accentPurple),
                    _RunInfoPill(
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
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cls.days,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isFull ? 'Lleno' : '${cls.availableSpots} cintas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isFull ? AppColors.error : AppColors.primary,
                          ),
                        ),
                        _RunSpotsBar(
                            total: cls.totalSpots,
                            booked: cls.bookedSpots),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isBooked && bookedSpot != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: color.withOpacity(0.2), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_run_rounded,
                            size: 14, color: color),
                        const SizedBox(width: 8),
                        const Text('Tu cinta reservada:',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(
                          'Cinta ${_spotFromIndex(bookedSpot!)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: isBooked
                      ? _RunBookedActions(
                          color: color,
                          onChangeSpot: onChangeSpot ?? () {},
                          onCancel: onCancel ?? () {},
                        )
                      : isFull
                          ? _RunFullButton()
                          : _RunBookButton(color: color, onTap: onBook),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _levelIcon(RunLevel l) {
    switch (l) {
      case RunLevel.principiante:
        return Icons.signal_cellular_alt_1_bar_rounded;
      case RunLevel.intermedio:
        return Icons.signal_cellular_alt_2_bar_rounded;
      case RunLevel.avanzado:
        return Icons.signal_cellular_alt_rounded;
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
  const _RunHeroImage({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.directions_run_rounded,
      Icons.electric_bolt_rounded,
      Icons.whatshot_rounded,
    ];
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.3), AppColors.surface],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(icons[level.index],
                size: 160, color: color.withOpacity(0.08)),
          ),
          Center(
            child: Icon(Icons.directions_run_rounded,
                size: 64, color: color.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _RunInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RunInfoPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _RunSpotsBar extends StatelessWidget {
  final int total;
  final int booked;
  const _RunSpotsBar({required this.total, required this.booked});

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
      decoration: BoxDecoration(
          color: AppColors.border, borderRadius: BorderRadius.circular(2)),
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

class _RunBookButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _RunBookButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run_rounded, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text('Elegir Cinta',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _RunBookedActions extends StatelessWidget {
  final Color color;
  final VoidCallback onChangeSpot;
  final VoidCallback onCancel;
  const _RunBookedActions(
      {required this.color,
      required this.onChangeSpot,
      required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onChangeSpot,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text('Cambiar cinta',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onCancel,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.3), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.error),
                  SizedBox(width: 6),
                  Text('Cancelar',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RunFullButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block_rounded, size: 18, color: AppColors.error),
          SizedBox(width: 8),
          Text('Clase llena',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error)),
        ],
      ),
    );
  }
}

// ── Instructors Tab ────────────────────────────────────

class _RunInstructorsTab extends StatelessWidget {
  final List<RunInstructor> instructors;
  const _RunInstructorsTab({required this.instructors});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: instructors.length,
      itemBuilder: (_, i) => _RunInstructorCard(inst: instructors[i]),
    );
  }
}

class _RunInstructorCard extends StatelessWidget {
  final RunInstructor inst;
  const _RunInstructorCard({required this.inst});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: inst.color.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
              color: inst.color.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
            child: Stack(
              children: [
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
                          colors: [
                            inst.color.withOpacity(0.35),
                            AppColors.surface,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.person_rounded,
                            size: 96,
                            color: inst.color.withOpacity(0.4)),
                      ),
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
                          Colors.black.withOpacity(0.75),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: inst.color)),
                          ],
                        ),
                      ),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: inst.color)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: inst.color.withOpacity(0.07),
              border: Border(
                top: BorderSide(
                    color: inst.color.withOpacity(0.2), width: 0.5),
                bottom: BorderSide(
                    color: inst.color.withOpacity(0.2), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RunStatCol(
                    icon: Icons.star_rounded,
                    value: inst.rating.toStringAsFixed(1),
                    label: 'Calificación',
                    color: AppColors.warning),
                Container(
                    width: 0.5,
                    height: 36,
                    color: inst.color.withOpacity(0.3)),
                _RunStatCol(
                    icon: Icons.directions_run_rounded,
                    value: '${inst.totalClasses}',
                    label: 'Sesiones',
                    color: inst.color),
                Container(
                    width: 0.5,
                    height: 36,
                    color: inst.color.withOpacity(0.3)),
                _RunStatCol(
                    icon: Icons.workspace_premium_rounded,
                    value: '4+',
                    label: 'Años de exp.',
                    color: AppColors.primary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                        color: inst.color,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Perfil profesional',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3)),
                ]),
                const SizedBox(height: 10),
                Text(inst.bio,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RunSpecChip(
                        label: 'Running Técnico', color: inst.color),
                    _RunSpecChip(
                        label: 'Cardio Avanzado', color: inst.color),
                    _RunSpecChip(
                        label: 'Entrenamiento HIIT', color: inst.color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunStatCol extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _RunStatCol(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

class _RunSpecChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RunSpecChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── My Bookings Tab ────────────────────────────────────

class _RunMyBookingsTab extends StatelessWidget {
  final List<RunClass> classes;
  final Map<String, int> myBookings;
  final Color Function(RunLevel) levelColor;
  final String Function(RunLevel) levelLabel;
  final String Function(int) spotLabel;
  final void Function(RunClass, int) onChangeSpot;
  final void Function(RunClass) onCancel;

  const _RunMyBookingsTab({
    required this.classes,
    required this.myBookings,
    required this.levelColor,
    required this.levelLabel,
    required this.spotLabel,
    required this.onChangeSpot,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final booked =
        classes.where((c) => myBookings.containsKey(c.id)).toList();
    if (booked.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_run_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Sin reservas aún',
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Ve a Horarios y reserva tu cinta',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.directions_run_rounded,
                        color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cls.name,
                            style: AppTextStyles.headingSmall),
                        const SizedBox(height: 2),
                        Text(cls.time,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text(cls.days,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(levelLabel(cls.level),
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 4),
                      Text('Cinta $label',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color)),
                      Text('${cls.caloriesMin}–${cls.caloriesMax} kcal',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 0.5, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChangeSpot(cls, spot),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: color.withOpacity(0.35), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                size: 15, color: color),
                            const SizedBox(width: 5),
                            Text('Cambiar cinta',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                              color: AppColors.error.withOpacity(0.25),
                              width: 1),
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
                                    color: AppColors.error)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
