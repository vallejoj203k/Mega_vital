// lib/services/fitness_calculator.dart
// ─────────────────────────────────────────────────────────────────
// Todas las fórmulas de fitness basadas en los datos reales
// del usuario (peso, altura, edad, objetivo).
//
// Fórmulas usadas:
//   • BMR  → Mifflin-St Jeor (la más precisa sin género)
//   • TDEE → BMR × 1.55 (actividad moderada)
//   • Proteínas, carbos, grasas → según objetivo
//   • Agua  → 35 ml por kg de peso corporal
// ─────────────────────────────────────────────────────────────────

class FitnessCalculator {
  final double weight;   // kg
  final double height;   // cm
  final int    age;
  final String goal;

  const FitnessCalculator({
    required this.weight,
    required this.height,
    required this.age,
    required this.goal,
  });

  // ── BMR (Tasa Metabólica Basal) ───────────────────────────────
  // Versión neutral de Mifflin-St Jeor (promedio hombre/mujer)
  double get bmr =>
      (10 * weight) + (6.25 * height) - (5.0 * age) - 78.0;

  // ── TDEE (Gasto energético total diario) ──────────────────────
  // Factor 1.55 = actividad moderada (3-5 días/semana)
  double get tdee => bmr * 1.55;

  // ── Meta calórica según objetivo ─────────────────────────────
  int get metaCalorias {
    switch (goal) {
      case 'Ganar músculo':       return (tdee + 300).round();
      case 'Perder grasa':        return (tdee - 500).round();
      case 'Mejorar resistencia': return (tdee + 100).round();
      case 'Aumentar fuerza':     return (tdee + 200).round();
      case 'Mejorar movilidad':   return (tdee - 100).round();
      default:                    return tdee.round(); // Mantenimiento
    }
  }

  // ── Meta de proteínas (g) ────────────────────────────────────
  // Más proteína para ganar músculo y perder grasa
  double get metaProteina {
    switch (goal) {
      case 'Ganar músculo':    return (weight * 2.2).roundToDouble();
      case 'Perder grasa':     return (weight * 2.0).roundToDouble();
      case 'Aumentar fuerza':  return (weight * 2.2).roundToDouble();
      default:                 return (weight * 1.6).roundToDouble();
    }
  }

  // ── Meta de grasas (g) ───────────────────────────────────────
  // 25% de las calorías totales vienen de grasas
  double get metaGrasas =>
      ((metaCalorias * 0.25) / 9).roundToDouble();

  // ── Meta de carbohidratos (g) ────────────────────────────────
  // Lo que queda después de proteínas y grasas
  double get metaCarbos {
    final calRestantes =
        metaCalorias - (metaProteina * 4) - (metaGrasas * 9);
    return (calRestantes / 4).clamp(50.0, 600.0).roundToDouble();
  }

  // ── Meta de agua (vasos de 250ml) ────────────────────────────
  // 35 ml por kg de peso corporal, redondeado a vasos
  int get metaVasos {
    final ml = weight * 35;        // ej: 78kg × 35 = 2730 ml
    return (ml / 250).ceil();      // ej: ceil(10.92) = 11 vasos
  }

  // ── Litros de agua totales ────────────────────────────────────
  double get metaLitros => (metaVasos * 0.25);

  // ── IMC ───────────────────────────────────────────────────────
  double get imc {
    final h = height / 100;
    return weight / (h * h);
  }

  String get imcLabel {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25.0) return 'Normal';
    if (imc < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  // ── Peso con 1 decimal máximo ─────────────────────────────────
  static String formatPeso(double kg) => kg.toStringAsFixed(1);

  // ── Resumen legible ───────────────────────────────────────────
  @override
  String toString() => 'Cal: $metaCalorias | '
      'P: ${metaProteina.toInt()}g | '
      'C: ${metaCarbos.toInt()}g | '
      'G: ${metaGrasas.toInt()}g | '
      'Agua: $metaVasos vasos';
}
