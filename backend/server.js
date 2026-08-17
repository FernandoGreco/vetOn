const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const path = require('path');
const swaggerUi = require('swagger-ui-express');

const app = express();
const port = process.env.PORT || 3000;

// Configuração de conexão do PostgreSQL
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'db',
  database: process.env.DB_NAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

// Configuração básica da documentação Swagger
const swaggerDocument = {
  openapi: '3.0.0',
  info: {
    title: 'VetOn API',
    version: '1.0.0',
    description: 'Documentação da API do sistema VetOn',
  },
  paths: {
    '/ping': {
      get: {
        summary: 'Verifica saúde da API',
        responses: {
          '200': { description: 'Retorna pong se a API estiver rodando' },
        },
      },
    },
    '/usuarios': {
      get: {
        summary: 'Lista todos os usuários',
        responses: {
          '200': { description: 'Lista de usuários cadastrados no banco' },
          '500': { description: 'Erro interno no servidor' },
        },
      },
    },
  },
};

app.use(cors());
app.use(express.json());

// Rota para a interface visual do Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Rota de teste simples para verificar se a API está respondendo
app.get('/ping', (req, res) => {
  res.send('pong');
});

// Servir o arquivo index.html na raiz
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Endpoint de Usuários
app.get('/usuarios', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM tb_usuario');
    res.json(result.rows);
  } catch (err) {
    console.error('Erro ao buscar usuários:', err);
    res.status(500).json({ error: 'Erro interno no servidor' });
  }
});


// ── ROTAS DE AUTENTICAÇÃO E USUÁRIOS ──

// Login: Autentica apenas usuários cadastrados na tabela do banco
app.post('/api/usuarios/login', async (req, res) => {
  try {
    const { email, senha } = req.body;

    if (!email || !senha) {
      return res.status(400).json({ error: 'E-mail e senha são obrigatórios.' });
    }

    // Consulta adaptada com os nomes exatos das colunas do seu banco
    const query = `
      SELECT 
        id_usuario AS id,
        nm_usuario AS nome,
        ds_email_usuario AS email,
        id_tipo_usuario AS role
      FROM tb_usuario 
      WHERE LOWER(ds_email_usuario) = LOWER($1) AND ds_senha_usuario = $2
    `;
    const result = await pool.query(query, [email, senha]);

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'E-mail ou senha incorretos.' });
    }

    // Trata o perfil do usuário (ex: id_tipo_usuario = 3 é prestador)
    const user = result.rows[0];
    user.role = user.role === 3 ? 'prestador' : 'tutor';
    user.avatar = user.nome.substring(0, 2).toUpperCase();

    return res.json({ success: true, user });
  } catch (error) {
    console.error('Erro ao realizar login:', error);
    return res.status(500).json({ error: 'Erro interno no servidor.' });
  }
});


// Cadastro: Insere novos usuários na tabela tb_usuario
app.post('/api/usuarios/cadastro', async (req, res) => {
  try {
    const { nome, email, senha, role } = req.body;

    if (!nome || !email || !senha) {
      return res.status(400).json({ error: 'Preencha todos os campos obrigatórios.' });
    }

    // Mapeia a role para o id_tipo_usuario do banco (3 = prestador, 2 = tutor)
    const idTipoUsuario = role === 'prestador' ? 3 : 2;

    const query = `
      INSERT INTO tb_usuario (nm_usuario, ds_email_usuario, ds_senha_usuario, id_tipo_usuario)
      VALUES ($1, $2, $3, $4)
      RETURNING 
        id_usuario AS id,
        nm_usuario AS nome,
        ds_email_usuario AS email,
        id_tipo_usuario AS role
    `;
    
    const result = await pool.query(query, [
      nome.trim(),
      email.toLowerCase().trim(),
      senha,
      idTipoUsuario
    ]);

    const user = result.rows[0];
    user.role = user.role === 3 ? 'prestador' : 'tutor';
    user.avatar = user.nome.substring(0, 2).toUpperCase();

    return res.status(201).json({ success: true, user });
  } catch (error) {
    if (error.code === '23505') { // Violação de UNIQUE (e-mail duplicado)
      return res.status(400).json({ error: 'Este e-mail já está cadastrado no sistema.' });
    }
    console.error('Erro no cadastro:', error);
    return res.status(500).json({ error: 'Erro ao registrar usuário.' });
  }
});


// Retry de conexão com o Postgres
async function connectWithRetry() {
  let connected = false;
  while (!connected) {
    try {
      await pool.query('SELECT 1');
      connected = true;
      console.log('Conectado ao PostgreSQL com sucesso!');
    } catch (err) {
      console.log('Aguardando banco de dados inicializar... Retentando em 3s');
      await new Promise((res) => setTimeout(res, 3000));
    }
  }
}

app.listen(port, async () => {
  await connectWithRetry();
  console.log(`Servidor rodando na porta ${port}`);
});