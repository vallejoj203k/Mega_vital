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
  image_url      TEXT,
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
DROP POLICY IF EXISTS "Users can update own posts"    ON public.community_posts;
DROP POLICY IF EXISTS "Users can delete own posts"    ON public.community_posts;

CREATE POLICY "Authenticated can view posts"
  ON public.community_posts FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own posts"
  ON public.community_posts FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own posts"
  ON public.community_posts FOR UPDATE
  USING (auth.uid()::text = user_id)
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


-- ─── 9. user_stories ────────────────────────────────────────────────────────
-- Historias de 24 horas. image_url apunta al bucket 'stories' de Supabase Storage.

CREATE TABLE IF NOT EXISTS public.user_stories (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    TEXT        NOT NULL,
  user_name  TEXT        NOT NULL,
  content    TEXT,
  image_url  TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL
);

-- Si la tabla ya existía sin image_url, añadirla (idempotente):
ALTER TABLE public.user_stories ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE public.user_stories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view stories" ON public.user_stories;
DROP POLICY IF EXISTS "Users can insert own stories"   ON public.user_stories;
DROP POLICY IF EXISTS "Users can update own stories"   ON public.user_stories;
DROP POLICY IF EXISTS "Users can delete own stories"   ON public.user_stories;

CREATE POLICY "Authenticated can view stories"
  ON public.user_stories FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own stories"
  ON public.user_stories FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own stories"
  ON public.user_stories FOR UPDATE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own stories"
  ON public.user_stories FOR DELETE
  USING (auth.uid()::text = user_id);


-- ─── 10. story_views ────────────────────────────────────────────────────────
-- Registra qué usuario vio cada historia (evita duplicados con UNIQUE).

CREATE TABLE IF NOT EXISTS public.story_views (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id   UUID NOT NULL REFERENCES public.user_stories(id) ON DELETE CASCADE,
  viewer_id  TEXT NOT NULL,
  UNIQUE(story_id, viewer_id)
);

ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view story_views" ON public.story_views;
DROP POLICY IF EXISTS "Users can insert own story_views"   ON public.story_views;

CREATE POLICY "Authenticated can view story_views"
  ON public.story_views FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own story_views"
  ON public.story_views FOR INSERT
  WITH CHECK (auth.uid()::text = viewer_id);


-- ─── 11. Storage: bucket 'stories' ──────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('stories', 'stories', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Limpiar políticas anteriores para evitar conflictos:
DROP POLICY IF EXISTS "Authenticated can view story images" ON storage.objects;
DROP POLICY IF EXISTS "Public read stories"                 ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own story images"   ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own stories"        ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own story images"   ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own stories"        ON storage.objects;
DROP POLICY IF EXISTS "stories_select"                      ON storage.objects;
DROP POLICY IF EXISTS "stories_insert"                      ON storage.objects;
DROP POLICY IF EXISTS "stories_delete"                      ON storage.objects;

-- Lectura pública (las imágenes se acceden por URL pública):
CREATE POLICY "stories_select"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'stories');

-- Solo el dueño puede subir a su carpeta ({uid}/...):
CREATE POLICY "stories_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'stories'
    AND (storage.foldername(name))[1] = auth.uid()::text);

-- Solo el dueño puede borrar sus propias imágenes:
CREATE POLICY "stories_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'stories'
    AND (storage.foldername(name))[1] = auth.uid()::text);


-- ─── 12. Limpieza automática de historias expiradas ─────────────────────────
-- Borra la imagen del Storage y luego el registro de la BD cada hora.

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.cleanup_expired_stories()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT id, user_id FROM public.user_stories WHERE expires_at < NOW()
  LOOP
    PERFORM net.http_delete(
      url     := 'https://ntxbjwmkxnewzzducfzz.supabase.co/storage/v1/object/stories/' || r.user_id || '/' || r.id,
      headers := jsonb_build_object('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50eGJqd21reG5ld3p6ZHVjZnp6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQwNDk4NiwiZXhwIjoyMDkxOTgwOTg2fQ.s9smfIGih_6ksWqQpIbkhDxo6KzSMwf0Aeoq9gXcZxc')
    );
    DELETE FROM public.user_stories WHERE id = r.id;
  END LOOP;
END;
$$;

SELECT cron.unschedule('cleanup-expired-stories');
SELECT cron.schedule('cleanup-expired-stories', '0 * * * *',
  'SELECT public.cleanup_expired_stories()');


-- ═══════════════════════════════════════════════════════════════════════════
-- SECCIÓN 2: Imágenes en posts · Seguir usuarios · Foto de perfil
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 13. Nuevas columnas (idempotente) ──────────────────────────────────────

-- Imagen adjunta en publicaciones
ALTER TABLE public.community_posts ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Foto de perfil del usuario
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Permitir que usuarios autenticados vean todos los perfiles (para mostrar
-- nombres y avatares en la comunidad)
DROP POLICY IF EXISTS "Users can view own profile"          ON public.user_profiles;
DROP POLICY IF EXISTS "Authenticated can view all profiles" ON public.user_profiles;

CREATE POLICY "Authenticated can view all profiles"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- ─── 14. user_follows ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_follows (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id  TEXT NOT NULL,
  following_id TEXT NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view follows" ON public.user_follows;
DROP POLICY IF EXISTS "Users can insert own follows"   ON public.user_follows;
DROP POLICY IF EXISTS "Users can delete own follows"   ON public.user_follows;

CREATE POLICY "Authenticated can view follows"
  ON public.user_follows FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own follows"
  ON public.user_follows FOR INSERT
  WITH CHECK (auth.uid()::text = follower_id);

CREATE POLICY "Users can delete own follows"
  ON public.user_follows FOR DELETE
  USING (auth.uid()::text = follower_id);


-- ─── 15. notifications ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    TEXT NOT NULL,
  type       TEXT NOT NULL,   -- 'new_post' | 'new_follower'
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  actor_id   TEXT,
  actor_name TEXT,
  post_id    UUID,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications"   ON public.notifications;
DROP POLICY IF EXISTS "Service can insert notifications"   ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid()::text = user_id);

-- Los triggers SECURITY DEFINER omiten RLS; esta política es para inserciones
-- directas desde el cliente si se necesitaran en el futuro.
CREATE POLICY "Service can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid()::text = user_id);


-- ─── 16. Trigger: notificar seguidores al publicar ──────────────────────────

CREATE OR REPLACE FUNCTION public.notify_followers_on_post()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.notifications
    (user_id, type, title, body, actor_id, actor_name, post_id)
  SELECT
    f.follower_id,
    'new_post',
    NEW.user_name || ' publicó algo nuevo',
    CASE
      WHEN LENGTH(NEW.content) > 80 THEN LEFT(NEW.content, 80) || '…'
      ELSE NEW.content
    END,
    NEW.user_id,
    NEW.user_name,
    NEW.id
  FROM public.user_follows f
  WHERE f.following_id = NEW.user_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_post_notify_followers ON public.community_posts;
CREATE TRIGGER on_post_notify_followers
  AFTER INSERT ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION public.notify_followers_on_post();


-- ─── 17. Trigger: notificar al seguido cuando alguien le sigue ──────────────

CREATE OR REPLACE FUNCTION public.notify_on_new_follower()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_name TEXT;
BEGIN
  SELECT name INTO v_name
  FROM public.user_profiles WHERE uid = NEW.follower_id;

  INSERT INTO public.notifications
    (user_id, type, title, body, actor_id, actor_name)
  VALUES (
    NEW.following_id,
    'new_follower',
    COALESCE(v_name, 'Alguien') || ' te empezó a seguir',
    'Ahora tienes un nuevo seguidor.',
    NEW.follower_id,
    v_name
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_follow_notify ON public.user_follows;
CREATE TRIGGER on_follow_notify
  AFTER INSERT ON public.user_follows
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_new_follower();


-- ─── 18. Storage: buckets 'post_images' y 'avatars' ─────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('post_images', 'post_images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Políticas para post_images
DROP POLICY IF EXISTS "post_images_select" ON storage.objects;
DROP POLICY IF EXISTS "post_images_insert" ON storage.objects;
DROP POLICY IF EXISTS "post_images_delete" ON storage.objects;

CREATE POLICY "post_images_select"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'post_images');

CREATE POLICY "post_images_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'post_images'
    AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "post_images_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'post_images'
    AND (storage.foldername(name))[1] = auth.uid()::text);

-- Políticas para avatars
DROP POLICY IF EXISTS "avatars_select" ON storage.objects;
DROP POLICY IF EXISTS "avatars_insert" ON storage.objects;
DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
DROP POLICY IF EXISTS "avatars_delete" ON storage.objects;

CREATE POLICY "avatars_select"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "avatars_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "avatars_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text);


-- ═══════════════════════════════════════════════════════════════════════════
-- SECCIÓN 3: Retos de ejercicio y records
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 19. challenges ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.challenges (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id       TEXT NOT NULL,
  creator_name     TEXT NOT NULL,
  title            TEXT NOT NULL,
  description      TEXT,
  exercise         TEXT NOT NULL,
  unit             TEXT NOT NULL DEFAULT 'kg',  -- 'kg' | 'reps' | 'seg' | 'km' | 'kg×reps'
  higher_is_better BOOLEAN NOT NULL DEFAULT true,
  deadline         DATE NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view challenges" ON public.challenges;
DROP POLICY IF EXISTS "Users can insert own challenges"   ON public.challenges;
DROP POLICY IF EXISTS "Users can delete own challenges"   ON public.challenges;

CREATE POLICY "Authenticated can view challenges"
  ON public.challenges FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own challenges"
  ON public.challenges FOR INSERT
  WITH CHECK (auth.uid()::text = creator_id);

CREATE POLICY "Users can delete own challenges"
  ON public.challenges FOR DELETE
  USING (auth.uid()::text = creator_id);


-- ─── 20. challenge_records ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.challenge_records (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id      TEXT NOT NULL,
  user_name    TEXT NOT NULL,
  value        NUMERIC NOT NULL,
  reps         INTEGER,               -- solo para unit = 'kg×reps'
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Si la tabla ya existía sin la columna reps, añadirla (idempotente):
ALTER TABLE public.challenge_records ADD COLUMN IF NOT EXISTS reps INTEGER;

ALTER TABLE public.challenge_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view records" ON public.challenge_records;
DROP POLICY IF EXISTS "Users can upsert own records"   ON public.challenge_records;
DROP POLICY IF EXISTS "Users can update own records"   ON public.challenge_records;
DROP POLICY IF EXISTS "Users can delete own records"   ON public.challenge_records;

CREATE POLICY "Authenticated can view records"
  ON public.challenge_records FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can upsert own records"
  ON public.challenge_records FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own records"
  ON public.challenge_records FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own records"
  ON public.challenge_records FOR DELETE
  USING (auth.uid()::text = user_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- SECCIÓN 4: Nutrición en la nube y rutinas públicas
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 21. nutrition_logs ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.nutrition_logs (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  date       DATE NOT NULL,
  meal_type  TEXT NOT NULL,
  name       TEXT NOT NULL,
  calories   INTEGER NOT NULL DEFAULT 0,
  protein    DOUBLE PRECISION NOT NULL DEFAULT 0,
  carbs      DOUBLE PRECISION NOT NULL DEFAULT 0,
  fat        DOUBLE PRECISION NOT NULL DEFAULT 0,
  portions   DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  logged_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.nutrition_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own nutrition"   ON public.nutrition_logs;
DROP POLICY IF EXISTS "Users can insert own nutrition" ON public.nutrition_logs;
DROP POLICY IF EXISTS "Users can update own nutrition" ON public.nutrition_logs;
DROP POLICY IF EXISTS "Users can delete own nutrition" ON public.nutrition_logs;

CREATE POLICY "Users can view own nutrition"
  ON public.nutrition_logs FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own nutrition"
  ON public.nutrition_logs FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own nutrition"
  ON public.nutrition_logs FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own nutrition"
  ON public.nutrition_logs FOR DELETE
  USING (auth.uid()::text = user_id);

-- Índice para consultas rápidas por usuario y fecha
CREATE INDEX IF NOT EXISTS nutrition_logs_user_date_idx
  ON public.nutrition_logs (user_id, date);


-- ─── 22. user_routines ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_routines (
  id           TEXT PRIMARY KEY,
  user_id      TEXT NOT NULL,
  name         TEXT NOT NULL,
  muscle_id    TEXT NOT NULL,
  muscle_name  TEXT NOT NULL,
  exercise_ids JSONB NOT NULL DEFAULT '[]',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_routines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view routines" ON public.user_routines;
DROP POLICY IF EXISTS "Users can insert own routines"   ON public.user_routines;
DROP POLICY IF EXISTS "Users can update own routines"   ON public.user_routines;
DROP POLICY IF EXISTS "Users can delete own routines"   ON public.user_routines;

CREATE POLICY "Authenticated can view routines"
  ON public.user_routines FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert own routines"
  ON public.user_routines FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own routines"
  ON public.user_routines FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own routines"
  ON public.user_routines FOR DELETE
  USING (auth.uid()::text = user_id);

-- Índice para consultas por usuario
CREATE INDEX IF NOT EXISTS user_routines_user_idx
  ON public.user_routines (user_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- SECCIÓN 5: Eliminación de cuenta (requerido por App Store Review Guideline 5.1.1)
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 23. delete_user_account ─────────────────────────────────────────────────
-- Elimina todos los datos del usuario autenticado y su cuenta de auth.
-- Se llama desde Flutter con: supabase.rpc('delete_user_account')
-- SECURITY DEFINER permite borrar de auth.users sin service_role key en el cliente.

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_uid_text text := auth.uid()::text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No hay sesión activa';
  END IF;

  -- Datos de nutrición y rutinas
  DELETE FROM public.nutrition_logs    WHERE user_id = v_uid_text;
  DELETE FROM public.user_routines     WHERE user_id = v_uid_text;

  -- Retos y records
  DELETE FROM public.challenge_records WHERE user_id = v_uid_text;
  DELETE FROM public.challenges        WHERE creator_id = v_uid_text;

  -- Historias
  DELETE FROM public.story_views       WHERE viewer_id = v_uid_text;
  DELETE FROM public.user_stories      WHERE user_id = v_uid_text;

  -- Comunidad
  DELETE FROM public.point_events      WHERE user_id = v_uid_text;
  DELETE FROM public.post_likes        WHERE user_id = v_uid_text;
  DELETE FROM public.post_comments     WHERE user_id = v_uid_text;
  DELETE FROM public.community_posts   WHERE user_id = v_uid_text;

  -- Notificaciones y seguidos
  DELETE FROM public.notifications     WHERE user_id = v_uid_text OR actor_id = v_uid_text;
  DELETE FROM public.user_follows      WHERE follower_id = v_uid_text OR following_id = v_uid_text;

  -- Perfil
  DELETE FROM public.user_profiles     WHERE uid = v_uid_text;

  -- Cuenta de autenticación (debe ser lo último)
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

-- ─── spinning_bookings ──────────────────────────────────────────────────────
-- Borrar versión anterior si existe (no hay datos reales aún)
DROP TABLE IF EXISTS public.spinning_bookings;

CREATE TABLE public.spinning_bookings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL,
  class_id    TEXT NOT NULL,
  seat_index  INTEGER NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT spinning_seat_unique UNIQUE (class_id, seat_index)
);

-- REPLICA IDENTITY FULL es necesario para que los eventos DELETE
-- de Realtime incluyan los datos del registro eliminado.
ALTER TABLE public.spinning_bookings REPLICA IDENTITY FULL;

ALTER TABLE public.spinning_bookings ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede ver todos los asientos ocupados
CREATE POLICY "spinning_select" ON public.spinning_bookings
  FOR SELECT TO authenticated USING (true);

-- Solo puedes insertar reservas propias
CREATE POLICY "spinning_insert" ON public.spinning_bookings
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Solo puedes cancelar tus propias reservas
CREATE POLICY "spinning_delete" ON public.spinning_bookings
  FOR DELETE TO authenticated USING (auth.uid() = user_id);
