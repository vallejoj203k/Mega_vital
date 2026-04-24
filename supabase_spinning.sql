-- ═══════════════════════════════════════════════════════
-- MEGA VITAL – Spinning Module
-- Ejecutar en el SQL Editor de Supabase
-- ═══════════════════════════════════════════════════════

-- ── 1. INSTRUCTORES ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS spinning_instructors (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  specialty    TEXT NOT NULL,
  bio          TEXT,
  rating       DECIMAL(3,1) DEFAULT 5.0,
  total_classes INTEGER DEFAULT 0,
  color_hex    TEXT DEFAULT '#FF6B35',
  is_active    BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. CLASES (horario recurrente) ──────────────────────
CREATE TABLE IF NOT EXISTS spinning_classes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT NOT NULL,
  description      TEXT,
  instructor_id    UUID REFERENCES spinning_instructors(id) ON DELETE SET NULL,
  level            TEXT NOT NULL CHECK (level IN ('basico','intermedio','avanzado')),
  start_time       TIME NOT NULL,
  end_time         TIME NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  days             TEXT[] NOT NULL,   -- ['mon','tue','wed','thu','fri']
  calories_min     INTEGER DEFAULT 400,
  calories_max     INTEGER DEFAULT 600,
  total_spots      INTEGER DEFAULT 18,
  is_active        BOOLEAN DEFAULT TRUE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. SESIONES (instancia de clase en fecha específica) ─
CREATE TABLE IF NOT EXISTS spinning_sessions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id     UUID REFERENCES spinning_classes(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  is_cancelled BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (class_id, session_date)
);

-- ── 4. RESERVAS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS spinning_bookings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   UUID REFERENCES spinning_sessions(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  seat_number  INTEGER NOT NULL CHECK (seat_number BETWEEN 0 AND 17),
  is_cancelled BOOLEAN DEFAULT FALSE,
  booked_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (session_id, seat_number),
  UNIQUE (session_id, user_id)
);

-- ═══════════════════════════════════════════════════════
-- DATOS INICIALES
-- ═══════════════════════════════════════════════════════

-- Instructores
INSERT INTO spinning_instructors (id, name, specialty, bio, rating, total_classes, color_hex)
VALUES
  ('a1000000-0000-0000-0000-000000000001',
   'Verónica',
   'Certificada Indoor Cycling · Nutrición Deportiva',
   'Instructora certificada con más de 8 años de experiencia en ciclismo indoor y entrenamiento funcional. Sus clases combinan técnica, música y motivación para llevar tu rendimiento al siguiente nivel.',
   4.9, 520, '#FF6B35'),
  ('a1000000-0000-0000-0000-000000000002',
   'Julio',
   'Certificado SPINNING® · Entrenamiento de Potencia',
   'Ciclista de competencia y entrenador certificado SPINNING®. Especialista en entrenamiento de potencia y resistencia cardiovascular. Cada sesión es un reto diseñado para superar tus límites.',
   4.8, 480, '#4FC3F7')
ON CONFLICT DO NOTHING;

-- Clases (Lunes–Viernes, 3 horarios)
INSERT INTO spinning_classes (id, name, description, instructor_id, level, start_time, end_time, days, calories_min, calories_max, total_spots)
VALUES
  ('b1000000-0000-0000-0000-000000000001',
   'Morning Power',
   'Inicia tu día con una sesión de ciclismo indoor de alta energía. Técnica de pedaleo, intervalos y fuerza mental para comenzar con todo.',
   'a1000000-0000-0000-0000-000000000001',
   'intermedio',
   '05:00', '06:00',
   ARRAY['mon','tue','wed','thu','fri'],
   500, 650, 18),

  ('b1000000-0000-0000-0000-000000000002',
   'Evening Ride',
   'La clase perfecta después del trabajo. Ritmo progresivo, técnica depurada y ambiente motivador. Ideal para quienes están iniciando o buscan un entrenamiento consistente.',
   'a1000000-0000-0000-0000-000000000002',
   'basico',
   '18:00', '19:00',
   ARRAY['mon','tue','wed','thu','fri'],
   400, 520, 18),

  ('b1000000-0000-0000-0000-000000000003',
   'Night Burn',
   'La sesión más intensa del día. Entrenamiento de alta potencia con intervalos explosivos. Solo para quienes buscan romper sus propios records.',
   'a1000000-0000-0000-0000-000000000001',
   'avanzado',
   '19:00', '20:00',
   ARRAY['mon','tue','wed','thu','fri'],
   600, 800, 18)
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════
-- RLS (Row Level Security)
-- ═══════════════════════════════════════════════════════

ALTER TABLE spinning_instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE spinning_classes     ENABLE ROW LEVEL SECURITY;
ALTER TABLE spinning_sessions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE spinning_bookings    ENABLE ROW LEVEL SECURITY;

-- Instructores y clases: lectura pública
CREATE POLICY "instructors_read" ON spinning_instructors FOR SELECT USING (true);
CREATE POLICY "classes_read"     ON spinning_classes     FOR SELECT USING (true);
CREATE POLICY "sessions_read"    ON spinning_sessions    FOR SELECT USING (true);

-- Reservas: solo el propio usuario
CREATE POLICY "bookings_read"   ON spinning_bookings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bookings_insert" ON spinning_bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bookings_update" ON spinning_bookings FOR UPDATE USING (auth.uid() = user_id);

-- Sesiones: autenticados pueden crear
CREATE POLICY "sessions_insert" ON spinning_sessions FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Todos pueden ver asientos ocupados (sin datos personales)
CREATE POLICY "bookings_seats_public" ON spinning_bookings
  FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════
-- RENOVACIÓN AUTOMÁTICA DE CUPOS
-- Las sesiones son por fecha: cada día tiene su propia
-- sesión con sus propias reservas. Los cupos se vacían
-- automáticamente al crear una nueva sesión cada día.
--
-- OPCIONAL: limpieza de sesiones antiguas con pg_cron
-- Actívalo en Supabase → Database → Extensions → pg_cron
-- ═══════════════════════════════════════════════════════

-- Limpiar sesiones con más de 7 días de antigüedad (ejecuta cada día a las 3am)
-- SELECT cron.schedule(
--   'clean-old-spinning-sessions',
--   '0 3 * * *',
--   $$
--     DELETE FROM spinning_sessions
--     WHERE session_date < CURRENT_DATE - INTERVAL '7 days';
--   $$
-- );
