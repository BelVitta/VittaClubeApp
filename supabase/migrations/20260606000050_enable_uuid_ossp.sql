-- Garante a extensão uuid-ossp (uuid_generate_v4) antes das migrations que
-- dependem dela. Já habilitada no prod; ausente em projetos novos (ex: dev).
create extension if not exists "uuid-ossp";
