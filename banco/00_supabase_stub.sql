-- Cria o schema auth simulado para o Postgres Vanilla / Docker local
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE
);

-- Mock da função auth.uid()
CREATE OR REPLACE FUNCTION auth.uid() 
RETURNS UUID AS $$
    SELECT NULL::UUID;
$$ LANGUAGE sql STABLE;