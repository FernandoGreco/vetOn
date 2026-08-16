-- ============================================================
--  VetConnect — Row Level Security DEFINITIVO
--  Colunas verificadas com o banco real
--  Execute no Supabase > SQL Editor
-- ============================================================

-- ── HELPERS (recriar para garantir) ──
CREATE OR REPLACE FUNCTION get_id_usuario()
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT id_usuario FROM tb_usuario
  WHERE ds_email_usuario = (SELECT email FROM auth.users WHERE id = auth.uid())
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM tb_usuario
    WHERE ds_email_usuario = (SELECT email FROM auth.users WHERE id = auth.uid())
    AND id_tipo_usuario = 1
  );
$$;

CREATE OR REPLACE FUNCTION get_id_prestador()
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT p.id_prestador FROM tb_prestador p
  JOIN tb_usuario u ON u.id_usuario = p.id_usuario
  WHERE u.ds_email_usuario = (SELECT email FROM auth.users WHERE id = auth.uid())
  LIMIT 1;
$$;

-- ── HABILITAR RLS ──
ALTER TABLE tb_usuario              ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_pet                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_agendamento          ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_avaliacao            ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_prestador            ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_prestador_servico    ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_contato_usuario      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_conversa             ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_mensagem             ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_bloqueio_agenda      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_aceite_termo         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_denuncia             ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_comissionamento      ENABLE ROW LEVEL SECURITY;
-- Públicas
ALTER TABLE tb_tipo_usuario         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_servico_catalogo     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_conselho             ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_servico_conselho     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_configuracao         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_cupom                ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_categoria_avaliacao  ENABLE ROW LEVEL SECURITY;

-- ════════════════════════════════════════
-- TABELAS PÚBLICAS
-- ════════════════════════════════════════
CREATE POLICY "tipos_pub"      ON tb_tipo_usuario        FOR SELECT USING (true);
CREATE POLICY "catalogo_pub"   ON tb_servico_catalogo    FOR SELECT USING (true);
CREATE POLICY "conselho_pub"   ON tb_conselho            FOR SELECT USING (true);
CREATE POLICY "svc_cons_pub"   ON tb_servico_conselho    FOR SELECT USING (true);
CREATE POLICY "cat_aval_pub"   ON tb_categoria_avaliacao FOR SELECT USING (true);
CREATE POLICY "cupom_pub"      ON tb_cupom               FOR SELECT USING (fl_ativo = true);
-- Configurações: ADM escreve, todos leem
CREATE POLICY "config_select"  ON tb_configuracao FOR SELECT USING (true);
CREATE POLICY "config_update"  ON tb_configuracao FOR UPDATE USING (is_admin());
CREATE POLICY "config_insert"  ON tb_configuracao FOR INSERT WITH CHECK (is_admin());

-- ════════════════════════════════════════
-- tb_usuario
-- ════════════════════════════════════════
CREATE POLICY "usr_select" ON tb_usuario FOR SELECT USING (
  ds_email_usuario = (SELECT email FROM auth.users WHERE id = auth.uid())
  OR is_admin()
);
CREATE POLICY "usr_insert" ON tb_usuario FOR INSERT WITH CHECK (
  ds_email_usuario = (SELECT email FROM auth.users WHERE id = auth.uid())
  OR is_admin()
);
CREATE POLICY "usr_update" ON tb_usuario FOR UPDATE USING (
  ds_email_usuario = (SELECT email FROM auth.users WHERE id = auth.uid())
  OR is_admin()
);

-- ════════════════════════════════════════
-- tb_pet  (id_usuario ✓)
-- ════════════════════════════════════════
CREATE POLICY "pet_sel" ON tb_pet FOR SELECT USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "pet_ins" ON tb_pet FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);
CREATE POLICY "pet_upd" ON tb_pet FOR UPDATE USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "pet_del" ON tb_pet FOR DELETE USING (
  id_usuario = get_id_usuario() OR is_admin()
);

-- ════════════════════════════════════════
-- tb_agendamento
-- Colunas reais: id_usuario, id_prestador_servico (sem id_prestador direto)
-- ════════════════════════════════════════
CREATE POLICY "ag_sel" ON tb_agendamento FOR SELECT USING (
  id_usuario = get_id_usuario()
  OR EXISTS (
    SELECT 1 FROM tb_prestador_servico ps
    WHERE ps.id_prestador_servico = tb_agendamento.id_prestador_servico
      AND ps.id_prestador = get_id_prestador()
  )
  OR is_admin()
);
CREATE POLICY "ag_ins" ON tb_agendamento FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);
CREATE POLICY "ag_upd" ON tb_agendamento FOR UPDATE USING (
  id_usuario = get_id_usuario()
  OR EXISTS (
    SELECT 1 FROM tb_prestador_servico ps
    WHERE ps.id_prestador_servico = tb_agendamento.id_prestador_servico
      AND ps.id_prestador = get_id_prestador()
  )
  OR is_admin()
);

-- ════════════════════════════════════════
-- tb_prestador  (id_usuario, fl_verificado_prestador ✓)
-- ════════════════════════════════════════
CREATE POLICY "prest_sel" ON tb_prestador FOR SELECT USING (
  fl_verificado_prestador = true
  OR id_usuario = get_id_usuario()
  OR is_admin()
);
CREATE POLICY "prest_ins" ON tb_prestador FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "prest_upd" ON tb_prestador FOR UPDATE USING (
  id_usuario = get_id_usuario() OR is_admin()
);

-- ════════════════════════════════════════
-- tb_prestador_servico  (id_prestador ✓, fl_ativo ✓)
-- ════════════════════════════════════════
CREATE POLICY "ps_sel" ON tb_prestador_servico FOR SELECT USING (
  fl_ativo = true OR id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "ps_ins" ON tb_prestador_servico FOR INSERT WITH CHECK (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "ps_upd" ON tb_prestador_servico FOR UPDATE USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "ps_del" ON tb_prestador_servico FOR DELETE USING (
  id_prestador = get_id_prestador() OR is_admin()
);

-- ════════════════════════════════════════
-- tb_avaliacao
-- Colunas: id_usuario_avaliador, id_prestador_avaliado, fl_visivel
-- ════════════════════════════════════════
CREATE POLICY "aval_sel" ON tb_avaliacao FOR SELECT USING (
  fl_visivel = true
  OR id_usuario_avaliador = get_id_usuario()
  OR id_prestador_avaliado = get_id_prestador()
  OR is_admin()
);
CREATE POLICY "aval_ins" ON tb_avaliacao FOR INSERT WITH CHECK (
  id_usuario_avaliador = get_id_usuario()
);
CREATE POLICY "aval_upd" ON tb_avaliacao FOR UPDATE USING (
  id_usuario_avaliador = get_id_usuario() OR is_admin()
);
CREATE POLICY "aval_del" ON tb_avaliacao FOR DELETE USING (is_admin());

-- ════════════════════════════════════════
-- tb_contato_usuario  (id_usuario ✓)
-- ════════════════════════════════════════
CREATE POLICY "ctto_sel" ON tb_contato_usuario FOR SELECT USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "ctto_ins" ON tb_contato_usuario FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);
CREATE POLICY "ctto_upd" ON tb_contato_usuario FOR UPDATE USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "ctto_del" ON tb_contato_usuario FOR DELETE USING (
  id_usuario = get_id_usuario() OR is_admin()
);

-- ════════════════════════════════════════
-- tb_conversa
-- Colunas: id_usuario_cliente, id_usuario_prestador (sem id_usuario_1/2)
-- ════════════════════════════════════════
CREATE POLICY "conv_sel" ON tb_conversa FOR SELECT USING (
  id_usuario_cliente    = get_id_usuario()
  OR id_usuario_prestador = get_id_usuario()
  OR is_admin()
);
CREATE POLICY "conv_ins" ON tb_conversa FOR INSERT WITH CHECK (
  id_usuario_cliente = get_id_usuario()
  OR id_usuario_prestador = get_id_usuario()
);

-- ════════════════════════════════════════
-- tb_mensagem  (verificar colunas abaixo)
-- ════════════════════════════════════════
CREATE POLICY "msg_sel" ON tb_mensagem FOR SELECT USING (
  id_usuario_remetente = get_id_usuario()
  OR EXISTS (
    SELECT 1 FROM tb_conversa c
    WHERE c.id_conversa = tb_mensagem.id_conversa
      AND (c.id_usuario_cliente = get_id_usuario()
           OR c.id_usuario_prestador = get_id_usuario())
  )
  OR is_admin()
);
CREATE POLICY "msg_ins" ON tb_mensagem FOR INSERT WITH CHECK (
  id_usuario_remetente = get_id_usuario()
);

-- ════════════════════════════════════════
-- tb_bloqueio_agenda  (id_prestador ✓)
-- ════════════════════════════════════════
CREATE POLICY "bloq_sel" ON tb_bloqueio_agenda FOR SELECT USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "bloq_ins" ON tb_bloqueio_agenda FOR INSERT WITH CHECK (
  id_prestador = get_id_prestador()
);
CREATE POLICY "bloq_upd" ON tb_bloqueio_agenda FOR UPDATE USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "bloq_del" ON tb_bloqueio_agenda FOR DELETE USING (
  id_prestador = get_id_prestador() OR is_admin()
);

-- ════════════════════════════════════════
-- tb_aceite_termo  (id_usuario ✓)
-- ════════════════════════════════════════
CREATE POLICY "aceite_sel" ON tb_aceite_termo FOR SELECT USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "aceite_ins" ON tb_aceite_termo FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);

-- ════════════════════════════════════════
-- tb_denuncia  (id_usuario_denunciante)
-- ════════════════════════════════════════
CREATE POLICY "den_sel" ON tb_denuncia FOR SELECT USING (
  id_usuario_denunciante = get_id_usuario() OR is_admin()
);
CREATE POLICY "den_ins" ON tb_denuncia FOR INSERT WITH CHECK (
  id_usuario_denunciante = get_id_usuario()
);
CREATE POLICY "den_upd" ON tb_denuncia FOR UPDATE USING (is_admin());

-- ════════════════════════════════════════
-- tb_comissionamento  (id_prestador ✓)
-- ════════════════════════════════════════
CREATE POLICY "com_sel" ON tb_comissionamento FOR SELECT USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "com_ins" ON tb_comissionamento FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "com_upd" ON tb_comissionamento FOR UPDATE USING (is_admin());

-- ════════════════════════════════════════
-- VERIFICAR RESULTADO
-- ════════════════════════════════════════
SELECT
  pt.tablename,
  pt.rowsecurity,
  COUNT(pp.policyname) AS nr_policies
FROM pg_tables pt
LEFT JOIN pg_policies pp ON pp.tablename = pt.tablename AND pp.schemaname = 'public'
WHERE pt.schemaname = 'public'
GROUP BY pt.tablename, pt.rowsecurity
ORDER BY pt.tablename;
