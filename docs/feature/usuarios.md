# Usuários

Gestão dos membros/pacientes cadastrados.

## O que faz
Listar, buscar, ver detalhes, editar dados, bloquear/desbloquear, cadastrar manualmente (walk-in).

## Fluxo
1. Admin busca por CPF/nome/telefone.
2. Ve plano ativo, consultas, histórico.
3. Edita dados básicos (nome, telefone, endereço).

## Permissão Admin (recepcionista)
- ✅ Buscar, visualizar, editar dados não sensíveis, cadastrar novo.
- ⚠️ Ve CPF/WhatsApp **mascarados** (ex: `***.123.***-**`).
- ❌ Não pode alterar role, excluir conta, ver pagamentos detalhados.

## Permissão Super Admin
- ✅ Tudo + ver CPF completo, alterar role (criar outro admin), excluir conta, ver total gasto.

## Riscos (recepcionista) — ⚠️ ALTO
- **Vazamento de LGPD**: CPF, WhatsApp, endereço são dados pessoais.
- **Escalação de privilégio**: recepcionista criar admin para si mesmo.
- **Fraude**: editar dados para redirecionar benefícios.
- Mitigação:
  - Campos sensíveis criptografados (pgcrypto), decrypt só para financeiro.
  - `audit_log` em todo UPDATE.
  - Role só muda via Super Admin.
  - Rate limit em buscas (evitar scraping).

## RLS Supabase
- `SELECT`: admin vê campos públicos; financeiro vê tudo.
- `UPDATE role`: apenas financeiro.
- `DELETE`: apenas financeiro.
