-- ============================================================
--  VetConnect — Usuários de Teste (Corrigido com ds_senha_usuario)
-- ============================================================

-- ── 1. Tipos de usuário ──
INSERT INTO tb_tipo_usuario (id_tipo_usuario, nm_tipo_usuario) VALUES
  (1, 'Administrador'),
  (2, 'Tutor'),
  (3, 'Prestador')
ON CONFLICT (id_tipo_usuario) DO UPDATE 
  SET nm_tipo_usuario = EXCLUDED.nm_tipo_usuario;

-- ── 2. Administrador ──
INSERT INTO tb_usuario (nm_usuario, ds_email_usuario, ds_senha_usuario, id_tipo_usuario, fl_ativo_usuario)
VALUES ('Admin VetConnect', 'admin@vetconnect.com', 'senha123', 1, true)
ON CONFLICT (ds_email_usuario) DO NOTHING;

-- ── 3. Clientes (Tutores) ──
INSERT INTO tb_usuario (nm_usuario, ds_email_usuario, ds_senha_usuario, id_tipo_usuario, nr_cpf_cnpj_usuario, fl_ativo_usuario)
VALUES 
  ('Maria Silva',   'cliente1@vetconnect.com', 'senha123', 2, '12345678901', true),
  ('João Santos',   'cliente2@vetconnect.com', 'senha123', 2, '98765432100', true),
  ('Ana Oliveira',  'cliente3@vetconnect.com', 'senha123', 2, '45678901234', true)
ON CONFLICT (ds_email_usuario) DO NOTHING;

-- ── 4. Prestadores ──
INSERT INTO tb_usuario (nm_usuario, ds_email_usuario, ds_senha_usuario, id_tipo_usuario, nr_cpf_cnpj_usuario, fl_ativo_usuario)
VALUES 
  ('Dr. Carlos Silva',   'vet@vetconnect.com',     'senha123', 3, '11122233344', true),
  ('PetShop Alegria',    'tosador@vetconnect.com', 'senha123', 3, '22233344455', true),
  ('Rafael Adestrador',  'prest3@vetconnect.com',  'senha123', 3, '33344455566', true)
ON CONFLICT (ds_email_usuario) DO NOTHING;

-- ── 5. Registros de prestador ──
INSERT INTO tb_prestador (id_usuario, fl_verificado_prestador)
SELECT id_usuario, true 
FROM tb_usuario 
WHERE ds_email_usuario IN (
  'vet@vetconnect.com',
  'tosador@vetconnect.com',
  'prest3@vetconnect.com'
)
ON CONFLICT DO NOTHING;

-- ── Verificar resultado ──
SELECT 
  u.id_usuario,
  u.nm_usuario,
  u.ds_email_usuario,
  t.nm_tipo_usuario AS tipo,
  u.fl_ativo_usuario AS ativo
FROM tb_usuario u
JOIN tb_tipo_usuario t ON t.id_tipo_usuario = u.id_tipo_usuario
ORDER BY u.id_tipo_usuario, u.id_usuario;