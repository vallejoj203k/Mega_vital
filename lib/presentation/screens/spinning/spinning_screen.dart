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
    name: 'Carlos Mendoza',
    specialty: 'HIIT & Resistencia',
    rating: 4.9,
    totalClasses: 312,
    color: Color(0xFFFF6B35),
  ),
  const SpinInstructor(
    id: 'i2',
    name: 'Laura Gómez',
    specialty: 'Ritmo & Cardio',
    rating: 4.8,
    totalClasses: 248,
    color: Color(0xFF4FC3F7),
  ),
  const SpinInstructor(
    id: 'i3',
    name: 'Diego Vargas',
    specialty: 'Potencia & Fuerza',
    rating: 4.7,
    totalClasses: 189,
    color: Color(0xFFBB86FC),
  ),
];

List<SpinClass> _buildClasses() => [
  SpinClass(
    id: 'c1',
    name: 'Morning Burn',
    instructor: _instructors[0],
    level: SpinLevel.basico,
    time: '06:00 AM',
    days: 'Lun · Mié · Vie',
    durationMinutes: 60,
    caloriesMin: 400,
    caloriesMax: 550,
    totalSpots: 20,
    bookedSpots: 0,
  ),
  SpinClass(
    id: 'c2',
    name: 'Power Cycle',
    instructor: _instructors[2],
    level: SpinLevel.avanzado,
    time: '07:30 AM',
    days: 'Mar · Jue · Sáb',
    durationMinutes: 60,
    caloriesMin: 600,
    caloriesMax: 800,
    totalSpots: 20,
    bookedSpots: 0,
  ),
  SpinClass(
    id: 'c3',
    name: 'Rhythm Ride',
    instructor: _instructors[1],
    level: SpinLevel.intermedio,
    time: '12:00 PM',
    days: 'Lun · Mar · Mié · Jue · Vie',
    durationMinutes: 60,
    caloriesMin: 500,
    caloriesMax: 650,
    totalSpots: 20,
    bookedSpots: 0,
  ),
  SpinClass(
    id: 'c4',
    name: 'Evening Flow',
    instructor: _instructors[1],
    level: SpinLevel.basico,
    time: '06:00 PM',
    days: 'Lun · Mié · Vie',
    durationMinutes: 60,
    caloriesMin: 380,
    caloriesMax: 500,
    totalSpots: 20,
    bookedSpots: 0,
  ),
  SpinClass(
    id: 'c5',
    name: 'Night HIIT',
    instructor: _instructors[0],
    level: SpinLevel.intermedio,
    time: '07:30 PM',
    days: 'Mar · Jue',
    durationMinutes: 60,
    caloriesMin: 550,
    caloriesMax: 700,
    totalSpots: 20,
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
        return 'Básico';
      case SpinLevel.intermedio:
        return 'Intermedio';
      case SpinLevel.avanzado:
        return 'Avanzado';
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
    final todayClasses =
        _classes.where((c) => c.availableSpots > 0).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentOrange.withOpacity(0.15),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.burnGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_bike_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spinning', style: AppTextStyles.displayMedium),
                  Text(
                    'Ciclismo indoor de alta intensidad',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatChip(
                icon: Icons.calendar_today_rounded,
                label: '$todayClasses clases hoy',
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
                // Booked badge
                if (isBooked)
                  Positioned(
                    top: 12,
                    right: 12,
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
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            'Reservado',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                        ],
                      ),
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
              children: [
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
                      label:
                          '${cls.caloriesMin}–${cls.caloriesMax} kcal',
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
                Text(inst.name, style: AppTextStyles.headingSmall),
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
