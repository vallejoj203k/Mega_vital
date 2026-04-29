// lib/presentation/screens/progress/progress_share_card.dart
// Tarjeta visual para compartir el progreso de un ejercicio.
// Diseñada para ser capturada como imagen con RepaintBoundary.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProgressShareCard extends StatelessWidget {
  final String exerciseName;
  final String muscle;
  final String userName;
  final double maxWeight;
  final double bestWeight;
  final double volume;
  final int sessions;
  final List<double> chartValues; // últimos valores para mini-gráfica
  final bool isUp;
  final double diff;
  final Color accentColor;

  const ProgressShareCard({
    super.key,
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
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A0A0A), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header con logo ────────────────────────────────────
          _Header(accentColor: accentColor, userName: userName),

          // ── Nombre del ejercicio ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (muscle.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${muscle[0].toUpperCase()}${muscle.substring(1)}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Estadísticas ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatBox(
                    label: 'Peso actual',
                    value: '${maxWeight.toStringAsFixed(1)} kg',
                    color: accentColor),
                const SizedBox(width: 10),
                _StatBox(
                    label: 'Mejor marca',
                    value: '${bestWeight.toStringAsFixed(1)} kg',
                    color: Colors.white),
                const SizedBox(width: 10),
                _StatBox(
                    label: 'Sesiones',
                    value: sessions.toString(),
                    color: Colors.white),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Mini gráfica ───────────────────────────────────────
          if (chartValues.length >= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 72,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MiniChartPainter(
                    values: chartValues,
                    color: accentColor,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Tendencia ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isUp
                            ? const Color(0xFF00FF87)
                            : const Color(0xFFCF6679))
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isUp
                              ? const Color(0xFF00FF87)
                              : const Color(0xFFCF6679))
                          .withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isUp
                            ? const Color(0xFF00FF87)
                            : const Color(0xFFCF6679),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${isUp ? "+" : ""}${diff.toStringAsFixed(1)} kg desde el inicio',
                        style: TextStyle(
                          color: isUp
                              ? const Color(0xFF00FF87)
                              : const Color(0xFFCF6679),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Footer ─────────────────────────────────────────────
          _Footer(accentColor: accentColor),
        ],
      ),
    );
  }
}

// ── Subwidgets internos ────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Color accentColor;
  final String userName;
  const _Header({required this.accentColor, required this.userName});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: accentColor.withOpacity(0.15), width: 0.8)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + nombre en la misma línea
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.fitness_center_rounded,
                          color: Color(0xFF00FF87),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'MEGA VITAL',
                      style: TextStyle(
                        color: Color(0xFF00FF87),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Mi Progreso · $userName',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _today(),
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );

  static String _today() {
    final d = DateTime.now();
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF2A2A2A), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 9,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Footer extends StatelessWidget {
  final Color accentColor;
  const _Footer({required this.accentColor});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
          gradient: LinearGradient(
            colors: [
              accentColor.withOpacity(0.08),
              accentColor.withOpacity(0.03),
            ],
          ),
          border: Border(
              top: BorderSide(
                  color: accentColor.withOpacity(0.12), width: 0.8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Track your limits 💪',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              'mega-vital.app',
              style: TextStyle(
                color: accentColor.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

// ── Mini gráfica para la tarjeta ──────────────────────────────────

class _MiniChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _MiniChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs();
    final effMin = range < 1 ? minV - 1 : minV - range * 0.15;
    final effMax = range < 1 ? maxV + 1 : maxV + range * 0.15;
    final effRange = effMax - effMin;

    double x(int i) => i / (values.length - 1) * size.width;
    double y(double v) =>
        size.height - ((v - effMin) / effRange) * size.height;

    final linePath = Path();
    final fillPath = Path();

    linePath.moveTo(x(0), y(values[0]));
    fillPath.moveTo(x(0), size.height);
    fillPath.lineTo(x(0), y(values[0]));

    for (int i = 1; i < values.length; i++) {
      final cx = (x(i - 1) + x(i)) / 2;
      linePath.cubicTo(cx, y(values[i - 1]), cx, y(values[i]), x(i), y(values[i]));
      fillPath.cubicTo(cx, y(values[i - 1]), cx, y(values[i]), x(i), y(values[i]));
    }

    fillPath.lineTo(x(values.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Glow en último punto
    final lx = x(values.length - 1), ly = y(values.last);
    canvas.drawCircle(Offset(lx, ly), 5, Paint()..color = color.withOpacity(0.3));
    canvas.drawCircle(Offset(lx, ly), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MiniChartPainter old) =>
      old.values != values || old.color != color;
}
