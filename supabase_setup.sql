-- ============================================
-- MEGA VITAL - Setup de base de datos Supabase
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Crear tabla (seguro si ya existe)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  uid             TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  email           TEXT NOT NULL,
  goal            TEXT NOT NULL DEFAULT 'Ganar músculo',
  weight          DOUBLE PRECISION NOT NULL DEFAULT 70.0,
  height          DOUBLE PRECISION NOT NULL DEFAULT 170.0,
  age             INTEGER NOT NULL DEFAULT 25,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  streak          INTEGER NOT NULL DEFAULT 0,
  total_workouts  INTEGER NOT NULL DEFAULT 0
);

-- 2. Activar Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 3. Eliminar políticas previas (evita errores de duplicado)
DROP POLICY IF EXISTS "Users can view own profile"   ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

-- 4. Crear políticas RLS (cada usuario solo accede a su propio perfil)
CREATE POLICY "Users can view own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid()::text = uid);

CREATE POLICY "Users can insert own profile"
  ON public.user_profiles FOR INSERT
  WITH CHECK (auth.uid()::text = uid);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid()::text = uid);
