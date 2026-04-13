// lib/services/food_vision_service.dart
// ─────────────────────────────────────────────────────────────────
// Analiza fotos de comida con Google Gemini Vision.
// Llama directamente a la API de Gemini — sin intermediarios.
// Plan gratuito: 1,500 análisis/día por clave.
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

// ── Alimento detectado en la foto ─────────────────────────────────
class VisionFoodItem {
  final String name;
  final int    estimatedWeightG;
  final int    caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const VisionFoodItem({
    required this.name,
    required this.estimatedWeightG,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  int    get calories => (caloriesPer100g * estimatedWeightG / 100).round();
  double get protein  => double.parse((proteinPer100g * estimatedWeightG / 100).toStringAsFixed(1));
  double get carbs    => double.parse((carbsPer100g   * estimatedWeightG / 100).toStringAsFixed(1));
  double get fat      => double.parse((fatPer100g     * estimatedWeightG / 100).toStringAsFixed(1));

  factory VisionFoodItem.fromMap(Map<String, dynamic> m) => VisionFoodItem(
    name:             m['name']                ?? 'Alimento',
    estimatedWeightG: (m['estimated_weight_g'] ?? 100) as int,
    caloriesPer100g:  (m['calories_per_100g']  ?? 0)   as int,
    proteinPer100g:   (m['protein_per_100g']   ?? 0.0).toDouble(),
    carbsPer100g:     (m['carbs_per_100g']     ?? 0.0).toDouble(),
    fatPer100g:       (m['fat_per_100g']       ?? 0.0).toDouble(),
  );
}

// ── Resultado del análisis ─────────────────────────────────────────
class VisionAnalysisResult {
  final List<VisionFoodItem> foods;
  final String?              notes;
  final String?              error;

  const VisionAnalysisResult({required this.foods, this.notes, this.error});

  bool   get success       => error == null && foods.isNotEmpty;
  int    get totalCalories => foods.fold(0,   (s, f) => s + f.calories);
  double get totalProtein  => foods.fold(0.0, (s, f) => s + f.protein);
  double get totalCarbs    => foods.fold(0.0, (s, f) => s + f.carbs);
  double get totalFat      => foods.fold(0.0, (s, f) => s + f.fat);
}

// ─────────────────────────────────────────────────────────────────
class FoodVisionService {
  FoodVisionService._();

  // URL directa a Gemini — sin proxy
  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const _prompt = '''
Analiza la imagen de comida. Identifica CADA alimento visible.

Devuelve ÚNICAMENTE un JSON válido con este formato exacto (sin texto adicional, sin markdown):
{
  "foods": [
    {
      "name": "Nombre del alimento en español",
      "estimated_weight_g": 150,
      "calories_per_100g": 200,
      "protein_per_100g": 15.0,
      "carbs_per_100g": 25.0,
      "fat_per_100g": 8.0
    }
  ],
  "notes": "Observación breve sobre la porción"
}

Reglas:
- estimated_weight_g: peso estimado de ESA PORCIÓN visible en la foto
- calories_per_100g: calorías por cada 100g del alimento
- Nombres en español (arepa, pollo, arroz, café, huevo, etc.)
- Sé específico: "pechuga de pollo a la plancha" no solo "carne"
''';

  static Future<VisionAnalysisResult> analyzeFood(File imageFile) async {
    if (!AppConfig.visionEnabled) {
      return const VisionAnalysisResult(
        foods: [],
        error: 'Agrega tu clave de Gemini en lib/core/config/app_config.dart\n'
            'Obtén una gratis en: aistudio.google.com/apikey',
      );
    }

    try {
      final bytes     = await imageFile.readAsBytes();
      final base64Img = base64Encode(bytes);
      final mimeType  = imageFile.path.toLowerCase().endsWith('.png')
          ? 'image/png' : 'image/jpeg';

      final url = Uri.parse('$_geminiUrl?key=${AppConfig.geminiApiKey}');

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Img,
                }
              },
              {'text': _prompt},
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 1024,
        },
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 400) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'Clave de API inválida. Verifica tu clave en app_config.dart.',
        );
      }
      if (response.statusCode == 403) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'Clave de API sin permisos. Activa Gemini API en Google AI Studio.',
        );
      }
      if (response.statusCode == 429) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'Límite diario alcanzado (1,500/día). Intenta mañana o usa otra clave.',
        );
      }
      if (response.statusCode != 200) {
        String msg = '';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          msg = err['error']?['message']?.toString() ?? response.body;
        } catch (_) {
          msg = response.body.length > 150
              ? response.body.substring(0, 150)
              : response.body;
        }
        return VisionAnalysisResult(
          foods: [],
          error: 'Error ${response.statusCode}: $msg',
        );
      }

      return _parseResponse(response.body);

    } on SocketException {
      return const VisionAnalysisResult(
        foods: [],
        error: 'Sin conexión a internet. Verifica tu red.',
      );
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'Tiempo de espera agotado. Intenta con otra foto.',
        );
      }
      return VisionAnalysisResult(
        foods: [],
        error: 'Error: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  static VisionAnalysisResult _parseResponse(String rawBody) {
    try {
      final data  = jsonDecode(rawBody) as Map<String, dynamic>;
      final parts = data['candidates']?[0]?['content']?['parts'] as List?;

      if (parts == null || parts.isEmpty) {
        return const VisionAnalysisResult(
            foods: [], error: 'La IA no devolvió respuesta. Intenta de nuevo.');
      }

      var text = (parts[0]['text'] as String).trim()
          .replaceAll('```json', '').replaceAll('```', '').trim();

      // Extraer solo el JSON si viene con texto extra
      final start = text.indexOf('{');
      final end   = text.lastIndexOf('}');
      if (start != -1 && end != -1 && start < end) {
        text = text.substring(start, end + 1);
      }

      final parsed    = jsonDecode(text) as Map<String, dynamic>;
      final foodsList = (parsed['foods'] as List?) ?? [];

      final foods = foodsList
          .map((f) => VisionFoodItem.fromMap(Map<String, dynamic>.from(f as Map)))
          .where((f) => f.caloriesPer100g > 0)
          .toList();

      if (foods.isEmpty) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'No se detectaron alimentos. Intenta con otra foto.',
        );
      }

      return VisionAnalysisResult(
        foods: foods,
        notes: parsed['notes'] as String?,
      );
    } catch (_) {
      return const VisionAnalysisResult(
        foods: [],
        error: 'No se pudo interpretar la respuesta. Intenta de nuevo.',
      );
    }
  }
}