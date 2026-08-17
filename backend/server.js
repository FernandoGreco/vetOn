const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const path = require('path');

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

app.use(cors());
app.use(express.json());

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