-- ============================================================
--  VetConnect — RLS Complemento DEFINITIVO
--  Todas as colunas verificadas com o banco real
-- ============================================================

-- ── HABILITAR RLS ──
ALTER TABLE tb_avaliacao_categoria     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_disponibilidade         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_dispositivo_usuario     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_endereco                ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_exame                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_foto                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_funcao                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_funcao_conselho         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_log_auditoria           ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_notificacao             ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_pagamento               ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_preferencia_notificacao ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_prestador_registro      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_repasse                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_resposta_avaliacao      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_solicitacao_servico     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_termo                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_tipo_notificacao        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tb_vacina                  ENABLE ROW LEVEL SECURITY;

-- ── TABELAS DE REFERÊNCIA (leitura pública) ──
CREATE POLICY "funcao_pub"        ON tb_funcao              FOR SELECT USING (true);
CREATE POLICY "funcao_cons_pub"   ON tb_funcao_conselho     FOR SELECT USING (true);
CREATE POLICY "tipo_notif_pub"    ON tb_tipo_notificacao    FOR SELECT USING (true);
CREATE POLICY "termo_pub"         ON tb_termo               FOR SELECT USING (true);
CREATE POLICY "cat_aval_pub"      ON tb_avaliacao_categoria FOR SELECT USING (true);

-- ── tb_endereco (id_usuario OU id_prestador) ──
CREATE POLICY "end_sel" ON tb_endereco FOR SELECT USING (
  id_usuario   = get_id_usuario()
  OR id_prestador = get_id_prestador()
  OR is_admin()
);
CREATE POLICY "end_ins" ON tb_endereco FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
  OR id_prestador = get_id_prestador()
);
CREATE POLICY "end_upd" ON tb_endereco FOR UPDATE USING (
  id_usuario   = get_id_usuario()
  OR id_prestador = get_id_prestador()
  OR is_admin()
);
CREATE POLICY "end_del" ON tb_endereco FOR DELETE USING (
  id_usuario   = get_id_usuario()
  OR id_prestador = get_id_prestador()
  OR is_admin()
);

-- ── tb_disponibilidade (id_prestador ✓) ──
CREATE POLICY "disp_sel" ON tb_disponibilidade FOR SELECT USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "disp_ins" ON tb_disponibilidade FOR INSERT WITH CHECK (
  id_prestador = get_id_prestador()
);
CREATE POLICY "disp_upd" ON tb_disponibilidade FOR UPDATE USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "disp_del" ON tb_disponibilidade FOR DELETE USING (
  id_prestador = get_id_prestador() OR is_admin()
);

-- ── tb_foto (id_usuario, id_pet) ──
CREATE POLICY "foto_sel" ON tb_foto FOR SELECT USING (
  id_usuario = get_id_usuario()
  OR EXISTS (
    SELECT 1 FROM tb_pet p
    WHERE p.id_pet = tb_foto.id_pet
      AND p.id_usuario = get_id_usuario()
  )
  OR is_admin()
);
CREATE POLICY "foto_ins" ON tb_foto FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);
CREATE POLICY "foto_del" ON tb_foto FOR DELETE USING (
  id_usuario = get_id_usuario() OR is_admin()
);

-- ── tb_vacina (via tb_pet → id_usuario) ──
CREATE POLICY "vac_sel" ON tb_vacina FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM tb_pet p
    WHERE p.id_pet = tb_vacina.id_pet
      AND p.id_usuario = get_id_usuario()
  )
  OR is_admin()
);
CREATE POLICY "vac_ins" ON tb_vacina FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM tb_pet p
    WHERE p.id_pet = tb_vacina.id_pet
      AND p.id_usuario = get_id_usuario()
  )
);
CREATE POLICY "vac_del" ON tb_vacina FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM tb_pet p
    WHERE p.id_pet = tb_vacina.id_pet
      AND p.id_usuario = get_id_usuario()
  )
  OR is_admin()
);

-- ── tb_exame (via tb_pet → id_usuario) ──
CREATE POLICY "exam_sel" ON tb_exame FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM tb_pet p
    WHERE p.id_pet = tb_exame.id_pet
      AND p.id_usuario = get_id_usuario()
  )
  OR is_admin()
);
CREATE POLICY "exam_ins" ON tb_exame FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM tb_pet p
    WHERE p.id_pet = tb_exame.id_pet
      AND p.id_usuario = get_id_usuario()
  )
);

-- ── tb_notificacao (id_usuario ✓) ──
CREATE POLICY "notif_sel" ON tb_notificacao FOR SELECT USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "notif_ins" ON tb_notificacao FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "notif_upd" ON tb_notificacao FOR UPDATE USING (
  id_usuario = get_id_usuario()
);

-- ── tb_preferencia_notificacao (id_usuario ✓) ──
CREATE POLICY "pref_sel" ON tb_preferencia_notificacao FOR SELECT USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "pref_ins" ON tb_preferencia_notificacao FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);
CREATE POLICY "pref_upd" ON tb_preferencia_notificacao FOR UPDATE USING (
  id_usuario = get_id_usuario()
);

-- ── tb_dispositivo_usuario (id_usuario) ──
CREATE POLICY "disp_usr_sel" ON tb_dispositivo_usuario FOR SELECT USING (
  id_usuario = get_id_usuario() OR is_admin()
);
CREATE POLICY "disp_usr_ins" ON tb_dispositivo_usuario FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);
CREATE POLICY "disp_usr_del" ON tb_dispositivo_usuario FOR DELETE USING (
  id_usuario = get_id_usuario() OR is_admin()
);

-- ── tb_prestador_registro (id_prestador ✓) ──
CREATE POLICY "preg_sel" ON tb_prestador_registro FOR SELECT USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "preg_ins" ON tb_prestador_registro FOR INSERT WITH CHECK (
  id_prestador = get_id_prestador()
);
CREATE POLICY "preg_upd" ON tb_prestador_registro FOR UPDATE USING (is_admin());

-- ── tb_pagamento (via tb_agendamento → id_usuario) ──
CREATE POLICY "pag_sel" ON tb_pagamento FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM tb_agendamento a
    WHERE a.id_agendamento = tb_pagamento.id_agendamento
      AND a.id_usuario = get_id_usuario()
  )
  OR is_admin()
);
CREATE POLICY "pag_ins" ON tb_pagamento FOR INSERT WITH CHECK (is_admin());

-- ── tb_repasse (id_prestador ✓) ──
CREATE POLICY "rep_sel" ON tb_repasse FOR SELECT USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "rep_ins" ON tb_repasse FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "rep_upd" ON tb_repasse FOR UPDATE USING (is_admin());

-- ── tb_resposta_avaliacao (id_usuario ✓) ──
CREATE POLICY "resp_sel" ON tb_resposta_avaliacao FOR SELECT USING (true);
CREATE POLICY "resp_ins" ON tb_resposta_avaliacao FOR INSERT WITH CHECK (
  id_usuario = get_id_usuario()
);
CREATE POLICY "resp_upd" ON tb_resposta_avaliacao FOR UPDATE USING (
  id_usuario = get_id_usuario() OR is_admin()
);

-- ── tb_solicitacao_servico (id_prestador ✓) ──
CREATE POLICY "solic_sel" ON tb_solicitacao_servico FOR SELECT USING (
  id_prestador = get_id_prestador() OR is_admin()
);
CREATE POLICY "solic_ins" ON tb_solicitacao_servico FOR INSERT WITH CHECK (
  id_prestador = get_id_prestador()
);
CREATE POLICY "solic_upd" ON tb_solicitacao_servico FOR UPDATE USING (is_admin());

-- ── tb_log_auditoria (somente ADM lê; qualquer sistema insere) ──
CREATE POLICY "log_sel" ON tb_log_auditoria FOR SELECT USING (is_admin());
CREATE POLICY "log_ins" ON tb_log_auditoria FOR INSERT WITH CHECK (true);

-- ── tb_aceite_termo (complemento UPDATE) ──
CREATE POLICY "aceite_upd" ON tb_aceite_termo FOR UPDATE USING (is_admin());

-- ════════════════════════════════════════
-- VERIFICAR RESULTADO FINAL
-- ════════════════════════════════════════
SELECT
  pt.tablename,
  pt.rowsecurity                          AS rls_ativo,
  COUNT(pp.policyname)                    AS nr_policies
FROM pg_tables pt
LEFT JOIN pg_policies pp
       ON pp.tablename   = pt.tablename
      AND pp.schemaname  = 'public'
WHERE pt.schemaname = 'public'
GROUP BY pt.tablename, pt.rowsecurity
ORDER BY pt.rowsecurity DESC, pt.tablename;
