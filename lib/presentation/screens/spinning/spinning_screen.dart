import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'seat_selection_screen.dart';

// ── Models ─────────────────────────────────────────────

enum SpinLevel { basico, intermedio, avanzado }

class SpinInstructor {
  final String id;
  final String name;
  final String specialty;
  final String bio;
  final String photoAsset;
  final double rating;
  final int totalClasses;
  final Color color;

  const SpinInstructor({
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

class SpinClass {
  final String id;
  final String name;
  final String description;
  final List<String> features;
  final SpinInstructor instructor;
  final SpinLevel level;
  final String time;
  final String days;
  final int durationMinutes;
  final int caloriesMin;
  final int caloriesMax;
  final int totalSpots;
  int bookedSpots;
  Set<int> reservedSeats;

  SpinClass({
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

final _instructors = [
  const SpinInstructor(
    id: 'i1',
    name: 'Verónica',
    specialty: 'HIIT & Alto Rendimiento',
    bio: 'Instructora certificada internacionalmente con más de 5 años de experiencia en ciclismo indoor de alto rendimiento. Especialista en protocolos HIIT y entrenamiento funcional cardiovascular. Ha acompañado a cientos de atletas a descubrir su máximo potencial, combinando técnica depurada con motivación real dentro del salón.',
    photoAsset: 'assets/images/instructors/vero.png',
    rating: 4.9,
    totalClasses: 280,
    color: Color(0xFFFF6B35),
  ),
  const SpinInstructor(
    id: 'i2',
    name: 'Julio',
    specialty: 'Potencia & Ciclismo Indoor',
    bio: 'Instructor profesional certificado con amplia trayectoria en ciclismo de potencia y entrenamiento cardiovascular de alta intensidad. Su metodología combina técnica depurada con intensidad progresiva, adaptada a cada nivel. Apasionado por el rendimiento, lleva a cada miembro a superar sus propias marcas sesión a sesión.',
    photoAsset: 'assets/images/instructors/julio.png',
    rating: 4.8,
    totalClasses: 195,
    color: Color(0xFF4FC3F7),
  ),
];

List<SpinClass> _buildClasses() => [
  SpinClass(
    id: 'c1',
    name: 'Morning Power',
    description: 'La sesión más exigente del día. Activa el metabolismo desde temprano con tabatas y sprints guiados por instructora certificada. Para los que hacen la diferencia antes que el resto despierte.',
    features: ['Bicicleta Keiser M3+', 'Monitor cardíaco', 'Protocolo HIIT'],
    instructor: _instructors[0], // Verónica
    level: SpinLevel.avanzado,
    time: '05:00 AM',
    days: 'Lun · Mar · Mié · Jue · Vie',
    durationMinutes: 60,
    caloriesMin: 550,
    caloriesMax: 750,
    totalSpots: 18,
    bookedSpots: 0,
  ),
  SpinClass(
    id: 'c2',
    name: 'Evening Burn',
    description: 'La sesión perfecta para desconectarte del trabajo. Cardio de precisión con música en vivo y retroalimentación en tiempo real. Quema calórica sostenida de inicio a fin.',
    features: ['Bicicleta Keiser M3', 'Monitor cardíaco', 'Música en vivo'],
    instructor: _instructors[1], // Julio
    level: SpinLevel.intermedio,
    time: '06:00 PM',
    days: 'Lun · Mar · Mié · Jue · Vie',
    durationMinutes: 60,
    caloriesMin: 450,
    caloriesMax: 600,
    totalSpots: 18,
    bookedSpots: 0,
  ),
  SpinClass(
    id: 'c3',
    name: 'Night Storm',
    description: 'Cierra el día con todo. Intervalos de alta intensidad guiados por instructora certificada para maximizar la quema calórica y desafiar tus límites cada sesión.',
    features: ['Bicicleta Keiser M3+', 'Potenciómetro watt', 'Métricas en tiempo real'],
    instructor: _instructors[0], // Verónica
    level: SpinLevel.avanzado,
    time: '07:00 PM',
    days: 'Lun · Mar · Mié · Jue · Vie',
    durationMinutes: 60,
    caloriesMin: 550,
    caloriesMax: 700,
    totalSpots: 18,
    bookedSpots: 0,
  ),
];

// ── Main Screen ────────────────────────────────────────

class SpinningScreen extends StatefulWidget {
  const SpinningScreen({super.key});

  @override
  State<SpinningScreen> createState() => _SpinningScreenState();
}

class _SpinningScreenState extends State<SpinningScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  late List<SpinClass> _classes;
  final Map<String, int> _myBookings = {}; // classId → seatIndex

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _classes = _buildClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _levelColor(SpinLevel l) {
    switch (l) {
      case SpinLevel.basico:
        return AppColors.primary;
      case SpinLevel.intermedio:
        return AppColors.accentOrange;
      case SpinLevel.avanzado:
        return AppColors.accentPurple;
    }
  }

  String _levelLabel(SpinLevel l) {
    switch (l) {
      case SpinLevel.basico:
        return 'Iniciación Pro';
      case SpinLevel.intermedio:
        return 'Intermedio Pro';
      case SpinLevel.avanzado:
        return 'Alto Rendimiento';
    }
  }

  String _seatLabel(int index) {
    const cols = 6;
    final row = index ~/ cols;
    final col = index % cols;
    return '${String.fromCharCode('A'.codeUnitAt(0) + row)}${col + 1}';
  }

  void _openSeatSelection(SpinClass cls, {int? oldSeat}) async {
    if (oldSeat != null) {
      // Temporarily free the old seat so it shows as available in the picker
      setState(() {
        cls.reservedSeats.remove(oldSeat);
        cls.bookedSpots--;
      });
    }

    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(spinClass: cls),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        cls.reservedSeats.add(result);
        cls.bookedSpots++;
        _myBookings[cls.id] = result;
      });
      HapticFeedback.mediumImpact();
      if (mounted) {
        final label = _seatLabel(result);
        final isChange = oldSeat != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isChange
                        ? 'Cambiaste al puesto $label en ${cls.name}'
                        : 'Puesto $label reservado en ${cls.name}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else if (oldSeat != null && mounted) {
      // User cancelled the change — restore old seat
      setState(() {
        cls.reservedSeats.add(oldSeat);
        cls.bookedSpots++;
      });
    }
  }

  void _cancelBooking(SpinClass cls) async {
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
          '¿Seguro que quieres cancelar tu puesto en ${cls.name}?',
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
    if (confirmed == true && mounted) {
      setState(() {
        final seat = _myBookings[cls.id];
        if (seat != null) {
          cls.reservedSeats.remove(seat);
          cls.bookedSpots--;
        }
        _myBookings.remove(cls.id);
      });
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reserva cancelada en ${cls.name}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ScheduleTab(
                    classes: _classes,
                    myBookings: _myBookings,
                    levelColor: _levelColor,
                    levelLabel: _levelLabel,
                    onBook: _openSeatSelection,
                    onChangeSeat: (cls, oldSeat) =>
                        _openSeatSelection(cls, oldSeat: oldSeat),
                    onCancel: _cancelBooking,
                  ),
                  _InstructorsTab(instructors: _instructors),
                  _MyBookingsTab(
                    classes: _classes,
                    myBookings: _myBookings,
                    levelColor: _levelColor,
                    levelLabel: _levelLabel,
                    seatLabel: _seatLabel,
                    onChangeSeat: (cls, oldSeat) =>
                        _openSeatSelection(cls, oldSeat: oldSeat),
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

  Widget _buildHeader() {
    final availableClasses = _classes.where((c) => c.availableSpots > 0).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentOrange.withOpacity(0.18),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.burnGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_bike_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Spinning', style: AppTextStyles.displayMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.burnGradient,
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
                      'Sesiones certificadas con instructores profesionales',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Fila de credenciales profesionales
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentOrange.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              children: [
                _CredBadge(icon: Icons.verified_rounded, label: 'Instructores Certificados', color: AppColors.accentOrange),
                const SizedBox(width: 10),
                _CredBadge(icon: Icons.monitor_heart_rounded, label: 'Monitor Cardíaco', color: AppColors.error),
                const SizedBox(width: 10),
                _CredBadge(icon: Icons.bike_scooter_rounded, label: 'Keiser M3', color: AppColors.accentBlue),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.calendar_today_rounded,
                label: '$availableClasses clases disponibles',
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                label: '400–800 kcal',
                color: AppColors.accentPurple,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.timer_rounded,
                label: '60 min',
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
          gradient: AppColors.burnGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentOrange.withOpacity(0.4),
              blurRadius: 8,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Horarios'),
          Tab(text: 'Entrenadores'),
          Tab(text: 'Mis Reservas'),
        ],
      ),
    );
  }
}

// ── Cred Badge (profesional) ───────────────────────────

class _CredBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CredBadge({required this.icon, required this.label, required this.color});

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
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ──────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
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
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Schedule Tab ───────────────────────────────────────

class _ScheduleTab extends StatelessWidget {
  final List<SpinClass> classes;
  final Map<String, int> myBookings;
  final Color Function(SpinLevel) levelColor;
  final String Function(SpinLevel) levelLabel;
  final void Function(SpinClass) onBook;
  final void Function(SpinClass, int) onChangeSeat;
  final void Function(SpinClass) onCancel;

  const _ScheduleTab({
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
        final bookedSeat = myBookings[cls.id];
        return _ClassCard(
          cls: cls,
          isBooked: bookedSeat != null,
          bookedSeat: bookedSeat,
          levelColor: levelColor,
          levelLabel: levelLabel,
          onBook: () => onBook(cls),
          onChangeSeat:
              bookedSeat != null ? () => onChangeSeat(cls, bookedSeat) : null,
          onCancel: bookedSeat != null ? () => onCancel(cls) : null,
        );
      },
    );
  }
}

// ── Class Card ─────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final SpinClass cls;
  final bool isBooked;
  final int? bookedSeat;
  final Color Function(SpinLevel) levelColor;
  final String Function(SpinLevel) levelLabel;
  final VoidCallback onBook;
  final VoidCallback? onChangeSeat;
  final VoidCallback? onCancel;

  const _ClassCard({
    required this.cls,
    required this.isBooked,
    this.bookedSeat,
    required this.levelColor,
    required this.levelLabel,
    required this.onBook,
    this.onChangeSeat,
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
          color: isBooked
              ? color.withOpacity(0.5)
              : AppColors.border,
          width: isBooked ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (isBooked)
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
            ),
        ],
      ),
      child: Column(
        children: [
          // ── Hero image area ──
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                _ClassHeroImage(level: cls.level, color: color),
                // Gradient overlay
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
                // Level badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
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
                        Icon(_levelIcon(cls.level),
                            size: 12, color: color),
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
                // Certified badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: isBooked
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.6), width: 1),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text('Reservado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                          ]),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accentOrange.withOpacity(0.5), width: 0.5),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.verified_rounded, size: 11, color: AppColors.accentOrange),
                            SizedBox(width: 4),
                            Text('CERTIFICADA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.accentOrange, letterSpacing: 0.8)),
                          ]),
                        ),
                ),
                // Class name over image
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Text(
                    cls.name,
                    style: AppTextStyles.headingLarge,
                  ),
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
                // Descripción profesional
                Text(
                  cls.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                // Features del equipamiento
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cls.features.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentOrange.withOpacity(0.25), width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline_rounded, size: 10, color: AppColors.accentOrange),
                      const SizedBox(width: 4),
                      Text(f, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentOrange)),
                    ]),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                // Divisor
                Container(height: 0.5, color: AppColors.border),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoPill(
                      icon: Icons.access_time_rounded,
                      label: cls.time,
                      color: AppColors.accentBlue,
                    ),
                    _InfoPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${cls.caloriesMin}–${cls.caloriesMax} kcal',
                      color: AppColors.accentOrange,
                    ),
                    _InfoPill(
                      icon: Icons.timer_rounded,
                      label: '${cls.durationMinutes} min',
                      color: AppColors.accentPurple,
                    ),
                    _InfoPill(
                      icon: Icons.people_rounded,
                      label: isFull
                          ? 'Sin cupos'
                          : '${cls.availableSpots}/${cls.totalSpots} cupos',
                      color: isFull
                          ? AppColors.error
                          : cls.availableSpots <= 3
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
                      child: Text(
                        cls.days,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ),
                    // Spots indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isFull
                              ? 'Lleno'
                              : '${cls.availableSpots} lugares',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isFull
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                        ),
                        _SpotsBar(
                          total: cls.totalSpots,
                          booked: cls.bookedSpots,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Book button
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
                          : _BookButton(
                              color: color, onTap: onBook),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _levelIcon(SpinLevel l) {
    switch (l) {
      case SpinLevel.basico:
        return Icons.signal_cellular_alt_1_bar_rounded;
      case SpinLevel.intermedio:
        return Icons.signal_cellular_alt_2_bar_rounded;
      case SpinLevel.avanzado:
        return Icons.signal_cellular_alt_rounded;
    }
  }
}

class _ClassHeroImage extends StatelessWidget {
  final SpinLevel level;
  final Color color;

  const _ClassHeroImage({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.directions_bike_rounded,
      Icons.electric_bolt_rounded,
      Icons.whatshot_rounded,
    ];
    final idx = level.index;

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            AppColors.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              icons[idx],
              size: 160,
              color: color.withOpacity(0.08),
            ),
          ),
          Center(
            child: Icon(
              Icons.directions_bike_rounded,
              size: 64,
              color: color.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SpotsBar extends StatelessWidget {
  final int total;
  final int booked;

  const _SpotsBar({required this.total, required this.booked});

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
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        widthFactor: ratio.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat_rounded, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Elegir Puesto',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookedActions extends StatelessWidget {
  final Color color;
  final VoidCallback onChangeSeat;
  final VoidCallback onCancel;

  const _BookedActions({
    required this.color,
    required this.onChangeSeat,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'Cambiar lugar',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
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
                  Text(
                    'Cancelar',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block_rounded, size: 18, color: AppColors.error),
          SizedBox(width: 8),
          Text(
            'Clase llena',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// ── Instructors Tab ────────────────────────────────────

class _InstructorsTab extends StatelessWidget {
  final List<SpinInstructor> instructors;
  const _InstructorsTab({required this.instructors});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: instructors.length,
      itemBuilder: (_, i) => _InstructorCard(inst: instructors[i]),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  final SpinInstructor inst;
  const _InstructorCard({required this.inst});

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
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto de perfil ──────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Stack(
              children: [
                // Foto real o placeholder
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
                            size: 96, color: inst.color.withOpacity(0.4)),
                      ),
                    ),
                  ),
                ),
                // Degradado inferior para legibilidad del nombre
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
                // Nombre + certificado sobre la foto
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
                            Text(
                              inst.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              inst.specialty,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: inst.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: inst.color.withOpacity(0.6), width: 1),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified_rounded, size: 13, color: inst.color),
                          const SizedBox(width: 4),
                          Text(
                            'Certificado/a',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: inst.color,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Estadísticas ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: inst.color.withOpacity(0.07),
              border: Border(
                top: BorderSide(color: inst.color.withOpacity(0.2), width: 0.5),
                bottom: BorderSide(color: inst.color.withOpacity(0.2), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  icon: Icons.star_rounded,
                  value: inst.rating.toStringAsFixed(1),
                  label: 'Calificación',
                  color: AppColors.warning,
                ),
                Container(width: 0.5, height: 36, color: inst.color.withOpacity(0.3)),
                _StatColumn(
                  icon: Icons.directions_bike_rounded,
                  value: '${inst.totalClasses}',
                  label: 'Clases impartidas',
                  color: inst.color,
                ),
                Container(width: 0.5, height: 36, color: inst.color.withOpacity(0.3)),
                _StatColumn(
                  icon: Icons.workspace_premium_rounded,
                  value: '5+',
                  label: 'Años de exp.',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // ── Presentación profesional ─────────────────────────
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Perfil profesional',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  inst.bio,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                // Chips de especialidad
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SpecChip(label: 'Ciclismo Indoor', color: inst.color),
                    _SpecChip(label: 'HIIT Profesional', color: inst.color),
                    _SpecChip(label: 'Cardio de Precisión', color: inst.color),
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

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatColumn({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SpecChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── My Bookings Tab ────────────────────────────────────

class _MyBookingsTab extends StatelessWidget {
  final List<SpinClass> classes;
  final Map<String, int> myBookings;
  final Color Function(SpinLevel) levelColor;
  final String Function(SpinLevel) levelLabel;
  final String Function(int) seatLabel;
  final void Function(SpinClass, int) onChangeSeat;
  final void Function(SpinClass) onCancel;

  const _MyBookingsTab({
    required this.classes,
    required this.myBookings,
    required this.levelColor,
    required this.levelLabel,
    required this.seatLabel,
    required this.onChangeSeat,
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
            Icon(
              Icons.event_seat_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin reservas aún',
              style: AppTextStyles.headingMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Ve a Horarios y reserva tu puesto',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
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
        final seat = myBookings[cls.id]!;
        final label = seatLabel(seat);
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
                    child: Icon(Icons.directions_bike_rounded,
                        color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cls.name, style: AppTextStyles.headingSmall),
                        const SizedBox(height: 2),
                        Text(
                          cls.time,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        Text(
                          cls.days,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
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
                        child: Text(
                          levelLabel(cls.level),
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bici $label',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                      Text(
                        '${cls.caloriesMin}–${cls.caloriesMax} kcal',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
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
                      onTap: () => onChangeSeat(cls, seat),
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
                            Text(
                              'Cambiar lugar',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: color),
                            ),
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
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error),
                            ),
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
