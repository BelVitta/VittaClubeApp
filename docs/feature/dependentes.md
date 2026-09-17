# Dependentes

Modulo para permitir que um titular use o Vita Clube com dependentes ativos,
sem add-on pago neste momento.

## Regras de Negocio

- **RN-01**: Cada titular pode ter no maximo `max_dependents_per_holder`
  dependentes (somando `pending` + `active`). Default: 2. Parametro global
  configuravel.
- **RN-02**: Cada dependente ativo tem `monthly_uses_per_dependent` usos por
  ciclo. Default: 1. Parametro global configuravel.
- **RN-03**: Todo cadastro de dependente entra como `pending`. Ele só pode
  ser usado (selecionado num agendamento, ter QR validado) depois que um
  admin aprova presencialmente — não existe fluxo self-service nem upload
  de documento. É uma confirmação humana no balcão (ex: na primeira visita
  do dependente), sem custo de verificação externa/API paga.
- **RN-03b**: Um admin pode rejeitar um cadastro `pending`, gravando
  `rejection_reason`. O registro vira `inactive` (mantido para auditoria,
  não é apagado).
- **RN-04**: O debito de cota ocorre somente na validacao do QR pela recepcao.
  Agendamento nunca debita cota.
- **RN-05**: Usos restantes = limite mensal menos `usage_records` utilizados
  no ciclo corrente. Agendamentos nao validados nao contam.
- **RN-06**: O ciclo de reset segue a data de adesao do titular, nao o
  mes-calendario.
- **RN-07**: A transicao `agendado -> utilizado` deve ser atomica, idempotente
  e protegida contra concorrencia.
- **RN-08**: O QR carrega apenas identificador opaco e assinado do agendamento.
  Validacao real sempre ocorre no servidor.
- **RN-09**: CPF do dependente e unico globalmente entre dependentes
  `pending` + `active` (evita fila de cadastros duplicados aguardando
  aprovação).
- **RN-10**: Uso so e liberado se o titular estiver com assinatura em dia e o
  dependente estiver `active` (não `pending`).

## Fluxo do Cliente

1. Titular cadastra dependente → status `pending`.
2. Sistema valida limite (`pending`+`active`) e CPF unico.
3. Titular aguarda aprovação presencial de um admin (ex: primeira visita).
4. Uma vez `active`, o titular pode escolher esse dependente ao agendar.
5. Agendamento gera QR assinado sem debitar cota.
6. Cota e debitada apenas quando a recepcao valida o QR.

## Fluxo da Recepcao

1. Admin revisa cadastros `pending` (tela própria no painel admin) e
   aprova/rejeita presencialmente.
2. Admin escaneia QR do agendamento.
3. Servidor valida assinatura, status, janela, assinatura do titular e status
   `active` do dependente.
4. Servidor bloqueia concorrencia, reconta usos no ciclo e grava
   `usage_records`.
5. Agendamento muda para `utilizado` ou retorna recusa clara.

## Configuracoes

- `max_dependents_per_holder`: maximo de dependentes (pending+active) por
  titular. Default 2.
- `monthly_uses_per_dependent`: usos por dependente ativo em cada ciclo.
  Default 1.

Ambas ficam em `clinic_settings` para evitar hardcode, editáveis em
`AdminClinicSettingsPage`.

## Mapeamento tecnico

- UI do cliente: `lib/features/dependents/presentation/pages/dependents_page.dart`
  e widgets de selecao/cadastro em `presentation/widgets`.
- UI do admin (aprovação): `lib/features/admin/presentation/pages/dependents/admin_dependents_list_page.dart`.
- Regras de negocio: use cases e services em
  `lib/features/dependents/domain`.
- Persistencia: datasource Supabase em
  `lib/features/dependents/data/datasources/dependents_supabase_datasource.dart`.
- Validacao atomica do QR: RPC `validate_dependent_qr` (dependente) e
  `validate_member_qr` (titular) — ambas chamadas pelo mesmo
  `AdminQrScannerPage`, que detecta o formato do código escaneado.
- Auditoria: `dependent_qr_validation_audit_logs`.
- Expiracao: funcao `expire_stale_dependent_appointments`, agendada via
  `pg_cron`.

## Estados e falhas esperadas

- Cadastro sempre nasce `pending`; nunca é usável antes da aprovação.
- Cadastro bloqueado quando o titular atinge o limite configurado
  (contando pending+active).
- Cadastro bloqueado quando CPF ja esta pending/active em outro titular.
- Agendamento criado em `agendado` sem gerar `usage_records`.
- QR recusado quando token e invalido, agendamento expirou, titular esta sem
  assinatura ativa, dependente nao esta `active` (inclui `pending`) ou cota
  foi esgotada.
- Replay de QR ja utilizado retorna decisao propria e nao debita novo uso.

## Acessibilidade

- Inputs precisam de labels visiveis e mensagens de erro textuais.
- Cards de quota e validacao nao podem depender apenas de cor para informar
  aprovado/recusado.
- CTAs devem manter area de toque minima adequada no mobile.
- Textos de status precisam continuar legiveis com fonte ampliada.
- Componentes icon-only devem receber `Semantics` ou tooltip quando forem
  adicionados ao fluxo.

## Performance e manutencao

- Nao chamar Supabase dentro de `build`; carregar dados via BLoC/use case.
- Usar widgets pequenos e `const` quando aplicavel para evitar rebuild amplo.
- Paginar listas de dependentes/agendamentos quando o volume crescer.
- Cachear settings globais via `ClinicSettingsService` e invalidar apos save.
- Evitar chamadas duplicadas ao RPC de QR; o botao/scanner deve entrar em
  loading durante a validacao.
- Imagens futuras de parceiros/profissionais devem ter fallback profissional e
  tamanho otimizado.
