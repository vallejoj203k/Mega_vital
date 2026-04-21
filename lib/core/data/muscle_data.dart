// lib/core/data/muscle_data.dart
// ─────────────────────────────────────────────────────────────────
// Base de datos completa de grupos musculares y ejercicios.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Dificultad de ejercicio ───────────────────────────────────────
enum ExerciseDifficulty { facil, medio, duro }

// ── Modelo de ejercicio ────────────────────────────────────────────
class ExerciseItem {
  final String id;
  final String name;
  final String muscleId;
  final String sets;        // "3-4 series"
  final String reps;        // "8-12 reps" o "45 seg"
  final int    restSeconds;
  final String? tip;
  final IconData icon;
  final ExerciseDifficulty difficulty;

  const ExerciseItem({
    required this.id,
    required this.name,
    required this.muscleId,
    required this.sets,
    required this.reps,
    this.restSeconds = 60,
    this.tip,
    required this.icon,
    this.difficulty = ExerciseDifficulty.medio,
  });
}

// ── Modelo de grupo muscular ───────────────────────────────────────
class MuscleGroup {
  final String   id;
  final String   name;
  final String   nameShort;
  final Color    color;
  final bool     isFront;       // true = vista frontal
  final String   bodyRegion;    // 'upper' | 'core' | 'lower'

  const MuscleGroup({
    required this.id,
    required this.name,
    required this.nameShort,
    required this.color,
    required this.isFront,
    required this.bodyRegion,
  });
}

// ── Modelo de rutina guardada ──────────────────────────────────────
class SavedRoutine {
  final String              id;
  final String              name;
  final String              muscleId;
  final String              muscleName;
  final List<ExerciseItem>  exercises;
  final Map<String, double> exerciseWeights; // exerciseId → kg
  final DateTime            createdAt;

  const SavedRoutine({
    required this.id,
    required this.name,
    required this.muscleId,
    required this.muscleName,
    required this.exercises,
    this.exerciseWeights = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'muscleId': muscleId,
    'muscleName': muscleName,
    'exerciseIds': exercises.map((e) => e.id).toList(),
    'exerciseWeights': exerciseWeights,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ─────────────────────────────────────────────────────────────────
// DATOS — grupos musculares
// ─────────────────────────────────────────────────────────────────
const List<MuscleGroup> kMuscleGroups = [
  // ── FRONTAL ───────────────────────────────────────────────────
  MuscleGroup(id: 'pecho',    name: 'Pecho',         nameShort: 'Pecho',
      color: Color(0xFF00FF87), isFront: true,  bodyRegion: 'upper'),
  MuscleGroup(id: 'hombros',  name: 'Hombros',       nameShort: 'Hombros',
      color: Color(0xFF4FC3F7), isFront: true,  bodyRegion: 'upper'),
  MuscleGroup(id: 'biceps',   name: 'Bíceps',        nameShort: 'Bíceps',
      color: Color(0xFFBB86FC), isFront: true,  bodyRegion: 'upper'),
  MuscleGroup(id: 'abs',      name: 'Abdomen / Core',nameShort: 'Abdomen',
      color: Color(0xFFFF6B35), isFront: true,  bodyRegion: 'core'),
  MuscleGroup(id: 'cuadriceps',name: 'Cuádriceps',   nameShort: 'Cuádriceps',
      color: Color(0xFF4FC3F7), isFront: true,  bodyRegion: 'lower'),
  MuscleGroup(id: 'gemelos',  name: 'Gemelos',       nameShort: 'Gemelos',
      color: Color(0xFF00CC6A), isFront: true,  bodyRegion: 'lower'),

  // ── POSTERIOR ─────────────────────────────────────────────────
  MuscleGroup(id: 'espalda',  name: 'Espalda alta / Trapecio',
      nameShort: 'Espalda',
      color: Color(0xFF4FC3F7), isFront: false, bodyRegion: 'upper'),
  MuscleGroup(id: 'dorsales', name: 'Dorsales / Lats',
      nameShort: 'Dorsales',
      color: Color(0xFF00FF87), isFront: false, bodyRegion: 'upper'),
  MuscleGroup(id: 'triceps',  name: 'Tríceps',       nameShort: 'Tríceps',
      color: Color(0xFFBB86FC), isFront: false, bodyRegion: 'upper'),
  MuscleGroup(id: 'lumbar',   name: 'Lumbar',        nameShort: 'Lumbar',
      color: Color(0xFFFFB020), isFront: false, bodyRegion: 'core'),
  MuscleGroup(id: 'gluteos',  name: 'Glúteos',       nameShort: 'Glúteos',
      color: Color(0xFFFF6B35), isFront: false, bodyRegion: 'lower'),
  MuscleGroup(id: 'isquio',   name: 'Isquiotibiales',nameShort: 'Isquios',
      color: Color(0xFFBB86FC), isFront: false, bodyRegion: 'lower'),
];

MuscleGroup? getMuscleById(String id) =>
    kMuscleGroups.cast<MuscleGroup?>()
        .firstWhere((m) => m?.id == id, orElse: () => null);

// ─────────────────────────────────────────────────────────────────
// DATOS — ejercicios por grupo muscular
// ─────────────────────────────────────────────────────────────────
const List<ExerciseItem> kAllExercises = [

  // ── PECHO ─────────────────────────────────────────────────────
  ExerciseItem(id:'pec1', muscleId:'pecho', name:'Press de banca plano',
      sets:'4', reps:'8-10', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'Baja la barra despacio. 2 seg de excéntrico.'),
  ExerciseItem(id:'pec2', muscleId:'pecho', name:'Press inclinado con mancuernas',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'Codos a 45° del torso.'),
  ExerciseItem(id:'pec3', muscleId:'pecho', name:'Aperturas en polea baja',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Estira al abrir, aprieta al cerrar.'),
  ExerciseItem(id:'pec4', muscleId:'pecho', name:'Fondos en paralelas',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Inclínate hacia adelante para mayor activación pectoral.'),
  ExerciseItem(id:'pec5', muscleId:'pecho', name:'Press con mancuernas plano',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'pec6', muscleId:'pecho', name:'Aperturas con mancuernas',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'No bloquees los codos. Ligera flexión permanente.'),
  ExerciseItem(id:'pec7', muscleId:'pecho', name:'Press declinado con barra',
      sets:'3', reps:'8-10', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'pec8', muscleId:'pecho', name:'Crossover en polea',
      sets:'3', reps:'15', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),

  // ── HOMBROS ────────────────────────────────────────────────────
  ExerciseItem(id:'hom1', muscleId:'hombros', name:'Press militar con barra',
      sets:'4', reps:'6-8', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Espalda recta. No arquees la zona lumbar.'),
  ExerciseItem(id:'hom2', muscleId:'hombros', name:'Elevaciones laterales',
      sets:'4', reps:'12-15', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Codos ligeramente flexionados. Sube hasta la altura de los hombros.'),
  ExerciseItem(id:'hom3', muscleId:'hombros', name:'Elevaciones frontales',
      sets:'3', reps:'12', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'hom4', muscleId:'hombros', name:'Arnold Press',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'Gira las palmas mientras subes.'),
  ExerciseItem(id:'hom5', muscleId:'hombros', name:'Face Pulls en polea',
      sets:'3', reps:'15-20', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Excelente para la salud de los hombros.'),
  ExerciseItem(id:'hom6', muscleId:'hombros', name:'Press con mancuernas sentado',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'hom7', muscleId:'hombros', name:'Pájaro (posterior de hombro)',
      sets:'3', reps:'15', restSeconds:45, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),

  // ── BÍCEPS ─────────────────────────────────────────────────────
  ExerciseItem(id:'bic1', muscleId:'biceps', name:'Curl con barra EZ',
      sets:'4', reps:'8-10', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'No uses el impulso del torso.'),
  ExerciseItem(id:'bic2', muscleId:'biceps', name:'Curl alterno con mancuernas',
      sets:'3', reps:'10-12 c/lado', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'bic3', muscleId:'biceps', name:'Curl martillo',
      sets:'3', reps:'12', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Pulgares hacia arriba en todo momento.'),
  ExerciseItem(id:'bic4', muscleId:'biceps', name:'Curl concentrado',
      sets:'3', reps:'12-15 c/lado', restSeconds:45, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'bic5', muscleId:'biceps', name:'Curl en banco inclinado',
      sets:'3', reps:'10-12', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'Mayor estiramiento del bíceps.'),
  ExerciseItem(id:'bic6', muscleId:'biceps', name:'Curl 21s con barra',
      sets:'3', reps:'21 reps', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro),
  ExerciseItem(id:'bic7', muscleId:'biceps', name:'Curl en polea baja',
      sets:'3', reps:'15', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),

  // ── ABDOMEN ────────────────────────────────────────────────────
  ExerciseItem(id:'abs1', muscleId:'abs', name:'Plancha frontal',
      sets:'3', reps:'45-60 seg', restSeconds:30, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Cuerpo recto como una tabla. No eleves las caderas.'),
  ExerciseItem(id:'abs2', muscleId:'abs', name:'Crunches con giro',
      sets:'3', reps:'20', restSeconds:30, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'abs3', muscleId:'abs', name:'Elevación de piernas colgado',
      sets:'3', reps:'12-15', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'Control en la bajada. Sin impulso.'),
  ExerciseItem(id:'abs4', muscleId:'abs', name:'Russian Twist',
      sets:'3', reps:'20 (10 c/lado)', restSeconds:30, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'abs5', muscleId:'abs', name:'Dead Bug',
      sets:'3', reps:'10 c/lado', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Zona lumbar pegada al suelo en todo momento.'),
  ExerciseItem(id:'abs6', muscleId:'abs', name:'Plancha lateral',
      sets:'3', reps:'30-45 seg c/lado', restSeconds:30, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'abs7', muscleId:'abs', name:'Ab Wheel (Rollout)',
      sets:'3', reps:'8-12', restSeconds:60, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro),
  ExerciseItem(id:'abs8', muscleId:'abs', name:'Hollow Hold',
      sets:'3', reps:'30 seg', restSeconds:30, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.medio),

  // ── CUÁDRICEPS ─────────────────────────────────────────────────
  ExerciseItem(id:'cua1', muscleId:'cuadriceps', name:'Sentadilla con barra',
      sets:'4', reps:'6-8', restSeconds:120, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Profundidad hasta paralelo o más. Rodillas alineadas con los pies.'),
  ExerciseItem(id:'cua2', muscleId:'cuadriceps', name:'Prensa de piernas',
      sets:'3', reps:'12-15', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'No bloquees las rodillas al extender.'),
  ExerciseItem(id:'cua3', muscleId:'cuadriceps', name:'Extensión de piernas',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'cua4', muscleId:'cuadriceps', name:'Zancadas con mancuernas',
      sets:'3', reps:'12 c/lado', restSeconds:75, icon:Icons.directions_walk_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'cua5', muscleId:'cuadriceps', name:'Sentadilla Hack',
      sets:'3', reps:'10-12', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'cua6', muscleId:'cuadriceps', name:'Sentadilla Búlgara',
      sets:'3', reps:'10-12 c/lado', restSeconds:90, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Pie trasero elevado. Rodilla delantera detrás de los dedos.'),
  ExerciseItem(id:'cua7', muscleId:'cuadriceps', name:'Step-up con mancuernas',
      sets:'3', reps:'12 c/lado', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),

  // ── GEMELOS ────────────────────────────────────────────────────
  ExerciseItem(id:'gem1', muscleId:'gemelos', name:'Elevación de talones de pie',
      sets:'4', reps:'15-20', restSeconds:45, icon:Icons.directions_walk_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Pausa de 1 seg en la cima. Baja completamente.'),
  ExerciseItem(id:'gem2', muscleId:'gemelos', name:'Elevación de talones sentado',
      sets:'4', reps:'15-20', restSeconds:45, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Trabaja el sóleo.'),
  ExerciseItem(id:'gem3', muscleId:'gemelos', name:'Donkey Calf Raise',
      sets:'3', reps:'15-20', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'gem4', muscleId:'gemelos', name:'Prensa de piernas (gemelos)',
      sets:'3', reps:'20', restSeconds:45, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'gem5', muscleId:'gemelos', name:'Saltos a la cuerda',
      sets:'3', reps:'3 min', restSeconds:60, icon:Icons.directions_run_rounded,
      difficulty: ExerciseDifficulty.medio),

  // ── ESPALDA ALTA / TRAPECIO ────────────────────────────────────
  ExerciseItem(id:'esp1', muscleId:'espalda', name:'Remo con barra',
      sets:'4', reps:'8-10', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Espalda recta. Codos cerca del torso.'),
  ExerciseItem(id:'esp2', muscleId:'espalda', name:'Remo sentado en polea',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'esp3', muscleId:'espalda', name:'Encogimientos de hombros',
      sets:'4', reps:'12-15', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Pausa de 1 seg arriba.'),
  ExerciseItem(id:'esp4', muscleId:'espalda', name:'Face Pulls con cuerda',
      sets:'3', reps:'15-20', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'esp5', muscleId:'espalda', name:'Remo con mancuerna',
      sets:'3', reps:'10-12 c/lado', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'esp6', muscleId:'espalda', name:'Remo T-bar',
      sets:'3', reps:'8-10', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro),

  // ── DORSALES ───────────────────────────────────────────────────
  ExerciseItem(id:'dor1', muscleId:'dorsales', name:'Dominadas',
      sets:'4', reps:'6-10', restSeconds:90, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Agarre prono ancho. Baja completamente.'),
  ExerciseItem(id:'dor2', muscleId:'dorsales', name:'Jalón al pecho',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'dor3', muscleId:'dorsales', name:'Jalón con agarre supino',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'dor4', muscleId:'dorsales', name:'Pullover con mancuerna',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'dor5', muscleId:'dorsales', name:'Straight Arm Pulldown',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'dor6', muscleId:'dorsales', name:'Remo en máquina',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),

  // ── TRÍCEPS ────────────────────────────────────────────────────
  ExerciseItem(id:'tri1', muscleId:'triceps', name:'Press francés con barra EZ',
      sets:'4', reps:'8-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'No dejes que los codos se abran.'),
  ExerciseItem(id:'tri2', muscleId:'triceps', name:'Extensión en polea alta',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Codos pegados al torso. Solo mueve el antebrazo.'),
  ExerciseItem(id:'tri3', muscleId:'triceps', name:'Fondos (tríceps)',
      sets:'3', reps:'10-15', restSeconds:75, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Cuerpo vertical para mayor activación de tríceps.'),
  ExerciseItem(id:'tri4', muscleId:'triceps', name:'Kickback con mancuerna',
      sets:'3', reps:'12-15 c/lado', restSeconds:45, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'tri5', muscleId:'triceps', name:'Press cerrado en banca',
      sets:'3', reps:'8-10', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'tri6', muscleId:'triceps', name:'Extensión sobre cabeza',
      sets:'3', reps:'12', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'tri7', muscleId:'triceps', name:'Extensión con cuerda',
      sets:'3', reps:'15', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),

  // ── LUMBAR ─────────────────────────────────────────────────────
  ExerciseItem(id:'lum1', muscleId:'lumbar', name:'Peso muerto convencional',
      sets:'4', reps:'5-6', restSeconds:120, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Espalda recta. Empuja el suelo. Cabeza neutra.'),
  ExerciseItem(id:'lum2', muscleId:'lumbar', name:'Hiperextensiones',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'lum3', muscleId:'lumbar', name:'Buenos días con barra',
      sets:'3', reps:'10-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'lum4', muscleId:'lumbar', name:'Superman',
      sets:'3', reps:'15-20', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'lum5', muscleId:'lumbar', name:'Bird Dog',
      sets:'3', reps:'10 c/lado', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil,
      tip:'Mantén la columna neutra.'),

  // ── GLÚTEOS ────────────────────────────────────────────────────
  ExerciseItem(id:'glu1', muscleId:'gluteos', name:'Hip Thrust con barra',
      sets:'4', reps:'8-12', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'Aprieta los glúteos en la cima. No hiperextiendas la lumbar.'),
  ExerciseItem(id:'glu2', muscleId:'gluteos', name:'Sentadilla Búlgara',
      sets:'3', reps:'10-12 c/lado', restSeconds:90, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro),
  ExerciseItem(id:'glu3', muscleId:'gluteos', name:'Puente de glúteos',
      sets:'3', reps:'15-20', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'glu4', muscleId:'gluteos', name:'Patada trasera en cable',
      sets:'3', reps:'15 c/lado', restSeconds:45, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'glu5', muscleId:'gluteos', name:'Abductor en máquina',
      sets:'3', reps:'15-20', restSeconds:45, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.facil),
  ExerciseItem(id:'glu6', muscleId:'gluteos', name:'Peso muerto sumo',
      sets:'3', reps:'8-10', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro),

  // ── ISQUIOTIBIALES ─────────────────────────────────────────────
  ExerciseItem(id:'isq1', muscleId:'isquio', name:'Curl femoral tumbado',
      sets:'4', reps:'10-12', restSeconds:75, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio,
      tip:'Contracción total arriba. Baja controlado.'),
  ExerciseItem(id:'isq2', muscleId:'isquio', name:'Peso muerto rumano',
      sets:'4', reps:'8-10', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Empuja las caderas hacia atrás. Espalda neutral.'),
  ExerciseItem(id:'isq3', muscleId:'isquio', name:'Peso muerto pierna rígida',
      sets:'3', reps:'10-12', restSeconds:90, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.duro),
  ExerciseItem(id:'isq4', muscleId:'isquio', name:'Nordic Curl',
      sets:'3', reps:'6-8', restSeconds:90, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro,
      tip:'Uno de los mejores para prevenir lesiones.'),
  ExerciseItem(id:'isq5', muscleId:'isquio', name:'Curl femoral sentado',
      sets:'3', reps:'12-15', restSeconds:60, icon:Icons.fitness_center_rounded,
      difficulty: ExerciseDifficulty.medio),
  ExerciseItem(id:'isq6', muscleId:'isquio', name:'Glute Ham Raise',
      sets:'3', reps:'8-10', restSeconds:90, icon:Icons.sports_gymnastics_rounded,
      difficulty: ExerciseDifficulty.duro),
];

List<ExerciseItem> exercisesForMuscle(String muscleId) =>
    kAllExercises.where((e) => e.muscleId == muscleId).toList();
