// lib/core/mock/mock_data.dart
import 'package:flutter/material.dart';

class UserModel {
  final String name, username, goal, avatarInitials;
  final int streak, age;
  final double weight, height;
  const UserModel({required this.name, required this.username, required this.goal,
    required this.avatarInitials, required this.streak, required this.weight,
    required this.height, required this.age});
}

class StatModel {
  final String label, value, unit;
  final double progress;
  final IconData icon;
  final Color color;
  const StatModel({required this.label, required this.value, required this.unit,
    required this.progress, required this.icon, required this.color});
}

class ExerciseModel {
  final String name, reps, muscle;
  final int sets, restSeconds;
  final String? notes;
  final IconData icon;
  const ExerciseModel({required this.name, required this.sets, required this.reps,
    required this.muscle, required this.icon, this.notes, this.restSeconds = 60});
}

class WorkoutModel {
  final String name, category, difficulty;
  final int durationMinutes, calories, exercises;
  final String? description;
  final IconData icon;
  final Color color;
  final List<ExerciseModel> exerciseList;
  const WorkoutModel({required this.name, required this.category,
    required this.durationMinutes, required this.calories, required this.difficulty,
    required this.exercises, required this.icon, required this.color,
    this.description, this.exerciseList = const []});
}

class NutritionIngredientModel {
  final String name, unit;
  final double amount, protein, carbs, fat;
  final int calories;
  const NutritionIngredientModel({required this.name, required this.amount,
    required this.unit, required this.calories, required this.protein,
    required this.carbs, required this.fat});
}

class NutritionMealModel {
  final String name, time;
  final int calories;
  final double protein, carbs, fat;
  final IconData icon;
  final Color color;
  final List<NutritionIngredientModel> ingredients;
  final String? notes;
  const NutritionMealModel({required this.name, required this.calories,
    required this.protein, required this.carbs, required this.fat,
    required this.time, required this.icon, required this.color,
    this.ingredients = const [], this.notes});
}

class CommunityPostModel {
  final String userName, initials, content, time;
  final int likes, comments;
  final String? achievement;
  final IconData? achievementIcon;
  const CommunityPostModel({required this.userName, required this.initials,
    required this.content, required this.time, required this.likes,
    required this.comments, this.achievement, this.achievementIcon});
}

class AchievementModel {
  final String title, description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  const AchievementModel({required this.title, required this.description,
    required this.icon, required this.color, required this.unlocked});
}

class MockData {
  MockData._();

  static const UserModel currentUser = UserModel(
    name: 'Juan García', username: '@juanfit', goal: 'Ganar músculo',
    avatarInitials: 'JG', streak: 14, weight: 78.5, height: 178, age: 28,
  );

  static const List<StatModel> todayStats = [
    StatModel(label: 'Calorías', value: '1,840', unit: 'kcal', progress: 0.72,
      icon: Icons.local_fire_department_rounded, color: Color(0xFFFF6B35)),
    StatModel(label: 'Proteínas', value: '134', unit: 'g', progress: 0.85,
      icon: Icons.fitness_center_rounded, color: Color(0xFF00FF87)),
    StatModel(label: 'Agua', value: '1.8', unit: 'L', progress: 0.60,
      icon: Icons.water_drop_rounded, color: Color(0xFF4FC3F7)),
  ];

  static const Map<String, double> weeklyProgress = {
    'Lun': 0.9, 'Mar': 0.7, 'Mié': 1.0, 'Jue': 0.5, 'Vie': 0.8, 'Sáb': 0.3, 'Dom': 0.0,
  };

  static const List<String> motivationalQuotes = [
    'El dolor que sientes hoy será la fuerza que sentirás mañana.',
    'No pares cuando estés cansado. Para cuando hayas terminado.',
  ];

  static const List<WorkoutModel> workouts = [
    WorkoutModel(
      name: 'Pecho & Tríceps', category: 'Fuerza', durationMinutes: 55,
      calories: 380, difficulty: 'Medio', exercises: 6,
      icon: Icons.fitness_center_rounded, color: Color(0xFF00FF87),
      description: 'Rutina de empuje enfocada en pectoral mayor y tríceps. Ideal para días de empuje en un split PPL.',
      exerciseList: [
        ExerciseModel(name: 'Press de banca plano', sets: 4, reps: '8-10', muscle: 'Pectoral mayor', icon: Icons.fitness_center_rounded, notes: 'Baja la barra despacio, 2 seg de excéntrico.', restSeconds: 90),
        ExerciseModel(name: 'Press inclinado con mancuernas', sets: 3, reps: '10-12', muscle: 'Pectoral superior', icon: Icons.fitness_center_rounded, notes: 'Mantén los codos a 45° del torso.', restSeconds: 75),
        ExerciseModel(name: 'Aperturas en polea', sets: 3, reps: '12-15', muscle: 'Pectoral medio', icon: Icons.sports_gymnastics_rounded, notes: 'Estira bien al abrir, aprieta en el centro.', restSeconds: 60),
        ExerciseModel(name: 'Fondos en paralelas', sets: 3, reps: '10-12', muscle: 'Pectoral inferior / Tríceps', icon: Icons.sports_gymnastics_rounded, notes: 'Inclínate hacia adelante para mayor activación.', restSeconds: 75),
        ExerciseModel(name: 'Press francés con barra EZ', sets: 3, reps: '10-12', muscle: 'Tríceps largo', icon: Icons.fitness_center_rounded, notes: 'No dejes que los codos se abran.', restSeconds: 60),
        ExerciseModel(name: 'Extensión en polea alta', sets: 3, reps: '15', muscle: 'Tríceps lateral', icon: Icons.fitness_center_rounded, notes: 'Bloquea los codos, solo mueve el antebrazo.', restSeconds: 45),
      ],
    ),
    WorkoutModel(
      name: 'HIIT Total Body', category: 'Cardio', durationMinutes: 30,
      calories: 520, difficulty: 'Difícil', exercises: 6,
      icon: Icons.directions_run_rounded, color: Color(0xFFFF6B35),
      description: 'Entrenamiento de alta intensidad. 40 seg de trabajo, 20 seg de descanso. Quema máxima de calorías.',
      exerciseList: [
        ExerciseModel(name: 'Burpees', sets: 4, reps: '40 seg', muscle: 'Cuerpo completo', icon: Icons.directions_run_rounded, notes: 'Mantén el core activo en todo momento.', restSeconds: 20),
        ExerciseModel(name: 'Mountain Climbers', sets: 4, reps: '40 seg', muscle: 'Core / Cardio', icon: Icons.nordic_walking_rounded, notes: 'Lleva las rodillas al pecho lo más rápido posible.', restSeconds: 20),
        ExerciseModel(name: 'Jump Squats', sets: 4, reps: '40 seg', muscle: 'Cuádriceps / Glúteos', icon: Icons.directions_walk_rounded, notes: 'Aterriza suave, rodillas ligeramente flexionadas.', restSeconds: 20),
        ExerciseModel(name: 'Push-ups explosivos', sets: 4, reps: '40 seg', muscle: 'Pectoral / Tríceps', icon: Icons.sports_gymnastics_rounded, notes: 'Despega las manos del suelo en cada rep.', restSeconds: 20),
        ExerciseModel(name: 'Saltos de tijera', sets: 4, reps: '40 seg', muscle: 'Cardio / Piernas', icon: Icons.directions_run_rounded, notes: 'Mantén el ritmo constante.', restSeconds: 20),
        ExerciseModel(name: 'Plancha dinámica', sets: 4, reps: '40 seg', muscle: 'Core completo', icon: Icons.sports_gymnastics_rounded, notes: 'Alterna tocar el hombro sin rotar las caderas.', restSeconds: 20),
      ],
    ),
    WorkoutModel(
      name: 'Piernas & Glúteos', category: 'Fuerza', durationMinutes: 60,
      calories: 420, difficulty: 'Difícil', exercises: 6,
      icon: Icons.sports_martial_arts_rounded, color: Color(0xFFBB86FC),
      description: 'Rutina completa de tren inferior. Fuerza máxima para cuádriceps, isquios y glúteos.',
      exerciseList: [
        ExerciseModel(name: 'Sentadilla con barra', sets: 4, reps: '6-8', muscle: 'Cuádriceps / Glúteos', icon: Icons.fitness_center_rounded, notes: 'Profundidad hasta paralelo o más.', restSeconds: 120),
        ExerciseModel(name: 'Peso muerto rumano', sets: 3, reps: '10-12', muscle: 'Isquiosurales / Glúteos', icon: Icons.fitness_center_rounded, notes: 'Empuja las caderas atrás, espalda neutral.', restSeconds: 90),
        ExerciseModel(name: 'Prensa de piernas', sets: 3, reps: '12-15', muscle: 'Cuádriceps', icon: Icons.fitness_center_rounded, notes: 'No bloquees las rodillas en la extensión.', restSeconds: 75),
        ExerciseModel(name: 'Zancadas con mancuernas', sets: 3, reps: '12 c/lado', muscle: 'Glúteos / Cuádriceps', icon: Icons.directions_walk_rounded, notes: 'Rodilla trasera casi toca el suelo.', restSeconds: 60),
        ExerciseModel(name: 'Curl femoral tumbado', sets: 3, reps: '12-15', muscle: 'Isquiosurales', icon: Icons.fitness_center_rounded, notes: 'Contracción completa arriba, baja controlado.', restSeconds: 60),
        ExerciseModel(name: 'Elevaciones de talones', sets: 4, reps: '20', muscle: 'Gemelos', icon: Icons.directions_walk_rounded, notes: 'Pausa de 1 seg en la cima.', restSeconds: 45),
      ],
    ),
    WorkoutModel(
      name: 'Espalda & Bíceps', category: 'Fuerza', durationMinutes: 50,
      calories: 340, difficulty: 'Medio', exercises: 5,
      icon: Icons.accessibility_new_rounded, color: Color(0xFF4FC3F7),
      description: 'Día de tirón. Dorsal ancho, romboides, trapecio y bíceps para el movimiento de tracción.',
      exerciseList: [
        ExerciseModel(name: 'Dominadas', sets: 4, reps: '6-10', muscle: 'Dorsal ancho', icon: Icons.sports_gymnastics_rounded, notes: 'Agarre prono ancho. Baja completamente.', restSeconds: 90),
        ExerciseModel(name: 'Remo con barra', sets: 4, reps: '8-10', muscle: 'Espalda media', icon: Icons.fitness_center_rounded, notes: 'Espalda recta, codos cerca del torso.', restSeconds: 90),
        ExerciseModel(name: 'Jalón al pecho', sets: 3, reps: '10-12', muscle: 'Dorsal / Bíceps', icon: Icons.fitness_center_rounded, notes: 'Lleva la barra a la parte alta del pecho.', restSeconds: 75),
        ExerciseModel(name: 'Curl con barra EZ', sets: 3, reps: '10-12', muscle: 'Bíceps', icon: Icons.fitness_center_rounded, notes: 'No uses el impulso del cuerpo.', restSeconds: 60),
        ExerciseModel(name: 'Curl martillo', sets: 3, reps: '12', muscle: 'Braquial / Bíceps', icon: Icons.fitness_center_rounded, notes: 'Pulgares hacia arriba en todo momento.', restSeconds: 60),
      ],
    ),
    WorkoutModel(
      name: 'Core & Abdomen', category: 'Funcional', durationMinutes: 25,
      calories: 200, difficulty: 'Fácil', exercises: 5,
      icon: Icons.sports_gymnastics_rounded, color: Color(0xFFFFB020),
      description: 'Rutina de core completa. Recto abdominal, oblicuos, transverso y estabilizadores de columna.',
      exerciseList: [
        ExerciseModel(name: 'Plancha frontal', sets: 3, reps: '45 seg', muscle: 'Transverso', icon: Icons.sports_gymnastics_rounded, notes: 'Cuerpo recto como una tabla.', restSeconds: 30),
        ExerciseModel(name: 'Crunches con giro', sets: 3, reps: '20', muscle: 'Recto / Oblicuos', icon: Icons.sports_gymnastics_rounded, notes: 'Toca el codo al lado contrario.', restSeconds: 30),
        ExerciseModel(name: 'Elevación de piernas', sets: 3, reps: '15', muscle: 'Recto inferior', icon: Icons.sports_gymnastics_rounded, notes: 'Baja sin que los pies toquen el suelo.', restSeconds: 45),
        ExerciseModel(name: 'Plancha lateral', sets: 3, reps: '30 seg c/lado', muscle: 'Oblicuos', icon: Icons.sports_gymnastics_rounded, restSeconds: 30),
        ExerciseModel(name: 'Dead Bug', sets: 3, reps: '10 c/lado', muscle: 'Core profundo', icon: Icons.sports_gymnastics_rounded, notes: 'Zona lumbar pegada al suelo.', restSeconds: 45),
      ],
    ),
    WorkoutModel(
      name: 'Yoga & Movilidad', category: 'Flexibilidad', durationMinutes: 40,
      calories: 150, difficulty: 'Fácil', exercises: 5,
      icon: Icons.self_improvement_rounded, color: Color(0xFF00CC6A),
      description: 'Sesión de movilidad articular y flexibilidad. Ideal como recuperación activa.',
      exerciseList: [
        ExerciseModel(name: 'Saludo al sol', sets: 3, reps: '5 ciclos', muscle: 'Cuerpo completo', icon: Icons.self_improvement_rounded, restSeconds: 30),
        ExerciseModel(name: 'Paloma (cadera)', sets: 2, reps: '60 seg c/lado', muscle: 'Flexores cadera', icon: Icons.self_improvement_rounded, notes: 'Respira profundo y relaja con cada exhalación.', restSeconds: 15),
        ExerciseModel(name: 'Postura del niño', sets: 2, reps: '60 seg', muscle: 'Lumbar / Dorsales', icon: Icons.self_improvement_rounded, restSeconds: 15),
        ExerciseModel(name: 'Estiramiento isquio', sets: 2, reps: '45 seg c/lado', muscle: 'Isquiosurales', icon: Icons.self_improvement_rounded, restSeconds: 15),
        ExerciseModel(name: 'Torsión espinal', sets: 2, reps: '45 seg c/lado', muscle: 'Columna / Oblicuos', icon: Icons.self_improvement_rounded, restSeconds: 15),
      ],
    ),
  ];

  static const List<NutritionMealModel> todayMeals = [
    NutritionMealModel(
      name: 'Desayuno', calories: 480, protein: 32, carbs: 55, fat: 14,
      time: '07:30', icon: Icons.wb_sunny_rounded, color: Color(0xFFFFB020),
      notes: 'Rico en proteínas para empezar el día. Prepara la avena la noche anterior.',
      ingredients: [
        NutritionIngredientModel(name: 'Avena en hojuelas', amount: 80, unit: 'g', calories: 296, protein: 10, carbs: 54, fat: 6),
        NutritionIngredientModel(name: 'Leche de almendras', amount: 200, unit: 'ml', calories: 26, protein: 1, carbs: 1, fat: 2),
        NutritionIngredientModel(name: 'Proteína en polvo', amount: 30, unit: 'g', calories: 120, protein: 24, carbs: 2, fat: 1),
        NutritionIngredientModel(name: 'Plátano', amount: 1, unit: 'unidad', calories: 89, protein: 1, carbs: 23, fat: 0),
        NutritionIngredientModel(name: 'Mantequilla de maní', amount: 15, unit: 'g', calories: 90, protein: 4, carbs: 3, fat: 8),
      ],
    ),
    NutritionMealModel(
      name: 'Almuerzo', calories: 720, protein: 56, carbs: 78, fat: 18,
      time: '12:00', icon: Icons.lunch_dining_rounded, color: Color(0xFF4FC3F7),
      notes: 'Comida principal post-entrenamiento. Arroz y pollo, el clásico de los atletas.',
      ingredients: [
        NutritionIngredientModel(name: 'Pechuga de pollo', amount: 200, unit: 'g', calories: 330, protein: 62, carbs: 0, fat: 7),
        NutritionIngredientModel(name: 'Arroz blanco cocido', amount: 180, unit: 'g', calories: 234, protein: 4, carbs: 52, fat: 0),
        NutritionIngredientModel(name: 'Brócoli al vapor', amount: 100, unit: 'g', calories: 34, protein: 3, carbs: 7, fat: 0),
        NutritionIngredientModel(name: 'Aceite de oliva', amount: 10, unit: 'ml', calories: 88, protein: 0, carbs: 0, fat: 10),
        NutritionIngredientModel(name: 'Aguacate', amount: 50, unit: 'g', calories: 80, protein: 1, carbs: 4, fat: 7),
      ],
    ),
    NutritionMealModel(
      name: 'Merienda', calories: 220, protein: 24, carbs: 20, fat: 5,
      time: '16:00', icon: Icons.apple_rounded, color: Color(0xFF00FF87),
      notes: 'Snack pre-entrenamiento. Fácil de digerir y con energía de rápida disponibilidad.',
      ingredients: [
        NutritionIngredientModel(name: 'Yogur griego 0%', amount: 150, unit: 'g', calories: 90, protein: 15, carbs: 6, fat: 0),
        NutritionIngredientModel(name: 'Plátano', amount: 1, unit: 'unidad', calories: 89, protein: 1, carbs: 23, fat: 0),
        NutritionIngredientModel(name: 'Almendras', amount: 15, unit: 'g', calories: 87, protein: 3, carbs: 3, fat: 7),
      ],
    ),
    NutritionMealModel(
      name: 'Cena', calories: 420, protein: 38, carbs: 32, fat: 12,
      time: '20:00', icon: Icons.nightlight_round, color: Color(0xFFBB86FC),
      notes: 'Cena ligera rica en proteína. El salmón aporta omega-3 para la recuperación.',
      ingredients: [
        NutritionIngredientModel(name: 'Salmón al horno', amount: 150, unit: 'g', calories: 280, protein: 34, carbs: 0, fat: 15),
        NutritionIngredientModel(name: 'Batata cocida', amount: 100, unit: 'g', calories: 86, protein: 2, carbs: 20, fat: 0),
        NutritionIngredientModel(name: 'Espinacas frescas', amount: 80, unit: 'g', calories: 18, protein: 2, carbs: 3, fat: 0),
        NutritionIngredientModel(name: 'Limón (jugo)', amount: 1, unit: 'unidad', calories: 4, protein: 0, carbs: 1, fat: 0),
      ],
    ),
  ];

  static const List<CommunityPostModel> communityPosts = [
    CommunityPostModel(userName: 'Carlos Méndez', initials: 'CM',
      content: '¡Nuevo récord personal! 120 kg en press de banca. 6 meses de trabajo duro pero valió la pena.',
      time: 'hace 12 min', likes: 47, comments: 8,
      achievement: 'Récord Personal', achievementIcon: Icons.emoji_events_rounded),
    CommunityPostModel(userName: 'Ana Torres', initials: 'AT',
      content: 'Completé mi semana 8 de entrenamiento sin fallar un día. La constancia es la clave.',
      time: 'hace 34 min', likes: 93, comments: 15,
      achievement: 'Racha de 56 días', achievementIcon: Icons.local_fire_department_rounded),
    CommunityPostModel(userName: 'Luis Herrera', initials: 'LH',
      content: 'Consejo del día: no te saltes el calentamiento. Llevo 2 años sin lesiones graves.',
      time: 'hace 1h', likes: 128, comments: 22),
    CommunityPostModel(userName: 'María Rodríguez', initials: 'MR',
      content: '¿Alguien más intenta hacer HIIT por las mañanas? Me cuesta pero los resultados son increíbles.',
      time: 'hace 2h', likes: 34, comments: 19),
  ];

  static const List<AchievementModel> achievements = [
    AchievementModel(title: 'Primer Mes', description: '30 días entrenando', icon: Icons.emoji_events_rounded, color: Color(0xFFFFB020), unlocked: true),
    AchievementModel(title: 'Racha de Fuego', description: '14 días seguidos', icon: Icons.local_fire_department_rounded, color: Color(0xFFFF6B35), unlocked: true),
    AchievementModel(title: 'Quema Calorías', description: '10,000 kcal quemadas', icon: Icons.fitness_center_rounded, color: Color(0xFF00FF87), unlocked: true),
    AchievementModel(title: 'Madrugador', description: '10 sesiones AM', icon: Icons.wb_sunny_rounded, color: Color(0xFF4FC3F7), unlocked: false),
    AchievementModel(title: 'Centurión', description: '100 entrenamientos', icon: Icons.military_tech_rounded, color: Color(0xFFBB86FC), unlocked: false),
    AchievementModel(title: 'Élite', description: '500 horas de entreno', icon: Icons.workspace_premium_rounded, color: Color(0xFFFFB020), unlocked: false),
  ];
}
