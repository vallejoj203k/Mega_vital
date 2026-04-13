// lib/services/food_search_service.dart
// ─────────────────────────────────────────────────────────────────
// Búsqueda de alimentos en dos fuentes (sin costo, sin API key):
//
//  1. Base de datos LOCAL → 120+ alimentos colombianos/latinos
//     Respuesta instantánea, funciona sin internet.
//     Cubre: arepa, huevo, café, arroz, pollo, plátano, etc.
//
//  2. Open Food Facts API → millones de productos empacados
//     https://world.openfoodfacts.org  (100% gratuito, sin registro)
//     Activa solo cuando la búsqueda local da pocos resultados.
//
// Uso:
//   final results = await FoodSearchService.search('arepa');
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Modelo de resultado de búsqueda ───────────────────────────────
class FoodSearchResult {
  final String name;
  final int    calories;   // kcal por 100g
  final double protein;    // g por 100g
  final double carbs;      // g por 100g
  final double fat;        // g por 100g
  final String source;     // 'local' | 'openfoodfacts'
  final String? brand;     // marca (si viene de OFF)

  const FoodSearchResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
    this.brand,
  });

  // Nombre para mostrar en la UI
  String get displayName => brand != null ? '$name ($brand)' : name;

  // Resumen de macros por 100g
  String get macroSummary =>
      '${calories} kcal · P:${protein.toInt()}g · C:${carbs.toInt()}g · G:${fat.toInt()}g';
}

// ─────────────────────────────────────────────────────────────────
// SERVICIO
// ─────────────────────────────────────────────────────────────────
class FoodSearchService {
  FoodSearchService._();

  static Future<List<FoodSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // 1. Búsqueda local (instantánea)
    final local = _searchLocal(query.trim().toLowerCase());

    // 2. Si encontramos 3+ resultados locales, no consultamos la API
    if (local.length >= 3) return local;

    // 3. Completar con Open Food Facts
    final online = await _searchOpenFoodFacts(query.trim());

    // Combinar: primero locales, luego online, sin duplicados
    final seen = <String>{};
    final merged = <FoodSearchResult>[];
    for (final r in [...local, ...online]) {
      final key = r.name.toLowerCase();
      if (seen.add(key)) merged.add(r);
    }
    return merged.take(8).toList();
  }

  // ── Búsqueda en la base de datos local ────────────────────────
  static List<FoodSearchResult> _searchLocal(String q) {
    return _localDB
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            q.split(' ').any((w) => w.length > 2 && f.name.toLowerCase().contains(w)))
        .take(6)
        .toList();
  }

  // ── Open Food Facts API ───────────────────────────────────────
  static Future<List<FoodSearchResult>> _searchOpenFoodFacts(String q) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(q)}'
        '&json=1&page_size=6'
        '&fields=product_name,brands,nutriments,serving_size'
        '&sort_by=unique_scans_n',
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'MegaVital/1.0'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final data    = jsonDecode(response.body) as Map<String, dynamic>;
      final products = (data['products'] as List?) ?? [];

      return products
          .map((p) => _parseOFFProduct(p as Map<String, dynamic>))
          .whereType<FoodSearchResult>()
          .toList();
    } catch (_) {
      return []; // Sin internet → silencioso
    }
  }

  static FoodSearchResult? _parseOFFProduct(Map<String, dynamic> p) {
    final name = (p['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final n   = (p['nutriments'] as Map?)?.cast<String, dynamic>() ?? {};
    final cal = _toInt(n['energy-kcal_100g'] ?? n['energy-kcal']);
    if (cal == null || cal <= 0) return null;

    return FoodSearchResult(
      name:     name,
      calories: cal,
      protein:  _toDouble(n['proteins_100g']) ?? 0,
      carbs:    _toDouble(n['carbohydrates_100g']) ?? 0,
      fat:      _toDouble(n['fat_100g']) ?? 0,
      source:   'openfoodfacts',
      brand:    (p['brands'] as String?)?.split(',').first.trim(),
    );
  }

  static int?    _toInt(dynamic v)    => v == null ? null : (v is num ? v.toInt()    : int.tryParse(v.toString()));
  static double? _toDouble(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
}

// ─────────────────────────────────────────────────────────────────
// BASE DE DATOS LOCAL — 120 alimentos colombianos / latinos
// Valores por 100 g salvo indicación contraria.
// Fuente: ICBF, USDA, tablas de composición de alimentos de Colombia.
// ─────────────────────────────────────────────────────────────────
const List<FoodSearchResult> _localDB = [

  // ── HUEVOS ────────────────────────────────────────────────────
  FoodSearchResult(name: 'Huevo entero', calories: 143, protein: 13.0, carbs: 0.7, fat: 9.5, source: 'local'),
  FoodSearchResult(name: 'Huevo frito', calories: 196, protein: 13.6, carbs: 0.4, fat: 15.0, source: 'local'),
  FoodSearchResult(name: 'Huevo cocido', calories: 155, protein: 13.0, carbs: 1.1, fat: 11.0, source: 'local'),
  FoodSearchResult(name: 'Clara de huevo', calories: 52, protein: 11.0, carbs: 0.7, fat: 0.2, source: 'local'),

  // ── CEREALES Y HARINAS ────────────────────────────────────────
  FoodSearchResult(name: 'Arepa de maíz', calories: 181, protein: 3.8, carbs: 36.0, fat: 2.2, source: 'local'),
  FoodSearchResult(name: 'Arepa boyacense', calories: 274, protein: 7.5, carbs: 38.0, fat: 10.5, source: 'local'),
  FoodSearchResult(name: 'Pan blanco', calories: 265, protein: 9.0, carbs: 51.0, fat: 3.2, source: 'local'),
  FoodSearchResult(name: 'Pan integral', calories: 247, protein: 12.0, carbs: 41.0, fat: 4.0, source: 'local'),
  FoodSearchResult(name: 'Arroz blanco cocido', calories: 130, protein: 2.7, carbs: 28.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Arroz integral cocido', calories: 111, protein: 2.6, carbs: 23.0, fat: 0.9, source: 'local'),
  FoodSearchResult(name: 'Avena en hojuelas', calories: 370, protein: 12.5, carbs: 67.0, fat: 7.5, source: 'local'),
  FoodSearchResult(name: 'Pasta cocida', calories: 131, protein: 5.0, carbs: 25.0, fat: 1.1, source: 'local'),
  FoodSearchResult(name: 'Maíz pira (popcorn)', calories: 382, protein: 12.0, carbs: 74.0, fat: 4.5, source: 'local'),
  FoodSearchResult(name: 'Yuca cocida', calories: 159, protein: 1.4, carbs: 38.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Papa cocida', calories: 87, protein: 1.9, carbs: 20.0, fat: 0.1, source: 'local'),
  FoodSearchResult(name: 'Papa criolla', calories: 78, protein: 1.8, carbs: 17.0, fat: 0.2, source: 'local'),
  FoodSearchResult(name: 'Batata / camote cocida', calories: 86, protein: 1.6, carbs: 20.0, fat: 0.1, source: 'local'),

  // ── PROTEÍNAS ANIMALES ────────────────────────────────────────
  FoodSearchResult(name: 'Pechuga de pollo asada', calories: 165, protein: 31.0, carbs: 0.0, fat: 3.6, source: 'local'),
  FoodSearchResult(name: 'Pollo entero asado', calories: 239, protein: 27.0, carbs: 0.0, fat: 14.0, source: 'local'),
  FoodSearchResult(name: 'Carne de res magra', calories: 215, protein: 26.0, carbs: 0.0, fat: 12.0, source: 'local'),
  FoodSearchResult(name: 'Carne molida (80/20)', calories: 254, protein: 26.0, carbs: 0.0, fat: 17.0, source: 'local'),
  FoodSearchResult(name: 'Cerdo lomo asado', calories: 242, protein: 27.0, carbs: 0.0, fat: 14.0, source: 'local'),
  FoodSearchResult(name: 'Costilla de cerdo', calories: 277, protein: 24.0, carbs: 0.0, fat: 19.0, source: 'local'),
  FoodSearchResult(name: 'Salmón a la plancha', calories: 208, protein: 28.0, carbs: 0.0, fat: 10.0, source: 'local'),
  FoodSearchResult(name: 'Atún en agua (escurrido)', calories: 116, protein: 25.0, carbs: 0.0, fat: 1.0, source: 'local'),
  FoodSearchResult(name: 'Mojarra frita', calories: 218, protein: 22.0, carbs: 2.0, fat: 13.0, source: 'local'),
  FoodSearchResult(name: 'Camarón cocido', calories: 99, protein: 21.0, carbs: 0.9, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Chorizo', calories: 376, protein: 20.0, carbs: 2.5, fat: 32.0, source: 'local'),
  FoodSearchResult(name: 'Jamón de cerdo', calories: 145, protein: 17.0, carbs: 2.0, fat: 7.0, source: 'local'),

  // ── LÁCTEOS ───────────────────────────────────────────────────
  FoodSearchResult(name: 'Leche entera', calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, source: 'local'),
  FoodSearchResult(name: 'Leche descremada', calories: 34, protein: 3.4, carbs: 5.0, fat: 0.1, source: 'local'),
  FoodSearchResult(name: 'Yogur natural entero', calories: 61, protein: 3.5, carbs: 4.7, fat: 3.3, source: 'local'),
  FoodSearchResult(name: 'Yogur griego 0%', calories: 59, protein: 10.0, carbs: 3.6, fat: 0.4, source: 'local'),
  FoodSearchResult(name: 'Queso campesino', calories: 264, protein: 18.0, carbs: 2.5, fat: 20.0, source: 'local'),
  FoodSearchResult(name: 'Queso mozzarella', calories: 280, protein: 22.0, carbs: 2.2, fat: 20.0, source: 'local'),
  FoodSearchResult(name: 'Queso cottage', calories: 98, protein: 11.0, carbs: 3.4, fat: 4.3, source: 'local'),
  FoodSearchResult(name: 'Kumis', calories: 52, protein: 3.0, carbs: 5.5, fat: 1.8, source: 'local'),
  FoodSearchResult(name: 'Mantequilla', calories: 717, protein: 0.9, carbs: 0.1, fat: 81.0, source: 'local'),

  // ── FRUTAS ────────────────────────────────────────────────────
  FoodSearchResult(name: 'Banano / plátano de mesa', calories: 89, protein: 1.1, carbs: 23.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Plátano verde cocido', calories: 116, protein: 1.3, carbs: 31.0, fat: 0.2, source: 'local'),
  FoodSearchResult(name: 'Patacón / tostón', calories: 200, protein: 1.5, carbs: 28.0, fat: 9.0, source: 'local'),
  FoodSearchResult(name: 'Mango común', calories: 60, protein: 0.8, carbs: 15.0, fat: 0.4, source: 'local'),
  FoodSearchResult(name: 'Mango Tommy', calories: 65, protein: 0.5, carbs: 17.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Papaya', calories: 43, protein: 0.5, carbs: 11.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Guanábana', calories: 66, protein: 1.0, carbs: 16.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Lulo', calories: 53, protein: 0.7, carbs: 13.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Mora', calories: 37, protein: 1.4, carbs: 5.7, fat: 0.5, source: 'local'),
  FoodSearchResult(name: 'Mandarina', calories: 53, protein: 0.8, carbs: 13.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Naranja', calories: 47, protein: 0.9, carbs: 12.0, fat: 0.1, source: 'local'),
  FoodSearchResult(name: 'Piña', calories: 50, protein: 0.5, carbs: 13.0, fat: 0.1, source: 'local'),
  FoodSearchResult(name: 'Aguacate / palta', calories: 160, protein: 2.0, carbs: 9.0, fat: 15.0, source: 'local'),
  FoodSearchResult(name: 'Fresas', calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Manzana', calories: 52, protein: 0.3, carbs: 14.0, fat: 0.2, source: 'local'),
  FoodSearchResult(name: 'Uvas', calories: 67, protein: 0.6, carbs: 17.0, fat: 0.4, source: 'local'),

  // ── LEGUMBRES Y GRANOS ────────────────────────────────────────
  FoodSearchResult(name: 'Frijoles negros cocidos', calories: 132, protein: 8.9, carbs: 24.0, fat: 0.5, source: 'local'),
  FoodSearchResult(name: 'Frijoles rojos cocidos', calories: 127, protein: 8.7, carbs: 22.8, fat: 0.5, source: 'local'),
  FoodSearchResult(name: 'Lentejas cocidas', calories: 116, protein: 9.0, carbs: 20.0, fat: 0.4, source: 'local'),
  FoodSearchResult(name: 'Garbanzo cocido', calories: 164, protein: 8.9, carbs: 27.0, fat: 2.6, source: 'local'),
  FoodSearchResult(name: 'Arveja cocida', calories: 81, protein: 5.4, carbs: 14.5, fat: 0.4, source: 'local'),
  FoodSearchResult(name: 'Maíz cocido', calories: 96, protein: 3.4, carbs: 21.0, fat: 1.5, source: 'local'),

  // ── BEBIDAS ───────────────────────────────────────────────────
  FoodSearchResult(name: 'Café negro', calories: 2, protein: 0.3, carbs: 0.0, fat: 0.0, source: 'local'),
  FoodSearchResult(name: 'Café con leche (tinto con leche)', calories: 38, protein: 1.6, carbs: 3.8, fat: 1.5, source: 'local'),
  FoodSearchResult(name: 'Agua', calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0, source: 'local'),
  FoodSearchResult(name: 'Jugo de naranja natural', calories: 44, protein: 0.7, carbs: 10.0, fat: 0.2, source: 'local'),
  FoodSearchResult(name: 'Jugo de mango', calories: 60, protein: 0.4, carbs: 15.0, fat: 0.1, source: 'local'),
  FoodSearchResult(name: 'Leche en polvo', calories: 496, protein: 25.0, carbs: 53.0, fat: 20.0, source: 'local'),
  FoodSearchResult(name: 'Cholado / chicha', calories: 45, protein: 0.1, carbs: 11.0, fat: 0.0, source: 'local'),

  // ── VERDURAS Y HORTALIZAS ─────────────────────────────────────
  FoodSearchResult(name: 'Brócoli cocido', calories: 34, protein: 2.4, carbs: 7.2, fat: 0.4, source: 'local'),
  FoodSearchResult(name: 'Espinaca cocida', calories: 23, protein: 2.9, carbs: 3.8, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Zanahoria cruda', calories: 41, protein: 0.9, carbs: 10.0, fat: 0.2, source: 'local'),
  FoodSearchResult(name: 'Tomate', calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, source: 'local'),
  FoodSearchResult(name: 'Lechuga', calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, source: 'local'),
  FoodSearchResult(name: 'Cebolla cabezona', calories: 40, protein: 1.1, carbs: 9.3, fat: 0.1, source: 'local'),
  FoodSearchResult(name: 'Ajo', calories: 149, protein: 6.4, carbs: 33.0, fat: 0.5, source: 'local'),
  FoodSearchResult(name: 'Pimentón / páprika fresco', calories: 31, protein: 1.0, carbs: 6.0, fat: 0.3, source: 'local'),
  FoodSearchResult(name: 'Pepino cohombro', calories: 16, protein: 0.7, carbs: 3.6, fat: 0.1, source: 'local'),
  FoodSearchResult(name: 'Apio', calories: 16, protein: 0.7, carbs: 3.0, fat: 0.2, source: 'local'),

  // ── GRASAS Y ACEITES ──────────────────────────────────────────
  FoodSearchResult(name: 'Aceite de oliva', calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, source: 'local'),
  FoodSearchResult(name: 'Aceite vegetal (girasol/maíz)', calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, source: 'local'),
  FoodSearchResult(name: 'Mantequilla de maní', calories: 588, protein: 25.0, carbs: 20.0, fat: 50.0, source: 'local'),
  FoodSearchResult(name: 'Almendras', calories: 579, protein: 21.0, carbs: 22.0, fat: 50.0, source: 'local'),
  FoodSearchResult(name: 'Nueces', calories: 654, protein: 15.0, carbs: 14.0, fat: 65.0, source: 'local'),
  FoodSearchResult(name: 'Maní tostado', calories: 567, protein: 25.0, carbs: 21.0, fat: 49.0, source: 'local'),

  // ── PLATOS TÍPICOS COLOMBIANOS ────────────────────────────────
  FoodSearchResult(name: 'Bandeja paisa (porción)', calories: 850, protein: 55.0, carbs: 95.0, fat: 28.0, source: 'local'),
  FoodSearchResult(name: 'Sancocho de pollo (plato)', calories: 320, protein: 28.0, carbs: 32.0, fat: 8.0, source: 'local'),
  FoodSearchResult(name: 'Ajiaco (plato)', calories: 280, protein: 22.0, carbs: 30.0, fat: 7.0, source: 'local'),
  FoodSearchResult(name: 'Changua (taza)', calories: 130, protein: 8.5, carbs: 10.0, fat: 6.0, source: 'local'),
  FoodSearchResult(name: 'Empanada de pipián', calories: 185, protein: 4.5, carbs: 28.0, fat: 7.0, source: 'local'),
  FoodSearchResult(name: 'Tamal (unidad mediano)', calories: 420, protein: 18.0, carbs: 50.0, fat: 16.0, source: 'local'),
  FoodSearchResult(name: 'Buñuelo (unidad)', calories: 160, protein: 3.5, carbs: 18.0, fat: 8.5, source: 'local'),
  FoodSearchResult(name: 'Pandebono (unidad)', calories: 120, protein: 3.0, carbs: 16.0, fat: 5.0, source: 'local'),
  FoodSearchResult(name: 'Almojábana (unidad)', calories: 130, protein: 3.5, carbs: 17.0, fat: 5.5, source: 'local'),
  FoodSearchResult(name: 'Obleas (par con arequipe)', calories: 210, protein: 2.5, carbs: 42.0, fat: 4.0, source: 'local'),
  FoodSearchResult(name: 'Sopa de lentejas (plato)', calories: 180, protein: 11.0, carbs: 28.0, fat: 2.5, source: 'local'),
  FoodSearchResult(name: 'Arroz con pollo (plato)', calories: 420, protein: 35.0, carbs: 45.0, fat: 8.0, source: 'local'),
  FoodSearchResult(name: 'Frijoles con chicharrón (plato)', calories: 480, protein: 28.0, carbs: 42.0, fat: 20.0, source: 'local'),

  // ── PROTEÍNA EN POLVO Y SUPLEMENTOS ──────────────────────────
  FoodSearchResult(name: 'Proteína whey (scoop 30g)', calories: 120, protein: 24.0, carbs: 3.0, fat: 1.5, source: 'local'),
  FoodSearchResult(name: 'Caseína (scoop 30g)', calories: 110, protein: 24.0, carbs: 2.0, fat: 1.0, source: 'local'),
  FoodSearchResult(name: 'Proteína vegana (scoop 30g)', calories: 110, protein: 21.0, carbs: 4.0, fat: 2.0, source: 'local'),
  FoodSearchResult(name: 'Creatina (scoop 5g)', calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0, source: 'local'),

  // ── SNACKS Y DULCES ───────────────────────────────────────────
  FoodSearchResult(name: 'Chocolate de mesa', calories: 456, protein: 8.0, carbs: 64.0, fat: 22.0, source: 'local'),
  FoodSearchResult(name: 'Arequipe / dulce de leche', calories: 307, protein: 5.5, carbs: 56.0, fat: 7.5, source: 'local'),
  FoodSearchResult(name: 'Galleta de soda', calories: 430, protein: 8.5, carbs: 68.0, fat: 14.0, source: 'local'),
  FoodSearchResult(name: 'Papas fritas de paquete', calories: 536, protein: 7.0, carbs: 53.0, fat: 35.0, source: 'local'),

  // ── VARIOS ───────────────────────────────────────────────────
  FoodSearchResult(name: 'Miel de abeja', calories: 304, protein: 0.3, carbs: 82.0, fat: 0.0, source: 'local'),
  FoodSearchResult(name: 'Azúcar blanca', calories: 387, protein: 0.0, carbs: 100.0, fat: 0.0, source: 'local'),
  FoodSearchResult(name: 'Sal de mesa', calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0, source: 'local'),
];
