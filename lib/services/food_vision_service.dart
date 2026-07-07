// lib/services/food_vision_service.dart
// ─────────────────────────────────────────────────────────────────
// Analiza fotos de comida con Google Gemini Vision o Groq Vision.
// Llama directamente a las APIs — sin intermediarios.
// Plan gratuito Gemini: 1,500 análisis/día por clave.
// Plan gratuito Groq:   ~7,000 tokens/min, sin límite diario estricto.
// Usa ApiKeyManager para rotación automática entre múltiples claves.
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'api_key_manager.dart';
import 'remote_config_service.dart';

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

  factory VisionFoodItem.fromMap(Map<String, dynamic> m) {
    final weight   = (m['estimated_weight_g'] as num?)?.round() ?? 100;
    final cal100   = (m['calories_per_100g']  as num?)?.round() ?? 0;
    final prot100  = (m['protein_per_100g']   as num?)?.toDouble() ?? 0.0;
    final carb100  = (m['carbs_per_100g']     as num?)?.toDouble() ?? 0.0;
    final fat100   = (m['fat_per_100g']       as num?)?.toDouble() ?? 0.0;

    // Clamp values to physiologically plausible ranges
    final safeWeight  = weight.clamp(5, 2000);
    final safeCal     = cal100.clamp(0, 900);
    final safeProt    = prot100.clamp(0.0, 100.0);
    final safeCarb    = carb100.clamp(0.0, 100.0);
    final safeFat     = fat100.clamp(0.0, 100.0);

    // If macros imply significantly different calories, trust the macro-derived value
    final macroCal = (safeProt * 4 + safeCarb * 4 + safeFat * 9).round();
    final resolvedCal = (safeCal > 0 && macroCal > 0)
        ? ((safeCal - macroCal).abs() / macroCal > 0.25 ? macroCal : safeCal)
        : (safeCal > 0 ? safeCal : macroCal);

    return VisionFoodItem(
      name:             (m['name'] as String?)?.trim().isNotEmpty == true
                            ? m['name'] as String
                            : 'Alimento',
      estimatedWeightG: safeWeight,
      caloriesPer100g:  resolvedCal,
      proteinPer100g:   safeProt,
      carbsPer100g:     safeCarb,
      fatPer100g:       safeFat,
    );
  }
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

  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Modelos Groq con soporte de visión (en orden de preferencia)
  static const _groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static const _prompt = '''
Eres un nutricionista experto analizando una foto de comida. Identifica CADA alimento visible y estima su valor nutricional con precisión.

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

REGLAS CRÍTICAS:
1. estimated_weight_g: peso de ESA PORCIÓN visible. Guía de porciones típicas:
   - Un filete/pechuga individual: 120-200g
   - Una taza de arroz/pasta cocida: 150-200g
   - Un huevo entero: 50-60g
   - Una arepa mediana: 80-120g
   - Un vaso de jugo/leche: 200-250g
   - Una papa mediana: 130-180g

2. calories_per_100g: usa valores de referencia reales por 100g:
   - Pechuga de pollo a la plancha: ~165 kcal
   - Arroz blanco cocido: ~130 kcal
   - Carne de res magra: ~170-200 kcal
   - Huevo entero: ~155 kcal
   - Aguacate: ~160 kcal
   - Arepa de maíz: ~175-200 kcal
   - Papa cocida: ~87 kcal
   - Frijoles/lentejas cocidos: ~120-130 kcal
   - Pan blanco: ~265 kcal
   - Aceite/mantequilla: ~700-900 kcal
   - Frutas frescas: ~40-80 kcal
   - Verduras crudas: ~15-40 kcal

3. COHERENCIA DE MACROS (OBLIGATORIO): Las calorías deben ser coherentes con los macros.
   Verifica: (protein_per_100g × 4) + (carbs_per_100g × 4) + (fat_per_100g × 9) ≈ calories_per_100g (±15%)
   Si no cuadra, ajusta los macros antes de responder.

4. Nombres en español, específicos: "pechuga de pollo a la plancha" no solo "pollo".

5. NUNCA inventes alimentos que no se vean claramente en la foto.
''';

  // ── Punto de entrada público ───────────────────────────────────
  // Orden de prioridad:
  //   1. Claves Gemini del ApiKeyManager (con rotación automática)
  //   2. Clave Gemini hardcoded en AppConfig (fallback)
  //   3. Claves Groq del ApiKeyManager (con rotación automática)
  static Future<VisionAnalysisResult> analyzeFood(File imageFile) async {
    final manager = ApiKeyManager.instance;
    await manager.load();

    // Debug: mostrar estado de claves disponibles
    final gCount  = manager.geminiKeys.length;
    final grCount = manager.groqKeys.length;
    print('[FoodVision] Claves Gemini: $gCount, Groq: $grCount');
    print('[FoodVision] Clave Gemini disponible: ${manager.nextAvailable('gemini')?.label ?? 'ninguna'}');
    print('[FoodVision] Clave Groq disponible:   ${manager.nextAvailable('groq')?.label ?? 'ninguna'}');

    final triedKeys = <String>{};

    // ── 1. Intentar con claves Gemini del manager ──────────────
    while (true) {
      final managed = manager.nextAvailable('gemini');
      if (managed == null || triedKeys.contains(managed.key)) break;

      print('[FoodVision] Intentando Gemini (manager): ${managed.label}');
      triedKeys.add(managed.key);
      final result = await _requestGemini(imageFile, managed.key);

      if (result == null) {
        // 429: forzar rotación marcando la clave como agotada
        while (managed.isFresh) await manager.markError(managed);
        print('[FoodVision] Gemini 429 — rotando clave...');
        continue;
      }
      if (result.success) await manager.markUsed(managed);
      return result;
    }

    // ── 2. Fallback: clave Gemini hardcoded ────────────────────
    final fallback = AppConfig.geminiApiKey;
    if (fallback.isNotEmpty && !triedKeys.contains(fallback)) {
      print('[FoodVision] Intentando Gemini (hardcoded fallback)...');
      triedKeys.add(fallback);
      final result = await _requestGemini(imageFile, fallback);
      if (result != null) return result;
      print('[FoodVision] Gemini hardcoded 429 — probando Groq...');
    }

    // ── 3. Intentar con claves Groq del manager ────────────────
    while (true) {
      final managed = manager.nextAvailable('groq');
      if (managed == null || triedKeys.contains(managed.key)) break;

      print('[FoodVision] Intentando Groq: ${managed.label}');
      triedKeys.add(managed.key);
      final result = await _requestGroq(imageFile, managed.key);

      if (result == null) {
        // 429 en Groq: rotar
        while (managed.isFresh) await manager.markError(managed);
        print('[FoodVision] Groq 429 — rotando clave...');
        continue;
      }
      if (result.success) await manager.markUsed(managed);
      return result;
    }

    // ── 4. Fallback: clave Groq compartida (Supabase o AppConfig) ──
    await RemoteConfigService.instance.load();
    final groqFallback = RemoteConfigService.instance.groqApiKey.isNotEmpty
        ? RemoteConfigService.instance.groqApiKey
        : AppConfig.groqApiKey;
    if (groqFallback.isNotEmpty && !triedKeys.contains(groqFallback)) {
      print('[FoodVision] Intentando Groq (compartida)...');
      triedKeys.add(groqFallback);
      final result = await _requestGroq(imageFile, groqFallback);
      if (result != null) return result;
      print('[FoodVision] Groq compartida 429 — sin más claves.');
    }

    // ── Sin claves configuradas ────────────────────────────────
    if (triedKeys.isEmpty) {
      return const VisionAnalysisResult(
        foods: [],
        error: 'Agrega tu clave de Gemini o Groq en Ajustes → Claves API\n'
            'Obtén una gratis en: aistudio.google.com/apikey',
      );
    }

    // ── Todas las claves agotadas ──────────────────────────────
    return const VisionAnalysisResult(
      foods: [],
      error: 'Límite diario alcanzado en todas las claves.\n'
          'Intenta mañana o agrega más claves en Ajustes → Claves API.',
    );
  }

  // ── Petición a Google Gemini ───────────────────────────────────
  // Devuelve null si recibió 429 (rotar clave), resultado en los demás casos.
  static Future<VisionAnalysisResult?> _requestGemini(
      File imageFile, String apiKey) async {
    try {
      final bytes     = await imageFile.readAsBytes();
      final base64Img = base64Encode(bytes);
      final mimeType  = imageFile.path.toLowerCase().endsWith('.png')
          ? 'image/png' : 'image/jpeg';

      final url = Uri.parse('$_geminiUrl?key=$apiKey');
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'inline_data': {'mime_type': mimeType, 'data': base64Img}},
              {'text': _prompt},
            ]
          }
        ],
        'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 1024},
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('[FoodVision] Gemini status: ${response.statusCode}');

      if (response.statusCode == 400) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'Clave Gemini inválida. Verifica tu clave en Ajustes → Claves API.',
        );
      }
      if (response.statusCode == 403) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'Clave Gemini sin permisos. Activa Gemini API en Google AI Studio.',
        );
      }
      if (response.statusCode == 429) return null; // señal de límite → rotar
      if (response.statusCode != 200) {
        String msg = '';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          msg = err['error']?['message']?.toString() ?? response.body;
        } catch (_) {
          msg = response.body.length > 150 ? response.body.substring(0, 150) : response.body;
        }
        return VisionAnalysisResult(foods: [], error: 'Error Gemini ${response.statusCode}: $msg');
      }

      return _parseGeminiResponse(response.body);

    } on SocketException {
      return const VisionAnalysisResult(foods: [], error: 'Sin conexión a internet.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return const VisionAnalysisResult(foods: [], error: 'Tiempo de espera agotado. Intenta con otra foto.');
      }
      return VisionAnalysisResult(foods: [], error: 'Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // ── Petición a Groq Vision ─────────────────────────────────────
  // Devuelve null si recibió 429 (rotar clave), resultado en los demás casos.
  static Future<VisionAnalysisResult?> _requestGroq(
      File imageFile, String apiKey) async {
    try {
      final bytes     = await imageFile.readAsBytes();
      final base64Img = base64Encode(bytes);
      final mimeType  = imageFile.path.toLowerCase().endsWith('.png')
          ? 'image/png' : 'image/jpeg';

      final body = jsonEncode({
        'model': _groqModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$base64Img'},
              },
              {'type': 'text', 'text': _prompt},
            ],
          }
        ],
        'temperature': 0.2,
        'max_tokens': 1024,
      });

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('[FoodVision] Groq status: ${response.statusCode}');

      if (response.statusCode == 401) {
        return const VisionAnalysisResult(
          foods: [],
          error: 'Clave Groq inválida. Verifica tu clave en Ajustes → Claves API.',
        );
      }
      if (response.statusCode == 429) return null; // señal de límite → rotar
      if (response.statusCode != 200) {
        String msg = '';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          msg = err['error']?['message']?.toString() ?? response.body;
        } catch (_) {
          msg = response.body.length > 150 ? response.body.substring(0, 150) : response.body;
        }
        return VisionAnalysisResult(foods: [], error: 'Error Groq ${response.statusCode}: $msg');
      }

      return _parseGroqResponse(response.body);

    } on SocketException {
      return const VisionAnalysisResult(foods: [], error: 'Sin conexión a internet.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return const VisionAnalysisResult(foods: [], error: 'Tiempo de espera agotado. Intenta con otra foto.');
      }
      return VisionAnalysisResult(foods: [], error: 'Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // ── Parser de respuesta Gemini ─────────────────────────────────
  static VisionAnalysisResult _parseGeminiResponse(String rawBody) {
    try {
      final data  = jsonDecode(rawBody) as Map<String, dynamic>;
      final parts = data['candidates']?[0]?['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return const VisionAnalysisResult(
            foods: [], error: 'La IA no devolvió respuesta. Intenta de nuevo.');
      }
      final text = (parts[0]['text'] as String).trim();
      return _parseJsonResponse(text);
    } catch (_) {
      return const VisionAnalysisResult(
          foods: [], error: 'No se pudo interpretar la respuesta. Intenta de nuevo.');
    }
  }

  // ── Parser de respuesta Groq ───────────────────────────────────
  static VisionAnalysisResult _parseGroqResponse(String rawBody) {
    try {
      final data    = jsonDecode(rawBody) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        return const VisionAnalysisResult(
            foods: [], error: 'La IA no devolvió respuesta. Intenta de nuevo.');
      }
      return _parseJsonResponse(content);
    } catch (_) {
      return const VisionAnalysisResult(
          foods: [], error: 'No se pudo interpretar la respuesta. Intenta de nuevo.');
    }
  }

  // ── Parser común del JSON de alimentos ────────────────────────
  static VisionAnalysisResult _parseJsonResponse(String text) {
    try {
      var cleaned = text.trim()
          .replaceAll('```json', '').replaceAll('```', '').trim();

      // Extraer solo el JSON si viene con texto extra
      final start = cleaned.indexOf('{');
      final end   = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1 && start < end) {
        cleaned = cleaned.substring(start, end + 1);
      }

      final parsed    = jsonDecode(cleaned) as Map<String, dynamic>;
      final foodsList = (parsed['foods'] as List?) ?? [];

      final foods = foodsList
          .map((f) => VisionFoodItem.fromMap(Map<String, dynamic>.from(f as Map)))
          .where((f) => f.caloriesPer100g > 0)
          .toList();

      if (foods.isEmpty) {
        return const VisionAnalysisResult(
          foods: [], error: 'No se detectaron alimentos. Intenta con otra foto.',
        );
      }

      return VisionAnalysisResult(foods: foods, notes: parsed['notes'] as String?);
    } catch (_) {
      return const VisionAnalysisResult(
        foods: [], error: 'No se pudo interpretar la respuesta. Intenta de nuevo.',
      );
    }
  }
}
