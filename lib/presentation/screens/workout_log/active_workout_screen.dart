// lib/presentation/screens/workout_log/active_workout_screen.dart
// ─────────────────────────────────────────────────────────────────
// Pantalla de entrenamiento activo.
// - Cronómetro en tiempo real
// - Lista de ejercicios con series, pesos y reps editables
// - Marca series como completadas
// - Añadir / eliminar series extra
// - Guarda automáticamente el último peso usado
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/workout_log_provider.dart';
import '../../../services/workout_log_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});
  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  final Set<int> _collapsedExercises = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmFinish(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    final provider = ctx.read<WorkoutLogProvider>();
    final session  = provider.activeSession;
    if (session == null) return;

    final totalSeries = session.totalDoneSets;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Terminar entrenamiento?',
            style: AppTextStyles.headingSmall),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _SummaryRow(
                  icon: Icons.timer_rounded,
                  color: AppColors.accentBlue,
                  label: 'Duración',
                  value: _formatTime(_elapsedSeconds)),
              const SizedBox(height: 8),
              _SummaryRow(
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  label: 'Ejercicios',
                  value: '${session.completedExercises}/${session.exercises.length}'),
              const SizedBox(height: 8),
              _SummaryRow(
                  icon: Icons.repeat_rounded,
                  color: AppColors.accentPurple,
                  label: 'Series hechas',
                  value: '$totalSeries'),
              if (session.totalVolume > 0) ...[
                const SizedBox(height: 8),
                _SummaryRow(
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.accentOrange,
                    label: 'Volumen total',
                    value: '${session.totalVolume.toStringAsFixed(0)} kg'),
              ],
            ]),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Continuar',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Terminar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && ctx.mounted) {
      final userName = ctx.read<AuthProvider>().profile?.name ?? 'Usuario';
      await ctx.read<WorkoutLogProvider>().finishSession(userName: userName);
      if (ctx.mounted) Navigator.of(ctx).pop();
    }
  }

  Future<void> _confirmCancel(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Cancelar entrenamiento?',
            style: AppTextStyles.headingSmall),
        content: Text(
            'Se perderá el progreso de esta sesión. ¿Estás seguro?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('No',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sí, cancelar',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<WorkoutLogProvider>().cancelSession();
      Navigator.of(ctx).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutLogProvider>();
    final session  = provider.activeSession;

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Sin sesión activa')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────
          _WorkoutHeader(
            sessionName   : session.name,
            elapsedSeconds: _elapsedSeconds,
            formatTime    : _formatTime,
            onFinish      : () => _confirmFinish(context),
            onCancel      : () => _confirmCancel(context),
          ),

          // ── Lista de ejercicios ───────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: session.exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, exIdx) => _ExerciseLogCard(
                exercise    : session.exercises[exIdx],
                exIdx       : exIdx,
                isCollapsed : _collapsedExercises.contains(exIdx),
                onCollapse  : () => setState(
                    () => _collapsedExercises.add(exIdx)),
              ),
            ),
          ),
        ]),
      ),

      // ── Botón terminar ────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: GestureDetector(
            onTap: () => _confirmFinish(context),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.background, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'TERMINAR ENTRENAMIENTO',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HEADER CON CRONÓMETRO
// ─────────────────────────────────────────────────────────────────
class _WorkoutHeader extends StatelessWidget {
  final String           sessionName;
  final int              elapsedSeconds;
  final String Function(int) formatTime;
  final VoidCallback     onFinish;
  final VoidCallback     onCancel;

  const _WorkoutHeader({
    required this.sessionName,
    required this.elapsedSeconds,
    required this.formatTime,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5)),
    ),
    child: Row(children: [
      // Botón cancelar
      GestureDetector(
        onTap: onCancel,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: const Icon(Icons.close_rounded,
              color: AppColors.textSecondary, size: 18),
        ),
      ),
      const SizedBox(width: 12),

      // Nombre + indicador en curso
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('En curso', style: AppTextStyles.caption
                .copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: 1),
          Text(sessionName, style: AppTextStyles.headingSmall,
              overflow: TextOverflow.ellipsis),
        ],
      )),

      // Cronómetro
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer_rounded,
              size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(formatTime(elapsedSeconds),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5)),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────
// TARJETA DE EJERCICIO — muestra solo la serie activa
// ─────────────────────────────────────────────────────────────────
class _ExerciseLogCard extends StatelessWidget {
  final LoggedExercise exercise;
  final int            exIdx;
  final bool           isCollapsed;
  final VoidCallback   onCollapse;

  const _ExerciseLogCard({
    required this.exercise,
    required this.exIdx,
    required this.isCollapsed,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final doneSets = exercise.doneSets;

    // ── Ejercicio colapsado (ya terminado por el usuario) ───────
    if (isCollapsed) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.4), width: 1.5),
          boxShadow: [BoxShadow(
              color: AppColors.primary.withOpacity(0.07), blurRadius: 10)],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 0.5)),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(exercise.exerciseName,
              style: AppTextStyles.labelLarge,
              overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 0.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_rounded, size: 11,
                  color: AppColors.primary),
              const SizedBox(width: 4),
              Text('$doneSets series',
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ]),
          ),
        ]),
      );
    }

    // ── Ejercicio activo ────────────────────────────────────────
    final currentSetIdx = exercise.sets.indexWhere((s) => !s.isDone);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Encabezado ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accentBlue.withOpacity(0.3), width: 0.5)),
              child: const Icon(Icons.fitness_center_rounded,
                  color: AppColors.accentBlue, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(exercise.exerciseName,
                  style: AppTextStyles.labelLarge,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                doneSets == 0
                    ? 'Empieza cuando quieras'
                    : '$doneSets ${doneSets == 1 ? 'serie' : 'series'} completadas',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: doneSets > 0
                        ? AppColors.primary
                        : AppColors.textMuted)),
            ])),
            // Contador circular de series hechas
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim, child: child),
              child: doneSets > 0
                  ? Container(
                      key: ValueKey(doneSets),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.35),
                              width: 1.5)),
                      child: Center(
                        child: Text('$doneSets',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    )
                  : const SizedBox(key: ValueKey(0), width: 36),
            ),
          ]),
        ),

        // ── Serie activa ────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve:  Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.18), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: currentSetIdx >= 0
              ? _ActiveSetSection(
                  key:         ValueKey(currentSetIdx),
                  set:         exercise.sets[currentSetIdx],
                  exIdx:       exIdx,
                  setIdx:      currentSetIdx,
                  accentColor: AppColors.accentBlue,
                )
              : const SizedBox(key: ValueKey('empty'), height: 4),
        ),

        // ── Botón terminar (siempre visible) ────────────────────
        _TerminarButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            onCollapse();
          },
        ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECCIÓN DE SERIE ACTIVA (cabecera + fila editable)
// ─────────────────────────────────────────────────────────────────
class _ActiveSetSection extends StatelessWidget {
  final ExerciseSetLog set;
  final int            exIdx;
  final int            setIdx;
  final Color          accentColor;

  const _ActiveSetSection({
    super.key,
    required this.set,
    required this.exIdx,
    required this.setIdx,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ── Badge "Serie X" ────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: accentColor.withOpacity(0.35), width: 1),
            ),
            child: Text(
              'Serie ${setIdx + 1}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: accentColor, letterSpacing: 0.3),
            ),
          ),
        ]),
      ),

      // ── Cabecera de columnas ────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          const SizedBox(width: 36),
          const SizedBox(width: 8),
          Expanded(child: Text('Peso (kg)',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(child: Text('Reps',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center)),
          const SizedBox(width: 44),
        ]),
      ),
      const SizedBox(height: 4),
      _SetRow(set: set, exIdx: exIdx, setIdx: setIdx),
      const SizedBox(height: 4),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────
// BOTÓN TERMINAR EJERCICIO
// ─────────────────────────────────────────────────────────────────
class _TerminarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TerminarButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: AppColors.primary.withOpacity(0.30),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: Colors.black, size: 16),
            SizedBox(width: 8),
            Text('TERMINAR EJERCICIO',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: Colors.black, letterSpacing: 0.5)),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// FILA DE SERIE (peso + reps + check)
// ─────────────────────────────────────────────────────────────────
class _SetRow extends StatefulWidget {
  final ExerciseSetLog set;
  final int            exIdx;
  final int            setIdx;
  const _SetRow({required this.set, required this.exIdx, required this.setIdx});
  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> with SingleTickerProviderStateMixin {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  bool _weightFocused  = false;
  bool _repsFocused    = false;
  bool _isConfirming   = false;

  late AnimationController _checkCtrl;
  late Animation<double>   _checkScale;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: widget.set.weight > 0 ? _weightDisplay(widget.set.weight) : '');
    _repsCtrl = TextEditingController(
        text: widget.set.reps.toString());

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    // Bounce: crece → encoge → vuelve (luego se llama toggleSetDone)
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.55)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.55, end: 0.82)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.82, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 40),
    ]).animate(_checkCtrl);
  }

  @override
  void didUpdateWidget(_SetRow old) {
    super.didUpdateWidget(old);
    if (!_weightFocused) {
      final v = widget.set.weight > 0 ? _weightDisplay(widget.set.weight) : '';
      if (_weightCtrl.text != v) _weightCtrl.text = v;
    }
    if (!_repsFocused) {
      final v = widget.set.reps.toString();
      if (_repsCtrl.text != v) _repsCtrl.text = v;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  String _weightDisplay(double w) =>
      w == w.truncateToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);

  void _onCheck(BuildContext ctx) {
    if (_isConfirming || widget.set.isDone) return;
    _isConfirming = true;
    HapticFeedback.heavyImpact();
    _checkCtrl.forward(from: 0).then((_) {
      if (mounted) {
        final provider = ctx.read<WorkoutLogProvider>();
        provider.toggleSetDone(widget.exIdx, widget.setIdx);
        provider.addSet(widget.exIdx); // serie siguiente en blanco
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.set.isDone;

    return AnimatedBuilder(
      animation: _checkCtrl,
      builder: (ctx, _) {
        final t = _checkCtrl.value; // 0→1 durante la animación

        return Container(
          margin  : const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          padding : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            // Fondo: destello verde progresivo durante la animación
            color: isDone
                ? AppColors.primary.withOpacity(0.06)
                : Color.lerp(Colors.transparent,
                    AppColors.primary.withOpacity(0.09), t),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDone
                    ? AppColors.primary.withOpacity(0.20)
                    : Color.lerp(Colors.transparent,
                        AppColors.primary.withOpacity(0.35), t)!,
                width: 0.5),
          ),
          child: Row(children: [
            // Número de serie
            SizedBox(width: 28,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                    color: isDone || t > 0.3
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle),
                child: Center(
                  child: Text('${widget.set.setNumber}',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isDone || t > 0.3
                              ? AppColors.primary
                              : AppColors.textMuted)),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Campo peso
            Expanded(
              child: Focus(
                onFocusChange: (f) => setState(() => _weightFocused = f),
                child: TextField(
                  controller  : _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign   : TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDone ? AppColors.primary : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: isDone
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1)),
                  ),
                  onChanged: (v) {
                    final w = double.tryParse(v) ?? 0;
                    ctx.read<WorkoutLogProvider>()
                        .updateSetWeight(widget.exIdx, widget.setIdx, w);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Campo reps
            Expanded(
              child: Focus(
                onFocusChange: (f) => setState(() => _repsFocused = f),
                child: TextField(
                  controller  : _repsCtrl,
                  keyboardType: TextInputType.number,
                  textAlign   : TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDone ? AppColors.primary : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: isDone
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1)),
                  ),
                  onChanged: (v) {
                    final r = int.tryParse(v) ?? 0;
                    ctx.read<WorkoutLogProvider>()
                        .updateSetReps(widget.exIdx, widget.setIdx, r);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botón check con bounce + glow
            GestureDetector(
              onTap: () => _onCheck(context),
              child: Transform.scale(
                scale: _checkScale.value,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary
                        : Color.lerp(AppColors.surfaceVariant,
                            AppColors.primary, t),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDone || t > 0.05
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1),
                    boxShadow: t > 0.05 || isDone
                        ? [BoxShadow(
                            color: AppColors.primary.withOpacity(
                                isDone ? 0.30 : t * 0.60),
                            blurRadius: isDone ? 8 : t * 20,
                            spreadRadius: t * 3)]
                        : null,
                  ),
                  child: Icon(
                    isDone || t > 0.42
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isDone || t > 0.42
                        ? AppColors.background
                        : AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  const _SummaryRow({required this.icon, required this.color,
    required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 8),
    Text(label, style: AppTextStyles.bodyMedium),
    const Spacer(),
    Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
  ]);
}
