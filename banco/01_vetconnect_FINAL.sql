-- ============================================================
--  VetConnect — SQL COMPLETO E DEFINITIVO
--  Execute este arquivo no Supabase > SQL Editor ou Docker
-- ============================================================

-- ── PARTE 1: SCHEMA BASE (36 tabelas) ──
-- ============================================================
--  VetConnect — Banco de Dados Completo
--  PostgreSQL
-- ============================================================

-- ============================================================
--  MÓDULO 1: USUÁRIOS
-- ============================================================

CREATE TABLE tb_tipo_usuario (
    id_tipo_usuario SERIAL PRIMARY KEY,
    nm_tipo_usuario VARCHAR(50) NOT NULL
);

INSERT INTO tb_tipo_usuario (nm_tipo_usuario) VALUES
    ('Administrador'),
    ('Cliente'),
    ('Prestador');

CREATE TABLE tb_usuario (
    id_usuario          SERIAL PRIMARY KEY,
    id_tipo_usuario     INTEGER NOT NULL REFERENCES tb_tipo_usuario(id_tipo_usuario),
    nm_usuario          VARCHAR(150) NOT NULL,
    nr_cpf_cnpj_usuario VARCHAR(18) NOT NULL UNIQUE,
    dt_nascimento_usuario DATE,
    ds_endereco_usuario TEXT,
    ds_email_usuario    VARCHAR(150) NOT NULL UNIQUE,
    ds_senha_usuario    VARCHAR(255) NOT NULL,
    dt_criacao_usuario  TIMESTAMP DEFAULT NOW(),
    fl_ativo_usuario    BOOLEAN DEFAULT TRUE
);

CREATE TABLE tb_contato_usuario (
    id_contato      SERIAL PRIMARY KEY,
    id_usuario      INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    ds_tipo         VARCHAR(20) NOT NULL,       -- 'CELULAR', 'WHATSAPP', 'RECADO'
    nr_contato      VARCHAR(20) NOT NULL,
    ds_descricao    VARCHAR(50),                -- 'Cônjuge', 'Trabalho', 'Pessoal'
    fl_principal    BOOLEAN DEFAULT FALSE,
    fl_whatsapp     BOOLEAN DEFAULT FALSE,
    dt_criacao      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tb_endereco (
    id_endereco     SERIAL PRIMARY KEY,
    id_usuario      INTEGER REFERENCES tb_usuario(id_usuario),
    id_prestador    INTEGER,                    -- FK adicionada após criar tb_prestador
    ds_cep          VARCHAR(9),
    ds_logradouro   VARCHAR(150),
    ds_numero       VARCHAR(10),
    ds_complemento  VARCHAR(100),
    ds_bairro       VARCHAR(100),
    ds_cidade       VARCHAR(100),
    ds_estado       CHAR(2),
    nr_latitude     NUMERIC(10,7),
    nr_longitude    NUMERIC(10,7),
    fl_principal    BOOLEAN DEFAULT FALSE
);

CREATE TABLE tb_foto (
    id_foto         SERIAL PRIMARY KEY,
    id_usuario      INTEGER REFERENCES tb_usuario(id_usuario),
    id_pet          INTEGER,                    -- FK adicionada após criar tb_pet
    ds_url_foto     VARCHAR(300) NOT NULL,
    fl_principal    BOOLEAN DEFAULT FALSE,
    dt_upload       TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_foto_referencia CHECK (
        (id_usuario IS NOT NULL)::INT +
        (id_pet IS NOT NULL)::INT = 1
    )
);

CREATE TABLE tb_dispositivo_usuario (
    id_dispositivo      SERIAL PRIMARY KEY,
    id_usuario          INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    ds_token_push       VARCHAR(300) NOT NULL,
    ds_plataforma       VARCHAR(10) NOT NULL,   -- 'IOS', 'ANDROID', 'WEB'
    dt_ultimo_acesso    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tb_termo (
    id_termo        SERIAL PRIMARY KEY,
    ds_tipo         VARCHAR(50) NOT NULL,       -- 'PRIVACIDADE', 'USO', 'PRESTADOR'
    ds_conteudo     TEXT NOT NULL,
    nr_versao       VARCHAR(10) NOT NULL,
    dt_vigencia     DATE NOT NULL,
    fl_ativo        BOOLEAN DEFAULT TRUE
);

CREATE TABLE tb_aceite_termo (
    id_aceite       SERIAL PRIMARY KEY,
    id_usuario      INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    id_termo        INTEGER NOT NULL REFERENCES tb_termo(id_termo),
    ds_ip           VARCHAR(45),
    dt_aceite       TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  MÓDULO 2: PRESTADOR
-- ============================================================

CREATE TABLE tb_funcao (
    id_funcao       SERIAL PRIMARY KEY,
    nm_funcao       VARCHAR(100) NOT NULL
);

INSERT INTO tb_funcao (nm_funcao) VALUES
    ('Veterinário'),
    ('Tosador'),
    ('Adestrador'),
    ('Pet Sitter'),
    ('Passeador');

CREATE TABLE tb_conselho (
    id_conselho     SERIAL PRIMARY KEY,
    nm_conselho     VARCHAR(100) NOT NULL,
    sg_conselho     VARCHAR(20) NOT NULL
);

INSERT INTO tb_conselho (nm_conselho, sg_conselho) VALUES
    ('Conselho Federal de Medicina Veterinária', 'CFMV'),
    ('Conselho Regional de Medicina Veterinária', 'CRMV');

CREATE TABLE tb_funcao_conselho (
    id_funcao_conselho  SERIAL PRIMARY KEY,
    id_funcao           INTEGER NOT NULL REFERENCES tb_funcao(id_funcao),
    id_conselho         INTEGER NOT NULL REFERENCES tb_conselho(id_conselho)
);

INSERT INTO tb_funcao_conselho (id_funcao, id_conselho) VALUES
    (1, 2); -- Veterinário exige CRMV

CREATE TABLE tb_prestador (
    id_prestador            SERIAL PRIMARY KEY,
    id_usuario              INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    id_funcao_conselho      INTEGER REFERENCES tb_funcao_conselho(id_funcao_conselho),
    nr_registro_conselho    VARCHAR(50),
    dt_validade_registro    DATE,
    ds_bio_prestador        TEXT,
    nr_avaliacao_media      NUMERIC(3,2) DEFAULT 0,
    fl_verificado_prestador BOOLEAN DEFAULT FALSE,
    nr_tempo_reserva_minutos INTEGER DEFAULT 30,
    ds_instagram            VARCHAR(100),
    ds_site                 VARCHAR(200),
    ds_sistema_gestao       VARCHAR(50),        -- 'BENSVET', 'GUIAVET', 'OUTRO'
    ds_token_integracao     VARCHAR(300),
    fl_integracao_ativa     BOOLEAN DEFAULT FALSE
);

-- FK de tb_endereco para tb_prestador
ALTER TABLE tb_endereco
    ADD CONSTRAINT fk_endereco_prestador
    FOREIGN KEY (id_prestador) REFERENCES tb_prestador(id_prestador);

CREATE TABLE tb_servico (
    id_servico              SERIAL PRIMARY KEY,
    id_prestador            INTEGER NOT NULL REFERENCES tb_prestador(id_prestador),
    nm_servico              VARCHAR(150) NOT NULL,
    ds_servico              TEXT,
    vl_servico              NUMERIC(10,2) NOT NULL,
    nr_duracao_minutos      INTEGER NOT NULL,
    fl_atende_domicilio     BOOLEAN DEFAULT FALSE,
    fl_atende_local         BOOLEAN DEFAULT FALSE,
    fl_teleconsulta         BOOLEAN DEFAULT FALSE,
    ds_plataforma_video     VARCHAR(50),        -- 'INTERNO', 'GOOGLE_MEET', 'ZOOM'
    nr_raio_atendimento_km  NUMERIC(5,1),
    vl_taxa_deslocamento    NUMERIC(10,2) DEFAULT 0,
    fl_ativo                BOOLEAN DEFAULT TRUE,
    dt_criacao              TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tb_disponibilidade (
    id_disponibilidade  SERIAL PRIMARY KEY,
    id_prestador        INTEGER NOT NULL REFERENCES tb_prestador(id_prestador),
    nr_dia_semana       SMALLINT NOT NULL,      -- 0=Dom, 1=Seg... 6=Sáb
    hr_inicio           TIME NOT NULL,
    hr_fim              TIME NOT NULL,
    fl_ativo            BOOLEAN DEFAULT TRUE
);

CREATE TABLE tb_bloqueio_agenda (
    id_bloqueio         SERIAL PRIMARY KEY,
    id_prestador        INTEGER NOT NULL REFERENCES tb_prestador(id_prestador),
    id_agendamento      INTEGER,                -- FK adicionada após criar tb_agendamento
    dt_inicio           TIMESTAMP NOT NULL,
    dt_fim              TIMESTAMP NOT NULL,
    ds_tipo             VARCHAR(20) DEFAULT 'MANUAL', -- 'AGENDAMENTO' ou 'MANUAL'
    ds_motivo           VARCHAR(150)
);

-- ============================================================
--  MÓDULO 3: PETS
-- ============================================================

CREATE TABLE tb_pet (
    id_pet              SERIAL PRIMARY KEY,
    id_usuario          INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    nm_pet              VARCHAR(100) NOT NULL,
    ds_especie_pet      VARCHAR(50),
    ds_raca_pet         VARCHAR(100),
    dt_nascimento_pet   DATE,
    ds_sexo_pet         CHAR(1),               -- 'M' ou 'F'
    nr_peso_pet         NUMERIC(5,2),
    ds_pelagem_pet      VARCHAR(100),
    fl_castrado_pet     BOOLEAN DEFAULT FALSE,
    nr_microchip_pet    VARCHAR(50) UNIQUE,
    nr_registro_pet     VARCHAR(50),
    ds_observacao_pet   TEXT,
    fl_ativo_pet        BOOLEAN DEFAULT TRUE,
    dt_criacao_pet      TIMESTAMP DEFAULT NOW()
);

-- FK de tb_foto para tb_pet
ALTER TABLE tb_foto
    ADD CONSTRAINT fk_foto_pet
    FOREIGN KEY (id_pet) REFERENCES tb_pet(id_pet);

CREATE TABLE tb_vacina (
    id_vacina           SERIAL PRIMARY KEY,
    id_pet              INTEGER NOT NULL REFERENCES tb_pet(id_pet),
    id_prestador        INTEGER REFERENCES tb_prestador(id_prestador),
    nm_vacina           VARCHAR(100) NOT NULL,
    dt_aplicacao        DATE NOT NULL,
    dt_proxima_dose     DATE,
    ds_lote_vacina      VARCHAR(50),
    ds_observacao       TEXT
);

CREATE TABLE tb_exame (
    id_exame            SERIAL PRIMARY KEY,
    id_pet              INTEGER NOT NULL REFERENCES tb_pet(id_pet),
    id_prestador        INTEGER REFERENCES tb_prestador(id_prestador),
    nm_exame            VARCHAR(150) NOT NULL,
    dt_exame            DATE NOT NULL,
    ds_resultado        TEXT,
    ds_url_arquivo      VARCHAR(300),
    ds_observacao       TEXT
);

-- ============================================================
--  MÓDULO 4: AGENDAMENTO
-- ============================================================

CREATE TABLE tb_cupom (
    id_cupom            SERIAL PRIMARY KEY,
    ds_codigo           VARCHAR(30) NOT NULL UNIQUE,
    ds_tipo             VARCHAR(20) NOT NULL,   -- 'PERCENTUAL', 'VALOR_FIXO'
    vl_desconto         NUMERIC(10,2) NOT NULL,
    dt_validade         TIMESTAMP,
    nr_limite_uso       INTEGER,
    nr_uso_atual        INTEGER DEFAULT 0,
    fl_ativo            BOOLEAN DEFAULT TRUE
);

CREATE TABLE tb_agendamento (
    id_agendamento              SERIAL PRIMARY KEY,
    id_servico                  INTEGER NOT NULL REFERENCES tb_servico(id_servico),
    id_usuario                  INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    id_pet                      INTEGER NOT NULL REFERENCES tb_pet(id_pet),
    id_endereco_atendimento     INTEGER REFERENCES tb_endereco(id_endereco),
    id_cupom                    INTEGER REFERENCES tb_cupom(id_cupom),
    dt_agendamento              TIMESTAMP NOT NULL,
    ds_tipo_atendimento         CHAR(1) NOT NULL, -- 'L' local, 'D' domicílio, 'T' teleconsulta
    vl_total                    NUMERIC(10,2) NOT NULL,
    vl_taxa_deslocamento        NUMERIC(10,2) DEFAULT 0,
    vl_desconto                 NUMERIC(10,2) DEFAULT 0,
    nr_duracao_minutos          INTEGER NOT NULL DEFAULT 60,
    ds_status                   VARCHAR(30) DEFAULT 'RESERVADO',
    dt_expiracao_reserva        TIMESTAMP,
    fl_reserva_expirada         BOOLEAN DEFAULT FALSE,
    ds_diagnostico              TEXT,
    ds_tratamento               TEXT,
    ds_prescricao               TEXT,
    ds_motivo_consulta          TEXT,
    ds_observacao               TEXT,
    dt_criacao                  TIMESTAMP DEFAULT NOW(),
    dt_atualizacao              TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_endereco_teleconsulta CHECK (
        (ds_tipo_atendimento = 'T' AND id_endereco_atendimento IS NULL)
        OR
        (ds_tipo_atendimento != 'T' AND id_endereco_atendimento IS NOT NULL)
    )
);

-- FK de tb_bloqueio_agenda para tb_agendamento
ALTER TABLE tb_bloqueio_agenda
    ADD CONSTRAINT fk_bloqueio_agendamento
    FOREIGN KEY (id_agendamento) REFERENCES tb_agendamento(id_agendamento);

CREATE TABLE tb_sessao_video (
    id_sessao           SERIAL PRIMARY KEY,
    id_agendamento      INTEGER NOT NULL REFERENCES tb_agendamento(id_agendamento),
    ds_link_sala        VARCHAR(300) NOT NULL,
    ds_status           VARCHAR(20) DEFAULT 'AGUARDANDO',
    dt_inicio_real      TIMESTAMP,
    dt_fim_real         TIMESTAMP,
    dt_criacao          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  MÓDULO 5: FINANCEIRO
-- ============================================================

CREATE TABLE tb_pagamento (
    id_pagamento        SERIAL PRIMARY KEY,
    id_agendamento      INTEGER NOT NULL REFERENCES tb_agendamento(id_agendamento),
    vl_pagamento        NUMERIC(10,2) NOT NULL,
    ds_forma_pagamento  VARCHAR(50),
    ds_status_pagamento VARCHAR(30) DEFAULT 'PENDENTE',
    ds_gateway          VARCHAR(50),
    ds_id_transacao     VARCHAR(150),
    dt_pagamento        TIMESTAMP,
    dt_criacao          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tb_comissionamento (
    id_comissionamento  SERIAL PRIMARY KEY,
    id_prestador        INTEGER REFERENCES tb_prestador(id_prestador),
    nr_percentual       NUMERIC(5,2) NOT NULL,
    vl_minimo           NUMERIC(10,2) DEFAULT 0,
    vl_maximo           NUMERIC(10,2),
    dt_inicio           DATE NOT NULL DEFAULT CURRENT_DATE,
    dt_fim              DATE,
    fl_ativo            BOOLEAN DEFAULT TRUE,
    dt_criacao          TIMESTAMP DEFAULT NOW()
);

INSERT INTO tb_comissionamento (nr_percentual, dt_inicio) VALUES (10.00, CURRENT_DATE);

CREATE TABLE tb_repasse (
    id_repasse              SERIAL PRIMARY KEY,
    id_prestador            INTEGER NOT NULL REFERENCES tb_prestador(id_prestador),
    id_pagamento            INTEGER NOT NULL REFERENCES tb_pagamento(id_pagamento),
    id_comissionamento      INTEGER REFERENCES tb_comissionamento(id_comissionamento),
    vl_bruto                NUMERIC(10,2) NOT NULL,
    vl_taxa_plataforma      NUMERIC(10,2) NOT NULL,
    nr_percentual_aplicado  NUMERIC(5,2) NOT NULL,
    vl_liquido              NUMERIC(10,2) NOT NULL,
    ds_status               VARCHAR(20) DEFAULT 'PENDENTE',
    dt_previsao_repasse     DATE,
    dt_repasse              TIMESTAMP
);

-- ============================================================
--  MÓDULO 6: AVALIAÇÃO
-- ============================================================

CREATE TABLE tb_categoria_avaliacao (
    id_categoria    SERIAL PRIMARY KEY,
    nm_categoria    VARCHAR(100) NOT NULL,
    ds_tipo         VARCHAR(20) NOT NULL
);

INSERT INTO tb_categoria_avaliacao (nm_categoria, ds_tipo) VALUES
    ('Pontualidade',    'PRESTADOR'),
    ('Atendimento',     'PRESTADOR'),
    ('Higiene e limpeza', 'PRESTADOR'),
    ('Comunicação',     'PRESTADOR'),
    ('Custo-benefício', 'PRESTADOR'),
    ('Comportamento',   'PET'),
    ('Cooperação',      'PET'),
    ('Agressividade',   'PET');

CREATE TABLE tb_avaliacao (
    id_avaliacao            SERIAL PRIMARY KEY,
    id_agendamento          INTEGER NOT NULL REFERENCES tb_agendamento(id_agendamento),
    id_usuario_avaliador    INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    id_prestador_avaliado   INTEGER REFERENCES tb_prestador(id_prestador),
    id_cliente_avaliado     INTEGER REFERENCES tb_usuario(id_usuario),
    id_pet_avaliado         INTEGER REFERENCES tb_pet(id_pet),
    ds_tipo                 VARCHAR(20) NOT NULL,
    nr_nota_geral           NUMERIC(3,2) NOT NULL,
    ds_comentario           TEXT,
    fl_visivel              BOOLEAN DEFAULT TRUE,
    dt_avaliacao            TIMESTAMP DEFAULT NOW(),
    dt_limite_avaliacao     TIMESTAMP NOT NULL,
    CONSTRAINT chk_apenas_um_avaliado CHECK (
        (
            (id_prestador_avaliado IS NOT NULL)::INT +
            (id_cliente_avaliado IS NOT NULL)::INT +
            (id_pet_avaliado IS NOT NULL)::INT
        ) = 1
    )
);

CREATE TABLE tb_avaliacao_categoria (
    id_avaliacao_categoria  SERIAL PRIMARY KEY,
    id_avaliacao            INTEGER NOT NULL REFERENCES tb_avaliacao(id_avaliacao),
    id_categoria            INTEGER NOT NULL REFERENCES tb_categoria_avaliacao(id_categoria),
    nr_nota                 SMALLINT NOT NULL CHECK (nr_nota BETWEEN 1 AND 5)
);

CREATE TABLE tb_resposta_avaliacao (
    id_resposta     SERIAL PRIMARY KEY,
    id_avaliacao    INTEGER NOT NULL REFERENCES tb_avaliacao(id_avaliacao),
    id_usuario      INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    ds_resposta     TEXT NOT NULL,
    dt_resposta     TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  MÓDULO 7: COMUNICAÇÃO
-- ============================================================

CREATE TABLE tb_conversa (
    id_conversa             SERIAL PRIMARY KEY,
    id_agendamento          INTEGER REFERENCES tb_agendamento(id_agendamento),
    id_usuario_cliente      INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    id_usuario_prestador    INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    dt_criacao              TIMESTAMP DEFAULT NOW(),
    dt_ultima_mensagem      TIMESTAMP
);

CREATE TABLE tb_mensagem (
    id_mensagem             SERIAL PRIMARY KEY,
    id_conversa             INTEGER NOT NULL REFERENCES tb_conversa(id_conversa),
    id_usuario_remetente    INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    ds_mensagem             TEXT,
    ds_url_anexo            VARCHAR(300),
    ds_tipo_anexo           VARCHAR(20),
    fl_lida                 BOOLEAN DEFAULT FALSE,
    dt_envio                TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tb_tipo_notificacao (
    id_tipo_notificacao SERIAL PRIMARY KEY,
    nm_tipo             VARCHAR(100) NOT NULL,
    ds_template         TEXT NOT NULL
);

INSERT INTO tb_tipo_notificacao (nm_tipo, ds_template) VALUES
    ('AGENDAMENTO_CRIADO',      'Seu agendamento foi criado e aguarda confirmação!'),
    ('AGENDAMENTO_CONFIRMADO',  'Seu agendamento com {prestador} foi confirmado!'),
    ('AGENDAMENTO_RECUSADO',    'Seu agendamento com {prestador} foi recusado.'),
    ('AGENDAMENTO_CANCELADO',   'O agendamento foi cancelado.'),
    ('RESERVA_EXPIRANDO',       'Sua reserva expira em 10 minutos!'),
    ('PAGAMENTO_APROVADO',      'Pagamento aprovado! Seu agendamento está confirmado.'),
    ('AVALIACAO_PENDENTE',      'Como foi seu atendimento? Avalie {prestador}!'),
    ('NOVA_MENSAGEM',           'Você tem uma nova mensagem de {remetente}.'),
    ('AGENDAMENTO_LEMBRETE',    'Lembrete: você tem um agendamento amanhã às {hora}.');

CREATE TABLE tb_template_mensagem (
    id_template             SERIAL PRIMARY KEY,
    id_tipo_notificacao     INTEGER NOT NULL REFERENCES tb_tipo_notificacao(id_tipo_notificacao),
    ds_canal                VARCHAR(20) NOT NULL,
    ds_template             TEXT NOT NULL,
    fl_aprovado             BOOLEAN DEFAULT FALSE,
    ds_nome_template_meta   VARCHAR(100),
    dt_criacao              TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tb_notificacao (
    id_notificacao          SERIAL PRIMARY KEY,
    id_usuario              INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    id_tipo_notificacao     INTEGER NOT NULL REFERENCES tb_tipo_notificacao(id_tipo_notificacao),
    ds_mensagem             TEXT NOT NULL,
    ds_canal                VARCHAR(20) NOT NULL,
    fl_lida                 BOOLEAN DEFAULT FALSE,
    dt_envio                TIMESTAMP DEFAULT NOW(),
    dt_leitura              TIMESTAMP,
    ds_resposta_gatilho     VARCHAR(10),
    ds_acao_executada       VARCHAR(50)
);

CREATE TABLE tb_preferencia_notificacao (
    id_preferencia          SERIAL PRIMARY KEY,
    id_usuario              INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    id_tipo_notificacao     INTEGER NOT NULL REFERENCES tb_tipo_notificacao(id_tipo_notificacao),
    fl_push                 BOOLEAN DEFAULT TRUE,
    fl_email                BOOLEAN DEFAULT TRUE,
    fl_sms                  BOOLEAN DEFAULT FALSE,
    fl_whatsapp             BOOLEAN DEFAULT TRUE
);

-- ============================================================
--  MÓDULO 8: ADMINISTRAÇÃO
-- ============================================================

CREATE TABLE tb_configuracao (
    id_configuracao SERIAL PRIMARY KEY,
    ds_chave        VARCHAR(100) NOT NULL UNIQUE,
    ds_valor        VARCHAR(300) NOT NULL,
    ds_descricao    TEXT,
    dt_atualizacao  TIMESTAMP DEFAULT NOW()
);

INSERT INTO tb_configuracao (ds_chave, ds_valor, ds_descricao) VALUES
    ('TEMPO_RESERVA_PADRAO_MINUTOS', '30',    'Tempo padrão de reserva de horário'),
    ('TAXA_COMISSAO_PADRAO',         '10.00', 'Percentual padrão de comissão da plataforma'),
    ('PRAZO_AVALIACAO_DIAS',         '7',     'Dias para avaliar após serviço concluído'),
    ('TAXA_TELECONSULTA',            '12.00', 'Percentual de comissão para teleconsultas');

CREATE TABLE tb_log_auditoria (
    id_log              SERIAL PRIMARY KEY,
    id_usuario          INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    ds_acao             VARCHAR(100) NOT NULL,
    ds_tabela           VARCHAR(50),
    id_registro         INTEGER,
    ds_valor_anterior   JSONB,
    ds_valor_novo       JSONB,
    ds_ip               VARCHAR(45),
    dt_acao             TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tb_denuncia (
    id_denuncia             SERIAL PRIMARY KEY,
    id_usuario_denunciante  INTEGER NOT NULL REFERENCES tb_usuario(id_usuario),
    ds_tipo                 VARCHAR(20) NOT NULL,
    id_referencia           INTEGER NOT NULL,
    ds_motivo               TEXT NOT NULL,
    ds_status               VARCHAR(20) DEFAULT 'PENDENTE',
    dt_criacao              TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  ÍNDICES RECOMENDADOS
-- ============================================================

CREATE INDEX idx_usuario_email       ON tb_usuario(ds_email_usuario);
CREATE INDEX idx_usuario_tipo        ON tb_usuario(id_tipo_usuario);
CREATE INDEX idx_pet_usuario         ON tb_pet(id_usuario);
CREATE INDEX idx_agendamento_usuario ON tb_agendamento(id_usuario);
CREATE INDEX idx_agendamento_status  ON tb_agendamento(ds_status);
CREATE INDEX idx_agendamento_data    ON tb_agendamento(dt_agendamento);
CREATE INDEX idx_bloqueio_prestador  ON tb_bloqueio_agenda(id_prestador, dt_inicio, dt_fim);
CREATE INDEX idx_notificacao_usuario ON tb_notificacao(id_usuario, fl_lida);
CREATE INDEX idx_mensagem_conversa   ON tb_mensagem(id_conversa, dt_envio);
CREATE INDEX idx_avaliacao_prestador ON tb_avaliacao(id_prestador_avaliado);
CREATE INDEX idx_prestador_usuario   ON tb_prestador(id_usuario);
CREATE INDEX idx_endereco_coords     ON tb_endereco(nr_latitude, nr_longitude);


-- ── PARTE 2: CATÁLOGO DE SERVIÇOS ──
-- ============================================================
--  VetConnect — Atualização: Catálogo de Serviços + CPF/CNPJ
-- ============================================================

-- ── 1. CPF/CNPJ na tb_usuario ──
ALTER TABLE tb_usuario
  ALTER COLUMN nr_cpf_cnpj_usuario DROP NOT NULL;

COMMENT ON COLUMN tb_usuario.nr_cpf_cnpj_usuario IS 
  'CPF (11 dígitos) ou CNPJ (14 dígitos). MEI usa CPF como CNPJ.';

-- ── 2. Catálogo de serviços (gerenciado pelo ADM) ──
CREATE TABLE tb_servico_catalogo (
    id_servico_catalogo SERIAL PRIMARY KEY,
    nm_servico          VARCHAR(150) NOT NULL UNIQUE,
    ds_servico          TEXT,
    ds_categoria        VARCHAR(50) NOT NULL,   -- 'Veterinário','Estética','Comportamento','Cuidados'
    nm_icone            VARCHAR(10) DEFAULT '🐾',
    nr_duracao_padrao   INTEGER DEFAULT 60,      -- minutos
    fl_requer_crmv      BOOLEAN DEFAULT FALSE,   -- só vets
    fl_ativo            BOOLEAN DEFAULT TRUE,
    dt_criacao          TIMESTAMP DEFAULT NOW()
);

-- Catálogo inicial
INSERT INTO tb_servico_catalogo (nm_servico, ds_servico, ds_categoria, nm_icone, nr_duracao_padrao, fl_requer_crmv) VALUES
  ('Consulta Clínica',        'Avaliação geral, diagnóstico e prescrição',         'Veterinário',   '🩺', 60,  TRUE),
  ('Vacinação',               'Aplicação de vacinas e atualização do cartão',      'Veterinário',   '💉', 30,  TRUE),
  ('Consulta de Retorno',     'Acompanhamento de tratamento em andamento',         'Veterinário',   '🔄', 30,  TRUE),
  ('Teleconsulta',            'Consulta veterinária por videochamada',             'Veterinário',   '📱', 45,  TRUE),
  ('Emergência Domiciliar',   'Atendimento de urgência na residência',             'Veterinário',   '🚨', 60,  TRUE),
  ('Banho e Tosa Completo',   'Banho, tosa, secagem e acabamento',                'Estética',      '✂️', 90,  FALSE),
  ('Banho Simples',           'Banho e secagem sem tosa',                          'Estética',      '🛁', 60,  FALSE),
  ('Tosa Higiênica',          'Higiene das extremidades e região íntima',          'Estética',      '✂️', 30,  FALSE),
  ('Spa Pet',                 'Banho, hidratação, massagem e aromaterapia',        'Estética',      '✨', 120, FALSE),
  ('Adestramento Básico',     'Comandos essenciais e obediência',                 'Comportamento', '🎓', 60,  FALSE),
  ('Adestramento Avançado',   'Comportamentos complexos e controle',              'Comportamento', '🎓', 60,  FALSE),
  ('Consultoria Comportamental','Avaliação e plano de tratamento comportamental', 'Comportamento', '🎓', 60,  FALSE),
  ('Passeio Diário',          'Passeio supervisionado de 1 hora',                 'Cuidados',      '🦮', 60,  FALSE),
  ('Passeio Express',         'Passeio rápido de 30 minutos',                     'Cuidados',      '🦮', 30,  FALSE),
  ('Pet Sitter Domiciliar',   'Cuidador vai até a casa do tutor',                 'Cuidados',      '🏠', 240, FALSE),
  ('Hospedagem',              'Pet fica na casa do prestador',                    'Cuidados',      '🏡', 1440,FALSE);

-- ── 3. Serviços do prestador (baseado no catálogo) ──
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'tb_servico') THEN
    ALTER TABLE tb_servico RENAME TO tb_servico_old;
  END IF;
END $$;

CREATE TABLE tb_prestador_servico (
    id_prestador_servico    SERIAL PRIMARY KEY,
    id_prestador            INTEGER NOT NULL REFERENCES tb_prestador(id_prestador),
    id_servico_catalogo     INTEGER NOT NULL REFERENCES tb_servico_catalogo(id_servico_catalogo),
    vl_preco                NUMERIC(10,2) NOT NULL,
    nr_duracao_minutos      INTEGER,
    fl_atende_local         BOOLEAN DEFAULT TRUE,
    fl_atende_domicilio     BOOLEAN DEFAULT FALSE,
    fl_teleconsulta         BOOLEAN DEFAULT FALSE,
    nr_raio_km              NUMERIC(5,1),
    vl_taxa_deslocamento    NUMERIC(10,2) DEFAULT 0,
    fl_ativo                BOOLEAN DEFAULT TRUE,
    dt_criacao              TIMESTAMP DEFAULT NOW(),
    UNIQUE(id_prestador, id_servico_catalogo)
);

-- ── 4. Solicitação de novo serviço ao ADM ──
CREATE TABLE tb_solicitacao_servico (
    id_solicitacao      SERIAL PRIMARY KEY,
    id_prestador        INTEGER NOT NULL REFERENCES tb_prestador(id_prestador),
    nm_servico_sugerido VARCHAR(150) NOT NULL,
    ds_justificativa    TEXT,
    ds_categoria        VARCHAR(50),
    ds_status           VARCHAR(20) DEFAULT 'PENDENTE',
    ds_resposta_adm     TEXT,
    dt_solicitacao      TIMESTAMP DEFAULT NOW(),
    dt_resposta         TIMESTAMP
);

-- ── 5. Agendamento aponta para tb_prestador_servico ──
DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.columns 
             WHERE table_name='tb_agendamento' AND column_name='id_servico') THEN
    ALTER TABLE tb_agendamento 
      RENAME COLUMN id_servico TO id_servico_old;
  END IF;
END $$;

ALTER TABLE tb_agendamento
  ADD COLUMN IF NOT EXISTS id_prestador_servico INTEGER 
  REFERENCES tb_prestador_servico(id_prestador_servico);


-- ── PARTE 3: CONSELHOS POR SERVIÇO ──
-- ============================================================
--  VetConnect — Atualização: Conselhos por Serviço
-- ============================================================

CREATE TABLE IF NOT EXISTS tb_servico_conselho (
    id_servico_conselho     SERIAL PRIMARY KEY,
    id_servico_catalogo     INTEGER NOT NULL REFERENCES tb_servico_catalogo(id_servico_catalogo),
    id_conselho             INTEGER NOT NULL REFERENCES tb_conselho(id_conselho),
    UNIQUE(id_servico_catalogo, id_conselho)
);

INSERT INTO tb_servico_conselho (id_servico_catalogo, id_conselho)
SELECT sc.id_servico_catalogo, c.id_conselho
FROM tb_servico_catalogo sc, tb_conselho c
WHERE sc.nm_servico IN (
    'Consulta Clínica','Vacinação','Consulta de Retorno',
    'Teleconsulta','Emergência Domiciliar'
)
AND c.sg_conselho = 'CRMV'
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS tb_prestador_registro (
    id_registro         SERIAL PRIMARY KEY,
    id_prestador        INTEGER NOT NULL REFERENCES tb_prestador(id_prestador),
    id_conselho         INTEGER NOT NULL REFERENCES tb_conselho(id_conselho),
    nr_registro         VARCHAR(50) NOT NULL,
    dt_validade         DATE,
    fl_verificado       BOOLEAN DEFAULT FALSE,
    dt_verificacao      TIMESTAMP,
    id_admin_verificou  INTEGER REFERENCES tb_usuario(id_usuario),
    dt_criacao          TIMESTAMP DEFAULT NOW(),
    UNIQUE(id_prestador, id_conselho)
);

CREATE OR REPLACE VIEW vw_servico_conselhos AS
SELECT 
    sc.id_servico_catalogo,
    sc.nm_servico,
    sc.ds_categoria,
    sc.fl_requer_crmv,
    COALESCE(
        string_agg(c.sg_conselho, ', ' ORDER BY c.sg_conselho), 
        'Nenhum'
    ) AS conselhos_aceitos,
    COUNT(sco.id_conselho) AS qtd_conselhos
FROM tb_servico_catalogo sc
LEFT JOIN tb_servico_conselho sco ON sco.id_servico_catalogo = sc.id_servico_catalogo
LEFT JOIN tb_conselho c ON c.id_conselho = sco.id_conselho
GROUP BY sc.id_servico_catalogo, sc.nm_servico, sc.ds_categoria, sc.fl_requer_crmv;


-- ── PARTE 4: USUÁRIOS DE TESTE (CORRIGIDO) ──
-- ============================================================
--  VetConnect — Usuários de Teste com Senha e CPF/CNPJ
-- ============================================================

-- ── 1. Tipos de usuário ──
INSERT INTO tb_tipo_usuario (id_tipo_usuario, nm_tipo_usuario) VALUES
  (1, 'Administrador'),
  (2, 'Tutor'),
  (3, 'Prestador')
ON CONFLICT (id_tipo_usuario) DO UPDATE 
  SET nm_tipo_usuario = EXCLUDED.nm_tipo_usuario;

-- ── 2. Administrador ──
INSERT INTO tb_usuario (nm_usuario, ds_email_usuario, ds_senha_usuario, id_tipo_usuario, nr_cpf_cnpj_usuario, fl_ativo_usuario)
VALUES ('Admin VetConnect', 'admin@vetconnect.com', '123456', 1, '00000000000', true)
ON CONFLICT (ds_email_usuario) DO NOTHING;

-- ── 3. Clientes (Tutores) ──
INSERT INTO tb_usuario (nm_usuario, ds_email_usuario, ds_senha_usuario, id_tipo_usuario, nr_cpf_cnpj_usuario, fl_ativo_usuario)
VALUES 
  ('Maria Silva',  'cliente1@vetconnect.com', '123456', 2, '12345678901', true),
  ('João Santos',  'cliente2@vetconnect.com', '123456', 2, '98765432100', true),
  ('Ana Oliveira', 'cliente3@vetconnect.com', '123456', 2, '45678901234', true)
ON CONFLICT (ds_email_usuario) DO NOTHING;

-- ── 4. Prestadores ──
INSERT INTO tb_usuario (nm_usuario, ds_email_usuario, ds_senha_usuario, id_tipo_usuario, nr_cpf_cnpj_usuario, fl_ativo_usuario)
VALUES 
  ('Dr. Carlos Silva',  'vet@vetconnect.com',     '123456', 3, '11122233344', true),
  ('PetShop Alegria',   'tosador@vetconnect.com', '123456', 3, '22233344455', true),
  ('Rafael Adestrador', 'prest3@vetconnect.com',  '123456', 3, '33344455566', true)
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