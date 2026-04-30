// lib/presentation/screens/home/home_screen.dart
// Todo calculado con los datos reales del usuario logueado.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/nav_provider.dart';
import '../../../core/providers/nutrition_provider.dart';
import '../../../core/providers/weight_provider.dart';
import '../../../core/providers/workout_log_provider.dart';
import '../../../services/fitness_calculator.dart';
import '../../../services/workout_log_service.dart';
import '../../widgets/shared_widgets.dart';
import '../progress/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── Estado local del día ──────────────────────────────────────
  int  _vasos              = 0;
  bool _monthlyDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionProvider>().loadToday();
      context.read<WeightProvider>().load().then((_) {
        if (!mounted || _monthlyDialogShown) return;
        if (context.read<WeightProvider>().needsMonthlyUpdate) {
          _monthlyDialogShown = true;
          _showWeightUpdateDialog();
        }
      });
    });
  }

  void _showWeightUpdateDialog() {
    final profile = context.read<AuthProvider>().profile;
    final initial = context.read<WeightProvider>().latest?.weight
        ?? profile?.weight
        ?? 70.0;
    double draft = initial;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.monitor_weight_outlined,
                color: AppColors.accentOrange, size: 22),
            const SizedBox(width: 10),
            Text(
              context.read<WeightProvider>().history.isEmpty
                  ? 'Registra tu peso inicial'
                  : 'Actualiza tu peso mensual',
              style: AppTextStyles.headingSmall,
            ),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              context.read<WeightProvider>().history.isEmpty
                  ? 'Registra tu peso para comenzar a ver tu progreso.'
                  : 'Han pasado más de 30 días. Registra tu peso actual para mantener el seguimiento.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _DialogAdjBtn(
                icon: Icons.remove_rounded,
                onTap: () => setDlg(() =>
                    draft = double.parse(
                        (draft - 0.1).clamp(30.0, 250.0)
                            .toStringAsFixed(1))),
              ),
              const SizedBox(width: 16),
              Column(children: [
                Text(draft.toStringAsFixed(1),
                    style: AppTextStyles.headingLarge
                        .copyWith(color: AppColors.accentOrange)),
                Text('kg', style: AppTextStyles.caption),
              ]),
              const SizedBox(width: 16),
              _DialogAdjBtn(
                icon: Icons.add_rounded,
                onTap: () => setDlg(() =>
                    draft = double.parse(
                        (draft + 0.1).clamp(30.0, 250.0)
                            .toStringAsFixed(1))),
              ),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Ahora no',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<WeightProvider>().addEntry(draft);
              },
              child: const Text('Guardar',
                  style: TextStyle(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fecha real ────────────────────────────────────────────────
  String get _fechaHoy {
    final d = DateTime.now();
    const dias  = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const meses = ['enero','febrero','marzo','abril','mayo','junio',
                   'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  }

  // ── Saludo dinámico ────────────────────────────────────────────
  String get _saludo {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12)  return 'Buenos días';
    if (h >= 12 && h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  IconData get _saludoIcon {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12)  return Icons.wb_sunny_rounded;
    if (h >= 12 && h < 19) return Icons.wb_cloudy_rounded;
    return Icons.bedtime_rounded;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth    = context.watch<AuthProvider>();
    final profile = auth.profile;

    if (profile == null) {
      if (auth.profileLoading) return const _LoadingHome();
      return _ErrorHome(onRetry: () => context.read<AuthProvider>().reloadProfile());
    }

    final calc = FitnessCalculator(
      weight: profile.weight,
      height: profile.height,
      age:    profile.age,
      goal:   profile.goal,
    );

    final nutrition = context.watch<NutritionProvider>();
    // Macros reales del día desde NutritionProvider
    final _calHoy    = nutrition.totalCalories.toDouble();
    final _protHoy   = nutrition.totalProtein;
    final _carbsHoy  = nutrition.totalCarbs;
    final _grasasHoy = nutrition.totalFat;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Top bar ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _TopBar(
                nombre:     profile.name,
                iniciales:  auth.userInitials,
                photoUrl:   profile.avatarUrl,
                saludo:     _saludo,
                saludoIcon: _saludoIcon,
                fecha:      _fechaHoy,
                streak:     0,
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Bienvenida personalizada ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WelcomeCard(
                nombre:        profile.name,
                meta:          profile.goal,
                calQuemadas:   380,
                metaCalorias:  calc.metaCalorias,
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Entrenamiento del día ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WorkoutOfDay(),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Último entrenamiento ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _LastWorkout(),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Stats rápidas del día (calculadas) ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Resumen de hoy'),
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: SizedBox(height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accentOrange,
                    label: 'Calorías',
                    value: _calHoy.toInt().toString(),
                    unit: 'kcal',
                    progress: _calHoy / calc.metaCalorias,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    label: 'Proteínas',
                    value: _protHoy.toInt().toString(),
                    unit: 'g',
                    progress: _protHoy / calc.metaProteina,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.water_drop_rounded,
                    color: AppColors.accentBlue,
                    label: 'Agua',
                    value: (_vasos * 0.25).toStringAsFixed(1),
                    unit: 'L',
                    progress: _vasos / calc.metaVasos,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Anillo de macros (con metas reales) ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MacrosRing(
                calHoy:   _calHoy,
                protHoy:  _protHoy,
                carbsHoy: _carbsHoy,
                grasHoy:  _grasasHoy,
                calc:     calc,
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Tracker de agua (meta calculada) ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WaterTracker(
                vasos:      _vasos,
                metaVasos:  calc.metaVasos,
                metaLitros: calc.metaLitros,
                onAdd: () {
                  if (_vasos < calc.metaVasos) {
                    HapticFeedback.lightImpact();
                    setState(() => _vasos++);
                  }
                },
                onRemove: () {
                  if (_vasos > 0) {
                    HapticFeedback.lightImpact();
                    setState(() => _vasos--);
                  }
                },
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Barras de progreso (metas reales) ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DailyProgress(
                calHoy:    _calHoy,
                vasos:     _vasos,
                calc:      calc,
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Gráfica de progreso de peso ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WeightChart(),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Frase motivacional ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MotivationCard(),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Acciones rápidas ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Acciones rápidas'),
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _QuickActions(),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Progreso semanal ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WeeklyProgress(),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS INTERNOS
// ─────────────────────────────────────────────────────────────────

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.background,
    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}

class _ErrorHome extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorHome({required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 16),
      Text('No se pudo cargar tu perfil',
          style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      Text('Verifica tu conexión y vuelve a intentarlo.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Reintentar',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.background)),
        ),
      ),
    ])),
  );
}

// ── Top bar ───────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String nombre, iniciales, saludo, fecha;
  final String? photoUrl;
  final IconData saludoIcon;
  final int streak;
  const _TopBar({required this.nombre, required this.iniciales,
    required this.saludo, required this.saludoIcon, required this.fecha,
    required this.streak, this.photoUrl});

  @override
  Widget build(BuildContext context) => Row(children: [
    InitialsAvatar(initials: iniciales, photoUrl: photoUrl),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(saludoIcon, size: 12, color: AppColors.accentOrange),
          const SizedBox(width: 4),
          Text(saludo, style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary)),
        ]),
        Text(nombre, style: AppTextStyles.headingSmall,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 1),
        Text(fecha, style: AppTextStyles.caption
            .copyWith(color: AppColors.textMuted, fontSize: 11)),
      ],
    )),
    StreakBadge(days: streak),
    const SizedBox(width: 10),
    GestureDetector(
      onTap: () {},
      child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: const Icon(Icons.notifications_outlined,
              color: AppColors.textSecondary, size: 20)),
    ),
  ]);
}

// ── Tarjeta de bienvenida ──────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String nombre, meta;
  final int calQuemadas, metaCalorias;
  const _WelcomeCard({required this.nombre, required this.meta,
    required this.calQuemadas, required this.metaCalorias});

  String get _primerNombre => nombre.trim().split(' ').first;

  @override
  Widget build(BuildContext context) => DarkCard(
    padding: const EdgeInsets.all(20),
    gradient: const LinearGradient(
        colors: [Color(0xFF0F2318), Color(0xFF0A1A10)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    borderColor: AppColors.primary.withOpacity(0.2),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meta: $meta', style: AppTextStyles.neonLabel),
          const SizedBox(height: 6),
          RichText(text: TextSpan(children: [
            TextSpan(text: 'Hola, $_primerNombre\n',
                style: AppTextStyles.headingLarge.copyWith(height: 1.3)),
            TextSpan(text: '¡A darle hoy!',
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.primary, height: 1.3)),
          ])),
          const SizedBox(height: 14),
          NeonButton(
              label: 'Iniciar entrenamiento',
              icon: Icons.play_arrow_rounded,
              onTap: () => context.read<NavProvider>().goTo(1)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ProgressScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.3),
                    width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      color: AppColors.accentPurple, size: 16),
                  const SizedBox(width: 8),
                  Text('Ver progreso',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
          ),
        ],
      )),
      const SizedBox(width: 14),
      // Círculo con calorías quemadas vs meta
      _CalCircle(quemadas: calQuemadas, meta: metaCalorias),
    ]),
  );
}

class _CalCircle extends StatelessWidget {
  final int quemadas, meta;
  const _CalCircle({required this.quemadas, required this.meta});

  @override
  Widget build(BuildContext context) {
    final pct = (quemadas / meta).clamp(0.0, 1.0);
    return SizedBox(width: 80, height: 80,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size(80, 80),
            painter: _CirclePainter(progress: pct)),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.primary, size: 18),
          Text(quemadas.toString(),
              style: AppTextStyles.statNumber.copyWith(fontSize: 16)),
          Text('kcal', style: AppTextStyles.caption),
        ]),
      ]),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  const _CirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke);
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
          -math.pi / 2, 2 * math.pi * progress, false,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF00FF87), Color(0xFF00CC6A)],
            ).createShader(Rect.fromCircle(center: c, radius: r))
            ..strokeWidth = 5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter o) => o.progress != progress;
}

// ── Entrenamiento del día ──────────────────────────────────────────
// ── Entrenamiento del día (datos reales) ──────────────────────────
class _WorkoutOfDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutLogProvider>();
    final today    = provider.todaySessions;

    // Si hay sesión activa, mostrar estado "en curso"
    if (provider.hasActiveSession) {
      final active = provider.activeSession!;
      return DarkCard(
        padding: const EdgeInsets.all(16),
        gradient: const LinearGradient(
            colors: [Color(0xFF0F1F0A), Color(0xFF081208)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderColor: AppColors.primary.withOpacity(0.4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Pill(label: 'En curso',
                icon: Icons.circle, color: AppColors.primary),
            const Spacer(),
            Text('${provider.currentDurationMinutes} min',
                style: AppTextStyles.caption),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            BoxedIcon(icon: Icons.fitness_center_rounded,
                color: AppColors.primary, size: 48),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(active.name, style: AppTextStyles.headingSmall),
              const SizedBox(height: 4),
              Text('${active.exercises.length} ejercicios · '
                  '${active.totalDoneSets} series hechas',
                  style: AppTextStyles.caption),
            ])),
            GestureDetector(
              onTap: () => context.read<NavProvider>().goTo(1),
              child: Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8)],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.background, size: 20)),
            ),
          ]),
        ]),
      );
    }

    // Si ya entrenó hoy
    if (today.isNotEmpty) {
      final lastToday = today.first;
      return DarkCard(
        padding: const EdgeInsets.all(16),
        gradient: const LinearGradient(
            colors: [Color(0xFF0F1F0A), Color(0xFF081208)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderColor: AppColors.primary.withOpacity(0.25),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Pill(label: 'Completado hoy',
                icon: Icons.check_circle_rounded, color: AppColors.primary),
            const Spacer(),
            Text('${today.length} sesión${today.length > 1 ? "es" : ""}',
                style: AppTextStyles.caption),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            BoxedIcon(icon: Icons.fitness_center_rounded,
                color: AppColors.primary, size: 48),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(lastToday.name, style: AppTextStyles.headingSmall),
              const SizedBox(height: 4),
              Text('${lastToday.durationMinutes} min  ·  '
                  '${lastToday.totalDoneSets} series  ·  '
                  '${lastToday.totalVolume > 0 ? "${lastToday.totalVolume.toStringAsFixed(0)} kg" : "—"}',
                  style: AppTextStyles.caption),
            ])),
          ]),
        ]),
      );
    }

    // Sin entrenamiento hoy — estado vacío motivacional
    final w = MockData.workouts.first;
    return DarkCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
          colors: [Color(0xFF0C1F2E), Color(0xFF081218)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderColor: AppColors.accentBlue.withOpacity(0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Pill(label: 'Entrenamiento del día',
              icon: Icons.today_rounded, color: AppColors.accentBlue),
          const Spacer(),
          Text('Recomendado', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          BoxedIcon(icon: w.icon, color: w.color, size: 48),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(w.name, style: AppTextStyles.headingSmall),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.timer_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${w.durationMinutes} min', style: AppTextStyles.caption),
                const SizedBox(width: 10),
                const Icon(Icons.local_fire_department_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${w.calories} kcal', style: AppTextStyles.caption),
              ]),
              const SizedBox(height: 6),
              DifficultyChip(difficulty: w.difficulty),
            ],
          )),
          GestureDetector(
            onTap: () => context.read<NavProvider>().goTo(1),
            child: Container(width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.background, size: 22)),
          ),
        ]),
      ]),
    );
  }
}

// ── Último entrenamiento (datos reales) ───────────────────────────
class _LastWorkout extends StatelessWidget {
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60)   return 'Hace ${diff.inMinutes} min';
    if (diff.inHours   < 24)   return 'Hace ${diff.inHours}h';
    if (diff.inDays    == 1)   return 'Ayer';
    if (diff.inDays    <= 6)   return 'Hace ${diff.inDays} días';
    return 'Hace ${(diff.inDays / 7).floor()} semana(s)';
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<WorkoutLogProvider>();
    final completed = provider.history.where((s) => s.isCompleted).toList();

    // Sin historial real: mostrar mock
    if (completed.isEmpty) {
      final w = MockData.workouts[1];
      return DarkCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          BoxedIcon(icon: w.icon, color: w.color, size: 42),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Último entrenamiento', style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(w.name, style: AppTextStyles.labelLarge),
              const SizedBox(height: 3),
              Text('¡Registra tu primer entrenamiento!',
                  style: AppTextStyles.caption),
            ],
          )),
        ]),
      );
    }

    final last = completed.first;
    final vol  = last.totalVolume;
    final volStr = vol > 0
        ? (vol >= 1000
            ? '${(vol / 1000).toStringAsFixed(1)}t'
            : '${vol.toStringAsFixed(0)} kg')
        : null;

    return DarkCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        BoxedIcon(icon: Icons.fitness_center_rounded,
            color: AppColors.primary, size: 42),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Último entrenamiento', style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(last.name, style: AppTextStyles.labelLarge,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(child: Text(
                [
                  _timeAgo(last.date),
                  if (last.durationMinutes > 0) '${last.durationMinutes} min',
                  if (volStr != null) volStr,
                ].join('  ·  '),
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )),
            ]),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _Pill(label: 'Completado',
              icon: Icons.check_circle_rounded, color: AppColors.primary),
          const SizedBox(height: 6),
          Text('${last.totalDoneSets} series',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

// ── Anillo de macros con metas reales ──────────────────────────────
class _MacrosRing extends StatelessWidget {
  final double calHoy, protHoy, carbsHoy, grasHoy;
  final FitnessCalculator calc;
  const _MacrosRing({required this.calHoy, required this.protHoy,
    required this.carbsHoy, required this.grasHoy, required this.calc});

  @override
  Widget build(BuildContext context) {
    final totalReal = protHoy * 4 + carbsHoy * 4 + grasHoy * 9;
    return DarkCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Macros del día', style: AppTextStyles.headingSmall),
          const Spacer(),
          Text('Meta: ${calc.metaCalorias} kcal',
              style: AppTextStyles.neonLabel.copyWith(fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          // Anillo
          SizedBox(width: 110, height: 110,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(size: const Size(110, 110),
                painter: _MacroPainter(
                  pRatio: totalReal > 0 ? (protHoy * 4) / totalReal : 0,
                  cRatio: totalReal > 0 ? (carbsHoy * 4) / totalReal : 0,
                  fRatio: totalReal > 0 ? (grasHoy * 9) / totalReal : 0,
                ),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(calHoy.toInt().toString(),
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 22)),
                Text('kcal', style: AppTextStyles.caption),
                Text('/ ${calc.metaCalorias}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted, fontSize: 10)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(children: [
            _MacroRow(label: 'Proteínas', actual: protHoy,
                meta: calc.metaProteina, color: AppColors.primary,
                icon: Icons.fitness_center_rounded),
            const SizedBox(height: 10),
            _MacroRow(label: 'Carbohidratos', actual: carbsHoy,
                meta: calc.metaCarbos, color: AppColors.accentBlue,
                icon: Icons.bolt_rounded),
            const SizedBox(height: 10),
            _MacroRow(label: 'Grasas', actual: grasHoy,
                meta: calc.metaGrasas, color: AppColors.accentOrange,
                icon: Icons.eco_rounded),
          ])),
        ]),
      ],
    ));
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double actual, meta;
  final Color color;
  final IconData icon;
  const _MacroRow({required this.label, required this.actual,
    required this.meta, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final pct = (actual / meta).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        Text('${actual.toInt()} / ${meta.toInt()} g',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 4),
      NeonProgressBar(
        progress: pct,
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.55)]),
        height: 5, showGlow: false,
      ),
    ]);
  }
}

class _MacroPainter extends CustomPainter {
  final double pRatio, cRatio, fRatio;
  const _MacroPainter(
      {required this.pRatio, required this.cRatio, required this.fRatio});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - sw * 2) / 2;
    const gap = 0.04;
    const start = -math.pi / 2;

    canvas.drawCircle(center, radius, Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke);

    double cur = start;
    for (final seg in [
      (pRatio, const Color(0xFF00FF87)),
      (cRatio, const Color(0xFF4FC3F7)),
      (fRatio, const Color(0xFFFF6B35)),
    ]) {
      if (seg.$1 <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        cur + gap / 2, 2 * math.pi * seg.$1 - gap, false,
        Paint()
          ..color = seg.$2
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      cur += 2 * math.pi * seg.$1;
    }
  }

  @override
  bool shouldRepaint(_MacroPainter o) => false;
}

// ── Tracker de agua con meta calculada ────────────────────────────
class _WaterTracker extends StatelessWidget {
  final int vasos, metaVasos;
  final double metaLitros;
  final VoidCallback onAdd, onRemove;
  const _WaterTracker({required this.vasos, required this.metaVasos,
    required this.metaLitros, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final litrosHoy = (vasos * 0.25);
    final completo  = vasos >= metaVasos;
    return DarkCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.water_drop_rounded,
              size: 16, color: AppColors.accentBlue),
          const SizedBox(width: 8),
          Text('Agua', style: AppTextStyles.headingSmall),
          const Spacer(),
          RichText(text: TextSpan(children: [
            TextSpan(text: litrosHoy.toStringAsFixed(2),
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.accentBlue)),
            TextSpan(text: ' / ${metaLitros.toStringAsFixed(1)} L',
                style: AppTextStyles.caption),
          ])),
        ]),
        const SizedBox(height: 6),
        Text('Meta calculada: $metaVasos vasos para tu peso',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 12),
        // Vasos visuales (máx 12 en pantalla para no desbordar)
        Wrap(spacing: 7, runSpacing: 7,
          children: List.generate(metaVasos.clamp(1, 14), (i) {
            final lleno = i < vasos;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28, height: 34,
              decoration: BoxDecoration(
                color: lleno
                    ? AppColors.accentBlue.withOpacity(0.2)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: lleno
                      ? AppColors.accentBlue.withOpacity(0.5)
                      : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Icon(
                lleno ? Icons.water_drop_rounded
                    : Icons.water_drop_outlined,
                size: 14,
                color: lleno ? AppColors.accentBlue : AppColors.textMuted,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        NeonProgressBar(progress: vasos / metaVasos,
            gradient: AppColors.waterGradient, height: 6),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(onTap: onRemove,
              child: Container(height: 40,
                  decoration: BoxDecoration(color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5)),
                  child: const Icon(Icons.remove_rounded,
                      color: AppColors.textSecondary, size: 20)))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: GestureDetector(onTap: onAdd,
              child: Container(height: 40,
                decoration: BoxDecoration(
                  gradient: completo ? null : AppColors.waterGradient,
                  color: completo
                      ? AppColors.primary.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: completo ? null : [BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.25),
                      blurRadius: 8)],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          completo ? Icons.check_circle_rounded : Icons.add_rounded,
                          color: completo ? AppColors.primary : Colors.white,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(
                          completo ? 'Meta cumplida' : '+1 vaso (250 ml)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: completo ? AppColors.primary : Colors.white)),
                    ]),
              ))),
        ]),
      ],
    ));
  }
}

// ── Barras de progreso con metas reales ───────────────────────────
class _DailyProgress extends StatelessWidget {
  final double calHoy;
  final int vasos;
  final FitnessCalculator calc;
  const _DailyProgress({required this.calHoy, required this.vasos,
    required this.calc});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ProgressItem('Calorías',
          '${calHoy.toInt()} kcal', '${calc.metaCalorias} kcal',
          calHoy / calc.metaCalorias,
          AppColors.burnGradient, Icons.local_fire_department_rounded,
          AppColors.accentOrange),
      _ProgressItem('Agua',
          '${(vasos * 0.25).toStringAsFixed(1)} L',
          '${calc.metaLitros.toStringAsFixed(1)} L',
          vasos / calc.metaVasos,
          AppColors.waterGradient, Icons.water_drop_rounded,
          AppColors.accentBlue),
      _ProgressItem('Sueño',
          '7h 20m', '8h',
          0.92,
          AppColors.primaryGradient, Icons.bedtime_rounded,
          AppColors.primary),
    ];
    return DarkCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progreso del día', style: AppTextStyles.headingSmall),
        const SizedBox(height: 14),
        ...items.map((it) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(it.icon, size: 13, color: it.color),
                    const SizedBox(width: 5),
                    Text(it.label, style: AppTextStyles.labelMedium),
                  ]),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: it.actual,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.textPrimary)),
                    TextSpan(text: ' / ${it.meta}',
                        style: AppTextStyles.caption),
                  ])),
                ],
              ),
              const SizedBox(height: 7),
              NeonProgressBar(
                  progress: it.progress.clamp(0.0, 1.0),
                  gradient: it.gradient, height: 7),
            ],
          ),
        )),
      ],
    ));
  }
}

class _ProgressItem {
  final String label, actual, meta;
  final double progress;
  final Gradient gradient;
  final IconData icon;
  final Color color;
  const _ProgressItem(this.label, this.actual, this.meta, this.progress,
      this.gradient, this.icon, this.color);
}

// ── Gráfica de progreso de peso ────────────────────────────────────
class _WeightChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WeightProvider>();

    return DarkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monitor_weight_outlined,
              size: 16, color: AppColors.accentOrange),
          const SizedBox(width: 8),
          Text('Progreso de peso', style: AppTextStyles.headingSmall),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddDialog(context, prov),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.accentOrange.withOpacity(0.35),
                    width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded,
                    color: AppColors.accentOrange, size: 14),
                const SizedBox(width: 4),
                Text('Registrar',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 11)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        if (prov.isLoading)
          const SizedBox(height: 120,
              child: Center(child: CircularProgressIndicator(
                  color: AppColors.accentOrange, strokeWidth: 2)))
        else if (prov.history.isEmpty)
          _EmptyWeight(onAdd: () => _showAddDialog(context, prov))
        else ...[
          // Peso actual + tendencia
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            RichText(text: TextSpan(children: [
              TextSpan(
                  text: prov.latest!.weight.toStringAsFixed(1),
                  style: AppTextStyles.headingLarge
                      .copyWith(color: AppColors.accentOrange, fontSize: 32)),
              TextSpan(text: ' kg', style: AppTextStyles.caption),
            ])),
            const SizedBox(width: 10),
            if (prov.trend != null) ...[
              Icon(
                prov.trend! < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                color: prov.trend! < 0
                    ? AppColors.primary
                    : AppColors.accentOrange,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${prov.trend! >= 0 ? "+" : ""}${prov.trend!.toStringAsFixed(1)} kg',
                style: AppTextStyles.caption.copyWith(
                  color: prov.trend! < 0
                      ? AppColors.primary
                      : AppColors.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Spacer(),
            Text('Último: ${_formatDate(prov.latest!.recordedAt)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted, fontSize: 10)),
          ]),
          const SizedBox(height: 16),

          // Línea de gráfica
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _WeightLinePainter(
                // El painter espera de menor a mayor (cronológico)
                entries: prov.history.reversed.toList(),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  String _formatDate(DateTime d) {
    const meses = ['ene','feb','mar','abr','may','jun',
                   'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${meses[d.month - 1]}';
  }

  void _showAddDialog(BuildContext context, WeightProvider prov) {
    double draft = prov.latest?.weight ?? 70.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.monitor_weight_outlined,
                color: AppColors.accentOrange, size: 22),
            const SizedBox(width: 10),
            Text('Registrar peso', style: AppTextStyles.headingSmall),
          ]),
          content: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            _DialogAdjBtn(
              icon: Icons.remove_rounded,
              onTap: () => setDlg(() => draft = double.parse(
                  (draft - 0.1).clamp(30.0, 250.0).toStringAsFixed(1))),
            ),
            const SizedBox(width: 20),
            Column(children: [
              Text(draft.toStringAsFixed(1),
                  style: AppTextStyles.headingLarge
                      .copyWith(color: AppColors.accentOrange)),
              Text('kg', style: AppTextStyles.caption),
            ]),
            const SizedBox(width: 20),
            _DialogAdjBtn(
              icon: Icons.add_rounded,
              onTap: () => setDlg(() => draft = double.parse(
                  (draft + 0.1).clamp(30.0, 250.0).toStringAsFixed(1))),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await prov.addEntry(draft);
              },
              child: const Text('Guardar',
                  style: TextStyle(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWeight extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyWeight({required this.onAdd});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 100,
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monitor_weight_outlined,
            color: AppColors.textMuted, size: 32),
        const SizedBox(height: 8),
        Text('Sin registros aún',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onAdd,
          child: Text('+ Registrar primer peso',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.accentOrange,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );
}

class _DialogAdjBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DialogAdjBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 18),
    ),
  );
}

class _WeightLinePainter extends CustomPainter {
  final List<WeightEntry> entries; // cronológico: el primero es el más antiguo
  const _WeightLinePainter({required this.entries});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) {
      // Un solo punto — dibuja un círculo centrado
      if (entries.isEmpty) return;
      final paint = Paint()
        ..color = AppColors.accentOrange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2), 5, paint);
      return;
    }

    final weights = entries.map((e) => e.weight).toList();
    final minW    = weights.reduce((a, b) => a < b ? a : b) - 1.5;
    final maxW    = weights.reduce((a, b) => a > b ? a : b) + 1.5;
    final range   = (maxW - minW).clamp(1.0, double.infinity);

    final n       = entries.length;
    final xStep   = size.width / (n - 1);
    const yPad    = 18.0; // espacio para etiquetas

    Offset toOffset(int i) {
      final x = i * xStep;
      final y = yPad + (1 - (weights[i] - minW) / range) *
          (size.height - yPad * 2);
      return Offset(x, y);
    }

    final points = List.generate(n, toOffset);

    // Relleno degradado bajo la línea
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accentOrange.withOpacity(0.25),
            AppColors.accentOrange.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Línea
    final linePaint = Paint()
      ..color = AppColors.accentOrange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Puntos y etiquetas de peso
    final dotPaint  = Paint()..color = AppColors.accentOrange;
    final bgPaint   = Paint()..color = AppColors.surface;
    final textStyle = const TextStyle(
        fontSize: 9, color: AppColors.textSecondary,
        fontWeight: FontWeight.w600);
    const meses = ['ene','feb','mar','abr','may','jun',
                   'jul','ago','sep','oct','nov','dic'];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];

      // Punto con borde blanco
      canvas.drawCircle(p, 5, bgPaint);
      canvas.drawCircle(p, 4, dotPaint);

      // Etiqueta de peso encima del punto (solo primero, último y cada 2)
      if (i == 0 || i == points.length - 1 || (n <= 6)) {
        final label = weights[i].toStringAsFixed(1);
        final tp = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset(p.dx - tp.width / 2, p.dy - tp.height - 5));
      }

      // Etiqueta de fecha debajo del eje (solo primero, último y cada 2)
      if (i == 0 || i == points.length - 1 || (n <= 6)) {
        final d   = entries[i].recordedAt;
        final lbl = '${d.day} ${meses[d.month - 1]}';
        final tp  = TextPainter(
          text: TextSpan(
              text: lbl,
              style: textStyle.copyWith(color: AppColors.textMuted)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset(
              (p.dx - tp.width / 2).clamp(0, size.width - tp.width),
              size.height - tp.height,
            ));
      }
    }
  }

  @override
  bool shouldRepaint(_WeightLinePainter old) => old.entries != entries;
}

// ── Frase motivacional ─────────────────────────────────────────────
class _MotivationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DarkCard(
    gradient: const LinearGradient(
        colors: [Color(0xFF1A0F0A), Color(0xFF120A06)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    borderColor: AppColors.accentOrange.withOpacity(0.25),
    child: Row(children: [
      BoxedIcon(icon: Icons.lightbulb_outline_rounded,
          color: AppColors.accentOrange),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Motivación del día', style: AppTextStyles.caption.copyWith(
              color: AppColors.accentOrange, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(MockData.motivationalQuotes[0],
              style: AppTextStyles.bodyMedium
                  .copyWith(fontStyle: FontStyle.italic, height: 1.4)),
        ],
      )),
    ]),
  );
}

// ── Acciones rápidas ───────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // (icon, label, color, tabIndex or -1 for progress screen)
    final items = [
      (Icons.fitness_center_rounded,  'Entreno',  AppColors.primary,      1),
      (Icons.restaurant_menu_rounded, 'Comida',   AppColors.accentBlue,   2),
      (Icons.monitor_weight_outlined, 'Peso',     AppColors.accentOrange, 4),
      (Icons.bar_chart_rounded,       'Progreso', AppColors.accentPurple, -1),
    ];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((a) => GestureDetector(
        onTap: () {
          if (a.$4 == -1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProgressScreen()),
            );
          } else {
            context.read<NavProvider>().goTo(a.$4);
          }
        },
        child: DarkCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(children: [
            BoxedIcon(icon: a.$1, color: a.$3),
            const SizedBox(height: 8),
            Text(a.$2, style: AppTextStyles.caption.copyWith(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
          ]),
        ),
      )).toList(),
    );
  }
}

// ── Progreso semanal ───────────────────────────────────────────────
class _WeeklyProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final log    = context.watch<WorkoutLogProvider>();
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonday = DateTime(monday.year, monday.month, monday.day);
    final todayStart    = DateTime(now.year, now.month, now.day);

    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    final days = List.generate(7, (i) {
      final dayStart = startOfMonday.add(Duration(days: i));
      final dayEnd   = dayStart.add(const Duration(days: 1));
      final isFuture = dayStart.isAfter(todayStart);
      final isToday  = dayStart == todayStart;

      double progress = 0.0;
      if (!isFuture) {
        final sessions = log.history.where((s) =>
          s.isCompleted &&
          !s.date.isBefore(dayStart) &&
          s.date.isBefore(dayEnd),
        ).length;
        if (sessions > 0) progress = 1.0;
      }

      return (label: labels[i], progress: progress, isToday: isToday);
    });

    return DarkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Esta semana',
            actionLabel: 'Ver todo', onAction: () {}),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((d) => Column(children: [
            Container(width: 32, height: 60,
              decoration: BoxDecoration(color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.antiAlias,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                // Entrenado → barra llena; hoy sin entreno → marca mínima; resto → 0
                height: d.progress > 0 ? 60 : (d.isToday ? 4 : 0),
                decoration: BoxDecoration(
                  gradient: d.isToday
                      ? AppColors.primaryGradient
                      : LinearGradient(colors: [
                          AppColors.textMuted.withOpacity(0.6),
                          AppColors.textMuted.withOpacity(0.4),
                        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(d.label, style: TextStyle(
              fontSize: 11,
              fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w400,
              color: d.isToday ? AppColors.primary : AppColors.textMuted,
            )),
          ])).toList(),
        ),
      ],
    ));
  }
}

// ── Stat card ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value, unit;
  final double progress;
  const _StatCard({required this.icon, required this.color, required this.label,
    required this.value, required this.unit, required this.progress});

  @override
  Widget build(BuildContext context) => DarkCard(
    padding: const EdgeInsets.all(14),
    child: SizedBox(width: 130, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 20),
          Text('${(progress.clamp(0.0, 1.0) * 100).toInt()}%',
              style: AppTextStyles.neonLabel
                  .copyWith(fontSize: 11, color: color)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: value,
                style: AppTextStyles.statNumber.copyWith(fontSize: 22)),
            TextSpan(text: ' $unit', style: AppTextStyles.statUnit),
          ])),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          NeonProgressBar(
              progress: progress.clamp(0.0, 1.0),
              gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)]),
              height: 4),
        ]),
      ],
    )),
  );
}

// ── Pill badge ─────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Pill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4), width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}