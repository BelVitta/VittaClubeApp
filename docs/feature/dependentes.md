# Dependentes

Modulo para permitir que um titular use o Vita Clube com dependentes ativos,
sem add-on pago neste momento.

## Regras de Negocio

- **RN-01**: Cada titular pode ter no maximo `max_dependents_per_holder`
  dependentes ativos. Default: 2. Parametro global configuravel.
- **RN-02**: Cada dependente tem `monthly_uses_per_dependent` usos por ciclo.
  Default: 2. Parametro global configuravel.
- **RN-03**: Os 2 primeiros dependentes sao gratuitos. Nao ha cobranca de
  add-on neste momento.
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
- **RN-09**: CPF do dependente e unico globalmente entre dependentes ativos.
- **RN-10**: Uso so e liberado se o titular estiver com assinatura em dia e o
  dependente estiver ativo.

## Fluxo do Cliente

1. Titular cadastra dependente.
2. Sistema valida limite ativo e CPF unico.
3. Titular escolhe para quem sera o desconto ao agendar.
4. Agendamento gera QR assinado sem debitar cota.
5. Cota e debitada apenas quando a recepcao valida o QR.

## Fluxo da Recepcao

1. Admin escaneia QR do agendamento.
2. Servidor valida assinatura, status, janela, assinatura do titular e status
   do dependente.
3. Servidor bloqueia concorrencia, reconta usos no ciclo e grava
   `usage_records`.
4. Agendamento muda para `utilizado` ou retorna recusa clara.

## Configuracoes

- `max_dependents_per_holder`: maximo de dependentes ativos por titular.
- `monthly_uses_per_dependent`: usos por dependente em cada ciclo.

Ambas ficam em `clinic_settings` para evitar hardcode.

## Mapeamento tecnico

- UI do cliente: `lib/features/dependents/presentation/pages/dependents_page.dart`
  e widgets de selecao/cadastro em `presentation/widgets`.
- Regras de negocio: use cases e services em
  `lib/features/dependents/domain`.
- Persistencia: datasource Supabase em
  `lib/features/dependents/data/datasources/dependents_supabase_datasource.dart`.
- Validacao atomica do QR: RPC `validate_dependent_qr`.
- Auditoria: `dependent_qr_validation_audit_logs`.
- Expiracao: funcao `expire_stale_dependent_appointments`, chamada por job
  agendado ou rotina operacional.

## Estados e falhas esperadas

- Cadastro bloqueado quando o titular atinge o limite configurado.
- Cadastro bloqueado quando CPF ja esta ativo em outro titular.
- Agendamento criado em `agendado` sem gerar `usage_records`.
- QR recusado quando token e invalido, agendamento expirou, titular esta sem
  assinatura ativa, dependente esta inativo ou cota foi esgotada.
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
