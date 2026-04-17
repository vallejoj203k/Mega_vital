// lib/presentation/screens/workouts/workouts_screen.dart
// ─────────────────────────────────────────────────────────────────
// Pantalla de entrenamientos con imágenes anatómicas reales.
// - Cuerpo humano PNG de alta calidad (frente/espalda)
// - Regiones musculares táctiles superpuestas
// - Animación suave: cuerpo desaparece → lista de ejercicios aparece
// - Ejercicios con animación de movimiento
// ─────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/data/muscle_data.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/workout_log_provider.dart';
import '../../../services/routine_service.dart';
import '../../../services/workout_log_service.dart';
import '../../widgets/shared_widgets.dart';
import '../workout_log/active_workout_screen.dart';
import '../workout_log/workout_history_screen.dart';
import 'exercise_animations.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  bool    _isFront         = true;
  String? _selectedMuscleId;
  final Set<String> _selectedExIds = {};
  final _routineService = RoutineService();
  List<SavedRoutine> _routines = [];
  late TabController _tabCtrl;

  // Animaciones
  late AnimationController _bodyCtrl;
  late AnimationController _listCtrl;
  late Animation<double>   _bodyFade;
  late Animation<double>   _bodyScale;
  late Animation<Offset>   _listSlide;
  late Animation<double>   _listFade;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadRoutines();

    _bodyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));

    _bodyFade  = CurvedAnimation(parent: _bodyCtrl,
        curve: Curves.easeIn).drive(Tween(begin: 1.0, end: 0.0));
    _bodyScale = CurvedAnimation(parent: _bodyCtrl,
        curve: Curves.easeIn).drive(Tween(begin: 1.0, end: 0.92));
    _listSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _listCtrl, curve: Curves.easeOutCubic));
    _listFade  = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _bodyCtrl.dispose(); _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoutines() async {
    final r = await _routineService.loadRoutines();
    if (mounted) setState(() => _routines = r);
  }

  void _onMuscleTap(String muscleId) {
    HapticFeedback.mediumImpact();
    if (_selectedMuscleId == muscleId) {
      _closeExercises();
    } else {
      setState(() { _selectedMuscleId = muscleId; _selectedExIds.clear(); });
      _bodyCtrl.forward().then((_) => _listCtrl.forward());
    }
  }

  void _closeExercises() {
    _listCtrl.reverse().then((_) {
      setState(() { _selectedMuscleId = null; _selectedExIds.clear(); });
      _bodyCtrl.reverse();
    });
  }

  void _flip() {
    HapticFeedback.lightImpact();
    if (_selectedMuscleId != null) {
      _closeExercises();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _isFront = !_isFront);
      });
    } else {
      setState(() => _isFront = !_isFront);
    }
  }

  void _toggleExercise(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedExIds.contains(id)) _selectedExIds.remove(id);
      else _selectedExIds.add(id);
    });
  }

  void _showSaveDialog() {
    if (_selectedExIds.isEmpty) return;
    final muscle = getMuscleById(_selectedMuscleId ?? '');
    final ctrl   = TextEditingController(text: 'Rutina ${muscle?.name ?? ""}');
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Guardar rutina', style: AppTextStyles.headingSmall),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${_selectedExIds.length} ejercicio(s)', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 16),
        TextField(controller: ctrl, autofocus: true,
            style: AppTextStyles.bodyLarge, cursorColor: AppColors.primary,
            decoration: InputDecoration(
                labelText: 'Nombre de la rutina',
                labelStyle: AppTextStyles.bodyMedium,
                filled: true, fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
        TextButton(
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            final exList = _selectedExIds
                .map((id) => kAllExercises.cast<ExerciseItem?>()
                .firstWhere((e) => e?.id == id, orElse: () => null))
                .whereType<ExerciseItem>().toList();
            await _routineService.saveRoutine(SavedRoutine(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name, muscleId: muscle?.id ?? '',
              muscleName: muscle?.name ?? '', exercises: exList,
              createdAt: DateTime.now(),
            ));
            if (mounted) {
              Navigator.pop(context); _loadRoutines();
              setState(() => _selectedExIds.clear());
            }
          },
          child: Text('Guardar', style: TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final muscle    = _selectedMuscleId != null ? getMuscleById(_selectedMuscleId!) : null;
    final exercises = _selectedMuscleId != null
        ? exercisesForMuscle(_selectedMuscleId!) : <ExerciseItem>[];

    final isMale =
        context.watch<AuthProvider>().profile?.isMale ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        // ── Header ────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Entrenamientos', style: AppTextStyles.displayMedium),
                AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                    child: Text(
                      key: ValueKey(_selectedMuscleId),
                      _selectedMuscleId == null ? 'Toca un músculo para ver ejercicios'
                          : muscle?.name ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: muscle?.color ?? AppColors.textSecondary),
                    )),
              ])),
              if (_selectedExIds.isNotEmpty)
                GestureDetector(
                  onTap: _showSaveDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.save_rounded,
                          color: AppColors.background, size: 14),
                      const SizedBox(width: 6),
                      Text('Guardar ${_selectedExIds.length}',
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.background)),
                    ]),
                  ),
                ),
            ])),
        const SizedBox(height: 10),

        // ── Tabs ──────────────────────────────────────────────────
        _WorkoutTabBar(controller: _tabCtrl),
        const SizedBox(height: 10),

        // ── Contenido ─────────────────────────────────────────────
        Expanded(child: TabBarView(
          controller: _tabCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // ── Tab Cuerpo ────────────────────────────────────────
            Stack(children: [
              // Cuerpo anatómico
              FadeTransition(opacity: _bodyFade,
                child: ScaleTransition(scale: _bodyScale,
                  child: _AnatomyBody(
                    isFront:          _isFront,
                    isMale:           isMale,
                    selectedMuscleId: _selectedMuscleId,
                    onMuscleTap:      _onMuscleTap,
                    onFlip:           _flip,
                  ),
                ),
              ),
              // Lista de ejercicios
              if (_selectedMuscleId != null)
                FadeTransition(opacity: _listFade,
                  child: SlideTransition(position: _listSlide,
                    child: _ExercisePanel(
                      muscle:        muscle!,
                      exercises:     exercises,
                      selectedExIds: _selectedExIds,
                      onToggle:      _toggleExercise,
                      onBack:        _closeExercises,
                    ),
                  ),
                ),
            ]),
            // ── Tab Rutinas ───────────────────────────────────────
            _RoutinesTab(routines: _routines, onDelete: (id) async {
              await _routineService.deleteRoutine(id);
              _loadRoutines();
            }),
            // ── Tab Historial ─────────────────────────────────────
            const _HistorialTab(),
          ],
        )),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CUERPO ANATÓMICO CON IMAGEN PNG
// ─────────────────────────────────────────────────────────────────
class _AnatomyBody extends StatelessWidget {
  final bool    isFront;
  final bool    isMale;
  final String? selectedMuscleId;
  final ValueChanged<String> onMuscleTap;
  final VoidCallback onFlip;

  const _AnatomyBody({required this.isFront, required this.isMale,
    required this.selectedMuscleId, required this.onMuscleTap,
    required this.onFlip});

  @override
  Widget build(BuildContext context) {
    // Músculo activo (si lo hay)
    final muscle = selectedMuscleId != null
        ? getMuscleById(selectedMuscleId!) : null;

    return Column(children: [
      // Barra superior: vista + voltear
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            // Badge frontal/posterior
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isFront ? Icons.face_rounded : Icons.person_outline_rounded,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(isFront ? 'Vista frontal' : 'Vista posterior',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
            const Spacer(),
            GestureDetector(onTap: onFlip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 0.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.flip_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Voltear', style: AppTextStyles.caption),
                  ]),
                )),
          ])),
      const SizedBox(height: 8),

      // Imagen del cuerpo + overlay de regiones
      Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
        // La imagen es ~270×470, mantenemos esa proporción
        const imgW = 270.0;
        const imgH = 470.0;
        final aspect = imgW / imgH;

        final maxH = constraints.maxHeight;
        final maxW = constraints.maxWidth;
        double dispH = maxH;
        double dispW = dispH * aspect;
        if (dispW > maxW * 0.75) {
          dispW = maxW * 0.75;
          dispH = dispW / aspect;
        }

        return Stack(alignment: Alignment.center, children: [
          // ── Imagen PNG anatómica (varía según género del perfil) ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Image.asset(
              key: ValueKey('${isFront}_$isMale'),
              isFront
                  ? (isMale
                      ? 'assets/images/frontal_masculino.png'
                      : 'assets/images/body_front.png')
                  : (isMale
                      ? 'assets/images/trasero_masculino.png'
                      : 'assets/images/body_back.png'),
              width: dispW,
              height: dispH,
              fit: BoxFit.contain,
            ),
          ),

          // ── Overlay de regiones musculares ─────────────────────
          SizedBox(width: dispW, height: dispH,
            child: GestureDetector(
              onTapDown: (d) {
                // Convertir tap a coordenadas de imagen (imgW × imgH)
                final lx = d.localPosition.dx / dispW * imgW;
                final ly = d.localPosition.dy / dispH * imgH;
                final id = _findMuscle(lx, ly, isFront);
                if (id != null) onMuscleTap(id);
              },
              child: CustomPaint(
                painter: _MuscleOverlayPainter(
                  isFront:          isFront,
                  selectedMuscleId: selectedMuscleId,
                  // Pasa el tamaño real para escalar los paths
                  dispW: dispW, dispH: dispH,
                ),
              ),
            ),
          ),

          // ── Hint ───────────────────────────────────────────────
          Positioned(bottom: 4, child: AnimatedOpacity(
            opacity: selectedMuscleId == null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.touch_app_rounded,
                    size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Toca un grupo muscular',
                    style: AppTextStyles.caption),
              ]),
            ),
          )),

          // ── Badge del músculo seleccionado ─────────────────────
          if (muscle != null)
            Positioned(bottom: 4, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: muscle.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: muscle.color.withOpacity(0.5), width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.fitness_center_rounded,
                    size: 12, color: muscle.color),
                const SizedBox(width: 6),
                Text(muscle.name, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: muscle.color)),
              ]),
            )),
        ]);
      })),

      // Leyenda
      _MuscleLegend(isFront: isFront, onTap: onMuscleTap,
          selected: selectedMuscleId),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────
// PATHS CALIBRADOS A LA IMAGEN PNG (espacio 270×470)
// Referencia visual: boxes de colores sobre figura anatómica
// ─────────────────────────────────────────────────────────────────

// FRENTE ──────────────────────────────────────────────────────────

// PECHO
Path _imgPecho() => Path()
  ..moveTo(113, 101)
  ..lineTo(177, 98)
  ..lineTo(186, 147)
  ..lineTo(109, 149)..close();

// HOMBROS
Path _imgHombros() {
  final p = Path();
  // Izquierda
  p.moveTo(85, 84);
  p.lineTo(118, 84);
  p.lineTo(105, 120);
  p.lineTo(59, 138);
  p.close();
  // Derecha
  p.moveTo(178, 84);
  p.lineTo(218, 92);
  p.lineTo(229, 141);
  p.lineTo(187, 114);
  p.close();
  return p;
}

// BÍCEPS
Path _imgBiceps() {
  final p = Path();
  // Izquierda
  p.moveTo(70, 142);
  p.lineTo(109, 122);
  p.lineTo(102, 170);
  p.lineTo(66, 170);
  p.close();
  // Derecha
  p.moveTo(182, 117);
  p.lineTo(218, 136);
  p.lineTo(227, 165);
  p.lineTo(194, 177);
  p.close();
  return p;
}

// ABDOMEN
Path _imgAbdomen() => Path()
  ..moveTo(114, 152)
  ..lineTo(178, 151)
  ..lineTo(173, 226)
  ..lineTo(116, 222)..close();


// CUÁDRICEPS
Path _imgCuadriceps() {
  final p = Path();
  // Izquierda
  p.moveTo(95, 200);
  p.lineTo(150, 252);
  p.lineTo(133, 334);
  p.lineTo(89, 318);
  p.close();
  // Derecha
  p.moveTo(150, 252);
  p.lineTo(193, 199);
  p.lineTo(210, 310);
  p.lineTo(156, 339);
  p.close();
  return p;
}

// GEMELOS
Path _imgGemelos() {
  final p = Path();
  // Izquierda
  p.moveTo(101, 323);
  p.lineTo(127, 347);
  p.lineTo(115, 424);
  p.lineTo(89, 424);
  p.close();
  // Derecha
  p.moveTo(164, 344);
  p.lineTo(205, 320);
  p.lineTo(201, 429);
  p.lineTo(173, 427);
  p.close();
  return p;
}

// ESPALDA ─────────────────────────────────────────────────────────

// ESPALDA ALTA
Path _imgEspaldaAlta() => Path()
  ..moveTo(111, 70)
  ..lineTo(185, 70)
  ..lineTo(188, 116)
  ..lineTo(101, 121)..close();

// DORSALES
Path _imgDorsales() {
  final p = Path();
  // izq
  p.moveTo(98, 125);
  p.lineTo(143, 123);
  p.lineTo(140, 153);
  p.lineTo(99, 158);
  p.close();
  // der
  p.moveTo(151, 124);
  p.lineTo(186, 121);
  p.lineTo(187, 152);
  p.lineTo(149, 152);
  p.close();
  return p;
}

// TRÍCEPS
Path _imgTriceps() {
  final p = Path();
  // izq
  p.moveTo(83, 113);
  p.lineTo(103, 111);
  p.lineTo(93, 172);
  p.lineTo(57, 177);
  p.close();
  // der
  p.moveTo(188, 113);
  p.lineTo(215, 115);
  p.lineTo(224, 175);
  p.lineTo(197, 195);
  p.close();
  return p;
}

// LUMBAR
Path _imgLumbar() => Path()
  ..moveTo(101, 162)
  ..lineTo(186, 159)
  ..lineTo(191, 198)
  ..lineTo(98, 199)..close();

// GLÚTEOS
Path _imgGluteos() => Path()
  ..moveTo(97, 202)
  ..lineTo(198, 201)
  ..lineTo(196, 243)
  ..lineTo(93, 253)..close();

// ISQUIOTIBIALES
Path _imgIsquiotibiales() {
  final p = Path();
  // izq
  p.moveTo(85, 263);
  p.lineTo(143, 256);
  p.lineTo(130, 337);
  p.lineTo(93, 325);
  p.close();
  // der
  p.moveTo(151, 251);
  p.lineTo(202, 249);
  p.lineTo(203, 337);
  p.lineTo(152, 325);
  p.close();
  return p;
}

// ISQUIOTIBIALES
Path _imgIsquiotibiales() {
  final p = Path();
  // izq
  p.moveTo(85, 263);
  p.lineTo(143, 256);
  p.lineTo(130, 337);
  p.lineTo(93, 325);
  p.close();
  // der
  p.moveTo(151, 251);
  p.lineTo(202, 249);
  p.lineTo(203, 337);
  p.lineTo(152, 325);
  p.close();
  return p;
}

// Mapa de paths para cada músculo en espacio 270×470
Map<String, Path> _frontPaths() => {
  'pecho':      _imgPecho(),
  'hombros':    _imgHombros(),
  'biceps':     _imgBiceps(),
  'abs':        _imgAbs(),
  'cuadriceps': _imgCuads(),
  'gemelos':    _imgGemelosF(),
};

Map<String, Path> _backPaths() => {
  'espalda':  _imgEspaldaAlta(),
  'dorsales': _imgDorsales(),
  'triceps':  _imgTriceps(),
  'lumbar':   _imgLumbar(),
  'gluteos':  _imgGluteos(),
  'isquio':   _imgIsquios(),
  'gemelos':  _imgGemelosB(),
};

// Detecta músculo en coordenadas de imagen (270×470)
String? _findMuscle(double lx, double ly, bool isFront) {
  final paths = isFront ? _frontPaths() : _backPaths();
  final pt = Offset(lx, ly);
  for (final entry in paths.entries.toList().reversed) {
    if (entry.value.contains(pt)) return entry.key;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────
// PAINTER: dibuja el overlay de músculos sobre la imagen
// ─────────────────────────────────────────────────────────────────
class _MuscleOverlayPainter extends CustomPainter {
  final bool    isFront;
  final String? selectedMuscleId;
  final double  dispW, dispH;
  const _MuscleOverlayPainter({required this.isFront,
    required this.selectedMuscleId, required this.dispW, required this.dispH});

  // Los paths están en espacio 270×470 → escalar a dispW×dispH
  static const double _srcW = 270.0;
  static const double _srcH = 470.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Solo pintamos si hay un músculo seleccionado
    if (selectedMuscleId == null) return;

    final sx = size.width  / _srcW;
    final sy = size.height / _srcH;
    final paths = isFront ? _frontPaths() : _backPaths();

    final entry = paths.entries
        .where((e) => e.key == selectedMuscleId)
        .firstOrNull;
    if (entry == null) return;

    final muscle = getMuscleById(entry.key);
    if (muscle == null) return;

    final color = muscle.color;
    final m = Matrix4.identity()..scale(sx, sy);
    final scaledPath = entry.value.transform(m.storage);

    // Glow exterior suave
    canvas.drawPath(scaledPath, Paint()
      ..color = color.withOpacity(0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // Relleno suave del músculo seleccionado
    canvas.drawPath(scaledPath, Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.fill);

    // Borde sutil del músculo seleccionado
    canvas.drawPath(scaledPath, Paint()
      ..color = color.withOpacity(0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_MuscleOverlayPainter o) =>
      o.isFront != isFront || o.selectedMuscleId != selectedMuscleId;
}

// ─────────────────────────────────────────────────────────────────
// PANEL DE EJERCICIOS
// ─────────────────────────────────────────────────────────────────
class _ExercisePanel extends StatelessWidget {
  final MuscleGroup      muscle;
  final List<ExerciseItem> exercises;
  final Set<String>      selectedExIds;
  final ValueChanged<String> onToggle;
  final VoidCallback     onBack;

  const _ExercisePanel({required this.muscle, required this.exercises,
    required this.selectedExIds, required this.onToggle, required this.onBack});

  @override
  Widget build(BuildContext context) => Column(children: [
    // Header
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          GestureDetector(onTap: onBack,
              child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: muscle.color.withOpacity(0.3), width: 0.5)),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: muscle.color, size: 14))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(muscle.name, style: AppTextStyles.headingSmall
                    .copyWith(color: muscle.color)),
                Text('${exercises.length} ejercicios · toca para seleccionar',
                    style: AppTextStyles.caption),
              ])),
        ])),
    const SizedBox(height: 10),
    // Lista
    Expanded(child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ExerciseCard(
        exercise:    exercises[i],
        muscleColor: muscle.color,
        selected:    selectedExIds.contains(exercises[i].id),
        onToggle:    () => onToggle(exercises[i].id),
      ),
    )),
  ]);
}

// ─────────────────────────────────────────────────────────────────
// TARJETA DE EJERCICIO CON ANIMACIÓN
// ─────────────────────────────────────────────────────────────────
class _ExerciseCard extends StatefulWidget {
  final ExerciseItem exercise;
  final Color muscleColor;
  final bool  selected;
  final VoidCallback onToggle;
  const _ExerciseCard({required this.exercise, required this.muscleColor,
    required this.selected, required this.onToggle});
  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _showAnim = false;

  @override
  Widget build(BuildContext context) {
    final ex  = widget.exercise;
    final col = widget.muscleColor;
    final sel = widget.selected;

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: sel ? col.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? col.withOpacity(0.45) : AppColors.border,
              width: sel ? 1.5 : 0.5),
          boxShadow: sel ? [BoxShadow(
              color: col.withOpacity(0.12), blurRadius: 10)] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Fila principal ──────────────────────────────────────
          Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Botón de animación
                GestureDetector(
                  onTap: () => setState(() => _showAnim = !_showAnim),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: _showAnim ? col.withOpacity(0.15) : col.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _showAnim ? col.withOpacity(0.6) : col.withOpacity(0.25),
                            width: _showAnim ? 1.5 : 0.5)),
                    child: _showAnim
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ExerciseAnimationWidget(
                          exerciseId: ex.id,
                          color: col,
                          size: 52,
                        ))
                        : Stack(alignment: Alignment.center, children: [
                      Icon(ex.icon, color: col, size: 24),
                      Positioned(bottom: 3, right: 3,
                          child: Container(width: 14, height: 14,
                              decoration: BoxDecoration(
                                  color: col, shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow_rounded,
                                  size: 10, color: Colors.black))),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(ex.name, style: AppTextStyles.labelLarge,
                            overflow: TextOverflow.ellipsis)),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                              color: sel ? col : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: sel ? col : AppColors.border, width: 1.5)),
                          child: sel ? const Icon(Icons.check_rounded,
                              color: Colors.black, size: 13) : null,
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Wrap(spacing: 10, children: [
                        _Chip(ex.sets, Icons.repeat_rounded, col),
                        _Chip(ex.reps, Icons.timer_rounded, col),
                        if (sel) _Chip('${ex.restSeconds}s descanso',
                            Icons.hourglass_empty_rounded, col),
                      ]),
                    ])),
              ])),

          // ── Animación expandida ─────────────────────────────────
          if (_showAnim) ...[
            Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                      color: col.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: col.withOpacity(0.15), width: 0.5)),
                  child: Stack(children: [
                    Center(child: ExerciseAnimationWidget(
                        exerciseId: ex.id, color: col, size: 110)),
                    Positioned(top: 8, right: 8,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: col.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('Ver movimiento',
                                style: TextStyle(fontSize: 9,
                                    color: col, fontWeight: FontWeight.w600)))),
                  ]),
                )),
          ],

          // ── Tip ────────────────────────────────────────────────
          if (ex.tip != null)
            Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: col.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 11, color: col),
                          const SizedBox(width: 5),
                          Expanded(child: Text(ex.tip!, style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary))),
                        ]))),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text; final IconData icon; final Color color;
  const _Chip(this.text, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 10, color: color.withOpacity(0.7)),
    const SizedBox(width: 3),
    Text(text, style: AppTextStyles.caption),
  ]);
}

// ─────────────────────────────────────────────────────────────────
// LEYENDA DE MÚSCULOS
// ─────────────────────────────────────────────────────────────────
class _MuscleLegend extends StatelessWidget {
  final bool    isFront;
  final String? selected;
  final ValueChanged<String> onTap;
  const _MuscleLegend({required this.isFront, required this.selected,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    final muscles = kMuscleGroups.where((m) => m.isFront == isFront).toList();
    return SizedBox(height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: muscles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m   = muscles[i];
          final sel = selected == m.id;
          return GestureDetector(
            onTap: () => onTap(m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: sel ? m.color.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel ? m.color.withOpacity(0.5) : Colors.transparent,
                      width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: m.color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(m.nameShort, style: AppTextStyles.caption.copyWith(
                    color: sel ? m.color : null,
                    fontWeight: sel ? FontWeight.w700 : null)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// RUTINAS GUARDADAS
// ─────────────────────────────────────────────────────────────────
class _RoutinesTab extends StatelessWidget {
  final List<SavedRoutine> routines;
  final ValueChanged<String> onDelete;
  const _RoutinesTab({required this.routines, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.surfaceVariant,
              shape: BoxShape.circle),
          child: const Icon(Icons.fitness_center_rounded,
              color: AppColors.textMuted, size: 32)),
      const SizedBox(height: 16),
      Text('Sin rutinas guardadas', style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      Text('Selecciona ejercicios y guárdalos como rutina',
          style: AppTextStyles.bodyMedium),
    ]));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: routines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RoutineCard(
          routine: routines[i], onDelete: () => onDelete(routines[i].id)),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final SavedRoutine routine; final VoidCallback onDelete;
  const _RoutineCard({required this.routine, required this.onDelete});

  Future<void> _startWorkout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final provider = context.read<WorkoutLogProvider>();
    if (provider.hasActiveSession) {
      final resume = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Entrenamiento en curso',
              style: AppTextStyles.headingSmall),
          content: Text(
              'Ya tienes un entrenamiento activo. ¿Quieres retomarlo?',
              style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.textSecondary))),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Retomar',
                    style: TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.w700))),
          ],
        ),
      );
      if (resume == true && context.mounted) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => const ActiveWorkoutScreen()));
      }
      return;
    }
    await provider.startSession(routine.name, routine.exercises);
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final muscle = getMuscleById(routine.muscleId);
    final color  = muscle?.color ?? AppColors.primary;
    return DarkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            BoxedIcon(icon: Icons.fitness_center_rounded, color: color, size: 42),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name, style: AppTextStyles.labelLarge),
                  Text('${routine.exercises.length} ejercicios · ${routine.muscleName}',
                      style: AppTextStyles.caption),
                ])),
            GestureDetector(onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textMuted, size: 20)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6,
              children: routine.exercises.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2), width: 0.5)),
                child: Text(e.name, style: AppTextStyles.caption.copyWith(color: color)),
              )).toList()),
          const SizedBox(height: 12),
          // ── Botón Iniciar ─────────────────────────────────────
          GestureDetector(
            onTap: () => _startWorkout(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3), width: 0.8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text('Iniciar entrenamiento',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: color)),
                  ]),
            ),
          ),
        ]));
  }
}

// ── Tab de Historial (integrado) ──────────────────────────────────
class _HistorialTab extends StatefulWidget {
  const _HistorialTab();
  @override
  State<_HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<_HistorialTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Set<String> _expandedIds = {};

  String _formatDate(DateTime d) {
    const days   = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    const months = ['ene','feb','mar','abr','may','jun',
      'jul','ago','sep','oct','nov','dic'];
    return '${days[d.weekday-1]} ${d.day} ${months[d.month-1]}';
  }

  String _formatDuration(int m) {
    if (m == 0) return '—';
    if (m < 60) return '${m}min';
    final h = m ~/ 60; final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}min';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider  = context.watch<WorkoutLogProvider>();
    final completed = provider.history.where((s) => s.isCompleted).toList();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(
          color: AppColors.primary, strokeWidth: 2));
    }

    if (completed.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 72, height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded,
                  color: AppColors.textMuted, size: 34)),
          const SizedBox(height: 16),
          Text('Sin entrenamientos aún',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text('Inicia una rutina para registrar\ntu progreso aquí',
              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ));
    }

    // Totales rápidos
    final totalSeries = completed.fold(0, (s, e) => s + e.totalDoneSets);
    final totalVol    = completed.fold(0.0, (s, e) => s + e.totalVolume);

    return Column(children: [
      // Resumen compacto
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: Row(children: [
            _MiniStat('${completed.length}', 'Sesiones', AppColors.primary),
            _VertDiv(),
            _MiniStat('$totalSeries', 'Series', AppColors.accentBlue),
            _VertDiv(),
            _MiniStat(
                totalVol >= 1000
                    ? '${(totalVol/1000).toStringAsFixed(1)}t'
                    : '${totalVol.toStringAsFixed(0)}kg',
                'Volumen', AppColors.accentOrange),
          ]),
        ),
      ),

      // Lista de sesiones
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        physics: const BouncingScrollPhysics(),
        itemCount: completed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final session  = completed[i];
          final isExpanded = _expandedIds.contains(session.id);

          return Dismissible(
            key: ValueKey(session.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
            ),
            confirmDismiss: (_) async {
              final ok = await showDialog<bool>(
                context: ctx,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('¿Eliminar sesión?',
                      style: AppTextStyles.headingSmall),
                  content: Text('Esta acción no se puede deshacer.',
                      style: AppTextStyles.bodyMedium),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancelar',
                            style: TextStyle(color: AppColors.textSecondary))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Eliminar',
                            style: TextStyle(color: AppColors.error,
                                fontWeight: FontWeight.w700))),
                  ],
                ),
              );
              if (ok == true) {
                await ctx.read<WorkoutLogProvider>().deleteSession(session.id);
              }
              return false;
            },
            child: GestureDetector(
              onTap: () => setState(() {
                if (isExpanded) _expandedIds.remove(session.id);
                else _expandedIds.add(session.id);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
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
                      // Encabezado
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Row(children: [
                          Container(width: 38, height: 38,
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.primary.withOpacity(0.25),
                                      width: 0.5)),
                              child: const Icon(Icons.fitness_center_rounded,
                                  color: AppColors.primary, size: 18)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(session.name, style: AppTextStyles.labelLarge,
                                    overflow: TextOverflow.ellipsis),
                                Text(_formatDate(session.date),
                                    style: AppTextStyles.caption),
                              ])),
                          Icon(isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                              color: AppColors.textMuted, size: 20),
                        ]),
                      ),

                      // Chips resumen
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Wrap(spacing: 6, runSpacing: 6, children: [
                          _HistChip(Icons.timer_rounded,
                              _formatDuration(session.durationMinutes),
                              AppColors.accentBlue),
                          _HistChip(Icons.fitness_center_rounded,
                              '${session.completedExercises} ejercicios',
                              AppColors.accentPurple),
                          _HistChip(Icons.repeat_rounded,
                              '${session.totalDoneSets} series',
                              AppColors.primary),
                          if (session.totalVolume > 0)
                            _HistChip(Icons.bar_chart_rounded,
                                session.totalVolume >= 1000
                                    ? '${(session.totalVolume/1000).toStringAsFixed(1)}t'
                                    : '${session.totalVolume.toStringAsFixed(0)} kg',
                                AppColors.accentOrange),
                        ]),
                      ),

                      // Detalle expandible
                      if (isExpanded)
                        _InlineSessionDetail(session: session),
                    ]),
              ),
            ),
          );
        },
      )),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: AppTextStyles.headingMedium.copyWith(color: color)),
    Text(label, style: AppTextStyles.caption),
  ]));
}

class _VertDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 28, color: AppColors.border,
          margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _HistChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _HistChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

class _InlineSessionDetail extends StatelessWidget {
  final WorkoutSession session;
  const _InlineSessionDetail({required this.session});

  String _bestSet(LoggedExercise ex) {
    final done = ex.sets.where((s) => s.isDone).toList();
    if (done.isEmpty) return '—';
    done.sort((a, b) => (b.weight * b.reps).compareTo(a.weight * a.reps));
    final best = done.first;
    final w = best.weight > 0
        ? (best.weight == best.weight.truncateToDouble()
        ? '${best.weight.toInt()} kg'
        : '${best.weight.toStringAsFixed(1)} kg')
        : 'Corporal';
    return '$w × ${best.reps} reps';
  }

  @override
  Widget build(BuildContext context) {
    final exDone = session.exercises.where((e) => e.doneSets > 0).toList();
    if (exDone.isEmpty) {
      return Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Text('Sin series completadas', style: AppTextStyles.caption));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: exDone.map((ex) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(ex.exerciseName,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary, fontSize: 11),
                overflow: TextOverflow.ellipsis)),
            Text('${ex.doneSets} series  ·  ${_bestSet(ex)}',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary, fontSize: 10)),
          ]),
        )).toList(),
      ),
    );
  }
}

// ── TabBar ─────────────────────────────────────────────────────────
class _WorkoutTabBar extends StatelessWidget {
  final TabController controller;
  const _WorkoutTabBar({required this.controller});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(height: 40,
        decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: TabBar(controller: controller,
          indicator: BoxDecoration(gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: AppColors.background,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Cuerpo'),
            Tab(text: 'Rutinas'),
            Tab(text: 'Historial'),
          ],
        )),
  );
}
