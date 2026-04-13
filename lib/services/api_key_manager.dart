// lib/services/api_key_manager.dart
// ─────────────────────────────────────────────────────────────────
// Gestiona múltiples claves de API gratuitas con rotación automática.
//
// Estrategia:
//   • Cada clave de Gemini tiene 1,500 análisis/día GRATIS
//   • Con 3 claves = 4,500/día gratis
//   • Con 10 claves = 15,000/día gratis
//   • Cuando una clave falla por límite, pasa automáticamente
//     a la siguiente
//
// Cómo obtener más claves gratis:
//   1. Crea una cuenta de Google adicional (Gmail)
//   2. Ve a aistudio.google.com/apikey con esa cuenta
//   3. Genera la clave y agrégala aquí
//
// Groq también es gratis (proveedor diferente):
//   1. Ve a console.groq.com
//   2. Crea cuenta → API Keys → Create API Key
//   3. Gratis: ~7,000 tokens/minuto sin tarjeta
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kGeminiKeys = 'mv_gemini_keys';
const _kGroqKeys   = 'mv_groq_keys';
const _kUsageKey   = 'mv_key_usage';

// ── Modelo de una clave con su contador de uso ────────────────────
class ApiKey {
  final String key;
  final String label;    // nombre descriptivo (ej: "Cuenta principal")
  final String provider; // 'gemini' | 'groq'
  int    usageToday;
  int    errorCount;     // errores consecutivos (429 = límite alcanzado)
  String dateStr;        // YYYY-MM-DD del último uso

  ApiKey({
    required this.key,
    required this.label,
    required this.provider,
    this.usageToday  = 0,
    this.errorCount  = 0,
    String? dateStr,
  }) : dateStr = dateStr ?? _today();

  // Resetea el contador si es un día nuevo
  void resetIfNewDay() {
    if (dateStr != _today()) {
      usageToday  = 0;
      errorCount  = 0;
      dateStr     = _today();
    }
  }

  bool get isFresh => errorCount < 3;  // hasta 3 errores consecutivos

  int get dailyLimit => provider == 'gemini' ? 1500 : 9000;

  bool get hasQuota {
    resetIfNewDay();
    return usageToday < dailyLimit && isFresh;
  }

  // Porcentaje de cuota usada hoy
  double get usagePercent => (usageToday / dailyLimit).clamp(0.0, 1.0);

  String get usageDisplay => '$usageToday / $dailyLimit hoy';

  Map<String, dynamic> toMap() => {
    'key':        key,
    'label':      label,
    'provider':   provider,
    'usageToday': usageToday,
    'errorCount': errorCount,
    'dateStr':    dateStr,
  };

  factory ApiKey.fromMap(Map<String, dynamic> m) => ApiKey(
    key:        m['key']        ?? '',
    label:      m['label']      ?? 'Clave',
    provider:   m['provider']   ?? 'gemini',
    usageToday: m['usageToday'] ?? 0,
    errorCount: m['errorCount'] ?? 0,
    dateStr:    m['dateStr'],
  );

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }
}

// ─────────────────────────────────────────────────────────────────
// GESTOR SINGLETON
// ─────────────────────────────────────────────────────────────────
class ApiKeyManager {
  static final ApiKeyManager instance = ApiKeyManager._();
  ApiKeyManager._();

  List<ApiKey> _geminiKeys = [];
  List<ApiKey> _groqKeys   = [];
  bool _loaded = false;

  // ── Cargar claves desde SharedPreferences ─────────────────────
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final gRaw = prefs.getString(_kGeminiKeys);
    if (gRaw != null) {
      _geminiKeys = (jsonDecode(gRaw) as List)
          .map((m) => ApiKey.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    final grRaw = prefs.getString(_kGroqKeys);
    if (grRaw != null) {
      _groqKeys = (jsonDecode(grRaw) as List)
          .map((m) => ApiKey.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGeminiKeys,
        jsonEncode(_geminiKeys.map((k) => k.toMap()).toList()));
    await prefs.setString(_kGroqKeys,
        jsonEncode(_groqKeys.map((k) => k.toMap()).toList()));
  }

  // ── Agregar clave ─────────────────────────────────────────────
  Future<void> addKey(String key, String label, String provider) async {
    await load();
    final clean = key.trim();
    if (clean.isEmpty) return;

    final newKey = ApiKey(key: clean, label: label.isEmpty ? 'Clave ${_count(provider) + 1}' : label, provider: provider);

    if (provider == 'gemini') {
      // Evitar duplicados
      if (_geminiKeys.any((k) => k.key == clean)) return;
      _geminiKeys.add(newKey);
    } else {
      if (_groqKeys.any((k) => k.key == clean)) return;
      _groqKeys.add(newKey);
    }
    await _save();
  }

  // ── Eliminar clave ────────────────────────────────────────────
  Future<void> removeKey(String key, String provider) async {
    await load();
    if (provider == 'gemini') {
      _geminiKeys.removeWhere((k) => k.key == key);
    } else {
      _groqKeys.removeWhere((k) => k.key == key);
    }
    await _save();
  }

  // ── Obtener la siguiente clave disponible ─────────────────────
  ApiKey? nextAvailable(String provider) {
    final keys = provider == 'gemini' ? _geminiKeys : _groqKeys;
    for (final k in keys) {
      k.resetIfNewDay();
      if (k.hasQuota) return k;
    }
    return null;
  }

  // ── Marcar uso exitoso ────────────────────────────────────────
  Future<void> markUsed(ApiKey key) async {
    key.resetIfNewDay();
    key.usageToday++;
    key.errorCount = 0; // reset errores al tener éxito
    await _save();
  }

  // ── Marcar error (posible límite alcanzado) ───────────────────
  Future<void> markError(ApiKey key) async {
    key.errorCount++;
    await _save();
  }

  // ── Estado general ────────────────────────────────────────────
  List<ApiKey> get geminiKeys { for (var k in _geminiKeys) k.resetIfNewDay(); return List.unmodifiable(_geminiKeys); }
  List<ApiKey> get groqKeys   { for (var k in _groqKeys)   k.resetIfNewDay(); return List.unmodifiable(_groqKeys); }

  int _count(String provider) =>
      provider == 'gemini' ? _geminiKeys.length : _groqKeys.length;

  // Total de análisis disponibles hoy
  int get totalAvailableToday {
    int total = 0;
    for (final k in [..._geminiKeys, ..._groqKeys]) {
      k.resetIfNewDay();
      total += (k.dailyLimit - k.usageToday).clamp(0, k.dailyLimit);
    }
    return total;
  }

  bool get hasAnyKey =>
      _geminiKeys.isNotEmpty || _groqKeys.isNotEmpty;

  bool get hasAvailableKey =>
      nextAvailable('gemini') != null || nextAvailable('groq') != null;
}
