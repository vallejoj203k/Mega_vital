// lib/presentation/screens/workouts/body_painter.dart
import 'package:flutter/material.dart';
import '../../../core/data/muscle_data.dart';

class BodyRegion {
  final String muscleId;
  final bool   isFront;
  final Path   path;
  BodyRegion({required this.muscleId, required this.isFront, required this.path});
}

// ── Construye todas las regiones ─────────────────────────────────
List<BodyRegion> buildBodyRegions() => [
  BodyRegion(muscleId: 'pecho',      isFront: true,  path: _pecho()),
  BodyRegion(muscleId: 'hombros',    isFront: true,  path: _hombrosF()),
  BodyRegion(muscleId: 'biceps',     isFront: true,  path: _biceps()),
  BodyRegion(muscleId: 'abs',        isFront: true,  path: _abs()),
  BodyRegion(muscleId: 'cuadriceps', isFront: true,  path: _cuads()),
  BodyRegion(muscleId: 'gemelos',    isFront: true,  path: _gemF()),
  BodyRegion(muscleId: 'espalda',    isFront: false, path: _espaldaAlta()),
  BodyRegion(muscleId: 'dorsales',   isFront: false, path: _dorsales()),
  BodyRegion(muscleId: 'triceps',    isFront: false, path: _triceps()),
  BodyRegion(muscleId: 'lumbar',     isFront: false, path: _lumbar()),
  BodyRegion(muscleId: 'gluteos',    isFront: false, path: _gluteos()),
  BodyRegion(muscleId: 'isquio',     isFront: false, path: _isquios()),
  BodyRegion(muscleId: 'gemelos',    isFront: false, path: _gemB()),
];

// ── Paths de grupos musculares (coordenadas en espacio 200×480) ──
// Cascadas en Path() son válidas en Dart: Path()..moveTo()..lineTo()..close()

Path _pecho() => Path()
  ..moveTo(72, 110)..lineTo(128, 110)
  ..lineTo(130, 158)..lineTo(70, 158)..close();

Path _hombrosF() {
  final p = Path();
  p.moveTo(55, 100); p.lineTo(74, 100); p.lineTo(76, 140); p.lineTo(52, 138); p.close();
  p.moveTo(126, 100); p.lineTo(145, 100); p.lineTo(148, 138); p.lineTo(124, 140); p.close();
  return p;
}

Path _biceps() {
  final p = Path();
  p.moveTo(50, 140); p.lineTo(68, 140); p.lineTo(70, 195); p.lineTo(46, 193); p.close();
  p.moveTo(132, 140); p.lineTo(150, 140); p.lineTo(154, 193); p.lineTo(130, 195); p.close();
  return p;
}

Path _abs() => Path()
  ..moveTo(72, 160)..lineTo(128, 160)
  ..lineTo(126, 215)..lineTo(74, 215)..close();

Path _cuads() {
  final p = Path();
  p.moveTo(74, 220); p.lineTo(97, 220); p.lineTo(95, 315); p.lineTo(70, 313); p.close();
  p.moveTo(103, 220); p.lineTo(126, 220); p.lineTo(130, 313); p.lineTo(105, 315); p.close();
  return p;
}

Path _gemF() {
  final p = Path();
  p.moveTo(70, 318); p.lineTo(93, 318); p.lineTo(91, 400); p.lineTo(66, 398); p.close();
  p.moveTo(107, 318); p.lineTo(130, 318); p.lineTo(134, 398); p.lineTo(109, 400); p.close();
  return p;
}

Path _espaldaAlta() => Path()
  ..moveTo(70, 105)..lineTo(130, 105)
  ..lineTo(128, 152)..lineTo(72, 152)..close();

Path _dorsales() {
  final p = Path();
  p.moveTo(55, 152); p.lineTo(76, 152); p.lineTo(78, 210); p.lineTo(52, 208); p.close();
  p.moveTo(124, 152); p.lineTo(145, 152); p.lineTo(148, 208); p.lineTo(122, 210); p.close();
  return p;
}

Path _triceps() {
  final p = Path();
  p.moveTo(50, 105); p.lineTo(68, 105); p.lineTo(70, 200); p.lineTo(46, 198); p.close();
  p.moveTo(132, 105); p.lineTo(150, 105); p.lineTo(154, 198); p.lineTo(130, 200); p.close();
  return p;
}

Path _lumbar() => Path()
  ..moveTo(76, 210)..lineTo(124, 210)
  ..lineTo(122, 250)..lineTo(78, 250)..close();

Path _gluteos() => Path()
  ..moveTo(74, 252)..lineTo(126, 252)
  ..lineTo(130, 305)..lineTo(70, 305)..close();

Path _isquios() {
  final p = Path();
  p.moveTo(70, 308); p.lineTo(96, 308); p.lineTo(94, 390); p.lineTo(66, 388); p.close();
  p.moveTo(104, 308); p.lineTo(130, 308); p.lineTo(134, 388); p.lineTo(106, 390); p.close();
  return p;
}

Path _gemB() {
  final p = Path();
  p.moveTo(66, 393); p.lineTo(92, 393); p.lineTo(90, 465); p.lineTo(62, 463); p.close();
  p.moveTo(108, 393); p.lineTo(134, 393); p.lineTo(138, 463); p.lineTo(110, 465); p.close();
  return p;
}

// ─────────────────────────────────────────────────────────────────
// CustomPainter
// ─────────────────────────────────────────────────────────────────
class BodyPainter extends CustomPainter {
  final bool    isFront;
  final String? selectedMuscleId;
  final List<BodyRegion> regions;

  const BodyPainter({
    required this.isFront,
    required this.selectedMuscleId,
    required this.regions,
  });

  Path _scale(Path logical, Size size) {
    final m = Matrix4.identity()
      ..scale(size.width / 200.0, size.height / 480.0);
    return logical.transform(m.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawOutline(canvas, size);
    _drawMuscles(canvas, size);
  }

  void _drawOutline(Canvas canvas, Size size) {
    final sx = size.width / 200.0;
    final sy = size.height / 480.0;

    final fill   = Paint()..color = const Color(0xFF1C1C1E)..style = PaintingStyle.fill;
    final border = Paint()..color = const Color(0xFF3A3A3C)..style = PaintingStyle.stroke..strokeWidth = 1.2;

    void oval(double cx, double cy, double rx, double ry) {
      final r = Rect.fromCenter(center: Offset(cx*sx, cy*sy), width: rx*2*sx, height: ry*2*sy);
      canvas.drawOval(r, fill); canvas.drawOval(r, border);
    }

    void rrect(double x, double y, double w, double h, double r) {
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x*sx,y*sy,w*sx,h*sy), Radius.circular(r));
      canvas.drawRRect(rr, fill); canvas.drawRRect(rr, border);
    }

    void poly(List<Offset> pts) {
      final p = Path()..moveTo(pts[0].dx*sx, pts[0].dy*sy);
      for (final pt in pts.skip(1)) p.lineTo(pt.dx*sx, pt.dy*sy);
      p.close();
      canvas.drawPath(p, fill); canvas.drawPath(p, border);
    }

    // Cabeza
    oval(100, 36, 28, 34);
    // Cuello
    rrect(88, 68, 24, 16, 4);
    // Torso
    poly([Offset(62,82),Offset(138,82),Offset(142,220),Offset(58,220)]);
    // Hombros
    oval(54, 105, 18, 22); oval(146, 105, 18, 22);
    // Brazos superiores
    poly([Offset(40,118),Offset(62,118),Offset(64,205),Offset(36,203)]);
    poly([Offset(138,118),Offset(160,118),Offset(164,203),Offset(136,205)]);
    // Antebrazos
    poly([Offset(34,207),Offset(62,207),Offset(60,280),Offset(30,278)]);
    poly([Offset(138,207),Offset(166,207),Offset(170,278),Offset(140,280)]);
    // Manos
    oval(46, 290, 16, 12); oval(154, 290, 16, 12);
    // Cadera
    poly([Offset(60,218),Offset(140,218),Offset(145,250),Offset(55,250)]);
    // Muslos
    poly([Offset(58,248),Offset(96,248),Offset(92,340),Offset(55,338)]);
    poly([Offset(104,248),Offset(142,248),Offset(145,338),Offset(108,340)]);
    // Pantorrillas
    poly([Offset(56,342),Offset(90,342),Offset(86,430),Offset(52,428)]);
    poly([Offset(110,342),Offset(144,342),Offset(148,428),Offset(114,430)]);
    // Pies
    oval(70, 440, 22, 12); oval(130, 440, 22, 12);
  }

  void _drawMuscles(Canvas canvas, Size size) {
    for (final region in regions) {
      if (region.isFront != isFront) continue;
      final muscle = getMuscleById(region.muscleId);
      if (muscle == null) continue;
      final isSelected = region.muscleId == selectedMuscleId;
      final scaled = _scale(region.path, size);
      canvas.drawPath(scaled, Paint()
        ..color = isSelected ? muscle.color.withOpacity(0.85) : muscle.color.withOpacity(0.25)
        ..style = PaintingStyle.fill);
      canvas.drawPath(scaled, Paint()
        ..color = isSelected ? muscle.color : muscle.color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 0.8);
    }
  }

  // Detecta qué músculo fue tocado (NO override de CustomPainter)
  String? findMuscleAt(Offset localPos, Size size) {
    final lx = localPos.dx / size.width  * 200.0;
    final ly = localPos.dy / size.height * 480.0;
    final logical = Offset(lx, ly);
    for (final region in regions.reversed) {
      if (region.isFront != isFront) continue;
      if (region.path.contains(logical)) return region.muscleId;
    }
    return null;
  }

  @override
  bool shouldRepaint(BodyPainter old) =>
      old.isFront != isFront || old.selectedMuscleId != selectedMuscleId;
}
