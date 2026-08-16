-- ============================================================
--  VetConnect — Fix DEFINITIVO das funções helper
--  Usa auth.uid() diretamente sem acessar auth.users
-- ============================================================

-- ── Adicionar coluna auth_uid em tb_usuario para vincular Auth ──
-- Primeiro verificar se já existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'tb_usuario' AND column_name = 'auth_uid'
  ) THEN
    ALTER TABLE tb_usuario ADD COLUMN auth_uid UUID;
  END IF;
END $$;

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_usuario_auth_uid ON tb_usuario(auth_uid);

-- ── Funções helper sem depender de auth.users ──
CREATE OR REPLACE FUNCTION get_id_usuario()
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT id_usuario FROM tb_usuario
  WHERE auth_uid = auth.uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM tb_usuario
    WHERE auth_uid = auth.uid()
    AND id_tipo_usuario = 1
  );
$$;

CREATE OR REPLACE FUNCTION get_id_prestador()
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT p.id_prestador FROM tb_prestador p
  JOIN tb_usuario u ON u.id_usuario = p.id_usuario
  WHERE u.auth_uid = auth.uid()
  LIMIT 1;
$$;

-- ── Vincular usuários existentes ao auth.uid ──
-- Isso só funciona se o email no auth = ds_email_usuario
UPDATE tb_usuario u
SET auth_uid = au.id
FROM auth.users au
WHERE au.email = u.ds_email_usuario
AND u.auth_uid IS NULL;

-- ── Atualizar policy do tb_usuario para usar auth_uid ──
DROP POLICY IF EXISTS "usr_select" ON tb_usuario;
DROP POLICY IF EXISTS "usr_insert" ON tb_usuario;
DROP POLICY IF EXISTS "usr_update" ON tb_usuario;
DROP POLICY IF EXISTS "usuario_select" ON tb_usuario;
DROP POLICY IF EXISTS "usuario_insert" ON tb_usuario;
DROP POLICY IF EXISTS "usuario_update" ON tb_usuario;

CREATE POLICY "usr_select" ON tb_usuario FOR SELECT USING (
  auth_uid = auth.uid() OR is_admin()
);
CREATE POLICY "usr_insert" ON tb_usuario FOR INSERT WITH CHECK (
  auth_uid = auth.uid() OR is_admin() OR auth_uid IS NULL
);
CREATE POLICY "usr_update" ON tb_usuario FOR UPDATE USING (
  auth_uid = auth.uid() OR is_admin()
);

-- ── Verificar resultado ──
SELECT id_usuario, nm_usuario, ds_email_usuario, auth_uid,
       CASE WHEN auth_uid IS NOT NULL THEN 'VINCULADO' ELSE 'SEM VÍNCULO' END AS status
FROM tb_usuario
ORDER BY id_usuario;
