# 🐾 VetConnect

Plataforma Web para conexão entre tutores de pets e prestadores de serviços veterinários/estéticos. O sistema roda em arquitetura containerizada com **Node.js + Express** e **PostgreSQL**.

---

## 🛠️ Pré-requisitos

Antes de iniciar, certifique-se de ter instalado em sua máquina:
* **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** (Windows/macOS) ou **Docker + Docker Compose** (Linux)
* **[Git](https://git-scm.com/)**

---

## 🚀 Passo a Passo para Rodar o Projeto

### 1. Clonar o Repositório
Abra o terminal e execute:
```bash
git clone https://github.com/FernandoGreco/vetOn.git
cd vetconnect
```

### 2. Subir os Containers
Na **pasta raiz** do projeto (onde está o arquivo `docker-compose.yml`), rode:
```bash
docker-compose up --build -d
```
> *Este comando baixa o PostgreSQL, cria o banco, executa os scripts SQL iniciais de criação de tabelas e sobe a API em Node.js.*

---

## 🔗 Links de Acesso

Após os containers subirem, acesse no navegador:

* **Aplicação Web:** [http://localhost:3000](http://localhost:3000)
* **Documentação Swagger (API):** [http://localhost:3000/docs](http://localhost:3000/docs)
* **Banco de Dados (PostgreSQL):** `localhost:5432`  
  * **Usuário:** `postgres`  
  * **Senha:** `postgres`  
  * **Banco:** `veton`

---

## 🔐 Contas de Teste

| Nome | E-mail | Senha | Perfil |
|------|--------|-------|--------|
| **Maria Silva** | `cliente1@vetconnect.com` | `123456` | Tutor |
| **Dr. Carlos Silva** | `vet@vetconnect.com` | `123456` | Prestador |
| **Admin VetConnect** | `admin@vetconnect.com` | `123456` | Administrador |

---

## 🛠️ Comandos Úteis

* **Ver logs do backend em tempo real:**
  ```bash
  docker-compose logs -f backend
  ```
* **Reiniciar o backend após alterar o `server.js`:**
  ```bash
  docker-compose restart backend
  ```
* **Parar todos os containers:**
  ```bash
  docker-compose down
  ```
* **Resetar o banco de dados do zero:**
  ```bash
  docker-compose down -v
  docker-compose up --build -d