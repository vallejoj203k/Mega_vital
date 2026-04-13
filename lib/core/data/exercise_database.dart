// lib/core/data/exercise_database.dart
// ─────────────────────────────────────────────────────────────────
// Base de datos completa de ejercicios organizados por grupo muscular.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class ExerciseItem {
  final String id;
  final String name;
  final String muscle;
  final int defaultSets;
  final String defaultReps;
  final int restSeconds;
  final String tip;
  final IconData icon;

  const ExerciseItem({
    required this.id,
    required this.name,
    required this.muscle,
    required this.defaultSets,
    required this.defaultReps,
    required this.restSeconds,
    required this.tip,
    required this.icon,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'muscle': muscle,
    'sets': defaultSets, 'reps': defaultReps,
    'rest': restSeconds,
  };

  factory ExerciseItem.fromMap(Map<String, dynamic> m) => ExerciseItem(
    id: m['id'] ?? '', name: m['name'] ?? '',
    muscle: m['muscle'] ?? '', defaultSets: m['sets'] ?? 3,
    defaultReps: m['reps'] ?? '10', restSeconds: m['rest'] ?? 60,
    tip: '', icon: Icons.fitness_center_rounded,
  );
}

class ExerciseDatabase {
  ExerciseDatabase._();

  static const Map<String, List<ExerciseItem>> byMuscle = {

    'Pectoral': [
      ExerciseItem(id:'p1', name:'Press de banca plano', muscle:'Pectoral', defaultSets:4, defaultReps:'8-10', restSeconds:90, tip:'Baja la barra despacio (2 seg), empuja explosivo.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'p2', name:'Press de banca inclinado', muscle:'Pectoral', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Ángulo de 30-45°. Activa el pectoral superior.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'p3', name:'Press de banca declinado', muscle:'Pectoral', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Trabajo el pectoral inferior. Usa spotter si es pesado.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'p4', name:'Aperturas con mancuernas', muscle:'Pectoral', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Codos ligeramente flexionados. Estira bien en la apertura.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'p5', name:'Crossover en polea alta', muscle:'Pectoral', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Aprieta en el centro. Control en el excéntrico.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'p6', name:'Fondos en paralelas', muscle:'Pectoral', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Inclínate hacia adelante para mayor activación pectoral.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'p7', name:'Press con mancuernas plano', muscle:'Pectoral', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Mayor rango de movimiento que con barra.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'p8', name:'Aperturas en polea baja', muscle:'Pectoral', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'El cable en la parte inferior activa el pectoral superior.', icon:Icons.sports_gymnastics_rounded),
    ],

    'Hombros': [
      ExerciseItem(id:'sh1', name:'Press militar con barra', muscle:'Hombros', defaultSets:4, defaultReps:'8-10', restSeconds:90, tip:'Core activo. No arquees la espalda baja.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'sh2', name:'Press Arnold', muscle:'Hombros', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'La rotación activa las tres cabezas del deltoides.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'sh3', name:'Elevaciones laterales', muscle:'Hombros', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Sube hasta la altura del hombro. Codo ligeramente doblado.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'sh4', name:'Elevaciones frontales', muscle:'Hombros', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'No balancees el cuerpo. Movimiento controlado.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'sh5', name:'Pájaros / Rear delt fly', muscle:'Hombros', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Trabaja el deltoides posterior. Codos ligeramente doblados.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'sh6', name:'Face pull en polea', muscle:'Hombros', defaultSets:3, defaultReps:'15', restSeconds:45, tip:'Lleva la cuerda a la altura de la frente. Codos arriba.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'sh7', name:'Press con mancuernas sentado', muscle:'Hombros', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Asiento vertical para aislar los hombros.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'sh8', name:'Encogimientos de hombros', muscle:'Hombros', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Activa el trapecio. Pausa en la cima 1 segundo.', icon:Icons.fitness_center_rounded),
    ],

    'Bíceps': [
      ExerciseItem(id:'bi1', name:'Curl con barra recta', muscle:'Bíceps', defaultSets:4, defaultReps:'10-12', restSeconds:60, tip:'No uses impulso del cuerpo. Solo codos.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'bi2', name:'Curl con barra EZ', muscle:'Bíceps', defaultSets:3, defaultReps:'10-12', restSeconds:60, tip:'Agarre neutro reduce estrés en muñecas.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'bi3', name:'Curl con mancuernas alterno', muscle:'Bíceps', defaultSets:3, defaultReps:'12 c/lado', restSeconds:60, tip:'Rota la muñeca en la subida para mayor activación.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'bi4', name:'Curl martillo', muscle:'Bíceps', defaultSets:3, defaultReps:'12', restSeconds:60, tip:'Trabaja el braquial. Pulgares hacia arriba.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'bi5', name:'Curl en banco Scott', muscle:'Bíceps', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Aísla el bíceps. No dejes caer completamente.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'bi6', name:'Curl concentrado', muscle:'Bíceps', defaultSets:3, defaultReps:'12 c/lado', restSeconds:45, tip:'Codo contra el muslo para máximo aislamiento.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'bi7', name:'Curl en polea baja', muscle:'Bíceps', defaultSets:3, defaultReps:'12-15', restSeconds:45, tip:'Tensión constante gracias al cable.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'bi8', name:'Curl predicador con mancuerna', muscle:'Bíceps', defaultSets:3, defaultReps:'10-12', restSeconds:60, tip:'Enfoca la cabeza larga del bíceps.', icon:Icons.fitness_center_rounded),
    ],

    'Tríceps': [
      ExerciseItem(id:'tr1', name:'Press francés con barra EZ', muscle:'Tríceps', defaultSets:4, defaultReps:'10-12', restSeconds:75, tip:'Codos apuntando al techo. No los abras.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tr2', name:'Extensión en polea alta (cuerda)', muscle:'Tríceps', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Abre la cuerda al final para mayor contracción.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'tr3', name:'Fondos en banco', muscle:'Tríceps', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Espalda cerca del banco. Baja hasta 90° en codos.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'tr4', name:'Press cerrado en banca plana', muscle:'Tríceps', defaultSets:4, defaultReps:'8-10', restSeconds:90, tip:'Agarre a la anchura de los hombros. Codos cerca del torso.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tr5', name:'Jalón en polea con barra recta', muscle:'Tríceps', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Codos pegados al cuerpo todo el movimiento.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'tr6', name:'Extensión con mancuerna (una mano)', muscle:'Tríceps', defaultSets:3, defaultReps:'12 c/lado', restSeconds:60, tip:'Codo apuntando al techo. Baja detrás de la cabeza.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tr7', name:'Patada de tríceps', muscle:'Tríceps', defaultSets:3, defaultReps:'12-15', restSeconds:45, tip:'Bloquea el codo al final. Movimiento de solo el antebrazo.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tr8', name:'Extensión sobre la cabeza en polea', muscle:'Tríceps', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Trabaja la cabeza larga al estar el brazo elevado.', icon:Icons.sports_gymnastics_rounded),
    ],

    'Espalda': [
      ExerciseItem(id:'ba1', name:'Dominadas agarre pronado', muscle:'Espalda', defaultSets:4, defaultReps:'6-10', restSeconds:90, tip:'Agarre ancho. Baja completamente. Toca el pecho a la barra.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ba2', name:'Jalón al pecho en polea alta', muscle:'Espalda', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Lleva la barra a la parte alta del pecho. No a la nuca.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ba3', name:'Remo con barra', muscle:'Espalda', defaultSets:4, defaultReps:'8-10', restSeconds:90, tip:'Espalda recta a 45°. Codos cerca del torso.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ba4', name:'Remo en polea baja sentado', muscle:'Espalda', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Saca el pecho. No redondees la espalda.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ba5', name:'Remo con mancuerna unilateral', muscle:'Espalda', defaultSets:3, defaultReps:'10-12 c/lado', restSeconds:60, tip:'Apoya la rodilla en el banco. Lleva el codo al techo.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ba6', name:'Pullover con mancuerna', muscle:'Espalda', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Estira el dorsal al máximo arriba. Codo ligeramente flexionado.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ba7', name:'Peso muerto convencional', muscle:'Espalda', defaultSets:4, defaultReps:'5-6', restSeconds:120, tip:'Espalda neutral. Empuja el suelo. Lleva las caderas adelante.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ba8', name:'Remo en máquina chest-supported', muscle:'Espalda', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'El pecho en el pad elimina el uso de la espalda baja.', icon:Icons.fitness_center_rounded),
    ],

    'Abdomen': [
      ExerciseItem(id:'ab1', name:'Crunches clásicos', muscle:'Abdomen', defaultSets:3, defaultReps:'20-25', restSeconds:45, tip:'No jales el cuello. Flexiona desde el abdomen.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ab2', name:'Plancha frontal', muscle:'Abdomen', defaultSets:3, defaultReps:'45-60 seg', restSeconds:30, tip:'Cuerpo recto de cabeza a talones. Respira continuamente.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ab3', name:'Elevación de piernas colgado', muscle:'Abdomen', defaultSets:3, defaultReps:'12-15', restSeconds:45, tip:'Sube lentamente. Baja sin balanceo.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ab4', name:'Rueda abdominal', muscle:'Abdomen', defaultSets:3, defaultReps:'10-12', restSeconds:60, tip:'Mantén la zona lumbar protegida. No hiperextiendas.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ab5', name:'Crunches en polea', muscle:'Abdomen', defaultSets:3, defaultReps:'15-20', restSeconds:45, tip:'Flexiona el abdomen, no solo inclinas el cuerpo.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ab6', name:'Plancha lateral', muscle:'Abdomen', defaultSets:3, defaultReps:'30-45 seg c/lado', restSeconds:30, tip:'Caderas alineadas. No dejes que caigan.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ab7', name:'Giro ruso con peso', muscle:'Abdomen', defaultSets:3, defaultReps:'20 giros', restSeconds:45, tip:'Pies elevados para mayor dificultad. Toca el suelo a cada lado.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'ab8', name:'Dead bug', muscle:'Abdomen', defaultSets:3, defaultReps:'10 c/lado', restSeconds:45, tip:'Zona lumbar pegada al suelo siempre. Movimiento lento.', icon:Icons.sports_gymnastics_rounded),
    ],

    'Cuádriceps': [
      ExerciseItem(id:'qu1', name:'Sentadilla con barra', muscle:'Cuádriceps', defaultSets:4, defaultReps:'6-8', restSeconds:120, tip:'Rodillas siguen la línea de los pies. Profundidad mínima: paralelo.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'qu2', name:'Prensa de piernas 45°', muscle:'Cuádriceps', defaultSets:4, defaultReps:'10-12', restSeconds:90, tip:'Pies a la anchura de hombros. No bloquees las rodillas.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'qu3', name:'Extensión de cuádriceps en máquina', muscle:'Cuádriceps', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Pausa 1 seg arriba. Baja controlado en 3 seg.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'qu4', name:'Sentadilla frontal', muscle:'Cuádriceps', defaultSets:4, defaultReps:'6-8', restSeconds:120, tip:'Mayor énfasis en cuádriceps que la sentadilla trasera.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'qu5', name:'Hack squat en máquina', muscle:'Cuádriceps', defaultSets:3, defaultReps:'10-12', restSeconds:90, tip:'Pies más bajos en la plataforma para más énfasis en cuádriceps.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'qu6', name:'Zancadas caminando', muscle:'Cuádriceps', defaultSets:3, defaultReps:'12 c/lado', restSeconds:60, tip:'Rodilla trasera casi toca el suelo. Torso recto.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'qu7', name:'Step up con mancuernas', muscle:'Cuádriceps', defaultSets:3, defaultReps:'12 c/lado', restSeconds:60, tip:'Empuja con el talón para activar más el glúteo.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'qu8', name:'Sissy squat', muscle:'Cuádriceps', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Aislamiento extremo de cuádriceps. Mantén las caderas adelante.', icon:Icons.sports_gymnastics_rounded),
    ],

    'Isquiotibiales': [
      ExerciseItem(id:'ha1', name:'Peso muerto rumano', muscle:'Isquiotibiales', defaultSets:4, defaultReps:'10-12', restSeconds:90, tip:'Caderas atrás, espalda neutral. Siente el estiramiento.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ha2', name:'Curl femoral tumbado', muscle:'Isquiotibiales', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Contrae el glúteo. Baja en 3 segundos.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ha3', name:'Curl femoral de pie (unilateral)', muscle:'Isquiotibiales', defaultSets:3, defaultReps:'12 c/lado', restSeconds:60, tip:'Trabaja la estabilidad y el aislamiento por separado.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ha4', name:'Buenos días con barra', muscle:'Isquiotibiales', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Bisagra de cadera. Mantén la espalda recta.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ha5', name:'Peso muerto piernas rígidas', muscle:'Isquiotibiales', defaultSets:3, defaultReps:'10-12', restSeconds:90, tip:'Sin flexión de rodilla. Siente el estiramiento máximo.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ha6', name:'Curl femoral sentado', muscle:'Isquiotibiales', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'La posición sentada estira el músculo activamente.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ha7', name:'Zancadas inversas', muscle:'Isquiotibiales', defaultSets:3, defaultReps:'12 c/lado', restSeconds:60, tip:'Paso atrás. Mayor enfoque en isquiotibiales que la zancada normal.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'ha8', name:'Nordic curl', muscle:'Isquiotibiales', defaultSets:3, defaultReps:'6-8', restSeconds:90, tip:'Ejercicio avanzado. Excelente para fuerza excéntrica.', icon:Icons.sports_gymnastics_rounded),
    ],

    'Glúteos': [
      ExerciseItem(id:'gl1', name:'Hip thrust con barra', muscle:'Glúteos', defaultSets:4, defaultReps:'10-12', restSeconds:75, tip:'Empuja las caderas al techo. Aprieta los glúteos arriba.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'gl2', name:'Sentadilla sumo', muscle:'Glúteos', defaultSets:4, defaultReps:'10-12', restSeconds:90, tip:'Pies hacia afuera, rodillas sobre los pies.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'gl3', name:'Patada de glúteo en máquina', muscle:'Glúteos', defaultSets:3, defaultReps:'15 c/lado', restSeconds:45, tip:'Contrae el glúteo en cada repetición. No uses impulso.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'gl4', name:'Abducción de cadera en máquina', muscle:'Glúteos', defaultSets:3, defaultReps:'15-20', restSeconds:45, tip:'Trabaja el glúteo medio. Importante para estabilidad.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'gl5', name:'Puente de glúteos con peso', muscle:'Glúteos', defaultSets:3, defaultReps:'15-20', restSeconds:60, tip:'Coloca el peso en las caderas. Aprieta arriba.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'gl6', name:'Zancadas con paso largo', muscle:'Glúteos', defaultSets:3, defaultReps:'12 c/lado', restSeconds:60, tip:'Paso largo = más glúteo. Paso corto = más cuádriceps.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'gl7', name:'Romanian split squat (búlgara)', muscle:'Glúteos', defaultSets:3, defaultReps:'10-12 c/lado', restSeconds:75, tip:'Pie trasero en banco elevado. Desciende controlado.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'gl8', name:'Cable kickback', muscle:'Glúteos', defaultSets:3, defaultReps:'15 c/lado', restSeconds:45, tip:'Patea hacia atrás y arriba. Mantén la cadera estable.', icon:Icons.sports_gymnastics_rounded),
    ],

    'Gemelos': [
      ExerciseItem(id:'ca1', name:'Elevaciones de talones de pie', muscle:'Gemelos', defaultSets:4, defaultReps:'15-20', restSeconds:45, tip:'Pausa de 1 seg en la cima. Baja completamente.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'ca2', name:'Elevaciones de talones sentado', muscle:'Gemelos', defaultSets:4, defaultReps:'15-20', restSeconds:45, tip:'Trabaja más el sóleo (músculo profundo).', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ca3', name:'Elevaciones en la prensa', muscle:'Gemelos', defaultSets:4, defaultReps:'15-20', restSeconds:45, tip:'Rango de movimiento completo. No rebotes.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'ca4', name:'Elevaciones unilaterales', muscle:'Gemelos', defaultSets:3, defaultReps:'15 c/lado', restSeconds:30, tip:'Con el peso corporal o una mancuerna en la mano libre.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'ca5', name:'Elevaciones en escalón', muscle:'Gemelos', defaultSets:4, defaultReps:'15-20', restSeconds:45, tip:'El talón cuelga para mayor rango de movimiento.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'ca6', name:'Saltar a la cuerda', muscle:'Gemelos', defaultSets:3, defaultReps:'60 seg', restSeconds:60, tip:'Excelente para gemelos y cardio simultáneamente.', icon:Icons.directions_run_rounded),
      ExerciseItem(id:'ca7', name:'Caminar en puntillas', muscle:'Gemelos', defaultSets:3, defaultReps:'30 seg', restSeconds:30, tip:'Simple y efectivo. Mantén el equilibrio.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'ca8', name:'Donkey calf raises', muscle:'Gemelos', defaultSets:3, defaultReps:'15-20', restSeconds:45, tip:'Clásico culturista. Enfatiza el gastrocnemio.', icon:Icons.fitness_center_rounded),
    ],

    'Trapecio': [
      ExerciseItem(id:'tp1', name:'Encogimientos con barra', muscle:'Trapecio', defaultSets:4, defaultReps:'12-15', restSeconds:60, tip:'Sube directo hacia las orejas. No gires los hombros.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tp2', name:'Encogimientos con mancuernas', muscle:'Trapecio', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Mayor rango de movimiento que con barra.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tp3', name:'Remo al cuello', muscle:'Trapecio', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Codos por encima de las muñecas. Cuidado con el peso.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tp4', name:'Peso muerto con agarre alto', muscle:'Trapecio', defaultSets:3, defaultReps:'6-8', restSeconds:120, tip:'El peso muerto activa fuertemente el trapecio.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'tp5', name:'Farmer walk (caminata del granjero)', muscle:'Trapecio', defaultSets:3, defaultReps:'30 m', restSeconds:90, tip:'Carga pesada. Hombros hacia atrás y abajo.', icon:Icons.directions_walk_rounded),
      ExerciseItem(id:'tp6', name:'Face pull (trapecio medio)', muscle:'Trapecio', defaultSets:3, defaultReps:'15', restSeconds:45, tip:'Trabaja el trapecio medio y posterior del deltoides.', icon:Icons.sports_gymnastics_rounded),
    ],

    'Lumbares': [
      ExerciseItem(id:'lb1', name:'Peso muerto convencional', muscle:'Lumbares', defaultSets:4, defaultReps:'5-6', restSeconds:120, tip:'El mejor ejercicio para lumbares y cuerpo completo.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'lb2', name:'Hiperextensiones en banco', muscle:'Lumbares', defaultSets:3, defaultReps:'12-15', restSeconds:60, tip:'Sube hasta alinear el cuerpo. No hiperextiendas.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'lb3', name:'Superman tumbado', muscle:'Lumbares', defaultSets:3, defaultReps:'12-15', restSeconds:45, tip:'Levanta brazos y piernas simultáneamente. Pausa arriba.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'lb4', name:'Plancha prono (lumbar)', muscle:'Lumbares', defaultSets:3, defaultReps:'45 seg', restSeconds:30, tip:'La plancha también trabaja los erectores espinales.', icon:Icons.sports_gymnastics_rounded),
      ExerciseItem(id:'lb5', name:'Buenos días con barra', muscle:'Lumbares', defaultSets:3, defaultReps:'10-12', restSeconds:75, tip:'Bisagra de cadera controlada. Espalda neutral.', icon:Icons.fitness_center_rounded),
      ExerciseItem(id:'lb6', name:'Remo con soporte pectoral', muscle:'Lumbares', defaultSets:3, defaultReps:'10-12', restSeconds:60, tip:'Versión segura que protege la zona lumbar.', icon:Icons.fitness_center_rounded),
    ],
  };

  // Obtiene todos los ejercicios de un grupo muscular
  static List<ExerciseItem> forMuscle(String muscle) =>
      byMuscle[muscle] ?? [];

  // Todos los grupos musculares disponibles
  static List<String> get allMuscles => byMuscle.keys.toList();
}
