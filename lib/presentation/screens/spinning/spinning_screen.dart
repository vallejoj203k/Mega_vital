import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/spinning_service.dart';
import 'seat_selection_screen.dart';

// ── Color helpers ────────────────────────────────────────

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
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

// ── Main Screen ──────────────────────────────────────────

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
  final _service = SpinningService();

  List<SpinClass> _classes = [];
  List<SpinInstructor> _instructors = [];
  List<UserBooking> _myBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.loadClasses(),
      _service.loadInstructors(),
      _service.getUserBookings(),
    ]);
    if (mounted) {
      setState(() {
        _classes = results[0] as List<SpinClass>;
        _instructors = results[1] as List<SpinInstructor>;
        _myBookings = results[2] as List<UserBooking>;
        _loading = false;
      });
    }
  }

  void _openSeatSelection(SpinClass cls) async {
    final sessionDate = cls.nextSessionDate;
    final sessionId =
        await _service.getOrCreateSession(cls.id, sessionDate);
    if (!mounted) return;

    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(
          spinClass: cls,
          sessionId: sessionId,
          service: _service,
        ),
      ),
    );

    if (result != null && mounted) {
      HapticFeedback.mediumImpact();
      await _load();
      if (mounted) {
        final seatLabel =
            '${String.fromCharCode('A'.codeUnitAt(0) + result ~/ 6)}${result % 6 + 1}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bici $seatLabel reservada en ${cls.name}',
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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentOrange))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ScheduleTab(
                          classes: _classes,
                          myBookings: _myBookings,
                          service: _service,
                          onBook: _openSeatSelection,
                          onRefresh: _load,
                        ),
                        _InstructorsTab(instructors: _instructors),
                        _MyBookingsTab(
                          bookings: _myBookings,
                          service: _service,
                          onRefresh: _load,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Spinning', style: AppTextStyles.displayMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                                letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Clases profesionales de ciclismo indoor',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.schedule_rounded,
                label: 'Lun – Vie',
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                label: '400–800 kcal',
                color: AppColors.accentPurple,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.verified_rounded,
                label: 'Certificados',
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
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: [
          const Tab(text: 'Horarios'),
          const Tab(text: 'Entrenadores'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mis Reservas'),
                if (_myBookings.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_myBookings.length}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────────

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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Schedule Tab ─────────────────────────────────────────

class _ScheduleTab extends StatelessWidget {
  final List<SpinClass> classes;
  final List<UserBooking> myBookings;
  final SpinningService service;
  final void Function(SpinClass) onBook;
  final VoidCallback onRefresh;

  const _ScheduleTab({
    required this.classes,
    required this.myBookings,
    required this.service,
    required this.onBook,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(
        child: Text('No hay clases disponibles',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    final bookedClassIds = myBookings.map((b) => b.sessionId).toSet();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: classes.length,
      itemBuilder: (context, i) => _ClassCard(
        cls: classes[i],
        isBooked: false,
        service: service,
        onBook: () => onBook(classes[i]),
      ),
    );
  }
}

// ── Class Card ───────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final SpinClass cls;
  final bool isBooked;
  final SpinningService service;
  final VoidCallback onBook;

  const _ClassCard({
    required this.cls,
    required this.isBooked,
    required this.service,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(cls.level);
    final instColor = _hexColor(cls.instructor.colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBooked ? color.withOpacity(0.5) : AppColors.border,
          width: isBooked ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
          if (isBooked)
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          // ── Hero ──
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                _HeroArea(color: color, level: cls.level),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.surface.withOpacity(0.98),
                        ],
                        stops: const [0.25, 1.0],
                      ),
                    ),
                  ),
                ),
                // Next session + PRO badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.burnGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accentOrange.withOpacity(0.4),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('CLASE PRO',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              cls.nextSessionLabel,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        Icon(_levelIcon(cls.level), size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(cls.level.label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ],
                    ),
                  ),
                ),
                // Title
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.name, style: AppTextStyles.headingLarge),
                      const SizedBox(height: 2),
                      Text(
                        cls.description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                // Pills row
                Row(
                  children: [
                    _Pill(
                        icon: Icons.access_time_rounded,
                        label: '${cls.startTime} – ${cls.endTime}',
                        color: AppColors.accentBlue),
                    const SizedBox(width: 6),
                    _Pill(
                        icon: Icons.local_fire_department_rounded,
                        label: '${cls.caloriesMin}–${cls.caloriesMax} kcal',
                        color: AppColors.accentOrange),
                    const SizedBox(width: 6),
                    _Pill(
                        icon: Icons.calendar_today_rounded,
                        label: 'Lun–Vie',
                        color: AppColors.accentPurple),
                  ],
                ),
                const SizedBox(height: 12),
                // Instructor row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            instColor.withOpacity(0.3),
                            instColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: instColor.withOpacity(0.5), width: 1.5),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 20, color: instColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(cls.instructor.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded,
                                  size: 13, color: instColor),
                            ],
                          ),
                          Text(cls.instructor.specialty,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          cls.instructor.rating.toString(),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Book button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isBooked
                      ? _BookedBtn(color: color)
                      : _BookBtn(color: color, onTap: onBook),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroArea extends StatelessWidget {
  final Color color;
  final SpinLevel level;

  const _HeroArea({required this.color, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.35), AppColors.surface],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(Icons.directions_bike_rounded,
                size: 200, color: color.withOpacity(0.07)),
          ),
          Positioned(
            left: 30,
            top: 20,
            child: Row(
              children: List.generate(
                  3,
                  (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.directions_bike_rounded,
                            size: 32,
                            color: color
                                .withOpacity(i <= level.index ? 0.6 : 0.15)),
                      )),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookBtn extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _BookBtn({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat_rounded, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text('Elegir mi bici',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _BookedBtn extends StatelessWidget {
  final Color color;

  const _BookedBtn({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Text('Reservado',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Instructors Tab ──────────────────────────────────────

class _InstructorsTab extends StatelessWidget {
  final List<SpinInstructor> instructors;

  const _InstructorsTab({required this.instructors});

  @override
  Widget build(BuildContext context) {
    if (instructors.isEmpty) {
      return const Center(
          child: Text('Sin entrenadores',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: instructors.length,
      itemBuilder: (context, i) =>
          _InstructorCard(inst: instructors[i]),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  final SpinInstructor inst;

  const _InstructorCard({required this.inst});

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(inst.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Hero
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.3),
                    AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.directions_bike_rounded,
                        size: 160, color: color.withOpacity(0.07)),
                  ),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.3),
                              color.withOpacity(0.1)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.withOpacity(0.5), width: 2),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 40, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(inst.name, style: AppTextStyles.headingLarge),
                    const SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 16, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(inst.specialty,
                    style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(inst.bio,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InstructorStat(
                        icon: Icons.star_rounded,
                        value: inst.rating.toString(),
                        label: 'Rating',
                        color: AppColors.warning),
                    const SizedBox(width: 24),
                    _InstructorStat(
                        icon: Icons.directions_bike_rounded,
                        value: '${inst.totalClasses}',
                        label: 'Clases',
                        color: color),
                    const SizedBox(width: 24),
                    _InstructorStat(
                        icon: Icons.workspace_premium_rounded,
                        value: 'Cert.',
                        label: 'Certificado',
                        color: AppColors.accentPurple),
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

class _InstructorStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InstructorStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

// ── My Bookings Tab ──────────────────────────────────────

class _MyBookingsTab extends StatelessWidget {
  final List<UserBooking> bookings;
  final SpinningService service;
  final VoidCallback onRefresh;

  const _MyBookingsTab({
    required this.bookings,
    required this.service,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_seat_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Sin reservas aún',
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Ve a Horarios y elige tu bici',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: bookings.length,
      itemBuilder: (context, i) => _BookingCard(
        booking: bookings[i],
        service: service,
        onCancelled: onRefresh,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final UserBooking booking;
  final SpinningService service;
  final VoidCallback onCancelled;

  const _BookingCard({
    required this.booking,
    required this.service,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.accentOrange.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bike_rounded,
                    color: AppColors.accentOrange, size: 20),
                Text(booking.seatLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentOrange)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bici ${booking.seatLabel}',
                    style: AppTextStyles.headingSmall),
                Text(
                  booking.bookedAt.toString().substring(0, 10),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Cancelar reserva',
                      style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text(
                      '¿Deseas cancelar esta reserva?',
                      style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No',
                            style:
                                TextStyle(color: AppColors.textSecondary))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sí, cancelar',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true) {
                await service.cancelBooking(booking.id);
                onCancelled();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.error, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
