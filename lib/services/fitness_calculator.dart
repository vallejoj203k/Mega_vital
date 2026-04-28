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
  final int    nivel;    // 1–4 (4 = Flash)

  const FitnessCalculator({
    required this.weight,
    required this.height,
    required this.age,
    required this.goal,
    this.nivel = 1,
  });

  // ── BMR (Tasa Metabólica Basal) ───────────────────────────────
  double get bmr =>
      (10 * weight) + (6.25 * height) - (5.0 * age) - 78.0;

  // ── TDEE (Gasto energético total diario) ──────────────────────
  double get tdee => bmr * 1.55;

  // ── Delta calórico por nivel ──────────────────────────────────
  // Objetivos de ganancia  → niveles suman superávit adicional
  // Objetivos de pérdida   → niveles suman déficit adicional
  // Mantenimiento          → niveles aplican déficit leve (recomposición)
  int get _nivelDelta {
    const _ganar   = {'Ganar músculo', 'Mejorar resistencia', 'Aumentar fuerza'};
    const _perder  = {'Perder grasa', 'Mejorar movilidad'};
    const _pasos   = {1: 0, 2: 150, 3: 300, 4: 500};
    final step     = _pasos[nivel] ?? 0;
    if (_ganar.contains(goal))  return step;
    if (_perder.contains(goal)) return -step;
    return -(step ~/ 2); // Mantenimiento → recomposición leve
  }

  // ── Meta calórica según objetivo + nivel ─────────────────────
  int get metaCalorias {
    int base;
    switch (goal) {
      case 'Ganar músculo':       base = (tdee + 300).round(); break;
      case 'Perder grasa':        base = (tdee - 500).round(); break;
      case 'Mejorar resistencia': base = (tdee + 100).round(); break;
      case 'Aumentar fuerza':     base = (tdee + 200).round(); break;
      case 'Mejorar movilidad':   base = (tdee - 100).round(); break;
      default:                    base = tdee.round();
    }
    return (base + _nivelDelta).clamp(1200, 6000);
  }

  // ── Etiqueta del nivel ────────────────────────────────────────
  static String nivelLabel(int n) {
    switch (n) {
      case 1:  return 'Nivel 1';
      case 2:  return 'Nivel 2';
      case 3:  return 'Nivel 3';
      default: return 'Flash';
    }
  }

  // ── Descripción contextual del nivel según objetivo ──────────
  static String nivelDescripcion(String goal, int nivel) {
    const ganar  = {'Ganar músculo', 'Mejorar resistencia', 'Aumentar fuerza'};
    const perder = {'Perder grasa', 'Mejorar movilidad'};
    final g = ganar.contains(goal);
    final p = perder.contains(goal);
    switch (nivel) {
      case 1:  return g ? 'Superávit base'          : p ? 'Déficit moderado'       : 'Mantenimiento';
      case 2:  return g ? 'Superávit moderado'      : p ? 'Déficit intenso'        : 'Recomposición leve';
      case 3:  return g ? 'Superávit intenso'       : p ? 'Déficit agresivo'       : 'Recomposición moderada';
      default: return '⚠️ Modo extremo';
    }
  }

  // ── Meta de proteínas (g) ────────────────────────────────────
  double get metaProteina {
    switch (goal) {
      case 'Ganar músculo':    return (weight * 2.2).roundToDouble();
      case 'Perder grasa':     return (weight * 2.0).roundToDouble();
      case 'Aumentar fuerza':  return (weight * 2.2).roundToDouble();
      default:                 return (weight * 1.6).roundToDouble();
    }
  }

  // ── Meta de grasas (g) ───────────────────────────────────────
  double get metaGrasas =>
      ((metaCalorias * 0.25) / 9).roundToDouble();

  // ── Meta de carbohidratos (g) ────────────────────────────────
  double get metaCarbos {
    final calRestantes =
        metaCalorias - (metaProteina * 4) - (metaGrasas * 9);
    return (calRestantes / 4).clamp(50.0, 600.0).roundToDouble();
  }

  // ── Meta de agua (vasos de 250ml) ────────────────────────────
  int get metaVasos {
    final ml = weight * 35;
    return (ml / 250).ceil();
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

  static String formatPeso(double kg) => kg.toStringAsFixed(1);

  @override
  String toString() => 'Cal: $metaCalorias (niv$nivel) | '
      'P: ${metaProteina.toInt()}g | '
      'C: ${metaCarbos.toInt()}g | '
      'G: ${metaGrasas.toInt()}g | '
      'Agua: $metaVasos vasos';
}
