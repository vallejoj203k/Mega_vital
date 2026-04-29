// lib/presentation/screens/progress/progress_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/workout_log_provider.dart';
import '../../../services/exercise_progress_service.dart';
import '../../../services/workout_log_service.dart';
import '../../widgets/shared_widgets.dart';
import 'progress_share_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  // Métricas
  static const _metrics = ['Peso máx.', 'Volumen'];
  int _metricIdx = 0;

  // Estado del sync con el cloud (solo indicador visual, no afecta los datos)
  bool _syncing = true;
  bool _syncOk = false;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncToCloud());
  }

  Future<void> _syncToCloud() async {
    if (!mounted || _synced) return;
    _synced = true;

    final local = context.read<WorkoutLogProvider>().history;
    await ExerciseProgressService.instance.syncAllSessions(local);

    if (mounted) {
      setState(() {
        _syncing = false;
        _syncOk = true;
      });
    }
  }

  // ── Siempre usa datos locales (granularidad por sesión) ──────────
  // El cloud es solo backup; tiene 1 fila por (ejercicio+día) por el
  // UNIQUE constraint, por lo que no puede representar múltiples
  // sesiones en el mismo día.

  Map<String, _ExerciseData> _buildExerciseMap(List<WorkoutSession> history) {
    final Map<String, _ExerciseData> map = {};

    final sorted = history
        .where((s) => s.isCompleted)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final session in sorted) {
      for (final ex in session.exercises) {
        final done = ex.sets.where((s) => s.isDone).toList();
        if (done.isEmpty) continue;
        map.putIfAbsent(
          ex.exerciseName,
          () => _ExerciseData(name: ex.exerciseName, muscle: ex.muscleId),
        );
        map[ex.exerciseName]!.points.add(_DataPoint(
          date: session.date,
          maxWeight: ex.maxWeight,
          volume: ex.totalVolume,
        ));
      }
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final log = context.watch<WorkoutLogProvider>();
    final history = log.history;

    final exerciseMap = _buildExerciseMap(history);
    final exercises = exerciseMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final userName =
        context.read<AuthProvider>().profile?.name ?? 'Usuario';
    final completedSessions =
        history.where((s) => s.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
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
                      Row(children: [
                        Text('Evolución por ejercicio',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        Icon(
                          _syncing
                              ? Icons.cloud_sync_rounded
                              : (_syncOk
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded),
                          size: 12,
                          color: _syncing
                              ? AppColors.textMuted
                              : (_syncOk
                                  ? AppColors.primary
                                  : AppColors.textMuted),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Selector de métrica ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.border, width: 0.5),
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

            // ── Resumen global ────────────────────────────────────
            if (completedSessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SummaryRow(sessions: completedSessions),
              ),

            const SizedBox(height: 16),

            // ── Lista de gráficas ─────────────────────────────────
            Expanded(
              child: exercises.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, i) => _ExerciseChart(
                        data: exercises[i],
                        showVolume: _metricIdx == 1,
                        userName: userName,
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

// ── Resumen global ─────────────────────────────────────────────────

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
                      .copyWith(
                          color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      );
}

// ── Tarjeta de gráfica por ejercicio ──────────────────────────────

class _ExerciseChart extends StatelessWidget {
  final _ExerciseData data;
  final bool showVolume;
  final String userName;
  const _ExerciseChart(
      {required this.data,
      required this.showVolume,
      required this.userName,
      super.key});

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
          // ── Encabezado ──────────────────────────────────────────
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
                        color:
                            isUp ? AppColors.primary : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${isUp ? "+" : ""}${diff.toStringAsFixed(1)} $unit',
                        style: AppTextStyles.caption.copyWith(
                          color: isUp
                              ? AppColors.primary
                              : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              // ── Botón compartir ────────────────────────────────
              GestureDetector(
                onTap: () => _showShareSheet(
                    context, color, values, current, best, diff, isUp, unit),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.share_rounded,
                      color: AppColors.textSecondary, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          if (data.muscle.isNotEmpty)
            Text(
              '${data.muscle[0].toUpperCase()}${data.muscle.substring(1)}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted, fontSize: 10),
            ),

          const SizedBox(height: 12),

          // ── Mini stats ─────────────────────────────────────────
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

          // ── Gráfica ────────────────────────────────────────────
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
                value: values.first, unit: unit, color: color)
          else
            SizedBox(
              height: 130,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: values,
                  minVal: minVal,
                  maxVal: maxVal,
                  color: color,
                  unit: unit,
                ),
                size: Size.infinite,
              ),
            ),

          const SizedBox(height: 8),

          if (points.length >= 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(points.first.date),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted, fontSize: 9)),
                Text(_fmt(points.last.date),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
        ],
      ),
    );
  }

  void _showShareSheet(
    BuildContext context,
    Color color,
    List<double> values,
    double current,
    double best,
    double diff,
    bool isUp,
    String unit,
  ) {
    final auth = context.read<AuthProvider>();
    final userName = auth.profile?.name ?? 'Usuario';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(
        exerciseName: data.name,
        muscle: data.muscle,
        userName: userName,
        maxWeight: current,
        bestWeight: best,
        volume: data.points.isNotEmpty
            ? data.points.last.volume
            : 0.0,
        sessions: data.points.length,
        chartValues: values,
        isUp: isUp,
        diff: diff,
        accentColor: color,
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';
}

// ── Bottom sheet para compartir ───────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final String exerciseName, muscle, userName;
  final double maxWeight, bestWeight, volume, diff;
  final int sessions;
  final List<double> chartValues;
  final bool isUp;
  final Color accentColor;

  const _ShareSheet({
    required this.exerciseName,
    required this.muscle,
    required this.userName,
    required this.maxWeight,
    required this.bestWeight,
    required this.volume,
    required this.sessions,
    required this.chartValues,
    required this.isUp,
    required this.diff,
    required this.accentColor,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;
  bool _posting = false;

  // Captura el widget con RepaintBoundary y retorna los bytes PNG
  Future<Uint8List?> _captureCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      await Future.delayed(const Duration(milliseconds: 80));
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareExternal() async {
    setState(() => _sharing = true);
    HapticFeedback.lightImpact();
    final bytes = await _captureCard();
    if (bytes == null) {
      setState(() => _sharing = false);
      if (mounted) _showError('No se pudo generar la imagen.');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/progreso_mega_vital.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '¡Mira mi progreso en ${widget.exerciseName}! 💪\n#MegaVital',
      );
    } catch (_) {
      if (mounted) _showError('Error al compartir.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _postToCommunity() async {
    setState(() => _posting = true);
    HapticFeedback.lightImpact();
    final bytes = await _captureCard();
    if (bytes == null) {
      setState(() => _posting = false);
      if (mounted) _showError('No se pudo generar la imagen.');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/progreso_comunidad.png');
      await file.writeAsBytes(bytes);

      final content =
          '¡Revisen mi progreso en ${widget.exerciseName}! '
          '${widget.isUp ? "📈 Subiendo" : "💪 Trabajando"} '
          '(${widget.isUp ? "+" : ""}${widget.diff.toStringAsFixed(1)} kg)';

      if (!mounted) return;
      final community = context.read<CommunityProvider>();
      final error = await community.createPost(
        widget.userName,
        content,
        achievement: widget.isUp ? '¡Nuevo PB! 🏆' : 'Progreso constante 💪',
        imageFile: file,
      );

      if (!mounted) return;
      if (error == null || error == 'warn:image') {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              const Text('¡Publicado en la comunidad!'),
            ]),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        _showError('Error al publicar: $error');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Text('Compartir progreso',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text('Vista previa de tu tarjeta',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted)),

          const SizedBox(height: 20),

          // ── Tarjeta de preview (capturada al compartir) ────────
          RepaintBoundary(
            key: _cardKey,
            child: ProgressShareCard(
              exerciseName: widget.exerciseName,
              muscle: widget.muscle,
              userName: widget.userName,
              maxWeight: widget.maxWeight,
              bestWeight: widget.bestWeight,
              volume: widget.volume,
              sessions: widget.sessions,
              chartValues: widget.chartValues,
              isUp: widget.isUp,
              diff: widget.diff,
              accentColor: widget.accentColor,
            ),
          ),

          const SizedBox(height: 24),

          // ── Botones de acción ──────────────────────────────────
          Row(
            children: [
              // Compartir en redes
              Expanded(
                child: GestureDetector(
                  onTap: _sharing ? null : _shareExternal,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _sharing
                          ? null
                          : const LinearGradient(
                              colors: [
                                Color(0xFF00FF87),
                                Color(0xFF00CC6A)
                              ],
                            ),
                      color: _sharing ? AppColors.surfaceVariant : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _sharing
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_sharing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textMuted,
                            ),
                          )
                        else
                          const Icon(Icons.share_rounded,
                              color: Color(0xFF0A0A0A), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _sharing ? 'Compartiendo...' : 'Redes sociales',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _sharing
                                ? AppColors.textMuted
                                : const Color(0xFF0A0A0A),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Publicar en comunidad
              Expanded(
                child: GestureDetector(
                  onTap: _posting ? null : _postToCommunity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentPurple.withOpacity(
                            _posting ? 0.15 : 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_posting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentPurple,
                            ),
                          )
                        else
                          const Icon(Icons.people_rounded,
                              color: AppColors.accentPurple, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _posting ? 'Publicando...' : 'Comunidad',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.accentPurple,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────

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
                color: highlight
                    ? AppColors.primary
                    : AppColors.textSecondary,
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
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double minVal, maxVal;
  final Color color;
  final String unit;

  const _LineChartPainter({
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
    required this.unit,
  });

  // Espacio reservado en la parte superior para las etiquetas
  static const double _labelHeight = 22.0;
  static const double _dotRadius   = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    // Área útil para la línea (debajo de las etiquetas)
    final chartTop    = _labelHeight;
    final chartHeight = size.height - chartTop;

    final range  = (maxVal - minVal).abs();
    final effMin = range < 1 ? minVal - 1 : minVal - range * 0.1;
    final effMax = range < 1 ? maxVal + 1 : maxVal + range * 0.1;
    final effRange = effMax - effMin;

    double xOf(int i) => i / (values.length - 1) * size.width;
    double yOf(double v) =>
        chartTop + chartHeight - ((v - effMin) / effRange) * chartHeight;

    // ── Degradado de fondo ─────────────────────────────────────
    final path     = Path();
    final fillPath = Path();

    path.moveTo(xOf(0), yOf(values[0]));
    fillPath.moveTo(xOf(0), size.height);
    fillPath.lineTo(xOf(0), yOf(values[0]));

    for (int i = 1; i < values.length; i++) {
      final cpX = (xOf(i - 1) + xOf(i)) / 2;
      path.cubicTo(
          cpX, yOf(values[i - 1]), cpX, yOf(values[i]), xOf(i), yOf(values[i]));
      fillPath.cubicTo(
          cpX, yOf(values[i - 1]), cpX, yOf(values[i]), xOf(i), yOf(values[i]));
    }

    fillPath.lineTo(xOf(values.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // ── Línea ──────────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Puntos + etiquetas ─────────────────────────────────────
    final dotBg  = Paint()..color = AppColors.surface;
    final dotFill = Paint()..color = color;

    // Decidir qué índices mostrar etiqueta cuando hay muchos puntos.
    // Con ≤6 puntos: todos. Con más: primero, último, máximo y mínimo.
    final showLabel = <int>{};
    if (values.length <= 6) {
      for (int i = 0; i < values.length; i++) {
        showLabel.add(i);
      }
    } else {
      showLabel.add(0);
      showLabel.add(values.length - 1);
      // índice del máximo y mínimo
      double mx = values[0], mn = values[0];
      int mxIdx = 0, mnIdx = 0;
      for (int i = 1; i < values.length; i++) {
        if (values[i] > mx) { mx = values[i]; mxIdx = i; }
        if (values[i] < mn) { mn = values[i]; mnIdx = i; }
      }
      showLabel.add(mxIdx);
      showLabel.add(mnIdx);
    }

    for (int i = 0; i < values.length; i++) {
      final x = xOf(i);
      final y = yOf(values[i]);
      final isLast = i == values.length - 1;

      // Glow en el último punto
      if (isLast) {
        canvas.drawCircle(Offset(x, y), 7,
            Paint()..color = color.withOpacity(0.25));
      }

      // Punto
      canvas.drawCircle(Offset(x, y), _dotRadius + 1.5, dotBg);
      canvas.drawCircle(Offset(x, y), _dotRadius, dotFill);

      // Etiqueta de valor
      if (showLabel.contains(i)) {
        final raw   = values[i];
        final label = raw == raw.truncateToDouble()
            ? '${raw.toInt()} $unit'
            : '${raw.toStringAsFixed(1)} $unit';

        final isMax = raw == values.reduce(math.max);
        final labelColor = isMax ? color : color.withOpacity(0.75);

        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: labelColor,
              fontSize: 9.5,
              fontWeight: isMax ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 80);

        // Centrar sobre el punto, clampear para no salirse del canvas
        double lx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
        // Posicionar encima del punto con un pequeño gap
        final ly = (y - tp.height - _dotRadius - 4).clamp(0.0, size.height);

        tp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.color != color || old.unit != unit;
}

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
