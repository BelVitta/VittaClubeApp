# Comandos Supabase e Ambientes

## Setup local

Copie o arquivo de exemplo e preencha com os dados reais dos projetos:

```bash
cp supabase.env.example supabase.env
```

Campos principais:

```bash
SUPABASE_DEV_REF=...
SUPABASE_DEV_DB_PASSWORD=...
SUPABASE_DEV_URL=https://...supabase.co
SUPABASE_DEV_ANON_KEY=...

SUPABASE_PROD_REF=...
SUPABASE_PROD_DB_PASSWORD=...
SUPABASE_PROD_URL=https://...supabase.co
SUPABASE_PROD_ANON_KEY=...
```

`supabase.env` é local e não deve ser commitado.

## Atualizar banco e Edge Functions

Aplicar migrations e functions no dev:

```bash
./scripts/supabase_push_dev.sh
```

Aplicar migrations e functions em produção:

```bash
./scripts/supabase_push_prod.sh
```

Aplicar em dev primeiro e depois produção, com confirmação:

```bash
./scripts/supabase_push_all.sh
```

Os scripts executam:

```bash
supabase link --project-ref <REF>
supabase migration list
supabase db push
supabase functions deploy health-check
supabase functions deploy create-woovi-subscription
supabase functions deploy woovi-webhook
supabase functions deploy reconcile-woovi-subscription
supabase functions deploy cancel-woovi-subscription
supabase migration list
```

## Rodar app apontando para dev/prod

Staging usando Supabase dev:

```bash
flutter run -t lib/main_staging.dart \
  --dart-define=SUPABASE_URL="$SUPABASE_DEV_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_DEV_ANON_KEY"
```

Produção:

```bash
flutter run -t lib/main_prod.dart \
  --dart-define=SUPABASE_URL="$SUPABASE_PROD_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_PROD_ANON_KEY"
```

No VS Code, configure estas variáveis no ambiente do terminal antes de abrir o editor:

```bash
export VITTACLUBE_SUPABASE_DEV_URL="$SUPABASE_DEV_URL"
export VITTACLUBE_SUPABASE_DEV_ANON_KEY="$SUPABASE_DEV_ANON_KEY"
export VITTACLUBE_SUPABASE_PROD_URL="$SUPABASE_PROD_URL"
export VITTACLUBE_SUPABASE_PROD_ANON_KEY="$SUPABASE_PROD_ANON_KEY"
code .
```

Depois use os launches `Vita Clube (Staging)` ou `Vita Clube (Prod)`.

## Keepalive provisório

Depois de deployar a function `health-check`, rode:

```bash
./scripts/supabase_keepalive.sh
```

Para cron local, exemplo a cada 3 dias às 09:00:

```cron
0 9 */3 * * cd /caminho/para/VittaClubeApp && ./scripts/supabase_keepalive.sh
```

Observação: keepalive é uma rotina operacional para reduzir risco de pausa em plano Free. A solução garantida para não pausar projeto por inatividade é usar organização/projeto em plano pago.

## Diagnóstico rápido

Ver projeto Supabase atualmente linkado:

```bash
cat supabase/.temp/project-ref
```

Ver migrations remotas e locais:

```bash
supabase migration list
```

Ver dispositivos Flutter:

```bash
flutter devices
```

Build Android staging:

```bash
flutter build apk --debug -t lib/main_staging.dart \
  --dart-define=SUPABASE_URL="$SUPABASE_DEV_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_DEV_ANON_KEY"
```
