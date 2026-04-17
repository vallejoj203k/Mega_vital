-- ============================================
-- MEGA VITAL - Setup de base de datos Supabase
-- Ejecutar en: Supabase Dashboard > SQL Editor
--
-- Si las tablas de comunidad ya existen y quieres
-- arreglar el error de FK, ejecuta primero:
--
--   ALTER TABLE public.community_posts
--     DROP CONSTRAINT IF EXISTS community_posts_user_id_fkey;
--   ALTER TABLE public.post_likes
--     DROP CONSTRAINT IF EXISTS post_likes_user_id_fkey;
--   ALTER TABLE public.post_comments
--     DROP CONSTRAINT IF EXISTS post_comments_user_id_fkey;
--
-- ============================================

-- ─── 1. user_profiles ───────────────────────────────────────────────────────

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
  total_workouts  INTEGER NOT NULL DEFAULT 0,
  gender          TEXT NOT NULL DEFAULT 'mujer',
  referred_by     TEXT
);

-- Si la tabla ya existe, añadir columnas nuevas (idempotente)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS gender      TEXT NOT NULL DEFAULT 'mujer';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS referred_by TEXT;

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile"   ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

CREATE POLICY "Users can view own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid()::text = uid);

CREATE POLICY "Users can insert own profile"
  ON public.user_profiles FOR INSERT
  WITH CHECK (auth.uid()::text = uid);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid()::text = uid);


-- ─── 2. community_posts ─────────────────────────────────────────────────────
-- user_id es TEXT sin FK a user_profiles para evitar fallos cuando el perfil
-- aún no existe. La seguridad se garantiza exclusivamente por RLS.

CREATE TABLE IF NOT EXISTS public.community_posts (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        TEXT NOT NULL,
  user_name      TEXT NOT NULL,
  content        TEXT NOT NULL,
  achievement    TEXT,
  likes_count    INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Si la tabla ya existía con FK, eliminarla:
ALTER TABLE public.community_posts
  DROP CONSTRAINT IF EXISTS community_posts_user_id_fkey;

ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view posts"  ON public.community_posts;
DROP POLICY IF EXISTS "Users can insert own posts"    ON public.community_posts;
DROP POLICY IF EXISTS "Users can delete own posts"    ON public.community_posts;

CREATE POLICY "Authenticated can view posts"
  ON public.community_posts FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own posts"
  ON public.community_posts FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own posts"
  ON public.community_posts FOR DELETE
  USING (auth.uid()::text = user_id);


-- ─── 3. post_likes ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Si ya existía con FK a user_profiles, eliminarla:
ALTER TABLE public.post_likes
  DROP CONSTRAINT IF EXISTS post_likes_user_id_fkey;

ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view likes" ON public.post_likes;
DROP POLICY IF EXISTS "Users can insert own likes"   ON public.post_likes;
DROP POLICY IF EXISTS "Users can delete own likes"   ON public.post_likes;

CREATE POLICY "Authenticated can view likes"
  ON public.post_likes FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own likes"
  ON public.post_likes FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own likes"
  ON public.post_likes FOR DELETE
  USING (auth.uid()::text = user_id);


-- ─── 4. post_comments ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL,
  user_name  TEXT NOT NULL,
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Si ya existía con FK a user_profiles, eliminarla:
ALTER TABLE public.post_comments
  DROP CONSTRAINT IF EXISTS post_comments_user_id_fkey;

ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view comments" ON public.post_comments;
DROP POLICY IF EXISTS "Users can insert own comments"   ON public.post_comments;
DROP POLICY IF EXISTS "Users can delete own comments"   ON public.post_comments;

CREATE POLICY "Authenticated can view comments"
  ON public.post_comments FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own comments"
  ON public.post_comments FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own comments"
  ON public.post_comments FOR DELETE
  USING (auth.uid()::text = user_id);


-- ─── 5. Triggers para mantener contadores sincronizados ─────────────────────

CREATE OR REPLACE FUNCTION public.handle_like_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_posts
      SET likes_count = likes_count + 1
      WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.community_posts
      SET likes_count = GREATEST(likes_count - 1, 0)
      WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_like_change ON public.post_likes;
CREATE TRIGGER on_like_change
  AFTER INSERT OR DELETE ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.handle_like_change();

CREATE OR REPLACE FUNCTION public.handle_comment_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_posts
      SET comments_count = comments_count + 1
      WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.community_posts
      SET comments_count = GREATEST(comments_count - 1, 0)
      WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_comment_change ON public.post_comments;
CREATE TRIGGER on_comment_change
  AFTER INSERT OR DELETE ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_comment_change();


-- ─── 6. point_events — historial de puntos por usuario ──────────────────────
-- Fuente de verdad para ambos rankings (semanal e histórico total).
-- Los triggers de comunidad insertan aquí con SECURITY DEFINER.
-- Flutter inserta directamente para entrenamientos y logros.

CREATE TABLE IF NOT EXISTS public.point_events (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    TEXT NOT NULL,
  user_name  TEXT NOT NULL,
  amount     INTEGER NOT NULL,
  reason     TEXT NOT NULL, -- 'post' | 'like_received' | 'comment' | 'workout' | 'nutrition_goal' | 'streak' | 'achievement'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.point_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view point events" ON public.point_events;
DROP POLICY IF EXISTS "Users can insert own point events"   ON public.point_events;

CREATE POLICY "Authenticated can view point events"
  ON public.point_events FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own point events"
  ON public.point_events FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);


-- ─── 7. Triggers que otorgan puntos automáticamente ─────────────────────────

-- +20 pts al autor cuando publica
CREATE OR REPLACE FUNCTION public.award_post_points()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.point_events (user_id, user_name, amount, reason)
  VALUES (NEW.user_id, NEW.user_name, 20, 'post');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_post_points ON public.community_posts;
CREATE TRIGGER on_post_points
  AFTER INSERT ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION public.award_post_points();

-- +3 pts al AUTOR DEL POST cuando alguien da like (no al liker)
CREATE OR REPLACE FUNCTION public.award_like_points()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_author_id   TEXT;
  v_author_name TEXT;
BEGIN
  SELECT user_id, user_name
    INTO v_author_id, v_author_name
    FROM public.community_posts
   WHERE id = NEW.post_id;

  -- No se auto-otorgan puntos por dar like a tu propio post
  IF v_author_id IS NOT NULL AND v_author_id <> NEW.user_id THEN
    INSERT INTO public.point_events (user_id, user_name, amount, reason)
    VALUES (v_author_id, v_author_name, 3, 'like_received');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_like_points ON public.post_likes;
CREATE TRIGGER on_like_points
  AFTER INSERT ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.award_like_points();

-- +5 pts al comentador
CREATE OR REPLACE FUNCTION public.award_comment_points()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.point_events (user_id, user_name, amount, reason)
  VALUES (NEW.user_id, NEW.user_name, 5, 'comment');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_comment_points ON public.post_comments;
CREATE TRIGGER on_comment_points
  AFTER INSERT ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.award_comment_points();


-- ─── 8. Funciones de clasificación ──────────────────────────────────────────

-- Clasificación histórica total
CREATE OR REPLACE FUNCTION public.get_leaderboard_total()
RETURNS TABLE(uid TEXT, name TEXT, points BIGINT, rank BIGINT)
LANGUAGE SQL SECURITY DEFINER STABLE AS $$
  SELECT
    user_id                                                    AS uid,
    user_name                                                  AS name,
    SUM(amount)::BIGINT                                        AS points,
    ROW_NUMBER() OVER (ORDER BY SUM(amount) DESC)::BIGINT      AS rank
  FROM public.point_events
  GROUP BY user_id, user_name
  ORDER BY points DESC
  LIMIT 20;
$$;

-- Clasificación semanal (lunes → domingo en curso)
CREATE OR REPLACE FUNCTION public.get_leaderboard_weekly()
RETURNS TABLE(uid TEXT, name TEXT, points BIGINT, rank BIGINT)
LANGUAGE SQL SECURITY DEFINER STABLE AS $$
  SELECT
    user_id                                                    AS uid,
    user_name                                                  AS name,
    SUM(amount)::BIGINT                                        AS points,
    ROW_NUMBER() OVER (ORDER BY SUM(amount) DESC)::BIGINT      AS rank
  FROM public.point_events
  WHERE created_at >= date_trunc('week', NOW())
  GROUP BY user_id, user_name
  ORDER BY points DESC
  LIMIT 20;
$$;

-- Mantener compatibilidad con la función original (ahora usa point_events)
CREATE OR REPLACE FUNCTION public.get_leaderboard()
RETURNS TABLE(uid TEXT, name TEXT, points BIGINT, rank BIGINT)
LANGUAGE SQL SECURITY DEFINER STABLE AS $$
  SELECT * FROM public.get_leaderboard_total();
$$;
