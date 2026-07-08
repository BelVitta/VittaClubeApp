# Release APK Cliente

## Pre-requisitos

- `android/key.properties` criado a partir de `android/key.properties.example`.
- Keystore local em `android/app/upload-keystore.jks` ou caminho equivalente.
- `SUPABASE_PROD_URL`, `SUPABASE_PROD_ANON_KEY` e `QR_SECRET` exportados no terminal.
- Migrations e Edge Functions aplicadas em produção.
- `android/app/google-services.json` compatível com o package da release. No arquivo local atual, o package é `com.example.vita_clube`.

## Gerar keystore local

```bash
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias vittaclube
```

Depois copie o exemplo e preencha as senhas:

```bash
cp android/key.properties.example android/key.properties
```

Esses arquivos são locais e não devem ser commitados.

## Validar antes do APK

```bash
flutter analyze
flutter test
./scripts/supabase_push_prod.sh
```

Validar manualmente contas com `profiles.role`:

- `user`: entra na Home e não acessa telas administrativas.
- `admin`: entra no painel operacional.
- `financeiro`: entra no dashboard financeiro e acessa operacional.
- `parceiro`: entra no painel parceiro.

## Build APK produção

```bash
flutter build apk --release --flavor prod -t lib/main_prod.dart \
  --dart-define=SUPABASE_URL="$SUPABASE_PROD_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_PROD_ANON_KEY" \
  --dart-define=QR_SECRET="$QR_SECRET"
```

APK esperado:

```text
build/app/outputs/flutter-apk/app-prod-release.apk
```
