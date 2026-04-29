// lib/core/config/app_config.dart
// ─────────────────────────────────────────────────────────────────
// Configuración central de la app.
//
// ── ANTES DE PUBLICAR EN LA STORE ────────────────────────────────
// Solo necesitas cambiar DOS valores:
//
//  1. workerUrl  → la URL de tu Cloudflare Worker (ver instrucciones)
//  2. appToken   → un string secreto que defines tú (cualquiera)
//
// Con eso, TODOS tus usuarios tienen IA sin pagar nada extra.
//
// ── Guía de deploy del Worker (5 minutos) ────────────────────────
//  1. Ve a workers.cloudflare.com → Crear cuenta gratis
//  2. Dashboard → Workers & Pages → Create Worker
//  3. Pega el contenido de backend/worker.js → Deploy
//  4. Settings → Variables & Secrets → Add:
//       GEMINI_KEY = AIzaSy...(tu clave de aistudio.google.com)
//       APP_TOKEN  = (el mismo string que pones abajo en appToken)
//  5. Copia la URL del worker y pégala en workerUrl
//
// Plan gratuito Cloudflare: 100,000 requests/día → gratis para siempre.
// ─────────────────────────────────────────────────────────────────

// lib/core/config/app_config.dart
// ─────────────────────────────────────────────────────────────────
// Configuración central de la app.
//
// ── PARA ACTIVAR EL ANÁLISIS DE FOTOS CON IA ─────────────────────
// 1. Ve a aistudio.google.com/apikey
// 2. Inicia sesión con Gmail → "Create API Key"
// 3. Copia la clave (AIzaSy...) y pégala abajo
//
// Plan gratuito: 1,500 análisis/día. Sin tarjeta de crédito.
// ─────────────────────────────────────────────────────────────────

class AppConfig {
  AppConfig._();

  // ── PON AQUÍ TU CLAVE DE GEMINI ──────────────────────────────
  // Obtén la tuya gratis en: aistudio.google.com/apikey
  static const String geminiApiKey = 'AIzaSyB3roNzpuoQAhTU4BvWa74rMaxElMB1GLw';

  // ── Estado ────────────────────────────────────────────────────
  // Habilitado si hay clave hardcoded O si el usuario agregó claves propias
  static bool get visionEnabled {
    if (geminiApiKey.isNotEmpty) return true;
    // Import circular evitado: ApiKeyManager se consulta solo en runtime
    return false; // se comprueba también en FoodVisionService.analyzeFood()
  }

  static String get visionStatus =>
      visionEnabled ? 'Activo' : 'Agrega tu clave en Ajustes → Claves API';

  // ── WhatsApp del dueño del gimnasio ──────────────────────────
  // Formato internacional sin '+' ni espacios. Ej: 521XXXXXXXXXX (México)
  static const String ownerWhatsApp = '521XXXXXXXXXX';
}