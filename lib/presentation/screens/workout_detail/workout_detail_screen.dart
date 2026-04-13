// lib/presentation/screens/workout_detail/workout_detail_screen.dart
// ──────────────────────────────────────────────────────────────────
// Pantalla de detalle de rutina con:
//   • Hero animation desde la lista
//   • Header inmersivo con degradado
//   • Chips de info (duración, calorías, dificultad)
//   • Lista expandible de ejercicios con sets/reps
//   • Indicador de músculos trabajados
//   • Contador de descanso animado
//   • Botón de iniciar entrenamiento
// ──────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/mock/mock_data.dart';
import '../../widgets/shared_widgets.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen>
    with SingleTickerProviderStateMixin {

  // ── Estado del entrenamiento ──
  bool _isStarted = false;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;

  // ── Timer de descanso ──
  Timer? _restTimer;
  int _restSecondsLeft = 0;
  bool _isResting = false;

  // ── Animación del botón principal ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _restTimer?.cancel();
    super.dispose();
  }

  // ── Iniciar descanso ──
  void _startRest(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsLeft = seconds;
    });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSecondsLeft <= 1) {
        t.cancel();
        setState(() => _isResting = false);
      } else {
        setState(() => _restSecondsLeft--);
      }
    });
  }

  // ── Marcar set como completado ──
  void _completeSet(int totalSets, int restSec) {
    if (_currentSet < totalSets) {
      setState(() => _currentSet++);
      _startRest(restSec);
    } else if (_currentExerciseIndex < widget.workout.exerciseList.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
      });
      _startRest(restSec);
    } else {
      // Entrenamiento completado
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(workout: widget.workout),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar inmersivo ──
              _WorkoutSliverAppBar(workout: widget.workout),

              // ── Chips de info ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _InfoChipsRow(workout: widget.workout),
                ),
              ),

              // ── Descripción ──
              if (widget.workout.description != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: DarkCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.workout.description!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Músculos trabajados ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _MuscleGroupsSection(workout: widget.workout),
                ),
              ),

              // ── Cabecera de ejercicios ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: SectionHeader(
                    title: 'Ejercicios (${widget.workout.exerciseList.length})',
                  ),
                ),
              ),

              // ── Lista de ejercicios ──
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final ex = widget.workout.exerciseList[i];
                    final isActive = _isStarted && i == _currentExerciseIndex;
                    final isDone = _isStarted && i < _currentExerciseIndex;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _ExerciseCard(
                        exercise: ex,
                        index: i,
                        isActive: isActive,
                        isDone: isDone,
                        currentSet: isActive ? _currentSet : 1,
                        onSetComplete: isActive
                            ? () => _completeSet(ex.sets, ex.restSeconds)
                            : null,
                      ),
                    );
                  },
                  childCount: widget.workout.exerciseList.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // ── Timer de descanso flotante ──
          if (_isResting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: _RestTimerOverlay(
                secondsLeft: _restSecondsLeft,
                onSkip: () {
                  _restTimer?.cancel();
                  setState(() => _isResting = false);
                },
              ),
            ),

          // ── Botón flotante inferior ──
          if (!_isResting)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomActionBar(
                isStarted: _isStarted,
                pulseAnim: _pulseAnim,
                currentIndex: _currentExerciseIndex,
                totalExercises: widget.workout.exerciseList.length,
                onStart: () => setState(() => _isStarted = true),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── SliverAppBar inmersivo ───
class _WorkoutSliverAppBar extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutSliverAppBar({required this.workout});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo con degradado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F2318),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Ícono grande centrado
            Center(
              child: Icon(workout.icon, color: workout.color, size: 80),
            ),
            // Overlay degradado abajo
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(workout.name, style: AppTextStyles.headingMedium),
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      ),
    );
  }
}

// ─── Chips de información ───
class _InfoChipsRow extends StatelessWidget {
  final WorkoutModel workout;
  const _InfoChipsRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.timer_outlined,
          label: '${workout.durationMinutes} min',
          color: AppColors.accentBlue,
        ),
        const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.local_fire_department_outlined,
          label: '${workout.calories} kcal',
          color: AppColors.accentOrange,
        ),
        const SizedBox(width: 10),
        DifficultyChip(difficulty: workout.difficulty),
        const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.fitness_center_outlined,
          label: workout.category,
          color: AppColors.accentPurple,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Músculos trabajados ───
class _MuscleGroupsSection extends StatelessWidget {
  final WorkoutModel workout;
  const _MuscleGroupsSection({required this.workout});

  @override
  Widget build(BuildContext context) {
    // Extrae músculo único de cada ejercicio
    final muscles = workout.exerciseList
        .map((e) => e.muscle.split(' / ').first)
        .toSet()
        .toList();

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Músculos trabajados', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: muscles.map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 0.5,
                ),
              ),
              child: Text(
                m,
                style: AppTextStyles.neonLabel.copyWith(fontSize: 12),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de ejercicio expandible ───
class _ExerciseCard extends StatefulWidget {
  final ExerciseModel exercise;
  final int index;
  final bool isActive;
  final bool isDone;
  final int currentSet;
  final VoidCallback? onSetComplete;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.isActive,
    required this.isDone,
    required this.currentSet,
    this.onSetComplete,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_ExerciseCard old) {
    super.didUpdateWidget(old);
    // Auto-expandir cuando este ejercicio se activa
    if (widget.isActive && !old.isActive) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: widget.isActive
            ? const Color(0xFF0F2318)
            : widget.isDone
                ? AppColors.surface.withOpacity(0.5)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActive
              ? AppColors.primary.withOpacity(0.5)
              : widget.isDone
                  ? AppColors.border.withOpacity(0.3)
                  : AppColors.border,
          width: widget.isActive ? 1 : 0.5,
        ),
        boxShadow: widget.isActive
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 16)]
            : [],
      ),
      child: Column(
        children: [
          // ── Fila principal ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Número / check
                  _ExerciseIndex(
                    index: widget.index,
                    isDone: widget.isDone,
                    isActive: widget.isActive,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: widget.isDone
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            decoration: widget.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.exercise.muscle,
                          style: AppTextStyles.caption.copyWith(
                            color: widget.isActive
                                ? AppColors.primary.withOpacity(0.8)
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sets x Reps
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.exercise.sets} × ${widget.exercise.reps}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: widget.isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${widget.exercise.restSeconds}s descanso',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Detalle expandible ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ExerciseDetail(
              exercise: widget.exercise,
              isActive: widget.isActive,
              currentSet: widget.currentSet,
              onSetComplete: widget.onSetComplete,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ─── Indicador de índice del ejercicio ───
class _ExerciseIndex extends StatelessWidget {
  final int index;
  final bool isDone;
  final bool isActive;
  const _ExerciseIndex({required this.index, required this.isDone, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.primary.withOpacity(0.15)
            : isActive
                ? AppColors.primaryGlow
                : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 0.5)
            : null,
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
          : Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
    );
  }
}

// ─── Detalle del ejercicio ───
class _ExerciseDetail extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isActive;
  final int currentSet;
  final VoidCallback? onSetComplete;
  const _ExerciseDetail({
    required this.exercise,
    required this.isActive,
    required this.currentSet,
    this.onSetComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Nota de forma
          if (exercise.notes != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accentBlue.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      size: 14, color: AppColors.accentBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.notes!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentBlue.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Series visuales
          Row(
            children: List.generate(exercise.sets, (i) {
              final done = isActive && i < currentSet - 1;
              final current = isActive && i == currentSet - 1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.primaryGlow
                        : current
                            ? AppColors.primaryGlow
                            : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: done || current
                          ? AppColors.primary.withOpacity(0.6)
                          : AppColors.border,
                      width: current ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 16)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: current
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),

          // Botón completar set
          if (isActive) ...[
            const SizedBox(height: 14),
            NeonButton(
              label: currentSet <= exercise.sets
                  ? 'Completar set $currentSet/${exercise.sets}'
                  : 'Siguiente ejercicio →',
              icon: Icons.check_circle_outline_rounded,
              fullWidth: true,
              onTap: onSetComplete,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Barra de acción inferior ───
class _BottomActionBar extends StatelessWidget {
  final bool isStarted;
  final Animation<double> pulseAnim;
  final int currentIndex;
  final int totalExercises;
  final VoidCallback onStart;

  const _BottomActionBar({
    required this.isStarted,
    required this.pulseAnim,
    required this.currentIndex,
    required this.totalExercises,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: isStarted
          ? Row(
              children: [
                Expanded(
                  child: DarkCard(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Ejercicio ${currentIndex + 1} de $totalExercises',
                          style: AppTextStyles.neonLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: pulseAnim.value,
                child: NeonButton(
                  label: 'Iniciar entrenamiento',
                  icon: Icons.play_circle_outline_rounded,
                  fullWidth: true,
                  onTap: onStart,
                ),
              ),
            ),
    );
  }
}

// ─── Overlay de descanso ───
class _RestTimerOverlay extends StatelessWidget {
  final int secondsLeft;
  final VoidCallback onSkip;

  const _RestTimerOverlay({required this.secondsLeft, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Descansando', style: AppTextStyles.headingMedium),
          const SizedBox(height: 32),
          // Círculo de temporizador
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$secondsLeft',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 52,
                  ),
                ),
                Text('seg', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Text(
                'Saltar descanso →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo de entrenamiento completado ───
class _CompletionDialog extends StatelessWidget {
  final WorkoutModel workout;
  const _CompletionDialog({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 52),
            const SizedBox(height: 12),
            Text('¡Entrenamiento\ncompletado!',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(workout.name, style: AppTextStyles.neonLabel),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatPill(label: 'Ejercicios', value: '${workout.exercises}', icon: Icons.fitness_center_rounded, color: AppColors.primary),
                _StatPill(label: 'Calorías', value: '${workout.calories}', icon: Icons.fitness_center_rounded, color: AppColors.primary),
                _StatPill(label: 'Minutos', value: '${workout.durationMinutes}', icon: Icons.fitness_center_rounded, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 24),
            NeonButton(
              label: 'Ver resumen',
              fullWidth: true,
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Text('Volver al inicio', style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headingSmall),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
