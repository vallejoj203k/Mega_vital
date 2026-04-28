-- ============================================================
-- PREMIUM SYSTEM MIGRATION
-- Secciones premium: Nutrición y Comunidad
-- ============================================================

-- ── Tabla de códigos premium generados por el admin ──────────
CREATE TABLE IF NOT EXISTS premium_codes (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  code          TEXT        UNIQUE NOT NULL,
  type          TEXT        NOT NULL CHECK (type IN ('mensual', 'trimestral', 'anual')),
  duration_days INTEGER     NOT NULL,
  is_used       BOOLEAN     DEFAULT FALSE,
  used_by       UUID        REFERENCES auth.users(id),
  used_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tabla de suscripciones premium por usuario ───────────────
CREATE TABLE IF NOT EXISTS premium_subscriptions (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    UUID        REFERENCES auth.users(id) UNIQUE NOT NULL,
  code_id    UUID        REFERENCES premium_codes(id),
  type       TEXT        NOT NULL,
  starts_at  TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── RLS ──────────────────────────────────────────────────────
ALTER TABLE premium_codes          ENABLE ROW LEVEL SECURITY;
ALTER TABLE premium_subscriptions  ENABLE ROW LEVEL SECURITY;

-- Los usuarios solo pueden leer su propia suscripción
CREATE POLICY "users_read_own_subscription"
  ON premium_subscriptions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "users_insert_own_subscription"
  ON premium_subscriptions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_update_own_subscription"
  ON premium_subscriptions FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ── Función: generar código premium (solo admin) ──────────────
CREATE OR REPLACE FUNCTION generate_premium_code(admin_key TEXT, code_type TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_code      TEXT;
  duration_val  INTEGER;
BEGIN
  IF admin_key != 'cocodemegavital' THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  duration_val := CASE code_type
    WHEN 'mensual'     THEN 30
    WHEN 'trimestral'  THEN 90
    WHEN 'anual'       THEN 365
    ELSE NULL
  END;

  IF duration_val IS NULL THEN
    RAISE EXCEPTION 'Tipo de código inválido: %', code_type;
  END IF;

  -- Generar código único con formato MV-XXXX-XXXX
  LOOP
    new_code := 'MV-'
      || upper(substring(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4))
      || '-'
      || upper(substring(md5(random()::TEXT || clock_timestamp()::TEXT), 5, 4));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM premium_codes WHERE code = new_code);
  END LOOP;

  INSERT INTO premium_codes (code, type, duration_days)
  VALUES (new_code, code_type, duration_val);

  RETURN new_code;
END;
$$;

-- ── Función: canjear código premium ──────────────────────────
CREATE OR REPLACE FUNCTION redeem_premium_code(code_text TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  code_rec   RECORD;
  expires    TIMESTAMPTZ;
  current_sub RECORD;
BEGIN
  -- Buscar código disponible (case-insensitive)
  SELECT * INTO code_rec
  FROM premium_codes
  WHERE upper(code) = upper(code_text) AND is_used = FALSE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Código inválido o ya utilizado.'
    );
  END IF;

  expires := NOW() + (code_rec.duration_days || ' days')::INTERVAL;

  -- Ver si ya tiene suscripción
  SELECT * INTO current_sub
  FROM premium_subscriptions
  WHERE user_id = auth.uid();

  IF FOUND THEN
    -- Si la suscripción actual aún está vigente, extender desde la fecha de vencimiento
    IF current_sub.expires_at > NOW() THEN
      expires := current_sub.expires_at + (code_rec.duration_days || ' days')::INTERVAL;
    END IF;
    UPDATE premium_subscriptions
    SET expires_at = expires, type = code_rec.type
    WHERE user_id = auth.uid();
  ELSE
    INSERT INTO premium_subscriptions (user_id, code_id, type, expires_at)
    VALUES (auth.uid(), code_rec.id, code_rec.type, expires);
  END IF;

  -- Marcar código como usado
  UPDATE premium_codes
  SET is_used = TRUE, used_by = auth.uid(), used_at = NOW()
  WHERE id = code_rec.id;

  RETURN jsonb_build_object(
    'success',    true,
    'expires_at', expires,
    'type',       code_rec.type
  );
END;
$$;

-- ── Función: listar códigos generados (solo admin) ────────────
CREATE OR REPLACE FUNCTION list_premium_codes(admin_key TEXT)
RETURNS TABLE (
  id            UUID,
  code          TEXT,
  type          TEXT,
  duration_days INTEGER,
  is_used       BOOLEAN,
  used_by       UUID,
  used_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF admin_key != 'cocodemegavital' THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  RETURN QUERY
  SELECT pc.id, pc.code, pc.type, pc.duration_days,
         pc.is_used, pc.used_by, pc.used_at, pc.created_at
  FROM premium_codes pc
  ORDER BY pc.created_at DESC;
END;
$$;

-- ── Función: ver suscripción premium del usuario actual ───────
CREATE OR REPLACE FUNCTION get_my_premium_subscription()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sub_rec RECORD;
BEGIN
  SELECT * INTO sub_rec
  FROM premium_subscriptions
  WHERE user_id = auth.uid();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('found', false);
  END IF;

  RETURN jsonb_build_object(
    'found',      true,
    'type',       sub_rec.type,
    'expires_at', sub_rec.expires_at,
    'is_active',  sub_rec.expires_at > NOW()
  );
END;
$$;
