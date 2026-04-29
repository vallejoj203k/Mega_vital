// lib/presentation/screens/progress/progress_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/workout_log_provider.dart';
import '../../../services/workout_log_service.dart';
import '../../widgets/shared_widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Métricas posibles a visualizar
  static const _metrics = ['Peso máx.', 'Volumen'];
  int _metricIdx = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = context.watch<WorkoutLogProvider>();
    final completed =
        log.history.where((s) => s.isCompleted).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    // Agrupar por ejercicio → lista de (fecha, maxWeight, volumen)
    final Map<String, _ExerciseData> byExercise = {};
    for (final session in completed) {
      for (final ex in session.exercises) {
        final doneSets = ex.sets.where((s) => s.isDone).toList();
        if (doneSets.isEmpty) continue;
        byExercise.putIfAbsent(
          ex.exerciseName,
          () => _ExerciseData(name: ex.exerciseName, muscle: ex.muscleId),
        );
        byExercise[ex.exerciseName]!.points.add(_DataPoint(
          date: session.date,
          maxWeight: ex.maxWeight,
          volume: ex.totalVolume,
        ));
      }
    }

    final exercises = byExercise.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi Progreso',
                          style: AppTextStyles.headingLarge),
                      Text('Evolución por ejercicio',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Selector de métrica ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: List.generate(_metrics.length, (i) {
                    final selected = i == _metricIdx;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _metricIdx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _metrics[i],
                            style: AppTextStyles.caption.copyWith(
                              color: selected
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Resumen global ──────────────────────────────────────
            if (completed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SummaryRow(sessions: completed),
              ),

            const SizedBox(height: 16),

            // ── Lista de gráficas ───────────────────────────────────
            Expanded(
              child: exercises.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, i) => _ExerciseChart(
                        data: exercises[i],
                        showVolume: _metricIdx == 1,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modelos internos ───────────────────────────────────────────────

class _DataPoint {
  final DateTime date;
  final double maxWeight;
  final double volume;
  const _DataPoint(
      {required this.date,
      required this.maxWeight,
      required this.volume});
}

class _ExerciseData {
  final String name;
  final String muscle;
  final List<_DataPoint> points = [];
  _ExerciseData({required this.name, required this.muscle});
}

// ── Resumen global ──────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _SummaryRow({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalSessions = sessions.length;
    final totalVolume =
        sessions.fold(0.0, (s, w) => s + w.totalVolume);
    final uniqueEx = <String>{};
    for (final s in sessions) {
      for (final e in s.exercises) {
        uniqueEx.add(e.exerciseName);
      }
    }

    return Row(
      children: [
        _MiniStat(
          label: 'Sesiones',
          value: totalSessions.toString(),
          icon: Icons.fitness_center_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          label: 'Ejercicios',
          value: uniqueEx.length.toString(),
          icon: Icons.sports_gymnastics_rounded,
          color: AppColors.accentBlue,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          label: 'Volumen total',
          value: totalVolume >= 1000
              ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
              : '${totalVolume.toStringAsFixed(0)} kg',
          icon: Icons.bar_chart_rounded,
          color: AppColors.accentPurple,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: DarkCard(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 6),
              Text(value,
                  style: AppTextStyles.headingSmall
                      .copyWith(color: Colors.white)),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      );
}

// ── Tarjeta de gráfica por ejercicio ──────────────────────────────

class _ExerciseChart extends StatelessWidget {
  final _ExerciseData data;
  final bool showVolume;
  const _ExerciseChart(
      {required this.data, required this.showVolume, super.key});

  Color get _muscleColor {
    switch (data.muscle) {
      case 'pecho':
        return AppColors.accentOrange;
      case 'espalda':
      case 'dorsales':
        return AppColors.accentBlue;
      case 'hombros':
        return const Color(0xFF80DEEA);
      case 'biceps':
      case 'triceps':
        return AppColors.accentPurple;
      case 'piernas':
      case 'cuadriceps':
      case 'isquiotibiales':
        return const Color(0xFFF48FB1);
      case 'gluteos':
        return const Color(0xFFFFCC02);
      case 'abdominales':
        return AppColors.accentOrange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = data.points;
    final values =
        points.map((p) => showVolume ? p.volume : p.maxWeight).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce(math.max);
    final minVal = values.isEmpty ? 0.0 : values.reduce(math.min);
    final color = _muscleColor;

    // Estadísticas rápidas
    final current = values.isNotEmpty ? values.last : 0.0;
    final best = values.isNotEmpty ? maxVal : 0.0;
    final diff = values.length >= 2 ? values.last - values.first : 0.0;
    final isUp = diff >= 0;
    final unit = showVolume ? 'kg vol' : 'kg';

    return DarkCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ejercicio ────────────────────────────────
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(data.name,
                    style: AppTextStyles.headingSmall,
                    overflow: TextOverflow.ellipsis),
              ),
              if (values.length >= 2)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isUp ? AppColors.primary : AppColors.error)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isUp ? AppColors.primary : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${isUp ? "+" : ""}${diff.toStringAsFixed(1)} $unit',
                        style: AppTextStyles.caption.copyWith(
                          color:
                              isUp ? AppColors.primary : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            data.muscle.isNotEmpty
                ? '${data.muscle[0].toUpperCase()}${data.muscle.substring(1)}'
                : '',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted, fontSize: 10),
          ),

          const SizedBox(height: 12),

          // ── Mini stats ──────────────────────────────────────────
          Row(
            children: [
              _ChartStat(
                  label: 'Actual',
                  value: '${current.toStringAsFixed(1)} $unit'),
              const SizedBox(width: 16),
              _ChartStat(
                  label: 'Mejor',
                  value: '${best.toStringAsFixed(1)} $unit',
                  highlight: true),
              const SizedBox(width: 16),
              _ChartStat(
                  label: 'Sesiones',
                  value: points.length.toString()),
            ],
          ),

          const SizedBox(height: 14),

          // ── Gráfica de línea ────────────────────────────────────
          if (points.isEmpty)
            Container(
              height: 90,
              alignment: Alignment.center,
              child: Text('Sin datos suficientes',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            )
          else if (points.length == 1)
            _SinglePointChart(
                value: values.first,
                unit: unit,
                color: color)
          else
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: values,
                  minVal: minVal,
                  maxVal: maxVal,
                  color: color,
                ),
                size: Size.infinite,
              ),
            ),

          const SizedBox(height: 8),

          // ── Etiquetas de fecha ──────────────────────────────────
          if (points.length >= 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(points.first.date),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted, fontSize: 9)),
                Text(_formatDate(points.last.date),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';
}

class _ChartStat extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _ChartStat(
      {required this.label,
      required this.value,
      this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted, fontSize: 9)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                color: highlight ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              )),
        ],
      );
}

class _SinglePointChart extends StatelessWidget {
  final double value;
  final String unit;
  final Color color;
  const _SinglePointChart(
      {required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        height: 90,
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.5), blurRadius: 8)
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('${value.toStringAsFixed(1)} $unit',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          Text('Primera sesión registrada',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted, fontSize: 10)),
        ]),
      );
}

// ── CustomPainter para la línea de progreso ────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double minVal, maxVal;
  final Color color;

  const _LineChartPainter({
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final range = (maxVal - minVal).abs();
    final effectiveMin = range < 1 ? minVal - 1 : minVal - range * 0.1;
    final effectiveMax = range < 1 ? maxVal + 1 : maxVal + range * 0.1;
    final effectiveRange = effectiveMax - effectiveMin;

    double xOf(int i) =>
        i / (values.length - 1) * size.width;
    double yOf(double v) =>
        size.height - ((v - effectiveMin) / effectiveRange) * size.height;

    final path = Path();
    final fillPath = Path();

    path.moveTo(xOf(0), yOf(values[0]));
    fillPath.moveTo(xOf(0), size.height);
    fillPath.lineTo(xOf(0), yOf(values[0]));

    for (int i = 1; i < values.length; i++) {
      // Curva suave con puntos de control
      final x0 = xOf(i - 1), y0 = yOf(values[i - 1]);
      final x1 = xOf(i), y1 = yOf(values[i]);
      final cpX = (x0 + x1) / 2;
      path.cubicTo(cpX, y0, cpX, y1, x1, y1);
      fillPath.cubicTo(cpX, y0, cpX, y1, x1, y1);
    }

    fillPath.lineTo(xOf(values.length - 1), size.height);
    fillPath.close();

    // Fondo degradado bajo la línea
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Línea principal
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Puntos en cada sesión
    final dotPaint = Paint()..color = color;
    final dotBgPaint = Paint()..color = AppColors.surface;

    for (int i = 0; i < values.length; i++) {
      final x = xOf(i), y = yOf(values[i]);
      canvas.drawCircle(Offset(x, y), 4.5, dotBgPaint);
      canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
    }

    // Glow en el último punto
    final lastX = xOf(values.length - 1);
    final lastY = yOf(values.last);
    canvas.drawCircle(
      Offset(lastX, lastY),
      6,
      Paint()..color = color.withOpacity(0.3),
    );
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.color != color;
}

// ── Estado vacío ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: AppColors.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Sin datos de progreso',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Completa entrenamientos para\nver tu progreso aquí.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
