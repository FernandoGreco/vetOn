# VetConnect — Código Fonte Completo
Data: 21/07/2026 02:31

## Estrutura
```
vetconnect_completo/
├── app/
│   └── index.html          → Aplicação completa (28 telas, 114 funções)
└── banco/
    ├── 01_vetconnect_FINAL.sql          → Schema completo do banco (39 tabelas)
    ├── 02_vetconnect_RLS.sql            → Row Level Security - parte 1
    ├── 03_vetconnect_RLS_complemento.sql → Row Level Security - parte 2
    ├── 04_vetconnect_RLS_fix.sql        → Fix funções helper (auth_uid)
    └── 05_criar_usuarios_teste.sql      → Usuários de teste
```

## Como usar

### App
- Abra `app/index.html` no browser
- Ou suba no Vercel: vercel.com/new/drop

### Banco (Supabase)
Execute os SQLs na ordem numérica no Supabase SQL Editor:
1. `01_vetconnect_FINAL.sql` → Cria todas as tabelas
2. `02_vetconnect_RLS.sql` → Aplica segurança RLS
3. `03_vetconnect_RLS_complemento.sql` → Complemento RLS
4. `04_vetconnect_RLS_fix.sql` → Vincula auth_uid
5. `05_criar_usuarios_teste.sql` → Cria usuários de teste

## Credenciais de teste
| Email | Senha | Tipo |
|-------|-------|------|
| admin@vetconnect.com | Admin@2024! | Administrador |
| cliente1@vetconnect.com | Cliente@2024! | Tutor |
| vet@vetconnect.com | Prest@2024! | Prestador |

## Infraestrutura
- Supabase: sgbiijwykhikdbeuvval.supabase.co
- Vercel: vetconnect-mu.vercel.app
- GitHub: github.com/brsouqu-dev/vetconnect
