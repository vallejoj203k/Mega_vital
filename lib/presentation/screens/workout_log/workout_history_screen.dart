// lib/presentation/screens/workout_log/workout_history_screen.dart
// ─────────────────────────────────────────────────────────────────
// Pantalla de historial de entrenamientos.
// - Lista de sesiones agrupadas por fecha
// - Resumen: duración, ejercicios, series, volumen total
// - Detalle expandible de cada sesión (pesos por ejercicio)
// - Deslizar para eliminar
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/workout_log_provider.dart';
import '../../../services/workout_log_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});
  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutLogProvider>().reloadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<WorkoutLogProvider>();
    final sessions  = provider.history;
    final completed = sessions.where((s) => s.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary, size: 14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial', style: AppTextStyles.displayMedium),
                  Text('${completed.length} entrenos registrados',
                      style: AppTextStyles.bodyMedium),
                ],
              )),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Resumen global ───────────────────────────────────
          if (completed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _GlobalStats(sessions: completed),
            ),

          const SizedBox(height: 16),

          // ── Lista ────────────────────────────────────────────
          Expanded(
            child: completed.isEmpty
                ? _EmptyHistory()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    physics: const BouncingScrollPhysics(),
                    children: _buildGroupedSessions(context, completed),
                  ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildGroupedSessions(
      BuildContext context, List<WorkoutSession> sessions) {
    // Agrupar por mes
    final Map<String, List<WorkoutSession>> byMonth = {};
    for (final s in sessions) {
      final key = _monthKey(s.date);
      byMonth.putIfAbsent(key, () => []).add(s);
    }

    final widgets = <Widget>[];
    for (final entry in byMonth.entries) {
      // Cabecera de mes
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(entry.key,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      ));

      for (final session in entry.value) {
        widgets.add(_SessionCard(
          session   : session,
          isExpanded: _expandedIds.contains(session.id),
          onToggle  : () {
            HapticFeedback.selectionClick();
            setState(() {
              if (_expandedIds.contains(session.id)) {
                _expandedIds.remove(session.id);
              } else {
                _expandedIds.add(session.id);
              }
            });
          },
          onDelete: () => _confirmDelete(context, session.id),
        ));
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }

  String _monthKey(DateTime d) {
    const months = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
      'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    return '${months[d.month - 1].toUpperCase()} ${d.year}';
  }

  Future<void> _confirmDelete(BuildContext ctx, String id) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar sesión?', style: AppTextStyles.headingSmall),
        content: Text('Esta acción no se puede deshacer.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar',
                  style: TextStyle(color: AppColors.error,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      await ctx.read<WorkoutLogProvider>().deleteSession(id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// RESUMEN GLOBAL
// ─────────────────────────────────────────────────────────────────
class _GlobalStats extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _GlobalStats({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalSeries = sessions.fold(0, (s, e) => s + e.totalDoneSets);
    final totalVol    = sessions.fold(0.0, (s, e) => s + e.totalVolume);
    final totalMin    = sessions.fold(0, (s, e) => s + e.durationMinutes);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        _StatPill(
            value: sessions.length.toString(),
            label: 'Sesiones',
            color: AppColors.primary),
        _Divider(),
        _StatPill(
            value: totalSeries.toString(),
            label: 'Series',
            color: AppColors.accentBlue),
        _Divider(),
        _StatPill(
            value: totalVol >= 1000
                ? '${(totalVol / 1000).toStringAsFixed(1)}t'
                : '${totalVol.toStringAsFixed(0)}kg',
            label: 'Volumen',
            color: AppColors.accentOrange),
        _Divider(),
        _StatPill(
            value: '${(totalMin / 60).toStringAsFixed(0)}h',
            label: 'Tiempo',
            color: AppColors.accentPurple),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color  color;
  const _StatPill({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: AppTextStyles.headingMedium.copyWith(color: color)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 0.5, height: 32, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ─────────────────────────────────────────────────────────────────
// TARJETA DE SESIÓN
// ─────────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final bool           isExpanded;
  final VoidCallback   onToggle;
  final VoidCallback   onDelete;

  const _SessionCard({
    required this.session,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
  });

  String _formatDate(DateTime d) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '—';
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String _volumeStr(double vol) {
    if (vol <= 0) return '—';
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}t';
    return '${vol.toStringAsFixed(0)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final vol = session.totalVolume;

    return Dismissible(
      key       : ValueKey(session.id),
      direction : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding  : const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // No elimina automáticamente, lo hace onDelete
      },
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isExpanded
                      ? AppColors.primary.withOpacity(0.35)
                      : AppColors.border,
                  width: isExpanded ? 1.5 : 0.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(children: [
                  // Icono
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                            width: 0.5)),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.name,
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(_formatDate(session.date),
                          style: AppTextStyles.caption),
                    ],
                  )),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted, size: 20,
                  ),
                ]),
              ),

              // ── Chips de resumen ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  _InfoChip(
                      icon : Icons.timer_rounded,
                      label: _formatDuration(session.durationMinutes),
                      color: AppColors.accentBlue),
                  _InfoChip(
                      icon : Icons.fitness_center_rounded,
                      label: '${session.completedExercises} ejercicios',
                      color: AppColors.accentPurple),
                  _InfoChip(
                      icon : Icons.repeat_rounded,
                      label: '${session.totalDoneSets} series',
                      color: AppColors.primary),
                  if (vol > 0)
                    _InfoChip(
                        icon : Icons.bar_chart_rounded,
                        label: _volumeStr(vol),
                        color: AppColors.accentOrange),
                ]),
              ),

              // ── Detalle expandible ───────────────────────────
              if (isExpanded)
                _SessionDetail(session: session),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DETALLE DE SESIÓN (ejercicios + series con pesos)
// ─────────────────────────────────────────────────────────────────
class _SessionDetail extends StatelessWidget {
  final WorkoutSession session;
  const _SessionDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la tabla
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              const Expanded(child: Text('Ejercicio',
                  style: AppTextStyles.caption)),
              SizedBox(width: 72, child: Text('Mejor\nSerie',
                  style: AppTextStyles.caption, textAlign: TextAlign.center)),
              SizedBox(width: 56, child: Text('Vol.',
                  style: AppTextStyles.caption, textAlign: TextAlign.right)),
            ]),
          ),
          const Divider(height: 0, thickness: 0.5, color: AppColors.border),

          // Filas de ejercicios
          ...session.exercises
              .where((e) => e.doneSets > 0)
              .map((ex) => _ExerciseDetailRow(exercise: ex)),

          // Si no hay ejercicios completados
          if (session.exercises.every((e) => e.doneSets == 0))
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Sin series completadas',
                  style: AppTextStyles.caption),
            ),
        ],
      ),
    );
  }
}

class _ExerciseDetailRow extends StatelessWidget {
  final LoggedExercise exercise;
  const _ExerciseDetailRow({required this.exercise});

  String _bestSetStr() {
    final done = exercise.sets.where((s) => s.isDone).toList();
    if (done.isEmpty) return '—';
    // Mejor serie = mayor peso × reps
    done.sort((a, b) => (b.weight * b.reps).compareTo(a.weight * a.reps));
    final best = done.first;
    final wStr = best.weight > 0
        ? '${_weightStr(best.weight)} kg'
        : 'Corporal';
    return '$wStr × ${best.reps}';
  }

  String _weightStr(double w) =>
      w == w.truncateToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);

  String _volStr(double v) {
    if (v <= 0) return '—';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}t';
    return '${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5))),
    child: Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.exerciseName,
              style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis),
          Text('${exercise.doneSets} series',
              style: AppTextStyles.caption),
        ],
      )),
      SizedBox(width: 72, child: Text(_bestSetStr(),
          style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary),
          textAlign: TextAlign.center)),
      SizedBox(width: 56, child: Text(_volStr(exercise.totalVolume),
          style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.accentOrange, fontSize: 12),
          textAlign: TextAlign.right)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(
            color: AppColors.surfaceVariant, shape: BoxShape.circle),
        child: const Icon(Icons.history_rounded,
            color: AppColors.textMuted, size: 34),
      ),
      const SizedBox(height: 16),
      Text('Sin entrenamientos aún',
          style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      Text('Completa tu primer entrenamiento\npara ver el historial aquí',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center),
    ]),
  );
}
