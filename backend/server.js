const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Servir os arquivos estáticos (HTML/CSS/JS) da pasta public
app.use(express.static(path.join(__dirname, '../public')));

// Configuração do Supabase Client
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://sgbiijwykhikdbeuvval.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_KEY || 'sb_publishable_f1HmaDqyfzNf6jMFpQFcyQ_6PFbFoNT';
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ── ROTAS DE AUTENTICAÇÃO ──

app.post('/api/auth/login', async (req, res) => {
  const { email, senha } = req.body;
  const { data, error } = await supabase.auth.signInWithPassword({ email, password: senha });
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data);
});

app.post('/api/auth/cadastro', async (req, res) => {
  const { email, senha, nome, role, extras } = req.body;
  const { data: authData, error: authError } = await supabase.auth.signUp({ email, password: senha });
  
  if (authError) return res.status(400).json({ error: authError.message });
  if (!authData.user) return res.json({ message: 'Cadastro realizado! Faça login.' });

  const idTipo = role === 'Prestador' ? 3 : 2;
  const { data: userData, error: userError } = await supabase.from('tb_usuario').insert([{
    ds_email_usuario: email,
    nm_usuario: nome || email.split('@')[0],
    id_tipo_usuario: idTipo,
    nr_cpf_cnpj_usuario: extras?.cpf ? extras.cpf.replace(/\D/g, '') : null,
    fl_ativo_usuario: true,
    auth_uid: authData.user.id
  }]).select();

  if (userError) return res.status(400).json({ error: userError.message });

  const idUsuario = userData[0].id_usuario;
  if (extras?.telefone) {
    await supabase.from('tb_contato_usuario').insert([{
      id_usuario: idUsuario, ds_tipo: 'CELULAR',
      nr_contato: extras.telefone, fl_principal: true, fl_whatsapp: true
    }]);
  }
  if (idTipo === 3) {
    await supabase.from('tb_prestador').insert([{
      id_usuario: idUsuario, fl_verificado_prestador: false
    }]);
  }

  return res.json({ user: authData.user, profile: userData[0] });
});

// ── ROTAS DE USUÁRIO E PETS ──

app.get('/api/usuario/:email', async (req, res) => {
  const { data, error } = await supabase.from('tb_usuario')
    .select('*, tb_tipo_usuario(nm_tipo_usuario)')
    .eq('ds_email_usuario', req.params.email).single();
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data);
});

app.get('/api/pets/:idUsuario', async (req, res) => {
  const { data, error } = await supabase.from('tb_pet')
    .select('*').eq('id_usuario', req.params.idUsuario).eq('fl_ativo_pet', true);
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data);
});

app.post('/api/pets', async (req, res) => {
  const pet = req.body;
  const { data, error } = pet.id_pet
    ? await supabase.from('tb_pet').update(pet).eq('id_pet', pet.id_pet).select()
    : await supabase.from('tb_pet').insert([pet]).select();
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data[0]);
});

// ── ROTAS DE AGENDAMENTOS ──

app.get('/api/agendamentos/cliente/:idUsuario', async (req, res) => {
  const { data, error } = await supabase.from('tb_agendamento')
    .select('*, tb_prestador_servico(vl_preco, nr_duracao_minutos, tb_servico_catalogo(nm_servico)), tb_pet(nm_pet), tb_prestador(tb_usuario(nm_usuario))')
    .eq('id_usuario', req.params.idUsuario)
    .order('dt_agendamento', { ascending: false });
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data);
});

app.get('/api/agendamentos/prestador/:idPrestador', async (req, res) => {
  const { data, error } = await supabase.from('tb_agendamento')
    .select('*, tb_prestador_servico(vl_preco, tb_servico_catalogo(nm_servico)), tb_pet(nm_pet), tb_usuario(nm_usuario, ds_email_usuario)')
    .eq('id_prestador_servico', req.params.idPrestador)
    .order('dt_agendamento', { ascending: false });
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data);
});

app.post('/api/agendamentos', async (req, res) => {
  const { data, error } = await supabase.from('tb_agendamento').insert([req.body]).select();
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data[0]);
});

app.patch('/api/agendamentos/:id/status', async (req, res) => {
  const { status } = req.body;
  const { error } = await supabase.from('tb_agendamento')
    .update({ ds_status: status }).eq('id_agendamento', req.params.id);
  if (error) return res.status(400).json({ error: error.message });
  return res.json({ success: true });
});

// ── ROTAS DE PRESTADORES ──

app.get('/api/prestadores', async (req, res) => {
  const { data, error } = await supabase.from('tb_prestador')
    .select('*, tb_usuario(nm_usuario, ds_email_usuario), tb_prestador_servico(*, tb_servico_catalogo(nm_servico, ds_categoria))')
    .eq('fl_verificado_prestador', true);
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data);
});

app.get('/api/prestadores/:id/servicos', async (req, res) => {
  const { data, error } = await supabase.from('tb_prestador_servico')
    .select('*, tb_servico_catalogo(nm_servico, ds_categoria, nm_icone, nr_duracao_padrao)')
    .eq('id_prestador_servico', req.params.id).eq('fl_ativo', true);
  if (error) return res.status(400).json({ error: error.message });
  return res.json(data);
});

// Rota fallback para entregar o HTML principal
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.listen(PORT, () => {
  console.log(`Servidor Node.js rodando na porta ${PORT}`);
});