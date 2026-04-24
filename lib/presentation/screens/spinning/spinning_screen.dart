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
  final double rating;
  final int totalClasses;
  final Color color;

  const SpinInstructor({
    required this.id,
    required this.name,
    required this.specialty,
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
    rating: 4.9,
    totalClasses: 280,
    color: Color(0xFFFF6B35),
  ),
  const SpinInstructor(
    id: 'i2',
    name: 'Julio',
    specialty: 'Potencia & Ciclismo Indoor',
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
    totalSpots: 15,
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
    totalSpots: 15,
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
    totalSpots: 15,
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
  final Set<String> _myBookings = {};

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

  void _openSeatSelection(SpinClass cls) async {
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
        _myBookings.add(cls.id);
      });
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Puesto ${result + 1} reservado en ${cls.name}',
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
                  ),
                  _InstructorsTab(instructors: _instructors),
                  _MyBookingsTab(
                    classes: _classes,
                    myBookings: _myBookings,
                    levelColor: _levelColor,
                    levelLabel: _levelLabel,
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
  final Set<String> myBookings;
  final Color Function(SpinLevel) levelColor;
  final String Function(SpinLevel) levelLabel;
  final void Function(SpinClass) onBook;

  const _ScheduleTab({
    required this.classes,
    required this.myBookings,
    required this.levelColor,
    required this.levelLabel,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: classes.length,
      itemBuilder: (context, i) => _ClassCard(
        cls: classes[i],
        isBooked: myBookings.contains(classes[i].id),
        levelColor: levelColor,
        levelLabel: levelLabel,
        onBook: () => onBook(classes[i]),
      ),
    );
  }
}

// ── Class Card ─────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final SpinClass cls;
  final bool isBooked;
  final Color Function(SpinLevel) levelColor;
  final String Function(SpinLevel) levelLabel;
  final VoidCallback onBook;

  const _ClassCard({
    required this.cls,
    required this.isBooked,
    required this.levelColor,
    required this.levelLabel,
    required this.onBook,
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
                Row(
                  children: [
                    _InfoPill(
                      icon: Icons.access_time_rounded,
                      label: cls.time,
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    _InfoPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${cls.caloriesMin}–${cls.caloriesMax} kcal',
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    _InfoPill(
                      icon: Icons.timer_rounded,
                      label: '${cls.durationMinutes} min',
                      color: AppColors.accentPurple,
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
                      ? _BookedButton(color: color)
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

class _BookedButton extends StatelessWidget {
  final Color color;

  const _BookedButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            'Puesto reservado',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: instructors.length,
      itemBuilder: (context, i) => _InstructorCard(inst: instructors[i]),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  final SpinInstructor inst;

  const _InstructorCard({required this.inst});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  inst.color.withOpacity(0.3),
                  inst.color.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: inst.color.withOpacity(0.5), width: 2),
            ),
            child: Icon(Icons.person_rounded, size: 36, color: inst.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(inst.name, style: AppTextStyles.headingSmall)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_rounded, size: 10, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text('Certificado', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  inst.specialty,
                  style: TextStyle(
                      fontSize: 12,
                      color: inst.color,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.star_rounded,
                      value: inst.rating.toString(),
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      icon: Icons.directions_bike_rounded,
                      value: '${inst.totalClasses} clases',
                      color: inst.color,
                    ),
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

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── My Bookings Tab ────────────────────────────────────

class _MyBookingsTab extends StatelessWidget {
  final List<SpinClass> classes;
  final Set<String> myBookings;
  final Color Function(SpinLevel) levelColor;
  final String Function(SpinLevel) levelLabel;

  const _MyBookingsTab({
    required this.classes,
    required this.myBookings,
    required this.levelColor,
    required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final booked = classes.where((c) => myBookings.contains(c.id)).toList();
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Row(
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
                          fontSize: 12, color: AppColors.textSecondary),
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
                    '${cls.caloriesMin}–${cls.caloriesMax} kcal',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
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
