// lib/presentation/screens/workouts/exercise_animations.dart
// ─────────────────────────────────────────────────────────────────
// Animaciones educativas de ejercicios mediante stick figures.
// Cada ejercicio tiene una animación personalizada que muestra
// claramente el movimiento correcto.
// ─────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// ── Mapa de videos disponibles ────────────────────────────────────
// Clave: ID del ejercicio (exercise_database.dart) → ruta del asset MP4.
// Agregar una línea por cada video que subas.
const _videoAssets = <String, String>{
  'pec1': 'assets/animations/exercises/pectoral/pec1.mp4',
  // 'pec2': 'assets/animations/exercises/pectoral/pec2.mp4',
  // 'pec3': 'assets/animations/exercises/pectoral/pec3.mp4',
};

// ── Widget principal (router) ─────────────────────────────────────
// Si existe video para el ejercicio lo reproduce en bucle;
// si no, muestra el stickman animado como fallback.
class ExerciseAnimationWidget extends StatelessWidget {
  final String exerciseId;
  final Color  color;
  final double size;

  const ExerciseAnimationWidget({
    super.key,
    required this.exerciseId,
    required this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final videoPath = _videoAssets[exerciseId];
    if (videoPath != null) {
      return _VideoLoopWidget(assetPath: videoPath, size: size);
    }
    return _StickmanWidget(exerciseId: exerciseId, color: color, size: size);
  }
}

// ── Reproductor de video en bucle ─────────────────────────────────
class _VideoLoopWidget extends StatefulWidget {
  final String assetPath;
  final double size;
  const _VideoLoopWidget({required this.assetPath, required this.size});

  @override
  State<_VideoLoopWidget> createState() => _VideoLoopWidgetState();
}

class _VideoLoopWidgetState extends State<_VideoLoopWidget> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _ctrl
            ..setLooping(true)
            ..setVolume(0)
            ..play();
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return SizedBox(width: widget.size, height: widget.size * 1.15);
    }
    return SizedBox(
      width:  widget.size,
      height: widget.size * 1.15,
      child: ClipRect(
        child: AspectRatio(
          aspectRatio: _ctrl.value.aspectRatio,
          child: VideoPlayer(_ctrl),
        ),
      ),
    );
  }
}

// ── Stickman animado (fallback) ───────────────────────────────────
class _StickmanWidget extends StatefulWidget {
  final String exerciseId;
  final Color  color;
  final double size;
  const _StickmanWidget({
    required this.exerciseId,
    required this.color,
    this.size = 120,
  });

  @override
  State<_StickmanWidget> createState() => _StickmanWidgetState();
}

class _StickmanWidgetState extends State<_StickmanWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    final info = _exerciseInfo(widget.exerciseId);
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: info.durationMs),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: info.curve);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final info = _exerciseInfo(widget.exerciseId);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size * 1.15),
        painter: _StickFigurePainter(
          t:     _anim.value,
          type:  info.type,
          color: widget.color,
        ),
      ),
    );
  }
}

// ── Info de la animación ──────────────────────────────────────────
class _AnimInfo {
  final _AnimType type;
  final int       durationMs;
  final Curve     curve;
  const _AnimInfo(this.type, {this.durationMs = 900, this.curve = Curves.easeInOut});
}

enum _AnimType {
  pressFlat,          // press banca plano
  pressIncline,       // press inclinado
  pressDecline,       // press declinado
  pressOverhead,      // press militar / Arnold
  pressSittingDB,     // press con mancuernas sentado
  fly,                // aperturas / crossover
  cableFly,           // crossover polea
  curl,               // curl bíceps
  curlHammer,         // curl martillo
  curlConcentrated,   // curl concentrado
  row,                // remo
  rowSeated,          // remo sentado
  shrug,              // encogimientos
  facePull,           // face pulls
  pullUp,             // dominadas
  latPulldown,        // jalón
  pullover,           // pullover
  straightPulldown,   // straight arm pulldown
  tricepExtension,    // extensión tríceps overhead
  tricepPushdown,     // polea tríceps
  tricepKickback,     // kickback
  tricepPress,        // fondos tríceps / press cerrado
  squat,              // sentadilla
  lunge,              // zancada
  legPress,           // prensa
  legExtension,       // extensión piernas
  bulgarianSplit,     // sentadilla búlgara
  stepUp,             // step-up
  calfRaise,          // elevación talones de pie
  calfRaiseSeated,    // elevación talones sentado
  jumpRope,           // saltos cuerda
  plank,              // plancha frontal
  plankSide,          // plancha lateral
  crunch,             // crunches
  legRaise,           // elevación piernas colgado
  russianTwist,       // russian twist
  deadBug,            // dead bug
  abWheel,            // ab wheel
  hollowHold,         // hollow hold
  deadlift,           // peso muerto
  hyperextension,     // hiperextensiones
  goodMorning,        // buenos días
  superman,           // superman
  birdDog,            // bird dog
  hipThrust,          // hip thrust
  bridgeGlute,        // puente glúteos
  cableKickback,      // patada trasera cable
  abductorMachine,    // abductor máquina
  sumoDeadlift,       // peso muerto sumo
  legCurl,            // curl femoral
  romanianDeadlift,   // peso muerto rumano
  nordicCurl,         // nordic curl
  gluteHamRaise,      // glute ham raise
}

_AnimInfo _exerciseInfo(String id) {
  const map = <String, _AnimInfo>{
    // PECHO
    'pec1': _AnimInfo(_AnimType.pressFlat,    durationMs: 900),
    'pec2': _AnimInfo(_AnimType.pressIncline, durationMs: 900),
    'pec3': _AnimInfo(_AnimType.cableFly,     durationMs: 1000),
    'pec4': _AnimInfo(_AnimType.tricepPress,  durationMs: 850),
    'pec5': _AnimInfo(_AnimType.pressFlat,    durationMs: 900),
    'pec6': _AnimInfo(_AnimType.fly,          durationMs: 1000),
    'pec7': _AnimInfo(_AnimType.pressDecline, durationMs: 900),
    'pec8': _AnimInfo(_AnimType.cableFly,     durationMs: 1000),
    // HOMBROS
    'hom1': _AnimInfo(_AnimType.pressOverhead,  durationMs: 900),
    'hom2': _AnimInfo(_AnimType.fly,            durationMs: 950),
    'hom3': _AnimInfo(_AnimType.fly,            durationMs: 950),
    'hom4': _AnimInfo(_AnimType.pressOverhead,  durationMs: 1000),
    'hom5': _AnimInfo(_AnimType.facePull,       durationMs: 900),
    'hom6': _AnimInfo(_AnimType.pressSittingDB, durationMs: 900),
    'hom7': _AnimInfo(_AnimType.fly,            durationMs: 950),
    // BÍCEPS
    'bic1': _AnimInfo(_AnimType.curl,            durationMs: 800),
    'bic2': _AnimInfo(_AnimType.curl,            durationMs: 800),
    'bic3': _AnimInfo(_AnimType.curlHammer,      durationMs: 800),
    'bic4': _AnimInfo(_AnimType.curlConcentrated,durationMs: 850),
    'bic5': _AnimInfo(_AnimType.curl,            durationMs: 850),
    'bic6': _AnimInfo(_AnimType.curl,            durationMs: 700),
    'bic7': _AnimInfo(_AnimType.curl,            durationMs: 850),
    // ABS
    'abs1': _AnimInfo(_AnimType.plank,        durationMs: 1200),
    'abs2': _AnimInfo(_AnimType.crunch,       durationMs: 900),
    'abs3': _AnimInfo(_AnimType.legRaise,     durationMs: 1000),
    'abs4': _AnimInfo(_AnimType.russianTwist, durationMs: 700),
    'abs5': _AnimInfo(_AnimType.deadBug,      durationMs: 1100),
    'abs6': _AnimInfo(_AnimType.plankSide,    durationMs: 1200),
    'abs7': _AnimInfo(_AnimType.abWheel,      durationMs: 1100),
    'abs8': _AnimInfo(_AnimType.hollowHold,   durationMs: 1200),
    // CUÁDRICEPS
    'cua1': _AnimInfo(_AnimType.squat,          durationMs: 950),
    'cua2': _AnimInfo(_AnimType.legPress,       durationMs: 900),
    'cua3': _AnimInfo(_AnimType.legExtension,   durationMs: 850),
    'cua4': _AnimInfo(_AnimType.lunge,          durationMs: 950),
    'cua5': _AnimInfo(_AnimType.squat,          durationMs: 950),
    'cua6': _AnimInfo(_AnimType.bulgarianSplit, durationMs: 950),
    'cua7': _AnimInfo(_AnimType.stepUp,         durationMs: 900),
    // GEMELOS
    'gem1': _AnimInfo(_AnimType.calfRaise,       durationMs: 700),
    'gem2': _AnimInfo(_AnimType.calfRaiseSeated, durationMs: 700),
    'gem3': _AnimInfo(_AnimType.calfRaise,       durationMs: 700),
    'gem4': _AnimInfo(_AnimType.legPress,        durationMs: 800),
    'gem5': _AnimInfo(_AnimType.jumpRope,        durationMs: 500),
    // ESPALDA
    'esp1': _AnimInfo(_AnimType.row,        durationMs: 850),
    'esp2': _AnimInfo(_AnimType.rowSeated,  durationMs: 850),
    'esp3': _AnimInfo(_AnimType.shrug,      durationMs: 750),
    'esp4': _AnimInfo(_AnimType.facePull,   durationMs: 850),
    'esp5': _AnimInfo(_AnimType.row,        durationMs: 850),
    'esp6': _AnimInfo(_AnimType.row,        durationMs: 850),
    // DORSALES
    'dor1': _AnimInfo(_AnimType.pullUp,            durationMs: 1000),
    'dor2': _AnimInfo(_AnimType.latPulldown,       durationMs: 900),
    'dor3': _AnimInfo(_AnimType.latPulldown,       durationMs: 900),
    'dor4': _AnimInfo(_AnimType.pullover,          durationMs: 1000),
    'dor5': _AnimInfo(_AnimType.straightPulldown,  durationMs: 900),
    'dor6': _AnimInfo(_AnimType.rowSeated,         durationMs: 850),
    // TRÍCEPS
    'tri1': _AnimInfo(_AnimType.tricepExtension, durationMs: 850),
    'tri2': _AnimInfo(_AnimType.tricepPushdown,  durationMs: 800),
    'tri3': _AnimInfo(_AnimType.tricepPress,     durationMs: 850),
    'tri4': _AnimInfo(_AnimType.tricepKickback,  durationMs: 850),
    'tri5': _AnimInfo(_AnimType.pressFlat,       durationMs: 900),
    'tri6': _AnimInfo(_AnimType.tricepExtension, durationMs: 850),
    'tri7': _AnimInfo(_AnimType.tricepPushdown,  durationMs: 800),
    // LUMBAR
    'lum1': _AnimInfo(_AnimType.deadlift,        durationMs: 1000),
    'lum2': _AnimInfo(_AnimType.hyperextension,  durationMs: 950),
    'lum3': _AnimInfo(_AnimType.goodMorning,     durationMs: 1000),
    'lum4': _AnimInfo(_AnimType.superman,        durationMs: 1000),
    'lum5': _AnimInfo(_AnimType.birdDog,         durationMs: 1100),
    // GLÚTEOS
    'glu1': _AnimInfo(_AnimType.hipThrust,       durationMs: 900),
    'glu2': _AnimInfo(_AnimType.bulgarianSplit,  durationMs: 950),
    'glu3': _AnimInfo(_AnimType.bridgeGlute,     durationMs: 850),
    'glu4': _AnimInfo(_AnimType.cableKickback,   durationMs: 900),
    'glu5': _AnimInfo(_AnimType.abductorMachine, durationMs: 900),
    'glu6': _AnimInfo(_AnimType.sumoDeadlift,    durationMs: 1000),
    // ISQUIOTIBIALES
    'isq1': _AnimInfo(_AnimType.legCurl,          durationMs: 850),
    'isq2': _AnimInfo(_AnimType.romanianDeadlift, durationMs: 1000),
    'isq3': _AnimInfo(_AnimType.romanianDeadlift, durationMs: 1000),
    'isq4': _AnimInfo(_AnimType.nordicCurl,       durationMs: 1100),
    'isq5': _AnimInfo(_AnimType.legCurl,          durationMs: 850),
    'isq6': _AnimInfo(_AnimType.gluteHamRaise,    durationMs: 1000),
  };
  return map[id] ?? const _AnimInfo(_AnimType.curl);
}

// ─────────────────────────────────────────────────────────────────
// PAINTER PRINCIPAL — dibuja el stick figure según el tipo
// ─────────────────────────────────────────────────────────────────
class _StickFigurePainter extends CustomPainter {
  final double    t;     // 0.0 → 1.0 (animación)
  final _AnimType type;
  final Color     color;

  const _StickFigurePainter({required this.t, required this.type,
    required this.color});

  // ── Pinceles ──────────────────────────────────────────────────
  Paint get _body => Paint()
    ..color = const Color(0xFFB0C8E0)
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint get _active => Paint()
    ..color = color
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint get _headFill => Paint()
    ..color = const Color(0xFFD0E4F0)
    ..style = PaintingStyle.fill;

  Paint _barPaint(double w) => Paint()
    ..color = const Color(0xFF607080)
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint _platePaint(Color c) => Paint()..color = c..style = PaintingStyle.fill;

  // ── Utilidades ────────────────────────────────────────────────
  double lerp(double a, double b) => a + (b - a) * t;
  Offset lerpO(Offset a, Offset b) =>
      Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

  void _head(Canvas c, Offset pos, double r) {
    c.drawCircle(pos, r, _headFill);
    c.drawCircle(pos, r, _body..style = PaintingStyle.stroke);
  }

  void _line(Canvas c, Offset a, Offset b, Paint p) =>
      c.drawLine(a, b, p);


  // ── Dibuja barra con discos ───────────────────────────────────
  void _bar(Canvas c, Offset l, Offset r, {double w = 6, double plateH = 14, double plateW = 5}) {
    c.drawLine(l, r, _barPaint(w));
    // Discos izquierda
    final lx = l.dx - plateW; final ly = l.dy;
    c.drawRect(Rect.fromLTWH(lx - plateW, ly - plateH/2, plateW, plateH),
        _platePaint(color.withOpacity(0.8)));
    // Discos derecha
    c.drawRect(Rect.fromLTWH(r.dx, r.dy - plateH/2, plateW, plateH),
        _platePaint(color.withOpacity(0.8)));
  }

  // ─────────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width;
    final h = sz.height;

    // Centrar el sistema de coordenadas
    // Trabajamos en espacio normalizado 0..100 x 0..115
    canvas.save();
    canvas.scale(w / 100, h / 115);

    switch (type) {
      case _AnimType.pressFlat:         _drawPressFlat(canvas);         break;
      case _AnimType.pressIncline:      _drawPressIncline(canvas);      break;
      case _AnimType.pressDecline:      _drawPressDecline(canvas);      break;
      case _AnimType.pressOverhead:     _drawPressOverhead(canvas);     break;
      case _AnimType.pressSittingDB:    _drawPressSittingDB(canvas);    break;
      case _AnimType.fly:               _drawFly(canvas);               break;
      case _AnimType.cableFly:          _drawCableFly(canvas);          break;
      case _AnimType.curl:              _drawCurl(canvas);              break;
      case _AnimType.curlHammer:        _drawCurlHammer(canvas);        break;
      case _AnimType.curlConcentrated:  _drawCurlConc(canvas);          break;
      case _AnimType.row:               _drawRow(canvas);               break;
      case _AnimType.rowSeated:         _drawRowSeated(canvas);         break;
      case _AnimType.shrug:             _drawShrug(canvas);             break;
      case _AnimType.facePull:          _drawFacePull(canvas);          break;
      case _AnimType.pullUp:            _drawPullUp(canvas);            break;
      case _AnimType.latPulldown:       _drawLatPulldown(canvas);       break;
      case _AnimType.pullover:          _drawPullover(canvas);          break;
      case _AnimType.straightPulldown:  _drawStraightPulldown(canvas);  break;
      case _AnimType.tricepExtension:   _drawTricepExt(canvas);         break;
      case _AnimType.tricepPushdown:    _drawTricepPushdown(canvas);    break;
      case _AnimType.tricepKickback:    _drawTricepKickback(canvas);    break;
      case _AnimType.tricepPress:       _drawTricepPress(canvas);       break;
      case _AnimType.squat:             _drawSquat(canvas);             break;
      case _AnimType.lunge:             _drawLunge(canvas);             break;
      case _AnimType.legPress:          _drawLegPress(canvas);          break;
      case _AnimType.legExtension:      _drawLegExtension(canvas);      break;
      case _AnimType.bulgarianSplit:    _drawBulgarianSplit(canvas);    break;
      case _AnimType.stepUp:            _drawStepUp(canvas);            break;
      case _AnimType.calfRaise:         _drawCalfRaise(canvas);         break;
      case _AnimType.calfRaiseSeated:   _drawCalfRaiseSeated(canvas);   break;
      case _AnimType.jumpRope:          _drawJumpRope(canvas);          break;
      case _AnimType.plank:             _drawPlank(canvas);             break;
      case _AnimType.plankSide:         _drawPlankSide(canvas);         break;
      case _AnimType.crunch:            _drawCrunch(canvas);            break;
      case _AnimType.legRaise:          _drawLegRaise(canvas);          break;
      case _AnimType.russianTwist:      _drawRussianTwist(canvas);      break;
      case _AnimType.deadBug:           _drawDeadBug(canvas);           break;
      case _AnimType.abWheel:           _drawAbWheel(canvas);           break;
      case _AnimType.hollowHold:        _drawHollowHold(canvas);        break;
      case _AnimType.deadlift:          _drawDeadlift(canvas);          break;
      case _AnimType.hyperextension:    _drawHyperextension(canvas);    break;
      case _AnimType.goodMorning:       _drawGoodMorning(canvas);       break;
      case _AnimType.superman:          _drawSuperman(canvas);          break;
      case _AnimType.birdDog:           _drawBirdDog(canvas);           break;
      case _AnimType.hipThrust:         _drawHipThrust(canvas);         break;
      case _AnimType.bridgeGlute:       _drawBridgeGlute(canvas);       break;
      case _AnimType.cableKickback:     _drawCableKickback(canvas);     break;
      case _AnimType.abductorMachine:   _drawAbductor(canvas);          break;
      case _AnimType.sumoDeadlift:      _drawSumoDeadlift(canvas);      break;
      case _AnimType.legCurl:           _drawLegCurl(canvas);           break;
      case _AnimType.romanianDeadlift:  _drawRomanianDL(canvas);        break;
      case _AnimType.nordicCurl:        _drawNordicCurl(canvas);        break;
      case _AnimType.gluteHamRaise:     _drawGluteHamRaise(canvas);     break;
    }
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // PRESS PLANO — figura acostada, brazos empujando hacia arriba
  // ─────────────────────────────────────────────────────────────
  void _drawPressFlat(Canvas c) {
    // Banco
    c.drawLine(const Offset(10, 80), const Offset(90, 80), _barPaint(4));
    // Figura acostada
    _head(c, const Offset(18, 70), 8);
    // Torso horizontal
    _line(c, const Offset(18, 78), const Offset(70, 78), _body);
    // Piernas
    _line(c, const Offset(70, 78), const Offset(82, 90), _body);
    _line(c, const Offset(82, 90), const Offset(90, 90), _body);
    _line(c, const Offset(70, 78), const Offset(78, 90), _body);
    _line(c, const Offset(78, 90), const Offset(84, 90), _body);

    // Brazos: t=0 doblados, t=1 extendidos
    final handY = lerp(52, 30);
    final elbowY = lerp(58, 44);
    final shoulderX = 45.0;
    _line(c, Offset(shoulderX, 78), Offset(36, elbowY), _active);
    _line(c, Offset(36, elbowY), Offset(28, handY), _active);
    _line(c, Offset(shoulderX, 78), Offset(54, elbowY), _active);
    _line(c, Offset(54, elbowY), Offset(62, handY), _active);

    // Barra
    _bar(c, Offset(20, handY), Offset(70, handY), w: 5, plateH: 12, plateW: 4);
  }

  // PRESS INCLINADO
  void _drawPressIncline(Canvas c) {
    // Banco inclinado (~45°)
    c.drawLine(const Offset(15, 85), const Offset(70, 55), _barPaint(4));
    // Figura inclinada
    _head(c, const Offset(22, 48), 8);
    final torsoA = const Offset(28, 54);
    final torsoB = const Offset(60, 74);
    _line(c, torsoA, torsoB, _body);
    // Piernas
    _line(c, torsoB, Offset(72, 90), _body);
    _line(c, Offset(72, 90), Offset(82, 92), _body);
    _line(c, torsoB, Offset(66, 90), _body);
    _line(c, Offset(66, 90), Offset(75, 92), _body);
    // Brazos en press inclinado
    final handY = lerp(30, 14);
    final elbowX = lerp(36, 42);
    final elbowY = lerp(44, 32);
    _line(c, Offset(37, 58), Offset(elbowX - 6, elbowY), _active);
    _line(c, Offset(elbowX - 6, elbowY), Offset(32, handY), _active);
    _line(c, Offset(47, 62), Offset(elbowX + 6, elbowY + 2), _active);
    _line(c, Offset(elbowX + 6, elbowY + 2), Offset(58, handY), _active);
    _bar(c, Offset(22, handY), Offset(68, handY), w: 5, plateH: 10, plateW: 4);
  }

  // PRESS DECLINADO
  void _drawPressDecline(Canvas c) {
    c.drawLine(const Offset(15, 55), const Offset(70, 75), _barPaint(4));
    _head(c, const Offset(20, 78), 8);
    _line(c, const Offset(22, 86), const Offset(62, 68), _body);
    _line(c, const Offset(22, 86), const Offset(18, 100), _body);
    _line(c, const Offset(18, 100), const Offset(24, 102), _body);
    final handY = lerp(52, 38);
    _line(c, const Offset(36, 72), Offset(28, lerp(62, 50)), _active);
    _line(c, Offset(28, lerp(62, 50)), Offset(22, handY), _active);
    _line(c, const Offset(52, 68), Offset(58, lerp(62, 50)), _active);
    _line(c, Offset(58, lerp(62, 50)), Offset(64, handY), _active);
    _bar(c, Offset(14, handY), Offset(72, handY), w: 5, plateH: 10, plateW: 4);
  }

  // PRESS OVERHEAD de pie
  void _drawPressOverhead(Canvas c) {
    // Suelo
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(50, 18), 9);
    _line(c, const Offset(50, 27), const Offset(50, 65), _body);
    _line(c, const Offset(50, 65), const Offset(38, 90), _body);
    _line(c, const Offset(38, 90), const Offset(36, 108), _body);
    _line(c, const Offset(50, 65), const Offset(62, 90), _body);
    _line(c, const Offset(62, 90), const Offset(64, 108), _body);
    // Brazos: t=0 hombro, t=1 extendido arriba
    final handY = lerp(35, 5);
    final elbowY = lerp(40, 22);
    _line(c, Offset(50, 37), Offset(34, elbowY), _active);
    _line(c, Offset(34, elbowY), Offset(28, handY), _active);
    _line(c, Offset(50, 37), Offset(66, elbowY), _active);
    _line(c, Offset(66, elbowY), Offset(72, handY), _active);
    _bar(c, Offset(18, handY), Offset(82, handY), w: 5, plateH: 11, plateW: 4);
  }

  // PRESS MANCUERNAS SENTADO
  void _drawPressSittingDB(Canvas c) {
    // Banco
    c.drawLine(const Offset(25, 82), const Offset(75, 82), _barPaint(4));
    _head(c, const Offset(50, 32), 9);
    _line(c, const Offset(50, 41), const Offset(50, 72), _body);
    _line(c, const Offset(50, 72), const Offset(38, 82), _body);
    _line(c, const Offset(38, 82), const Offset(36, 100), _body);
    _line(c, const Offset(50, 72), const Offset(62, 82), _body);
    _line(c, const Offset(62, 82), const Offset(64, 100), _body);
    // Brazos con mancuernas
    final handY = lerp(48, 20);
    final elbowX = lerp(36, 32);
    _line(c, Offset(50, 50), Offset(elbowX, lerp(56, 44)), _active);
    _line(c, Offset(elbowX, lerp(56, 44)), Offset(elbowX - 4, handY), _active);
    _line(c, Offset(50, 50), Offset(100 - elbowX, lerp(56, 44)), _active);
    _line(c, Offset(100 - elbowX, lerp(56, 44)), Offset(100 - elbowX + 4, handY), _active);
    // Mancuernas (rectángulos pequeños)
    c.drawRect(Rect.fromCenter(center: Offset(elbowX - 4, handY), width: 8, height: 5),
        _platePaint(color.withOpacity(0.8)));
    c.drawRect(Rect.fromCenter(center: Offset(100 - elbowX + 4, handY), width: 8, height: 5),
        _platePaint(color.withOpacity(0.8)));
  }

  // APERTURAS / FLY
  void _drawFly(Canvas c) {
    c.drawLine(const Offset(10, 80), const Offset(90, 80), _barPaint(4));
    _head(c, const Offset(18, 68), 8);
    _line(c, const Offset(18, 76), const Offset(68, 76), _body);
    _line(c, const Offset(68, 76), const Offset(80, 90), _body);
    _line(c, const Offset(68, 76), const Offset(74, 90), _body);
    // Brazos: abiertos → cerrados arriba
    final openAngle = lerp(40, 0);
    final lHandX = 44.0 - openAngle;
    final rHandX = 44.0 + openAngle;
    final handY  = lerp(65, 45);
    _line(c, const Offset(38, 76), Offset(lHandX, handY), _active);
    _line(c, const Offset(50, 76), Offset(rHandX, handY), _active);
    // Mancuernas
    c.drawRect(Rect.fromCenter(center: Offset(lHandX, handY), width: 8, height: 4),
        _platePaint(color.withOpacity(0.8)));
    c.drawRect(Rect.fromCenter(center: Offset(rHandX, handY), width: 8, height: 4),
        _platePaint(color.withOpacity(0.8)));
  }

  // CROSSOVER CABLE
  void _drawCableFly(Canvas c) {
    // Postes de polea
    c.drawLine(const Offset(5, 10), const Offset(5, 90), _barPaint(3));
    c.drawLine(const Offset(95, 10), const Offset(95, 90), _barPaint(3));
    _head(c, const Offset(50, 30), 9);
    _line(c, const Offset(50, 39), const Offset(50, 72), _body);
    _line(c, const Offset(50, 72), const Offset(40, 92), _body);
    _line(c, const Offset(40, 92), const Offset(38, 108), _body);
    _line(c, const Offset(50, 72), const Offset(60, 92), _body);
    _line(c, const Offset(60, 92), const Offset(62, 108), _body);
    // Cables: abrir → cerrar abajo
    final handX = lerp(30, 50);
    final handY = lerp(40, 65);
    c.drawLine(const Offset(5, 20), Offset(handX, handY), _body..color = color.withOpacity(0.5));
    c.drawLine(const Offset(95, 20), Offset(100 - handX, handY), _body..color = color.withOpacity(0.5));
    _line(c, Offset(50, 50), Offset(handX, handY), _active);
    _line(c, Offset(50, 50), Offset(100 - handX, handY), _active);
  }

  // CURL BÍCEPS
  void _drawCurl(Canvas c) {
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(50, 18), 9);
    _line(c, const Offset(50, 27), const Offset(50, 70), _body);
    _line(c, const Offset(50, 70), const Offset(38, 92), _body);
    _line(c, const Offset(38, 92), const Offset(36, 108), _body);
    _line(c, const Offset(50, 70), const Offset(62, 92), _body);
    _line(c, const Offset(62, 92), const Offset(64, 108), _body);
    // Brazo derecho: t=0 recto abajo, t=1 curlado
    final handY = lerp(88, 48);
    final elbowY = lerp(72, 72);
    _line(c, Offset(50, 42), Offset(66, elbowY), _active);
    _line(c, Offset(66, elbowY), Offset(lerp(74, 62), handY), _active);
    // Brazo izquierdo espejo
    _line(c, Offset(50, 42), Offset(34, elbowY), _body);
    _line(c, Offset(34, elbowY), Offset(lerp(26, 38), handY + 8), _body);
    // Barra
    _bar(c, Offset(lerp(74, 62) - 18, handY), Offset(lerp(74, 62) + 2, handY),
        w: 4, plateH: 9, plateW: 3);
  }

  // CURL MARTILLO
  void _drawCurlHammer(Canvas c) {
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(50, 18), 9);
    _line(c, const Offset(50, 27), const Offset(50, 70), _body);
    _line(c, const Offset(50, 70), const Offset(38, 92), _body);
    _line(c, const Offset(38, 92), const Offset(36, 108), _body);
    _line(c, const Offset(50, 70), const Offset(62, 92), _body);
    _line(c, const Offset(62, 92), const Offset(64, 108), _body);
    final handY = lerp(88, 48);
    _line(c, Offset(50, 42), Offset(66, 72), _active);
    _line(c, Offset(66, 72), Offset(68, handY), _active); // martillo: muñeca recta
    _line(c, Offset(50, 42), Offset(34, 72), _body);
    _line(c, Offset(34, 72), Offset(32, handY + 8), _body);
    // Mancuerna vertical
    c.drawRect(Rect.fromCenter(center: Offset(68, handY), width: 5, height: 10),
        _platePaint(color.withOpacity(0.8)));
  }

  // CURL CONCENTRADO (sentado)
  void _drawCurlConc(Canvas c) {
    c.drawLine(const Offset(20, 90), const Offset(80, 90), _barPaint(4));
    _head(c, const Offset(45, 35), 8);
    // Torso inclinado
    _line(c, const Offset(45, 43), const Offset(55, 72), _body);
    // Piernas sentado
    _line(c, const Offset(55, 72), const Offset(40, 72), _body);
    _line(c, const Offset(40, 72), const Offset(35, 90), _body);
    _line(c, const Offset(55, 72), const Offset(70, 72), _body);
    _line(c, const Offset(70, 72), const Offset(74, 90), _body);
    // Brazo apoyado en rodilla, curlando
    final handY = lerp(78, 48);
    _line(c, const Offset(50, 55), const Offset(44, 72), _active); // upper arm on knee
    _line(c, const Offset(44, 72), Offset(42, handY), _active);
    c.drawRect(Rect.fromCenter(center: Offset(42, handY), width: 8, height: 5),
        _platePaint(color.withOpacity(0.8)));
  }

  // REMO INCLINADO
  void _drawRow(Canvas c) {
    c.drawLine(const Offset(10, 100), const Offset(90, 100), _barPaint(2));
    // Figura inclinada ~45°
    _head(c, const Offset(24, 45), 8);
    _line(c, const Offset(28, 52), const Offset(65, 76), _body);
    _line(c, const Offset(65, 76), const Offset(60, 100), _body);
    _line(c, const Offset(60, 100), const Offset(55, 100), _body);
    _line(c, const Offset(65, 76), const Offset(74, 100), _body);
    _line(c, const Offset(74, 100), const Offset(78, 100), _body);
    // Brazos: t=0 extendidos abajo, t=1 jalando hacia cadera
    final handY = lerp(82, 68);
    final elbowY = lerp(74, 62);
    _line(c, const Offset(40, 60), Offset(lerp(40, 32), elbowY), _active);
    _line(c, Offset(lerp(40, 32), elbowY), Offset(lerp(34, 26), handY), _active);
    _bar(c, Offset(lerp(26, 18), handY), Offset(lerp(46, 38), handY),
        w: 4, plateH: 9, plateW: 3);
  }

  // REMO SENTADO EN POLEA
  void _drawRowSeated(Canvas c) {
    // Máquina
    c.drawLine(const Offset(5, 55), const Offset(5, 95), _barPaint(4));
    c.drawRect(Rect.fromLTWH(2, 52, 8, 6), _platePaint(color.withOpacity(0.6)));
    // Asiento
    c.drawLine(const Offset(30, 88), const Offset(70, 88), _barPaint(3));
    _head(c, const Offset(65, 45), 8);
    // Torso erguido
    _line(c, const Offset(65, 53), const Offset(65, 76), _body);
    _line(c, const Offset(65, 76), const Offset(55, 88), _body);
    _line(c, const Offset(55, 88), const Offset(38, 88), _body);
    _line(c, const Offset(65, 76), const Offset(72, 88), _body);
    _line(c, const Offset(72, 88), const Offset(80, 100), _body);
    // Brazos jalando
    final handX = lerp(30, 55);
    final elbowX = lerp(38, 52);
    _line(c, Offset(65, 58), Offset(elbowX, 58), _active);
    _line(c, Offset(elbowX, 58), Offset(handX, 63), _active);
    // Cable
    c.drawLine(Offset(handX, 63), const Offset(5, 58),
        _body..color = color.withOpacity(0.4));
  }

  // ENCOGIMIENTOS
  void _drawShrug(Canvas c) {
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    final shoulderY = lerp(40, 34); // hombros suben
    _head(c, Offset(50, shoulderY - 12), 9);
    _line(c, Offset(50, shoulderY), const Offset(50, 72), _body);
    _line(c, const Offset(50, 72), const Offset(38, 92), _body);
    _line(c, const Offset(38, 92), const Offset(36, 108), _body);
    _line(c, const Offset(50, 72), const Offset(62, 92), _body);
    _line(c, const Offset(62, 92), const Offset(64, 108), _body);
    _line(c, Offset(50, shoulderY), Offset(30, shoulderY + 6), _active);
    _line(c, Offset(30, shoulderY + 6), const Offset(26, 88), _active);
    _line(c, Offset(50, shoulderY), Offset(70, shoulderY + 6), _active);
    _line(c, Offset(70, shoulderY + 6), const Offset(74, 88), _active);
    _bar(c, const Offset(18, 88), const Offset(82, 88), w: 5, plateH: 12, plateW: 4);
  }

  // FACE PULL
  void _drawFacePull(Canvas c) {
    c.drawLine(const Offset(5, 45), const Offset(5, 60), _barPaint(4));
    c.drawRect(Rect.fromLTWH(2, 42, 6, 5), _platePaint(color.withOpacity(0.6)));
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(65, 30), 9);
    _line(c, const Offset(65, 39), const Offset(65, 72), _body);
    _line(c, const Offset(65, 72), const Offset(55, 92), _body);
    _line(c, const Offset(55, 92), const Offset(52, 108), _body);
    _line(c, const Offset(65, 72), const Offset(75, 92), _body);
    _line(c, const Offset(75, 92), const Offset(78, 108), _body);
    final handX = lerp(30, 50);
    _line(c, const Offset(65, 50), Offset(handX + 6, 44), _active);
    _line(c, Offset(handX + 6, 44), Offset(handX, 50), _active);
    _line(c, const Offset(65, 50), Offset(handX - 2, 44), _active);
    c.drawLine(Offset(handX, 50), const Offset(5, 50),
        _body..color = color.withOpacity(0.4));
  }

  // DOMINADAS
  void _drawPullUp(Canvas c) {
    // Barra arriba
    c.drawLine(const Offset(10, 8), const Offset(90, 8), _barPaint(5));
    final bodyY = lerp(28, 18); // cuerpo sube
    _head(c, Offset(50, bodyY + 10), 9);
    _line(c, Offset(50, bodyY + 19), Offset(50, bodyY + 62), _body);
    _line(c, Offset(50, bodyY + 62), Offset(40, bodyY + 85), _body);
    _line(c, Offset(40, bodyY + 85), Offset(38, bodyY + 102), _body);
    _line(c, Offset(50, bodyY + 62), Offset(60, bodyY + 85), _body);
    _line(c, Offset(60, bodyY + 85), Offset(62, bodyY + 102), _body);
    // Brazos a la barra
    _line(c, Offset(50, bodyY + 30), Offset(30, 8), _active);
    _line(c, Offset(50, bodyY + 30), Offset(70, 8), _active);
  }

  // JALÓN AL PECHO
  void _drawLatPulldown(Canvas c) {
    // Máquina + cable
    c.drawLine(const Offset(50, 2), const Offset(50, 15), _barPaint(3));
    c.drawLine(const Offset(20, 15), const Offset(80, 15), _barPaint(5));
    // Asiento
    c.drawLine(const Offset(30, 86), const Offset(70, 86), _barPaint(3));
    _head(c, const Offset(50, 28), 9);
    _line(c, const Offset(50, 37), const Offset(50, 68), _body);
    _line(c, const Offset(50, 68), const Offset(38, 86), _body);
    _line(c, const Offset(38, 86), const Offset(32, 100), _body);
    _line(c, const Offset(50, 68), const Offset(62, 86), _body);
    _line(c, const Offset(62, 86), const Offset(68, 100), _body);
    // Brazos jalando la barra hacia abajo
    final barY = lerp(15, 38);
    _line(c, Offset(50, 44), Offset(22, barY), _active);
    _line(c, Offset(50, 44), Offset(78, barY), _active);
    // Barra jalón
    c.drawLine(Offset(18, barY), Offset(82, barY), _barPaint(5));
  }

  // PULLOVER
  void _drawPullover(Canvas c) {
    c.drawLine(const Offset(15, 80), const Offset(85, 80), _barPaint(4));
    _head(c, const Offset(20, 68), 8);
    _line(c, const Offset(20, 76), const Offset(68, 76), _body);
    _line(c, const Offset(68, 76), const Offset(80, 88), _body);
    _line(c, const Offset(80, 88), const Offset(86, 90), _body);
    // Brazos sobre cabeza → bajar a cadera
    final handX = lerp(8, 36);
    final handY = lerp(52, 62);
    _line(c, const Offset(38, 76), Offset(handX + 8, lerp(62, 70)), _active);
    _line(c, Offset(handX + 8, lerp(62, 70)), Offset(handX, handY), _active);
    c.drawRect(Rect.fromCenter(center: Offset(handX, handY), width: 10, height: 5),
        _platePaint(color.withOpacity(0.8)));
  }

  // STRAIGHT ARM PULLDOWN
  void _drawStraightPulldown(Canvas c) {
    c.drawLine(const Offset(5, 15), const Offset(5, 30), _barPaint(4));
    c.drawRect(Rect.fromLTWH(2, 12, 6, 5), _platePaint(color.withOpacity(0.6)));
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(55, 22), 9);
    _line(c, const Offset(55, 31), const Offset(55, 72), _body);
    _line(c, const Offset(55, 72), const Offset(44, 92), _body);
    _line(c, const Offset(44, 92), const Offset(42, 108), _body);
    _line(c, const Offset(55, 72), const Offset(66, 92), _body);
    _line(c, const Offset(66, 92), const Offset(68, 108), _body);
    // Brazos: t=0 hacia arriba, t=1 abajo
    final handY = lerp(25, 75);
    final handX = lerp(30, 50);
    _line(c, const Offset(55, 45), Offset(handX, handY), _active);
    c.drawLine(Offset(handX, handY), const Offset(5, 22),
        _body..color = color.withOpacity(0.4));
  }

  // EXTENSIÓN TRÍCEPS OVERHEAD
  void _drawTricepExt(Canvas c) {
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(50, 18), 9);
    _line(c, const Offset(50, 27), const Offset(50, 70), _body);
    _line(c, const Offset(50, 70), const Offset(38, 92), _body);
    _line(c, const Offset(38, 92), const Offset(36, 108), _body);
    _line(c, const Offset(50, 70), const Offset(62, 92), _body);
    _line(c, const Offset(62, 92), const Offset(64, 108), _body);
    // Codos fijos arriba, solo el antebrazo se mueve
    final handY = lerp(50, 22);
    _line(c, const Offset(50, 38), const Offset(36, 32), _body); // upper arm
    _line(c, const Offset(36, 32), Offset(lerp(36, 28), handY), _active);
    _line(c, const Offset(50, 38), const Offset(64, 32), _body);
    _line(c, const Offset(64, 32), Offset(lerp(64, 72), handY), _active);
    _bar(c, Offset(lerp(28, 20), handY), Offset(lerp(72, 80), handY),
        w: 4, plateH: 9, plateW: 3);
  }

  // TRÍCEPS POLEA ALTA
  void _drawTricepPushdown(Canvas c) {
    c.drawLine(const Offset(5, 10), const Offset(5, 30), _barPaint(4));
    c.drawRect(Rect.fromLTWH(2, 7, 6, 5), _platePaint(color.withOpacity(0.6)));
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(55, 22), 9);
    _line(c, const Offset(55, 31), const Offset(55, 72), _body);
    _line(c, const Offset(55, 72), const Offset(44, 92), _body);
    _line(c, const Offset(44, 92), const Offset(42, 108), _body);
    _line(c, const Offset(55, 72), const Offset(66, 92), _body);
    _line(c, const Offset(66, 92), const Offset(68, 108), _body);
    // Codos fijos, muñecas bajan
    final handY = lerp(48, 72);
    _line(c, Offset(55, 45), Offset(44, 45), _body);
    _line(c, Offset(44, 45), Offset(42, handY), _active);
    _line(c, Offset(55, 45), Offset(64, 45), _body);
    _line(c, Offset(64, 45), Offset(66, handY), _active);
    c.drawLine(const Offset(5, 18), Offset(54, 45),
        _body..color = color.withOpacity(0.4));
  }

  // KICKBACK TRÍCEPS
  void _drawTricepKickback(Canvas c) {
    c.drawLine(const Offset(10, 90), const Offset(90, 90), _barPaint(2));
    _head(c, const Offset(24, 44), 8);
    _line(c, const Offset(28, 51), const Offset(62, 68), _body);
    _line(c, const Offset(62, 68), const Offset(56, 90), _body);
    _line(c, const Offset(62, 68), const Offset(70, 90), _body);
    // Brazo: codo fijo, antebrazo hacia atrás
    final handX = lerp(50, 80);
    _line(c, const Offset(40, 58), const Offset(56, 58), _body);
    _line(c, const Offset(56, 58), Offset(handX, lerp(68, 55)), _active);
    c.drawRect(Rect.fromCenter(center: Offset(handX, lerp(68, 55)), width: 8, height: 5),
        _platePaint(color.withOpacity(0.8)));
  }

  // TRÍCEPS FONDOS / PRESS CERRADO
  void _drawTricepPress(Canvas c) {
    // Paralelas
    c.drawLine(const Offset(10, 62), const Offset(40, 62), _barPaint(3));
    c.drawLine(const Offset(60, 62), const Offset(90, 62), _barPaint(3));
    _head(c, Offset(50, lerp(34, 24)), 9);
    final torsoY = lerp(54, 42);
    _line(c, Offset(50, lerp(43, 33)), Offset(50, torsoY), _body);
    _line(c, Offset(50, torsoY), Offset(38, torsoY + 18), _body);
    _line(c, Offset(38, torsoY + 18), Offset(36, torsoY + 34), _body);
    _line(c, Offset(50, torsoY), Offset(62, torsoY + 18), _body);
    _line(c, Offset(62, torsoY + 18), Offset(64, torsoY + 34), _body);
    // Brazos en las paralelas
    _line(c, Offset(50, lerp(43, 33) + 8), Offset(30, 62), _active);
    _line(c, Offset(50, lerp(43, 33) + 8), Offset(70, 62), _active);
  }

  // SENTADILLA
  void _drawSquat(Canvas c) {
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    // t=0 de pie, t=1 en cuclillas
    final hipY  = lerp(65, 82);
    final kneeY = lerp(88, 96);
    final headY = lerp(18, 38);
    _head(c, Offset(50, headY), 9);
    _line(c, Offset(50, headY + 9), Offset(50, hipY), _body);
    // Barra sobre hombros
    _bar(c, Offset(30, headY + 14), Offset(70, headY + 14), w: 4, plateH: 10, plateW: 4);
    // Piernas: van hacia afuera en cuclillas
    _line(c, Offset(50, hipY), Offset(lerp(38, 32), kneeY), _active);
    _line(c, Offset(lerp(38, 32), kneeY), Offset(lerp(34, 28), 108), _active);
    _line(c, Offset(50, hipY), Offset(lerp(62, 68), kneeY), _active);
    _line(c, Offset(lerp(62, 68), kneeY), Offset(lerp(66, 72), 108), _active);
    // Brazos
    _line(c, Offset(50, headY + 20), Offset(30, headY + 16), _body);
    _line(c, Offset(50, headY + 20), Offset(70, headY + 16), _body);
  }

  // ZANCADA
  void _drawLunge(Canvas c) {
    c.drawLine(const Offset(10, 108), const Offset(90, 108), _barPaint(2));
    final frontKneeY = lerp(85, 95);
    final backKneeY  = lerp(75, 90);
    _head(c, const Offset(45, 18), 9);
    _line(c, const Offset(45, 27), const Offset(45, 68), _body);
    // Mancuernas
    c.drawRect(Rect.fromLTWH(28, 52, 7, 4), _platePaint(color.withOpacity(0.7)));
    c.drawRect(Rect.fromLTWH(60, 52, 7, 4), _platePaint(color.withOpacity(0.7)));
    _line(c, const Offset(45, 40), const Offset(30, 55), _body);
    _line(c, const Offset(45, 40), const Offset(62, 55), _body);
    // Pierna delantera
    _line(c, Offset(45, 68), Offset(38, frontKneeY), _active);
    _line(c, Offset(38, frontKneeY), const Offset(32, 108), _active);
    // Pierna trasera
    _line(c, Offset(45, 68), Offset(58, backKneeY), _body);
    _line(c, Offset(58, backKneeY), Offset(lerp(68, 72), 108), _body);
  }

  // PRENSA
  void _drawLegPress(Canvas c) {
    // Máquina inclinada
    c.drawLine(const Offset(10, 20), const Offset(90, 95), _barPaint(4));
    // Figura recostada inclinada
    _head(c, const Offset(25, 88), 8);
    _line(c, const Offset(28, 95), const Offset(62, 76), _body);
    // Piernas: t=0 dobladas, t=1 extendidas
    final footX = lerp(25, 12);
    final footY = lerp(48, 26);
    final kneeX = lerp(34, 22);
    final kneeY = lerp(66, 54);
    _line(c, const Offset(52, 80), Offset(kneeX + 10, kneeY), _active);
    _line(c, Offset(kneeX + 10, kneeY), Offset(footX + 10, footY), _active);
    _line(c, const Offset(58, 76), Offset(kneeX + 16, kneeY + 4), _active);
    _line(c, Offset(kneeX + 16, kneeY + 4), Offset(footX + 16, footY + 4), _active);
    // Plataforma
    c.drawLine(Offset(footX + 4, footY - 4), Offset(footX + 26, footY + 2),
        _barPaint(6));
  }

  // EXTENSIÓN PIERNAS
  void _drawLegExtension(Canvas c) {
    // Máquina
    c.drawLine(const Offset(20, 60), const Offset(80, 60), _barPaint(4));
    c.drawLine(const Offset(40, 60), const Offset(40, 100), _barPaint(4));
    _head(c, const Offset(50, 22), 9);
    _line(c, const Offset(50, 31), const Offset(50, 60), _body);
    _line(c, const Offset(50, 60), const Offset(35, 60), _body); // muslo
    _line(c, const Offset(50, 60), const Offset(65, 60), _body);
    // Pantorrillas: t=0 colgando, t=1 extendidas
    final footLY = lerp(85, 60);
    final footRY = lerp(85, 60);
    _line(c, const Offset(35, 60), Offset(28, footLY), _active);
    _line(c, const Offset(65, 60), Offset(72, footRY), _active);
    // Barra
    c.drawLine(Offset(24, footLY), Offset(76, footRY), _barPaint(4));
  }

  // SENTADILLA BÚLGARA
  void _drawBulgarianSplit(Canvas c) {
    // Banco detrás
    c.drawLine(const Offset(60, 78), const Offset(90, 78), _barPaint(4));
    c.drawLine(const Offset(10, 108), const Offset(65, 108), _barPaint(2));
    _head(c, const Offset(35, 20), 9);
    _line(c, const Offset(35, 29), Offset(35, lerp(62, 72)), _body);
    final frontKnee = lerp(88, 98);
    _line(c, Offset(35, lerp(62, 72)), Offset(28, frontKnee), _active);
    _line(c, Offset(28, frontKnee), const Offset(24, 108), _active);
    _line(c, Offset(35, lerp(62, 72)), Offset(50, 74), _body);
    _line(c, Offset(50, 74), const Offset(68, 78), _body); // pie sobre banco
    // Mancuernas
    c.drawRect(Rect.fromLTWH(20, 44, 7, 4), _platePaint(color.withOpacity(0.7)));
    c.drawRect(Rect.fromLTWH(44, 44, 7, 4), _platePaint(color.withOpacity(0.7)));
    _line(c, const Offset(35, 38), const Offset(22, 46), _body);
    _line(c, const Offset(35, 38), const Offset(48, 46), _body);
  }

  // STEP-UP
  void _drawStepUp(Canvas c) {
    // Cajón
    c.drawRect(Rect.fromLTWH(40, 78, 50, 30), _platePaint(const Color(0xFF2A3A4A)));
    c.drawRect(Rect.fromLTWH(40, 78, 50, 30), Paint()
      ..color = const Color(0xFF3A4A5A)..style = PaintingStyle.stroke..strokeWidth = 1);
    c.drawLine(const Offset(10, 108), const Offset(90, 108), _barPaint(2));
    _head(c, Offset(50, lerp(32, 20)), 9);
    final hipY = lerp(62, 50);
    _line(c, Offset(50, lerp(41, 29)), Offset(50, hipY), _body);
    // Pierna en el cajón
    _line(c, Offset(50, hipY), Offset(55, lerp(80, 68)), _active);
    _line(c, Offset(55, lerp(80, 68)), const Offset(60, 78), _active);
    // Pierna abajo
    _line(c, Offset(50, hipY), Offset(38, lerp(88, 75)), _body);
    _line(c, Offset(38, lerp(88, 75)), Offset(32, 108), _body);
  }

  // ELEVACIÓN TALONES DE PIE
  void _drawCalfRaise(Canvas c) {
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    _head(c, const Offset(50, 18), 9);
    _line(c, const Offset(50, 27), const Offset(50, 70), _body);
    _line(c, const Offset(50, 70), const Offset(40, 92), _body);
    _line(c, const Offset(50, 70), const Offset(60, 92), _body);
    // t=0 talones abajo, t=1 de puntillas (piernas más cortas, cuerpo arriba)
    final footYL = lerp(108, 100);
    final footYR = lerp(108, 100);
    _line(c, const Offset(40, 92), Offset(38, footYL), _active);
    _line(c, const Offset(60, 92), Offset(62, footYR), _active);
    // Barra sobre hombros
    _bar(c, const Offset(30, 34), const Offset(70, 34), w: 4, plateH: 9, plateW: 3);
    _line(c, const Offset(50, 34), const Offset(32, 32), _body);
    _line(c, const Offset(50, 34), const Offset(68, 32), _body);
  }

  // ELEVACIÓN TALONES SENTADO
  void _drawCalfRaiseSeated(Canvas c) {
    c.drawLine(const Offset(20, 85), const Offset(80, 85), _barPaint(3));
    _head(c, const Offset(50, 22), 9);
    _line(c, const Offset(50, 31), const Offset(50, 68), _body);
    _line(c, const Offset(50, 68), const Offset(30, 68), _body);
    _line(c, const Offset(50, 68), const Offset(70, 68), _body);
    final footY = lerp(90, 82);
    _line(c, const Offset(30, 68), Offset(26, footY), _active);
    _line(c, const Offset(70, 68), Offset(74, footY), _active);
    // Peso sobre rodillas
    c.drawRect(Rect.fromLTWH(30, 60, 40, 8),
        _platePaint(color.withOpacity(0.5)));
  }

  // SALTOS CUERDA
  void _drawJumpRope(Canvas c) {
    final jumpY = lerp(0, -12); // cuerpo sube
    _head(c, Offset(50, 22 + jumpY), 9);
    _line(c, Offset(50, 31 + jumpY), Offset(50, 68 + jumpY), _body);
    _line(c, Offset(50, 68 + jumpY), Offset(38, 90 + jumpY), _active);
    _line(c, Offset(38, 90 + jumpY), Offset(35, 108 + jumpY), _active);
    _line(c, Offset(50, 68 + jumpY), Offset(62, 90 + jumpY), _active);
    _line(c, Offset(62, 90 + jumpY), Offset(65, 108 + jumpY), _active);
    // Brazos con cuerda
    final ropeSweep = lerp(0, math.pi * 1.5);
    _line(c, Offset(50, 45 + jumpY), Offset(30 + math.cos(ropeSweep) * 8, 58 + jumpY), _body);
    _line(c, Offset(50, 45 + jumpY), Offset(70 - math.cos(ropeSweep) * 8, 58 + jumpY), _body);
    // Cuerda curva
    final path = Path();
    path.moveTo(30 + math.cos(ropeSweep) * 8, 58 + jumpY);
    path.quadraticBezierTo(50, 108 + math.sin(ropeSweep) * 20,
        70 - math.cos(ropeSweep) * 8, 58 + jumpY);
    c.drawPath(path, _body..color = color.withOpacity(0.6));
  }

  // PLANCHA FRONTAL
  void _drawPlank(Canvas c) {
    c.drawLine(const Offset(10, 90), const Offset(90, 90), _barPaint(2));
    _head(c, const Offset(18, 64), 8);
    // Cuerpo horizontal
    _line(c, const Offset(24, 70), const Offset(80, 70), _active);
    // Brazos (codo en suelo)
    _line(c, const Offset(30, 70), const Offset(28, 90), _body);
    _line(c, const Offset(40, 70), const Offset(38, 90), _body);
    // Pies
    _line(c, const Offset(80, 70), const Offset(84, 90), _body);
    // Respiración (pulsación suave del cuerpo)
    final pulse = math.sin(t * math.pi) * 1.5;
    c.drawLine(Offset(24, 70 - pulse), Offset(80, 70 - pulse),
        _active..strokeWidth = 3.5..color = color.withOpacity(0.4));
  }

  // PLANCHA LATERAL
  void _drawPlankSide(Canvas c) {
    c.drawLine(const Offset(10, 95), const Offset(90, 95), _barPaint(2));
    _head(c, const Offset(22, 56), 8);
    _line(c, const Offset(26, 63), const Offset(78, 80), _active);
    _line(c, const Offset(78, 80), const Offset(82, 95), _body);
    // Brazo apoyado
    _line(c, const Offset(36, 66), const Offset(32, 95), _body);
    // Brazo arriba
    final armY = lerp(50, 40);
    _line(c, const Offset(48, 70), Offset(50, armY), _active);
  }

  // CRUNCH
  void _drawCrunch(Canvas c) {
    c.drawLine(const Offset(10, 98), const Offset(90, 98), _barPaint(2));
    // Espalda inclinada según t
    final torsoAngle = lerp(0, 35) * math.pi / 180;
    final hipPos  = const Offset(50, 90);
    final torsoLen = 38.0;
    final headPos = Offset(
      hipPos.dx - math.sin(torsoAngle) * torsoLen,
      hipPos.dy - math.cos(torsoAngle) * torsoLen,
    );
    _head(c, headPos, 9);
    _line(c, headPos + Offset(math.sin(torsoAngle) * 9, math.cos(torsoAngle) * 9),
        hipPos, _active);
    // Piernas dobladas
    _line(c, const Offset(50, 90), const Offset(35, 92), _body);
    _line(c, const Offset(35, 92), const Offset(28, 98), _body);
    _line(c, const Offset(50, 90), const Offset(65, 92), _body);
    _line(c, const Offset(65, 92), const Offset(72, 98), _body);
    // Manos en la cabeza
    _line(c, headPos, Offset(headPos.dx - 10, headPos.dy + 6), _body);
    _line(c, headPos, Offset(headPos.dx + 10, headPos.dy + 6), _body);
  }

  // ELEVACIÓN DE PIERNAS COLGADO
  void _drawLegRaise(Canvas c) {
    // Barra
    c.drawLine(const Offset(10, 8), const Offset(90, 8), _barPaint(5));
    _head(c, const Offset(50, 20), 9);
    _line(c, const Offset(50, 29), const Offset(50, 58), _body);
    // Brazos arriba
    _line(c, const Offset(50, 36), const Offset(26, 8), _body);
    _line(c, const Offset(50, 36), const Offset(74, 8), _body);
    // Piernas: t=0 colgando, t=1 a 90°
    final legAngle = lerp(0, 85) * math.pi / 180;
    final legLen = 45.0;
    final lKnee = Offset(50 - math.sin(legAngle) * 22,
        58 + math.cos(legAngle) * 22);
    final lFoot = Offset(50 - math.sin(legAngle) * legLen,
        58 + math.cos(legAngle) * legLen);
    _line(c, const Offset(50, 58), lKnee, _active);
    _line(c, lKnee, lFoot, _active);
    final rKnee = Offset(50 + math.sin(legAngle) * 22,
        58 + math.cos(legAngle) * 22);
    final rFoot = Offset(50 + math.sin(legAngle) * legLen,
        58 + math.cos(legAngle) * legLen);
    _line(c, const Offset(50, 58), rKnee, _active);
    _line(c, rKnee, rFoot, _active);
  }

  // RUSSIAN TWIST
  void _drawRussianTwist(Canvas c) {
    c.drawLine(const Offset(10, 98), const Offset(90, 98), _barPaint(2));
    _head(c, const Offset(50, 44), 9);
    // Torso inclinado ~45°
    _line(c, const Offset(50, 53), const Offset(50, 82), _body);
    // Piernas dobladas en el suelo
    _line(c, const Offset(50, 82), const Offset(35, 88), _active);
    _line(c, const Offset(35, 88), const Offset(28, 98), _active);
    _line(c, const Offset(50, 82), const Offset(65, 88), _active);
    _line(c, const Offset(65, 88), const Offset(72, 98), _active);
    // Brazos girando: t=0.5 al centro, t=0/1 a los lados
    final armAngle = (t - 0.5) * 80 * math.pi / 180;
    final armLen = 22.0;
    final armEnd = Offset(50 + math.sin(armAngle) * armLen,
        62 + math.cos(armAngle) * armLen * 0.3);
    _line(c, const Offset(50, 60), armEnd, _body);
    c.drawRect(Rect.fromCenter(center: armEnd, width: 9, height: 7),
        _platePaint(color.withOpacity(0.8)));
  }

  // DEAD BUG
  void _drawDeadBug(Canvas c) {
    c.drawLine(const Offset(10, 68), const Offset(90, 68), _barPaint(2));
    // Figura boca arriba
    _head(c, const Offset(20, 56), 8);
    _line(c, const Offset(24, 63), const Offset(70, 63), _body);
    // Brazo izq arriba, pierna derecha extendida (y viceversa con t)
    final armLY = lerp(40, 20);
    final legRX = lerp(78, 92);
    _line(c, const Offset(34, 63), Offset(28, armLY), _active); // brazo izq
    _line(c, const Offset(60, 63), Offset(lerp(68, 74), lerp(78, 62)), _body); // pierna izq dobla
    _line(c, const Offset(60, 63), Offset(legRX, lerp(75, 62)), _active); // pierna der extiende
    _line(c, const Offset(48, 63), Offset(lerp(52, 62), lerp(50, 40)), _body); // brazo der
  }

  // AB WHEEL
  void _drawAbWheel(Canvas c) {
    final wheelX = lerp(50, 30);
    // Rueda
    c.drawCircle(Offset(wheelX, 90), 10,
        _platePaint(color.withOpacity(0.3)));
    c.drawCircle(Offset(wheelX, 90), 10, _barPaint(1.5));
    c.drawLine(Offset(wheelX - 14, 90), Offset(wheelX + 14, 90), _barPaint(3));
    // Figura en plancha extendida
    _head(c, Offset(wheelX + 28, lerp(68, 55)), 8);
    _line(c, Offset(wheelX + 28, lerp(76, 63)), Offset(wheelX + 8, lerp(80, 78)), _body);
    _line(c, Offset(wheelX + 8, lerp(80, 78)), Offset(wheelX, 90), _active);
    // Piernas
    _line(c, Offset(wheelX + 28, lerp(76, 63)), Offset(wheelX + 42, lerp(80, 72)), _body);
    _line(c, Offset(wheelX + 42, lerp(80, 72)), Offset(wheelX + 46, lerp(92, 88)), _body);
  }

  // HOLLOW HOLD
  void _drawHollowHold(Canvas c) {
    c.drawLine(const Offset(10, 85), const Offset(90, 85), _barPaint(2));
    _head(c, const Offset(20, 62), 8);
    // Cuerpo en banana shape
    _line(c, const Offset(24, 70), const Offset(72, 75), _active);
    // Piernas levantadas
    final legY = lerp(80, 65);
    _line(c, const Offset(72, 75), Offset(88, legY), _active);
    // Brazos extendidos
    final armY = lerp(65, 55);
    _line(c, const Offset(24, 70), Offset(10, armY), _active);
    // Respiración
    final pulse = math.sin(t * math.pi) * 2;
    c.drawLine(Offset(24, 70 - pulse), Offset(72, 75 - pulse),
        _active..color = color.withOpacity(0.25)..strokeWidth = 5);
  }

  // PESO MUERTO
  void _drawDeadlift(Canvas c) {
    c.drawLine(const Offset(10, 100), const Offset(90, 100), _barPaint(2));
    final hipY   = lerp(82, 55);
    final headY  = lerp(55, 18);
    final spineX = lerp(35, 50);
    _head(c, Offset(spineX, headY), 9);
    _line(c, Offset(spineX, headY + 9), Offset(50, hipY), _active);
    // Piernas
    _line(c, Offset(50, hipY), const Offset(38, 100), _body);
    _line(c, Offset(50, hipY), const Offset(62, 100), _body);
    // Brazos agarrando la barra
    final shoulderY = lerp(70, 36);
    _line(c, Offset(spineX, shoulderY), Offset(lerp(32, 36), 95), _body);
    _line(c, Offset(spineX, shoulderY), Offset(lerp(68, 64), 95), _body);
    // Barra
    _bar(c, Offset(lerp(24, 28), 95), Offset(lerp(76, 72), 95),
        w: 5, plateH: 14, plateW: 5);
  }

  // HIPEREXTENSIONES
  void _drawHyperextension(Canvas c) {
    // Banco de hiperextensión
    c.drawLine(const Offset(15, 80), const Offset(85, 80), _barPaint(4));
    c.drawLine(const Offset(20, 80), const Offset(20, 100), _barPaint(4));
    // Figura: t=0 caída, t=1 extendida
    final torsoAngle = lerp(-30, 10) * math.pi / 180;
    final hipPos = const Offset(55, 72);
    final headPos = Offset(
      hipPos.dx - math.cos(torsoAngle) * 38,
      hipPos.dy - math.sin(torsoAngle + math.pi/2) * 28,
    );
    _head(c, Offset(lerp(34, 22), lerp(78, 50)), 8);
    _line(c, Offset(lerp(38, 26), lerp(85, 57)),
        Offset(55, lerp(74, 72)), _active);
    // Piernas fijas
    _line(c, const Offset(55, 72), const Offset(62, 80), _body);
    _line(c, const Offset(62, 80), const Offset(64, 100), _body);
    _line(c, const Offset(55, 72), const Offset(50, 80), _body);
    _line(c, const Offset(50, 80), const Offset(48, 100), _body);
  }

  // BUENOS DÍAS
  void _drawGoodMorning(Canvas c) {
    c.drawLine(const Offset(20, 108), const Offset(80, 108), _barPaint(2));
    final torsoAngle = lerp(0, 60) * math.pi / 180;
    final hipPos = const Offset(50, 72);
    final torsoLen = 42.0;
    final headPos = Offset(
      hipPos.dx - math.sin(torsoAngle) * torsoLen,
      hipPos.dy - math.cos(torsoAngle) * torsoLen,
    );
    _head(c, headPos, 9);
    _line(c, Offset(headPos.dx + math.sin(torsoAngle) * 9,
        headPos.dy + math.cos(torsoAngle) * 9), hipPos, _active);
    // Piernas
    _line(c, hipPos, Offset(38, 108), _body);
    _line(c, hipPos, Offset(62, 108), _body);
    // Barra
    final barL = Offset(headPos.dx + math.sin(torsoAngle) * 9 - 20, headPos.dy + 8);
    final barR = Offset(headPos.dx + math.sin(torsoAngle) * 9 + 20, headPos.dy + 8);
    _bar(c, barL, barR, w: 4, plateH: 9, plateW: 3);
  }

  // SUPERMAN
  void _drawSuperman(Canvas c) {
    c.drawLine(const Offset(10, 80), const Offset(90, 80), _barPaint(2));
    _head(c, const Offset(20, 62), 8);
    _line(c, const Offset(24, 68), const Offset(72, 70), _body);
    // Brazos arriba
    final armY = lerp(72, 55);
    _line(c, const Offset(24, 68), Offset(8, armY), _active);
    // Piernas arriba
    final legY = lerp(72, 58);
    _line(c, const Offset(72, 70), Offset(88, legY), _active);
  }

  // BIRD DOG
  void _drawBirdDog(Canvas c) {
    c.drawLine(const Offset(10, 95), const Offset(90, 95), _barPaint(2));
    // En cuatro patas
    _head(c, const Offset(22, 50), 8);
    _line(c, const Offset(26, 57), const Offset(68, 60), _body);
    // Apoyos
    _line(c, const Offset(36, 58), const Offset(36, 80), _body);
    _line(c, const Offset(36, 80), const Offset(32, 95), _body);
    _line(c, const Offset(56, 58), const Offset(56, 80), _body);
    _line(c, const Offset(56, 80), const Offset(60, 95), _body);
    // Brazo derecho y pierna izquierda se extienden
    final armExtY = lerp(58, 42);
    final legExtY = lerp(62, 48);
    _line(c, const Offset(30, 58), Offset(lerp(24, 10), armExtY), _active);
    _line(c, const Offset(64, 60), Offset(lerp(72, 90), legExtY), _active);
  }

  // HIP THRUST
  void _drawHipThrust(Canvas c) {
    c.drawLine(const Offset(10, 100), const Offset(90, 100), _barPaint(2));
    c.drawLine(const Offset(10, 65), const Offset(35, 65), _barPaint(4)); // banco
    final hipY = lerp(85, 62);
    _head(c, Offset(22, lerp(60, 52)), 8);
    _line(c, Offset(26, lerp(66, 58)), Offset(35, 65), _body);
    _line(c, Offset(35, 65), Offset(58, lerp(78, 60)), _active);
    _line(c, Offset(58, lerp(78, 60)), Offset(68, 100), _active);
    _line(c, Offset(58, lerp(78, 60)), Offset(48, 100), _active);
    // Barra sobre cadera
    _bar(c, Offset(44, hipY), Offset(72, hipY), w: 5, plateH: 12, plateW: 4);
  }

  // PUENTE GLÚTEOS
  void _drawBridgeGlute(Canvas c) {
    c.drawLine(const Offset(10, 100), const Offset(90, 100), _barPaint(2));
    final hipY = lerp(82, 60);
    _head(c, const Offset(20, 88), 8);
    _line(c, const Offset(24, 95), const Offset(40, 95), _body);
    _line(c, const Offset(40, 95), Offset(50, hipY), _active);
    _line(c, Offset(50, hipY), Offset(62, 90), _active);
    _line(c, Offset(62, 90), const Offset(68, 100), _body);
    // Manos en el suelo
    _line(c, const Offset(30, 95), const Offset(26, 100), _body);
    _line(c, const Offset(40, 95), const Offset(44, 100), _body);
  }

  // PATADA TRASERA CABLE
  void _drawCableKickback(Canvas c) {
    c.drawLine(const Offset(5, 55), const Offset(5, 70), _barPaint(4));
    c.drawRect(Rect.fromLTWH(2, 52, 6, 5), _platePaint(color.withOpacity(0.6)));
    c.drawLine(const Offset(20, 100), const Offset(80, 100), _barPaint(2));
    _head(c, const Offset(62, 38), 8);
    _line(c, const Offset(62, 46), const Offset(50, 70), _body);
    _line(c, const Offset(50, 70), const Offset(42, 100), _body);
    // Pierna que patea hacia atrás
    final kickAngle = lerp(0, 40) * math.pi / 180;
    _line(c, const Offset(50, 70),
        Offset(50 + math.sin(kickAngle) * 28, 70 + math.cos(kickAngle) * 28), _active);
    _line(c, Offset(50 + math.sin(kickAngle) * 28, 70 + math.cos(kickAngle) * 28),
        Offset(50 + math.sin(kickAngle) * 48, 70 + math.cos(kickAngle) * 48 + 4), _active);
    // Cable
    c.drawLine(Offset(50 + math.sin(kickAngle) * 48, 70 + math.cos(kickAngle) * 48 + 4),
        const Offset(5, 62), _body..color = color.withOpacity(0.4));
    // Brazos apoyados
    _line(c, const Offset(62, 54), const Offset(72, 70), _body);
    _line(c, const Offset(72, 70), const Offset(76, 84), _body);
  }

  // ABDUCTOR MÁQUINA
  void _drawAbductor(Canvas c) {
    c.drawLine(const Offset(20, 85), const Offset(80, 85), _barPaint(3));
    c.drawLine(const Offset(40, 85), const Offset(40, 100), _barPaint(4));
    c.drawLine(const Offset(60, 85), const Offset(60, 100), _barPaint(4));
    _head(c, const Offset(50, 22), 9);
    _line(c, const Offset(50, 31), const Offset(50, 68), _body);
    _line(c, const Offset(50, 68), const Offset(38, 85), _body);
    _line(c, const Offset(38, 85), const Offset(36, 100), _body);
    _line(c, const Offset(50, 68), const Offset(62, 85), _body);
    _line(c, const Offset(62, 85), const Offset(64, 100), _body);
    // Rodillas: t=0 juntas, t=1 abiertas
    final spread = lerp(0, 14);
    c.drawLine(Offset(38 - spread, 92), Offset(62 + spread, 92), _active..strokeWidth = 6);
  }

  // PESO MUERTO SUMO
  void _drawSumoDeadlift(Canvas c) {
    c.drawLine(const Offset(10, 100), const Offset(90, 100), _barPaint(2));
    final hipY = lerp(75, 55);
    _head(c, Offset(50, lerp(45, 18)), 9);
    _line(c, Offset(50, lerp(54, 27)), Offset(50, hipY), _active);
    // Piernas muy abiertas (sumo)
    _line(c, Offset(50, hipY), const Offset(28, 100), _body);
    _line(c, Offset(50, hipY), const Offset(72, 100), _body);
    // Brazos entre las piernas
    _line(c, Offset(50, lerp(65, 44)), const Offset(38, 95), _body);
    _line(c, Offset(50, lerp(65, 44)), const Offset(62, 95), _body);
    _bar(c, const Offset(20, 93), const Offset(80, 93), w: 5, plateH: 14, plateW: 5);
  }

  // CURL FEMORAL
  void _drawLegCurl(Canvas c) {
    c.drawLine(const Offset(15, 55), const Offset(85, 55), _barPaint(3));
    _head(c, const Offset(22, 40), 8);
    _line(c, const Offset(24, 48), const Offset(72, 50), _body);
    // Piernas: t=0 extendidas, t=1 curladas
    final footY = lerp(55, 28);
    final kneeX = 72.0;
    _line(c, const Offset(72, 50), Offset(lerp(82, 78), lerp(55, 44)), _active);
    _line(c, Offset(lerp(82, 78), lerp(55, 44)), Offset(lerp(90, 75), footY), _active);
    _line(c, const Offset(72, 50), Offset(lerp(78, 74), lerp(55, 44)), _active);
    _line(c, Offset(lerp(78, 74), lerp(55, 44)), Offset(lerp(84, 68), footY + 4), _active);
  }

  // PESO MUERTO RUMANO
  void _drawRomanianDL(Canvas c) {
    c.drawLine(const Offset(10, 100), const Offset(90, 100), _barPaint(2));
    final torsoAngle = lerp(0, 65) * math.pi / 180;
    final hipPos = const Offset(50, 68);
    final torsoLen = 40.0;
    final headPos = Offset(
      hipPos.dx - math.sin(torsoAngle) * torsoLen,
      hipPos.dy - math.cos(torsoAngle) * torsoLen,
    );
    _head(c, headPos, 9);
    _line(c, Offset(headPos.dx + math.sin(torsoAngle) * 9,
        headPos.dy + math.cos(torsoAngle) * 9), hipPos, _active);
    // Piernas ligeramente dobladas
    _line(c, hipPos, const Offset(40, 100), _body);
    _line(c, hipPos, const Offset(60, 100), _body);
    // Brazos
    final shoulderY = lerp(48, 65);
    _line(c, Offset(hipPos.dx, shoulderY),
        Offset(lerp(40, 32), lerp(78, 90)), _body);
    _line(c, Offset(hipPos.dx, shoulderY),
        Offset(lerp(60, 68), lerp(78, 90)), _body);
    _bar(c, Offset(lerp(24, 18), lerp(88, 96)), Offset(lerp(76, 82), lerp(88, 96)),
        w: 5, plateH: 12, plateW: 4);
  }

  // NORDIC CURL
  void _drawNordicCurl(Canvas c) {
    c.drawLine(const Offset(20, 95), const Offset(80, 95), _barPaint(2));
    // Anclaje de pies
    c.drawRect(Rect.fromLTWH(48, 88, 16, 8), _platePaint(const Color(0xFF2A3A4A)));
    _head(c, Offset(50, lerp(38, 68)), 9);
    _line(c, Offset(50, lerp(47, 77)), Offset(50, lerp(78, 90)), _active);
    _line(c, Offset(50, lerp(78, 90)), const Offset(52, 95), _body);
    _line(c, Offset(50, lerp(78, 90)), const Offset(62, 95), _body);
    // Brazos (amortiguando caída)
    final handY = lerp(70, 98);
    _line(c, Offset(50, lerp(58, 80)), Offset(35, lerp(62, 88)), _body);
    _line(c, Offset(35, lerp(62, 88)), Offset(28, handY), _body);
  }

  // GLUTE HAM RAISE
  void _drawGluteHamRaise(Canvas c) {
    c.drawLine(const Offset(20, 85), const Offset(80, 85), _barPaint(3));
    final torsoAngle = lerp(-60, 5) * math.pi / 180;
    final kneePos = const Offset(50, 80);
    final headPos = Offset(
      kneePos.dx + math.sin(torsoAngle) * 50,
      kneePos.dy + math.cos(torsoAngle) * 50,
    );
    _head(c, headPos, 9);
    _line(c, Offset(headPos.dx - math.sin(torsoAngle) * 9,
        headPos.dy - math.cos(torsoAngle) * 9), kneePos, _active);
    _line(c, kneePos, const Offset(44, 85), _body);
    _line(c, kneePos, const Offset(56, 85), _body);
  }

  @override
  bool shouldRepaint(_StickFigurePainter old) =>
      old.t != t || old.type != type || old.color != color;
}