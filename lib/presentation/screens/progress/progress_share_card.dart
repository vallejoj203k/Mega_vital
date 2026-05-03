// lib/presentation/screens/progress/progress_share_card.dart
// Tarjeta visual que se captura como imagen para compartir el progreso.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ProgressShareCard extends StatelessWidget {
  final String exerciseName;
  final String muscle;
  final String userName;
  final double maxWeight;
  final double bestWeight;
  final double volume;
  final int sessions;
  final List<double> chartValues;
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
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1F10),
            const Color(0xFF0A1A10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: logo + usuario
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    size: 16, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mega Vital',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      )),
                  Text(userName,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      )),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: accentColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isUp ? "+" : ""}${diff.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nombre del ejercicio
          Text(
            exerciseName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (muscle.isNotEmpty)
            Text(
              '${muscle[0].toUpperCase()}${muscle.substring(1)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _StatChip(label: 'Actual', value: '${maxWeight.toStringAsFixed(1)} kg', color: accentColor),
              const SizedBox(width: 8),
              _StatChip(label: 'Mejor', value: '${bestWeight.toStringAsFixed(1)} kg', color: AppColors.primary),
              const SizedBox(width: 8),
              _StatChip(label: 'Sesiones', value: '$sessions', color: AppColors.accentBlue),
            ],
          ),

          const SizedBox(height: 16),

          // Mini gráfica
          if (chartValues.length >= 2)
            SizedBox(
              height: 70,
              child: CustomPaint(
                painter: _MiniChartPainter(values: chartValues, color: accentColor),
                size: Size.infinite,
              ),
            ),

          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#MegaVital · Tu progreso, tu poder',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 9)),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _MiniChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final range = (maxVal - minVal).abs();
    final effMin = range < 1 ? minVal - 1 : minVal - range * 0.1;
    final effMax = range < 1 ? maxVal + 1 : maxVal + range * 0.1;
    final effRange = effMax - effMin;

    double xOf(int i) => i / (values.length - 1) * size.width;
    double yOf(double v) => size.height - ((v - effMin) / effRange) * size.height;

    final path = Path();
    final fill = Path();
    path.moveTo(xOf(0), yOf(values[0]));
    fill.moveTo(xOf(0), size.height);
    fill.lineTo(xOf(0), yOf(values[0]));

    for (int i = 1; i < values.length; i++) {
      final cx = (xOf(i - 1) + xOf(i)) / 2;
      path.cubicTo(cx, yOf(values[i - 1]), cx, yOf(values[i]), xOf(i), yOf(values[i]));
      fill.cubicTo(cx, yOf(values[i - 1]), cx, yOf(values[i]), xOf(i), yOf(values[i]));
    }

    fill.lineTo(xOf(values.length - 1), size.height);
    fill.close();

    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Punto final
    final lx = xOf(values.length - 1);
    final ly = yOf(values.last);
    canvas.drawCircle(Offset(lx, ly), 5, Paint()..color = color.withOpacity(0.3));
    canvas.drawCircle(Offset(lx, ly), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MiniChartPainter old) => old.values != values;
}
