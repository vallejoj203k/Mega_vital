// lib/services/remote_config_service.dart
// ─────────────────────────────────────────────────────────────────
// Lee configuración compartida desde Supabase (tabla app_settings).
// Se usa para la clave Groq compartida sin exponerla en el repo público.
// Cachea el valor en memoria y en SharedPreferences para uso offline.
// ─────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoteConfigService {
  static final RemoteConfigService instance = RemoteConfigService._();
  RemoteConfigService._();

  final _db = Supabase.instance.client;

  static const _kGroqCacheKey = 'mv_remote_groq_key';

  String _groqKey = '';
  bool _loaded = false;

  String get groqApiKey => _groqKey;

  // Carga la config desde Supabase; si falla, usa el caché local.
  Future<void> load() async {
    // Primero el caché local (rápido y offline)
    if (!_loaded) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _groqKey = prefs.getString(_kGroqCacheKey) ?? '';
      } catch (_) {}
      _loaded = true;
    }

    // Luego intenta refrescar desde Supabase
    try {
      final row = await _db
          .from('app_settings')
          .select('value')
          .eq('key', 'groq_api_key')
          .maybeSingle();
      final value = row?['value'] as String?;
      if (value != null && value.isNotEmpty) {
        _groqKey = value;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kGroqCacheKey, value);
      }
    } catch (_) {
      // Sin conexión o tabla ausente: se mantiene el caché
    }
  }
}
