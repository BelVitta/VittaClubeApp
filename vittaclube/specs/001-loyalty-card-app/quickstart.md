# Quickstart: Planejamento Tecnico Vitta Clube

## Objetivo

Validar que a implementacao futura do Vitta Clube segue a arquitetura atual,
mantem qualidade visual, performance, acessibilidade, seguranca e permite
evolucao para dados dinamicos sem refatoracao caotica.

## Pre-requisitos

- Flutter instalado.
- Dependencias do projeto instaladas.
- Arquivos de configuracao de ambiente preenchidos a partir dos exemplos.
- Supabase configurado para ambientes dev/staging/prod quando usar dados
  remotos.

## Comandos de verificacao

Na raiz do app Flutter (`/home/alanis/Downloads/Vita Clube/VittaClubeApp`):

```bash
flutter pub get
flutter analyze
flutter test
```

Para validar a feature de dependentes de forma focada:

```bash
flutter test test/features/dependents test/core/services/clinic_settings_service_dependents_test.dart test/features/admin/presentation/dependent_settings_page_test.dart
```

## Validacao manual da home comercial

1. Abrir o app em viewport mobile pequeno.
2. Confirmar que a primeira tela mostra:
   - proposta do Vitta Clube;
   - CTA principal;
   - CTA de contato;
   - indicio de preco/beneficio;
   - prova de confianca.
3. Navegar pelas secoes:
   - como funciona;
   - beneficios;
   - planos;
   - niveis;
   - especialistas;
   - parceiros;
   - sorteios;
   - FAQ;
   - contato.
4. Confirmar ausencia de placeholders.
5. Confirmar que WhatsApp/telefone/link externo tem fallback se falhar.

## Validacao de arquitetura

Para cada nova feature:

1. Criar ou usar pasta em `lib/features/[feature]`.
2. Manter `domain`, `data` e `presentation` quando houver regra/dado dinamico.
3. Colocar widgets especificos em `features/[feature]/presentation/widgets`.
4. Colocar apenas widgets genericos em `lib/shared/widgets`.
5. Registrar dependencias em `lib/core/di/injection_container.dart`.
6. Evitar import de Supabase fora de datasource/config.
7. Evitar import de Flutter no domain.

## Validacao de seguranca

1. Testar login como `user`, `admin`, `financeiro/super_admin` e `parceiro`
   quando aplicavel.
2. Confirmar que admin nao ve valores financeiros consolidados.
3. Confirmar que admin nao altera role.
4. Confirmar que user nao acessa dados de outro user.
5. Confirmar que acoes sensiveis geram audit log.
6. Confirmar que dados pessoais sao mascarados conforme role.

## Validacao manual de dependentes e QR

1. Cadastrar dois dependentes ativos para o mesmo titular.
2. Confirmar que o terceiro cadastro e bloqueado pelo valor de
   `max_dependents_per_holder`.
3. Tentar cadastrar o mesmo CPF ativo em outro titular e confirmar recusa.
4. Criar agendamento para titular/dependente e confirmar que a cota nao muda.
5. Validar o QR na recepcao e confirmar debito de apenas um uso.
6. Revalidar o mesmo QR e confirmar replay sem novo debito.
7. Alterar `monthly_uses_per_dependent` no admin e confirmar que a cota muda
   sem alteracao no codigo.
8. Executar ou agendar `expire_stale_dependent_appointments` e confirmar que
   agendamentos expirados nao geram `usage_records`.

## Validacao de acessibilidade

1. Aumentar tamanho de fonte do dispositivo.
2. Verificar se textos principais nao cortam.
3. Conferir contraste visual de textos, botoes e estados.
4. Confirmar labels em inputs.
5. Confirmar Semantics/tooltip em botoes icon-only.
6. Confirmar que erro nao depende apenas de cor.

## Validacao de performance

1. Confirmar que nao ha chamadas remotas em `build`.
2. Verificar listas com muitos itens.
3. Confirmar skeleton/loading em dados remotos.
4. Conferir imagens grandes ou remotas com fallback.
5. Usar `const` onde possivel.
6. Evitar rebuilds amplos em BLoCs.

## Pronto para tasks quando

- `plan.md`, `research.md`, `data-model.md`, `contracts/` e `quickstart.md`
  estiverem completos.
- Constituicao passar sem violacoes.
- Nao houver `NEEDS CLARIFICATION`.
- Arquitetura de pastas e contratos estiverem claros para gerar tarefas.
