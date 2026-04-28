// lib/core/config/supabase_config.dart
// ─────────────────────────────────────────────────────────────────
// Credenciales de Supabase.
//
// Pasos para obtener estos valores:
//   1. Ve a https://supabase.com y crea un proyecto
//   2. En el dashboard ve a Settings → API
//   3. Copia "Project URL" y "anon public" key
//   4. Pégalos abajo
// ─────────────────────────────────────────────────────────────────

class SupabaseConfig {
  static const String url = "https://ntxbjwmkxnewzzducfzz.supabase.co";
  // Ejemplo: 'https://xyzcompany.supabase.co'

  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50eGJqd21reG5ld3p6ZHVjZnp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0MDQ5ODYsImV4cCI6MjA5MTk4MDk4Nn0.8gc2LnlGwmEGnAIONeudlx1zRFiE-EdokEpvCg8nZzM';

  // Clave de servicio (service_role). Necesaria para crear usuarios sin correo.
  // Encuéntrala en: Supabase Dashboard → Settings → API → "service_role" key
  // IMPORTANTE: esta clave solo debe usarse en apps de administración interna.
  static const String serviceRoleKey = '';
}
